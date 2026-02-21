# Plan: Progress bar w import_screen.dart

## Kontekst
Ekran importu/eksportu (`import_screen.dart`) pokazuje tylko nieokreślony spinner (`CircularProgressIndicator`) podczas operacji trwających niekiedy kilkadziesiąt sekund. Użytkownik nie wie, na jakim etapie jest operacja. Dodajemy prosty `LinearProgressIndicator` z procentem i etykietą aktualnego kroku.

## Pliki do modyfikacji
- `lib/screens/import_screen.dart` — jedyny plik

## Podejście
Użycie `ValueNotifier<double>` + `ValueNotifier<String>` do reaktywnej aktualizacji dialogu z postępem. `ValueListenableBuilder` wewnątrz dialogu nasłuchuje zmian i przebudowuje widżet bez potrzeby `setState`.

## Kroki implementacji

### 1. Nowe zmienne stanu (linie ~59-60, obok `count`)
```dart
final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
final ValueNotifier<String> _progressLabelNotifier = ValueNotifier<String>('');
int _completedSteps = 0;
int _totalSteps = 1;
```
Usunięcie nieużywanej zmiennej `count` i `test`.

### 2. Metoda `dispose` (nowa, po `didChangeDependencies`)
```dart
@override
void dispose() {
  _progressNotifier.dispose();
  _progressLabelNotifier.dispose();
  super.dispose();
}
```

### 3. Metoda pomocnicza `_updateProgress` (nowa)
```dart
void _updateProgress(String label) {
  _completedSteps++;
  _progressNotifier.value = _completedSteps / _totalSteps;
  _progressLabelNotifier.value = label;
}
```

### 4. Nowa metoda `showProgressDialog` (obok istniejącej `showLoaderDialog`)
Zastępuje `showLoaderDialog` w 3 operacjach (import, export new, export all).
Wyświetla:
- Tytuł operacji (np. "Import danych z chmury")
- `LinearProgressIndicator` z kolorem zielonym
- Procent (np. "42%")
- Etykieta kroku (np. "Notatki...")

`showLoaderDialog` pozostaje bez zmian — nadal używana przez eksporty pojedynczych tabel.

### 5. Modyfikacja `_showAlertImport` (linia ~201)
- Zamiana `showLoaderDialog(...)` → `showProgressDialog(context, ..., 12)`
- Po każdym `.then()` z `fetchXxxFromSerwer` — dodanie `_updateProgress('Notatki...')` itd.
- Kroki importu (12 łącznie):
  1-7: Pobranie 7 tabel równolegle (notatki, zakupy, sprzedaż, matki, zbiory, zdjęcia, ramki)
  8: Pobranie info (sekwencyjnie po ramkach)
  9: Odbudowa tabeli uli z ramek
  10: Aktualizacja uli z info
  11: Odbudowa tabeli pasiek
  12: Przywrócenie NFC + finalizacja

### 6. Modyfikacja `_showAlertExportAll` (linia ~1482)
- Zamiana `showLoaderDialog(...)` → `showProgressDialog(context, ..., 8)`
- Po każdym `.then()` z `fetchAndSetXxx` — dodanie `_updateProgress('Notatki...')` itd.
- 8 kroków: notatki, zakupy, sprzedaż, matki, zbiory, info, zdjęcia, ramki

### 7. Modyfikacja `_showAlertExportNew` (linia ~1942)
- Identyczna zmiana jak w Export All — `showProgressDialog(context, ..., 8)` + 8× `_updateProgress`

## Uwagi
- Kroki 1-7 importu lecą równolegle — progress bar skacze ale rośnie poprawnie
- `showLoaderDialog` NIE jest modyfikowana — eksporty pojedynczych tabel nadal używają spinnera
- Brak zmian w plikach ARB — etykiety kroków to nazwy istniejących kluczy lokalizacyjnych (np. `AppLocalizations.of(context)!.nOtes`)
- Żadna zmiana w logice biznesowej — tylko dodanie wywołań `_updateProgress` w istniejących callbackach `.then()`
