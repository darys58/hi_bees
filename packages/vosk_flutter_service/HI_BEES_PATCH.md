# vosk_flutter_service 0.1.2 — kopia zwendorowana dla hi_bees

Źródło: `https://pub.dev/api/archives/vosk_flutter_service-0.1.2.tar.gz`
(repo autora: https://github.com/dhia-bechattaoui/vosk-flutter-service).
Skopiowane 29.07.2026. Licencja Apache-2.0 — plik `LICENSE` bez zmian.

Pakiet jest w repo, a nie brany z pub.dev, bo trzeba było poprawić warstwę
iOS. Aktualizacja pakietu = nadpisanie plików, więc **poprawki trzeba nanieść
ponownie ręcznie** — ten plik mówi, co zmieniliśmy i dlaczego.

## Co zostało skopiowane

Cały pakiet **poza** `example/`, `test/`, `coverage/`, `build.yaml`,
`analysis_options.yaml`, `plan.md` — rzeczy potrzebne tylko do rozwijania
pakietu, nie do jego użycia.

`packages/**` jest wyłączone z `flutter analyze` (patrz
`analysis_options.yaml` w katalogu głównym) — to nie nasz kod i nie nasz styl.

## Binaria natywne

Nie ma ich w pakiecie z pub.dev (autor je `.pubignore`-uje) ani w gicie
(setki MB, patrz `.gitignore`). Po każdym świeżym klonie repo:

```bash
flutter pub get
dart run vosk_flutter_service install -t ios   # → packages/vosk_flutter_service/ios/Frameworks/
cd ios && pod install && cd ..
```

Instalator pobiera `vosk-ios-0.3.45.zip` z releases v0.0.6 repo autora.
**Nie dodawać `publish_to: none` do `pubspec.yaml` tego pakietu** —
`shouldSkipInstall()` w `lib/src/cli/vosk_cli.dart` wtedy pomija pobieranie.

## Zmiany względem oryginału

Wszystkie w jednym pliku:
`ios/vosk_flutter_service/Classes/VoskFlutterPlugin.swift`
(pełne uzasadnienie i pomiary w nagłówku tego pliku).

### 1. Sesja audio nie jest przestawiana przy `recognizer.*` — GŁÓWNA POPRAWKA

Oryginał wołał `configureAudioSession()` (czyli `setCategory` +
`setActive(true)`) na wejściu do **każdego** wywołania `recognizer.*`
i `speechService.*`. Przy naszym strumieniu to 5 razy na sekundę.
Przestawianie aktywnej sesji audio w trakcie nagrywania przerywa wejście,
a AVAudioRecorder pisze dalej po osi czasu → przerwa ląduje w pliku jako
cyfrowa cisza.

Teraz: dla `recognizer.*` sesja nie jest ruszana w ogóle (recognizer nie
dotyka mikrofonu), dla `speechService.*` konfiguracja jest jednorazowa
(`audioSessionConfigured`).

Pomiar, który to wykrył (nagrania z iPhone'a, analiza próbka po próbce):
karmienie recognizera w tle → 74,3 % cyfrowej ciszy i 60 dziur po ~185 ms;
to samo nagrywanie bez karmienia → 1,7 % zer i zero dziur.

### 2. Praca recognizera zeszła z głównego wątku

`vosk_recognizer_accept_waveform`, `_result`, `_partial_result`,
`_final_result`, `_reset`, `_free` oraz budowa recognizera wykonywały się
wprost w handlerze `FlutterMethodCall`, czyli na głównym wątku iOS (na
`DispatchQueue.global` schodziło tylko ładowanie modelu). Model PL ma 244 k
słów — dekodowanie zajmowało główny wątek prawie bez przerwy.

Teraz wszystko idzie przez `voskQueue` — kolejkę **szeregową** (jeden
recognizer nie jest bezpieczny wielowątkowo). Na główny wątek wraca tylko
gotowa wartość do `result(...)`. Pomocniki: `onVoskQueue(_:_:)`
i `withRecognizer(_:_:_:)`.

`recognizersMap` jest od tej pory własnością `voskQueue` — czytana i pisana
wyłącznie z niej (`speechService.init` też przez nią przechodzi). Mapy modeli
zostają przy głównym wątku.

### 3. Wycięte logowanie z gorącej ścieżki

Przy każdej porcji audio oryginał skanował dane bajt po bajcie i robił `NSLog`
gdy wszystko było zerami — przy dziurawym sygnale pętla dodatniego sprzężenia.
Do tego `NSLog` przy każdym wywołaniu metody i losowy log co ~100 porcji.
Zostało to za flagą `voskVerboseLogging` (domyślnie `false`).

### 4. `SpeechService` — dekodowanie zeszło z wątku audio

Tap wołał Vosk wprost z wątku renderowania audio. Teraz kopiuje bufor
i przekazuje go na `voskQueue`.

**To NIE naprawia znanego błędu tej klasy:** tap jest instalowany w formacie
sprzętowym (iPhone: 48 kHz float ±1.0) i podawany do Vosk, który oczekuje
skali int16 i częstotliwości zadanej przy tworzeniu recognizera — brakuje
`AVAudioConverter` (autor zostawił o tym komentarz w kodzie). Dlatego
`initSpeechService()` jest w hi_bees nieużywany: audio zbiera pakiet `record`,
a my karmimy `recognizer.acceptWaveform`.

## Znane, świadomie nietknięte

- **Android (`android/src/main/java/.../VoskFlutterPlugin.java`)** ma tę samą
  wadę co iOS w punkcie 2: accept/result wołane wprost w `onMethodCall`, czyli
  na wątku UI (na `TaskRunner` schodzi tylko ładowanie modelu). Nie ruszane —
  objaw mierzyliśmy wyłącznie na iOS, a Javy nie ma tu jak skompilować.
  Do zrobienia przy testach na Androidzie.
- `recognizer.setPartialWords` jest no-opem (brak odpowiednika w C API).
- Ścieżka `floats` w `recognizer.acceptWaveform` nie jest zaimplementowana.
- **`Recognizer.setGrammar` NIE DZIAŁA na iOS i nie da się tego naprawić tutaj**
  (ustalone 01.08.2026 po `MissingPluginException(No implementation found for
  method recognizer.setGrammar on channel vosk_flutter)` na iPhonie 15
  i na symulatorze). Dwie warstwy problemu:
  1. `VoskFlutterPlugin.swift` nie ma case'a `"recognizer.setGrammar"` —
     to źródło wyjątku;
  2. dopisanie go nic nie da, bo zwendorowane **libvosk 0.3.45 dla iOS w ogóle
     nie eksportuje `vosk_recognizer_set_grm`**. Sprawdzone na obu archiwach
     w `ios/Frameworks/vosk.xcframework` (`ios-arm64_armv7_armv7s`
     i `ios-arm64_x86_64-simulator`) — z rodziny gramatyk jest wyłącznie
     `vosk_recognizer_new_grm`. Nie ma go też w `Classes/vosk_api.h`.
     Naprawa wymagałaby przebudowania libvosk dla iOS — poza zakresem.

  Obejście po naszej stronie: gramatykę podaje się przy **tworzeniu**
  recognizera (`createRecognizer(grammar:)` — ta ścieżka jest przetestowana
  na urządzeniu). `lib/helpers/vosk_engine.dart` trzyma dlatego dwa gotowe
  recognizery (czuwanie / komendy) i przełącza wskaźnik zamiast gramatyki.
  Android ma `setGrammar` zaimplementowane, ale używamy tej samej drogi na
  obu platformach — jedna ścieżka kodu, zero opóźnienia przy przełączaniu.
