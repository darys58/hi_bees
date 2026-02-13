import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../globals.dart' as globals;
import '../models/dodatki1.dart';
import '../models/hives.dart';
import '../models/info.dart';
import '../models/infos.dart';

class RaportScreen extends StatefulWidget {
  static const routeName = '/raport';

  @override
  State<RaportScreen> createState() => _RaportScreenState();
}

class _RaportScreenState extends State<RaportScreen> {
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
  
  @override
  void didChangeDependencies() {
    // print('import_screen - didChangeDependencies');

    // print('import_screen - _isInit = $_isInit');

    Provider.of<Hives>(context, listen: false)
      .fetchAndSetHives(globals.pasiekaID)
      .then((_){ 
        final hivesDataAll = Provider.of<Hives>(context, listen: false);
        final hivesAll = hivesDataAll.items; 
         
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
    if (globals.jezyk == 'pl_PL')
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
                              pageBuilder: (context, animation, secondaryAnimation) => RaportScreen(),
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

   // Funkcja do dynamicznego tworzenia słupków wykresu na podstawie danych - dynamiczne tworzenie sekcji "barGroupsMiod"
  void _generateBarGroupsMiod2023() {
    barGroupsMiod2023 = daneZbioruMioduDoWykresu2023.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
        barRods: [
          BarChartRodData(
            toY: data['value'].toDouble(), // Wartość Y z bazy danych
            // rodStackItems: [
            //   BarChartRodStackItem(0, data['value_01'].toDouble(), Color.fromARGB(255, 56, 127, 251)),
            //   BarChartRodStackItem(data['value_01'].toDouble(), data['value_02'].toDouble(), Color.fromARGB(255, 56, 251, 160)),
            //   BarChartRodStackItem(data['value_02'].toDouble(), data['value_03'].toDouble(), Color.fromARGB(255, 251, 56, 56)),
            // ], 
            borderRadius: BorderRadius.zero, //słupek bez zaokrągleń
            color: Color.fromARGB(255, 56, 127, 251), //kolor domyślny słupka
          ),
        ],
      );
    }).toList();
  }

  void _generateBarGroupsMiod2024() {
    barGroupsMiod2024 = daneZbioruMioduDoWykresu2024.map((data) {
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsMiod2025() {
    barGroupsMiod2025 = daneZbioruMioduDoWykresu2025.map((data) {
      //print('generownie słupka - data[x] = ${data['x']}');
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
        barRods: [
          BarChartRodData(
            toY: data['value'].toDouble(), // Wartość Y obliczona wartość słupka
            borderRadius: BorderRadius.zero, //słupek bez zaokrągleń
            color: Color.fromARGB(255, 56, 127, 251),
          ),
        ],
      );
    }).toList();
  }

  void _generateBarGroupsMiod2026() {
    barGroupsMiod2026 = daneZbioruMioduDoWykresu2026.map((data) {
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsMiod2027() {
    barGroupsMiod2027 = daneZbioruMioduDoWykresu2027.map((data) {
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsMiod2028() {
    barGroupsMiod2028 = daneZbioruMioduDoWykresu2028.map((data) {
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsMiod2029() {
    barGroupsMiod2029 = daneZbioruMioduDoWykresu2029.map((data) {
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsMiod2030() {
    barGroupsMiod2030 = daneZbioruMioduDoWykresu2030.map((data) {
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsPylek2023() {
    barGroupsPylek2023 = daneZbioruPylkuDoWykresu2023.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsPylek2024() {
    barGroupsPylek2024 = daneZbioruPylkuDoWykresu2024.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsPylek2025() {
    barGroupsPylek2025 = daneZbioruPylkuDoWykresu2025.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsPylek2026() {
    barGroupsPylek2026 = daneZbioruPylkuDoWykresu2026.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsPylek2027() {
    barGroupsPylek2027 = daneZbioruPylkuDoWykresu2027.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsPylek2028() {
    barGroupsPylek2028 = daneZbioruPylkuDoWykresu2028.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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
 
  void _generateBarGroupsPylek2029() {
    barGroupsPylek2029 = daneZbioruPylkuDoWykresu2029.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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

  void _generateBarGroupsPylek2030() {
    barGroupsPylek2030 = daneZbioruPylkuDoWykresu2030.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      //xAxisLabelsMiod[data['x']] = data['label'];
      return BarChartGroupData(
        x: data['x'], // Wartość X - opis słupka - numer ula
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
    final dod1Data = Provider.of<Dodatki1>(context);
    final dod1 = dod1Data.items;

    //pobranie danych info z wybranej kategorii - zbiory
    final infosData = Provider.of<Infos>(context);
    List<Info> infos = infosData.items.where((inf) {
      return inf.kategoria == ('harvest');
    }).toList();

     //poszukanie najstarszego roku w wybranej kategorii
    int odRoku = int.parse(DateTime.now().toString().substring(0, 4)); //biezący rok
    for (var i = 0; i < infos.length; i++) {
      if(odRoku > int.parse(infos[i].data.substring(0, 4)))
        odRoku = int.parse(infos[i].data.substring(0, 4));
    }

    //TWORZENIE DANYCH DO WYKRESóW
   //print('infos = ${infos.length}');
      
    //2023
    //dla kazdego ula w pasiece w 2023 roku - suma z wszystkich uli
    for (var j = 1; j < allHivesNumbers.length + 1; j++) { 
      //sumowanie zbiorów i tworzenie słupka wykresu
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2023'){ //info z roku ...
          if(infos[i].ulNr == allHivesNumbers[j-1]) { //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2023 = allMiod2023 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);  
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2023 = allMiod2023 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);           
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = "  && infos[i].wartosc.isNotEmpty){
              allMiod2023 = allMiod2023 + (double.parse(infos[i].wartosc) * 1000).toInt(); //miód w kg           
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
            //i pyłku (dla miarki)
              allPylek2023 = allPylek2023 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty ){
            //i pyłku (w ml)
              allPylek2023 = allPylek2023 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
            //i pyłku (w l)
              allPylek2023 = allPylek2023 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
    }

    //dla kazdego ula (na prezentowanej stronie raportu) w 2023 roku
    for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      double miod= 0;
      int pylek = 0;
      // int varroa = 0;
      //sumowanie zbiorów i tworzenie słupków wykresów
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2023'){ //info z roku ...
          if(infos[i].ulNr == hivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000); 
              miod2023 = miod2023 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000); //suma zbioru za 2023
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2023 = miod2023 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);  //suma zbioru za 2023           
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " && infos[i].wartosc.isNotEmpty){
              miod = miod + (double.parse(infos[i].wartosc) * 1000).toInt();
              miod2023 = miod2023 + (double.parse(infos[i].wartosc) * 1000).toInt();             
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2023 = pylek2023 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2023 = pylek2023 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              pylek = pylek + (double.parse(infos[i].wartosc) * 1000).toInt();
              pylek2023 = pylek2023 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
      if(miod2023 > 0)
        daneZbioruMioduDoWykresu2023.add({ //to dodaj następny słupek wykresu
          "x": j,         // Kolejna wartość osi X - numer ula
          "value": miod,   // Wartość słupka
          // "value_01": 5000,   // Wartość słupka
          // "value_02": 5000,
          // "value_03": 15000,
        });
      if(pylek2023 > 0)
        daneZbioruPylkuDoWykresu2023.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2023.isNotEmpty) _generateBarGroupsMiod2023();
    if(daneZbioruPylkuDoWykresu2023.isNotEmpty) _generateBarGroupsPylek2023();
    //if(daneVarroaDoWykresu2023.isNotEmpty) _generateBarGroupsVarroa2023(); 
//===============================================================================================

  //2024
  //dla kazdego ula w pasiece w 2024 roku  - suma z wszystkich uli
  for (var j = 1; j < allHivesNumbers.length + 1; j++) { 
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2024'){ //info z roku ...
          if(infos[i].ulNr == allHivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2024 = allMiod2024 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2024 = allMiod2024 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = "  && infos[i].wartosc.isNotEmpty){
              allMiod2024 = allMiod2024 + (double.parse(infos[i].wartosc) * 1000).toInt(); //miód w kg           
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              allPylek2024 = allPylek2024 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty ){
             //i pyłku (w ml)
              allPylek2024 = allPylek2024 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              allPylek2024 = allPylek2024 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
    }

  //dla kazdego ula (na prezentowanej stronie raportu) w 2024 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      double miod = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2024'){ //info z roku ...
          if(infos[i].ulNr == hivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2024 = miod2024 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2024 = miod2024 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " && infos[i].wartosc.isNotEmpty){
              miod = miod + (double.parse(infos[i].wartosc) * 1000).toInt();
              miod2024 = miod2024 + (double.parse(infos[i].wartosc) * 1000).toInt();             
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2024 = pylek2024 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2024 = pylek2024 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              pylek = pylek + (double.parse(infos[i].wartosc) * 1000).toInt();
              pylek2024 = pylek2024 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
      if(miod2024 > 0)
        daneZbioruMioduDoWykresu2024.add({ //to dodaj następny słupek wykresu
          "x": j,         // Kolejna wartość osi X - numer ula
          "value": miod, // Wartość słupka         
        });
      if(pylek2024 > 0)
        daneZbioruPylkuDoWykresu2024.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2024.isNotEmpty) _generateBarGroupsMiod2024();
    if(daneZbioruPylkuDoWykresu2024.isNotEmpty) _generateBarGroupsPylek2024();
  //==================================================================================
  

  //2025
  //dla kazdego ula w pasiece w 2025 roku  - suma z wszystkich uli
  for (var j = 1; j < allHivesNumbers.length + 1; j++) { 
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2025'){ //info z roku ...
          if(infos[i].ulNr == allHivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2025 = allMiod2025 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2025 = allMiod2025 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000); //miód duza ramka            
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = "  && infos[i].wartosc.isNotEmpty){
              allMiod2025 = allMiod2025 + (double.parse(infos[i].wartosc) * 1000).toInt(); //miód w kg           
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              allPylek2025 = allPylek2025 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty ){
             //i pyłku (w ml)
              allPylek2025 = allPylek2025 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              allPylek2025 = allPylek2025 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
    }
   
  //dla kazdego ula (na prezentowanej stronie raportu) w 2025 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      double miod = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2025'){ //info z roku ...
          if(infos[i].ulNr == hivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2025 = miod2025 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2025 = miod2025 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " && infos[i].wartosc.isNotEmpty){
              miod = miod + (double.parse(infos[i].wartosc) * 1000).toInt();
              miod2025 = miod2025 + (double.parse(infos[i].wartosc) * 1000).toInt();             
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2025 = pylek2025 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty ){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2025 = pylek2025 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              pylek = pylek + (double.parse(infos[i].wartosc) * 1000).toInt();
              pylek2025 = pylek2025 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
      //print('miod2025 = $miod2025');
      if(miod2025 > 0)
        daneZbioruMioduDoWykresu2025.add({ //to dodaj następny słupek wykresu
          "x": j,         // Kolejna wartość osi X - index w tabeli numerów uli hivesNumbers wskazujący numer ula
          "value": miod,   // Wartość słupka
        });
      
      if(pylek2025 > 0)
        daneZbioruPylkuDoWykresu2025.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2025.isNotEmpty) _generateBarGroupsMiod2025();
    if(daneZbioruPylkuDoWykresu2025.isNotEmpty) _generateBarGroupsPylek2025();
  //===============================================================================================
  
  //2026
  //dla kazdego ula w pasiece w 2026 roku 
  for (var j = 1; j < allHivesNumbers.length + 1; j++) { 
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2026'){ //info z roku ...
          if(infos[i].ulNr == allHivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2026 = allMiod2026 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2026 = allMiod2026 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = "  && infos[i].wartosc.isNotEmpty){
              allMiod2026 = allMiod2026 + (double.parse(infos[i].wartosc) * 1000).toInt(); //miód w kg           
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              allPylek2026 = allPylek2026 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty ){
             //i pyłku (w ml)
              allPylek2026 = allPylek2026 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              allPylek2026 = allPylek2026 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
    }

  //dla kazdego ula (na prezentowanej stronie raportu) w 2026 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      double miod = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2026'){ //info z roku ...
          if(infos[i].ulNr == hivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2026 = miod2026 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2026 = miod2026 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " && infos[i].wartosc.isNotEmpty){
              miod = miod + (double.parse(infos[i].wartosc) * 1000).toInt();
              miod2026 = miod2026 + (double.parse(infos[i].wartosc) * 1000).toInt();             
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2026 = pylek2026 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2026 = pylek2026 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              pylek = pylek + (double.parse(infos[i].wartosc) * 1000).toInt();
              pylek2026 = pylek2026 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
      if(miod2026 > 0)
        daneZbioruMioduDoWykresu2026.add({ //to dodaj następny słupek wykresu
          "x": j,         // Kolejna wartość osi X - numer ula
          "value": miod,   // Wartość słupka
        });
      if(pylek2026 > 0)
        daneZbioruPylkuDoWykresu2026.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2026.isNotEmpty) _generateBarGroupsMiod2026();
    if(daneZbioruPylkuDoWykresu2026.isNotEmpty) _generateBarGroupsPylek2026();
//===============================================================================================

  //2027
  //dla kazdego ula w pasiece w 2027 roku 
  for (var j = 1; j < allHivesNumbers.length + 1; j++) { 
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2027'){ //info z roku ...
          if(infos[i].ulNr == allHivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2027 = allMiod2027 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2027 = allMiod2027 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = "  && infos[i].wartosc.isNotEmpty){
              allMiod2027 = allMiod2027 + (double.parse(infos[i].wartosc) * 1000).toInt(); //miód w kg           
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              allPylek2027 = allPylek2027 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty ){
             //i pyłku (w ml)
              allPylek2027 = allPylek2027 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              allPylek2027 = allPylek2027 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
    }

  //dla kazdego ula (na prezentowanej stronie raportu) w 2027 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      double miod = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2027'){ //info z roku ...
          if(infos[i].ulNr == hivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2027 = miod2027 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2027 = miod2027 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " && infos[i].wartosc.isNotEmpty){
              miod = miod + (double.parse(infos[i].wartosc) * 1000).toInt();
              miod2027 = miod2027 + (double.parse(infos[i].wartosc) * 1000).toInt();             
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2027 = pylek2027 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2027 = pylek2027 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              pylek = pylek + (double.parse(infos[i].wartosc) * 1000).toInt();
              pylek2027 = pylek2027 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
      if(miod2027 > 0)
        daneZbioruMioduDoWykresu2027.add({ //to dodaj następny słupek wykresu
          "x": j,         // Kolejna wartość osi X - numer ula
          "value": miod,   // Wartość słupka
        });
      if(pylek2027 > 0)
        daneZbioruPylkuDoWykresu2027.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2027.isNotEmpty) _generateBarGroupsMiod2027();
    if(daneZbioruPylkuDoWykresu2027.isNotEmpty) _generateBarGroupsPylek2027();
    //===============================================================================================

  //2028
  //dla kazdego ula w pasiece w 2028 roku 
  for (var j = 1; j < allHivesNumbers.length + 1; j++) { 

      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2028'){ //info z roku ...
          if(infos[i].ulNr == allHivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2028 = allMiod2028 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2028 = allMiod2028 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = "  && infos[i].wartosc.isNotEmpty){
              allMiod2028 = allMiod2028 + (double.parse(infos[i].wartosc) * 1000).toInt(); //miód w kg           
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              allPylek2028 = allPylek2028 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty ){
             //i pyłku (w ml)
              allPylek2028 = allPylek2028 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              allPylek2028 = allPylek2028 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
    }

  //dla kazdego ula (na prezentowanej stronie raportu) w 2028 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      double miod= 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2028'){ //info z roku ...
          if(infos[i].ulNr == hivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2028 = miod2028 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2028 = miod2028 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " && infos[i].wartosc.isNotEmpty){
              miod = miod + (double.parse(infos[i].wartosc) * 1000).toInt();
              miod2028 = miod2028 + (double.parse(infos[i].wartosc) * 1000).toInt();             
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2028 = pylek2028 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2028 = pylek2028 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              pylek = pylek + (double.parse(infos[i].wartosc) * 1000).toInt();
              pylek2028 = pylek2028 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
      if(miod2028 > 0)
        daneZbioruMioduDoWykresu2028.add({ //to dodaj następny słupek wykresu
          "x": j,         // Kolejna wartość osi X - numer ula
          "value": miod,   // Wartość słupka
        });
      if(pylek2028 > 0)
        daneZbioruPylkuDoWykresu2028.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2028.isNotEmpty) _generateBarGroupsMiod2028();
    if(daneZbioruPylkuDoWykresu2028.isNotEmpty) _generateBarGroupsPylek2028();
   //===============================================================================================

  //2029
  //dla kazdego ula w pasiece w 2029 roku 
  for (var j = 1; j < allHivesNumbers.length + 1; j++) { 
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2029'){ //info z roku ...
          if(infos[i].ulNr == allHivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2029 = allMiod2029 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2029 = allMiod2029 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = "  && infos[i].wartosc.isNotEmpty){
              allMiod2029 = allMiod2029 + (double.parse(infos[i].wartosc) * 1000).toInt(); //miód w kg           
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              allPylek2029 = allPylek2029 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty ){
             //i pyłku (w ml)
              allPylek2029 = allPylek2029 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              allPylek2029 = allPylek2029 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
    }

  //dla kazdego ula (na prezentowanej stronie raportu) w 2029 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      double miod = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2029'){ //info z roku ...
          if(infos[i].ulNr == hivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2029 = miod2029 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2029 = miod2029 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " && infos[i].wartosc.isNotEmpty){
              miod = miod + (double.parse(infos[i].wartosc) * 1000).toInt();
              miod2029 = miod2029 + (double.parse(infos[i].wartosc) * 1000).toInt();             
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2029 = pylek2029 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2029 = pylek2029 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              pylek = pylek + (double.parse(infos[i].wartosc) * 1000).toInt();
              pylek2029 = pylek2029 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
      if(miod2029 > 0)
        daneZbioruMioduDoWykresu2029.add({ //to dodaj następny słupek wykresu
          "x": j,         // Kolejna wartość osi X - numer ula
          "value": miod,   // Wartość słupka
        });
      if(pylek2029 > 0)
        daneZbioruPylkuDoWykresu2029.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2029.isNotEmpty) _generateBarGroupsMiod2029();
    if(daneZbioruPylkuDoWykresu2029.isNotEmpty) _generateBarGroupsPylek2029();
  //===============================================================================================

  //2030
  //dla kazdego ula w pasiece w 2030 roku 
  for (var j = 1; j < allHivesNumbers.length + 1; j++) { 
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2030'){ //info z roku ...
          if(infos[i].ulNr == allHivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2030 = allMiod2030 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              allMiod2030 = allMiod2030 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = "  && infos[i].wartosc.isNotEmpty){
              allMiod2030 = allMiod2030 + (double.parse(infos[i].wartosc) * 1000).toInt(); //miód w kg           
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              allPylek2030 = allPylek2030 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty ){
             //i pyłku (w ml)
              allPylek2030 = allPylek2030 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              allPylek2030 = allPylek2030 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
    }

  //dla kazdego ula (na prezentowanej stronie raportu) w 2030 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      double miod = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2030'){ //info z roku ...
          if(infos[i].ulNr == hivesNumbers[j-1]) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              if(infos[i].pogoda=='') dm = 35175; //dla starszych wpisów przyjąć ze jest to mała ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2030 = miod2030 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" && infos[i].wartosc.isNotEmpty){
              if(infos[i].pogoda=='') dm = 78725; //dla starszych wpisów przyjąć ze jest to duza ramka wielkopolska
              else dm = double.parse(infos[i].pogoda);
              miod = miod + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);
              miod2030 = miod2030 + (double.parse(infos[i].wartosc) * int.parse(dod1[0].b) * dm/10000);             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " && infos[i].wartosc.isNotEmpty){
              miod = miod + (double.parse(infos[i].wartosc) * 1000).toInt();
              miod2030 = miod2030 + (double.parse(infos[i].wartosc) * 1000).toInt();             
            }
            if((infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x") && infos[i].wartosc.isNotEmpty){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2030 = pylek2030 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2030 = pylek2030 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  " && infos[i].wartosc.isNotEmpty){
             //i pyłku (w l)
              pylek = pylek + (double.parse(infos[i].wartosc) * 1000).toInt();
              pylek2030 = pylek2030 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
      if(miod2030 > 0)
        daneZbioruMioduDoWykresu2030.add({ //to dodaj następny słupek wykresu
          "x": j,         // Kolejna wartość osi X - numer ula
          "value": miod,   // Wartość słupka
        });
      if(pylek2030 > 0)
        daneZbioruPylkuDoWykresu2030.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2030.isNotEmpty) _generateBarGroupsMiod2030();
    if(daneZbioruPylkuDoWykresu2030.isNotEmpty) _generateBarGroupsPylek2030();
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
                    RaportScreen.routeName,
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
                    RaportScreen.routeName,
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
                    RaportScreen.routeName, 
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
                    RaportScreen.routeName, 
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
                    RaportScreen.routeName, 
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
                    RaportScreen.routeName, 
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
                    RaportScreen.routeName, 
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
                    RaportScreen.routeName, 
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
                    RaportScreen.routeName, 
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
          //           pageBuilder: (context, animation, secondaryAnimation) => RaportScreen(),
          //           transitionDuration: Duration.zero, // brak animacji
          //           reverseTransitionDuration: Duration.zero,
          //         ),
          //         //MaterialPageRoute(builder: (context) =>RaportScreen()),
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
                                            pageBuilder: (context, animation, secondaryAnimation) => RaportScreen(),
                                            transitionDuration: Duration.zero, // brak animacji
                                            reverseTransitionDuration: Duration.zero,
                                          ),
                                          //MaterialPageRoute(builder: (context) =>RaportScreen()),
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
                                          pageBuilder: (context, animation, secondaryAnimation) => RaportScreen(),
                                          transitionDuration: Duration.zero, // brak animacji
                                          reverseTransitionDuration: Duration.zero,
                                        ),
                                        //MaterialPageRoute(builder: (context) =>RaportScreen()),
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
        //kreska 
                    if(daneZbioruMioduDoWykresu2026.isNotEmpty && (globals.rokRaportow == 'wszystkie' || globals.rokRaportow == '2026'))  const Divider(
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
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toString()+' l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toString()+' l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toString()+' l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toString()+' l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toString()+' l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toString()+' l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toString()+' l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      double osY = value.toDouble()/1000; // /1000
                                      return Padding( 
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text (osY.toString()+' l', style: TextStyle(fontSize: 12)),// , fontWeight: FontWeight.bold
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
