# Plan: Powiadomienia lokalne w Hi Bees

## Kontekst
Lokalne powiadomienia push, które działają nawet gdy aplikacja jest zamknięta. Powiadomienia przypominają o: zadaniach z notesu, przeglądach uli, dokarmianiu i leczeniu. Godzina i dni wyprzedzenia ustawiane przez użytkownika w nowym ekranie ustawień.

---

## Nowe zależności (`pubspec.yaml`)
```yaml
flutter_local_notifications: ^17.2.4
timezone: ^0.9.4
flutter_timezone: ^3.0.1
```

---

## Pliki do UTWORZENIA (2)

### 1. `lib/helpers/notification_helper.dart` — serwis powiadomień
Klasa statyczna (wzorowana na `db_helper.dart`), metody:
- `initialize()` — inicjalizacja pluginu, request permissions (Android 13+, iOS)
- `scheduleAllNotifications()` — anuluje wszystkie, planuje od nowa (4 typy)
- `scheduleNoteReminders()` — query notatki gdzie `status=0` i `pole1!=''`, planuj na `pole1 - advanceDays`
- `scheduleInspectionReminders()` — dla każdego ula: ostatni przegląd + X dni
- `scheduleFeedingReminders()` — analogicznie dla dokarmiania
- `scheduleTreatmentReminders()` — analogicznie dla leczenia
- `cancelAllNotifications()`

Schemat ID powiadomień (unikanie kolizji):
- Notatki: `100000 + noteId`
- Przeglądy: `200000 + (pasiekaNr * 1000 + ulNr)`
- Dokarmianie: `300000 + (pasiekaNr * 1000 + ulNr)`
- Leczenie: `400000 + (pasiekaNr * 1000 + ulNr)`

Ustawienia przechowywane w `SharedPreferences` (już w projekcie):
- `notif_enabled` (bool) — master on/off
- `notif_hour`, `notif_minute` (int) — godzina powiadomień
- `notif_notes_enabled` (bool), `notif_notes_advance_days` (int, 0-7)
- `notif_inspection_enabled` (bool), `notif_inspection_days` (int, domyślnie 14)
- `notif_feeding_enabled` (bool), `notif_feeding_days` (int, domyślnie 7)
- `notif_treatment_enabled` (bool), `notif_treatment_days` (int, domyślnie 14)

### 2. `lib/screens/notification_settings_screen.dart` — ekran ustawień
Wzorowany na `nfc_settings_screen.dart` (StatefulWidget, ten sam styl AppBar). Układ:
```
[SwitchListTile] Włącz powiadomienia (master toggle)
--- Sekcja: Notatki ---
  [SwitchListTile] Przypomnienia z notatek
  [ListTile + Dropdown] Dni wcześniej: 0-7
--- Sekcja: Przeglądy ---
  [SwitchListTile] Przypomnienia o przeglądach
  [ListTile + Dropdown] Dni od ostatniego: 7/10/14/21/30
--- Sekcja: Dokarmianie ---
  [SwitchListTile] Przypomnienia o dokarmianiu
  [ListTile + Dropdown] Dni od ostatniego: 3/5/7/10/14
--- Sekcja: Leczenie ---
  [SwitchListTile] Przypomnienia o leczeniu
  [ListTile + Dropdown] Dni od ostatniego: 7/10/14/21/30
--- Godzina ---
  [ListTile + TimePicker] Godzina powiadomienia: HH:MM
```
Każda zmiana → zapis do SharedPreferences + `scheduleAllNotifications()`.

---

## Pliki do MODYFIKACJI (8)

### 3. `pubspec.yaml`
Dodanie 3 zależności (flutter_local_notifications, timezone, flutter_timezone).

### 4. `lib/main.dart`
- Import `notification_helper.dart` i ekranu
- W `main()` po `WidgetsFlutterBinding.ensureInitialized()`: inicjalizacja timezone + `NotificationHelper.initialize()`
- Dodanie route: `NotificationSettingsScreen.routeName: (ctx) => NotificationSettingsScreen()`

### 5. `lib/helpers/db_helper.dart`
Dodanie 2 nowych metod statycznych:
```dart
static Future<List<Map<String, dynamic>>> getLatestInfoPerHive(String kategoria)
// SELECT pasiekaNr, ulNr, MAX(data) as lastDate FROM info WHERE kategoria=? AND arch=0 GROUP BY pasiekaNr, ulNr

static Future<List<Map<String, dynamic>>> getActiveNotesWithTaskDate()
// SELECT id, tytul, pole1 FROM notatki WHERE status=0 AND pole1 IS NOT NULL AND pole1!='' AND arch=0
```

### 6. `lib/screens/settings_screen.dart`
Dodanie pozycji menu "Powiadomienia" z ikoną `Icons.notifications` — między NFC a O aplikacji (linia ~241).

### 7. `lib/screens/apiarys_screen.dart`
Po załadowaniu danych z bazy (po `fetchAndSetDodatki1`): wywołanie `NotificationHelper.scheduleAllNotifications()` — przeplanowanie powiadomień przy starcie aplikacji.

### 8. `lib/screens/note_edit_screen.dart`
Po zapisie/edycji notatki z `pole1`: wywołanie `scheduleAllNotifications()`.

### 9. `lib/screens/infos_edit_screen.dart`
Po zapisie info (inspection/feeding/treatment): wywołanie `scheduleAllNotifications()`.

### 10. `lib/l10n/app_en.arb` i `app_pl.arb`
Dodanie ~16 kluczy lokalizacyjnych (nazwy sekcji, opisy, tytuły powiadomień).

---

## Konfiguracja platform

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### iOS (`ios/Runner/AppDelegate.swift`)
Dodanie delegata `UNUserNotificationCenter` dla powiadomień w tle.

---

## Kolejność implementacji
1. `pubspec.yaml` — zależności
2. `db_helper.dart` — nowe query
3. `notification_helper.dart` — NOWY, serwis powiadomień
4. `notification_settings_screen.dart` — NOWY, ekran ustawień
5. `app_en.arb` + `app_pl.arb` — lokalizacja
6. `main.dart` — inicjalizacja + route
7. `settings_screen.dart` — pozycja w menu
8. `apiarys_screen.dart` — planowanie przy starcie
9. `note_edit_screen.dart` — planowanie po zapisie notatki
10. `infos_edit_screen.dart` — planowanie po zapisie info
11. `AndroidManifest.xml` + `AppDelegate.swift` — uprawnienia platform

---

## Weryfikacja
Użytkownik testuje lokalnie:
1. `flutter pub get` → `flutter run`
2. Wejście w Ustawienia → Powiadomienia → włączenie, ustawienie godziny
3. Dodanie notatki z "Data zadania" na dziś/jutro → sprawdzenie czy powiadomienie się pojawi
4. Test z zamkniętą aplikacją — powiadomienie powinno się wyświetlić o ustawionej godzinie

---

## Ważne uwagi techniczne
- **Limit Androida:** max 50 zaplanowanych alarmów na aplikację. Dla dużych pasiek (wiele uli) — grupować powiadomienia tego samego dnia w jedno.
- **Restart telefonu (Android):** plugin `flutter_local_notifications` automatycznie rejestruje BOOT_COMPLETED receiver — powiadomienia przetrwają restart.
- **iOS:** wymaga jednorazowej zgody użytkownika na powiadomienia (system dialog).
- **Android 13+:** wymaga runtime permission `POST_NOTIFICATIONS`.
- **Daty:** format YYYY-MM-DD (zgodny z istniejącym kodem), czasy HH:MM:SS.
- **Baza danych:** pola kluczowe to `notatki.pole1` (data zadania) i `info.data` + `info.kategoria`.

---

## Przyszły rozwój (do dodania w kolejnych wersjach)
- Powiadomienia o zbiorach (sezon miodowy)
- Powiadomienia pogodowe (np. ostrzeżenie przed przymrozkami)
- Powiadomienia o matce (brak matki, wymiana)
- Grupowanie powiadomień na Androidzie (NotificationChannel)
- Akcje w powiadomieniu (np. "Oznacz jako wykonane")
