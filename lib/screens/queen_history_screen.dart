import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/queen.dart';
import '../models/info.dart';
import '../helpers/db_helper.dart';
import '../globals.dart' as globals;

class QueenHistoryScreen extends StatefulWidget {
  static const routeName = '/screen-queen-history';

  @override
  State<QueenHistoryScreen> createState() => _QueenHistoryScreenState();
}

class _QueenHistoryScreenState extends State<QueenHistoryScreen> {
  bool _isInit = true;
  bool _isLoading = true;
  List<Info> _queenInfos = [];
  Queen? _queen;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
      final queenId = args['queenId'] as int;

      // Znajdź matkę
      final queensData = Provider.of<Queens>(context, listen: false);
      final queens = queensData.items.where((q) => q.id == queenId);
      if (queens.isNotEmpty) {
        _queen = queens.first;
      }

      // Pobranie info bezpośrednio z bazy (bez modyfikacji providera Infos)
      // Filtrowanie po ID matki w polu pogoda - ze wszystkich pasiek i uli
      DBHelper.getData('info').then((dataList) {
        _queenInfos = dataList
            .map((item) => Info(
                  id: item['id'],
                  data: item['data'],
                  pasiekaNr: item['pasiekaNr'],
                  ulNr: item['ulNr'],
                  kategoria: item['kategoria'],
                  parametr: item['parametr'],
                  wartosc: item['wartosc'],
                  miara: item['miara'],
                  pogoda: item['pogoda'],
                  temp: item['temp'],
                  czas: item['czas'],
                  uwagi: item['uwagi'],
                  arch: item['arch'],
                ))
            .where((info) =>
                info.kategoria == 'queen' &&
                info.pogoda == queenId.toString())
            .toList();

        // Sortowanie od najstarszego do najmłodszego
        _queenInfos.sort((a, b) => a.data.compareTo(b.data));

        setState(() {
          _isLoading = false;
        });
      });
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

  List<Widget> _buildMarkIcon(String znak, BuildContext context) {
    if (znak.isEmpty || znak == '0') return [];
    if (znak == AppLocalizations.of(context)!.unmarked)
      return [
        const Icon(Icons.circle,
            size: 20.0, color: Color.fromARGB(255, 61, 61, 61))
      ];
    if (znak == AppLocalizations.of(context)!.markedWhite)
      return [
        const Icon(Icons.check_circle_outline_outlined,
            size: 20.0, color: Color.fromARGB(255, 0, 0, 0))
      ];
    if (znak == AppLocalizations.of(context)!.markedYellow)
      return [
        const Icon(Icons.check_circle_rounded,
            size: 20.0, color: Color.fromARGB(255, 215, 208, 0))
      ];
    if (znak == AppLocalizations.of(context)!.markedRed)
      return [
        const Icon(Icons.check_circle_rounded,
            size: 20.0, color: Color.fromARGB(255, 255, 0, 0))
      ];
    if (znak == AppLocalizations.of(context)!.markedGreen)
      return [
        const Icon(Icons.check_circle_rounded,
            size: 20.0, color: Color.fromARGB(255, 15, 200, 8))
      ];
    if (znak == AppLocalizations.of(context)!.markedBlue)
      return [
        const Icon(Icons.check_circle_rounded,
            size: 20.0, color: Color.fromARGB(255, 0, 102, 255))
      ];
    if (znak == AppLocalizations.of(context)!.markedOther)
      return [
        const Icon(Icons.check_circle_rounded,
            size: 20.0, color: Color.fromARGB(255, 158, 166, 172))
      ];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _queen == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              '${AppLocalizations.of(context)!.queenHistory} ID ${_queen?.id ?? ''}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final queen = _queen!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppLocalizations.of(context)!.queenHistory} ID ${queen.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        children: [
          // --- Segment 1: Dane matki ---
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linia 1: linia + rasa (czcionki jak w summary_screen)
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: '${queen.linia} ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        TextSpan(
                          text: queen.rasa,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Linia 2: znak, napis na opalitku, sposób pozyskania, data pozyskania
                  Row(
                    children: [
                      ..._buildMarkIcon(queen.znak, context),
                      if (queen.napis.isNotEmpty && queen.napis != '0')
                        Text(' ${queen.napis} ',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      if (queen.zrodlo.isNotEmpty && queen.zrodlo != '0')
                        Text('  ${queen.zrodlo}',
                            style: const TextStyle(fontSize: 14)),
                      if (queen.data.isNotEmpty && queen.data != '0')
                        Text('  ${_zmienDatePelna(queen.data)}',
                            style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  // Linia 3: "Stracona" (data straty matki) - wytłuszczona
                  if (queen.dataStraty.isNotEmpty && queen.dataStraty != '0')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${AppLocalizations.of(context)!.lOst} ${_zmienDatePelna(queen.dataStraty)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  // Linia 4: Uwagi - bez tytułu
                  if (queen.uwagi.isNotEmpty && queen.uwagi != '0')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(queen.uwagi,
                          style: const TextStyle(fontSize: 14)),
                    ),
                ],
              ),
            ),
          ),

          // --- Kolejne segmenty: wpisy z info kategoria "queen" ---
          for (final info in _queenInfos)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wiersz 1: numer pasieki / numer ula, data wpisu, godzina, temperatura
                    Text(
                      '${info.pasiekaNr} / ${info.ulNr}   ${_zmienDatePelna(info.data)}   ${info.czas}   ${info.temp}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    // Wiersz 2: parametr i wartość
                    if (info.parametr.isNotEmpty || info.wartosc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${info.parametr} ${info.wartosc}'.trim(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    // Wiersz 3: uwagi
                    if (info.uwagi.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(info.uwagi,
                            style: const TextStyle(fontSize: 14)),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
