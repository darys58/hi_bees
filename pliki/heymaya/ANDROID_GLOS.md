# Sterowanie głosem na Androidzie — co gotowe, co do zrobienia na drugiej maszynie

**Data:** 13.08.2026 · **Branch:** `xcode-26-upgrade` · **Wersja:** 1.12.0.95
(bez podbicia — commit ≠ nowa wersja)

Punkt wyjścia: sterowanie głosem (Vosk + `record` 6.2.1) **działa na iPhonie**.
Tu jest to, czego brakowało po stronie Androida.

## Jak czytać ten dokument

Projekt androidowy to **osobna kopia repo na drugim komputerze**, z własnymi
wersjami Fluttera i pakietów (stąd cała ta separacja: kiedyś nie dało się
pogodzić wersji). To repo **nie buduje Androida** — katalog `android/` jest tu
martwy i celowo nietknięty.

Dlatego praca dzieli się na dwie części:

| | Gdzie jest | Co z tym zrobić |
|---|---|---|
| **Część A** — niezależna od wersji | zrobiona, w tym repo | przenieść na drugą maszynę razem z resztą kodu |
| **Część B** — konfiguracja builda | **NIE zrobiona** | policzyć na miejscu, z tamtejszego `pubspec.lock` |

> Nic z tego nie było uruchomione ani zbudowane — w tym kontenerze nie ma ani
> Flutter SDK, ani Android SDK.

---

# CZĘŚĆ A — zrobione w tym repo

## A1. Wtyczka Vosk: praca zeszła z wątku UI

`packages/vosk_flutter_service/android/src/main/java/.../VoskFlutterPlugin.java`

To jest **właściwa przyczyna**, dla której głos nie mógłby działać na
Androidzie, nawet gdyby build przechodził. Oryginał wołał `acceptWaveForm`,
`get*Result`, `reset`, `close` i **budowę recognizera** wprost w
`onMethodCall`, czyli na głównym wątku:

- budowa recognizera z gramatyką ~3,3 tys. fraz trwa sekundy → ANR („Hi Bees
  nie odpowiada") przy wejściu na ekran głosu;
- `acceptWaveForm` idzie 5 razy na sekundę (porcje 0,2 s), a przy dyktowaniu
  notatki dwa razy tyle (recognizer notatki + detektor „hej maja") — na tym
  samym wątku, na którym rysuje się żywy podgląd korpusu.

Teraz wszystko przechodzi przez kolejkę **szeregową** `voskQueue`, a na główny
wątek wraca tylko gotowy wynik. To dokładnie ta poprawka, którą w lipcu dostał
iOS — obie platformy pracują wreszcie tak samo. Przy okazji
`result.error(..., details)` nie dostaje już obiektu wyjątku
(`StandardMessageCodec` nie umie go zakodować i zamiast błędu leciał błąd
kodowania błędu), tylko tekstowy ślad stosu.

## A2. Reguły R8 dla Voska i JNA

`packages/vosk_flutter_service/android/consumer-rules.pro` (nowy) + wpięcie
przez `consumerProguardFiles` w `android/build.gradle` wtyczki.

vosk-android nie ma własnego JNI — woła bibliotekę natywną przez **JNA, po
nazwach klas i metod**. W buildzie release (`minifyEnabled true`) R8 to
przemianowuje i głos pada na `UnsatisfiedLinkError`. **W debugu tego nie widać
w ogóle**, bo R8 tam nie działa.

Reguły jadą z wtyczką celowo — aplikacja nie musi o nich pamiętać.

## A3. `android/build.gradle` wtyczki

- usunięty własny `buildscript` z `com.android.tools.build:gradle:8.0.0` —
  wtyczka bierze teraz AGP z projektu głównego (działa i ze starym
  `app_plugin_loader.gradle`, i z deklaratywnym `settings.gradle`);
- usunięte `rootProject.allprojects { repositories }` — konfiguracja cudzego
  projektu z podprojektu; repozytoria deklarowane dla siebie;
- **`compileSdk` 33 → 35** ← *jedyna liczba w części A zależna od środowiska*.
  `androidx.appcompat:appcompat:1.7.0` wymaga ≥ 34 (metadane AAR), więc
  oryginał nie przechodził nawet konfiguracji. 35 wymaga AGP ≥ 8.6 — **przy
  starszym AGP zejdź do 34**.

## A4. Źródło audio pod Androida

`lib/helpers/vosk_engine.dart`, `_startStrumienia()`:

```dart
androidConfig: const AndroidRecordConfig(
  audioSource: AndroidAudioSource.voiceRecognition,
  muteAudio: false,
  speakerphone: false,
  audioManagerMode: AudioManagerMode.modeNormal,
),
```

- `voiceRecognition` zamiast domyślnego `DEFAULT` — jedyne źródło, przy którym
  Android obiecuje ścieżkę bez obróbki pod rozmowę (AGC, bramka szumów).
  Odpowiednik „surowego mikrofonu", który na iOS okazał się warunkiem
  działania; przy `DEFAULT` część producentów dokłada własne „ulepszenia".
- `muteAudio: false` — inaczej system wyciszyłby wszystkie strumienie na czas
  nagrywania, czyli odzywki Mai przez cały czas pracy ekranu.
- tryb audio i speakerphone bez zmian — tryb rozmowy włączyłby AEC, ale
  przerzucił dźwięk na słuchawkę przy uchu, a telefon leży na ulu.

⚠️ **Wymaga `record` 6.x** (klasa `AndroidRecordConfig` z tymi polami). Jeśli na
maszynie androidowej stoi starszy `record`, ten fragment się nie skompiluje —
wtedy albo podnieść pakiet, albo tymczasowo usunąć `androidConfig` (zostaje
domyślne źródło `DEFAULT`, czyli gorsze rozpoznawanie, ale działające).

## A5. Komunikat o zgodzie na mikrofon

`vosk_engine.dart` mówił „iOS: Ustawienia → Hi Bees → Mikrofon" niezależnie od
systemu. Teraz na Androidzie pokazuje ścieżkę androidową. To jedyny komunikat,
po którym nasłuch **nie wróci sam**, więc musi wskazywać właściwy ekran.

---

# CZĘŚĆ B — do zrobienia na maszynie androidowej

## B0. Dlaczego tego tu nie ma

Konfiguracja builda wynika wprost z **wersji pakietów w `pubspec.lock`**, a ten
plik jest na obu maszynach inny. Liczby wyliczone z locka tego repo (AGP 8.7.3,
Kotlin 2.1.0, `compileSdk` 35, `minSdk` 24) byłyby tam zgadywaniem. Zostawiam
metodę, nie wynik.

**Żeby to policzyć, potrzebuję z tamtej maszyny:** `pubspec.yaml` +
`pubspec.lock`, cały katalog `android/`, `.metadata` i wynik `flutter --version`.
Wtedy sprawdzę faktyczne wymagania każdej wtyczki, zamiast podnosić wszystko do
najnowszego.

## B1. Sprawdzić wymagania wtyczek (metoda)

Dla każdej wtyczki z Androidem w locku liczy się jej `android/build.gradle`:
`compileSdk`, `minSdk`, wersja AGP/Kotlina w `buildscript` i to, czy używa
`flutter.compileSdkVersion`. Najostrzejsze wymaganie wygrywa — build zatrzymuje
się na metadanych AAR, jeszcze przed kompilacją.

Z locka tego repo wychodziły np.: `jni`/`jni_flutter` → `compileSdk` 35,
`permission_handler_android` → 35, `url_launcher_android` i
`shared_preferences_android` → `minSdk` 24 + DSL Kotlina 2.x. **Na tamtym locku
może wyjść zupełnie co innego** — to tylko przykład, jak to wygląda.

## B2. Reguły R8 po stronie aplikacji

W `android/app/build.gradle` jest `minifyEnabled true` i `shrinkResources true`,
ale **nie ma `proguardFiles`** — R8 działa wyłącznie na regułach domyślnych
i tych, które dorzucają biblioteki. Do dopisania w `buildTypes.release`:

```gradle
proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
```

i nowy `android/app/proguard-rules.pro`:

```proguard
# Powiadomienia zaplanowane są zapisywane jako JSON i odtwarzane po restarcie
# telefonu; Gson mapuje je po nazwach pól, więc przemianowane klasy = ciche
# zniknięcie przypomnień.
-keep class com.dexterous.** { *; }

# Silnik i wtyczki Fluttera - wołane z kodu natywnego i przez rejestrator.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
```

Reguł dla Voska/JNA **tu nie powtarzać** — jadą z wtyczki (A2).

## B3. Model 50 MB poza kopią zapasową

Model Vosk ląduje w `files/vosk_models`
(`getApplicationSupportDirectory()` = `context.getFilesDir()`), a auto-backup
Androida obejmuje `files/` i ma **limit 25 MB na aplikację**. Po przekroczeniu
system przestaje robić kopię **całej** aplikacji — razem z bazą pasiek.

Dwa nowe pliki. `android/app/src/main/res/xml/backup_rules.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="file" path="vosk_models" />
    <exclude domain="root" path="app_flutter/nagrania" />
</full-backup-content>
```

`android/app/src/main/res/xml/data_extraction_rules.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="file" path="vosk_models" />
        <exclude domain="root" path="app_flutter/nagrania" />
    </cloud-backup>
    <device-transfer>
        <exclude domain="file" path="vosk_models" />
        <exclude domain="root" path="app_flutter/nagrania" />
    </device-transfer>
</data-extraction-rules>
```

Podpięcie w `<application>` w `AndroidManifest.xml`:

```xml
android:fullBackupContent="@xml/backup_rules"
android:dataExtractionRules="@xml/data_extraction_rules"
```

(`app_flutter/nagrania` to nagrania dyktowanych notatek —
`getApplicationDocumentsDirectory()` na Androidzie to `getDir("flutter")`.
Kasują się po 7 dniach, ale przy intensywnym dyktowaniu to dziesiątki MB.)

## B4. Rzeczy do sprawdzenia przy okazji

- **Uprawnienie `RECORD_AUDIO`** — jest w manifeście, sprawdzić przy scalaniu.
- **NDK** — jeśli w locku jest pakiet `jni` (wchodzi z `path_provider_android`),
  kompiluje kod natywny przez build hooks Darta i wymaga zainstalowanego NDK.
- **`package=` w manifestach** — AGP 8 tego atrybutu nie przyjmuje (zastąpiony
  przez `namespace` w `build.gradle`). Dotyczy też manifestu wtyczki Vosk, jeśli
  tamten projekt jest już na AGP 8.
- **Stara wada, warta poprawienia niezależnie od Androida:**
  `android/build.gradle` definiuje `keystoreProperties` i `flutterVersionCode`
  jako `def`, a używa ich `android/app/build.gradle`. Skrypty Gradle **nie dzielą
  zmiennych lokalnych**, więc te odwołania nigdy się nie rozwiązują — odczyt
  `local.properties` i `key.properties` musi być w `app/build.gradle`.
- **`targetSdk`** — Google Play wymaga dziś 35 przy nowych uploadach, a 35
  włącza wymuszony edge-to-edge Androida 15 (treść pod paskami systemowymi),
  czyli przebudowę układu każdego ekranu. Osobny temat, nie do wrzucenia razem
  z głosem.

---

# Checklist testów na telefonie z Androidem

Kolejność ma znaczenie — każdy punkt zakłada, że poprzedni przeszedł.

- [ ] **Build debug wchodzi na telefon** i apka startuje (weryfikuje część B).
- [ ] Ekran startowy pokazuje przycisk **Sterowanie głosem** (widoczny tylko
      przy języku polskim — `globals.jezyk == 'pl_PL'`).
- [ ] Wejście na ekran głosu: prośba o **zgodę na mikrofon**, po odmowie
      komunikat wskazuje ścieżkę androidową (A5).
- [ ] **Pobranie modelu** (~50 MB, tylko raz) kończy się, widać „Ładuję
      model...", potem „Buduję gramatykę komend...".
- [ ] **Ekran nie zawiesza się** przy budowie gramatyki — brak okna „Hi Bees
      nie odpowiada". To jest test poprawki A1.
- [ ] Ekran startuje **w poziomie**, żywy podgląd korpusu **płynnie się rysuje
      w trakcie nasłuchu** (drugi test A1 — dekodowanie nie może zabierać
      wątku UI).
- [ ] „Hej Maja start" otwiera sesję, odzywka Mai jest **słyszalna**.
- [ ] Odzywka **nie wraca do mikrofonu jako fraza**. Na iOS trzeba było na to
      ogona wyciszenia 300 ms; na Androidzie bufor wejścia jest inny i ta
      liczba może wymagać korekty (`_ogonWyciszenia` w `vosk_engine.dart`).
- [ ] Kilka komend zapisujących (np. „ciasto dwa kilogramy") — czy trafiają do
      bazy i czy **rozpoznawanie nie jest wyraźnie gorsze niż na iPhonie**.
      Jeśli jest — pierwszy podejrzany to źródło audio (A4).
- [ ] „Hej Maja cofnij ostatni zapis" przywraca stan.
- [ ] **Dyktowanie notatki** („notatka do notesu") — tekst leci na żywo,
      „hej maja" kończy, nagranie WAV da się odtworzyć przy notatce.
      Najcięższy tryb: dwa recognizery na jednej porcji.
- [ ] **Przerwanie mikrofonu**: zadzwoń na telefon w trakcie nasłuchu. Po
      odłożeniu słuchawki nasłuch ma wrócić **sam** (backoff do 15 s), w
      czuwaniu, nie w komendach.
- [ ] Przejście w tło i powrót — mikrofon wraca, ekran nie zostaje „żywy przy
      martwym mikrofonie".
- [ ] **BUILD RELEASE (podpisany!)** — instalacja i przejście całej ścieżki
      jeszcze raz. Jedyny test, który wykrywa złe reguły R8 (A2, B2).

# Znane, świadomie nierozwiązane

- **Sterowanie głosem po angielsku nie działa** — `vosk_engine.dart` pobiera
  bezwarunkowo `vosk-model-small-pl-0.22`. Dotyczy obu platform.
- **Pobranie modelu idzie przez pamięć.** `ModelLoader` wciąga cały zip
  (~50 MB) do RAM-u, rozpakowuje w pamięci i dopiero potem zrzuca na dysk —
  szczyt grubo ponad 100 MB. Na iPhonie przechodzi, na słabszym Androidzie może
  skończyć się ubiciem procesu przy PIERWSZYM uruchomieniu głosu. Gdyby padło:
  strumieniowy zapis do pliku (`extractFileToDisk` zamiast `decodeBytes` +
  `compute`) w `packages/vosk_flutter_service/lib/src/model_loader.dart`.
- **Rozmiar APK** — cztery ABI po ~10 MB `libvosk.so`. Przy `flutter build
  appbundle` Google Play rozdaje po jednym ABI, ale „gruby" APK z `build apk`
  będzie o ~40 MB większy.
- **`applicationId`** w tym repo to `pl.hi_bees`, a w sklepie stoi
  `eu.darys.heymaya` (link z `apiarys_screen.dart`) — jak jest w projekcie
  androidowym, do sprawdzenia na miejscu.

---

# RUNDA 2 (14.08.2026) — „«hej maja start» wchodzi, komendy już nie"

Zgłoszenie z testu na Samsungu SM-G930F (Galaxy S7): ekran głosu startuje,
„Hej Maja start" jest łapane, Maja mówi „czekam na polecenia" i **na tym
koniec** — żadna komenda nie przechodzi, a co jakiś czas wraca samo „czekam
na polecenia".

## Dlaczego z ekranu nic nie widać

Ekran produkcyjny **z założenia milczy** o odrzuconej frazie (`_opisFrazy`
w `voice_vosk_screen.dart`): fraza z `[unk]` to rozmowa przy ulu, a nie
nieudana komenda, więc meldunek po każdym zdaniu byłby szumem. Skutek uboczny:
CZTERY różne przyczyny wyglądają na ekranie identycznie.

| # | Przyczyna | Jak odróżnić |
|---|---|---|
| 1 | recognizer komend się nie podmienił (silnik karmi dalej gramatykę czuwania, 6 fraz) | w logu brak linii `tryb czuwanie -> komendy` |
| 2 | z mikrofonu nic nie płynie | `szczyt sygnału` < 0,02 → `CISZA Z MIKROFONU` |
| 3 | słychać, ale wszystko leci na `[unk]` albo na próg pewności | linie `fraza: … ODRZUCONA: …` |
| 4 | dekodowanie wolniejsze niż mowa, zaległość rośnie bez końca | `NIE NADĄŻAM` + rosnąca `zaległość` |

Punkt 4 jest podejrzany szczególnie mocno, bo dotyczy **wyłącznie trybu
komend**: graf dekodowania ma tam 3 343 frazy zamiast 6. Czuwanie działa,
komendy nie — to dokładnie ta granica.

## Co zostało dołożone

- `lib/helpers/vosk_engine.dart` — ślad diagnostyczny (`VOSK/ślad:` w logu),
  wyłącznik `_sladDiagnostyczny`. Loguje: który recognizer jest karmiony
  i ile ma fraz, każdą przełączkę trybu, każdą domkniętą frazę z werdyktem
  bramki (tekst → intent, unk, śr./min pewności) oraz co 10 s dźwięku raport
  tempa (ms na porcję, zaległość bufora, szczyt sygnału).
- `lib/helpers/vosk_engine.dart` — **realna poprawka:** `_przelaczGramatyke`
  zwraca `bool`, a `ustawTryb` przy niepowodzeniu **nie ustawia już `_tryb`**.
  Dotąd brak recognizera dawał ciche kłamstwo: silnik meldował „słucham
  komend", karmiąc dalej sześciofrazową gramatykę czuwania.
- `lib/screens/voice_settings_screen.dart` — przełącznik **Diagnostyka głosu**
  odkomentowany (był ukryty 06.08.2026). Do ponownego ukrycia po zamknięciu
  tematu Androida.

Oba pliki naniesione TAKŻE na `pliki/heymaya_14_08_26_po_aktualizacji/`
(z zachowaniem tamtejszych różnic: `package:heymaya`, nazwa „Hey Maya").

## Jak zebrać materiał na telefonie

1. Ustawienia → Sterowanie głosem → **Diagnostyka głosu = włączona**.
2. `flutter run` (debug wystarczy) z podłączonym telefonem, log leci do konsoli.
3. Wejść na ekran głosu, powiedzieć „hej maja start", potem **3–4 komendy
   z listy pomocy** (np. „ciasto dwa kilogramy"), odczekać ~30 s.
4. Przysłać CAŁE linie `VOSK/ślad:` z tego przebiegu.

Na ekranie przy włączonej diagnostyce widać to samo w skrócie: `pominięte:
„…" (powód)` albo `przyjęte: „…" → intent (śr. …, min …)`.

## Przy okazji: `flutter run --release` padał na keystore

`android/key.properties` wskazywał `storeFile` **ścieżką bezwzględną do starego
katalogu** (`/Users/darys/tools/apps/heymaya/heymaya-key.jks`), a projekt został
skopiowany gdzie indziej. Poprawione na ścieżkę względną:

```properties
storeFile=../../heymaya-key.jks
```

(`file()` w `android/app/build.gradle.kts` rozwiązuje względem `android/app/`,
a plik `heymaya-key.jks` leży w katalogu głównym projektu.)

Do testów diagnostycznych release nie jest potrzebny — ale przy `minifyEnabled
false` (tak jest dziś) release i tak nie sprawdza reguł R8, więc ten test
zostaje na koniec, po włączeniu zmniejszania kodu.

---

# RUNDA 3 (14.08.2026) — ROZSTRZYGNIĘTE: mikrofon pauzuje NASZA WŁASNA odzywka

Ślad z rundy 2 wskazał winowajcę w trzech linijkach logu z telefonu:

```
VOSK/ślad: fraza: „hej maja start" -> voiceStart | PRZYJĘTA
VOSK/ślad: tryb czuwanie -> komendy, karmię recognizer #2      <- sesja OTWARTA
... MediaPlayer gra „słucham" (1,7 s), po nim:
D/AudioManager: dispatching onAudioFocusChange(1) to ...record.recorder.AudioRecorder
VOSK/ślad: tryb wylaczony -> czuwanie, karmię recognizer #1    <- sesja MARTWA
```

Czyli **żadna z czterech kandydatek** (podmiana gramatyki, głuchy mikrofon,
[unk]/próg pewności, za wolne dekodowanie). Sesja komend otwierała się
poprawnie i ginęła pół sekundy później, a użytkownik mówił polecenia do
gramatyki znającej sześć fraz — stąd „czuwanie łapie, komendy nie".

## Mechanizm

1. Odzywka „słucham" leci przez MediaPlayer i **zabiera AUDIOFOCUS**.
2. Wtyczka `record` prosi o focus przy starcie nagrywania i wiesza na nim
   listenera. Ten na KAŻDEJ utracie focusa woła `pauseRecording()` —
   `record_android` 1.5.2, `recorder/AudioRecorder.kt` linia 244. Nie odróżnia
   cudzego dźwięku od naszego własnego.
3. Powrót focusa (`onAudioFocusChange(1)` = `AUDIOFOCUS_GAIN`, widoczny w logu)
   wznawia nagrywanie **wyłącznie w trybie `PAUSE_RESUME`** (linia 245).
   Domyślny `AudioInterruptionMode.pause` znaczy „pauzuj automatycznie, wznów
   ręcznie” → mikrofon zostawał zapauzowany **na zawsze**.
4. 3 s bez ani jednej porcji → watchdog → `_utraconoMikrofon` → `wstrzymaj()`
   + `wznow()`, a `wznow` z założenia wraca do **CZUWANIA** (decyzja
   z 01.08.2026: po przerwaniu użytkownik ma świadomie powiedzieć „hej maja
   start”).

Na iOS tego nie było, bo AVAudioSession nie zgłasza przerwania, gdy dźwięk gra
ta sama aplikacja.

## Poprawka

`lib/helpers/vosk_engine.dart`, `_startStrumienia` — w `RecordConfig`:

```dart
audioInterruption: Platform.isAndroid
    ? AudioInterruptionMode.none
    : AudioInterruptionMode.pause,
```

`none` = **nie prosimy o audio focus**, więc nikt nas nie pauzuje. Nic na tym
nie tracimy: rozmowę telefoniczną łapie cykl życia ekranu (`paused` →
`wstrzymaj`, `resumed` → `wznowOdNowa`), a naprawdę martwy strumień — watchdog.
iOS zostaje na przetestowanej ścieżce.

Dołożony też ślad `UTRATA MIKROFONU w trybie X (próba N): powód` w
`_utraconoMikrofon` — w logu z rundy 2 widać było wyłącznie SKUTEK („tryb
wylaczony -> czuwanie”), bez słowa o tym, że przed chwilą zginął mikrofon.

Oba pliki naniesione TAKŻE na `pliki/heymaya_14_08_26_po_aktualizacji/`.

## Test po poprawce

„hej maja start” → po odzywce „słucham” w logu MUSZĄ lecieć linie
`tempo komendy: … ms/porcję` (a nie `tempo czuwanie`) i NIE MOŻE pojawić się
`UTRATA MIKROFONU`. Wtedy komendy z listy pomocy powinny wchodzić normalnie.

## Drobiazg zauważony przy okazji (nie jest błędem)

Szczyt sygnału na tym telefonie to 0,02–0,03 przy mowie, czyli dokładnie na
progu `_progDzwieku = 0.02` — marker `<-- CISZA Z MIKROFONU` zapala się więc
także wtedy, gdy coś było powiedziane. Rozpoznanie działa (pewność 1,00), więc
progu na razie nie ruszamy; gdyby doszły zgłoszenia „nie słyszy”, to jest
pierwsze miejsce do zmierzenia.

---

# RUNDA 4 (14.08.2026) — po potwierdzeniu: dźwięk potwierdzenia i układ ekranu

Sterowanie głosem na Androidzie **działa, komendy wykonują się poprawnie**
(potwierdzone na telefonie). Zostały dwie rzeczy zgłoszone przy okazji testu.

## 4.1. Beep potwierdzenia: znowu dźwięk systemowy

**Zgłoszenie:** „nie podoba mi się `listening.wav` — czy można dźwięk systemowy
jak na iOS”.

Tło: na iOS gra `FlutterBeep.playSysSound`, a `flutter_beep` nie przechodzi
buildu od AGP 8 (brak `namespace`), więc na Androidzie zastępczo szedł nagrany
plik `assets/audio/listening.wav` przez `audioplayers`.

**Poprawka — bez wracania do `flutter_beep`:** własny `MethodChannel`
**`hej_maja/sygnal`**, obsługiwany po obu stronach:

| platforma | plik | co robi |
|---|---|---|
| Android | `android/app/src/main/kotlin/eu/darys/heymaya/MainActivity.kt` | `ToneGenerator` |
| iOS | `ios/Runner/AppDelegate.swift` (repo `hi_bees`) | `AudioServicesPlaySystemSound(1116)` |

To dokładnie to, co robił `flutter_beep` — cały ten pakiet to po jednym
wywołaniu systemowego API na platformę. **`flutter_beep` wypadł więc z OBU
projektów** (`pubspec.yaml` w `hi_bees` zaremowany z uzasadnieniem).

- **Dźwięk na iOS jest ten sam co dotąd:** `iOSSoundIDs.JBL_NoMatch`
  z `flutter_beep` to stała **1116**, podawana teraz wprost do
  `AudioServicesPlaySystemSound`.
- Android: `ToneGenerator.TONE_PROP_BEEP`, 150 ms, głośność 80/100. Zmiana tonu =
  jedna stała `tonPotwierdzenia` w `MainActivity.kt` (alternatywy wypisane
  w komentarzu obok).
- `SoundHelper.beep()` woła kanał, a `listening.wav` zostaje jako wyjście
  awaryjne (gdy kanał nie odpowie). Po pierwszej odmowie kanał nie jest już
  wołany — inaczej każde potwierdzenie kosztowałoby `MissingPluginException`.
- **Efekt uboczny na plus:** `audioplayers` prosi Androida o audio focus,
  a odebranie focusu pauzuje `record` — to dokładnie mechanizm z rundy 3.
  `ToneGenerator` o focus **nie prosi**, więc ta ścieżka znika z drogi
  mikrofonu, niezależnie od `AudioInterruptionMode.none`.

⚠️ Po tej zmianie w `hi_bees` trzeba lokalnie zrobić **`flutter pub get`
i `pod install`** — `flutter_beep` znika z `pubspec.lock`, `Podfile.lock`
i `GeneratedPluginRegistrant`.

Do sprawdzenia na telefonie: sygnał po komendzie ma być krótki i systemowy,
a po nim komendy mają dalej wchodzić bez przerwy (żadnego `UTRATA MIKROFONU`).
Na iPhonie: sygnał ma brzmieć **identycznie jak przed zmianą**.

## 4.2. Ekran sterowania głosem na małych ekranach

**Zgłoszenie:** w POZIOMIE (iOS) brane są duże rozmiary i elementy wchodzą na
siebie; na Samsungu w PIONIE też się nie mieści.

Przyczyna: wariant „mały" wierszy strefy 1 wybierał warunek powtórzony
dziewięć razy w `voice_vosk_screen.dart`:

```dart
heightScreen < 590 && orientation == portrait && !globals.voice2LiveLandscape
```

czyli **wysokość całego ekranu**, z liczbą zgadniętą z dwóch urządzeń, i to
z jawnym wykluczeniem poziomu.

**Poprawka (naniesiona na oba drzewa — `hi_bees` i `heymaya`):**

1. Jedno pole `_maleWiersze`, liczone raz w `LayoutBuilder`:
   - **każdy układ poziomy** → wariant mały (to była prośba wprost);
   - w pionie → mały, gdy układ duży **nie mieści się w wysokości, którą
     naprawdę dostała treść** (`wymiary.maxHeight`), zamiast progu 590 px.
     Próg liczy się ze stałych stref (`371 + 254 + 2 + 64` z live podglądem,
     `371 * 6/4` w układzie klasycznym), więc idzie za układem, a nie za listą
     urządzeń.
   - do rachunku wchodzi **skala czcionki systemowej** (`MediaQuery.textScalerOf`):
     pudełka mają stałe wysokości, a teksty w nich rosną razem z ustawieniem
     „rozmiar czcionki” — na Androidzie podniesionym częściej niż na iOS.
2. Wiersz „ul / korpus / półkorpus / ramka" ma sztywne szerokości pudełek
   (80–100 px każde) i `spaceEvenly`, który przy braku miejsca **nie zwęża, tylko
   pozwala im wyjść poza kontener** — stąd nachodzenie w poziomie, gdzie strefa 1
   to lewa POŁOWA ekranu (na małym iPhonie ok. 250 px na 260–300 px pudełek).
   Nowe `_dopasujWiersz` zostawia wiersz nietknięty, dopóki się mieści, a gdy
   zabraknie szerokości — skaluje go w dół (`FittedBox`), więc pudełka stykają
   się bokami i są niższe, ale **wszystkie są w całości widoczne**.

**Rachunek dla Galaxy S7 (SM-G930F), czyli telefonu z testów:** 1440 x 2560 px
przy `devicePixelRatio` 4 = **360 x 640 punktów logicznych**. Stary warunek:
640 > 590 → wariant DUŻY. Nowy: treść dostaje 640 − 24 (pasek stanu) − 56 (pasek
tytułu) ≈ **560 px**, a układ duży potrzebuje 691 → wariant MAŁY, i to bez
skalowania stref (mały mieści się w 624). W poziomie lewa kolumna ma
640/2 − 30 ≈ 290 px: trzy pudełka duże to 300 px (nachodziły), małe 260 px
(mieszczą się). Zgadza się z obydwoma zgłoszeniami.

Do sprawdzenia na telefonie: pion i poziom, z otwartym ulem i korpusem
(najszerszy wiersz), na Samsungu i na małym iPhonie.

---

# RUNDA 5 (15.08.2026) — „na Androidzie i tak gra `listening.wav`"

**Zgłoszenie:** po komendzie nie słychać dźwięku systemowego, tylko nagrany
plik — kiepskiej jakości, co jakiś raz z trzaskiem na początku.

**Co to znaczy dosłownie:** `SoundHelper.beep()` sięga po plik WYŁĄCZNIE wtedy,
gdy kanał `hej_maja/sygnal` nie powie „zagrałem". Skoro słychać plik, to albo
(a) kanału w tym buildzie nie ma, albo (b) `ToneGenerator` odmówił. Z telefonu
oba przypadki brzmią identycznie — i to była pierwsza rzecz do naprawienia.

Sam plik jest niewinny: `listening.wav` to czysta sinusoida 433 Hz, 0,15 s,
44,1 kHz mono, zaczyna się i kończy na zerze (sprawdzone). Trzask bierze się
z rozruchu odtwarzacza `audioplayers`, nie z nagrania — czyli nie da się go
wyleczyć zmianą pliku. Dlatego celem zostaje dźwięk systemowy.

## 5.1. Co poprawione w `MainActivity.kt`

1. **Honorujemy wynik `startTone`.** Metoda zwraca `boolean` i potrafi oddać
   `false` bez rzucania wyjątku (zajęta ścieżka audio). Dotąd kanał raportował
   sukces zawsze, gdy nie poleciał wyjątek — więc „gra plik" znaczyło, że poległ
   już sam **konstruktor** `ToneGenerator` („Init failed", brak wolnej ścieżki).
2. **Trzy podejścia zamiast jednego:** `STREAM_MUSIC` → `STREAM_SYSTEM` →
   `STREAM_NOTIFICATION`, a gdy wszystkie odmówią —
   `AudioManager.playSoundEffect(FX_KEY_CLICK)`. Ten ostatni gra w **procesie
   systemowym**, więc nie zużywa naszej ścieżki audio ani focusa; jest cichy
   tylko wtedy, gdy w telefonie wyłączono „dźwięki dotyku" (opis to mówi).
   Strumienia nie da się zmienić po utworzeniu generatora — przy zmianie stary
   jest zwalniany.
3. **Odpowiedź tekstowa zamiast `true`/`false`.** Kontrakt: odpowiedź zaczynająca
   się od `ok` = „zagrałem, nie sięgaj po plik". Cokolwiek innego to powód
   porażki, np. `brak: ToneGenerator media: Init failed | startTone=false na
   system | ...`.

## 5.2. Co poprawione po stronie Darta

- `SoundHelper.beep()` czyta odpowiedź jako `Object` (Android oddaje tekst, iOS
  `true` albo — po zmianie w `AppDelegate.swift` — też tekst) i zapisuje ją
  w polu **`ostatniSygnal`**.
- **Kanał gaśnie na stałe tylko przy `MissingPluginException`**, czyli gdy
  natywnej strony w buildzie NIE MA. Zwykła odmowa dźwięku już go nie gasi —
  do 14.08.2026 jedna nieudana próba skazywała całą sesję na plik z dysku.
- Nowa pozycja **„Sygnał potwierdzenia komendy"** w Ustawieniach → Sterowanie
  głosem: dzwonek po prawej gra sygnał i wypisuje pod tytułem, czym zagrał.
  To jedyny sposób, żeby rozstrzygnąć zgłoszenie bez kabla i `logcat`.
- Zapasowy plik można podmienić bez ruszania kodu: wrzucić
  `assets/audio/beep.mp3` i odkomentować jego linię w `pubspec.yaml`
  (`SoundHelper._plikSygnaluWlasny`). Gdy pliku nie ma — wraca `listening.wav`.

## 5.3. Test na telefonie (w tej kolejności)

1. **Pełny rebuild**, nie hot restart — kanał wpina się przy tworzeniu silnika
   Fluttera, więc hot restart go nie doda.
2. Ustawienia → Sterowanie głosem → dzwonek przy „Sygnał potwierdzenia komendy".
   Odczytać opis:
   - `ok: ton na media` → działa, tak ma być;
   - `ok: ton na system` / `ok: efekt systemowy` → działa, ale ścieżka mediów
     jest zajęta — warto zapisać, na jakim telefonie;
   - `brak kanału natywnego …` → **build jest stary**, wrócić do punktu 1;
   - `brak: …` → treść mówi, co odmówiło; wtedy dopiero temat własnego mp3.
3. Dopiero potem próba głosem: sygnał ma być krótki i systemowy, a komendy mają
   dalej wchodzić bez przerwy (żadnego `UTRATA MIKROFONU`).

Zmiany naniesione na **oba drzewa** (`hi_bees` i `pliki/heymaya_…`);
w `hi_bees` kanał dostał też `android/app/src/main/kotlin/.../MainActivity.kt`,
który dotąd był pusty.
