
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;
import 'package:intl/intl.dart';

import '../helpers/db_helper.dart';
import '../models/apiarys.dart';
import '../models/frame.dart';
import '../models/hives.dart';
import '../models/info.dart';
import '../models/infos.dart';
//import '../screens/activation_screen.dart';
import '../models/frames.dart';
import '../models/hive.dart';
// import 'package:flutter/services.dart';
//import 'frames_detail_screen.dart';

class FrameEditScreen extends StatefulWidget {
  static const routeName = '/frame_edit';
  
  
    @override
    State<FrameEditScreen> createState() => _FrameEditScreenState();
  }

class _FrameEditScreenState extends State<FrameEditScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');
  bool _isInit = true;
  var formatterHm = new DateFormat('H:mm');
  int? nowyNrPasieki;
  int? nowyNrUla;
  int? nowyNrKorpusu;
  int? nowyNrRamki;//przed  przeglądem
  int? nowyNrRamkiPo; //po przeglądzie
  int korpus = 2;//1-półkorpus, 2-korpus
  List<bool> _selectedKorpus = <bool>[false, true]; // pół|cały
  int rozmiarRamki = 2;//1-mała, 2-duza
  List<bool> _selectedRozmiarRamki = <bool>[false, true]; // mała|duza
  int stronaRamki = 1; //0-obie, 1-lewa, 2-prawa
  List<bool> _selectedStronaRamki = <bool>[true, false, false]; // lewa|obie|prawa
  int numeryWieluRamek = 1;// 0- xx/0 po=0, 1- xx/xx przed=po, 2- 0/xx przed=0
  List<bool> _selectedNumeryWieluRamek = <bool>[false, true, false]; // po=0 | przed=po | przed=0
  int? nowyZasob;
  //int? tempZasob;
  String nowaWartosc = '0';
  //String tempNowaWartosc = '0';
  // String noweToDo = '0';
  // String noweIsDone = '0';
  List<Frame> ramka = [];
  List<Hive> hive = [];
  String tryb = '';
  String tytulEkranu = '';
  TextEditingController dateController = TextEditingController();
  int zakresRamek = 0; //"0" - jedna,ramki przed i po przeglądzie; "1" - wiele, zakres ramek od do
  List<bool> _selectedZakresRamek = <bool>[true, false]; // jedna|wiele
  int zakresZasobow = 1; //"0" - zmiana jednego zasobu, "1" - zmiana wszystkich zasobów (przeniesienie ramki)
  List<bool> _selectedZakresZasobow = <bool>[false, true]; //jeden|wszystkie
  int nrRamkiOd = 1;
  int nrRamkiDo = 5;
  List<bool> _selectedZasoby = <bool>[false, true]; // wartość|zasób
  List<bool> _selectedToDo = <bool>[true, false, false, false]; // ramka pracy | trzeba wirować | trzeba usunać | mozna izolować
  List<bool> _selectedIsDone = <bool>[true, false, false, false, false]; //usuń ramka | wsraw ramka | izolacja | przesuń w lewo | przesuń w prawo
  int dzielnik = 2; //do ustawiania proporcji klawiszy klawiatur numeru ramki i ilości zasobów
  //List<Info> info = [];
  //dla hive
  String ikona = 'green'; //pobierana z aktualnego ula
  int ramek = 10; //pobierane z aktualnego ula
  int korpusNr = 0;
  int trut = 0;
  int czerw = 0;
  int larwy = 0;
  int jaja = 0;
  int pierzga = 0;
  int miod = 0;
  int dojrzaly = 0;
  int weza = 0;
  int susz = 0;
  int matka = 0;
  int mateczniki = 0;
  int usunmat = 0;
  String todo = '0';
  String matka1 = '';
  String matka2 = '';
  String matka3 = '';
  String matka4 = '';
  String matka5 = '';
  String rodzajUla = '';
  String typUla = '';
  List<int> gridItems = [];//tworzona lista klawiszy klawiatury wyboru numeru ramki
  List<int> gridItemsKorpus = [1,2,3,4,5,6,7,8,9]; //lista klawiszy klawiatury wyboru numeru korpusu
  List<int> gridItemsZasob = [0,5,10,15,20,25,30,35,40,50,60,70,80,90,100]; //lista klawiszy klawiatury ilosci zasobu do dodania
  List<String> gridItemsKolor = ['czarny','żółty','czerwony','zielony','niebieski','biały','brak\ndanych','inny'];
  var matkaKolor = Icon(Icons.brightness_1, color: Color.fromARGB(255, 255, 255, 255), size: 30.0,);//niewidoczny - brak informacji o matce
 

  //zasoby dodawane podczas zapisu
  int trutDod = 0;
  int czerwDod = 0;
  int larwyDod = 0;
  int jajaDod = 0;
  int pierzgaDod = 0;
  int miodDod = 0;
  int dojrzalyDod = 0;
  int wezaDod = 0;
  int suszDod = 0;
  int matkaDod = 0;
  int matecznikiDod = 0;
  int usunmatDod = 0;
  int sumaZasobow = 0;
  
  
  @override
  void didChangeDependencies() {
    if (_isInit) {
      //print('na poczatek didChangeDependencies: nowyZasobId  = ${dateController.text}');
      final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
      final idRamki = routeArgs['idRamki']; //pobiera z frames_detail_item.dart
      final idPasieki = routeArgs['idPasieki'];
      final idUla = routeArgs['idUla'];
      final idZasobu = routeArgs['idZasobu'];
      //print('ramka = $idRamki, pasieka = $idPasieki , ul = $idUla');

      if (idRamki != null) {
        //jezeli edycja istniejącego wpisu
        final frameData = Provider.of<Frames>(context, listen: false);
        ramka = frameData.items.where((element) {
          //to wczytanie danych ramki
          return element.id == ('$idRamki');
        }).toList();
        dateController.text = ramka[0].data;
        // nowyRok = ramka[0].data.substring(0, 4);
        // nowyMiesiac = ramka[0].data.substring(5, 7);
        // nowyDzien = ramka[0].data.substring(8);
        nowyNrPasieki = ramka[0].pasiekaNr;
        nowyNrUla = ramka[0].ulNr;
        nowyNrKorpusu = ramka[0].korpusNr;
        nowyNrRamki = ramka[0].ramkaNr;
        nowyNrRamkiPo = ramka[0].ramkaNrPo;
        korpus = ramka[0].typ;
        korpus == 1 ? _selectedKorpus[0] = true : _selectedKorpus[0] = false;
        korpus == 2 ? _selectedKorpus[1] = true : _selectedKorpus[1] = false;
        rozmiarRamki = ramka[0].rozmiar;
        rozmiarRamki == 1 ? _selectedRozmiarRamki[0] = true : _selectedRozmiarRamki[0] = false;
        rozmiarRamki == 2 ? _selectedRozmiarRamki[1] = true : _selectedRozmiarRamki[1] = false;
        nowyZasob = ramka[0].zasob; //id edytowanego zasobu 
        nowaWartosc = ramka[0].wartosc.replaceAll(RegExp('%'), '');
        switch (nowyZasob) {
          case 1: trutDod = int.parse(nowaWartosc);break;
          case 2: czerwDod = int.parse(nowaWartosc);break;
          case 3: larwyDod = int.parse(nowaWartosc);break;
          case 4: jajaDod = int.parse(nowaWartosc);break;
          case 5: pierzgaDod = int.parse(nowaWartosc);break;
          case 6: miodDod = int.parse(nowaWartosc);break;
          case 7: dojrzalyDod = int.parse(nowaWartosc);break;
          case 8: wezaDod = int.parse(nowaWartosc);break;
          case 9: suszDod = int.parse(nowaWartosc);break;
          case 10: matkaDod = int.parse(nowaWartosc);
                    switch(matkaDod){
                      case 1: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);break;
                      case 2: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 215, 208, 0),size: 30.0);break;
                      case 3: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 0, 0),size: 30.0);break;
                      case 4: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 15, 200, 8),size: 30.0);break;
                      case 5: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 102, 255),size: 30.0);break;
                      case 6: matkaKolor = Icon(Icons.brightness_1_outlined,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);break;
                      //case 6: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 255, 255),size: 30.0);break;
                      case 7: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 158, 166, 172),size: 30.0);break;
                      default:
                    }
            break;
          case 11: matecznikiDod = int.parse(nowaWartosc);break;
          case 12: usunmatDod = int.parse(nowaWartosc);break;
          case 13: switch (nowaWartosc) {
                    case 'ramka pracy': _selectedToDo = [true, false, false, false];break; // ramka pracy | trzeba wirować | trzeba usunać | mozna izolować
                    case 'trzeba wirować': _selectedToDo = [false, true, false, false];break;
                    case 'trzeba usunąć': _selectedToDo = [false, false, true, false];break;
                    case 'można izolować': _selectedToDo = [false, false, false, true];break;
                    case 'work frame': _selectedToDo = [true, false, false, false];break; // ramka pracy | trzeba wirować | trzeba usunać | mozna izolować
                    case 'to extraction': _selectedToDo = [false, true, false, false];break;
                    case 'to delete': _selectedToDo = [false, false, true, false];break;
                    case 'to insulate': _selectedToDo = [false, false, false, true];break;
                  default: _selectedToDo = [true, false, false, false];
                  }break;
          case 14: switch (nowaWartosc) {
                    case 'usuń ramka': _selectedIsDone = <bool>[true, false, false, false, false];break; //usuń ramka | wstaw ramka | izolacja | przesuń w lewo | przesuń w prawo
                    case 'wstaw ramka': _selectedIsDone = <bool>[false, true, false, false, false];break;
                    case 'izolacja': _selectedIsDone = <bool>[false, false, true, false, false];break;
                    case 'przesuń w lewo': _selectedIsDone = <bool>[false, false, false, true, false];break;
                    case 'przesuń w prawo': _selectedIsDone = <bool>[false, false, false, false, true];break;
                    case 'deleted': _selectedIsDone = <bool>[true, false, false, false, false];break; //usuń ramka | wstaw ramka | izolacja | przesuń w lewo | przesuń w prawo
                    case 'inserted': _selectedIsDone = <bool>[false, true, false, false, false];break;
                    case 'insulated': _selectedIsDone = <bool>[false, false, true, false, false];break;
                    case 'moved left': _selectedIsDone = <bool>[false, false, false, true, false];break;
                    case 'moved right': _selectedIsDone = <bool>[false, false, false, false, true];break;
                  default: _selectedIsDone = <bool>[true, false, false, false, false];
                  }break;
          default:
        }
        stronaRamki = ramka[0].strona; //1-lewa, 2-prawa
        stronaRamki == 1 ? _selectedStronaRamki[0] = true : _selectedStronaRamki[0] = false;
        stronaRamki == 2 ? _selectedStronaRamki[2] = true : _selectedStronaRamki[2] = false;                                  
        tryb = 'edycja';
        tytulEkranu = AppLocalizations.of(context)!.editingFrame; //edycja zasobu
      } else {
        //jezeli dodanie nowego wpisu (tylko dla aktualnie wybranej pasieki i ula)
        dateController.text = globals.dataWpisu; //DateTime.now().toString().substring(0, 10);
        // nowyRok = DateFormat('yyyy').format(DateTime.now());
        // nowyMiesiac = DateFormat('MM').format(DateTime.now());
        // nowyDzien = DateFormat('dd').format(DateTime.now());
        nowyNrPasieki = int.parse('$idPasieki');
        nowyNrUla = int.parse('$idUla');
        nowyNrKorpusu = globals.nowyNrKorpusu; //zapamiętany ostatni wybór
        nowyNrRamki = globals.nowyNrRamki;
        nowyNrRamkiPo = globals.nowyNrRamkiPo;
        korpus = globals.korpus;
        korpus == 1 ? _selectedKorpus[0] = true : _selectedKorpus[0] = false;
        korpus == 2 ? _selectedKorpus[1] = true : _selectedKorpus[1] = false;
        rozmiarRamki = globals.rozmiarRamki;
        rozmiarRamki == 1 ? _selectedRozmiarRamki[0] = true : _selectedRozmiarRamki[0] = false;
        rozmiarRamki == 2 ? _selectedRozmiarRamki[1] = true : _selectedRozmiarRamki[1] = false;
        stronaRamki = globals.stronaRamki;
        stronaRamki == 0 ? _selectedStronaRamki[1] = true : _selectedStronaRamki[1] = false;
        stronaRamki == 1 ? _selectedStronaRamki[0] = true : _selectedStronaRamki[0] = false;
        stronaRamki == 2 ? _selectedStronaRamki[2] = true : _selectedStronaRamki[2] = false;
        nrRamkiOd = globals.nrRamkiOd;
        nrRamkiDo = globals.nrRamkiDo;
        zakresRamek = globals.zakresRamek;
        zakresRamek == 0 ? _selectedZakresRamek[0] = true : _selectedZakresRamek[0] = false;
        zakresRamek == 1 ? _selectedZakresRamek[1] = true : _selectedZakresRamek[1] = false;
        nowyZasob = int.parse('$idZasobu'); //id zasobu z pola dialogowego "Wybierz rodzaj wpisu" (po przycisnięciu "+" u góry ekranu) - decyduje o rodzaju wpisu (zasób na ramce, toDo czy isDone)
        //tempZasob = nowyZasob;
        nowaWartosc = '1'; //wartość dla toDo i isDone ustawiana dalej...
        //tempNowaWartosc = nowaWartosc;
        tryb = 'dodaj';
        tytulEkranu = AppLocalizations.of(context)!.addFrame;
        if (nowyZasob == 13) nowaWartosc = AppLocalizations.of(context)!.workFrame;
        if (nowyZasob == 14) nowaWartosc = AppLocalizations.of(context)!.deleted; 
      }
      //pobranie danych 0 ulu
      Provider.of<Hives>(context, listen: false).fetchAndSetHives(nowyNrPasieki)
            .then((_) {
        final hiveData = Provider.of<Hives>(context, listen: false);
        hive = hiveData.items.where((element) {
          //to wczytanie danych edytowanego ula
          return element.id == ('$nowyNrPasieki.$nowyNrUla');
        }).toList();
        
        ramek = hive[0].ramek; //liczba ramek w ulu
        
        //utworzenie klwiatury wyboru numeru ramki
        gridItems=[];
        for(int i = 0; i <= ramek; i++){
          gridItems.add(i);
        // print('i = ${gridItems}');
        } 
      });
      
      //ustawienie numerów wielu ramek
      if(globals.numeryWieluRamek == 1) _selectedNumeryWieluRamek=<bool>[false, true, false];
      else if(globals.numeryWieluRamek == 0) _selectedNumeryWieluRamek=<bool>[true, false, false];
      else if(globals.numeryWieluRamek == 2) _selectedNumeryWieluRamek=<bool>[false, false, true];

      globals.jezyk == 'pl_PL'
        ? gridItemsKolor = ['czarny','żółty','czerwony','zielony','niebieski','biały','brak\ndanych','inny']
        : gridItemsKolor = ['black','yellow','red','green','blue','white','no\ndata','other'];
      
      double heightScreen = MediaQuery.of(context).size.height;
      // print('wysokość ekranu');
      // print(heightScreen);
      if (heightScreen < 590) {
        dzielnik = 3; //zeby proporcje klawiszy klawiatur numerów ramek i zasobów był 1:1 (kwadraty dla małych ekranów)
      }
    
    } //od if (_isInit) {
    _isInit = false;
   // print('na koniec didChangeDependencies: nowyZasobId  = ${dateController.text}'); 
    super.didChangeDependencies();
  }

  
  //wybór numeru ramki lub toDo lub isDone
  void _showAlertNr(String wybor, int przycisk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(wybor,textAlign: TextAlign.center,),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[           
            SizedBox(
              //height: 200.0,
              height: 340,
              width: 300,
              child:GridView.count(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(15.0),
                crossAxisCount: 3, //ilość kolumn
                childAspectRatio: (3 / dzielnik), //proporcje boków kafli
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: gridItems
                  .map((data) => InkWell(
                    onTap: () {
                      switch (przycisk) {
                        case 1:
                          setState(() {
                            nowyNrRamki = data;
                            globals.nowyNrRamki = data;
                            globals.zakresRamek = 0;
                          });
                          break;
                        case 2:
                          setState(() {
                            nowyNrRamkiPo = data;
                            globals.nowyNrRamkiPo = data;
                            globals.zakresRamek = 0; //zapamiętanie ze jedna ramka
                          });
                          break;  
                        case 3:
                          setState(() {
                            nrRamkiOd = data;
                            globals.nrRamkiOd = data;
                            globals.zakresRamek = 1;
                          });
                          break; 
                        case 4:
                          setState(() {
                            nrRamkiDo = data;
                            globals.nrRamkiDo = data;
                            globals.zakresRamek = 1; //zapamiętanie ze wiele ramek
                          });
                          break;
                        //case 11: setState(() {matecznikiDod = data;}); break; 
                        //case 12: setState(() {usunmatDod = data;}); break;  
                        default:
                      }
                      
                      if(tryb == 'dodaj')
                        switch (przycisk) {
                          case 11: setState(() {matecznikiDod = data;}); break; 
                          case 12: setState(() {usunmatDod = data;}); break; 
                          default:
                        }

                      if(tryb == 'edycja' && (przycisk == 11 || przycisk == 12)){
                        trutDod = 0;
                        czerwDod = 0;
                        larwyDod = 0;
                        jajaDod = 0;
                        pierzgaDod = 0;
                        miodDod = 0;
                        dojrzalyDod = 0;
                        wezaDod = 0;
                        suszDod = 0;
                        matkaDod = 0;
                        matecznikiDod = 0;
                        usunmatDod = 0;
                        switch (przycisk) {
                          case 11: setState(() {matecznikiDod = data; nowyZasob = 11; nowaWartosc = data.toString();}); break; 
                          case 12: setState(() {usunmatDod = data; nowyZasob = 12; nowaWartosc = data.toString();}); break; 
                          default:
                        }
                      }

                      Navigator.of(context).pop();
                   
                    },
                    splashColor: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(                        
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withValues(alpha:0.7),
                            Theme.of(context).primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        //color: Theme.of(context).primaryColor,
                      ),
                      //margin:EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                      //color: Theme.of(context).primaryColor,
                      child: Center(
                        child: Text('$data',
                          style: TextStyle(
                            //fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color.fromARGB(255, 0, 0, 0)),
                          textAlign: TextAlign.center)))
                    )
                  )
                .toList(),
              ), 
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

  //wybór numeru korpusu
  void _showAlertNrKorpusu(String wybor) {
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
              child:GridView.count(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(15.0),
                crossAxisCount: 3, //ilość kolumn
                childAspectRatio: (3 / dzielnik), //proporcje boków kafli
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: gridItemsKorpus
                  .map((data) => InkWell(
                    onTap: () {
                      setState(() {
                        nowyNrKorpusu = data;
                        globals.nowyNrKorpusu = data;
                      });
                      Navigator.of(context).pop();
                      //getGridViewSelectedItem(context, data);
                    },
                    splashColor: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(                        
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withValues(alpha:0.7),
                            Theme.of(context).primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        //color: Theme.of(context).primaryColor,
                      ),
                      //margin:EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                      //color: Theme.of(context).primaryColor,
                      child: Center(
                        child: Text('$data',
                          style: TextStyle(
                            //fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color.fromARGB(255, 0, 0, 0)),
                          textAlign: TextAlign.center)))
                    )
                  )
                .toList(),
              ), 
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

  //wyswietlenie komunikatu o przekroczeniu sumy wartości zasobów
  void _showAlertAnuluj(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
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
  
  //wybór ilości zasobu do zapisu
  void _showAlertDodajZasob(String wybor, int przycisk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(wybor,textAlign: TextAlign.center,),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[           
            SizedBox(
              //height: 200.0,
              height: 360,
              width: 300,
              child:GridView.count(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(15.0),
                crossAxisCount: 3, //ilość kolumn
                childAspectRatio: (3 / dzielnik), //proporcje boków kafli
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: gridItemsZasob
                  .map((data) => InkWell(
                    onTap: () {
                      
                      if(tryb == 'edycja'){//zerowanie zasobów bo będzie nowy zasób
                        trutDod = 0;
                        czerwDod = 0;
                        larwyDod = 0;
                        jajaDod = 0;
                        pierzgaDod = 0;
                        miodDod = 0;
                        dojrzalyDod = 0;
                        wezaDod = 0;
                        suszDod = 0;
                        matkaDod = 0;
                        matecznikiDod = 0;
                        usunmatDod = 0;
                        matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 255, 255),size: 30.0);
                        
                        switch (przycisk) { //ustawienie nowego zasobu
                          case 1: setState(() {trutDod = data; nowyZasob = 1; nowaWartosc = data.toString();}); Navigator.of(context).pop();break;
                          case 2: setState(() {czerwDod = data; nowyZasob = 2; nowaWartosc = data.toString();}); Navigator.of(context).pop();break;
                          case 3: setState(() {larwyDod = data; nowyZasob = 3; nowaWartosc = data.toString();}); Navigator.of(context).pop();break;
                          case 4: setState(() {jajaDod = data; nowyZasob = 4; nowaWartosc = data.toString();}); Navigator.of(context).pop();break;
                          case 5: setState(() {pierzgaDod = data; nowyZasob = 5; nowaWartosc = data.toString();}); Navigator.of(context).pop();break;
                          case 6: setState(() {miodDod = data; nowyZasob = 6; nowaWartosc = data.toString();}); Navigator.of(context).pop();break;
                          case 7: setState(() {dojrzalyDod = data; nowyZasob = 7; nowaWartosc = data.toString();}); Navigator.of(context).pop();break;
                          case 8: setState(() {wezaDod = data; nowyZasob = 8; nowaWartosc = data.toString();}); Navigator.of(context).pop();break;
                          case 9: setState(() {suszDod = data; nowyZasob = 9; nowaWartosc = data.toString();}); Navigator.of(context).pop();break;                         
                          default:
                        } 
                      }
                    
                      if(tryb == 'dodaj')
                        switch (przycisk) {
                          case 1: 
                            //dodanie wybranej wartości do sumy zasobów (bez modyfikacji aktualnej wartości wybranego zasobu!)
                            sumaZasobow = data + czerwDod + larwyDod + jajaDod + pierzgaDod + miodDod + dojrzalyDod + wezaDod + suszDod;
                            if(sumaZasobow>100){ //jezeli suma przekroczyła 100%
                              int zaDuzo = sumaZasobow - 100; 
                              sumaZasobow -= data; //od sumy odjąć proponowaną wartość
                              sumaZasobow  += trutDod; //do sumy dodać poprzednią, niezmodyfikowaną wartość by taka jak przed wybraniem tej wartości
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel, AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobow + trutDod}%');break; //wyświetlenie komunikatu
                            }else{setState(() {trutDod = data;}); Navigator.of(context).pop();break;}

                          case 2: 
                            sumaZasobow = trutDod + data + larwyDod + jajaDod + pierzgaDod + miodDod + dojrzalyDod + wezaDod + suszDod;
                            if(sumaZasobow>100){
                              int zaDuzo = sumaZasobow - 100;
                              sumaZasobow -= data;
                              sumaZasobow  += czerwDod;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobow + czerwDod}%');break;
                            }else{setState(() {czerwDod = data;}); Navigator.of(context).pop();break;}

  
                          case 3: 
                            sumaZasobow = trutDod + czerwDod + data + jajaDod + pierzgaDod + miodDod + dojrzalyDod + wezaDod + suszDod;
                            if(sumaZasobow>100){
                              int zaDuzo = sumaZasobow - 100;
                              sumaZasobow -= data;
                              sumaZasobow  += larwyDod;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobow + larwyDod}%');break;
                            }else{setState(() {larwyDod = data;}); Navigator.of(context).pop();break;}

                          case 4: 
                            sumaZasobow = trutDod + czerwDod + larwyDod + data + pierzgaDod + miodDod + dojrzalyDod + wezaDod + suszDod;
                            if(sumaZasobow>100){
                              int zaDuzo = sumaZasobow - 100;
                              sumaZasobow -= data;
                              sumaZasobow  += jajaDod;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobow + jajaDod}%');break;
                            }else{setState(() {jajaDod = data;}); Navigator.of(context).pop();break;}

                          case 5: 
                            sumaZasobow = trutDod + czerwDod + larwyDod + jajaDod + data + miodDod + dojrzalyDod + wezaDod + suszDod;
                            if(sumaZasobow>100){
                              int zaDuzo = sumaZasobow - 100;
                              sumaZasobow -= data;
                              sumaZasobow  += pierzgaDod;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobow + pierzgaDod}%');break;
                            }else{setState(() {pierzgaDod = data;}); Navigator.of(context).pop();break;}

                          case 6: 
                            sumaZasobow = trutDod + czerwDod + larwyDod + jajaDod + pierzgaDod + data + dojrzalyDod + wezaDod + suszDod;
                            if(sumaZasobow>100){
                              int zaDuzo = sumaZasobow - 100;
                              sumaZasobow -= data;
                              sumaZasobow  += miodDod;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobow + miodDod}%');break;
                            }else{setState(() {miodDod = data;}); Navigator.of(context).pop();break;}

                          case 7: 
                            sumaZasobow = trutDod + czerwDod + larwyDod + jajaDod + pierzgaDod + miodDod + data + wezaDod + suszDod;
                            if(sumaZasobow>100){
                              int zaDuzo = sumaZasobow - 100;
                              sumaZasobow -= data;
                              sumaZasobow  += dojrzalyDod;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobow + dojrzalyDod}%');break;
                            }else{setState(() {dojrzalyDod = data;}); Navigator.of(context).pop();break;}
  
                          case 8: 
                            sumaZasobow = trutDod + czerwDod + larwyDod + jajaDod + pierzgaDod + miodDod + dojrzalyDod + data + suszDod;
                            if(sumaZasobow>100){
                              int zaDuzo = sumaZasobow - 100;
                              sumaZasobow -= data;
                              sumaZasobow  += wezaDod;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobow + wezaDod}%');break;
                            }else{setState(() {wezaDod = data;}); Navigator.of(context).pop();break;}
  
                          case 9: 
                            sumaZasobow = trutDod + czerwDod + larwyDod + jajaDod + pierzgaDod + miodDod + dojrzalyDod + wezaDod + data;
                            if(sumaZasobow>100){
                              int zaDuzo = sumaZasobow - 100;
                              sumaZasobow -= data;
                              sumaZasobow  += suszDod;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobow + suszDod}%');break;
                            }else{setState(() {suszDod = data;}); Navigator.of(context).pop();break;}
                              
                          default:
                        }
                      //sumaZasobow = trutDod + czerwDod + larwyDod + jajaDod + pierzgaDod + miodDod + dojrzalyDod + wezaDod + suszDod;
                      //Navigator.of(context).pop();
                      //getGridViewSelectedItem(context, data);
                    },
                    splashColor: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(                        
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withValues(alpha:0.7),
                            Theme.of(context).primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        //color: Theme.of(context).primaryColor,
                      ),
                      //margin:EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                      //color: Theme.of(context).primaryColor,
                      child: Center(
                        child: Text('$data',
                          style: TextStyle(
                            //fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color.fromARGB(255, 0, 0, 0)),
                          textAlign: TextAlign.center)))
                    )
                  )
                .toList(),
              ), 
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
  
  //wybór koloru oznaczenia matki
  void _showAlertKolor(String wybor, int przycisk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(wybor,textAlign: TextAlign.center,),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[           
            SizedBox(
              //height: 200.0,
              height: 360,
              width: 300,
              child:GridView.count(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(15.0),
                crossAxisCount: 2, //ilość kolumn
                childAspectRatio: (3 / 1.8), //proporcje boków kafli
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: gridItemsKolor
                  .map((data) => InkWell(
                    onTap: () {
                      
                      if(tryb == 'edycja'){ //zerowanie zasobów bo będzie zmiana - nowa matka
                        trutDod = 0;
                        czerwDod = 0;
                        larwyDod = 0;
                        jajaDod = 0;
                        pierzgaDod = 0;
                        miodDod = 0;
                        dojrzalyDod = 0;
                        wezaDod = 0;
                        suszDod = 0;
                        matkaDod = 0;
                        matecznikiDod = 0;
                        usunmatDod = 0;
                      
                        if(globals.jezyk == 'pl_PL'){  
                          switch (data) {
                            case 'czarny': 
                              setState(() {
                                //matkaDod = 1;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '1';
                              }); break;
                            case 'żółty': 
                              setState(() {
                                //matkaDod = 2;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 215, 208, 0),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '2';
                              }); break;  
                            case 'czerwony': 
                              setState(() {
                                //matkaDod = 3;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 0, 0),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '3';
                              }); break; 
                            case 'zielony': 
                              setState(() {
                                //matkaDod = 4;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 15, 200, 8),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '4';
                              }); break;                        
                            case 'niebieski': 
                              setState(() {
                                //matkaDod = 5;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 102, 255),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '5';
                              }); break; 
                            case 'biały': 
                              setState(() {
                                //matkaDod = 6;
                                matkaKolor = Icon(Icons.brightness_1_outlined,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '6';
                              }); break; 
                            case 'inny': 
                              setState(() {
                                //matkaDod = 7;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 158, 166, 172),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '7';
                              }); break;                     
                            default:
                              setState(() {
                                //matkaDod = 0; //zeby jej nie zapisywac w bazie gdyby ktoś wybrał ten przycisk kasujący ewentualnmy poprzedni wybór
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 255, 255),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '0';
                              }); 
                          }
                        }else{
                          switch (data) {
                            case 'black': 
                              setState(() {
                                //matkaDod = 1;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '1';
                              }); break;
                            case 'yellow': 
                              setState(() {
                                //matkaDod = 2;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 215, 208, 0),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '2';
                              }); break;  
                            case 'red': 
                              setState(() {
                                //matkaDod = 3;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 0, 0),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '3';
                              }); break; 
                            case 'green': 
                              setState(() {
                                //matkaDod = 4;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 15, 200, 8),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '4';
                              }); break;                        
                            case 'blue': 
                              setState(() {
                                //matkaDod = 5;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 102, 255),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '5';
                              }); break; 
                            case 'white': 
                              setState(() {
                                //matkaDod = 6;
                                matkaKolor = Icon(Icons.brightness_1_outlined,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '6';
                              }); break;                     
                            case 'other': 
                              setState(() {
                                //matkaDod = 7;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 158, 166, 172),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '7';
                              }); break;  
                            default:
                              setState(() {
                                //matkaDod = 0; //zeby jej nie zapisywac w bazie gdyby ktoś wybrał ten przycisk kasujący ewentualnmy poprzedni wybór
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 255, 255),size: 30.0);
                                nowyZasob = 10; nowaWartosc = '0';
                              }); 
                          }

                        }
                      
                      }
                    
                      if(tryb == 'dodaj')
                        if(globals.jezyk == 'pl_PL'){  
                          switch (data) {
                            case 'czarny': 
                              setState(() {
                                matkaDod = 1;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;
                            case 'żółty': 
                              setState(() {
                                matkaDod = 2;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 215, 208, 0),size: 30.0);
                              }); break;  
                            case 'czerwony': 
                              setState(() {
                                matkaDod = 3;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 0, 0),size: 30.0);
                              }); break; 
                            case 'zielony': 
                              setState(() {
                                matkaDod = 4;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 15, 200, 8),size: 30.0);
                              }); break;                        
                            case 'niebieski': 
                              setState(() {
                                matkaDod = 5;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 102, 255),size: 30.0);
                              }); break; 
                            case 'biały': 
                              setState(() {
                                matkaDod = 6;
                                matkaKolor = Icon(Icons.brightness_1_outlined,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;                     
                            case 'inny': 
                              setState(() {
                                matkaDod = 7;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 158, 166, 172),size: 30.0);
                              }); break;  
                            default:
                              setState(() {
                                matkaDod = 0; //zeby jej nie zapisywac w bazie gdyby ktoś wybrał ten przycisk kasujący ewentualnmy poprzedni wybór
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 255, 255),size: 30.0);
                              }); 
                          }
                        }else{
                          switch (data) {
                            case 'black': 
                              setState(() {
                                matkaDod = 1;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;
                            case 'yellow': 
                              setState(() {
                                matkaDod = 2;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 215, 208, 0),size: 30.0);
                              }); break;  
                            case 'red': 
                              setState(() {
                                matkaDod = 3;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 0, 0),size: 30.0);
                              }); break; 
                            case 'green': 
                              setState(() {
                                matkaDod = 4;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 15, 200, 8),size: 30.0);
                              }); break;                        
                            case 'blue': 
                              setState(() {
                                matkaDod = 5;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 102, 255),size: 30.0);
                              }); break; 
                            case 'white': 
                              setState(() {
                                matkaDod = 6;
                                matkaKolor = Icon(Icons.brightness_1_outlined,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;                     
                            case 'other': 
                              setState(() {
                                matkaDod = 7;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 158, 166, 172),size: 30.0);
                              }); break;  
                            default:
                              setState(() {
                                matkaDod = 0; //zeby jej nie zapisywac w bazie gdyby ktoś wybrał ten przycisk kasujący ewentualnmy poprzedni wybór
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 255, 255),size: 30.0);
                              }); 
                          }
                        }
                      
                      Navigator.of(context).pop();
                     
                    },
                    splashColor: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(                        
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withValues(alpha:0.7),
                            Theme.of(context).primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        //color: Theme.of(context).primaryColor,
                      ),
                      //margin:EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                      //color: Theme.of(context).primaryColor,
                      child: Center(
                        child: Text('$data',
                          style: TextStyle(
                            //fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color.fromARGB(255, 0, 0, 0)),
                          textAlign: TextAlign.center)))
                    
                    )
                  )
                .toList(),
              ), 
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
  
  
  //zapis zasobu do tabeli "ramki"
  zapisDoBazy(int zas, String wart, String zrobic) {
    String formattedDate = dateController.text; //nowyRok + '-' + nowyMiesiac + '-' + nowyDzien;

    if (zas < 10) wart = wart + '%'; //????????

    //ustawienie zmiennej "korpus"
    if(_selectedKorpus[0] == true){ //[0]==true to półkorpus; [0]==false to korpus
      korpus = 1; globals.korpus = 1;   
    }else { 
      korpus = 2; globals.korpus = 2;
    }
   
    //ustawienie zmiennej "rozmiarRamki"
    if(_selectedRozmiarRamki[0] == true){ //[0]==true to mała; [0]==false to duza
      rozmiarRamki = 1; globals.rozmiarRamki = 1;   
    }else { 
      rozmiarRamki = 2; globals.rozmiarRamki = 2;
    }

    //ustawienie zmiennej "stronaRamki" w zalezności od ustawienia przełacznika lewa|obie|prawa
    if(_selectedStronaRamki[0] == true){ //[0]==true to lewa; [0]==false to obie, chyba ze
      stronaRamki = 1; globals.stronaRamki = 1;   
    }else { 
      stronaRamki = 0; globals.stronaRamki = 0;
    }
    if(_selectedStronaRamki[2] == true){//[2]==true to prawa
      stronaRamki = 2; globals.stronaRamki = 2;
    }
    
    //======= Zapis zasobu do tabeli  "ramka" ========
    //jezeli zakres ramek
    if(_selectedZakresRamek[1]){ //jezeli "true" to wiele ramek
      int nrWieluRamekPo = 0;
      int nrWieluRamekPrzed = 0 ;
      
      //dla kazdej z wielu ramek
      for (var i = nrRamkiOd; i <= nrRamkiDo; i++) {
        
        //jezeli ramki są wstawiane lub usuwane
        if ((_selectedNumeryWieluRamek[1]==true)){ // przed = po
            nrWieluRamekPrzed = i;
            nrWieluRamekPo = i ;
            globals.numeryWieluRamek = 1;
        }else if(_selectedNumeryWieluRamek[0]==true) {
          nrWieluRamekPrzed = i; // przed = bez zmian
          nrWieluRamekPo = 0; //po = 0
          globals.numeryWieluRamek = 0;
        }else if(_selectedNumeryWieluRamek[2]==true){
          nrWieluRamekPrzed = 0; //przed = 0
          nrWieluRamekPo = i ; //po = bez zmian
          globals.numeryWieluRamek = 2;
        }

        if (stronaRamki == 1) { //dla lewej strony
            // print(
            //     'zapis do bazy id = $formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.1.$zas');
            // print('numer ramki = $i');
            // print('nowa wartość = $wart');
            // print(
            //     'dane do zapisu = $formattedDate, $nowyNrPasieki,$nowyNrUla,$nowyNrKorpusu,$korpus,$nowyNrRamki,$nowyNrRamkiPo,$rozmiarRamki,1,$zas,$wart,0');
          Frames.insertFrame(
            '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nrWieluRamekPrzed.$nrWieluRamekPo.1.$zas',
            formattedDate,
            nowyNrPasieki!,
            nowyNrUla!,
            nowyNrKorpusu!,
            korpus,
            nrWieluRamekPrzed,
            nrWieluRamekPo,
            rozmiarRamki,
            1, //lewa
            zas,
            wart,
            0); //arch
        }else if (stronaRamki == 2) { //dla prawej strony
          Frames.insertFrame(
            '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nrWieluRamekPrzed.$nrWieluRamekPo.2.$zas',
            formattedDate,
            nowyNrPasieki!,
            nowyNrUla!,
            nowyNrKorpusu!,
            korpus,
            nrWieluRamekPrzed,
            nrWieluRamekPo,
            rozmiarRamki,
            2, //prawa
            zas,
            wart,
            0); //arch
        }else { //dla obu stron ramki
          Frames.insertFrame(
            '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nrWieluRamekPrzed.$nrWieluRamekPo.1.$zas',
            formattedDate,
            nowyNrPasieki!,
            nowyNrUla!,
            nowyNrKorpusu!,
            korpus,
            nrWieluRamekPrzed,
            nrWieluRamekPo,
            rozmiarRamki,
            1, //lewa
            zas,
            wart,
            0);
          Frames.insertFrame(
            '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nrWieluRamekPrzed.$nrWieluRamekPo.2.$zas',
            formattedDate,
            nowyNrPasieki!,
            nowyNrUla!,
            nowyNrKorpusu!,
            korpus,
            nrWieluRamekPrzed,
            nrWieluRamekPo,
            rozmiarRamki,
            2, //lewa
            zas,
            wart,
            0);
        }
      }
      //jezeli jedna ramka
    }else{
      if (stronaRamki == 1) { //dla lewej strony
          // print(
          //     'zapis do bazy id = $formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.1.$zas');
          // print('nowa wartość = $wart');
          // print(
          //     'dane do zapisu = $formattedDate, $nowyNrPasieki,$nowyNrUla,$nowyNrKorpusu,$korpus,$nowyNrRamki,$nowyNrRamkiPo,$rozmiarRamki,1,$zas,$wart,0');
        Frames.insertFrame(
          '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.1.$zas',
          formattedDate,
          nowyNrPasieki!,
          nowyNrUla!,
          nowyNrKorpusu!,
          korpus,
          nowyNrRamki!,
          nowyNrRamkiPo!,
          rozmiarRamki,
          1, //lewa
          zas,
          wart,
          0); //arch
      } else if (stronaRamki == 2) { //dla prawej strony
        Frames.insertFrame(
          '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.2.$zas',
          formattedDate,
          nowyNrPasieki!,
          nowyNrUla!,
          nowyNrKorpusu!,
          korpus,
          nowyNrRamki!,
          nowyNrRamkiPo!,
          rozmiarRamki,
          2, //prawa
          zas,
          wart,
          0); //arch
      } else { //dla obu stron ramki
        Frames.insertFrame(
          '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.1.$zas',
          formattedDate,
          nowyNrPasieki!,
          nowyNrUla!,
          nowyNrKorpusu!,
          korpus,
          nowyNrRamki!,
          nowyNrRamkiPo!,
          rozmiarRamki,
          1, //lewa
          zas,
          wart,
          0);
        Frames.insertFrame(
          '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.2.$zas',
          formattedDate,
          nowyNrPasieki!,
          nowyNrUla!,
          nowyNrKorpusu!,
          korpus,
          nowyNrRamki!,
          nowyNrRamkiPo!,
          rozmiarRamki,
          2, //lewa
          zas,
          wart,
          0);
      }

    }
    
    //========= Modyfikacja belki =========
    //zeby nie stracić danych zebranych podczas przeglądu w widoku zbiorczym uli (belka)
    final hiveData = Provider.of<Hives>(context, listen: false);
    hive = hiveData.items.where((element) {
      //to wczytanie danych edytowanego ula
      return element.id == ('$nowyNrPasieki.$nowyNrUla');
    }).toList();
    ikona = hive[0].ikona; 
    ramek = hive[0].ramek;
    korpusNr = hive[0].korpusNr; 
    trut = hive[0].trut;
    czerw = hive[0].czerw;
    larwy = hive[0].larwy;
    jaja = hive[0].jaja;
    pierzga = hive[0].pierzga;
    miod = hive[0].miod;
    dojrzaly = hive[0].dojrzaly;
    weza = hive[0].weza;
    susz = hive[0].susz;
    matka = hive[0].matka;
    mateczniki = hive[0].mateczniki;
    usunmat = hive[0].usunmat;
    todo = hive[0].todo;
    matka1 = hive[0].matka1;
    matka2 = hive[0].matka2;
    matka3 = hive[0].matka3;
    matka4 = hive[0].matka4;
    matka5 = hive[0].matka5;
    rodzajUla = hive[0].h1;
    typUla = hive[0].h2;
    //print('nowyNrPasieki = $nowyNrPasieki, nowyNrUla = $nowyNrUla, id wpisu w "ule" = ${hive[0].id}, data wybranego przeglądu = $formattedDate, data ostatniego przeglądu =  ${hive[0].przeglad}');
    //print('nowyZasob = $nowyZasob, korpusNr = $korpusNr, nowyNrKorpusu = $nowyNrKorpusu');
    
    //===== Jezeli data dodawanego lub modyfikowanego przegladu jest nowsza lub taka sama jak data ostatniego przegladu
    //===== to modyfikacja belki bo jest zmiana zasobu
    if((DateTime.parse(formattedDate)).compareTo(DateTime.parse(hive[0].przeglad)) >= 0){
      
      if (formattedDate == hive[0].przeglad) {//data wprowadzanych zmian i data belki takie same to edycja/modyfikacja
        // print('edycja istniejącego przeglądu bo takie same daty');
        //więc nic nie rób chyba ze
        //było skasowanie przeglądu z aktualnie ustawioną datą lub zmieniono numer korpusu więc dodawanie nowego przeglądu
        if (korpusNr == 0 || korpusNr != nowyNrKorpusu){ 
          // print('miała być edycja istniejącego przeglądu ale jednak jest nowy przegląd bo inny numer korpusa !!!!!!!');
          korpusNr = nowyNrKorpusu!;
          ikona = 'green'; //"zerowanie" zasobów bo nowy przegląd
          trut = 0;
          czerw = 0;
          larwy = 0;
          jaja = 0;
          pierzga = 0;
          miod = 0;
          dojrzaly = 0;
          weza = 0;
          susz = 0;
          matka = 0;
          mateczniki = 0;
          usunmat = 0;
          todo = '';
        }      
      }else if((DateTime.parse(formattedDate)).compareTo(DateTime.parse(hive[0].przeglad)) > 0) { //dodanie aktualnego nowego przeglądu bo data nowsza niz ta z przeglądu ($nowyNrPasieki.$nowyNrUla' == hive[0].id && )
        // print('dodanie nowego przeglądu - zerowanie belki');
        korpusNr = nowyNrKorpusu!;
        trut = 0;
        czerw = 0;
        larwy = 0;
        jaja = 0;
        pierzga = 0;
        miod = 0;
        dojrzaly = 0;
        weza = 0;
        susz = 0;
        matka = 0;
        mateczniki = 0;
        usunmat = 0;
        todo = '';
        ikona = 'green'; //"zerowanie" ikony bo nowy przegląd
      }
      
      
      // print('-------------------------ikona przed  = $ikona');
      //print('$todo != '' && ($ikona != red || $ikona != orange)'); 
      // ikona ula zółta jezeli zasobem była czynność do zrobienia
      //o ile nie była czerwona lub pomarańczowa, bo problemy z matką są wazniejsze
      if ((todo != '' && todo != '0') && (ikona != 'red' || ikona != 'orange')) {
        ikona = 'yellow';
      }else if ((todo == '' || todo == '0') && (ikona =='yellow'))ikona ='green';   
    // print('ikona po  = $ikona');
      
      
      
      //aktualizacja zasobów ula na belce po jego modyfikacji na ramce lub ramkach
      Provider.of<Frames>(context, listen: false)
        .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
        .then((_) { //pobranie wszystkich ramek/zasobów z wybranego ula
        //pobranie wszyskich wpisów z tabeli "ramki" dla danego ula
        final framesUla = Provider.of<Frames>(context, listen: false);
        //dotyczących aktualnie zmodyfikowanego zasobu w ulu (i dla wybranej daty oraz tylko dla ramek Po i wybranego korpusu)
        List<Frame> framesZas = framesUla.items.where((fr) {
            return fr.zasob == zas && fr.data == dateController.text && fr.ramkaNrPo != 0 && fr.korpusNr == nowyNrKorpusu; 
          }).toList();
          //dla kazdego zapisu dotyczącego tego zasobu na ramkaNrPo - sumowanie wszystkich wartości zasobów
          
          // print('******** framesZas.length ${framesZas.length}');
          // print('zas $zas,korpusNr $korpusNr, nowyNrKorpusu $nowyNrKorpusu,globals.dataWpisu ${globals.dataWpisu}, ');
          
          // print('fr.zasob == {framesZas[0].zasob }&& fr.data == {framesZas[0].data} && data wpisu = ${globals.dataWpisu}');
          
          //print('przed for ======= ramka ${framesZas[0].ramkaNrPo}, zas ${framesZas[0].zasob} == ${framesZas[0].wartosc}');
          
          for (var i = 0; i < framesZas.length; i++) {
            // print('$i ======= ramka ${framesZas[i].ramkaNrPo}, zas ${framesZas[i].zasob} == ${framesZas[i].wartosc}');
            switch (zas) {//id zasobu
              case 1:           
                if(i == 0) trut = 0; //zerowanie zasobu bo będzie aktualizowany
                trut = trut + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); //dodanie z uprzednim usunięciem znaku %
                break;
              case 2:
                if(i == 0) czerw = 0; //zerowanie zasobu bo będzie aktualizowany
                czerw = czerw + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), ''));
                // print('wartość czerwiu $czerw');
                break;
              case 3:
                if(i == 0) larwy = 0; //zerowanie zasobu bo będzie aktualizowany
                larwy = larwy + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 4:
                if(i == 0) jaja = 0; //zerowanie zasobu bo będzie aktualizowany
                jaja = jaja + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 5:
                if(i == 0) pierzga = 0; //zerowanie zasobu bo będzie aktualizowany
                pierzga = pierzga + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 6:
                if(i == 0) miod = 0; //zerowanie zasobu bo będzie aktualizowany
                miod = miod + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 7:
                if(i == 0) dojrzaly = 0; //zerowanie zasobu bo będzie aktualizowany
                dojrzaly = dojrzaly + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 8:
                if(i == 0) weza = 0; //zerowanie zasobu bo będzie aktualizowany
                weza = weza + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 9:
                if(i == 0) susz = 0; //zerowanie zasobu bo będzie aktualizowany
                susz = susz + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 10:
                  matka = int.parse(wart); 
                break;
              case 11:
                if(i == 0) mateczniki = 0; //zerowanie zasobu bo będzie aktualizowany
                mateczniki = mateczniki + int.parse(wart); 
                break;
              case 12:
                if(i == 0) usunmat = 0; //zerowanie zasobu bo będzie aktualizowany
                usunmat = usunmat + int.parse(wart); 
                break;
              case 13:
                todo = wart;
                break;
            }
          } //for
          // print('po for==================== korpusNr = $korpusNr');
      
      
        // });
        // print('po aktualizacji zasobów czerw ==================== $czerw');
        // print('wartość czerwiu przed zapisem do hive = $czerw');
        //print('korpus`nr = $korpusNr');
        // print('trut = $trut, czerw = $czerw');
        // print('insertHive');
        Hives.insertHive(
          '$nowyNrPasieki.$nowyNrUla',
          nowyNrPasieki!, //pasieka nr
          nowyNrUla!, //ul nr
          formattedDate, //przeglad
          ikona, //ikona
          ramek, //ramek - ilość ramek w korpusie
          korpusNr,
          trut,
          czerw,
          larwy,
          jaja,
          pierzga,
          miod,
          dojrzaly,
          weza,
          susz,
          matka,
          mateczniki,
          usunmat,
          todo,
          '0', //zerowanie parametrów info bo zapis zasobów do belki
          '0',
          '0',
          '0',
          matka1,
          matka2,
          matka3,
          matka4,
          matka5,
          rodzajUla, //h1 - rodzaj ula: ul, odlład, mini
          typUla, //h2 - WIELKOPOLSKI itp
          '0', //h3
          0, //aktualne zasoby
        ).then((_) {
          //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
          Provider.of<Hives>(context, listen: false).fetchAndSetHives(nowyNrPasieki)
          .then((_) {
            final hivesData = Provider.of<Hives>(context, listen: false);
            final hives = hivesData.items;
            int ileUli = hives.length;
            //print('edit_screen - ilość uli =');
            // print(hives.length);
            // print(ileUli);

            //DBHelper.updateIleUli(nrXXOfApiary, ileUli); //
            // print('insertApiary');
            //zapis do tabeli "pasieki"
            Apiarys.insertApiary(
              '$nowyNrPasieki',
              nowyNrPasieki!, //pasieka nr
              ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
              formattedDate, //przeglad
              globals.ikonaPasieki, //ikona
              '??', //opis
            ).then((_) {
              Provider.of<Apiarys>(context, listen: false)
                  .fetchAndSetApiarys()
                  .then((_) {
                // print(
                //     'edit_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy');
              });
            });
          });
        });   
      }); //od pobrania ramek z zasobami do aktualizacji 
    }
    
    //zapis info o przegladzie do bazy (podczas przeglądu tylko raz na poczatku przegladu zeby była godzina rozpoczecia przegladu i ewentualnie notatka jesli kiedykolwiek sie pojawi zeby jej nie stracić)
    //więc jeśli nie zapisywano jeszcze info przegladu lub zpisano info o innym przeglądzie niz obecny określony przez datę
    if(globals.dataAktualnegoPrzegladu == '' || globals.dataAktualnegoPrzegladu != '$formattedDate' || globals.ulID != nowyNrUla || globals.pasiekaID != nowyNrPasieki){
      // to pobranie wszystkich info dla ula
      final infoData = Provider.of<Infos>(context, listen: false);
      //pobranie info o tym przeglądzie jezeli jest (czyli zgadza się data, nr ula, kategoria i parametr)
      List<Info> info = infoData.items.where((element) { 
        return element.data == formattedDate && element.ulNr == nowyNrUla && element.kategoria == 'inspection' && element.parametr == '${AppLocalizations.of(context)!.inspection}'; //data, nr ula, kategoria i parametr
      }).toList();
      //i jezeli wpis o przeglądzie juz jest to
      if(info.isNotEmpty){ 
        //to zapisz w globals datę tego przeglądu
        globals.dataAktualnegoPrzegladu = '$formattedDate';
        //print('info = ${info[0].id}, kategoria = ${info[0].kategoria}, czas = ${info[0].czas}');
      }else{ //a jezeli jeszcze nie ma takego wpisu
        //print('jeszcze nie ma wpisu');
        //to zapis przegladu do info 'inspection"
        Infos.insertInfo(
          '$formattedDate.$nowyNrPasieki.$nowyNrUla.inspection.${AppLocalizations.of(context)!.inspection}', //id
          formattedDate, //data
          nowyNrPasieki!, //pasiekaNr
          nowyNrUla!, //ulNr
          'inspection', //karegoria
          AppLocalizations.of(context)!.inspection, //parametr
          ikona, //wartosc
          '', //miara
          '',//icon, //ikona pogody
          '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}', //'${temp.toStringAsFixed(0)}$stopnie', //temperatura zaokrąglona do 1 stopnia
          formatterHm.format(DateTime.now()), //formatedTime, //czas
          '', //uwagi
          0 //arch
        ).then((_) {
          Provider.of<Infos>(context, listen: false)
              .fetchAndSetInfosForHive(nowyNrPasieki,nowyNrUla)
              .then((_) {
            // print(
            //     'edit_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy');
          });
        });
      }
    }//else{print('juz jest wpis = ${globals.dataAktualnegoPrzegladu}');}
  }

  

  @override
  Widget build(BuildContext context) {
    
    final ButtonStyle buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(2.0),
      backgroundColor: Theme.of(context).primaryColor, //Color.fromARGB(255, 233, 140, 0),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(66.0, 35.0),
      //textStyle: const TextStyle(color: Color.fromARGB(255, 162, 103, 0),)
    );
    final ButtonStyle dataButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(2.0),
      backgroundColor: Theme.of(context).primaryColor, //Color.fromARGB(255, 233, 140, 0),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(126.0, 35.0),
      textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    );
    final ButtonStyle buttonPasiekaUlStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(2.0),
      backgroundColor: Color.fromARGB(255, 211, 211, 211),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(83.0, 35.0),
      textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    );
    final ButtonStyle buttonSumaZasobow = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(2.0),
      backgroundColor: Color.fromARGB(255, 211, 211, 211),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(85.0, 35.0),
      textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    );
//print(dateController.text );
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(
            tytulEkranu,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
        ),
        body: SingleChildScrollView(         
            child: Padding(
                padding: const EdgeInsets.all(10.0),  //było 15
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Form(
                        key: _formKey1,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[

//data - pasieka - ul - korpus
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
 //data przeglądu  
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.inspectionDate),
                                      OutlinedButton(
                                        style: dataButtonStyle,
                                        onPressed: () async {
                                          DateTime? pickedDate =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.parse(dateController.text),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2101),
                                              builder:(context , child){
                                                return Theme( data: Theme.of(context).copyWith(  // override MaterialApp ThemeData
                                                  colorScheme: ColorScheme.light(
                                                    primary: Color.fromARGB(255, 236, 167, 63),//header and selced day background color
                                                    onPrimary: Colors.white, // titles and 
                                                    onSurface: Colors.black, // Month days , years 
                                                  ),
                                                  textButtonTheme: TextButtonThemeData(
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors.black, // ok , cancel    buttons
                                                    ),
                                                  ),
                                                ),  child: child!   );  // pass child to this child
                                              }
                                            );
                                          if (pickedDate != null) {
                                            String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                                            setState(() {
                                              dateController.text = formattedDate;
                                              globals.dataWpisu = formattedDate;
                                            });
                                          } else {print("Date is not selected");}
                                        },
  
                                         child: Text(dateController.text ,
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontSize: 15),),   
                                      ),
                                  ]),                                                             
 //pasieka/ul                              
                                  SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.aPiary + ' / ' + AppLocalizations.of(context)!.hIve),
                                      OutlinedButton(
                                          style: buttonPasiekaUlStyle,
                                          onPressed: null,
                                          child: Text('$nowyNrPasieki/$nowyNrUla',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                        )]) ,                                 
  //korpus                                
                                  SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.bOdy),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: () {_showAlertNrKorpusu(AppLocalizations.of(context)!.bOdyNumber);},
                                          child: Text('$nowyNrKorpusu',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                        )]) 
                               ],
                              ),

// ramki
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                //mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[ 
//jeden zasób - wszystkie zasoby na ramce                  
                                if(tryb == 'edycja') 
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.rEsourceOnFrame),
                                      ToggleButtons(
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            for (int i = 0; i < _selectedZakresZasobow.length; i++) {
                                              _selectedZakresZasobow[i] = i == index;
                                            }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                        fillColor: Theme.of(context).primaryColor, //tło wybranego
                                        color: Color.fromARGB(255, 78, 78, 78), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 33.0,
                                          minWidth: 70.0,
                                        ),
                                        isSelected: _selectedZakresZasobow,
                                        children: [ //napisy na przełącznikach
                                          Text(AppLocalizations.of(context)!.thisOne),
                                          Text(AppLocalizations.of(context)!.all),
                                        ],  //lewa, obie, prawa
                                      ),
                                  // Column(
                                  //   mainAxisAlignment: MainAxisAlignment.end,
                                  //   crossAxisAlignment: CrossAxisAlignment.end,
                                  //   children: [
                                  //     SizedBox(height: 20),
                                  //     SizedBox(width: 110,child:Text(AppLocalizations.of(context)!.fRameNumber + ': ', style: const TextStyle(
                                  //             fontSize: 15,),textAlign:TextAlign.end,),),
                                    ],
                                  ),
//zakres ramek                                 
                                if(tryb == 'dodaj')                                               
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.frameRange),
                                      ToggleButtons(
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            for (int i = 0; i < _selectedZakresRamek.length; i++) {
                                              _selectedZakresRamek[i] = i == index;
                                            }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                        fillColor: Theme.of(context).primaryColor, //tło wybranego
                                        color: Color.fromARGB(255, 78, 78, 78), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 33.0,
                                          minWidth: 70.0,
                                        ),
                                        isSelected: _selectedZakresRamek,
                                        children: [ //napisy na przełącznikach
                                          Text(AppLocalizations.of(context)!.one),
                                          Text(AppLocalizations.of(context)!.many),
                                        ],  //lewa, obie, prawa
                                      ),
                                  ]),
                                                                  
                               SizedBox(width: 10),
//ramka przed                  
                              if(tryb == 'edycja')  
                                Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.before),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: () {_showAlertNr(AppLocalizations.of(context)!.frameNumberBefore,1);},
                                          child: Text('$nowyNrRamki',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                        )]),

                              if(tryb == 'dodaj')
                                _selectedZakresRamek[1] == false  
                                  ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.before),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: () {_showAlertNr(AppLocalizations.of(context)!.frameNumberBefore,1);},
                                          child: Text('$nowyNrRamki',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                        )]) 
                                    
                                  : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.from),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: () {_showAlertNr(AppLocalizations.of(context)!.frameNumberFrom,3);},
                                          child: Text('$nrRamkiOd',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                        )]), 
                                
                                SizedBox(width: 10),
//ramka po                                 
                              if(tryb == 'edycja') 
                                Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.after),
                                      OutlinedButton(
                                            style: buttonStyle,
                                            onPressed: () {_showAlertNr(AppLocalizations.of(context)!.frameNumberAfter,2);},
                                            child: Text('$nowyNrRamkiPo',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Color.fromARGB(255, 0, 0,0))),
                                          )]),

                              if(tryb == 'dodaj')  
                                _selectedZakresRamek[1] == false  
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.after),
                                      OutlinedButton(
                                            style: buttonStyle,
                                            onPressed: () {_showAlertNr(AppLocalizations.of(context)!.frameNumberAfter,2);},
                                            child: Text('$nowyNrRamkiPo',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Color.fromARGB(255, 0, 0,0))),
                                          )])
                                  : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.to),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: () {_showAlertNr(AppLocalizations.of(context)!.frameNumberTo,4);},
                                          child: Text('$nrRamkiDo',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                        )]),
  
                                  
                                  //   Checkbox(
                                  //     checkColor: Colors.white,
                                  //     activeColor: Color.fromARGB(255, 0, 0, 0),
                                  //     //fillColor: MaterialStateProperty.Color(0xFF42A5F5),
                                  //     value: isChecked,
                                  //     onChanged: (bool? value) {
                                  //       setState(() {
                                  //         isChecked = value!;
                                  //         zakresRamek = value;
                                  //       });
                                  //     },
                                  //   ),                              
                                  //   // SizedBox(
                                  //   //   width: 0,
                                  //   // ),
                                  // if(tryb == 'dodaj')  
                                  //   Text(AppLocalizations.of(context)!.frameRange),
                                  
                                
                                ],
                              ),
//przed - bez zmian - po
                            SizedBox(height: 5),
                            if(tryb == 'dodaj' && _selectedZakresRamek[1] == true )   
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//wiele przed
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.fRameNumbersBeforeAndAfter),
                                      ToggleButtons(
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            for (int i = 0; i < _selectedNumeryWieluRamek.length; i++) {
                                              _selectedNumeryWieluRamek[i] = i == index;
                                            }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                        fillColor: Theme.of(context).primaryColor, //tło wybranego
                                        color: Color.fromARGB(255, 78, 78, 78), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 33.0,
                                          minWidth: 97.0,
                                        ),
                                        isSelected: _selectedNumeryWieluRamek,
                                        children: [ //napisy na przełącznikach
                                          Text ('xx/0'), //Text(AppLocalizations.of(context)!.left),
                                          Text ('xx/xx'), //Text(AppLocalizations.of(context)!.both),
                                          Text ('0/xx'), //Text(AppLocalizations.of(context)!.right)
                                        ],  //lewa, obie, prawa
                                      ),                                  
                                  ]),
  //chwilowa suma zasobów                                 
                                //   SizedBox(width: 10),
                                // if(tryb == 'dodaj')  
                                //   Column(
                                //     mainAxisAlignment: MainAxisAlignment.center,
                                //     crossAxisAlignment: CrossAxisAlignment.center,
                                //     children: [
                                //       Text(AppLocalizations.of(context)!.rEsources),
                                //       OutlinedButton(
                                //           style: buttonSumaZasobow,
                                //           onPressed: null,
                                //           child: Text('$sumaZasobow'+'%',
                                //             style: const TextStyle(
                                //               fontWeight: FontWeight.bold,
                                //               fontSize: 18,
                                //               color: Color.fromARGB(255, 0, 0,0))),
                                //   )]) ,  
                              ]),  






//korpus-półkorpus
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//korpus-półkorpus
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.bOdyType),
                                      ToggleButtons(
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            for (int i = 0; i < _selectedKorpus.length; i++) {
                                              _selectedKorpus[i] = i == index;
                                            }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                        fillColor: Theme.of(context).primaryColor, //tło wybranego
                                        color: Color.fromARGB(255, 78, 78, 78), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 33.0,
                                          minWidth: 70.0,
                                        ),
                                        isSelected: _selectedKorpus,
                                        children: [ //napisy na przełącznikach
                                          Text(AppLocalizations.of(context)!.half),
                                          Text(AppLocalizations.of(context)!.full),
                                        ],  //lewa, obie, prawa
                                      ),
                                  ]),

//rozmiar ramki
                                  SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.fRameSize),
                                      ToggleButtons(
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            for (int i = 0; i < _selectedRozmiarRamki.length; i++) {
                                              _selectedRozmiarRamki[i] = i == index;
                                            }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                        fillColor: Theme.of(context).primaryColor, //tło wybranego
                                        color: Color.fromARGB(255, 78, 78, 78), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 33.0,
                                          minWidth: 70.0,
                                        ),
                                        isSelected: _selectedRozmiarRamki,
                                        children: [ //napisy na przełącznikach
                                          Text(AppLocalizations.of(context)!.small),
                                          Text(AppLocalizations.of(context)!.big),
                                        ],  //lewa, obie, prawa
                                      ),
                                  ]),
                              ]),  



//strona ramki
                              SizedBox(height: 5),
                            if (nowyZasob! < 13)   
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//strona ramki
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.sIteOfFrame),
                                      ToggleButtons(
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                              _selectedStronaRamki[i] = i == index;
                                            }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                        fillColor: Theme.of(context).primaryColor, //tło wybranego
                                        color: Color.fromARGB(255, 78, 78, 78), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 33.0,
                                          minWidth: 65.0,
                                        ),
                                        isSelected: _selectedStronaRamki,
                                        children: [ //napisy na przełącznikach
                                          Text(AppLocalizations.of(context)!.left),
                                          Text(AppLocalizations.of(context)!.both),
                                          Text(AppLocalizations.of(context)!.right)
                                        ],  //lewa, obie, prawa
                                      ),                                  
                                  ]),
  //chwilowa suma zasobów                                 
                                  SizedBox(width: 10),
                                if(tryb == 'dodaj')  
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.rEsources),
                                      OutlinedButton(
                                          style: buttonSumaZasobow,
                                          onPressed: null,
                                          child: Text('$sumaZasobow'+'%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                  )]) ,  
                              ]),  

                              SizedBox(height: 10),
 
//sekcja zasobów 1-12 
                      if (nowyZasob! < 13)  
                        Column(       //??????
                          children:[   //??????
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//węza / susz                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfWax, 8);
                                          setState(() {   
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                        fillColor: Color.fromARGB(255, 255, 255, 0), //tło wybranego
                                        color: Color.fromARGB(255, 0, 0, 0), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 70.0,
                                         
                                        ),
                                        isSelected: _selectedZasoby,
                                        children: [ //napisy na przełącznikach
                                          wezaDod != 0 ? Text('$wezaDod' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.waxFundationN + ' ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfComb, 9);
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                        fillColor: Color.fromARGB(255, 255, 255, 0), //tło wybranego
                                        color: Color.fromARGB(255, 0, 0, 0), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 70.0,
                                        
                                        ),
                                        isSelected: _selectedZasoby,
                                        children: [ //napisy na przełącznikach
                                          suszDod != 0 ? Text('$suszDod' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.waxCombN + ' ' ),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 

//miód
                              //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//dojrzały/ nakrop                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {_showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfSealed, 7);
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 255, 255, 255), //napis wybranego
                                        fillColor: Color.fromARGB(255, 131, 92, 0), //tło wybranego
                                        color: Color.fromARGB(255, 78, 78, 78), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 70.0,
                                         
                                        ),
                                        isSelected: _selectedZasoby,
                                        children: [ //napisy na przełącznikach
                                          dojrzalyDod != 0 ? Text('$dojrzalyDod' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.honeySealedN + ' ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfHoney, 6);
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 255, 255, 255), //napis wybranego
                                        fillColor: Color.fromARGB(255, 222, 156, 1), //tło wybranego
                                        color: Color.fromARGB(255, 0, 0, 0), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 70.0,
                                        
                                        ),
                                        isSelected: _selectedZasoby,
                                        children: [ //napisy na przełącznikach
                                          miodDod != 0 ? Text('$miodDod' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(AppLocalizations.of(context)!.hOney , textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 

//matka
                              //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//matka / matka / pierzga                               
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertKolor(AppLocalizations.of(context)!.cOolorOfMother, 10);
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 255, 255, 255), //napis wybranego
                                        fillColor: Color.fromARGB(255, 0, 0, 0), //tło wybranego
                                        color: Color.fromARGB(255, 0, 0, 0), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 70.0,
                                         
                                        ),
                                        isSelected: _selectedZasoby, //bez znaczenia
                                        children: [ //napisy na przełącznikach
                                          //Text('$matkaDod'),
                                          matkaKolor,
                                          Text(' ' + AppLocalizations.of(context)!.queen + ' ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfPollen, 5);
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 255, 255, 255), //napis wybranego
                                        fillColor: Color.fromARGB(255, 0, 197, 0), //tło wybranego
                                        color: Color.fromARGB(255, 0, 0, 0), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 70.0,
                                        
                                        ),
                                        isSelected: _selectedZasoby, //bez znaczenia
                                        children: [ //napisy na przełącznikach
                                          pierzgaDod != 0 ? Text('$pierzgaDod' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.pollen + ' ' ),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 
//czerw odkryty
                              //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//jajka / larwy                               
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfEggs, 4);
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                        fillColor: Color.fromARGB(255, 255, 255, 255), //tło wybranego
                                        color: Color.fromARGB(255, 0, 0, 0), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 70.0,
                                         
                                        ),
                                        isSelected: _selectedZasoby,
                                        children: [ //napisy na przełącznikach
                                          jajaDod != 0 ? Text('$jajaDod' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.eggs + ' ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfLarvae, 3);
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                        fillColor: Color.fromARGB(255, 253, 195, 192), //tło wybranego
                                        color: Color.fromARGB(255, 0, 0, 0), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 70.0,
                                        
                                        ),
                                        isSelected: _selectedZasoby,
                                        children: [ //napisy na przełącznikach
                                          larwyDod != 0 ? Text('$larwyDod' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.larvae + ' ' ),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 

//czerw
                              //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//kryty / trutowy                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfBrood, 2);
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 255, 255, 255), //napis wybranego
                                        fillColor: Color.fromARGB(255, 255, 17, 0), //tło wybranego
                                        color: Color.fromARGB(255, 0, 0, 0), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 70.0,
                                         
                                        ),
                                        isSelected: _selectedZasoby,
                                        children: [ //napisy na przełącznikach
                                          czerwDod != 0 ? Text('$czerwDod' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(AppLocalizations.of(context)!.broodCoveredN, textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfDrone, 1);
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 255, 255, 255), //napis wybranego
                                        fillColor: Color.fromARGB(255, 114, 0, 0), //tło wybranego
                                        color: Color.fromARGB(255, 0, 0, 0), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 70.0,
                                        
                                        ),
                                        isSelected: _selectedZasoby,
                                        children: [ //napisy na przełącznikach
                                          trutDod != 0 ? Text('$trutDod' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(AppLocalizations.of(context)!.droneN , textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 

//mateczniki
                             //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//mateczniki / usunięte mateczniki                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertNr(AppLocalizations.of(context)!.nUmberOfQueenCells, 11);
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 255, 255, 255), //napis wybranego
                                        fillColor: Color.fromARGB(255, 255, 17, 0), //tło wybranego
                                        color: Color.fromARGB(255, 0, 0, 0), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 60.0,
                                         
                                        ),
                                        isSelected: _selectedZasoby,
                                        children: [ //napisy na przełącznikach
                                          matecznikiDod != 0 ? Text('$matecznikiDod' + ' szt.', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.queenCells + '  ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertNr(AppLocalizations.of(context)!.nUmberOfCellsRemoved, 12);
                                          setState(() {
                                            // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                            // for (int i = 0; i < _selectedStronaRamki.length; i++) {
                                            //   _selectedStronaRamki[i] = i == index;
                                            // }
                                          });
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        borderColor: Color.fromARGB(255, 162, 103, 0),
                                        selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                        selectedColor: Color.fromARGB(255, 255, 255, 255), //napis wybranego
                                        fillColor: Color.fromARGB(255, 153, 125, 125), //tło wybranego
                                        color: Color.fromARGB(255, 0, 0, 0), //napis niewybranego
                                        constraints: const BoxConstraints(
                                          minHeight: 38.0,
                                          minWidth: 60.0,
                                        
                                        ),
                                        isSelected: _selectedZasoby,
                                        children: [ //napisy na przełącznikach
                                          usunmatDod != 0 ? Text('$usunmatDod' + ' szt.', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text('  ' + AppLocalizations.of(context)!.deleteQueenCellsN + '  ' , textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]),  

                            ]),//?????????
                              
//toDo                              
                              if (nowyZasob == 13)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(AppLocalizations.of(context)!.toDo),
                                          SizedBox(height: 5),
                                          ToggleButtons(
                                            direction: Axis.vertical, 
                                            onPressed: (int index) {
                                              setState(() {
                                                // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                                for (int i = 0; i < _selectedToDo.length; i++) {
                                                  _selectedToDo[i] = i == index;
                                                }
                                              });
                                            },
                                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                                            borderColor: Color.fromARGB(255, 162, 103, 0),
                                            selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                            selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                            fillColor: Theme.of(context).primaryColor, //tło wybranego
                                            color: Color.fromARGB(255, 78, 78, 78), //napis niewybranego
                                            constraints: const BoxConstraints(
                                              minHeight: 45.0,
                                              minWidth: 200.0,
                                            ),
                                            isSelected: _selectedToDo,
                                            children: [ //napisy na przełącznikach
                                              Text(AppLocalizations.of(context)!.workFrame),
                                              Text(AppLocalizations.of(context)!.toExtraction),
                                              Text(AppLocalizations.of(context)!.toDelete),
                                              Text(AppLocalizations.of(context)!.toInsulate)
                                            ],  
                                          ),                                  
                                      ]),
                                  ],
                                ),
                                
                                
                                
                                
                                
                                
                                
                                
                                // Row(
                                //     mainAxisAlignment: MainAxisAlignment.center,
                                //     crossAxisAlignment: CrossAxisAlignment.center,
                                //     children: <Widget>[
                                //       DropdownButton(
                                //         style: TextStyle(
                                //           fontSize: 18,
                                //           color: Colors.black54,
                                //         ),
                                //         value: nowaWartosc, //ramka[0].zasob, //ustawiona, widoczna wartość
                                //         items: [
                                //           DropdownMenuItem(
                                //               child: Text(AppLocalizations.of(context)!.workFrame),
                                //               value: AppLocalizations.of(context)!.workFrame),
                                //           DropdownMenuItem(
                                //               child: Text(AppLocalizations.of(context)!.toExtraction),
                                //               value: AppLocalizations.of(context)!.toExtraction),
                                //           DropdownMenuItem(
                                //               child: Text(AppLocalizations.of(context)!.toDelete),
                                //               value: AppLocalizations.of(context)!.toDelete),
                                //           DropdownMenuItem(
                                //               child: Text(AppLocalizations.of(context)!.toInsulate),
                                //               value: AppLocalizations.of(context)!.toInsulate),
                                //         ], //lista elementów do wyboru
                                //         onChanged: (newValue) {
                                //           setState(() {
                                //             nowaWartosc = newValue
                                //                 .toString(); // ustawienie nowej wwrtośi
                                //             //print('nowy zasób = $nowyZasob');
                                //           });
                                //         }, //onChangeDropdownItemWar1,
                                //       ),
                                //     ]),
//isDone
                              if (nowyZasob == 14)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(AppLocalizations.of(context)!.isDone),
                                          SizedBox(height: 5),
                                          ToggleButtons(
                                            direction: Axis.vertical, 
                                            onPressed: (int index) {
                                              setState(() {
                                                // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                                for (int i = 0; i < _selectedIsDone.length; i++) {
                                                  _selectedIsDone[i] = i == index;
                                                }
                                              });
                                            },
                                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                                            borderColor: Color.fromARGB(255, 162, 103, 0),
                                            selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                            selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                            fillColor: Theme.of(context).primaryColor, //tło wybranego
                                            color: Color.fromARGB(255, 78, 78, 78), //napis niewybranego
                                            constraints: const BoxConstraints(
                                              minHeight: 45.0,
                                              minWidth: 200.0,
                                            ),
                                            isSelected: _selectedIsDone,
                                            children: [ //napisy na przełącznikach
                                              Text(AppLocalizations.of(context)!.deleted),
                                              Text(AppLocalizations.of(context)!.inserted),
                                              Text(AppLocalizations.of(context)!.insulated),
                                              Text(AppLocalizations.of(context)!.movedLeft),
                                              Text(AppLocalizations.of(context)!.movedRight),
                                            ],  
                                          ),                                  
                                      ]),
                                  ],
                                ),
                                // Row(
                                //     mainAxisAlignment: MainAxisAlignment.center,
                                //     crossAxisAlignment: CrossAxisAlignment.center,
                                //     children: <Widget>[
                                //       DropdownButton(
                                //         style: TextStyle(
                                //           fontSize: 18,
                                //           color: Colors.black54,
                                //         ),
                                //         value: nowaWartosc, //ramka[0].zasob, //ustawiona, widoczna wartość
                                //         items: [
                                //           DropdownMenuItem(
                                //               child: Text(AppLocalizations.of(context)!.deleted),
                                //               value: AppLocalizations.of(context)!.deleted),
                                //           DropdownMenuItem(
                                //               child: Text(AppLocalizations.of(context)!.inserted),
                                //               value: AppLocalizations.of(context)!.inserted),
                                //           DropdownMenuItem(
                                //               child: Text(AppLocalizations.of(context)!.insulated),
                                //               value: AppLocalizations.of(context)!.insulated),
                                //           DropdownMenuItem(
                                //               child: Text(AppLocalizations.of(context)!.movedLeft),
                                //               value: AppLocalizations.of(context)!.movedLeft),
                                //           DropdownMenuItem(
                                //               child: Text(AppLocalizations.of(context)!.movedRight),
                                //               value: AppLocalizations.of(context)!.movedRight),
                                //         ], //lista elementów do wyboru
                                //         onChanged: (newValue) {
                                //           setState(() {
                                //             nowaWartosc = newValue
                                //                 .toString(); // ustawienie nowej wwrtośi
                                //             //print('nowy zasób = $nowyZasob');
                                //           });
                                //         }, //onChangeDropdownItemWar1,
                                //       ),
                                //     ]),
                        ]),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                
//przyciski
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
//zmień
                          if(tryb == 'edycja')
                            MaterialButton(
                              height: 50,
                              shape: const StadiumBorder(
                                side: const BorderSide(color: Color.fromARGB(255, 162, 103, 0)),
                                ),
                              onPressed: () {
                                DBHelper.deleteFrame(ramka[0].id).then((_) {  //kasowanie ramki bo będzie nowa                                
                                
                                if(nowyZasob! < 13) {  
                                  zapisDoBazy(nowyZasob!, nowaWartosc, 'zmiana');   //zapis nowej ramki                                
                                }

                                if(nowyZasob == 13) {
                                  if(_selectedToDo[0] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.workFrame;}
                                  if(_selectedToDo[1] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.toExtraction;}
                                  if(_selectedToDo[2] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.toDelete;}
                                  if(_selectedToDo[3] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.toInsulate;}
                                  zapisDoBazy(nowyZasob!, nowaWartosc, 'dodaj');
                                 }

                                 if(nowyZasob == 14) {
                                  if(_selectedIsDone[0] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.deleted;}
                                  if(_selectedIsDone[1] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.inserted;}
                                  if(_selectedIsDone[2] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.insulated;}
                                  if(_selectedIsDone[3] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.movedLeft;}
                                  if(_selectedIsDone[4] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.movedRight;}
                                  zapisDoBazy(nowyZasob!, nowaWartosc, 'dodaj');
                                 }
                                  Provider.of<Frames>(context, listen: false)
                                    .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                                    .then((_) {
                                    
                                    //jezeli edycja jednej ramki z numerem róznym od 0 i dla wszystkich zasobów
                                    if(nowyNrRamki != 0 && _selectedZakresRamek[0] && _selectedZakresZasobow[1]){//!!! zeby mogło być kilka ramek nowych wstawianych do ula to mozna to robić tylko dla ramek gdzie "przed" jest rózne od 0
                                      //dla wszystkich zasobów dla ramki z numerem "nowyNrRamki" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
                                      final framesData1 = Provider.of<Frames>(context, listen: false);
                                        //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu)
                                      List<Frame> frames = framesData1.items.where((fr) {
                                        return fr.ramkaNr == nowyNrRamki && fr.data == dateController.text && fr.korpusNr == nowyNrKorpusu; //return fr.data.contains('2024-04-04');
                                      }).toList();

                                        //dla kazdego zasobu modyfikacja ramkaNrPo
                                      for (var i = 0; i < frames.length; i++) {
                                        //(' id: ${frames[i].id}, ramkaPrzed: ${frames[i].ramkaNr}, ramkaPo: ${frames[i].ramkaNrPo}, zasób: ${frames[i].zasob}');
                                        DBHelper.updateRamkaNrPo(frames[i].id, nowyNrRamkiPo!);
                                      }
                                    } 
                                    Provider.of<Frames>(context, listen: false)
                                      .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                                      .then((_) {
                                      Navigator.of(context).pop();
                                    });
                                  });                                   
                                });
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!.replace) +
                                  '   '), //Modyfikuj
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.black,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),

//zapisz
                          if(tryb == 'dodaj')
                            MaterialButton(
                              height: 50,
                               shape: const StadiumBorder(
                                side: const BorderSide(color: Color.fromARGB(255, 162, 103, 0)),
                                ),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                 
                                 if(trutDod > 0){zapisDoBazy(1, trutDod.toString(), 'dodaj');};
                                 if(czerwDod > 0){zapisDoBazy(2, czerwDod.toString(), 'dodaj');};
                                 if(larwyDod > 0){zapisDoBazy(3, larwyDod.toString(), 'dodaj');};
                                 if(jajaDod > 0){zapisDoBazy(4, jajaDod.toString(), 'dodaj');};
                                 if(pierzgaDod > 0){zapisDoBazy(5, pierzgaDod.toString(), 'dodaj');};
                                 if(miodDod > 0){zapisDoBazy(6, miodDod.toString(), 'dodaj');};
                                 if(dojrzalyDod > 0){zapisDoBazy(7, dojrzalyDod.toString(), 'dodaj');};
                                 if(wezaDod > 0){zapisDoBazy(8, wezaDod.toString(), 'dodaj');};
                                 if(suszDod > 0){zapisDoBazy(9, suszDod.toString(), 'dodaj');};
                                 if(matkaDod > 0){zapisDoBazy(10, matkaDod.toString(), 'dodaj');};
                                 if(matecznikiDod > 0){zapisDoBazy(11, matecznikiDod.toString(), 'dodaj');};
                                 if(usunmatDod > 0){zapisDoBazy(12, usunmatDod.toString(), 'dodaj');}; 

                                 if(nowyZasob == 13) {
                                  if(_selectedToDo[0] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.workFrame;}
                                  if(_selectedToDo[1] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.toExtraction;}
                                  if(_selectedToDo[2] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.toDelete;}
                                  if(_selectedToDo[3] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.toInsulate;}
                                  zapisDoBazy(nowyZasob!, nowaWartosc, 'dodaj');
                                 }

                                 if(nowyZasob == 14) {
                                  if(_selectedIsDone[0] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.deleted;}
                                  if(_selectedIsDone[1] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.inserted;}
                                  if(_selectedIsDone[2] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.insulated;}
                                  if(_selectedIsDone[3] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.movedLeft;}
                                  if(_selectedIsDone[4] == true){_selectedStronaRamki[0] = true; nowaWartosc = AppLocalizations.of(context)!.movedRight;}
                                  zapisDoBazy(nowyZasob!, nowaWartosc, 'dodaj');
                                 }
                                  //zapisDoBazy(nowyZasob!, nowaWartosc, 'dodaj');
                                  Provider.of<Frames>(context, listen: false)
                                    .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                                    .then((_) {
                                      //jezeli była to jakaś ramka "przed" i było to dodawanie jednej ramki a nie wielu
                                      if(nowyNrRamki != 0 && _selectedZakresRamek[0]){//zeby mogło być kilka ramek nowych wstawianych do ula
                                        //dla wszystkich zasobów dla ramki z numerem "nowyNrRamki" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
                                        final framesData1 = Provider.of<Frames>(context, listen: false);
                                        //zasoby tej ramki (z wybranej daty dla ula i tylko w wybranym korpusie)
                                        List<Frame> frames = framesData1.items.where((fr) {
                                          return fr.ramkaNr == nowyNrRamki && fr.data == dateController.text && fr.korpusNr == nowyNrKorpusu; //return fr.data.contains('2024-04-04');
                                        }).toList();
                                        //dla kazdego zasobu modyfikacja ramkaNrPo
                                        for (var i = 0; i < frames.length; i++) {
                                          //print('ramka: ${frames[i].ramkaNr} zasób: ${frames[i].zasob}');
                                          DBHelper.updateRamkaNrPo(frames[i].id, nowyNrRamkiPo!);
                                        }
                                      }
                                      Provider.of<Frames>(context, listen: false)
                                        .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                                        .then((_) {
                                        Navigator.of(context).pop();
                                      });
                                  });
                                }
                                ;
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!.saveZ) +
                                  '   '), //Zapisz
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.black,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),
                  ]),
                    ]))));
  }
}
