// Silnik-parser gramatyki .yml dla sterowania głosowego na Vosku.
//
// PO CO TO JEST
// Picovoice Rhino dostarczał gotowy obiekt RhinoInference {isUnderstood, intent,
// slots}. Vosk zwraca goły tekst. Ten plik zamienia tekst z Vosk na dokładnie ten
// sam kształt danych, czytając gramatykę z pliku .yml (tego samego, który
// opisywał kontekst Rhino). Dzięki temu switch ~3600 linii w voice_screen2.dart
// wraz z całą logiką zapisów i rysowania ula ZOSTAJE BEZ ZMIAN - migracja
// wymienia tylko warstwę wejścia.
//
// KONTRAKT (odtworzony z voice_screen2.dart, nie z dokumentacji Picovoice):
//   $pv.Percent            -> "NN%"  ZE ZNAKIEM procenta. Dowód: linie ~4281-4306
//                             robią int.parse(drone.replaceAll(RegExp('%'), '')).
//   $pv.TwoDigitInteger    -> "NN"   (linia ~1092: int.parse('${slots[key]}'))
//   $pv.SingleDigitInteger -> "N"
//   $slot:klucz            -> KANONICZNA wartość z .yml. Np. $hundred zwraca
//                             słowo "sto", a kod sam mapuje je na 100 (~linia 1588).
//
// KOLEJNOŚĆ SLOTÓW JEST ISTOTNA. voice_screen2 iteruje `for (String key in
// slots.keys)`, a linia ~1547 dodaje setki ($hundred:nrXXOfHiveH) do już
// policzonych dziesiątek ($pv.TwoDigitInteger:nrXXOfHive) - czyli setki muszą
// przyjść PIERWSZE. Dlatego sloty wstawiamy w kolejności WYPOWIEDZI, a Map w
// Darcie (LinkedHashMap) zachowuje kolejność wstawiania.
//
// PRZYIMKI, KTÓRE VOSK GUBI - patrz stałą [pomijalneSlowa] niżej.
//
// UWAGA PRZY ZMIANACH: bliźniacza implementacja referencyjna w Pythonie stoi w
// pliki/vosk_parser_ref.py i jest przetestowana na pliki/lista_komend.txt
// (w kontenerze nie ma Dart SDK, więc logikę walidowano tam). Zmieniasz tu ->
// zmień tam, i odwrotnie. Testy jednostkowe: test/vosk_grammar_test.dart.

import 'package:flutter/services.dart' show rootBundle;

/// Wynik rozpoznania - ten sam kształt co RhinoInference z picovoice_flutter,
/// żeby dał się podstawić bez zmian w switchu voice_screen2.dart.
class VoskInference {
  VoskInference({required this.isUnderstood, this.intent, this.slots});

  /// NIGDY nie jest null - typ zostawiony nullowalny wyłącznie dla zgodności
  /// z RhinoInference, żeby `if (inference.isUnderstood!)` w voice_screen2.dart
  /// (linia ~546) skompilowało się bez zmiany choćby jednego znaku.
  final bool? isUnderstood;
  final String? intent;

  /// Kolejność kluczy = kolejność wypowiedzi (patrz nagłówek pliku).
  final Map<String, String>? slots;

  /// Wyrażenie .yml, które dopasowało - tylko do diagnostyki/logów.
  String? zrodloWyrazenie;

  static VoskInference nieRozumiem() => VoskInference(isUnderstood: false);

  @override
  String toString() =>
      isUnderstood == true ? '$intent $slots' : 'isUnderstood=false';
}

/// Jedno dopasowanie wyrażenia - publiczne, bo zwraca je [VoskGrammar.wszystkieTrafienia].
class VoskTrafienie {
  VoskTrafienie(this.intent, this.sloty, this.kara, this.wyrazenie);

  final String intent;
  final Map<String, String> sloty;

  /// Ile słów wzorca pominięto (przyimki) - mniej znaczy lepiej.
  final int kara;

  /// Wyrażenie z .yml, które dopasowało.
  final String wyrazenie;

  @override
  String toString() => '$intent $sloty (kara=$kara)';
}

/// Słowa wzorca, które wolno pominąć, jeśli nie ma ich w tekście z Vosk.
///
/// "z" jest ZMIERZONE: w nagraniu pliki/vosk_0801-124040_...wav Vosk ani razu
/// (14/14 wypowiedzi) nie zwrócił "z" - wychodziło "pięćdziesiąt procent lewej"
/// zamiast "z lewej", choć "z" jest i w słowniku modelu, i w gramatyce. Powód:
/// jedna niezgłoskotwórcza spółgłoska wtapia się w następne słowo.
/// "w" dodane z tej samej fonetyki (w wygłosie ubezdźwięcznia się do [f]).
///
/// Klucz: pomijamy słowo WZORCA, ale zwracamy kanoniczną wartość slotu z .yml.
/// Dzięki temu tekst "przesuń prawo" daje isDone = "przesuń w prawo", czyli
/// dokładnie ten string, którego szuka voice_screen2.dart (case 'przesuń w
/// prawo', ~linia 10300) - inaczej komenda przestałaby działać.
const Set<String> pomijalneSlowa = {'z', 'w'};

// ---------------------------------------------------------------------------
// Elementy wyrażenia
// ---------------------------------------------------------------------------

abstract class _Element {}

class _Slowo extends _Element {
  _Slowo(this.w);
  final String w;
}

class _SlotRef extends _Element {
  _SlotRef(this.nazwa, this.klucz);
  final String nazwa;
  final String klucz;
}

class _Wbudowany extends _Element {
  _Wbudowany(this.typ, this.klucz);
  final String typ;
  final String klucz;
}

class _Alternatywa extends _Element {
  _Alternatywa(this.warianty, this.opcjonalna);
  final List<List<_Element>> warianty;
  final bool opcjonalna;
}

class _Wyrazenie {
  _Wyrazenie(this.intent, this.tekst, this.sekwencja);
  final String intent;
  final String tekst;
  final List<_Element> sekwencja;
}

class _Stan {
  _Stan(this.poz, this.sloty, this.kara);
  final int poz;
  final Map<String, String> sloty;

  /// Ile słów wzorca pominięto (przyimki). Przy remisie wygrywa mniejsza kara.
  final int kara;
}

/// Wyjątek przy niepoprawnej gramatyce - lepiej wywalić się na starcie niż
/// milczeć i nie rozpoznawać komend.
class BladGramatyki implements Exception {
  BladGramatyki(this.opis);
  final String opis;

  @override
  String toString() => 'BladGramatyki: $opis';
}

// ---------------------------------------------------------------------------
// Liczebniki - typy wbudowane, których Vosk (w przeciwieństwie do Rhino) nie ma
// ---------------------------------------------------------------------------

const Map<String, int> _jednostki = {
  'zero': 0, 'jeden': 1, 'jedna': 1, 'jedną': 1, 'jednego': 1,
  'dwa': 2, 'dwie': 2, 'dwóch': 2, 'trzy': 3, 'cztery': 4, 'pięć': 5,
  'sześć': 6, 'siedem': 7, 'osiem': 8, 'dziewięć': 9,
};

const Map<String, int> _nastki = {
  'dziesięć': 10, 'jedenaście': 11, 'dwanaście': 12, 'trzynaście': 13,
  'czternaście': 14, 'piętnaście': 15, 'szesnaście': 16, 'siedemnaście': 17,
  'osiemnaście': 18, 'dziewiętnaście': 19,
};

const Map<String, int> _dziesiatki = {
  'dwadzieścia': 20, 'trzydzieści': 30, 'czterdzieści': 40,
  'pięćdziesiąt': 50, 'sześćdziesiąt': 60, 'siedemdziesiąt': 70,
  'osiemdziesiąt': 80, 'dziewięćdziesiąt': 90,
};

const Map<String, int> _setki = {
  'sto': 100, 'dwieście': 200, 'trzysta': 300, 'czterysta': 400,
  'pięćset': 500, 'sześćset': 600, 'siedemset': 700, 'osiemset': 800,
  'dziewięćset': 900,
};

const Map<String, int> _ordinaly = {
  'pierwszy': 1, 'drugi': 2, 'trzeci': 3, 'czwarty': 4, 'piąty': 5,
  'szósty': 6, 'siódmy': 7, 'ósmy': 8, 'dziewiąty': 9,
};

const Set<String> _procent = {'procent', 'procenta', 'procentów'};

const Map<String, List<int>> _zakresy = {
  'SingleDigitInteger': [0, 9],
  'TwoDigitInteger': [0, 99],
  'Percent': [0, 100],
  'SingleDigitOrdinal': [1, 9],
};

/// Wszystkie sensowne odczyty liczebnika od pozycji [poz], od NAJDŁUŻSZEGO.
///
/// Nie „najdłuższy wygrywa" na siłę, bo krótszy odczyt bywa poprawny: w
/// wyrażeniu ($hundred:nrXXOfHiveH) ($pv.TwoDigitInteger:nrXXOfHive) dla
/// „sto dwadzieścia" slot setek zabiera „sto", a dwucyfrowy „dwadzieścia".
/// Gdy matcher pominie opcjonalny slot setek, dwucyfrowy odczyta 120, odrzuci
/// to przez zakres i nawrotem wróci do wariantu ze setkami.
List<List<int>> _kandydaciLiczby(List<String> tokeny, int poz) {
  final wyniki = <List<int>>[];
  var i = poz;
  var wartosc = 0;
  if (i < tokeny.length && _setki.containsKey(tokeny[i])) {
    wartosc += _setki[tokeny[i]]!;
    i++;
    wyniki.add([wartosc, i - poz]);
  }
  if (i < tokeny.length && _nastki.containsKey(tokeny[i])) {
    wartosc += _nastki[tokeny[i]]!;
    i++;
    wyniki.add([wartosc, i - poz]);
  } else {
    if (i < tokeny.length && _dziesiatki.containsKey(tokeny[i])) {
      wartosc += _dziesiatki[tokeny[i]]!;
      i++;
      wyniki.add([wartosc, i - poz]);
    }
    if (i < tokeny.length && _jednostki.containsKey(tokeny[i])) {
      wartosc += _jednostki[tokeny[i]]!;
      i++;
      wyniki.add([wartosc, i - poz]);
    }
  }
  return wyniki.reversed.toList();
}

// ---------------------------------------------------------------------------
// Silnik
// ---------------------------------------------------------------------------

class VoskGrammar {
  VoskGrammar._(this._wyrazenia, this._slotyDef);

  final List<_Wyrazenie> _wyrazenia;
  final Map<String, List<String>> _slotyDef;

  /// Buduje silnik z treści pliku .yml. Czysty Dart - nadaje się do testów
  /// jednostkowych bez uruchamiania aplikacji.
  factory VoskGrammar.zTekstu(String yml) {
    final czytnik = _CzytnikYml(yml);
    czytnik.wczytaj();
    if (czytnik.wyrazenia.isEmpty) {
      throw BladGramatyki('brak sekcji expressions albo jest pusta');
    }
    final slotyDef = <String, List<String>>{};
    czytnik.sloty.forEach((k, v) => slotyDef[k] = v);

    final wyrazenia = <_Wyrazenie>[];
    czytnik.wyrazenia.forEach((intent, teksty) {
      for (final tekst in teksty) {
        wyrazenia.add(_Wyrazenie(intent, tekst, _ParserWyrazenia(tekst).parsuj()));
      }
    });
    final silnik = VoskGrammar._(wyrazenia, slotyDef);
    silnik._sprawdzReferencje();
    return silnik;
  }

  /// Wygodne ładowanie z assetu (pubspec: assets/grammar/pol_vosk.yml).
  static Future<VoskGrammar> zAssetu(String sciezka) async =>
      VoskGrammar.zTekstu(await rootBundle.loadString(sciezka));

  /// Slot użyty w wyrażeniu, którego nie ma w sekcji slots, to cicha awaria:
  /// komenda po prostu nigdy nie zadziała. Lepiej wywalić się od razu.
  void _sprawdzReferencje() {
    final braki = <String>{};
    void obejdz(List<_Element> seq) {
      for (final e in seq) {
        if (e is _SlotRef && !_slotyDef.containsKey(e.nazwa)) {
          braki.add('\$${e.nazwa}');
        } else if (e is _Wbudowany && !_zakresy.containsKey(e.typ)) {
          braki.add('\$pv.${e.typ}');
        } else if (e is _Alternatywa) {
          for (final w in e.warianty) {
            obejdz(w);
          }
        }
      }
    }

    for (final w in _wyrazenia) {
      obejdz(w.sekwencja);
    }
    if (braki.isNotEmpty) {
      throw BladGramatyki(
          'gramatyka odwołuje się do nieznanych slotów/typów: ${(braki.toList()..sort()).join(', ')}');
    }
  }

  int get liczbaWyrazen => _wyrazenia.length;

  Set<String> get intencje => _wyrazenia.map((w) => w.intent).toSet();

  // -- rozpoznawanie ----------------------------------------------------

  /// Tekst z Vosk -> VoskInference. Wymaga zużycia CAŁEJ wypowiedzi; obcięcie
  /// wake-worda i sklejanie fraz po oknie zwłoki należy do wołającego.
  VoskInference rozpoznaj(String tekst) {
    final trafienia = wszystkieTrafienia(tekst);
    if (trafienia.isEmpty) return VoskInference.nieRozumiem();
    final t = trafienia.first;
    return VoskInference(isUnderstood: true, intent: t.intent, slots: t.sloty)
      ..zrodloWyrazenie = t.wyrazenie;
  }

  /// Wszystkie dopasowania, najlepsze pierwsze. Do diagnostyki i testów
  /// niejednoznaczności.
  List<VoskTrafienie> wszystkieTrafienia(String tekst) {
    final tokeny = tokenizuj(tekst);
    if (tokeny.isEmpty) return const [];
    final trafienia = <VoskTrafienie>[];
    for (final w in _wyrazenia) {
      final stany = _dopasujSekwencje(
          w.sekwencja, tokeny, [_Stan(0, <String, String>{}, 0)]);
      for (final s in stany) {
        if (s.poz == tokeny.length) {
          trafienia.add(VoskTrafienie(w.intent, s.sloty, s.kara, w.tekst));
        }
      }
    }
    // Więcej slotów = konkretniejsze dopasowanie; przy remisie mniej
    // pominiętych słów wzorca; dalej stabilnie kolejność z .yml.
    trafienia.sort((a, b) {
      final r = b.sloty.length.compareTo(a.sloty.length);
      return r != 0 ? r : a.kara.compareTo(b.kara);
    });
    return trafienia;
  }

  static List<String> tokenizuj(String tekst) => tekst
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  List<_Stan> _dopasujSekwencje(
      List<_Element> seq, List<String> tokeny, List<_Stan> stany) {
    for (final element in seq) {
      final nowe = <_Stan>[];
      for (final stan in stany) {
        nowe.addAll(_dopasujElement(element, tokeny, stan));
      }
      if (nowe.isEmpty) return const [];
      stany = _odchudz(nowe);
    }
    return stany;
  }

  /// Zostaw po jednym najtańszym stanie na (pozycja, sloty) - bez tego liczba
  /// stanów rośnie wykładniczo przy zagnieżdżonych opcjonalnościach.
  List<_Stan> _odchudz(List<_Stan> stany) {
    final najlepsze = <String, _Stan>{};
    for (final s in stany) {
      final klucz = '${s.poz}|${s.sloty.entries.map((e) => '${e.key}=${e.value}').join(';')}';
      final byl = najlepsze[klucz];
      if (byl == null || s.kara < byl.kara) najlepsze[klucz] = s;
    }
    return najlepsze.values.toList();
  }

  List<_Stan> _dopasujElement(
      _Element element, List<String> tokeny, _Stan stan) {
    if (element is _Slowo) {
      if (stan.poz < tokeny.length && tokeny[stan.poz] == element.w) {
        return [_Stan(stan.poz + 1, stan.sloty, stan.kara)];
      }
      if (pomijalneSlowa.contains(element.w)) {
        // przyimek, którego Vosk nie zwrócił
        return [_Stan(stan.poz, stan.sloty, stan.kara + 1)];
      }
      return const [];
    }
    if (element is _Wbudowany) {
      return _dopasujWbudowany(element, tokeny, stan);
    }
    if (element is _SlotRef) {
      final out = <_Stan>[];
      for (final wartosc in _slotyDef[element.nazwa] ?? const <String>[]) {
        final slowa = wartosc.toLowerCase().split(RegExp(r'\s+'));
        for (final para in _dopasujSlowa(slowa, tokeny, stan.poz)) {
          // ZAWSZE kanoniczna wartość z .yml, nie to, co usłyszał Vosk
          out.add(_Stan(para[0], _zSlotem(stan.sloty, element.klucz, wartosc),
              stan.kara + para[1]));
        }
      }
      return out;
    }
    if (element is _Alternatywa) {
      final out = <_Stan>[];
      for (final wariant in element.warianty) {
        out.addAll(_dopasujSekwencje(wariant, tokeny, [stan]));
      }
      if (element.opcjonalna) out.add(stan);
      return out;
    }
    throw BladGramatyki('nieznany element wyrażenia');
  }

  List<_Stan> _dopasujWbudowany(
      _Wbudowany element, List<String> tokeny, _Stan stan) {
    final poz = stan.poz;
    if (element.typ == 'SingleDigitOrdinal') {
      if (poz < tokeny.length && _ordinaly.containsKey(tokeny[poz])) {
        return [
          _Stan(poz + 1,
              _zSlotem(stan.sloty, element.klucz, '${_ordinaly[tokeny[poz]]}'),
              stan.kara)
        ];
      }
      return const [];
    }
    final zakres = _zakresy[element.typ]!;
    final out = <_Stan>[];
    for (final kandydat in _kandydaciLiczby(tokeny, poz)) {
      final wartosc = kandydat[0];
      final koniec = poz + kandydat[1];
      if (wartosc < zakres[0] || wartosc > zakres[1]) continue;
      if (element.typ == 'Percent') {
        // W Rhino słowo "procent" należy do typu wbudowanego, nie do
        // wyrażenia - w .yml po $pv.Percent nie ma literalnego "procent".
        if (koniec < tokeny.length && _procent.contains(tokeny[koniec])) {
          out.add(_Stan(koniec + 1,
              _zSlotem(stan.sloty, element.klucz, '$wartosc%'), stan.kara));
        } else {
          // "procent" bywa gubione dokładnie tak jak przyimki z [pomijalneSlowa]:
          // jest nieakcentowane, stoi między liczebnikiem a "z prawej", a jego
          // nagłosowe [p] wtapia się w wygłos liczebnika ("dziesięć procent").
          // Brak tego słowa NIE MOŻE wywalać komendy - liczba i tak jest
          // jednoznaczna, bo w tej pozycji żadne wyrażenie nie oczekuje niczego
          // innego. Kara sprawia, że wypowiedź z "procent" nadal wygrywa.
          out.add(_Stan(koniec, _zSlotem(stan.sloty, element.klucz, '$wartosc%'),
              stan.kara + 1));
        }
      } else {
        out.add(_Stan(
            koniec, _zSlotem(stan.sloty, element.klucz, '$wartosc'), stan.kara));
      }
    }
    return out;
  }

  /// Ciąg słów wzorca wobec tokenów. Zwraca listę [nowaPozycja, dodatkowaKara];
  /// toleruje brak przyimka z [pomijalneSlowa].
  List<List<int>> _dopasujSlowa(
      List<String> slowa, List<String> tokeny, int poz) {
    var stany = <List<int>>[
      [poz, 0]
    ];
    for (final w in slowa) {
      final nowe = <List<int>>[];
      for (final s in stany) {
        if (s[0] < tokeny.length && tokeny[s[0]] == w) {
          nowe.add([s[0] + 1, s[1]]);
        } else if (pomijalneSlowa.contains(w)) {
          nowe.add([s[0], s[1] + 1]);
        }
      }
      if (nowe.isEmpty) return const [];
      stany = nowe;
    }
    return stany;
  }

  static Map<String, String> _zSlotem(
      Map<String, String> sloty, String klucz, String wartosc) {
    // Map w Darcie zachowuje kolejność wstawiania = kolejność wypowiedzi.
    return Map<String, String>.from(sloty)..[klucz] = wartosc;
  }

  // -- generowanie gramatyki dla recognizera Vosk -----------------------

  /// Wszystkie słowa literalne gramatyki (do kontroli OOV wobec słownika modelu).
  Set<String> slowa() {
    final out = <String>{};
    void obejdz(List<_Element> seq) {
      for (final e in seq) {
        if (e is _Slowo) {
          out.add(e.w);
        } else if (e is _Alternatywa) {
          for (final w in e.warianty) {
            obejdz(w);
          }
        }
      }
    }

    for (final w in _wyrazenia) {
      obejdz(w.sekwencja);
    }
    for (final wartosci in _slotyDef.values) {
      for (final v in wartosci) {
        out.addAll(v.toLowerCase().split(RegExp(r'\s+')));
      }
    }
    return out;
  }

  Set<String> liczebniki() => {
        ..._jednostki.keys,
        ..._nastki.keys,
        ..._dziesiatki.keys,
        ..._setki.keys,
        ..._ordinaly.keys,
        ..._procent,
      };

  /// Pierwsze słowa wyrażeń - do bramki „komenda musi się tak zaczynać".
  Set<String> slowaOtwierajace() {
    final out = <String>{};
    // Zbiór FIRST: idziemy po elementach dopóki są opcjonalne.
    bool zbierz(List<_Element> seq) {
      for (final e in seq) {
        var moznaDalej = false;
        if (e is _Slowo) {
          out.add(e.w);
        } else if (e is _SlotRef) {
          for (final v in _slotyDef[e.nazwa] ?? const <String>[]) {
            final t = v.toLowerCase().split(RegExp(r'\s+'));
            if (t.isNotEmpty) out.add(t.first);
          }
        } else if (e is _Wbudowany) {
          out.addAll(liczebniki());
        } else if (e is _Alternatywa) {
          for (final w in e.warianty) {
            if (zbierz(w)) moznaDalej = true;
          }
          if (e.opcjonalna) moznaDalej = true;
        }
        if (!moznaDalej) return false;   // element wymagany domyka zbiór FIRST
      }
      return true;
    }

    for (final w in _wyrazenia) {
      zbierz(w.sekwencja);
    }
    // przyimek nie otwiera komendy
    out.removeWhere((w) => pomijalneSlowa.contains(w));
    return out;
  }

  /// Gramatyka FRAZOWA dla KaldiRecognizer(model, rate, grammar).
  ///
  /// Test z 30.07.2026 na nagraniach: lista FRAZ bije płaską listę słów, bo
  /// Vosk buduje z gramatyki bigramowy model języka - płaska lista gubiła
  /// fleksję („z prawej stronę" zamiast „strony", „po przegląd" zamiast
  /// „po przeglądzie").
  ///
  /// Wyrażenia rozwijamy na warianty, ale ROZCINAMY na typach wbudowanych -
  /// inaczej same liczebniki dają wysyp kombinacji (101 procentów x 9 stron
  /// x ... = dziesiątki tysięcy fraz na jedno wyrażenie). Liczebniki idą
  /// osobno jako pojedyncze pozycje; bigram i tak działa lokalnie.
  /// [intencje] zawęża wynik do wybranych intencji - tak powstaje gramatyka
  /// CZUWANIA (same frazy sesji: „hej maja start/stop"). Im mniejsza gramatyka,
  /// tym trudniej przypadkowej rozmowie otworzyć nasłuch komend.
  List<String> frazy({Set<String>? intencje}) {
    final wynik = <String>{};
    var uzytoLiczebnikow = false;
    for (final w in _wyrazenia) {
      if (intencje != null && !intencje.contains(w.intent)) continue;
      if (_maWbudowany(w.sekwencja)) uzytoLiczebnikow = true;
      for (final kawalek in _rozetnij(w.sekwencja)) {
        for (final warianty in _rozwin(kawalek)) {
          if (warianty.isNotEmpty) wynik.add(warianty.join(' '));
        }
      }
    }
    if (intencje == null) {
      // Wartości slotów i tak wchodzą przez rozwinięcie wyrażeń; przy pełnej
      // gramatyce dokładamy je osobno, bo rozcięcie na typach wbudowanych
      // potrafi rozdzielić slot od reszty frazy.
      for (final wartosci in _slotyDef.values) {
        for (final v in wartosci) {
          wynik.add(v.toLowerCase());
        }
      }
    }
    if (intencje == null || uzytoLiczebnikow) {
      wynik.addAll(liczebniki());
      // Druga połowa mostka dla "procent": bigram liczebnik -> procent.
      // Liczebniki są w gramatyce pojedynczymi frazami, więc przejście
      // "dziesięć" -> "procent" biegło przez granicę fraz, czyli po najdroższej
      // ścieżce. Tanie: ~50 pozycji na 3000.
      for (final liczba in {..._jednostki.keys, ..._nastki.keys,
        ..._dziesiatki.keys, ..._setki.keys}) {
        wynik.add('$liczba procent');
      }
    }
    wynik.remove('');
    return wynik.toList()..sort();
  }

  bool _maWbudowany(List<_Element> seq) {
    for (final e in seq) {
      if (e is _Wbudowany) return true;
      if (e is _Alternatywa) {
        for (final w in e.warianty) {
          if (_maWbudowany(w)) return true;
        }
      }
    }
    return false;
  }

  List<List<_Element>> _rozetnij(List<_Element> seq) {
    final kawalki = <List<_Element>>[];
    var biezacy = <_Element>[];
    for (final e in seq) {
      if (e is _Wbudowany) {
        if (biezacy.isNotEmpty) kawalki.add(biezacy);
        // Po $pv.Percent zaczynamy nowy kawałek OD SŁOWA "procent". Bez tego
        // "procent" trafiał do gramatyki wyłącznie jako samotna, jednowyrazowa
        // fraza - model języka nie miał żadnego bigramu wiążącego go z dalszym
        // ciągiem komendy, więc pominięcie go kosztowało prawie nic. Zmierzone
        // na pliki/vosk_0801-124040_...wav: pewność słowa "procent" rośnie
        // z 0,91 do 1,00, tekst bez zmian.
        biezacy = e.typ == 'Percent'
            ? <_Element>[_Slowo('procent')]
            : <_Element>[];
      } else {
        biezacy.add(e);
      }
    }
    if (biezacy.isNotEmpty) kawalki.add(biezacy);
    return kawalki;
  }

  List<List<String>> _rozwin(List<_Element> seq) {
    var wyniki = <List<String>>[<String>[]];
    for (final e in seq) {
      final nowe = <List<String>>[];
      if (e is _Slowo) {
        for (final r in wyniki) {
          nowe.add([...r, e.w]);
        }
      } else if (e is _SlotRef) {
        for (final r in wyniki) {
          for (final v in _slotyDef[e.nazwa] ?? const <String>[]) {
            nowe.add([...r, ...v.toLowerCase().split(RegExp(r'\s+'))]);
          }
        }
      } else if (e is _Alternatywa) {
        for (final r in wyniki) {
          for (final w in e.warianty) {
            for (final rozw in _rozwin(w)) {
              nowe.add([...r, ...rozw]);
            }
          }
          if (e.opcjonalna) nowe.add(r);
        }
      } else {
        nowe.addAll(wyniki);
      }
      wyniki = nowe;
      if (wyniki.length > 20000) {
        throw BladGramatyki('rozwinięcie wyrażenia wybuchło: ${wyniki.length}');
      }
    }
    return wyniki;
  }
}

// ---------------------------------------------------------------------------
// Czytnik .yml
// ---------------------------------------------------------------------------
// Świadomie własny, a nie pakiet yaml: to jedyne miejsce, gdzie potrzebujemy
// YAML-a, plik jest pod naszą kontrolą, a nowa zależność w pubspec to koszt
// przy każdym pod install. Zgodność z prawdziwym YAML-em jest sprawdzana w
// pliki/vosk_parser_ref.py --yamlcheck (tam pyyaml jest dostępny).

class _CzytnikYml {
  _CzytnikYml(this.zrodlo);

  final String zrodlo;
  final Map<String, List<String>> wyrazenia = {};
  final Map<String, List<String>> sloty = {};

  void wczytaj() {
    Map<String, List<String>>? cel;
    String? nazwa;
    String? biezaca;

    void domknij() {
      if (biezaca != null) {
        if (cel != null && nazwa != null) {
          (cel[nazwa] ??= <String>[]).add(_odcytuj(biezaca!.trim()));
        }
        biezaca = null;
      }
    }

    for (final surowa in zrodlo.split('\n')) {
      final linia = surowa.replaceAll('\r', '');
      final s = linia.trim();
      if (s.isEmpty || s.startsWith('#')) continue;
      final wciecie = linia.length - linia.trimLeft().length;
      if (s == 'context:') continue;
      if (s == 'expressions:') {
        domknij();
        cel = wyrazenia;
        nazwa = null;
        continue;
      }
      if (s == 'slots:') {
        domknij();
        cel = sloty;
        nazwa = null;
        continue;
      }
      if (s.startsWith('macros:')) {
        domknij();
        cel = null;
        nazwa = null;
        continue;
      }
      if (s.startsWith('- ')) {
        domknij();
        biezaca = s.substring(2);
        continue;
      }
      if (s.endsWith(':') && wciecie <= 4) {
        domknij();
        nazwa = s.substring(0, s.length - 1);
        continue;
      }
      if (biezaca != null) {
        biezaca = '${biezaca!} $s';   // kontynuacja zawiniętej pozycji YAML
      }
    }
    domknij();
  }

  static String _odcytuj(String t) {
    if (t.length >= 2 &&
        t[0] == t[t.length - 1] &&
        (t[0] == '"' || t[0] == "'")) {
      return t.substring(1, t.length - 1);
    }
    return t;
  }
}

// ---------------------------------------------------------------------------
// Parser mini-języka wyrażeń
// ---------------------------------------------------------------------------
// słowo          - wymagane
// (a) (a,b)      - opcjonalne / opcjonalna alternatywa
// [a,b]          - alternatywa WYMAGANA
// $slot:klucz    - slot słownikowy
// $pv.Typ:klucz  - typ wbudowany (liczebniki)
// zagnieżdżenia dozwolone, np. ([jest,na]) albo ($siteOfFrame:siteOfFrame)

class _ParserWyrazenia {
  _ParserWyrazenia(this.tekst);

  final String tekst;
  int poz = 0;

  static final RegExp _ref = RegExp(r'\$([A-Za-z0-9_.]+):([A-Za-z0-9_]+)');
  static final RegExp _slowo = RegExp(r'[^\s()\[\],]+');

  List<_Element> parsuj() {
    final seq = _czytajSekwencje(null);
    if (poz != tekst.length) {
      throw BladGramatyki(
          'niesparsowana końcówka "${tekst.substring(poz)}" w "$tekst"');
    }
    return seq;
  }

  List<_Element> _czytajSekwencje(String? doZnaku) {
    final elementy = <_Element>[];
    while (poz < tekst.length) {
      final c = tekst[poz];
      if (doZnaku != null && doZnaku.contains(c)) break;
      if (c.trim().isEmpty) {
        poz++;
        continue;
      }
      if (c == '(') {
        poz++;
        elementy.add(_czytajGrupe(')', true));
        continue;
      }
      if (c == '[') {
        poz++;
        elementy.add(_czytajGrupe(']', false));
        continue;
      }
      if (c == ')' || c == ']' || c == ',') break;
      elementy.add(_czytajAtom());
    }
    return elementy;
  }

  _Alternatywa _czytajGrupe(String zamkniecie, bool opcjonalna) {
    final warianty = <List<_Element>>[];
    while (true) {
      warianty.add(_czytajSekwencje('$zamkniecie,'));
      if (poz >= tekst.length) {
        throw BladGramatyki('brak "$zamkniecie" w "$tekst"');
      }
      if (tekst[poz] == ',') {
        poz++;
        continue;
      }
      if (tekst[poz] == zamkniecie) {
        poz++;
        break;
      }
      throw BladGramatyki('nieoczekiwany znak "${tekst[poz]}" w "$tekst"');
    }
    final niepuste = warianty.where((w) => w.isNotEmpty).toList();
    return _Alternatywa(
        niepuste.isEmpty ? [<_Element>[]] : niepuste, opcjonalna);
  }

  _Element _czytajAtom() {
    final m = _ref.matchAsPrefix(tekst, poz);
    if (m != null) {
      poz = m.end;
      final nazwa = m.group(1)!;
      final klucz = m.group(2)!;
      if (nazwa.startsWith('pv.')) {
        return _Wbudowany(nazwa.substring(3), klucz);
      }
      return _SlotRef(nazwa, klucz);
    }
    final w = _slowo.matchAsPrefix(tekst, poz);
    if (w == null) {
      throw BladGramatyki('nie umiem sparsować "$tekst" od pozycji $poz');
    }
    poz = w.end;
    return _Slowo(w.group(0)!.toLowerCase());
  }
}
