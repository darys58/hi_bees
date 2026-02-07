import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/hive.dart';
import '../models/hives.dart';
import '../models/info.dart';
import '../models/infos.dart';
import '../models/queen.dart';
import '../models/harvest.dart';
import '../models/note.dart';
import '../globals.dart' as globals;
import '../widgets/hives_item.dart';

class SummaryScreen extends StatefulWidget {
  static const routeName = '/screen-summary';

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  String _inspectionNote = '';
  List<Queen> _queens = [];
  String _colonyForce = '';
  String _colonyState = '';
  Info? _lastFeeding;
  Info? _lastTreatment;
  Harvest? _lastHarvest;
  List<Note> _hiveNotes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, int>;
      final pasiekaNr = args['pasiekaNr']!;
      final ulNr = args['ulNr']!;

      final hivesData = Provider.of<Hives>(context, listen: false);
      final hiveList = hivesData.items.where((h) =>
          h.ulNr == ulNr && h.pasiekaNr == pasiekaNr && h.korpusNr > 0);

      Future<void> loadInfos() async {
        final infosData = Provider.of<Infos>(context, listen: false);
        await infosData.fetchAndSetInfosForHive(pasiekaNr, ulNr);

        // Znajdź hive żeby pobrać datę przeglądu
        final hivesData2 = Provider.of<Hives>(context, listen: false);
        final hiveList2 = hivesData2.items.where((h) =>
            h.ulNr == ulNr && h.pasiekaNr == pasiekaNr);
        if (hiveList2.isNotEmpty) {
          final hive = hiveList2.first;
          // Szukaj notatki z przeglądu (kategoria == 'inspection', ta sama data)
          final inspectionInfos = infosData.items.where((info) =>
              info.kategoria == 'inspection' &&
              info.data == hive.przeglad &&
              info.uwagi.isNotEmpty);
          if (inspectionInfos.isNotEmpty) {
            _inspectionNote = inspectionInfos.first.uwagi;
          }
        }

        // Załaduj matki dla tego ula
        final queensData = Provider.of<Queens>(context, listen: false);
        await queensData.fetchAndSetQueens();
        _queens = queensData.items.where((q) =>
            q.pasieka == pasiekaNr && q.ul == ulNr && q.dataStraty == '').toList();

        // Colony info (siła i stan rodziny)
        DateTime latestColonyForce = DateTime(2000);
        DateTime latestColonyState = DateTime(2000);
        for (final info in infosData.items) {
          if (info.kategoria == 'colony') {
            final infoDate = DateTime.parse(info.data);
            if (info.parametr.startsWith(' ') && infoDate.isAfter(latestColonyForce)) {
              latestColonyForce = infoDate;
              _colonyForce = info.wartosc;
            } else if (!info.parametr.startsWith(' ') && infoDate.isAfter(latestColonyState)) {
              latestColonyState = infoDate;
              _colonyState = info.wartosc;
            }
          }
        }

        // Last feeding
        DateTime latestFeeding = DateTime(2000);
        for (final info in infosData.items) {
          if (info.kategoria == 'feeding') {
            final infoDate = DateTime.parse(info.data);
            if (infoDate.isAfter(latestFeeding)) {
              latestFeeding = infoDate;
              _lastFeeding = info;
            }
          }
        }

        // Last treatment
        DateTime latestTreatment = DateTime(2000);
        for (final info in infosData.items) {
          if (info.kategoria == 'treatment') {
            final infoDate = DateTime.parse(info.data);
            if (infoDate.isAfter(latestTreatment)) {
              latestTreatment = infoDate;
              _lastTreatment = info;
            }
          }
        }

        // Last harvest for this apiary
        final harvestsData = Provider.of<Harvests>(context, listen: false);
        await harvestsData.fetchAndSetZbiory();
        final apiaryHarvests = harvestsData.items.where((h) =>
            h.pasiekaNr == pasiekaNr).toList();
        if (apiaryHarvests.isNotEmpty) {
          _lastHarvest = apiaryHarvests.first;
        }

        // Notes for this hive
        final notesData = Provider.of<Notes>(context, listen: false);
        await notesData.fetchAndSetNotatki();
        _hiveNotes = notesData.items.where((n) =>
            n.pasiekaNr == pasiekaNr && n.ulNr == ulNr).toList();
      }

      if (hiveList.isEmpty) {
        Provider.of<Hives>(context, listen: false)
            .fetchAndSetHives(pasiekaNr)
            .then((_) => loadInfos())
            .then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        loadInfos().then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, int>;
    final ulNr = args['ulNr']!;
    final pasiekaNr = args['pasiekaNr']!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.ostatnieInformacje),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hivesData = Provider.of<Hives>(context, listen: false);
    final hiveList = hivesData.items.where((h) =>
        h.ulNr == ulNr && h.pasiekaNr == pasiekaNr);

    if (hiveList.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.ostatnieInformacje),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.nOData),
        ),
      );
    }

    final hive = hiveList.first;

    // Wszystkie korpusy dla tego ula (do wyświetlenia belek zasobów)
    final allKorpus = hivesData.items.where((h) =>
        h.ulNr == ulNr && h.pasiekaNr == pasiekaNr && h.korpusNr > 0)
        .toList()
      ..sort((a, b) => a.korpusNr.compareTo(b.korpusNr));

    //obliczanie różnicy między dwoma datami
    int daysBetween(DateTime from, DateTime to) {
      from = DateTime(from.year, from.month, from.day);
      to = DateTime(to.year, to.month, to.day);
      return (to.difference(from).inHours / 24).round();
    }

    final przeglad = DateTime.parse(hive.przeglad);
    final now = DateTime.now();
    final difference = daysBetween(przeglad, now);

    //ikona koloru ula
    Icon hiveIcon;
    if (hive.ikona == 'green') {
      hiveIcon = const Icon(Icons.hive, color: Color.fromARGB(255, 0, 255, 0), size: 30);
    } else if (hive.ikona == 'yellow') {
      hiveIcon = const Icon(Icons.hive, color: Color.fromARGB(255, 233, 229, 1), size: 30);
    } else if (hive.ikona == 'orange') {
      hiveIcon = const Icon(Icons.hive, color: Color.fromARGB(255, 233, 132, 1), size: 30);
    } else {
      hiveIcon = const Icon(Icons.hive, color: Color.fromARGB(255, 255, 0, 0), size: 30);
    }

    // Szerokość belki zasobów
    final double barWidth = MediaQuery.of(context).size.width - 80;

    // Czy sekcja "Przegląd ramek" ma cokolwiek do wyświetlenia
    final bool hasFrameReviewData = allKorpus.isNotEmpty ||
        hive.matka > 0 || hive.mateczniki > 0 || hive.usunmat > 0 ||
        (hive.todo.isNotEmpty && hive.todo != '0') ||
        _inspectionNote.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.ostatnieInformacje),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx > 300) {
            Navigator.of(context).pop();
          }
        },
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        children: [
          // --- Segment 1: Połączone info o ulu ---
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wiersz 1: ikona + pasieka/ul
                  Row(
                    children: [
                      hiveIcon,
                      const SizedBox(width: 12),
                      Text(
                        '${AppLocalizations.of(context)!.aPiary} ${hive.pasiekaNr}  ${AppLocalizations.of(context)!.hIve} ${hive.ulNr}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Wiersz 2: typ ula + ilość ramek
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        '${hive.h1} ${hive.h2} (${hive.ramek})',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Wiersz 3: dni od przeglądu
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        difference > 365
                            ? '? ${AppLocalizations.of(context)!.sinceLastInspection}'
                            : '$difference ${AppLocalizations.of(context)!.sinceLastInspection}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (hasFrameReviewData)
            const SizedBox(height: 8),

          // --- Segment 2: Ramki ---
          if (hasFrameReviewData)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tytuł "Przegląd ramek"
                  Row(
                    children: [
                      Image.asset('assets/image/hi_bees.png', width: 22, height: 22, fit: BoxFit.fill),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.frameReview,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Belki zasobów dla wszystkich korpusów
                  for (final korpusHive in allKorpus)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            child: Text('${korpusHive.korpusNr}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              color: const Color.fromARGB(172, 223, 223, 223),
                              child: CustomPaint(
                                painter: MyHiveRow(ul: korpusHive),
                                size: Size(barWidth, 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (allKorpus.isNotEmpty)
                    const SizedBox(height: 4),

                  // Informacje o matce
                  if (hive.matka > 0 || hive.mateczniki > 0 || hive.usunmat > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          if (hive.matka > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, size: 12, color: Color.fromARGB(255, 59, 59, 59)),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.queenSeen,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          if (hive.mateczniki > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, size: 12, color: Color.fromARGB(255, 255, 17, 0)),
                                const SizedBox(width: 4),
                                Text(
                                  '${AppLocalizations.of(context)!.queenCellsCount}: ${hive.mateczniki}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          if (hive.usunmat > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, size: 12, color: Color.fromARGB(255, 153, 125, 125)),
                                const SizedBox(width: 4),
                                Text(
                                  '${AppLocalizations.of(context)!.removedCellsCount}: ${hive.usunmat}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                  // Do zrobienia
                  if (hive.todo.isNotEmpty && hive.todo != '0')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.toDo}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              hive.todo,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Notatka z przeglądu
                  if (_inspectionNote.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _inspectionNote,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --- Segment: Rodzina ---
          if (_colonyForce.isNotEmpty || _colonyState.isNotEmpty)
            const SizedBox(height: 8),
          if (_colonyForce.isNotEmpty || _colonyState.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${AppLocalizations.of(context)!.cOlony}  ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: [
                          if (_colonyForce.isNotEmpty) _colonyForce,
                          if (_colonyState.isNotEmpty) _colonyState,
                        ].join(', '),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- Segment: Matka ---
          if (_queens.isNotEmpty)
            const SizedBox(height: 8),
          if (_queens.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int qi = 0; qi < _queens.length; qi++) ...[
                      if (qi > 0) const SizedBox(height: 8),
                      // Wiersz 1: ID, linia (bold), rasa
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: '${AppLocalizations.of(context)!.qUeen} (ID${_queens[qi].id}) ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            TextSpan(
                              text: '${_queens[qi].linia} ',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            TextSpan(
                              text: _queens[qi].rasa,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Wiersz 2: ikona znaku, napis, źródło, data
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (_queens[qi].znak != '' && _queens[qi].znak != '0')
                            if (_queens[qi].znak == AppLocalizations.of(context)!.unmarked)
                              const Icon(Icons.circle, size: 20.0, color: Color.fromARGB(255, 61, 61, 61))
                            else if (_queens[qi].znak == AppLocalizations.of(context)!.markedWhite)
                              const Icon(Icons.check_circle_outline_outlined, size: 20.0, color: Color.fromARGB(255, 0, 0, 0))
                            else if (_queens[qi].znak == AppLocalizations.of(context)!.markedYellow)
                              const Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 215, 208, 0))
                            else if (_queens[qi].znak == AppLocalizations.of(context)!.markedRed)
                              const Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 255, 0, 0))
                            else if (_queens[qi].znak == AppLocalizations.of(context)!.markedGreen)
                              const Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 15, 200, 8))
                            else if (_queens[qi].znak == AppLocalizations.of(context)!.markedBlue)
                              const Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 0, 102, 255))
                            else if (_queens[qi].znak == AppLocalizations.of(context)!.markedOther)
                              const Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 158, 166, 172)),
                          Text(' ${_queens[qi].napis} ',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          Text('  ${_queens[qi].zrodlo} ${_zmienDateCala(_queens[qi].data)} ',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ],
                      ),
                      // Wiersz 3: ikony z przeglądu (matka4, matka1, matka3, matka2, matka5)
                      if (hive.matka4 != '' && hive.matka4 != '0' ||
                          hive.matka1 != '' && hive.matka1 != '0' ||
                          hive.matka3 != '' && hive.matka3 != '0' ||
                          hive.matka2 != '' && hive.matka2 != '0' ||
                          hive.matka5 != '' && hive.matka5 != '0')
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // matka4 - ograniczenie
                              if (hive.matka4 == 'wolna' || hive.matka4 == 'freed')
                                Image.asset('assets/image/matka12.png', width: 30, height: 18, fit: BoxFit.fill)
                              else if (hive.matka4 == 'ograniczona' || hive.matka4 == 'in a cage' || hive.matka4 == 'in the insulator')
                                Image.asset('assets/image/matka11.png', width: 28, height: 17, fit: BoxFit.fill),
                              if (hive.matka4 != '' && hive.matka4 != '0')
                                const SizedBox(width: 10),
                              // matka1 - jakość
                              if (hive.matka1 == 'ok' || hive.matka1 == 'dobra' || hive.matka1 == 'good' || hive.matka1 == 'bardzo dobra' || hive.matka1 == 'very good' || hive.matka1 == 'duża' || hive.matka1 == 'big')
                                const Icon(Icons.thumb_up_outlined, size: 24.0, color: Color.fromARGB(255, 15, 200, 8))
                              else if (hive.matka1 == 'zła' || hive.matka1 == 'canceled' || hive.matka1 == 'słaba' || hive.matka1 == 'weak' || hive.matka1 == 'mała' || hive.matka1 == 'small' || hive.matka1 == 'stara' || hive.matka1 == 'to exchange')
                                const Icon(Icons.thumb_down_outlined, size: 24.0, color: Color.fromARGB(255, 255, 1, 1)),
                              if (hive.matka1 != '' && hive.matka1 != '0')
                                const SizedBox(width: 10),
                              // matka3 - unasiennienie
                              if (hive.matka3 == 'unasienniona' || hive.matka3 == 'naturally mated' || hive.matka3 == 'artificially inseminated')
                                const Icon(Icons.egg, size: 24.0, color: Color.fromARGB(255, 15, 200, 8))
                              else if (hive.matka3 == 'nieunasienniona' || hive.matka3 == 'virgine')
                                const Icon(Icons.egg_outlined, size: 24.0, color: Color.fromARGB(255, 255, 0, 0))
                              else if (hive.matka3 == 'trutowa' || hive.matka3 == 'drone laying')
                                const Icon(Icons.egg_outlined, size: 24.0, color: Color.fromARGB(255, 219, 170, 9)),
                              if (hive.matka3 != '' && hive.matka3 != '0')
                                const SizedBox(width: 10),
                              // matka2 - znak (kolor)
                              if (hive.matka2 != '' && hive.matka2 != '0' && hive.matka2.length >= 4)
                                if (hive.matka2.substring(0, 4) == 'niez' || hive.matka2.substring(0, 4) == 'unma')
                                  const Icon(Icons.circle, size: 24.0, color: Color.fromARGB(255, 61, 61, 61))
                                else if (hive.matka2.substring(0, 4) == 'brak' || hive.matka2.substring(0, 4) == 'miss' || hive.matka2.substring(0, 4) == 'gone' || hive.matka2.substring(0, 4) == 'nie ')
                                  const Icon(Icons.dangerous_outlined, size: 24.0, color: Color.fromARGB(255, 255, 0, 0))
                                else if (hive.matka2.substring(0, 4) == 'inny' || hive.matka2.substring(0, 4) == 'mark')
                                  const Icon(Icons.check_circle_rounded, size: 24.0, color: Color.fromARGB(255, 158, 166, 172))
                                else if (hive.matka2.substring(0, 4) == 'biał' || hive.matka2.substring(0, 4) == 'ma b')
                                  const Icon(Icons.check_circle_outline_outlined, size: 24.0, color: Color.fromARGB(255, 0, 0, 0))
                                else if (hive.matka2.substring(0, 4) == 'żółt')
                                  const Icon(Icons.check_circle_rounded, size: 24.0, color: Color.fromARGB(255, 215, 208, 0))
                                else if (hive.matka2.substring(0, 4) == 'czer')
                                  const Icon(Icons.check_circle_rounded, size: 24.0, color: Color.fromARGB(255, 255, 0, 0))
                                else if (hive.matka2.substring(0, 4) == 'ziel')
                                  const Icon(Icons.check_circle_rounded, size: 24.0, color: Color.fromARGB(255, 15, 200, 8))
                                else if (hive.matka2.substring(0, 4) == 'nieb')
                                  const Icon(Icons.check_circle_rounded, size: 24.0, color: Color.fromARGB(255, 0, 102, 255)),
                              // matka2 - napis na opalitku
                              if (hive.matka2 != '' && hive.matka2 != '0' && hive.matka2.length > 4 && hive.matka2.substring(4).isNotEmpty)
                                Text(hive.matka2.substring(4),
                                  style: const TextStyle(fontSize: 15, color: Color.fromARGB(255, 69, 69, 69)),
                                ),
                              if (hive.matka2 != '' && hive.matka2 != '0')
                                const SizedBox(width: 10),
                              // matka5 - rocznik
                              if (hive.matka5 != '' && hive.matka5 != '0' && hive.matka5.length > 2)
                                Text("'${hive.matka5.substring(2)}",
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),

          // --- Segment: Zbiory ---
          if (_lastHarvest != null)
            const SizedBox(height: 8),
          if (_lastHarvest != null)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.hArvests,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Image.asset('assets/image/zbiory.png', width: 22, height: 22, fit: BoxFit.fill),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_harvestName(context, _lastHarvest!.zasobId)} '
                            '${globals.jezyk == 'pl_PL' ? _lastHarvest!.ilosc.toString().replaceAll('.', ',') : _lastHarvest!.ilosc.toString()} '
                            '${_lastHarvest!.miara == 1 ? 'l' : 'kg'} '
                            '(${_zmienDateCala(_lastHarvest!.data)})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // --- Segment: Dokarmianie ---
          if (_lastFeeding != null)
            const SizedBox(height: 8),
          if (_lastFeeding != null)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.feeding[0].toUpperCase() +
                          AppLocalizations.of(context)!.feeding.substring(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Image.asset('assets/image/invert.png', width: 22, height: 22, fit: BoxFit.fill),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_lastFeeding!.parametr} ${_lastFeeding!.wartosc} ${_lastFeeding!.miara} (${_zmienDateCala(_lastFeeding!.data)})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // --- Segment: Leczenie ---
          if (_lastTreatment != null)
            const SizedBox(height: 8),
          if (_lastTreatment != null)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.tReatment,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Image.asset('assets/image/apivarol1.png', width: 22, height: 22, fit: BoxFit.fill),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_lastTreatment!.parametr} ${_lastTreatment!.wartosc} ${_lastTreatment!.miara} (${_zmienDateCala(_lastTreatment!.data)})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // --- Segment: Notatki ---
          if (_hiveNotes.isNotEmpty)
            const SizedBox(height: 8),
          if (_hiveNotes.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.nOtes,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (int ni = 0; ni < _hiveNotes.length; ni++) ...[
                      if (ni > 0) const Divider(height: 12),
                      Row(
                        children: [
                          Text(
                            '${_zmienDatePelna(_hiveNotes[ni].data)} ',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Expanded(
                            child: Text(
                              _hiveNotes[ni].tytul,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_hiveNotes[ni].notatka.isNotEmpty)
                        Text(
                          _hiveNotes[ni].notatka,
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  String _harvestName(BuildContext context, int zasobId) {
    switch (zasobId) {
      case 1: return AppLocalizations.of(context)!.honey;
      case 2: return AppLocalizations.of(context)!.beePollen;
      case 3: return AppLocalizations.of(context)!.perga;
      case 4: return AppLocalizations.of(context)!.wax;
      case 5: return 'propolis';
      default: return '';
    }
  }

  String _zmienDatePelna(String data) {
    if (data.length < 10) return data;
    String rok = data.substring(0, 4);
    String miesiac = data.substring(5, 7);
    String dzien = data.substring(8, 10);
    if (globals.jezyk == 'pl_PL') {
      return '$dzien.$miesiac.$rok';
    } else {
      return '$rok-$miesiac-$dzien';
    }
  }

  String _zmienDateCala(String data) {
    if (data.length < 10) return data;
    String rok = data.substring(2, 4);
    String miesiac = data.substring(5, 7);
    String dzien = data.substring(8, 10);
    if (globals.jezyk == 'pl_PL') {
      return '$dzien.$miesiac.$rok';
    } else {
      return '$rok-$miesiac-$dzien';
    }
  }
}
