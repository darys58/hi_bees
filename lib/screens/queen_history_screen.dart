import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hi_bees/l10n/app_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/queen.dart';
import '../models/info.dart';
import '../helpers/db_helper.dart';
import '../helpers/queen_helpers.dart';
import '../helpers/parametr_nazwy.dart'; //nazwaParametru, wartoscWBiezacym
import '../helpers/eksport_helper.dart'; //menu PDF/CSV, zapis CSV
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
        //w obrębie dnia po godzinie - kolejność cech w kafelku zbiorczym
        _queenInfos.sort((a, b) {
          final int d = a.data.compareTo(b.data);
          return d != 0 ? d : _minuty(a.czas).compareTo(_minuty(b.czas));
        });

        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  //"9:05" -> 545. Czas jest w bazie jako H:mm (bez zera z przodu), więc
  //porównanie napisów stawiałoby "10:00" przed "9:05".
  int _minuty(String czas) {
    final List<String> cz = czas.split(':');
    if (cz.length < 2) return 0;
    return (int.tryParse(cz[0].trim()) ?? 0) * 60 + (int.tryParse(cz[1].trim()) ?? 0);
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

  //Parametr i wartość wpisu o matce w BIEŻĄCYM języku - także dla wpisów zapisanych
  //przy innym języku, dawnej jakości "zła" i kluczy znaku ("mark_white"). Do 05.10.2026
  //szły surowo z bazy, z wyjątkiem dwóch literałów ('dziewica', 'virgine').
  String _opisWpisu(BuildContext context, Info info) {
    final loc = AppLocalizations.of(context)!;
    final String parametr = nazwaParametru(context, info.parametr);
    final String wartosc = wartoscWBiezacym(context, info.wartosc, parametr: info.parametr);
    if (wartosc == loc.virgine) return '$parametr ${loc.virgine1}'; //"nieunasienniona"
    //znak matki - z napisem na opalitku (info.miara), jak na belce ula (11.10.2026)
    if (_wpisZnaku(context, info) && info.miara.trim().isNotEmpty && info.miara.trim() != '0') {
      return '$parametr $wartosc ${info.miara.trim()}'.trim();
    }
    return '$parametr $wartosc'.trim();
  }

  //wpis o znaku z wartością "brak" / "nie ma" (matki nie ma w ulu)
  bool _brakMatki(BuildContext context, Info info) {
    final loc = AppLocalizations.of(context)!;
    final String v = wartoscWBiezacym(context, info.wartosc, parametr: info.parametr);
    return v == loc.missing || v == loc.gone;
  }

  //Ikonka cechy jak na belce matki w info (infos_screen, statystyki "queen") -
  //te same ikony i kolory, żeby historia czytała się tak samo (11.10.2026).
  //Rocznik - skrót roku ('26). Wpisy bez ikony - null (puste miejsce na ikonę).
  Widget? _ikonaCechy(BuildContext context, Info info) {
    final loc = AppLocalizations.of(context)!;
    final String p = parametrWBiezacym(context, info.parametr);
    final String v = wartoscWBiezacym(context, info.wartosc, parametr: info.parametr);
    if (p == loc.queen + '  ' + loc.isIs) { //jakość
      return qualityIsBad(info.wartosc)
          ? const Icon(Icons.thumb_down_outlined, size: 20.0, color: Color.fromARGB(255, 255, 1, 1))
          : const Icon(Icons.thumb_up_outlined, size: 20.0, color: Color.fromARGB(255, 15, 200, 8));
    }
    if (p == loc.queen + ' -') { //unasiennienie
      final String u = wartoscWBiezacym(context, info.wartosc);
      if (u == loc.virgine) return const Icon(Icons.egg_outlined, size: 20.0, color: Color.fromARGB(255, 255, 0, 0));
      if (u == loc.naturallyMated || u == loc.artificiallyInseminated) {
        return const Icon(Icons.egg, size: 20.0, color: Color.fromARGB(255, 15, 200, 8));
      }
      if (u == loc.droneLaying) return const Icon(Icons.egg_outlined, size: 20.0, color: Color.fromARGB(255, 219, 170, 9));
      return null;
    }
    if (p == loc.queenIs) { //ograniczenie: wolna / w klatce
      return wartoscWBiezacym(context, info.wartosc) == loc.freed
          ? Image.asset('assets/image/matka12.png', width: 27, height: 16, fit: BoxFit.fill)
          : Image.asset('assets/image/matka11.png', width: 25, height: 15, fit: BoxFit.fill);
    }
    if (p == loc.queenWasBornIn) { //rocznik - skrót roku jak na belce: '26
      final String rok = info.wartosc.trim();
      if (rok.length < 4) return null;
      return Text('\'${rok.substring(2)}', style: const TextStyle(fontSize: 14));
    }
        if (p == ' ' + loc.queen) { //znak
      if (v == loc.missing || v == loc.gone) {
        return const Icon(Icons.dangerous_outlined, size: 20.0, color: Color.fromARGB(255, 255, 0, 0));
      }
      final List<Widget> ikona = markToIcon(markToKey(v));
      return ikona.isEmpty ? null : ikona.first;
    }
    return null;
  }

  //wpis o znaku matki (parametr " matka" w dowolnym z języków)
  bool _wpisZnaku(BuildContext context, Info info) =>
      parametrWBiezacym(context, info.parametr) == ' ' + AppLocalizations.of(context)!.queen;

  //Wpisy z chwili podłączenia matki do ula (11.10.2026). Od tej daty queen_item
  //znaczy je przyrostkiem id [kIdPodlaczeniaMatki]. Starsze rozpoznajemy po
  //kolejności: wpis o znaku, który jest PIERWSZYM wpisem tej matki w danym ulu
  //(poprzedni był w innym ulu albo nie było żadnego) - podłączenie dopisuje
  //właśnie wpis o znaku. Ponowne podłączenie do TEGO SAMEGO ula widać tylko
  //w wpisach z przyrostkiem.
  Set<String> _wpisyPodlaczenia(BuildContext context) {
    final Set<String> wynik = {};
    String poprzedniUl = '';
    for (final info in _queenInfos) {
      final String ul = '${info.pasiekaNr}|${info.ulNr}';
      //"matki brak" / "nie ma" to też wpis o znaku, ale nie podłączenie
      if (info.id.endsWith(kIdPodlaczeniaMatki) ||
          (ul != poprzedniUl && _wpisZnaku(context, info) && !_brakMatki(context, info))) {
        wynik.add(info.id);
      }
      poprzedniUl = ul;
    }
    return wynik;
  }

  //Kafelki historii (11.10.2026, prośba usera). Wpisy BEZ uwag z tej samej daty
  //i tego samego ula idą do jednego kafelka - przegląd zapisuje każdą cechę matki
  //osobnym wpisem, więc jeden dzień dawał kilka kafelków z tym samym nagłówkiem.
  //Wpis z uwagą zostaje osobno (uwaga dotyczy tej jednej cechy). Kafelek zbiorczy
  //stoi w miejscu pierwszego wpisu dnia; kolejność jak w _queenInfos.
  //Ul w kluczu: matkę przeniesioną tego samego dnia do innego ula widać w dwóch.
  List<List<Info>> _kafelki() {
    final List<List<Info>> kafelki = [];
    final Map<String, List<Info>> zbiorcze = {};
    for (final info in _queenInfos) {
      if (info.uwagi.trim().isNotEmpty) {
        kafelki.add([info]);
        continue;
      }
      final String klucz = '${info.data}|${info.pasiekaNr}|${info.ulNr}';
      final List<Info>? grupa = zbiorcze[klucz];
      if (grupa != null) {
        grupa.add(info);
      } else {
        final List<Info> nowa = [info];
        zbiorcze[klucz] = nowa;
        kafelki.add(nowa);
      }
    }
    return kafelki;
  }

  List<Widget> _buildMarkIcon(String znak, BuildContext context) {
    return markToIcon(markToKey(znak));
  }

  //CSV historii matki (11.10.2026) - to samo co PDF: dane matki jako wiersze
  //"etykieta;wartość" (etykiety jak w PDF), potem tabela z jednym wierszem na
  //kafelek; cechy z jednego dnia w jednej komórce, jedna pod drugą.
  Future<void> _generateQueenHistoryCsv() async {
    if (_queen == null) return;
    final queen = _queen!;
    final loc = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final dataCsv = globals.isEuropeanFormat()
        ? '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}'
        : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final List<List<String>> wiersze = [
      [loc.pdfQueenHistoryTitle(queen.id.toString())],
      ['Hey Maya $dataCsv'],
      [],
    ];

    // Dane matki - te same warunki co w PDF
    if (queen.linia.isNotEmpty) wiersze.add([loc.pdfLine, queen.linia]);
    if (queen.rasa.isNotEmpty) {
      wiersze.add([loc.pdfBreed, breedToDisplay(breedToKey(queen.rasa), loc)]);
    }
    if (queen.znak.isNotEmpty && queen.znak != '0') {
      wiersze.add([loc.pdfMark, markToDisplay(markToKey(queen.znak), loc)]);
    }
    if (queen.napis.isNotEmpty && queen.napis != '0') {
      wiersze.add([loc.pdfLabel, queen.napis]);
    }
    if (queen.zrodlo.isNotEmpty && queen.zrodlo != '0') {
      wiersze.add([loc.pdfSource, sourceToDisplay(sourceToKey(queen.zrodlo), loc)]);
    }
    if (queen.data.isNotEmpty && queen.data != '0') {
      wiersze.add([loc.pdfObtainedDate, _zmienDatePelna(queen.data)]);
    }
    if (queen.dataStraty.isNotEmpty && queen.dataStraty != '0') {
      wiersze.add([loc.pdfLostDate, _zmienDatePelna(queen.dataStraty)]);
    }
    if (queen.uwagi.isNotEmpty && queen.uwagi != '0') {
      wiersze.add([loc.pdfRemarks, queen.uwagi]);
    }
    wiersze.add([]);

    // Tabela - jeden wiersz na kafelek, jak w PDF
    final List<List<Info>> kafelki = _kafelki();
    final Set<String> podlaczenia = _wpisyPodlaczenia(context);
    if (kafelki.isNotEmpty) {
      wiersze.add([loc.pdfLp, loc.pdfApiaryHive, loc.pdfDate, loc.pdfHour,
                   loc.pdfTemperature, loc.pdfInformation, loc.pdfRemarks]);
    }
    for (int i = 0; i < kafelki.length; i++) {
      final info = kafelki[i].first;
      final String infoText = kafelki[i]
          .map((w) => podlaczenia.contains(w.id)
              ? '${_opisWpisu(context, w)} (${loc.queenConnectedToHive})'
              : _opisWpisu(context, w))
          .join('\n');
      wiersze.add([
        '${i + 1}',
        '${info.pasiekaNr}/${info.ulNr}',
        _zmienDatePelna(info.data),
        info.czas,
        _cleanTemp(info.temp),
        infoText,
        info.uwagi,
      ]);
    }
    await udostepnijCsv(context, 'historia_matki_ID${queen.id}', wiersze);
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
                  text: breedToDisplay(breedToKey(queen.rasa), loc),
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
        detailParts.add('${loc.pdfMark}: ${markToDisplay(markToKey(queen.znak), loc)}');
      }
      if (queen.napis.isNotEmpty && queen.napis != '0') {
        detailParts.add('${loc.pdfLabel}: ${queen.napis}');
      }
      if (queen.zrodlo.isNotEmpty && queen.zrodlo != '0') {
        detailParts.add('${loc.pdfSource}: ${sourceToDisplay(sourceToKey(queen.zrodlo), loc)}');
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
      //jeden wiersz na kafelek z ekranu - cechy z tego samego dnia i ula bez uwag
      //razem, jedna pod drugą (11.10.2026)
      final List<List<Info>> kafelki = _kafelki();
      final Set<String> podlaczenia = _wpisyPodlaczenia(context);
      for (int i = 0; i < kafelki.length; i++) {
        final info = kafelki[i].first;
        final String infoText = kafelki[i]
            .map((w) => podlaczenia.contains(w.id)
                ? '${_opisWpisu(context, w)} (${loc.queenConnectedToHive})'
                : _opisWpisu(context, w))
            .join('\n');
        
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
              if (tableData.isNotEmpty)
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
    final Set<String> podlaczenia = _wpisyPodlaczenia(context);

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
                  onPressed: () async {
                    final format = await wybierzFormat(context); //menu PDF / CSV
                    if (format == FormatEksportu.pdf) _generateAndSharePdf();
                    if (format == FormatEksportu.csv) _generateQueenHistoryCsv();
                  },
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
                          text: breedToDisplay(breedToKey(queen.rasa), AppLocalizations.of(context)!),
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
                        Text('  ${sourceToDisplay(sourceToKey(queen.zrodlo), AppLocalizations.of(context)!)}',
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
          //wpisy z tego samego dnia i ula bez uwag = jeden kafelek, cechy jedna pod drugą
          for (final grupa in _kafelki())
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
                    //(w kafelku zbiorczym - z pierwszego wpisu dnia)
                    Text(
                      '${grupa.first.pasiekaNr} / ${grupa.first.ulNr}   ${_zmienDatePelna(grupa.first.data)}   ${grupa.first.czas}   ${grupa.first.temp}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    // Wiersz 2: parametr i wartość - każdy wpis kafelka w osobnej linii
                    for (final info in grupa)
                      if (info.parametr.isNotEmpty || info.wartosc.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 10),
                          child: Row(
                            children: [
                              //ikonka cechy jak na belce matki w info
                              SizedBox(
                                width: 30,
                                child: Center(child: _ikonaCechy(context, info)),
                              ),
                              Flexible(
                                child: Text(
                                  _opisWpisu(context, info),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              //podłączenie matki do ula - ikonka po napisie na opalitku
                              if (podlaczenia.contains(info.id))
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Tooltip(
                                    message: AppLocalizations.of(context)!.queenConnectedToHive,
                                    child: const Icon(Icons.login,
                                        size: 18, color: Color.fromARGB(255, 46, 125, 50)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    // Wiersz 3: uwagi (tylko kafelek pojedynczy - zbiorczy uwag nie ma)
                    if (grupa.first.uwagi.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, left: 40),
                        child: Text(grupa.first.uwagi,
                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic), ),
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
