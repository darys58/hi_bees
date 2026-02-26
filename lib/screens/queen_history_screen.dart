import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  bool _generatingPdf = false;
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
    if (globals.isEuropeanFormat()) {
      return '$dzien.$miesiac.$rok';
    } else {
      return '$rok-$miesiac-$dzien';
    }
  }

  /// Czyści wartość temperatury do wyświetlenia w PDF.
  /// Usuwa znaki stopni/Celsjusza, zostaw tylko liczbę + czyste °C.
  String _cleanTemp(String temp) {
    if (temp.isEmpty || temp == '0') return '';
    // Wyciągnij liczbę (opcjonalny minus, cyfry, kropka/przecinek)
    final numMatch = RegExp(r'-?\d+[.,]?\d*').firstMatch(temp);
    if (numMatch == null) return '';
    return '${numMatch.group(0)}\u00B0C';
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

  Future<void> _generateAndSharePdf() async {
    if (_queen == null) return;
    final queen = _queen!;
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _generatingPdf = true;
    });

    try {
      // Załaduj fonty obsługujące polskie znaki
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
      );

      // Aktualna data
      final now = DateTime.now();
      final dataPdf = globals.isEuropeanFormat()
          ? '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}'
          : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Tytuł PDF
      final tytul = loc.pdfQueenHistoryTitle(queen.id.toString());

      // Dane matki - zbuduj linie tekstowe
      List<pw.Widget> queenDataWidgets = [];

      // Linia + rasa
      if (queen.linia.isNotEmpty || queen.rasa.isNotEmpty) {
        queenDataWidgets.add(
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '${queen.linia} ',
                  style: pw.TextStyle(fontSize: 12, font: fontBold),
                ),
                pw.TextSpan(
                  text: queen.rasa,
                  style: pw.TextStyle(fontSize: 10, font: fontRegular),
                ),
              ],
            ),
          ),
        );
      }

      // Znak, napis, źródło, data pozyskania
      List<String> detailParts = [];
      if (queen.znak.isNotEmpty && queen.znak != '0') {
        detailParts.add('${loc.pdfMark}: ${queen.znak}');
      }
      if (queen.napis.isNotEmpty && queen.napis != '0') {
        detailParts.add('${loc.pdfLabel}: ${queen.napis}');
      }
      if (queen.zrodlo.isNotEmpty && queen.zrodlo != '0') {
        detailParts.add('${loc.pdfSource}: ${queen.zrodlo}');
      }
      if (queen.data.isNotEmpty && queen.data != '0') {
        detailParts.add('${loc.pdfObtainedDate}: ${_zmienDatePelna(queen.data)}');
      }
      if (detailParts.isNotEmpty) {
        queenDataWidgets.add(
          pw.Text(
            detailParts.join('   '),
            style: pw.TextStyle(fontSize: 10, font: fontRegular),
          ),
        );
      }

      // Stracona
      if (queen.dataStraty.isNotEmpty && queen.dataStraty != '0') {
        queenDataWidgets.add(
          pw.Text(
            '${loc.pdfLostDate} ${_zmienDatePelna(queen.dataStraty)}',
            style: pw.TextStyle(fontSize: 10, font: fontBold),
          ),
        );
      }

      // Uwagi
      if (queen.uwagi.isNotEmpty && queen.uwagi != '0') {
        queenDataWidgets.add(
          pw.Text(
            queen.uwagi,
            style: pw.TextStyle(fontSize: 10, font: fontRegular),
          ),
        );
      }

      // Tabela z wpisami info
      // Nagłówek "Pasieka / Ul" w dwóch liniach
      final apiaryHiveParts = loc.pdfApiaryHive.split(' / ');
      final apiaryLabel = apiaryHiveParts.isNotEmpty ? apiaryHiveParts[0] : '';
      final hiveLabel = apiaryHiveParts.length > 1 ? apiaryHiveParts[1] : '';

      // Proporcje kolumn: L.p., Pasieka/Ul, Data, Czas, Temp., Informacja, Uwagi
      final columnWidths = {
        0: const pw.FixedColumnWidth(22),
        1: const pw.FixedColumnWidth(42),
        2: const pw.FixedColumnWidth(55),
        3: const pw.FixedColumnWidth(32),
        4: const pw.FixedColumnWidth(30),
        5: const pw.FlexColumnWidth(2),
        6: const pw.FlexColumnWidth(3),
      };

      final headerStyle = pw.TextStyle(fontSize: 8, font: fontBold);
      final cellStyle = pw.TextStyle(fontSize: 8, font: fontRegular);

      // Nagłówki tabeli - kolumny 0-4 wyśrodkowane
      final headerRow = pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey200,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Center(child: pw.Text(loc.pdfLp, style: headerStyle)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(apiaryLabel, style: headerStyle),
                  pw.Text(hiveLabel, style: headerStyle),
                ],
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Center(child: pw.Text(loc.pdfDate, style: headerStyle)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Center(child: pw.Text(loc.pdfHour, style: headerStyle)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Center(child: pw.Text(loc.pdfTemperature, style: headerStyle)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Text(loc.pdfInformation, style: headerStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.Text(loc.pdfRemarks, style: headerStyle),
          ),
        ],
      );

      List<List<pw.Widget>> tableData = [];
      for (int i = 0; i < _queenInfos.length; i++) {
        final info = _queenInfos[i];  
        String? infoText;
        info.wartosc == 'dziewica'
        ? infoText = '${info.parametr} nieunasienniona'
        : info.wartosc == 'virgine'
          ? infoText = '${info.parametr} virgine'
          : infoText = '${info.parametr} ${info.wartosc}'.trim();
        
        // Czyść temperaturę - zostaw tylko cyfry, minus, kropkę i dodaj °C
        final tempClean = _cleanTemp(info.temp);
        tableData.add([
          pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Center(child: pw.Text('${i + 1}', style: cellStyle)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Center(child: pw.Text('${info.pasiekaNr}/${info.ulNr}', style: cellStyle)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Center(child: pw.Text(_zmienDatePelna(info.data), style: cellStyle)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Center(child: pw.Text(info.czas, style: cellStyle)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Center(child: pw.Text(tempClean, style: cellStyle)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Text(infoText, style: cellStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Text(info.uwagi, style: cellStyle),
          ),
        ]);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(56.7), // 2cm
          build: (pw.Context context) {
            return [
              // Tytuł
              pw.Center(
                child: pw.Text(
                  tytul,
                  style: pw.TextStyle(fontSize: 16, font: fontBold),
                ),
              ),
              pw.SizedBox(height: 4),
              // Data PDF
              pw.Center(
                child: pw.Text(
                  'Hey Maya  $dataPdf',
                  style: pw.TextStyle(fontSize: 10, font: fontRegular),
                ),
              ),
              pw.SizedBox(height: 12),
              // Dane matki
              ...queenDataWidgets.map((w) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: w,
                  )),
              pw.SizedBox(height: 12),
              // Tabela
              if (_queenInfos.isNotEmpty)
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  columnWidths: columnWidths,
                  children: [
                    // Nagłówek
                    headerRow,
                    // Dane
                    ...tableData.map((row) => pw.TableRow(children: row)),
                  ],
                ),
            ];
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'historia_matki_ID${queen.id}.pdf',
      );
    } catch (e) {
      debugPrint('Błąd generowania PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.pdfGeneratingError}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _generatingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _queen == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              '${AppLocalizations.of(context)!.queenHistory} ID ${_queen?.id ?? ''}'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.picture_as_pdf, color: Colors.grey),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final queen = _queen!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppLocalizations.of(context)!.queenHistory} ID ${queen.id}'),
        actions: [
          _generatingPdf
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: _generateAndSharePdf,
                ),
        ],
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
                        child: 
                          info.wartosc == 'dziewica'
                        ? Text(
                            '${info.parametr} nieunasienniona',
                            style: const TextStyle(fontSize: 14),
                          )
                        : info.wartosc == 'virgine'
                          ? Text(
                              '${info.parametr} virgine',//jakby była własciwa nazwa po angielsku to tu mozna zmienić //${info.wartosc}'.trim(),
                              style: const TextStyle(fontSize: 14),
                            )
                          : Text(
                            '${info.parametr} ${info.wartosc}'.trim(), //wszystkie inne wartości
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
