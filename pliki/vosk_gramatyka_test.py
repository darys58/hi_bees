#!/usr/bin/env python3
# Offline testownia gramatyki Vosk — do uruchamiania w kontenerze (nie na telefonie).
#
# Dwie rzeczy naraz:
#   1. --oov      sprawdza, czy każde słowo literalne z pol_vosk.yml jest w
#                 słowniku modelu (vosk_slownik_pl.txt). Słowa spoza słownika
#                 Vosk po cichu POMIJA przy budowaniu gramatyki.
#   2. --rec      puszcza nagranie WAV (16 kHz mono) przez model — w trybie
#                 wolnym (cały słownik) albo z gramatyką pasieczną, z opcjonalnymi
#                 dodatkowymi frazami. Tryb wolny odpowiada na pytanie
#                 „co model NAPRAWDĘ słyszy" i tak wybraliśmy alias dla „nakrop".
#
# Wymaga: pip install vosk pyyaml   +   rozpakowanego modelu vosk-model-small-pl-0.22
#         (domyślnie /tmp/plm/vosk-model-small-pl-0.22, patrz MODEL poniżej).
#
# Przykłady:
#   python3 vosk_gramatyka_test.py --oov
#   python3 vosk_gramatyka_test.py --rec nagranie.wav                  # tryb wolny
#   python3 vosk_gramatyka_test.py --rec nagranie.wav --gram
#   python3 vosk_gramatyka_test.py --rec nagranie.wav --gram --fraza "na grób"

import argparse
import collections
import json
import os
import re
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
# Gramatyka jest assetem aplikacji (pubspec), nie kopią w pliki/ - jedno źródło.
YML = os.path.join(os.path.dirname(HERE), 'assets', 'grammar', 'pol_vosk.yml')
DICT = os.path.join(HERE, 'vosk_slownik_pl.txt')
MODEL = os.environ.get('VOSK_MODEL', '/tmp/plm/vosk-model-small-pl-0.22')

# Liczebniki — w Rhino były typami wbudowanymi ($pv.Percent, $pv.TwoDigitInteger),
# Vosk musi mieć je w gramatyce wypisane słowo po słowie.
NUMBERS = """zero jeden jedna jedną jednego dwa dwie dwóch trzy cztery pięć sześć siedem osiem
dziewięć dziesięć jedenaście dwanaście trzynaście czternaście piętnaście szesnaście siedemnaście
osiemnaście dziewiętnaście dwadzieścia trzydzieści czterdzieści pięćdziesiąt sześćdziesiąt
siedemdziesiąt osiemdziesiąt dziewięćdziesiąt sto dwieście trzysta czterysta pięćset sześćset
siedemset osiemset dziewięćset procent procenta procentów pierwszy drugi trzeci czwarty piąty
szósty siódmy ósmy dziewiąty""".split()

TOKEN = re.compile(r'\$[A-Za-z0-9_.]+:[A-Za-z0-9_]+')


def wczytaj_pozycje(path=YML):
    """Zwraca listę (sekcja, nazwa, tekst) — własny, tolerancyjny parser.

    Świadomie NIE używamy pyyaml: linie zaczynające się od "[" bez cudzysłowu
    nie są poprawnym YAML-em (Rhino takie linie cytował).
    """
    items, section, name, cur = [], None, None, None

    def flush():
        nonlocal cur
        if cur is not None:
            items.append((section, name, cur.strip()))
            cur = None

    for raw in open(path, encoding='utf-8'):
        line = raw.rstrip('\n')
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        ind = len(line) - len(line.lstrip())
        s = line.strip()
        if s == 'context:':
            continue
        if s in ('expressions:', 'slots:'):
            flush(); section = s[:-1]; name = None; continue
        if s.startswith('macros:'):
            flush(); section = None; continue
        if s.startswith('- '):
            flush(); cur = s[2:]; continue
        if s.endswith(':') and ind <= 4:
            flush(); name = s[:-1]; continue
        if cur is not None:            # kontynuacja zawinietej pozycji
            cur += ' ' + s
    flush()
    return items


def slowa_gramatyki(path=YML):
    """Słowo -> zbiór wyrażeń/slotów, w których występuje."""
    where = collections.defaultdict(set)
    for section, name, text in wczytaj_pozycje(path):
        t = TOKEN.sub(' ', text.strip('"\''))
        t = re.sub(r'[\[\]\(\),]', ' ', t)
        origin = ('slot:' if section == 'slots' else '') + str(name)
        for w in t.split():
            if not w.startswith('$'):
                where[w].add(origin)
    return where


def slownik():
    return set(l.strip() for l in open(DICT, encoding='utf-8') if l.strip())


def sprawdz_oov():
    vocab = slownik()
    where = slowa_gramatyki()
    brak = sorted(w for w in where if w not in vocab)
    print('Słów literalnych w gramatyce: %d' % len(where))
    print('BRAK w słowniku modelu: %d' % len(brak))
    for w in brak:
        print('  %-16s <- %s' % (w, ', '.join(sorted(where[w]))))
    nmiss = [w for w in NUMBERS if w not in vocab]
    print('Liczebniki spoza słownika: %s' % (nmiss or 'żadnych'))
    return brak


def gramatyka(frazy=(), bez=()):
    """Lista pozycji gramatyki: słowa z .yml (tylko te ze słownika) + frazy + [unk]."""
    vocab = slownik()
    ws = set(slowa_gramatyki()) | set(NUMBERS)
    ws = {w for w in ws if w in vocab} - set(bez)
    return sorted(ws) + list(frazy) + ['[unk]']


def rozpoznaj(path, grammar=None, label=''):
    from vosk import Model, KaldiRecognizer, SetLogLevel
    SetLogLevel(-1)
    wf = wave.open(path, 'rb')
    if wf.getnchannels() != 1 or wf.getsampwidth() != 2:
        raise SystemExit('Potrzebny WAV mono 16-bit (jest %d kan., %d B)'
                         % (wf.getnchannels(), wf.getsampwidth()))
    rate = wf.getframerate()
    model = Model(MODEL)
    rec = (KaldiRecognizer(model, rate) if grammar is None
           else KaldiRecognizer(model, rate, json.dumps(grammar, ensure_ascii=False)))
    rec.SetWords(True)
    wyniki = []
    ramek = int(rate * 0.2)          # porcje 0,2 s — tak jak POC na iPhonie
    while True:
        data = wf.readframes(ramek)
        if not data:
            break
        if rec.AcceptWaveform(data):
            r = json.loads(rec.Result())
            if r.get('text'):
                wyniki.append(r)
    r = json.loads(rec.FinalResult())
    if r.get('text'):
        wyniki.append(r)
    print('=== %s | %s' % (label, os.path.basename(path)))
    for r in wyniki:
        confs = [w['conf'] for w in r.get('result', [])]
        t0 = r['result'][0]['start'] if r.get('result') else 0.0
        print('  [%6.2fs] %-60s minconf=%.2f' % (t0, r['text'], min(confs) if confs else -1))
    return wyniki


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--oov', action='store_true', help='sprawdź gramatykę względem słownika')
    ap.add_argument('--rec', metavar='WAV', help='rozpoznaj nagranie')
    ap.add_argument('--gram', action='store_true', help='użyj gramatyki pasieki (domyślnie tryb wolny)')
    ap.add_argument('--fraza', action='append', default=[], help='dodatkowa fraza do gramatyki (można wielokrotnie)')
    ap.add_argument('--bez', action='append', default=[], help='słowo do wycięcia z gramatyki')
    a = ap.parse_args()
    if a.oov or not a.rec:
        sprawdz_oov()
    if a.rec:
        g = gramatyka(a.fraza, a.bez) if a.gram else None
        etykieta = ('gramatyka %d poz.' % len(g)) if g else 'tryb wolny (244k słów)'
        if a.fraza:
            etykieta += ' + ' + ', '.join('„%s"' % f for f in a.fraza)
        rozpoznaj(a.rec, g, etykieta)
