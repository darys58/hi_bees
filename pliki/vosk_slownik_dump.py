#!/usr/bin/env python3
# Wyciąga listę wszystkich słów, które model Vosk w ogóle potrafi rozpoznać.
#
# Model vosk-model-small-pl-0.22 NIE ma pliku graph/words.txt — tablica symboli
# (słownik) jest zapisana WEWNĄTRZ binarnego graph/Gr.fst, w formacie OpenFst.
# Ten skrypt czyta nagłówek FST i odtwarza z niego tablicę symboli.
#
# Użycie:
#   python3 vosk_slownik_dump.py <katalog_modelu> [plik_wyjsciowy]
# np.
#   python3 vosk_slownik_dump.py vosk-model-small-pl-0.22 vosk_slownik_pl.txt
#
# Po co: gramatyka podawana do createRecognizer() może zawierać WYŁĄCZNIE słowa
# z tego zbioru. Słowo spoza słownika nie wywala gramatyki — libvosk wypisuje
# "Ignoring word missing in vocabulary: 'X'" i po cichu je pomija, więc komenda
# z takim słowem nigdy nie zostanie rozpoznana. Dlatego każde słowo gramatyki
# warto sprawdzić TU, a nie na telefonie.

import struct
import sys


def _dump(path):
    data = open(path, 'rb').read()
    pos = 0

    def i32():
        nonlocal pos
        v = struct.unpack_from('<i', data, pos)[0]
        pos += 4
        return v

    def i64():
        nonlocal pos
        v = struct.unpack_from('<q', data, pos)[0]
        pos += 8
        return v

    def text():
        nonlocal pos
        n = i32()
        v = data[pos:pos + n]
        pos += n
        return v.decode('utf8', 'replace')

    magic = i32()
    if magic != 2125659606:
        raise SystemExit('To nie jest plik FST (zły magic: %s)' % magic)
    text()  # typ FST, np. "ngram"
    text()  # typ łuku, np. "standard"
    i32()   # wersja
    flags = i32()
    i64()   # properties
    i64()   # stan startowy
    i64()   # liczba stanów
    i64()   # liczba łuków

    if not flags & 1:
        raise SystemExit('FST nie zawiera tablicy symboli wejściowych.')

    i32()   # magic tablicy symboli
    text()  # nazwa tablicy (ścieżka words.txt z czasu budowy modelu)
    i64()   # available_key
    size = i64()

    words = []
    for _ in range(size):
        words.append(text())
        i64()  # id symbolu
    return words


# Sortowanie po polsku bez zależności od locale: litera z ogonkiem ląduje
# tuż za swoim odpowiednikiem bez ogonka.
_ORDER = 'aąbcćdeęfghijklłmnńoópqrsśtuvwxyzźż'
_RANK = {c: i for i, c in enumerate(_ORDER)}


def _key(word):
    return [_RANK.get(c, 100 + ord(c)) for c in word.lower()]


if __name__ == '__main__':
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    model_dir = sys.argv[1].rstrip('/')
    out = sys.argv[2] if len(sys.argv) > 2 else 'vosk_slownik_pl.txt'

    syms = _dump(model_dir + '/graph/Gr.fst')
    # Pomijamy symbole techniczne: <eps>, <s>, </s>, #0, !SIL, [unk].
    words = [w for w in syms if not (w.startswith('<') or w.startswith('#')
                                     or w.startswith('!') or w.startswith('['))]
    words.sort(key=_key)
    with open(out, 'w', encoding='utf8') as f:
        f.write('\n'.join(words) + '\n')
    print('%d symboli w tablicy, %d słów zapisanych do %s'
          % (len(syms), len(words), out))
