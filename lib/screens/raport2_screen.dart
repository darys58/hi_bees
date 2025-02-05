import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../globals.dart' as globals;
//import '../models/dodatki1.dart';
import '../models/hives.dart';
import '../models/info.dart';
import '../models/infos.dart';

class Raport2Screen extends StatefulWidget {
  static const routeName = '/raport2';

  @override
  State<Raport2Screen> createState() => _Raport2ScreenState();
}

class _Raport2ScreenState extends State<Raport2Screen> {
  bool _isInit = true;
  
  int varroa2023 = 0;
  int varroa2024 = 0;
  int varroa2025 = 0;
  int varroa2026 = 0;
  int varroa2027 = 0;
  int varroa2028 = 0;
  int varroa2029 = 0;
  int varroa2030 = 0;
  List<int> hivesNumbers = [];  //lista numerów wszystkich uli
  List<Map<String, dynamic>> daneVarroaDoWykresu2023 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2024 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2025 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2026 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2027 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2028 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2029 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2030 = [];
  List<BarChartGroupData> barGroupsVarroa2023 = []; //lista elementów sekcji "barGroupsMiod" czyli słupki wykresu miodu
  List<BarChartGroupData> barGroupsVarroa2024 = [];
  List<BarChartGroupData> barGroupsVarroa2025 = [];
  List<BarChartGroupData> barGroupsVarroa2026 = [];
  List<BarChartGroupData> barGroupsVarroa2027 = [];
  List<BarChartGroupData> barGroupsVarroa2028 = [];
  List<BarChartGroupData> barGroupsVarroa2029 = [];
  List<BarChartGroupData> barGroupsVarroa2030 = [];

  @override
  void didChangeDependencies() {
    // print('import_screen - didChangeDependencies');

    // print('import_screen - _isInit = $_isInit');

    Provider.of<Hives>(context, listen: false)
      .fetchAndSetHives(globals.pasiekaID)
      .then((_){ 
        final hivesDataAll = Provider.of<Hives>(context, listen: false);
        final hivesAll = hivesDataAll.items; 
        //lista numerów uli
        for (var i = 0; i < hivesAll.length; i++) { 
          hivesNumbers.add(hivesAll[i].ulNr); //utworzenie listy numerów wszystkich uli - dla pętli for 
        }
        
    });
    
    if (_isInit) {
      Provider.of<Infos>(context, listen: false).fetchAndSetInfos().then((_) {
        //wszystkie informacje dla wybranej pasieki i ula
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
    if (globals.jezyk == 'pl_PL')
      return '$dzien.$miesiac';
    else
      return '$miesiac-$dzien';
  }

  // Funkcja do dynamicznego tworzenia słupków wykresu na podstawie danych - dynamiczne tworzenie sekcji "barGroupsMiod"
  void _generateBarGroupsVarroa2023() {
    barGroupsVarroa2023 = daneVarroaDoWykresu2023.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - kolejny numer słupka
        barRods: [
          BarChartRodData(
            toY: data['value'].toDouble(), // Wartość Y z bazy danych
            borderRadius: BorderRadius.zero, //słupek bez zaokrągleń
            color: Color.fromARGB(255, 56, 127, 251),
          ),
        ],
      );
    }).toList();
  }

  void _generateBarGroupsVarroa2024() {
    barGroupsVarroa2024 = daneVarroaDoWykresu2024.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - kolejny numer słupka
        barRods: [
          BarChartRodData(
            toY: data['value'].toDouble(), // Wartość Y z bazy danych
            borderRadius: BorderRadius.zero, //słupek bez zaokrągleń
            color: Color.fromARGB(255, 56, 127, 251),
          ),
        ],
      );
    }).toList();
  }

  void _generateBarGroupsVarroa2025() {
    barGroupsVarroa2025 = daneVarroaDoWykresu2025.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - kolejny numer słupka
        barRods: [
          BarChartRodData(
            toY: data['value'].toDouble(), // Wartość Y z bazy danych
            borderRadius: BorderRadius.zero, //słupek bez zaokrągleń
            color: Color.fromARGB(255, 56, 127, 251),
          ),
        ],
      );
    }).toList();
  }

  void _generateBarGroupsVarroa2026() {
    barGroupsVarroa2026 = daneVarroaDoWykresu2026.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - kolejny numer słupka
        barRods: [
          BarChartRodData(
            toY: data['value'].toDouble(), // Wartość Y z bazy danych
            borderRadius: BorderRadius.zero, //słupek bez zaokrągleń
            color: Color.fromARGB(255, 56, 127, 251),
          ),
        ],
      );
    }).toList();
  }

  void _generateBarGroupsVarroa2027() {
    barGroupsVarroa2027 = daneVarroaDoWykresu2027.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - kolejny numer słupka
        barRods: [
          BarChartRodData(
            toY: data['value'].toDouble(), // Wartość Y z bazy danych
            borderRadius: BorderRadius.zero, //słupek bez zaokrągleń
            color: Color.fromARGB(255, 56, 127, 251),
          ),
        ],
      );
    }).toList();
  }

  void _generateBarGroupsVarroa2028() {
    barGroupsVarroa2028 = daneVarroaDoWykresu2028.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - kolejny numer słupka
        barRods: [
          BarChartRodData(
            toY: data['value'].toDouble(), // Wartość Y z bazy danych
            borderRadius: BorderRadius.zero, //słupek bez zaokrągleń
            color: Color.fromARGB(255, 56, 127, 251),
          ),
        ],
      );
    }).toList();
  }

  void _generateBarGroupsVarroa2029() {
    barGroupsVarroa2029 = daneVarroaDoWykresu2029.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - kolejny numer słupka
        barRods: [
          BarChartRodData(
            toY: data['value'].toDouble(), // Wartość Y z bazy danych
            borderRadius: BorderRadius.zero, //słupek bez zaokrągleń
            color: Color.fromARGB(255, 56, 127, 251),
          ),
        ],
      );
    }).toList();
  }

  void _generateBarGroupsVarroa2030() {
    barGroupsVarroa2030 = daneVarroaDoWykresu2030.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - kolejny numer słupka
        barRods: [
          BarChartRodData(
            toY: data['value'].toDouble(), // Wartość Y z bazy danych
            borderRadius: BorderRadius.zero, //słupek bez zaokrągleń
            color: Color.fromARGB(255, 56, 127, 251),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    //uzyskanie dostępu do danych w pamięci
    // final memData = Provider.of<Memory>(context, listen: false);
    // final mem = memData.items;
    // final dod1Data = Provider.of<Dodatki1>(context);
    // final dod1 = dod1Data.items;

    //pobranie danych info z wybranej kategorii - zbiory
    final infosData = Provider.of<Infos>(context);
    List<Info> infos = infosData.items.where((inf) {
      return inf.kategoria.contains('treatment');
    }).toList();

    //TWORZENIE DANYCH DO WYKRESóW
//dla kazdego ula w 2023 roku
    for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int varroa = 0;

      //sumowanie zbiorów i tworzenie słupków wykresów
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2023'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == "varroa"){
              varroa = varroa + int.parse(infos[i].wartosc); //sumowanie varroa w ulu 
              varroa2023 = varroa2023 + int.parse(infos[i].wartosc); //sumowanie varroa dla całej pasieki
            //print('varroa - $varroa');
            }
          }
        }
      }
      if(varroa2023 > 0)  
        daneVarroaDoWykresu2023.add({
          "x": j,         // Kolejna wartość osi X
          "value": varroa,   // Wartość słupka
        });
    }
    if(daneVarroaDoWykresu2023.isNotEmpty) _generateBarGroupsVarroa2023(); 

//dla kazdego ula w 2024 roku
    for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int varroa = 0;

      //sumowanie zbiorów i tworzenie słupków wykresów
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2024'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == "varroa"){
              varroa = varroa + int.parse(infos[i].wartosc); //sumowanie varroa w ulu 
              varroa2024 = varroa2024 + int.parse(infos[i].wartosc); //sumowanie varroa dla całej pasieki
            //print('varroa - $varroa');
            }
          }
        }
      }
      if(varroa2024 > 0)  
        daneVarroaDoWykresu2024.add({
          "x": j,         // Kolejna wartość osi X
          "value": varroa,   // Wartość słupka
        });
    }
    if(daneVarroaDoWykresu2024.isNotEmpty) _generateBarGroupsVarroa2024(); 

//dla kazdego ula w 2025 roku
    for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int varroa = 0;

      //sumowanie zbiorów i tworzenie słupków wykresów
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2025'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == "varroa"){
              varroa = varroa + int.parse(infos[i].wartosc); //sumowanie varroa w ulu 
              varroa2025 = varroa2025 + int.parse(infos[i].wartosc); //sumowanie varroa dla całej pasieki
            //print('varroa - $varroa');
            }
          }
        }
      }
      if(varroa2025 > 0)  
        daneVarroaDoWykresu2025.add({
          "x": j,         // Kolejna wartość osi X
          "value": varroa,   // Wartość słupka
        });
    }
    if(daneVarroaDoWykresu2025.isNotEmpty) _generateBarGroupsVarroa2025(); 

//dla kazdego ula w 2026 roku
for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int varroa = 0;

      //sumowanie zbiorów i tworzenie słupków wykresów
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2026'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == "varroa"){
              varroa = varroa + int.parse(infos[i].wartosc); //sumowanie varroa w ulu 
              varroa2026 = varroa2026 + int.parse(infos[i].wartosc); //sumowanie varroa dla całej pasieki
            //print('varroa - $varroa');
            }
          }
        }
      }
      if(varroa2026 > 0)  
        daneVarroaDoWykresu2026.add({
          "x": j,         // Kolejna wartość osi X
          "value": varroa,   // Wartość słupka
        });
    }
    if(daneVarroaDoWykresu2026.isNotEmpty) _generateBarGroupsVarroa2026(); 

//dla kazdego ula w 2027 roku
for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int varroa = 0;

      //sumowanie zbiorów i tworzenie słupków wykresów
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2027'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == "varroa"){
              varroa = varroa + int.parse(infos[i].wartosc); //sumowanie varroa w ulu 
              varroa2027 = varroa2027 + int.parse(infos[i].wartosc); //sumowanie varroa dla całej pasieki
            //print('varroa - $varroa');
            }
          }
        }
      }
      if(varroa2027 > 0)  
        daneVarroaDoWykresu2027.add({
          "x": j,         // Kolejna wartość osi X
          "value": varroa,   // Wartość słupka
        });
    }
    if(daneVarroaDoWykresu2027.isNotEmpty) _generateBarGroupsVarroa2027(); 

//dla kazdego ula w 2028 roku
for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int varroa = 0;

      //sumowanie zbiorów i tworzenie słupków wykresów
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2028'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == "varroa"){
              varroa = varroa + int.parse(infos[i].wartosc); //sumowanie varroa w ulu 
              varroa2028 = varroa2028 + int.parse(infos[i].wartosc); //sumowanie varroa dla całej pasieki
            //print('varroa - $varroa');
            }
          }
        }
      }
      if(varroa2028 > 0)  
        daneVarroaDoWykresu2028.add({
          "x": j,         // Kolejna wartość osi X
          "value": varroa,   // Wartość słupka
        });
    }
    if(daneVarroaDoWykresu2028.isNotEmpty) _generateBarGroupsVarroa2028(); 

//dla kazdego ula w 2029 roku
for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int varroa = 0;

      //sumowanie zbiorów i tworzenie słupków wykresów
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2029'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == "varroa"){
              varroa = varroa + int.parse(infos[i].wartosc); //sumowanie varroa w ulu 
              varroa2029 = varroa2029 + int.parse(infos[i].wartosc); //sumowanie varroa dla całej pasieki
            //print('varroa - $varroa');
            }
          }
        }
      }
      if(varroa2029 > 0)  
        daneVarroaDoWykresu2029.add({
          "x": j,         // Kolejna wartość osi X
          "value": varroa,   // Wartość słupka
        });
    }
    if(daneVarroaDoWykresu2029.isNotEmpty) _generateBarGroupsVarroa2029(); 

//dla kazdego ula w 2030 roku
for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int varroa = 0;

      //sumowanie zbiorów i tworzenie słupków wykresów
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2030'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == "varroa"){
              varroa = varroa + int.parse(infos[i].wartosc); //sumowanie varroa w ulu 
              varroa2030 = varroa2030 + int.parse(infos[i].wartosc); //sumowanie varroa dla całej pasieki
            //print('varroa - $varroa');
            }
          }
        }
      }
      if(varroa2030 > 0)  
        daneVarroaDoWykresu2030.add({
          "x": j,         // Kolejna wartość osi X
          "value": varroa,   // Wartość słupka
        });
    }
    if(daneVarroaDoWykresu2030.isNotEmpty) _generateBarGroupsVarroa2030(); 

    // wybór roku do statystyk
  //   void _showAlertYear() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text(AppLocalizations.of(context)!.selectStatYear),
  //       content: Column(
  //         //zeby tekst był wyśrodkowany w poziomie
  //         mainAxisSize: MainAxisSize.min,
  //         children: <Widget>[
  //           if(2023 <= int.parse(DateTime.now().toString().substring(0, 4)))
  //             TextButton(onPressed: (){
  //               Navigator.of(context).pop();
  //               Navigator.of(context).pop();
  //               globals.rokStatystyk = '2023';
  //               Navigator.of(context).pushNamed(
  //                   ParametrScreen.routeName,
  //                 );
  //             }, child: Text(('2023'),style: TextStyle(fontSize: 18))
  //             ),  
  //           if(2024 <= int.parse(DateTime.now().toString().substring(0, 4)))  
  //             TextButton(onPressed: (){
  //               Navigator.of(context).pop();
  //               Navigator.of(context).pop();
  //               globals.rokStatystyk = '2024';
  //               Navigator.of(context).pushNamed(
  //                   ParametrScreen.routeName, 
  //               );
  //             }, child: Text(('2024'),style: TextStyle(fontSize: 18))
  //             ),
  //           if(2025 <= int.parse(DateTime.now().toString().substring(0, 4)))  
  //             TextButton(onPressed: (){
  //               Navigator.of(context).pop();
  //               Navigator.of(context).pop();
  //               globals.rokStatystyk = '2025';
  //               Navigator.of(context).pushNamed(
  //                   ParametrScreen.routeName, 
  //               );
  //             }, child: Text(('2025'),style: TextStyle(fontSize: 18))
  //             ),
  //           if(2026 <= int.parse(DateTime.now().toString().substring(0, 4)))  
  //             TextButton(onPressed: (){
  //               Navigator.of(context).pop();
  //               Navigator.of(context).pop();
  //               globals.rokStatystyk = '2026';
  //               Navigator.of(context).pushNamed(
  //                   ParametrScreen.routeName, 
  //               );
  //             }, child: Text(('2026'),style: TextStyle(fontSize: 18))
  //             ),
  //           if(2027 <= int.parse(DateTime.now().toString().substring(0, 4)))  
  //             TextButton(onPressed: (){
  //               Navigator.of(context).pop();
  //               Navigator.of(context).pop();
  //               globals.rokStatystyk = '2027';
  //               Navigator.of(context).pushNamed(
  //                   ParametrScreen.routeName, 
  //               );
  //             }, child: Text(('2027'),style: TextStyle(fontSize: 18))
  //             ),
  //         ],
  //       ),
  //       actions: <Widget>[
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //           },
  //           child: Text(AppLocalizations.of(context)!.cancel),
  //         ),
  //       ],
  //       elevation: 24.0,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(15.0),
  //       ),
  //     ),
  //     barrierDismissible:
  //         false, //zeby zaciemnione tło było zablokowane na kliknięcia
  //   );
  // }

   // _generateBarGroupsMiod();

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        // actions: <Widget>[          
        //   IconButton(
        //     icon: Icon(Icons.query_stats, color: Color.fromARGB(255, 0, 0, 0)),
        //      onPressed: () //=> 
        //          _showAlertYear(),              
        //    ),
        // ],
        title: Text(AppLocalizations.of(context)!.tReatmentReports,
          //AppLocalizations.of(context)!.pArameterization,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            daneVarroaDoWykresu2023.isEmpty && daneVarroaDoWykresu2024.isEmpty && daneVarroaDoWykresu2025.isEmpty && daneVarroaDoWykresu2026.isEmpty && daneVarroaDoWykresu2027.isEmpty && daneVarroaDoWykresu2028.isEmpty && daneVarroaDoWykresu2029.isEmpty && daneVarroaDoWykresu2030.isEmpty
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
  
  
  //varroa wykres 2030        
                if(daneVarroaDoWykresu2030.isNotEmpty) SizedBox(height: 10),
                if(daneVarroaDoWykresu2030.isNotEmpty) Text(AppLocalizations.of(context)!.dEad + ' varroa 2030: ${varroa2030} ' + AppLocalizations.of(context)!.pcs, style: TextStyle(fontSize: 16),),  
                if(daneVarroaDoWykresu2030.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                      child: AspectRatio(
                        aspectRatio: 2,
                        child: BarChart(
                          BarChartData(
                            barGroups: barGroupsVarroa2030, // Używamy dynamicznie generowanych słupków
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
                                    rod.toY.toString().substring(0, rod.toY.toString().length - 2), //obcięce .0
                                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                }
                              )
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles( //dolne opisy osi
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                     // child: RotatedBox(
                                      //  quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
                                        child: Text(text, style: TextStyle(fontSize: 12)),
                                     // ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles( //lewe opisy osi
                                axisNameSize: 20,
                                //axisNameWidget: Text('kg'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) {
                                    //double osY = value.toDouble();
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
  
  //varroa wykres 2029        
                if(daneVarroaDoWykresu2029.isNotEmpty) SizedBox(height: 10),
                if(daneVarroaDoWykresu2029.isNotEmpty) Text(AppLocalizations.of(context)!.dEad + ' varroa 2029: ${varroa2029} ' + AppLocalizations.of(context)!.pcs, style: TextStyle(fontSize: 16),),  
                if(daneVarroaDoWykresu2029.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                      child: AspectRatio(
                        aspectRatio: 2,
                        child: BarChart(
                          BarChartData(
                            barGroups: barGroupsVarroa2029, // Używamy dynamicznie generowanych słupków
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
                                    rod.toY.toString().substring(0, rod.toY.toString().length - 2), //obcięce .0
                                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                }
                              )
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles( //dolne opisy osi
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                     // child: RotatedBox(
                                      //  quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
                                        child: Text(text, style: TextStyle(fontSize: 12)),
                                     // ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles( //lewe opisy osi
                                axisNameSize: 20,
                                //axisNameWidget: Text('kg'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) {
                                    //double osY = value.toDouble();
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
  
  //varroa wykres 2028        
                if(daneVarroaDoWykresu2028.isNotEmpty) SizedBox(height: 10),
                if(daneVarroaDoWykresu2028.isNotEmpty) Text(AppLocalizations.of(context)!.dEad + ' varroa 2028: ${varroa2028} ' + AppLocalizations.of(context)!.pcs, style: TextStyle(fontSize: 16),),  
                if(daneVarroaDoWykresu2028.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                      child: AspectRatio(
                        aspectRatio: 2,
                        child: BarChart(
                          BarChartData(
                            barGroups: barGroupsVarroa2028, // Używamy dynamicznie generowanych słupków
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
                                    rod.toY.toString().substring(0, rod.toY.toString().length - 2), //obcięce .0
                                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                }
                              )
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles( //dolne opisy osi
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                     // child: RotatedBox(
                                      //  quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
                                        child: Text(text, style: TextStyle(fontSize: 12)),
                                     // ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles( //lewe opisy osi
                                axisNameSize: 20,
                                //axisNameWidget: Text('kg'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) {
                                    //double osY = value.toDouble();
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

  //varroa wykres 2027        
                if(daneVarroaDoWykresu2027.isNotEmpty) SizedBox(height: 10),
                if(daneVarroaDoWykresu2027.isNotEmpty) Text(AppLocalizations.of(context)!.dEad + ' varroa 2027: ${varroa2027} ' + AppLocalizations.of(context)!.pcs, style: TextStyle(fontSize: 16),),  
                if(daneVarroaDoWykresu2027.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                      child: AspectRatio(
                        aspectRatio: 2,
                        child: BarChart(
                          BarChartData(
                            barGroups: barGroupsVarroa2027, // Używamy dynamicznie generowanych słupków
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
                                    rod.toY.toString().substring(0, rod.toY.toString().length - 2), //obcięce .0
                                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                }
                              )
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles( //dolne opisy osi
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                     // child: RotatedBox(
                                      //  quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
                                        child: Text(text, style: TextStyle(fontSize: 12)),
                                     // ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles( //lewe opisy osi
                                axisNameSize: 20,
                                //axisNameWidget: Text('kg'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) {
                                    //double osY = value.toDouble();
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
                  
  //varroa wykres 2026        
                if(daneVarroaDoWykresu2026.isNotEmpty) SizedBox(height: 10),
                if(daneVarroaDoWykresu2026.isNotEmpty) Text(AppLocalizations.of(context)!.dEad + ' varroa 2026: ${varroa2026} ' + AppLocalizations.of(context)!.pcs, style: TextStyle(fontSize: 16),),  
                if(daneVarroaDoWykresu2026.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                      child: AspectRatio(
                        aspectRatio: 2,
                        child: BarChart(
                          BarChartData(
                            barGroups: barGroupsVarroa2026, // Używamy dynamicznie generowanych słupków
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
                                    rod.toY.toString().substring(0, rod.toY.toString().length - 2), //obcięce .0
                                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                }
                              )
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles( //dolne opisy osi
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                     // child: RotatedBox(
                                      //  quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
                                        child: Text(text, style: TextStyle(fontSize: 12)),
                                     // ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles( //lewe opisy osi
                                axisNameSize: 20,
                                //axisNameWidget: Text('kg'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) {
                                    //double osY = value.toDouble();
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

   //varroa wykres 2025        
                if(daneVarroaDoWykresu2025.isNotEmpty) SizedBox(height: 10),
                if(daneVarroaDoWykresu2025.isNotEmpty) Text(AppLocalizations.of(context)!.dEad + ' varroa 2025: ${varroa2025} ' + AppLocalizations.of(context)!.pcs, style: TextStyle(fontSize: 16),),  
                if(daneVarroaDoWykresu2025.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                      child: AspectRatio(
                        aspectRatio: 2,
                        child: BarChart(
                          BarChartData(
                            barGroups: barGroupsVarroa2025, // Używamy dynamicznie generowanych słupków
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
                                    rod.toY.toString().substring(0, rod.toY.toString().length - 2), //obcięce .0
                                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                }
                              )
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles( //dolne opisy osi
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                     // child: RotatedBox(
                                      //  quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
                                        child: Text(text, style: TextStyle(fontSize: 12)),
                                     // ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles( //lewe opisy osi
                                axisNameSize: 20,
                                //axisNameWidget: Text('kg'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) {
                                    //double osY = value.toDouble();
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
                  
  //varroa wykres 2024        
                if(daneVarroaDoWykresu2024.isNotEmpty) SizedBox(height: 10),
                if(daneVarroaDoWykresu2024.isNotEmpty) Text(AppLocalizations.of(context)!.dEad + ' varroa 2024: ${varroa2024} ' + AppLocalizations.of(context)!.pcs, style: TextStyle(fontSize: 16),),  
                if(daneVarroaDoWykresu2024.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                      child: AspectRatio(
                        aspectRatio: 2,
                        child: BarChart(
                          BarChartData(
                            barGroups: barGroupsVarroa2024, // Używamy dynamicznie generowanych słupków
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
                                    rod.toY.toString().substring(0, rod.toY.toString().length - 2), //obcięce .0
                                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                }
                              )
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles( //dolne opisy osi
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                     // child: RotatedBox(
                                      //  quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
                                        child: Text(text, style: TextStyle(fontSize: 12)),
                                     // ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles( //lewe opisy osi
                                axisNameSize: 20,
                                //axisNameWidget: Text('kg'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) {
                                    //double osY = value.toDouble();
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
                  
  //varroa wykres 2023        
                if(daneVarroaDoWykresu2023.isNotEmpty) SizedBox(height: 10),
                if(daneVarroaDoWykresu2023.isNotEmpty) Text(AppLocalizations.of(context)!.dEad + ' varroa 2023: ${varroa2023} ' + AppLocalizations.of(context)!.pcs, style: TextStyle(fontSize: 16),),  
                if(daneVarroaDoWykresu2023.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 24.0, top: 15.0, bottom: 10),
                      child: AspectRatio(
                        aspectRatio: 2,
                        child: BarChart(
                          BarChartData(
                            barGroups: barGroupsVarroa2023, // Używamy dynamicznie generowanych słupków
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
                                    rod.toY.toString().substring(0, rod.toY.toString().length - 2), //obcięce .0
                                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                }
                              )
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles( //dolne opisy osi
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    //String text = xAxisLabelsMiod[value.toInt()] ?? '';
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                     // child: RotatedBox(
                                      //  quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
                                        child: Text(text, style: TextStyle(fontSize: 12)),
                                     // ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles( //lewe opisy osi
                                axisNameSize: 20,
                                //axisNameWidget: Text('kg'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) {
                                    //double osY = value.toDouble();
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
                  
                    
                  ],  
              ),    
          ],
        ),
      ),
    );
  }
}
