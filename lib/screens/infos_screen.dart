import 'package:flutter/material.dart';
//import 'package:hi_bees/screens/frame_edit_screen2.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import '../globals.dart' as globals;
import '../models/info.dart';
import '../models/infos.dart';
import '../widgets/info_item.dart';
import '../models/dodatki1.dart';
import '../screens/infos_edit_screen.dart';
import '../screens/frame_edit_screen.dart';
import '../screens/frame_edit_screen2.dart';

class InfoScreen extends StatefulWidget {
  static const routeName = '/screen-infos';

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  bool _isInit = true;
  String wybranaKategoria = globals.aktualnaKategoriaInfo;
  String rokStatystyk = globals.rokStatystyk; //DateTime.now().toString().substring(0, 4);

  List<Color> colory = [
    const Color.fromARGB(255, 252, 193, 104),
    const Color.fromARGB(255, 255, 114, 104),
    const Color.fromARGB(255, 104, 187, 254),
    const Color.fromARGB(255, 83, 215, 88),
    const Color.fromARGB(255, 203, 174, 85),
    const Color.fromARGB(255, 253, 182, 76),
    const Color.fromARGB(255, 255, 86, 74),
    const Color.fromARGB(255, 71, 170, 251),
    Color.fromARGB(255, 61, 214, 66),
    Color.fromARGB(255, 210, 170, 49),
  ];

  List<Map<String, dynamic>> daneZbioruPylkuDoWykresu = [];
  List<Map<String, dynamic>> daneZbioruMioduDoWykresu = [];
  List<Map<String, dynamic>> daneVarroaDoWykresu = [];     
  
  // List<Map<String, dynamic>> dataFromDatabase = [
  //   {"x": 0, "value": 20, "label": "Jan"},
  //   {"x": 1, "value": 400, "label": "Feb"},
  //   {"x": 2, "value": 300, "label": "Mar"},
  //   {"x": 3, "value": 50, "label": "Apr"},
  // ];
  List<BarChartGroupData> barGroupsPylek = []; //lista elementów sekcji "barGroupsPylek" czyli słupki wykresu pyłku
  Map<int, String> xAxisLabelsPylek = {}; // Mapowanie etykiet tekstowych dla osi X wykresy pyłku
  List<BarChartGroupData> barGroupsMiod = []; //lista elementów sekcji "barGroupsPylek" czyli słupki wykresu miodu
  Map<int, String> xAxisLabelsMiod = {}; // Mapowanie etykiet tekstowych dla osi X wykresy miodu
  List<BarChartGroupData> barGroupsVarroa = []; //lista elementów sekcji "barGroupsPylek" czyli słupki wykresu warrozy
  Map<int, String> xAxisLabelsVarroa = {}; // Mapowanie etykiet tekstowych dla osi X wykresy warrozy
  
  @override
  void didChangeDependencies() {
    // print('frames_screen - didChangeDependencies');

    // print('frames_screen - _isInit = $_isInit');

    if (_isInit) {
      //wszystkie informacje dla wybranej pasieki i ula
      Provider.of<Infos>(context, listen: false)
          .fetchAndSetInfosForHive(globals.pasiekaID, globals.ulID)
          .then((_) {
        //wywołanie funkcji dynamicznego tworzenia słupków wykresu
         
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

  // Funkcja do dynamicznego tworzenia słupków wykresu na podstawie danych - dynamiczne tworzenie sekcji "barGroupsPylek"
  void _generateBarGroupsPylek() {
    barGroupsPylek = daneZbioruPylkuDoWykresu.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      xAxisLabelsPylek[data['x']] = data['label'];
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

  // Funkcja do dynamicznego tworzenia słupków wykresu na podstawie danych - dynamiczne tworzenie sekcji "barGroupsMiod"
  void _generateBarGroupsMiod() {
    barGroupsMiod = daneZbioruMioduDoWykresu.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      xAxisLabelsMiod[data['x']] = data['label'];
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

  // Funkcja do dynamicznego tworzenia słupków wykresu na podstawie danych - dynamiczne tworzenie sekcji "barGroupsVarroa"
  void _generateBarGroupsVarroa() {
    barGroupsVarroa = daneVarroaDoWykresu.map((data) {
      // Dodajemy mapowanie wartości 'x' na etykietę tekstową
      xAxisLabelsVarroa[data['x']] = data['label'];
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
    //przekazanie hiveNr z hives_item za pomocą navigatora
    final hiveNr = ModalRoute.of(context)!.settings.arguments as int;

    int kolor = globals.pasiekaID;
    while (kolor > 10) {
      kolor = kolor - 10;
    }
    //pobranie danych parametryzacyjnych (e - waga mała ramka, f - waga duza ramka)
    final dod1Data = Provider.of<Dodatki1>(context, listen: false);
    final dod1 = dod1Data.items;

    //pobranie danych info z wybranej kategorii
    final infosData = Provider.of<Infos>(context);
    List<Info> infos = infosData.items.where((inf) {
      return inf.kategoria.contains(wybranaKategoria);
    }).toList();
    //print('======= infos globals ${globals.pasiekaID}, ${globals.ulID}');
    // print(wybranaKategoria);
    // print('======= infos lenght ${infos.length}');

    int miod = 0; //suma zboru miodu w g
    int miodSlupekNr = 0; //numer słupka na wykresie zbioru miodu
    daneZbioruMioduDoWykresu = []; //zerowanie danych wykresu miodu dla ula
    String tempDataZbioru = ''; // tymczasowe zapamietanie daty zbioru przy dodawaniu zbiorów miodu z małych i duzych ramek
    
    int pylek = 0; //suma zbioru pyłku w ml
    int pylekSlupekNr = 0; //numer słupka na wykresie zbioru pyłku
    daneZbioruPylkuDoWykresu = []; //zerowanie danych wykresu pyłku dla ula

    int varroa = 0; //suma varroa w sztukach
    int varroaSlupekNr = 0; //numer słupka na wykresie varroa
    daneVarroaDoWykresu = []; //zerowanie danych wykresu varroa dla ula

    double wysokoscStatystyk = 0;
    int dodatek = 0;
    var ostatniaData1 = DateTime.parse('2022-01-01 00:00');
    var ostatniaData2 = DateTime.parse('2022-01-01 00:00');
    var ostatniaData3 = DateTime.parse('2022-01-01 00:00');
    var ostatniaData4 = DateTime.parse('2022-01-01 00:00');
    var ostatniaData5 = DateTime.parse('2022-01-01 00:00');
    var ostatniaData6 = DateTime.parse('2022-01-01 00:00');
    String wartosc1 = ''; //queenBorn
    String wartosc2 = ''; //queenState
    String wartosc3 = ''; //queenStart
    String wartosc4 = ''; //queenMark
    String wartosc5 = ''; //queenQuality
    String wartosc6 = '';
    double suma1 = 0.0;
    double suma2 = 0.0;
    double suma3 = 0.0;
    double suma4 = 0.0;
   //double suma5 = 0.0;


    //dla kazdego info o zbiorach - podliczenie roczne zbiorów i przygotowanie danych do wykresów
    for (var i = 0; i < infos.length; i++) {
      // print(
      //     '${infos[i].id},${infos[i].data},${infos[i].pasiekaNr},${infos[i].ulNr},${infos[i].kategoria},${infos[i].parametr},${infos[i].wartosc},${infos[i].miara},${infos[i].pogoda},${infos[i].temp},${infos[i].czas},${infos[i].uwagi},${infos[i].arch}');
      // print('======= infos $i');
      // print(infos[i].parametr);

      //****** ZBIORY*****  dla harvest:
      if (wybranaKategoria == 'harvest') {
        //dla bierzącego roku i danego rodzaju zbioru (miód, mała ramka)
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x") {
          miod = miod + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
          //dane do wykresu
          if(tempDataZbioru != infos[i].data){ //jezeli data aktualnego wpisu o zbioze miodu jeszcze nie wystąpiła
            daneZbioruMioduDoWykresu.add({ //to dodaj następny słupek wykresu
              "x": miodSlupekNr,         // Kolejna wartość osi X
              "value": int.parse(infos[i].wartosc) * int.parse(dod1[0].e),   // Wartość słupka
              "label": "${zmienDate5_10(infos[i].data.substring(5, 10))}"  // Etykieta dla osi X - data zbioru
            });
            tempDataZbioru = infos[i].data; //zapamietanie daty zbioru
            miodSlupekNr = miodSlupekNr + 1;
          }else{ //jezeli data jest taka sama jak przy ostatnim wpisie to dodaj wartość zbióru do poprzedniego słupka wykresu
            daneZbioruMioduDoWykresu[daneZbioruMioduDoWykresu.length - 1]['value'] //tzn. edytuj poprzednią wartość "value"
            = daneZbioruMioduDoWykresu[daneZbioruMioduDoWykresu.length - 1]['value'] //dodając do niej
            + int.parse(infos[i].wartosc) * int.parse(dod1[0].e); //kolejną wartość bo jest taka sama data zbioru 
          }
        }
        //dla bierzącego roku i danego rodzaju zbioru (miód, duza ramka)
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x") {
          miod = miod + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));
          //dane do wykresu
          if(tempDataZbioru != infos[i].data){ //jezeli data aktualnego wpisu o zbioze miodu jeszcze nie wystąpiła
            daneZbioruMioduDoWykresu.add({ //to dodaj następny słupek wykresu
              "x": miodSlupekNr,         // Kolejna wartość osi X
              "value": int.parse(infos[i].wartosc) * int.parse(dod1[0].f),   // Wartość słupka
              "label": "${zmienDate5_10(infos[i].data.substring(5, 10))}"  // Etykieta dla osi X - data zbioru
            });
            tempDataZbioru = infos[i].data; //zapamietanie daty zbioru
            miodSlupekNr = miodSlupekNr + 1;
          }else{ //jezeli data jest taka sama jak przy ostatnim wpisie to dodaj wartość zbióru do poprzedniego słupka wykresu
            daneZbioruMioduDoWykresu[daneZbioruMioduDoWykresu.length - 1]['value'] //tzn. edytuj poprzednią wartość "value"
            = daneZbioruMioduDoWykresu[daneZbioruMioduDoWykresu.length - 1]['value'] //dodając do niej
            + int.parse(infos[i].wartosc) * int.parse(dod1[0].e); //kolejną wartość bo jest taka sama data zbioru 
          }
        }
        //dla bierzącego roku i danego rodzaju zbioru (pyłek, miarka)
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            (infos[i].parametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.portion + " x" ||
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x")) {
          pylek = pylek + (int.parse(infos[i].wartosc) * int.parse(dod1[0].g));
          //dane do wykresu
          daneZbioruPylkuDoWykresu.add({
            "x": pylekSlupekNr,         // Kolejna wartość osi X
            "value": int.parse(infos[i].wartosc) * int.parse(dod1[0].g),   // Wartość słupka
            "label": "${zmienDate5_10(infos[i].data.substring(5, 10))}"  // Etykieta dla osi X
          });
          pylekSlupekNr = pylekSlupekNr + 1;
        }
        //dla bierzącego roku i danego rodzaju zbioru (pyłek w ml)
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.beePollen + " = ") {
          pylek = pylek + (int.parse(infos[i].wartosc));
          //dane do wykresu
          daneZbioruPylkuDoWykresu.add({
            "x": pylekSlupekNr,         // Kolejna wartość osi X
            "value": int.parse(infos[i].wartosc),   // Wartość słupka
            "label": "${zmienDate5_10(infos[i].data.substring(5, 10))}"  // Etykieta dla osi X
          });
          pylekSlupekNr = pylekSlupekNr + 1;
        }

        //dla bierzącego roku i danego rodzaju zbioru (pyłek w l)
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == " " + AppLocalizations.of(context)!.beePollen + " =  ") {
          pylek = pylek + (double.parse(infos[i].wartosc) * 1000).toInt();
          //dane do wykresu
          daneZbioruPylkuDoWykresu.add({
            "x": pylekSlupekNr,         // Kolejna wartość osi X
            "value": (double.parse(infos[i].wartosc) * 1000).toInt(),   // Wartość słupka
            "label": "${zmienDate5_10(infos[i].data.substring(5, 10))}"  // Etykieta dla osi X
          });
          pylekSlupekNr = pylekSlupekNr + 1;
        }
      }

      //********** WYPOSAZENIE ******** dla kategorii equipment
      if (wybranaKategoria == 'equipment') {
        //dla bierzącego roku i parametru excluder
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.excluder) {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData1)) {
            ostatniaData1 = DateTime.parse(infos[i].data);
            wartosc1 = AppLocalizations.of(context)!.excluder + 
                ' ' + AppLocalizations.of(context)!.on + ' ' + infos[i].miara +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})'; //zamiana na polski format
          }
        }
        //dla bierzącego roku i parametru excluder - usuń
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == " " + AppLocalizations.of(context)!.excluder + " -") {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData1)) {
            ostatniaData1 = DateTime.parse(infos[i].data);
            wartosc1 = AppLocalizations.of(context)!.excluder + ' - ' + AppLocalizations.of(context)!.lack +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})'; //zamiana na polski format
          }
        }
        //dla bierzącego roku i parametru bottomBoard
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.bottomBoard + " " + AppLocalizations.of(context)!.isIs) {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData2)) {
            ostatniaData2 = DateTime.parse(infos[i].data);
            wartosc2 = infos[i].parametr + ' ' + infos[i].wartosc +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i parametru beePolenTrap
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.beePollenTrap + " " + AppLocalizations.of(context)!.isIs) {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData3)) {
            ostatniaData3 = DateTime.parse(infos[i].data);
            wartosc3 = infos[i].parametr + ' ' + infos[i].wartosc +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i parametru numberOfFrame
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.numberOfFrame + " = ") {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData4)) {
            ostatniaData4 = DateTime.parse(infos[i].data);
            wartosc4 = infos[i].parametr + ' ' + infos[i].wartosc +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
      }

      //********** RODZINA ******** dla kategorii colony
      if (wybranaKategoria == 'colony') {
        //dla bierzącego roku i parametru colonyForce
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == " " + AppLocalizations.of(context)!.colony + " " + AppLocalizations.of(context)!.isIs) {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData1)) {
            ostatniaData1 = DateTime.parse(infos[i].data);
            wartosc1 = infos[i].wartosc +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i cechy colony colonyState
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.colony + " " + AppLocalizations.of(context)!.isIs) {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData2)) {
            ostatniaData2 = DateTime.parse(infos[i].data);
            wartosc2 = infos[i].wartosc +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i cechy colony deadBees
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.deadBees) {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData3)) {
            ostatniaData3 = DateTime.parse(infos[i].data);
            wartosc3 = infos[i].wartosc + ' ' + infos[i].miara +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
      }

      //********** MATKA ******** dla queen
      if (wybranaKategoria == 'queen') {
        //dla bierzącego roku i cechy matki queenBorn
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.queenWasBornIn) {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData5)) {
            ostatniaData5 = DateTime.parse(infos[i].data);
            wartosc5 = infos[i].wartosc +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i cechy matki queenState (dziewica, naturalna)
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.queen + " -") {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData3)) {
            ostatniaData3 = DateTime.parse(infos[i].data);
            wartosc3 = infos[i].wartosc +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i cechy matki queenStart (wolna, w klatce)
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.queenIs) {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData4)) {
            ostatniaData4 = DateTime.parse(infos[i].data);
            wartosc4 = infos[i].wartosc +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i cechy matki queenMark
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == " " + AppLocalizations.of(context)!.queen) {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData2)) {
            ostatniaData2 = DateTime.parse(infos[i].data);
            wartosc2 = infos[i].wartosc + ' ' + infos[i].miara +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i cechy matki queenQuality (bardzo dobra)
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.queen + '  ' + AppLocalizations.of(context)!.isIs) {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData1)) {
            ostatniaData1 = DateTime.parse(infos[i].data);
            wartosc1 = infos[i].wartosc +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
      }

      //********** POKARM ******** dla kategorii feeding
      if (wybranaKategoria == 'feeding') {
        //dla bierzącego roku i parametru syrup1to1I,syrup1to1D
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.syrup + " 1:1") {
          suma1 = suma1 + double.parse(infos[i].wartosc);
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData1)) {
            ostatniaData1 = DateTime.parse(infos[i].data);
            globals.jezyk == 'pl_PL'
                ? wartosc1 = infos[i].wartosc.replaceAll('.', ',') + ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})'
                : wartosc1 = infos[i].wartosc + ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i parametru syrup3to2I,syrup3to2D
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
                 infos[i].parametr == AppLocalizations.of(context)!.syrup + " 3:2") {
          suma2 = suma2 + double.parse(infos[i].wartosc);
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData2)) {
            ostatniaData2 = DateTime.parse(infos[i].data);
            globals.jezyk == 'pl_PL'
                ? wartosc2 = infos[i].wartosc.replaceAll('.', ',') + ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})'
                : wartosc2 = infos[i].wartosc + ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i parametru invert
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.invert) {
          suma3 = suma3 + double.parse(infos[i].wartosc);
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData3)) {
            ostatniaData3 = DateTime.parse(infos[i].data);
            globals.jezyk == 'pl_PL'
                ? wartosc3 = infos[i].wartosc.replaceAll('.', ',') + ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})'
                : wartosc3 = infos[i].wartosc + ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i parametru candy
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.candy) {
          suma4 = suma4 + double.parse(infos[i].wartosc);
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData4)) {
            ostatniaData4 = DateTime.parse(infos[i].data);
            globals.jezyk == 'pl_PL'
                ? wartosc4 = infos[i].wartosc.replaceAll('.', ',') + ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})'
                : wartosc4 = infos[i].wartosc +  ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';

          }
        }
        //dla bierzącego roku i parametru removeFood
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.removedFood) {
          //suma5 = suma5 + double.parse(infos[i].wartosc);
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData5) && DateTime.parse(infos[i].data).isAfter(ostatniaData4)) {
            ostatniaData5 = DateTime.parse(infos[i].data);
            globals.jezyk == 'pl_PL'
                ? wartosc5 = infos[i].wartosc.replaceAll('.', ',') + ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})'
                : wartosc5 = infos[i].wartosc +  ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';

          }
        }
        //dla bierzącego roku i parametru leftFood
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.leftFood) {
          //suma5 = suma5 + double.parse(infos[i].wartosc);
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData6) && DateTime.parse(infos[i].data).isAfter(ostatniaData5) && DateTime.parse(infos[i].data).isAfter(ostatniaData4)) {
            ostatniaData6 = DateTime.parse(infos[i].data);
            globals.jezyk == 'pl_PL'
                ? wartosc6 = infos[i].wartosc.replaceAll('.', ',') + ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})'
                : wartosc6 = infos[i].wartosc +  ' ' + infos[i].miara + ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
      }

      //********** LECZENIE ******** dla kategorii treatment
      if (wybranaKategoria == 'treatment') {
        //dla bierzącego roku i parametru apivarol
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == "apivarol") {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData1)) {
            ostatniaData1 = DateTime.parse(infos[i].data);
            wartosc1 = infos[i].wartosc + ' ' + infos[i].miara +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i parametru biovar
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == "biovar") {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData2)) {
            ostatniaData2 = DateTime.parse(infos[i].data);
            wartosc2 = infos[i].wartosc + ' ' + infos[i].miara +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i parametru acid
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == AppLocalizations.of(context)!.acid) {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData3)) {
            ostatniaData3 = DateTime.parse(infos[i].data);
            wartosc3 = infos[i].wartosc + ' ' + infos[i].miara +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          }
        }
        //dla bierzącego roku i parametru varroa
        if (infos[i].data.substring(0, 4) == rokStatystyk &&
            infos[i].parametr == "varroa") {
          if (DateTime.parse(infos[i].data).isAfter(ostatniaData4)) {
            ostatniaData4 = DateTime.parse(infos[i].data);
            wartosc4 = infos[i].wartosc + ' ' + infos[i].miara +
                ' (${zmienDate5_10(infos[i].data.substring(5, 10))})';
          } //ostatnia wartość varroa (nieuzywana bo wyswietlana jest suma)
          varroa = varroa + int.parse(infos[i].wartosc); //sumowanie varroa w ulu
          daneVarroaDoWykresu.add({
            "x": varroaSlupekNr,         // Kolejna wartość osi X
            "value": int.parse(infos[i].wartosc),   // Wartość słupka
            "label": "${zmienDate5_10(infos[i].data.substring(5, 10))}"  // Etykieta dla osi X
          });
          varroaSlupekNr = varroaSlupekNr + 1;
        }
      }
    }

    if (miod > 0 && pylek == 0) globals.wykresZbiory = 'miod';
    if (miod == 0 && pylek > 0) globals.wykresZbiory = 'pylek';
    if (miod != 0 || pylek != 0 ||
        wartosc1 != '' ||
        wartosc2 != '' ||
        wartosc3 != '' ||
        wartosc4 != '' ||
        wartosc5 != '' ||
        wartosc6 != '') dodatek = 10;
    if (miod != 0) wysokoscStatystyk = wysokoscStatystyk + 19;
    if (pylek != 0) wysokoscStatystyk = wysokoscStatystyk + 19;
    if (wartosc1 != '') wysokoscStatystyk = wysokoscStatystyk + 22;
    if (wartosc2 != '') wysokoscStatystyk = wysokoscStatystyk + 22;
    if (wartosc3 != '') wysokoscStatystyk = wysokoscStatystyk + 22;
    if (wartosc4 != '') wysokoscStatystyk = wysokoscStatystyk + 22;
    if (wartosc5 != '') wysokoscStatystyk = wysokoscStatystyk + 22;
    if (wartosc6 != '') wysokoscStatystyk = wysokoscStatystyk + 22;
    // print(wartosc1);
    // print(wartosc2);
    // print(wartosc3);
    // print(wartosc4);
    // print(wartosc5);

    // wybór roku do statystyk
    void _showAlertYear() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectStatYear),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[        
            if(2023 <= int.parse(DateTime.now().toString().substring(0, 4)))   
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2023';
                Navigator.of(context).pushNamed(
                    InfoScreen.routeName,
                    arguments: globals.ulID ,
                  );
              }, child: Text(('2023'),style: TextStyle(fontSize: 18))
              ), 
            if(2024 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2024';
                Navigator.of(context).pushNamed(
                    InfoScreen.routeName,
                    arguments: globals.ulID ,
                );
              }, child: Text(('2024'),style: TextStyle(fontSize: 18))
              ),
            if(2025 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2025';
                Navigator.of(context).pushNamed(
                    InfoScreen.routeName,
                    arguments: globals.ulID ,
                );
              }, child: Text(('2025'),style: TextStyle(fontSize: 18))
              ),
            if(2026 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2026';
                Navigator.of(context).pushNamed(
                    InfoScreen.routeName,
                    arguments: globals.ulID ,
                );
              }, child: Text(('2026'),style: TextStyle(fontSize: 18))
              ),
            if(2027 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2027';
                Navigator.of(context).pushNamed(
                    InfoScreen.routeName,
                    arguments: globals.ulID ,
                );
              }, child: Text(('2027'),style: TextStyle(fontSize: 18))
              ),
            if(2028 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2028';
                Navigator.of(context).pushNamed(
                    InfoScreen.routeName,
                    arguments: globals.ulID ,
                );
              }, child: Text(('2028'),style: TextStyle(fontSize: 18))
              ),
            if(2029 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2029';
                Navigator.of(context).pushNamed(
                    InfoScreen.routeName,
                    arguments: globals.ulID ,
                );
              }, child: Text(('2029'),style: TextStyle(fontSize: 18))
              ),
            if(2030 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2030';
                Navigator.of(context).pushNamed(
                    InfoScreen.routeName,
                    arguments: globals.ulID ,
                );
              }, child: Text(('2030'),style: TextStyle(fontSize: 18))
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
    

    // + dodawanie przeglądu lub info
    void _showAlert(BuildContext context, int pasieka, int ul) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectEntryType),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
//przeglad
          if(wybranaKategoria == 'inspection')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  FrameEditScreen.routeName,
                  arguments: {'idPasieki': pasieka, 'idUla':ul, 'idZasobu': 2},
                );
            }, child: Text((AppLocalizations.of(context)!.resourceOnFrame),style: TextStyle(fontSize: 18))
            ), 
          if(wybranaKategoria == 'inspection')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  FrameEditScreen2.routeName,
                  arguments: {'idPasieki': pasieka, 'idUla':ul, 'idZasobu': 2},
                );
            }, child: Text((AppLocalizations.of(context)!.resourceOnFramePlus),style: TextStyle(fontSize: 18))
            ),  
          if(wybranaKategoria == 'inspection')  
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  FrameEditScreen.routeName,
                  arguments: {'idPasieki': pasieka, 'idUla':ul, 'idZasobu': 13},
                );
            }, child: Text((AppLocalizations.of(context)!.toDO),style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'inspection')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  FrameEditScreen.routeName,
                  arguments: {'idPasieki': pasieka, 'idUla':ul, 'idZasobu': 14},
                );         
            }, child: Text((AppLocalizations.of(context)!.itWasDone),
            style: TextStyle(fontSize: 18)),
            ), 
//wyposazenie                   
          if(wybranaKategoria == 'equipment')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'equipment', 
                              'parametr': AppLocalizations.of(context)!.beePollenTrap + " " + AppLocalizations.of(context)!.isIs, //krata odgrodowa - brak
                              'wartosc': AppLocalizations.of(context)!.off, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(1) ' + AppLocalizations.of(context)!.beePollenTrap), //poławiacz pyłku
            style: TextStyle(fontSize: 18)),
            ), 
          if(wybranaKategoria == 'equipment')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'equipment', 
                              'parametr': AppLocalizations.of(context)!.bottomBoard +  " " + AppLocalizations.of(context)!.isIs, //dennica
                              'wartosc': 'ok', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(2) ' + AppLocalizations.of(context)!.dennica),//dennica
            style: TextStyle(fontSize: 18)),
            ), 
          if(wybranaKategoria == 'equipment')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'equipment', 
                              'parametr': " " + AppLocalizations.of(context)!.excluder + " -", //krata odgrodowa - brak
                              'wartosc': '', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(3) ' + AppLocalizations.of(context)!.exclud + ' - ' + AppLocalizations.of(context)!.lack),
            style: TextStyle(fontSize: 18)),
            ), 
          if(wybranaKategoria == 'equipment')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'equipment', 
                              'parametr': AppLocalizations.of(context)!.excluder, //ustaw krata odgrodowa
                              'wartosc': AppLocalizations.of(context)!.onBodyNumber, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(4) ' + AppLocalizations.of(context)!.set + " " + AppLocalizations.of(context)!.exclud),
            style: TextStyle(fontSize: 18)),
            ), 
          if(wybranaKategoria == 'equipment')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'equipment', 
                              'parametr': AppLocalizations.of(context)!.numberOfFrame + " = ", //ilość ramek
                              'wartosc': '10', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(5) ' + AppLocalizations.of(context)!.numberOfFrame),
            style: TextStyle(fontSize: 18)),
            ), 

//rodzina
          if(wybranaKategoria == 'colony')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'colony', 
                              'parametr': AppLocalizations.of(context)!.colony + " " + AppLocalizations.of(context)!.isIs, //colony State stan
                              'wartosc': 'ok', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(1) ' + AppLocalizations.of(context)!.colonyState),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'colony')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'colony', 
                              'parametr': " " + AppLocalizations.of(context)!.colony + " " + AppLocalizations.of(context)!.isIs, //colony Force siła
                              'wartosc': AppLocalizations.of(context)!.strong, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(2) ' + AppLocalizations.of(context)!.colonyForce),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'colony')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'colony', 
                              'parametr': AppLocalizations.of(context)!.deadBees, //colony osyp pszczół
                              'wartosc': '100', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(3) ' + AppLocalizations.of(context)!.deadBees),
            style: TextStyle(fontSize: 18)),
            ),                  

//matka                   
          if(wybranaKategoria == 'queen')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': AppLocalizations.of(context)!.queenIs, //Start
                              'wartosc': AppLocalizations.of(context)!.freed, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(1) ' + AppLocalizations.of(context)!.queenStart),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'queen')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': AppLocalizations.of(context)!.queen + '  ' + AppLocalizations.of(context)!.isIs, //Quality
                              'wartosc': AppLocalizations.of(context)!.good, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(2) ' + AppLocalizations.of(context)!.queenQuality),
            style: TextStyle(fontSize: 18)),
            ),       
          if(wybranaKategoria == 'queen')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': AppLocalizations.of(context)!.queen + " -", //State
                              'wartosc': AppLocalizations.of(context)!.naturallyMated, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(3) ' + AppLocalizations.of(context)!.queenState),
            style: TextStyle(fontSize: 18)),
            ),
           if(wybranaKategoria == 'queen')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': " " + AppLocalizations.of(context)!.queen, //Mark
                              'wartosc': AppLocalizations.of(context)!.unmarked, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(4) ' + AppLocalizations.of(context)!.queenMark),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'queen')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': AppLocalizations.of(context)!.queenWasBornIn, //Born
                              'wartosc': '2023', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(5) ' + AppLocalizations.of(context)!.queenBorn),
            style: TextStyle(fontSize: 18)),
            ),

//zbiory                   
          if(wybranaKategoria == 'harvest')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'harvest', 
                              'parametr': AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x", //miód = mała ramka x
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(1) ' + AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'harvest')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'harvest', 
                              'parametr': AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x", //miód = duza ramka x
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(1) ' + AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame),// duza ramka
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'harvest')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'harvest', 
                              'parametr': AppLocalizations.of(context)!.beePollen + " = ", //pyłek w ml
                              'wartosc': '100', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(( '(2) ' + AppLocalizations.of(context)!.beePollen + " (ml)"),// pyłek (ml)
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'harvest')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'harvest', 
                              'parametr': " " + AppLocalizations.of(context)!.beePollen + " =  ", //pyłek w l
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(( '(2) ' + AppLocalizations.of(context)!.beePollen + " (l)"),// pyłek (l)
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'harvest')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'harvest', 
                              'parametr': AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x", //pyłek x porcja
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(( '(2) ' + AppLocalizations.of(context)!.beePollen + " (" + AppLocalizations.of(context)!.miarka + ")"),// pyłek x porcja
            style: TextStyle(fontSize: 18)),
            ),
//dokarmianie                  
          if(wybranaKategoria == 'feeding')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'feeding', 
                              'parametr': AppLocalizations.of(context)!.syrup + " 1:1", //syrop 1:1
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(1) ' + AppLocalizations.of(context)!.syrup + " 1:1"),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'feeding')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'feeding', 
                              'parametr': AppLocalizations.of(context)!.syrup + " 3:2", //syrop 3:2
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(2) ' + AppLocalizations.of(context)!.syrup + " 3:2"),
            style: TextStyle(fontSize: 18)),
            ),
           if(wybranaKategoria == 'feeding')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'feeding', 
                              'parametr': AppLocalizations.of(context)!.invert, //invert
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(3) ' + AppLocalizations.of(context)!.invert),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'feeding')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'feeding', 
                              'parametr': AppLocalizations.of(context)!.candy, //ciasto
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(4) ' + AppLocalizations.of(context)!.candy),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'feeding')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'feeding', 
                              'parametr': AppLocalizations.of(context)!.removedFood, //usuń ciasto
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(5) ' + AppLocalizations.of(context)!.removedFood),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'feeding')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'feeding', 
                              'parametr': AppLocalizations.of(context)!.leftFood, //pozostało ciasto
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(6) ' + AppLocalizations.of(context)!.leftFood),
            style: TextStyle(fontSize: 18)),
            ),
//leczenie                
          if(wybranaKategoria == 'treatment')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'treatment', 
                              'parametr': 'apivarol', //chemia
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(1)  apivarol'),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'treatment')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'treatment', 
                              'parametr': 'biovar', //biovar
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(2) biovar'),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'treatment')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'treatment', 
                              'parametr': AppLocalizations.of(context)!.acid, //biovar
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(3) ' + AppLocalizations.of(context)!.acid),
            style: TextStyle(fontSize: 18)),
            ),
          if(wybranaKategoria == 'treatment')
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  InfosEditScreen.routeName,
                  arguments: {'idInfo': '',
                              'kategoria': 'treatment', 
                              'parametr': 'varroa', //biovar
                              'wartosc': '1', //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                );         
            }, child: Text(('(4) varroa'),
            style: TextStyle(fontSize: 18)),
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

    //odwócenie elementów listy zeby daty zwykresów były narastajaco (bo z bazy są malejąco)
    daneZbioruPylkuDoWykresu = daneZbioruPylkuDoWykresu.reversed.toList();
    daneZbioruMioduDoWykresu = daneZbioruMioduDoWykresu.reversed.toList();
    daneVarroaDoWykresu = daneVarroaDoWykresu.reversed.toList();   
    
    //generowanie wykresów
    if(globals.wykresZbiory == 'miod') _generateBarGroupsMiod();
    if(globals.wykresZbiory == 'pylek') _generateBarGroupsPylek();
    _generateBarGroupsVarroa();


     //ThemeData theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        title: 
        wybranaKategoria == 'inspection'
        ? Text(
            AppLocalizations.of(context)!.hIve + " $hiveNr "  + AppLocalizations.of(context)!.frameInspections,
            style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 0, 0, 0)),
          )
        : wybranaKategoria == 'equipment'
          ? Text(
              AppLocalizations.of(context)!.hIve + " $hiveNr "  + AppLocalizations.of(context)!.equipment  + " " + rokStatystyk,
              style: TextStyle(fontSize: 17, color: Color.fromARGB(255, 0, 0, 0)),
            )
            : wybranaKategoria == 'colony'
              ? Text(
                  AppLocalizations.of(context)!.hIve + " $hiveNr "  + AppLocalizations.of(context)!.colony + " " + rokStatystyk,
                  style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 0, 0, 0)),
                )
                : wybranaKategoria == 'queen'
                  ? Text(
                      AppLocalizations.of(context)!.hIve + " $hiveNr "  + AppLocalizations.of(context)!.queen + " " + rokStatystyk,
                      style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 0, 0, 0)),
                    )
                  : wybranaKategoria == 'harvest'
                    ? Text(
                        AppLocalizations.of(context)!.hIve + " $hiveNr "  + AppLocalizations.of(context)!.harvest + " " + rokStatystyk,
                        style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 0, 0, 0)),
                      )
                    : wybranaKategoria == 'feeding'
                      ? Text(
                          AppLocalizations.of(context)!.hIve + " $hiveNr "  + AppLocalizations.of(context)!.feeding + " " + rokStatystyk,
                          style: TextStyle(fontSize: 17, color: Color.fromARGB(255, 0, 0, 0)),
                        )
                      : wybranaKategoria == 'treatment'
                        ? Text(
                            AppLocalizations.of(context)!.hIve + " $hiveNr "  + AppLocalizations.of(context)!.treatment + " " + rokStatystyk,
                            style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 0, 0, 0)),
                          )
                        : null,      
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        // title: Text('Hive $hiveNr'),
        // backgroundColor: Color.fromARGB(255, 233, 140, 0),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () => 
               //print('${globals.pasiekaID}, $hiveNr')
                _showAlert(context, globals.pasiekaID, hiveNr)
               
          ),
          //wybranaKategoria=='harvest' || wybranaKategoria=='feeding'
          IconButton(
            icon: Icon(Icons.query_stats, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () => 
               //print('${globals.pasiekaID}, $hiveNr')
                _showAlertYear(),
               
          ),
          //: Text(''),
          // IconButton(
          //   icon: Icon(Icons.edit),
          //   onPressed: () => Navigator.of(context)
          //       .pushNamed(FramesDetailScreen.routeName, arguments: {
          //     'ul': globals.ulID,
          //     'data': wybranaData,
          //   }),
          // )
        ],
      ),
      body: Column(
        children: <Widget>[



  //menu wyboru kategorii info - ikony w kółkach
          Container(
            margin: EdgeInsets.all(10),
            //height: 60,
            child:
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: <Widget>[

             SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                children: [
                wybranaKategoria == 'inspection'
                  ? CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),//colory[kolor - 1],
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/hi_bees.png'),
                      iconSize: 50,
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'inspection';
                          globals.aktualnaKategoriaInfo = 'inspection';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  )
                  : CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: colory[kolor - 1],
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/hi_bees.png'),
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'inspection';
                          globals.aktualnaKategoriaInfo = 'inspection';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                wybranaKategoria == 'equipment'  
                  ? CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),//colory[kolor - 1],
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/korpus.png'),
                      iconSize: 50,
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'equipment';
                          globals.aktualnaKategoriaInfo = 'equipment';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  )
                  : CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: colory[kolor - 1],
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/korpus.png'),
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'equipment';
                          globals.aktualnaKategoriaInfo = 'equipment';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                wybranaKategoria == 'colony'  
                  ? CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/pszczola1.png'),
                      iconSize: 50,
                      //icon: Icon(Icons.female_rounded),
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'colony';
                          globals.aktualnaKategoriaInfo = 'colony';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  )
                  : CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: colory[kolor - 1],
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/pszczola1.png'),
                      //icon: Icon(Icons.female_rounded),
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'colony';
                          globals.aktualnaKategoriaInfo = 'colony';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                wybranaKategoria == 'queen'  
                  ? CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/matka1.png'),
                      iconSize: 50,
                      //icon: Icon(Icons.female_rounded),
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'queen';
                          globals.aktualnaKategoriaInfo = 'queen';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  )
                  : CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: colory[kolor - 1],
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/matka1.png'),
                      //icon: Icon(Icons.female_rounded),
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'queen';
                          globals.aktualnaKategoriaInfo = 'queen';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                wybranaKategoria == 'harvest'  
                  ? CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/zbiory.png'),
                      iconSize: 50,
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'harvest';
                          globals.aktualnaKategoriaInfo = 'harvest';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  )
                  : CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: colory[kolor - 1],
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/zbiory.png'),
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'harvest';
                          globals.aktualnaKategoriaInfo = 'harvest';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                wybranaKategoria == 'feeding'  
                  ? CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/invert.png'),
                      iconSize: 50,
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'feeding';
                          globals.aktualnaKategoriaInfo = 'feeding';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  )
                  : CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: colory[kolor - 1],
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/invert.png'),
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'feeding';
                          globals.aktualnaKategoriaInfo = 'feeding';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                wybranaKategoria == 'treatment'  
                  ? CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/apivarol1.png'),
                      iconSize: 50,
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'treatment';
                          globals.aktualnaKategoriaInfo = 'treatment';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  )
                  : CircleAvatar(
                    maxRadius: 30,
                    backgroundColor: colory[kolor - 1],
                    child: IconButton(
                      //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      color: Colors.black,
                      icon: Image.asset('assets/image/apivarol1.png'),
                      onPressed: () {
                        setState(() {
                          wybranaKategoria = 'treatment';
                          globals.aktualnaKategoriaInfo = 'treatment';
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 252, 193, 104),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),

                  // ElevatedButton(
                  //   onPressed: () => print("Button pressed!"),
                  //   child: Text(button),
                  // ),
                ],
              ),
            ),
          ),

          //   ]
          // ),

//lista z info o ostatniej inpekcji - bez mozliwosci skasowania
          //   );
          // wybranaKategoria == 'inspection'
          //     ? Card(
          //         margin:
          //             const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          //         child: ListTile(
          //             //zeby nie mozna było skasować ptzejścia do inspekcji
          //             onTap: () {
          //               Navigator.of(context).pushNamed(
          //                 FramesScreen.routeName,
          //                 arguments: globals.ulID,
          //               );
          //             },
          //             leading: CircleAvatar(
          //               backgroundColor: Colors.white,
          //               child: Image.asset(
          //                   'assets/image/hi_bees.png'), //done_outline_rounted //face //female_rounded
          //             ),
          //             title: Text(AppLocalizations.of(context)!.bigInspections,
          //                 style: const TextStyle(
          //                     fontSize: 14, color: Colors.black)),
          //             //subtitle: Text(
          //             // 'last inspection',
          //             //'${infos[0].parametr}  ${infos[0].wartosc} ${infos[0].miara}',
          //             //  style:
          //             //       const TextStyle(fontSize: 18, color: Colors.black)),
          //             trailing: const Icon(Icons.arrow_forward_ios)),
          //       )
          //     : SizedBox(height: 1),

//Statystyki zbiorów dla biezacego roku - wykres
//Wykres zbiorów miodu
          SizedBox(height: 10),
          if (wybranaKategoria == 'harvest' && globals.wykresZbiory == 'miod' && miod > 0)
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 10),
              child: AspectRatio(
                aspectRatio: 2.2,
                child: BarChart(
                  BarChartData(
                    barGroups: barGroupsMiod, // Używamy dynamicznie generowanych słupków
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
                            String text = xAxisLabelsMiod[value.toInt()] ?? '';
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
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            double osY = value.toDouble()/1000;
                            return Padding( 
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text (osY.toString()+' kg', style: TextStyle(fontSize: 12)), //, fontWeight: FontWeight.bold
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
//Wykres zbiorów pyłku
          if (wybranaKategoria == 'harvest' && globals.wykresZbiory == 'pylek' && pylek > 0)
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 10),
              child: AspectRatio(
                aspectRatio: 2.2,
                child: BarChart(
                  BarChartData(
                    barGroups: barGroupsPylek, // Używamy dynamicznie generowanych słupków
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
                    titlesData: FlTitlesData( //opisy osi
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            // Pobieranie tekstu na podstawie wartości 'x'
                            String text = xAxisLabelsPylek[value.toInt()] ?? '';
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
                      leftTitles: AxisTitles(
                        //axisNameWidget: Text('ml'), //nazwa osi lewej
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Padding( 
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text(value.toInt().toString()+' ml', style: TextStyle(fontSize: 12)),
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


          if (wybranaKategoria == 'harvest')
            Container(
              //margin: EdgeInsets.all(10),
              height: wysokoscStatystyk + dodatek + 50,
              child: Column(
                children: [                
                  if (miod != 0)
                    TextButton(onPressed: (){                      
                      setState(() {
                        globals.wykresZbiory = 'miod';
                        _generateBarGroupsMiod();
                      });
                      }, child: 
                      globals.wykresZbiory == 'miod'
                        ? Text("(1) " + AppLocalizations.of(context)!.honeyZbior +
                            ' $rokStatystyk: ${(miod / 1000).toString().replaceAll('.', ',')} kg',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 94, 255)))
                        : Text("(1) " + AppLocalizations.of(context)!.honeyZbior +
                            ' $rokStatystyk: ${(miod / 1000).toString().replaceAll('.', ',')} kg',
                            style: const TextStyle(fontSize: 16)),
                    ), 
                  
                  if (pylek != 0)  
                    TextButton(onPressed: (){
                      setState(() {
                        globals.wykresZbiory = 'pylek';
                        _generateBarGroupsPylek();
                      });
                      }, child:  
                      globals.wykresZbiory == 'pylek'
                        ? Text("(2) " + AppLocalizations.of(context)!.beePollenZbior +
                            ' $rokStatystyk: ${(pylek / 1000).toString().replaceAll('.', ',')} l',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 94, 255)))
                        : Text("(2) " + AppLocalizations.of(context)!.beePollenZbior +
                            ' $rokStatystyk: ${(pylek / 1000).toString().replaceAll('.', ',')} l',
                            style: const TextStyle(fontSize: 16)),
                    ),
                    
                    // Text("(1) " + AppLocalizations.of(context)!.honeyZbior +
                    //         ' $rokStatystyk: ${(miod / 1000).toString().replaceAll('.', ',')} kg',
                    //     style: const TextStyle(fontSize: 16)),
                  // if (pylek != 0)
                  //   Text("(2) " + AppLocalizations.of(context)!.beePollenZbior +
                  //           ' $rokStatystyk: ${(pylek / 1000).toString().replaceAll('.', ',')} l',
                  //       style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),


//Statystyki equipment dla biezacego roku
          if (wybranaKategoria == 'equipment')
            Container(
              //margin: EdgeInsets.all(10),
              height: wysokoscStatystyk + dodatek + 10,
              child: Column(
                children: [
                  if (wartosc3 != '')
                    Text('(1) $wartosc3', style: const TextStyle(fontSize: 16)),
                  if (wartosc2 != '')
                    Text('(2) $wartosc2', style: const TextStyle(fontSize: 16)),
                  if (wartosc1 != '')
                    Text('(3/4) $wartosc1', style: const TextStyle(fontSize: 16)),
                  if (wartosc4 != '')
                    Text('(5) $wartosc4', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
//Statystyki colony dla biezacego roku
          if (wybranaKategoria == 'colony')
            Container(
              //margin: EdgeInsets.all(10),
              height: wysokoscStatystyk + dodatek,
              child: Column(
                children: [
                  if (wartosc2 != '')
                    Text('(1) $wartosc2',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc1 != '')
                    Text('(2) $wartosc1',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc3 != '')
                    Text('(3) ' + AppLocalizations.of(context)!.deadBees + ' $wartosc3',
                        style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
//Statystyki queen dla biezacego roku
          if (wybranaKategoria == 'queen')
            Container(
              //margin: EdgeInsets.all(10),
              height: wysokoscStatystyk + dodatek,
              child: Column(
                children: [
                  if (wartosc4 != '')
                    Text('(1) $wartosc4',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc1 != '')
                    Text('(2) $wartosc1',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc3 != '')
                    Text('(3) $wartosc3',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc2 != '')
                    Text('(4) $wartosc2',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc5 != '')
                    Text('(5) $wartosc5',
                        style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
//Statystyki feeding dla biezacego roku
          if (wybranaKategoria == 'feeding')
            Container(
              //margin: EdgeInsets.all(10),
              height: wysokoscStatystyk + dodatek + 10,
              child: Column(
                children: [
                  if (wartosc1 != '')
                    Text(
                        globals.jezyk == 'pl_PL'
                            ? '(1) ' + AppLocalizations.of(context)!.syrup +
                                ' 1:1 $wartosc1' +
                                ' ($rokStatystyk: ${suma1.toString().replaceAll('.', ',')} l))'
                            : '(1) ' + AppLocalizations.of(context)!.syrup +
                                ' 1:1 $wartosc1' +
                                ' ($rokStatystyk: $suma1 l)',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc2 != '')
                    Text(
                        globals.jezyk == 'pl_PL'
                            ? '(2) ' + AppLocalizations.of(context)!.syrup +
                                ' 3:2 $wartosc2' +
                                ' ($rokStatystyk: ${suma2.toString().replaceAll('.', ',')} l)'
                            : '(2) ' + AppLocalizations.of(context)!.syrup +
                                ' 3:2 $wartosc2' +
                                ' ($rokStatystyk: $suma2 l)',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc3 != '')
                    Text(
                        globals.jezyk == 'pl_PL'
                            ? '(3) ' + AppLocalizations.of(context)!.invert +
                                ' $wartosc3' +
                                ' ($rokStatystyk: ${suma3.toString().replaceAll('.', ',')} l)'
                            : '(3) ' + AppLocalizations.of(context)!.invert +
                                ' $wartosc3' +
                                ' ($rokStatystyk: $suma3 l)',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc4 != '') SizedBox(height: 10),
                  if (wartosc4 != '')
                    Text(
                        globals.jezyk == 'pl_PL'
                            ? '(4) ' + AppLocalizations.of(context)!.candy +
                                ' $wartosc4' +
                                ' ($rokStatystyk: ${suma4.toString().replaceAll('.', ',')} kg)'
                            : '(4) ' + AppLocalizations.of(context)!.candy +
                                ' $wartosc4' +
                                ' ($rokStatystyk: $suma4 kg)',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc5 != '')
                    Text('(5) ' + AppLocalizations.of(context)!.removedFood + ' $wartosc5',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc6 != '')
                    Text('(6) ' + AppLocalizations.of(context)!.leftFood + ' $wartosc6',
                        style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
//Statystyki treatment dla biezacego roku
//Wykres varroa
          if (wybranaKategoria == 'treatment' && varroa > 0)
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 10),
              child: AspectRatio(
                aspectRatio: 2.2,
                child: BarChart(
                  BarChartData(
                    barGroups: barGroupsVarroa, // Używamy dynamicznie generowanych słupków
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
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            // Pobieranie tekstu na podstawie wartości 'x'
                            String text = xAxisLabelsVarroa[value.toInt()] ?? '';
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
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(AppLocalizations.of(context)!.mites), //nazwa osi lewej
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) {
                            return Padding( 
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text(value.toInt().toString(), style: TextStyle(fontSize: 12)),
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

          
          
          if (wybranaKategoria == 'treatment')
            Container(
              // margin: EdgeInsets.all(10),
              height: wysokoscStatystyk + dodatek,
              child: Column(
                children: [
                  if (varroa != '')
                    Text('(4) varroa' + ' $rokStatystyk: ${(varroa).toString().replaceAll('.', ',')} ' + AppLocalizations.of(context)!.mites,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 94, 255))),
                  if (wartosc1 != '')
                    Text('(1) apivarol' + ' $wartosc1',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc2 != '')
                    Text('(2) biovar' + ' $wartosc2',
                        style: const TextStyle(fontSize: 16)),
                  if (wartosc3 != '')
                    Text('(3) ' + AppLocalizations.of(context)!.acid + ' $wartosc3',
                        style: const TextStyle(fontSize: 16)),
                  // if (wartosc4 != '')
                  //   Text('(4) varroa' + ' $wartosc4',
                  //       style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          

//kreska pod statystykami
          const Divider(
            height: 10,
            thickness: 1,
            indent: 0,
            endIndent: 0,
            color: Colors.black,
          ),
          
//lista z informacjami w poszczególnych kategoriach
          infos.length > 0
              ? Expanded(
                  child: ListView.builder(
                    itemCount: infos.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: infos[i],
                      child: InfoItem(),
                    ),
                  ),
                )
              : Center(
                  child: ListTile(
                    // onTap: () {
                    //   Navigator.of(context).pushNamed(
                    //     FramesScreen.routeName,
                    //     arguments: globals.ulID,
                    //   );
                    // },
                    leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: wybranaKategoria == 'inspection'
                            ? Image.asset('assets/image/hi_bees.png')
                            : wybranaKategoria == 'feeding'
                                ? Image.asset('assets/image/invert.png')
                                : wybranaKategoria == 'treatment'
                                    ? Image.asset('assets/image/apivarol1.png')
                                    : wybranaKategoria == 'equipment'
                                        ? Image.asset('assets/image/korpus.png')
                                        : wybranaKategoria == 'queen'
                                            ? Image.asset(
                                                'assets/image/matka1.png')
                                            : wybranaKategoria == 'colony'
                                                ? Image.asset(
                                                    'assets/image/pszczola1.png')
                                                : wybranaKategoria == 'harvest'
                                                    ? Image.asset(
                                                        'assets/image/zbiory.png')
                                                    : const Icon(
                                                        Icons.info_rounded,
                                                        color: Colors.black,
                                                      )),
                    title: Text(
                        AppLocalizations.of(context)!.noInfoInThisCategory,
                        style: const TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 81, 81, 81))),
                    //subtitle: Text(
                    // 'last inspection',
                    //'${infos[0].parametr}  ${infos[0].wartosc} ${infos[0].miara}',
                    //  style:
                    //       const TextStyle(fontSize: 18, color: Colors.black)),
                    //trailing: const Icon(Icons.arrow_forward_ios)),

                    // Column(
                    //       children: <Widget>[
                    //         Container(
                    //           padding: const EdgeInsets.all(50),
                    //           child: Text(
                    //             AppLocalizations.of(context)!.noInfoInThisCategory,
                    //             style: TextStyle(
                    //               fontSize: 20,
                    //               color: Colors.grey,
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                  ),
                ),
        ],
      ),
    );
  }
}
