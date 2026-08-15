package org.vosk.vosk_flutter;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.vosk.LibVosk;
import org.vosk.LogLevel;
import org.vosk.Model;
import org.vosk.Recognizer;
import org.vosk.android.SpeechService;
import org.vosk.vosk_flutter.exceptions.MissingRequiredArgument;
import org.vosk.vosk_flutter.exceptions.RecognizerNotFound;
import org.vosk.vosk_flutter.exceptions.SpeechServiceNotFound;
import org.vosk.vosk_flutter.exceptions.WrongArgumentTypeException;
import org.vosk.SpeakerModel;

/**
 * VoskFlutterPlugin
 *
 * <p>============================================================================
 * KOPIA ZWENDOROWANA (hi_bees) — vosk_flutter_service 0.1.2
 * ----------------------------------------------------------------------------
 * Zmiany względem oryginału z pub.dev (13.08.2026, uruchomienie na Androidzie).
 * Aktualizacja pakietu = nadpisanie tego pliku, więc poprawki trzeba nanieść
 * ponownie — opis całości w HI_BEES_PATCH.md.
 *
 * <p>1. PRACA RECOGNIZERA ZESZŁA Z WĄTKU UI. Oryginał wołał
 *    {@code acceptWaveForm}, {@code getResult}, {@code getPartialResult},
 *    {@code getFinalResult}, {@code reset}, {@code close} ORAZ budowę
 *    recognizera wprost w {@link #onMethodCall} — czyli na głównym wątku
 *    Androida (na {@link TaskRunner} schodziło tylko ładowanie modelu).
 *    W hi_bees to nie jest drobiazg wydajnościowy, tylko blokada:
 *      - {@code new Recognizer(model, rate, grammar)} z gramatyką ~3,3 tys.
 *        fraz buduje graf dekodowania przez SEKUNDY. Na wątku UI to prosta
 *        droga do ANR-a przy wejściu na ekran sterowania głosem;
 *      - {@code acceptWaveForm} leci 5 razy na sekundę (porcje 0,2 s), przy
 *        dyktowaniu notatki DWA RAZY tyle (recognizer notatki + detektor frazy
 *        kończącej) — dekodowanie zabierałoby wątek UI, na którym rysuje się
 *        żywy podgląd korpusu.
 *    Teraz wszystko idzie przez {@code voskQueue} — kolejkę SZEREGOWĄ (jeden
 *    recognizer nie jest bezpieczny wielowątkowo), a na główny wątek wraca
 *    tylko gotowa wartość do {@code result(...)}. To samo rozwiązanie, co na
 *    iOS ({@code voskQueue} w VoskFlutterPlugin.swift).
 *
 * <p>2. {@code recognizersMap} jest od tej pory własnością {@code voskQueue} —
 *    czytana i pisana wyłącznie z niej. Mapy modeli są współbieżne, bo model
 *    powstaje na kolejce, a sprzątanie przy odłączeniu silnika idzie z main.
 *
 * <p>3. WYJĄTEK NIE JEST JUŻ WKŁADANY W {@code result.error(..., details)}.
 *    Oryginał podawał tam obiekt {@code Exception}, a StandardMessageCodec nie
 *    umie go zakodować — zamiast czytelnego błędu z natywnej strony leciał
 *    wyjątek z kodeka. Teraz idzie tekstowy ślad stosu.
 *
 * <p>4. Poziom logów Vosk ustawiony na {@code WARNINGS}. Domyślny sypie do
 *    logcata przy każdej porcji audio, a logcat to też praca na urządzeniu.
 * ============================================================================
 */
public class VoskFlutterPlugin implements FlutterPlugin, MethodCallHandler {

  private static final String TAG = "VoskFlutterPlugin";

  private static final Class<HashMap<String, Object>> argsMapClass = (Class<HashMap<String, Object>>) new HashMap<String, Object>().getClass();

  // Modele powstają na voskQueue, a sprzątane są z wątku UI — stąd mapy
  // współbieżne zamiast zwykłych HashMap.
  private final ConcurrentHashMap<String, Model> modelsMap = new ConcurrentHashMap<>();
  private final ConcurrentHashMap<String, SpeakerModel> speakerModelsMap = new ConcurrentHashMap<>();

  // WŁASNOŚĆ voskQueue. Nie dotykać z innego wątku - patrz nagłówek klasy.
  private final TreeMap<Integer, Recognizer> recognizersMap = new TreeMap<>();

  private final Handler mainHandler = new Handler(Looper.getMainLooper());

  // Kolejka szeregowa: jeden recognizer nie znosi równoległych wywołań, a
  // kolejność porcji audio musi zostać zachowana.
  private ExecutorService voskQueue;

  private MethodChannel channel;
  private volatile SpeechService speechService;
  private FlutterRecognitionListener recognitionListener;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "vosk_flutter");
    channel.setMethodCallHandler(this);
    recognitionListener = new FlutterRecognitionListener(flutterPluginBinding.getBinaryMessenger());
    voskQueue = Executors.newSingleThreadExecutor(runnable -> {
      Thread thread = new Thread(runnable, "vosk-queue");
      thread.setPriority(Thread.NORM_PRIORITY);
      return thread;
    });
    try {
      LibVosk.setLogLevel(LogLevel.WARNINGS);
    } catch (Throwable t) {
      // Biblioteka natywna może się nie załadować (brak .so dla ABI) - powiemy
      // o tym przy pierwszym realnym wywołaniu, a nie przy starcie silnika.
      Log.w(TAG, "Nie udało się ustawić poziomu logów Vosk.", t);
    }
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    // Rozbiór argumentów zostaje na wątku UI - jest darmowy, a dzięki temu
    // błędy "złe argumenty" wracają natychmiast, bez kolejkowania.
    try {
      switch (call.method) {

        case "model.create": {
          String modelPath = castMethodCallArgs(call, String.class);
          if (modelPath == null) {
            result.error("WRONG_ARGS", "Please, send 1 string argument, contains model path", null);
            break;
          }

          // Ładowanie modelu (dziesiątki MB) NIGDY na wątku UI. Idzie tą samą
          // kolejką co recognizery, więc budowa gramatyki nie zacznie się,
          // zanim model będzie gotowy.
          boolean modelQueued = execute(() -> {
            try {
              Model model = new Model(modelPath);
              modelsMap.put(modelPath, model);
              mainHandler.post(() -> channel.invokeMethod("model.created", modelPath));
            } catch (Exception e) {
              Log.e(TAG, "Nie udało się wczytać modelu: " + modelPath, e);
              mainHandler.post(() -> channel.invokeMethod("model.error", new HashMap<String, Object>() {{
                put("modelPath", modelPath);
                put("error", String.valueOf(e.getMessage()));
              }}));
            }
          });

          if (!modelQueued) {
            result.error("PLUGIN_DETACHED", "Vosk plugin is not attached to an engine.", null);
            break;
          }
          result.success(null);
        }
        break;

        case "speakerModel.create": {
          String modelPath = castMethodCallArgs(call, String.class);
          if (modelPath == null) {
            result.error("WRONG_ARGS", "Please, send 1 string argument, contains speaker model path", null);
            break;
          }

          boolean speakerQueued = execute(() -> {
            try {
              SpeakerModel speakerModel = new SpeakerModel(modelPath);
              speakerModelsMap.put(modelPath, speakerModel);
              mainHandler.post(() -> channel.invokeMethod("speakerModel.created", modelPath));
            } catch (Exception e) {
              Log.e(TAG, "Nie udało się wczytać modelu mówcy: " + modelPath, e);
              mainHandler.post(() -> channel.invokeMethod("speakerModel.error", new HashMap<String, Object>() {{
                put("speakerModelPath", modelPath);
                put("error", String.valueOf(e.getMessage()));
              }}));
            }
          });

          if (!speakerQueued) {
            result.error("PLUGIN_DETACHED", "Vosk plugin is not attached to an engine.", null);
            break;
          }
          result.success(null);
        }
        break;


        case "recognizer.create": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer sampleRate = getRequiredArgumentFromMap(argsMap, "sampleRate", Integer.class);
          String modelPath = getRequiredArgumentFromMap(argsMap, "modelPath", String.class);
          String grammar = getArgumentFromMap(argsMap, "grammar", String.class);

          // Budowa grafu dekodowania z gramatyki liczy się w sekundach - to
          // jest ten moment, w którym stary kod zawieszał wątek UI.
          onVoskQueue(result, () -> {
            Model model = modelsMap.get(modelPath);
            if (model == null) {
              throw new VoskError("NO_MODEL",
                  "Couldn't find model with this path. Pls, create model or send correct path.");
            }

            Integer recognizerId = recognizersMap.isEmpty() ? 1 : recognizersMap.lastKey() + 1;
            try {
              Recognizer recognizer = grammar == null
                  ? new Recognizer(model, sampleRate)
                  : new Recognizer(model, sampleRate, grammar);
              recognizersMap.put(recognizerId, recognizer);
            } catch (IOException e) {
              throw new VoskError("CREATION_ERROR", "Can't create recognizer. " + e.getMessage());
            }

            return recognizerId;
          });
        }
        break;

        case "recognizer.setSpeakerModel": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          String speakerModelPath = getRequiredArgumentFromMap(argsMap, "speakerModelPath", String.class);

          onVoskQueue(result, () -> {
            SpeakerModel speakerModel = speakerModelsMap.get(speakerModelPath);
            if (speakerModel == null) {
              throw new VoskError("NO_SPEAKER_MODEL",
                  "Couldn't find speaker model with this path. Pls, create speaker model or send correct path.");
            }
            getRecognizerById(recognizerId).setSpeakerModel(speakerModel);
            return null;
          });
        }
        break;


        case "recognizer.setMaxAlternatives": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          Integer maxAlternatives = getRequiredArgumentFromMap(argsMap, "maxAlternatives",
              Integer.class);

          onVoskQueue(result, () -> {
            getRecognizerById(recognizerId).setMaxAlternatives(maxAlternatives);
            return null;
          });
        }
        break;

        case "recognizer.setWords": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          Boolean words = getRequiredArgumentFromMap(argsMap, "words", Boolean.class);

          onVoskQueue(result, () -> {
            getRecognizerById(recognizerId).setWords(words);
            return null;
          });
        }
        break;

        case "recognizer.setPartialWords": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          Boolean partialWords = getRequiredArgumentFromMap(argsMap, "partialWords", Boolean.class);

          onVoskQueue(result, () -> {
            getRecognizerById(recognizerId).setPartialWords(partialWords);
            return null;
          });
        }
        break;

        case "recognizer.acceptWaveForm": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          byte[] bytes = getArgumentFromMap(argsMap, "bytes", byte[].class);
          float[] floats = getArgumentFromMap(argsMap, "floats", float[].class);

          if (bytes == null && floats == null) {
            result.error("WRONG_ARGS", "Didn't find data. Pls, send data", null);
            break;
          }

          onVoskQueue(result, () -> {
            Recognizer recognizer = getRecognizerById(recognizerId);
            if (bytes == null) {
              return recognizer.acceptWaveForm(floats, floats.length);
            }
            return recognizer.acceptWaveForm(bytes, bytes.length);
          });
        }
        break;

        case "recognizer.getResult": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          onVoskQueue(result, () -> getRecognizerById(recognizerId).getResult());
        }
        break;

        case "recognizer.getPartialResult": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          onVoskQueue(result, () -> getRecognizerById(recognizerId).getPartialResult());
        }
        break;

        case "recognizer.getFinalResult": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          onVoskQueue(result, () -> getRecognizerById(recognizerId).getFinalResult());
        }
        break;

        case "recognizer.setGrammar": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          String grammar = getRequiredArgumentFromMap(argsMap, "grammar", String.class);

          // UWAGA: hi_bees tej drogi NIE UŻYWA (na iOS jej nie ma - libvosk dla
          // iOS nie eksportuje vosk_recognizer_set_grm). Gramatykę podajemy przy
          // tworzeniu recognizera, ta sama ścieżka na obu platformach.
          onVoskQueue(result, () -> {
            getRecognizerById(recognizerId).setGrammar(grammar);
            return null;
          });
        }
        break;

        case "recognizer.reset": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          onVoskQueue(result, () -> {
            getRecognizerById(recognizerId).reset();
            return null;
          });
        }
        break;

        case "recognizer.close": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);

          onVoskQueue(result, () -> {
            getRecognizerById(recognizerId).close();
            recognizersMap.remove(recognizerId);
            return null;
          });
        }
        break;

        case "speechService.init": {
          Map<String, Object> argsMap = castMethodCallArgs(call, argsMapClass);
          Integer recognizerId = getRequiredArgumentFromMap(argsMap, "recognizerId", Integer.class);
          Integer sampleRate = getRequiredArgumentFromMap(argsMap, "sampleRate", Integer.class);

          // Recognizer trzeba wyjąć z mapy należącej do kolejki, więc cała
          // inicjalizacja idzie przez nią.
          onVoskQueue(result, () -> {
            if (speechService != null) {
              throw new VoskError("INITIALIZE_FAIL", "SpeechService instance already exist.");
            }
            try {
              speechService = new SpeechService(getRecognizerById(recognizerId), sampleRate);
            } catch (IOException e) {
              throw new VoskError("INITIALIZE_FAIL", String.valueOf(e.getMessage()));
            }
            return null;
          });
        }
        break;

        case "speechService.start": {
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }
          result.success(speechService.startListening(recognitionListener));
        }
        break;

        case "speechService.stop": {
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }
          result.success(speechService.stop());
        }
        break;

        case "speechService.setPause": {
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }

          Boolean paused = castMethodCallArgs(call, Boolean.class);

          speechService.setPause(paused);
          result.success(null);
        }
        break;

        case "speechService.reset": {
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }
          speechService.reset();
          result.success(null);
        }
        break;

        case "speechService.cancel": {
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }
          result.success(speechService.cancel());
        }
        break;

        case "speechService.destroy": {
          if (speechService == null) {
            throw new SpeechServiceNotFound();
          }
          speechService.shutdown();
          speechService = null;
          result.success(null);
        }
        break;

        default:
          result.notImplemented();
          break;
      }
    } catch (MissingRequiredArgument e) {
      result.error("MISSING_REQUIRED_ARGUMENT", "Couldn't find required argument", stackTrace(e));
    } catch (WrongArgumentTypeException e) {
      result.error("WRONG_TYPE", "Wrong argument type", stackTrace(e));
      // RecognizerNotFound NIE jest tu łapany: szukanie recognizera zeszło na
      // voskQueue, więc na tym wątku nie ma go już jak rzucić (kompilator
      // odrzuca catch dla wyjątku, którego blok try nie może zgłosić).
      // Obsługa jest w postError().
    } catch (SpeechServiceNotFound e) {
      result.error("NO_SPEECH_SERVICE", "Speech service not created.", stackTrace(e));
    }
  }

  // -- kolejka Vosk -----------------------------------------------------------

  /** Zadanie wykonywane na {@code voskQueue}; jego wynik wraca do Darta. */
  private interface VoskTask {
    Object run() throws Exception;
  }

  /** Błąd z ustalonym kodem, żeby strona Darta widziała to samo co dotąd. */
  private static class VoskError extends Exception {
    private final String code;

    VoskError(String code, String message) {
      super(message);
      this.code = code;
    }
  }

  /**
   * Wykonuje [task] na kolejce Vosk i oddaje wynik na wątku UI. Kanał metod
   * Fluttera wymaga, żeby {@code result} był wołany z wątku głównego.
   */
  private void onVoskQueue(@NonNull Result result, @NonNull VoskTask task) {
    boolean queued = execute(() -> {
      final Object value;
      try {
        value = task.run();
      } catch (Exception e) {
        postError(result, e);
        return;
      }
      mainHandler.post(() -> result.success(value));
    });
    if (!queued) {
      result.error("PLUGIN_DETACHED", "Vosk plugin is not attached to an engine.", null);
    }
  }

  /** Zwraca false, gdy kolejki już nie ma (silnik odłączony w trakcie pracy). */
  private boolean execute(@NonNull Runnable runnable) {
    ExecutorService queue = voskQueue;
    if (queue == null || queue.isShutdown()) {
      return false;
    }
    try {
      queue.execute(runnable);
      return true;
    } catch (RuntimeException e) {
      // Wyścig z onDetachedFromEngine - kolejka zamknięta między sprawdzeniem
      // a wysłaniem zadania.
      Log.w(TAG, "Kolejka Vosk odrzuciła zadanie.", e);
      return false;
    }
  }

  private void postError(@NonNull Result result, @NonNull Exception e) {
    final String code;
    final String message;
    if (e instanceof VoskError) {
      code = ((VoskError) e).code;
      message = e.getMessage();
    } else if (e instanceof RecognizerNotFound) {
      code = "NO_RECOGNIZER";
      message = "There is no recognizer with this id.";
    } else if (e instanceof MissingRequiredArgument) {
      code = "MISSING_REQUIRED_ARGUMENT";
      message = "Couldn't find required argument";
    } else if (e instanceof WrongArgumentTypeException) {
      code = "WRONG_TYPE";
      message = "Wrong argument type";
    } else {
      code = "VOSK_ERROR";
      message = String.valueOf(e.getMessage());
    }
    Log.e(TAG, "Błąd w kolejce Vosk (" + code + ")", e);
    // details MUSI być typem obsługiwanym przez StandardMessageCodec - obiekt
    // wyjątku wysypywał kodowanie odpowiedzi (patrz nagłówek klasy).
    final String details = stackTrace(e);
    mainHandler.post(() -> result.error(code, message, details));
  }

  private static String stackTrace(Throwable t) {
    return Log.getStackTraceString(t);
  }

  // -- pomocnicze -------------------------------------------------------------

  public <T> T castMethodCallArgs(MethodCall call, Class<T> classType)
      throws WrongArgumentTypeException {
    if (classType.isInstance(call.arguments)) {
      return classType.cast(call.arguments);
    } else {
      throw new WrongArgumentTypeException(call.arguments.getClass(), classType,
          String.format("%s method", call.method));
    }
  }

  public <T> T getArgumentFromMap(Map<String, Object> map, String argumentName, Class<T> classType)
      throws WrongArgumentTypeException {
    Object argument = map.get(argumentName);
    if (argument == null) {
      return null;
    } else if (classType.isInstance(argument)) {
      return classType.cast(argument);
    } else {
      throw new WrongArgumentTypeException(argument.getClass(), classType,
          String.format("Argument %s", argumentName));
    }
  }

  public <T> T getRequiredArgumentFromMap(Map<String, Object> map, String argumentName,
      Class<T> classType) throws MissingRequiredArgument, WrongArgumentTypeException {
    T argument = getArgumentFromMap(map, argumentName, classType);
    if (argument == null) {
      throw new MissingRequiredArgument(argumentName);
    }

    return argument;
  }

  /** Wolno wołać WYŁĄCZNIE z {@code voskQueue}. */
  Recognizer getRecognizerById(Integer recognizerId) throws RecognizerNotFound {
    Recognizer recognizer = recognizersMap.get(recognizerId);
    if (recognizer == null) {
      throw new RecognizerNotFound(recognizerId);
    }
    return recognizer;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    recognitionListener.dispose();

    if (speechService != null) {
      speechService.shutdown();
      speechService = null;
    }

    // Sprzątanie idzie na kolejkę, bo recognizery i modele są jej własnością,
    // a w chwili odłączenia może w niej jeszcze siedzieć porcja audio.
    // Kolejność ma znaczenie: najpierw recognizery, potem modele - model
    // zamknięty pod pracującym recognizerem to natychmiastowy SIGSEGV.
    ExecutorService queue = voskQueue;
    voskQueue = null;
    if (queue == null) {
      return;
    }
    queue.execute(() -> {
      List<Recognizer> recognizers = new ArrayList<>(recognizersMap.values());
      recognizersMap.clear();
      for (Recognizer recognizer : recognizers) {
        try {
          recognizer.close();
        } catch (Exception e) {
          Log.w(TAG, "Nie udało się zamknąć recognizera.", e);
        }
      }

      List<Model> models = new ArrayList<>(modelsMap.values());
      modelsMap.clear();
      for (Model model : models) {
        try {
          model.close();
        } catch (Exception e) {
          Log.w(TAG, "Nie udało się zamknąć modelu.", e);
        }
      }
    });
    queue.shutdown();
  }
}
