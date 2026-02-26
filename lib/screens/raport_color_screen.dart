import 'dart:io';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../globals.dart' as globals;
import '../models/dodatki1.dart';
import '../models/harvest.dart';
import '../models/hives.dart';
import '../models/info.dart';
import '../models/infos.dart';
import '../models/memory.dart';

class RaportColorScreen extends StatefulWidget {
  static const routeName = '/raport_color';

  @override
  State<RaportColorScreen> createState() => _RaportColorScreenState();
}

class _RaportColorScreenState extends State<RaportColorScreen> {
  bool _isInit = true;

  double miod2023 = 0; //waga miodu z uli na prezentowanej stronie raportu
  double miod2024 = 0;
  double miod2025 = 0;
  double miod2026 = 0;
  double miod2027 = 0;
  double miod2028 = 0;
  double miod2029 = 0;
  double miod2030 = 0;
  double allMiod2023 = 0; //waga miodu z wszystkich uli
  double allMiod2024 = 0;
  double allMiod2025 = 0;
  double allMiod2026 = 0;
  double allMiod2027 = 0;
  double allMiod2028 = 0;
  double allMiod2029 = 0;
  double allMiod2030 = 0;
  int pylek2023 = 0; //waga pyłku z uli na prezentowanej stronie raportu
  int pylek2024 = 0;
  int pylek2025 = 0;
  int pylek2026 = 0;
  int pylek2027 = 0;
  int pylek2028 = 0;
  int pylek2029 = 0;
  int pylek2030 = 0;
  int allPylek2023 = 0; //waga pyłku z wszystkich uli
  int allPylek2024 = 0;
  int allPylek2025 = 0;
  int allPylek2026 = 0;
  int allPylek2027 = 0;
  int allPylek2028 = 0;
  int allPylek2029 = 0;
  int allPylek2030 = 0;

  List<int> hivesNumbers = [];  //lista numerów uli na prezentowanej w raporcie stronie
  List<int> allHivesNumbers = [];  //lista numerów wszystkich uli

  // Dane do wykresów - teraz przechowują listę miodobrań dla każdego ula
  // Struktura: {"x": nrUla, "harvests": [{"date": "YYYY-MM-DD", "value": double}, ...]}
  List<Map<String, dynamic>> daneZbioruMioduDoWykresu2023 = [];
  List<Map<String, dynamic>> daneZbioruMioduDoWykresu2024 = [];
  List<Map<String, dynamic>> daneZbioruMioduDoWykresu2025 = [];
  List<Map<String, dynamic>> daneZbioruMioduDoWykresu2026 = [];
  List<Map<String, dynamic>> daneZbioruMioduDoWykresu2027 = [];
  List<Map<String, dynamic>> daneZbioruMioduDoWykresu2028 = [];
  List<Map<String, dynamic>> daneZbioruMioduDoWykresu2029 = [];
  List<Map<String, dynamic>> daneZbioruMioduDoWykresu2030 = [];
  List<Map<String, dynamic>> daneZbioruPylkuDoWykresu2023 = [];
  List<Map<String, dynamic>> daneZbioruPylkuDoWykresu2024 = [];
  List<Map<String, dynamic>> daneZbioruPylkuDoWykresu2025 = [];
  List<Map<String, dynamic>> daneZbioruPylkuDoWykresu2026 = [];
  List<Map<String, dynamic>> daneZbioruPylkuDoWykresu2027 = [];
  List<Map<String, dynamic>> daneZbioruPylkuDoWykresu2028 = [];
  List<Map<String, dynamic>> daneZbioruPylkuDoWykresu2029 = [];
  List<Map<String, dynamic>> daneZbioruPylkuDoWykresu2030 = [];

  // Unikalne daty miodobrań dla legendy (wspólne dla wszystkich uli w roku)
  List<String> datyMiodobranMiod2023 = [];
  List<String> datyMiodobranMiod2024 = [];
  List<String> datyMiodobranMiod2025 = [];
  List<String> datyMiodobranMiod2026 = [];
  List<String> datyMiodobranMiod2027 = [];
  List<String> datyMiodobranMiod2028 = [];
  List<String> datyMiodobranMiod2029 = [];
  List<String> datyMiodobranMiod2030 = [];
  List<String> datyMiodobranPylek2023 = [];
  List<String> datyMiodobranPylek2024 = [];
  List<String> datyMiodobranPylek2025 = [];
  List<String> datyMiodobranPylek2026 = [];
  List<String> datyMiodobranPylek2027 = [];
  List<String> datyMiodobranPylek2028 = [];
  List<String> datyMiodobranPylek2029 = [];
  List<String> datyMiodobranPylek2030 = [];

  // Sumy kg miodu dla każdego zgrupowanego miodobrania (data -> suma kg)
  Map<String, double> sumaKgMiod2023 = {};
  Map<String, double> sumaKgMiod2024 = {};
  Map<String, double> sumaKgMiod2025 = {};
  Map<String, double> sumaKgMiod2026 = {};
  Map<String, double> sumaKgMiod2027 = {};
  Map<String, double> sumaKgMiod2028 = {};
  Map<String, double> sumaKgMiod2029 = {};
  Map<String, double> sumaKgMiod2030 = {};

  // Sumy ml pyłku dla każdego zbioru (data -> suma ml)
  Map<String, double> sumaLPylek2023 = {};
  Map<String, double> sumaLPylek2024 = {};
  Map<String, double> sumaLPylek2025 = {};
  Map<String, double> sumaLPylek2026 = {};
  Map<String, double> sumaLPylek2027 = {};
  Map<String, double> sumaLPylek2028 = {};
  Map<String, double> sumaLPylek2029 = {};
  Map<String, double> sumaLPylek2030 = {};

  // Pomocnicze funkcje do obliczania wartości miodu i pyłku
  double _obliczMiod(Info info, int b, String honeySmall, String honeyBig, String honeyKg) {
    if (info.parametr == honeySmall && info.wartosc.isNotEmpty) {
      double dmVal = info.pogoda == '' ? 35175 : double.parse(info.pogoda);
      return double.parse(info.wartosc) * b * dmVal / 10000;
    }
    if (info.parametr == honeyBig && info.wartosc.isNotEmpty) {
      double dmVal = info.pogoda == '' ? 78725 : double.parse(info.pogoda);
      return double.parse(info.wartosc) * b * dmVal / 10000;
    }
    if (info.parametr == honeyKg && info.wartosc.isNotEmpty) {
      return double.parse(info.wartosc) * 1000;
    }
    return 0;
  }

  double _obliczPylek(Info info, int g, String pylekPorcja, String pylekMiarka, String pylekMl, String pylekL) {
    if ((info.parametr == pylekPorcja || info.parametr == pylekMiarka) && info.wartosc.isNotEmpty) {
      return (int.parse(info.wartosc) * g).toDouble();
    }
    if (info.parametr == pylekMl && info.wartosc.isNotEmpty) {
      return int.parse(info.wartosc).toDouble();
    }
    if (info.parametr == pylekL && info.wartosc.isNotEmpty) {
      return double.parse(info.wartosc) * 1000;
    }
    return 0;
  }

  // Paleta kolorów dla miodobrań
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

  List<BarChartGroupData> barGroupsMiod2023 = []; //lista elementów sekcji "barGroupsMiod" czyli słupki wykresu miodu
  List<BarChartGroupData> barGroupsMiod2024 = []; //lista elementów sekcji "barGroupsMiod" czyli słupki wykresu miodu
  List<BarChartGroupData> barGroupsMiod2025 = [];
  List<BarChartGroupData> barGroupsMiod2026 = [];
  List<BarChartGroupData> barGroupsMiod2027 = [];
  List<BarChartGroupData> barGroupsMiod2028 = [];
  List<BarChartGroupData> barGroupsMiod2029 = [];
  List<BarChartGroupData> barGroupsMiod2030 = [];
  List<BarChartGroupData> barGroupsPylek2023 = [];
  List<BarChartGroupData> barGroupsPylek2024 = [];
  List<BarChartGroupData> barGroupsPylek2025 = [];
  List<BarChartGroupData> barGroupsPylek2026 = [];
  List<BarChartGroupData> barGroupsPylek2027 = [];
  List<BarChartGroupData> barGroupsPylek2028 = [];
  List<BarChartGroupData> barGroupsPylek2029 = [];
  List<BarChartGroupData> barGroupsPylek2030 = [];

  final _formKey1 = GlobalKey<FormState>();
  int numerStrony = globals.raportNrStrony; //numwe zakresu uli wyświetlanych w statystykach
  int iloscUli = 0; //ilość uli w pasiece
  int reszta = 0; //jak reszta (modulo) > 0 to reszta == 1, a jak 0 to reszta == 0
  double dm = 0; //rozmiar plastra miodu w dm2
  bool _generatingPdf = false; //czy trwa generowanie PDF
  
  @override
  void didChangeDependencies() {
    // print('import_screen - didChangeDependencies');

    // print('import_screen - _isInit = $_isInit');

     Provider.of<Harvests>(context, listen: false)
          .fetchAndSetZbiory()
          .then((_) {
        //wszystkie zbiory z tabeli zbiory z bazy lokalnej
      });
    
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

        //print('globals.pasiekaID = ${globals.pasiekaID}') ;
        //print('hivesAll.lengtht = ${hivesAll.length}');
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
        //wszystkie informacje dla wybranej pasieki
      });
    }

    _isInit = false;
    //Provider.of<Rests>(context, listen: false).fetchAndSetRests(); //dostawca restauracji
    super.didChangeDependencies();
  }

  String zmienDate5_10(String data) {
    //String rok = data.substring(0, 4);
    String miesiac = data.substring(0, 2);
    String dzien = data.substring(3);
    if (globals.isEuropeanFormat())
      return '$dzien.$miesiac';
    else
      return '$miesiac-$dzien';
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
                              pageBuilder: (context, animation, secondaryAnimation) => RaportColorScreen(),
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

  // Funkcja grupująca bliskie daty miodobrań (różnica 0-3 dni = to samo miodobranie)
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

  // Generyczna funkcja do tworzenia stacked bar chart dla miodu
  // data: lista miodobrań dla ula: {"x": nrUla, "harvests": [{"date": "YYYY-MM-DD", "value": double}, ...]}
  // datyMiodobran: posortowana lista unikalnych dat miodobrań (wspólna dla wszystkich uli)
  List<BarChartGroupData> _generateStackedBarGroupsMiod(
    List<Map<String, dynamic>> data,
    List<String> datyMiodobran
  ) {
    return data.map((hiveData) {
      List<Map<String, dynamic>> harvests = List<Map<String, dynamic>>.from(hiveData['harvests'] ?? []);

      // Oblicz sumę dla toY
      double total = 0;
      for (var h in harvests) {
        total += (h['value'] as num).toDouble();
      }

      // Tworzenie stack items - sortuj harvests według indeksu daty
      List<BarChartRodStackItem> stackItems = [];
      // WAŻNE: Mały offset startowy rozwiązuje problem fl_chart z niewidocznymi
      // pierwszymi segmentami gdy fromY=0 (znane zachowanie biblioteki)
      const double baseOffset = 0.1;
      double currentY = baseOffset;

      // Najpierw zbierz wszystkie segmenty z wartościami > 0
      List<Map<String, dynamic>> segments = [];
      for (int i = 0; i < datyMiodobran.length; i++) {
        String date = datyMiodobran[i];
        double value = 0;
        for (var h in harvests) {
          if (h['date'] == date) {
            value = (h['value'] as num).toDouble();
            break;
          }
        }
        if (value > 0) {
          segments.add({'index': i, 'value': value});
        }
      }

      // Teraz twórz stackItems w kolejności od dołu do góry
      for (var seg in segments) {
        int i = seg['index'];
        double value = seg['value'];
        Color color = harvestColors[i % harvestColors.length];
        // Dodaj BorderSide żeby segment był widoczny nawet przy problemach renderowania
        stackItems.add(BarChartRodStackItem(
          currentY,
          currentY + value,
          color,
          BorderSide(color: color, width: 0.5),
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

  // Generyczna funkcja do tworzenia stacked bar chart dla pyłku
  List<BarChartGroupData> _generateStackedBarGroupsPylek(
    List<Map<String, dynamic>> data,
    List<String> datyMiodobran
  ) {
    return data.map((hiveData) {
      List<Map<String, dynamic>> harvests = List<Map<String, dynamic>>.from(hiveData['harvests'] ?? []);

      // Oblicz sumę dla toY
      double total = 0;
      for (var h in harvests) {
        total += (h['value'] as num).toDouble();
      }

      // Tworzenie stack items - sortuj harvests według indeksu daty
      List<BarChartRodStackItem> stackItems = [];
      // WAŻNE: Mały offset startowy rozwiązuje problem fl_chart z niewidocznymi
      // pierwszymi segmentami gdy fromY=0 (znane zachowanie biblioteki)
      const double baseOffset = 0.1;
      double currentY = baseOffset;

      // Najpierw zbierz wszystkie segmenty z wartościami > 0
      List<Map<String, dynamic>> segments = [];
      for (int i = 0; i < datyMiodobran.length; i++) {
        String date = datyMiodobran[i];
        double value = 0;
        for (var h in harvests) {
          if (h['date'] == date) {
            value = (h['value'] as num).toDouble();
            break;
          }
        }
        if (value > 0) {
          segments.add({'index': i, 'value': value});
        }
      }

      // Teraz twórz stackItems w kolejności od dołu do góry
      for (var seg in segments) {
        int i = seg['index'];
        double value = seg['value'];
        Color color = harvestColors[i % harvestColors.length];
        // Dodaj BorderSide żeby segment był widoczny nawet przy problemach renderowania
        stackItems.add(BarChartRodStackItem(
          currentY,
          currentY + value,
          color,
          BorderSide(color: color, width: 0.5),
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

  // Widget legendy dla wykresu pyłku - wyrównana do lewej z przyciskiem PDF po prawej
  Widget _buildLegend(
    List<String> datyMiodobran,
    Map<String, double> sumaL, {
    String? rok,
    List<Map<String, dynamic>>? daneZbioru,
    double? totalValue,
  }) {
    if (datyMiodobran.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 80.0, right: 24.0, top: 8.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Legenda pyłku - wyrównana do lewej (układ pionowy jak w miodzie)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: datyMiodobran.asMap().entries.map((entry) {
                int index = entry.key;
                String date = entry.value;
                Color color = harvestColors[index % harvestColors.length];

                // Formatowanie daty do wyświetlenia
                String displayDate = '';
                if (date.length >= 10) {
                  String day = date.substring(8, 10);
                  String month = date.substring(5, 7);
                  if (globals.isEuropeanFormat()) {
                    displayDate = '$day.$month';
                  } else {
                    displayDate = '$month-$day';
                  }
                } else {
                  displayDate = date;
                }

                // Suma litrów dla tego zbioru (wartość w ml, dzielimy przez 1000)
                double litry = (sumaL[date] ?? 0) / 1000;
                // Przeliczenie na kg (gęstość pyłku pszczelego ~0.5 kg/l)
                double kg = litry * 0.5;
                String litryText = litry.toStringAsFixed(2);
                String kgText = kg.toStringAsFixed(2);

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
                      Text(displayDate, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      SizedBox(width: 12),
                      Text('$litryText l', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 8),
                      Text('($kgText kg)', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Przycisk PDF po prawej stronie (pionowy)
          if (rok != null && daneZbioru != null && totalValue != null)
            _generatingPdf
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : InkWell(
                    onTap: () {
                      _showPdfOptionsDialog(
                        typ: 'pylek',
                        rok: rok,
                        daneZbioru: daneZbioru,
                        datyMiodobran: datyMiodobran,
                        sumaL: sumaL,
                        totalValue: totalValue,
                      );
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

  // Widget legendy dla wykresu miodu - wyrównana do lewej od pozycji wykresu
  // z przyciskiem PDF po prawej stronie (pionowo)
  Widget _buildLegendMiod(
    List<String> datyMiodobran,
    Map<String, double> sumaKg, {
    String? rok,
    List<Map<String, dynamic>>? daneZbioru,
    double? totalValue,
  }) {
    if (datyMiodobran.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 80.0, right: 24.0, top: 8.0, bottom: 8.0), // 80 = 70 (reservedSize) + 10 (padding)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Legenda miodobrań - wyrównana do lewej
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: datyMiodobran.asMap().entries.map((entry) {
                int index = entry.key;
                String date = entry.value;
                Color color = harvestColors[index % harvestColors.length];

                // Formatowanie daty do wyświetlenia
                String displayDate = '';
                if (date.length >= 10) {
                  String day = date.substring(8, 10);
                  String month = date.substring(5, 7);
                  if (globals.isEuropeanFormat()) {
                    displayDate = '$day.$month';
                  } else {
                    displayDate = '$month-$day';
                  }
                } else {
                  displayDate = date;
                }

                // Suma kg dla tego miodobrania (wartość jest w gramach, dzielimy przez 1000)
                double kg = (sumaKg[date] ?? 0) / 1000;
                // Przeliczenie na litry (1 litr miodu = 1.45 kg)
                double litry = kg / 1.45;
                String kgText = kg.toStringAsFixed(1);
                String litryText = litry.toStringAsFixed(1);

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
                      Text(displayDate, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      SizedBox(width: 12),
                      Text('$kgText kg', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 8),
                      Text('($litryText l)', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Przycisk PDF po prawej stronie (pionowy)
          if (rok != null && daneZbioru != null && totalValue != null)
            _generatingPdf
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : InkWell(
                    onTap: () {
                      _showPdfOptionsDialog(
                        typ: 'miod',
                        rok: rok,
                        daneZbioru: daneZbioru,
                        datyMiodobran: datyMiodobran,
                        sumaKg: sumaKg,
                        totalValue: totalValue,
                      );
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

  // Dialog z opcjami PDF: widoczne ule, wszystkie ule, wyślij mailem
  void _showPdfOptionsDialog({
    required String typ,
    required String rok,
    required List<Map<String, dynamic>> daneZbioru,
    required List<String> datyMiodobran,
    Map<String, double>? sumaKg,
    Map<String, double>? sumaL, // sumy ml pyłku dla każdego zbioru
    required double totalValue,
  }) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PDF - ${typ == 'miod' ? loc.hOneyHarvest : loc.beePollen} $rok'),
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
                _generateAndSendPdf(
                  typ: typ,
                  rok: rok,
                  daneZbioru: daneZbioru,
                  datyMiodobran: datyMiodobran,
                  sumaKg: sumaKg,
                  sumaL: sumaL,
                  totalValue: totalValue,
                  pasiekaNazwa: loc.aPiary + ' nr ' + globals.pasiekaID.toString(),
                  tylkoWidoczne: true,
                );
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
                _generateAndSendPdf(
                  typ: typ,
                  rok: rok,
                  daneZbioru: daneZbioru,
                  datyMiodobran: datyMiodobran,
                  sumaKg: sumaKg,
                  sumaL: sumaL,
                  totalValue: totalValue,
                  pasiekaNazwa: loc.aPiary + ' nr ' + globals.pasiekaID.toString(),
                  tylkoWidoczne: false,
                );
              },
            ),
            // Opcja 3: Wyślij mailem - zakomentowane (nie działa poprawnie)
            // Divider(),
            // ListTile(
            //   leading: Icon(Icons.email),
            //   title: Text(loc.sendEmail),
            //   onTap: () {
            //     Navigator.of(context).pop();
            //     _generateAndSendPdf(
            //       typ: typ,
            //       rok: rok,
            //       daneZbioru: daneZbioru,
            //       datyMiodobran: datyMiodobran,
            //       sumaKg: sumaKg,
            //       totalValue: totalValue,
            //       pasiekaNazwa: loc.aPiary + ' nr ' + globals.pasiekaID.toString(),
            //       tylkoWidoczne: false,
            //       wyslijMailem: true,
            //     );
            //   },
            // ),
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

  // Funkcja generująca PDF z wykresem miodu/pyłku i wysyłająca mailem
  // typ: 'miod' lub 'pylek'
  // rok: np. '2023', '2024', etc.
  // daneZbioru: dane do wykresu dla WSZYSTKICH uli
  // datyMiodobran: lista dat miodobrań
  // sumaKgMiod: mapa sum kg dla każdego miodobrania (tylko dla miodu)
  // sumaL: mapa sum ml dla każdego zbioru pyłku (tylko dla pyłku)
  // totalKg: całkowita suma kg/g
  // tylkoWidoczne: true = tylko ule z bieżącej strony, false = wszystkie
  // wyslijMailem: true = otwórz klienta poczty po wygenerowaniu
  Future<void> _generateAndSendPdf({
    required String typ, // 'miod' lub 'pylek'
    required String rok,
    required List<Map<String, dynamic>> daneZbioru,
    required List<String> datyMiodobran,
    Map<String, double>? sumaKg,
    Map<String, double>? sumaL, // sumy ml pyłku dla każdego zbioru
    required double totalValue,
    required String pasiekaNazwa,
    bool tylkoWidoczne = false, // true = tylko ule z bieżącej strony
    bool wyslijMailem = false, // true = otwórz klienta poczty
  }) async {
    if (daneZbioru.isEmpty) return;

    // Pobierz teksty lokalizacji przed async
    final loc = AppLocalizations.of(context)!;
    final String honeyHarvestText = loc.hOneyHarvest;
    final String beePollenText = loc.beePollenHarvest; // "Zbiór pyłku" zamiast "pyłek"
    final String totalText = loc.total;
    final String pageText = loc.pAge;
    final String errorText = loc.error;
    final String hiveNumbersText = loc.hiveNumbers;

    setState(() {
      _generatingPdf = true;
    });

    try {
      // Pobierz email z memory
      final memData = Provider.of<Memory>(context, listen: false);
      String email = '';
      if (memData.items.isNotEmpty) {
        email = memData.items[0].email;
      }

      // Stała ilość uli na stronę PDF dla czytelności
      const int uliNaStrone = 20;

      // Przygotuj dane w zależności od opcji
      List<Map<String, dynamic>> allData = [];

      // Mapa uwag dla każdej grupy dat (data -> lista zbiorów z ilością, miarą i uwagami)
      Map<String, List<Map<String, dynamic>>> uwagiDlaGrupyDat = {};

      if (tylkoWidoczne) {
        // Tylko ule z bieżącej strony - użyj istniejących danych
        for (var j = 0; j < hivesNumbers.length; j++) {
          var hiveData = daneZbioru.firstWhere(
            (d) => d['x'] == j + 1,
            orElse: () => {'x': j + 1, 'harvests': []},
          );
          if ((hiveData['harvests'] as List).isNotEmpty) {
            allData.add({
              'nrUla': hivesNumbers[j],
              'harvests': hiveData['harvests'],
            });
          }
        }

        // Upewnij się że datyMiodobran zawiera wszystkie daty z danych
        Set<String> allDatesFromData = {};
        for (var hive in allData) {
          for (var h in (hive['harvests'] as List)) {
            allDatesFromData.add(h['date'] as String);
          }
        }
        // Jeśli są daty których brakuje w datyMiodobran, dodaj je
        for (var date in allDatesFromData) {
          if (!datyMiodobran.contains(date)) {
            datyMiodobran.add(date);
          }
        }
        datyMiodobran.sort();

        // Pobierz uwagi z tabeli zbiory
        final harvestsData = Provider.of<Harvests>(context, listen: false);
        int zasobIdFilter = typ == 'miod' ? 1 : 2; // 1 = miód, 2 = pyłek
        List<Harvest> zbioryFiltered = harvestsData.items.where((h) =>
          h.zasobId == zasobIdFilter && h.pasiekaNr == globals.pasiekaID
        ).toList();

        // Dla każdej daty miodobrania znajdź uwagi (z tolerancją 3 dni dla miodu)
        for (var groupDate in datyMiodobran) {
          DateTime groupDateTime = DateTime.parse(groupDate);
          List<Map<String, dynamic>> zbioryList = [];

          for (var harvest in zbioryFiltered) {
            if (harvest.data.substring(0, 4) != rok) continue;

            String harvestDate = harvest.data.substring(0, 10);
            DateTime harvestDateTime = DateTime.parse(harvestDate);
            int daysDiff = harvestDateTime.difference(groupDateTime).inDays.abs();

            // Dla miodu tolerancja 3 dni, dla pyłku dokładne dopasowanie
            if ((typ == 'miod' && daysDiff <= 3) || (typ == 'pylek' && daysDiff == 0)) {
              zbioryList.add({
                'ilosc': harvest.ilosc,
                'miara': harvest.miara,
                'uwagi': harvest.uwagi,
              });
            }
          }

          if (zbioryList.isNotEmpty) {
            uwagiDlaGrupyDat[groupDate] = zbioryList;
          }
        }
      } else {
        // Wszystkie ule - przelicz dane od nowa z infos
        final infosData = Provider.of<Infos>(context, listen: false);
        final dod1Data = Provider.of<Dodatki1>(context, listen: false);
        final dod1 = dod1Data.items;

        List<Info> infos = infosData.items.where((inf) => inf.kategoria == 'harvest').toList();

        // Stringi do rozpoznawania typu zbioru
        String honeySmall = loc.honey + " = " + loc.small + " " + loc.frame + " x";
        String honeyBig = loc.honey + " = " + loc.big + " " + loc.frame + " x";
        String honeyKg = loc.honey + " = ";
        String pylekPorcja = loc.beePollen + "  = " + loc.portion + " x";
        String pylekMiarka = loc.beePollen + "  = " + loc.miarka + " x";
        String pylekMl = loc.beePollen + " = ";
        String pylekL = " " + loc.beePollen + " =  ";

        int b = dod1.isNotEmpty ? int.parse(dod1[0].b) : 250;
        int g = dod1.isNotEmpty ? int.parse(dod1[0].g) : 100;

        // Zbierz wszystkie unikalne daty dla tego roku
        Set<String> uniqueDates = {};
        for (var info in infos) {
          if (info.data.substring(0, 4) == rok) {
            String date = info.data.substring(0, 10);
            double val = typ == 'miod'
                ? _obliczMiod(info, b, honeySmall, honeyBig, honeyKg)
                : _obliczPylek(info, g, pylekPorcja, pylekMiarka, pylekMl, pylekL);
            if (val > 0) uniqueDates.add(date);
          }
        }

        // Grupuj bliskie daty (tylko dla miodu)
        Map<String, String> dateMapping = typ == 'miod'
            ? _grupujBliskieDaty(uniqueDates)
            : Map.fromEntries(uniqueDates.map((d) => MapEntry(d, d)));

        // Aktualizuj datyMiodobran - użyj nowo obliczonych dat dla wszystkich uli
        datyMiodobran.clear();
        Set<String> groupedDates = dateMapping.values.toSet();
        List<String> sortedGroupedDates = groupedDates.toList()..sort();
        datyMiodobran.addAll(sortedGroupedDates);

        // Dla każdego ula oblicz zbiory
        for (var nrUla in allHivesNumbers) {
          Map<String, double> harvests = {};

          for (var info in infos) {
            if (info.data.substring(0, 4) == rok && info.ulNr == nrUla) {
              String date = info.data.substring(0, 10);
              double val = typ == 'miod'
                  ? _obliczMiod(info, b, honeySmall, honeyBig, honeyKg)
                  : _obliczPylek(info, g, pylekPorcja, pylekMiarka, pylekMl, pylekL);

              if (val > 0) {
                String groupDate = dateMapping[date] ?? date;
                harvests[groupDate] = (harvests[groupDate] ?? 0) + val;
              }
            }
          }

          if (harvests.isNotEmpty) {
            List<Map<String, dynamic>> harvestsList = harvests.entries
                .map((e) => {"date": e.key, "value": e.value})
                .toList();
            allData.add({
              'nrUla': nrUla,
              'harvests': harvestsList,
            });
          }
        }

        // Pobierz uwagi z tabeli zbiory
        final harvestsData = Provider.of<Harvests>(context, listen: false);
        int zasobIdFilter = typ == 'miod' ? 1 : 2; // 1 = miód, 2 = pyłek
        List<Harvest> zbioryFiltered = harvestsData.items.where((h) =>
          h.zasobId == zasobIdFilter && h.pasiekaNr == globals.pasiekaID
        ).toList();

        for (var groupDate in datyMiodobran) {
          DateTime groupDateTime = DateTime.parse(groupDate);
          List<Map<String, dynamic>> zbioryList = [];

          for (var harvest in zbioryFiltered) {
            if (harvest.data.substring(0, 4) != rok) continue;

            String harvestDate = harvest.data.substring(0, 10);
            DateTime harvestDateTime = DateTime.parse(harvestDate);
            int daysDiff = harvestDateTime.difference(groupDateTime).inDays.abs();

            // Dla miodu tolerancja 3 dni, dla pyłku dokładne dopasowanie
            if ((typ == 'miod' && daysDiff <= 3) || (typ == 'pylek' && daysDiff == 0)) {
              zbioryList.add({
                'ilosc': harvest.ilosc,
                'miara': harvest.miara,
                'uwagi': harvest.uwagi,
              });
            }
          }

          if (zbioryList.isNotEmpty) {
            uwagiDlaGrupyDat[groupDate] = zbioryList;
          }
        }
      }

      if (allData.isEmpty) {
        setState(() {
          _generatingPdf = false;
        });
        return;
      }

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

      // Współczynnik przeliczeniowy (gramy na kg dla miodu, ml na litry dla pyłku)
      double dzielnik = 1000; // dla obu typów: miód g->kg, pyłek ml->l

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
        maxValue = maxValue / dzielnik;
        // Zaokrąglij do góry do ładnej wartości
        if (maxValue > 0) {
          if (typ == 'miod') {
            // Dla miodu (kg) - zaokrąglij do dziesiątek
            maxValue = ((maxValue / 10).ceil() * 10).toDouble();
            if (maxValue < 10) maxValue = 10;
          } else {
            // Dla pyłku (litry) - mniejsze kroki zaokrąglania
            if (maxValue <= 1) {
              maxValue = (maxValue * 10).ceil() / 10; // zaokrąglij do 0.1
              if (maxValue < 0.5) maxValue = 0.5;
            } else if (maxValue <= 5) {
              maxValue = (maxValue * 2).ceil() / 2; // zaokrąglij do 0.5
            } else if (maxValue <= 20) {
              maxValue = maxValue.ceil().toDouble(); // zaokrąglij do 1
            } else {
              maxValue = ((maxValue / 5).ceil() * 5).toDouble(); // zaokrąglij do 5
            }
          }
        }

        // Oblicz etykiety osi Y (5 poziomów)
        int numYLabels = 5;
        List<double> yLabels = [];
        for (int i = 0; i <= numYLabels; i++) {
          yLabels.add((maxValue / numYLabels) * i);
        }

        // Jednostka osi Y
        String jednostkaY = typ == 'miod' ? 'kg' : 'l';

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
                      typ == 'miod'
                          ? '${honeyHarvestText} $rok - $pasiekaNazwa'
                          : '${beePollenText} $rok - $pasiekaNazwa',
                      style: pw.TextStyle(fontSize: 18, font: fontBold),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Center(
                    child: pw.Text(
                      typ == 'miod'
                          ? '${totalText}: ${(totalValue / 1000).toStringAsFixed(2)} kg (${(totalValue / 1000 / 1.45).toStringAsFixed(2)} l)'
                          : '${totalText}: ${(totalValue / 1000).toStringAsFixed(2)} l (${(totalValue / 1000 * 0.5).toStringAsFixed(2)} kg)', // dane w ml; gęstość pyłku ~0.5 kg/l
                      style: pw.TextStyle(fontSize: 12, font: fontRegular),
                    ),
                  ),
                  if (liczbaStron > 1)
                    pw.Center(
                      child: pw.Text(
                        '${pageText} ${strona + 1} / $liczbaStron',
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
                              // Etykiety Y pozycjonowane precyzyjnie względem siatki
                              for (int i = 0; i <= numYLabels; i++)
                                pw.Positioned(
                                  right: 4,
                                  top: chartTopOffset + ((numYLabels - i) / numYLabels) * maxBarHeight - 4, // chartTopOffset + pozycja - 4 dla wyrównania środka tekstu
                                  child: pw.Text(
                                    typ == 'miod'
                                        ? '${yLabels[i].toStringAsFixed(0)} $jednostkaY'
                                        : '${yLabels[i].toStringAsFixed(2)} $jednostkaY',
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
                                    List harvests = hive['harvests'] as List;

                                    // Sortuj harvests NAJPIERW, żeby używać tej samej listy wszędzie
                                    List<Map<String, dynamic>> sortedHarvests = List<Map<String, dynamic>>.from(harvests);
                                    sortedHarvests.sort((a, b) {
                                      int idxA = datyMiodobran.indexOf(a['date']);
                                      int idxB = datyMiodobran.indexOf(b['date']);
                                      return idxA.compareTo(idxB);
                                    });

                                    // Oblicz sumę surowych wartości RAZ - używając posortowanej listy
                                    double totalHiveRaw = 0;
                                    for (var h in sortedHarvests) {
                                      totalHiveRaw += (h['value'] as num).toDouble();
                                    }
                                    double totalHive = totalHiveRaw / dzielnik;

                                    // Oblicz wysokość słupka używając tej samej wartości bazowej
                                    double barHeight = maxValue > 0
                                        ? (totalHive / maxValue) * maxSlupekHeight
                                        : 0;

                                    return pw.Column(
                                      mainAxisAlignment: pw.MainAxisAlignment.end,
                                      children: [
                                        // Wartość nad słupkiem (kg dla miodu i pyłku)
                                        pw.Text(
                                          totalHive.toStringAsFixed(typ == 'miod' ? 1 : 2),
                                          style: pw.TextStyle(fontSize: 7, font: fontRegular),
                                        ),
                                        pw.SizedBox(height: 2),
                                        // Słupek (stackowany) - segmenty posortowane wg daty od dołu do góry
                                        // Używamy Stack zamiast Column żeby uniknąć problemów z renderowaniem
                                        pw.Container(
                                          width: pageData.length <= 10 ? 25 : 15,
                                          height: barHeight > 0 ? barHeight : 1,
                                          child: pw.Stack(
                                            children: () {
                                              // Oblicz wysokości segmentów używając proporcji surowych wartości
                                              List<double> segmentHeights = [];
                                              for (int i = 0; i < sortedHarvests.length; i++) {
                                                double rv = (sortedHarvests[i]['value'] as num).toDouble();
                                                double sh = totalHiveRaw > 0 && barHeight > 0
                                                    ? (rv / totalHiveRaw) * barHeight
                                                    : 0;
                                                segmentHeights.add(sh);
                                              }

                                              // Skoryguj pierwszy segment (najniższy), żeby suma była DOKŁADNIE równa barHeight
                                              if (segmentHeights.isNotEmpty && barHeight > 0) {
                                                double sumSegs = segmentHeights.fold(0.0, (a, b) => a + b);
                                                double diff = barHeight - sumSegs;
                                                segmentHeights[0] = segmentHeights[0] + diff;
                                              }

                                              // Buduj segmenty od dołu do góry używając pozycji absolutnych
                                              List<pw.Widget> segments = [];
                                              double currentBottom = 0;
                                              double barWidth = pageData.length <= 10 ? 25.0 : 15.0;

                                              // sortedHarvests[0] = najstarsza data (na dole), więc iterujemy normalnie
                                              for (int i = 0; i < sortedHarvests.length; i++) {
                                                var h = sortedHarvests[i];
                                                int idx = datyMiodobran.indexOf(h['date']);
                                                double segmentHeight = segmentHeights[i];
                                                PdfColor color = _getPdfColor(idx >= 0 ? idx : 0);

                                                segments.add(pw.Positioned(
                                                  left: 0,
                                                  right: 0,
                                                  bottom: currentBottom,
                                                  child: pw.Container(
                                                    width: barWidth,
                                                    height: segmentHeight,
                                                    color: color,
                                                  ),
                                                ));
                                                currentBottom += segmentHeight;
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
                                          angle: 1.5708, // +90 stopni (obrót o 180° względem poprzedniego)
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
                    margin: const pw.EdgeInsets.only(left: 40, top: 0, bottom: 15), // więcej miejsca przed legendą
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
                      children: datyMiodobran.asMap().entries.map((entry) {
                        int index = entry.key;
                        String date = entry.value;
                        PdfColor color = _getPdfColor(index);

                        String displayDate = '';
                        if (date.length >= 10) {
                          String day = date.substring(8, 10);
                          String month = date.substring(5, 7);
                          displayDate = globals.isEuropeanFormat() ? '$day.$month' : '$month-$day';
                        } else {
                          displayDate = date;
                        }

                        String kgInfo = '';
                        if (typ == 'miod' && sumaKg != null) {
                          double kg = (sumaKg[date] ?? 0) / 1000;
                          double litry = kg / 1.45;
                          kgInfo = ' - ${kg.toStringAsFixed(1)} kg (${litry.toStringAsFixed(1)} l)';
                        } else if (typ == 'pylek' && sumaL != null) {
                          double litry = (sumaL[date] ?? 0) / 1000;
                          double kg = litry * 0.5;
                          kgInfo = ' - ${litry.toStringAsFixed(2)} l (${kg.toStringAsFixed(2)} kg)';
                        }

                        // Uwagi dla tej daty
                        List<Map<String, dynamic>> zbioryList = uwagiDlaGrupyDat[date] ?? [];
                        String uwagiText = '';
                        if (zbioryList.isNotEmpty) {
                          List<String> zbiorTeksty = zbioryList.map((zbior) {
                            double ilosc = (zbior['ilosc'] as num?)?.toDouble() ?? 0.0;
                            int miara = (zbior['miara'] as num?)?.toInt() ?? 1;
                            String uwagi = (zbior['uwagi'] as String?) ?? '';
                            String jednostka = miara == 1 ? 'l' : 'kg';
                            String iloscStr = ilosc.toStringAsFixed(1).replaceAll('.', ',');
                            return uwagi.isNotEmpty
                                ? '$iloscStr $jednostka - $uwagi'
                                : '$iloscStr $jednostka';
                          }).toList();
                          uwagiText = zbiorTeksty.join('; ');
                        }

                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Kwadracik z kolorem
                              pw.Container(
                                width: 12,
                                height: 12,
                                color: color,
                              ),
                              pw.SizedBox(width: 4),
                              // Data + kgInfo (stała szerokość)
                              pw.Container(
                                width: 130,
                                child: pw.Text('$displayDate$kgInfo', style: pw.TextStyle(fontSize: 9, font: fontRegular)),
                              ),
                              pw.SizedBox(width: 10),
                              // Uwagi (elastyczna szerokość)
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

      // Zapisz PDF i udostępnij/wyślij mailem
      final Uint8List pdfBytes = await pdf.save();
      final String fileName = typ == 'miod'
          ? 'miod_${rok}_${DateTime.now().millisecondsSinceEpoch}.pdf'
          : 'pylek_${rok}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Wyłącz kółko oczekiwania PRZED otwarciem dialogu/udostępniania
      if (mounted) {
        setState(() {
          _generatingPdf = false;
        });
      }

      // Jeśli wybrano opcję wysłania mailem
      if (wyslijMailem) {
        if (email.isNotEmpty) {
          // Pokaż dialog potwierdzenia przed wysyłką
          if (mounted) {
            final bool? confirmed = await showDialog<bool>(
              context: this.context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: Text(loc.sendEmail),
                  content: Text('${loc.sendReportToEmail}\n$email?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(loc.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(loc.send),
                    ),
                  ],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                );
              },
            );

            if (confirmed == true) {
              // Zapisz PDF do pliku tymczasowego
              final tempDir = await getTemporaryDirectory();
              final tempFile = File('${tempDir.path}/$fileName');
              await tempFile.writeAsBytes(pdfBytes);

              // Przygotuj dane do emaila
              final String subject = typ == 'miod'
                  ? '${honeyHarvestText} $rok - $pasiekaNazwa'
                  : '${beePollenText} $rok - $pasiekaNazwa';
              final String body = typ == 'miod'
                  ? '${totalText}: ${(totalValue / 1000).toStringAsFixed(2)} kg (${(totalValue / 1000 / 1.45).toStringAsFixed(2)} l)'
                  : '${totalText}: ${(totalValue / 1000).toStringAsFixed(2)} l (${(totalValue / 1000 * 0.5).toStringAsFixed(2)} kg)';

              // Udostępnij PDF z wymuszeniem opcji email
              await Share.shareXFiles(
                [XFile(tempFile.path)],
                subject: subject,
                text: '$body\n\n${loc.attachedPdf}',
              );
            }
          }
        } else {
          // Brak emaila w aplikacji - pokaż komunikat
          if (mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(content: Text(loc.noEmailConfigured)),
            );
          }
        }
      } else {
        // Użyj Printing do podglądu/udostępnienia (dla opcji drukowania)
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: fileName,
        );
      }

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

  // Funkcje generujące - teraz używają generycznej funkcji
  void _generateBarGroupsMiod2023() {
    barGroupsMiod2023 = _generateStackedBarGroupsMiod(daneZbioruMioduDoWykresu2023, datyMiodobranMiod2023);
  }
  void _generateBarGroupsMiod2024() {
    barGroupsMiod2024 = _generateStackedBarGroupsMiod(daneZbioruMioduDoWykresu2024, datyMiodobranMiod2024);
  }
  void _generateBarGroupsMiod2025() {
    barGroupsMiod2025 = _generateStackedBarGroupsMiod(daneZbioruMioduDoWykresu2025, datyMiodobranMiod2025);
  }
  void _generateBarGroupsMiod2026() {
    barGroupsMiod2026 = _generateStackedBarGroupsMiod(daneZbioruMioduDoWykresu2026, datyMiodobranMiod2026);
  }
  void _generateBarGroupsMiod2027() {
    barGroupsMiod2027 = _generateStackedBarGroupsMiod(daneZbioruMioduDoWykresu2027, datyMiodobranMiod2027);
  }
  void _generateBarGroupsMiod2028() {
    barGroupsMiod2028 = _generateStackedBarGroupsMiod(daneZbioruMioduDoWykresu2028, datyMiodobranMiod2028);
  }
  void _generateBarGroupsMiod2029() {
    barGroupsMiod2029 = _generateStackedBarGroupsMiod(daneZbioruMioduDoWykresu2029, datyMiodobranMiod2029);
  }
  void _generateBarGroupsMiod2030() {
    barGroupsMiod2030 = _generateStackedBarGroupsMiod(daneZbioruMioduDoWykresu2030, datyMiodobranMiod2030);
  }

  void _generateBarGroupsPylek2023() {
    barGroupsPylek2023 = _generateStackedBarGroupsPylek(daneZbioruPylkuDoWykresu2023, datyMiodobranPylek2023);
  }
  void _generateBarGroupsPylek2024() {
    barGroupsPylek2024 = _generateStackedBarGroupsPylek(daneZbioruPylkuDoWykresu2024, datyMiodobranPylek2024);
  }
  void _generateBarGroupsPylek2025() {
    barGroupsPylek2025 = _generateStackedBarGroupsPylek(daneZbioruPylkuDoWykresu2025, datyMiodobranPylek2025);
  }
  void _generateBarGroupsPylek2026() {
    barGroupsPylek2026 = _generateStackedBarGroupsPylek(daneZbioruPylkuDoWykresu2026, datyMiodobranPylek2026);
  }
  void _generateBarGroupsPylek2027() {
    barGroupsPylek2027 = _generateStackedBarGroupsPylek(daneZbioruPylkuDoWykresu2027, datyMiodobranPylek2027);
  }
  void _generateBarGroupsPylek2028() {
    barGroupsPylek2028 = _generateStackedBarGroupsPylek(daneZbioruPylkuDoWykresu2028, datyMiodobranPylek2028);
  }
  void _generateBarGroupsPylek2029() {
    barGroupsPylek2029 = _generateStackedBarGroupsPylek(daneZbioruPylkuDoWykresu2029, datyMiodobranPylek2029);
  }
  void _generateBarGroupsPylek2030() {
    barGroupsPylek2030 = _generateStackedBarGroupsPylek(daneZbioruPylkuDoWykresu2030, datyMiodobranPylek2030);
  }



  @override
  Widget build(BuildContext context) {
    //uzyskanie dostępu do danych w pamięci
    // final memData = Provider.of<Memory>(context, listen: false);
    // final mem = memData.items;
    final dod1Data = Provider.of<Dodatki1>(context);
    final dod1 = dod1Data.items;

    // Zerowanie zmiennych przed każdym buildowaniem (zapobiega kumulacji wartości)
    miod2023 = 0; miod2024 = 0; miod2025 = 0; miod2026 = 0;
    miod2027 = 0; miod2028 = 0; miod2029 = 0; miod2030 = 0;
    allMiod2023 = 0; allMiod2024 = 0; allMiod2025 = 0; allMiod2026 = 0;
    allMiod2027 = 0; allMiod2028 = 0; allMiod2029 = 0; allMiod2030 = 0;
    pylek2023 = 0; pylek2024 = 0; pylek2025 = 0; pylek2026 = 0;
    pylek2027 = 0; pylek2028 = 0; pylek2029 = 0; pylek2030 = 0;
    allPylek2023 = 0; allPylek2024 = 0; allPylek2025 = 0; allPylek2026 = 0;
    allPylek2027 = 0; allPylek2028 = 0; allPylek2029 = 0; allPylek2030 = 0;

    //pobranie danych info z wybranej kategorii - zbiory
    final infosData = Provider.of<Infos>(context);
    List<Info> infos = infosData.items.where((inf) {
      return inf.kategoria == ('harvest');
    }).toList();

    //poszukanie najstarszego roku w wybranej kategorii (do wyboru daty do ststystyk)
    int odRoku = int.parse(DateTime.now().toString().substring(0, 4)); //biezący rok
    for (var i = 0; i < infos.length; i++) {
      if(odRoku > int.parse(infos[i].data.substring(0, 4)))
        odRoku = int.parse(infos[i].data.substring(0, 4));
    }
   
   
    //TWORZENIE DANYCH DO WYKRESóW
   //print('infos = ${infos.length}');

    // Pomocnicza funkcja do obliczania wartości miodu
    double obliczMiod(Info info, double dm, int b) {
      String honeySmall = AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x";
      String honeyBig = AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x";
      String honeyKg = AppLocalizations.of(context)!.honey + " = ";

      if (info.parametr == honeySmall && info.wartosc.isNotEmpty) {
        double dmVal = info.pogoda == '' ? 35175 : double.parse(info.pogoda);
        return double.parse(info.wartosc) * b * dmVal / 10000;
      }
      if (info.parametr == honeyBig && info.wartosc.isNotEmpty) {
        double dmVal = info.pogoda == '' ? 78725 : double.parse(info.pogoda);
        return double.parse(info.wartosc) * b * dmVal / 10000;
      }
      if (info.parametr == honeyKg && info.wartosc.isNotEmpty) {
        return double.parse(info.wartosc) * 1000;
      }
      return 0;
    }

    // Pomocnicza funkcja do obliczania wartości pyłku
    double obliczPylek(Info info, int g) {
      String pylekPorcja = AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.portion + " x";
      String pylekMiarka = AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x";
      String pylekMl = AppLocalizations.of(context)!.beePollen + " = ";
      String pylekL = " " + AppLocalizations.of(context)!.beePollen + " =  ";

      if ((info.parametr == pylekPorcja || info.parametr == pylekMiarka) && info.wartosc.isNotEmpty) {
        return (int.parse(info.wartosc) * g).toDouble();
      }
      if (info.parametr == pylekMl && info.wartosc.isNotEmpty) {
        return int.parse(info.wartosc).toDouble();
      }
      if (info.parametr == pylekL && info.wartosc.isNotEmpty) {
        return double.parse(info.wartosc) * 1000;
      }
      return 0;
    }

    // Funkcja do przetwarzania danych dla danego roku
    void processYear(
      String rok,
      Function(double) addAllMiod,
      Function(int) addAllPylek,
      Function(double) addMiod,
      Function(int) addPylek,
      List<Map<String, dynamic>> daneZbioruMiodu,
      List<Map<String, dynamic>> daneZbioruPylku,
      List<String> datyMiodobranMiod,
      List<String> datyMiodobranPylek,
      Function generateBarMiod,
      Function generateBarPylek,
      Map<String, double> sumaKgMiod, // mapa sum kg dla każdego zgrupowanego miodobrania
      Map<String, double> sumaLPylek, // mapa sum ml dla każdego zbioru pyłku
    ) {
      // Wyczyść listy przed ponownym wypełnieniem (zapobiega powielaniu słupków)
      daneZbioruMiodu.clear();
      daneZbioruPylku.clear();
      datyMiodobranMiod.clear();
      datyMiodobranPylek.clear();
      sumaKgMiod.clear();
      sumaLPylek.clear();

      Set<String> uniqueDatesMiod = {};
      Set<String> uniqueDatesPylek = {};

      // Zbierz wszystkie unikalne daty miodobrań dla tego roku (przed grupowaniem)
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == rok) {
          String date = infos[i].data.substring(0, 10); // YYYY-MM-DD
          double miodVal = obliczMiod(infos[i], dm, int.parse(dod1[0].b));
          double pylekVal = obliczPylek(infos[i], int.parse(dod1[0].g));
          if (miodVal > 0) uniqueDatesMiod.add(date);
          if (pylekVal > 0) uniqueDatesPylek.add(date);
        }
      }

      // Grupuj bliskie daty miodu (0-3 dni = to samo miodobranie)
      Map<String, String> dateMappingMiod = _grupujBliskieDaty(uniqueDatesMiod);

      // Unikalne daty grup (posortowane)
      Set<String> groupedDatesMiod = dateMappingMiod.values.toSet();
      List<String> sortedGroupedDatesMiod = groupedDatesMiod.toList()..sort();
      datyMiodobranMiod.addAll(sortedGroupedDatesMiod);

      // Pyłek bez grupowania
      List<String> sortedDatesPylek = uniqueDatesPylek.toList()..sort();
      datyMiodobranPylek.addAll(sortedDatesPylek);

      // Suma z wszystkich uli
      for (var j = 1; j < allHivesNumbers.length + 1; j++) {
        for (var i = 0; i < infos.length; i++) {
          if (infos[i].data.substring(0, 4) == rok) {
            if (infos[i].ulNr == allHivesNumbers[j - 1]) {
              double miodVal = obliczMiod(infos[i], dm, int.parse(dod1[0].b));
              double pylekVal = obliczPylek(infos[i], int.parse(dod1[0].g));
              addAllMiod(miodVal);
              addAllPylek(pylekVal.toInt());

              // Dodaj do sumy kg dla zgrupowanej daty
              if (miodVal > 0) {
                String date = infos[i].data.substring(0, 10);
                String groupDate = dateMappingMiod[date] ?? date;
                sumaKgMiod[groupDate] = (sumaKgMiod[groupDate] ?? 0) + miodVal;
              }

              // Dodaj do sumy ml dla daty pyłku
              if (pylekVal > 0) {
                String date = infos[i].data.substring(0, 10);
                sumaLPylek[date] = (sumaLPylek[date] ?? 0) + pylekVal;
              }
            }
          }
        }
      }

      // Dla każdego ula na prezentowanej stronie
      for (var j = 1; j < hivesNumbers.length + 1; j++) {
        Map<String, double> harvestsMiod = {}; // zgrupowana data -> wartość
        Map<String, double> harvestsPylek = {};
        double sumaMiod = 0;
        double sumaPylek = 0;

        for (var i = 0; i < infos.length; i++) {
          if (infos[i].data.substring(0, 4) == rok) {
            if (infos[i].ulNr == hivesNumbers[j - 1]) {
              String date = infos[i].data.substring(0, 10);
              double miodVal = obliczMiod(infos[i], dm, int.parse(dod1[0].b));
              double pylekVal = obliczPylek(infos[i], int.parse(dod1[0].g));

              if (miodVal > 0) {
                // Użyj zgrupowanej daty
                String groupDate = dateMappingMiod[date] ?? date;
                harvestsMiod[groupDate] = (harvestsMiod[groupDate] ?? 0) + miodVal;
                sumaMiod += miodVal;
                addMiod(miodVal);
              }
              if (pylekVal > 0) {
                harvestsPylek[date] = (harvestsPylek[date] ?? 0) + pylekVal;
                sumaPylek += pylekVal;
                addPylek(pylekVal.toInt());
              }
            }
          }
        }


        // Konwertuj mapę na listę
        if (sumaMiod > 0) {
          List<Map<String, dynamic>> harvestsList = harvestsMiod.entries
              .map((e) => {"date": e.key, "value": e.value})
              .toList();
          daneZbioruMiodu.add({
            "x": j,
            "harvests": harvestsList,
          });
        }
        if (sumaPylek > 0) {
          List<Map<String, dynamic>> harvestsList = harvestsPylek.entries
              .map((e) => {"date": e.key, "value": e.value})
              .toList();
          daneZbioruPylku.add({
            "x": j,
            "harvests": harvestsList,
          });
        }
      }

      if (daneZbioruMiodu.isNotEmpty) generateBarMiod();
      if (daneZbioruPylku.isNotEmpty) generateBarPylek();
    }

    //2023
    processYear(
      '2023',
      (val) => allMiod2023 += val,
      (val) => allPylek2023 += val,
      (val) => miod2023 += val,
      (val) => pylek2023 += val,
      daneZbioruMioduDoWykresu2023,
      daneZbioruPylkuDoWykresu2023,
      datyMiodobranMiod2023,
      datyMiodobranPylek2023,
      _generateBarGroupsMiod2023,
      _generateBarGroupsPylek2023,
      sumaKgMiod2023,
      sumaLPylek2023,
    );
//===============================================================================================

    //2024
    processYear(
      '2024',
      (val) => allMiod2024 += val,
      (val) => allPylek2024 += val,
      (val) => miod2024 += val,
      (val) => pylek2024 += val,
      daneZbioruMioduDoWykresu2024,
      daneZbioruPylkuDoWykresu2024,
      datyMiodobranMiod2024,
      datyMiodobranPylek2024,
      _generateBarGroupsMiod2024,
      _generateBarGroupsPylek2024,
      sumaKgMiod2024,
      sumaLPylek2024,
    );
  //==================================================================================


    //2025
    processYear(
      '2025',
      (val) => allMiod2025 += val,
      (val) => allPylek2025 += val,
      (val) => miod2025 += val,
      (val) => pylek2025 += val,
      daneZbioruMioduDoWykresu2025,
      daneZbioruPylkuDoWykresu2025,
      datyMiodobranMiod2025,
      datyMiodobranPylek2025,
      _generateBarGroupsMiod2025,
      _generateBarGroupsPylek2025,
      sumaKgMiod2025,
      sumaLPylek2025,
    );
  //===============================================================================================

    //2026
    processYear(
      '2026',
      (val) => allMiod2026 += val,
      (val) => allPylek2026 += val,
      (val) => miod2026 += val,
      (val) => pylek2026 += val,
      daneZbioruMioduDoWykresu2026,
      daneZbioruPylkuDoWykresu2026,
      datyMiodobranMiod2026,
      datyMiodobranPylek2026,
      _generateBarGroupsMiod2026,
      _generateBarGroupsPylek2026,
      sumaKgMiod2026,
      sumaLPylek2026,
    );
//===============================================================================================

    //2027
    processYear(
      '2027',
      (val) => allMiod2027 += val,
      (val) => allPylek2027 += val,
      (val) => miod2027 += val,
      (val) => pylek2027 += val,
      daneZbioruMioduDoWykresu2027,
      daneZbioruPylkuDoWykresu2027,
      datyMiodobranMiod2027,
      datyMiodobranPylek2027,
      _generateBarGroupsMiod2027,
      _generateBarGroupsPylek2027,
      sumaKgMiod2027,
      sumaLPylek2027,
    );
    //===============================================================================================

    //2028
    processYear(
      '2028',
      (val) => allMiod2028 += val,
      (val) => allPylek2028 += val,
      (val) => miod2028 += val,
      (val) => pylek2028 += val,
      daneZbioruMioduDoWykresu2028,
      daneZbioruPylkuDoWykresu2028,
      datyMiodobranMiod2028,
      datyMiodobranPylek2028,
      _generateBarGroupsMiod2028,
      _generateBarGroupsPylek2028,
      sumaKgMiod2028,
      sumaLPylek2028,
    );
   //===============================================================================================

    //2029
    processYear(
      '2029',
      (val) => allMiod2029 += val,
      (val) => allPylek2029 += val,
      (val) => miod2029 += val,
      (val) => pylek2029 += val,
      daneZbioruMioduDoWykresu2029,
      daneZbioruPylkuDoWykresu2029,
      datyMiodobranMiod2029,
      datyMiodobranPylek2029,
      _generateBarGroupsMiod2029,
      _generateBarGroupsPylek2029,
      sumaKgMiod2029,
      sumaLPylek2029,
    );
  //===============================================================================================

    //2030
    processYear(
      '2030',
      (val) => allMiod2030 += val,
      (val) => allPylek2030 += val,
      (val) => miod2030 += val,
      (val) => pylek2030 += val,
      daneZbioruMioduDoWykresu2030,
      daneZbioruPylkuDoWykresu2030,
      datyMiodobranMiod2030,
      datyMiodobranPylek2030,
      _generateBarGroupsMiod2030,
      _generateBarGroupsPylek2030,
      sumaKgMiod2030,
      sumaLPylek2030,
    );
//===============================================================================================


    final ButtonStyle buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(2.0),
      backgroundColor: Theme.of(context).primaryColor, //Color.fromARGB(255, 233, 140, 0),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(66.0, 35.0),
      //textStyle: const TextStyle(color: Color.fromARGB(255, 162, 103, 0),)
    );
    final ButtonStyle buttonOffStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(2.0),
      backgroundColor: Color.fromARGB(255, 211, 211, 211),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(66.0, 35.0),
      //textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    );

    // wybór roku do raportowania
    void _showAlertYear() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectReportYear),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokRaportow = 'wszystkie';
                Navigator.of(context).pushNamed(
                    RaportColorScreen.routeName,
                  );
              }, child: globals.rokRaportow == 'wszystkie'
                        ? Text(('> ${AppLocalizations.of(context)!.aLl} <'),style: TextStyle(fontSize: 18))
                        : Text((AppLocalizations.of(context)!.aLl),style: TextStyle(fontSize: 18))
              ), 
            if(2023 <= int.parse(DateTime.now().toString().substring(0, 4)) && 2023 >= odRoku)
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokRaportow = '2023';
                Navigator.of(context).pushNamed(
                    RaportColorScreen.routeName,
                  );
              }, child: globals.rokRaportow == '2023'
                        ? Text(('> 2023 <'),style: TextStyle(fontSize: 18))
                        : Text(('2023'),style: TextStyle(fontSize: 18))
              ), 
            if(2024 <= int.parse(DateTime.now().toString().substring(0, 4)) && 2024 >= odRoku)  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokRaportow = '2024';
                Navigator.of(context).pushNamed(
                    RaportColorScreen.routeName, 
                );
              }, child: globals.rokRaportow == '2024'
                        ? Text(('> 2024 <'),style: TextStyle(fontSize: 18))
                        : Text(('2024'),style: TextStyle(fontSize: 18))
              ),
            if(2025 <= int.parse(DateTime.now().toString().substring(0, 4)) && 2025 >= odRoku)  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokRaportow = '2025';
                Navigator.of(context).pushNamed(
                    RaportColorScreen.routeName, 
                );
              }, child: globals.rokRaportow == '2025'
                        ? Text(('> 2025 <'),style: TextStyle(fontSize: 18))
                        : Text(('2025'),style: TextStyle(fontSize: 18))
              ),
            if(2026 <= int.parse(DateTime.now().toString().substring(0, 4)) && 2026 >= odRoku)  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokRaportow = '2026';
                Navigator.of(context).pushNamed(
                    RaportColorScreen.routeName, 
                );
              }, child: globals.rokRaportow == '2026'
                        ? Text(('> 2026 <'),style: TextStyle(fontSize: 18))
                        : Text(('2026'),style: TextStyle(fontSize: 18))
              ),
            if(2027 <= int.parse(DateTime.now().toString().substring(0, 4)) && 2027 >= odRoku)  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokRaportow = '2027';
                Navigator.of(context).pushNamed(
                    RaportColorScreen.routeName, 
                );
              }, child: globals.rokRaportow == '2027'
                        ? Text(('> 2027 <'),style: TextStyle(fontSize: 18))
                        : Text(('2027'),style: TextStyle(fontSize: 18))
              ),
            if(2028 <= int.parse(DateTime.now().toString().substring(0, 4)) && 2028 >= odRoku)  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokRaportow = '2028';
                Navigator.of(context).pushNamed(
                    RaportColorScreen.routeName, 
                );
              }, child: globals.rokRaportow == '2028'
                        ? Text(('> 2028 <'),style: TextStyle(fontSize: 18))
                        : Text(('2028'),style: TextStyle(fontSize: 18))
              ),
            if(2029 <= int.parse(DateTime.now().toString().substring(0, 4)) && 2029 >= odRoku)  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokRaportow = '2029';
                Navigator.of(context).pushNamed(
                    RaportColorScreen.routeName, 
                );
              }, child: globals.rokRaportow == '2029'
                        ? Text(('> 2029 <'),style: TextStyle(fontSize: 18))
                        : Text(('2029'),style: TextStyle(fontSize: 18))
              ),
            if(2030 <= int.parse(DateTime.now().toString().substring(0, 4)) && 2030 >= odRoku)  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokRaportow = '2030';
                Navigator.of(context).pushNamed(
                    RaportColorScreen.routeName, 
                );
              }, child: globals.rokRaportow == '2030'
                        ? Text(('> 2030 <'),style: TextStyle(fontSize: 18))
                        : Text(('2030'),style: TextStyle(fontSize: 18))
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

   // _generateBarGroupsMiod();

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        actions: <Widget>[          
          // IconButton(
          //   icon: Icon(Icons.arrow_circle_left_outlined, color: Color.fromARGB(255, 0, 0, 0)),
          //    onPressed: () => //powrót do pierwszej strony (gdy brak danych dla dalszych słupków)
          //       { 
          //       globals.raportNrStrony = 1,
          //       Navigator.pushReplacement(
          //         context,
          //         PageRouteBuilder(
          //           pageBuilder: (context, animation, secondaryAnimation) => RaportColorScreen(),
          //           transitionDuration: Duration.zero, // brak animacji
          //           reverseTransitionDuration: Duration.zero,
          //         ),
          //         //MaterialPageRoute(builder: (context) =>RaportColorScreen()),
          //       ),
          //       }                        
          //  ),
           IconButton(
            icon: Icon(Icons.query_stats, color: Color.fromARGB(255, 0, 0, 0)),
             onPressed: () => 
                 _showAlertYear(),              
           ),
        ],
        title: Text('${AppLocalizations.of(context)!.hArvestReports} ${globals.rokRaportow}',
          //AppLocalizations.of(context)!.pArameterization,
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
                //margin: EdgeInsets.all(10),
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
                                            pageBuilder: (context, animation, secondaryAnimation) => RaportColorScreen(),
                                            transitionDuration: Duration.zero, // brak animacji
                                            reverseTransitionDuration: Duration.zero,
                                          ),
                                          //MaterialPageRoute(builder: (context) =>RaportColorScreen()),
                                        );
                                      });
                                  },//{_showAlertNrKorpusu(AppLocalizations.of(context)!.bOdyNumber);},
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
                                onPressed: () {},//{_showAlertNrKorpusu(AppLocalizations.of(context)!.bOdyNumber);},
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
                                          pageBuilder: (context, animation, secondaryAnimation) => RaportColorScreen(),
                                          transitionDuration: Duration.zero, // brak animacji
                                          reverseTransitionDuration: Duration.zero,
                                        ),
                                        //MaterialPageRoute(builder: (context) =>RaportColorScreen()),
                                      );
                                    });
                                  },//{_showAlertNrKorpusu(AppLocalizations.of(context)!.bOdyNumber);},
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
              daneZbioruMioduDoWykresu2023.isEmpty && daneZbioruMioduDoWykresu2024.isEmpty && daneZbioruMioduDoWykresu2025.isEmpty && daneZbioruMioduDoWykresu2026.isEmpty && daneZbioruMioduDoWykresu2027.isEmpty && daneZbioruMioduDoWykresu2028.isEmpty && daneZbioruMioduDoWykresu2029.isEmpty && daneZbioruMioduDoWykresu2030.isEmpty
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
                
          //Wykres zbiorów miodu 
                : Column(
                  children: [                 
                    SizedBox(height: 10),
        
        //miód wykres 2030  
                    if(daneZbioruMioduDoWykresu2030.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2030')) SizedBox(height: 10),
                    if(daneZbioruMioduDoWykresu2030.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2030')) 
                      RichText(
                        text: TextSpan(           
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.hOneyHarvest + ' 2030: ${(allMiod2030/1000).toStringAsFixed(2)} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${(miod2030/1000).toStringAsFixed(2)} kg)'),
                            style: TextStyle(fontSize: 14 )),                          
                          ])),
                    if(daneZbioruMioduDoWykresu2030.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2030'))
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsMiod2030, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY/1000).toStringAsFixed(2),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('kg'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000;
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toStringAsFixed(2)+' kg', style: TextStyle(fontSize: 12)),
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
        //legenda miodobrań 2030
                    if(daneZbioruMioduDoWykresu2030.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2030'))
                      _buildLegendMiod(datyMiodobranMiod2030, sumaKgMiod2030,
                        rok: '2030',
                        daneZbioru: daneZbioruMioduDoWykresu2030,
                        totalValue: allMiod2030,
                      ),
        //kreska
                    if(daneZbioruMioduDoWykresu2030.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2030')) const Divider(
                        height: 10,
                        thickness: 1,indent: 0,
                        endIndent: 0,
                        color: Colors.black,
                      ),

        //miód wykres 2029  
                    if(daneZbioruMioduDoWykresu2029.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2029')) SizedBox(height: 10),
                    if(daneZbioruMioduDoWykresu2029.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2029')) 
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.hOneyHarvest + ' 2029: ${(allMiod2029/1000).toStringAsFixed(2)} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${(miod2029/1000).toStringAsFixed(2)} kg)'),
                            style: TextStyle(fontSize: 14 )),                          
                          ])),
                    if(daneZbioruMioduDoWykresu2029.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2029'))
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsMiod2029, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY/1000).toStringAsFixed(2),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('kg'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000;
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toStringAsFixed(2)+' kg', style: TextStyle(fontSize: 12)),
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
        //legenda miodobrań 2029
                    if(daneZbioruMioduDoWykresu2029.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2029'))
                      _buildLegendMiod(datyMiodobranMiod2029, sumaKgMiod2029,
                        rok: '2029',
                        daneZbioru: daneZbioruMioduDoWykresu2029,
                        totalValue: allMiod2029,
                      ),
        //kreska 
                    if(daneZbioruMioduDoWykresu2029.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2029')) const Divider(
                        height: 10,
                        thickness: 1,
                        indent: 0,
                        endIndent: 0,
                        color: Colors.black,
                      ), 
        
        //miód wykres 2028 
                    if(daneZbioruMioduDoWykresu2028.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2028')) SizedBox(height: 10),
                    if(daneZbioruMioduDoWykresu2028.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2028'))
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.hOneyHarvest + ' 2028: ${(allMiod2028/1000).toStringAsFixed(2)} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${(miod2028/1000).toStringAsFixed(2)} kg)'),
                            style: TextStyle(fontSize: 14 )),                         
                          ])),
                    if(daneZbioruMioduDoWykresu2028.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2028'))
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsMiod2028, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY/1000).toStringAsFixed(2),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('kg'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000;
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toStringAsFixed(2)+' kg', style: TextStyle(fontSize: 12)),
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
                    //legenda miodobrań 2028
                    if(daneZbioruMioduDoWykresu2028.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2028'))
                      _buildLegendMiod(datyMiodobranMiod2028, sumaKgMiod2028,
                        rok: '2028',
                        daneZbioru: daneZbioruMioduDoWykresu2028,
                        totalValue: allMiod2028,
                      ),
        //kreska 
                    if(daneZbioruMioduDoWykresu2028.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2028'))const Divider(
                        height: 10,
                        thickness: 1,
                        indent: 0,
                        endIndent: 0,
                        color: Colors.black,
                      ),      
          
          //miód wykres 2027           
                    if(daneZbioruMioduDoWykresu2027.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2027')) SizedBox(height: 10),
                    if(daneZbioruMioduDoWykresu2027.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2027')) 
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.hOneyHarvest + ' 2027: ${(allMiod2027/1000).toStringAsFixed(2)} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${(miod2027/1000).toStringAsFixed(2)} kg)'),
                            style: TextStyle(fontSize: 14 )),                          
                          ])),
                    if(daneZbioruMioduDoWykresu2027.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2027'))
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsMiod2027, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY/1000).toStringAsFixed(2),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('kg'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000;
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toStringAsFixed(2)+' kg', style: TextStyle(fontSize: 12)),
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
                    //legenda miodobrań 2027
                    if(daneZbioruMioduDoWykresu2027.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2027'))
                      _buildLegendMiod(datyMiodobranMiod2027, sumaKgMiod2027,
                        rok: '2027',
                        daneZbioru: daneZbioruMioduDoWykresu2027,
                        totalValue: allMiod2027,
                      ),
         //kreska 
                    if(daneZbioruMioduDoWykresu2027.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2027'))const Divider(
                        height: 10,
                        thickness: 1,
                        indent: 0,
                        endIndent: 0,
                        color: Colors.black,
                      ),
        
        //miód wykres 2026   
                    if(daneZbioruMioduDoWykresu2026.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2026')) SizedBox(height: 10),
                    if(daneZbioruMioduDoWykresu2026.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2026')) 
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.hOneyHarvest + ' 2026: ${(allMiod2026/1000).toStringAsFixed(2)} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${(miod2026/1000).toStringAsFixed(2)} kg)'),
                            style: TextStyle(fontSize: 14 )),
                          
                          ])),
                    if(daneZbioruMioduDoWykresu2026.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2026'))
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsMiod2026, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY/1000).toStringAsFixed(2),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('kg'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000;
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toStringAsFixed(2)+' kg', style: TextStyle(fontSize: 12)),
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
        //legenda miodobrań 2026
                    if(daneZbioruMioduDoWykresu2026.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2026'))
                      _buildLegendMiod(datyMiodobranMiod2026, sumaKgMiod2026,
                        rok: '2026',
                        daneZbioru: daneZbioruMioduDoWykresu2026,
                        totalValue: allMiod2026,
                      ),
        //kreska
                    if(daneZbioruMioduDoWykresu2026.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2026')) const Divider(
                        height: 10,
                        thickness: 1,
                        indent: 0,
                        endIndent: 0,
                        color: Colors.black,
                      ), 
        
        //miód wykres 2025  
                    if(daneZbioruMioduDoWykresu2025.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2025')) SizedBox(height: 10),
                    if(daneZbioruMioduDoWykresu2025.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2025')) 
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.hOneyHarvest + ' 2025: ${(allMiod2025/1000).toStringAsFixed(2)} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${(miod2025/1000).toStringAsFixed(2)} kg)'),
                            style: TextStyle(fontSize: 14 )),                          
                          ])),
                    if(daneZbioruMioduDoWykresu2025.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2025'))
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsMiod2025, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY/1000).toStringAsFixed(2),
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
                                      // Pobieranie tekstu opisu słupka na podstawie wartości 'x'
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula
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
                                 // axisNameWidget: Text('kg'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000;
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toStringAsFixed(2)+' kg', style: TextStyle(fontSize: 12)),
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
                    //legenda miodobrań 2025
                    if(daneZbioruMioduDoWykresu2025.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2025'))
                      _buildLegendMiod(datyMiodobranMiod2025, sumaKgMiod2025,
                        rok: '2025',
                        daneZbioru: daneZbioruMioduDoWykresu2025,
                        totalValue: allMiod2025,
                      ),
      //kreska 
                    if(daneZbioruMioduDoWykresu2025.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2025'))const Divider(
                        height: 10,
                        thickness: 1,
                        indent: 0,
                        endIndent: 0,
                        color: Colors.black,
                      ),  
        
        
        //miód wykres 2024
                    if(daneZbioruMioduDoWykresu2024.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2024')) SizedBox(height: 10),
                    if(daneZbioruMioduDoWykresu2024.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2024'))
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.hOneyHarvest + ' 2024: ${(allMiod2024/1000).toStringAsFixed(2)} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${(miod2024/1000).toStringAsFixed(2)} kg)'),
                              style: TextStyle(fontSize: 14 )),                         
                          ])),
                    if(daneZbioruMioduDoWykresu2024.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2024'))
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsMiod2024, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY/1000).toStringAsFixed(2),
                                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                  }
                                )
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles( //dolne opisy osi
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40, //It determines the maximum space that your titles need,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('kg'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000;
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toStringAsFixed(2)+' kg', style: TextStyle(fontSize: 12)),
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
                  //legenda miodobrań 2024
                  if(daneZbioruMioduDoWykresu2024.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2024'))
                    _buildLegendMiod(datyMiodobranMiod2024, sumaKgMiod2024,
                      rok: '2024',
                      daneZbioru: daneZbioruMioduDoWykresu2024,
                      totalValue: allMiod2024,
                    ),
        //kreska 
                  if(daneZbioruMioduDoWykresu2024.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2024')) const Divider(
                      height: 10,
                      thickness: 1,
                      indent: 0,
                      endIndent: 0,
                      color: Colors.black,
                    ),   
        
        //miód wykres 2023        
                  if(daneZbioruMioduDoWykresu2023.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2023')) SizedBox(height: 10),
                  if(daneZbioruMioduDoWykresu2023.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2023')) 
                    RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.hOneyHarvest + ' 2023: ${(allMiod2023/1000).toStringAsFixed(2)} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${(miod2023/1000).toStringAsFixed(2)} kg)'),
                            style: TextStyle(fontSize: 14 )),                          
                          ])), 
                  if(daneZbioruMioduDoWykresu2023.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2023'))
                    Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsMiod2023, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY/1000).toStringAsFixed(2),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('kg'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000;
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toStringAsFixed(2)+' kg', style: TextStyle(fontSize: 12)),
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
                  //legenda miodobrań 2023
                  if(daneZbioruMioduDoWykresu2023.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2023'))
                    _buildLegendMiod(datyMiodobranMiod2023, sumaKgMiod2023,
                      rok: '2023',
                      daneZbioru: daneZbioruMioduDoWykresu2023,
                      totalValue: allMiod2023,
                    ),
        //kreska 
                  if(daneZbioruMioduDoWykresu2023.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2023'))const Divider(
                    height: 10,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Colors.black,
                  ), 
        
        //pyłek wykres 2030        
                  if(daneZbioruPylkuDoWykresu2030.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2030')) SizedBox(height: 10),
                  if(daneZbioruPylkuDoWykresu2030.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2030')) 
                  RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.beePollenHarvest + ' 2030: ${allPylek2030/1000} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${pylek2030/1000} kg)'),
                            style: TextStyle(fontSize: 14 )),
                          ])),  
                  if(daneZbioruPylkuDoWykresu2030.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2030'))
                    Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsPylek2030, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY).toString(),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text ('${osY.toStringAsFixed(2)} l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                  //legenda pyłku 2030
                  if(daneZbioruPylkuDoWykresu2030.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2030'))
                    _buildLegend(datyMiodobranPylek2030, sumaLPylek2030,
                      rok: '2030',
                      daneZbioru: daneZbioruPylkuDoWykresu2030,
                      totalValue: allPylek2030.toDouble(),
                    ),
        //kreska
                  if(daneZbioruPylkuDoWykresu2030.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2030')) const Divider(
                    height: 10,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Colors.black,
                  ),

        //pyłek wykres 2029        
                  if(daneZbioruPylkuDoWykresu2029.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2029')) SizedBox(height: 10),
                  if(daneZbioruPylkuDoWykresu2029.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2029')) 
                    RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.beePollenHarvest + ' 2029: ${allPylek2029/1000} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${pylek2029/1000} kg)'),
                            style: TextStyle(fontSize: 14 )),
                          ])),  
                  if(daneZbioruPylkuDoWykresu2029.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2029'))
                    Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsPylek2029, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY).toString(),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text ('${osY.toStringAsFixed(2)} l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                  //legenda pyłku 2029
                  if(daneZbioruPylkuDoWykresu2029.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2029'))
                    _buildLegend(datyMiodobranPylek2029, sumaLPylek2029,
                      rok: '2029',
                      daneZbioru: daneZbioruPylkuDoWykresu2029,
                      totalValue: allPylek2029.toDouble(),
                    ),
        //kreska
                  if(daneZbioruPylkuDoWykresu2029.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2029')) const Divider(
                    height: 10,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Colors.black,
                  ),

        //pyłek wykres 2028        
                  if(daneZbioruPylkuDoWykresu2028.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2028')) SizedBox(height: 10),
                  if(daneZbioruPylkuDoWykresu2028.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2028')) 
                    RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.beePollenHarvest + ' 2028: ${allPylek2028/1000} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${pylek2028/1000} kg)'),
                            style: TextStyle(fontSize: 14 )),
                          ])),
                  if(daneZbioruPylkuDoWykresu2028.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2028'))
                    Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsPylek2028, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY).toString(),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text ('${osY.toStringAsFixed(2)} l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                  //legenda pyłku 2028
                  if(daneZbioruPylkuDoWykresu2028.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2028'))
                    _buildLegend(datyMiodobranPylek2028, sumaLPylek2028,
                      rok: '2028',
                      daneZbioru: daneZbioruPylkuDoWykresu2028,
                      totalValue: allPylek2028.toDouble(),
                    ),
        //kreska
                  if(daneZbioruPylkuDoWykresu2028.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2028')) const Divider(
                    height: 10,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Colors.black,
                  ),

        //pyłek wykres 2027        
                  if(daneZbioruPylkuDoWykresu2027.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2027')) SizedBox(height: 10),
                  if(daneZbioruPylkuDoWykresu2027.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2027')) 
                    RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.beePollenHarvest + ' 2027: ${allPylek2027/1000} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${pylek2027/1000} kg)'),
                            style: TextStyle(fontSize: 14 )),
                          ])), 
                  if(daneZbioruPylkuDoWykresu2027.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2027'))
                    Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsPylek2027, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY).toString(),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text ('${osY.toStringAsFixed(2)} l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                  //legenda pyłku 2027
                  if(daneZbioruPylkuDoWykresu2027.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2027'))
                    _buildLegend(datyMiodobranPylek2027, sumaLPylek2027,
                      rok: '2027',
                      daneZbioru: daneZbioruPylkuDoWykresu2027,
                      totalValue: allPylek2027.toDouble(),
                    ),
        //kreska
                  if(daneZbioruPylkuDoWykresu2027.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2027')) const Divider(
                    height: 10,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Colors.black,
                  ),

        //pyłek wykres 2026        
                  if(daneZbioruPylkuDoWykresu2026.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2026')) SizedBox(height: 10),
                  if(daneZbioruPylkuDoWykresu2026.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2026')) 
                    RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.beePollenHarvest + ' 2026: ${allPylek2026/1000} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${pylek2026/1000} kg)'),
                            style: TextStyle(fontSize: 14 )),
                          ])), 
                  if(daneZbioruPylkuDoWykresu2026.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2026'))
                    Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsPylek2026, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY).toString(),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text ('${osY.toStringAsFixed(2)} l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                  //legenda pyłku 2026
                  if(daneZbioruPylkuDoWykresu2026.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2026'))
                    _buildLegend(datyMiodobranPylek2026, sumaLPylek2026,
                      rok: '2026',
                      daneZbioru: daneZbioruPylkuDoWykresu2026,
                      totalValue: allPylek2026.toDouble(),
                    ),
        //kreska
                  if(daneZbioruPylkuDoWykresu2026.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2026')) const Divider(
                    height: 10,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Colors.black,
                  ),

        //pyłek wykres 2025        
                  if(daneZbioruPylkuDoWykresu2025.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2025')) SizedBox(height: 10),
                  if(daneZbioruPylkuDoWykresu2025.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2025'))
                    RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.beePollenHarvest + ' 2025: ${allPylek2025/1000} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${pylek2025/1000} kg)'),
                            style: TextStyle(fontSize: 14 )),
                          ])), 
                  if(daneZbioruPylkuDoWykresu2025.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2025'))
                    Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsPylek2025, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY).toString(),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text ('${osY.toStringAsFixed(2)} l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                  //legenda pyłku 2025
                  if(daneZbioruPylkuDoWykresu2025.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2025'))
                    _buildLegend(datyMiodobranPylek2025, sumaLPylek2025,
                      rok: '2025',
                      daneZbioru: daneZbioruPylkuDoWykresu2025,
                      totalValue: allPylek2025.toDouble(),
                    ),
        //kreska
                  if(daneZbioruPylkuDoWykresu2025.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2025')) const Divider(
                    height: 10,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Colors.black,
                  ),

        //pyłek wykres 2024        
                  if(daneZbioruPylkuDoWykresu2024.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2024')) SizedBox(height: 10),
                  if(daneZbioruPylkuDoWykresu2024.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2024')) 
                    RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.beePollenHarvest + ' 2024: ${allPylek2024/1000} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${pylek2024/1000} kg)'),
                            style: TextStyle(fontSize: 14 )),
                          ])),  
                  if(daneZbioruPylkuDoWykresu2024.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2024'))
                    Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsPylek2024, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY/1000).toString(),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text ('${osY.toStringAsFixed(2)} l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                  //legenda pyłku 2024
                  if(daneZbioruPylkuDoWykresu2024.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2024'))
                    _buildLegend(datyMiodobranPylek2024, sumaLPylek2024,
                      rok: '2024',
                      daneZbioru: daneZbioruPylkuDoWykresu2024,
                      totalValue: allPylek2024.toDouble(),
                    ),
        //kreska
                  if(daneZbioruPylkuDoWykresu2024.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2024')) const Divider(
                    height: 10,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Colors.black,
                  ),

        //pyłek wykres 2023        
                  if(daneZbioruPylkuDoWykresu2023.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2023')) SizedBox(height: 10),
                  if(daneZbioruPylkuDoWykresu2023.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2023')) 
                    RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text:(AppLocalizations.of(context)!.beePollenHarvest + ' 2023: ${allPylek2023/1000} kg '),
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, )),
                            TextSpan(
                              text:('(${pylek2023/1000} kg)'),
                            style: TextStyle(fontSize: 14 )),
                          ])),  
                  if(daneZbioruPylkuDoWykresu2023.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2023'))
                    Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              barGroups: barGroupsPylek2023, // Używamy dynamicznie generowanych słupków
                              barTouchData: BarTouchData( //etykiety słupków
                                touchTooltipData: BarTouchTooltipData(
                                  //tooltipMargin: 0,
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex
                                  ){
                                    return BarTooltipItem(
                                      (rod.toY).toString(),
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
                                      // Pobieranie tekstu na podstawie wartości 'x'
                                      //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                      String text = hivesNumbers[value.toInt()-1].toString(); //numer ula 
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
                                  //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text ('${osY.toStringAsFixed(2)} l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                  //legenda pyłku 2023
                  if(daneZbioruPylkuDoWykresu2023.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2023'))
                    _buildLegend(datyMiodobranPylek2023, sumaLPylek2023,
                      rok: '2023',
                      daneZbioru: daneZbioruPylkuDoWykresu2023,
                      totalValue: allPylek2023.toDouble(),
                    ),
          //kreska
                  if(daneZbioruPylkuDoWykresu2023.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2023')) const Divider(
                    height: 10,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Colors.black,
                  ),

          // //varroa wykres 2023        
          //               if(daneVarroaDoWykresu2023.isNotEmpty) SizedBox(height: 10),
          //               if(daneVarroaDoWykresu2023.isNotEmpty) Text(AppLocalizations.of(context)!.bEePollenHarvest + ' 2023: ${varroa2023} szt.', style: TextStyle(fontSize: 16),),  
          //               if(daneVarroaDoWykresu2023.isNotEmpty)
          //                 Padding(
          //                     padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
          //                     child: AspectRatio(
          //                       aspectRatio: 2,
          //                       child: BarChart(
          //                         BarChartData(
          //                           barGroups: barGroupsVarroa2023, // Używamy dynamicznie generowanych słupków
          //                           barTouchData: BarTouchData( //etykiety słupków
          //                             touchTooltipData: BarTouchTooltipData(
          //                               //tooltipMargin: 0,
          //                               getTooltipItem: (
          //                                 BarChartGroupData group,
          //                                 int groupIndex,
          //                                 BarChartRodData rod,
          //                                 int rodIndex
          //                               ){
          //                                 return BarTooltipItem(
          //                                   (rod.toY).toString(),
          //                                   TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
          //                               }
          //                             )
          //                           ),
          //                           titlesData: FlTitlesData(
          //                             show: true,
          //                             bottomTitles: AxisTitles( //dolne opisy osi
          //                               sideTitles: SideTitles(
          //                                 showTitles: true,
          //                                 reservedSize: 50,
          //                                 getTitlesWidget: (double value, TitleMeta meta) {
          //                                   // Pobieranie tekstu na podstawie wartości 'x'
          //                                   //String text = xAxisLabelsMiod[value.toInt()] ?? '';
          //                                   String text = value.toInt().toString();
          //                                   return Padding(
          //                                     padding: const EdgeInsets.only(top: 8.0),
          //                                    // child: RotatedBox(
          //                                     //  quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
          //                                       child: Text(text, style: TextStyle(fontSize: 12)),
          //                                    // ),
          //                                   );
          //                                 },
          //                               ),
          //                             ),
          //                             leftTitles: AxisTitles( //lewe opisy osi
          //                               axisNameSize: 20,
          //                               axisNameWidget: Text('kg'), //nazwa osi lewej
          //                               sideTitles: SideTitles(
          //                                 showTitles: true,
          //                                 reservedSize: 44,
          //                                 getTitlesWidget: (value, meta) {
          //                                   double osY = value.toDouble()/1000;
          //                                   return Padding( 
          //                                     padding: const EdgeInsets.only(left: 10.0),
          //                                     child: Text (osY.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          //                                   );
          //                                 },
          //                               ),
          //                             ),
          //                             rightTitles: AxisTitles(
          //                               sideTitles: SideTitles(showTitles: false,)
          //                             ),
          //                             topTitles: AxisTitles(
          //                               sideTitles: SideTitles(showTitles: false,)
          //                             ),
          //                           ),
          //                         ),
          //                       ),
          //                     ),
          //                   ),  
                    
                      
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
