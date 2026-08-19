import 'package:flutter/material.dart';
import 'package:hi_bees/l10n/app_localizations.dart';
import '../globals.dart' as globals;
import '../helpers/sound_helper.dart';
import '../helpers/recording_helper.dart'; //nagrania dyktowanych notatek

/// Ustawienia sterowania głosem - wszystko, co dotyczy Mai: podgląd korpusu,
/// nagrywanie dyktowanych notatek i głośność odzywek.
///
/// OSOBNY EKRAN, a nie sekcja rozwijana w Parametryzacji - tak samo jak
/// "Aktualności ula" ([HiveNewsSettingsScreen]). W Parametryzacji zostaje sama
/// belka (tekst bez pogrubienia i bez ikony, strzałka po prawej), bo rozwinięte
/// ustawienia zajmowały pół ekranu (same suwaki dźwięków to kilkanaście
/// wierszy) i przesłaniały pozostałe pozycje listy.
///
/// Teksty pozycji są po polsku, poza plikami ARB - świadomie: sterowanie głosem
/// działa wyłącznie przy globals.jezyk == 'pl_PL' (mamy tylko polski model
/// Vosk), więc tłumaczenie nie miałoby kogo obsłużyć. Wyjątkiem są nazwy
/// dźwięków i nagłówek głośności, które w ARB już były.
class VoiceSettingsScreen extends StatefulWidget {
  static const routeName = '/voice-settings';

  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  //SoundHelper jest singletonem, a init() nie robi nic przy powtórnym
  //wywołaniu - ekran głosowy woła je u siebie, my tylko upewniamy się, że
  //zapisane głośności są wczytane, zanim pokażemy suwaki.
  final _sound = SoundHelper();
  bool _soundReady = false;

  //opis ostatniego sygnału potwierdzenia; null = jeszcze nie sprawdzano.
  //Pod komentarzem razem z pozycją "Sygnał potwierdzenia polecenia" (15.08.2026,
  //przed publikacją) - patrz komentarz przy tamtym Card w [build].
  // String? _opisSygnalu;

  @override
  void initState() {
    super.initState();
    _sound.init().then((_) {
      if (mounted) setState(() => _soundReady = true);
    });
  }

  //nazwa dźwięku do wyświetlenia (z ARB)
  String _soundLabel(BuildContext context, String name) {
    final l = AppLocalizations.of(context)!;
    switch (name) {
      case 'wake_word': return l.soundWakeWord;
      case 'start': return l.soundStart;
      case 'listening': return l.soundListening;
      case 'success': return l.soundSuccess;
      //'open' nie trafia już tutaj - pozycja jest schowana w
      //SoundHelper.soundNames (19.08.2026). Case i klucz `soundOpen` zostają,
      //żeby powrót suwaka nie wymagał dopisywania tłumaczeń w 7 językach.
      case 'open': return l.soundOpen;
      case 'close': return l.soundClose;
      case 'error': return l.soundError;
      case 'nie_rozumiem': return l.soundNieRozumiem;
      default: return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: const Text(
          'Sterowanie głosem',
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Podgląd korpusu na żywo zamiast podpowiedzi poleceń.
          // WYŁĄCZONY  -> podpowiedzi komend, ekran pionowy.
          // WŁĄCZONY   -> korpus aktualizowany na żywo, ekran poziomy.
          // Nazwa pozycji bez słowa "Live" - świadoma decyzja użytkownika,
          // opis ma być po polsku i mówić, co przełącznik robi.
          Card(
            child: ListTile(
              title: const Text('Podgląd korpusu w trakcie poleceń'),
              //zwykły Switch, NIE Switch.adaptive: .adaptive daje na iOS zielony
              //CupertinoSwitch, a Powiadomienia (SwitchListTile) są materiałowe
              trailing: Switch(
                value: globals.voice2LivePodglad,
                onChanged: (value) {
                  setState(() {
                    globals.voice2LivePodglad = value;
                  });
                },
              ),
            ),
          ),
          // DIAGNOSTYKA GŁOSU - przełącznik UKRYTY PONOWNIE 15.08.2026, przed
          // publikacją. Historia: ukryty 06.08.2026 jako tryb serwisowy
          // niepotrzebny na co dzień, odkomentowany 14.08.2026 na czas
          // uruchamiania Androida (bez niego zgłoszenie „komendy nie działają"
          // jest nie do rozstrzygnięcia z ekranu: odrzucona fraza jest
          // z założenia CICHA - patrz _opisFrazy w voice_vosk_screen - więc
          // „nie usłyszałam" i „usłyszałam, ale odrzuciłam" wyglądają
          // identycznie). Temat Androida zamknięty, więc wraca pod komentarz.
          //
          // Powód ukrywania na produkcji (patrz globals.voiceDiagnostyka):
          // gramatyka stoi na aliasach fonetycznych ("pierzcha", "węża",
          // "miodu branie", "na grób") i pokazanie ich wygląda na błąd aplikacji.
          //
          // Sama diagnostyka ZOSTAJE w kodzie i budzi się przez
          // globals.voiceDiagnostyka - wystarczy odkomentować ten Card.
          // Card(
          //   child: ListTile(
          //     title: const Text('Diagnostyka głosu'),
          //     subtitle: const Text(
          //         'Pokazuje rozpoznany tekst i pewność rozpoznania. Tekst bywa zapisany inaczej niż wypowiedziane słowo - to dopasowanie fonetyczne, nie błąd'),
          //     //zwykły Switch, NIE Switch.adaptive - jak pozostałe na tym ekranie
          //     trailing: Switch(
          //       value: globals.voiceDiagnostyka,
          //       onChanged: (value) {
          //         setState(() {
          //           globals.voiceDiagnostyka = value;
          //         });
          //       },
          //     ),
          //   ),
          // ),
          // Nagrywanie dyktowanych notatek. Obok tekstu zapisujemy ścieżkę
          // dźwiękową (WAV 16 kHz mono) i przypinamy ją do notatki - po to,
          // żeby dało się sprawdzić, co pszczelarz naprawdę powiedział, gdy
          // transkrypcja wyszła przekręcona. Nagrania NIE idą do chmury i
          // znikają po tygodniu albo razem z notatką (patrz RecordingHelper).
          Card(
            child: ListTile(
              title: const Text('Nagrywanie notatek'),
              subtitle: Text(
                  'Nagrania zostają na telefonie i kasują się po ${RecordingHelper.dniPrzechowywania} dniach'),
              //zwykły Switch, NIE Switch.adaptive: .adaptive daje na iOS zielony
              //CupertinoSwitch, a Powiadomienia (SwitchListTile) są materiałowe
              trailing: Switch(
                value: globals.nagrywajNotatki,
                onChanged: (value) {
                  setState(() {
                    globals.nagrywajNotatki = value;
                  });
                },
              ),
            ),
          ),
          // Wymuszenie układu poziomego dla live podglądu korpusu
          // (niezależnie od orientacji urządzenia).
          // Card(
          //   child: ListTile(
          //     title: Text('Voice 2 - układ poziomy'),
          //     subtitle: Text('Wymuś układ poziomy dla live podglądu korpusu (niezależnie od orientacji urządzenia)'),
          //     trailing: Switch.adaptive(
          //       value: globals.voice2LiveLandscape,
          //       onChanged: (value) {
          //         setState(() {
          //           globals.voice2LiveLandscape = value;
          //         });
          //       },
          //     ),
          //   ),
          // ),

          // SYGNAŁ POTWIERDZENIA POLECENIA - dźwięk systemowy (ToneGenerator na
          // Androidzie, AudioServicesPlaySystemSound na iOS), a dopiero gdy
          // system odmówi - plik z assetów. Sygnał NIE MA suwaka: to znak
          // techniczny, a nie odzywka Mai, i ma być zawsze słyszalny.
          //
          // POZYCJA UKRYTA 15.08.2026, przed publikacją - to narzędzie
          // serwisowe, nie ustawienie: pokazuje techniczny opis kanału
          // ("ok: ton na media", nazwy strumieni, treść wyjątku), czyli coś,
          // czego pszczelarz nie ma jak zinterpretować.
          //
          // Powstała, bo to jedyny sposób, żeby z telefonu dowiedzieć się,
          // KTÓRA z dróg zagrała - bez niej wszystkie porażki brzmią tak samo
          // (słychać plik) i nie wiadomo, czy to stary build, czy odmowa
          // systemu. Sam mechanizm ([SoundHelper.beep] i jego
          // [SoundHelper.ostatniSygnal]) ZOSTAJE nietknięty, więc przy kolejnej
          // diagnozie wystarczy odkomentować ten Card i pole [_opisSygnalu].
          // Card(
          //   child: ListTile(
          //     title: const Text('Sygnał potwierdzenia polecenia'),
          //     subtitle: Text(_opisSygnalu ??
          //         'Naciśnij dzwonek po prawej - powinien zabrzmieć krótki '
          //             'dźwięk systemowy. Pod spodem pokaże się, czym zagrał.'),
          //     trailing: IconButton(
          //       icon: const Icon(Icons.notifications_active_outlined, size: 28),
          //       tooltip: 'Sprawdź sygnał',
          //       onPressed: () async {
          //         await _sound.beep();
          //         if (!mounted) return;
          //         setState(() => _opisSygnalu = _sound.ostatniSygnal);
          //       },
          //     ),
          //   ),
          // ),

          // GŁOŚNOŚĆ ODZYWEK MAI. Suwaki pokazujemy dopiero po wczytaniu
          // zapisanych wartości - inaczej przez chwilę stałyby na wartościach
          // domyślnych i przesunięcie któregoś nadpisałoby ustawienia
          // użytkownika.
          if (_soundReady) ...[
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: Text(
                l.soundVolume,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // suwak głównej głośności
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l.masterVolume,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      value: _sound.masterVolume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: '${(_sound.masterVolume * 100).round()}%',
                      onChanged: (v) {
                        setState(() => _sound.masterVolume = v);
                      },
                      onChangeEnd: (_) => _sound.saveVolumes(),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text('${(_sound.masterVolume * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Divider(),
            // suwaki poszczególnych dźwięków
            ...SoundHelper.soundNames.map((name) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    // przycisk odtwarzania
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline, size: 28),
                      tooltip: l.soundPlay,
                      onPressed: () => _sound.play(name),
                    ),
                    // nazwa dźwięku
                    SizedBox(
                      width: 100,
                      child: Text(
                        _soundLabel(context, name),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    // suwak
                    Expanded(
                      child: Slider(
                        value: _sound.volumes[name] ?? 1.0,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        label: '${((_sound.volumes[name] ?? 1.0) * 100).round()}%',
                        onChanged: (v) {
                          setState(() => _sound.volumes[name] = v);
                        },
                        onChangeEnd: (_) => _sound.saveVolumes(),
                      ),
                    ),
                    // wartość %
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${((_sound.volumes[name] ?? 1.0) * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
