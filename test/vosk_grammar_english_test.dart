// Testy silnika-parsera gramatyki .yml (lib/helpers/vosk_grammar.dart) DLA
// PAKIETU LICZEBNIKÓW ANGIELSKICH.
//
// Uruchomienie:  flutter test test/vosk_grammar_english_test.dart
//
// PO CO OSOBNY PLIK. test/vosk_grammar_test.dart sprawdza silnik na
// assets/grammar/pol_vosk.yml (jezyk domyślny 'pl'). Ten plik sprawdza
// DOKŁADNIE TĘ SAMĄ implementację, ale z parametrem `jezyk: 'en'` (dodanym
// 03.09.2026), na assets/grammar/eng_vosk.yml - żeby udowodnić, że blocker
// "liczebniki na sztywno polskie" (patrz komentarz przy _PakietLiczb w
// vosk_grammar.dart) jest naprawiony, a nie tylko "wygląda naprawiony".
//
// STATUS eng_vosk.yml w dniu pisania tych testów: gramatyka NAPISANA i
// zwalidowana strukturalnie (patrz nagłówek pliku .yml), ale NIEPODŁĄCZONA
// do apki (nie ma jej w pubspec.yaml) i NIEPRZETESTOWANA na głosie - te testy
// sprawdzają wyłącznie silnik-parser w izolacji, tak jak dla polskiego.
//
// Oczekiwane wartości NIE są wymyślone - policzone transliteracją tego
// samego algorytmu na Python (ten sam sposób co przy pisaniu eng_vosk.yml,
// patrz pamięć sesji "voice_english_scoping"), potem PRZEPISANE tutaj jako
// asercje. Jeśli test tutaj padnie, port na Darta się rozjechał z tym, co
// faktycznie napisano w tym pliku.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hi_bees/helpers/vosk_grammar.dart';

late VoskGrammar silnik;

void main() {
  setUpAll(() {
    final plik = File('assets/grammar/eng_vosk.yml');
    expect(plik.existsSync(), isTrue,
        reason: 'brak assets/grammar/eng_vosk.yml - uruchom z katalogu projektu');
    silnik = VoskGrammar.zTekstu(plik.readAsStringSync(), jezyk: 'en');
  });

  group('wczytanie gramatyki angielskiej', () {
    test('parsuje wszystkie wyrażenia i intencje - te same co pol_vosk.yml', () {
      // 71 wyrażeń, 24 intencje - IDENTYCZNIE jak assets/grammar/pol_vosk.yml
      // (sprawdzone niezależnie skryptem Python przy pisaniu eng_vosk.yml -
      // ten sam zestaw kluczy intencji/slotów w obu plikach).
      expect(silnik.liczbaWyrazen, 71,
          reason: 'zmieniła się liczba wyrażeń w assets/grammar/eng_vosk.yml');
      expect(silnik.intencje.length, 24);
      expect(silnik.intencje, contains('setStore'));
      expect(silnik.intencje, contains('setMoveBody'));
      expect(silnik.intencje, contains('voiceStart'));
      expect(silnik.intencje, contains('setHivesRange'));
    });

    test('brak słów spoza słownika modelu EN (poza celowym "excluder")', () {
      // 166 = policzone Python-em przy pisaniu tego testu. "excluder" NIE
      // jest w słowniku modelu (patrz nagłówek eng_vosk.yml) - zostaje jako
      // pierwsza, udokumentowana opcja alternatywy [excluder,grid,grate].
      expect(silnik.slowa().length, 166,
          reason: 'zmienił się zbiór słów - sprawdź OOV wobec '
              'pliki/vosk_slownik_eng.txt');
      expect(silnik.liczebniki(), contains('twenty'));
      expect(silnik.liczebniki(), contains('percent'));
      expect(silnik.liczebniki(), contains('hundred'),
          reason: 'słowo-mnożnik setek (angielska setka to DWA słowa)');
    });
  });

  group('liczebniki angielskie - blocker naprawiony', () {
    test('liczby jednocyfrowe i dwucyfrowe', () {
      expect(silnik.rozpoznaj('insert body number three').slots!['nrXOfBody'],
          '3');
      expect(
          silnik
              .rozpoznaj('open apiary number fifty one')
              .slots!['nrXXOfApiary'],
          '51');
    });

    test('zakresy typów są pilnowane (SingleDigitInteger 0-9)', () {
      expect(silnik.rozpoznaj('open body number ten').isUnderstood, isFalse,
          reason: 'body number 0-9, "ten" jest poza zakresem');
    });

    test('setka to DWA słowa ("one hundred"), rozdzielona między dwa sloty', () {
      // Odpowiednik polskiego testu "setki i dziesiątki rozdzielane między
      // dwa sloty" (roztocza sto trzydzieści sztuk) - tu $hundred (słowo) +
      // $pv.TwoDigitInteger (liczba), KOLEJNOŚĆ slotów jak w wypowiedzi.
      final w = silnik.rozpoznaj('insert hive number one hundred twenty');
      expect(w.slots!.keys.toList(), ['hiveState', 'nrXXOfHiveH', 'nrXXOfHive']);
      expect(w.slots!['nrXXOfHiveH'], 'one hundred');
      expect(w.slots!['nrXXOfHive'], '20');
    });

    test('procent z "percent" i bez - oba dają wartość ze znakiem %', () {
      for (final t in [
        'food twenty percent on the left',
        'food twenty on the left',
      ]) {
        final w = silnik.rozpoznaj(t);
        expect(w.intent, 'setStore', reason: t);
        expect(w.slots!['food'], '20%', reason: t);
        expect(w.slots!['siteOfFrame'], 'left', reason: t);
      }
    });

    test('wypowiedź ZE słowem "percent" wygrywa z wersją bez niego', () {
      final t = silnik.wszystkieTrafienia('food twenty percent on the left');
      expect(t.first.kara, 0);
    });

    test('"one hundred percent" = 100% (setka + procent naraz)', () {
      // Krytyczny przypadek brzegowy: $pv.Percent ma zakres [0,100], więc
      // "sto procent" (100%) MUSI dać się przeczytać z samej setki, bez
      // żadnej dziesiątki/jedności po niej. To NIE działało przed naprawą
      // blockera - _kandydaciLiczby w ogóle nie znał słowa "hundred".
      final w = silnik.rozpoznaj('food one hundred percent');
      expect(w.intent, 'setStore');
      expect(w.slots!['food'], '100%');
    });

    test('gramatyka recognizera wiąże "percent" bigramami', () {
      final frazy = silnik.frazy();
      expect(frazy, contains('twenty percent'));
      expect(frazy, contains('hundred percent'),
          reason: 'mostek dla setek złożonych z dwóch słów');
    });

    test('gramatyka recognizera wiąże łącznik zakresu "to" bigramami', () {
      // Zgłoszenie z urządzenia 03.09.2026: "set frame from X to Y" działało
      // tylko dla niektórych X - "to" wchodziło do gramatyki jako samotna,
      // jednowyrazowa fraza (setFrames/setHivesRange rozcinają wyrażenie na
      // dwóch $pv.TwoDigitInteger). Mostek w obie strony, bo liczba PO "to"
      // ma ten sam problem co liczba PRZED nim.
      final frazy = silnik.frazy();
      expect(frazy, contains('two to'), reason: '"two"/"to" to homofony - ten '
          'przypadek zgłoszony jako najbardziej zawodny');
      expect(frazy, contains('to two'));
      expect(frazy, contains('three to'));
      expect(frazy, contains('to five'));
    });

    test('gramatyka recognizera wiąże jednostki miary z liczbą', () {
      // Zgłoszenie z urządzenia 05.09.2026: "two liters" wchodziło "dość
      // opornie". Jednostka stoi za $pv, więc po rozcięciu wyrażenia trafiała
      // do gramatyki jako samotna, jednowyrazowa fraza - bez bigramu
      // wiążącego ją z poprzedzającą liczbą (mostekPoSlocie).
      final frazy = silnik.frazy();
      expect(frazy, contains('two liters'));
      expect(frazy, contains('three kilo'));
      expect(frazy, contains('five units'));
      // Te dwie jednostki stoją PO nawiasie, w którym siedzi liczba
      // ("acid (and) ($pv:acid) (milliliter, milliliters)") - łapie je dopiero
      // zbiór FIRST liczony z ciągiem dalszym sekwencji nadrzędnej.
      expect(frazy, contains('ten mites'));
      expect(frazy, contains('twenty milliliters'));
      // Dalszy ciąg komendy, nie tylko jednostka.
      expect(frazy, contains('twenty on'),
          reason: '"drone brood twenty percent on the left"');
    });
  });

  group('excluder - jedyne brakujące słowo, łata [excluder,grid,grate]', () {
    test('wszystkie trzy alternatywy działają', () {
      expect(silnik.rozpoznaj('remove excluder').intent, 'setEquipment');
      expect(silnik.rozpoznaj('remove grid').intent, 'setEquipment');
      expect(silnik.rozpoznaj('remove grate').intent, 'setEquipment');
      expect(
          silnik.rozpoznaj('grid on body number one').slots!['excluder'], '1');
      expect(
          silnik.rozpoznaj('grate on body number one').slots!['excluder'],
          '1');
    });
  });

  group('8 intencji bez odpowiednika w eng1.yml (dodane po migracji)', () {
    test('sterowanie sesją', () {
      for (final t in ['hey maya start', 'hey maya begin']) {
        expect(silnik.rozpoznaj(t).intent, 'voiceStart', reason: t);
      }
      for (final t in ['hey maya stop', 'hey maya done', 'hey maya finished']) {
        expect(silnik.rozpoznaj(t).intent, 'voiceStop', reason: t);
      }
    });

    test('dyktowanie notatki - dwa ujścia się nie mylą', () {
      expect(silnik.rozpoznaj('hey maya note').intent, 'voiceNote');
      expect(silnik.rozpoznaj('hey maya note for notepad').intent,
          'voiceNotepad');
      expect(silnik.rozpoznaj('hey maya note for notepad').intent,
          isNot('voiceNote'));
    });

    test('cofanie wymaga pełnego zawołania', () {
      expect(silnik.rozpoznaj('hey maya undo last save').intent, 'voiceUndo');
      expect(silnik.rozpoznaj('hey maya undo last entry').intent, 'voiceUndo');
      expect(silnik.rozpoznaj('undo last save').isUnderstood, isFalse,
          reason: 'komenda zmieniająca bazę wymaga "hey maya"');
    });

    test('zakres uli: setHivesRange', () {
      final w = silnik.rozpoznaj('set hives from five to ten');
      expect(w.intent, 'setHivesRange');
      expect(w.slots!['nrXXOdHive'], '5');
      expect(w.slots!['nrXXDoHive'], '10');
    });

    test('setChange: numer ramki po przeglądzie', () {
      final w =
          silnik.rozpoznaj('frame number one after inspection number ten');
      expect(w.intent, 'setChange');
      expect(w.slots!['nrXXOfFrame'], '1');
      expect(w.slots!['nrXXOfFramePo'], '10');
    });

    test('setMoveBody: oba warianty (box i half box)', () {
      final w1 = silnik
          .rozpoznaj('move to hive number two box number one frame number four');
      expect(w1.intent, 'setMoveBody');
      expect(w1.slots!['nrTempHive'], '2');
      expect(w1.slots!['nrTempBody'], '1');
      expect(w1.slots!['nrTempFrame'], '4');

      final w2 = silnik.rozpoznaj(
          'move to hive number two half box number one frame number four');
      expect(w2.intent, 'setMoveBody');
      expect(w2.slots!['nrTempHalfBody'], '1');
    });
  });

  group('poprawki wobec eng1.yml (błędy oryginału naprawione)', () {
    test('queenQuality "old", nie "canceled" (błąd w eng1.yml)', () {
      expect(silnik.rozpoznaj('queen is old').slots!['queenQuality'], 'old');
      expect(silnik.rozpoznaj('queen is to exchange').slots!['queenQuality'],
          'to exchange');
      expect(silnik.rozpoznaj('queen is canceled').isUnderstood, isFalse,
          reason: '"canceled" to była nazwa klucza kodu, nie słowo do '
              'wypowiedzenia - usunięte z gramatyki');
    });

    test('setDate: "month", nie "mouth" (literówka w eng1.yml)', () {
      final w = silnik.rozpoznaj('set other month twenty one');
      expect(w.intent, 'setDate');
      expect(w.slots!['dateMonth'], '21');
    });

    test('"side", nie "site" (błąd w eng1.yml, wszędzie)', () {
      expect(
          silnik
              .rozpoznaj('insert frame number four on the right side')
              .isUnderstood,
          isTrue);
    });

    test('quality/colonyState/queenQuality: "okay" jako synonim "ok"', () {
      expect(silnik.rozpoznaj('bottom board is okay').slots!['bottomBoard'],
          'okay');
      expect(silnik.rozpoznaj('colony is okay').slots!['colonyState'], 'okay');
    });
  });

  group('nieznany język', () {
    test('rzuca BladGramatyki, nie milczy', () {
      expect(() => VoskGrammar.zTekstu('context:\n  expressions:\n', jezyk: 'de'),
          throwsA(isA<BladGramatyki>()));
    });
  });

  group('domyślny język zostaje polski (bez regresji dla pol_vosk.yml)', () {
    test('VoskGrammar.zTekstu bez `jezyk` nadal czyta polskie liczebniki', () {
      final plikPl = File('assets/grammar/pol_vosk.yml');
      expect(plikPl.existsSync(), isTrue);
      final pl = VoskGrammar.zTekstu(plikPl.readAsStringSync());
      final w = pl.rozpoznaj('otwórz pasiekę numer pięćdziesiąt jeden');
      expect(w.slots!['nrXXOfApiary'], '51');
    });
  });
}
