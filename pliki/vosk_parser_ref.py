#!/usr/bin/env python3
# REFERENCYJNA implementacja silnika-parsera gramatyki .yml (Python).
#
# Po co osobna implementacja w Pythonie, skoro docelowy kod jest w Darcie?
# W kontenerze NIE MA Dart/Flutter SDK - nie da się uruchomić ani przetestować
# kodu Darta. Ta wersja jest 1:1 tym samym algorytmem, więc pozwala:
#   * przetestować logikę na 121 komendach z pliki/lista_komend.txt,
#   * znaleźć dziury w gramatyce PRZED napisaniem Darta,
#   * służyć jako wzorzec przy zmianach (zmieniasz tu -> zmieniasz w Darcie).
# Odpowiednik w Darcie: lib/helpers/vosk_grammar.dart
# Testy Darta (do uruchomienia lokalnie): test/vosk_grammar_test.dart
#
# Kontrakt wyjścia = RhinoInference, żeby switch 3600 linii w voice_screen2.dart
# został BEZ ZMIAN:
#   {isUnderstood: bool, intent: str, slots: dict}   <- dict ZACHOWUJE KOLEJNOŚĆ
# Kolejność slotów jest ISTOTNA: voice_screen2 iteruje `for (String key in
# slots.keys)` i np. setki ($hundred:nrXXOfHiveH) muszą trafić do kodu PRZED
# dziesiątkami ($pv.TwoDigitInteger:nrXXOfHive), bo linia ~1547 dodaje setki do
# już policzonych dziesiątek. Dlatego sloty wstawiamy w kolejności WYPOWIEDZI.
#
# Format wartości slotów (odtworzony z voice_screen2.dart, nie z dokumentacji):
#   $pv.Percent            -> "NN%"  ze znakiem procenta (linie ~4281-4306:
#                             int.parse(drone.replaceAll(RegExp('%'), '')))
#   $pv.TwoDigitInteger    -> "NN"   (linia ~1092: int.parse('${slots[key]}'))
#   $pv.SingleDigitInteger -> "N"
#   $slot:key              -> KANONICZNA wartość z .yml (np. $hundred zwraca
#                             słowo "sto", a kod sam mapuje je na 100 w ~1588)
#
# Użycie:
#   python3 vosk_parser_ref.py --test              # cały pliki/lista_komend.txt
#   python3 vosk_parser_ref.py "pokarm dwadzieścia procent z lewej"
#   python3 vosk_parser_ref.py --frazy | head      # gramatyka frazowa dla Vosk

import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
# JEDNO źródło prawdy: gramatyka jest assetem aplikacji (pubspec -> assets/),
# a nie kopią w pliki/. Bez tego kopie zaczęłyby się rozjeżdżać.
YML = os.path.join(os.path.dirname(HERE), 'assets', 'grammar', 'pol_vosk.yml')

# Przyimki, które Vosk gubi. "z" ZMIERZONE (14/14 wypowiedzi w nagraniu
# vosk_0801-124040_...wav: "pięćdziesiąt procent lewej" zamiast "z lewej").
# "w" dodane z tej samej fonetyki (jedna spółgłoska, wtapia się w następne
# słowo). Reguła: jeśli wzorzec ma ten przyimek, a wejście nie - POMIŃ go we
# wzorcu, ale ZWRÓĆ kanoniczną wartość slotu z .yml. Dzięki temu tekst
# "przesuń prawo" daje isDone = "przesuń w prawo", czyli dokładnie ten string,
# którego szuka voice_screen2.dart (case 'przesuń w prawo', linia ~10300).
POMIJALNE = {'z', 'w'}   # nadpisywane przez ustaw_jezyk()

# ---------------------------------------------------------------------------
# 1. Wczytanie .yml
# ---------------------------------------------------------------------------
# Świadomie bez pyyaml: w Darcie i tak trzeba tego parsera napisać ręcznie
# (unikamy nowej zależności w pubspec), a wtedy obie implementacje muszą
# czytać plik IDENTYCZNIE. Kształt pliku jest pod naszą kontrolą.
# Zgodność z prawdziwym YAML-em sprawdza --yamlcheck.


def wczytaj_yml(path=YML):
    """Zwraca (expressions, slots) jako dict nazwa -> lista tekstów pozycji."""
    expressions, slots = {}, {}
    sekcja, nazwa, biezaca = None, None, None
    cel = None

    def domknij():
        nonlocal biezaca
        if biezaca is not None:
            if cel is not None and nazwa is not None:
                cel.setdefault(nazwa, []).append(_odcytuj(biezaca.strip()))
            biezaca = None

    for surowa in open(path, encoding='utf-8'):
        linia = surowa.rstrip('\n')
        if not linia.strip() or linia.lstrip().startswith('#'):
            continue
        wciecie = len(linia) - len(linia.lstrip())
        s = linia.strip()
        if s == 'context:':
            continue
        if s == 'expressions:':
            domknij(); sekcja, cel, nazwa = 'expressions', expressions, None; continue
        if s == 'slots:':
            domknij(); sekcja, cel, nazwa = 'slots', slots, None; continue
        if s.startswith('macros:'):
            domknij(); sekcja, cel, nazwa = None, None, None; continue
        if s.startswith('- '):
            domknij(); biezaca = s[2:]; continue
        if s.endswith(':') and wciecie <= 4:
            domknij(); nazwa = s[:-1]; continue
        if biezaca is not None:      # kontynuacja zawiniętej pozycji YAML
            biezaca += ' ' + s
    domknij()
    if not expressions:
        raise SystemExit('Nie znaleziono sekcji expressions w %s' % path)
    return expressions, slots


def _odcytuj(t):
    if len(t) >= 2 and t[0] == t[-1] and t[0] in '"\'':
        return t[1:-1]
    return t


# ---------------------------------------------------------------------------
# 2. Parser mini-języka wyrażeń
# ---------------------------------------------------------------------------
# słowo            - wymagane
# (a) (a,b)        - opcjonalne / opcjonalna alternatywa
# [a,b]            - alternatywa WYMAGANA
# $slot:klucz      - slot słownikowy (wartości z sekcji slots)
# $pv.Typ:klucz    - typ wbudowany (liczebniki)
# zagnieżdżenia OK, np. ([jest,na]) albo ($siteOfFrame:siteOfFrame)

class Slowo:
    __slots__ = ('w',)

    def __init__(self, w):
        self.w = w


class Slot:
    __slots__ = ('nazwa', 'klucz')

    def __init__(self, nazwa, klucz):
        self.nazwa, self.klucz = nazwa, klucz


class Wbudowany:
    __slots__ = ('typ', 'klucz')

    def __init__(self, typ, klucz):
        self.typ, self.klucz = typ, klucz


class Alternatywa:
    __slots__ = ('warianty', 'opcjonalna')

    def __init__(self, warianty, opcjonalna):
        self.warianty, self.opcjonalna = warianty, opcjonalna


TOKEN_REF = re.compile(r'\$([A-Za-z0-9_.]+):([A-Za-z0-9_]+)')


def parsuj_wyrazenie(tekst):
    """Tekst wyrażenia -> lista elementów (sekwencja)."""
    poz = [0]

    def blad(msg):
        raise ValueError('%s w %r (pozycja %d)' % (msg, tekst, poz[0]))

    def czytaj_sekwencje(do_znaku=None):
        elementy = []
        while poz[0] < len(tekst):
            c = tekst[poz[0]]
            if do_znaku is not None and c in do_znaku:
                break
            if c.isspace():
                poz[0] += 1
                continue
            if c == '(':
                poz[0] += 1
                elementy.append(czytaj_grupe(')', True))
                continue
            if c == '[':
                poz[0] += 1
                elementy.append(czytaj_grupe(']', False))
                continue
            if c in ')],':
                break
            elementy.append(czytaj_atom())
        return elementy

    def czytaj_grupe(zamkniecie, opcjonalna):
        warianty = []
        while True:
            warianty.append(czytaj_sekwencje(zamkniecie + ','))
            if poz[0] >= len(tekst):
                blad('brak %r' % zamkniecie)
            if tekst[poz[0]] == ',':
                poz[0] += 1
                continue
            if tekst[poz[0]] == zamkniecie:
                poz[0] += 1
                break
            blad('nieoczekiwany znak %r' % tekst[poz[0]])
        warianty = [w for w in warianty if w] or [[]]
        return Alternatywa(warianty, opcjonalna)

    def czytaj_atom():
        m = TOKEN_REF.match(tekst, poz[0])
        if m:
            poz[0] = m.end()
            nazwa, klucz = m.group(1), m.group(2)
            if nazwa.startswith('pv.'):
                return Wbudowany(nazwa[3:], klucz)
            return Slot(nazwa, klucz)
        m = re.compile(r'[^\s()\[\],]+').match(tekst, poz[0])
        if not m:
            blad('nie umiem sparsować')
        poz[0] = m.end()
        return Slowo(m.group(0).lower())

    seq = czytaj_sekwencje()
    if poz[0] != len(tekst):
        raise ValueError('niesparsowana końcówka %r w %r' % (tekst[poz[0]:], tekst))
    return seq


# ---------------------------------------------------------------------------
# 3. Liczebniki (typy wbudowane Rhino, których Vosk nie ma)
# ---------------------------------------------------------------------------
# JĘZYK. Odpowiednik klasy [_PakietLiczb] z lib/helpers/vosk_grammar.dart -
# obie implementacje MUSZĄ liczyć tak samo (kontrakt z nagłówka tego pliku).
# Angielska setka to DWA słowa ("one hundred"), polska jedno ("sto"), stąd
# SLOWO_SETEK osobno od SETKI. Dopisane 04.09.2026 przy audycie pomocy EN.
_PAKIETY = {
    'pl': dict(
        jednostki={
            'zero': 0, 'jeden': 1, 'jedna': 1, 'jedną': 1, 'jednego': 1,
            'dwa': 2, 'dwie': 2, 'dwóch': 2, 'trzy': 3, 'cztery': 4, 'pięć': 5,
            'sześć': 6, 'siedem': 7, 'osiem': 8, 'dziewięć': 9,
        },
        nastki={
            'dziesięć': 10, 'jedenaście': 11, 'dwanaście': 12, 'trzynaście': 13,
            'czternaście': 14, 'piętnaście': 15, 'szesnaście': 16,
            'siedemnaście': 17, 'osiemnaście': 18, 'dziewiętnaście': 19,
        },
        dziesiatki={
            'dwadzieścia': 20, 'trzydzieści': 30, 'czterdzieści': 40,
            'pięćdziesiąt': 50, 'sześćdziesiąt': 60, 'siedemdziesiąt': 70,
            'osiemdziesiąt': 80, 'dziewięćdziesiąt': 90,
        },
        setki={
            'sto': 100, 'dwieście': 200, 'trzysta': 300, 'czterysta': 400,
            'pięćset': 500, 'sześćset': 600, 'siedemset': 700, 'osiemset': 800,
            'dziewięćset': 900,
        },
        slowo_setek=None,
        procent={'procent', 'procenta', 'procentów'},
        ordinaly={
            'pierwszy': 1, 'drugi': 2, 'trzeci': 3, 'czwarty': 4, 'piąty': 5,
            'szósty': 6, 'siódmy': 7, 'ósmy': 8, 'dziewiąty': 9,
        },
        pomijalne={'z', 'w'},
    ),
    'en': dict(
        jednostki={
            'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
            'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
        },
        nastki={
            'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
            'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
            'eighteen': 18, 'nineteen': 19,
        },
        dziesiatki={
            'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60,
            'seventy': 70, 'eighty': 80, 'ninety': 90,
        },
        setki={},
        slowo_setek='hundred',
        procent={'percent'},
        ordinaly={
            'first': 1, 'second': 2, 'third': 3, 'fourth': 4, 'fifth': 5,
            'sixth': 6, 'seventh': 7, 'eighth': 8, 'ninth': 9,
        },
        # angielski nie gubi przyimków tak jak polskie "z"/"w" - w gramatyce
        # stoją jako (on) (the), czyli opcjonalne już na poziomie wyrażenia
        pomijalne=set(),
    ),
}

JEDNOSTKI = NASTKI = DZIESIATKI = SETKI = ORDINALY = None
SLOWO_SETEK = None
PROCENT = None


def ustaw_jezyk(kod):
    """Przestawia tabele liczebników na dany język ('pl'/'en')."""
    global JEDNOSTKI, NASTKI, DZIESIATKI, SETKI, SLOWO_SETEK, PROCENT
    global ORDINALY, POMIJALNE
    p = _PAKIETY.get(kod)
    if p is None:
        raise SystemExit('nieznany język "%s" (znane: %s)'
                         % (kod, ', '.join(_PAKIETY)))
    JEDNOSTKI, NASTKI = p['jednostki'], p['nastki']
    DZIESIATKI, SETKI = p['dziesiatki'], p['setki']
    SLOWO_SETEK, PROCENT = p['slowo_setek'], p['procent']
    ORDINALY, POMIJALNE = p['ordinaly'], p['pomijalne']


def kandydaci_liczby(tokeny, poz):
    """Wszystkie sensowne odczyty liczebnika od pozycji poz.

    Zwraca listę (wartość, ile_tokenów) od NAJDŁUŻSZEGO. Nie „najdłuższy
    wygrywa" na siłę, bo krótszy odczyt bywa poprawny: w wyrażeniu
    ($hundred:nrXXOfHiveH) ($pv.TwoDigitInteger:nrXXOfHive) dla „sto
    dwadzieścia" slot setek zabiera „sto", a dwucyfrowy „dwadzieścia".
    Gdy matcher pominie opcjonalny slot setek, dwucyfrowy dostanie 120,
    odrzuci to przez zakres i wróci do wariantu ze setkami.
    """
    wyniki = []
    i, wartosc = poz, 0
    if i < len(tokeny) and tokeny[i] in SETKI:
        wartosc += SETKI[tokeny[i]]          # polskie "sto" - jedno słowo
        i += 1
        wyniki.append((wartosc, i - poz))
    elif (SLOWO_SETEK is not None and i + 1 < len(tokeny)
          and tokeny[i] in JEDNOSTKI and tokeny[i + 1] == SLOWO_SETEK):
        wartosc += JEDNOSTKI[tokeny[i]] * 100   # angielskie "one" + "hundred"
        i += 2
        wyniki.append((wartosc, i - poz))
    if i < len(tokeny) and tokeny[i] in NASTKI:
        wartosc += NASTKI[tokeny[i]]
        i += 1
        wyniki.append((wartosc, i - poz))
    else:
        if i < len(tokeny) and tokeny[i] in DZIESIATKI:
            wartosc += DZIESIATKI[tokeny[i]]
            i += 1
            wyniki.append((wartosc, i - poz))
        if i < len(tokeny) and tokeny[i] in JEDNOSTKI:
            wartosc += JEDNOSTKI[tokeny[i]]
            i += 1
            wyniki.append((wartosc, i - poz))
    wyniki.reverse()
    return wyniki


ZAKRESY = {
    'SingleDigitInteger': (0, 9),
    'TwoDigitInteger': (0, 99),
    'Percent': (0, 100),
    'SingleDigitOrdinal': (1, 9),
}
# ORDINALY - patrz _PAKIETY/ustaw_jezyk wyżej


def dopasuj_wbudowany(typ, tokeny, poz):
    """Zwraca listę (sformatowana_wartosc, nowa_pozycja, dodatkowa_kara)."""
    if typ == 'SingleDigitOrdinal':
        if poz < len(tokeny) and tokeny[poz] in ORDINALY:
            # Trzeci element (kara) dopisany 04.09.2026: ta gałąź zwracała
            # krotkę 2-elementową, gdy wołający rozpakowuje 3 - czyli
            # ValueError przy KAŻDYM użyciu $pv.SingleDigitOrdinal. Nie wyszło
            # wcześniej, bo pol_vosk.yml nie używa tego typu ani razu; wyszło
            # dopiero, gdy eng_vosk.yml dostał "chemistry first dose".
            # Dart (vosk_grammar.dart, _dopasujWbudowany) był od początku
            # poprawny - to był błąd wyłącznie tej referencji.
            return [(str(ORDINALY[tokeny[poz]]), poz + 1, 0)]
        return []
    lo, hi = ZAKRESY.get(typ, (0, 999))
    out = []
    for wartosc, zjedzone in kandydaci_liczby(tokeny, poz):
        if not (lo <= wartosc <= hi):
            continue
        koniec = poz + zjedzone
        if typ == 'Percent':
            # W Rhino słowo "procent" należy do typu wbudowanego, nie do
            # wyrażenia - w .yml po $pv.Percent nie ma literalnego "procent".
            if koniec < len(tokeny) and tokeny[koniec] in PROCENT:
                out.append(('%d%%' % wartosc, koniec + 1, 0))
            else:
                # Gubione tak samo jak przyimki z POMIJALNE - nieakcentowane,
                # nagłosowe [p] wtapia się w wygłos liczebnika. Kara 1, więc
                # wypowiedź ZE słowem "procent" nadal wygrywa.
                out.append(('%d%%' % wartosc, koniec, 1))
        else:
            out.append((str(wartosc), koniec, 0))
    return out


# ---------------------------------------------------------------------------
# 4. Dopasowanie (zbiory stanów, z nawrotami)
# ---------------------------------------------------------------------------
# Stan = (pozycja_w_tokenach, sloty, kara). "kara" liczy pominięte słowa
# wzorca - przy remisie wygrywa dopasowanie, które pominęło mniej.
# Świadomie zbiory stanów, a nie generatory: to samo przenosi się 1:1 na
# Darta, który nie ma yield-owych generatorów w tej formie.


def _dodaj_slot(sloty, klucz, wartosc):
    nowe = dict(sloty)          # dict w Pythonie i Map w Darcie: kolejność
    nowe[klucz] = wartosc       # wstawiania = kolejność wypowiedzi
    return nowe


def dopasuj_sekwencje(seq, tokeny, stany, sloty_def):
    for element in seq:
        nowe = []
        for stan in stany:
            nowe.extend(dopasuj_element(element, tokeny, stan, sloty_def))
        if not nowe:
            return []
        stany = _odchudz(nowe)
    return stany


def _odchudz(stany):
    """Zostaw po jednym najlepszym stanie na (pozycja, sloty)."""
    najlepsze = {}
    for poz, sloty, kara in stany:
        klucz = (poz, tuple(sloty.items()))
        if klucz not in najlepsze or kara < najlepsze[klucz][2]:
            najlepsze[klucz] = (poz, sloty, kara)
    return list(najlepsze.values())


def dopasuj_element(element, tokeny, stan, sloty_def):
    poz, sloty, kara = stan
    if isinstance(element, Slowo):
        if poz < len(tokeny) and tokeny[poz] == element.w:
            return [(poz + 1, sloty, kara)]
        if element.w in POMIJALNE:          # przyimek, którego Vosk nie zwrócił
            return [(poz, sloty, kara + 1)]
        return []
    if isinstance(element, Wbudowany):
        return [(nowa, _dodaj_slot(sloty, element.klucz, wartosc), kara + dokara)
                for wartosc, nowa, dokara
                in dopasuj_wbudowany(element.typ, tokeny, poz)]
    if isinstance(element, Slot):
        out = []
        for wartosc in sloty_def.get(element.nazwa, []):
            slowa = wartosc.lower().split()
            for nowa, dokara in _dopasuj_slowa(slowa, tokeny, poz):
                # ZAWSZE kanoniczna wartość z .yml, nie to, co usłyszał Vosk
                out.append((nowa, _dodaj_slot(sloty, element.klucz, wartosc),
                            kara + dokara))
        return out
    if isinstance(element, Alternatywa):
        out = []
        for wariant in element.warianty:
            out.extend(dopasuj_sekwencje(wariant, tokeny, [stan], sloty_def))
        if element.opcjonalna:
            out.append(stan)
        return out
    raise AssertionError('nieznany element %r' % element)


def _dopasuj_slowa(slowa, tokeny, poz):
    """Ciąg słów wzorca wobec tokenów; toleruje brak przyimka z POMIJALNE."""
    stany = [(poz, 0)]
    for w in slowa:
        nowe = []
        for p, k in stany:
            if p < len(tokeny) and tokeny[p] == w:
                nowe.append((p + 1, k))
            elif w in POMIJALNE:
                nowe.append((p, k + 1))
        if not nowe:
            return []
        stany = nowe
    return stany


# ---------------------------------------------------------------------------
# 5. Silnik
# ---------------------------------------------------------------------------

class Wynik:
    def __init__(self, intent, sloty, kara, wyrazenie):
        self.intent, self.sloty, self.kara, self.wyrazenie = intent, sloty, kara, wyrazenie

    def __repr__(self):
        return '%s %s' % (self.intent, self.sloty)


class SilnikGramatyki:
    def __init__(self, path=YML, jezyk='pl'):
        ustaw_jezyk(jezyk)
        self.jezyk = jezyk
        wyrazenia, sloty = wczytaj_yml(path)
        self.sloty_def = {k: [_odcytuj(v) for v in vs] for k, vs in sloty.items()}
        self.wyrazenia = []          # (intent, tekst, sekwencja)
        for intent, teksty in wyrazenia.items():
            for tekst in teksty:
                self.wyrazenia.append((intent, tekst, parsuj_wyrazenie(tekst)))
        self._sprawdz_referencje()

    def _sprawdz_referencje(self):
        """Slot użyty w wyrażeniu, którego nie ma w sekcji slots = cicha awaria."""
        braki = set()

        def obejdz(seq):
            for e in seq:
                if isinstance(e, Slot) and e.nazwa not in self.sloty_def:
                    braki.add(e.nazwa)
                elif isinstance(e, Wbudowany) and e.typ not in ZAKRESY:
                    braki.add('pv.' + e.typ)
                elif isinstance(e, Alternatywa):
                    for w in e.warianty:
                        obejdz(w)
        for _, _, seq in self.wyrazenia:
            obejdz(seq)
        if braki:
            raise SystemExit('Gramatyka odwołuje się do nieznanych slotów/typów: %s'
                             % ', '.join(sorted(braki)))

    # -- dopasowanie ------------------------------------------------------
    def rozpoznaj(self, tekst):
        """Tekst z Vosk -> Wynik albo None (odpowiednik isUnderstood=false)."""
        tokeny = [t for t in re.split(r'\s+', tekst.lower().strip()) if t]
        if not tokeny:
            return None
        trafienia = []
        for intent, wyr, seq in self.wyrazenia:
            for poz, sloty, kara in dopasuj_sekwencje(seq, tokeny, [(0, {}, 0)],
                                                      self.sloty_def):
                if poz == len(tokeny):          # cała wypowiedź zużyta
                    trafienia.append(Wynik(intent, sloty, kara, wyr))
        if not trafienia:
            return None
        # Więcej slotów = konkretniejsze dopasowanie; przy remisie mniej
        # pominiętych słów wzorca; dalej kolejność z .yml (stabilnie).
        trafienia.sort(key=lambda w: (-len(w.sloty), w.kara))
        return trafienia[0]

    def wszystkie(self, tekst):
        tokeny = [t for t in re.split(r'\s+', tekst.lower().strip()) if t]
        out = []
        for intent, wyr, seq in self.wyrazenia:
            for poz, sloty, kara in dopasuj_sekwencje(seq, tokeny, [(0, {}, 0)],
                                                      self.sloty_def):
                if poz == len(tokeny):
                    out.append(Wynik(intent, sloty, kara, wyr))
        return out

    # -- generowanie gramatyki dla Vosk -----------------------------------
    def slowa(self):
        """Wszystkie słowa literalne gramatyki (do kontroli OOV)."""
        out = set()

        def obejdz(seq):
            for e in seq:
                if isinstance(e, Slowo):
                    out.add(e.w)
                elif isinstance(e, Alternatywa):
                    for w in e.warianty:
                        obejdz(w)
        for _, _, seq in self.wyrazenia:
            obejdz(seq)
        for wartosci in self.sloty_def.values():
            for v in wartosci:
                out.update(v.lower().split())
        return out

    def liczebniki(self):
        return (set(JEDNOSTKI) | set(NASTKI) | set(DZIESIATKI) | set(SETKI)
                | PROCENT | set(ORDINALY))

    def slowa_otwierajace(self):
        """Zbiór FIRST - pierwsze słowa wyrażeń, do bramki „komenda musi się
        tak zaczynać". Idziemy po elementach, dopóki są opcjonalne."""
        out = set()

        def zbierz(seq):
            for e in seq:
                mozna_dalej = False
                if isinstance(e, Slowo):
                    out.add(e.w)
                elif isinstance(e, Slot):
                    for v in self.sloty_def.get(e.nazwa, []):
                        t = v.lower().split()
                        if t:
                            out.add(t[0])
                elif isinstance(e, Wbudowany):
                    out.update(self.liczebniki())
                elif isinstance(e, Alternatywa):
                    for w in e.warianty:
                        if zbierz(w):
                            mozna_dalej = True
                    if e.opcjonalna:
                        mozna_dalej = True
                if not mozna_dalej:      # element wymagany domyka zbiór FIRST
                    return False
            return True

        for _, _, seq in self.wyrazenia:
            zbierz(seq)
        return out - POMIJALNE          # przyimek nie otwiera komendy

    def frazy(self, intencje=None):
        """Gramatyka FRAZOWA dla KaldiRecognizer(grammar=...).

        `intencje` (zbiór nazw) zawęża wynik - tak powstaje gramatyka CZUWANIA
        (same frazy sesji „hej maja start/stop"). Odpowiednik parametru
        `intencje` w VoskGrammar.frazy() z lib/helpers/vosk_grammar.dart.

        Test z 30.07.2026 pokazał, że lista fraz bije płaską listę słów
        (płaska gubi fleksję: „z prawej stronę" zamiast „strony"), bo Vosk
        buduje z fraz bigramowy model języka.
        Wyrażenia rozwijamy na warianty, ale ROZCINAMY je na typach
        wbudowanych - inaczej same liczebniki dają wysyp kombinacji
        (101 procentów x 9 stron x ... = dziesiątki tysięcy fraz na jedno
        wyrażenie). Liczebniki idą osobno jako pojedyncze pozycje; bigram
        i tak działa lokalnie.
        """
        frazy = set()
        uzyto_liczebnikow = False
        for intent, _, seq in self.wyrazenia:
            if intencje is not None and intent not in intencje:
                continue
            if self._ma_wbudowany(seq):
                uzyto_liczebnikow = True
            for kawalek in self._rozetnij(seq):
                for warianty in self._rozwin(kawalek):
                    if warianty:
                        frazy.add(' '.join(warianty))
        if intencje is None:
            for wartosci in self.sloty_def.values():
                for v in wartosci:
                    frazy.add(v.lower())
        if intencje is None or uzyto_liczebnikow:
            frazy.update(self.liczebniki())
            # Druga połowa mostka: bigram liczebnik -> procent (~50 pozycji).
            for liczba in list(JEDNOSTKI) + list(NASTKI) + list(DZIESIATKI) + list(SETKI):
                frazy.add('%s procent' % liczba)
        frazy.discard('')
        return sorted(frazy)

    def _ma_wbudowany(self, seq):
        for e in seq:
            if isinstance(e, Wbudowany):
                return True
            if isinstance(e, Alternatywa):
                for w in e.warianty:
                    if self._ma_wbudowany(w):
                        return True
        return False

    def _rozetnij(self, seq):
        """Podziel sekwencję na kawałki bez typów wbudowanych."""
        kawalki, biezacy = [], []
        for e in seq:
            if isinstance(e, Wbudowany):
                if biezacy:
                    kawalki.append(biezacy)
                # Po $pv.Percent nowy kawałek zaczyna się OD "procent" - inaczej
                # słowo trafia do gramatyki tylko jako samotna fraza i model
                # języka nie ma bigramu wiążącego je z dalszym ciągiem komendy.
                biezacy = [Slowo('procent')] if e.typ == 'Percent' else []
            else:
                biezacy.append(e)
        if biezacy:
            kawalki.append(biezacy)
        return kawalki

    def _rozwin(self, seq):
        """Wszystkie warianty słowne sekwencji (lista list słów)."""
        wyniki = [[]]
        for e in seq:
            nowe = []
            if isinstance(e, Slowo):
                for r in wyniki:
                    nowe.append(r + [e.w])
            elif isinstance(e, Slot):
                for r in wyniki:
                    for v in self.sloty_def.get(e.nazwa, []):
                        nowe.append(r + v.lower().split())
            elif isinstance(e, Alternatywa):
                for r in wyniki:
                    for w in e.warianty:
                        for rozw in self._rozwin(w):
                            nowe.append(r + rozw)
                    if e.opcjonalna:
                        nowe.append(r)
            else:
                nowe = wyniki
            wyniki = nowe
            if len(wyniki) > 20000:      # bezpiecznik, nie powinno się zdarzyć
                raise SystemExit('rozwinięcie wyrażenia wybuchło: %d' % len(wyniki))
        return wyniki


# ---------------------------------------------------------------------------
# 6. Harness testowy
# ---------------------------------------------------------------------------
SLOWNIE = {
    0: 'zero', 1: 'jeden', 2: 'dwa', 3: 'trzy', 4: 'cztery', 5: 'pięć',
    6: 'sześć', 7: 'siedem', 8: 'osiem', 9: 'dziewięć', 10: 'dziesięć',
    11: 'jedenaście', 12: 'dwanaście', 13: 'trzynaście', 14: 'czternaście',
    15: 'piętnaście', 16: 'szesnaście', 17: 'siedemnaście', 18: 'osiemnaście',
    19: 'dziewiętnaście', 20: 'dwadzieścia', 30: 'trzydzieści',
    40: 'czterdzieści', 50: 'pięćdziesiąt', 60: 'sześćdziesiąt',
    70: 'siedemdziesiąt', 80: 'osiemdziesiąt', 90: 'dziewięćdziesiąt',
    100: 'sto', 200: 'dwieście', 300: 'trzysta', 400: 'czterysta',
    500: 'pięćset', 600: 'sześćset', 700: 'siedemset', 800: 'osiemset',
    900: 'dziewięćset',
}


def na_slowa(n):
    """Cyfry -> słowa (nagłówek lista_komend.txt każe tak czytać plik)."""
    n = int(n)
    if n in SLOWNIE:
        return SLOWNIE[n]
    czesci = []
    if n >= 100:
        czesci.append(SLOWNIE[(n // 100) * 100])
        n %= 100
    if n >= 20:
        czesci.append(SLOWNIE[(n // 10) * 10])
        n %= 10
    if n:
        czesci.append(SLOWNIE[n])
    return ' '.join(czesci)


def cyfry_na_slowa(tekst):
    return re.sub(r'\d+', lambda m: na_slowa(m.group(0)), tekst)


def wczytaj_komendy(path=None):
    """pliki/lista_komend.txt -> lista (oczekiwany_intent, komenda)."""
    path = path or os.path.join(HERE, 'lista_komend.txt')
    out, intent = [], None
    for surowa in open(path, encoding='utf-8'):
        s = surowa.strip()
        if not s or s.startswith('(') or s.startswith('Przykładowe'):
            continue
        if s.endswith(':') and re.match(r'^set[A-Za-z]+:$', s):
            intent = s[:-1]
            continue
        if intent:
            out.append((intent, s))
    return out


def test(pokaz_ok=False):
    silnik = SilnikGramatyki()
    komendy = wczytaj_komendy()
    ok = zle_intent = brak = 0
    problemy = []
    for oczekiwany, surowa in komendy:
        tekst = cyfry_na_slowa(surowa)
        w = silnik.rozpoznaj(tekst)
        if w is None:
            brak += 1
            problemy.append(('BRAK DOPASOWANIA', oczekiwany, surowa, tekst, ''))
        elif w.intent != oczekiwany:
            zle_intent += 1
            problemy.append(('ZŁY INTENT -> ' + w.intent, oczekiwany, surowa,
                             tekst, str(w.sloty)))
        else:
            ok += 1
            if pokaz_ok:
                print('  OK  %-14s %-42s %s' % (oczekiwany, surowa, w.sloty))
    print('\n=== %d komend: %d OK, %d bez dopasowania, %d zły intent'
          % (len(komendy), ok, brak, zle_intent))
    if problemy:
        print('\n--- do przejrzenia:')
        for powod, oczekiwany, surowa, tekst, sloty in problemy:
            print('  %-24s %-13s %s' % (powod, oczekiwany, surowa))
            if tekst != surowa:
                print('  %-24s %-13s -> %s' % ('', '', tekst))
            if sloty:
                print('  %-24s %-13s    %s' % ('', '', sloty))
    return brak + zle_intent


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('tekst', nargs='*')
    ap.add_argument('--test', action='store_true', help='przejedź lista_komend.txt')
    ap.add_argument('-v', action='store_true', help='pokaż też trafienia')
    ap.add_argument('--frazy', action='store_true', help='wypisz gramatykę frazową')
    ap.add_argument('--slowa', action='store_true', help='wypisz słowa gramatyki')
    ap.add_argument('--wszystkie', action='store_true', help='pokaż wszystkie dopasowania')
    ap.add_argument('--yamlcheck', action='store_true', help='porównaj z pyyaml')
    a = ap.parse_args()

    if a.yamlcheck:
        import yaml
        wl, sl = wczytaj_yml()
        d = yaml.safe_load(open(YML, encoding='utf-8'))['context']
        zgoda = True
        for sekcja, moje in (('expressions', wl), ('slots', sl)):
            ich = {k: [str(x) for x in v] for k, v in d[sekcja].items()}
            moje2 = {k: [' '.join(x.split()) for x in v] for k, v in moje.items()}
            ich2 = {k: [' '.join(x.split()) for x in v] for k, v in ich.items()}
            if moje2 != ich2:
                zgoda = False
                print('ROZJAZD w %s:' % sekcja)
                for k in set(moje2) | set(ich2):
                    if moje2.get(k) != ich2.get(k):
                        print('  %s\n    moje: %s\n    yaml: %s'
                              % (k, moje2.get(k), ich2.get(k)))
        print('parser własny == pyyaml: %s' % ('TAK' if zgoda else 'NIE'))
        sys.exit(0 if zgoda else 1)

    if a.frazy:
        s = SilnikGramatyki()
        f = s.frazy()
        print('\n'.join(f))
        print('--- %d fraz' % len(f), file=sys.stderr)
        sys.exit(0)
    if a.slowa:
        s = SilnikGramatyki()
        print('\n'.join(sorted(s.slowa() | s.liczebniki())))
        sys.exit(0)
    if a.test or not a.tekst:
        sys.exit(1 if test(a.v) else 0)

    s = SilnikGramatyki()
    tekst = cyfry_na_slowa(' '.join(a.tekst))
    if a.wszystkie:
        for w in sorted(s.wszystkie(tekst), key=lambda w: (-len(w.sloty), w.kara)):
            print('%-14s kara=%d %s\n    <- %s' % (w.intent, w.kara, w.sloty, w.wyrazenie))
    else:
        w = s.rozpoznaj(tekst)
        print('tekst : %s' % tekst)
        if w is None:
            print('wynik : isUnderstood = false')
        else:
            print('intent: %s' % w.intent)
            print('sloty : %s' % w.sloty)
            print('wyraż.: %s' % w.wyrazenie)
