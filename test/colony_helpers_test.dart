// Ocena stanu rodziny i kolor ikony na belce ula (lib/helpers/colony_helpers.dart).
// Kolor NAJGORSZY wygrywa: matka / do zrobienia (ule.ikona) kontra stan rodziny.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hi_bees/helpers/colony_helpers.dart';
import 'package:hi_bees/helpers/parametr_nazwy.dart';

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
      expect(ikonaNaBelce('green', 'zła'), 'yellow');
      expect(ikonaNaBelce('orange', 'zła'), 'orange');
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
