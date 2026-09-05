import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../globals.dart' as globals;

/// Helper do odtwarzania dźwięków w sterowania głosowym.
/// Dźwięki odtwarzane przez kanał mediów (głośność kontrolowana suwakiem Media Volume).
/// Każdy dźwięk ma osobną głośność (0.0 - 1.0) konfigurowalną w [volumes].
class SoundHelper {
  static final SoundHelper _instance = SoundHelper._internal();
  factory SoundHelper() => _instance;
  SoundHelper._internal();

  final Map<String, AudioPlayer> _players = {};
  bool _initialized = false;

  /// Sygnał potwierdzenia komendy - trzymany OSOBNO, poza [soundNames].
  ///
  /// Po co osobno: [soundNames] to lista odzywek Mai, po której iteruje ekran
  /// "Sterowanie głosem" budując suwaki głośności. Sygnał nie jest odzywką i nie
  /// ma tam czego robić - to znak techniczny, który ma być zawsze słyszalny.
  ///
  /// Ten odtwarzacz to WYJŚCIE AWARYJNE. Normalnie gra dźwięk systemowy przez
  /// [_kanalSygnalu]; z pliku gramy dopiero wtedy, gdy kanał nie odpowie.
  /// `listening.wav` trwa 0,15 s i - jak każdy sygnał w tym miejscu - NIE JEST
  /// MOWĄ, więc nawet gdy przecieknie do mikrofonu, Vosk nie zbuduje z niego
  /// frazy.
  AudioPlayer? _beepPlayer;

  /// Plik zapasowego sygnału. Wbudowany `listening.wav` to czysta sinusoida
  /// 433 Hz (0,15 s, cichnie do zera na obu końcach), więc trzask, który słychać
  /// na Androidzie, bierze się z rozruchu odtwarzacza, a nie z nagrania.
  ///
  /// [_plikSygnaluWlasny] jest po to, żeby dało się podłożyć własny dźwięk BEZ
  /// ruszania kodu: wystarczy wrzucić `assets/audio/beep.mp3` i odkomentować
  /// jego linię w `pubspec.yaml` (jest tam, obok `listening.wav`). Gdy pliku nie
  /// ma - [init] cofa się do wbudowanego i nic się nie psuje.
  static const String _plikSygnaluWlasny = 'audio/beep.mp3';
  static const String _plikSygnaluWbudowany = 'audio/listening.wav';
  String _plikSygnalu = _plikSygnaluWbudowany;

  /// Kanał do natywnego dźwięku systemowego, obsługiwany po obu stronach:
  /// iOS - `AudioServicesPlaySystemSound(1116)` w `AppDelegate.swift`,
  /// Android - `ToneGenerator` w `MainActivity.kt`.
  ///
  /// Zastąpił pakiet `flutter_beep` (14.08.2026), który robił dokładnie to samo,
  /// ale nie przechodził już buildu Androida od AGP 8. Dźwięk na iOS został ten
  /// sam - `iOSSoundIDs.JBL_NoMatch` to była stała 1116.
  static const MethodChannel _kanalSygnalu = MethodChannel('hej_maja/sygnal');

  /// Czy kanał systemowy w ogóle ISTNIEJE w tym buildzie. Wyłączamy go na stałe
  /// WYŁĄCZNIE po `MissingPluginException`, czyli gdy natywnej strony nie ma -
  /// wtedy każde kolejne potwierdzenie komendy kosztowałoby wyjątek.
  ///
  /// Odmowa samego dźwięku (zajęta ścieżka audio) NIE wyłącza kanału: to stan
  /// chwilowy i po następnej komendzie ton zwykle gra. Do 15.08.2026 gasiła go
  /// na stałe i jedna nieudana próba skazywała całą sesję na plik z dysku.
  bool _kanalSygnaluIstnieje = true;

  /// Powód, dla którego kanał został wyłączony na stałe - pamiętany, żeby
  /// pokazywać go przy każdym kolejnym sygnale, a nie tylko przy pierwszym.
  String _powodBezKanalu = '';

  /// Co się stało przy ostatnim sygnale potwierdzenia - do pokazania w
  /// ustawieniach sterowania głosem (przycisk „Sprawdź sygnał").
  ///
  /// Po co: z telefonu WSZYSTKIE porażki brzmią identycznie - słychać plik.
  /// „Build sprzed dodania kanału", „ToneGenerator odmówił" i „ton zagrał, ale
  /// media są wyciszone" wymagają trzech różnych ruchów, a rozróżnić je można
  /// tylko tutaj.
  String ostatniSygnal = 'jeszcze nie grał';

  /// Nazwy dźwięków (publiczne - do iteracji w UI).
  ///
  /// Lista buduje suwaki głośności na ekranie „Sterowanie głosem" i decyduje,
  /// co [init] wczytuje do pamięci.
  ///
  /// 'open' (okej.mp3) SCHOWANY 19.08.2026: potwierdzenie przyjęcia polecenia
  /// gra od 14.08.2026 sygnałem systemowym (`beep('open')` ustawia tylko flagę
  /// `_pendingOpenBeep`, a `_flushPendingOpenBeep` woła [beep]), więc suwak nie
  /// wpływał na nic. Plik, jego wpis w [_soundFiles], głośność w [volumes]
  /// i etykieta `soundOpen` zostają - powrót do odzywki to odkomentowanie
  /// jednej linii poniżej i przywrócenie `_zagraj('open')` w `_playSuccess()`.
  static const List<String> soundNames = [
    'wake_word',
    'start',
    'listening',
    'success',
    //'open',
    'close',
    'error',
    'nie_rozumiem',
    'nie_tutaj',
  ];

  /// Katalogi z odzywkami Mai - JEDNA nazwa pliku, dwa nagrania.
  ///
  /// Polskie leżą tam, gdzie zawsze (`assets/audio/`), angielskie w podkatalogu
  /// `assets/audio/en/`, pod DOKŁADNIE tymi samymi nazwami (`slucham.mp3`
  /// itd.). Dzięki temu dorzucenie nagrań angielskich nie wymaga ani linii
  /// kodu, ani wpisu w `pubspec.yaml` - katalog jest tam zgłoszony w całości.
  ///
  /// Komplet angielski nagrano 05.09.2026 - dziewięć plików, ten sam serwis
  /// co polskie (24 kHz / 160 kb/s / mono), wszystkie krótsze od polskich
  /// odpowiedników. Szczegóły i teksty: assets/audio/en/README.txt.
  ///
  /// Nazwy plików zostają POLSKIE także po angielsku świadomie: to klucze
  /// [_soundFiles], a nie treść. Przemianowanie ich znaczyłoby przepisanie
  /// [soundNames], [volumes], etykiet `sound*` w 7 plikach ARB i `case`
  /// w `voice_settings_screen` - za to, że plik nazywa się „ładniej".
  static const String _katalogPl = 'audio';
  static const String _katalogEn = 'audio/en';

  /// Katalog, z którego odtwarzacze mają WCZYTANE źródła. Pusty = jeszcze nic.
  /// Po zmianie języka w Ustawieniach [init] przestawia źródła na nowy katalog,
  /// zamiast tworzyć odtwarzacze od nowa.
  String _katalogWczytany = '';

  /// Katalog odzywek dla AKTUALNEGO języka aplikacji. Bramka głosu w
  /// `apiarys_screen` przepuszcza tylko `pl_PL` i `en_US`, więc każdy inny
  /// język i tak nigdy tu nie trafi - ale gdyby trafił, dostanie polskie
  /// nagrania, czyli to samo, co dostawał przed tą zmianą.
  static String get _katalogOdzywek =>
      globals.jezyk == 'en_US' ? _katalogEn : _katalogPl;

  /// Mapowanie nazw dźwięków na pliki MP3.
  static const Map<String, String> _soundFiles = {
    'wake_word': 'slucham.mp3',
    'start': 'czekam_na_polecenia.mp3',
    'listening': 'czekam.mp3',
    'success': 'zapisalam.mp3',
    'open': 'okej.mp3',
    'close': 'zamkniete.mp3',
    'error': 'blad.mp3',
    'nie_rozumiem': 'nie_rozumiem.mp3',
    'nie_tutaj': 'nie_tutaj.mp3',
  };

  /// Czym zastąpić odzywkę, dla której brakuje nagrania - SIATKA
  /// BEZPIECZEŃSTWA, nie stan docelowy.
  ///
  /// 'nie_tutaj' rozdzielono od 'nie_rozumiem' 05.09.2026, bo jeden plik
  /// obsługiwał dwa różne znaczenia: „zrozumiałam, ale nie w tym miejscu"
  /// (43 wywołania `beep('error')` w switchu pasiecznym) i „nie zrozumiałam
  /// treści notatki" (zapis notatki bez rozpoznanego tekstu). Kod rozdzielono
  /// ZANIM powstały nagrania i przez kilka godzin grał tu stary plik - wpis
  /// zostaje, żeby brak nagrania nigdy nie oznaczał ciszy w pasiece.
  static const Map<String, String> _plikZapasowy = {
    'nie_tutaj': 'nie_rozumiem.mp3',
  };

  /// Głośności poszczególnych dźwięków (0.0 - 1.0).
  /// Można zmieniać w runtime.
  final Map<String, double> volumes = {
    'wake_word': 1.0,
    'start': 0.9,
    'listening': 0.7,
    'success': 0.9,
    'open': 0.8,
    'close': 0.8,
    'error': 1.0,
    'nie_rozumiem': 0.9,
    'nie_tutaj': 0.9,
  };

  /// Główna głośność (mnożnik dla wszystkich dźwięków).
  double masterVolume = 1.0;

  /// Inicjalizacja - preload wszystkich dźwięków + odczyt zapisanych głośności.
  /// Wywołać raz w initState ekranu voice lub parametryzacji.
  Future<void> init() async {
    // Język mógł się zmienić w Ustawieniach OD OSTATNIEGO wejścia na ekran
    // głosowy - wtedy odtwarzacze trzymają jeszcze nagrania poprzedniego
    // języka. Wychodzimy dopiero, gdy wczytany katalog zgadza się z aktualnym.
    final String katalog = _katalogOdzywek;
    if (_initialized && katalog == _katalogWczytany) return;
    for (final name in soundNames) {
      final player = _players[name] ?? AudioPlayer();
      await _ustawZrodloOdzywki(player, name, katalog);
      await player.setReleaseMode(ReleaseMode.stop);
      _players[name] = player;
    }
    _katalogWczytany = katalog;
    //reszta jest niezależna od języka - przy samej zmianie języka nie ma po co
    if (_initialized) return;
    final beep = AudioPlayer();
    // Własny plik ma pierwszeństwo, wbudowany jest zawsze na miejscu. Brak
    // assetu leci z `rootBundle` jako błąd (nie wyjątek), stąd `catch (_)` bez
    // typu - inaczej ustawienie źródła wywróciłoby całe init() i zamilkłyby
    // TAKŻE odzywki Mai.
    try {
      await beep.setSource(AssetSource(_plikSygnaluWlasny));
      _plikSygnalu = _plikSygnaluWlasny;
    } catch (_) {
      await beep.setSource(AssetSource(_plikSygnaluWbudowany));
      _plikSygnalu = _plikSygnaluWbudowany;
    }
    await beep.setReleaseMode(ReleaseMode.stop);
    _beepPlayer = beep;
    await loadVolumes();
    _initialized = true;
  }

  /// Źródło JEDNEJ odzywki, z cofaniem się po kolejnych kandydatach.
  ///
  /// Kolejność: nagranie w języku aplikacji -> jego zamiennik z [_plikZapasowy]
  /// W TYM SAMYM języku -> nagranie polskie -> polski zamiennik. Język trzyma
  /// pierwszeństwo nad dokładnością znaczenia: angielskie „I don't understand"
  /// jest w angielskiej sesji mniej mylące niż poprawne, ale polskie
  /// „Nie tutaj".
  ///
  /// Cofanie jest tu po to, żeby zmiany w kodzie nie musiały czekać na studio -
  /// tak powstało rozdzielenie 'nie_tutaj' od 'nie_rozumiem' i katalog
  /// angielski (05.09.2026, oba wpięte przed nagraniami). Brak pliku wraca
  /// z `rootBundle` jako błąd, nie wyjątek - stąd `catch (_)` bez typu.
  ///
  /// OSTATNI kandydat leci BEZ łapania: gdyby padł, to nie jest brakujące
  /// nagranie, tylko rozjechany `pubspec.yaml` - i lepiej, żeby było to widać
  /// od razu, a nie jako cicha cisza w pasiece.
  Future<void> _ustawZrodloOdzywki(
    AudioPlayer player,
    String name,
    String katalog,
  ) async {
    final String plik = _soundFiles[name]!;
    final String? zapas = _plikZapasowy[name];
    final List<String> kandydaci = <String>[
      if (katalog != _katalogPl) ...<String>[
        '$katalog/$plik',
        if (zapas != null) '$katalog/$zapas',
      ],
      '$_katalogPl/$plik',
      if (zapas != null) '$_katalogPl/$zapas',
    ];
    for (int i = 0; i < kandydaci.length - 1; i++) {
      try {
        await player.setSource(AssetSource(kandydaci[i]));
        return;
      } catch (_) {
        debugPrint('SoundHelper: brak „${kandydaci[i]}" - próbuję dalej');
      }
    }
    await player.setSource(AssetSource(kandydaci.last));
  }

  /// Krótki sygnał potwierdzenia przyjęcia komendy (patrz [_beepPlayer]).
  ///
  /// Jak [play]: NIE RZUCA. Sygnał jest ozdobą - jego awaria nie ma prawa
  /// przerwać tego, co ekran głosowy właśnie robi.
  ///
  /// NAJPIERW dźwięk systemowy: krótszy, czystszy i - co ważniejsze na
  /// Androidzie - nie prosi systemu o audio focus. Odebranie focusu pauzuje
  /// nagrywanie w pakiecie `record`, czyli sterowanie głosem ogłuchłoby po
  /// każdej komendzie (ta sama przyczyna, co w rundzie 3 w ANDROID_GLOS.md).
  /// Dopiero gdy kanał odmówi - wracamy do pliku [_plikSygnalu], z głośnością
  /// z [masterVolume] (to nie odzywka, nie ma własnego suwaka).
  ///
  /// Odpowiedź kanału czytamy jako OPIS: Android zwraca tekst mówiący, którą
  /// drogą poszedł sygnał (patrz `MainActivity.zagrajSygnal`), iOS - samo
  /// `true`. Umowa jest jedna: „ok" na początku znaczy „zagrało". Wynik ląduje
  /// w [ostatniSygnal], bo z telefonu nie da się tego wyczytać inaczej.
  Future<void> beep() async {
    // Opis budujemy w ZMIENNEJ LOKALNEJ, a do [ostatniSygnal] wkładamy dopiero
    // gotowy. Doklejanie do pola dawałoby napis rosnący z każdą komendą, gdy
    // kanał jest wyłączony na stałe (jego powód nie zmienia się już nigdy).
    String opis = _powodBezKanalu;
    if (_kanalSygnaluIstnieje) {
      try {
        // Typ `Object`, nie `bool` ani `String`: obie platformy odpowiadają
        // inaczej i typowanie na jedną z nich wywracałoby drugą na CastError -
        // czyli sygnał na iOS działałby „przez wyjątek".
        final Object? odpowiedz =
            await _kanalSygnalu.invokeMethod<Object>('beep');
        opis = odpowiedz is String
            ? odpowiedz
            : (odpowiedz == true
                ? 'ok: dźwięk systemowy'
                : 'brak: kanał zwrócił $odpowiedz');
        if (opis.startsWith('ok')) {
          ostatniSygnal = opis;
          return;
        }
        debugPrint('SoundHelper: systemowy sygnał - $opis');
      } on MissingPluginException catch (_) {
        // Kanału NIE MA w tej aplikacji. Na Androidzie znaczy to najczęściej
        // build sprzed dopisania MainActivity.kt - a że kanał wpina się przy
        // starcie silnika, hot restart tego nie naprawi, trzeba zbudować od nowa.
        _kanalSygnaluIstnieje = false;
        _powodBezKanalu = 'brak kanału natywnego - aplikacja zbudowana bez '
            'MainActivity.kt/AppDelegate.swift (potrzebny pełny rebuild, '
            'hot restart nie wystarczy)';
        opis = _powodBezKanalu;
        debugPrint('SoundHelper: $opis');
      } catch (e) {
        // Awaria przejściowa - kanał zostaje włączony, próbujemy przy następnej
        // komendzie.
        opis = 'błąd kanału: $e';
        debugPrint('SoundHelper: systemowy sygnał nie zagrał - $e');
      }
    }
    final player = _beepPlayer;
    if (player == null) {
      ostatniSygnal = '$opis → brak odtwarzacza zapasowego';
      return;
    }
    try {
      await player.setVolume(0.0); // wycisz przed seek, żeby nie było trzasku
      await player.seek(Duration.zero);
      await player.setVolume(masterVolume.clamp(0.0, 1.0));
      await player.resume();
      ostatniSygnal = '$opis → plik $_plikSygnalu';
    } catch (e) {
      ostatniSygnal = '$opis → plik $_plikSygnalu też nie zagrał: $e';
      debugPrint('SoundHelper: sygnał z pliku nie zagrał - $e');
    }
  }

  /// Odtwórz dźwięk po nazwie.
  ///
  /// TA METODA NIE RZUCA WYJĄTKÓW. Na iOS sesja audio jest wspólna z
  /// nagrywaniem mikrofonu (sterowanie głosem nasłuchuje bez przerwy), więc
  /// odtwarzacz potrafi odmówić posłuszeństwa w środku pracy ekranu. Odzywka
  /// jest ozdobą, a nie funkcją - jej awaria nie może przerwać tego, co ekran
  /// właśnie robi. Zgłoszenie z 03.08.2026: wyjątek z odzywki „słucham"
  /// wylatywał z _zacznijNotatke i całe wejście w dyktowanie notatki znikało
  /// bez śladu - bez ikony, bez komunikatu, z powrotem w tryb komend.
  Future<void> play(String name) async {
    final player = _players[name];
    if (player == null) return;
    final vol = (volumes[name] ?? 1.0) * masterVolume;
    try {
      await player.setVolume(0.0); // wycisz przed seek, żeby nie było trzasku
      await player.seek(Duration.zero);
      await player.setVolume(vol.clamp(0.0, 1.0));
      await player.resume();
    } catch (e) {
      debugPrint('SoundHelper: dźwięk „$name" nie zagrał - $e');
    }
  }

  /// Odtwórz dźwięk i POCZEKAJ, aż ucichnie.
  ///
  /// Potrzebne przy sterowaniu na Vosku: mikrofon nasłuchuje bez przerwy, więc
  /// na czas odzywki Mai trzeba go wyciszyć - a do tego trzeba wiedzieć, kiedy
  /// dźwięk się kończy (patrz VoskEngine.wyciszNaOdzywke).
  ///
  /// [limit] to bezpiecznik: gdyby odtwarzacz nie zgłosił końca (błąd sesji
  /// audio, przerwana wtyczka), i tak wracamy - inaczej mikrofon zostałby
  /// wyciszony na zawsze, czyli sterowanie głosem przestałoby działać po cichu.
  ///
  /// Tak samo jak [play]: NIE RZUCA. Ani błąd odtwarzania, ani zamknięty
  /// strumień zdarzeń odtwarzacza nie mają prawa przerwać pracy ekranu.
  Future<void> playAndWait(
    String name, {
    Duration limit = const Duration(seconds: 6),
  }) async {
    final player = _players[name];
    if (player == null) return;
    // Nasłuch na koniec PRZED startem - inaczej krótki dźwięk zdąży się
    // skończyć, zanim zdążymy się podpiąć, i czekalibyśmy do limitu.
    //
    // Błąd łapiemy PRZY ŹRÓDLE, nie dopiero przy await: gdy przyjdzie już po
    // upływie [limit], nie ma go kto odebrać i leci jako nieobsłużony wyjątek
    // asynchroniczny (w release nie widać go nawet w konsoli).
    //
    // WŁASNY async zamiast .catchError() na strumieniu: onPlayerComplete jest
    // zadeklarowany jako Stream<void>, ale W ŚRODKU to przefiltrowany
    // Stream<AudioEvent>, więc .first daje future o RZECZYWISTYM typie
    // Future<AudioEvent>. Timeout sprawdza typ onTimeout po tym typie
    // rzeczywistym i wywala „() => Null is not a subtype of
    // () => FutureOr<AudioEvent>" (log z 05.08.2026) - czyli playAndWait
    // wracał NATYCHMIAST i wyciszanie mikrofonu na czas odzywki Mai nie
    // działało. Ciało async daje prawdziwe Future<void> i problem znika.
    final Future<void> koniec = () async {
      try {
        await player.onPlayerComplete.first;
      } catch (e) {
        debugPrint('SoundHelper: koniec „$name" nie przyszedł - $e');
      }
    }();
    await play(name);
    try {
      await koniec.timeout(limit, onTimeout: () {});
    } catch (e) {
      debugPrint('SoundHelper: czekanie na koniec „$name" - $e');
    }
  }

  /// Zapisz głośności do SharedPreferences.
  Future<void> saveVolumes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_master_volume', masterVolume);
    for (final name in soundNames) {
      await prefs.setDouble('sound_vol_$name', volumes[name] ?? 1.0);
    }
  }

  /// Odczytaj głośności z SharedPreferences.
  Future<void> loadVolumes() async {
    final prefs = await SharedPreferences.getInstance();
    masterVolume = prefs.getDouble('sound_master_volume') ?? 1.0;
    for (final name in soundNames) {
      volumes[name] = prefs.getDouble('sound_vol_$name') ?? volumes[name]!;
    }
  }

  /// Zwolnij zasoby. Wywołać w dispose ekranu voice.
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    await _beepPlayer?.dispose();
    _beepPlayer = null;
    _initialized = false;
  }
}
