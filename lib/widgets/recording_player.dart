import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hi_bees/l10n/app_localizations.dart';
import '../helpers/recording_helper.dart';
import '../models/recording.dart';

/// Odtwarzacz nagrania dyktowanej notatki - do wstawienia przy treści notatki
/// (lista przeglądów, Notes) albo pod polem tekstowym na ekranie edycji.
///
/// Świadomie BEZ NAPISÓW: pokazuje ikony i czas ("0:03 / 0:07"), więc nie
/// potrzebuje tłumaczenia na siedem języków, a przy notatce i tak liczy się
/// jedno - czy da się odsłuchać, co użytkownik powiedział.
///
///  - stuknięcie      -> odtwarzanie / PAUZA (wznowienie od miejsca zatrzymania),
///  - kwadracik obok  -> zatrzymanie i powrót na początek,
///  - przytrzymanie   -> kasowanie nagrania (z pytaniem o potwierdzenie).
///
/// PAUZA, A NIE STOP (04.08.2026): przy poprawianiu dłuższej notatki odsłuchuje
/// się ją kawałkami - poprawka, powrót do dźwięku, kolejna poprawka. Odtwarzanie
/// zawsze od początku znaczyło, że przy każdej poprawce trzeba przeczekać całą
/// wcześniejszą część nagrania.
///
/// W wersji [zSuwakiem] (ekrany edycji, gdzie jest szerokość) dochodzi pasek
/// przewijania - można wrócić do jednego przekręconego słowa bez słuchania
/// reszty.
///
/// Sam plik może zniknąć niezależnie od wpisu w bazie (sprzątanie po
/// [RecordingHelper.dniPrzechowywania] dniach, aktualizacja aplikacji zmienia
/// katalog Documents na iOS). Wtedy ikonka jest przekreślona i szara zamiast
/// udawać, że jest czego słuchać.
class RecordingPlayer extends StatefulWidget {
  const RecordingPlayer({
    super.key,
    required this.nagranie,
    this.male = false,
    this.zSuwakiem = false,
  });

  final Recording nagranie;

  /// Wersja do wiersza z tekstem notatki (mniejsza ikona, bez tła).
  final bool male;

  /// Wersja z paskiem przewijania - zajmuje całą szerokość, więc tylko tam,
  /// gdzie nie stoi obok tekstu notatki (ekrany edycji).
  final bool zSuwakiem;

  @override
  State<RecordingPlayer> createState() => _RecordingPlayerState();
}

/// Stan odtwarzania. Trzy stany, a nie flaga "gra/nie gra" - pauza musi być
/// odróżnialna od zatrzymania, bo tylko ona zachowuje pozycję.
enum _Stan { stop, gra, pauza }

class _RecordingPlayerState extends State<RecordingPlayer> {
  AudioPlayer? _player;
  _Stan _stan = _Stan.stop;
  bool _brakPliku = false;

  /// Pozycja odtwarzania i długość nagrania. Długość bierzemy z odtwarzacza, ale
  /// do czasu jej poznania (albo gdy nagłówek WAV nie da rady) zostaje wartość z
  /// bazy - suwak musi mieć sensowny zakres od pierwszej klatki.
  Duration _pozycja = Duration.zero;
  Duration? _dlugosc;

  /// Przeciąganie suwaka: dopóki palec jedzie, pozycję rysujemy z suwaka, a nie
  /// ze strumienia odtwarzacza - inaczej uchwyt "ucieka" pod palcem.
  bool _przewijam = false;

  final List<StreamSubscription<dynamic>> _subskrypcje = [];

  Duration get _calosc =>
      _dlugosc ?? Duration(seconds: widget.nagranie.sekundy);

  @override
  void dispose() {
    //Odtwarzacz zwalniamy ZAWSZE, także w trakcie grania - element listy
    //potrafi zniknąć przy przewijaniu, a osierocony AudioPlayer grałby dalej.
    for (final StreamSubscription<dynamic> s in _subskrypcje) {
      s.cancel();
    }
    _subskrypcje.clear();
    _player?.dispose();
    _player = null;
    super.dispose();
  }

  /// Odtwarzacz powstaje przy pierwszym stuknięciu (element listy, który nigdy
  /// nie zagrał, nie ma po co trzymać zasobów audio). Strumienie podpinamy raz -
  /// razem z nim.
  AudioPlayer _odtwarzacz() {
    final AudioPlayer istniejacy = _player ?? AudioPlayer();
    if (_player != null) return istniejacy;
    _player = istniejacy;
    _subskrypcje.add(istniejacy.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _stan = _Stan.stop;
        _pozycja = Duration.zero;
      });
    }));
    _subskrypcje.add(istniejacy.onPositionChanged.listen((Duration d) {
      if (!mounted || _przewijam || _stan == _Stan.stop) return;
      setState(() => _pozycja = d);
    }));
    _subskrypcje.add(istniejacy.onDurationChanged.listen((Duration d) {
      if (!mounted || d <= Duration.zero) return;
      setState(() => _dlugosc = d);
    }));
    return istniejacy;
  }

  /// Stuknięcie w ikonę: start / pauza / wznowienie.
  Future<void> _przelacz() async {
    switch (_stan) {
      case _Stan.gra:
        await _pauza();
        return;
      case _Stan.pauza:
        await _wznow();
        return;
      case _Stan.stop:
        await _graj();
        return;
    }
  }

  Future<void> _graj({Duration? od}) async {
    try {
      final File f = await RecordingHelper.plik(widget.nagranie.sciezka);
      if (!await f.exists()) {
        if (mounted) setState(() => _brakPliku = true);
        return;
      }
      final AudioPlayer p = _odtwarzacz();
      await p.play(DeviceFileSource(f.path));
      //Przewinięcie PO starcie: play() zawsze rusza od zera, więc suwak
      //przesunięty przy zatrzymanym nagraniu ustawiamy dopiero teraz.
      if (od != null && od > Duration.zero) await p.seek(od);
      if (!mounted) return;
      setState(() {
        _stan = _Stan.gra;
        _pozycja = od ?? Duration.zero;
      });
    } catch (e) {
      //Sesja audio na iOS bywa zajęta (np. wróciliśmy prosto ze sterowania
      //głosem). To nie jest awaria notatki - notatka ma tekst i leży w bazie.
      debugPrint('Nagranie: nie udało się odtworzyć - $e');
      if (mounted) setState(() => _stan = _Stan.stop);
    }
  }

  Future<void> _pauza() async {
    try {
      await _player?.pause();
    } catch (e) {
      debugPrint('Nagranie: pauza - $e');
    }
    if (mounted) setState(() => _stan = _Stan.pauza);
  }

  Future<void> _wznow() async {
    try {
      await _player?.resume();
      if (mounted) setState(() => _stan = _Stan.gra);
    } catch (e) {
      //Odtwarzacz mógł stracić źródło (np. system zabrał sesję audio w czasie
      //pauzy) - wtedy gramy od zapamiętanej pozycji jeszcze raz, zamiast
      //zostawiać martwy przycisk.
      debugPrint('Nagranie: wznowienie nie wyszło, gram od nowa - $e');
      await _graj(od: _pozycja);
    }
  }

  Future<void> _stop() async {
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('Nagranie: zatrzymanie - $e');
    }
    if (mounted) {
      setState(() {
        _stan = _Stan.stop;
        _pozycja = Duration.zero;
      });
    }
  }

  /// Koniec przeciągania suwaka. Przy zatrzymanym nagraniu przewinięcie samo
  /// uruchamia odtwarzanie - inaczej trzeba by celować w suwak, a potem jeszcze
  /// w przycisk.
  Future<void> _przewinDo(Duration cel) async {
    _przewijam = false;
    if (_stan == _Stan.stop) {
      await _graj(od: cel);
      return;
    }
    try {
      await _player?.seek(cel);
      if (mounted) setState(() => _pozycja = cel);
    } catch (e) {
      debugPrint('Nagranie: przewijanie - $e');
    }
  }

  Future<void> _kasuj() async {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    final bool? tak = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(loc.removeThisItem),
        content: Text(loc.deletePermanently),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.yesDelete),
          ),
        ],
      ),
    );
    if (tak != true || !mounted) return;
    await _stop();
    if (!mounted) return;
    await Provider.of<Recordings>(context, listen: false)
        .usun(widget.nagranie);
  }

  Color get _kolor => _brakPliku
      ? Colors.grey
      : _stan == _Stan.stop
          ? const Color.fromARGB(255, 0, 94, 255)
          : const Color.fromARGB(255, 179, 2, 2);

  IconData get _ikona => _brakPliku
      ? Icons.volume_off
      : _stan == _Stan.gra
          ? Icons.pause_circle_outline
          : _stan == _Stan.pauza
              ? Icons.play_circle_outline
              : Icons.volume_up;

  /// Czas pod ikoną: przy zatrzymanym nagraniu sama długość (tak jak było -
  /// "0:07"), w trakcie odsłuchu pozycja i długość ("0:03 / 0:07").
  String get _czas {
    final String calosc = RecordingHelper.opisCzasu(_calosc.inSeconds);
    if (_stan == _Stan.stop) return calosc;
    return '${RecordingHelper.opisCzasu(_pozycja.inSeconds)} / $calosc';
  }

  @override
  Widget build(BuildContext context) {
    return widget.zSuwakiem ? _zSuwakiem() : _kompaktowy();
  }

  /// Wersja do listy: ikona + czas, a kwadracik "od początku" pojawia się
  /// dopiero wtedy, gdy jest co zatrzymywać.
  Widget _kompaktowy() {
    final double rozmiar = widget.male ? 18 : 24;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _brakPliku ? null : _przelacz,
          onLongPress: _kasuj,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_ikona, size: rozmiar, color: _kolor),
                const SizedBox(width: 2),
                Text(
                  _czas,
                  style: TextStyle(
                    fontSize: widget.male ? 12 : 14,
                    color: _kolor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_stan != _Stan.stop)
          InkWell(
            onTap: _stop,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Icon(
                Icons.stop_circle_outlined,
                size: rozmiar,
                color: _kolor,
              ),
            ),
          ),
      ],
    );
  }

  /// Wersja do ekranu edycji: ikona, pasek przewijania i czas.
  Widget _zSuwakiem() {
    final double maks =
        _calosc.inMilliseconds > 0 ? _calosc.inMilliseconds.toDouble() : 1;
    final double wartosc =
        _pozycja.inMilliseconds.toDouble().clamp(0.0, maks).toDouble();
    return Row(
      children: [
        InkWell(
          onTap: _brakPliku ? null : _przelacz,
          onLongPress: _kasuj,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(_ikona, size: 28, color: _kolor),
          ),
        ),
        Expanded(
          child: SliderTheme(
            //Suwak w domyślnych rozmiarach zjadłby pół ekranu edycji - to ma być
            //pasek przy notatce, a nie odtwarzacz muzyki.
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: _kolor,
              inactiveTrackColor: Colors.grey.shade400,
              thumbColor: _kolor,
              overlayColor: _kolor.withAlpha(40),
            ),
            child: Slider(
              min: 0,
              max: maks,
              value: wartosc,
              onChanged: _brakPliku
                  ? null
                  : (double v) => setState(() {
                        _przewijam = true;
                        _pozycja = Duration(milliseconds: v.round());
                      }),
              onChangeEnd: _brakPliku
                  ? null
                  : (double v) =>
                      _przewinDo(Duration(milliseconds: v.round())),
            ),
          ),
        ),
        Text(
          '${RecordingHelper.opisCzasu(_pozycja.inSeconds)} / '
          '${RecordingHelper.opisCzasu(_calosc.inSeconds)}',
          style: TextStyle(fontSize: 13, color: _kolor),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// Wszystkie nagrania przypięte do jednego wpisu, jedno obok drugiego.
/// Gdy nagrań nie ma - nie zajmuje ani piksela.
class RecordingRow extends StatelessWidget {
  const RecordingRow({
    super.key,
    required this.zrodlo,
    required this.powiazanieId,
    this.male = false,
    this.zSuwakiem = false,
  });

  final String zrodlo;
  final String powiazanieId;
  final bool male;

  /// Odtwarzacze z paskiem przewijania - każdy w osobnym wierszu na całą
  /// szerokość (ekrany edycji notatki i przeglądu).
  final bool zSuwakiem;

  @override
  Widget build(BuildContext context) {
    //watch, nie read: po skasowaniu nagrania ikonka ma zniknąć bez wychodzenia
    //z ekranu, a po podyktowaniu notatki - pojawić się od razu.
    final List<Recording> moje =
        context.watch<Recordings>().dla(zrodlo, powiazanieId);
    if (moje.isEmpty) return const SizedBox.shrink();
    if (zSuwakiem) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final Recording r in moje)
            RecordingPlayer(nagranie: r, male: male, zSuwakiem: true),
        ],
      );
    }
    return Wrap(
      spacing: 2,
      children: [
        for (final Recording r in moje)
          RecordingPlayer(nagranie: r, male: male),
      ],
    );
  }
}
