import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/hive.dart';
import '../models/hives.dart';

class SummaryScreen extends StatefulWidget {
  static const routeName = '/screen-summary';

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isLoading = true;
  bool _isInit = true;

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

      if (hiveList.isEmpty) {
        // Brak danych - pobierz dane uli dla tej pasieki
        Provider.of<Hives>(context, listen: false)
            .fetchAndSetHives(pasiekaNr)
            .then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        setState(() {
          _isLoading = false;
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
          title: Text(AppLocalizations.of(context)!.summary),
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
          title: Text(AppLocalizations.of(context)!.summary),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.nOData),
        ),
      );
    }

    final hive = hiveList.first;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.summary),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx > 300) {
            Navigator.of(context).pop();
          }
        },
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: hiveIcon,
              title: Text(
                '${AppLocalizations.of(context)!.aPiary} ${hive.pasiekaNr}  ${AppLocalizations.of(context)!.hIve} ${hive.ulNr}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline, size: 28),
              title: Text(
                '${hive.h1} ${hive.h2} (${hive.ramek})',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: const Icon(Icons.calendar_today, size: 28),
              title: Text(
                difference > 365
                    ? '? ${AppLocalizations.of(context)!.sinceLastInspection}'
                    : '$difference ${AppLocalizations.of(context)!.sinceLastInspection}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
