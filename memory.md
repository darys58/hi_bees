# Memory - Notatki robocze

## Aktualny temat: Przenoszenie ramki (frame_move_screen.dart)

### Koncepcja formularza (WAŻNE - uzgodnione z użytkownikiem)

Formularz ma **dwie sekcje**:

**1. Sekcja "SKĄD" (Przenieś ramkę z:)**
- **Pasieka, ul, data przeglądu** — brane z kontekstu nawigacji, **nieaktywne** (readonly)
- **Korpus** — do wyboru z dostępnych korpusów w tym kontekście (filtrowane wg daty i ula)
- **Ramka** — do wyboru z dostępnych ramek w wybranym korpusie

**2. Sekcja "DOKĄD" (Przenieś ramkę do:)**
- **Pasieka** — wybieramy z listy wszystkich pasiek
- **Ul** — wybieramy z listy uli w wybranej pasiece docelowej
- **Korpus** — wybieramy numer korpusu docelowego
- **Typ korpusu** — pół/cały
- **Ramka** — wybieramy numer ramki docelowej
- **Data przeglądu docelowego** — automatycznie ustawiana na **ostatnią datę przeglądu** wybranego ula docelowego. Jeśli brak przeglądów — domyślnie **data bieżąca**

### Nawigacja do ekranu
Ekran wywoływany z **2 miejsc** (NIE z infos_screen!):
- `frames_screen.dart` (linia ~432) - z ekranu ramek
- `frames_detail_screen.dart` (linia ~68) - z detali ramki

Argumenty: `{'idPasieki': pasieka, 'idUla': ul, 'idZasobu': 2, 'idKorpusu': globals.nowyNrKorpusu, 'idRamki': globals.nowyNrRamki, 'idData': wybranaData}`

### Zmienne globalne (globals.dart)
- `nrUlaPrzeniesZ` - nr ula źródłowego
- `nrKorpusuPrzeniesZ` - nr korpusu źródłowego
- `nrRamkiPrzeniesZ` - nr ramki źródłowej
- `nrUlaPrzeniesDo` - nr ula docelowego
- `nrKorpusuPrzeniesDo` - nr korpusu docelowego
- `nrRamkiPrzeniesDo` - nr ramki docelowej
- `nrPasiekiPrzeniesDo` - nr pasieki docelowej
- `dataPrzeniesRamke` - data przeglądu docelowego

### Wykonane zmiany (09.02.2026)
1. **Naprawiono hardcoded dane** - `globals.nrUlaPrzeniesZ` i `nrUlaPrzeniesDo` były domyślnie ustawione na 1 i nie inicjalizowane z argumentów trasy (`idUla`). Teraz pobierają wartość z kontekstu nawigacji.
2. **Zamieniono kolejność** przycisków w sekcji "Z:" - data przeglądu jest teraz pierwsza (po lewej), a pasieka/ul drugi (po prawej), tak jak było w oryginalnej wersji.
3. **Dodano wcześniej** (w poprzedniej sesji): wybór pasieki docelowej, filtrowanie dostępnych korpusów/ramek źródłowych, automatyczne tworzenie wpisu inspection w docelowym ulu, sprawdzanie czy zostały ramki po przeniesieniu.
4. **Naprawiono hardcoded korpus i ramkę** - `globals.nrKorpusuPrzeniesZ`, `nrKorpusuPrzeniesDo`, `nrRamkiPrzeniesZ` i `nrRamkiPrzeniesDo` były domyślnie ustawione na 1. Teraz pobierają wartość z kontekstu nawigacji.
5. **Dodano datę do argumentów trasy** - `'idData': wybranaData` przekazywana z `frames_screen.dart` i `frames_detail_screen.dart`. W `frame_move_screen.dart` czytana jako `routeArgs['idData']` i ustawiana w `dateController.text` (zamiast `globals.dataWpisu`).
6. **Usunięto opcję przenoszenia ramki z `infos_screen.dart`** - bo tam nie ma wybranej daty przeglądu. Przenoszenie ramek dostępne tylko z `frames_screen.dart` i `frames_detail_screen.dart`.
7. **Automatyczna data docelowa** - dodano metodę `_updateTargetDate(pasiekaDo, ulDo)` która pobiera ostatnią datę przeglądu (inspection) ula docelowego i ustawia `globals.dataPrzeniesRamke`. Jeśli brak przeglądów — data bieżąca. Wywoływana: przy inicjalizacji, po zmianie pasieki docelowej i po zmianie ula docelowego.

### Naprawione bugi (09.02.2026 - sesja 2)

**Bug 1: Data przeglądu docelowego nie odświeżała się po zmianie pasieki/ula**

Przyczyna: W `_showAlertNrPasieki` i `_showAlertNrUla` parametr `builder: (context)` w `showDialog` przesłaniał kontekst widgetu kontekstem dialogu. Callbacki `.then()` uruchamiały się PO `Navigator.pop()` (dialog już nie istniał), więc `Provider.of(context)` używał nieważnego kontekstu. Dodatkowo zmiany stanu w `.then()` nie były w `setState()`.

Naprawa:
- `builder: (context)` → `builder: (dialogContext)` — teraz wewnątrz buildera `context` = kontekst widgetu (zawsze ważny)
- Dialog zamykany PRZED operacjami async (`Navigator.of(dialogContext).pop()` → potem `Provider.of(context)`)
- Callbacki `.then()` opakowane w `if (!mounted) return` + `setState(() { ... })`
- `_updateTargetDate` też dostało `if (!mounted) return`

**Bug 2: Apka gubiła kontekst (pasiekę/ul) po zapisie lub cofnięciu**

Przyczyna: Operacje na ekranie przenoszenia modyfikowały providery (Hives, Frames, Infos) danymi ula/pasieki docelowej. Po powrocie do `frames_screen` providery miały dane innego ula. A `frames_screen` ma `_isInit=false` więc nie odświeżał danych.

Naprawa:
- Dodano `_sourceUl` (zmienna instancji) — zapamiętuje numer ula źródłowego z argumentów nawigacji
- Dodano metodę `_restoreAndPop({bool afterSave = false})`:
  1. Re-fetch `Hives` dla źródłowej pasieki
  2. Re-fetch `Infos` dla źródłowej pasieki/ula
  3. Re-fetch `Frames` dla źródłowej pasieki/ula
  4. Jeśli `afterSave`: sprawdza czy ul ma jeszcze ramki (`ramkaNr > 0 && ramkaNrPo != 0`)
     - Tak → `popUntil(FramesScreen.routeName)`
     - Nie → `popUntil(InfosScreen.routeName)`
  5. Jeśli zwykły powrót: `popUntil(FramesScreen.routeName)`
- Przycisk zapisz: zamiast `Navigator.pop()` → `_restoreAndPop(afterSave: true)`
- Przycisk wstecz (AppBar): `leading: IconButton(onPressed: _restoreAndPop)`
- Systemowy back (Android): `PopScope(canPop: false, onPopInvokedWithResult: ... _restoreAndPop())`

### Logika nawigacji po zapisie/cofnięciu

Stos nawigacji (zawsze):
```
...hives_screen / infos_screen / frames_screen / [frames_detail_screen] / frame_move_screen
```

- `popUntil(FramesScreen.routeName)` — wraca do ekranu ramek (pomija frames_detail jeśli był)
- `popUntil(InfosScreen.routeName)` — wraca do przeglądów (gdy brak ramek w ulu)
- Przed popUntil providery mają przywrócone dane źródłowe → `frames_screen` i `infos_screen` odczytają poprawne dane z providerów (listen: true → rebuild)

### Ważne: wzorzec dialog + async w Flutter

**ŹLE** (stary kod):
```dart
builder: (context) => AlertDialog(  // context = dialog!
  onTap: () {
    setState(() {
      Provider.of(context).fetch().then((_) {  // context dialogu - po pop nieważny
        zmiennaStanu = x;  // bez setState → brak rebuild
      });
    });
    Navigator.of(context).pop();  // dialog zamknięty, ale .then() jeszcze nie uruchomiony
  }
)
```

**DOBRZE** (nowy kod):
```dart
builder: (dialogContext) => AlertDialog(  // dialogContext = dialog
  onTap: () {
    setState(() { syncState = x; });  // synchroniczne zmiany stanu
    Navigator.of(dialogContext).pop();  // zamknij dialog
    Provider.of(context).fetch().then((_) {  // context = widget (ważny!)
      if (!mounted) return;
      setState(() { asyncState = y; });  // async zmiany stanu w setState
    });
  }
)
```

### Pliki powiązane
- `lib/screens/frame_move_screen.dart` - główny ekran
- `lib/screens/frames_screen.dart` - ekran ramek (routeName: '/screen-frames')
- `lib/screens/infos_screen.dart` - ekran przeglądów (routeName: '/screen-infos')
- `lib/globals.dart` - zmienne globalne
- `lib/models/frames.dart` - provider ramek
- `lib/helpers/db_helper.dart` - operacje DB (updateRamkaNrPo)
