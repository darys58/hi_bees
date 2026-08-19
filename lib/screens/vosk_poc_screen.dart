// POC Faza 0 — test rozpoznawania mowy Vosk po polsku pod komendy pasieczne.
// Ekran w pełni samodzielny, NIE dotyka voice_screen2.dart ani logiki Picovoice.
// Do usunięcia, jeśli rezygnujemy z migracji na Vosk.
//
// ---------------------------------------------------------------------------
// CO JUŻ WIADOMO (skrót zamkniętej diagnostyki, 26–29.07.2026)
// ---------------------------------------------------------------------------
// 1. Pakiet: `vosk_flutter_service`, ZWENDOROWANY do `packages/` — rozjazd
//    z upstreamem opisany w packages/vosk_flutter_service/HI_BEES_PATCH.md.
// 2. NIE używamy jego initSpeechService(): natywny mikrofon tej wtyczki na iOS
//    instaluje tap w formacie sprzętowym (48 kHz float ±1.0) i podaje próbki
//    wprost do vosk_recognizer_accept_waveform_f, który oczekuje skali int16.
//    Audio zbieramy sami pakietem `record` i karmimy acceptWaveformBytes().
// 3. Ścieżkę modelu podajemy JAWNIE (ModelLoader(modelStorage: ...)). Domyślna
//    ma fallback na relatywny katalog 'models', a na iOS katalog procesu jest
//    read-only → FileSystemException errno 30. Model trzymamy w Application
//    Support (50 MB nie ma po co lądować w backupie iCloud).
// 4. PRZYCZYNA „cyfrowej ciszy" (74 % zer w nagraniu, mowa poszatkowana na
//    23-ms wysepki co 171 ms) była we wtyczce, nie w mikrofonie i nie w
//    `record`: configureAudioSession() wołane przy KAŻDYM recognizer.* robiło
//    setCategory + setActive(true), czyli 5 razy na sekundę przestawiało
//    aktywną sesję audio w trakcie nagrywania; do tego całe dekodowanie szło
//    na głównym wątku iOS. Po poprawkach we wtyczce (sesja nietykana, własna
//    kolejka szeregowa voskQueue, NSLog wycięty z gorącej ścieżki) test na
//    iPhonie dał 0,38–0,46 % ciszy cyfrowej, ZERO dziur i tekst na żywo,
//    przy koszcie 14 ms na porcję 0,2 s = 7 % czasu rzeczywistego.
// 5. Gramatyka: model vosk-model-small-pl-0.22 jest typu LGRAPH, więc
//    createRecognizer(grammar:) działa. 250 słów (209 z `assets/grammar/pol_vosk.yml`
//    + 41 liczebników) sprawdzono względem słownika modelu — zero OOV.
//
// ---------------------------------------------------------------------------
// TO WYDANIE (v13, 01.08.2026) — trzy rzeczy do sprawdzenia w terenie
// ---------------------------------------------------------------------------
// A. TRYB KOMEND WŁĄCZONY DOMYŚLNIE. Zamiast 244 tys. słów modelu recognizer
//    dostaje 250 słów gramatyki pasieki + [unk]. To docelowe rozwiązanie:
//    powinno podnieść trafność żargonu (czerw, susz, korpus, liczebniki),
//    wyciąć przypadkowe frazy z wiatru i jeszcze zbić koszt dekodowania.
//    Przełącznik zostaje, żeby dało się porównać oba tryby na tym samym
//    nagraniu (przycisk „rozpoznaj ponownie" przy każdym nagraniu).
// B. NASŁUCH CIĄGŁY, BEZ PRZYCISKU STARTU. Ekran sam ładuje model i zaczyna
//    słuchać; jest tylko pauza (potrzebna do odsłuchu nagrań). Zmiana
//    ustawienia sama przerywa i wznawia nasłuch.
//    ŹRÓDŁO AUDIO jest przełącznikiem: STRUMIEŃ (record.startStream —
//    podejrzany w trakcie diagnostyki, ale prawdziwym winnym okazała się
//    wtyczka, więc wraca do sprawdzenia; nie wymaga plików) albo PLIK
//    (AVAudioRecorder + odczyt rosnącego pliku co 200 ms — droga sprawdzona,
//    ale przy ciągłym nasłuchu wymaga rotacji pliku, 32 kB/s).
//    Nagranie kontrolne przy źródle STRUMIEŃ to bufor pierścieniowy z OSTATNIĄ
//    minutą — przy nasłuchu bez końca zapisywanie od początku nie ma sensu.
// C. WYŁUSKIWANIE KOMEND BEZ WAKE-WORDA. Przy zawężonej gramatyce Vosk
//    dopasowuje KAŻDY dźwięk do słów komend albo do [unk], więc zwykła rozmowa
//    w pasiece też coś zwróci. Bramka ocenia każdą domkniętą frazę trzema
//    kryteriami i pokazuje werdykt z powodem:
//      1) brak [unk] — cokolwiek spoza gramatyki dyskwalifikuje frazę,
//      2) pewność rozpoznania każdego słowa (setWords → conf) powyżej progu,
//      3) fraza zaczyna się od słowa, które MOŻE otwierać komendę (zbiór
//         pierwszych słów wszystkich wyrażeń z `assets/grammar/pol_vosk.yml`).
//    To jeszcze NIE jest parser gramatyki — pełna walidacja („czy fraza pasuje
//    do jakiegoś wyrażenia od początku do końca") to dopiero silnik czytający
//    .yml. Tu chodzi o zmierzenie, ile fałszywych trafień przechodzi bramkę
//    w realnej rozmowie: to jest odpowiedź na pytanie, czy da się zapisywać
//    dane bez „Hej Maja".
// D. ALIAS „NAKROP" = fraza „na grób" (rozstrzygnięte 01.08.2026, domyślnie WŁĄCZONY).
//    W Rhino „nakrop 20 procent" działało, choć tego słowa nie ma w gramatyce —
//    silnik dopasowywał je siłowo do „pokarm $Percent:food". Vosk tak nie umie,
//    a „nakrop" nie występuje w słowniku modelu w żadnej formie. Alias wybrany
//    pomiarem na nagraniach usera, nie zgadywaniem → komentarz przy _nakropTokeny.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vosk_flutter_service/vosk_flutter_service.dart';

// Tryb obróbki sygnału przez iOS. Z lektury źródeł record_ios wynika, że:
//  - noiseSuppress na iOS jest IGNOROWANE (liczy się tylko na Androidzie),
//  - echoCancel włącza voice processing AVAudioEngine,
//  - automatyczna regulacja wzmocnienia (AGC) siedzi pod osobną flagą autoGain
//    i przy samym echoCancel jest WYŁĄCZANA (isVoiceProcessingAGCEnabled=false).
enum MicMode { surowy, voiceProcessing, voiceProcessingAgc }

// Skąd bierzemy audio. Dwie zupełnie różne drogi w iOS, ten sam mikrofon.
enum Zrodlo {
  // AVAudioEngine + tap + AVAudioConverter. Nie tworzy plików, naturalna
  // ścieżka dla nasłuchu bez końca.
  strumien,
  // AVAudioRecorder pisze WAV, my co 200 ms czytamy przyrost. Sprawdzona
  // w diagnostyce, ale przy ciągłym nasłuchu potrzebuje rotacji pliku.
  plik,
}

// Słownik komend wyciągnięty z `assets/grammar/pol_vosk.yml` (sekcje expressions i slots,
// bez znaczników składni Rhino). To NOWA, poprawiona gramatyka — nie stary
// `assets/rhino/pol1 (4).yml`, który jeszcze obsługuje Picovoice.
//
// LISTA JEST GENEROWANA, NIE PISANA RĘCZNIE. Po każdej zmianie .yml odtwórz ją
// (i _anchorWords niżej) skryptem — inaczej POC testuje inną gramatykę niż ta,
// którą właśnie poprawiłeś:
//   python3 pliki/vosk_gramatyka_test.py --oov      ← musi dać „BRAK: 0"
// Docelowo parser przeczyta .yml jako asset i te trzy listy znikną.
//
// Stan na 01.08.2026: 209 słów literalnych, ZERO spoza słownika modelu.
// Zamienniki słów, których w słowniku nie ma, siedzą już w samym .yml
// (`trud` za `trut` — homofon przez ubezdźwięcznienie wygłosowe; `wosk` obok
// `węża`; `pyłek` obok `pierzcha`; `mili gram`/`miligramów` za `miligram`;
// `miodu branie` za `miodobranie`; `pół korpus` za `półkorpus`).
// „grób" świadomie NIE MA na tej liście — wchodzi wyłącznie jako fraza
// _nakropFraza, żeby nie stało się samodzielnym celem dla szumu.
final List<String> _commandWords = [
  'agresywna', 'aktualna', 'aktualną', 'bardzo', 'biała', 'biały', 'brak',
  'branie', 'brudna', 'chemia', 'ciasto', 'czarna', 'czerw', 'czerwona',
  'czerwony', 'czterysta', 'czysta', 'data', 'datę', 'dawka', 'do', 'dobra',
  'dojrzały', 'dokarmianie', 'duża', 'dużych', 'dużą', 'dwieście', 'dwóch',
  'dziewicza', 'dziewięćset', 'dzień', 'gram', 'grama', 'gramy', 'i',
  'ilość', 'inna', 'inny', 'izolacja', 'izolować', 'jaja', 'jajka', 'jeden',
  'jednego', 'jest', 'kilo', 'kilogram', 'kilograma', 'kilogramy',
  'kilogramów', 'klatce', 'korpus', 'korpusie', 'korpusu', 'krata', 'kratę',
  'kropka', 'kryty', 'królowa', 'królowej', 'kwas', 'kłąb', 'larwy',
  'leczenie', 'lewa', 'lewej', 'lewo', 'lewą', 'liczba', 'liczbę', 'litr',
  'litra', 'litry', 'litrów', 'lokacja', 'ma', 'martwe', 'martwych',
  'matecznik', 'matka', 'matki', 'mała', 'małych', 'małą', 'mi', 'miarka',
  'miesiąc', 'mili', 'miligramów', 'mililitrów', 'miodu', 'miód', 'można',
  'na', 'nastroju', 'naturalna', 'nie', 'niebieska', 'niebieski',
  'normalna', 'numer', 'obie', 'obu', 'od', 'ok', 'okej', 'osiemset',
  'otwórz', 'pasiekę', 'paski', 'pierzcha', 'pięćset', 'po', 'podłoga',
  'pokarm', 'pokarmu', 'pomoc', 'pomóż', 'porcja', 'pracy', 'prawa',
  'prawej', 'prawo', 'prawą', 'przecinek', 'przed', 'przegląd',
  'przeglądzie', 'przenieś', 'przesuń', 'pszczoły', 'pszczół', 'pyłek',
  'pyłku', 'pół', 'później', 'ramek', 'ramka', 'ramki', 'ramkę', 'raz',
  'razy', 'rocznik', 'rodzina', 'rok', 'roku', 'roztocza', 'siedemset',
  'silna', 'stara', 'sto', 'stron', 'strona', 'stronie', 'strony', 'stronę',
  'susz', 'syrop', 'sześćset', 'sztuczna', 'sztuk', 'sztuka', 'sztuki',
  'słaba', 'trud', 'trzeba', 'trzy', 'trzysta', 'ucieczki', 'ul', 'ula',
  'ule', 'ustaw', 'usunąć', 'usuń', 'w', 'wcześniej', 'wirować', 'wolna',
  'wosk', 'wstaw', 'wszystkie', 'wyczyszczona', 'wymiany', 'wyposażenie',
  'wytnij', 'wyłącz', 'węża', 'z', 'zabierz', 'zamknij', 'zamknięta',
  //'załóż' usunięte razem z wartością ze slotu $state (06.08.2026).
  //'zabierz' ZOSTAJE - jest jeszcze w slocie `deleted` ("zabierz kratę").
  'zawiązała', 'załącz', 'zbieracz', 'zbiory', 'zbiór', 'zielona',
  'zielony', 'znak', 'znaku', 'zostało', 'zła', 'ów', 'łagodna', 'żyje',
  'żółta', 'żółty',
];

// Liczebniki — Rhino miał je jako typy wbudowane ($pv.Percent,
// $pv.TwoDigitInteger...), Vosk musi mieć te słowa w gramatyce wypisane.
// Tu tylko te, których NIE ma już w _commandWords (setki, „jeden", „trzy"
// i „dwóch" padają w .yml dosłownie, np. „syrop trzy do dwóch").
final List<String> _numberWords = [
  'czterdzieści', 'czternaście', 'cztery', 'czwarty', 'drugi', 'dwa',
  'dwadzieścia', 'dwanaście', 'dwie', 'dziesięć', 'dziewiąty',
  'dziewiętnaście', 'dziewięć', 'dziewięćdziesiąt', 'jedenaście', 'jedna',
  'jedną', 'osiem', 'osiemdziesiąt', 'osiemnaście', 'pierwszy', 'piąty',
  'piętnaście', 'pięć', 'pięćdziesiąt', 'procent', 'procenta', 'procentów',
  'siedem', 'siedemdziesiąt', 'siedemnaście', 'siódmy', 'szesnaście',
  'sześć', 'sześćdziesiąt', 'szósty', 'trzeci', 'trzydzieści', 'trzynaście',
  'zero', 'ósmy',
];

// ALIAS „nakrop" mimo braku tego słowa w słowniku modelu.
//
// W Rhino „nakrop 20 procent" działało przypadkiem — silnik dopasowywał je
// siłowo do najbliższej ścieżki gramatyki, czyli do „pokarm $Percent:food",
// i zwracał kanoniczne „pokarm". Vosk tak nie umie: gramatyka może zawierać
// wyłącznie słowa ze słownika modelu, a „nakrop" (ani żadna forma „nakrop*")
// w vosk_slownik_pl.txt nie występuje — 0 trafień na 244 431 słów. Wpisane
// wprost zostałoby po cichu pominięte („Ignoring word missing in vocabulary").
//
// ROZSTRZYGNIĘTE POMIAREM (01.08.2026, `pliki/vosk_gramatyka_test.py` na dwóch
// nagraniach usera, 17 wypowiedzi „nakrop X procent"). Zamiast zgadywać
// transkrypcję fonetyczną, puszczono nagrania w trybie WOLNYM (pełne 244 tys.
// słów) i odczytano, co model naprawdę słyszy: „na grób" 13×, „na krok" 3×,
// „nagrobki" 1×. Porównanie wariantów gramatyki:
//   bez aliasu        →  0/17 („na kropka", „na kłąb", „znak rok")
//   „na kro p"+„na kro" → 17/17, ale rozjazd na dwie formy, conf 0,58–1,00
//   „na grób"         → 17/17, conf 1,00      ← wybrane
//   „na krok"         → 17/17, conf 1,00
//   obie naraz        → 17/17, ale conf spada do 0,54 (konkurują ze sobą)
// „na krok" odrzucone mimo równie dobrego wyniku: „krok" pada w zwykłej mowie
// („ani na krok", „krok po kroku"), więc niesie większe ryzyko fałszywego
// trafienia niż „grób", którego w pasiece nikt nie wypowie.
//
// Dlaczego stary pomysł „na kro p" był gorszy: samotne „p" model ma w leksykonie
// najpewniej jako nazwę litery (/p e/), więc końcówka łapała się tylko w części
// przypadków — reszta kończyła się na „na kro". Do tego „kro" i „p" jako osobne
// pozycje gramatyki stawały się celami dla szumu („na kropka" → „na kro").
//
// Podawane jako JEDNA fraza, nie dwa luźne słowa: „grób" ma być osiągalny tylko
// w tej sekwencji. Alias zapisuje ten sam zasób co „pokarm" i „miód"
// (voice_screen2.dart, sloty food/honey → zapisZas = 6).
const List<String> _nakropTokeny = ['na', 'grób'];
final String _nakropFraza = _nakropTokeny.join(' ');

// Słowa, od których MOŻE zaczynać się komenda — zebrane z pierwszych pozycji
// wszystkich wyrażeń `assets/grammar/pol_vosk.yml`, z rozwinięciem slotów, grup
// opcjonalnych (nawiasy) i alternatyw. Przykład: „($state)($sizeOfFrame) ramkę
// ..." otwiera się na $state, na $sizeOfFrame ALBO na słowo „ramkę".
// To najsłabsze z trzech kryteriów bramki (ok. 1/3 słownika), ale wycina
// urwane fragmenty typu „...stronie procent" — a przy okazji pokazuje, jak
// bardzo gramatyka Rhino pozwala zaczynać komendę „od środka".
// GENEROWANE razem z _commandWords — patrz komentarz tam.
// „na" świadomie POMINIĘTE mimo aliasu „na grób": zbyt pospolity przyimek,
// żeby otwierał komendę. Bramka wpuszcza alias po dokładnym prefiksie.
final Set<String> _anchorWords = {
  // $state (setApiary/Hive/Body/Frame/HalfBody/AllHives/HivesRange/Frames/Equipment)
  //bez 'załóż' - usunięte ze slotu $state 06.08.2026 jako nieużywane.
  //'zabierz' zostaje: otwiera komendę "zabierz kratę" ze slotu `deleted`.
  'wstaw', 'zabierz', 'usuń', 'załącz', 'wyłącz', 'otwórz', 'zamknij',
  'ustaw',
  // $sizeOfFrame + „ramka/ramki/ramkę" (setFrame, setFrames, setChange)
  'mała', 'duża', 'małą', 'dużą', 'ramka', 'ramki', 'ramkę',
  // setStore
  'pokarm', 'larwy', 'miód', 'dojrzały', 'jaja', 'jajka', 'czerw', 'kryty',
  'susz', 'wytnij', 'przesuń', 'izolacja', 'można', 'trzeba', 'wosk', 'węża',
  'pyłek', 'pierzcha', 'trud',
  // $siteOfFrame (wyrażenie „(ustaw) (z) $siteOfFrame [stron,...]")
  'z', 'obu', 'obie', 'prawa', 'prawą', 'prawej', 'lewa', 'lewą', 'lewej',
  // $queen (kolory matki otwierają wyrażenie o matce na ramce)
  'biała', 'niebieska', 'zielona', 'czerwona', 'żółta', 'czarna', 'inna',
  // setFeeding / setTreatment
  'zostało', 'syrop', 'ciasto', 'kwas', 'roztocza', 'chemia',
  // setEquipment
  'krata', 'podłoga', 'ilość', 'liczba', 'liczbę',
  // setQueen
  'królowa', 'królowej', 'matka', 'matki',
  // setHelp ($helpMe: „ul", „zbiory", „rodzina", „data"...)
  'pomóż', 'ul', 'lokacja', 'zbiór', 'zbiory', 'rodzina', 'data', 'leczenie',
  'dokarmianie', 'wyposażenie', 'przegląd',
  // setHarvest („zbiór miodu" / „miodu branie")
  'miodu',
  // setColony („martwe pszczoły" / „martwych pszczół") / setMoveBody
  'martwe', 'martwych', 'przenieś',
  // liczebniki — „$pv.SingleDigitInteger matecznik ..." zaczyna się od liczby
  'zero', 'jeden', 'jedna', 'jedną', 'dwa', 'dwie', 'trzy', 'cztery', 'pięć',
  'sześć', 'siedem', 'osiem', 'dziewięć',
};

// Ocena jednej domkniętej frazy przez bramkę komend.
class _Fraza {
  _Fraza({
    required this.tekst,
    required this.unk,
    required this.minConf,
    required this.przyjeta,
    required this.powod,
    required this.oCzasie,
  });

  final String tekst;
  final int unk; // ile słów spoza gramatyki
  final double minConf; // najsłabiej rozpoznane słowo (−1 = brak danych)
  final bool przyjeta;
  final String powod;
  final DateTime oCzasie;
}

// Zawartość pliku WAV potrzebna do analizy: format + surowe PCM.
class _Wav {
  const _Wav({required this.rate, required this.channels, required this.pcm});
  final int rate;
  final int channels;
  final Uint8List pcm;
}

class VoskPocScreen extends StatefulWidget {
  static const routeName = '/vosk-poc';
  const VoskPocScreen({super.key});

  @override
  State<VoskPocScreen> createState() => _VoskPocScreenState();
}

class _VoskPocScreenState extends State<VoskPocScreen> {
  // Mały model polski (~50 MB). Pobierany raz z sieci i cache'owany lokalnie
  // przez ModelLoader — nie pakujemy go do repo/gita.
  static const String _modelUrl =
      'https://alphacephei.com/vosk/models/vosk-model-small-pl-0.22.zip';

  // Częstotliwość próbkowania. 16 kHz to standard modeli Vosk; 48 kHz to
  // częstotliwość sprzętowa iPhone'a (record nie przepróbkowuje).
  int _rate = 16000;
  // Porcja podawana do recognizera = 0,2 s (2 bajty na próbkę).
  int get _chunkBytes => (_rate ~/ 5) * 2;
  // Ile ostatniego dźwięku trzymamy w buforze pierścieniowym: 60 s.
  int get _wavLimit => 60 * _rate * 2;
  // Rozmiar bufora tapu AVAudioEngine (null = domyślny pakietu, 1024).
  int? _bufSize;
  // Co ile sekund rotujemy plik przy źródle PLIK. Przy 16 kHz to ~1,9 MB.
  static const int _rotateSec = 60;

  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  Model? _model;
  Recognizer? _recognizer;
  StreamSubscription<Uint8List>? _audioSub;
  Timer? _meterTimer; // odświeżanie panelu diagnostycznego
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<void>? _endSub;

  // Bufor surowego PCM — porcje z mikrofonu bywają mniejsze/większe niż porcja,
  // którą chcemy podać do Vosk, więc sklejamy je tutaj.
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  bool _feeding = false; // blokada: jedno wywołanie kanału naraz

  // Nagranie kontrolne przy źródle STRUMIEŃ: bufor PIERŚCIENIOWY z ostatnią
  // minutą tego, co poszło do Vosk. Przy nasłuchu bez końca zapisywanie od
  // początku byłoby bezużyteczne — interesuje nas to, co przed chwilą.
  final ListQueue<Uint8List> _wavRing = ListQueue<Uint8List>();
  int _wavRingBytes = 0;

  // Odsłuch: lista zapisanych nagrań (najnowsze na górze) i stan odtwarzacza.
  List<File> _recordings = [];
  String? _playingPath; // null = nic nie gra
  Duration _playPos = Duration.zero;
  Duration _playDur = Duration.zero;

  String _status = 'Ładuję model polski...';
  String _modelPath = '';
  String _partial = ''; // tekst „w locie", podczas mówienia
  String _finalText = ''; // ostatni domknięty wynik
  bool _busy = false;
  bool _modelReady = false;

  // Nasłuch ciągły: startuje sam po załadowaniu modelu, zatrzymuje go tylko
  // pauza (albo odsłuch nagrania / zmiana ustawienia).
  bool _running = false;
  bool _paused = false;
  Zrodlo _zrodlo = Zrodlo.strumien;

  // Obróbka sygnału przez iOS — patrz komentarz przy MicMode.
  MicMode _mic = MicMode.surowy;
  // Programowe wzmocnienie próbek przed podaniem do Vosk (1 = brak).
  int _gain = 1;
  // Zawężony słownik komend zamiast 244 tys. słów. DOMYŚLNIE WŁĄCZONY —
  // to jest testowane rozwiązanie docelowe.
  bool _useGrammar = true;
  // Alias „nakrop" jako fraza „na grób" — patrz komentarz przy _nakropTokeny.
  // DOMYŚLNIE WŁĄCZONY: wariant wybrany pomiarem (17/17 przy pewności 1,00).
  // Przełącznik zostaje, żeby dało się zmierzyć jego wpływ na liczbę fałszywych
  // trafień w realnej rozmowie (przebieg ON vs OFF na tej samej gadaninie).
  bool _nakropTest = true;
  // Ile razy fraza „na grób" faktycznie padła (niezależnie od werdyktu
  // bramki) — bez tego nie da się odróżnić „nie działa" od „działa, ale
  // bramka to odrzuca".
  int _nakropTrafien = 0;
  // Zapisywanie nagrań kontrolnych. Przy nasłuchu ciągłym domyślnie wyłączone,
  // żeby nie zasypać dysku (32 kB/s = ~115 MB na godzinę).
  bool _keepRec = false;
  // Wybrane wejście audio (null = domyślne systemowe).
  List<InputDevice> _devices = [];
  InputDevice? _device;

  // ---- bramka komend ------------------------------------------------------
  bool _gateOn = true;
  // Próg pewności rozpoznania najsłabszego słowa we frazie. 0 = kryterium
  // wyłączone (przy gramatyce Vosk często zwraca conf = 1,0, więc trzeba
  // zmierzyć w terenie, czy ta liczba w ogóle różnicuje).
  double _confMin = 0.7;
  final List<_Fraza> _log = []; // najnowsze na górze, przycinane do 60
  int _frazyRazem = 0;
  int _frazyPrzyjete = 0;

  // ---- diagnostyka mikrofonu (pomiar PRZED wzmocnieniem) ------------------
  int _chunkCount = 0;
  int _byteCount = 0;
  double _peak = 0; // szczyt w bieżącej porcji (0..1)
  double _peakMax = 0; // szczyt od początku nasłuchu (0..1)
  double _rms = 0; // energia bieżącej porcji (0..1)
  double _rmsMax = 0; // najgłośniejsza porcja = mowa
  double _rmsMin = 1; // najcichsza porcja = szum tła
  DateTime? _startedAt; // czas zegarowy startu nasłuchu
  DateTime? _stoppedAt; // ...i zatrzymania
  int _clipped = 0; // ile próbek obciętych przez wzmocnienie
  // Cisza cyfrowa — próbki równe dokładnie zeru. Mikrofon nigdy nie oddaje
  // idealnych zer (zawsze jest szum tła), więc dłuższy ciąg zer to dziura
  // dopisana przez warstwę natywną, czyli utracony fragment mowy.
  int _sampleCount = 0;
  int _zeroCount = 0;
  int _zeroRun = 0; // bieżący ciąg zer (liczony PRZEZ granice porcji)
  int _zeroRunMax = 0; // najdłuższa dziura w całym nasłuchu
  // Statystyka POJEDYNCZEJ porcji z mikrofonu — tylko tu widać granice buforów
  // warstwy natywnej.
  int _rawBytes = 0;
  int _rawBytesMin = 0;
  int _rawBytesMax = 0;
  double _fillSum = 0; // suma wypełnień porcji (0..1) → średnia
  int _tailZeroChunks = 0; // porcje, w których zera są WYŁĄCZNIE na końcu
  DateTime? _lastChunkAt;
  double _gapMsSum = 0;
  int _gapMsCount = 0;
  // Koszt obsługi jednej porcji 0,2 s po stronie Vosk (accept + partial/result).
  int _feedChunks = 0;
  int _feedMsSum = 0;
  int _feedMsMax = 0;

  // ---- źródło PLIK --------------------------------------------------------
  Timer? _tailTimer;
  bool _tailBusy = false; // jeden odczyt naraz
  String? _tailPath;
  DateTime? _tailFileStart; // do rotacji
  int _tailOffset = 0; // ile bajtów pliku już podaliśmy do Vosk
  int _tailReads = 0; // odczyty, które coś przyniosły
  int _tailMaxGapMs = 0; // najdłuższa przerwa między takimi odczytami
  DateTime? _tailLastDataAt;
  int _rotations = 0;

  String _fileReport = ''; // wynik ponownego rozpoznania nagrania

  @override
  void initState() {
    super.initState();
    // Po pierwszej klatce, a nie wprost z initState: _boot() od razu woła
    // setState (pasek stanu ładowania modelu), a to w trakcie budowania drzewa
    // kończy się asercją „setState called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _meterTimer?.cancel();
    _tailTimer?.cancel();
    _audioSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _endSub?.cancel();
    // Nasłuch jest ciągły, więc wyjście z ekranu MUSI zwolnić mikrofon —
    // inaczej sesja audio zostaje zajęta po opuszczeniu POC. Zamknięcie
    // rekordera dopiero po zatrzymaniu, żeby nie ścigały się dwa wywołania.
    _recorder.stop().whenComplete(() => _recorder.dispose());
    _player.dispose();
    _recognizer?.dispose();
    _model?.dispose();
    super.dispose();
  }

  // Wejście na ekran: przygotuj wszystko i ZACZNIJ SŁUCHAĆ. Bez przycisku
  // startu — nasłuch ma być ciągły, tak jak w docelowym rozwiązaniu.
  Future<void> _boot() async {
    await _initPlayer();
    await _loadDevices();
    await _loadRecordings();
    await _prepareModel();
    if (_modelReady && mounted && !_paused) await _start();
  }

  // Odtwarzacz nagrań kontrolnych. Kategoria sesji audio ustawiona JAWNIE na
  // `playback`: po nagrywaniu iOS zostaje w playAndRecord, w którym dźwięk
  // idzie cicho przez słuchawkę przy uchu. Kontekst ustawiamy na instancji,
  // żeby nie ruszać globalnych ustawień SoundHelper (dźwięki voice_screen2).
  Future<void> _initPlayer() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
          android: AudioContextAndroid(
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
          ),
        ),
      );
    } catch (_) {
      // Odtwarzanie zadziała na domyślnym kontekście — nie blokujemy ekranu.
    }
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _playDur = d);
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _playPos = p);
    });
    _endSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingPath = null;
          _playPos = Duration.zero;
        });
      }
    });
  }

  // Lista wejść audio — pozwala jawnie wskazać AirPods / słuchawki przewodowe
  // / mikrofon wbudowany i porównać je bez grzebania w ustawieniach iOS.
  Future<void> _loadDevices() async {
    try {
      final List<InputDevice> list = await _recorder.listInputDevices();
      // Po odświeżeniu wracamy do wejścia domyślnego — obiekty z nowej listy
      // nie są tożsame ze starymi, a DropdownButton wymaga wartości z items.
      if (mounted) {
        setState(() {
          _devices = list;
          _device = null;
        });
      }
    } catch (_) {
      // Brak wsparcia na danej platformie — zostaje wejście domyślne.
    }
  }

  // Katalog na model: jawna, zapisywalna ścieżka. Bez tego pakiet potrafi
  // spaść na relatywny 'models' (read-only na iOS) — patrz nagłówek pliku.
  Future<String> _modelStorage() async {
    final Directory base = await getApplicationSupportDirectory();
    final Directory dir = Directory('${base.path}/vosk_models');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir.path;
  }

  // Wyciąga tekst z JSON-a Vosk: {"text":"..."} lub {"partial":"..."}.
  String _extract(dynamic data, String key) {
    try {
      final map = jsonDecode(data.toString()) as Map<String, dynamic>;
      return (map[key] ?? '').toString();
    } catch (_) {
      return data.toString();
    }
  }

  Future<void> _prepareModel() async {
    setState(() {
      _busy = true;
      _status = 'Pobieranie modelu PL (~50 MB, tylko za pierwszym razem)...';
    });
    try {
      final String storage = await _modelStorage();
      final ModelLoader loader = ModelLoader(modelStorage: storage);
      final String modelPath = await loader.loadFromNetwork(_modelUrl);

      setState(() {
        _modelPath = modelPath;
        _status = 'Ładowanie modelu do pamięci...';
      });
      _model = await _vosk.createModel(modelPath);
      await _makeRecognizer();

      setState(() => _modelReady = _recognizer != null);
    } catch (e) {
      setState(() => _status = 'BŁĄD ładowania modelu:\n$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Tworzy recognizer — z zawężoną gramatyką albo z pełnym słownikiem modelu.
  // Gramatyka wymaga modelu typu LGRAPH; small-pl-0.22 nim jest. Jeśli jednak
  // Vosk odrzuci listę słów (np. któreś jest poza słownikiem), wracamy do
  // trybu ogólnego zamiast zostawiać ekran bez recognizera.
  Future<void> _makeRecognizer() async {
    _recognizer?.dispose();
    _recognizer = null;
    if (_model == null) return;

    if (_useGrammar) {
      final List<String> grammar = [
        ..._commandWords,
        ..._numberWords,
        // Fraza, nie dwa osobne słowa — „grób" ma być osiągalny wyłącznie
        // w tej sekwencji.
        if (_nakropTest) _nakropFraza,
        '[unk]', // pozwala Voskowi powiedzieć „to nie jest komenda"
      ];
      try {
        _recognizer = await _vosk.createRecognizer(
          model: _model!,
          sampleRate: _rate,
          grammar: grammar,
        );
      } catch (e) {
        _useGrammar = false;
        _status = 'Gramatyka odrzucona przez Vosk — wracam do słownika '
            'ogólnego.\n$e';
      }
    }
    _recognizer ??= await _vosk.createRecognizer(
      model: _model!,
      sampleRate: _rate,
    );

    // Pewność rozpoznania per słowo — bez tego bramka komend ma tylko [unk]
    // i słowo otwierające. Wołane po utworzeniu, bo dotyczy tej instancji.
    try {
      await _recognizer!.setWords(words: true);
    } catch (_) {
      // Starsza wtyczka bez setWords — bramka zadziała na dwóch kryteriach.
    }
  }

  // Usuwa rozpakowany model z dysku, żeby dało się powtórzyć pobranie
  // (ModelLoader pomija pobranie, gdy katalog modelu już istnieje).
  Future<void> _deleteModel() async {
    await _stop();
    setState(() {
      _busy = true;
      _paused = true; // bez modelu nie ma czego wznawiać
    });
    try {
      _recognizer?.dispose();
      _model?.dispose();
      _recognizer = null;
      _model = null;

      final Directory dir = Directory(await _modelStorage());
      if (dir.existsSync()) dir.deleteSync(recursive: true);

      setState(() {
        _modelReady = false;
        _modelPath = '';
        _status = 'Model usunięty. Wyjdź z ekranu i wejdź ponownie, '
            'żeby pobrać go od nowa.';
      });
    } catch (e) {
      setState(() => _status = 'BŁĄD usuwania modelu:\n$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- nasłuch ciągły ------------------------------------------------------

  // Każda zmiana ustawienia przerywa nasłuch, nanosi zmianę i wznawia — dzięki
  // temu w UI nie trzeba niczego blokować w trakcie słuchania.
  Future<void> _restart(Future<void> Function() apply) async {
    final bool was = _running;
    if (was) await _stop();
    setState(() => _busy = true);
    try {
      await apply();
    } catch (e) {
      if (mounted) setState(() => _status = 'BŁĄD zmiany ustawienia:\n$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (was && !_paused && mounted) await _start();
  }

  Future<void> _start() async {
    if (_running || _recognizer == null) return;
    if (!await _recorder.hasPermission()) {
      setState(() => _status =
          'Brak zgody na mikrofon. iOS: Ustawienia → Hi Bees → Mikrofon.');
      return;
    }
    // Odtwarzanie i nagrywanie na raz to na iOS proszenie się o sprzężenie
    // i o przełączenie sesji audio w trakcie nasłuchu.
    await _stopPlayback();
    await _resetMeters();

    try {
      if (_zrodlo == Zrodlo.strumien) {
        await _startStream();
      } else {
        await _startFile();
      }
    } catch (e) {
      setState(() => _status = 'BŁĄD startu nasłuchu:\n$e');
      return;
    }

    // Panel diagnostyczny odświeżamy z timera — setState na każdą porcję
    // audio (5×/s i częściej) niepotrzebnie miga UI.
    _meterTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (mounted) setState(() {});
    });

    setState(() {
      _running = true;
      _partial = '';
      _status = _zrodlo == Zrodlo.strumien
          ? 'Słucham na żywo (strumień). Mów — polecenia pojawią się poniżej.'
          : 'Słucham na żywo (plik, rotacja co $_rotateSec s).';
    });
  }

  Future<void> _startStream() async {
    final Stream<Uint8List> stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _rate,
        numChannels: 1,
        device: _device,
        echoCancel: _mic != MicMode.surowy,
        noiseSuppress: _mic != MicMode.surowy, // działa tylko na Androidzie
        autoGain: _mic == MicMode.voiceProcessingAgc,
        streamBufferSize: _bufSize,
      ),
    );
    _audioSub = stream.listen(
      _onAudioChunk,
      onError: (Object e) {
        if (mounted) setState(() => _status = 'BŁĄD strumienia audio:\n$e');
      },
      onDone: () {
        if (mounted && _running) {
          setState(() => _status = 'Strumień audio zakończony przez system.');
        }
      },
    );
  }

  // Źródło PLIK: AVAudioRecorder pisze WAV, a my co 200 ms czytamy przyrost.
  // Przy nasłuchu bez końca plik musi być rotowany, inaczej urośnie
  // w nieskończoność (32 kB/s przy 16 kHz).
  Future<void> _startFile() async {
    _tailPath = await _newFilePath();
    _tailOffset = 0;
    _tailFileStart = DateTime.now();
    await _recorder.start(_fileConfig(), path: _tailPath!);
    _tailTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _pumpTail(),
    );
  }

  RecordConfig _fileConfig() => RecordConfig(
        encoder: AudioEncoder.wav, // liniowy PCM 16-bit, bez stratnej kompresji
        sampleRate: _rate,
        numChannels: 1,
        device: _device,
        echoCancel: _mic != MicMode.surowy,
        noiseSuppress: _mic != MicMode.surowy,
        autoGain: _mic == MicMode.voiceProcessingAgc,
      );

  Future<String> _newFilePath() async {
    final Directory dir = await _recordingsDir();
    return '${dir.path}/${_recName('PLIK')}';
  }

  Future<void> _stop() async {
    if (!_running) return;
    _meterTimer?.cancel();
    _meterTimer = null;
    _tailTimer?.cancel();
    _tailTimer = null;
    await _audioSub?.cancel();
    _audioSub = null;

    await _recorder.stop();
    if (_zrodlo == Zrodlo.plik) {
      // Ogon pliku dopisany po stopie — koniec ostatniej wypowiedzi zwykle
      // leży w kawałku, którego timer nie zdążył pobrać. Najpierw czekamy na
      // odczyt, który mógł właśnie trwać: przy zajętej fladze `force` nic by
      // nie dał i ostatnia sekunda przepadłaby.
      for (int i = 0; i < 25 && _tailBusy; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
      await _pumpTail(force: true);
    }
    _stoppedAt = DateTime.now();
    _running = false; // domyka pętlę _drain
    await _waitForFeeder();

    // Resztka krótsza niż porcja też ma trafić do Vosk.
    final Uint8List rest = _buffer.takeBytes();
    if (rest.isNotEmpty && _recognizer != null) {
      await _recognizer!.acceptWaveformBytes(_amplify(rest));
    }
    if (_recognizer != null) {
      _przyjmijFraze(await _recognizer!.getFinalResult());
    }
    _buffer.clear();

    await _closeRecording();

    if (!mounted) return;
    setState(() {
      _running = false;
      _partial = '';
      _status = _chunkCount == 0
          ? 'UWAGA: mikrofon nie dostarczył ANI JEDNEJ porcji audio — '
              'problem jest po stronie nagrywania, nie rozpoznawania.'
          : 'Nasłuch zatrzymany.';
    });
  }

  // Domknięcie nagrania kontrolnego po zatrzymaniu nasłuchu: strumień zrzuca
  // bufor pierścieniowy do pliku, źródło PLIK zostawia albo kasuje ostatni plik.
  Future<void> _closeRecording() async {
    if (_zrodlo == Zrodlo.strumien) {
      if (_keepRec) await _saveRing();
      _wavRing.clear();
      _wavRingBytes = 0;
    } else if (!_keepRec && _tailPath != null) {
      _usunPlik(_tailPath!);
    }
    await _loadRecordings();
  }

  Future<void> _togglePause() async {
    if (_running) {
      setState(() => _paused = true);
      await _stop();
    } else {
      setState(() => _paused = false);
      await _start();
    }
  }

  // Zeruje recognizer i wszystkie liczniki diagnostyczne.
  Future<void> _resetMeters() async {
    await _recognizer!.reset();
    _buffer.clear();
    _wavRing.clear();
    _wavRingBytes = 0;
    _chunkCount = 0;
    _byteCount = 0;
    _peak = 0;
    _peakMax = 0;
    _rms = 0;
    _rmsMax = 0;
    _rmsMin = 1;
    _clipped = 0;
    _sampleCount = 0;
    _zeroCount = 0;
    _zeroRun = 0;
    _zeroRunMax = 0;
    _rawBytes = 0;
    _rawBytesMin = 0;
    _rawBytesMax = 0;
    _fillSum = 0;
    _tailZeroChunks = 0;
    _lastChunkAt = null;
    _gapMsSum = 0;
    _gapMsCount = 0;
    _tailReads = 0;
    _tailMaxGapMs = 0;
    _tailLastDataAt = null;
    _rotations = 0;
    _feedChunks = 0;
    _feedMsSum = 0;
    _feedMsMax = 0;
    _startedAt = DateTime.now();
    _stoppedAt = null;
  }

  void _onAudioChunk(Uint8List chunk) {
    _chunkCount++;
    _byteCount += chunk.length;

    // Rozmiar porcji i odstęp między porcjami zdradzają rozmiar bufora tapu
    // po stronie iOS — a ten, zestawiony z długością „wysepki" sygnału,
    // mówi wprost, ile cykli I/O wraca pustych.
    final DateTime now = DateTime.now();
    if (_lastChunkAt != null) {
      _gapMsSum += now.difference(_lastChunkAt!).inMicroseconds / 1000.0;
      _gapMsCount++;
    }
    _lastChunkAt = now;
    _rawBytes = chunk.length;
    if (_rawBytesMin == 0 || chunk.length < _rawBytesMin) {
      _rawBytesMin = chunk.length;
    }
    if (chunk.length > _rawBytesMax) _rawBytesMax = chunk.length;

    _measure(chunk);
    _buffer.add(chunk);
    _drain(); // celowo bez await — kolejkowanie pilnuje flaga _feeding
  }

  // Szczyt i energia (RMS) porcji (PCM 16-bit little endian) w skali 0..1.
  // Szczyt sam w sobie kłamie: pojedyncze trzaśnięcie daje wysoki peak przy
  // mowie ledwo słyszalnej. RMS min/max przez cały nasłuch daje szacunek
  // odstępu mowy od szumu tła (SNR) — to on decyduje, czy Vosk ma z czego
  // rozpoznawać.
  void _measure(Uint8List chunk) {
    final int samples = chunk.length ~/ 2;
    if (samples == 0) return;
    final ByteData view = ByteData.sublistView(chunk, 0, samples * 2);
    int maxAbs = 0;
    double sumSq = 0;
    int zerosHere = 0; // zera w TEJ porcji
    int lastNonZero = -1; // ostatnia próbka z sygnałem w TEJ porcji
    for (int i = 0; i < samples; i++) {
      final int s = view.getInt16(i * 2, Endian.little);
      if (s == 0) {
        _zeroCount++;
        _zeroRun++;
        zerosHere++;
        if (_zeroRun > _zeroRunMax) _zeroRunMax = _zeroRun;
      } else {
        _zeroRun = 0;
        lastNonZero = i;
      }
      final int a = s.abs();
      if (a > maxAbs) maxAbs = a;
      sumSq += s.toDouble() * s.toDouble();
    }
    _sampleCount += samples;
    // Wypełnienie porcji = dokąd sięga sygnał, licząc od początku.
    _fillSum += (lastNonZero + 1) / samples;
    // Zera wyłącznie na końcu = wszystkie zera leżą za ostatnią próbką
    // z sygnałem. To podpis „bufor oddany częściowo wypełniony".
    if (zerosHere > 0 && zerosHere == samples - (lastNonZero + 1)) {
      _tailZeroChunks++;
    }
    _peak = maxAbs / 32768.0;
    if (_peak > _peakMax) _peakMax = _peak;
    _rms = math.sqrt(sumSq / samples) / 32768.0;
    if (_rms > _rmsMax) _rmsMax = _rms;
    if (_rms > 0 && _rms < _rmsMin) _rmsMin = _rms;
  }

  // Programowe wzmocnienie z obcięciem. Zwraca NOWĄ tablicę — porcja z
  // mikrofonu bywa współdzielona, nie modyfikujemy jej w miejscu.
  Uint8List _amplify(Uint8List pcm) {
    if (_gain == 1) return pcm;
    final Uint8List out = Uint8List.fromList(pcm);
    final ByteData view = ByteData.sublistView(out);
    final int count = out.length ~/ 2;
    for (int i = 0; i < count; i++) {
      int s = view.getInt16(i * 2, Endian.little) * _gain;
      if (s > 32767) {
        s = 32767;
        _clipped++;
      } else if (s < -32768) {
        s = -32768;
        _clipped++;
      }
      view.setInt16(i * 2, s, Endian.little);
    }
    return out;
  }

  // Dokłada porcję do bufora pierścieniowego nagrania kontrolnego, wyrzucając
  // najstarsze — trzymamy ostatnią minutę, nie pierwszą.
  void _ringAdd(Uint8List chunk) {
    _wavRing.add(chunk);
    _wavRingBytes += chunk.length;
    while (_wavRingBytes > _wavLimit && _wavRing.isNotEmpty) {
      _wavRingBytes -= _wavRing.removeFirst().length;
    }
  }

  // Podaje zbuforowane PCM do recognizera porcjami, sekwencyjnie
  // (każde wywołanie to przejście przez MethodChannel — nie mogą się nakładać).
  Future<void> _drain() async {
    if (_feeding || _recognizer == null) return;
    _feeding = true;
    try {
      while (_running && _buffer.length >= _chunkBytes) {
        final Uint8List all = _buffer.takeBytes();
        final Uint8List raw = Uint8List.sublistView(all, 0, _chunkBytes);
        if (all.length > _chunkBytes) {
          _buffer.add(Uint8List.sublistView(all, _chunkBytes));
        }

        final Uint8List chunk = _amplify(raw);
        // Przy źródle PLIK nagranie kontrolne robi już AVAudioRecorder —
        // druga kopia w pamięci byłaby marnotrawstwem.
        if (_zrodlo == Zrodlo.strumien && _keepRec) _ringAdd(chunk);

        // Ile czasu zajmuje obsłużenie JEDNEJ porcji 0,2 s po stronie Vosk.
        // Po naprawie wtyczki (dekodowanie na własnej kolejce) to już nie
        // blokuje nagrywania, ale nadal mówi, ile procesora zjada nasłuch
        // ciągły — a ten ma chodzić godzinami.
        final Stopwatch sw = Stopwatch()..start();
        final bool ready = await _recognizer!.acceptWaveformBytes(chunk);
        String? result;
        String? part;
        if (ready) {
          // Vosk wykrył koniec wypowiedzi — mamy domkniętą frazę.
          result = (await _recognizer!.getResult()).toString();
        } else {
          part = _extract(await _recognizer!.getPartialResult(), 'partial');
        }
        sw.stop();
        _feedChunks++;
        _feedMsSum += sw.elapsedMilliseconds;
        if (sw.elapsedMilliseconds > _feedMsMax) {
          _feedMsMax = sw.elapsedMilliseconds;
        }

        if (!mounted) return;
        if (result != null) {
          _przyjmijFraze(result);
        } else if (part != null && part != _partial) {
          final String p = part;
          setState(() => _partial = p);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'BŁĄD przetwarzania audio:\n$e');
    } finally {
      _feeding = false;
    }
  }

  // ---- bramka komend -------------------------------------------------------
  //
  // Pytanie, na które ma odpowiedzieć ten kawałek: czy da się w ogóle
  // zrezygnować z „Hej Maja" i zapisywać dane wyłuskane z ciągłej mowy?
  // Ryzyko jest oczywiste — przy zawężonej gramatyce Vosk MUSI dopasować każdy
  // dźwięk do słów komend albo do [unk], więc rozmowa przy ulu też coś zwróci.
  // Trzy kryteria poniżej to minimum, jakie da się zrobić bez parsera .yml;
  // pełna walidacja („czy fraza pasuje do wyrażenia od początku do końca,
  // ze wszystkimi wymaganymi słowami") przyjdzie z silnikiem gramatyki i to
  // ona będzie właściwym zabezpieczeniem.

  void _przyjmijFraze(dynamic raw) {
    final Map<String, dynamic> map = _json(raw);
    final String tekst = (map['text'] ?? '').toString().trim();
    if (tekst.isEmpty) return;

    // setWords → {"result":[{"conf":1.0,"word":"ramka",...}], "text":"..."}
    final List<dynamic> slowa = (map['result'] as List<dynamic>?) ?? const [];
    double minConf = -1;
    for (final dynamic w in slowa) {
      if (w is Map && w['conf'] != null) {
        final double c = (w['conf'] as num).toDouble();
        if (minConf < 0 || c < minConf) minConf = c;
      }
    }

    final List<String> tokeny = tekst.split(RegExp(r'\s+'));
    final int unk =
        tokeny.where((t) => t == '[unk]' || t == '<unk>' || t == 'unk').length;

    // Alias „nakrop": zaczyna się od „na", które NIE jest słowem otwierającym
    // komendę i nigdy nim nie będzie — to zbyt pospolity przyimek, żeby wpuścić
    // go do _anchorWords. Dlatego bramkę otwiera nie samo „na", tylko dokładny
    // prefiks „na grób".
    final bool nakrop = _nakropTest && _zaczynaSieOd(tokeny, _nakropTokeny);

    bool przyjeta = true;
    String powod = 'przechodzi bramkę';
    if (!_gateOn) {
      powod = 'bramka wyłączona';
    } else if (unk > 0) {
      przyjeta = false;
      powod = 'poza gramatyką ($unk × [unk])';
    } else if (_confMin > 0 && minConf >= 0 && minConf < _confMin) {
      przyjeta = false;
      powod = 'niska pewność (${minConf.toStringAsFixed(2)})';
    } else if (!nakrop && !_anchorWords.contains(tokeny.first)) {
      przyjeta = false;
      powod = 'nie zaczyna się od słowa otwierającego polecenie '
          '(„${tokeny.first}")';
    } else if (nakrop) {
      powod = 'przechodzi bramkę (alias „nakrop")';
    }

    final _Fraza f = _Fraza(
      tekst: tekst,
      unk: unk,
      minConf: minConf,
      przyjeta: przyjeta,
      powod: powod,
      oCzasie: DateTime.now(),
    );

    if (!mounted) return;
    setState(() {
      _partial = '';
      _finalText = tekst;
      _frazyRazem++;
      if (przyjeta) _frazyPrzyjete++;
      if (nakrop) _nakropTrafien++;
      _log.insert(0, f);
      if (_log.length > 60) _log.removeLast();
    });
  }

  // Czy lista tokenów zaczyna się dokładnie od zadanego prefiksu.
  bool _zaczynaSieOd(List<String> tokeny, List<String> prefiks) {
    if (tokeny.length < prefiks.length) return false;
    for (int i = 0; i < prefiks.length; i++) {
      if (tokeny[i] != prefiks[i]) return false;
    }
    return true;
  }

  Map<String, dynamic> _json(dynamic raw) {
    try {
      final dynamic d = jsonDecode(raw.toString());
      return d is Map<String, dynamic> ? d : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  // ---- źródło PLIK: odczyt ogona i rotacja ---------------------------------

  // Czeka, aż skończy się karmienie recognizera w tle. Wywołania przez
  // MethodChannel nie mogą się nakładać, a przy zatrzymaniu chcemy jeszcze
  // dosłać resztkę bufora i pobrać wynik końcowy.
  Future<void> _waitForFeeder() async {
    for (int i = 0; i < 50 && _feeding; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  // Jeden odczyt „ogona" pliku. force = czytaj nawet gdy nasłuch już
  // zatrzymany (domknięcie po Stop).
  Future<void> _pumpTail({bool force = false}) async {
    if (_tailBusy || _tailPath == null) return;
    if (!_running && !force) return;
    _tailBusy = true;
    try {
      final File f = File(_tailPath!);
      if (!f.existsSync()) return;
      final int len = await f.length();

      if (_tailOffset == 0) {
        // Nagłówek RIFF bywa gotowy dopiero po chwili od startu. Świadomie
        // ignorujemy rozmiar bloku `data` — w pliku w trakcie nagrywania
        // jeszcze go nie ma; bierzemy sam OFFSET początku PCM.
        if (len < 64) return;
        final Uint8List head = await _readRange(f, 0, math.min(len, 8192));
        final int? dataAt = _wavDataOffset(head);
        if (dataAt == null || dataAt >= len) return;
        _tailOffset = dataAt;
      }

      int avail = len - _tailOffset;
      avail -= avail % 2; // tylko pełne próbki 16-bit
      if (avail > 0) {
        final Uint8List bytes =
            await _readRange(f, _tailOffset, _tailOffset + avail);
        _tailOffset += avail;

        final DateTime now = DateTime.now();
        if (_tailLastDataAt != null) {
          final int gap = now.difference(_tailLastDataAt!).inMilliseconds;
          if (gap > _tailMaxGapMs) _tailMaxGapMs = gap;
        }
        _tailLastDataAt = now;
        _tailReads++;
        _onAudioChunk(bytes);
      }

      // Rotacja po odczytaniu ogona — nowy plik zaczyna się tam, gdzie
      // skończyliśmy czytać stary. Ubytek to czas samego przełączenia
      // (kilka–kilkanaście ms zapisanych po ostatnim odczycie).
      // `force` to domknięcie po Stop — wtedy rotacja jest ostatnią rzeczą,
      // jakiej chcemy (uruchomiłaby nagrywanie od nowa).
      if (_running &&
          !force &&
          _tailFileStart != null &&
          DateTime.now().difference(_tailFileStart!).inSeconds >= _rotateSec) {
        await _rotateFile();
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'BŁĄD odczytu pliku:\n$e');
    } finally {
      _tailBusy = false;
    }
  }

  // Zamyka bieżący plik i otwiera następny. Recognizera NIE resetujemy —
  // z jego punktu widzenia strumień audio płynie dalej.
  Future<void> _rotateFile() async {
    final String? stary = _tailPath;
    try {
      await _recorder.stop();
      if (stary != null && !_keepRec) _usunPlik(stary);

      _tailPath = await _newFilePath();
      _tailOffset = 0;
      _tailFileStart = DateTime.now();
      await _recorder.start(_fileConfig(), path: _tailPath!);
      _rotations++;
      if (_keepRec) await _loadRecordings();
    } catch (e) {
      if (mounted) setState(() => _status = 'BŁĄD rotacji pliku:\n$e');
    }
  }

  Future<Uint8List> _readRange(File f, int start, int end) async {
    final RandomAccessFile raf = await f.open();
    try {
      await raf.setPosition(start);
      return await raf.read(end - start);
    } finally {
      await raf.close();
    }
  }

  // Offset początku danych PCM w pliku WAV.
  int? _wavDataOffset(Uint8List b) {
    if (b.length < 12) return null;
    if (String.fromCharCodes(b.sublist(0, 4)) != 'RIFF' ||
        String.fromCharCodes(b.sublist(8, 12)) != 'WAVE') {
      return null;
    }
    final ByteData view = ByteData.sublistView(b);
    int pos = 12;
    while (pos + 8 <= b.length) {
      final String id = String.fromCharCodes(b.sublist(pos, pos + 4));
      final int size = view.getUint32(pos + 4, Endian.little);
      if (id == 'data') return pos + 8;
      // Nieustalony rozmiar bloku = nie ma jak iść dalej.
      if (size <= 0 || pos + 8 + size > b.length) return null;
      pos += 8 + size + (size.isOdd ? 1 : 0);
    }
    return null;
  }

  // ---- nagrania kontrolne --------------------------------------------------

  // Nagłówek WAV PCM 16-bit mono — 44 bajty, bez dodatkowych pakietów.
  Uint8List _wrapWav(Uint8List pcm) {
    const int channels = 1;
    const int bits = 16;
    final int blockAlign = channels * bits ~/ 8;
    final BytesBuilder b = BytesBuilder();
    void tag(String v) => b.add(ascii.encode(v));
    void u32(int v) =>
        b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
    void u16(int v) =>
        b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());

    tag('RIFF');
    u32(36 + pcm.length);
    tag('WAVE');
    tag('fmt ');
    u32(16); // rozmiar bloku fmt
    u16(1); // PCM
    u16(channels);
    u32(_rate);
    u32(_rate * blockAlign); // bajty na sekundę
    u16(blockAlign);
    u16(bits);
    tag('data');
    u32(pcm.length);
    b.add(pcm);
    return b.toBytes();
  }

  // Krótki znacznik trybu do nazwy pliku — po kilku testach łatwo się pogubić,
  // które nagranie było z jakim ustawieniem.
  String _micTag() {
    switch (_mic) {
      case MicMode.surowy:
        return 'surowy';
      case MicMode.voiceProcessing:
        return 'vp';
      case MicMode.voiceProcessingAgc:
        return 'vpagc';
    }
  }

  // Znacznik czasu w nazwie pliku: MMDD-HHMMSS.
  String _stamp() {
    final DateTime now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  // Nazwa pliku koduje warunki testu — inaczej po kilkunastu nagraniach nie
  // wiadomo, które z jakim ustawieniem powstało. Człon `_16k_` jest odczytywany
  // przy liczeniu czasu trwania na liście.
  String _recName(String zrodlo) {
    final String dev = (_device?.label ?? 'domyslne')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final String buf = _bufSize == null ? 'bufdom' : 'buf$_bufSize';
    return 'vosk_${_stamp()}_${dev}_${_micTag()}_${_rate ~/ 1000}k_'
        '${buf}_${_gain}x_${_useGrammar ? 'gram' : 'ogol'}_$zrodlo.wav';
  }

  // Katalog nagrań. Documents, NIE katalog tymczasowy: iOS potrafi wyczyścić
  // tmp między uruchomieniami, a nagrania mają służyć do porównań w czasie.
  Future<Directory> _recordingsDir() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${base.path}/vosk_nagrania');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<void> _loadRecordings() async {
    try {
      final Directory dir = await _recordingsDir();
      final List<File> files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.wav'))
          .toList()
        ..sort((a, b) =>
            b.statSync().modified.compareTo(a.statSync().modified));
      if (mounted) setState(() => _recordings = files);
    } catch (_) {
      // Brak katalogu / brak dostępu — lista zostaje pusta.
    }
  }

  void _usunPlik(String path) {
    try {
      final File f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {
      // Plik mógł już zniknąć — nieistotne.
    }
  }

  // Zrzut bufora pierścieniowego (ostatnia minuta strumienia) do pliku WAV.
  Future<void> _saveRing() async {
    try {
      if (_wavRing.isEmpty) return;
      final BytesBuilder b = BytesBuilder(copy: false);
      for (final Uint8List c in _wavRing) {
        b.add(c);
      }
      final Uint8List pcm = b.takeBytes();
      if (pcm.isEmpty) return;
      final Directory dir = await _recordingsDir();
      final File f = File('${dir.path}/${_recName('STRUM')}');
      await f.writeAsBytes(_wrapWav(pcm));
    } catch (e) {
      if (mounted) setState(() => _status = 'BŁĄD zapisu nagrania:\n$e');
    }
  }

  // Ponowne rozpoznanie gotowego nagrania — pozwala porównać tryb komend
  // z trybem ogólnym NA TYM SAMYM dźwięku (nagraj raz, przełącz, sprawdź).
  Future<void> _analyzeFile(File f) async {
    if (_running) {
      setState(() => _paused = true);
      await _stop();
    }
    setState(() {
      _busy = true;
      _fileReport = '';
      _status = 'Analizuję nagranie...';
    });
    try {
      if (!f.existsSync()) {
        setState(() => _status = 'Plik nagrania nie istnieje: ${f.path}');
        return;
      }
      final Uint8List bytes = await f.readAsBytes();
      final _Wav? wav = _parseWav(bytes);
      if (wav == null) {
        setState(() => _status = 'Nie umiem odczytać tego pliku jako WAV PCM '
            '16-bit (${bytes.length} B).');
        return;
      }

      final StringBuffer report = StringBuffer();
      report.writeln(f.path.split('/').last);
      report.writeln('${wav.rate} Hz, ${wav.channels} kan., '
          '${(wav.pcm.length / (wav.rate * 2 * wav.channels)).toStringAsFixed(1)} s');
      report.write(_pcmReport(wav.pcm, wav.rate));

      // Rozpoznanie ma sens tylko gdy plik jest mono i w tej samej
      // częstotliwości co recognizer — inaczej wynik byłby bez wartości.
      if (wav.channels != 1) {
        report.writeln('(pomijam rozpoznanie — plik nie jest mono)');
      } else if (wav.rate != _rate) {
        report.writeln('(pomijam rozpoznanie — plik ma ${wav.rate} Hz, '
            'a recognizer $_rate Hz)');
      } else if (_recognizer == null) {
        report.writeln('(pomijam rozpoznanie — model nie jest wczytany)');
      } else {
        final String text = await _recognizeBytes(wav.pcm);
        report.writeln('Vosk (${_useGrammar ? 'tryb poleceń' : 'słownik ogólny'}'
            '): ${text.isEmpty ? '(nic)' : text}');
      }

      if (!mounted) return;
      setState(() {
        _fileReport = report.toString().trimRight();
        _status = 'Nagranie przeanalizowane. Przełącz tryb słownika '
            'i powtórz, żeby porównać na tym samym dźwięku.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'BŁĄD analizy nagrania:\n$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Podaje gotowe PCM do recognizera w takich samych porcjach jak nasłuch.
  Future<String> _recognizeBytes(Uint8List pcm) async {
    await _recognizer!.reset();
    for (int off = 0; off < pcm.length; off += _chunkBytes) {
      final int end = math.min(off + _chunkBytes, pcm.length);
      // Ostatnia, niepełna porcja też się liczy — Vosk przyjmuje dowolną długość.
      await _recognizer!.acceptWaveformBytes(
        Uint8List.sublistView(pcm, off, end),
      );
    }
    final String text = _extract(await _recognizer!.getFinalResult(), 'text');
    await _recognizer!.reset();
    return text;
  }

  // Te same miary co w panelu diagnostycznym, policzone na całym pliku.
  String _pcmReport(Uint8List pcm, int rate) {
    final int samples = pcm.length ~/ 2;
    if (samples == 0) return 'plik jest pusty\n';
    final ByteData view = ByteData.sublistView(pcm, 0, samples * 2);
    int zeros = 0, run = 0, runMax = 0, maxAbs = 0;
    double sumSq = 0;
    for (int i = 0; i < samples; i++) {
      final int s = view.getInt16(i * 2, Endian.little);
      if (s == 0) {
        zeros++;
        run++;
        if (run > runMax) runMax = run;
      } else {
        run = 0;
      }
      final int a = s.abs();
      if (a > maxAbs) maxAbs = a;
      sumSq += s.toDouble() * s.toDouble();
    }
    final double zeroPct = 100.0 * zeros / samples;
    final double peak = maxAbs / 32768.0;
    final double rms = math.sqrt(sumSq / samples) / 32768.0;
    return 'cisza cyfrowa: ${zeroPct.toStringAsFixed(1)} %   '
        'najdłuższa dziura: ${(1000.0 * runMax / rate).toStringAsFixed(0)} ms\n'
        'szczyt: ${_db(peak)} dBFS   średnia (RMS): ${_db(rms)} dBFS\n';
  }

  // Minimalny czytnik WAV — przechodzi po blokach RIFF, bo AVAudioRecorder
  // potrafi wstawić przed `data` bloki, których nie ma w naszym własnym
  // nagłówku (sztywne 44 bajty nie wystarczą).
  _Wav? _parseWav(Uint8List b) {
    if (b.length < 12) return null;
    if (String.fromCharCodes(b.sublist(0, 4)) != 'RIFF' ||
        String.fromCharCodes(b.sublist(8, 12)) != 'WAVE') {
      return null;
    }
    final ByteData view = ByteData.sublistView(b);
    int pos = 12, rate = 0, channels = 0, bits = 0;
    Uint8List? data;
    while (pos + 8 <= b.length) {
      final String id = String.fromCharCodes(b.sublist(pos, pos + 4));
      final int size = view.getUint32(pos + 4, Endian.little);
      final int body = pos + 8;
      if (id == 'fmt ' && body + 16 <= b.length) {
        channels = view.getUint16(body + 2, Endian.little);
        rate = view.getUint32(body + 4, Endian.little);
        bits = view.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        data = Uint8List.sublistView(b, body, math.min(b.length, body + size));
      }
      if (size <= 0) break; // nieustalony rozmiar bloku — dalej nie idziemy
      // Bloki RIFF są wyrównane do parzystej liczby bajtów.
      pos = body + size + (size.isOdd ? 1 : 0);
    }
    if (data == null || bits != 16 || rate == 0) return null;
    return _Wav(rate: rate, channels: channels, pcm: data);
  }

  // ---- odsłuch -------------------------------------------------------------

  Future<void> _stopPlayback() async {
    try {
      await _player.stop();
    } catch (_) {
      // Nic nie grało — nieistotne.
    }
    if (mounted) {
      setState(() {
        _playingPath = null;
        _playPos = Duration.zero;
      });
    }
  }

  Future<void> _togglePlay(File f) async {
    if (_playingPath == f.path) {
      await _stopPlayback();
      return;
    }
    // Odsłuch przy włączonym mikrofonie to sprzężenie i przestawianie sesji
    // audio w trakcie nasłuchu — pauzujemy, wznowienie zostaje dla użytkownika.
    if (_running) {
      setState(() => _paused = true);
      await _stop();
    }
    try {
      await _player.stop();
      setState(() {
        _playingPath = f.path;
        _playPos = Duration.zero;
        _playDur = Duration.zero;
      });
      await _player.play(DeviceFileSource(f.path));
    } catch (e) {
      if (mounted) {
        setState(() {
          _playingPath = null;
          _status = 'BŁĄD odtwarzania:\n$e';
        });
      }
    }
  }

  Future<void> _deleteRecording(File f) async {
    if (_playingPath == f.path) await _stopPlayback();
    _usunPlik(f.path);
    await _loadRecordings();
  }

  Future<void> _shareRecording(File f) async {
    // Bez mimeType — iOS rozpoznaje typ po rozszerzeniu .wav, a jawne
    // 'audio/wav' potrafiło skończyć się tym, że arkusz w ogóle się nie
    // pokazywał. sharePositionOrigin jest obowiązkowe na iPadzie.
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final ShareResult r = await Share.shareXFiles(
        [XFile(f.path)],
        subject: 'POC Vosk — nagranie kontrolne',
        text: 'Nagranie tego, co dostał recognizer: '
            '${f.path.split('/').last}',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
      if (mounted) {
        setState(() => _status = 'Udostępnianie: ${r.status.name}'
            '${r.raw.isEmpty ? '' : ' (${r.raw})'}');
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'BŁĄD udostępniania:\n$e');
    }
  }

  String _mmss(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  // Rozmiar pliku odporny na to, że plik właśnie zniknął — czytamy go
  // w metodzie build, a wyjątek tam oznacza czerwony ekran w środku testu.
  int _size(File f) {
    try {
      return f.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  // ---- UI -----------------------------------------------------------------

  // Poziom w dBFS — czytelniejszy niż surowy ułamek przy cichym sygnale.
  String _db(double level) =>
      level <= 0 ? '−∞' : (20 * math.log(level) / math.ln10).toStringAsFixed(1);

  String _hhmmss(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:'
      '${d.second.toString().padLeft(2, '0')}';

  // Pasek stanu nasłuchu zamiast przycisku „Słuchaj" — nasłuch jest ciągły,
  // użytkownik ma tu tylko pauzę (potrzebną do odsłuchu i zmian ustawień).
  Widget _listenBar() {
    final bool ok = _running;
    return Card(
      color: ok ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(ok ? Icons.hearing : Icons.hearing_disabled,
                color: ok ? Colors.green[800] : Colors.orange[800]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ok ? 'Nasłuch ciągły — włączony' : 'Nasłuch wstrzymany',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    _zrodlo == Zrodlo.strumien
                        ? 'źródło: strumień (record.startStream)'
                        : 'źródło: plik (rotacja co $_rotateSec s, '
                            'obrotów: $_rotations)',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: (_busy || !_modelReady) ? null : _togglePause,
              icon: Icon(ok ? Icons.pause : Icons.play_arrow),
              label: Text(ok ? 'Pauza' : 'Wznów'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zrodloPicker() {
    return Row(
      children: [
        const Text('Źródło: ', style: TextStyle(fontSize: 13)),
        ...Zrodlo.values.map(
          (z) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(z == Zrodlo.strumien ? 'strumień' : 'plik',
                  style: const TextStyle(fontSize: 12)),
              selected: _zrodlo == z,
              onSelected: (_busy || !_modelReady)
                  ? null
                  : (_) => _restart(() async {
                        _zrodlo = z;
                      }),
            ),
          ),
        ),
      ],
    );
  }

  // Panel bramki komend — sedno tego wydania.
  Widget _commandPanel() {
    final int odrzucone = _frazyRazem - _frazyPrzyjete;
    return Card(
      color: Colors.indigo[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Polecenia wyłuskane z ciągłej mowy (bez „Hej Maja")',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Bramka odrzuca frazę, gdy: zawiera [unk] (coś spoza gramatyki), '
              'najsłabiej rozpoznane słowo ma pewność poniżej progu, albo fraza '
              'nie zaczyna się od słowa mogącego otwierać polecenie. To jeszcze '
              'nie parser .yml — mierzymy, ile fałszywych trafień przechodzi.',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Bramka włączona',
                  style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                  'Wyłączona pokazuje wszystko, co Vosk zwrócił — do porównania.',
                  style: TextStyle(fontSize: 11)),
              value: _gateOn,
              onChanged: (bool v) => setState(() => _gateOn = v),
            ),
            Row(
              children: [
                const Text('Próg pewności: ', style: TextStyle(fontSize: 13)),
                ...[0.0, 0.5, 0.7, 0.9].map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(p == 0 ? 'brak' : p.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12)),
                      selected: _confMin == p,
                      onSelected: (_) => setState(() => _confMin = p),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'fraz: $_frazyRazem   przyjętych: $_frazyPrzyjete   '
              'odrzuconych: $odrzucone',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (_nakropTest)
              Text(
                '„nakrop" („$_nakropFraza"): $_nakropTrafien   '
                '— wyłącz i porównaj „odrzuconych" na tej samej rozmowie',
                style: TextStyle(fontSize: 12, color: Colors.indigo[700]),
              ),
            const SizedBox(height: 6),
            const Text('Na żywo (partial):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(
              _partial.isEmpty ? '—' : _partial,
              style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            if (_log.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('(jeszcze nic nie padło)',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            else
              ..._log.map(_frazaTile),
            if (_log.isNotEmpty)
              TextButton.icon(
                onPressed: () => setState(() {
                  _log.clear();
                  _frazyRazem = 0;
                  _frazyPrzyjete = 0;
                  _nakropTrafien = 0;
                }),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Wyczyść log',
                    style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _frazaTile(_Fraza f) {
    final Color kolor = f.przyjeta ? Colors.green[800]! : Colors.grey[600]!;
    final String conf =
        f.minConf < 0 ? '' : '   min conf ${f.minConf.toStringAsFixed(2)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(f.przyjeta ? Icons.check_circle : Icons.remove_circle_outline,
              size: 16, color: kolor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.tekst,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: f.przyjeta ? FontWeight.w600 : FontWeight.normal,
                    color: f.przyjeta ? Colors.black : Colors.grey[700],
                  ),
                ),
                Text(
                  '${_hhmmss(f.oCzasie)}   ${f.powod}$conf',
                  style: TextStyle(fontSize: 11, color: kolor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagnostics() {
    final double audioSec = _byteCount / (_rate * 2);
    final double wallSec = _startedAt == null
        ? 0
        : (_stoppedAt ?? DateTime.now())
                .difference(_startedAt!)
                .inMilliseconds /
            1000.0;
    // Faktyczna częstotliwość próbkowania strumienia. Rozjazd z zamówioną
    // oznacza mowę przyspieszoną lub zwolnioną — Vosk nie ma wtedy szans.
    final double realRate = wallSec > 1 ? (_byteCount / 2) / wallSec : 0;
    final bool rateBad =
        realRate > 0 && (realRate < _rate * 0.85 || realRate > _rate * 1.15);
    final String rateText = realRate == 0 ? '—' : '${realRate.round()} Hz';
    final double zeroPct =
        _sampleCount == 0 ? 0 : 100.0 * _zeroCount / _sampleCount;
    final bool zeroBad = _sampleCount > 0 && zeroPct > 5;
    final double zeroMaxMs = 1000.0 * _zeroRunMax / _rate;
    final double snr = (_rmsMax > 0 && _rmsMin < 1)
        ? 20 * math.log(_rmsMax / _rmsMin) / math.ln10
        : 0;
    final String snrText = snr == 0 ? '—' : '${snr.toStringAsFixed(1)} dB';
    final String clipText = _gain > 1 ? '   obcięte próbki: $_clipped' : '';
    final double fill = _chunkCount == 0 ? 0 : _fillSum / _chunkCount;
    final double gapMs = _gapMsCount == 0 ? 0 : _gapMsSum / _gapMsCount;
    final bool bufferBad =
        _chunkCount > 10 && fill < 0.9 && _tailZeroChunks > _chunkCount * 0.5;
    // Koszt Vosk na porcję 0,2 s. Po naprawie wtyczki dekodowanie idzie na
    // własnej kolejce, więc to już nie blokuje nagrywania — ale przy nasłuchu
    // ciągłym mówi, ile procesora (i baterii) zjada samo słuchanie.
    final double feedMs = _feedChunks == 0 ? 0 : _feedMsSum / _feedChunks;
    final double feedLoad = 100.0 * feedMs / (_chunkBytes / (_rate * 2) * 1000);
    final bool feedBad = _feedChunks > 5 && feedLoad > 50;
    final String feedText = _feedChunks == 0
        ? '— (recognizer nie był wołany)'
        : 'śr. ${feedMs.toStringAsFixed(0)} ms na porcję 0,2 s '
            '= ${feedLoad.toStringAsFixed(0)} % czasu rzeczywistego';

    return Card(
      color: _chunkCount == 0 && _running ? Colors.red[50] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Diagnostyka mikrofonu',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'porcje: $_chunkCount   bajty: $_byteCount   '
              'audio: ${audioSec.toStringAsFixed(1)} s   '
              'zegar: ${wallSec.toStringAsFixed(1)} s',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'faktyczne próbkowanie: $rateText   (oczekiwane $_rate Hz)',
              style: TextStyle(
                fontSize: 13,
                color: rateBad ? Colors.red : Colors.black87,
                fontWeight: rateBad ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              'szczyt: ${_db(_peakMax)} dBFS   teraz: ${_db(_rms)} dBFS\n'
              'mowa (RMS): ${_db(_rmsMax)} dBFS   tło: ${_db(_rmsMin)} dBFS',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'odstęp mowa/tło: $snrText$clipText',
              style: TextStyle(
                fontSize: 13,
                color: snr > 0 && snr < 15 ? Colors.orange[800] : Colors.black87,
              ),
            ),
            Text(
              'cisza cyfrowa: ${zeroPct.toStringAsFixed(1)} %   '
              'najdłuższa dziura: ${zeroMaxMs.toStringAsFixed(0)} ms',
              style: TextStyle(
                fontSize: 13,
                color: zeroBad ? Colors.red : Colors.black87,
                fontWeight: zeroBad ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              'koszt Vosk: $feedText'
              '${_feedChunks == 0 ? '' : '   (max $_feedMsMax ms)'}',
              style: TextStyle(
                fontSize: 13,
                color: feedBad ? Colors.red : Colors.black87,
                fontWeight: feedBad ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              'porcja z mikrofonu: $_rawBytes B'
              '${_rawBytesMin == _rawBytesMax ? '' : ' (od $_rawBytesMin do $_rawBytesMax)'}'
              '   co ${gapMs == 0 ? '—' : '${gapMs.toStringAsFixed(0)} ms'}\n'
              'wypełnienie porcji: ${(100 * fill).toStringAsFixed(0)} %   '
              'zera tylko na końcu: $_tailZeroChunks / $_chunkCount',
              style: TextStyle(
                fontSize: 13,
                color: bufferBad ? Colors.red : Colors.black87,
                fontWeight: bufferBad ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_zrodlo == Zrodlo.plik && (_running || _tailReads > 0))
              Text(
                'odczyty z danymi: $_tailReads   '
                'najdłuższa przerwa: $_tailMaxGapMs ms   '
                'rotacji pliku: $_rotations',
                style: TextStyle(
                  fontSize: 13,
                  color: _tailMaxGapMs > 1500 ? Colors.red : Colors.black87,
                ),
              ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: _peak.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              color: _peak > 0.02 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 4),
            Text(
              'Poziomy mierzone PRZED wzmocnieniem programowym.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (zeroBad)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Nagranie jest podziurawione cyfrową ciszą — mowa dociera do '
                  'Vosk poszatkowana. Po naprawie wtyczki to NIE powinno się '
                  'zdarzać; jeśli wraca, sprawdź drugie źródło audio.',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            if (rateBad)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Strumień NIE jest w $_rate Hz — mowa dochodzi do Vosk '
                  'przyspieszona lub zwolniona.',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            if (bufferBad)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Każda porcja ma dane tylko na początku, a zera na końcu — '
                  'bufor przychodzi z warstwy natywnej niedopełniony. '
                  'Przełącz źródło audio.',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            if (_running && _chunkCount == 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Brak danych z mikrofonu — nagrywanie nie wystartowało.',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            if (_chunkCount > 0 && _peakMax < 0.005)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Dane lecą, ale są ciszą — mikrofon oddaje puste próbki '
                  '(spróbuj innego wejścia audio).',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Wybór wejścia audio — bez tego nie da się porównać AirPods / słuchawek
  // przewodowych / mikrofonu wbudowanego w sposób powtarzalny.
  Widget _devicePicker() {
    return Row(
      children: [
        const Text('Wejście: ', style: TextStyle(fontSize: 13)),
        Expanded(
          child: DropdownButton<InputDevice?>(
            isExpanded: true,
            value: _device,
            hint: const Text('domyślne systemowe',
                style: TextStyle(fontSize: 13)),
            onChanged: _busy
                ? null
                : (InputDevice? d) => _restart(() async {
                      _device = d;
                    }),
            items: [
              const DropdownMenuItem<InputDevice?>(
                value: null,
                child:
                    Text('domyślne systemowe', style: TextStyle(fontSize: 13)),
              ),
              ..._devices.map(
                (d) => DropdownMenuItem<InputDevice?>(
                  value: d,
                  child: Text(d.label,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Odśwież listę wejść',
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: _busy ? null : () => _restart(_loadDevices),
        ),
      ],
    );
  }

  Widget _micChip(MicMode mode, String label) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _mic == mode,
      onSelected: _busy
          ? null
          : (_) => _restart(() async {
                _mic = mode;
              }),
    );
  }

  // Częstotliwość strumienia. Zmiana wymaga NOWEGO recognizera — Vosk dostaje
  // ją przy tworzeniu i po niej przelicza próbki na 16 kHz modelu.
  Widget _ratePicker() {
    return Row(
      children: [
        const Text('Próbkowanie: ', style: TextStyle(fontSize: 13)),
        ...[16000, 48000].map(
          (r) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text('${r ~/ 1000} kHz',
                  style: const TextStyle(fontSize: 12)),
              selected: _rate == r,
              onSelected: (_busy || !_modelReady)
                  ? null
                  : (_) => _restart(() async {
                        _rate = r;
                        await _makeRecognizer();
                      }),
            ),
          ),
        ),
      ],
    );
  }

  // Rozmiar bufora tapu AVAudioEngine — dotyczy wyłącznie źródła STRUMIEŃ.
  Widget _bufferPicker() {
    return Row(
      children: [
        const Text('Bufor: ', style: TextStyle(fontSize: 13)),
        ...<int?>[null, 1024, 4096].map(
          (b) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(b == null ? 'domyślny' : '$b',
                  style: const TextStyle(fontSize: 12)),
              selected: _bufSize == b,
              onSelected: (_busy || _zrodlo != Zrodlo.strumien)
                  ? null
                  : (_) => _restart(() async {
                        _bufSize = b;
                      }),
            ),
          ),
        ),
      ],
    );
  }

  // Wzmocnienie programowe — lekarstwo na zbyt cichy mikrofon wbudowany,
  // przewidywalne w przeciwieństwie do voice processingu iOS.
  Widget _gainPicker() {
    return Row(
      children: [
        const Text('Wzmocnienie: ', style: TextStyle(fontSize: 13)),
        ...[1, 2, 4, 8].map(
          (g) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text('${g}×', style: const TextStyle(fontSize: 12)),
              selected: _gain == g,
              onSelected: (_) => setState(() => _gain = g),
            ),
          ),
        ),
      ],
    );
  }

  Widget _recordingsPanel() {
    final int totalKb =
        _recordings.fold<int>(0, (s, f) => s + _size(f)) ~/ 1024;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Nagrania kontrolne',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (_recordings.isNotEmpty)
                  Text('$totalKb kB',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Zapisuj nagrania', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                _zrodlo == Zrodlo.strumien
                    ? 'Ostatnia minuta nasłuchu trafia na dysk po pauzie '
                        '(bufor pierścieniowy).'
                    : 'Każdy plik z rotacji zostaje na dysku (~1,9 MB / minutę).',
                style: const TextStyle(fontSize: 11),
              ),
              value: _keepRec,
              onChanged: (bool v) => setState(() => _keepRec = v),
            ),
            if (_fileReport.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.amber[50],
                  child: Text(_fileReport,
                      style: const TextStyle(fontSize: 12, height: 1.3)),
                ),
              ),
            if (_recordings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Brak nagrań — włącz „Zapisuj nagrania" i mów przez chwilę.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
            else ...[
              Text(
                'Ikona lupy rozpoznaje nagranie PONOWNIE, bieżącym trybem '
                'słownika — tak porównasz tryb poleceń z ogólnym na tym samym '
                'dźwięku.',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              ..._recordings.map(_recordingTile),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        await _stopPlayback();
                        for (final File f in List<File>.from(_recordings)) {
                          _usunPlik(f.path);
                        }
                        await _loadRecordings();
                      },
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Usuń wszystkie nagrania',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _recordingTile(File f) {
    final bool playing = _playingPath == f.path;
    final int bytes = _size(f);
    final int kb = bytes ~/ 1024;
    // Czas trwania z rozmiaru pliku (16-bit mono). Częstotliwość bierzemy
    // z nazwy pliku, bo nagrania bywają robione przy różnych ustawieniach.
    final RegExp rateInName = RegExp(r'_(\d+)k_');
    final Match? m = rateInName.firstMatch(f.path.split('/').last);
    final int fileRate =
        m == null ? _rate : (int.tryParse(m.group(1)!) ?? 16) * 1000;
    final double sec = (bytes - 44) / (fileRate * 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        Row(
          children: [
            IconButton(
              tooltip: playing ? 'Zatrzymaj' : 'Odtwórz',
              icon: Icon(
                playing ? Icons.stop_circle : Icons.play_circle,
                size: 32,
                color: playing ? Colors.red : Colors.green[700],
              ),
              onPressed: _busy ? null : () => _togglePlay(f),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.path.split('/').last.replaceFirst('vosk_', ''),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${sec.toStringAsFixed(1)} s   $kb kB',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Rozpoznaj ponownie',
              icon: const Icon(Icons.search, size: 20),
              onPressed: (_busy || !_modelReady) ? null : () => _analyzeFile(f),
            ),
            IconButton(
              tooltip: 'Udostępnij',
              icon: const Icon(Icons.share, size: 20),
              onPressed: () => _shareRecording(f),
            ),
            IconButton(
              tooltip: 'Usuń',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: _busy ? null : () => _deleteRecording(f),
            ),
          ],
        ),
        if (playing)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: _playDur.inMilliseconds == 0
                      ? null
                      : _playPos.inMilliseconds / _playDur.inMilliseconds,
                  minHeight: 4,
                ),
                const SizedBox(height: 2),
                Text('${_mmss(_playPos)} / ${_mmss(_playDur)}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POC Vosk-PL (test)'),
        actions: [
          IconButton(
            tooltip: 'Usuń model',
            onPressed: _busy ? null : _deleteModel,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status
          Card(
            color: Colors.blueGrey[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      Expanded(
                        child: Text(_status,
                            style:
                                const TextStyle(fontSize: 14, height: 1.3)),
                      ),
                    ],
                  ),
                  if (_modelPath.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _modelPath,
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          _listenBar(),
          const SizedBox(height: 8),

          // Tryb słownika — zawężona gramatyka to testowane rozwiązanie
          // docelowe, dlatego jest domyślnie włączona.
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Tryb poleceń (gramatyka pasieki)',
                style: TextStyle(fontSize: 13)),
            subtitle: Text(
                _useGrammar
                    ? 'Słownik zawężony do '
                        '${_commandWords.length + _numberWords.length} słów '
                        '+ [unk] zamiast 244 tys.'
                    : 'Pełny słownik modelu (244 tys. słów).',
                style: const TextStyle(fontSize: 11)),
            value: _useGrammar,
            onChanged: (_busy || !_modelReady)
                ? null
                : (bool v) => _restart(() async {
                      _useGrammar = v;
                      await _makeRecognizer();
                    }),
          ),

          // Alias „nakrop" — ma sens tylko przy zawężonej gramatyce.
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Alias: „nakrop" jako „na grób"',
                style: TextStyle(fontSize: 13)),
            subtitle: const Text(
                'Słowa „nakrop" nie ma w słowniku modelu — model słyszy je jako '
                '„na grób" (17/17 na nagraniach, pewność 1,00). Wyłącz, żeby '
                'sprawdzić, czy alias nie podnosi liczby fałszywych trafień.',
                style: TextStyle(fontSize: 11)),
            value: _nakropTest,
            onChanged: (_busy || !_modelReady || !_useGrammar)
                ? null
                : (bool v) => _restart(() async {
                      _nakropTest = v;
                      _nakropTrafien = 0;
                      await _makeRecognizer();
                    }),
          ),

          _zrodloPicker(),
          _devicePicker(),
          _ratePicker(),
          _bufferPicker(),
          _gainPicker(),

          // Obróbka sygnału przez iOS.
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Obróbka sygnału przez iOS:',
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _micChip(MicMode.surowy, 'surowy'),
                    _micChip(MicMode.voiceProcessing, 'voice processing'),
                    _micChip(MicMode.voiceProcessingAgc, 'v. proc. + AGC'),
                  ],
                ),
                Text(
                  'AGC = automatyczna regulacja wzmocnienia Apple.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          _commandPanel(),
          const SizedBox(height: 8),

          _diagnostics(),
          const SizedBox(height: 8),

          _recordingsPanel(),
          const SizedBox(height: 12),

          // Ostatni domknięty wynik — surowy tekst z Vosk, przed bramką.
          const Text('Ostatnia fraza z Vosk (surowo):',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            _finalText.isEmpty ? '—' : _finalText,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
