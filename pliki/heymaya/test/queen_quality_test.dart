// Jakość matki trafia do bazy jako GOŁE SŁOWO w języku ustawionym w chwili zapisu
// (kolumna info.wartosc, a po przeliczeniu flaga ule.matka1). Ikona kciuka liczyła
// się wcześniej z list literałów zaszytych w czterech ekranach - i to tylko polskich
// i angielskich, więc wpis zrobiony po niemiecku czy po włosku dostawał kciuk w górę.
// Ten test pilnuje, że jedna wspólna tabela z queen_helpers.dart zna wszystkie języki
// ORAZ wartości historyczne, których z bazy nikt już nie usunie.
import 'package:flutter_test/flutter_test.dart';
import 'package:heymaya/helpers/queen_helpers.dart';

void main() {
  group('kciuk w dół', () {
    const zle = <String>[
      // do wymiany - opcja, która 06.08.2026 zastąpiła "zła"
      'do wymiany', 'to replace', 'zu ersetzen', 'à remplacer',
      'a reemplazar', 'da sostituire', 'a substituir',
      // stara (angielskie "to exchange" zamienione wtedy na "old")
      'stara', 'old', 'alt', 'vieille', 'vieja', 'vecchia', 'velha',
      // mała / słaba
      'mała', 'small', 'klein', 'petite', 'pequeno', 'piccolo',
      'słaba', 'weak', 'schwach', 'faible', 'debil', 'debole', 'fraca',
    ];
    for (final w in zle) {
      test('"$w"', () => expect(qualityIsBad(w), isTrue));
    }

    test('wartości historyczne z bazy nadal dają kciuk w dół', () {
      // etykiety opcji "zła" sprzed zamiany na "do wymiany"
      for (final w in ['zła', 'canceled', 'schlecht', 'mauvaise', 'mala',
                       'cattiva', 'má']) {
        expect(qualityIsBad(w), isTrue, reason: w);
      }
      // angielska etykieta "stara" sprzed zamiany na "old"
      expect(qualityIsBad('to exchange'), isTrue);
      // wewnętrzna flaga belki ula (ule.matka1), nie etykieta z listy
      expect(qualityIsBad('zła'), isTrue);
      expect(qualityIsBad('ok'), isFalse);
    });
  });

  group('kciuk w górę', () {
    const dobre = <String>[
      'bardzo dobra', 'very good', 'sehr gut', 'très bonne', 'muy buena',
      'ottima', 'muito boa',
      'dobra', 'good', 'gut', 'bonne', 'buena', 'buona', 'boa',
      'duża', 'big', 'groß', 'grande',
      'ok',
    ];
    for (final w in dobre) {
      test('"$w"', () => expect(qualityIsBad(w), isFalse));
    }

    test('nieznana wartość NIE jest zła', () {
      // wpis z prehistorycznej wersji albo uszkodzony synchronizacją - lepiej
      // kciuk w górę niż czerwona ikona bez pokrycia w danych
      expect(qualityIsBad('jakieś dziwo'), isFalse);
    });
  });

  test('spacje i wielkość liter nie mają znaczenia', () {
    expect(qualityIsBad(' Do Wymiany '), isTrue);
    expect(qualityIsBad('ZU ERSETZEN'), isTrue);
    expect(qualityIsBad(' Bardzo Dobra '), isFalse);
  });

  test('pusta jakość nie rysuje kciuka w ogóle', () {
    expect(qualityIsSet(''), isFalse);
    expect(qualityIsSet('   '), isFalse);
    expect(qualityIsSet('0'), isFalse); // "brak wartości" w tej bazie
    expect(qualityIsSet('ok'), isTrue);
    expect(qualityIsSet('do wymiany'), isTrue);
  });

  test('ta sama etykieta w kilku językach ma jeden klucz', () {
    expect(qualityToKey('do wymiany'), kQualityToReplace);
    expect(qualityToKey('zu ersetzen'), kQualityToReplace);
    expect(qualityToKey('zła'), kQualityToReplace);
    expect(qualityToKey('grande'), kQualityBig); // fr/es/it/pt
    expect(qualityToKey('old'), kQualityOld);
    expect(qualityToKey('stara'), kQualityOld);
  });
}
