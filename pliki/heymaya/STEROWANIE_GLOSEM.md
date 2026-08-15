# Sterowanie głosem (Vosk) w projekcie androidowym — co zostało zrobione

**Data:** 14.08.2026 · **Punkt wyjścia:** projekt `heymaya` w wersji 1.11.3.94
(bez sterowania głosem) · **Źródło kodu:** repo iOS `hi_bees`, wersja 1.12.0.95

Sterowanie głosem działa na iPhonie od sierpnia 2026. Tu jest ta sama ścieżka
przeniesiona do projektu androidowego — razem z poprawkami, bez których na
Androidzie nie zadziałałaby wcale.

> **Nic z tego nie zostało zbudowane ani uruchomione** — kontener, w którym
> powstała ta zmiana, nie ma Flutter SDK ani Android SDK. Pierwszy build i cały
> test jest po Twojej stronie.

---

## Zanim zbudujesz — trzy komendy

```bash
flutter pub get      # KONIECZNE: doszła wtyczka ze ścieżki + record + audioplayers,
                     # zniknął vosk_flutter_2; pubspec.lock jest nieaktualny
flutter analyze
flutter test test/vosk_grammar_test.dart test/queen_quality_test.dart
```

**Testy uruchamiaj po nazwach, nie całym `flutter test`.** `test/widget_test.dart`
to nietknięty szablon Fluttera (szuka licznika z demówki „Counter increments"),
więc zawsze świeci na czerwono — tak samo jak w wersji iOS. Kompiluje się, więc
`flutter analyze` przechodzi; padnie dopiero uruchomiony.

`flutter pub get` podniesie przy okazji dwie rzeczy: `archive` 3.6.1 → 4.x
i `permission_handler` 11.4.0 → 12.x. Obie trzymał na starych wersjach
**`vosk_flutter_2`** — porównanie obu locków pokazuje, że był jedynym pakietem
w tym projekcie, którego nie ma w wersji iOS (poza `flutter_lints`). Po jego
usunięciu rozwiązanie powinno wylądować tam, gdzie w iOS: `archive` 4.0.9,
`permission_handler` 12.0.3.

---

## 1. Wtyczka Vosk: kopia w repo zamiast pakietu z pub.dev

`packages/vosk_flutter_service/` (nowy katalog) — zwendorowana kopia pakietu
`vosk_flutter_service` 0.1.2. Zastępuje `vosk_flutter_2: ^1.0.5`, który był tu
dotąd na potrzeby POC.

Nie chodzi o kaprys — **oryginał na Androidzie zawieszałby ekran**. Wołał
`acceptWaveForm`, `get*Result`, `reset`, `close` i **budowę recognizera** wprost
w `onMethodCall`, czyli na głównym wątku:

- budowa recognizera z gramatyką ~3,3 tys. fraz trwa sekundy → okno „Hey Maya
  nie odpowiada" przy wejściu na ekran głosu;
- `acceptWaveForm` idzie 5 razy na sekundę (porcje 0,2 s), a przy dyktowaniu
  notatki dwa razy tyle (recognizer notatki + detektor „hej maja") — na tym
  samym wątku, na którym rysuje się żywy podgląd korpusu.

Teraz wszystko przechodzi przez kolejkę **szeregową** `voskQueue`, a na główny
wątek wraca tylko gotowy wynik. Pełny opis obu platform:
`packages/vosk_flutter_service/HI_BEES_PATCH.md`.

Poza tym w kopii:

- **`android/consumer-rules.pro`** (nowy) wpięty przez `consumerProguardFiles` —
  vosk-android nie ma własnego JNI, woła bibliotekę natywną przez **JNA, po
  nazwach klas i metod**. Przy `minifyEnabled true` R8 je przemianowuje i głos
  pada na `UnsatisfiedLinkError`. W debugu tego nie widać w ogóle. Reguły jadą
  z wtyczką celowo — aplikacja nie musi o nich pamiętać.
- `android/build.gradle`: usunięty własny `buildscript` z AGP 8.0.0 (wtyczka
  bierze AGP z projektu głównego), usunięte `rootProject.allprojects`,
  `compileSdk` 33 → 35 (wymaga tego `androidx.appcompat:appcompat:1.7.0`).
  Projekt stoi na AGP 8.9.1, więc 35 przechodzi bez zastrzeżeń.

### Czego w kopii NIE MA

**Binariów iOS** (`ios/Frameworks/vosk.xcframework`, ~164 MB). Na tej maszynie
i tak nie ma pełnego Xcode. Gdyby kiedyś były potrzebne:

```bash
dart run vosk_flutter_service install -t ios
```

Android niczego nie dociąga — bierze `vosk-android` i JNA z Mavena.

---

## 2. Co doszło po stronie Darta

Nowe pliki (przeniesione 1:1 z iOS, z przepisanymi importami `hi_bees` →
`heymaya`):

| Plik | Do czego |
|---|---|
| `lib/helpers/vosk_engine.dart` | silnik: mikrofon (`record`), model, dwa recognizery, watchdog ciszy |
| `lib/helpers/vosk_grammar.dart` | parser gramatyki `assets/grammar/pol_vosk.yml` |
| `lib/helpers/sound_helper.dart` | odzywki Mai (mp3) + sygnał potwierdzenia |
| `lib/helpers/recording_helper.dart` | zapis WAV dyktowanych notatek, cykl życia (7 dni) |
| `lib/helpers/undo_helper.dart` | „hej maja cofnij ostatni zapis" (migawka plastra, stos 5 kroków) |
| `lib/models/recording.dart` | provider `Recordings` |
| `lib/screens/voice_vosk_screen.dart` | ekran główny sterowania głosem |
| `lib/screens/voice_help_dialogs.dart` | okna pomocy (lista poleceń) |
| `lib/screens/voice_settings_screen.dart` | ustawienia głosu (osobny ekran) |
| `lib/widgets/recording_player.dart` | odtwarzacz nagrania przy notatce |
| `lib/screens/vosk_poc_screen.dart` | **podmieniony** — POC z `vosk_flutter_2` na wersję pod nową wtyczkę |
| `test/vosk_grammar_test.dart`, `test/queen_quality_test.dart` | testy jednostkowe |

Assety: `assets/grammar/pol_vosk.yml`, osiem odzywek mp3 i `listening.wav`
(patrz niżej). Wszystko dopisane do `pubspec.yaml`.

Zmiany w plikach, które już były:

- **`db_helper.dart`** — baza **v4 → v5**: nowa tabela `nagrania`, migracja
  `oldVersion < 5`. Doszły `insertZwrocId`, `getInfoUwagi`, `updateInfoUwagi`,
  `updatePrzegladPasieki`, `getAllIds`. Przy okazji (bo plik przeniesiony w
  całości) wchodzi poprawka `applyInfoStateToHives`: ul zlikwidowany zachowuje
  w belce rodzaj, typ i liczbę ramek z ostatniego wpisu „liczba ramek = ",
  zamiast wracać do „Ul ( 10)".
- **`note.dart`** — `insertNotatki` zwraca `int` (id notatki), żeby dało się
  przypiąć do niej nagranie. Dotychczasowi wołający mogą wynik zignorować.
- **`queen_helpers.dart`** — doszedł `qualityIsBad()` / `qualityIsSet()`:
  jakość matki liczona w JEDNYM miejscu, ze wszystkimi językami i wartościami
  historycznymi (patrz punkt 5).
- **`globals.dart`** — `voice2LivePodglad` domyślnie `true`, doszły
  `voiceDiagnostyka` (wyłączona, przełącznik zaremowany) i `nagrywajNotatki`.
  Zniknęło nieużywane `voice2`.
- **`main.dart`** — trasy `VoiceVoskScreen` i `VoiceSettingsScreen`, provider
  `Recordings`, sprzątanie nagrań przy starcie.
- **`apiarys_screen.dart`** — wróciła stopka, z **jednym** przyciskiem
  „STEROWANIE GŁOSEM". Przycisku NFC tam nie ma, bo w tej wersji sesja NFC
  startuje sama w `initState` ekranu, a nie z przycisku jak na iOS.
- **`parametr_screen.dart`** — belka „Sterowanie głosem" prowadząca do
  osobnego ekranu ustawień.
- **`info_item.dart`, `note_item.dart`, `note_priorytet_item.dart`,
  `note_edit_screen.dart`, `infos_edit_screen.dart`** — ikonka głośnika przy
  notatce, która ma nagranie; kasowanie wpisu kasuje nagranie. W ekranach
  edycji (notatki i przeglądu) odtwarzacz ma suwak, bo poprawianie tekstu to
  skakanie po nagraniu, a nie słuchanie go od początku.
- **`frames_screen.dart`** — `getDaty` czyta daty z DWÓCH źródeł: z tabeli
  `ramka` (zwykły przegląd) **oraz** z `info` kategorii `inspection`. Bez tego
  przegląd założony samą podyktowaną notatką zapisywał się do bazy, ale nie było
  jak go otworzyć — ekran mówił „Nie ma jeszcze żadnych przeglądów". Doszedł też
  odtwarzacz nagrania i komunikat `noFramesInInspection`.
- **`import_screen.dart`** — przy imporcie odtwarzane są teraz nie tylko tagi
  NFC (`h3`), ale i rodzaj (`h1`) oraz typ ula (`h2`). Tabela `ule` nie przychodzi
  z serwera, tylko jest odbudowywana z `ramka` i `info`, więc wszystkie trzy
  kolumny przepadały tak samo. Razem z tym idzie poprawka w `infos_edit_screen`
  (`_uzupelnijRodzajITyp`): zmiana liczby ramek nie robi już z Odkładu Ula,
  a z ulika weselnego wielkopolskiego.
- **`l10n`** — pliki ARB i wygenerowane `app_localizations*.dart` zrównane z
  wersją iOS (doszły `apiaryAcc`, `frameAcc`, `hivesPlural`, `undoDone`,
  `undoFailed`, `undoNothing`, poprawione frazy pomocy).

### Bramka językowa

Przycisk na ekranie startowym i belka w Parametryzacji pokazują się **tylko
przy `globals.jezyk == 'pl_PL'`**. `vosk_engine.dart` pobiera bezwarunkowo
`vosk-model-small-pl-0.22`, a gramatyka jest polska — przy innym języku nie ma
czego uruchomić.

---

## 3. Różnice względem wersji iOS (świadome)

### `flutter_beep` wypadł

Potwierdzenie przyjęcia komendy grało na iOS przez `FlutterBeep.playSysSound`.
Ten pakiet **nie przechodzi buildu od AGP 8** — stoi na wtyczkowym
`build.gradle` sprzed 8.0 i nie deklaruje `namespace`, więc Gradle zatrzymuje
się na „Namespace not specified" jeszcze przed kompilacją. (Dlatego był tu
zaremowany w `pubspec.yaml` — zostaje zaremowany, teraz z wyjaśnieniem.)

Zamiast niego `SoundHelper.beep()` gra `assets/audio/listening.wav` — 0,15 s,
44,1 kHz. Tak samo jak beep **nie jest mową**, więc kiedy przecieknie do
mikrofonu, Vosk nie ma z czego zbudować frazy. To był cały powód, dla którego
w tym miejscu nie gra „okej.mp3".

Sygnał ma własny odtwarzacz, **poza** listą `soundNames` — nie jest odzywką
Mai i nie ma swojego suwaka w ustawieniach; głośność bierze z suwaka głównego.

### Nazwa aplikacji w komunikatach

`vosk_engine.dart` pokazuje przy odmowie zgody na mikrofon ścieżkę
**androidową** i nazwę **„Hey Maya"** (na iOS jest „Hi Bees"). To jedyny
komunikat, po którym nasłuch nie wróci sam, więc musi wskazywać właściwy ekran.

### Ekran POC został widoczny

Ikonka „POC Vosk-PL" (mikrofon, fioletowa) w pasku ekranu startowego zostaje
włączona — w wersji iOS jest zaremowana. Na nowej platformie to najszybszy
sposób sprawdzenia surowego rozpoznawania bez gramatyki. Do zdjęcia po testach:
`apiarys_screen.dart`, `IconButton` w `actions` + import.

---

## 4. Warstwa natywna Androida

- **`res/xml/backup_rules.xml`** i **`res/xml/data_extraction_rules.xml`**
  (nowe) + wpięcie w `<application>`. Model Vosk (~50 MB) ląduje w
  `files/vosk_models`, a auto-backup ma **limit 25 MB na aplikację**; po jego
  przekroczeniu system przestaje robić kopię **całej** aplikacji, razem z bazą
  pasiek. Wyłączone są też nagrania notatek (`app_flutter/nagrania`).
- **`app/proguard-rules.pro`** (nowy) + `proguardFiles` w `buildTypes.release`.
  Dziś **bezczynne**, bo `isMinifyEnabled = false`. Wpięte z góry, żeby
  włączenie zmniejszania kodu nie wywaliło powiadomień (Gson po nazwach pól).
  Reguł dla Voska/JNA tam nie ma — jadą z wtyczki.
- **`RECORD_AUDIO`** już było w manifeście. `record` prosi o zgodę sam, przy
  pierwszym wejściu na ekran głosu.
- **`minSdk` zostaje 23** (`gradle.properties`) — **niesprawdzone**. Wtyczka
  Vosk deklaruje 21, ale wymagań `record_android` i `audioplayers_android` nie
  dało się tu zweryfikować (brak pub-cache w kontenerze). Gdyby scalanie
  manifestów zaprotestowało („uses-sdk:minSdkVersion 23 cannot be smaller than
  version 24…"), podnieś `flutter.minSdkVersion` do wartości z komunikatu — to
  jedyna zmiana, jaka będzie wtedy potrzebna.
- `compileSdk` (36) i `targetSdk` (36) **bez zmian**.

---

## 5. Jakość matki: „zła" → „do wymiany"

To nie jest zmiana pod głos, ale bez niej głos byłby niespójny, więc weszła
razem: gramatyka Vosk **nie przyjmuje już słowa „zła"** dla jakości matki (jest
„do wymiany"), a lista wyboru i pomoc muszą mówić to samo, co gramatyka.

Dlatego:
- `canceled` w ARB to teraz „do wymiany" (EN: „to replace"), `exchange` po
  angielsku to „old";
- kciuk w górę/w dół liczy **jedna funkcja** `qualityIsBad()` z
  `queen_helpers.dart`, zamiast sześciu kopii listy literałów rozsianych po
  `hives_screen`, `hives_item`, `infos_screen`, `infos_edit_screen`,
  `summary_screen`. Kopie znały tylko polski i angielski, więc np. niemieckie
  „zu ersetzen" dostawało kciuk w górę.

**Stare wpisy z wartością „zła" czytamy dalej** i dalej dają kciuk w dół —
`queen_helpers` trzyma tabelę wszystkich tłumaczeń i wartości historycznych.
Wewnętrzna flaga belki (`ule.matka1 = 'zła'`) się **nie zmienia** — to nie jest
etykieta z listy, tylko znacznik.

---

## Checklist testów na telefonie

Kolejność ma znaczenie — każdy punkt zakłada, że poprzedni przeszedł.

- [ ] `flutter pub get`, `flutter analyze`, `flutter test` — czysto.
- [ ] **Build debug wchodzi na telefon** i apka startuje.
- [ ] Baza migruje z v4 na v5 (na telefonie z danymi!) — pasieki, ule
      i przeglądy są na miejscu, nic nie zniknęło.
- [ ] Ekran startowy pokazuje przycisk **STEROWANIE GŁOSEM** (widoczny tylko
      przy języku polskim).
- [ ] Wejście na ekran głosu: prośba o **zgodę na mikrofon**; po odmowie
      komunikat wskazuje ścieżkę androidową i nazwę „Hey Maya".
- [ ] **Pobranie modelu** (~50 MB, tylko raz) kończy się: „Ładuję model…",
      potem „Buduję gramatykę komend…".
- [ ] **Ekran nie zawiesza się** przy budowie gramatyki — brak okna „Hey Maya
      nie odpowiada". To jest test kolejki `voskQueue`.
- [ ] Ekran startuje **w poziomie**, żywy podgląd korpusu **płynnie się rysuje
      w trakcie nasłuchu** (drugi test tej samej poprawki — dekodowanie nie może
      zabierać wątku UI).
- [ ] „Hej Maja start" otwiera sesję, odzywka Mai jest **słyszalna**.
- [ ] Odzywka **nie wraca do mikrofonu jako fraza**. Na iOS trzeba było na to
      ogona wyciszenia 300 ms; na Androidzie bufor wejścia jest inny i ta liczba
      może wymagać korekty (`_ogonWyciszenia` w `vosk_engine.dart`).
- [ ] Kilka komend zapisujących (np. „ciasto dwa kilogramy") — czy trafiają do
      bazy i czy **rozpoznawanie nie jest wyraźnie gorsze niż na iPhonie**.
      Jeśli jest — pierwszy podejrzany to źródło audio (`AndroidRecordConfig`
      w `vosk_engine.dart`, `_startStrumienia`).
- [ ] Sygnał potwierdzenia komendy jest **słyszalny** i nie wraca jako fraza.
- [ ] „Hej Maja cofnij ostatni zapis" przywraca stan.
- [ ] **Dyktowanie notatki** („notatka do notesu") — tekst leci na żywo,
      „hej maja" kończy, nagranie WAV da się odtworzyć przy notatce.
      Najcięższy tryb: dwa recognizery na jednej porcji.
- [ ] Jakość matki „do wymiany" — z ręki i głosem; **stary wpis „zła"** ma się
      pokazywać na liście i dawać kciuk w dół.
- [ ] **Przerwanie mikrofonu**: zadzwoń na telefon w trakcie nasłuchu. Po
      odłożeniu słuchawki nasłuch ma wrócić **sam** (backoff do 15 s), w
      czuwaniu, nie w komendach.
- [ ] Przejście w tło i powrót — mikrofon wraca, ekran nie zostaje „żywy przy
      martwym mikrofonie".
- [ ] **BUILD RELEASE (podpisany!)** — instalacja i cała ścieżka jeszcze raz.

---

## Picovoice — stan po przeglądzie

Sprawdzone: **nie ma żadnego żywego kodu, żadnych assetów ani żadnej
zależności** po Picovoice. Konkretnie:

- brak plików `.ppn` / `.rhn` / `.pv` i katalogów `assets/porcupine`,
  `assets/rhino` (wpisy w `pubspec.yaml` były i zostają zaremowane);
- brak `picovoice_flutter`, `porcupine_flutter`, `rhino_flutter` w zależnościach;
- `frames_screen.dart` miał jeszcze zaremowane importy Picovoice, `accessKey`
  z konsoli Picovoice i martwy widget stopki „Made in Vancouver, Canada by
  Picovoice" — **usunięte** razem z przeniesieniem tego pliku;
- `globals.dart` i `models/memory.dart` opisywały `key` jako „accessKey
  picovoice" — komentarze poprawione (to dziś klucz aktywacyjny apki, silnik go
  nie potrzebuje).

- **`lib/screens/voice_screen.dart` SKASOWANY** (14.08.2026, na prośbę
  użytkownika) — 9188 linii starego ekranu Picovoice, w całości wewnątrz jednego
  bloku `/* */`. Wersja iOS pozbyła się go commitem `0cada23`; wersja androidowa
  różniła się od tamtej o ~7,9 tys. linii, więc **w gicie `hi_bees` jej nie ma** —
  jeśli miałaby kiedyś wrócić, jedyne źródło to historia gita tego projektu
  (`git show <commit>:lib/screens/voice_screen.dart`). Razem z plikiem zniknęły
  zaremowane odwołania w `main.dart` i `apiarys_screen.dart`.

Nazwy `rhinoText` i `buildRhinoTextArea` w `voice_vosk_screen.dart` **nie są
pozostałością** — tak samo nazywają się w wersji iOS (ekran powstał jako kopia
`voice_screen2.dart` z wymienionym silnikiem). Reszta wzmianek to komentarze
i historia wersji.

---

## Zaległości względem iOS — nadrobione 14.08.2026

Nie miały związku ze sterowaniem głosem, ale skoro i tak porównywaliśmy drzewa:

- **`widgets/queen_item.dart:42`** — data poddania matki brała się z
  `globals.dataWpisu` (ostatnio wybrana data), teraz z `DateTime.now()`.
  Ciekawostka: komentarz wersji **1.11.3.94 tę zmianę obiecywał**, a kodu tu
  nigdy nie było.
- **`screens/apiary_weather_5days.dart:238`** — `globals.jezyk == 'pl_PL'`
  zamienione na `globals.isEuropeanFormat()`. Przy siedmiu językach interfejsu
  Niemiec czy Włoch dostawał w prognozie datę w formacie `2026-08-14` zamiast
  `14.08.2026`.
- **Sprzątanie po `flutter analyze`** (commit iOS `394075e`) w dziewięciu
  plikach: nieużywane importy (`weather.dart` w `apiarys_all_map_screen`,
  `infos.dart` w `frames_detail_item`, `dart:typed_data` w `infos_screen` —
  `Uint8List` przychodzi z `flutter/services.dart`) i martwe komentarze
  w `frame_edit_screen`, `frame_edit_screen2`, `apiarys_weather_edit_screen`,
  `about_screen`, `purchase_screen`, `sale_screen`. Plus nieużywana zmienna
  `loc` w `info_item.dart`.

**Świadomie NIE nadrobione:**

| Plik | Android ma | iOS ma | Dlaczego zostaje |
|---|---|---|---|
| `screens/raport_color_screen.dart:410,477` | `//BorderSide(color: color, width: 0.5)` zaremowane | aktywne | decyzja użytkownika — obramowania słupków mają zostać wyłączone |
| `screens/hive_news_settings_screen.dart:71` | `Switch.adaptive` | `Switch` | czysta kosmetyka iOS (`.adaptive` daje tam zielony `CupertinoSwitch`); na Androidzie oba renderują się tak samo |
| `widgets/info_item.dart:263` | `//print('odświeenie danych o ulu')` zaremowane | `print(...)` żywy | debugowy `print` w produkcji jest gorszy, wersja androidowa jest tu lepsza |

Różnice, które **mają zostać** (celowa odrębność Androida): NFC wpisane wprost
w `apiarys_screen` zamiast `nfc_helper`, brak przycisku NFC w stopce, `hive.h3`
opisane jako tag NFC, zaremowana opcja „NFC wyłączony" w `nfc_settings_screen`,
inna nawigacja po odczycie taga w `nfc_hive_selection_dialog`, własny
`languages_screen.dart`, `globals` bez `library`/`status`, historia wersji
i numer `1.11.3.94`.

Po tej rundzie realny rozjazd z iOS to **18 plików**: 9 to celowa odrębność
Androida, 9 to zmiany wprowadzone przez ten port (beep, „Hey Maya"
w komunikatach, bramka językowa, kolejność importów).

**Drobiazg do wiedzy, nie do naprawy:** `hives_screen.dart:27` importuje
`apiary_weather_5Days.dart` przez duże „D", a plik nazywa się `5days.dart`.
Na macOS (APFS bez rozróżniania wielkości liter) działa i **tak samo jest
w wersji iOS** — zapali się dopiero przy buildzie na systemie plików
rozróżniającym wielkość liter.

---

## Znane, świadomie nierozwiązane

- **Sterowanie głosem po angielsku nie działa.** `vosk_engine.dart` pobiera
  bezwarunkowo model polski. Dotyczy obu platform — stąd bramka językowa.
- **Pobranie modelu idzie przez pamięć.** `ModelLoader` wciąga cały zip (~50 MB)
  do RAM-u, rozpakowuje w pamięci i dopiero potem zrzuca na dysk — szczyt grubo
  ponad 100 MB. Na iPhonie przechodzi; na słabszym Androidzie może skończyć się
  ubiciem procesu przy PIERWSZYM uruchomieniu głosu. Gdyby padło: strumieniowy
  zapis do pliku (`extractFileToDisk` zamiast `decodeBytes` + `compute`) w
  `packages/vosk_flutter_service/lib/src/model_loader.dart`.
- **Rozmiar APK** — cztery ABI po ~10 MB `libvosk.so`. Przy
  `flutter build appbundle` Google Play rozdaje po jednym ABI, ale „gruby" APK
  z `flutter build apk` będzie o ~40 MB większy.
- **Wersja nie została podbita.** W `apiarys_screen.dart` jest komentarz
  `//1.12.0.95 14.08.2026 …`, ale `final wersja` dalej mówi `1.11.3.94`,
  a `pubspec.yaml` `1.11.3+94`. Do podbicia razem przy publikacji.
- **`targetSdk` 36** — bez zmian, ale warto pamiętać, że Android 15 wymusza
  edge-to-edge; to osobny temat, nie do wrzucenia razem z głosem.
