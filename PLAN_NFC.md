# Plan implementacji funkcjonalności NFC

## Cel
Dodanie możliwości odczytu tagów NFC przypisanych do uli. Po zeskanowaniu tagu aplikacja rozpoznaje ul i automatycznie do niego nawiguje (symulacja ręcznego wyboru).

## Przepływ użytkownika

```
[Klik przycisk NFC] → [Skanowanie] → [Odczyt ID tagu]
                                            ↓
                    ┌───────────────────────┴───────────────────────┐
                    ↓                                               ↓
            [Tag przypisany]                              [Tag nieprzypisany]
                    ↓                                               ↓
            [Nawiguj do ula]                          [Dialog wyboru ula]
                                                              ↓
                                                    [Zapisz tag w h3]
                                                              ↓
                                                    [Nawiguj do ula]
```

---

## Pliki do modyfikacji

### 1. `android/app/src/main/AndroidManifest.xml`
**Zmiana:** Dodanie uprawnień NFC (po linii 8, przed `<application>`)
```xml
<uses-permission android:name="android.permission.NFC"/>
<uses-feature android:name="android.hardware.nfc" android:required="false"/>
```

### 2. `lib/helpers/db_helper.dart`
**Zmiana:** Dodanie metody do wyszukiwania ula po tagu NFC (po linii ~440)
```dart
static Future<List<Map<String, dynamic>>> getHiveByH3(String h3Value) async {
  final db = await DBHelper.database();
  return db.rawQuery('SELECT * FROM ule WHERE h3 = ?', [h3Value]);
}
```

### 3. `lib/l10n/app_pl.arb`
**Zmiana:** Dodanie tekstów lokalizacyjnych dla NFC
- `nfcScanning`, `nfcHoldNearTag`, `nfcNotAvailable`, `nfcTagReadError`
- `nfcAssignTag`, `nfcSelectApiary`, `nfcSelectHive`, `nfcAssign`, `nfcTagAssigned`
- `nfcButton` - etykieta przycisku NFC

### 4. `lib/l10n/app_en.arb`
**Zmiana:** Dodanie tekstów lokalizacyjnych (angielskie odpowiedniki)

### 5. `lib/screens/apiarys_screen.dart`
**Zmiany:**
- Import nowych plików (nfc_helper.dart, hives.dart)
- **Przycisk NFC obok "STEROWANIE GŁOSEM"** (na dole ekranu, ~linia 1570)
- Metoda `_startNfcScan()` do obsługi skanowania

### 6. `lib/screens/import_screen.dart` (WAŻNE!)
**Zmiana:** Zachowanie pola h3 przy imporcie danych
- Przed usunięciem tabeli `ule` - zapisać mapowanie `id → h3`
- Po imporcie - przywrócić wartości h3 dla istniejących uli

---

## Pliki do utworzenia

### 1. `lib/helpers/nfc_helper.dart`
Helper do obsługi NFC zawierający:
- `isNfcAvailable()` - sprawdzenie dostępności NFC
- `handleNfcScan()` - główna logika skanowania
- `_extractTagId()` - wyodrębnienie ID z tagu (NfcA, NfcB, NfcV, MiFare)
- `_bytesToHex()` - konwersja bajtów na hex string
- `_findHiveByNfcTag()` - wyszukanie ula po tagu
- `_navigateToHive()` - nawigacja do ula (ustawienie globals + Navigator)
- `_showScanningDialog()` - dialog podczas skanowania
- `_showHiveSelectionDialog()` - dialog wyboru ula dla nowego tagu

### 2. `lib/widgets/nfc_hive_selection_dialog.dart`
Dialog do wyboru ula przy przypisywaniu nowego tagu:
- Dropdown z pasiekami
- Dropdown z ulami (filtrowanie: tylko ule bez przypisanego tagu)
- Przycisk "Przypisz"

---

## Szczegóły implementacji

### Przycisk NFC (obok "STEROWANIE GŁOSEM", ~linia 1570)
```dart
// W Row obok przycisku Voice Control - dodać przed SizedBox(width: 15)
SizedBox(
  width: 80,  // mniejszy niż Voice Control (220)
  height: 50,
  child: ElevatedButton(
    style: buttonStyle,  // ten sam styl co Voice Control
    onPressed: () {
      globals.key == '' || globals.key == "bez_klucza"
          ? null
          : _startNfcScan(context);
    },
    child: Text(
      'NFC',
      style: TextStyle(
        height: 1.0,
        fontSize: 14,
        color: Color.fromARGB(255, 0, 0, 0),
      ),
    ),
  ),
),
const SizedBox(width: 9),  // odstęp między przyciskami
```

### Symulacja wyboru ula (tak jak w hives_item.dart linie 115-123)
```dart
globals.pasiekaID = hive.pasiekaNr;
globals.ulID = hive.ulNr;
globals.typUla = hive.h2;
globals.dataAktualnegoPrzegladu = '';
Navigator.of(context).pushNamed(InfoScreen.routeName, arguments: hive.ulNr);
```

### Zapis tagu do bazy
```dart
await DBHelper.updateUle(hive.id, 'h3', tagId);
```

---

## Zachowanie h3 przy imporcie (import_screen.dart)

**Problem:** Przy imporcie z chmury tabela `ule` jest usuwana (linia ~2429) i tworzona na nowo z h3='0' (linie 370, 431), co powoduje utratę przypisań NFC.

**Rozwiązanie:** Przed importem zapisać mapowanie tagów, po imporcie przywrócić.

```dart
// Przed deleteTable('ule'):
Map<String, String> nfcTags = {};
final hives = await DBHelper.getData('ule');
for (var hive in hives) {
  if (hive['h3'] != '0' && hive['h3'] != null && hive['h3'] != '') {
    nfcTags[hive['id']] = hive['h3'];
  }
}

// Po zakończeniu importu uli:
for (var entry in nfcTags.entries) {
  await DBHelper.updateUle(entry.key, 'h3', entry.value);
}
```

---

## Obsługa błędów

| Scenariusz | Reakcja |
|------------|---------|
| NFC niedostępne | Dialog informacyjny |
| Błąd odczytu tagu | Komunikat o błędzie |
| Brak uli w bazie | SnackBar z informacją |
| Wszystkie ule mają tagi | Ostrzeżenie w dialogu |
| Anulowanie skanowania | Zamknięcie sesji NFC |

---

## Kolejność implementacji

1. `AndroidManifest.xml` - uprawnienia NFC
2. `db_helper.dart` - metoda getHiveByH3
3. `app_pl.arb`, `app_en.arb` - lokalizacja
4. `nfc_helper.dart` - helper NFC (NOWY PLIK)
5. `nfc_hive_selection_dialog.dart` - dialog wyboru (NOWY PLIK)
6. `apiarys_screen.dart` - przycisk NFC obok "STEROWANIE GŁOSEM"
7. `import_screen.dart` - zachowanie h3 przy imporcie

---

## Weryfikacja

### Test na urządzeniu fizycznym (wymagane NFC):
1. Uruchom aplikację
2. Kliknij przycisk NFC na dole ekranu (obok "STEROWANIE GŁOSEM")
3. Przyłóż tag NFC do telefonu
4. **Nowy tag:** Powinien pojawić się dialog wyboru ula → wybierz ul → nawigacja do ula
5. **Zapisany tag:** Bezpośrednia nawigacja do przypisanego ula

### Test bez NFC:
1. Uruchom na emulatorze/urządzeniu bez NFC
2. Kliknij przycisk NFC
3. Powinien pojawić się dialog "NFC niedostępne"

### Test importu (zachowanie h3):
1. Przypisz tag NFC do ula
2. Wykonaj import z chmury
3. Sprawdź czy przypisanie NFC zostało zachowane

### Weryfikacja zapisu w bazie:
```sql
SELECT id, ulNr, h3 FROM ule WHERE h3 != '0';
```

---

## Kluczowe pliki referencyjne

- `lib/screens/apiarys_screen.dart` (linie 1549-1570) - wzorzec przycisku Voice Control
- `lib/widgets/hives_item.dart` (linie 115-123) - wzorzec nawigacji do ula
- `lib/models/hive.dart` (linia 35) - pole h3 w modelu
- `lib/helpers/db_helper.dart` (linia 220) - metoda updateUle
- `lib/screens/import_screen.dart` (linie 370, 431, 2429) - miejsca gdzie h3 jest ustawiane na '0'
- `ios/Runner/Info.plist` - NFCReaderUsageDescription już skonfigurowane

---

## Faza 2 - Ustawienia NFC (tryb działania przycisku NFC)

### Cel
Dodanie ekranu ustawień NFC w Ustawieniach aplikacji, umożliwiającego konfigurację działania przycisku NFC na stronie startowej. Trzy tryby:
1. **Wyłącz obsługę NFC** (`off`) - ukrywa przycisk NFC na stronie startowej
2. **Otwieraj informacje szczegółowe** (`info`) - domyślne, dotychczasowe działanie (nawigacja do `InfoScreen`)
3. **Otwieraj podsumowanie** (`summary`) - po odczytaniu tagu NFC otwiera ekran `SummaryScreen`

### Przechowywanie ustawienia
- Pole `c` w tabeli `dodatki1` (dotychczas nieużywane, inicjalizowane jako `'0'`)
- Wartości: `'off'`, `'info'`, `'summary'`
- Domyślna wartość gdy `c == '0'` lub puste: `'info'`
- Zmienna globalna: `globals.nfcMode`

### Nowy plik
- **`lib/screens/nfc_settings_screen.dart`** - ekran z 3 opcjami RadioListTile, route: `/nfc-settings`

### Zmodyfikowane pliki

| Plik | Zmiana |
|------|--------|
| `lib/globals.dart` | Dodana zmienna `String nfcMode = 'info'` |
| `lib/l10n/app_en.arb` | Dodane klucze: `nfcSettings`, `nfcModeOff`, `nfcModeOffDesc`, `nfcModeInfo`, `nfcModeInfoDesc`, `nfcModeSummary`, `nfcModeSummaryDesc` |
| `lib/l10n/app_pl.arb` | Dodane te same klucze po polsku |
| `lib/screens/settings_screen.dart` | Dodany panel "Obsługa NFC" (ikona `Icons.nfc`) nad panelem "O aplikacji" |
| `lib/main.dart` | Import `nfc_settings_screen.dart`, rejestracja trasy `/nfc-settings` |
| `lib/helpers/nfc_helper.dart` | Import `provider`, `Hives`, `SummaryScreen`; metoda `_navigateToHive` sprawdza `globals.nfcMode` i nawiguje do `InfoScreen` lub `SummaryScreen` |
| `lib/screens/apiarys_screen.dart` | Odczyt trybu NFC z `dodatki1.c` przy starcie; ukrywanie przycisku NFC gdy `nfcMode == 'off'` |
| `lib/screens/summary_screen.dart` | Konwersja z `StatelessWidget` na `StatefulWidget` z pobieraniem danych uli (`fetchAndSetHives`) w `didChangeDependencies` |

### Przepływ danych

```
Uruchomienie apki
  → fetchAndSetDodatki1()
  → odczyt dodatki1.c → globals.nfcMode

Ekran ustawień NFC (NfcSettingsScreen)
  → użytkownik wybiera opcję
  → globals.nfcMode = wartość
  → DBHelper.updateDodatki1('c', wartość)

Przycisk NFC na stronie startowej (apiarys_screen)
  → widoczny tylko gdy globals.nfcMode != 'off'
  → NfcHelper.handleNfcScan(context)

NfcHelper._navigateToHive()
  → jeśli nfcMode == 'summary':
      → fetchAndSetHives(pasiekaNr)
      → nawigacja do SummaryScreen z argumentami {ulNr, pasiekaNr}
  → jeśli nfcMode == 'info':
      → nawigacja do InfoScreen (dotychczasowe działanie)

SummaryScreen (StatefulWidget)
  → didChangeDependencies: sprawdza czy dane uli są w Providerze
  → jeśli brak → fetchAndSetHives(pasiekaNr)
  → wyświetla podsumowanie ula
```

### Naprawiony problem: brak danych dla pasiek innych niż pierwsza
- `SummaryScreen` przekształcony z `StatelessWidget` na `StatefulWidget`
- W `didChangeDependencies` sprawdza czy dane uli są dostępne w Providerze
- Jeśli brak danych (inna pasieka) - automatycznie pobiera z bazy (`fetchAndSetHives`)
- Pokazuje `CircularProgressIndicator` podczas ładowania
