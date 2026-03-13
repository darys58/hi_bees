import 'package:audioplayers/audioplayers.dart';
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
  ];

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
  };

  /// Główna głośność (mnożnik dla wszystkich dźwięków).
  double masterVolume = 1.0;

  /// Inicjalizacja - preload wszystkich dźwięków + odczyt zapisanych głośności.
  /// Wywołać raz w initState ekranu voice lub parametryzacji.
  Future<void> init() async {
    if (_initialized) return;
    for (final name in soundNames) {
      final player = AudioPlayer();
      await player.setSource(AssetSource('audio/$name.wav'));
      await player.setReleaseMode(ReleaseMode.stop);
      _players[name] = player;
    }
    await loadVolumes();
    _initialized = true;
  }

  /// Odtwórz dźwięk po nazwie.
  Future<void> play(String name) async {
    final player = _players[name];
    if (player == null) return;
    final vol = (volumes[name] ?? 1.0) * masterVolume;
    await player.setVolume(0.0); // wycisz przed seek, żeby nie było trzasku
    await player.seek(Duration.zero);
    await player.setVolume(vol.clamp(0.0, 1.0));
    await player.resume();
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
