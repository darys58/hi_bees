// Ocena stanu rodziny i kolor ikony na belce ula (lib/helpers/colony_helpers.dart).
// Kolor NAJGORSZY wygrywa: matka / do zrobienia (ule.ikona) kontra stan rodziny.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heymaya/helpers/colony_helpers.dart';
import 'package:heymaya/helpers/kolor_przegladu.dart';
import 'package:heymaya/helpers/parametr_nazwy.dart';

void main() {
  group('ocenaStanuRodziny', () {
    test('wartości w różnych językach', () {
      expect(ocenaStanuRodziny('łagodna'), OcenaRodziny.dobra);
      expect(ocenaStanuRodziny('ok'), OcenaRodziny.dobra);
      expect(ocenaStanuRodziny('w kłębie'), OcenaRodziny.dobra);
      expect(ocenaStanuRodziny('zła'), OcenaRodziny.uwaga); //agresywna zapisywana jako "zła"
      expect(ocenaStanuRodziny('w nastroju do ucieczki'), OcenaRodziny.uwaga);
      expect(ocenaStanuRodziny('swarming mood'), OcenaRodziny.uwaga);
      expect(ocenaStanuRodziny('strutowiała'), OcenaRodziny.zla);
      expect(ocenaStanuRodziny('drohnenbrütig'), OcenaRodziny.zla);
      expect(ocenaStanuRodziny('chora'), OcenaRodziny.zla);
      expect(ocenaStanuRodziny('sick'), OcenaRodziny.zla);
      expect(ocenaStanuRodziny('nie żyje'), OcenaRodziny.martwa);
      expect(ocenaStanuRodziny('dead'), OcenaRodziny.martwa);
      expect(ocenaStanuRodziny(''), OcenaRodziny.brak);
    });
  });

  group('ikonaSilyRodziny', () {
    test('buźka od uśmiechniętej do smutnej', () {
      expect(ikonaSilyRodziny('bardzo silna')!.icon, Icons.sentiment_very_satisfied);
      expect(ikonaSilyRodziny('strong')!.icon, Icons.sentiment_satisfied_alt);
      expect(ikonaSilyRodziny('norma')!.icon, Icons.sentiment_neutral);
      expect(ikonaSilyRodziny('słaba')!.icon, Icons.sentiment_dissatisfied);
      expect(ikonaSilyRodziny('very weak')!.icon, Icons.sentiment_very_dissatisfied);
      expect(ikonaSilyRodziny(''), isNull);
    });
    test('nie żyje - ikonka jak brak matki', () {
      expect(ikonaStanuRodziny('nie żyje')!.icon, Icons.dangerous_outlined);
    });
  });

  group('ikonaNaBelce', () {
    test('rodzina dobra nie zmienia ikony', () {
      expect(ikonaNaBelce('green', 'ok'), 'green');
      expect(ikonaNaBelce('red', 'łagodna'), 'red');
      expect(ikonaNaBelce('yellow', ''), 'yellow');
    });
    test('najgorszy kolor wygrywa', () {
      expect(ikonaNaBelce('green', 'zła'), 'orange'); //agresywna = pomarańczowy (20.10.2026)
      expect(ikonaNaBelce('yellow', 'w nastroju do ucieczki'), 'orange');
      expect(ikonaNaBelce('orange', 'zła'), 'orange');
      expect(ikonaNaBelce('red', 'zła'), 'red');
      expect(ikonaNaBelce('yellow', 'chora'), 'red');
      expect(ikonaNaBelce('orange', 'strutowiała'), 'red');
    });
    test('matka strutowiała (matka3 trutowa) daje czerwony', () {
      expect(ikonaNaBelce('green', '', matka3: 'trutowa'), 'red');
      expect(ikonaNaBelce('orange', 'ok', matka3: 'trutowa'), 'red');
      expect(ikonaNaBelce('green', 'nie żyje', matka3: 'trutowa'), 'dead');
      expect(ikonaNaBelce('black', '', matka3: 'trutowa'), 'black');
      expect(ikonaNaBelce('green', '', matka3: 'unasienniona'), 'green');
    });
    test('nie żyje = dead, ul zlikwidowany zostaje black', () {
      expect(ikonaNaBelce('red', 'nie żyje'), 'dead');
      expect(ikonaNaBelce('black', 'chora'), 'black');
      expect(ikonaNaBelce('black', 'nie żyje'), 'black');
    });
  });

  group('czyMatkaTrutowa', () {
    test('nowy napis, dawne "trutówka" i inne języki', () {
      expect(czyMatkaTrutowa('strutowiała'), isTrue);
      expect(czyMatkaTrutowa('trutówka'), isTrue); //wpisy sprzed 15.10.2026
      expect(czyMatkaTrutowa('drone laying'), isTrue);
      expect(czyMatkaTrutowa('drohnenbrütig'), isTrue);
      expect(czyMatkaTrutowa('dziewica'), isFalse);
    });
  });

  group('do zrobienia i mateczniki (20.10.2026)', () {
    test('zadanieDoZrobienia - "można izolować" nie barwi', () {
      expect(zadanieDoZrobienia('trzeba wirować'), isTrue);
      expect(zadanieDoZrobienia('work frame'), isTrue);
      expect(zadanieDoZrobienia('można izolować'), isFalse);
      expect(zadanieDoZrobienia('to insulate'), isFalse);
      expect(zadanieDoZrobienia('kann isoliert werden'), isFalse);
      expect(zadanieDoZrobienia(''), isFalse);
      expect(zadanieDoZrobienia('0'), isFalse);
      expect(zadanieDoZrobienia(null), isFalse);
    });
    test('ikonaNaBelce z zadaniem i matecznikami', () {
      expect(ikonaNaBelce('green', '', todo: 'trzeba usunąć'), 'yellow');
      expect(ikonaNaBelce('yellow', '', todo: 'można izolować'), 'green'); //stary zapis
      expect(ikonaNaBelce('yellow', '', todo: '0'), 'green');
      expect(ikonaNaBelce('yellow', ''), 'yellow'); //bez todo - bez zmian
      expect(ikonaNaBelce('green', '', todo: '', mateczniki: 3), 'orange');
      expect(ikonaNaBelce('green', '', todo: '', mateczniki: 3, usunmat: 3), 'green');
      expect(ikonaNaBelce('yellow', '', todo: 'ramka pracy', mateczniki: 2, usunmat: 1), 'orange');
      expect(ikonaNaBelce('red', '', todo: '', mateczniki: 2), 'red');
      expect(ikonaNaBelce('black', '', todo: 'ramka pracy', mateczniki: 2), 'black');
    });
    test('kolorPrzegladuZRamek', () {
      expect(kolorPrzegladuZRamek([]), 'green');
      expect(kolorPrzegladuZRamek([{'zasob': 13, 'wartosc': 'można izolować'}]), 'green');
      expect(kolorPrzegladuZRamek([{'zasob': 13, 'wartosc': 'trzeba wirować'}]), 'yellow');
      expect(kolorPrzegladuZRamek([{'zasob': 11, 'wartosc': '2'}]), 'orange');
      expect(kolorPrzegladuZRamek([
        {'zasob': 11, 'wartosc': '2'}, {'zasob': 11, 'wartosc': '1'}, {'zasob': 12, 'wartosc': '3'},
        {'zasob': 13, 'wartosc': 'ramka pracy'},
      ]), 'yellow'); //wszystkie mateczniki usunięte
      expect(kolorPrzegladuZRamek([
        {'zasob': 13, 'wartosc': 'ramka pracy'}, {'zasob': 11, 'wartosc': '1'},
      ]), 'orange');
    });
  });

  group('ikonaPasiekiZUli', () {
    test('najgorsza, bez zlikwidowanych, martwa jak czerwona', () {
      expect(ikonaPasiekiZUli([]), 'green');
      expect(ikonaPasiekiZUli(['green', 'yellow', 'black']), 'yellow');
      expect(ikonaPasiekiZUli(['orange', 'yellow']), 'orange');
      expect(ikonaPasiekiZUli(['green', 'dead']), 'red');
      expect(ikonaPasiekiZUli(['black']), 'green');
    });
  });
}
