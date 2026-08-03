#!/usr/bin/env python3
# Test END-TO-END całego łańcucha, bez telefonu:
#   assets/grammar/pol_vosk.yml -> silnik generuje gramatykę frazową
#   -> Vosk rozpoznaje nagranie WAV tą gramatyką
#   -> silnik parsuje rozpoznany tekst na {intent, slots}
#
# Dzięki temu wiadomo, czy gramatyka wyprodukowana przez silnik naprawdę działa
# na realnym nagraniu z iPhone'a, a nie tylko na tekście wpisanym z klawiatury.
#
# Wymaga: pip install vosk  +  model w $VOSK_MODEL (domyślnie
#         /tmp/plm/vosk-model-small-pl-0.22).
#
# Użycie: python3 vosk_e2e_test.py nagranie.wav [...]

import json
import os
import sys
import wave

import vosk_parser_ref as ref
import vosk_gramatyka_test as gt

MODEL = os.environ.get('VOSK_MODEL', '/tmp/plm/vosk-model-small-pl-0.22')


def sprawdz_oov(frazy):
    """Każde słowo gramatyki musi być w słowniku modelu - inaczej Vosk pominie
    je po cichu (`Ignoring word missing in vocabulary`) i komenda nigdy nie
    zadziała."""
    vocab = gt.slownik()
    braki = sorted({w for f in frazy for w in f.split() if w not in vocab})
    print('Fraz w gramatyce: %d, słów unikalnych: %d, BRAK w słowniku: %d'
          % (len(frazy), len({w for f in frazy for w in f.split()}), len(braki)))
    for w in braki:
        print('  OOV: %s' % w)
    return braki


def rozpoznaj(path, frazy):
    from vosk import Model, KaldiRecognizer, SetLogLevel
    SetLogLevel(-1)
    wf = wave.open(path, 'rb')
    if wf.getnchannels() != 1 or wf.getsampwidth() != 2:
        raise SystemExit('Potrzebny WAV mono 16-bit')
    rate = wf.getframerate()
    rec = KaldiRecognizer(Model(MODEL), rate,
                          json.dumps(frazy + ['[unk]'], ensure_ascii=False))
    rec.SetWords(True)
    wyniki = []
    porcja = int(rate * 0.2)          # 0,2 s - tak jak POC na iPhonie
    while True:
        data = wf.readframes(porcja)
        if not data:
            break
        if rec.AcceptWaveform(data):
            r = json.loads(rec.Result())
            if r.get('text'):
                wyniki.append(r)
    r = json.loads(rec.FinalResult())
    if r.get('text'):
        wyniki.append(r)
    return wyniki


def main(pliki_wav):
    silnik = ref.SilnikGramatyki()
    frazy = silnik.frazy()
    if sprawdz_oov(frazy):
        print('!! gramatyka ma OOV - Vosk pominie te słowa')
    print()
    for path in pliki_wav:
        print('=== %s' % os.path.basename(path))
        ok = nie = 0
        for r in rozpoznaj(path, frazy):
            tekst = r['text']
            confs = [w['conf'] for w in r.get('result', [])]
            w = silnik.rozpoznaj(tekst)
            if w is None:
                nie += 1
                print('  %-46s minconf=%.2f  -> NIE ROZUMIEM' %
                      (tekst, min(confs) if confs else -1))
            else:
                ok += 1
                print('  %-46s minconf=%.2f  -> %-11s %s' %
                      (tekst, min(confs) if confs else -1, w.intent, w.sloty))
        print('  --- %d rozpoznanych komend, %d nierozpoznanych fraz' % (ok, nie))
        print()


if __name__ == '__main__':
    if len(sys.argv) < 2:
        raise SystemExit('podaj plik(i) WAV')
    main(sys.argv[1:])
