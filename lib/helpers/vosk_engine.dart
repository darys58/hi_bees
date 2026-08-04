// Warstwa WEJŚCIA sterowania głosowego na Vosku: mikrofon -> recognizer ->
// gramatyka -> VoskInference. Odpowiednik PicovoiceManager z voice_screen2.dart.
//
// PO CO OSOBNY PLIK
// voice_screen2.dart ma 10 tys. linii, z czego logika Picovoice była wpleciona
// w ekran i nie dało się jej ruszyć bez ruszania reszty. Tu warstwa wejścia
// stoi osobno: ekran dostaje gotowe zdarzenia (fraza, stan, błąd), a całe
// audio - bufory, kolejki, przerwania - siedzi w tej klasie.
//
// SKĄD TEN KOD
// Sprawdzona ścieżka audio z POC (lib/screens/vosk_poc_screen.dart), przebadana
// 26-29.07.2026: własny recorder `record` + acceptWaveformBytes na porcjach
// 0,2 s. NIE initSpeechService() z wtyczki - jej natywny mikrofon podaje na iOS
// próbki 48 kHz float do funkcji oczekującej int16. Konfiguracja mikrofonu jest
// tą, którą zmierzono jako działającą (16 kHz, surowy - bez echoCancel/AGC,
// wzmocnienie 1x, domyślny bufor): 0,38-0,46 % ciszy cyfrowej, zero dziur.
//
// TRZY RZECZY, KTÓRYCH NIE BYŁO W POC, a bez których nasłuch ciągły nie nadaje
// się do pracy w terenie:
//   1. DWIE GRAMATYKI. W czuwaniu recognizer zna WYŁĄCZNIE "hej maja start"
//      (6 fraz), więc rozmowa przy ulu nie ma jak otworzyć sesji. Dopiero po
//      starcie dostaje pełne 3078 fraz. Realizowane DWOMA recognizerami, nie
//      przełącznikiem setGrammar - powód przy _utworzRecognizery().
//   2. WYCISZENIE NA CZAS ODZYWEK MAI. Przy Rhino nie mieliśmy dostępu do
//      strumienia, więc mp3 z mową trzeba było wyciąć (patrz historia
//      wake-worda, 10.06.2026). Tu mikrofon jest nasz: na czas odtwarzania
//      przestajemy karmić recognizer i po wszystkim go resetujemy. Odzywki
//      wracają bez ograniczeń.
//   3. WATCHDOG BRAKU AUDIO. Telefon, Siri, budzik albo przejście w tło
//      zabierają mikrofon i strumień NIE wznawia się sam. Bez tego ekran
//      wyglądałby na żywy przy martwym mikrofonie - najgorszy możliwy wariant.
//
// DYKTOWANIE NOTATKI (03.08.2026) dokłada trzeci tryb: recognizer BEZ gramatyki
// (cały słownik modelu) plus drugi, jednofrazowy, karmiony tą samą porcją i
// pilnujący wyłącznie "hej maja". Osobny detektor, bo w modelu swobodnym nic tej
// frazy nie faworyzuje - wychodzi z niej "hej mają" albo "ej maja" i notatka
// nigdy by się nie domknęła. Limit twardy i cisza są drugim wyjściem, a KAŻDE
// zakończenie (także utrata mikrofonu) oddaje tekst ekranowi: utrata
// podyktowanej notatki jest gorsza niż notatka ucięta.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vosk_flutter_service/vosk_flutter_service.dart';

import 'vosk_grammar.dart';

/// Stan nasłuchu. Przejścia robi ekran (przez [VoskEngine.ustawTryb]) z JEDNYM
/// wyjątkiem: z [dyktowanie] silnik wraca do [komendy] sam, bo koniec notatki
/// wykrywa on, a nie ekran.
enum TrybNasluchu {
  /// Mikrofon wyłączony - ekran zamknięty, aplikacja w tle albo błąd.
  wylaczony,

  /// Mikrofon pracuje, ale recognizer zna tylko "hej maja start/stop".
  czuwanie,

  /// Pełna gramatyka - komendy pasieczne trafiają do apki.
  komendy,

  /// Dyktowanie notatki: recognizer BEZ gramatyki (cały słownik modelu), a
  /// koniec wypowiedzi wykrywa osobny recognizer-detektor. Patrz
  /// [VoskEngine.zacznijDyktowanie].
  dyktowanie,
}

/// Dlaczego dyktowanie się skończyło. Ekran zapisuje notatkę w KAŻDYM z tych
/// przypadków - utrata podyktowanego tekstu jest gorsza niż notatka za długa
/// albo ucięta.
enum PowodKoncaDyktowania {
  /// Użytkownik powiedział "hej maja" - przewidziane zakończenie.
  fraza,

  /// Cisza dłuższa niż [VoskEngine._ciszaKonczacaDyktowanie].
  cisza,

  /// Twardy limit długości notatki.
  limitCzasu,

  /// Mikrofon przepadł (telefon, Siri, tło) albo ekran się zamyka.
  przerwane,
}

/// Fraza domknięta przez Vosk, z werdyktem bramki i wynikiem parsera.
class VoskFraza {
  VoskFraza({
    required this.tekst,
    required this.inference,
    required this.przyjeta,
    required this.powod,
    required this.minConf,
    required this.sredniaConf,
    required this.unk,
    required this.sklejona,
  });

  /// Tekst tak, jak zwrócił go Vosk (po sklejeniu, jeśli do niego doszło).
  final String tekst;

  /// Wynik parsera gramatyki - to trafia do prettyPrintInference w ekranie.
  final VoskInference inference;

  /// Czy fraza przeszła bramkę. Odrzucone ekran ma IGNOROWAĆ po cichu.
  final bool przyjeta;

  /// Powód decyzji - do panelu diagnostycznego, nie do logiki.
  final String powod;

  /// Najniższa pewność słowa we frazie (-1 = Vosk nie podał).
  final double minConf;

  /// Średnia pewność słów we frazie (-1 = Vosk nie podał).
  final double sredniaConf;

  /// Ile słów Vosk uznał za spoza gramatyki.
  final int unk;

  /// Czy powstała ze sklejenia dwóch kolejnych wyników (Vosk tnie komendy).
  final bool sklejona;

  @override
  String toString() => '"$tekst" ${przyjeta ? "OK" : "odrzucona"} ($powod)';
}

class VoskEngine {
  VoskEngine({
    required this.gramatyka,
    this.onFraza,
    this.onPartial,
    this.onStan,
    this.onBlad,
    this.onDyktowanieTekst,
    this.onKoniecDyktowania,
    this.progPewnosci = 0.5,
    this.podlogaPewnosci = 0.2,
    this.oknoSklejania = const Duration(milliseconds: 1500),
  });

  /// Silnik-parser .yml. Ten sam obiekt generuje gramatykę dla recognizera
  /// i parsuje wynik - jedno źródło prawdy.
  final VoskGrammar gramatyka;

  /// Domknięta fraza (także odrzucona przez bramkę - ekran sam decyduje).
  final void Function(VoskFraza fraza)? onFraza;

  /// Tekst "w locie", w trakcie mówienia. Do podglądu, nie do logiki.
  final void Function(String tekst)? onPartial;

  /// Zmiana stanu silnika - opis dla użytkownika + bieżący tryb.
  final void Function(String opis, TrybNasluchu tryb)? onStan;

  /// Awaria, po której nasłuch nie działa (brak zgody, utrata mikrofonu).
  final void Function(String opis)? onBlad;

  /// Notatka w trakcie dyktowania - tekst domknięty do tej pory plus to, co
  /// Vosk słyszy w tej chwili. Osobno od [onPartial], bo tutaj surowy tekst
  /// JEST produktem i ekran ma go pokazywać zawsze, niezależnie od przełącznika
  /// diagnostyki (który ukrywa aliasy fonetyczne gramatyki komend).
  final void Function(String tekst)? onDyktowanieTekst;

  /// Koniec dyktowania. Tekst bywa pusty (nikt nic nie powiedział) - decyzję,
  /// czy zapisywać, podejmuje ekran.
  final void Function(String tekst, PowodKoncaDyktowania powod)?
      onKoniecDyktowania;

  /// Próg ŚREDNIEJ pewności słów we frazie. 0 = kryterium wyłączone.
  /// Średnia, a nie minimum: jedno przymulone słówko („z", „w", końcówka
  /// liczebnika) nie może wywalać komendy, którą parser rozpoznał w całości.
  final double progPewnosci;

  /// Twarda podłoga dla najsłabszego słowa - zabezpiecza przed frazą, w której
  /// jedno słowo jest praktycznie zgadnięte, a reszta ciągnie średnią w górę.
  final double podlogaPewnosci;

  /// Ile czekamy na drugą połowę rozciętej komendy.
  final Duration oknoSklejania;

  // Intencje sterujące sesją - w czuwaniu recognizer dostaje tylko je.
  static const Set<String> intencjeSesji = {'voiceStart', 'voiceStop'};

  // Mały model polski (~50 MB), pobierany raz i cache'owany na urządzeniu.
  static const String _modelUrl =
      'https://alphacephei.com/vosk/models/vosk-model-small-pl-0.22.zip';

  // 16 kHz - standard modeli Vosk. Porcja podawana do recognizera = 0,2 s.
  static const int _rate = 16000;
  static const int _chunkBytes = (_rate ~/ 5) * 2;

  // Po tylu sekundach bez ani jednej porcji audio uznajemy mikrofon za utracony.
  static const Duration _limitCiszy = Duration(seconds: 3);

  // Odstępy kolejnych prób odzyskania mikrofonu. Rosnące, bo najczęstszą
  // przyczyną utraty jest ROZMOWA TELEFONICZNA - a ta trwa minuty, nie sekundy.
  // Trzy szybkie próby (tak było do 02.08.2026) wypalały się w ~9 s, czyli na
  // starcie rozmowy, i silnik poddawał się na dobre: po odłożeniu słuchawki
  // ekran był martwy, trzeba było z niego wyjść i wejść ponownie.
  // Ostatni odstęp obowiązuje w kółko - nie ma limitu prób.
  static const List<Duration> _odstepyPonowien = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
  ];

  // Po tylu nieudanych próbach mówimy o tym użytkownikowi. Wcześniej nie ma po
  // co - krótkie przerwania (Siri, powiadomienie) wracają za pierwszym razem.
  static const int _probDoKomunikatu = 3;

  // Ogon wyciszenia po odzywce - bufory audio iOS oddają dźwięk z opóźnieniem,
  // więc odblokowanie dokładnie w chwili końca mp3 wpuściłoby jego końcówkę.
  static const Duration _ogonWyciszenia = Duration(milliseconds: 300);

  // -- dyktowanie notatki ---------------------------------------------------

  // Fraza kończąca notatkę. To samo "hej maja", które otwiera sesję - użytkownik
  // ma pamiętać JEDNO zawołanie, nie dwa. W dyktowaniu wyłapuje ją osobny
  // recognizer, dla którego jest ona CAŁĄ gramatyką (patrz _karmDyktowanie):
  // w wolnym modelu nic jej nie faworyzuje i wychodzi jako "hej mają" albo
  // "ej maja", więc szukanie jej w podyktowanym tekście jest tylko zapasem.
  static const String _frazaKonca = 'hej maja';

  // Twardy limit długości notatki. Dyktowanie zdejmuje barierę, dzięki której
  // rozmowa przy ulu nie wchodzi do aplikacji - nie może więc trwać bez końca,
  // gdyby fraza kończąca przepadła.
  static const Duration _limitDyktowania = Duration(seconds: 90);

  // Cisza kończąca notatkę - drugie wyjście, gdy "hej maja" nie zostanie
  // usłyszane. Liczona od ostatniego USŁYSZANEGO słowa.
  static const Duration _ciszaKonczacaDyktowanie = Duration(seconds: 5);

  // Cisza PRZED pierwszym słowem notatki. Dłuższa (jest czas na zebranie myśli),
  // ale skończona: bez niej użytkownik, który nic nie powiedział, czekał na
  // jakąkolwiek reakcję do twardego limitu, czyli 90 sekund. Tak właśnie
  // wyglądało zgłoszenie z 03.08.2026 - „Słucham i nic więcej się nie dzieje".
  static const Duration _ciszaPrzedPierwszymSlowem = Duration(seconds: 12);

  // Karencja na frazę kończącą. Bufor wejściowy iOS oddaje dźwięk z OPÓŹNIENIEM
  // (zmierzone 02.08.2026 na odzywce "okej", która wracała z Vosk jako fraza),
  // więc końcówka wypowiedzianego przed chwilą "hej maja zanotuj" potrafi wpaść
  // już do dyktowania. Detektor zna WYŁĄCZNIE "hej maja", więc dopasowałby ją
  // z pewnością 1,00 i zamknął notatkę, zanim użytkownik zdąży cokolwiek
  // powiedzieć - z zewnątrz nie do odróżnienia od "dyktowanie nie działa".
  static const Duration _karencjaTerminatora = Duration(milliseconds: 1500);

  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  final AudioRecorder _recorder = AudioRecorder();

  Model? _model;

  // Dwa gotowe recognizery zamiast jednego przełączanego w locie. Oba stoją na
  // tym samym modelu, karmiony jest zawsze dokładnie jeden - ten w _recognizer.
  Recognizer? _recCzuwanie;
  Recognizer? _recKomendy;

  // Dyktowanie: recognizer BEZ gramatyki (goły tekst) + detektor frazy
  // kończącej. Oba budowane z góry razem z pozostałymi - recognizer bez
  // gramatyki powstaje natychmiast (nie ma grafu do zbudowania), a detektor ma
  // jedną frazę, więc wejście w dyktowanie nie zacina ekranu.
  Recognizer? _recDyktowanie;
  Recognizer? _recDetektor;

  // Ślad po nieudanej budowie recognizerów notatki i po odmowie wejścia w
  // dyktowanie. Bez tego ekran umie powiedzieć tylko „niedostępne", a to za
  // mało, żeby cokolwiek naprawić po teście na urządzeniu.
  String? _bladBudowyDyktowania;
  String? _bladBudowyDetektora;
  String? _powodOdmowyDyktowania;

  Recognizer? _recognizer;

  StreamSubscription<Uint8List>? _audioSub;
  Timer? _watchdog;

  final BytesBuilder _bufor = BytesBuilder(copy: false);
  bool _karmienie = false; // jedno wywołanie kanału naraz
  bool _nagrywa = false;

  TrybNasluchu _tryb = TrybNasluchu.wylaczony;
  bool _gotowy = false;
  String _partial = '';

  // Wyciszenie na czas odzywki. Licznik, a nie flaga - dźwięki potrafią się
  // nakładać, a każdy odblokowywałby mikrofon w środku poprzedniego.
  int _wyciszenia = 0;
  bool _ogonTrwa = false; // dogrywka po ostatnim dźwięku
  Timer? _timerOgona;

  // Trwa podmiana recognizera - porcje z tego czasu są wyrzucane, żeby nie
  // trafiły w recognizer w środku zmiany.
  bool _zmianaGramatyki = false;

  // Sklejanie rozciętych komend.
  String _ogon = '';
  DateTime? _ogonOCzasie;

  // Dyktowanie: tekst domknięty do tej pory + znaczniki czasu do limitów.
  final StringBuffer _notatka = StringBuffer();
  DateTime? _dyktowanieOd;
  DateTime? _ostatniaMowa;

  // Koniec dyktowania wykryty w środku pętli karmienia. Samego zakończenia NIE
  // wykonujemy w pętli: przełączenie recognizera czeka na koniec karmienia, a
  // my siedzielibyśmy w tej chwili właśnie w nim.
  PowodKoncaDyktowania? _zadanieKonca;

  // Trwa domykanie notatki. Karmienie musi na ten czas stanąć: _zakonczDyktowanie
  // woła getFinalResult, a jednoczesne acceptWaveform na tym samym recognizerze
  // to dwa nakładające się wywołania kanału (patrz _poczekajNaKarmienie).
  bool _konczeDyktowanie = false;

  DateTime? _ostatniaPorcja;
  bool _wznawianie = false;
  int _proboWznowienia = 0;
  Timer? _timerPonowienia;
  bool _brakZgody = false; // jedyna przyczyna, która nie minie sama

  // Poziom sygnału do wskaźnika na ekranie (0..1).
  double _poziom = 0;

  TrybNasluchu get tryb => _tryb;
  bool get gotowy => _gotowy;
  bool get nagrywa => _nagrywa;
  bool get wyciszony => _wyciszenia > 0 || _ogonTrwa;
  double get poziom => _poziom;
  String get partial => _partial;
  bool get dyktuje => _tryb == TrybNasluchu.dyktowanie;

  /// Czy dyktowanie w ogóle jest możliwe. Detektor frazy kończącej NIE jest do
  /// tego potrzebny - bez niego "hej maja" wyłapujemy z podyktowanego tekstu.
  bool get dyktowanieGotowe => _recDyktowanie != null;

  /// Dlaczego ostatnie [zacznijDyktowanie] się nie udało. Ekran ma to pokazać:
  /// „notatka nie działa" bez powodu nie daje się zdiagnozować na urządzeniu,
  /// a do konsoli Xcode użytkownik zagląda rzadko.
  String? get powodOdmowyDyktowania => _powodOdmowyDyktowania;

  // -- cykl życia -----------------------------------------------------------

  /// Pobiera model (raz), tworzy recognizer i zaczyna słuchać w [czuwanie].
  /// Zwraca false, gdy nasłuch nie ruszył - opis poszedł już przez [onBlad].
  Future<bool> uruchom() async {
    if (_gotowy) return _nagrywa;
    try {
      _stan('Przygotowuję rozpoznawanie mowy...');
      final String storage = await _katalogModelu();
      final ModelLoader loader = ModelLoader(modelStorage: storage);
      // Pobranie tylko za pierwszym razem - potem ModelLoader widzi katalog.
      _stan('Pobieram model języka polskiego (~50 MB, tylko raz)...');
      final String sciezka = await loader.loadFromNetwork(_modelUrl);

      _stan('Ładuję model...');
      _model = await _vosk.createModel(sciezka);
      await _utworzRecognizery();
      _gotowy = _recCzuwanie != null && _recKomendy != null;
    } catch (e) {
      _blad('Nie udało się przygotować rozpoznawania mowy.\n$e');
      return false;
    }
    if (!_gotowy) {
      _blad('Nie udało się utworzyć recognizera Vosk.');
      return false;
    }
    return wznow();
  }

  /// Wznawia nasłuch w czuwaniu (start ekranu, powrót z tła, po przerwaniu).
  ///
  /// [cicho] = nieudana próba nie zapala błędu na ekranie. Tak wznawiają
  /// automatyczne ponowienia: przy rozmowie telefonicznej mikrofon JEST zajęty
  /// i to jest stan normalny, a nie awaria do zgłoszenia użytkownikowi.
  Future<bool> wznow({bool cicho = false}) async {
    if (!_gotowy || _nagrywa) return _nagrywa;
    if (!await _recorder.hasPermission()) {
      // To jedyna naprawdę terminalna przyczyna - sama nie minie, więc jako
      // jedyna wyłącza automatyczne ponawianie.
      _brakZgody = true;
      _blad('Brak zgody na mikrofon.\niOS: Ustawienia → Hi Bees → Mikrofon.');
      return false;
    }
    _brakZgody = false;
    try {
      await _przelaczGramatyke(TrybNasluchu.czuwanie);
      await _startStrumienia();
    } catch (e) {
      if (cicho) {
        _stan('Mikrofon zajęty. Próbuję dalej...');
      } else {
        _blad('Nie udało się uruchomić mikrofonu.\n$e');
      }
      return false;
    }
    _nagrywa = true;
    _tryb = TrybNasluchu.czuwanie;
    _ostatniaPorcja = DateTime.now();
    // UWAGA: licznika prób NIE zerujemy tutaj. Rekorder potrafi wystartować
    // "poprawnie" i nie oddać ani jednej porcji - wtedy zerowanie tutaj dawałoby
    // wznawianie w kółko co 3 s, bez żadnego komunikatu. Licznik kasuje dopiero
    // fizycznie odebrany dźwięk (patrz _porcja).
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) => _sprawdzMikrofon());
    _stan('Czuwam. Powiedz „hej maja start", żeby zacząć.');
    return true;
  }

  /// Wznowienie ŚWIADOME: powrót ekranu na wierzch albo dotknięcie ikony przez
  /// użytkownika. Kasuje historię nieudanych prób, więc backoff rusza od zera -
  /// inaczej po długiej rozmowie czekalibyśmy jeszcze 15 s mimo wolnego
  /// mikrofonu.
  Future<bool> wznowOdNowa() async {
    _timerPonowienia?.cancel();
    _timerPonowienia = null;
    _proboWznowienia = 0;
    if (_nagrywa) return true;
    final bool ok = await wznow();
    if (!ok && !_brakZgody) {
      // Nie udało się TERAZ - ale mikrofon zwolni się sam, gdy skończy się
      // rozmowa. Bez tego ręczna próba byłaby jednorazowa.
      _proboWznowienia = 1;
      _zaplanujPonowienie('Mikrofon zajęty.');
    }
    return ok;
  }

  /// Zatrzymuje nagrywanie, ale zostawia model w pamięci (przejście w tło).
  Future<void> wstrzymaj() async {
    _timerPonowienia?.cancel();
    _timerPonowienia = null;
    if (!_nagrywa) return;
    _watchdog?.cancel();
    _watchdog = null;
    await _audioSub?.cancel();
    _audioSub = null;
    _nagrywa = false;
    try {
      await _recorder.stop();
    } catch (_) {
      // Rekorder mógł już paść razem z sesją audio - nie ma czego ratować.
    }
    await _poczekajNaKarmienie();
    _bufor.clear();
    _porzucOgon();
    // Mikrofon przepadł albo ekran się zamyka w środku dyktowania - to, co
    // użytkownik zdążył podyktować, oddajemy ekranowi do zapisania. Utrata
    // notatki jest gorsza niż notatka ucięta w pół zdania.
    if (_tryb == TrybNasluchu.dyktowanie) {
      await _zakonczDyktowanie(
        PowodKoncaDyktowania.przerwane,
        wrocDoKomend: false,
      );
    }
    try {
      await _recognizer?.reset();
    } catch (_) {}
    _tryb = TrybNasluchu.wylaczony;
    _stan('Nasłuch wstrzymany.');
  }

  /// Zwalnia wszystko. Po tym silnik nadaje się już tylko do wyrzucenia.
  Future<void> zamknij() async {
    _timerOgona?.cancel();
    await wstrzymaj();
    try {
      await _recorder.dispose();
    } catch (_) {}
    await _zwolnijRecognizery();
    _model?.dispose();
    _model = null;
    _gotowy = false;
  }

  // -- tryby ----------------------------------------------------------------

  /// Przełącza gramatykę recognizera. [TrybNasluchu.wylaczony] tu nie działa -
  /// od tego jest [wstrzymaj].
  Future<void> ustawTryb(TrybNasluchu nowy) async {
    if (nowy == _tryb || nowy == TrybNasluchu.wylaczony || !_nagrywa) return;
    // Wyjście z dyktowania inną drogą niż koniec notatki (ręczne zamknięcie
    // sesji) - podyktowany tekst i tak oddajemy ekranowi, żeby nie przepadł.
    if (_tryb == TrybNasluchu.dyktowanie) {
      await _zakonczDyktowanie(
        PowodKoncaDyktowania.przerwane,
        wrocDoKomend: false,
      );
    }
    await _przelaczGramatyke(nowy);
    _tryb = nowy;
    _porzucOgon();
    _stan(_opisTrybu(nowy));
  }

  String _opisTrybu(TrybNasluchu t) {
    switch (t) {
      case TrybNasluchu.komendy:
        return 'Słucham komend.';
      case TrybNasluchu.dyktowanie:
        return 'Dyktuj notatkę. Zakończ słowami „hej maja".';
      case TrybNasluchu.czuwanie:
      case TrybNasluchu.wylaczony:
        return 'Czuwam. Powiedz „hej maja start", żeby zacząć.';
    }
  }

  // -- dyktowanie notatki ---------------------------------------------------

  /// Wchodzi w dyktowanie. Zwraca false, gdy się nie da - nie ma otwartej sesji
  /// komend albo recognizery dyktowania nie powstały przy starcie. Ekran ma to
  /// wtedy zakomunikować użytkownikowi, bo cisza wyglądałaby jak zignorowana
  /// komenda.
  Future<bool> zacznijDyktowanie() async {
    _powodOdmowyDyktowania = null;
    if (!_nagrywa) {
      _powodOdmowyDyktowania = 'mikrofon nie nagrywa';
      return false;
    }
    if (_tryb != TrybNasluchu.komendy) {
      _powodOdmowyDyktowania = 'tryb ${_tryb.name}, nie komendy';
      return false;
    }
    // Druga szansa: recognizer bez gramatyki powstaje natychmiast (nie ma grafu
    // do zbudowania), więc gdy przy starcie ekranu coś mu przeszkodziło, próba
    // tutaj nic nie kosztuje - a bywa różnicą między działającą a martwą
    // notatką. Detektor dobudowujemy przy okazji, ale jego brak nie blokuje.
    if (_recDyktowanie == null && _model != null) {
      try {
        _recDyktowanie = await _nowyRecognizer(TrybNasluchu.dyktowanie);
        _bladBudowyDyktowania = null;
        debugPrint('VoskEngine: recognizer notatki dobudowany w locie.');
      } catch (e) {
        _bladBudowyDyktowania = '$e';
        debugPrint('VoskEngine: dobudowa recognizera notatki nie wyszła: $e');
      }
    }
    if (_recDetektor == null && _recDyktowanie != null && _model != null) {
      try {
        _recDetektor = await _nowyRecognizerZGramatyka(
          const <String>[_frazaKonca, '[unk]'],
        );
        _bladBudowyDetektora = null;
      } catch (e) {
        _bladBudowyDetektora = '$e';
        debugPrint('VoskEngine: dobudowa detektora nie wyszła: $e');
      }
    }
    // Detektor NIE jest wymagany - bez niego frazę kończącą wyłapuje
    // _karmDyktowanie z samego tekstu. Wymagany jest sam recognizer notatki.
    if (_recDyktowanie == null) {
      _powodOdmowyDyktowania =
          'brak recognizera notatki (${_bladBudowyDyktowania ?? "nie powstał"})';
      return false;
    }
    _notatka.clear();
    _partial = '';
    _dyktowanieOd = DateTime.now();
    _ostatniaMowa = null;
    _zadanieKonca = null;
    try {
      // Detektor mógł zostać z resztkami poprzedniej notatki - inaczej pierwsza
      // porcja domknęłaby starą frazę i notatka skończyłaby się natychmiast.
      await _recDetektor?.reset();
      await _recDyktowanie?.reset();
    } catch (_) {}
    await _przelaczGramatyke(TrybNasluchu.dyktowanie);
    if (_recognizer != _recDyktowanie) {
      _powodOdmowyDyktowania = 'nie udało się podmienić recognizera';
      return false; // podmiana się nie udała
    }
    _tryb = TrybNasluchu.dyktowanie;
    _porzucOgon();
    if (_recDetektor == null) {
      debugPrint('VoskEngine: notatka bez detektora '
          '(${_bladBudowyDetektora ?? "nie powstał"}) - „$_frazaKonca" '
          'wyłapywane z tekstu.');
    }
    debugPrint('VoskEngine: dyktowanie START '
        '(detektor: ${_recDetektor != null ? "jest" : "brak"}).');
    _stan(_opisTrybu(TrybNasluchu.dyktowanie));
    _emitujNotatke();
    return true;
  }

  /// Ręczne przerwanie dyktowania - ekran podpina je pod ikonę nasłuchu, żeby
  /// niewysłuchane "hej maja" nie skazywało użytkownika na czekanie do limitu.
  /// Tekst NIE przepada: leci do [onKoniecDyktowania] jak przy zwykłym końcu.
  Future<void> przerwijDyktowanie() =>
      _zakonczDyktowanie(PowodKoncaDyktowania.przerwane);

  Future<void> _zakonczDyktowanie(
    PowodKoncaDyktowania powod, {
    bool wrocDoKomend = true,
  }) async {
    if (_tryb != TrybNasluchu.dyktowanie) return;
    try {
      // Ostatnia, jeszcze niedomknięta wypowiedź. Bez tego ginie końcówka
      // zdania - czyli dokładnie to, na czym użytkownik przestał mówić.
      _dopiszDoNotatki(
        _wyjmij(await _recDyktowanie?.getFinalResult(), 'text'),
      );
    } catch (_) {}
    _partial = '';
    final String tekst = _oczyscNotatke(_notatka.toString());
    _notatka.clear();
    _dyktowanieOd = null;
    _ostatniaMowa = null;
    _zadanieKonca = null;
    try {
      await _recDetektor?.reset();
    } catch (_) {}
    if (wrocDoKomend && _nagrywa) {
      await _przelaczGramatyke(TrybNasluchu.komendy);
      _tryb = TrybNasluchu.komendy;
      _porzucOgon();
      _stan(_opisTrybu(TrybNasluchu.komendy));
    }
    debugPrint('VoskEngine: koniec dyktowania (${powod.name}), '
        '${tekst.length} znaków.');
    onDyktowanieTekst?.call('');
    onKoniecDyktowania?.call(tekst, powod);
  }

  void _dopiszDoNotatki(String tekst) {
    final String t = tekst.trim();
    if (t.isEmpty) return;
    if (_notatka.isNotEmpty) _notatka.write(' ');
    _notatka.write(t);
    // Tekst z karencji to najczęściej echo komendy otwierającej (patrz
    // [_karencjaTerminatora]) - zapisujemy go, ale zegara ciszy nim nie ruszamy.
    if (!_wKarencji) _ostatniaMowa = DateTime.now();
  }

  void _emitujNotatke() {
    final String wLocie = _partial.trim();
    final String calosc =
        wLocie.isEmpty ? _notatka.toString() : '$_notatka $wLocie';
    //podgląd na ekranie czyścimy z tych samych ech co zapisywaną treść - inaczej
    //„słucham" wisi przez całe dyktowanie i wygląda jak część notatki. Ogona
    //(frazy kończącej) tu NIE tniemy: w locie „hej" bywa początkiem zwykłego
    //słowa i podgląd urywałby się w połowie zdania.
    onDyktowanieTekst?.call(_bezEchaZPrzodu(calosc).trim());
  }

  // Fraza kończąca bywa przepisana także przez recognizer notatki - i to w
  // formie przekręconej, bo w wolnym modelu nic jej nie faworyzuje. Ucinamy ją
  // z treści razem z ogonem, żeby "hej maja" nie zostało w zapisanej notatce.
  static final RegExp _ogonKonca = RegExp(
    r'\s*\b(hej|ej)\s+(maja|mają|maj|majo|maju)\b[\s\S]*$',
    caseSensitive: false,
  );

  // Echo komendy otwierającej na POCZĄTKU notatki. Ta sama przyczyna co
  // [_karencjaTerminatora] - opóźniony bufor wejściowy iOS. Bez wycięcia z
  // przodu notatka ginęłaby w całości: _ogonKonca tnie od pierwszego "hej maja"
  // do końca, a tutaj to "hej maja" stoi na samym początku.
  static final RegExp _echoOtwarcia = RegExp(
    r'^\s*((hej|ej)\s+(maja|mają|maj|majo|maju)\s+)?'
    r'(zanotuj|zapisz\s+notatk[ęe])\b',
    caseSensitive: false,
  );

  // Samo zawołanie na początku (bez czasownika) - też echo, nie treść.
  static final RegExp _echoZawolania = RegExp(
    r'^\s*(hej|ej)\s+(maja|mają|maj|majo|maju)\b',
    caseSensitive: false,
  );

  // Odzywka „słucham", którą Maja gra PRZED wejściem w dyktowanie. Mikrofon jest
  // na ten czas wyciszony, ale bufor wejściowy iOS oddaje dźwięk z opóźnieniem
  // większym niż ogon wyciszenia (ta sama przyczyna co [_karencjaTerminatora]),
  // więc słowo i tak wpada do notatki - zawsze na jej początku. Zgłoszone z
  // urządzenia 04.08.2026: KAŻDA notatka zaczynała się od „słucham".
  static final RegExp _echoOdzywki = RegExp(
    r'^\s*s[łl]ucham\b',
    caseSensitive: false,
  );

  // Echa z POCZĄTKU notatki: komenda otwierająca, zawołanie i odzywka Mai.
  // W PĘTLI, bo wpadają w różnych kombinacjach („zanotuj słucham", „słucham",
  // „hej maja zanotuj słucham") - pojedyncze przejście zdejmowałoby tylko część,
  // a reszta zostawałaby w treści notatki.
  String _bezEchaZPrzodu(String tekst) {
    String t = tekst;
    for (int i = 0; i < 6; i++) {
      final String przed = t;
      t = t
          .replaceFirst(_echoOtwarcia, '')
          .replaceFirst(_echoZawolania, '')
          .replaceFirst(_echoOdzywki, '');
      if (t == przed) break; //nic już nie schodzi - dalej jest treść
    }
    return t;
  }

  String _oczyscNotatke(String tekst) =>
      _bezEchaZPrzodu(tekst.replaceAll(RegExp(r'\[unk\]|<unk>'), ' '))
          .replaceFirst(_ogonKonca, '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  // Czy detektor usłyszał frazę kończącą. Zna WYŁĄCZNIE ją i [unk], więc
  // wystarczyłby sam tekst - ale pewność sprawdzamy i tak, bo przy
  // jednofrazowej gramatyce Vosk chętnie dopasowuje do niej przypadkowy dźwięk.
  bool _toTerminator(dynamic wynik) {
    final Map<String, dynamic> m = _json(wynik);
    if (!(m['text'] ?? '').toString().contains(_frazaKonca)) return false;
    double min = -1;
    for (final dynamic w in (m['result'] as List<dynamic>?) ?? const []) {
      if (w is Map && w['conf'] != null) {
        final double c = (w['conf'] as num).toDouble();
        if (min < 0 || c < min) min = c;
      }
    }
    return min < 0 || min >= podlogaPewnosci;
  }

  // -- wyciszenie na czas odzywek Mai ---------------------------------------

  /// Woływane PRZED odtworzeniem dźwięku. Od tej chwili porcje z mikrofonu są
  /// wyrzucane, więc Maja nie usłyszy samej siebie.
  void wyciszNaOdzywke() {
    _wyciszenia++;
    _timerOgona?.cancel();
    _timerOgona = null;
    _ogonTrwa = false;
  }

  /// Woływane po zakończeniu odtwarzania. Mikrofon wraca po ogonie, a stan
  /// recognizera jest resetowany - to, co zdążyło wpaść, nie jest komendą.
  void wznowPoOdzywce() {
    if (_wyciszenia == 0) return;
    _wyciszenia--;
    if (_wyciszenia > 0) return; // gra jeszcze inny dźwięk
    _ogonTrwa = true;
    _timerOgona?.cancel();
    _timerOgona = Timer(_ogonWyciszenia, () async {
      _ogonTrwa = false;
      _bufor.clear();
      _porzucOgon();
      try {
        await _recognizer?.reset();
      } catch (_) {}
      _ostatniaPorcja = DateTime.now(); // cisza z wyciszenia to nie awaria
    });
  }

  // -- środek: audio --------------------------------------------------------

  Future<String> _katalogModelu() async {
    // Jawna, zapisywalna ścieżka: domyślna wpada na iOS w read-only katalog
    // procesu (FileSystemException errno 30). Application Support nie idzie
    // do backupu iCloud - 50 MB modelu nie ma po co tam lądować.
    final Directory base = await getApplicationSupportDirectory();
    final Directory dir = Directory('${base.path}/vosk_models');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  // DLACZEGO DWA RECOGNIZERY, A NIE setGrammar
  // Wtyczka wystawia Recognizer.setGrammar, ale na iOS to ślepy zaułek:
  // - w VoskFlutterPlugin.swift nie ma case'a "recognizer.setGrammar"
  //   (stąd MissingPluginException przy wejściu na ekran, 01.08.2026),
  // - i nie da się go dopisać, bo zwendorowane libvosk 0.3.45 dla iOS w ogóle
  //   NIE eksportuje vosk_recognizer_set_grm (sprawdzone na obu archiwach
  //   xcframework - jest tylko vosk_recognizer_new_grm).
  // Zostaje droga z POC, przetestowana na urządzeniu: gramatykę podaje się przy
  // TWORZENIU recognizera. Budujemy więc oba z góry i przełączamy wskaźnik.
  // Efekt uboczny na plus: przebudowa grafu dekodowania (sekundy przy 3078
  // frazach) dzieje się raz, przy starcie ekranu, a nie przy każdym
  // "hej maja start".
  Future<void> _utworzRecognizery() async {
    await _zwolnijRecognizery();
    if (_model == null) return;
    _recCzuwanie = await _nowyRecognizer(TrybNasluchu.czuwanie);
    _stan('Buduję gramatykę komend...');
    _recKomendy = await _nowyRecognizer(TrybNasluchu.komendy);
    _recognizer = _recCzuwanie;
    // Para do dyktowania. Osobno i BEZ przerywania startu przy niepowodzeniu:
    // brak dyktowania ma wyłączyć jedną komendę, a nie całe sterowanie głosem.
    //
    // KAŻDY Z DWÓCH OSOBNO: to nie jest komplet "wszystko albo nic". Bez
    // recognizera notatki dyktowania nie ma w ogóle, ale bez detektora frazy
    // kończącej notatka nadal działa - "hej maja" wyłapujemy wtedy z tekstu
    // (patrz _karmDyktowanie). Wspólny catch wyłączał notatkę także wtedy, gdy
    // padał wyłącznie detektor.
    _bladBudowyDyktowania = null;
    _bladBudowyDetektora = null;
    try {
      _recDyktowanie = await _nowyRecognizer(TrybNasluchu.dyktowanie);
    } catch (e) {
      _recDyktowanie = null;
      _bladBudowyDyktowania = '$e';
      debugPrint('VoskEngine: recognizer dyktowania nie powstał: $e');
    }
    try {
      _recDetektor = await _nowyRecognizerZGramatyka(
        const <String>[_frazaKonca, '[unk]'],
      );
    } catch (e) {
      _recDetektor = null;
      _bladBudowyDetektora = '$e';
      debugPrint('VoskEngine: detektor „$_frazaKonca" nie powstał: $e');
    }
  }

  Future<Recognizer> _nowyRecognizer(TrybNasluchu t) =>
      _nowyRecognizerZGramatyka(_gramatykaDla(t));

  // grammar == null schodzi we wtyczce do vosk_recognizer_new zamiast
  // vosk_recognizer_new_grm - czyli model bez ograniczeń (dyktowanie).
  // Sprawdzone na iOS 03.08.2026, na obu poziomach naraz, bo sama metoda w
  // Darcie niczego nie dowodzi (lekcja z setGrammar, 01.08.2026):
  //   - VoskFlutterPlugin.swift, case "recognizer.create" - jawnie obsługuje
  //     brak klucza "grammar",
  //   - symbol _vosk_recognizer_new JEST w libvosk.a (oba plastry xcframework).
  Future<Recognizer> _nowyRecognizerZGramatyka(List<String>? gram) async {
    final Recognizer r = await _vosk.createRecognizer(
      model: _model!,
      sampleRate: _rate,
      grammar: gram,
    );
    try {
      // Pewność per słowo - bez tego bramka traci jedno z trzech kryteriów.
      await r.setWords(words: true);
    } catch (_) {
      // Starsza wtyczka bez setWords - bramka zadziała na pozostałych.
    }
    return r;
  }

  Future<void> _zwolnijRecognizery() async {
    _recognizer = null;
    for (final Recognizer? r in <Recognizer?>[
      _recCzuwanie,
      _recKomendy,
      _recDyktowanie,
      _recDetektor,
    ]) {
      try {
        await r?.dispose();
      } catch (_) {
        // Wtyczka mogła już paść razem z sesją - nie ma czego ratować.
      }
    }
    _recCzuwanie = null;
    _recKomendy = null;
    _recDyktowanie = null;
    _recDetektor = null;
  }

  List<String>? _gramatykaDla(TrybNasluchu t) {
    // Dyktowanie to jedyny tryb bez gramatyki - notatki nie da się z góry
    // opisać listą fraz. Cena jest znana i przyjęta: model small-pl w trybie
    // swobodnym myli słowa pszczelarskie (patrz komentarze w pol_vosk.yml),
    // więc tekst ma przypominać, co użytkownik miał na myśli, a nie być
    // protokołem. Poprawia się go w ekranie notatek.
    if (t == TrybNasluchu.dyktowanie) return null;
    return <String>[
      ...(t == TrybNasluchu.komendy
          ? gramatyka.frazy()
          : gramatyka.frazy(intencje: intencjeSesji)),
      // Pozwala Voskowi powiedzieć „to nie jest komenda" zamiast dopasowywać
      // każdy dźwięk do najbliższej frazy.
      '[unk]',
    ];
  }

  Recognizer? _recognizerDla(TrybNasluchu t) {
    switch (t) {
      case TrybNasluchu.komendy:
        return _recKomendy;
      case TrybNasluchu.dyktowanie:
        return _recDyktowanie;
      case TrybNasluchu.czuwanie:
      case TrybNasluchu.wylaczony:
        return _recCzuwanie;
    }
  }

  Future<void> _przelaczGramatyke(TrybNasluchu t) async {
    final Recognizer? cel = _recognizerDla(t);
    if (cel == null) return;
    // Podmiana jest natychmiastowa, ale i tak wstrzymujemy karmienie: porcja
    // w locie nie może się rozjechać między dwa recognizery.
    _zmianaGramatyki = true;
    try {
      await _poczekajNaKarmienie();
      _bufor.clear();
      _recognizer = cel;
      // Nowo aktywowany recognizer ma w sobie stan sprzed poprzedniej zmiany -
      // resztki tamtej wypowiedzi nie mają się domknąć jako komenda.
      await cel.reset();
    } finally {
      _zmianaGramatyki = false;
      _ostatniaPorcja = DateTime.now(); // przerwa na podmianę to nie awaria
    }
  }

  Future<void> _startStrumienia() async {
    final Stream<Uint8List> stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _rate,
        numChannels: 1,
        // "Surowy" mikrofon - dokładnie ta konfiguracja została zmierzona jako
        // działająca. echoCancel/autoGain iOS potrafią wyciąć mowę do zera.
        echoCancel: false,
        noiseSuppress: false,
        autoGain: false,
      ),
    );
    _audioSub = stream.listen(
      _porcja,
      onError: (Object e) => _blad('Błąd strumienia audio:\n$e'),
      onDone: () {
        // Strumień zamknięty przez system (przerwanie sesji audio). Watchdog
        // i tak by to złapał, ale tu wiemy o tym natychmiast.
        if (_nagrywa) _utraconoMikrofon('Strumień audio zamknięty przez system.');
      },
    );
  }

  void _porcja(Uint8List chunk) {
    _ostatniaPorcja = DateTime.now();
    _proboWznowienia = 0; // dźwięk realnie dociera - mikrofon odzyskany
    // Odzywka Mai albo przebudowa gramatyki - porcji nie karmimy.
    if (wyciszony || _zmianaGramatyki) return;
    _zmierz(chunk);
    _bufor.add(chunk);
    _karm(); // bez await - kolejkowanie pilnuje flaga _karmienie
  }

  // Energia porcji (RMS, PCM 16-bit LE) w skali 0..1 - do wskaźnika na ekranie.
  void _zmierz(Uint8List chunk) {
    final int probek = chunk.length ~/ 2;
    if (probek == 0) return;
    final ByteData view = ByteData.sublistView(chunk, 0, probek * 2);
    double sumaKw = 0;
    for (int i = 0; i < probek; i++) {
      final int s = view.getInt16(i * 2, Endian.little);
      sumaKw += s.toDouble() * s.toDouble();
    }
    _poziom = math.sqrt(sumaKw / probek) / 32768.0;
  }

  Future<void> _karm() async {
    if (_karmienie || _konczeDyktowanie || _recognizer == null) return;
    _karmienie = true;
    try {
      while (_nagrywa && _bufor.length >= _chunkBytes) {
        // Recognizer bierzemy raz na obrót pętli: podmiana trybu w trakcie nie
        // może rozbić jednej porcji na dwa różne obiekty.
        final Recognizer? r = _recognizer;
        if (r == null || _zmianaGramatyki) break;
        final Uint8List all = _bufor.takeBytes();
        final Uint8List chunk = Uint8List.sublistView(all, 0, _chunkBytes);
        if (all.length > _chunkBytes) {
          _bufor.add(Uint8List.sublistView(all, _chunkBytes));
        }
        if (_tryb == TrybNasluchu.dyktowanie) {
          await _karmDyktowanie(r, chunk);
          if (_zadanieKonca != null) break;
          continue;
        }

        final bool koniecFrazy = await r.acceptWaveformBytes(chunk);
        if (koniecFrazy) {
          _przyjmijFraze(await r.getResult());
        } else {
          final String p = _wyjmij(await r.getPartialResult(), 'partial');
          if (p != _partial) {
            _partial = p;
            onPartial?.call(p);
          }
        }
      }
    } catch (e) {
      _blad('Błąd przetwarzania audio:\n$e');
    } finally {
      _karmienie = false;
    }

    // Koniec dyktowania domykamy DOPIERO TUTAJ, poza pętlą karmienia:
    // _przelaczGramatyke czeka na jej zakończenie, więc wywołany w środku
    // czekałby sam na siebie przez cały timeout.
    // Między wyzerowaniem _karmienie a ustawieniem _konczeDyktowanie nie ma
    // ani jednego await, więc żadna porcja nie zdąży się tu wcisnąć.
    final PowodKoncaDyktowania? powod = _zadanieKonca;
    if (powod != null) {
      _zadanieKonca = null;
      _konczeDyktowanie = true;
      try {
        await _zakonczDyktowanie(powod);
      } finally {
        _konczeDyktowanie = false;
      }
    }
  }

  // Ta sama porcja idzie do DWÓCH recognizerów: jeden pisze notatkę (bez
  // gramatyki), drugi pilnuje wyłącznie frazy kończącej. Dekodowanie po stronie
  // natywnej jest seryjne, więc koszt porcji rośnie mniej więcej dwukrotnie -
  // to jest ta liczba, którą trzeba zmierzyć na urządzeniu.
  Future<void> _karmDyktowanie(Recognizer r, Uint8List chunk) async {
    final Recognizer? det = _recDetektor;
    // W karencji frazy kończącej NIE SŁUCHAMY, ale porcje i tak podajemy -
    // detektor ma iść w takt notatki, a nie odtwarzać potem zaległe audio.
    final bool wolnoKonczyc = !_wKarencji;
    if (det != null && await det.acceptWaveformBytes(chunk)) {
      if (wolnoKonczyc && _toTerminator(await det.getResult())) {
        _zadanieKonca = PowodKoncaDyktowania.fraza;
        return;
      }
    }

    if (await r.acceptWaveformBytes(chunk)) {
      final String tekst = _wyjmij(await r.getResult(), 'text');
      _dopiszDoNotatki(tekst);
      _partial = '';
      _emitujNotatke();
      // Zapas na brak detektora: frazy szukamy w tym, co zapisał recognizer
      // notatki. Z treści i tak wypada - wycina ją _oczyscNotatke.
      if (det == null && wolnoKonczyc && _ogonKonca.hasMatch(tekst)) {
        _zadanieKonca = PowodKoncaDyktowania.fraza;
        return;
      }
    } else {
      final String p = _wyjmij(await r.getPartialResult(), 'partial');
      if (p != _partial) {
        _partial = p;
        // Echo komendy otwierającej z bufora iOS nie jest mową użytkownika -
        // gdyby ruszało zegar ciszy, notatka zamykałaby się 5 s po wejściu,
        // nawet jeśli użytkownik jeszcze zbiera myśli.
        if (p.trim().isNotEmpty && wolnoKonczyc) _ostatniaMowa = DateTime.now();
        _emitujNotatke();
        if (det == null && wolnoKonczyc && _ogonKonca.hasMatch(p)) {
          _zadanieKonca = PowodKoncaDyktowania.fraza;
          return;
        }
      }
    }

    final DateTime teraz = DateTime.now();
    if (_dyktowanieOd != null &&
        teraz.difference(_dyktowanieOd!) >= _limitDyktowania) {
      _zadanieKonca = PowodKoncaDyktowania.limitCzasu;
      return;
    }
    // Cisza liczona od ostatniego USŁYSZANEGO słowa, a przed pierwszym słowem -
    // od wejścia w dyktowanie, tylko z dłuższym oknem. Notatka MUSI się domknąć
    // sama w rozsądnym czasie także wtedy, gdy nikt nic nie powiedział: to
    // jedyny sygnał, że tryb notatki w ogóle się skończył.
    final DateTime? odkad = _ostatniaMowa ?? _dyktowanieOd;
    final Duration okno = _ostatniaMowa != null
        ? _ciszaKonczacaDyktowanie
        : _ciszaPrzedPierwszymSlowem;
    if (odkad != null && teraz.difference(odkad) >= okno) {
      _zadanieKonca = PowodKoncaDyktowania.cisza;
    }
  }

  // Czy jesteśmy jeszcze w karencji frazy kończącej (patrz
  // [_karencjaTerminatora]).
  bool get _wKarencji =>
      _dyktowanieOd != null &&
      DateTime.now().difference(_dyktowanieOd!) < _karencjaTerminatora;

  Future<void> _poczekajNaKarmienie() async {
    // Wywołania przez MethodChannel nie mogą się nakładać.
    for (int i = 0; i < 50 && _karmienie; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  // -- bramka i sklejanie ---------------------------------------------------

  void _przyjmijFraze(dynamic raw) {
    final Map<String, dynamic> map = _json(raw);
    final String tekst = (map['text'] ?? '').toString().trim();
    _partial = '';
    onPartial?.call('');
    if (tekst.isEmpty) return;

    // setWords -> {"result":[{"conf":1.0,"word":"ramka"}], "text":"..."}
    double minConf = -1;
    double sumaConf = 0;
    int ileConf = 0;
    for (final dynamic w in (map['result'] as List<dynamic>?) ?? const []) {
      if (w is Map && w['conf'] != null) {
        final double c = (w['conf'] as num).toDouble();
        if (minConf < 0 || c < minConf) minConf = c;
        sumaConf += c;
        ileConf++;
      }
    }
    final double sredniaConf = ileConf > 0 ? sumaConf / ileConf : -1;
    final List<String> tokeny = tekst.split(RegExp(r'\s+'));
    final int unk =
        tokeny.where((t) => t == '[unk]' || t == '<unk>' || t == 'unk').length;

    // Sklejanie: Vosk potrafi rozciąć komendę na dwie frazy (2 razy na 14 w
    // teście e2e). Jeśli poprzednia fraza nie dała się sparsować, a od jej
    // domknięcia nie minęło okno, próbujemy najpierw wersji sklejonej.
    String doParsowania = tekst;
    bool sklejona = false;
    if (_ogon.isNotEmpty && _ogonSwiezy) {
      final VoskInference proba = gramatyka.rozpoznaj('$_ogon $tekst');
      if (proba.isUnderstood == true) {
        doParsowania = '$_ogon $tekst';
        sklejona = true;
      }
    }
    _porzucOgon();

    final VoskInference inf = gramatyka.rozpoznaj(doParsowania);

    // Kolejność ma znaczenie: najpierw pytamy, CZY to w ogóle komenda (unk +
    // parser), a dopiero potem, jak pewnie została usłyszana. Dzięki temu
    // przymulona pierwsza połowa rozciętej komendy trafia do _ogona i ma szansę
    // na sklejenie, zamiast wylatywać wcześniej na samej pewności.
    bool przyjeta = true;
    String powod = 'przechodzi bramkę';
    final String opisConf = sredniaConf < 0
        ? ''
        : 'śr. ${sredniaConf.toStringAsFixed(2)}, '
            'min ${minConf.toStringAsFixed(2)}';
    if (unk > 0) {
      przyjeta = false;
      powod = 'poza gramatyką ($unk × [unk])';
    } else if (inf.isUnderstood != true) {
      przyjeta = false;
      powod = 'nie pasuje do żadnej komendy';
      // Może to być pierwsza połowa rozciętej komendy - przytrzymaj na okno.
      _ogon = doParsowania;
      _ogonOCzasie = DateTime.now();
    } else if (progPewnosci > 0 &&
        sredniaConf >= 0 &&
        (sredniaConf < progPewnosci || minConf < podlogaPewnosci)) {
      przyjeta = false;
      powod = 'niska pewność ($opisConf)';
    } else if (sklejona) {
      powod = 'przechodzi bramkę (sklejona z dwóch fraz)';
    }

    onFraza?.call(VoskFraza(
      tekst: doParsowania,
      inference: inf,
      przyjeta: przyjeta,
      powod: powod,
      minConf: minConf,
      sredniaConf: sredniaConf,
      unk: unk,
      sklejona: sklejona,
    ));
  }

  bool get _ogonSwiezy =>
      _ogonOCzasie != null &&
      DateTime.now().difference(_ogonOCzasie!) <= oknoSklejania;

  void _porzucOgon() {
    _ogon = '';
    _ogonOCzasie = null;
  }

  // -- watchdog -------------------------------------------------------------

  // Telefon, Siri, budzik albo przejście w tło zabierają mikrofon i strumień
  // NIE wznawia się sam. Cisza dłuższa niż _limitCiszy przy włączonym nasłuchu
  // znaczy, że nagrywanie padło - nie że w pasiece jest cicho (mikrofon zawsze
  // oddaje szum tła, porcje lecą 5 razy na sekundę niezależnie od dźwięku).
  Future<void> _sprawdzMikrofon() async {
    if (!_nagrywa || wyciszony || _zmianaGramatyki || _wznawianie) return;
    final DateTime? ostatnia = _ostatniaPorcja;
    if (ostatnia == null) return;
    if (DateTime.now().difference(ostatnia) <= _limitCiszy) return;
    await _utraconoMikrofon('Mikrofon zamilkł (rozmowa, Siri albo alarm).');
  }

  /// Reakcja watchdoga na ciszę. Pierwsze próby robimy NATYCHMIAST (krótkie
  /// przerwania - powiadomienie, Siri - wracają od razu), ale dalej oddajemy
  /// sprawę backoffowi. Inaczej przez całą rozmowę telefoniczną restartowaliśmy
  /// rekorder co 3 sekundy, bez najmniejszej szansy na powodzenie.
  Future<void> _utraconoMikrofon(String opis) async {
    if (_wznawianie) return;
    if (_proboWznowienia >= 2) {
      await wstrzymaj();
      if (!_brakZgody) _zaplanujPonowienie(opis);
      return;
    }
    await _probujWznowic(opis);
  }

  Future<void> _probujWznowic(String opis) async {
    if (_wznawianie) return;
    _wznawianie = true;
    _proboWznowienia++;
    try {
      await wstrzymaj(); // zatrzymuje też watchdoga i zaplanowane ponowienie
      if (_brakZgody) return;
      if (_proboWznowienia >= _probDoKomunikatu) {
        // Użytkownik ma prawo wiedzieć, że nie słuchamy - ale to NIE jest koniec
        // prób. Najczęstsza przyczyna (rozmowa telefoniczna) mija sama i wtedy
        // mikrofon wraca bez udziału użytkownika.
        _stan('$opis\nMikrofon jest zajęty. Próbuję dalej - wrócę sam, '
            'gdy się zwolni.');
      } else {
        _stan('$opis Wznawiam nasłuch...');
      }
      // Po przerwaniu WRACAMY DO CZUWANIA, nigdy do trybu komend: użytkownik
      // ma świadomie powiedzieć „hej maja start", żeby apka znów przyjmowała
      // komendy. Decyzja z 01.08.2026.
      if (await wznow(cicho: true)) return;
      // Rekorder nie ruszył (mikrofon wciąż zajęty) - bez watchdoga nikt by
      // nie spróbował ponownie, więc planujemy próbę sami.
      if (!_brakZgody) _zaplanujPonowienie(opis);
    } finally {
      _wznawianie = false;
    }
  }

  void _zaplanujPonowienie(String opis) {
    final int i = _proboWznowienia - 1;
    final Duration za = _odstepyPonowien[
        i < _odstepyPonowien.length ? i : _odstepyPonowien.length - 1];
    _timerPonowienia?.cancel();
    _timerPonowienia = Timer(za, () {
      if (!_gotowy || _nagrywa) return;
      _probujWznowic(opis); // po backoffie próbujemy naprawdę, bez zwłoki
    });
  }

  // -- drobiazgi ------------------------------------------------------------

  String _wyjmij(dynamic data, String klucz) {
    final Map<String, dynamic> m = _json(data);
    return (m[klucz] ?? '').toString();
  }

  Map<String, dynamic> _json(dynamic raw) {
    try {
      final dynamic d = jsonDecode(raw.toString());
      return d is Map<String, dynamic> ? d : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  void _stan(String opis) => onStan?.call(opis, _tryb);

  void _blad(String opis) {
    _stan(opis);
    onBlad?.call(opis);
  }
}
