import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper do odtwarzania dźwięków w sterowania głosowym.
/// Dźwięki odtwarzane przez kanał mediów (głośność kontrolowana suwakiem Media Volume).
/// Każdy dźwięk ma osobną głośność (0.0 - 1.0) konfigurowalną w [volumes].
class SoundHelper {
  static final SoundHelper _instance = SoundHelper._internal();
  factory SoundHelper() => _instance;
  SoundHelper._internal();

  final Map<String, AudioPlayer> _players = {};
  bool _initialized = false;

  /// Nazwy dźwięków (publiczne - do iteracji w UI).
  static const List<String> soundNames = [
    'wake_word',
    'start',
    'listening',
    'success',
    'open',
    'close',
    'error',
    'nie_rozumiem',
  ];

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
  };

  /// Główna głośność (mnożnik dla wszystkich dźwięków).
  double masterVolume = 1.0;

  /// Inicjalizacja - preload wszystkich dźwięków + odczyt zapisanych głośności.
  /// Wywołać raz w initState ekranu voice lub parametryzacji.
  Future<void> init() async {
    if (_initialized) return;
    for (final name in soundNames) {
      final player = AudioPlayer();
      await player.setSource(AssetSource('audio/${_soundFiles[name]}'));
      await player.setReleaseMode(ReleaseMode.stop);
      _players[name] = player;
    }
    await loadVolumes();
    _initialized = true;
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
    _initialized = false;
  }
}
