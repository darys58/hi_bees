import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:heymaya/l10n/app_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../globals.dart' as globals;
import '../models/hives.dart';
import '../models/info.dart';
import '../models/infos.dart';
import '../helpers/parametr_nazwy.dart'; //rokNaEkran

// Raport leczenia (osyp varroa) z kolorowymi słupkami - rozwinięcie raport2_screen
// na wzór raport_color_screen:
// - słupek ula podzielony na kolorowe segmenty - każdy segment to jedno liczenie osypu (data)
// - bliskie daty liczenia (0-3 dni) łączone w jedno liczenie (jak miodobrania)
// - legenda pod wykresem: kolor, data, suma osypu z całej pasieki
// - przycisk PDF: bieżąca strona albo wszystkie ule
class Raport2ColorScreen extends StatefulWidget {
  static const routeName = '/raport2_color';

  @override
  State<Raport2ColorScreen> createState() => _Raport2ColorScreenState();
}

class _Raport2ColorScreenState extends State<Raport2ColorScreen> {
  bool _isInit = true;

  // Lata raportowane (tak jak w raport2_screen)
  static const List<String> lata = ['2023', '2024', '2025', '2026', '2027', '2028', '2029', '2030'];

  // Dane per rok (klucz = rok, np. '2025')
  Map<String, int> varroa = {}; //ilość warrozy z uli na prezentowanej stronie raportu
  Map<String, int> allVarroa = {}; //ilość varrozy ze wszystkich uli
  // Dane do wykresów - lista liczeń dla każdego ula
  // Struktura: {"x": nrKolejny, "nrUla": nrUla, "harvests": [{"date": "YYYY-MM-DD", "value": double}, ...]}
  // (nazwa klucza "harvests" jak w raport_color_screen - segmenty słupka)
  Map<String, List<Map<String, dynamic>>> daneVarroaDoWykresu = {}; //ule z bieżącej strony
  Map<String, List<Map<String, dynamic>>> daneVarroaWszystkieUle = {}; //wszystkie ule (do PDF)
  Map<String, List<BarChartGroupData>> barGroupsVarroa = {};
  // Unikalne (zgrupowane) daty liczeń osypu dla legendy (wspólne dla wszystkich uli w roku)
  Map<String, List<String>> datyVarroa = {};
  // Suma osypu dla każdego zgrupowanego liczenia (data -> suma szt.) - wszystkie ule
  Map<String, Map<String, double>> sumaVarroa = {};
  // Uwagi z wpisów varroa dla każdego zgrupowanego liczenia (data -> lista uwag) - do PDF
  Map<String, Map<String, List<String>>> uwagiVarroa = {};

  List<int> hivesNumbers = [];  //lista numerów uli naa prezentowanej stronie raportu
  List<int> allHivesNumbers = [];  //lista numerów wszystkich uli

  // Paleta kolorów dla liczeń osypu (jak dla miodobrań w raport_color_screen)
  final List<Color> harvestColors = [
    Color(0xFF2196F3), // niebieski
    Color(0xFF4CAF50), // zielony
    Color(0xFFFF9800), // pomarańczowy
    Color(0xFFE91E63), // różowy
    Color(0xFF9C27B0), // fioletowy
    Color(0xFF00BCD4), // cyjan
    Color(0xFFFFEB3B), // żółty
    Color(0xFF795548), // brązowy
    Color(0xFF607D8B), // szaroniebieski
    Color(0xFFFF5722), // głęboki pomarańczowy
    Color(0xFF3F51B5), // indygo
    Color(0xFF8BC34A), // jasnozielony
  ];

  final _formKey1 = GlobalKey<FormState>();
  int numerStrony = globals.raportNrStrony; //numwe zakresu uli wyświetlanych w statystykach
  int iloscUli = 0; //ilość uli w pasiece
  int reszta = 0; //jak reszta (modulo) > 0 to reszta == 1, a jak 0 to reszta == 0
  bool _generatingPdf = false; //czy trwa generowanie PDF

  @override
  void didChangeDependencies() {
    Provider.of<Hives>(context, listen: false)
      .fetchAndSetHives(globals.pasiekaID)
      .then((_){
        final hivesDataAll = Provider.of<Hives>(context, listen: false);
        final hivesAll = hivesDataAll.items;

        // Wyczyść listy przed ponownym wypełnieniem (zapobiega powielaniu uli)
        allHivesNumbers.clear();
        hivesNumbers.clear();

        for (var i = 0; i < hivesAll.length; i++) {
          allHivesNumbers.add(hivesAll[i].ulNr); //utworzenie listy wszystkich numerów uli do raportu
        }

       //przygotowanie numerów uli do przedstawiania na wybranej stronie raportu
        iloscUli = hivesAll.length; //ilośc wszystkich uli w pasiece
        if (iloscUli % globals.raportIleUliNaStronie != 0) reszta = 1 ;//jezeli jest reszta z dzielenia (modulo) to reszta=1 bo trzeba wyświetlić jeszcze jedną, choć niepełną, stronę
        int koniecFor = 0;
        if (globals.raportNrStrony * globals.raportIleUliNaStronie <= hivesAll.length) koniecFor = globals.raportNrStrony * globals.raportIleUliNaStronie;
        else koniecFor = hivesAll.length;

        //lista numerów raportowanych uli - numer strony i ile uli na stronie do raportowania
        for (var i = globals.raportNrStrony * globals.raportIleUliNaStronie - globals.raportIleUliNaStronie; i < koniecFor; i++) {
          hivesNumbers.add(hivesAll[i].ulNr); //utworzenie listy numerów uli do raportu - dla pętli for
        }
    });

    if (_isInit) {
      Provider.of<Infos>(context, listen: false).fetchAndSetInfosForApiary(globals.pasiekaID).then((_) {
        //wszystkie informacje dla wybranej pasieki i ula
      });
    }

    _isInit = false;
    super.didChangeDependencies();
  }

  //wybór ilości uli na stronie raportu
  void _showAlertNaStronie(String wybor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(wybor,textAlign: TextAlign.center,),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min, //okno ściśniete w pionie
          children: <Widget>[
            SizedBox(
              height: 230,
              width: 300,
              child: ListWheelScrollView( //przewijane kółko w wartościami
                itemExtent: 70,
                physics: FixedExtentScrollPhysics() ,
                perspective: 0.009,
                children: [
                  for(var i=1; i<21; i++) //tworzenie klikalnych wartości dla kółka
                    InkWell(
                      onTap: () {
                        setState(() {
                          globals.raportNrStrony = 1;
                          globals.raportIleUliNaStronie = i;
                          Navigator.of(context).pop();
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder( //przejście bez najazdu ekranu
                              pageBuilder: (context, animation, secondaryAnimation) => Raport2ColorScreen(),
                              transitionDuration: Duration.zero, // brak animacji
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        });
                      },
                      child: Text('${i.toString()}', style: const TextStyle(fontSize: 40),)
                    ),
                ]
              )
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
      barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  // Funkcja grupująca bliskie daty liczenia osypu (różnica 0-3 dni = to samo liczenie)
  // Zwraca mapę: oryginalna data -> data reprezentująca grupę (najwcześniejsza w grupie)
  Map<String, String> _grupujBliskieDaty(Set<String> dates) {
    List<String> sortedDates = dates.toList()..sort();
    Map<String, String> dateMapping = {}; // oryginalna data -> data grupy

    if (sortedDates.isEmpty) return dateMapping;

    String currentGroupDate = sortedDates[0];
    dateMapping[sortedDates[0]] = currentGroupDate;

    for (int i = 1; i < sortedDates.length; i++) {
      DateTime current = DateTime.parse(sortedDates[i]);
      DateTime groupStart = DateTime.parse(currentGroupDate);

      int daysDiff = current.difference(groupStart).inDays;

      if (daysDiff <= 3) {
        // Ta data należy do tej samej grupy
        dateMapping[sortedDates[i]] = currentGroupDate;
      } else {
        // Nowa grupa
        currentGroupDate = sortedDates[i];
        dateMapping[sortedDates[i]] = currentGroupDate;
      }
    }

    return dateMapping;
  }

  // Ilość roztoczy z wpisu info (0 gdy wpis nie jest liczeniem varroa)
  int _obliczVarroa(Info info) {
    if (info.parametr == 'varroa' && info.wartosc.isNotEmpty) {
      return int.tryParse(info.wartosc) ?? 0;
    }
    return 0;
  }

  // Formatowanie daty YYYY-MM-DD do wyświetlenia (DD.MM albo MM-DD)
  String _dataNaEkran(String date) {
    if (date.length < 10) return date;
    String day = date.substring(8, 10);
    String month = date.substring(5, 7);
    return globals.isEuropeanFormat() ? '$day.$month' : '$month-$day';
  }

  // Tworzenie stacked bar chart dla osypu varroa
  // data: lista liczeń dla ula: {"x": nrKolejny, "harvests": [{"date": "YYYY-MM-DD", "value": double}, ...]}
  // datyLiczen: posortowana lista unikalnych dat liczeń (wspólna dla wszystkich uli)
  List<BarChartGroupData> _generateStackedBarGroupsVarroa(
    List<Map<String, dynamic>> data,
    List<String> datyLiczen
  ) {
    return data.map((hiveData) {
      List<Map<String, dynamic>> harvests = List<Map<String, dynamic>>.from(hiveData['harvests'] ?? []);

      // Oblicz sumę dla toY
      double total = 0;
      for (var h in harvests) {
        total += (h['value'] as num).toDouble();
      }

      List<BarChartRodStackItem> stackItems = [];
      // WAŻNE: Mały offset startowy rozwiązuje problem fl_chart z niewidocznymi
      // pierwszymi segmentami gdy fromY=0 (znane zachowanie biblioteki)
      const double baseOffset = 0.1;
      double currentY = baseOffset;

      // Segmenty w kolejności dat - od dołu do góry
      for (int i = 0; i < datyLiczen.length; i++) {
        String date = datyLiczen[i];
        double value = 0;
        for (var h in harvests) {
          if (h['date'] == date) {
            value = (h['value'] as num).toDouble();
            break;
          }
        }
        if (value <= 0) continue;
        Color color = harvestColors[i % harvestColors.length];
        // Dodaj BorderSide żeby segment był widoczny nawet przy problemach renderowania
        stackItems.add(BarChartRodStackItem(
          currentY,
          currentY + value,
          color,
          //BorderSide(color: color, width: 0.5),
        ));
        currentY += value;
      }

      return BarChartGroupData(
        x: hiveData['x'],
        barRods: [
          BarChartRodData(
            toY: total > 0 ? total + baseOffset : 0.001,
            borderRadius: BorderRadius.zero,
            width: 8, // Szerokość słupka
            color: stackItems.isEmpty ? Colors.grey.withValues(alpha: 0.1) : Colors.transparent,
            rodStackItems: stackItems,
          ),
        ],
      );
    }).toList();
  }

  // Przetwarzanie danych osypu dla danego roku
  void _processYear(String rok, List<Info> infos) {
    // Zbierz wszystkie unikalne daty liczeń dla tego roku (przed grupowaniem)
    Set<String> uniqueDates = {};
    for (var info in infos) {
      if (info.data.substring(0, 4) == rok && _obliczVarroa(info) > 0) {
        uniqueDates.add(info.data.substring(0, 10)); // YYYY-MM-DD
      }
    }

    // Grupuj bliskie daty (0-3 dni = to samo liczenie)
    Map<String, String> dateMapping = _grupujBliskieDaty(uniqueDates);
    List<String> daty = dateMapping.values.toSet().toList()..sort();

    Map<String, double> suma = {};
    Map<String, List<String>> uwagi = {};
    List<Map<String, dynamic>> daneWszystkie = [];
    List<Map<String, dynamic>> daneStrona = [];
    int sumaWszystkie = 0;
    int sumaStrona = 0;

    // Dla każdego ula w pasiece
    for (var nrUla in allHivesNumbers) {
      Map<String, double> liczenia = {}; // zgrupowana data -> ilość roztoczy
      int sumaUla = 0;

      for (var info in infos) {
        if (info.data.substring(0, 4) != rok || info.ulNr != nrUla) continue;
        int val = _obliczVarroa(info);
        if (val <= 0) continue;

        String date = info.data.substring(0, 10);
        String groupDate = dateMapping[date] ?? date;
        liczenia[groupDate] = (liczenia[groupDate] ?? 0) + val;
        suma[groupDate] = (suma[groupDate] ?? 0) + val;
        sumaUla += val;

        if (info.uwagi.isNotEmpty) {
          List<String> lista = uwagi.putIfAbsent(groupDate, () => []);
          String uwaga = '$nrUla: ${info.uwagi}';
          if (!lista.contains(uwaga)) lista.add(uwaga);
        }
      }
      sumaWszystkie += sumaUla;

      if (sumaUla > 0) {
        List<Map<String, dynamic>> harvestsList = liczenia.entries
            .map((e) => {"date": e.key, "value": e.value})
            .toList();
        daneWszystkie.add({"nrUla": nrUla, "harvests": harvestsList});

        // Ul z bieżącej strony raportu - numer kolejny słupka (x) jak w raport2_screen
        int idx = hivesNumbers.indexOf(nrUla);
        if (idx >= 0) {
          daneStrona.add({"x": idx + 1, "nrUla": nrUla, "harvests": harvestsList});
          sumaStrona += sumaUla;
        }
      }
    }
    daneStrona.sort((a, b) => (a['x'] as int).compareTo(b['x'] as int));

    allVarroa[rok] = sumaWszystkie;
    varroa[rok] = sumaStrona;
    datyVarroa[rok] = daty;
    sumaVarroa[rok] = suma;
    uwagiVarroa[rok] = uwagi;
    daneVarroaWszystkieUle[rok] = daneWszystkie;
    daneVarroaDoWykresu[rok] = daneStrona;
    barGroupsVarroa[rok] = daneStrona.isNotEmpty
        ? _generateStackedBarGroupsVarroa(daneStrona, daty)
        : [];
  }

  // Czy wykres dla roku ma być widoczny
  bool _pokazRok(String rok) {
    return (daneVarroaDoWykresu[rok] ?? []).isNotEmpty &&
        (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == rok);
  }

  // Widget legendy dla wykresu osypu - wyrównana do lewej od pozycji wykresu
  // z przyciskiem PDF po prawej stronie (pionowo)
  Widget _buildLegendVarroa(String rok) {
    List<String> daty = datyVarroa[rok] ?? [];
    Map<String, double> suma = sumaVarroa[rok] ?? {};
    if (daty.isEmpty) return SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(left: 60.0, right: 24.0, top: 8.0, bottom: 8.0), // 60 = 50 (reservedSize) + 10 (padding)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Legenda liczeń - wyrównana do lewej
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: daty.asMap().entries.toList().reversed.map((entry) { //od najnowszej daty (jak na słupku - od góry)
                int index = entry.key;
                String date = entry.value;
                Color color = harvestColors[index % harvestColors.length];
                int szt = (suma[date] ?? 0).round();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(_dataNaEkran(date), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      SizedBox(width: 12),
                      Text('$szt ${loc.pcs}', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Przycisk PDF po prawej stronie (pionowy)
          _generatingPdf
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : InkWell(
                  onTap: () {
                    _showPdfOptionsDialog(rok);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 20, color: Theme.of(context).primaryColor),
                        SizedBox(height: 4),
                        Text('PDF', style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor)),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // Dialog z opcjami PDF: widoczne ule, wszystkie ule
  void _showPdfOptionsDialog(String rok) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PDF - ${loc.dEad} varroa ${rokNaEkran(context, rok)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Opcja 1: Drukuj widoczne ule (bieżąca strona)
            ListTile(
              leading: Icon(Icons.visibility),
              title: Text(loc.pAge + ' $numerStrony'),
              subtitle: Text('${hivesNumbers.length} ${loc.hives}'),
              onTap: () {
                Navigator.of(context).pop();
                _generatePdf(rok: rok, tylkoWidoczne: true);
              },
            ),
            Divider(),
            // Opcja 2: Drukuj wszystkie ule
            ListTile(
              leading: Icon(Icons.select_all),
              title: Text(loc.aLl),
              subtitle: Text('${allHivesNumbers.length} ${loc.hives}'),
              onTap: () {
                Navigator.of(context).pop();
                _generatePdf(rok: rok, tylkoWidoczne: false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  // Funkcja generująca PDF z wykresem osypu varroa
  // rok: np. '2023', '2024', etc.
  // tylkoWidoczne: true = tylko ule z bieżącej strony, false = wszystkie
  Future<void> _generatePdf({
    required String rok,
    bool tylkoWidoczne = false,
  }) async {
    List<Map<String, dynamic>> allData = tylkoWidoczne
        ? (daneVarroaDoWykresu[rok] ?? [])
        : (daneVarroaWszystkieUle[rok] ?? []);
    if (allData.isEmpty) return;

    List<String> daty = datyVarroa[rok] ?? [];
    Map<String, double> suma = sumaVarroa[rok] ?? {};
    Map<String, List<String>> uwagiDlaGrupyDat = uwagiVarroa[rok] ?? {};
    int totalValue = tylkoWidoczne ? (varroa[rok] ?? 0) : (allVarroa[rok] ?? 0);

    // Pobierz teksty lokalizacji przed async
    final loc = AppLocalizations.of(context)!;
    final String titleText = '${loc.dEad} varroa';
    final String rokEkran = rokNaEkran(context, rok); //'wszystkie' -> loc.aLl, wyliczone przed await
    final String totalText = loc.total;
    final String pageText = loc.pAge;
    final String errorText = loc.error;
    final String hiveNumbersText = loc.hiveNumbers;
    final String pcsText = loc.pcs;
    final String pasiekaNazwa = loc.aPiary + ' nr ' + globals.pasiekaID.toString();

    setState(() {
      _generatingPdf = true;
    });

    try {
      // Stała ilość uli na stronę PDF dla czytelności
      const int uliNaStrone = 20;

      // Oblicz liczbę stron
      int liczbaStron = (allData.length / uliNaStrone).ceil();

      // Załaduj czcionkę obsługującą polskie znaki
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      // Utwórz dokument PDF
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
      );

      for (int strona = 0; strona < liczbaStron; strona++) {
        int startIndex = strona * uliNaStrone;
        int endIndex = (startIndex + uliNaStrone > allData.length)
            ? allData.length
            : startIndex + uliNaStrone;

        List<Map<String, dynamic>> pageData = allData.sublist(startIndex, endIndex);

        // Oblicz maksymalną wartość dla skali wykresu
        double maxValue = 0;
        for (var hive in pageData) {
          double sum = 0;
          for (var h in (hive['harvests'] as List)) {
            sum += (h['value'] as num).toDouble();
          }
          if (sum > maxValue) maxValue = sum;
        }
        // Zaokrąglij do góry do ładnej wartości (podzielnej przez 5 - całkowite etykiety osi Y)
        if (maxValue <= 10) {
          maxValue = 10;
        } else if (maxValue <= 100) {
          maxValue = ((maxValue / 10).ceil() * 10).toDouble();
        } else if (maxValue <= 500) {
          maxValue = ((maxValue / 50).ceil() * 50).toDouble();
        } else {
          maxValue = ((maxValue / 100).ceil() * 100).toDouble();
        }

        // Oblicz etykiety osi Y (5 poziomów)
        int numYLabels = 5;
        List<double> yLabels = [];
        for (int i = 0; i <= numYLabels; i++) {
          yLabels.add((maxValue / numYLabels) * i);
        }

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            // Marginesy: góra/dół 20pt, lewo/prawo 2cm (~57pt)
            margin: const pw.EdgeInsets.only(top: 20, bottom: 20, left: 57, right: 57),
            build: (pw.Context context) {
              // Stała wysokość wykresu (290 punktów - dodatkowe 10 na górną etykietę Y)
              const double chartHeight = 290;
              const double yAxisWidth = 40; // Szerokość obszaru na etykiety osi Y
              const double chartTopOffset = 10; // Offset na górze na etykietę Y wychodząca ponad linię
              const double maxBarHeight = chartHeight - 50 - chartTopOffset; // Wysokość obszaru wykresu (etykiety Y, siatka, obramowanie)
              const double maxSlupekHeight = maxBarHeight - 15; // Maksymalna wysokość słupka (zostawia miejsce na tekst wartości nad słupkiem)

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  // Odstęp od góry
                  pw.SizedBox(height: 10),
                  // Tytuł
                  pw.Center(
                    child: pw.Text(
                      '$titleText $rokEkran - $pasiekaNazwa',
                      style: pw.TextStyle(fontSize: 18, font: fontBold),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Center(
                    child: pw.Text(
                      '$totalText: $totalValue $pcsText',
                      style: pw.TextStyle(fontSize: 12, font: fontRegular),
                    ),
                  ),
                  if (liczbaStron > 1)
                    pw.Center(
                      child: pw.Text(
                        '$pageText ${strona + 1} / $liczbaStron',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey, font: fontRegular),
                      ),
                    ),
                  pw.SizedBox(height: 20),

                  // Wykres z osią Y
                  pw.Container(
                    height: chartHeight,
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        // Oś Y z etykietami - pozycjonowane absolutnie
                        pw.Container(
                          width: yAxisWidth,
                          child: pw.Stack(
                            overflow: pw.Overflow.visible, // Pozwól etykietom wychodzić poza kontener
                            children: [
                              for (int i = 0; i <= numYLabels; i++)
                                pw.Positioned(
                                  right: 4,
                                  top: chartTopOffset + ((numYLabels - i) / numYLabels) * maxBarHeight - 4, // chartTopOffset + pozycja - 4 dla wyrównania środka tekstu
                                  child: pw.Text(
                                    yLabels[i].toStringAsFixed(0),
                                    style: pw.TextStyle(fontSize: 8, font: fontRegular),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Obszar wykresu z siatką i słupkami
                        pw.Expanded(
                          child: pw.Stack(
                            children: [
                              // Obramowanie wykresu (gruba linia zewnętrzna)
                              pw.Positioned(
                                left: 0,
                                right: 0,
                                top: chartTopOffset,
                                bottom: chartHeight - maxBarHeight - chartTopOffset,
                                child: pw.Container(
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      color: PdfColors.black,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),

                              // Linie siatki poziomej - pozycjonowane precyzyjnie
                              for (int i = 0; i <= numYLabels; i++)
                                pw.Positioned(
                                  left: 0,
                                  right: 0,
                                  top: chartTopOffset + (i / numYLabels) * maxBarHeight,
                                  child: pw.Container(
                                    height: i == 0 || i == numYLabels ? 0 : 0.5, // Nie rysuj na krawędziach (jest obrys)
                                    color: PdfColors.grey300,
                                  ),
                                ),

                              // Słupki wykresu
                              pw.Positioned(
                                left: 0,
                                right: 0,
                                top: chartTopOffset,
                                bottom: chartHeight - maxBarHeight - chartTopOffset,
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                                  children: pageData.map((hive) {
                                    // Sortuj liczenia wg daty - ta sama lista używana wszędzie
                                    List<Map<String, dynamic>> sortedHarvests = List<Map<String, dynamic>>.from(hive['harvests'] as List);
                                    sortedHarvests.sort((a, b) {
                                      int idxA = daty.indexOf(a['date']);
                                      int idxB = daty.indexOf(b['date']);
                                      return idxA.compareTo(idxB);
                                    });

                                    double totalHive = 0;
                                    for (var h in sortedHarvests) {
                                      totalHive += (h['value'] as num).toDouble();
                                    }

                                    double barHeight = maxValue > 0
                                        ? (totalHive / maxValue) * maxSlupekHeight
                                        : 0;
                                    double barWidth = pageData.length <= 10 ? 25.0 : 15.0;

                                    return pw.Column(
                                      mainAxisAlignment: pw.MainAxisAlignment.end,
                                      children: [
                                        // Wartość nad słupkiem (szt.)
                                        pw.Text(
                                          totalHive.toStringAsFixed(0),
                                          style: pw.TextStyle(fontSize: 7, font: fontRegular),
                                        ),
                                        pw.SizedBox(height: 2),
                                        // Słupek (stackowany) - segmenty posortowane wg daty od dołu do góry
                                        // Używamy Stack zamiast Column żeby uniknąć problemów z renderowaniem
                                        pw.Container(
                                          width: barWidth,
                                          height: barHeight > 0 ? barHeight : 1,
                                          child: pw.Stack(
                                            children: () {
                                              // Wysokości segmentów proporcjonalnie do wartości
                                              List<double> segmentHeights = [];
                                              for (var h in sortedHarvests) {
                                                double rv = (h['value'] as num).toDouble();
                                                segmentHeights.add(totalHive > 0 && barHeight > 0
                                                    ? (rv / totalHive) * barHeight
                                                    : 0);
                                              }

                                              // Skoryguj pierwszy segment (najniższy), żeby suma była DOKŁADNIE równa barHeight
                                              if (segmentHeights.isNotEmpty && barHeight > 0) {
                                                double sumSegs = segmentHeights.fold(0.0, (a, b) => a + b);
                                                segmentHeights[0] = segmentHeights[0] + (barHeight - sumSegs);
                                              }

                                              // Buduj segmenty od dołu do góry używając pozycji absolutnych
                                              List<pw.Widget> segments = [];
                                              double currentBottom = 0;
                                              for (int i = 0; i < sortedHarvests.length; i++) {
                                                int idx = daty.indexOf(sortedHarvests[i]['date']);
                                                segments.add(pw.Positioned(
                                                  left: 0,
                                                  right: 0,
                                                  bottom: currentBottom,
                                                  child: pw.Container(
                                                    width: barWidth,
                                                    height: segmentHeights[i],
                                                    color: _getPdfColor(idx >= 0 ? idx : 0),
                                                  ),
                                                ));
                                                currentBottom += segmentHeights[i];
                                              }
                                              return segments;
                                            }(),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),

                              // Numery uli na dole - obrócone o +90 stopni (zgodnie z wykresami w apce)
                              pw.Positioned(
                                left: 0,
                                right: 0,
                                top: chartTopOffset + maxBarHeight + 5, // Pod słupkami wykresu
                                bottom: 0,
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                                  children: pageData.map((hive) {
                                    return pw.Container(
                                      width: pageData.length <= 10 ? 25 : 15,
                                      child: pw.Center(
                                        child: pw.Transform.rotate(
                                          angle: 1.5708, // +90 stopni
                                          child: pw.Text(
                                            '${hive['nrUla']}',
                                            style: pw.TextStyle(fontSize: 8, font: fontRegular),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Podpis osi X - wyśrodkowany względem obszaru wykresu, bliżej numerów uli
                  pw.Container(
                    margin: const pw.EdgeInsets.only(left: 40, top: 0, bottom: 15),
                    child: pw.Center(
                      child: pw.Text(
                        hiveNumbersText,
                        style: pw.TextStyle(fontSize: 9, font: fontRegular),
                      ),
                    ),
                  ),

                  // Legenda - każda data z uwagami w jednym wierszu
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 40), // yAxisWidth
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: daty.asMap().entries.toList().reversed.map((entry) { //od najnowszej daty (jak na słupku - od góry)
                        int index = entry.key;
                        String date = entry.value;
                        int szt = (suma[date] ?? 0).round();
                        String uwagiText = (uwagiDlaGrupyDat[date] ?? []).join('; ');

                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Kwadracik z kolorem
                              pw.Container(
                                width: 12,
                                height: 12,
                                color: _getPdfColor(index),
                              ),
                              pw.SizedBox(width: 4),
                              // Data + suma (stała szerokość)
                              pw.Container(
                                width: 100,
                                child: pw.Text('${_dataNaEkran(date)} - $szt $pcsText', style: pw.TextStyle(fontSize: 9, font: fontRegular)),
                              ),
                              pw.SizedBox(width: 10),
                              // Uwagi (elastyczna szerokość) - "nrUla: uwagi"
                              pw.Expanded(
                                child: uwagiText.isNotEmpty
                                    ? pw.Text(
                                        uwagiText,
                                        style: pw.TextStyle(fontSize: 9, font: fontRegular, fontStyle: pw.FontStyle.italic),
                                      )
                                    : pw.SizedBox(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      final Uint8List pdfBytes = await pdf.save();
      final String fileName = 'varroa_${rok}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Wyłącz kółko oczekiwania PRZED otwarciem udostępniania
      if (mounted) {
        setState(() {
          _generatingPdf = false;
        });
      }

      // Podgląd/udostępnienie PDF
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );

    } catch (e) {
      debugPrint('Błąd generowania PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorText: $e')),
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

  // Pomocnicza funkcja do konwersji kolorów na PdfColor
  PdfColor _getPdfColor(int index) {
    final colors = [
      PdfColors.blue,
      PdfColors.green,
      PdfColors.orange,
      PdfColors.pink,
      PdfColors.purple,
      PdfColors.cyan,
      PdfColors.yellow,
      PdfColors.brown,
      PdfColors.blueGrey,
      PdfColors.deepOrange,
      PdfColors.indigo,
      PdfColors.lightGreen,
    ];
    return colors[index % colors.length];
  }

  // Sekcja jednego roku: nagłówek z sumami, wykres, legenda, kreska
  List<Widget> _buildYearSection(String rok) {
    if (!_pokazRok(rok)) return [];
    final loc = AppLocalizations.of(context)!;

    return [
      SizedBox(height: 10),
      RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black),
          children: [
            TextSpan(
              text:(loc.dEad + ' varroa $rok: ${allVarroa[rok] ?? 0} ' + loc.pcs),
            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
            TextSpan(
              text:(' (${varroa[rok] ?? 0} ' + loc.pcs + ')'),
            style: TextStyle(fontSize: 14 )),
          ])),
      Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
        child: AspectRatio(
          aspectRatio: 2,
          child: BarChart(
            BarChartData(
              barGroups: barGroupsVarroa[rok] ?? [], // Używamy dynamicznie generowanych słupków
              barTouchData: BarTouchData( //etykiety słupków
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (
                    BarChartGroupData group,
                    int groupIndex,
                    BarChartRodData rod,
                    int rodIndex
                  ){
                    return BarTooltipItem(
                      rod.toY.round().toString(), //toY = suma + offset 0.1
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                  }
                )
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles( //dolne opisy osi
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      int idx = value.toInt() - 1;
                      String text = idx >= 0 && idx < hivesNumbers.length ? hivesNumbers[idx].toString() : ''; //numer ula
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: RotatedBox(
                          quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
                          child: Text(text, style: TextStyle(fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles( //lewe opisy osi
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text (value.toInt().toString(), style: TextStyle(fontSize: 12),),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false,)
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false,)
                ),
              ),
            ),
          ),
        ),
      ),
      //legenda liczeń osypu
      _buildLegendVarroa(rok),
      //kreska
      const Divider(
        height: 10,
        thickness: 1,indent: 0,
        endIndent: 0,
        color: Colors.black,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    //pobranie danych info z wybranej kategorii - leczenie
    final infosData = Provider.of<Infos>(context);
    List<Info> infos = infosData.items.where((inf) {
      return inf.kategoria == ('treatment');
    }).toList();

     //poszukanie najstarszego roku w wybranej kategorii
    int odRoku = int.parse(DateTime.now().toString().substring(0, 4)); //biezący rok
    for (var i = 0; i < infos.length; i++) {
      if(odRoku > int.parse(infos[i].data.substring(0, 4)))
        odRoku = int.parse(infos[i].data.substring(0, 4));
    }

    //TWORZENIE DANYCH DO WYKRESóW - każdy build liczy od zera (bez kumulacji wartości)
    for (var rok in lata) {
      _processYear(rok, infos);
    }
    bool brakDanych = lata.every((rok) => (daneVarroaDoWykresu[rok] ?? []).isEmpty);

     final ButtonStyle buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(2.0),
      backgroundColor: Theme.of(context).primaryColor, //Color.fromARGB(255, 233, 140, 0),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(66.0, 35.0),
    );
    final ButtonStyle buttonOffStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(2.0),
      backgroundColor: Color.fromARGB(255, 211, 211, 211),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(66.0, 35.0),
    );

    // wybór roku do raportowania
    void _showAlertYear() {
      // przycisk wyboru roku ('wszystkie' albo rok)
      Widget przyciskRoku(BuildContext context, String rok, String etykieta) {
        return TextButton(onPressed: (){
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          globals.rokRaportow = rok;
          Navigator.of(context).pushNamed(
              Raport2ColorScreen.routeName,
            );
        }, child: globals.rokRaportow == rok
                  ? Text(('> $etykieta <'),style: TextStyle(fontSize: 18))
                  : Text((etykieta),style: TextStyle(fontSize: 18))
        );
      }

      int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectReportYear),
          content: Column(
            //zeby tekst był wyśrodkowany w poziomie
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              przyciskRoku(context, 'wszystkie', AppLocalizations.of(context)!.aLl),
              for (var rok in lata)
                if (int.parse(rok) <= biezacyRok && int.parse(rok) >= odRoku)
                  przyciskRoku(context, rok, rok),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
          elevation: 24.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        barrierDismissible:
            false, //zeby zaciemnione tło było zablokowane na kliknięcia
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.query_stats, color: Color.fromARGB(255, 0, 0, 0)),
             onPressed: () =>
                 _showAlertYear(),
           ),
        ],
        title: Text('${AppLocalizations.of(context)!.dEad} varroa ${rokNaEkran(context, globals.rokRaportow)}',
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey[300], // kolor linii
              height: 1.0,
            ),
          ),
      ),
      body: Column(
        children: [
          SizedBox(height: 5),
          // --- CZĘŚĆ STAŁA
          Container(
            height: 75,
            width: double.infinity,
            alignment: Alignment.center,
            child:   //wybór strony raportowanych uli
              Container(
                height: 75,
                child:
                  Form(
                    key: _formKey1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
      //<<
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('-'),
                              numerStrony == 1 //przycisk nieaktywny jezeli numerStrony = 1
                                ? OutlinedButton(
                                    style: buttonOffStyle,
                                    onPressed: () {},
                                    child: Text('<',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Color.fromARGB(255, 0, 0,0))),
                                  )
                                : OutlinedButton(
                                    style: buttonStyle,
                                    onPressed: () {
                                      setState(() {
                                        numerStrony = numerStrony - 1;
                                        globals.raportNrStrony = numerStrony;
                                        Navigator.pushReplacement(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => Raport2ColorScreen(),
                                            transitionDuration: Duration.zero, // brak animacji
                                            reverseTransitionDuration: Duration.zero,
                                          ),
                                        );
                                      });
                                  },
                                child: Text('<',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 0, 0,0))),
                        )]),

                        SizedBox(width: 10),
  //numer oglądanej strony
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.pAge),
                            OutlinedButton(
                                style: buttonOffStyle,
                                onPressed: () {},
                                child: Text('$numerStrony',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 0, 0,0))),
                        )]),

   //>>
                        SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('+'),
                            numerStrony == iloscUli~/globals.raportIleUliNaStronie + reszta
                              ? OutlinedButton(
                                  style: buttonOffStyle,
                                  onPressed: () {},
                                  child: Text('>',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 0, 0,0))),
                                )
                              : OutlinedButton(
                                  style: buttonStyle,
                                  onPressed: () {
                                    setState(() {
                                      numerStrony = numerStrony +1;
                                      globals.raportNrStrony = numerStrony;
                                      Navigator.pushReplacement(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) => Raport2ColorScreen(),
                                          transitionDuration: Duration.zero, // brak animacji
                                          reverseTransitionDuration: Duration.zero,
                                        ),
                                      );
                                    });
                                  },
                                  child: Text('>',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 0, 0,0))),
                            )]),

                            SizedBox(width: 30),
  //ilość uli na stronie
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(AppLocalizations.of(context)!.onPage),
                                OutlinedButton(
                                    style: buttonStyle,
                                    onPressed: () {_showAlertNaStronie(AppLocalizations.of(context)!.hivesOnSite);},
                                    child: Text('${globals.raportIleUliNaStronie}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Color.fromARGB(255, 0, 0,0))),
                            )]),

                          ],
                        ),
                    ),
                  ),
          ),
      //kreska
              const Divider(
                height: 10,
                thickness: 1,
                indent: 0,
                endIndent: 0,
                color: Colors.black,
              ),
      //część przewijana
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              brakDanych
                ? Center(
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.only(top: 50),
                          child: Text(
                            AppLocalizations.of(context)!.noData,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )

          //Wykresy osypu varroa - od najnowszego roku
                : Column(
                  children: [
                    SizedBox(height: 10),
                    for (var rok in lata.reversed) ..._buildYearSection(rok),
                  ],
                ),
            ],
          ),
        ),
      ),
     ]),
    );
  }
}
