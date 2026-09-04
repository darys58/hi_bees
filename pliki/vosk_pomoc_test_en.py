#!/usr/bin/env python3
# Czy ANGIELSKIE okna pomocy uczą fraz, które gramatyka NAPRAWDĘ rozpoznaje?
#
# Bliźniak pliki/vosk_pomoc_test.py (polski), ta sama logika i ten sam powód
# istnienia - patrz nagłówek tamtego pliku. Tutaj źródłem jest
# assets/grammar/eng_vosk.yml + angielskie wartości z lib/l10n/app_en.arb.
#
# PO CO POWSTAŁ (04.09.2026): angielska pomoc rozjechała się z gramatyką na
# SZEŚĆ niezależnych sposobów, a każdy objawiał się identycznie - "powiedziałem
# dokładnie to, co pokazuje pomoc, i nic się nie stało". Użytkownik zgłaszał je
# pojedynczo z urządzenia (to extraction, on the, frames, ...), aż zapytał
# wprost, czy nie dałoby się sprawdzić CAŁEJ pomocy naraz. Ten skrypt to robi.
#
# Źródła rozjazdów, wszystkie realnie znalezione:
#   1. stare teksty z eng1.yml (sprzed migracji na Vosk), nigdy nieaktualizowane
#      przy pisaniu eng_vosk.yml - "to extraction"/"to delete", "Apivarol",
#      "covered brood", "put on", "belts";
#   2. wartość ARB kanoniczna (do bazy) pomylona z wypowiadaną - "to replace"
#      zamiast "to exchange", "virgine" zamiast "virgin";
#   3. liczba pojedyncza/mnoga - "frame from X to Y" zamiast "frames",
#      "number of frame in body" (klucz DB, gramatyka przyjmuje teraz obie);
#   4. szyk przymiotnika przeniesiony z polskiego - "brood drone" zamiast
#      "drone brood";
#   5. słowo spoza słownika modelu - "excluder" (działa "grid"/"grate");
#   6. zwykłe literówki - "seald", "site" zamiast "side".
#
# Użycie:
#   python3 pliki/vosk_pomoc_test_en.py        # podsumowanie
#   python3 pliki/vosk_pomoc_test_en.py -v     # z rozpoznanym intentem

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from vosk_parser_ref import SilnikGramatyki  # noqa: E402

YML_EN = os.path.join(os.path.dirname(HERE), 'assets', 'grammar', 'eng_vosk.yml')

# --- frazy, których uczy pomoc (kolejność jak sekcje w voice_help_dialogs.dart)
# Liczby zapisane SŁOWAMI, bo tak zwraca je Vosk - pomoc pokazuje cyfry
# ("6", "35%") dokładnie tak samo jak polska.
POMOC = [
    ('location', [
        'open apiary number one',
        'open all hives',
        'set hives from one to five',
        'open hive number five',
        'open body number two',
        'open half body number two',
        'open big frame number six on the left',
        'open small frame number six on the right',
        'frame number six',                       # $state i rozmiar opcjonalne
        'frame number two after inspection number five',
        'move hive number four body number three frame number ten',
        'move hive number four half body number three frame number ten',
        'insert big frame number four',
        'insert small frame number four',
        'set frames from one to nine',            # POPRAWKA: było "frame"
    ]),
    ('inspection', [
        'drone brood ten percent on the left',    # POPRAWKA: było "brood drone"
        'drone ten percent on the left',          # "brood" opcjonalne
        'capped brood twenty percent on the left',   # POPRAWKA: było "covered"
        'sealed brood twenty percent on the right',
        'larvae thirty five percent on the left',
        'eggs thirty five percent on the left',
        'pollen thirty five percent on the left',
        'honey thirty five percent on the left',
        'food thirty five percent on the left',
        'sealed thirty five percent on the left',    # POPRAWKA: było "seald"
        'wax thirty five percent on the left',
        'comb thirty five percent on the left',
        'black queen on the left',
        'white queen on the right',
        'two queen cells on the left',
        'delete three queen cells on the left',
        'set left side',
        'set right side',
        'set both side',
        'work frame',
        'to extraction',                          # forma KANONICZNA (z pomocy)
        'to extract',                             # tolerowany skrót
        'to delete',                              # forma KANONICZNA (z pomocy)
        'to remove',                              # tolerowany skrót
        'to insulate',
        'deleted',
        'inserted',
        'insulated',
        'moved left',
        'moved right',
    ]),
    ('equipment', [
        'set number of frames in body is ten',
        'set number of frame in body is ten',     # forma z pomocy (klucz DB)
        'grid on body number one',                # POPRAWKA: było "excluder"
        'grate on body number one',
        'delete grid',
        'remove grate',
        'bottom board is ok',
        'bottom board is dirty',
        'bottom board is clean',
        'bee pollen trap is on',
        'bee pollen trap is off',
        'bee pollen trap is open',
        'bee pollen trap is close',
        'bee pollen trap is set',
    ]),
    ('queen', [
        'queen was born in twenty three',
        'queen is virgin',                        # POPRAWKA: było "virgine"
        'queen is artificially inseminated',
        'queen is naturally mated',
        'queen is freed',
        'queen is in a cage',
        'queen is in the insulator',
        'queen is unmarked',
        'queen is marked white number fifty five',
        'queen is marked yellow',
        'queen is marked red',
        'queen is marked green',
        'queen is marked blue',
        'queen is gone',
        'queen is missing',
        'queen is very good',
        'queen is good',
        'queen is ok',
        'queen is big',
        'queen is small',
        'queen is weak',
        'queen is to exchange',                   # POPRAWKA: było "to replace"
        'queen is old',
    ]),
    ('colony', [
        'colony is gentle',
        'colony is aggressive',
        'colony is ok',
        'colony is swarming mood',
        'colony is swarming',
        'colony is in a cluster',
        'colony is dead',
        'colony is very strong',
        'colony is strong',
        'colony is normal',
        'colony is weak',
        'colony is very weak',
        'dead bees two hundred fifty milliliter',
    ]),
    ('feeding', [
        'syrup one to one one point five liters',
        'syrup three to two three point five liters',
        'bee candy one point zero kilo',
        'invert two point seven liters',
        'left food thirty percent',
        'remove food thirty percent',
    ]),
    ('treatment', [
        'chemistry first dose',                   # POPRAWKA: było "Apivarol"
        'chemistry dose number one',
        'chemistry portion number one',
        'insert strips three units',              # POPRAWKA: było "belts"/"mites"
        'remove strips three units',              # POPRAWKA: było "put on"
        'acid forty milliliter',
        'varroa two hundred eighteen mites',
    ]),
    ('harvest', [
        'honey harvest ten small frames',
        'honey harvest ten small frame',          # forma z pomocy (l.p.)
        'honey harvest ten big frames',
        'bee pollen harvest two portion',
        'bee pollen harvest eight hundred twenty five milliliter',
        'bee pollen harvest zero point fifteen liters',
    ]),
    ('date', [
        'set other day fifteen',
        'set other month three',                  # POPRAWKA: było "mouth"
        'set other year twenty two',
        'set current date',
    ]),
    ('help me', [
        'location help me',
        'inspection help me',
        'equipment help me',
        'queen help me',
        'colony help me',
        'feeding help me',
        'treatment help me',
        'harvest help me',
        'date help me',
        'hive help me',
        'notes help me',
        'close help',
        'help me',
    ]),
    ('session', [
        'hey maya start',
        'hey maya begin',
        'hey maya stop',
        'hey maya done',
        'hey maya finished',
        'note',
        'hey maya note',
        'write note',
        'hey maya note for inspection',
        'hey maya note for notepad',
        'hey maya undo last save',
        'hey maya undo last entry',
    ]),
]

# --- formy, których pomoc uczyła PRZED audytem 04.09.2026.
# Każda MUSI zostać odrzucona - inaczej poprawka była kosmetyczna.
NIEAKTUALNE = [
    ('frame zamiast frames (setFrames)', 'set frame from one to nine'),
    ('brood drone - szyk z polskiego', 'brood drone ten percent on the left'),
    ('covered z eng1.yml', 'covered brood twenty percent on the left'),
    ('seald - literowka', 'seald thirty five percent on the left'),
    ('virgine - wartosc ARB, nie wypowiadana', 'queen is virgine'),
    ('to replace - wartosc ARB, nie wypowiadana', 'queen is to replace'),
    ('apivarol usuniety z gramatyki', 'apivarol dose number one'),
    ('part spoza [portion, dose]', 'chemistry part number one'),
    ('put on spoza slotu $state', 'put on strips three units'),
    ('belts - wartosc ARB, nie wypowiadana', 'insert belts three units'),
    ('mites przy paskach zamiast units', 'insert strips three mites'),
    # UWAGA: "excluder" NIE trafia tutaj, choć w pomocy zostało zastąpione przez
    # grid/grate. Powód: to słowo JEST w gramatyce (alternatywa
    # [excluder,grid,grate]), więc parser je rozpozna - brakuje go dopiero
    # w SŁOWNIKU MODELU Vosk, czyli warstwę niżej, której ten test nie widzi.
    # Sprawdza to osobna kontrola OOV wobec pliki/vosk_slownik_eng.txt
    # (polecenie w nagłówku assets/grammar/eng_vosk.yml).
    ('activated spoza slotu $state', 'bee pollen trap is activated'),
    ('eliminated spoza slotu $state', 'bee pollen trap is eliminated'),
    ('mouth zamiast month', 'set other mouth three'),
    ('site zamiast side', 'set left site'),
    # UWAGA: "to extraction"/"to delete" NIE są tu wymienione - od 04.09.2026
    # to formy KANONICZNE, które mają działać. Wcześniej stały w tej liście
    # przez moją pomyłkę z KROK 2 (skróciłem je w gramatyce bez powodu, choć
    # oba słowa są w słowniku modelu) - patrz komentarz przy slocie toDo
    # w eng_vosk.yml.
]


def main(gadatliwy=False):
    silnik = SilnikGramatyki(YML_EN, jezyk='en')
    bledy = []

    print('=== frazy z pomocy EN (muszą się dopasować)')
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
        print('  %-12s %3d fraz  %s' % (sekcja, len(frazy), stan))
        for fraza in zle:
            print('      nie dopasowano: %s' % fraza)

    print('\n=== formy nieaktualne (muszą zostać odrzucone)')
    for opis, fraza in NIEAKTUALNE:
        w = silnik.rozpoznaj(fraza)
        if w is not None:
            bledy.append(('WCIĄŻ DZIAŁA', opis, fraza))
            print('  BŁĄD  %-38s %s -> %s' % (opis, fraza, w.intent))
        elif gadatliwy:
            print('    OK  %-38s %s' % (opis, fraza))
    if not [b for b in bledy if b[0] == 'WCIĄŻ DZIAŁA']:
        print('  wszystkie %d odrzucone' % len(NIEAKTUALNE))

    print('\n=== %d fraz pomocy, %d form nieaktualnych: %s'
          % (razem, len(NIEAKTUALNE),
             'OK' if not bledy else '%d PROBLEMÓW' % len(bledy)))
    return 1 if bledy else 0


if __name__ == '__main__':
    sys.exit(main('-v' in sys.argv))
