#!/usr/bin/env python3
# Czy wartości slotów z gramatyki trafiają do bazy w postaci, którą reszta
# aplikacji rozpozna?
#
# TRZECI strażnik obok vosk_pomoc_test.py / vosk_pomoc_test_en.py, i pilnuje
# INNEJ warstwy. Tamte sprawdzają "czy da się to wypowiedzieć". Ten sprawdza,
# co się ZAPISZE - i czy zapisany string jest tym samym, którego szukają
# painter ramek, ikony ula, raporty i ręczna edycja.
#
# PO CO (04.09.2026): "to extract"/"to remove" były poprawnie ROZPOZNAWANE,
# ale nie rysowały trójkąta nad ramką. Powód: frames_screen porównuje wartość
# ZNAK W ZNAK z app_en.arb ("to extraction"/"to delete"), a gramatyka mówi
# krócej. Ten sam mechanizm zepsuł wcześniej "virgin"/"virgine" i
# "swarming"/"swarming mood". Polski audyt z 04.08.2026 znalazł dokładnie tę
# klasę błędu dla 9 slotów - wtedy ręcznie, bo nie było tego skryptu.
#
# JAK TO DZIAŁA
#   wartość z gramatyki -> _ujednolicWartosciSlotow (voice_vosk_screen.dart)
#   -> wartość zapisana. Skrypt czyta OBA mapowania (_mapowanieSlotowPl,
#   _mapowanieSlotowEn) wprost z kodu Darta, więc nie da się ich rozjechać
#   z tym testem. Wartość PO przeliczeniu musi istnieć w odpowiednim .arb
#   (albo być jawnie dopuszczonym literałem - patrz LITERALY).
#
# Użycie:
#   python3 pliki/vosk_sloty_arb_test.py        # podsumowanie
#   python3 pliki/vosk_sloty_arb_test.py -v     # z każdą wartością

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

from vosk_parser_ref import SilnikGramatyki  # noqa: E402

EKRAN = os.path.join(ROOT, 'lib', 'screens', 'voice_vosk_screen.dart')

# Sloty, których wartości LĄDUJĄ W BAZIE jako tekst. Pozostałe ($state,
# $hundred, $date, $help...) sterują tylko przebiegiem polecenia.
#
# $queen (kolor matki) CELOWO POMINIĘTY: voice_vosk_screen zamienia go
# switchem na cyfrę '1'..'7' (case 'czarna' -> queen = '1'), więc do bazy
# nigdy nie idzie słowo. Angielskie kolory pasują do ARB przypadkiem
# (blackColor itd.) - to nie jest dowód poprawności.
ISTOTNE = ['toDo', 'isDone', 'sizeOfFrame', 'queenState', 'queenMark',
           'queenQuality', 'colonyForce', 'colonyState', 'quality']

# Wartości, które CELOWO nie są kluczem ARB - kod porównuje je z literałem.
LITERALY = {'ok'}

JEZYKI = {
    'pl': (os.path.join(ROOT, 'assets', 'grammar', 'pol_vosk.yml'),
           os.path.join(ROOT, 'lib', 'l10n', 'app_pl.arb'),
           '_mapowanieSlotowPl'),
    'en': (os.path.join(ROOT, 'assets', 'grammar', 'eng_vosk.yml'),
           os.path.join(ROOT, 'lib', 'l10n', 'app_en.arb'),
           '_mapowanieSlotowEn'),
}


def wczytaj_mapowanie(nazwa_metody):
    """Wyciąga {slot: {forma_z_gramatyki: klucz_ARB_lub_literal}} z Darta."""
    with open(EKRAN, encoding='utf8') as f:
        src = f.read()
    start = src.index('%s(AppLocalizations l10n) => {' % nazwa_metody)
    # koniec mapy: pierwsze "      };" w tej samej kolumnie co otwarcie
    koniec = src.index('\n      };', start)
    blok = re.sub(r'//[^\n]*', '', src[start:koniec])

    mapowanie, biezacy = {}, None
    for linia in blok.split('\n'):
        s = linia.strip()
        m = re.match(r"^'([A-Za-z]+)':\s*\{$", s)
        if m:
            biezacy = m.group(1)
            mapowanie[biezacy] = {}
            continue
        m = re.match(r"^'(.+?)':\s*(?:l10n\.(\w+)|'(.+?)'),$", s)
        if m and biezacy:
            mapowanie[biezacy][m.group(1)] = ('klucz', m.group(2)) \
                if m.group(2) else ('literal', m.group(3))
    return mapowanie


def klucze_slotow(yml_path):
    """NAZWA slotu -> KLUCZE, pod jakimi wchodzi do inference.slots.

    To nie zawsze to samo: gramatyka ma "$quality:bottomBoard", więc slot
    NAZYWA się `quality`, ale w slotach wyniku (i w mapowaniu
    _ujednolicWartosciSlotow, które chodzi po `sloty.keys`) występuje jako
    `bottomBoard`. Bez tego rozróżnienia test szukał mapowania pod złą nazwą
    i zgłaszał fałszywe alarmy.
    """
    with open(yml_path, encoding='utf8') as f:
        tekst = re.sub(r'#[^\n]*', '', f.read())
    uzycia = {}
    for nazwa, klucz in re.findall(r'\$([A-Za-z][A-Za-z0-9_]*):([A-Za-z0-9_]+)',
                                   tekst):
        if nazwa.startswith('pv.'):
            continue
        uzycia.setdefault(nazwa, set()).add(klucz)
    return uzycia


def wartosci_zapisywane(kod):
    """slot -> [(forma z gramatyki, wartość ZAPISANA, skąd)] + treść ARB."""
    yml, arb_path, metoda = JEZYKI[kod]
    silnik = SilnikGramatyki(yml, jezyk=kod)
    uzycia = klucze_slotow(yml)
    mapowanie = wczytaj_mapowanie(metoda)
    with open(arb_path, encoding='utf8') as f:
        arb = json.load(f)

    wynik, braki = {}, []
    for slot in ISTOTNE:
        pozycje = []
        for surowa in silnik.sloty_def.get(slot, []):
            #mapowanie jest kluczowane KLUCZEM slotu, nie jego nazwą
            przeliczenie = None
            for klucz_slotu in sorted(uzycia.get(slot, {slot})):
                przeliczenie = mapowanie.get(klucz_slotu, {}).get(surowa)
                if przeliczenie is not None:
                    break
            if przeliczenie is None:
                pozycje.append((surowa, surowa, 'bez przeliczenia'))
            elif przeliczenie[0] == 'klucz':
                klucz = przeliczenie[1]
                if klucz not in arb:
                    braki.append((slot, surowa, 'mapowanie wskazuje na '
                                  'NIEISTNIEJĄCY klucz ARB l10n.%s' % klucz))
                    continue
                pozycje.append((surowa, arb[klucz], 'l10n.%s' % klucz))
            else:
                pozycje.append((surowa, przeliczenie[1], 'literał'))
        wynik[slot] = pozycje
    return wynik, arb, braki


def main(gadatliwy=False):
    dane = {}
    bledy = []
    for kod in ('pl', 'en'):
        dane[kod], arb, braki = wartosci_zapisywane(kod)
        dane[kod + '_arb'] = arb
        bledy += [(kod,) + b for b in braki]

    # KRYTERIUM. Nie wystarczy, że taki napis GDZIEŚ w ARB istnieje - musi to
    # być klucz, którego odpowiednik w DRUGIM języku też jest zapisywany przez
    # ten sam slot. Inaczej test przepuszcza przypadkowe zbieżności: "to
    # remove" pasuje do klucza `tORemove` ("Usunąć?" - pytanie w oknie
    # potwierdzenia z infos_screen), choć painter ramek porównuje `toDelete`.
    # Ta zbieżność przepuściła realny błąd zgłoszony 04.09.2026.
    razem = 0
    for kod in ('pl', 'en'):
        inny = 'pl' if kod == 'en' else 'en'
        arb, arb_inny = dane[kod + '_arb'], dane[inny + '_arb']
        print('=== %s ===' % kod)
        lokalne = []
        for slot, pozycje in dane[kod].items():
            zapisane_w_drugim = {z.lower() for _, z, _ in dane[inny][slot]}
            for surowa, zapisana, skad in pozycje:
                razem += 1
                ok = zapisana in LITERALY or any(
                    isinstance(arb_inny.get(k), str)
                    and arb_inny[k].lower() in zapisane_w_drugim
                    for k, v in arb.items()
                    if isinstance(v, str) and v.lower() == zapisana.lower())
                if gadatliwy:
                    print('    %-4s %-12s %-26s -> %-26s %s'
                          % ('OK' if ok else 'BŁĄD', slot, surowa, zapisana,
                             skad))
                if not ok:
                    lokalne.append((slot, surowa,
                                    'zapisze "%s", ale odpowiednik tej wartości '
                                    'nie jest zapisywany przez slot %s w %s'
                                    % (zapisana, slot, inny)))
        for slot, wartosc, opis in lokalne:
            print('  BŁĄD  %-12s %-26s %s' % (slot, wartosc, opis))
        print('  %d wartości slotów: %s'
              % (len(sum(dane[kod].values(), [])),
                 'OK' if not lokalne else '%d PROBLEMÓW' % len(lokalne)))
        bledy += [(kod,) + b for b in lokalne]

    print('\n=== %d wartości razem: %s'
          % (razem, 'OK' if not bledy else '%d PROBLEMÓW' % len(bledy)))
    return 1 if bledy else 0


if __name__ == '__main__':
    sys.exit(main('-v' in sys.argv))
