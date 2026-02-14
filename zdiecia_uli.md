# Zdjęcia uli w czasie przeglądów

## Wymagania użytkownika (14.02.2026)

- Po wybraniu ula, w kategorii **inspection**, pod ikonami kategorii (tam gdzie w innych kategoriach są statystyki) mają pojawić się:
  - **Przycisk do zrobienia zdjęcia** (aparat)
  - **Przycisk do pobrania zdjęcia z biblioteki** telefonu
- Po wykonaniu/pobraniu zdjęcia:
  - Wyświetla się **miniatura zdjęcia** z **datą wykonania** pod nią
- Po kliknięciu w miniaturę:
  - Wyświetla się **zdjęcie w pełnym rozmiarze**
  - Możliwość **skasowania** zdjęcia
  - Możliwość **udostępnienia** (tak jak PDF-y w aplikacji)
  - Przycisk **wyjścia** z podglądu

---

## Propozycja implementacji

### 1. Nowa zależność w `pubspec.yaml`

```yaml
image_picker: ^1.0.7   # do robienia zdjęć i wybierania z galerii
```

Pakiet `image_picker` obsługuje zarówno aparat jak i galerię na iOS i Android. Pakiety `share_plus` (udostępnianie) i `path_provider` (ścieżki plików) już są w projekcie.

### 2. Przechowywanie zdjęć

**Pliki zdjęć** — w katalogu aplikacji na urządzeniu:
```
<app_documents_directory>/photos/<pasiekaNr>_<ulNr>_<timestamp>.jpg
```
- Zdjęcia są kompresowane przez `image_picker` przy pobraniu (maxWidth: 1200px)
- Miniatura generowana nie jest potrzebna — Flutter `Image.file()` z parametrem `fit` i małym rozmiarem wystarczy

**Metadane zdjęć** — nowa tabela `zdjecia` w SQLite:

| Kolumna      | Typ     | Opis                              |
|--------------|---------|-----------------------------------|
| id           | TEXT PK | unikalny identyfikator            |
| data         | TEXT    | data wykonania (YYYY-MM-DD)       |
| czas         | TEXT    | godzina wykonania (HH:MM)        |
| pasiekaNr    | INTEGER | numer pasieki                     |
| ulNr         | INTEGER | numer ula                         |
| sciezka      | TEXT    | ścieżka do pliku zdjęcia         |
| uwagi        | TEXT    | opcjonalny opis                   |
| arch         | INTEGER | 0=aktywne, 1=wysłane, 2=import   |

### 3. Nowe pliki

| Plik | Opis |
|------|------|
| `lib/models/photo.dart` | Model Photo + Provider Photos |
| Metody w `lib/helpers/db_helper.dart` | CRUD dla tabeli `zdjecia` |

### 4. Zmiany w istniejących plikach

| Plik | Zmiana |
|------|--------|
| `pubspec.yaml` | Dodanie `image_picker` |
| `lib/helpers/db_helper.dart` | Nowa tabela `zdjecia` + metody CRUD + podniesienie wersji bazy |
| `lib/main.dart` | Rejestracja providera `Photos` w `MultiProvider` |
| `lib/screens/infos_screen.dart` | Sekcja zdjęć w kategorii inspection (przyciski + galeria miniatur + podgląd) |
| `ios/Runner/Info.plist` | Uprawnienia do aparatu i galerii (NSCameraUsageDescription, NSPhotoLibraryUsageDescription) — **do sprawdzenia czy już są** |

### 5. Architektura UI w `infos_screen.dart`

```
[Ikony kategorii: inspection, equipment, colony, queen, harvest, feeding, treatment]

── jeśli wybranaKategoria == 'inspection' ──

[Row]
  [ElevatedButton z ikoną aparatu — "Zrób zdjęcie"]
  [ElevatedButton z ikoną galerii — "Z biblioteki"]

[GridView / Wrap — galeria miniatur]
  [Column]
    [GestureDetector → otwiera podgląd]
      [Image.file() — miniatura 80x80]
    [Text — data "DD.MM.YYYY"]
  ...kolejne zdjęcia...

── koniec sekcji inspection ──

[Lista wpisów info jak dotychczas]
```

### 6. Podgląd zdjęcia (Dialog / nowy ekran)

Po kliknięciu w miniaturę — `showDialog` lub `Navigator.push` z:
- Zdjęcie na pełny ekran (`InteractiveViewer` do zoomowania)
- Dolny pasek z przyciskami:
  - **Udostępnij** — `Share.shareXFiles([XFile(sciezka)])` (pakiet `share_plus`)
  - **Usuń** — potwierdzenie → kasowanie pliku + rekordu z bazy
  - **Zamknij** — powrót

### 7. Uprawnienia platformowe

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Aplikacja potrzebuje dostępu do aparatu aby robić zdjęcia uli</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Aplikacja potrzebuje dostępu do zdjęć aby wybrać zdjęcie ula</string>
```

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

---

## Status

- [x] Analiza wymagań
- [x] Propozycja architektury
- [x] Akceptacja użytkownika
- [x] Implementacja
- [ ] Testy lokalne

---

## Zmodyfikowane pliki

| Plik | Zmiana |
|------|--------|
| `pubspec.yaml` | Dodano `image_picker: ^1.0.7` |
| `lib/models/photo.dart` | **NOWY** — model Photo + provider Photos |
| `lib/helpers/db_helper.dart` | Tabela `zdjecia` w onCreate + onUpgrade (wersja 2→3), metody `getPhotosOfHive()` i `deletePhoto()` |
| `lib/main.dart` | Import `photo.dart`, rejestracja `Photos()` w MultiProvider |
| `lib/screens/infos_screen.dart` | Importy (dart:io, image_picker, path_provider, share_plus, photo.dart), zmienne `_photos` i `_picker`, metody `_loadPhotos()`, `_pickImage()`, `_showPhotoPreview()`, sekcja UI z przyciskami i galerią miniatur |
| `ios/Runner/Info.plist` | Dodano `NSCameraUsageDescription` i `NSPhotoLibraryUsageDescription` |
| `android/app/src/main/AndroidManifest.xml` | Dodano `CAMERA` permission i `camera` feature |

---

## Dziennik działań

| Data | Działanie |
|------|-----------|
| 14.02.2026 | Użytkownik opisał wymagania dot. zdjęć uli w przeglądach |
| 14.02.2026 | Analiza kodu: infos_screen.dart, db_helper.dart, pubspec.yaml, modele |
| 14.02.2026 | Przygotowanie propozycji implementacji |
| 14.02.2026 | Akceptacja użytkownika |
| 14.02.2026 | Implementacja: pubspec.yaml — dodano image_picker |
| 14.02.2026 | Implementacja: db_helper.dart — tabela zdjecia, wersja bazy 3, metody CRUD |
| 14.02.2026 | Implementacja: lib/models/photo.dart — nowy model i provider |
| 14.02.2026 | Implementacja: main.dart — rejestracja providera Photos |
| 14.02.2026 | Implementacja: infos_screen.dart — UI: przyciski aparat/galeria, galeria miniatur, podgląd pełnoekranowy z udostępnianiem i usuwaniem |
| 14.02.2026 | Implementacja: Info.plist + AndroidManifest.xml — uprawnienia aparatu i galerii |
