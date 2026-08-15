package eu.darys.heymaya

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * SYGNAŁ POTWIERDZENIA KOMENDY GŁOSOWEJ - dźwięk systemowy Androida.
 *
 * Po co własny kanał, skoro na iOS wystarczał pakiet `flutter_beep`:
 * `flutter_beep` nie deklaruje `namespace` w swoim `android/build.gradle`, więc
 * od AGP 8 zatrzymuje build jeszcze na konfiguracji Gradle. Zastępczo grał tu
 * `assets/audio/listening.wav` przez `audioplayers` - i to jest to, co się nie
 * podobało (nagrany plik zamiast krótkiego sygnału systemu).
 *
 * Ten sam kanał („hej_maja/sygnal") obsługuje teraz TAKŻE iOS, w projekcie
 * `hi_bees` (`ios/Runner/AppDelegate.swift`, `AudioServicesPlaySystemSound`),
 * więc `flutter_beep` wypadł z obu projektów.
 *
 * [ToneGenerator] to ta sama klasa, której używa `flutter_beep` po stronie
 * Androida, tylko wołana wprost - bez martwej zależności w `pubspec.yaml`.
 *
 * PRZY OKAZJI ZNIKA PROBLEM Z MIKROFONEM: `audioplayers` prosi Androida
 * o audio focus, a odebranie focusu pauzuje nagrywanie w pakiecie `record`
 * (patrz ANDROID_GLOS.md, runda 3). [ToneGenerator] pisze wprost do ścieżki
 * audio i o focus NIE prosi, więc nasłuch nie ma od czego przycichnąć.
 *
 * RUNDA 5 (15.08.2026) - zgłoszenie „na Androidzie i tak gra listening.wav".
 * Kanał wraca do Darta z zapasowym plikiem tylko wtedy, gdy [zagrajSygnal]
 * powie „nie zagrałem", więc naprawa to trzy rzeczy naraz:
 *  1. HONORUJEMY WYNIK [ToneGenerator.startTone] - zwraca `boolean` i potrafi
 *     oddać `false` bez rzucania wyjątku (zajęta ścieżka audio). Dotąd zawsze
 *     raportowaliśmy sukces, więc „gra plik" znaczyło, że poległ już sam
 *     KONSTRUKTOR generatora - a to najczęściej znaczy zajętą ścieżkę mediów;
 *  2. DRUGIE PODEJŚCIE NA INNYM STRUMIENIU (STREAM_SYSTEM, potem
 *     STREAM_NOTIFICATION) i ostatecznie systemowy efekt dźwiękowy - żeby
 *     przegrana na jednej ścieżce nie kończyła się od razu plikiem;
 *  3. ODPOWIEDŹ TEKSTOWA zamiast `true`/`false` - Dart ma powiedzieć w
 *     ustawieniach głosu (przycisk „Sprawdź sygnał"), CO się stało. Z telefonu
 *     nie da się inaczej odróżnić „stary build bez kanału" od „ToneGenerator
 *     odmówił" - w obu przypadkach słychać dokładnie to samo: plik.
 */
class MainActivity : FlutterActivity() {

  private val kanalSygnalu = "hej_maja/sygnal"

  //JEDNA instancja na cały czas życia ekranu. ToneGenerator zajmuje ścieżkę
  //audio systemu, a tych jest skończona liczba - tworzenie go przy każdym
  //sygnale kończy się wyjątkiem po kilkudziesięciu komendach.
  private var generatorTonu: ToneGenerator? = null

  //strumień, na którym stoi [generatorTonu] - strumienia nie da się zmienić po
  //utworzeniu, więc przy zmianie trzeba zwolnić stary generator i zrobić nowy
  private var strumienGeneratora = STRUMIEN_NIEZNANY

  //Sygnał ma być KRÓTKI i NIE MOŻE BYĆ MOWĄ: mikrofon nasłuchuje bez przerwy,
  //więc każdy dźwięk przecieka do Voska. Z tonu nie ma jak zbudować słowa.
  //
  //15.08.2026 - wracamy do TONE_CDMA_ONE_MIN_BEEP, czyli DOKŁADNIE tego, co
  //grało tu przez `flutter_beep` (jego `AndroidSoundIDs` to były po prostu
  //stałe [ToneGenerator], więc żaden dźwięk nie przepadł razem z pakietem).
  //Poprzedni TONE_PROP_BEEP to sinus ~0,15 s, czyli brzmieniowo bliźniak
  //zapasowego `listening.wav` - stąd wrażenie „i tak gra plik".
  //
  //Do przymiarek wystarczy podmienić tę jedną stałą (nazwa tonu jest w opisie
  //zwracanym do Darta, więc dzwonek w Ustawieniach powie, co właśnie zagrało):
  //  TONE_PROP_ACK          - dwutonowe "przyjąłem"
  //  TONE_PROP_BEEP2        - podwójny beep
  //  TONE_PROP_BEEP         - pojedynczy sinus (było do 15.08.2026)
  //  TONE_CDMA_CONFIRM      - krótkie potwierdzenie z telefonii
  //  TONE_CDMA_ALERT_CALL_GUARD - wyraźniejszy, "systemowy" dwuton
  private val tonPotwierdzenia = ToneGenerator.TONE_PROP_PROMPT
  private val nazwaTonu = "TONE_PROP_PROMPT"
  private val czasTonuMs = 150

  //Kolejność prób. STREAM_MUSIC jest pierwszy, bo tam stoi suwak, którego
  //pszczelarz w terenie faktycznie używa (tym samym reguluje odzywki Mai).
  //Dalsze dwa to ścieżki, które system trzyma dla dźwięków własnych - bywają
  //wolne wtedy, gdy ścieżka mediów jest zajęta przez nasze nagrywanie.
  private val strumienieDoProby = intArrayOf(
    AudioManager.STREAM_MUSIC,
    AudioManager.STREAM_SYSTEM,
    AudioManager.STREAM_NOTIFICATION,
  )

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, kanalSygnalu)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "beep" -> result.success(zagrajSygnal())
          else -> result.notImplemented()
        }
      }
  }

  /**
   * Zwraca OPIS TEKSTOWY tego, co się stało - nigdy nie rzuca.
   *
   * Kontrakt ze stroną Dartową ([SoundHelper.beep]): odpowiedź zaczynająca się
   * od „ok" znaczy „zagrałem, nie sięgaj po plik". Cokolwiek innego to powód
   * porażki, który Dart pokaże w ustawieniach głosu i zagra plik zapasowy.
   */
  private fun zagrajSygnal(): String {
    val powody = mutableListOf<String>()
    for (strumien in strumienieDoProby) {
      //w opisie NAZWA TONU, nie tylko strumień: przy przymiarkach kolejnych
      //stałych to jedyny sposób, żeby z telefonu potwierdzić, że build jest
      //świeży i gra naprawdę ten ton, który był ustawiany
      val powod = sprobujTon(strumien)
        ?: return "ok: ton $nazwaTonu na ${nazwaStrumienia(strumien)}"
      powody += powod
    }
    val powodEfektu = sprobujEfektSystemowy()
    if (powodEfektu == null) {
      //UWAGA: playSoundEffect nie mówi, czy cokolwiek było słychać - gdy
      //w ustawieniach telefonu wyłączone są „dźwięki dotyku", system po cichu
      //nic nie robi. Dlatego opis mówi wprost, czego szukać, gdy jest cisza.
      return "ok: efekt systemowy (cisza? włącz dźwięki dotyku w ustawieniach telefonu)"
    }
    powody += powodEfektu
    return "brak: ${powody.joinToString(" | ")}"
  }

  /** `null` = zagrało; tekst = dlaczego nie zagrało na tym strumieniu. */
  private fun sprobujTon(strumien: Int): String? {
    return try {
      //jawne `if` z `!!` zamiast lokalnej zmiennej nullowalnej - nie zostawiamy
      //kompilatorowi zgadywania, czy po przypisaniu w gałęzi da się zrobić
      //smart cast (generatorTonu jest polem, więc sam z siebie się nie zawęża)
      val generator: ToneGenerator =
        if (generatorTonu == null || strumienGeneratora != strumien) {
          generatorTonu?.release()
          ToneGenerator(strumien, GLOSNOSC_TONU).also {
            generatorTonu = it
            strumienGeneratora = strumien
          }
        } else {
          generatorTonu!!
        }
      //stopTone przed startem: przy szybkiej serii komend poprzedni ton mógłby
      //jeszcze brzmieć i kolejne wywołanie zostałoby po cichu zignorowane
      generator.stopTone()
      if (generator.startTone(tonPotwierdzenia, czasTonuMs)) {
        null
      } else {
        //generator żyje, ale odmówił zagrania - następna próba ma dostać
        //świeży obiekt na innym strumieniu
        zwolnijGenerator()
        "startTone=false na ${nazwaStrumienia(strumien)}"
      }
    } catch (e: RuntimeException) {
      //ToneGenerator rzuca („Init failed"), gdy systemowi zabraknie ścieżek audio
      zwolnijGenerator()
      "ToneGenerator ${nazwaStrumienia(strumien)}: ${e.message ?: e.javaClass.simpleName}"
    }
  }

  /**
   * Ostatnia deska ratunku: dźwięk z puli efektów systemowych. Gra go proces
   * systemowy, a nie nasza aplikacja - nie zużywa więc ANI naszej ścieżki
   * audio, ANI audio focusa, czyli działa dokładnie tam, gdzie
   * [ToneGenerator] się poddaje.
   */
  private fun sprobujEfektSystemowy(): String? {
    return try {
      val menedzer = getSystemService(Context.AUDIO_SERVICE) as AudioManager
      menedzer.playSoundEffect(AudioManager.FX_KEY_CLICK, 1.0f)
      null
    } catch (e: RuntimeException) {
      "playSoundEffect: ${e.message ?: e.javaClass.simpleName}"
    }
  }

  private fun zwolnijGenerator() {
    try {
      generatorTonu?.release()
    } catch (e: RuntimeException) {
      //zwalnianie zepsutego generatora też potrafi rzucić - i tak go porzucamy
    }
    generatorTonu = null
    strumienGeneratora = STRUMIEN_NIEZNANY
  }

  private fun nazwaStrumienia(strumien: Int): String = when (strumien) {
    AudioManager.STREAM_MUSIC -> "media"
    AudioManager.STREAM_SYSTEM -> "system"
    AudioManager.STREAM_NOTIFICATION -> "powiadomienia"
    else -> "strumień $strumien"
  }

  override fun onDestroy() {
    zwolnijGenerator()
    super.onDestroy()
  }

  companion object {
    //głośność tonu w skali 0-100 (ToneGenerator ma własną, niezależną od
    //suwaka mediów - 100 przy telefonie leżącym na ulu było za ostre)
    private const val GLOSNOSC_TONU = 80

    //wartość spoza zakresu AudioManager.STREAM_* - „generatora jeszcze nie ma"
    private const val STRUMIEN_NIEZNANY = -1
  }
}
