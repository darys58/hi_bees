# Historia ula - notatki z prac

## Propozycja rozwiązania (13.02.2026)

### Opis funkcjonalności

Generowanie PDF z historią wybranego ula za wybrany rok. PDF zawiera tabelkę ze wszystkimi wpisami z tabeli INFO dla danego ula, ze WSZYSTKICH kategorii (inspection, equipment, colony, queen, harvest, feeding, treatment) z wybranego roku.

### Uruchomienie

- **Ikona:** `Icons.picture_as_pdf` w AppBar `infos_screen.dart`
- **Pozycja:** za ikoną statystyk (`Icons.query_stats`), jako trzecia ikona w actions
- **Zakres danych:** rok z `globals.rokStatystyk` (wybrany w statystykach)

### Struktura PDF

1. **Tytuł (wycentrowany, bold, 16pt):**
   - `"Historia ula nr X w roku YYYY"` - gdy wybrany konkretny rok
   - `"Historia ula nr X"` - gdy rok = "wszystkie"

2. **Data wygenerowania (wycentrowana, 10pt):**
   - Format zależny od locale (pl/en)

3. **Tabela - 7 kolumn:**

| Kolumna | Nagłówek | Szerokość | Opis |
|---------|----------|-----------|------|
| 0 | L.p. | Fixed(22) | Numer porządkowy |
| 1 | **Kat.** | Fixed(28) | **Ikonka kategorii (PNG z assets, bez tła)** |
| 2 | Data | Fixed(55) | Data wpisu |
| 3 | Czas | Fixed(32) | Godzina wpisu |
| 4 | Temp. | Fixed(30) | Temperatura (°C) |
| 5 | Informacja | Flex(2) | `parametr wartosc` |
| 6 | Uwagi | Flex(3) | Pole uwagi |

### Ikony kategorii w PDF

Ikony z `assets/image/` załadowane przez `rootBundle.load()` i osadzone jako `pw.Image(pw.MemoryImage(bytes))`:

| Kategoria | Asset | Opis |
|-----------|-------|------|
| inspection | `hi_bees.png` | Logo/pszczoła |
| equipment | `korpus.png` | Korpus ula |
| colony | `pszczola1.png` | Pszczoła |
| queen | `matka1.png` | Matka |
| harvest | `zbiory.png` | Słoik miodu |
| feeding | `invert.png` | Karmienie |
| treatment | `apivarol1.png` | Leczenie |

Rozmiar ikony w PDF: ~12x12 pt (mała, czytelna).

### Implementacja - plan

**Nie tworzymy nowego ekranu** - PDF generowany bezpośrednio z `infos_screen.dart`:

1. **`infos_screen.dart`** - dodanie:
   - Import `printing` i `pdf` packages
   - Import `dart:typed_data` i `services` (rootBundle)
   - Zmienna `bool _generatingPdf = false`
   - Ikona PDF w AppBar (z CircularProgressIndicator podczas generowania)
   - Metoda `_generateHiveHistoryPdf()`:
     - Pobranie danych z bazy: `DBHelper.getInfosOfHive(pasieka, ul)` (przez provider lub bezpośrednio)
     - Filtrowanie po roku (`rokStatystyk`) jeśli nie "wszystkie"
     - Sortowanie od najstarszego do najnowszego
     - Załadowanie fontów: `PdfGoogleFonts.robotoRegular()`, `PdfGoogleFonts.robotoBold()`
     - Załadowanie 7 ikon PNG z assets przez `rootBundle.load()`
     - Budowa PDF z `pw.MultiPage` (A4, marginesy 2cm)
     - Tabela ze stylem identycznym jak w historii matki (border grey400, header grey200)
     - Udostępnienie: `Printing.sharePdf(bytes, filename)`

2. **`app_pl.arb`** - klucze:
   - `"hiveHistory"`: `"Historia ula"`
   - `"hiveHistoryTitle"`: `"Historia ula nr {hiveNr} w roku {year}"`
   - `"hiveHistoryTitleAll"`: `"Historia ula nr {hiveNr}"`
   - `"catColumn"`: `"Kat."`

3. **`app_en.arb`** - klucze:
   - `"hiveHistory"`: `"Hive history"`
   - `"hiveHistoryTitle"`: `"Hive no. {hiveNr} history in year {year}"`
   - `"hiveHistoryTitleAll"`: `"Hive no. {hiveNr} history"`
   - `"catColumn"`: `"Cat."`

### Nazwa pliku PDF

`historia_ula_NR_ROK.pdf` (np. `historia_ula_5_2026.pdf`)

### Uwagi techniczne

- Wzorowane na `queen_history_screen.dart` - ten sam styl tabeli, fonty, marginesy, sharing
- Dane pobierane z providera `Infos` (items już załadowane dla danego ula) - bez dodatkowego zapytania do bazy
- Filtrowanie po roku w kodzie: `info.data.substring(0, 4) == rokStatystyk`
- Sortowanie: `a.data.compareTo(b.data)` potem `a.czas.compareTo(b.czas)` (chronologicznie)
- Obsługa "dziewica"/"virgine" tak jak w historii matki

## Podsumowanie działań (13.02.2026)

### Wykonane prace:
1. **`app_pl.arb`** - Dodano klucze: `hiveHistoryTitle`, `hiveHistoryTitleAll`, `catColumn`
2. **`app_en.arb`** - Dodano klucze: `hiveHistoryTitle`, `hiveHistoryTitleAll`, `catColumn`
3. **`infos_screen.dart`** - Dodano:
   - Importy: `dart:typed_data`, `flutter/services.dart`, `pdf/pdf.dart`, `pdf/widgets.dart`, `printing/printing.dart`
   - Zmienna stanu: `bool _generatingPdf = false`
   - Metody pomocnicze: `_zmienDatePdf()`, `_cleanTempPdf()`
   - Metoda główna: `_generateHiveHistoryPdf(int hiveNr)`:
     - Ładuje fonty Roboto (regular + bold)
     - Ładuje 7 ikon kategorii z assets jako PNG
     - Pobiera dane z providera Infos (wszystkie kategorie)
     - Filtruje po roku (`rokStatystyk`) jeśli nie "wszystkie"
     - Sortuje chronologicznie (data + czas)
     - Tworzy PDF z tabelą: L.p., Kat. (ikona PNG 12x12), Data, Czas, Temp., Informacja, Uwagi
     - Udostępnia przez `Printing.sharePdf()`
   - Ikona PDF w AppBar (po ikonie statystyk) z CircularProgressIndicator podczas generowania
   - Nazwa pliku: `historia_ula_NR_ROK.pdf`
