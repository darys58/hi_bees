# Upgrade do Xcode 26 / iOS 26 SDK — checklist

**Status na dzień 2026-04-29:** deadline Apple (28.04.2026) **już minął**.
Nowe uploady do App Store Connect wymagają iOS 26 SDK (Xcode 26+).

**Stan wyjściowy:**
- macOS 15.4.1 Sequoia
- Xcode 16.4
- Flutter 3.27.4
- Hi Bees 1.10.20.90

---

## Co już zostało przygotowane w repo (zrobione w kontenerze)

- [x] `pubspec.yaml` — Dart SDK `>=3.5.0 <4.0.0`, Flutter `>=3.32.0`
- [x] `ios/Podfile` — `platform :ios, '15.0'` + `post_install` wymusza 15.0 na podach
- [x] `ios/Runner.xcodeproj/project.pbxproj` — wszystkie 6 wystąpień `IPHONEOS_DEPLOYMENT_TARGET` ujednolicone na 15.0
- [x] `ios/Runner/PrivacyInfo.xcprivacy` — utworzony manifest prywatności (UserDefaults, FileTimestamp, SystemBootTime, DiskSpace)

⚠️ **`PrivacyInfo.xcprivacy` trzeba dodać do projektu Xcode ręcznie**: w Xcode prawym → "Add Files to Runner..." → wskaż `Runner/PrivacyInfo.xcprivacy` → zaznacz target Runner.

---

## Krok 1: Zabezpieczenie pracy (Mac)

```bash
# W repo:
cd ~/path/to/hi_bees
git status                    # sprawdź co jest niezacommitowane
git fetch --all
git checkout -b xcode-26-upgrade   # branch izolacyjny
```

- [ ] Time Machine backup całego Maca (1-2h, ale niezbędny)
- [ ] Kopia obecnego `/Applications/Xcode.app` na zewnętrzny dysk LUB zmień nazwę na `Xcode-16.4.app` przed instalacją nowego (pozwoli wrócić do wersji 16.4 bez App Store)
- [ ] Branch `xcode-26-upgrade` utworzony i pushed na origin

---

## Krok 2: Upgrade macOS Sequoia → Tahoe

**Xcode 26 wymaga macOS 26 Tahoe.** Sequoia 15.4.1 nie wystarczy.

- [ ] System Settings → General → Software Update → upgrade do macOS 26 Tahoe
- [ ] Po upgrade: zweryfikuj `sw_vers`
- [ ] Restart i sprawdź czy obecny Xcode 16.4 jeszcze działa (`xcodebuild -version`)

> Jeśli Tahoe jeszcze nie wyszło / nie jest dostępne na danym sprzęcie — sprawdź czy Xcode 26 ma beta channel działający na Sequoia.

---

## Krok 3: Instalacja Xcode 26

- [ ] Mac App Store → pobierz Xcode 26 (~15 GB)
- [ ] Po instalacji: `sudo xcode-select -s /Applications/Xcode.app`
- [ ] `xcodebuild -version` → potwierdź Xcode 26
- [ ] `sudo xcodebuild -license accept`
- [ ] `xcodebuild -downloadAllPlatforms` (lub w Xcode → Settings → Platforms → iOS 26 download)
- [ ] Otwórz Xcode 26 raz osobno żeby zaakceptował CLI tools

---

## Krok 4: Upgrade Flutter

```bash
flutter upgrade           # do najnowszego stable 3.32+ (na kwiecień 2026)
flutter --version         # potwierdź
flutter doctor -v         # wszystkie zielone
```

- [ ] `flutter --version` → 3.32.x lub nowszy
- [ ] `flutter doctor -v` → Xcode 26 wykryty, brak błędów
- [ ] Jeśli Flutter wykrzaczy się o brak Dart 3 → usuń stary cache: `flutter clean`

---

## Krok 5: Synchronizacja zależności

```bash
cd ~/path/to/hi_bees
flutter clean
flutter pub get
flutter pub outdated      # zobacz co jest do aktualizacji
```

### Pakiety priorytetowe do bumpowania (zweryfikuj wersje aktualne na pub.dev)

| Pakiet | Obecna | Ryzyko iOS 26 | Sugestia |
|--------|--------|---------------|----------|
| `picovoice_flutter` | ^3.0.3 | **WYSOKIE** — natywny iOS, może nie kompilować się ze Swift 6 | Sprawdź pub.dev, prawdopodobnie 3.x → najnowszy 3.x lub 4.x |
| `flutter_local_notifications` | ^17.2.4 | **WYSOKIE** — duże zmiany API w 18+ i 19+ | Bump do 19.x, sprawdź migration guide |
| `nfc_manager` | ^3.5.0 | Średnie | Bump jeśli dostępny |
| `image_picker` | ^1.0.7 | Średnie — privacy manifest | Bump do 1.1.x+ |
| `share_plus` | ^10.1.4 | Niskie | Może bump do 11.x |
| `flutter_map` | ^6.2.1 | Średnie | 8.x dostępny — ale to API breaking |
| `fl_chart` | ^0.70.1 | Niskie | Opcjonalny bump |
| `intl` | ^0.19.0 | **WYSOKIE** — Flutter 3.32+ często wymaga 0.20.x | Bump do 0.20.x |
| `device_info_plus` | ^11.2.0 | Niskie | OK |
| `connectivity_plus` | ^6.1.1 | Niskie | OK |

```bash
flutter pub upgrade --major-versions   # rozważ — ale przegląda się ręcznie!
```

- [ ] `intl` zaktualizowany (najczęściej wymagany)
- [ ] `picovoice_flutter` zaktualizowany — **przetestuj voice_screen2 dokładnie**
- [ ] `flutter_local_notifications` zaktualizowany — **przetestuj powiadomienia**
- [ ] `flutter pub get` przechodzi bez konfliktów

---

## Krok 6: CocoaPods

```bash
cd ios
pod repo update
pod deintegrate
pod install --repo-update
cd ..
```

- [ ] Brak warningów o deployment target
- [ ] `Podfile.lock` zaktualizowany (zacommit go!)
- [ ] Otwórz `Runner.xcworkspace` (NIE `.xcodeproj`!) w Xcode 26

---

## Krok 7: PrivacyInfo.xcprivacy w Xcode

- [ ] Xcode 26 → Project navigator → prawym na `Runner` → Add Files to "Runner"...
- [ ] Wskaż `ios/Runner/PrivacyInfo.xcprivacy` → zaznacz target **Runner** → Add
- [ ] Sprawdź czy plik pojawia się w Build Phases → Copy Bundle Resources

---

## Krok 8: Build i sanity check

```bash
flutter build ios --release --no-codesign
```

Najczęstsze błędy i rozwiązania:

- **"Module 'X' was not compiled with library evolution support"**
  → bump pakiet, czasem pomoże usunięcie `Pods/` i ponowne `pod install`
- **"The Swift language version (Swift X) is not supported"**
  → w pbxproj któryś target ma stary `SWIFT_VERSION` — ujednolić na `5.0` lub `6.0`
- **"Bitcode is no longer supported"**
  → usuń wszystkie `ENABLE_BITCODE = YES` z pbxproj (powinny już być NO)
- **Picovoice: "Symbol not found / undefined"**
  → wymagany bump pakietu, ewentualnie zaktualizować wersje contextów (.rhn) jeśli ABI się zmieniło
- **flutter_local_notifications: brak DarwinInitializationSettings**
  → migracja API z 17 → 19, sprawdź ich CHANGELOG

---

## Krok 9: Test na fizycznym urządzeniu

- [ ] iPhone podłączony przez kabel
- [ ] `flutter run --release` na iPhone
- [ ] Test golden path:
  - [ ] Logowanie/aktywacja
  - [ ] Nowa pasieka, nowy ul, ramka
  - [ ] **Voice control "Hey Maya!"** — krytyczne, najczęstsze regresje
  - [ ] Powiadomienia (kalendarz)
  - [ ] Pogoda
  - [ ] PDF (raporty)
  - [ ] NFC
  - [ ] Aparat (zdjęcia uli)
  - [ ] Import/eksport z chmury
- [ ] Sprawdź na obu językach (PL/EN minimum, idealnie też nowe DE/FR/ES/IT/PT)

---

## Krok 10: Archive i upload do TestFlight

- [ ] Bump wersji w `apiarys_screen.dart` i `pubspec.yaml` (np. 1.10.21.91)
- [ ] Xcode → Product → Scheme → Edit Scheme → Run → Build Configuration: **Release**
- [ ] Xcode → Product → Archive
- [ ] Po archiwizacji: Distribute App → App Store Connect → Upload
- [ ] Walidacja **musi** przejść (tu wyjdzie czy PrivacyInfo.xcprivacy jest OK)
- [ ] TestFlight: nowa wersja widoczna → testuj na realnym urządzeniu z TestFlight

---

## Krok 11: Cleanup po sukcesie

```bash
git checkout main
git merge xcode-26-upgrade
git push
git tag v1.10.21
git push --tags
```

---

## BLOKADA (05.08.2026): `objective_c.framework` — ROZWIĄZANA

> **Status 05.08.2026 (wieczór): naprawione i potwierdzone na urządzeniu.**
> Po skasowaniu zatrutego stagingu (`rm -rf build/native_assets build/ios
> .dart_tool/flutter_build`) framework w `Runner.app` jest **arm64**, a apka
> instaluje się i startuje na fizycznym iPhone. Sekcja zostaje jako opis
> przyczyny — procedura z „Naprawa" obowiązuje przy KAŻDYM przełączeniu
> urządzenie ↔ symulator.

Po upgrade apka **nie instalowała się ani na fizycznym iPhone 15, ani nie
startowała na symulatorze** — oba błędy dotyczyły tej samej biblioteki:

| Cel | Błąd |
|-----|------|
| iPhone 15 (iOS 26.5.2), Xcode | `Failed to verify code signature of .../Frameworks/objective_c.framework : 0xe8008014 (The executable contains an invalid signature.)` |
| Symulator iPhone 15 (iOS 17.5) | `dlopen(objective_c.framework/objective_c): fat file, but missing compatible architecture (have 'arm64', need 'x86_64')` |

### Przyczyna: intelowy Mac + wspólny katalog przejściowy native assets

**To JEDNA przyczyna, nie dwie osobne usterki.** `objective_c` to zależność
przechodnia `record` 6.x (przez `record_ios`). To pakiet FFI — jego framework
buduje **pipeline native assets Darta** (`hooks`, `code_assets`,
`native_toolchain_c` w `pubspec.lock`), a nie CocoaPods. Dlatego wysypuje się
dokładnie ten JEDEN framework, a wszystkie pody podpisują się poprawnie.

Pipeline wystawia gotowy framework do **jednego katalogu
`build/native_assets/ios/`, wspólnego dla urządzenia i symulatora** — nie ma
osobnego `iphoneos` i `iphonesimulator`. Wygrywa architektura tego celu, który
budował się jako ostatni.

**Ten Mac jest intelowy** (rozstrzygnięte 05.08.2026: `sysctl -n
sysctl.proc_translated` → `unknown oid`, co na Apple Silicon jest niemożliwe —
tam klucz zawsze zwraca 0 albo 1; dodatkowo brak pozycji „Otwórz w Rosetcie"
w ⌘I). Nie ma tu żadnej Rosetty — `arch` → `i386`, `uname -m` → `x86_64`,
x86_64 `dart` i `darwin-x64` w `flutter devices` to **poprawny, natywny** stan
na tym sprzęcie.

Skutek: symulator jest **zawsze** celem `ios_x64`, a urządzenie **zawsze**
`ios_arm64`. Kolizja we wspólnym stagingu zachodzi więc przy KAŻDYM
przełączeniu celu — to stan trwały, nie pech jednego builda. Na Apple Silicon
oba cele są arm64, dlatego ten błąd jest w sieci prawie nieopisany.

**Dowód z artefaktów builda (05.08.2026):**

```
build/native_assets/ios/objective_c.framework/objective_c   05.08 11:55  x86_64  ← staging
build/ios/Release-iphoneos/…/objective_c.framework/…        05.08 11:55  x86_64  ← iPhone!
build/ios/Debug-iphoneos/…/objective_c.framework/…          04.08 11:56  arm64   ← udany test
build/ios/Debug-iphonesimulator/Runner.app/Runner           05.08 11:48  x86_64
build/ios/Debug-iphonesimulator/…/objective_c.framework/…   04.08 12:34  arm64
```

W `.dart_tool/flutter_build/*/native_assets.json` obok `ios_arm64` widnieje
**`ios_x64`**; `.dart_tool/native_assets.yaml` melduje host jako `macos_x64`
(na intelowym Macu to wartość poprawna).

**Przebieg:**

1. **04.08 11:56** — build na iPhone, framework arm64 → działa („test na urządzeniu OK").
2. **05.08 11:48** — symulator (x86_64): Runner x86_64, ale w Runner.app wciąż arm64-owy framework z 4.08 → `dlopen: have 'arm64', need 'x86_64'`.
3. **05.08 11:55** — `flutter pub get` unieważnia cache hooka; przebudowa dla celu `ios_x64` **nadpisuje wspólny staging** x86_64-em.
4. **05.08 11:55 / 12:30** — build `Release-iphoneos` kopiuje zatruty staging: x86_64 framework w arm64-owej apce → `0xe8008014`.

**Wersje pakietów są niewinne.** `pubspec.lock` jest w gicie niezmieniony od
commitów `37ae5e2` / `d32e111` / `81a6a2d`, a każdy z nich przeszedł test na
urządzeniu: `record` 6.2.1, `objective_c` 9.3.0, `hooks` 1.0.3, `code_assets` 1.0.0.

### Naprawa

**1. Skasować zatruty staging** — to jedyna realna naprawa:

```bash
rm -rf build/native_assets build/ios .dart_tool/flutter_build
```

**2. Zbudować na urządzenie** i sprawdzić architekturę bez odpalania:

```bash
flutter run --debug     # z podłączonym iPhone'em
file build/ios/Debug-iphoneos/Runner.app/Frameworks/objective_c.framework/objective_c
# ma być arm64
```

**3. Powtarzać krok 1 przed KAŻDYM przełączeniem urządzenie ↔ symulator.**
Dopóki staging jest wspólny, a cele mają różne architektury (na Intelu zawsze
mają), przeciek architektury wróci. Najprościej: pracować tylko na urządzeniu
albo tylko na symulatorze, a przy zmianie czyścić.

### Czego NIE robić przy tej diagnozie

- **Nie szukaj Rosetty.** Sprawdzone 05.08.2026 — Mac jest intelowy, Rosetty nie
  ma i nie było. `arch` → `i386` to normalny output na Intelu, NIE dowód Rosetty;
  rozstrzyga wyłącznie `sysctl -n sysctl.proc_translated` (na Apple Silicon
  zwraca 0/1, na Intelu „unknown oid"). Nie przeinstalowuj Fluttera na
  `macos_arm64` — na tym sprzęcie by nie działał.
- **Nie schodź na `record: 5.2.1`.** Te same wersje działały 4.08 — pakiet nie jest winny.
- **Nie ruszaj podpisów.** W `project.pbxproj` stoi jeszcze
  `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Developer"` (dziś: Apple Development),
  ale Xcode mapuje tę nazwę sam, a tą samą tożsamością podpisały się poprawnie
  binarka apki, `Flutter.framework` i wszystkie pody. Zła tożsamość wywaliłaby
  CAŁE podpisywanie („no signing certificate found"), a nie jeden framework.
  `0xe8008014` to skutek złej architektury, nie złego certyfikatu.

---

## Plan B — jak wrócić jeśli coś pójdzie nie tak

1. `git checkout main` (wracasz do stanu przed upgrade)
2. Usuń Xcode 26 z `/Applications/`
3. Przywróć `Xcode-16.4.app` → `Xcode.app`
4. `sudo xcode-select -s /Applications/Xcode.app`
5. Time Machine restore — jeśli macOS Tahoe sprawia problemy
6. Stary `flutter` z `~/development/flutter_3.27.4_backup/` (jeśli zachowałeś)

> **Ważne:** trzymaj `xcode-26-upgrade` jako branch dopóki nie potwierdzisz że App Store Connect zaakceptował upload. Nie merguj do main pochopnie.

---

## Czego NIE robić

- ❌ Nie aktualizuj wszystkich pakietów na raz (`flutter pub upgrade --major-versions`) bez przeglądu — łatwo o niekompatybilności
- ❌ Nie usuwaj `ios/Pods/` z gita ręcznie — `pod install` to zrobi
- ❌ Nie commituj `ios/build/` ani `Pods/` (powinny być w .gitignore)
- ❌ Nie zapominaj o backup'ie projektowanej wersji opublikowanej (`wersja` w `apiarys_screen.dart`)
