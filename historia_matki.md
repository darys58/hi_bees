# Historia matki - notatki z prac

## Instrukcje użytkownika (10.02.2026)

Stwórz nowy ekran zatytułowany "Historia matki ID (id matki)" w pliku queen_history_screen.dart. Ekran będzie wywoływany z queen_item. W showDialog umieść kolejny TextButton przed "Edytuj" z nazwą "Historia". Ekran będzie się składał z segmentów.

Pierwszy segment będzie miał kilka linii:
1. Linia i rasa matki - czcionki jak w summary_screen.
2. Znak, napis na opalitku, sposób pozyskania, data pozyskania.
3. "Stracona" (data straty matki) - linia wytłuszczona.
4. Uwagi - bez tytułu wiersza.

Dalej będą kolejne segmenty. Każdy będzie miał 3 wiersze:
1. Numer pasieki / numer ula, data wpisu, godzina, temperatura (wszystkie dane z info, kategoria "queen").
2. Parametr i wartość.
3. Uwagi.

Wiersze nie mają tytułów, tylko treść. Wszystkie te dane pobrane z info kategoria "queen" posortowane od najstarszego wpisu do najmłodszego.

## Podsumowanie działań (10.02.2026)

### Wykonane prace:
1. **CLAUDE.md** - Zaktualizowano sekcję "W trakcie rozwoju" - usunięto treść o summary_screen, dodano nową sekcję "Historia matki".
2. **historia_matki.md** - Utworzono plik z instrukcjami użytkownika i podsumowaniem działań.
3. **queen_history_screen.dart** - Utworzono nowy ekran:
   - Tytuł: "Historia matki ID {id}"
   - Segment 1: dane matki (linia+rasa, znak+napis+źródło+data, stracona, uwagi)
   - Kolejne segmenty: wpisy z tabeli info (kategoria "queen") - pasieka/ul, data, godzina, temp, parametr+wartość, uwagi
   - Dane posortowane od najstarszego do najmłodszego
   - Filtrowanie po ID matki w polu pogoda lub po lokalizacji matki (pasieka/ul)
4. **queen_item.dart** - Dodano przycisk "Historia" w showDialog, przed "Edytuj"
5. **main.dart** - Zarejestrowano nową trasę `/screen-queen-history`
6. **app_pl.arb** - Dodano klucz "queenHistory": "Historia matki"
7. **app_en.arb** - Dodano klucz "queenHistory": "Queen history"

## Instrukcje użytkownika (10.02.2026 - sesja 2)

1. Dane do historii pobierać z info dla WSZYSTKICH pasiek i uli na podstawie numeru ID matki, który:
   - jest ID matki w tabeli "matki"
   - znajduje się w polu "pogoda" w tabeli "info" kategoria "queen"
   Matka może być przenoszona między pasiekami/ulami w czasie swojego życia - historia musi to uwzględniać.
2. Dodać prefiks "ID" przed numerem ID matki w tytule strony.
3. Bug: po wejściu do historii matki i wycofaniu się (info -> queen -> zarządzanie matkami -> historia -> cofnij x2) lista w widoku szczegółów matki zmienia się - jest posortowana inaczej i zawiera duplikaty. Trzeba ją odświeżyć przy powrocie.

## Podsumowanie działań (10.02.2026 - sesja 2)

### Wykonane prace:
1. **queen_history_screen.dart** - Zmieniono pobieranie danych:
   - Zamiast używania providera `Infos.fetchAndSetInfos()` (który nadpisywał `_items` providera danymi ze wszystkich info, psując listę w ekranie nadrzędnym), dane pobierane są bezpośrednio z bazy przez `DBHelper.getData('info')` - provider Infos nie jest modyfikowany
   - Usunięto filtrowanie po lokalizacji matki (pasieka/ul) - teraz filtrowanie TYLKO po `info.pogoda == queenId` (ID matki) ze wszystkich pasiek i uli
   - Usunięto import `../models/infos.dart`, dodano import `../helpers/db_helper.dart`
2. **queen_history_screen.dart** - Dodano prefiks "ID" w tytule: "Historia matki ID {id}"
3. **Bug z listą naprawiony** - Źródło problemu: `fetchAndSetInfos()` pobierał WSZYSTKIE info z bazy i zapisywał je w `_items` providera Infos (z `notifyListeners()`), nadpisując dane specyficzne dla ula (załadowane wcześniej przez `fetchAndSetInfosForHive()`). Po powrocie do ekranu nadrzędnego lista wyświetlała dane z całej bazy zamiast z wybranego ula. Rozwiązanie: bezpośrednie zapytanie do bazy przez `DBHelper.getData('info')` bez modyfikacji providera.
