// Cofanie ostatnich poleceń głosowych ("hej maja cofnij ostatni zapis").
//
// DLACZEGO MIGAWKI, A NIE KASOWANIE OSTATNIEGO REKORDU
// Jedna komenda głosowa to nie jest jeden wiersz w bazie. "czerw 50 procent"
// przy zakresie ramek 3-7 pisze do 10 wierszy w `ramka`, nadpisuje wiersz w
// `ule` (belka sumaryczna) i w `pasieki`, a przy pierwszym zasobie dnia dokłada
// wiersz `info` (kategoria "inspection"). Do tego:
//
//  - zapis jest UPSERT-em po składanym id (data.pasieka.ul.korpus.ramka.ramkaPo.
//    strona.zasob), a DBHelper.insert to ConflictAlgorithm.replace. Powiedzenie
//    "czerw 50", a potem "czerw 70" na tej samej ramce tego samego dnia NADPISUJE
//    pierwszą wartość. Zwykły DELETE przy cofaniu skasowałby wiersz, zamiast
//    przywrócić 50 - dlatego cofanie musi znać stan SPRZED zapisu,
//  - belka ula jest kumulatywna (sumujZasob), ale matka, todo i ikona to stany
//    "ostatnia wartość wygrywa" - przeliczyć się ich nie da, muszą wrócić z
//    migawki,
//  - komendy strukturalne ("wstaw ramkę", "usuń ramkę", przeniesienie do innego
//    korpusu) przenumerowują cały korpus. Odtworzenie tego z reguł odwrotnych
//    jest praktycznie niewykonalne.
//
// Stąd model: przed komendą zrzucamy CAŁY plaster bazy, którego może dotknąć, a
// cofanie przywraca ten plaster. Jeden mechanizm obsługuje wszystkie typy
// komend - ramkowe, info, dokarmianie, leczenie i strukturalne - więc nie ma
// czternastu ścieżek odwrotnych do napisania i utrzymania.
//
// WYŚCIG Z ZAPISEM - POWÓD, DLA KTÓREGO ODCZYT JEST W TRANSAKCJI
// Zapisy w voice_vosk_screen NIE są awaitowane: lecą w łańcuchach `.then()` po
// fetchAndSetHives / fetchAndSetFramesForHive, a wywołujący wraca natychmiast.
// Gdyby migawka była serią osobnych zapytań, zapis mógłby wejść między nie i
// zrzut byłby częściowo już zmieniony. Cały odczyt idzie więc w JEDNEJ
// transakcji, zakolejkowanej zanim komenda zdąży cokolwiek zapisać (wywołanie
// [przygotuj] jest pierwszą instrukcją obsługi komendy, przed switchem).
// sqflite wykonuje operacje w kolejności zakolejkowania, a transakcja blokuje
// pozostałe do swojego końca.
//
// CZEGO TO NIE COFA
// Rekordy wysłane do chmury mają arch = 1. Skasowanie ich lokalnie nie kasuje
// ich na serwerze - przy najbliższym imporcie mogą wrócić. Przywracanie stanu
// sprzed zmiany jest bezpieczne (ten sam id, nadpisanie), niebezpieczne jest
// tylko usunięcie wiersza, który zdążył pojechać do chmury. W praktyce cofa się
// w ciągu sekund, a eksport jest ręczny, więc to ryzyko jest przyjęte świadomie.

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

import 'db_helper.dart';

/// Które wiersze bazy obejmuje migawka. Zakres wynika z komendy: zwykły zapis
/// zasobu dotyka jednego ula, "wpis dla wszystkich uli" - całej pasieki, a
/// przeniesienie ramki może dotknąć drugiego ula, którego numeru nie znamy,
/// zanim komenda się wykona (dlatego wtedy bierzemy całą pasiekę).
class ZakresPlastra {
  /// Data przeglądu (kolumna `data` w `ramka` i `info`).
  final String data;

  /// Numer pasieki.
  final int pasiekaNr;

  /// Numery uli objętych migawką. PUSTA lista = wszystkie ule pasieki.
  final List<int> uleNr;

  /// Czy zrzucać tabelę `ramka`. Komendy czysto informacyjne (dokarmianie,
  /// leczenie, matka) ramek nie ruszają, więc nie ma po co czytać setek wierszy.
  final bool zRamkami;

  const ZakresPlastra({
    required this.data,
    required this.pasiekaNr,
    this.uleNr = const [],
    this.zRamkami = true,
  });

  /// Zakres dla jednego ula - typowy przypadek.
  factory ZakresPlastra.ul(String data, int pasiekaNr, int ulNr,
          {bool zRamkami = true}) =>
      ZakresPlastra(
        data: data,
        pasiekaNr: pasiekaNr,
        uleNr: [ulNr],
        zRamkami: zRamkami,
      );

  /// Zakres dla całej pasieki - "wpis dla wszystkich uli" oraz komendy, które
  /// mogą trafić w ul spoza bieżącego kontekstu (przeniesienie ramki).
  factory ZakresPlastra.pasieka(String data, int pasiekaNr,
          {bool zRamkami = true}) =>
      ZakresPlastra(
        data: data,
        pasiekaNr: pasiekaNr,
        uleNr: const [],
        zRamkami: zRamkami,
      );

  bool get calaPasieka => uleNr.isEmpty;
}

/// Stan czterech tabel sprzed jednej komendy głosowej.
class MigawkaZapisu {
  /// Zakres, z którego zrzut powstał - przywracanie musi użyć TEGO SAMEGO,
  /// inaczej nie wiedziałoby, które wiersze dodane przez komendę usunąć.
  final ZakresPlastra zakres;

  /// tabela -> wiersze sprzed komendy. Brak wiersza w tej mapie przy obecnym w
  /// bazie oznacza, że komenda go DODAŁA i cofanie ma go usunąć.
  final Map<String, List<Map<String, Object?>>> wiersze;

  /// Opis dla użytkownika - to samo, co ekran pokazuje w wierszu "Zapis:"
  /// ("czerw kryty = 50%", "syrop 1:1 = 2,5 l"). Maja wypowiada to przy
  /// cofaniu, żeby było słychać, CO znika.
  final String opis;

  /// Kontekst do odświeżenia widoku po cofnięciu.
  final int pasiekaNr;
  final int ulNr;
  final int korpusNr;

  const MigawkaZapisu({
    required this.zakres,
    required this.wiersze,
    required this.opis,
    required this.pasiekaNr,
    required this.ulNr,
    required this.korpusNr,
  });

  int get ileWierszy =>
      wiersze.values.fold<int>(0, (suma, lista) => suma + lista.length);
}

/// Czym skończyła się próba cofnięcia. Ekran MUSI rozróżniać te trzy przypadki:
/// "nie ma czego cofnąć" i "migawka się nie udała" wyglądają dla użytkownika
/// tak samo (komenda nic nie robi), a znaczą co innego - pierwsze jest normalne,
/// drugie to awaria, o której trzeba powiedzieć wprost.
enum StanCofania { cofnieto, brak, blad }

class WynikCofania {
  final StanCofania stan;

  /// Wypełniona tylko przy [StanCofania.cofnieto] - do odświeżenia widoku.
  final MigawkaZapisu? migawka;

  /// Opis cofniętego zapisu ("ciasto = 2.0 kg") - znany także przy błędzie,
  /// bo trafia na stos od razu, razem z komendą.
  final String opis;

  const WynikCofania(this.stan, {this.migawka, this.opis = ''});
}

/// Jeden krok na stosie: OPIS ZNANY OD RAZU + MIGAWKA, KTÓRA DOPIERO SIĘ LICZY.
///
/// Dlaczego future, a nie gotowa migawka: odczyt plastra to transakcja SQLite,
/// czyli kilka przeskoków przez kanał platformy. Gdyby krok trafiał na stos
/// dopiero po jej zakończeniu (`await`, a potem `add`), o kolejności decydowałby
/// wyścig - a `wyczysc()` przy komendzie kontekstowej jest synchroniczne i
/// wchodziłoby w środek. Stos ma być odbiciem KOLEJNOŚCI KOMEND, a nie kolejności
/// kończenia się zapytań, więc krok odkładamy synchronicznie, a na wynik odczytu
/// czeka dopiero [StosCofania.cofnij].
class _WpisStosu {
  final Future<MigawkaZapisu?> przyszla;
  final String opis;

  _WpisStosu(this.przyszla, this.opis);
}

/// Stos cofania - pamięć ekranu głosowego, nie baza.
///
/// Świadome ograniczenia:
///  - stos żyje w pamięci ekranu. Wyjście z ekranu głosowego kończy cofanie.
///    Ta funkcja ma ratować pomyłkę sprzed kilkunastu sekund przy otwartym ulu,
///    a nie służyć za historię zmian,
///  - [maxKrokow] kroków. Głębiej nie ma sensu: nikt nie pamięta, co mówił 15
///    komend temu, a każde cofnięcie trzeba zapowiedzieć głosem,
///  - zmiana ula, korpusu lub daty CZYŚCI stos ([wyczysc]). Inaczej użytkownik
///    cofnąłby coś w ulu, którego nie widzi na ekranie.
class StosCofania {
  static const int maxKrokow = 5;

  final List<_WpisStosu> _stos = [];

  /// Blokada na czas przywracania - drugie "cofnij" w trakcie pierwszego
  /// weszłoby w środek transakcji i zostawiło plaster w połowie stanu.
  bool _wTrakcie = false;

  /// Ostatni błąd bazy (migawka albo przywracanie) - do diagnostyki na ekranie.
  String? _ostatniBlad;

  bool get pusty => _stos.isEmpty;
  bool get zajety => _wTrakcie;
  int get ile => _stos.length;
  String? get ostatniBlad => _ostatniBlad;

  /// Opis ostatniego zapisu - do zapowiedzi "cofnę: czerw kryty = 50%".
  String? get opisOstatniego => _stos.isEmpty ? null : _stos.last.opis;

  /// Zrzuca plaster bazy. Wołane PRZED wykonaniem komendy, a zwrócony future
  /// trafia na stos dopiero w [odloz] - bo dopiero po komendzie wiadomo, czy
  /// cokolwiek zapisała i pod jakim opisem.
  Future<MigawkaZapisu?> przygotuj(
    ZakresPlastra zakres, {
    required int pasiekaNr,
    required int ulNr,
    required int korpusNr,
  }) async {
    try {
      final wiersze = await _pobierzPlaster(zakres);
      final migawka = MigawkaZapisu(
        zakres: zakres,
        wiersze: wiersze,
        opis: '',
        pasiekaNr: pasiekaNr,
        ulNr: ulNr,
        korpusNr: korpusNr,
      );
      debugPrint('Cofanie: migawka gotowa - ${migawka.ileWierszy} wierszy '
          '(${wiersze.keys.join(", ")})');
      return migawka;
    } catch (e) {
      //nieudana migawka nie może przewrócić komendy - zapis ma się wykonać,
      //tylko bez możliwości cofnięcia. Błąd zapamiętujemy, bo ekran musi umieć
      //powiedzieć "nie udało się cofnąć" zamiast "nie ma czego cofnąć"
      _ostatniBlad = '$e';
      debugPrint('Cofanie: NIE UDAŁO SIĘ zdjąć migawki: $e');
      return null;
    }
  }

  /// Odkłada krok na stos. Wołane SYNCHRONICZNIE zaraz po komendzie, jeszcze
  /// zanim migawka się doczyta - patrz [_WpisStosu]. [opis] to tekst z wiersza
  /// "Zapis:".
  void odloz(Future<MigawkaZapisu?> przyszla, String opis) {
    _stos.add(_WpisStosu(przyszla, opis));
    if (_stos.length > maxKrokow) _stos.removeAt(0);
    debugPrint('Cofanie: na stosie $ile krok(ów), ostatni: „$opis"');
  }

  /// Przywraca stan sprzed ostatniej zapisującej komendy i zdejmuje ją ze stosu.
  Future<WynikCofania> cofnij() async {
    if (_wTrakcie || _stos.isEmpty) {
      return const WynikCofania(StanCofania.brak);
    }
    _wTrakcie = true;
    //krok zdejmujemy ZAWSZE, także gdy przywracanie padnie: gdyby został na
    //stosie, kolejne "cofnij" próbowałoby tego samego w kółko, zamiast sięgnąć
    //po krok wcześniejszy, który cofnąć się da
    final wpis = _stos.removeLast();
    try {
      //dopiero TU czekamy na odczyt plastra - w praktyce jest gotowy od dawna
      //(komenda i cofnięcie dzieli kilka sekund mowy), ale gdy nie jest, lepiej
      //poczekać ułamek sekundy niż cofnąć w oparciu o niedoczytany stan
      final migawka = await wpis.przyszla;
      if (migawka == null) {
        //migawka padła już przy zdejmowaniu (powód w [_ostatniBlad]) - nie ma
        //czego przywrócić, ale to AWARIA, a nie pusty stos
        debugPrint('Cofanie: krok „${wpis.opis}" nie ma migawki - '
            'zapis został w bazie');
        return WynikCofania(StanCofania.blad, opis: wpis.opis);
      }
      await _przywrocPlaster(migawka);
      debugPrint('Cofanie: przywrócono ${migawka.ileWierszy} wierszy '
          '(„${wpis.opis}")');
      return WynikCofania(StanCofania.cofnieto,
          migawka: migawka, opis: wpis.opis);
    } catch (e) {
      _ostatniBlad = '$e';
      debugPrint('Cofanie: nie udało się przywrócić plastra: $e');
      return WynikCofania(StanCofania.blad, opis: wpis.opis);
    } finally {
      _wTrakcie = false;
    }
  }

  /// Czyści stos - przy zmianie ula, korpusu, daty i przy wyjściu z ekranu.
  void wyczysc() {
    if (_stos.isEmpty) return;
    debugPrint('Cofanie: czyszczenie stosu ($ile krok(ów))');
    _stos.clear();
  }

  //--- warstwa bazy -------------------------------------------------------

  /// Tabele w kolejności zrzutu. `ule` i `pasieki` nie mają kolumny `data`,
  /// więc filtruje je sam numer pasieki/ula - i o to chodzi: belka ula sprzed
  /// komendy musi wrócić w całości, razem z matką, todo i ikoną.
  static const List<String> _tabele = ['ramka', 'info', 'ule', 'pasieki'];

  Future<Map<String, List<Map<String, Object?>>>> _pobierzPlaster(
      ZakresPlastra z) async {
    final db = await DBHelper.database();
    //CAŁY odczyt w jednej transakcji - patrz nagłówek pliku, akapit o wyścigu
    return db.transaction((txn) async {
      final wynik = <String, List<Map<String, Object?>>>{};
      for (final tabela in _tabele) {
        if (tabela == 'ramka' && !z.zRamkami) continue;
        final (where, argumenty) = _warunek(tabela, z);
        final wiersze = await txn.rawQuery('SELECT * FROM $tabela $where', argumenty);
        //kopia, bo sqflite zwraca mapy tylko do odczytu
        wynik[tabela] = wiersze.map((w) => Map<String, Object?>.from(w)).toList();
      }
      return wynik;
    });
  }

  Future<void> _przywrocPlaster(MigawkaZapisu migawka) async {
    final db = await DBHelper.database();
    await db.transaction((txn) async {
      for (final tabela in _tabele) {
        final zapisane = migawka.wiersze[tabela];
        if (zapisane == null) continue; //tabeli nie było w zakresie

        final (where, argumenty) = _warunek(tabela, migawka.zakres);

        //1. wiersze, których w migawce NIE MA, komenda dodała - kasujemy je
        final teraz = await txn.rawQuery('SELECT id FROM $tabela $where', argumenty);
        final byly = zapisane.map((w) => w['id']).toSet();
        for (final w in teraz) {
          final id = w['id'];
          if (!byly.contains(id)) {
            await txn.rawDelete('DELETE FROM $tabela WHERE id = ?', [id]);
          }
        }

        //2. wiersze z migawki wracają dosłownie. UPSERT, a nie INSERT - bo
        //komenda mogła je nadpisać, nie dodać ("czerw 50" -> "czerw 70")
        for (final w in zapisane) {
          await txn.insert(tabela, w,
              conflictAlgorithm: sql.ConflictAlgorithm.replace);
        }
      }
    });
  }

  /// Warunek WHERE dla tabeli w danym zakresie. Zwraca gotowy fragment SQL i
  /// listę parametrów - zapytania są parametryzowane, numery uli nigdy nie
  /// wchodzą do SQL przez sklejanie stringów.
  (String, List<Object?>) _warunek(String tabela, ZakresPlastra z) {
    if (tabela == 'pasieki') {
      return ('WHERE pasiekaNr = ?', [z.pasiekaNr]);
    }

    final warunki = <String>['pasiekaNr = ?'];
    final argumenty = <Object?>[z.pasiekaNr];

    //`ule` i `pasieki` nie mają kolumny `data` - trzymają stan bieżący, nie
    //historię, więc filtrowanie po dacie by je wycięło z migawki
    if (tabela == 'ramka' || tabela == 'info') {
      warunki.add('data = ?');
      argumenty.add(z.data);
    }

    if (!z.calaPasieka) {
      warunki.add('ulNr IN (${List.filled(z.uleNr.length, '?').join(',')})');
      argumenty.addAll(z.uleNr);
    }

    return ('WHERE ${warunki.join(' AND ')}', argumenty);
  }
}
