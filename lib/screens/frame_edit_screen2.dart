
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
import '../models/infos.dart';
import '../models/info.dart';
//import '../screens/activation_screen.dart';
import '../models/frames.dart';
import '../models/hive.dart';
// import 'package:flutter/services.dart';
//import 'frames_detail_screen.dart';

class FrameEditScreen2 extends StatefulWidget {
  static const routeName = '/frame_edit2';
  
  
    @override
    State<FrameEditScreen2> createState() => _FrameEditScreen2State();
  }

class _FrameEditScreen2State extends State<FrameEditScreen2> {
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
  //List<bool> _selectedToDo = <bool>[true, false, false, false]; // ramka pracy | trzeba wirować | trzeba usunać | mozna izolować
  //List<bool> _selectedIsDone = <bool>[true, false, false, false, false]; //usuń ramka | wsraw ramka | izolacja | przesuń w lewo | przesuń w prawo
  int dzielnik = 2; //do ustawiania proporcji klawiszy klawiatur numeru ramki i ilości zasobów

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
  String tagNFC = '';
  List<int> gridItems = [];//tworzona lista klawiszy klawiatury wyboru numeru ramki
  List<int> gridItemsKorpus = [1,2,3,4,5,6,7,8,9]; //lista klawiszy klawiatury wyboru numeru korpusu
  List<int> gridItemsZasob = [0,5,10,15,20,25,30,35,40,50,60,70,80,90,100]; //lista klawiszy klawiatury ilosci zasobu do dodania
  List<String> gridItemsKolor = ['czarny','żółty','czerwony','zielony','niebieski','biały','brak\ndanych','inny'];
  var matkaKolor = Icon(Icons.brightness_1, color: Color.fromARGB(255, 255, 255, 255), size: 30.0,);//niewidoczny - brak informacji o matce
  var matkaKolorP = Icon(Icons.brightness_1, color: Color.fromARGB(255, 255, 255, 255), size: 30.0,);//niewidoczny - brak informacji o matce

  //zasoby dodawane podczas zapisu
  int trutDodL = 0; //dla lewj strony
  int czerwDodL = 0;
  int larwyDodL = 0;
  int jajaDodL = 0;
  int pierzgaDodL = 0;
  int miodDodL = 0;
  int dojrzalyDodL = 0;
  int wezaDodL = 0;
  int suszDodL = 0;
  int matkaDodL = 0;
  int matecznikiDodL = 0;
  int usunmatDodL = 0;
  int sumaZasobowL = 0;
  int trutDodP = 0; //dla prawej strony
  int czerwDodP = 0;
  int larwyDodP = 0;
  int jajaDodP = 0;
  int pierzgaDodP = 0;
  int miodDodP = 0;
  int dojrzalyDodP = 0;
  int wezaDodP = 0;
  int suszDodP = 0;
  int matkaDodP = 0;
  int matecznikiDodP = 0;
  int usunmatDodP = 0;
  int sumaZasobowP = 0;
  
  
  
  @override
  void didChangeDependencies() {
    if (_isInit) {
      //print('na poczatek didChangeDependencies: nowyZasobId  = ${dateController.text}');
      final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    //  final idRamki = routeArgs['idRamki']; //pobiera z frames_detail_item.dart
      final idPasieki = routeArgs['idPasieki'];
      final idUla = routeArgs['idUla'];
      final idZasobu = routeArgs['idZasobu'];
    //  print('ramka = $idRamki, pasieka = $idPasieki , ul = $idUla');

      // if (idRamki != null) {
      //   //jezeli edycja istniejącego wpisu
      //   final frameData = Provider.of<Frames>(context, listen: false);
      //   ramka = frameData.items.where((element) {
      //     //to wczytanie danych ramki
      //     return element.id.contains('$idRamki');
      //   }).toList();
      //   dateController.text = ramka[0].data;
      //   // nowyRok = ramka[0].data.substring(0, 4);
      //   // nowyMiesiac = ramka[0].data.substring(5, 7);
      //   // nowyDzien = ramka[0].data.substring(8);
      //   nowyNrPasieki = ramka[0].pasiekaNr;
      //   nowyNrUla = ramka[0].ulNr;
      //   nowyNrKorpusu = ramka[0].korpusNr;
      //   nowyNrRamki = ramka[0].ramkaNr;
      //   nowyNrRamkiPo = ramka[0].ramkaNrPo;
      //   korpus = ramka[0].typ;
      //   korpus == 1 ? _selectedKorpus[0] = true : _selectedKorpus[0] = false;
      //   korpus == 2 ? _selectedKorpus[1] = true : _selectedKorpus[1] = false;
      //   rozmiarRamki = ramka[0].rozmiar;
      //   rozmiarRamki == 1 ? _selectedRozmiarRamki[0] = true : _selectedRozmiarRamki[0] = false;
      //   rozmiarRamki == 2 ? _selectedRozmiarRamki[1] = true : _selectedRozmiarRamki[1] = false;
      //   nowyZasob = ramka[0].zasob; //id edytowanego zasobu 
      //   nowaWartosc = ramka[0].wartosc.replaceAll(RegExp('%'), '');
      //   switch (nowyZasob) {
      //     case 1: trutDod = int.parse(nowaWartosc);break;
      //     case 2: czerwDod = int.parse(nowaWartosc);break;
      //     case 3: larwyDodL = int.parse(nowaWartosc);break;
      //     case 4: jajaDod = int.parse(nowaWartosc);break;
      //     case 5: pierzgaDod = int.parse(nowaWartosc);break;
      //     case 6: miodDod = int.parse(nowaWartosc);break;
      //     case 7: dojrzalyDod = int.parse(nowaWartosc);break;
      //     case 8: wezaDod = int.parse(nowaWartosc);break;
      //     case 9: suszDod = int.parse(nowaWartosc);break;
      //     case 10: matkaDod = int.parse(nowaWartosc);
      //               switch(matkaDod){
      //                 case 1: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);break;
      //                 case 2: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 215, 208, 0),size: 30.0);break;
      //                 case 3: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 0, 0),size: 30.0);break;
      //                 case 4: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 15, 200, 8),size: 30.0);break;
      //                 case 5: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 102, 255),size: 30.0);break;
      //                 case 6: matkaKolor = Icon(Icons.brightness_1_outlined,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);break;
      //                 case 6: matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 255, 255),size: 30.0);break;
      //                 default:
      //               }
      //       break;
      //     case 11: matecznikiDod = int.parse(nowaWartosc);break;
      //     case 12: usunmatDod = int.parse(nowaWartosc);break;
      //     case 13: switch (nowaWartosc) {
      //               case 'ramka pracy': _selectedToDo = [true, false, false, false];break; // ramka pracy | trzeba wirować | trzeba usunać | mozna izolować
      //               case 'trzeba wirować': _selectedToDo = [false, true, false, false];break;
      //               case 'trzeba usunąć': _selectedToDo = [false, false, true, false];break;
      //               case 'można izolować': _selectedToDo = [false, false, false, true];break;
      //               case 'work frame': _selectedToDo = [true, false, false, false];break; // ramka pracy | trzeba wirować | trzeba usunać | mozna izolować
      //               case 'to extraction': _selectedToDo = [false, true, false, false];break;
      //               case 'to delete': _selectedToDo = [false, false, true, false];break;
      //               case 'to insulate': _selectedToDo = [false, false, false, true];break;
      //             default: _selectedToDo = [true, false, false, false];
      //             }break;
      //     case 14: switch (nowaWartosc) {
      //               case 'usuń ramka': _selectedIsDone = <bool>[true, false, false, false, false];break; //usuń ramka | wstaw ramka | izolacja | przesuń w lewo | przesuń w prawo
      //               case 'wstaw ramka': _selectedIsDone = <bool>[false, true, false, false, false];break;
      //               case 'izolacja': _selectedIsDone = <bool>[false, false, true, false, false];break;
      //               case 'przesuń w lewo': _selectedIsDone = <bool>[false, false, false, true, false];break;
      //               case 'przesuń w prawo': _selectedIsDone = <bool>[false, false, false, false, true];break;
      //               case 'deleted': _selectedIsDone = <bool>[true, false, false, false, false];break; //usuń ramka | wstaw ramka | izolacja | przesuń w lewo | przesuń w prawo
      //               case 'inserted': _selectedIsDone = <bool>[false, true, false, false, false];break;
      //               case 'insulated': _selectedIsDone = <bool>[false, false, true, false, false];break;
      //               case 'moved left': _selectedIsDone = <bool>[false, false, false, true, false];break;
      //               case 'moved right': _selectedIsDone = <bool>[false, false, false, false, true];break;
      //             default: _selectedIsDone = <bool>[true, false, false, false, false];
      //             }break;
      //     default:
      //   }
      //   stronaRamki = ramka[0].strona; //1-lewa, 2-prawa
      //   stronaRamki == 1 ? _selectedStronaRamki[0] = true : _selectedStronaRamki[0] = false;
      //   stronaRamki == 2 ? _selectedStronaRamki[2] = true : _selectedStronaRamki[2] = false;                                  
      //   tryb = 'edycja';
      //   tytulEkranu = AppLocalizations.of(context)!.editingFrame; //edycja zasobu
   //   } else {
        //jezeli dodanie nowego wpisu (tylko dla aktualnie wybranej pasieki i ula)
        dateController.text = globals.dataWpisu; //DateTime.now().toString().substring(0, 10);
        // nowyRok = DateFormat('yyyy').format(DateTime.now());
        // nowyMiesiac = DateFormat('MM').format(DateTime.now());
        // nowyDzien = DateFormat('dd').format(DateTime.now());
        nowyNrPasieki = int.parse('$idPasieki');
        nowyNrUla = int.parse('$idUla');
        nowyNrKorpusu = globals.nowyNrKorpusu; //zapamiętany ostatni wybór
        // globals.nowyNrRamki < 10 ? nowyNrRamki = globals.nowyNrRamki + 1 : nowyNrRamki = globals.nowyNrRamki;
        // globals.nowyNrRamkiPo < 10 ? nowyNrRamkiPo = globals.nowyNrRamkiPo + 1 : nowyNrRamkiPo = globals.nowyNrRamkiPo;
        // nowyNrRamki = globals.nowyNrRamki;
        // nowyNrRamkiPo = globals.nowyNrRamkiPo;
        // print(globals.nowyNrRamki);
        //  print(globals.ileRamek);
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
  //      if (nowyZasob == 13) nowaWartosc = AppLocalizations.of(context)!.workFrame;
   //     if (nowyZasob == 14) nowaWartosc = AppLocalizations.of(context)!.deleted; 
   //   }
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

      globals.nowyNrRamki < ramek ? nowyNrRamki = globals.nowyNrRamki + 1 : nowyNrRamki = globals.nowyNrRamki;
      globals.nowyNrRamki  = nowyNrRamki!;
      globals.nowyNrRamkiPo < ramek ? nowyNrRamkiPo = globals.nowyNrRamkiPo + 1 : nowyNrRamkiPo = globals.nowyNrRamkiPo;
      globals.nowyNrRamkiPo  = nowyNrRamkiPo!;

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
                  .map((data) => InkWell( //data - kolejne elementy klikalne w oknie wyboru np. numeru ramki
                    onTap: () {
                      switch (przycisk) {
                        case 1:
                          setState(() {
                            nowyNrRamki = data; //numer ramki "przed"
                            globals.nowyNrRamki = data;
                            globals.zakresRamek = 0; //zapamiętanie ze jedna ramka
                          });
                          break;
                        case 2:
                          setState(() {
                            nowyNrRamkiPo = data; //numer ramki "po"
                            globals.nowyNrRamkiPo = data;
                            globals.zakresRamek = 0; //zapamiętanie ze jedna ramka
                          });
                          break;  
                        case 3:
                          setState(() {
                            nrRamkiOd = data; //numer ramki "od"
                            globals.nrRamkiOd = data;
                            globals.zakresRamek = 1; //zapamiętanie ze wiele ramek
                          });
                          break; 
                        case 4:
                          setState(() {
                            nrRamkiDo = data; //numer ramki "do"
                            globals.nrRamkiDo = data;
                            globals.zakresRamek = 1; //zapamiętanie ze wiele ramek
                          });
                          break; 
                        default:
                      }
                      
                      if(tryb == 'dodaj')
                        switch (przycisk) {
                          case 11: setState(() {matecznikiDodL = data;}); break; 
                          case 12: setState(() {usunmatDodL = data;}); break; 
                          case 111: setState(() {matecznikiDodP = data;}); break; 
                          case 112: setState(() {usunmatDodP = data;}); break;
                          default:
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
                      
                    
                      if(tryb == 'dodaj')
                        switch (przycisk) {
                          case 1: 
                            //dodanie wybranej wartości do sumy zasobów (bez modyfikacji aktualnej wartości wybranego zasobu!)
                            sumaZasobowL = data + czerwDodL + larwyDodL + jajaDodL + pierzgaDodL + miodDodL + dojrzalyDodL + wezaDodL + suszDodL;
                            if(sumaZasobowL>100){ //jezeli suma przekroczyła 100%
                              int zaDuzo = sumaZasobowL - 100; 
                              sumaZasobowL -= data; //od sumy odjąć proponowaną wartość
                              sumaZasobowL  += trutDodL; //do sumy dodać poprzednią, niezmodyfikowaną wartość by taka jak przed wybraniem tej wartości
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel, AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowL + trutDodL}%');break; //wyświetlenie komunikatu
                            }else{setState(() {trutDodL = data;}); Navigator.of(context).pop();break;}

                          case 2: 
                            sumaZasobowL = trutDodL + data + larwyDodL + jajaDodL + pierzgaDodL + miodDodL + dojrzalyDodL + wezaDodL + suszDodL;
                            if(sumaZasobowL>100){
                              int zaDuzo = sumaZasobowL - 100;
                              sumaZasobowL -= data;
                              sumaZasobowL  += czerwDodL;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowL + czerwDodL}%');break;
                            }else{setState(() {czerwDodL = data;}); Navigator.of(context).pop();break;}

  
                          case 3: 
                            sumaZasobowL = trutDodL + czerwDodL + data + jajaDodL + pierzgaDodL + miodDodL + dojrzalyDodL + wezaDodL + suszDodL;
                            if(sumaZasobowL>100){
                              int zaDuzo = sumaZasobowL - 100;
                              sumaZasobowL -= data;
                              sumaZasobowL  += larwyDodL;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowL + larwyDodL}%');break;
                            }else{setState(() {larwyDodL = data;}); Navigator.of(context).pop();break;}

                          case 4: 
                            sumaZasobowL = trutDodL + czerwDodL + larwyDodL + data + pierzgaDodL + miodDodL + dojrzalyDodL + wezaDodL + suszDodL;
                            if(sumaZasobowL>100){
                              int zaDuzo = sumaZasobowL - 100;
                              sumaZasobowL -= data;
                              sumaZasobowL  += jajaDodL;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowL + jajaDodL}%');break;
                            }else{setState(() {jajaDodL = data;}); Navigator.of(context).pop();break;}

                          case 5: 
                            sumaZasobowL = trutDodL + czerwDodL + larwyDodL + jajaDodL + data + miodDodL + dojrzalyDodL + wezaDodL + suszDodL;
                            if(sumaZasobowL>100){
                              int zaDuzo = sumaZasobowL - 100;
                              sumaZasobowL -= data;
                              sumaZasobowL  += pierzgaDodL;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowL + pierzgaDodL}%');break;
                            }else{setState(() {pierzgaDodL = data;}); Navigator.of(context).pop();break;}

                          case 6: 
                            sumaZasobowL = trutDodL + czerwDodL + larwyDodL + jajaDodL + pierzgaDodL + data + dojrzalyDodL + wezaDodL + suszDodL;
                            if(sumaZasobowL>100){
                              int zaDuzo = sumaZasobowL - 100;
                              sumaZasobowL -= data;
                              sumaZasobowL  += miodDodL;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowL + miodDodL}%');break;
                            }else{setState(() {miodDodL = data;}); Navigator.of(context).pop();break;}

                          case 7: 
                            sumaZasobowL = trutDodL + czerwDodL + larwyDodL + jajaDodL + pierzgaDodL + miodDodL + data + wezaDodL + suszDodL;
                            if(sumaZasobowL>100){
                              int zaDuzo = sumaZasobowL - 100;
                              sumaZasobowL -= data;
                              sumaZasobowL  += dojrzalyDodL;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowL + dojrzalyDodL}%');break;
                            }else{setState(() {dojrzalyDodL = data;}); Navigator.of(context).pop();break;}
  
                          case 8: 
                            sumaZasobowL = trutDodL + czerwDodL + larwyDodL + jajaDodL + pierzgaDodL + miodDodL + dojrzalyDodL + data + suszDodL;
                            if(sumaZasobowL>100){
                              int zaDuzo = sumaZasobowL - 100;
                              sumaZasobowL -= data;
                              sumaZasobowL  += wezaDodL;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowL + wezaDodL}%');break;
                            }else{setState(() {wezaDodL = data;}); Navigator.of(context).pop();break;}
  
                          case 9: 
                            sumaZasobowL = trutDodL + czerwDodL + larwyDodL + jajaDodL + pierzgaDodL + miodDodL + dojrzalyDodL + wezaDodL + data;
                            if(sumaZasobowL>100){
                              int zaDuzo = sumaZasobowL - 100;
                              sumaZasobowL -= data;
                              sumaZasobowL  += suszDodL;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowL + suszDodL}%');break;
                            }else{setState(() {suszDodL = data;}); Navigator.of(context).pop();break;}
                              
                          default:
                        }
                      //sumaZasobowL = trutDodL + czerwDod + larwyDodL + jajaDodL + pierzgaDodL + miodDodL + dojrzalyDodL + wezaDodL + suszDodL;
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

   //wybór ilości zasobu do zapisu
  void _showAlertDodajZasobP(String wybor, int przycisk) {
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
                      
                    
                      if(tryb == 'dodaj')
                        switch (przycisk) {
                          case 1: 
                            //dodanie wybranej wartości do sumy zasobów (bez modyfikacji aktualnej wartości wybranego zasobu!)
                            sumaZasobowP = data + czerwDodP + larwyDodP + jajaDodP + pierzgaDodP + miodDodP + dojrzalyDodP + wezaDodP + suszDodP;
                            if(sumaZasobowP>100){ //jezeli suma przekroczyła 100%
                              int zaDuzo = sumaZasobowP - 100; 
                              sumaZasobowP -= data; //od sumy odjąć proponowaną wartość
                              sumaZasobowP  += trutDodP; //do sumy dodać poprzednią, niezmodyfikowaną wartość by taka jak przed wybraniem tej wartości
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel, AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowP + trutDodL}%');break; //wyświetlenie komunikatu
                            }else{setState(() {trutDodP = data;}); Navigator.of(context).pop();break;}

                          case 2: 
                            sumaZasobowP = trutDodP + data + larwyDodP + jajaDodP + pierzgaDodP + miodDodP + dojrzalyDodP + wezaDodP + suszDodP;
                            if(sumaZasobowP>100){
                              int zaDuzo = sumaZasobowP - 100;
                              sumaZasobowP -= data;
                              sumaZasobowP  += czerwDodP;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowP + czerwDodP}%');break;
                            }else{setState(() {czerwDodP = data;}); Navigator.of(context).pop();break;}

  
                          case 3: 
                            sumaZasobowP = trutDodP + czerwDodP + data + jajaDodP + pierzgaDodP + miodDodP + dojrzalyDodP + wezaDodP + suszDodP;
                            if(sumaZasobowP>100){
                              int zaDuzo = sumaZasobowP - 100;
                              sumaZasobowP -= data;
                              sumaZasobowP  += larwyDodP;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowP + larwyDodP}%');break;
                            }else{setState(() {larwyDodP = data;}); Navigator.of(context).pop();break;}

                          case 4: 
                            sumaZasobowP = trutDodP + czerwDodP + larwyDodP + data + pierzgaDodP + miodDodP + dojrzalyDodP + wezaDodP + suszDodP;
                            if(sumaZasobowP>100){
                              int zaDuzo = sumaZasobowP - 100;
                              sumaZasobowP -= data;
                              sumaZasobowP  += jajaDodP;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowP + jajaDodP}%');break;
                            }else{setState(() {jajaDodP = data;}); Navigator.of(context).pop();break;}

                          case 5: 
                            sumaZasobowP = trutDodP + czerwDodP + larwyDodP + jajaDodP + data + miodDodP + dojrzalyDodP + wezaDodP + suszDodP;
                            if(sumaZasobowP>100){
                              int zaDuzo = sumaZasobowP - 100;
                              sumaZasobowP -= data;
                              sumaZasobowP  += pierzgaDodP;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowP + pierzgaDodP}%');break;
                            }else{setState(() {pierzgaDodP = data;}); Navigator.of(context).pop();break;}

                          case 6: 
                            sumaZasobowP = trutDodP + czerwDodP + larwyDodP + jajaDodP + pierzgaDodP + data + dojrzalyDodP + wezaDodP + suszDodP;
                            if(sumaZasobowP>100){
                              int zaDuzo = sumaZasobowP - 100;
                              sumaZasobowP -= data;
                              sumaZasobowP  += miodDodP;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowP + miodDodP}%');break;
                            }else{setState(() {miodDodP = data;}); Navigator.of(context).pop();break;}

                          case 7: 
                            sumaZasobowP = trutDodP + czerwDodP + larwyDodP + jajaDodP + pierzgaDodP + miodDodP + data + wezaDodP + suszDodP;
                            if(sumaZasobowP>100){
                              int zaDuzo = sumaZasobowP - 100;
                              sumaZasobowP -= data;
                              sumaZasobowP  += dojrzalyDodP;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowP + dojrzalyDodP}%');break;
                            }else{setState(() {dojrzalyDodP = data;}); Navigator.of(context).pop();break;}
  
                          case 8: 
                            sumaZasobowP = trutDodP + czerwDodP + larwyDodP + jajaDodP + pierzgaDodP + miodDodP + dojrzalyDodP + data + suszDodP;
                            if(sumaZasobowP>100){
                              int zaDuzo = sumaZasobowP - 100;
                              sumaZasobowP -= data;
                              sumaZasobowP  += wezaDodP;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowP + wezaDodP}%');break;
                            }else{setState(() {wezaDodP = data;}); Navigator.of(context).pop();break;}
  
                          case 9: 
                            sumaZasobowP = trutDodP + czerwDodP + larwyDodP + jajaDodP + pierzgaDodP + miodDodP + dojrzalyDodP + wezaDodP + data;
                            if(sumaZasobowP>100){
                              int zaDuzo = sumaZasobowP - 100;
                              sumaZasobowP -= data;
                              sumaZasobowP  += suszDodP;
                              _showAlertAnuluj(context,AppLocalizations.of(context)!.cancel,AppLocalizations.of(context)!.aBout + ' $zaDuzo' + AppLocalizations.of(context)!.tooMuch +  ' ${100 - sumaZasobowL + suszDodP}%');break;
                            }else{setState(() {suszDodP = data;}); Navigator.of(context).pop();break;}
                              
                          default:
                        }
                      //sumaZasobowL = trutDodL + czerwDod + larwyDodL + jajaDodL + pierzgaDodL + miodDodL + dojrzalyDodL + wezaDodL + suszDodL;
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
  
  //wybór koloru oznaczenia matki dla lewej strony
  void _showAlertKolorL(String wybor, int przycisk) {
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
                      
                    
                      if(tryb == 'dodaj')
                        if(globals.jezyk == 'pl_PL'){  
                          switch (data) {
                            case 'czarny': 
                              setState(() {
                                matkaDodL = 1;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;
                            case 'żółty': 
                              setState(() {
                                matkaDodL = 2;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 215, 208, 0),size: 30.0);
                              }); break;  
                            case 'czerwony': 
                              setState(() {
                                matkaDodL = 3;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 0, 0),size: 30.0);
                              }); break; 
                            case 'zielony': 
                              setState(() {
                                matkaDodL = 4;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 15, 200, 8),size: 30.0);
                              }); break;                        
                            case 'niebieski': 
                              setState(() {
                                matkaDodL = 5;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 102, 255),size: 30.0);
                              }); break; 
                            case 'biały': 
                              setState(() {
                                matkaDodL = 6;
                                matkaKolor = Icon(Icons.brightness_1_outlined,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;
                            case 'inny': 
                              setState(() {
                                matkaDodL = 7;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 158, 166, 172),size: 30.0);
                              }); break;                       
                            default:
                              setState(() {
                                matkaDodL = 0; //zeby jej nie zapisywac w bazie gdyby ktoś wybrał ten przycisk kasujący ewentualnmy poprzedni wybór
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 255, 255),size: 30.0);
                              }); 
                          }
                        }else{
                          switch (data) {
                            case 'black': 
                              setState(() {
                                matkaDodL = 1;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;
                            case 'yellow': 
                              setState(() {
                                matkaDodL = 2;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 215, 208, 0),size: 30.0);
                              }); break;  
                            case 'red': 
                              setState(() {
                                matkaDodL = 3;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 0, 0),size: 30.0);
                              }); break; 
                            case 'green': 
                              setState(() {
                                matkaDodL = 4;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 15, 200, 8),size: 30.0);
                              }); break;                        
                            case 'blue': 
                              setState(() {
                                matkaDodL = 5;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 102, 255),size: 30.0);
                              }); break; 
                            case 'white': 
                              setState(() {
                                matkaDodL = 6;
                                matkaKolor = Icon(Icons.brightness_1_outlined,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;                     
                            case 'other': 
                              setState(() {
                                matkaDodL = 7;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 158, 166, 172),size: 30.0);
                              }); break;  
                            default:
                              setState(() {
                                matkaDodL = 0; //zeby jej nie zapisywac w bazie gdyby ktoś wybrał ten przycisk kasujący ewentualnmy poprzedni wybór
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

  //wybór koloru oznaczenia matki dla prawej strony
  void _showAlertKolorP(String wybor, int przycisk) {
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
                      
                    
                      if(tryb == 'dodaj')
                        if(globals.jezyk == 'pl_PL'){  
                          switch (data) {
                            case 'czarny': 
                              setState(() {
                                matkaDodP = 1;
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;
                            case 'żółty': 
                              setState(() {
                                matkaDodP = 2;
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 215, 208, 0),size: 30.0);
                              }); break;  
                            case 'czerwony': 
                              setState(() {
                                matkaDodP = 3;
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 0, 0),size: 30.0);
                              }); break; 
                            case 'zielony': 
                              setState(() {
                                matkaDodP = 4;
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 15, 200, 8),size: 30.0);
                              }); break;                        
                            case 'niebieski': 
                              setState(() {
                                matkaDodP = 5;
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 102, 255),size: 30.0);
                              }); break; 
                            case 'biały': 
                              setState(() {
                                matkaDodP = 6;
                                matkaKolorP = Icon(Icons.brightness_1_outlined,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;                     
                            case 'inny': 
                              setState(() {
                                matkaDodP = 7;
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 158, 166, 172),size: 30.0);
                              }); break;  
                            default:
                              setState(() {
                                matkaDodP = 0; //zeby jej nie zapisywac w bazie gdyby ktoś wybrał ten przycisk kasujący ewentualnmy poprzedni wybór
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 255, 255),size: 30.0);
                              }); 
                          }
                        }else{
                          switch (data) {
                            case 'black': 
                              setState(() {
                                matkaDodP = 1;
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;
                            case 'yellow': 
                              setState(() {
                                matkaDodP = 2;
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 215, 208, 0),size: 30.0);
                              }); break;  
                            case 'red': 
                              setState(() {
                                matkaDodP = 3;
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 0, 0),size: 30.0);
                              }); break; 
                            case 'green': 
                              setState(() {
                                matkaDodP = 4;
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 15, 200, 8),size: 30.0);
                              }); break;                        
                            case 'blue': 
                              setState(() {
                                matkaDodP = 5;
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 0, 102, 255),size: 30.0);
                              }); break; 
                            case 'white': 
                              setState(() {
                                matkaDodP = 6;
                                matkaKolorP = Icon(Icons.brightness_1_outlined,color: Color.fromARGB(255, 0, 0, 0),size: 30.0);
                              }); break;                     
                            case 'other': 
                              setState(() {
                                matkaDodP = 7;
                                matkaKolor = Icon(Icons.brightness_1,color: Color.fromARGB(255, 158, 166, 172),size: 30.0);
                              }); break;  
                            default:
                              setState(() {
                                matkaDodP = 0; //zeby jej nie zapisywac w bazie gdyby ktoś wybrał ten przycisk kasujący ewentualnmy poprzedni wybór
                                matkaKolorP = Icon(Icons.brightness_1,color: Color.fromARGB(255, 255, 255, 255),size: 30.0);
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
  
  
  //zapis zasobu do tabeli "ramki" - tylko dla lewej strony ramki
  zapisDoBazyL(int zas, String wart, String zrobic) {
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
 //   if(_selectedStronaRamki[0] == true){ //[0]==true to lewa; [0]==false to obie, chyba ze
      stronaRamki = 1; globals.stronaRamki = 1;   //lewa strona
    // }else { 
    //   stronaRamki = 0; globals.stronaRamki = 0;
    // }
    // if(_selectedStronaRamki[2] == true){//[2]==true to prawa
    //   stronaRamki = 2; globals.stronaRamki = 2;
    // }
    
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

       // if (stronaRamki == 1) { //dla lewej strony
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
        // }else if (stronaRamki == 2) { //dla prawej strony
        //   Frames.insertFrame(
        //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nrWieluRamekPrzed.$nrWieluRamekPo.2.$zas',
        //     formattedDate,
        //     nowyNrPasieki!,
        //     nowyNrUla!,
        //     nowyNrKorpusu!,
        //     korpus,
        //     nrWieluRamekPrzed,
        //     nrWieluRamekPo,
        //     rozmiarRamki,
        //     2, //prawa
        //     zas,
        //     wart,
        //     0); //arch
        // }else { //dla obu stron ramki
        //   Frames.insertFrame(
        //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nrWieluRamekPrzed.$nrWieluRamekPo.1.$zas',
        //     formattedDate,
        //     nowyNrPasieki!,
        //     nowyNrUla!,
        //     nowyNrKorpusu!,
        //     korpus,
        //     nrWieluRamekPrzed,
        //     nrWieluRamekPo,
        //     rozmiarRamki,
        //     1, //lewa
        //     zas,
        //     wart,
        //     0);
        //   Frames.insertFrame(
        //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nrWieluRamekPrzed.$nrWieluRamekPo.2.$zas',
        //     formattedDate,
        //     nowyNrPasieki!,
        //     nowyNrUla!,
        //     nowyNrKorpusu!,
        //     korpus,
        //     nrWieluRamekPrzed,
        //     nrWieluRamekPo,
        //     rozmiarRamki,
        //     2, //lewa
        //     zas,
        //     wart,
        //     0);
        // }
      }
      //jezeli jedna ramka
    }else{
      //if (stronaRamki == 1) { //dla lewej strony
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
      // } else if (stronaRamki == 2) { //dla prawej strony
      //   Frames.insertFrame(
      //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.2.$zas',
      //     formattedDate,
      //     nowyNrPasieki!,
      //     nowyNrUla!,
      //     nowyNrKorpusu!,
      //     korpus,
      //     nowyNrRamki!,
      //     nowyNrRamkiPo!,
      //     rozmiarRamki,
      //     2, //prawa
      //     zas,
      //     wart,
      //     0); //arch
      // } else { //dla obu stron ramki
      //   Frames.insertFrame(
      //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.1.$zas',
      //     formattedDate,
      //     nowyNrPasieki!,
      //     nowyNrUla!,
      //     nowyNrKorpusu!,
      //     korpus,
      //     nowyNrRamki!,
      //     nowyNrRamkiPo!,
      //     rozmiarRamki,
      //     1, //lewa
      //     zas,
      //     wart,
      //     0);
      //   Frames.insertFrame(
      //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.2.$zas',
      //     formattedDate,
      //     nowyNrPasieki!,
      //     nowyNrUla!,
      //     nowyNrKorpusu!,
      //     korpus,
      //     nowyNrRamki!,
      //     nowyNrRamkiPo!,
      //     rozmiarRamki,
      //     2, //lewa
      //     zas,
      //     wart,
      //     0);
      // }

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
    tagNFC = hive[0].h3;     
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
          rodzajUla, // h1
          typUla, //h2
          tagNFC, //h3
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

//zapis zasobu do tabeli "ramki" - tylko dla prawej strony ramki
  zapisDoBazyP(int zas, String wart, String zrobic) {
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
 //   if(_selectedStronaRamki[0] == true){ //[0]==true to lewa; [0]==false to obie, chyba ze
    //  stronaRamki = 1; globals.stronaRamki = 1;   //lewa strona
    // }else { 
    //   stronaRamki = 0; globals.stronaRamki = 0;
    // }
    // if(_selectedStronaRamki[2] == true){//[2]==true to prawa
      stronaRamki = 2; globals.stronaRamki = 2; //prawa strona
    // }
    
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

       // if (stronaRamki == 1) { //dla lewej strony
            // print(
            //     'zapis do bazy id = $formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.1.$zas');
            // print('numer ramki = $i');
            // print('nowa wartość = $wart');
            // print(
            //     'dane do zapisu = $formattedDate, $nowyNrPasieki,$nowyNrUla,$nowyNrKorpusu,$korpus,$nowyNrRamki,$nowyNrRamkiPo,$rozmiarRamki,1,$zas,$wart,0');
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
        // }else if (stronaRamki == 2) { //dla prawej strony
        //   Frames.insertFrame(
        //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nrWieluRamekPrzed.$nrWieluRamekPo.2.$zas',
        //     formattedDate,
        //     nowyNrPasieki!,
        //     nowyNrUla!,
        //     nowyNrKorpusu!,
        //     korpus,
        //     nrWieluRamekPrzed,
        //     nrWieluRamekPo,
        //     rozmiarRamki,
        //     2, //prawa
        //     zas,
        //     wart,
        //     0); //arch
        // }else { //dla obu stron ramki
        //   Frames.insertFrame(
        //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nrWieluRamekPrzed.$nrWieluRamekPo.1.$zas',
        //     formattedDate,
        //     nowyNrPasieki!,
        //     nowyNrUla!,
        //     nowyNrKorpusu!,
        //     korpus,
        //     nrWieluRamekPrzed,
        //     nrWieluRamekPo,
        //     rozmiarRamki,
        //     1, //lewa
        //     zas,
        //     wart,
        //     0);
        //   Frames.insertFrame(
        //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nrWieluRamekPrzed.$nrWieluRamekPo.2.$zas',
        //     formattedDate,
        //     nowyNrPasieki!,
        //     nowyNrUla!,
        //     nowyNrKorpusu!,
        //     korpus,
        //     nrWieluRamekPrzed,
        //     nrWieluRamekPo,
        //     rozmiarRamki,
        //     2, //lewa
        //     zas,
        //     wart,
        //     0);
        // }
      }
      //jezeli jedna ramka
    }else{
      //if (stronaRamki == 1) { //dla lewej strony
          // print(
          //     'zapis do bazy id = $formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.1.$zas');
          // print('nowa wartość = $wart');
          // print(
          //     'dane do zapisu = $formattedDate, $nowyNrPasieki,$nowyNrUla,$nowyNrKorpusu,$korpus,$nowyNrRamki,$nowyNrRamkiPo,$rozmiarRamki,1,$zas,$wart,0');
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
      // } else if (stronaRamki == 2) { //dla prawej strony
      //   Frames.insertFrame(
      //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.2.$zas',
      //     formattedDate,
      //     nowyNrPasieki!,
      //     nowyNrUla!,
      //     nowyNrKorpusu!,
      //     korpus,
      //     nowyNrRamki!,
      //     nowyNrRamkiPo!,
      //     rozmiarRamki,
      //     2, //prawa
      //     zas,
      //     wart,
      //     0); //arch
      // } else { //dla obu stron ramki
      //   Frames.insertFrame(
      //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.1.$zas',
      //     formattedDate,
      //     nowyNrPasieki!,
      //     nowyNrUla!,
      //     nowyNrKorpusu!,
      //     korpus,
      //     nowyNrRamki!,
      //     nowyNrRamkiPo!,
      //     rozmiarRamki,
      //     1, //lewa
      //     zas,
      //     wart,
      //     0);
      //   Frames.insertFrame(
      //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.2.$zas',
      //     formattedDate,
      //     nowyNrPasieki!,
      //     nowyNrUla!,
      //     nowyNrKorpusu!,
      //     korpus,
      //     nowyNrRamki!,
      //     nowyNrRamkiPo!,
      //     rozmiarRamki,
      //     2, //lewa
      //     zas,
      //     wart,
      //     0);
      // }

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
    tagNFC = hive[0].h3;
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
          rodzajUla, // h1
          typUla, //h2
          tagNFC, //h3
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
    }else{print('juz jest wpis = ${globals.dataAktualnegoPrzegladu}');}

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

    // print(globals.nowyNrRamki);
    //      print(nowyNrRamki);
    //      print(ramek);
    //     //ustawianie kolejnych numerów ramek - o 1 większych od poprzednich
    //     globals.nowyNrRamki < 10 ? nowyNrRamki = globals.nowyNrRamki + 1 : nowyNrRamki = globals.nowyNrRamki;
    //     globals.nowyNrRamkiPo < ramek ? nowyNrRamkiPo = globals.nowyNrRamkiPo + 1 : nowyNrRamkiPo = globals.nowyNrRamkiPo;
    //     print(globals.nowyNrRamki);
    //      print(nowyNrRamki);
    //      print(ramek);

    
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


                    SizedBox(
                        height: 10,
                      ),
                
//przyciski
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[

//chwilowa suma zasobów                                 
                                  //SizedBox(width: 10),
                                if(tryb == 'dodaj')  
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.rEsources + ' L'),
                                      OutlinedButton(
                                          style: buttonSumaZasobow,
                                          onPressed: null,
                                          child: Text('$sumaZasobowL'+'%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                  )]) ,  
                              
                             // ]),  
                              SizedBox(width: 12),
                              SizedBox(height: 10),


//zapisz
                          if(tryb == 'dodaj')
                            MaterialButton(
                              
                              height: 50,
                              shape: const StadiumBorder(
                                side: const BorderSide(color: Color.fromARGB(255, 162, 103, 0)),
                                ),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                 
                                 if(trutDodL > 0){zapisDoBazyL(1, trutDodL.toString(), 'dodaj');};
                                 if(czerwDodL > 0){zapisDoBazyL(2, czerwDodL.toString(), 'dodaj');};
                                 if(larwyDodL > 0){zapisDoBazyL(3, larwyDodL.toString(), 'dodaj');};
                                 if(jajaDodL > 0){zapisDoBazyL(4, jajaDodL.toString(), 'dodaj');};
                                 if(pierzgaDodL > 0){zapisDoBazyL(5, pierzgaDodL.toString(), 'dodaj');};
                                 if(miodDodL > 0){zapisDoBazyL(6, miodDodL.toString(), 'dodaj');};
                                 if(dojrzalyDodL > 0){zapisDoBazyL(7, dojrzalyDodL.toString(), 'dodaj');};
                                 if(wezaDodL > 0){zapisDoBazyL(8, wezaDodL.toString(), 'dodaj');};
                                 if(suszDodL > 0){zapisDoBazyL(9, suszDodL.toString(), 'dodaj');};
                                 if(matkaDodL > 0){zapisDoBazyL(10, matkaDodL.toString(), 'dodaj');};
                                 if(matecznikiDodL > 0){zapisDoBazyL(11, matecznikiDodL.toString(), 'dodaj');};
                                 if(usunmatDodL > 0){zapisDoBazyL(12, usunmatDodL.toString(), 'dodaj');}; 

                                if(trutDodP > 0){zapisDoBazyP(1, trutDodP.toString(), 'dodaj');};
                                 if(czerwDodP > 0){zapisDoBazyP(2, czerwDodP.toString(), 'dodaj');};
                                 if(larwyDodP > 0){zapisDoBazyP(3, larwyDodP.toString(), 'dodaj');};
                                 if(jajaDodP > 0){zapisDoBazyP(4, jajaDodP.toString(), 'dodaj');};
                                 if(pierzgaDodP > 0){zapisDoBazyP(5, pierzgaDodP.toString(), 'dodaj');};
                                 if(miodDodP > 0){zapisDoBazyP(6, miodDodP.toString(), 'dodaj');};
                                 if(dojrzalyDodP > 0){zapisDoBazyP(7, dojrzalyDodP.toString(), 'dodaj');};
                                 if(wezaDodP > 0){zapisDoBazyP(8, wezaDodP.toString(), 'dodaj');};
                                 if(suszDodP > 0){zapisDoBazyP(9, suszDodP.toString(), 'dodaj');};
                                 if(matkaDodP > 0){zapisDoBazyP(10, matkaDodP.toString(), 'dodaj');};
                                 if(matecznikiDodP > 0){zapisDoBazyP(11, matecznikiDodP.toString(), 'dodaj');};
                                 if(usunmatDodP > 0){zapisDoBazyP(12, usunmatDodP.toString(), 'dodaj');};

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
                  
     //chwilowa suma zasobów                                 
                                SizedBox(width: 12),
                                if(tryb == 'dodaj')  
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.rEsources + ' P'),
                                      OutlinedButton(
                                          style: buttonSumaZasobow,
                                          onPressed: null,
                                          child: Text('$sumaZasobowP'+'%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                  )]) ,  
                            

                              SizedBox(height: 10),             
                  
                  
                  
                  
                  ]),



//strona ramki
                            //   SizedBox(height: 5),
                            // if (nowyZasob! < 13)   
                            //   Row(
                            //     mainAxisAlignment: MainAxisAlignment.center,
                            //     crossAxisAlignment: CrossAxisAlignment.center,
                            //     children: <Widget>[
// //strona ramki
//                                   Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.center,
//                                     children: [
//                                       Text(AppLocalizations.of(context)!.sIteOfFrame),
//                                       ToggleButtons(
//                                         direction: Axis.horizontal, 
//                                         onPressed: (int index) {
//                                           setState(() {
//                                             // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
//                                             for (int i = 0; i < _selectedStronaRamki.length; i++) {
//                                               _selectedStronaRamki[i] = i == index;
//                                             }
//                                           });
//                                         },
//                                         borderRadius: const BorderRadius.all(Radius.circular(8)),
//                                         borderColor: Color.fromARGB(255, 162, 103, 0),
//                                         selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
//                                         selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
//                                         fillColor: Theme.of(context).primaryColor, //tło wybranego
//                                         color: Color.fromARGB(255, 78, 78, 78), //napis niewybranego
//                                         constraints: const BoxConstraints(
//                                           minHeight: 33.0,
//                                           minWidth: 65.0,
//                                         ),
//                                         isSelected: _selectedStronaRamki,
//                                         children: [ //napisy na przełącznikach
//                                           Text(AppLocalizations.of(context)!.left),
//                                           Text(AppLocalizations.of(context)!.both),
//                                           Text(AppLocalizations.of(context)!.right)
//                                         ],  //lewa, obie, prawa
//                                       ),                                  
//                                   ]),
  // //chwilowa suma zasobów                                 
  //                                 SizedBox(width: 10),
  //                               if(tryb == 'dodaj')  
  //                                 Column(
  //                                   mainAxisAlignment: MainAxisAlignment.center,
  //                                   crossAxisAlignment: CrossAxisAlignment.center,
  //                                   children: [
  //                                     Text(AppLocalizations.of(context)!.rEsources),
  //                                     OutlinedButton(
  //                                         style: buttonSumaZasobow,
  //                                         onPressed: null,
  //                                         child: Text('$sumaZasobowL'+'%',
  //                                           style: const TextStyle(
  //                                             fontWeight: FontWeight.bold,
  //                                             fontSize: 18,
  //                                             color: Color.fromARGB(255, 0, 0,0))),
  //                                 )]) ,  
                              
   //                           ]),  

                              SizedBox(height: 10),
 
//sekcja zasobów 1-12 częśc 1
                      if (nowyZasob! < 13)  
                        Column(       //??????
                          children:[   //??????
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//dojrzały                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfSealed, 7);
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
                                          dojrzalyDodL != 0 ? Text('$dojrzalyDodL' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.honeySealedN + ' ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasobP(AppLocalizations.of(context)!.aMountOfSealed, 7);
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
                                          dojrzalyDodP != 0 ? Text('$dojrzalyDodP' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.honeySealedN + ' ' ),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 

//miód
                              //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
// nakrop                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {_showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfHoney, 6);
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
                                          miodDodL != 0 ? Text('$miodDodL' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.hOney + ' ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasobP(AppLocalizations.of(context)!.aMountOfHoney, 6);
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
                                          miodDodP != 0 ? Text('$miodDodP' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(AppLocalizations.of(context)!.hOney , textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 

//pierzga
                              //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
// pierzga                               
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfPollen, 5);
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
                                          pierzgaDodL != 0 ? Text('$pierzgaDodL' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.pollen + ' ' ),
                                        ],   //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasobP(AppLocalizations.of(context)!.aMountOfPollen, 5);
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
                                          pierzgaDodP != 0 ? Text('$pierzgaDodP' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.pollen + ' ' ),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 
//jajka
                              //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//jajka                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfEggs, 4);
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
                                          jajaDodL != 0 ? Text('$jajaDodL' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.eggs + ' ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasobP(AppLocalizations.of(context)!.aMountOfEggs, 4);
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
                                          jajaDodP != 0 ? Text('$jajaDodP' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.eggs + ' ' ),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 

//larwy
                              //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//larwy                              
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfLarvae, 3);
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
                                          larwyDodL != 0 ? Text('$larwyDodL' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.larvae + ' ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasobP(AppLocalizations.of(context)!.aMountOfLarvae, 3);
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
                                          larwyDodP != 0 ? Text('$larwyDodP' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
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
//kryty                               
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfBrood, 2);
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
                                          czerwDodL != 0 ? Text('$czerwDodL' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(AppLocalizations.of(context)!.broodCoveredN, textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasobP(AppLocalizations.of(context)!.aMountOfBrood, 2);
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
                                          czerwDodP != 0 ? Text('$czerwDodP' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(AppLocalizations.of(context)!.broodCoveredN , textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]),  

                            ]),//kolumna przycisków zasobów
                                                             
                      //   ]),
                      // ),
//                       SizedBox(
//                         height: 10,
//                       ),
                
// //przyciski
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: <Widget>[

// //chwilowa suma zasobów                                 
//                                   //SizedBox(width: 10),
//                                 if(tryb == 'dodaj')  
//                                   Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.center,
//                                     children: [
//                                       Text(AppLocalizations.of(context)!.rEsources),
//                                       OutlinedButton(
//                                           style: buttonSumaZasobow,
//                                           onPressed: null,
//                                           child: Text('$sumaZasobowL'+'%',
//                                             style: const TextStyle(
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 18,
//                                               color: Color.fromARGB(255, 0, 0,0))),
//                                   )]) ,  
                              
//                              // ]),  

//                               SizedBox(height: 10),


// //zapisz
//                           if(tryb == 'dodaj')
//                             MaterialButton(
//                               shape: const StadiumBorder(),
//                               onPressed: () {
//                                 if (_formKey1.currentState!.validate()) {
                                 
//                                  if(trutDodL > 0){zapisDoBazyL(1, trutDodL.toString(), 'dodaj');};
//                                  if(czerwDodL > 0){zapisDoBazyL(2, czerwDodL.toString(), 'dodaj');};
//                                  if(larwyDodL > 0){zapisDoBazyL(3, larwyDodL.toString(), 'dodaj');};
//                                  if(jajaDodL > 0){zapisDoBazyL(4, jajaDodL.toString(), 'dodaj');};
//                                  if(pierzgaDodL > 0){zapisDoBazyL(5, pierzgaDodL.toString(), 'dodaj');};
//                                  if(miodDodL > 0){zapisDoBazyL(6, miodDodL.toString(), 'dodaj');};
//                                  if(dojrzalyDodL > 0){zapisDoBazyL(7, dojrzalyDodL.toString(), 'dodaj');};
//                                  if(wezaDodL > 0){zapisDoBazyL(8, wezaDodL.toString(), 'dodaj');};
//                                  if(suszDodL > 0){zapisDoBazyL(9, suszDodL.toString(), 'dodaj');};
//                                  if(matkaDodL > 0){zapisDoBazyL(10, matkaDodL.toString(), 'dodaj');};
//                                  if(matecznikiDodL > 0){zapisDoBazyL(11, matecznikiDodL.toString(), 'dodaj');};
//                                  if(usunmatDodL > 0){zapisDoBazyL(12, usunmatDodL.toString(), 'dodaj');}; 

//                                 if(trutDodP > 0){zapisDoBazyP(1, trutDodP.toString(), 'dodaj');};
//                                  if(czerwDodP > 0){zapisDoBazyP(2, czerwDodP.toString(), 'dodaj');};
//                                  if(larwyDodP > 0){zapisDoBazyP(3, larwyDodP.toString(), 'dodaj');};
//                                  if(jajaDodP > 0){zapisDoBazyP(4, jajaDodP.toString(), 'dodaj');};
//                                  if(pierzgaDodP > 0){zapisDoBazyP(5, pierzgaDodP.toString(), 'dodaj');};
//                                  if(miodDodP > 0){zapisDoBazyP(6, miodDodP.toString(), 'dodaj');};
//                                  if(dojrzalyDodP > 0){zapisDoBazyP(7, dojrzalyDodP.toString(), 'dodaj');};
//                                  if(wezaDodP > 0){zapisDoBazyP(8, wezaDodP.toString(), 'dodaj');};
//                                  if(suszDodP > 0){zapisDoBazyP(9, suszDodP.toString(), 'dodaj');};
//                                  if(matkaDodP > 0){zapisDoBazyP(10, matkaDodP.toString(), 'dodaj');};
//                                  if(matecznikiDodP > 0){zapisDoBazyP(11, matecznikiDodP.toString(), 'dodaj');};
//                                  if(usunmatDodP > 0){zapisDoBazyP(12, usunmatDodP.toString(), 'dodaj');};

//                                   //zapisDoBazy(nowyZasob!, nowaWartosc, 'dodaj');
//                                   Provider.of<Frames>(context, listen: false)
//                                     .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
//                                     .then((_) {
//                                       //jezeli była to jakaś ramka "przed" i było to dodawanie jednej ramki a nie wielu
//                                       if(nowyNrRamki != 0 && _selectedZakresRamek[0]){//zeby mogło być kilka ramek nowych wstawianych do ula
//                                         //dla wszystkich zasobów dla ramki z numerem "nowyNrRamki" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
//                                         final framesData1 = Provider.of<Frames>(context, listen: false);
//                                         //zasoby tej ramki (z wybranej daty dla ula i tylko w wybranym korpusie)
//                                         List<Frame> frames = framesData1.items.where((fr) {
//                                           return fr.ramkaNr == nowyNrRamki && fr.data == globals.dataWpisu && fr.korpusNr == nowyNrKorpusu; //return fr.data.contains('2024-04-04');
//                                         }).toList();
//                                         //dla kazdego zasobu modyfikacja ramkaNrPo
//                                         for (var i = 0; i < frames.length; i++) {
//                                           //print('ramka: ${frames[i].ramkaNr} zasób: ${frames[i].zasob}');
//                                           DBHelper.updateRamkaNrPo(frames[i].id, nowyNrRamkiPo!);
//                                         }
//                                       }
//                                       Provider.of<Frames>(context, listen: false)
//                                         .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
//                                         .then((_) {
//                                         Navigator.of(context).pop();
//                                       });
//                                   });
//                                 }
//                                 ;
//                               },
//                               child: Text('   ' +
//                                   (AppLocalizations.of(context)!.saveZ) +
//                                   '   '), //Zapisz
//                               color: Theme.of(context).primaryColor,
//                               textColor: Colors.white,
//                               disabledColor: Colors.grey,
//                               disabledTextColor: Colors.white,
//                             ),
                  
//      //chwilowa suma zasobów                                 
//                                   SizedBox(width: 10),
//                                 if(tryb == 'dodaj')  
//                                   Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.center,
//                                     children: [
//                                       Text(AppLocalizations.of(context)!.rEsources),
//                                       OutlinedButton(
//                                           style: buttonSumaZasobow,
//                                           onPressed: null,
//                                           child: Text('$sumaZasobowL'+'%',
//                                             style: const TextStyle(
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 18,
//                                               color: Color.fromARGB(255, 0, 0,0))),
//                                   )]) ,  
                            

//                               SizedBox(height: 10),             
                  
                  
                  
                  
//                   ]),
                    
//sekcja zasobów 1-12 częśc 1
                      if (nowyZasob! < 13)  
                        Column(       //??????
                          children:[   //??????
                            // SizedBox(
                            //   height: 10,
                            // ),
//matka
                              //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//matka                               
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertKolorL(AppLocalizations.of(context)!.cOolorOfMother, 10);
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
                                          _showAlertKolorP(AppLocalizations.of(context)!.cOolorOfMother, 10);
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
                                          matkaKolorP,
                                          Text(' ' + AppLocalizations.of(context)!.queen + ' ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]),     
 //węza                              
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//węza                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfWax, 8);
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
                                          wezaDodL != 0 ? Text('$wezaDodL' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.waxFundationN + ' ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasobP(AppLocalizations.of(context)!.aMountOfWax, 8);
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
                                          wezaDodP != 0 ? Text('$wezaDodP' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.waxFundationN + ' ' ),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 

 // susz                             
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//susz                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfComb, 9);
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
                                          suszDodL != 0 ? Text('$suszDodL' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.waxCombN + ' ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasobP(AppLocalizations.of(context)!.aMountOfComb, 9);
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
                                          suszDodP != 0 ? Text('$suszDodP' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.waxCombN + ' ' ),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]),                         
                         

//trutowy
                              //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//trutowy                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasob(AppLocalizations.of(context)!.aMountOfDrone, 1);
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
                                          trutDodL != 0 ? Text('$trutDodL' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(AppLocalizations.of(context)!.droneN, textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertDodajZasobP(AppLocalizations.of(context)!.aMountOfDrone, 1);
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
                                          trutDodP != 0 ? Text('$trutDodP' + '%', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(AppLocalizations.of(context)!.droneN , textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 


//usunięte mateczniki 
                             //SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
// usunięte mateczniki                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertNr(AppLocalizations.of(context)!.nUmberOfCellsRemoved, 12); //maksymalna ilość mateczników taka jak ilość ramek (? tymczasowo - mozna zmienić ale trzeba tworzyć dodatkowe okno dialogowe dla ilosci mateczników)
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
                                          usunmatDodL != 0 ? Text('$usunmatDodL' + ' szt.', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text('  ' + AppLocalizations.of(context)!.deleteQueenCellsN + '  ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertNr(AppLocalizations.of(context)!.nUmberOfCellsRemoved, 112);
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
                                          usunmatDodP != 0 ? Text('$usunmatDodP' + ' szt.', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text('  ' + AppLocalizations.of(context)!.deleteQueenCellsN + '  ' , textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]), 

//mateczniki
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//mateczniki                                
                                      ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertNr(AppLocalizations.of(context)!.nUmberOfQueenCells, 11); //maksymalna ilość mateczników taka jak ilość ramek (? tymczasowo - mozna zmienić ale trzeba tworzyć dodatkowe okno dialogowe dla ilosci mateczników)
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
                                          matecznikiDodL != 0 ? Text('$matecznikiDodL' + ' szt.', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.queenCells + '  ', textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                               SizedBox(width: 10),
                               ToggleButtons(                                     
                                        direction: Axis.horizontal, 
                                        onPressed: (int index) {
                                          _showAlertNr(AppLocalizations.of(context)!.nUmberOfQueenCells, 111); //inny numer "przycisk" dla prawej strony
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
                                          matecznikiDodP != 0 ? Text('$matecznikiDodP' + ' szt.', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(''),
                                          Text(' ' + AppLocalizations.of(context)!.queenCells + '  ' , textAlign: TextAlign.center),
                                        ],  //lewa, obie, prawa
                                      ),
                              ]),                           
                              SizedBox(height: 20),
                          ]),  
                    
                         
                        ]),
                      ),
                    ]),
                    )));
  }
}

