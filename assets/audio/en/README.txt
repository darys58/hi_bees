ANGIELSKIE ODZYWKI MAI
======================
Stan na 05.09.2026: KOMPLET, dziewięć plików, nagrane tym samym łańcuchem
co polskie (24 kHz / 160 kb/s / mono, Lavf59.27.100 - ten sam serwis).
Wszystkie krótsze od polskich odpowiedników, najdłuższy 1,51 s.

JAK PODMIENIĆ ALBO DOŁOŻYĆ NAGRANIE
  1. wrzuć plik pod DOKŁADNIE tą samą nazwą co polski (lista niżej),
  2. nic więcej - katalog jest zgłoszony w pubspec.yaml w całości,
     kodu ani wpisu w pubspec NIE trzeba ruszać.
  Gdyby któregoś zabrakło, SoundHelper cofa się PLIK PO PLIKU do nagrania
  polskiego (patrz _ustawZrodloOdzywki w lib/helpers/sound_helper.dart) -
  ubytek jest słyszalny, ale nic nie milknie.

CO KTÓRY PLIK MÓWI I KIEDY GRA
  slucham.mp3             "I'm listening."        PRZED dyktowaniem notatki
                                                  (nie po „hey maya start"!)
  czekam_na_polecenia.mp3 "Ready for commands."   po „hey maya start"
  czekam.mp3              "Standing by."          po „hey maya stop"
  zapisalam.mp3           "Note saved."           po zapisie notatki
  zamkniete.mp3           "Closed."               zamknięcie okna/ekranu
  blad.mp3                "Error."                notatka nie powstała albo
                                                  nie dała się zapisać
  nie_rozumiem.mp3        "I don't understand."   notatka ZAPISANA, ale Vosk
                                                  nie wyciągnął z niej ani
                                                  jednego słowa (zostaje samo
                                                  nagranie do odsłuchania)
  nie_tutaj.mp3           "Not here."             polecenie ZROZUMIANE, ale
                                                  niewykonalne tu i teraz
                                                  (NAJCZĘSTSZA - trzymać krótko)
  okej.mp3                "Okay."                 dziś NIE GRA - zastąpiony
                                                  sygnałem systemowym; nagrać
                                                  na zapas (powrót to jedna
                                                  odkomentowana linia)

nie_tutaj.mp3 - PLIK NOWY, ROZDZIELENIE ZNACZEŃ
  Do 05.09.2026 jeden plik (nie_rozumiem.mp3) obsługiwał DWA różne znaczenia,
  przez co po nieudanej komendzie Maja mówiła „nie rozumiem", choć rozumiała
  doskonale - po prostu nie było gdzie zapisu wykonać. Rozdzielone:

    nie_tutaj    - 43 wywołania beep('error') w switchu pasiecznym plus
                   notatka do przeglądu bez wybranej pasieki/ula
                   (voice_vosk_screen :793, :6986). Nie zdekodowano slotu,
                   zła kolejność komend, brak ula, pusty stos cofania.
    nie_rozumiem - TYLKO notatka zapisana bez rozpoznanego tekstu
                   (voice_vosk_screen :1019, :1149). Tu „nie rozumiem" jest
                   prawdą, więc polskie nagranie zostaje bez zmian.

  Polecenie NIEROZPOZNANE nie gra NICZEGO - bramka odrzuca je po cichu
  (vosk_engine.dart:1508), bo przy nasłuchu ciągłym mikrofon łapie rozmowę
  przy ulu i sygnał po każdym zdaniu byłby nie do zniesienia.

  OBA PLIKI SĄ NAGRANE (05.09.2026):
    assets/audio/nie_tutaj.mp3      "Nie tutaj"   0,96 s
    assets/audio/en/nie_tutaj.mp3   "Not here."   0,89 s
  Polski jest wpisany do pubspec.yaml osobną linią (tuż pod nie_rozumiem.mp3),
  angielski wchodzi przez zgłoszony katalog. Zapas w SoundHelper._plikZapasowy
  ('nie_tutaj' -> nie_rozumiem.mp3) zostaje jako siatka bezpieczeństwa.

WYMAGANIA
  * długość do ~1,8 s. Na czas odzywki mikrofon jest WYCISZANY, więc każda
    dziesiąta sekundy to czas, w którym Maja nie słyszy. Polskie mieszczą się
    w 1,0-1,75 s. „okej" wyleciał z użycia właśnie za długość.
  * format jak polskie: mp3, 24000 Hz, mono, ok. 160 kb/s. Nie dlatego, że
    audioplayers wymaga, tylko żeby głośności z SoundHelper.volumes zostały
    takie same.
  * ten sam głos we wszystkich plikach danego języka.

ZOSTAŁO DO ZROBIENIA - ZMIERZYĆ NA TELEFONIE
  Echo odzywki wpada do treści dyktowanej notatki (bufor wejściowy iOS oddaje
  dźwięk z opóźnieniem większym niż wyciszenie mikrofonu). Dla polskiego wycina
  je wzorzec echoOdzywki w _echaPl (lib/helpers/vosk_engine.dart); dla
  angielskiego jest tam null, bo nie wiadomo, JAK angielski model Vosk
  przepisze nagranie. Trzeba to ZMIERZYĆ na telefonie przy włączonej
  diagnostyce (globals.voiceDiagnostyka), a nie zgadywać - zły wzorzec ucina
  prawdziwą treść notatki. Dotyczy WYŁĄCZNIE slucham.mp3 - reszta odzywek gra
  poza dyktowaniem.
