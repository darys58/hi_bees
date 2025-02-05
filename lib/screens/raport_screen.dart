import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
  
  int miod2023 = 0;
  int miod2024 = 0;
  int miod2025 = 0;
  int miod2026 = 0;
  int miod2027 = 0;
  int miod2028 = 0;
  int miod2029 = 0;
  int miod2030 = 0;
  int pylek2023 = 0;
  int pylek2024 = 0;
  int pylek2025 = 0;
  int pylek2026 = 0;
  int pylek2027 = 0;
  int pylek2028 = 0;
  int pylek2029 = 0;
  int pylek2030 = 0;
  int varroa2023 = 0;
  int varroa2024 = 0;
  int varroa2025 = 0;
  int varroa2026 = 0;
  int varroa2027 = 0;
  int varroa2028 = 0;
  int varroa2029 = 0;
  int varroa2030 = 0;
  List<int> hivesNumbers = [];  //lista numerów wszystkich uli
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
  List<Map<String, dynamic>> daneVarroaDoWykresu2023 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2024 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2025 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2026 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2027 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2028 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2029 = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu2030 = [];
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
  List<BarChartGroupData> barGroupsVarroa2023 = [];
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
  void _generateBarGroupsMiod2023() {
    barGroupsMiod2023 = daneZbioruMioduDoWykresu2023.map((data) {
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

  void _generateBarGroupsMiod2024() {
    barGroupsMiod2024 = daneZbioruMioduDoWykresu2024.map((data) {
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

  void _generateBarGroupsMiod2025() {
    barGroupsMiod2025 = daneZbioruMioduDoWykresu2025.map((data) {
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

  void _generateBarGroupsMiod2026() {
    barGroupsMiod2026 = daneZbioruMioduDoWykresu2026.map((data) {
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

  void _generateBarGroupsMiod2027() {
    barGroupsMiod2027 = daneZbioruMioduDoWykresu2027.map((data) {
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

  void _generateBarGroupsMiod2028() {
    barGroupsMiod2028 = daneZbioruMioduDoWykresu2028.map((data) {
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

  void _generateBarGroupsMiod2029() {
    barGroupsMiod2029 = daneZbioruMioduDoWykresu2029.map((data) {
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

  void _generateBarGroupsMiod2030() {
    barGroupsMiod2030 = daneZbioruMioduDoWykresu2030.map((data) {
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

  void _generateBarGroupsPylek2023() {
    barGroupsPylek2023 = daneZbioruPylkuDoWykresu2023.map((data) {
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

  void _generateBarGroupsPylek2024() {
    barGroupsPylek2024 = daneZbioruPylkuDoWykresu2024.map((data) {
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

  void _generateBarGroupsPylek2025() {
    barGroupsPylek2025 = daneZbioruPylkuDoWykresu2025.map((data) {
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

  void _generateBarGroupsPylek2026() {
    barGroupsPylek2026 = daneZbioruPylkuDoWykresu2026.map((data) {
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

  void _generateBarGroupsPylek2027() {
    barGroupsPylek2027 = daneZbioruPylkuDoWykresu2027.map((data) {
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

  void _generateBarGroupsPylek2028() {
    barGroupsPylek2028 = daneZbioruPylkuDoWykresu2028.map((data) {
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
 
  void _generateBarGroupsPylek2029() {
    barGroupsPylek2029 = daneZbioruPylkuDoWykresu2029.map((data) {
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

  void _generateBarGroupsPylek2030() {
    barGroupsPylek2030 = daneZbioruPylkuDoWykresu2030.map((data) {
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
//  void _generateBarGroupsVarroa2023() {
//     barGroupsVarroa2023 = daneVarroaDoWykresu2023.map((data) {
//       // Dodajemy mapowanie wartości 'x' na etykietę tekstową
//       //xAxisLabelsMiod[data['x']] = data['label'];
//       return BarChartGroupData(
//         x: data['x'], // Wartość X - kolejny numer słupka
//         barRods: [
//           BarChartRodData(
//             toY: data['value'].toDouble(), // Wartość Y z bazy danych
//             borderRadius: BorderRadius.zero, //słupek bez zaokrągleń
//             color: Color.fromARGB(255, 56, 127, 251),
//           ),
//         ],
//       );
//     }).toList();
//   }


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
      return inf.kategoria.contains('harvest');
    }).toList();

    //TWORZENIE DANYCH DO WYKRESóW
    //dla kazdego ula w 2023 roku
    for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int miodMala = 0;
      int miodDuza = 0;
      int pylek = 0;
     // int varroa = 0;

      //sumowanie zbiorów i tworzenie słupków wykresów
      for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2023'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x"){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              miodMala = miodMala + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
              miod2023 = miod2023 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x"){
              miodDuza = miodDuza + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));
              miod2023 = miod2023 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x"){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2023 = pylek2023 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = "){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2023 = pylek2023 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  "){
             //i pyłku (w l)
              pylek = pylek + (double.parse(infos[i].wartosc) * 1000).toInt();
              pylek2023 = pylek2023 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
            // if(infos[i].parametr == "varroa"){
            //   varroa = varroa + int.parse(infos[i].wartosc); //sumowanie varroa w ulu 
            //   varroa2023 = varroa2023 + int.parse(infos[i].wartosc); //sumowanie varroa dla całej pasieki
            // print('varroa - $varroa');
            // }

          }
        }
      }
      if(miod2023 > 0)
        daneZbioruMioduDoWykresu2023.add({ //to dodaj następny słupek wykresu
          "x": j,         // Kolejna wartość osi X - numer ula
          "value": miodMala + miodDuza,   // Wartość słupka
        });
      // daneVarroaDoWykresu2023.add({
      //   "x": j,         // Kolejna wartość osi X
      //   "value": varroa,   // Wartość słupka
      // });
      if(pylek2023 > 0)
        daneZbioruPylkuDoWykresu2023.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2023.isNotEmpty) _generateBarGroupsMiod2023();
    if(daneZbioruPylkuDoWykresu2023.isNotEmpty) _generateBarGroupsPylek2023();
    //if(daneVarroaDoWykresu2023.isNotEmpty) _generateBarGroupsVarroa2023(); 

  //dla kazdego ula w 2024 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int miodMala = 0;
      int miodDuza = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2024'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x"){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              miodMala = miodMala + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
              miod2024 = miod2024 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x"){
              miodDuza = miodDuza + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));
              miod2024 = miod2024 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x"){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2024 = pylek2024 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = "){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2024 = pylek2024 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  "){
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
          "value": miodMala + miodDuza,   // Wartość słupka
        });
      if(pylek2024 > 0)
        daneZbioruPylkuDoWykresu2024.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2024.isNotEmpty) _generateBarGroupsMiod2024();
    if(daneZbioruPylkuDoWykresu2024.isNotEmpty) _generateBarGroupsPylek2024();

  //dla kazdego ula w 2025 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int miodMala = 0;
      int miodDuza = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2025'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x"){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              miodMala = miodMala + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
              miod2025 = miod2025 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x"){
              miodDuza = miodDuza + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));
              miod2025 = miod2025 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x"){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2025 = pylek2025 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = "){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2025 = pylek2025 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  "){
             //i pyłku (w l)
              pylek = pylek + (double.parse(infos[i].wartosc) * 1000).toInt();
              pylek2025 = pylek2025 + (double.parse(infos[i].wartosc) * 1000).toInt();            
            }
          }
        }
      }
      if(miod2025 > 0)
        daneZbioruMioduDoWykresu2025.add({ //to dodaj następny słupek wykresu
          "x": j,         // Kolejna wartość osi X - numer ula
          "value": miodMala + miodDuza,   // Wartość słupka
        });
      if(pylek2025 > 0)
        daneZbioruPylkuDoWykresu2025.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2025.isNotEmpty) _generateBarGroupsMiod2025();
    if(daneZbioruPylkuDoWykresu2025.isNotEmpty) _generateBarGroupsPylek2025();

  //dla kazdego ula w 2026 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int miodMala = 0;
      int miodDuza = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2026'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x"){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              miodMala = miodMala + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
              miod2026 = miod2026 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x"){
              miodDuza = miodDuza + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));
              miod2026 = miod2026 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x"){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2026 = pylek2026 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = "){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2026 = pylek2026 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  "){
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
          "value": miodMala + miodDuza,   // Wartość słupka
        });
      if(pylek2026 > 0)
        daneZbioruPylkuDoWykresu2026.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2026.isNotEmpty) _generateBarGroupsMiod2026();
    if(daneZbioruPylkuDoWykresu2026.isNotEmpty) _generateBarGroupsPylek2026();

  //dla kazdego ula w 2027 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int miodMala = 0;
      int miodDuza = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2027'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x"){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              miodMala = miodMala + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
              miod2027 = miod2027 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x"){
              miodDuza = miodDuza + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));
              miod2027 = miod2027 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x"){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2027 = pylek2027 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = "){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2027 = pylek2027 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  "){
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
          "value": miodMala + miodDuza,   // Wartość słupka
        });
      if(pylek2027 > 0)
        daneZbioruPylkuDoWykresu2027.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2027.isNotEmpty) _generateBarGroupsMiod2027();
    if(daneZbioruPylkuDoWykresu2027.isNotEmpty) _generateBarGroupsPylek2027();
         
  //dla kazdego ula w 2028 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int miodMala = 0;
      int miodDuza = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2028'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x"){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              miodMala = miodMala + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
              miod2028 = miod2028 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x"){
              miodDuza = miodDuza + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));
              miod2028 = miod2028 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x"){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2028 = pylek2028 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = "){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2028 = pylek2028 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  "){
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
          "value": miodMala + miodDuza,   // Wartość słupka
        });
      if(pylek2028 > 0)
        daneZbioruPylkuDoWykresu2028.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2028.isNotEmpty) _generateBarGroupsMiod2028();
    if(daneZbioruPylkuDoWykresu2028.isNotEmpty) _generateBarGroupsPylek2028();
   
  //dla kazdego ula w 2029 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int miodMala = 0;
      int miodDuza = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2029'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x"){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              miodMala = miodMala + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
              miod2029 = miod2029 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x"){
              miodDuza = miodDuza + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));
              miod2029 = miod2029 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x"){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2029 = pylek2029 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = "){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2029 = pylek2029 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  "){
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
          "value": miodMala + miodDuza,   // Wartość słupka
        });
      if(pylek2029 > 0)
        daneZbioruPylkuDoWykresu2029.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2029.isNotEmpty) _generateBarGroupsMiod2029();
    if(daneZbioruPylkuDoWykresu2029.isNotEmpty) _generateBarGroupsPylek2029();
  
  //dla kazdego ula w 2030 roku
  for (var j = 1; j < hivesNumbers.length + 1; j++) { 
      int miodMala = 0;
      int miodDuza = 0;
      int pylek = 0;
      //sumowanie zbiorów i tworzenie słupka wykresu
    for (var i = 0; i < infos.length; i++) {
        if (infos[i].data.substring(0, 4) == '2030'){ //info z roku ...
          if(infos[i].ulNr == j) {  //dla ula nr ...
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x"){ 
              //i danego rodzaju zbioru (miód, mała ramka)
              miodMala = miodMala + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
              miod2030 = miod2030 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x"){
              miodDuza = miodDuza + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));
              miod2030 = miod2030 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x"){
             //i pyłku (dla miarki)
              pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
              pylek2030 = pylek2030 + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));             
            }
            if(infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = "){
             //i pyłku (w ml)
              pylek = pylek + int.parse(infos[i].wartosc);
              pylek2030 = pylek2030 + int.parse(infos[i].wartosc);             
            }
            if(infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  "){
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
          "value": miodMala + miodDuza,   // Wartość słupka
        });
      if(pylek2030 > 0)
        daneZbioruPylkuDoWykresu2030.add({
          "x": j,         // Kolejna wartość osi X
          "value": pylek,   // Wartość słupka
        });
    }
    if(daneZbioruMioduDoWykresu2030.isNotEmpty) _generateBarGroupsMiod2030();
    if(daneZbioruPylkuDoWykresu2030.isNotEmpty) _generateBarGroupsPylek2030();
  
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
        title: Text(AppLocalizations.of(context)!.hArvestReports,
          //AppLocalizations.of(context)!.pArameterization,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
      ),
      body: SingleChildScrollView(
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
                  if(daneZbioruMioduDoWykresu2030.isNotEmpty) SizedBox(height: 10),
                  if(daneZbioruMioduDoWykresu2030.isNotEmpty) Text(AppLocalizations.of(context)!.hOneyHarvest + ' 2030: ${miod2030/1000} kg', style: TextStyle(fontSize: 16)),
                  if(daneZbioruMioduDoWykresu2030.isNotEmpty)
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
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                    // child: RotatedBox(
                                    //   quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
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
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    double osY = value.toDouble()/1000;
                                    return Padding( 
                                      padding: const EdgeInsets.only(left: 10.0),
                                      child: Text (osY.toString()+' kg', style: TextStyle(fontSize: 12)),
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

//miód wykres 2029 
                  if(daneZbioruMioduDoWykresu2029.isNotEmpty) SizedBox(height: 10),
                  if(daneZbioruMioduDoWykresu2029.isNotEmpty) Text(AppLocalizations.of(context)!.hOneyHarvest + ' 2029: ${miod2029/1000} kg', style: TextStyle(fontSize: 16)),
                  if(daneZbioruMioduDoWykresu2029.isNotEmpty)
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
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                    // child: RotatedBox(
                                    //   quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
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
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    double osY = value.toDouble()/1000;
                                    return Padding( 
                                      padding: const EdgeInsets.only(left: 10.0),
                                      child: Text (osY.toString()+' kg', style: TextStyle(fontSize: 12)),
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

//miód wykres 2028 
                  if(daneZbioruMioduDoWykresu2028.isNotEmpty) SizedBox(height: 10),
                  if(daneZbioruMioduDoWykresu2028.isNotEmpty) Text(AppLocalizations.of(context)!.hOneyHarvest + ' 2028: ${miod2028/1000} kg', style: TextStyle(fontSize: 16)),
                  if(daneZbioruMioduDoWykresu2028.isNotEmpty)
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
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                    // child: RotatedBox(
                                    //   quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
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
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    double osY = value.toDouble()/1000;
                                    return Padding( 
                                      padding: const EdgeInsets.only(left: 10.0),
                                      child: Text (osY.toString()+' kg', style: TextStyle(fontSize: 12)),
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

//miód wykres 2027 
                  if(daneZbioruMioduDoWykresu2027.isNotEmpty) SizedBox(height: 10),
                  if(daneZbioruMioduDoWykresu2027.isNotEmpty) Text(AppLocalizations.of(context)!.hOneyHarvest + ' 2027: ${miod2027/1000} kg', style: TextStyle(fontSize: 16)),
                  if(daneZbioruMioduDoWykresu2027.isNotEmpty)
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
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                    // child: RotatedBox(
                                    //   quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
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
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    double osY = value.toDouble()/1000;
                                    return Padding( 
                                      padding: const EdgeInsets.only(left: 10.0),
                                      child: Text (osY.toString()+' kg', style: TextStyle(fontSize: 12)),
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
        
//miód wykres 2026 
                  if(daneZbioruMioduDoWykresu2026.isNotEmpty) SizedBox(height: 10),
                  if(daneZbioruMioduDoWykresu2026.isNotEmpty) Text(AppLocalizations.of(context)!.hOneyHarvest + ' 2026: ${miod2027/1000} kg', style: TextStyle(fontSize: 16)),
                  if(daneZbioruMioduDoWykresu2026.isNotEmpty)
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
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                    // child: RotatedBox(
                                    //   quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
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
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    double osY = value.toDouble()/1000;
                                    return Padding( 
                                      padding: const EdgeInsets.only(left: 10.0),
                                      child: Text (osY.toString()+' kg', style: TextStyle(fontSize: 12)),
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
        
//miód wykres 2025 
                  if(daneZbioruMioduDoWykresu2025.isNotEmpty) SizedBox(height: 10),
                  if(daneZbioruMioduDoWykresu2025.isNotEmpty) Text(AppLocalizations.of(context)!.hOneyHarvest + ' 2025: ${miod2025/1000} kg', style: TextStyle(fontSize: 16)),
                  if(daneZbioruMioduDoWykresu2025.isNotEmpty)
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
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                    // child: RotatedBox(
                                    //   quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
                                        child: Text(text, style: TextStyle(fontSize: 12)),
                                    // ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles( //lewe opisy osi
                                axisNameSize: 20,
                               // axisNameWidget: Text('kg'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    double osY = value.toDouble()/1000;
                                    return Padding( 
                                      padding: const EdgeInsets.only(left: 10.0),
                                      child: Text (osY.toString()+' kg', style: TextStyle(fontSize: 12)),
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
        
//miód wykres 2024
                  if(daneZbioruMioduDoWykresu2024.isNotEmpty) SizedBox(height: 10),
                  if(daneZbioruMioduDoWykresu2024.isNotEmpty) Text(AppLocalizations.of(context)!.hOneyHarvest + ' 2024: ${miod2024/1000} kg', style: TextStyle(fontSize: 16)),
                  if(daneZbioruMioduDoWykresu2024.isNotEmpty)
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
                                  reservedSize: 50,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    // Pobieranie tekstu na podstawie wartości 'x'
                                    String text = value.toInt().toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                    // child: RotatedBox(
                                    //   quarterTurns: 3, // Obracamy o -90 stopni (czyli 270 stopni)
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
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    double osY = value.toDouble()/1000;
                                    return Padding( 
                                      padding: const EdgeInsets.only(left: 10.0),
                                      child: Text (osY.toString()+' kg', style: TextStyle(fontSize: 12)),
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
        
//miód wykres 2023        
                if(daneZbioruMioduDoWykresu2023.isNotEmpty) SizedBox(height: 10),
                if(daneZbioruMioduDoWykresu2023.isNotEmpty) Text(AppLocalizations.of(context)!.hOneyHarvest + ' 2023: ${miod2023/1000} kg', style: TextStyle(fontSize: 16),),  
                if(daneZbioruMioduDoWykresu2023.isNotEmpty)
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
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    double osY = value.toDouble()/1000;
                                    return Padding( 
                                      padding: const EdgeInsets.only(left: 10.0),
                                      child: Text (osY.toString()+' kg', style: TextStyle(fontSize: 12)),
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

//pyłek wykres 2030        
                if(daneZbioruPylkuDoWykresu2030.isNotEmpty) SizedBox(height: 10),
                if(daneZbioruPylkuDoWykresu2030.isNotEmpty) Text(AppLocalizations.of(context)!.bEePollenHarvest + ' 2030: ${pylek2024/1000} l', style: TextStyle(fontSize: 16),),  
                if(daneZbioruPylkuDoWykresu2030.isNotEmpty)
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
                                //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
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

//pyłek wykres 2029        
                if(daneZbioruPylkuDoWykresu2029.isNotEmpty) SizedBox(height: 10),
                if(daneZbioruPylkuDoWykresu2029.isNotEmpty) Text(AppLocalizations.of(context)!.bEePollenHarvest + ' 2029: ${pylek2024/1000} l', style: TextStyle(fontSize: 16),),  
                if(daneZbioruPylkuDoWykresu2029.isNotEmpty)
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
                                //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
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

//pyłek wykres 2028        
                if(daneZbioruPylkuDoWykresu2028.isNotEmpty) SizedBox(height: 10),
                if(daneZbioruPylkuDoWykresu2028.isNotEmpty) Text(AppLocalizations.of(context)!.bEePollenHarvest + ' 2028: ${pylek2024/1000} l', style: TextStyle(fontSize: 16),),  
                if(daneZbioruPylkuDoWykresu2028.isNotEmpty)
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
                                //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
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

//pyłek wykres 2027        
                if(daneZbioruPylkuDoWykresu2027.isNotEmpty) SizedBox(height: 10),
                if(daneZbioruPylkuDoWykresu2027.isNotEmpty) Text(AppLocalizations.of(context)!.bEePollenHarvest + ' 2027: ${pylek2024/1000} l', style: TextStyle(fontSize: 16),),  
                if(daneZbioruPylkuDoWykresu2027.isNotEmpty)
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
                                //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
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

//pyłek wykres 2026        
                if(daneZbioruPylkuDoWykresu2026.isNotEmpty) SizedBox(height: 10),
                if(daneZbioruPylkuDoWykresu2026.isNotEmpty) Text(AppLocalizations.of(context)!.bEePollenHarvest + ' 2026: ${pylek2024/1000} l', style: TextStyle(fontSize: 16),),  
                if(daneZbioruPylkuDoWykresu2026.isNotEmpty)
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
                                //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
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

//pyłek wykres 2025        
                if(daneZbioruPylkuDoWykresu2025.isNotEmpty) SizedBox(height: 10),
                if(daneZbioruPylkuDoWykresu2025.isNotEmpty) Text(AppLocalizations.of(context)!.bEePollenHarvest + ' 2025: ${pylek2024/1000} l', style: TextStyle(fontSize: 16),),  
                if(daneZbioruPylkuDoWykresu2025.isNotEmpty)
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
                                //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
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

//pyłek wykres 2024        
                if(daneZbioruPylkuDoWykresu2024.isNotEmpty) SizedBox(height: 10),
                if(daneZbioruPylkuDoWykresu2024.isNotEmpty) Text(AppLocalizations.of(context)!.bEePollenHarvest + ' 2024: ${pylek2024/1000} l', style: TextStyle(fontSize: 16),),  
                if(daneZbioruPylkuDoWykresu2024.isNotEmpty)
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
                                //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
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

//pyłek wykres 2023        
                if(daneZbioruPylkuDoWykresu2023.isNotEmpty) SizedBox(height: 10),
                if(daneZbioruPylkuDoWykresu2023.isNotEmpty) Text(AppLocalizations.of(context)!.bEePollenHarvest + ' 2023: ${pylek2023/1000} l', style: TextStyle(fontSize: 16),),  
                if(daneZbioruPylkuDoWykresu2023.isNotEmpty)
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
                                //axisNameWidget: Text('w litrach'), //nazwa osi lewej
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
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
    );
  }
}
