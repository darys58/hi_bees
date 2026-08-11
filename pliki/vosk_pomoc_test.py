#!/usr/bin/env python3
# Czy okna pomocy uczą fraz, które gramatyka NAPRAWDĘ rozpoznaje?
#
# Pomoc (lib/screens/voice_help_dialogs.dart + klucze w lib/l10n/app_pl.arb) to
# jedyne miejsce, gdzie użytkownik czyta, JAK powiedzieć komendę. Jeżeli rozjedzie
# się z assets/grammar/pol_vosk.yml, uczy fraz, na które silnik nie zareaguje -
# a objaw jest nie do odróżnienia od "głos nie działa". Tak było po migracji
# Picovoice->Vosk: pomoc została nietknięta i miała ~20 martwych fraz
# ("rodzina jest zła", "ustaw prawdziwą datę", "Biovar wstaw 3 paski"...).
#
# Skrypt jedzie w dwie strony:
#   ZIELONE - każda fraza, której uczy pomoc, musi się dopasować,
#   CZERWONE - stare, błędne formy muszą NIE dopasować się (inaczej "poprawka"
#              niczego nie naprawiła, bo gramatyka brała obie formy).
#
# ALIASY FONETYCZNE. Pomoc pokazuje formę WYMAWIANĄ, gramatyka - to, co słyszy
# model. Poniżej frazy zapisane są tak, jak zwróci je Vosk:
#   nakrop -> "na grób"      węza  -> "węża"       pierzga -> "pierzcha"
#   trut   -> "trud"         mateczniki -> "matecznik i"/"matecznik ów"
#   półkorpus -> "pół korpus"    miodobranie -> "miodu branie"
# To NIE są błędy pomocy - nie "poprawiać" jej do postaci z pliku YML.
#
# Użycie:
#   python3 pliki/vosk_pomoc_test.py        # podsumowanie
#   python3 pliki/vosk_pomoc_test.py -v     # z rozpoznanym wyrażeniem dla każdej frazy

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from vosk_parser_ref import SilnikGramatyki  # noqa: E402

# --- frazy, których uczy pomoc (kolejność jak sekcje w voice_help_dialogs.dart)
POMOC = [
    ('sesja', [
        'hej maja start', 'hej maja zaczynamy', 'hej maja startujemy',
        'hej maja stop', 'hej maja kończymy', 'hej maja koniec',
        'zanotuj', 'zapisz notatkę', 'hej maja notatka do przeglądu',
        'hej maja notatka do notesu',
        'hej maja cofnij ostatni zapis', 'hej maja cofnij ostatni wpis',
    ]),
    ('lokacja', [
        'otwórz pasiekę numer jeden',
        'otwórz wszystkie ule',
        'ustaw ule od jeden do pięć',
        'otwórz ul numer pięć',
        'otwórz korpus numer dwa',
        'otwórz pół korpus numer dwa',
        'otwórz duża ramka numer sześć z lewej strony',
        'otwórz mała ramkę numer sześć z obu stron',
        'ramka numer dwa po przeglądzie numer pięć',
        'przenieś ul numer cztery korpus numer trzy ramka numer dziesięć',
        'przenieś ul numer cztery pół korpus numer trzy ramka numer dziesięć',
        'wstaw duża ramka numer cztery',
        'ustaw ramkę od jeden do dziewięć',
    ]),
    ('przegląd', [
        'czerw trud dziesięć procent z lewej strony',
        'czerw kryty dwadzieścia procent z prawej strony',
        'larwy trzydzieści pięć procent z lewej strony',
        'jajka trzydzieści pięć procent z lewej strony',
        'pierzcha trzydzieści pięć procent z lewej strony',
        'miód trzydzieści pięć procent z lewej strony',
        'pokarm trzydzieści pięć procent z lewej strony',
        'na grób trzydzieści pięć procent z lewej strony',
        'miód dojrzały trzydzieści pięć procent z lewej strony',
        'węża trzydzieści pięć procent z lewej strony',
        'susz trzydzieści pięć procent z lewej strony',
        'czarna matka z lewej strony', 'żółta matka z lewej strony',
        'czerwona matka z lewej strony', 'zielona matka z lewej strony',
        'niebieska matka z lewej strony', 'biała matka z lewej strony',
        'inna matka z lewej strony',
        'dwa matecznik i z lewej strony',
        'usuń trzy matecznik ów z lewej strony',
        'ustaw z lewej strony', 'ustaw z obu stron',
        'ramka pracy', 'trzeba wirować', 'trzeba usunąć', 'można izolować',
        'usuń ramkę', 'wstaw ramkę', 'izolacja',
        'przesuń w lewo', 'przesuń w prawo',
    ]),
    ('wyposażenie', [
        'ustaw ilość ramek w korpusie jest dziesięć',
        'krata na korpusie numer jeden',
        'usuń kratę',
        'podłoga jest ok', 'podłoga jest brudna', 'podłoga jest czysta',
        'podłoga jest wyczyszczona',
        'załącz zbieracz pyłku', 'wyłącz zbieracz pyłku',
        'otwórz zbieracz pyłku', 'zamknij zbieracz pyłku',
        'ustaw zbieracz pyłku',
    ]),
    ('matka', [
        'matka jest z roku dwadzieścia trzy',
        'matka jest dziewicza', 'matka jest sztuczna', 'matka jest naturalna',
        'matka jest wolna', 'matka jest zamknięta', 'matka jest w klatce',
        'matka nie ma znaku',
        'matka ma biały znak numer pięćdziesiąt pięć',
        'matka ma żółty znak', 'matka ma czerwony znak',
        'matka ma zielony znak', 'matka ma niebieski znak',
        'matka nie ma', 'matka brak',
        'matka jest bardzo dobra', 'matka jest dobra', 'matka jest ok',
        'matka jest duża', 'matka jest mała', 'matka jest słaba',
        'matka jest do wymiany', 'matka jest stara',
    ]),
    ('rodzina', [
        'rodzina jest łagodna', 'rodzina jest agresywna', 'rodzina jest ok',
        'rodzina jest w nastroju do ucieczki', 'rodzina zawiązała kłąb',
        'rodzina nie żyje',
        'rodzina jest bardzo silna', 'rodzina jest silna',
        'rodzina jest normalna', 'rodzina jest słaba',
        'rodzina jest bardzo słaba',
        'martwe pszczoły dwieście pięćdziesiąt mililitrów',
        'martwych pszczół dwieście pięćdziesiąt mililitrów',
    ]),
    ('dokarmianie', [
        'syrop jeden do jednego jeden przecinek pięć litr',
        'syrop trzy do dwóch trzy przecinek pięć litr',
        'ciasto jeden przecinek zero kilo',
        'syrop dwa przecinek siedem litr',
        'zostało trzydzieści procent pokarmu',
        'usuń trzydzieści procent pokarmu',
    ]),
    ('leczenie', [
        'chemia dawka numer jeden', 'chemia porcja numer jeden',
        'wstaw paski trzy sztuki', 'usuń paski trzy sztuki',
        'kwas czterdzieści mililitrów',
        'roztocza dwieście osiemnaście sztuk',
    ]),
    ('zbiory', [
        'zbiór miodu dziesięć razy mała ramka',
        'miodu branie dziesięć razy duża ramka',
        'zbiór pyłku dwa razy miarka',
        'zbiór pyłku osiemset dwadzieścia pięć mililitrów',
        'zbiór pyłku zero przecinek piętnaście litr',
    ]),
    ('data', [
        'ustaw inny dzień piętnaście', 'ustaw inny miesiąc trzy',
        'ustaw inny rok dwadzieścia dwa', 'ustaw aktualną datę',
    ]),
    ('pomóż mi', [
        'lokacja pomóż mi', 'przegląd pomóż mi', 'wyposażenie pomóż mi',
        'matka pomóż mi', 'rodzina pomóż mi', 'dokarmianie pomóż mi',
        'leczenie pomóż mi', 'zbiory pomóż mi', 'data pomóż mi',
        'zamknij pomoc', 'pomóż mi',
        'ul pomóż mi', 'ul przed pomóż mi', 'ul po pomóż mi',
        'ul wcześniej pomóż mi', 'ul później pomóż mi',
    ]),
]

# --- formy, których pomoc uczyła PRZED poprawką 11.08.2026.
# Każda MUSI zostać odrzucona - inaczej poprawka była kosmetyczna.
NIEAKTUALNE = [
    ('pasieka zamiast pasiekę', 'otwórz pasieka numer jeden'),
    ('ramka zamiast ramkę (setFrames)', 'ustaw ramka od jeden do dziewięć'),
    ('larwa zamiast larwy', 'larwa trzydzieści pięć procent z lewej strony'),
    ('usuń ramka zamiast ramkę', 'usuń ramka'),
    ('na korpus zamiast w korpusie', 'ustaw ilość ramek na korpus jest dziesięć'),
    ('dennica spoza gramatyki', 'dennica jest ok'),
    ('poławiacz zamiast zbieracz', 'załącz poławiacz pyłku'),
    ('włącz spoza slotu $state', 'włącz zbieracz pyłku'),
    ('dziewica zamiast dziewicza', 'matka jest dziewica'),
    ('nie ma znak zamiast znaku', 'matka nie ma znak'),
    ('zła zamiast agresywna', 'rodzina jest zła'),
    ('w kłębie zamiast zawiązała kłąb', 'rodzina w kłębie'),
    ('norma zamiast normalna', 'rodzina jest norma'),
    ('osyp zamiast martwe pszczoły', 'osyp pszczół dwieście pięćdziesiąt mililitrów'),
    ('prawdziwą zamiast aktualną', 'ustaw prawdziwą datę'),
    ('pokarm zamiast dokarmianie', 'pokarm pomóż mi'),
    ('zbiór zamiast zbiory', 'zbiór pomóż mi'),
    ('Biovar spoza gramatyki', 'biovar wstaw trzy paski'),
    ('chemia z liczbą na początku', 'chemia jeden dawka'),
    ('razy w wariancie mililitrowym',
     'zbiór pyłku osiemset dwadzieścia pięć razy mililitrów'),
]


def main(gadatliwy=False):
    silnik = SilnikGramatyki()
    bledy = []

    print('=== frazy z pomocy (muszą się dopasować)')
    razem = 0
    for sekcja, frazy in POMOC:
        zle = []
        for fraza in frazy:
            razem += 1
            w = silnik.rozpoznaj(fraza)
            if w is None:
                zle.append(fraza)
                bledy.append(('NIEROZPOZNANA', sekcja, fraza))
            elif gadatliwy:
                print('    OK  %-52s %s' % (fraza, w.intent))
        stan = 'OK' if not zle else 'BŁĄD (%d)' % len(zle)
        print('  %-14s %3d fraz  %s' % (sekcja, len(frazy), stan))
        for fraza in zle:
            print('      nie dopasowano: %s' % fraza)

    print('\n=== formy nieaktualne (muszą zostać odrzucone)')
    for opis, fraza in NIEAKTUALNE:
        w = silnik.rozpoznaj(fraza)
        if w is not None:
            bledy.append(('WCIĄŻ DZIAŁA', opis, fraza))
            print('  BŁĄD  %-34s %s -> %s' % (opis, fraza, w.intent))
        elif gadatliwy:
            print('    OK  %-34s %s' % (opis, fraza))
    if not [b for b in bledy if b[0] == 'WCIĄŻ DZIAŁA']:
        print('  wszystkie %d odrzucone' % len(NIEAKTUALNE))

    print('\n=== %d fraz pomocy, %d form nieaktualnych: %s'
          % (razem, len(NIEAKTUALNE), 'OK' if not bledy else '%d PROBLEMÓW' % len(bledy)))
    return 1 if bledy else 0


if __name__ == '__main__':
    sys.exit(main('-v' in sys.argv))
