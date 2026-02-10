# CLAUDE.md - Instrukcje dla Claude Code

## Zasady pracy z Git

**ZAWSZE pytaj użytkownika przed:**
- Wykonaniem `git commit` - zapytaj o opis commita
- Wykonaniem `git push` - potwierdź przed wysłaniem na GitHub
- Wszelkimi destrukcyjnymi operacjami Git

**Wersjonowanie projektu:**
- Wersja aplikacji znajduje się w pliku `lib/screens/apiarys_screen.dart`
- Najniższy komentarz w formacie `//X.X.X.XX DD.MM.RRRR - opis zmian` = aktualna wersja deweloperska
- Zmienna `final wersja = 'X.X.X.XX';` = wersja opublikowana w App Store
- Przy commicie używaj wersji z komentarza

**Repozytorium:** https://github.com/darys58/hi_bees.git

---

## O projekcie

**Nazwa:** Hi Bees / Hey Maya
**Typ:** Aplikacja Flutter do zarządzania pasiekami pszczół
**Platformy:** iOS, Android
**Język programowania:** Dart
**Baza danych:** SQLite (hibees.db)

---

## Struktura projektu

```
lib/
├── main.dart              # Punkt wejścia, konfiguracja MultiProvider
├── globals.dart           # Zmienne globalne (75+ zmiennych)
├── helpers/
│   └── db_helper.dart     # Obsługa SQLite (70+ metod)
├── models/                # Modele danych (18 plików)
│   ├── apiary.dart        # Pasieka
│   ├── apiarys.dart       # Provider pasiek
│   ├── hive.dart          # Ul
│   ├── hives.dart         # Provider uli
│   ├── frame.dart         # Ramka
│   ├── frames.dart        # Provider ramek
│   ├── info.dart          # Przegląd/dokarmianie/leczenie
│   ├── infos.dart         # Provider info
│   ├── queen.dart         # Matka pszczela
│   ├── harvest.dart       # Zbiory miodu/pyłku
│   ├── note.dart          # Notatka
│   ├── purchase.dart      # Zakupy
│   ├── sale.dart          # Sprzedaż
│   ├── weather.dart       # Pogoda
│   ├── memory.dart        # Dane urządzenia
│   └── dodatki1/2.dart    # Konfiguracja
├── screens/               # Ekrany (34 pliki)
│   ├── apiarys_screen.dart      # Ekran startowy - lista pasiek
│   ├── hives_screen.dart        # Ule w pasiece
│   ├── frames_screen.dart       # Ramki w ulu
│   ├── infos_screen.dart        # Przeglądy/dokarmianie/leczenie
│   ├── harvest_screen.dart      # Zbiory
│   ├── queens_screen.dart       # Matki
│   ├── note_screen.dart         # Notatki
│   ├── purchase_screen.dart     # Zakupy
│   ├── sale_screen.dart         # Sprzedaż
│   ├── voice_screen.dart        # Sterowanie głosowe
│   ├── raport_screen.dart       # Raporty
│   └── ...
├── widgets/               # Komponenty UI (10+ plików)
└── l10n/                  # Lokalizacja
    ├── app_en.arb         # Angielski
    └── app_pl.arb         # Polski
```

---

## Hierarchia danych

```
Pasieka (Apiary)
├── Ul (Hive)
│   ├── Ramka (Frame) - zasoby: trutnie, czerw, larwy, jaja, pierzga, miód...
│   ├── Info - przeglądy, dokarmianie, leczenie
│   └── Matka (Queen)
├── Zbiory (Harvest)
├── Notatki (Note)
├── Zakupy (Purchase)
└── Sprzedaż (Sale)
```

---

## Tabele w bazie danych (SQLite)

| Tabela | Opis |
|--------|------|
| pasieki | Pasieky |
| ule | Ule |
| ramka | Ramki z zasobami |
| info | Przeglądy, dokarmianie, leczenie |
| matki | Matki pszczele |
| zbiory | Zbiory miodu/pyłku |
| notatki | Notatki |
| zakupy | Zakupy |
| sprzedaz | Sprzedaż |
| memory | Dane urządzenia, klucze |
| dodatki1/2 | Konfiguracja |
| pogoda | Cache pogody |

---

## Zarządzanie stanem

Aplikacja używa **Provider pattern** z 13 providerami:
- Frames, Hives, Apiarys, Infos
- Harvests, Notes, Queens
- Purchases, Sales
- Weathers, Memory, Dodatki1, Dodatki2

Każdy provider dziedziczy `ChangeNotifier` i zarządza listą `_items`.

---

## Funkcjonalności aplikacji

1. **Zarządzanie pasiekami** - tworzenie, edycja, usuwanie pasiek
2. **Zarządzanie ulami** - stan uli, ikony, statystyki
3. **Przeglądy ramek** - rejestracja zasobów na ramkach (graficzny widok plastrów)
4. **Dokarmianie i leczenie** - historia z datami i ilościami
5. **Zarządzanie matkami** - rasa, linia, znakowanie
6. **Zbiory miodu/pyłku** - rejestracja i statystyki
7. **Notatki z priorytetami** - zadania do wykonania
8. **Zakupy i sprzedaż** - historia transakcji
9. **Sterowanie głosowe** - Picovoice (wake-word "Hey Maya!")
10. **Pogoda** - prognoza na 5 dni
11. **Raporty** - zbiory i leczenie per ul/rok
12. **Import/Export** - synchronizacja z chmurą (darys.pl)
13. **Dwujęzyczność** - polski i angielski

---

## Kluczowe pliki

| Plik | Znaczenie |
|------|-----------|
| `apiarys_screen.dart` | Główny ekran, wersjonowanie, aktywacja |
| `globals.dart` | Wszystkie zmienne globalne |
| `db_helper.dart` | Wszystkie operacje na bazie danych |
| `main.dart` | Konfiguracja providerów i routing |

---

## Znane problemy architektoniczne (do refaktoryzacji)

1. **Zmienne globalne** - 75+ zmiennych w `globals.dart` zamiast proper state management
2. **Brak separacji warstw** - logika biznesowa w ekranach
3. **Raw SQL queries** - brak parametryzacji (ryzyko SQL injection)
4. **Duplikacja kodu** - podobne ekrany z powtarzającą się logiką
5. **Brak testów** - tylko szablonowy widget_test.dart
6. **Długie metody** - 200+ linii w niektórych ekranach
7. **Mieszane nazewnictwo** - polski/angielski w kodzie

---

## Plany na przyszłość

- Refaktoryzacja do czystej architektury (Clean Architecture)
- Separacja warstw: data, domain, presentation
- Repository pattern dla bazy danych
- Testy jednostkowe
- Lepsza obsługa błędów
- Konsystentne nazewnictwo

---

## W trakcie rozwoju

### Historia matki (`queen_history_screen.dart`)
- **Status:** bazowa wersja gotowa, do dalszego rozwijania
- **Plik:** `lib/screens/queen_history_screen.dart`
- **Route:** `/screen-queen-history`
- **Nawigacja:** przycisk "Historia" w showDialog z `queen_item.dart`
- **Dane:** segment z danymi matki + segmenty z info (kategoria "queen") posortowane od najstarszego
- **Lokalizacja:** klucz `queenHistory` w obu plikach ARB

---

## Zależności (pubspec.yaml)

Główne:
- `provider` - state management
- `sqflite` - SQLite
- `http` - requesty HTTP
- `picovoice_flutter` - sterowanie głosowe
- `fl_chart` - wykresy
- `flutter_localizations` - l10n

---

## Budowanie i testowanie

**Zakaz budowania w kontenerach:**
- NIGDY nie próbuj budować projektu w kontenerach Docker ani tworzyć obrazów Docker.
- NIGDY nie uruchamiaj komend `flutter analyze`, `flutter pub get`, `flutter build` ani innych komend Flutter - Flutter SDK nie jest zainstalowany w kontenerze.
- Użytkownik testuje kod lokalnie na swoim urządzeniu.

**Po zakończeniu zmian w kodzie:**
- NIE pytaj o uruchomienie analizy statycznej - nie możesz jej wykonać.
- Zamiast tego napisz: **"Kod jest gotowy do sprawdzenia lokalnego."**
- Użytkownik sam uruchomi `flutter analyze` i testy na swoim urządzeniu.

**Standardy kodu:**
- Nie wprowadzaj błędów składniowych, które uniemożliwiłyby użytkownikowi manualne uruchomienie projektu.
- Dbaj o poprawność składni Dart i struktury plików ARB (JSON).

---

## Uruchomienie projektu

```bash
flutter pub get
flutter run
```

Dla iOS dodatkowo:
```bash
cd ios && pod install && cd ..
```
