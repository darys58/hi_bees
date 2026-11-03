// Ustawienia → Sterowanie głosem → Rozmowy telefoniczne (03.11.2026).
//
// Jak odebrać rozmowę przychodzącą bez dotykania telefonu, gdy działa
// sterowanie głosem. Sama aplikacja tego NIE potrafi:
// - iOS nie daje zwykłej aplikacji dostępu do rozmów komórkowych (CallKit
//   obsługuje tylko VoIP tej aplikacji), a przy dzwonieniu system przerywa
//   sesję audio - Vosk nie usłyszałby "odbierz";
// - na Androidzie byłoby to możliwe (TelecomManager.acceptRingingCall), ale to
//   osobny temat - na razie tylko wskazówki z ustawień systemu.
// Stąd ekran z instrukcją funkcji systemowych, osobno dla iOS i Androida.
//
// Teksty PL/EN w kodzie, poza ARB - jak reszta voice_settings_screen: pozycja
// jest widoczna tylko przy globals.jezyk 'pl_PL' / 'en_US' (języki z modelem
// Vosk), więc tłumaczenia na pozostałe języki nie miałyby kogo obsłużyć.
// Plik identyczny w obu drzewach (hi_bees + heymaya) - nie importuje l10n.

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../globals.dart' as globals;

class VoiceCallsHelpScreen extends StatelessWidget {
  const VoiceCallsHelpScreen({super.key});

  static bool get _pl => globals.jezyk == 'pl_PL';

  /// Tytuł belki w Ustawieniach głosu i nagłówek tego ekranu.
  static String get tytul => _pl ? 'Rozmowy telefoniczne' : 'Phone calls';

  //--- teksty ---------------------------------------------------------------

  String get _wstep => Platform.isIOS
      ? (_pl
          ? 'Gdy ktoś dzwoni, iOS zabiera aplikacji mikrofon, więc Maja nie usłyszy polecenia „odbierz”. '
              'Rozmowę możesz jednak odebrać bez dotykania telefonu, korzystając z funkcji systemu iOS.'
          : 'When a call comes in, iOS takes the microphone away from the app, so Maya cannot hear “answer”. '
              'You can still answer without touching the phone using built-in iOS features.')
      : (_pl
          ? 'Aplikacja nie odbiera rozmów. Rozmowę możesz odebrać bez dotykania telefonu, korzystając z funkcji systemu Android. '
              'Nazwy i położenie opcji różnią się w zależności od producenta telefonu i wersji Androida.'
          : 'The app does not answer calls. You can answer without touching the phone using built-in Android features. '
              'Option names and locations differ between phone makers and Android versions.');

  List<_Punkt> get _punkty => Platform.isIOS ? _punktyIos : _punktyAndroid;

  List<_Punkt> get _punktyIos => _pl
      ? const [
          //Siri nie mówi po polsku - polecenia PO ANGIELSKU, "odbierz" nie działa
          //(sprawdzone przez usera 03.11.2026). "Ogłaszaj połączenia" NIE jest
          //potrzebne - "answer" odbiera także bez niej (test usera 03.11.2026),
          //a kto dzwoni, widać na ekranie. "Hey Siri, hang up" działa dopiero po
          //włączeniu Ustawienia → Siri → Kończenie połączeń (domyślnie wyłączone;
          //bez tego Siri w trakcie rozmowy nie przyjmuje poleceń) - test usera
          //03.11.2026, stąd uwaga w opisie punktu.
          _Punkt(
            'Odbieranie głosem przez Siri',
            'Ustawienia → Siri (Siri włączona, język angielski)',
            'Gdy telefon dzwoni, powiedz po angielsku „answer” (odbierz) albo „decline” (odrzuć). '
                'Siri nie obsługuje języka polskiego, więc „odbierz” nie zadziała.',
          ),
          _Punkt(
            'Automatyczne odbieranie',
            'Ustawienia → Dostępność → Dotyk → Odbieranie audio połączeń → Automatyczne odbieranie połączeń',
            'Telefon sam odbierze rozmowę po ustawionej liczbie sekund. '
                'Uwaga: odbiera każde połączenie – włączaj na czas pracy w pasiece.',
          ),
          _Punkt(
            'Rozłączanie głosem',
            'Ustawienia → Siri → Kończenie połączeń',
            'W trakcie rozmowy powiedz po angielsku „Hey Siri, hang up”. '
                'Uwaga: ta opcja jest domyślnie wyłączona – bez jej włączenia Siri w trakcie rozmowy nie przyjmuje poleceń.',
          ),
        ]
      : const [
          _Punkt(
            'Answer by voice with Siri',
            'Settings → Siri (Siri turned on)',
            'When the phone rings, say “answer” or “decline”.',
          ),
          _Punkt(
            'Auto-answer calls',
            'Settings → Accessibility → Touch → Call Audio Routing → Auto-Answer Calls',
            'The phone answers by itself after the set number of seconds. '
                'Note: it answers every call – turn it on while working in the apiary.',
          ),
          _Punkt(
            'Hang up by voice',
            'Settings → Siri → Call Hang Up',
            'During a call say “Hey Siri, hang up”. '
                'Note: this option is off by default – without it Siri does not accept commands during a call.',
          ),
        ];

  List<_Punkt> get _punktyAndroid => _pl
      ? const [
          _Punkt(
            'Szybkie frazy (Pixel i niektóre inne telefony)',
            'Ustawienia Asystenta Google → Szybkie frazy → Połączenia przychodzące',
            'Gdy telefon dzwoni, powiedz „odbierz” albo „odrzuć” – bez „Hej Google”. '
                'Jeśli polskie polecenie nie działa, powiedz po angielsku „answer” albo „decline”.',
          ),
          _Punkt(
            'Polecenia głosowe (Samsung)',
            'Telefon → Ustawienia → Odbieranie i kończenie połączeń → Odbieranie i odrzucanie poleceniami głosowymi',
            'Gdy telefon dzwoni, powiedz „odbierz” albo „odrzuć”. '
                'Jeśli polskie polecenie nie działa, powiedz po angielsku „answer” albo „reject”.',
          ),
          _Punkt(
            'Automatyczne odbieranie',
            'Telefon → Ustawienia → Odbieranie i kończenie połączeń → Automatyczne odbieranie',
            'Telefon sam odbierze rozmowę po kilku sekundach. Na wielu telefonach '
                'działa tylko ze słuchawkami. Uwaga: odbiera każde połączenie.',
          ),
        ]
      : const [
          _Punkt(
            'Quick phrases (Pixel and some other phones)',
            'Google Assistant settings → Quick phrases → Incoming calls',
            'When the phone rings, say “answer” or “decline” – no “Hey Google” needed.',
          ),
          _Punkt(
            'Voice commands (Samsung)',
            'Phone → Settings → Answering and ending calls → Answer and reject calls with voice commands',
            'When the phone rings, say “answer” or “reject”.',
          ),
          _Punkt(
            'Auto-answer',
            'Phone → Settings → Answering and ending calls → Answer automatically',
            'The phone answers by itself after a few seconds. On many phones this '
                'works only with headphones. Note: it answers every call.',
          ),
        ];

  //zgodnie z VoskEngine._probujWznowic: ponowienia bez limitu (co najwyżej
  //co 15 s), po przerwaniu powrót do CZUWANIA, nie do trybu komend
  String get _poRozmowie => _pl
      ? 'W czasie rozmowy Maja nie słucha poleceń. Po rozłączeniu sama wraca do nasłuchu (może to potrwać do kilkunastu sekund). '
          'Sesję otwórz ponownie poleceniem „hej maja start”.'
      : 'Maya does not listen for commands during a call. After you hang up she resumes listening by herself (this may take up to about 15 seconds). '
          'Open the session again with “hey maya start”.';

  //--- widok ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: Text(
          tytul,
          style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
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
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Text(_wstep, style: const TextStyle(fontSize: 15)),
          ),
          for (final p in _punkty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.tytul,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    //ścieżka w ustawieniach systemu - wyróżniona kolorem
                    Text(p.sciezka,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.blue)),
                    const SizedBox(height: 6),
                    Text(p.opis, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(_poRozmowie,
                style: const TextStyle(
                    fontSize: 14, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}

class _Punkt {
  final String tytul;
  final String sciezka;
  final String opis;
  const _Punkt(this.tytul, this.sciezka, this.opis);
}
