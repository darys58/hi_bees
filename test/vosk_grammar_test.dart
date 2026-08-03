// Testy silnika-parsera gramatyki .yml (lib/helpers/vosk_grammar.dart).
//
// Uruchomienie:  flutter test test/vosk_grammar_test.dart
//
// Oczekiwane wartości NIE są wymyślone - pochodzą z referencyjnej
// implementacji w Pythonie (pliki/vosk_parser_ref.py), przetestowanej na
// pliki/lista_komend.txt i na realnym nagraniu z iPhone'a przez
// pliki/vosk_e2e_test.py. Jeśli test tutaj padnie, a referencja przechodzi,
// to znaczy, że port na Darta się rozjechał.
//
// Gramatykę czytamy z pliku, nie z rootBundle - testy jednostkowe działają
// na maszynie hosta, więc dart:io jest prostsze i nie wymaga inicjalizacji
// bindingów Fluttera.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hi_bees/helpers/vosk_grammar.dart';

late VoskGrammar silnik;

void main() {
  setUpAll(() {
    final plik = File('assets/grammar/pol_vosk.yml');
    expect(plik.existsSync(), isTrue,
        reason: 'brak assets/grammar/pol_vosk.yml - uruchom z katalogu projektu');
    silnik = VoskGrammar.zTekstu(plik.readAsStringSync());
  });

  group('wczytanie gramatyki', () {
    test('parsuje wszystkie wyrażenia i intencje', () {
      // Liczby celowo dokładne - wychwytują sytuację, w której edycja .yml
      // cicho wywala wyrażenie (np. przez zły cudzysłów). Po ŚWIADOMEJ zmianie
      // gramatyki trzeba je tu podbić.
      expect(silnik.liczbaWyrazen, 62,
          reason: 'zmieniła się liczba wyrażeń w assets/grammar/pol_vosk.yml');
      expect(silnik.intencje.length, 20);
      expect(silnik.intencje, contains('setStore'));
      expect(silnik.intencje, contains('setMoveBody'));
    });

    test('brak słów spoza gramatyki i komplet liczebników', () {
      // 218 słów literalnych - ta liczba jest zweryfikowana wobec słownika
      // modelu (pliki/vosk_gramatyka_test.py --oov: zero OOV). Po zmianie .yml
      // uruchom --oov i podbij tę liczbę, jeśli zmiana była zamierzona.
      expect(silnik.slowa().length, 218,
          reason: 'zmienił się zbiór słów - sprawdź OOV wobec słownika modelu');
      expect(silnik.liczebniki(), contains('pięćdziesiąt'));
      expect(silnik.liczebniki(), contains('procent'));
    });

    test('niepoprawna gramatyka wywala się, a nie milczy', () {
      expect(
          () => VoskGrammar.zTekstu('context:\n  expressions:\n'
              '    setX:\n      - ustaw \$nieistniejacy:klucz\n  slots:\n'),
          throwsA(isA<BladGramatyki>()));
      expect(() => VoskGrammar.zTekstu('context:\n  slots:\n'),
          throwsA(isA<BladGramatyki>()));
    });
  });

  group('kontrakt zgodny z RhinoInference', () {
    test('procent zwraca wartość ZE ZNAKIEM %', () {
      // voice_screen2.dart ~4281 robi int.parse(x.replaceAll(RegExp('%'), ''))
      final w = silnik.rozpoznaj('pokarm dwadzieścia procent z lewej');
      expect(w.isUnderstood, isTrue);
      expect(w.slots!['food'], '20%');
    });

    test('liczby całkowite bez znaku procenta', () {
      final w = silnik.rozpoznaj('otwórz ramkę numer cztery');
      expect(w.slots!['nrXXOfFrame'], '4');
    });

    test('KOLEJNOŚĆ slotów = kolejność wypowiedzi (setki przed dziesiątkami)', () {
      // voice_screen2.dart ~1547 dodaje setki do już policzonych dziesiątek,
      // więc nrXXOfHiveH MUSI przyjść przed nrXXOfHive.
      final w = silnik.rozpoznaj('wstaw ul numer sto dwadzieścia');
      expect(w.slots!.keys.toList(), ['hiveState', 'nrXXOfHiveH', 'nrXXOfHive']);
      expect(w.slots!['nrXXOfHiveH'], 'sto'); // slot zwraca SŁOWO, kod mapuje na 100
      expect(w.slots!['nrXXOfHive'], '20');
    });

    test('nierozpoznane daje isUnderstood = false', () {
      final w = silnik.rozpoznaj('jakiś kompletny bezsens');
      expect(w.isUnderstood, isFalse);
      expect(w.slots, isNull);
    });
  });

  group('przyimki, których Vosk nie zwraca', () {
    test('brak "z" nie psuje komendy', () {
      // ZMIERZONE na nagraniu: Vosk zwraca "procent lewej", nie "z lewej".
      final w = silnik.rozpoznaj('pokarm pięćdziesiąt procent lewej');
      expect(w.intent, 'setStore');
      expect(w.slots!['food'], '50%');
      expect(w.slots!['siteOfFrame'], 'lewej');
    });

    test('brak "w" nie psuje komendy', () {
      final w = silnik.rozpoznaj('ustaw liczbę ramek korpusie dziesięć');
      expect(w.intent, 'setEquipment');
      expect(w.slots!['numberOfFrame'], '10');
    });

    test('slot zwraca KANONICZNĄ wartość z .yml, mimo braku przyimka', () {
      // Kluczowe: voice_screen2.dart ~10300 ma case 'przesuń w prawo'.
      // Gdyby parser zwrócił to, co usłyszał ("przesuń prawo"), komenda
      // przestałaby działać.
      for (final tekst in ['przesuń prawo', 'przesuń w prawo']) {
        final w = silnik.rozpoznaj(tekst);
        expect(w.slots!['isDone'], 'przesuń w prawo', reason: tekst);
      }
    });

    test('przyimek nie otwiera komendy', () {
      expect(silnik.slowaOtwierajace(), isNot(contains('z')));
      expect(silnik.slowaOtwierajace(), isNot(contains('w')));
      expect(silnik.slowaOtwierajace(), contains('pokarm'));
      expect(silnik.slowaOtwierajace(), contains('otwórz'));
    });

    test('brak "procent" nie psuje komendy', () {
      // Zgłoszone z urządzenia 02.08.2026: "procent" bywa gubione tak samo jak
      // przyimki - nieakcentowane, nagłosowe [p] wtapia się w wygłos
      // liczebnika. Wartość slotu MUSI zostać ze znakiem % (kontrakt).
      for (final tekst in [
        'larwy dziesięć procent z prawej',
        'larwy dziesięć z prawej',
        'larwy dziesięć prawej',
      ]) {
        final w = silnik.rozpoznaj(tekst);
        expect(w.intent, 'setStore', reason: tekst);
        expect(w.slots!['larvae'], '10%', reason: tekst);
        expect(w.slots!['siteOfFrame'], 'prawej', reason: tekst);
      }
      expect(silnik.rozpoznaj('zostało dwadzieścia pokarmu').slots!['leftFood'],
          '20%');
    });

    test('wypowiedź ZE słowem "procent" wygrywa z wersją bez niego', () {
      // Kara za pominięcie ma trzymać kolejność trafień - inaczej dopasowanie
      // bez "procent" mogłoby przykryć poprawne.
      final t = silnik.wszystkieTrafienia('miód pięćdziesiąt procent z lewej');
      expect(t.first.kara, 0);
    });

    test('gramatyka recognizera wiąże "procent" bigramami', () {
      // Samotna fraza "procent" nie daje modelowi języka żadnego przejścia do
      // dalszego ciągu komendy - stąd mostki po obu stronach słowa.
      final frazy = silnik.frazy();
      expect(frazy, contains('dziesięć procent'));
      expect(frazy, contains('procent z prawej strony'));
      expect(frazy, contains('procent pokarmu'));
    });
  });

  group('sterowanie sesją: hej maja start/stop', () {
    // Te dwie intencje zastępują przycisk START/STOP z voice_screen2 i są
    // obsługiwane w voice_vosk_screen.dart PRZED switchem prettyPrintInference.
    test('start otwiera sesję w każdym wariancie', () {
      for (final t in [
        'hej maja start',
        'hej maja zaczynamy',
        'hej maja startujemy',
      ]) {
        expect(silnik.rozpoznaj(t).intent, 'voiceStart', reason: t);
      }
    });

    test('stop zamyka sesję w każdym wariancie', () {
      for (final t in [
        'hej maja stop',
        'hej maja kończymy',
        'hej maja koniec',
      ]) {
        expect(silnik.rozpoznaj(t).intent, 'voiceStop', reason: t);
      }
    });

    test('samo "hej maja" nic nie robi', () {
      // Wybudzenie bez decyzji nie może otwierać sesji - inaczej wystarczyłoby
      // wymówić imię w rozmowie, żeby ekran zaczął przyjmować komendy.
      expect(silnik.rozpoznaj('hej maja').isUnderstood, isFalse);
      expect(silnik.rozpoznaj('maja start').isUnderstood, isFalse);
    });

    test('frazy sesji są w gramatyce recognizera', () {
      // W czuwaniu recognizer dostaje TYLKO te frazy - muszą wyjść z silnika
      // w całości, bo inaczej nie ma czym ograniczyć gramatyki.
      final frazy = silnik.frazy();
      expect(frazy, contains('hej maja start'));
      expect(frazy, contains('hej maja stop'));
      expect(silnik.slowaOtwierajace(), contains('hej'));
    });

    test('gramatyka czuwania zawiera WYŁĄCZNIE frazy sesji', () {
      // W czuwaniu recognizer nie może znać komend pasiecznych - inaczej
      // rozmowa przy ulu miałaby czym otworzyć nasłuch. 6 fraz = start x3
      // (start, zaczynamy, startujemy), stop x3, bez liczebników i bez
      // wartości slotów.
      final czuwanie = silnik.frazy(intencje: {'voiceStart', 'voiceStop'});
      expect(czuwanie.length, 6);
      expect(czuwanie.every((f) => f.startsWith('hej maja')), isTrue,
          reason: 'do czuwania wciekła fraza spoza sesji: $czuwanie');
      // Zawężenie nie może uszkodzić pełnej gramatyki.
      expect(silnik.frazy().length, 3079); //+1: "hej maja startujemy"
    });
  });

  group('aliasy słów spoza słownika modelu', () {
    // Model Vosk nie zna "nakrop", "węza", "pierzga", "trut" - .yml podstawia
    // słowa, które model naprawdę słyszy. Szczegóły w komentarzu .yml.
    test('na grób = nakrop (slot food)', () {
      final w = silnik.rozpoznaj('na grób dziesięć procent z prawej');
      expect(w.intent, 'setStore');
      expect(w.slots!['food'], '10%');
    });

    test('węża = węza, pierzcha = pierzga, trud = trut', () {
      expect(silnik.rozpoznaj('węża sto procent z obu stron').slots!['wax'],
          '100%');
      expect(silnik.rozpoznaj('pierzcha dziesięć procent').slots!['pollen'],
          '10%');
      expect(silnik.rozpoznaj('trud piętnaście procent').slots!['drone'], '15%');
    });

    test('samo "nakrop" nie jest rozpoznawane (nie ma go w słowniku modelu)',
        () {
      expect(silnik.rozpoznaj('nakrop dziesięć procent').isUnderstood, isFalse);
    });
  });

  group('liczebniki', () {
    test('zakresy typów są pilnowane', () {
      // SingleDigitInteger: numer korpusu 0-9, więc "dziesięć" nie przejdzie.
      expect(silnik.rozpoznaj('otwórz korpus numer trzy').slots!['nrXOfBody'],
          '3');
      expect(silnik.rozpoznaj('otwórz korpus numer dziesięć').isUnderstood,
          isFalse);
    });

    test('setki i dziesiątki rozdzielane między dwa sloty', () {
      final w = silnik.rozpoznaj('roztocza sto trzydzieści sztuk');
      expect(w.slots!['varroaH'], 'sto');
      expect(w.slots!['varroa'], '30');
    });

    test('liczby złożone', () {
      expect(
          silnik
              .rozpoznaj('otwórz pasiekę numer pięćdziesiąt jeden')
              .slots!['nrXXOfApiary'],
          '51');
      expect(silnik.rozpoznaj('zostało zero procent pokarmu').slots!['leftFood'],
          '0%');
    });
  });

  group('po jednej komendzie z każdej intencji', () {
    // Wartości wygenerowane z referencji Pythona (vosk_parser_ref.py).
    final przypadki = <List<Object>>[
      ['otwórz pasiekę numer pięćdziesiąt jeden', 'setApiary'],
      ['otwórz ul numer pięć', 'setHive'],
      ['otwórz korpus numer jeden', 'setBody'],
      ['otwórz ramkę numer cztery z lewej strony', 'setFrame'],
      ['pokarm dwadzieścia procent z lewej', 'setStore'],
      ['otwórz pół korpus numer dwa', 'setHalfBody'],
      ['otwórz wszystkie ule', 'setAllHives'],
      ['zostało zero procent pokarmu', 'setFeeding'],
      ['kwas dwa mili gramy', 'setTreatment'],
      ['usuń kratę', 'setEquipment'],
      ['matka ma zielony znak dziewięć', 'setQueen'],
      ['przegląd pomóż mi', 'setHelp'],
      ['ustaw inny dzień dwadzieścia jeden', 'setDate'],
      ['rodzina zawiązała kłąb', 'setColony'],
      ['zbiór miodu dwa razy mała ramka', 'setHarvest'],
      ['ustaw ramkę od dwa do dziewięć', 'setFrames'],
      ['ramka numer jeden po przeglądzie numer dziesięć', 'setChange'],
      ['przenieś korpus dwa ramka cztery', 'setMoveBody'],
    ];

    for (final p in przypadki) {
      test('${p[1]}: ${p[0]}', () {
        final w = silnik.rozpoznaj(p[0] as String);
        expect(w.isUnderstood, isTrue, reason: 'brak dopasowania: ${p[0]}');
        expect(w.intent, p[1]);
        expect(w.slots, isNotEmpty);
      });
    }
  });

  group('sloty wielosłowne i wartości opisowe', () {
    test('wartość wielosłowna wraca w całości', () {
      expect(silnik.rozpoznaj('rodzina zawiązała kłąb').slots!['colonyState'],
          'zawiązała kłąb');
      expect(silnik.rozpoznaj('trzeba usunąć').slots!['toDo'], 'trzeba usunąć');
      expect(silnik.rozpoznaj('matka jest do wymiany').slots!['queenQuality'],
          'do wymiany');
    });

    test('usuń/wstaw ramkę trafia do isDone', () {
      expect(silnik.rozpoznaj('usuń ramkę').slots!['isDone'], 'usuń ramkę');
      expect(silnik.rozpoznaj('wstaw ramkę').slots!['isDone'], 'wstaw ramkę');
    });
  });

  group('poprawki gramatyki z 01.08.2026', () {
    test('podłoga bez słowa "jest"', () {
      // "jest" uopcjonalnione - "podłoga wyczyszczona" to naturalna forma.
      for (final t in ['podłoga wyczyszczona', 'podłoga jest wyczyszczona']) {
        expect(silnik.rozpoznaj(t).slots!['bottomBoard'], 'wyczyszczona',
            reason: t);
      }
    });

    test('zbiór miodu w liczbie pojedynczej: "jeden raz"', () {
      expect(
          silnik.rozpoznaj('zbiór miodu jeden raz duża ramka')
              .slots!['honeyBigHarvest'],
          '1');
      expect(
          silnik.rozpoznaj('zbiór miodu dwa razy mała ramka')
              .slots!['honeySmallHarvest'],
          '2');
    });

    test('paski nadal wymagają czasownika (decyzja projektowa)', () {
      expect(silnik.rozpoznaj('wstaw paski pięć sztuk').slots!['biovarBelts'],
          '5');
      expect(silnik.rozpoznaj('paski pięć sztuk').isUnderstood, isFalse);
    });

    test('ul i korpus nadal wymagają czasownika (decyzja projektowa)', () {
      expect(silnik.rozpoznaj('ul numer szesnaście').isUnderstood, isFalse);
      expect(silnik.rozpoznaj('korpus numer dwa').isUnderstood, isFalse);
      expect(silnik.rozpoznaj('otwórz ul numer szesnaście').isUnderstood, isTrue);
      // setFrame ma $state OPCJONALNY - tu goła forma działa i tak ma zostać.
      expect(silnik.rozpoznaj('ramka numer dziesięć').isUnderstood, isTrue);
    });
  });

  group('gramatyka dla recognizera Vosk', () {
    test('frazy zawierają odmienione formy, których gubi lista słów', () {
      final frazy = silnik.frazy();
      // Test z 30.07.2026: płaska lista słów dawała "z prawej stronę"
      // i "po przegląd"; gramatyka frazowa trzyma poprawną fleksję.
      expect(frazy, contains('z prawej strony'));
      expect(frazy, contains('po przeglądzie'));
      expect(frazy, contains('na grób'));
      expect(frazy.length, greaterThan(2000));
      expect(frazy.length, lessThan(6000)); // bez wysypu kombinacji
    });

    test('żadna fraza nie jest pusta ani nie ma podwójnych spacji', () {
      for (final f in silnik.frazy()) {
        expect(f.trim(), isNotEmpty);
        expect(f.contains('  '), isFalse, reason: f);
        expect(f.contains(r'$'), isFalse, reason: 'nierozwinięty slot: $f');
        expect(f.contains('('), isFalse, reason: 'nierozwinięta grupa: $f');
      }
    });
  });

  group('odporność', () {
    test('wielkie litery i nadmiarowe spacje nie przeszkadzają', () {
      final w = silnik.rozpoznaj('  Pokarm   DWADZIEŚCIA  procent z LEWEJ ');
      expect(w.intent, 'setStore');
      expect(w.slots!['food'], '20%');
    });

    test('pusty tekst nie wybucha', () {
      expect(silnik.rozpoznaj('').isUnderstood, isFalse);
      expect(silnik.rozpoznaj('   ').isUnderstood, isFalse);
    });

    test('ogon poza komendą jest odrzucany (brak fałszywych trafień)', () {
      expect(
          silnik.rozpoznaj('pokarm dwadzieścia procent z lewej i jeszcze coś')
              .isUnderstood,
          isFalse);
    });
  });
}
