
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
import '../screens/frames_screen.dart';
import '../screens/infos_screen.dart';
// import 'package:flutter/services.dart';


class FrameMoveScreen extends StatefulWidget {
  static const routeName = '/frame_move';
  
  
    @override
    State<FrameMoveScreen> createState() => _FrameMoveScreenState();
  }

class _FrameMoveScreenState extends State<FrameMoveScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');
  bool _isInit = true;
  var formatterHm = new DateFormat('H:mm');
  int? nrPasieki;
  int _sourceUl = 1; // zapamiętany numer ula źródłowego do przywracania kontekstu
  // int? nrUlaZ;
  // int? nrUlaDo;
  // int? nrKorpusuZ;
  // int? nrKorpusuDo;
  // int? nrRamkiZ;//przed  przeglądem
  // int? nrRamkiDo; //po przeglądzie
  int korpus = 2;//1-półkorpus, 2-korpus
  List<bool> _selectedKorpus = <bool>[false, true]; // pół|cały
  int rozmiarRamki = 2;//1-mała, 2-duza
  int stronaRamki = 1; //0-obie, 1-lewa, 2-prawa
  int numeryWieluRamek = 1;// 0- xx/0 po=0, 1- xx/xx przed=po, 2- 0/xx przed=0
  int? nowyZasob;
  String nowaWartosc = '0';

  List<Frame> ramka = [];
  List<Hive> hiveZ = [];
  List<Hive> hiveDo = [];
  TextEditingController dateController = TextEditingController();
  
  int dzielnik = 2; //do ustawiania proporcji klawiszy klawiatur numeru ramki i ilości zasobów

  //dla hive
  String ikona = 'green'; //pobierana z aktualnego ula
  int ramekZ = 10; //ilośc ramek w ulu Z którego przenoszona jest ramka
  int ramekDo = 10; //ilośc ramek w ulu Do którego przenoszona jest ramka
  int korpusNr = 0;
  
  List<int> gridItemsZ = [];//tworzona lista klawiszy klawiatury wyboru numeru ramki Z
   List<int> gridItemsDo = [];//tworzona lista klawiszy klawiatury wyboru numeru ramki Do
  List<int> gridItemsKorpus = [1,2,3,4,5,6,7,8,9]; //lista klawiszy klawiatury wyboru numeru korpusu
  List<int> gridItemsHive = [];//tworzona lista klawiszy klawiatury wyboru numeru ula
  int nrPasiekiDo = 1; // numer pasieki docelowej
  List<int> gridItemsApiary = []; // numery pasiek do klawiatury wyboru
  List<int> gridItemsHiveDo = []; // numery uli w pasiece docelowej
  List<int> availableKorpusyZ = []; // dostępne korpusy źródłowe (z danymi)
  List<int> availableRamkiZ = []; // dostępne ramki w wybranym korpusie źródłowym


  
  
  @override
  void didChangeDependencies() {
    if (_isInit) {
      //print('na poczatek didChangeDependencies: nowyZasobId  = ${dateController.text}');
      final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
      //final idRamki = routeArgs['idRamki']; //pobiera z frames_detail_item.dart
      final idPasieki = routeArgs['idPasieki'];
      final idUla = routeArgs['idUla'];
      final idZasobu = routeArgs['idZasobu'];
      final idKorpusu = routeArgs['idKorpusu'];
      final idRamki = routeArgs['idRamki'];
      final idData = routeArgs['idData'];
      //print('ramka = $idRamki, pasieka = $idPasieki , ul = $idUla');


        //jezeli dodanie nowego wpisu (tylko dla aktualnie wybranej pasieki i ula)
        dateController.text = '$idData'; //data przeglądu z kontekstu nawigacji
        // nowyRok = DateFormat('yyyy').format(DateTime.now());
        // nowyMiesiac = DateFormat('MM').format(DateTime.now());
        // nowyDzien = DateFormat('dd').format(DateTime.now());
        nrPasieki = int.parse('$idPasieki');
        globals.nrUlaPrzeniesZ = int.parse('$idUla');
        _sourceUl = int.parse('$idUla');
        globals.nrUlaPrzeniesDo = int.parse('$idUla');
        globals.nrKorpusuPrzeniesZ = int.parse('$idKorpusu');
        globals.nrKorpusuPrzeniesDo = int.parse('$idKorpusu');
        globals.nrRamkiPrzeniesZ = int.parse('$idRamki');
        globals.nrRamkiPrzeniesDo = int.parse('$idRamki');
        korpus = globals.korpus;
        korpus == 1 ? _selectedKorpus[0] = true : _selectedKorpus[0] = false;
        korpus == 2 ? _selectedKorpus[1] = true : _selectedKorpus[1] = false;
        // nrUlaDo = nrUlaZ;
        // nrKorpusuDo = nrKorpusuZ;
        rozmiarRamki = globals.rozmiarRamki;
        stronaRamki = globals.stronaRamki;
       
        nowyZasob = int.parse('$idZasobu'); //id zasobu z pola dialogowego "Wybierz rodzaj wpisu" (po przycisnięciu "+" u góry ekranu) - decyduje o rodzaju wpisu (zasób na ramce, toDo czy isDone)
        //tempZasob = nowyZasob;
        nowaWartosc = '1'; //wartość dla toDo i isDone ustawiana dalej...
        //tempNowaWartosc = nowaWartosc;

        //inicjalizacja pasieki docelowej (na start ta sama co źródłowa)
        nrPasiekiDo = nrPasieki!;
        globals.nrPasiekiPrzeniesDo = nrPasieki!;

      //pobranie listy pasiek do klawiatury wyboru pasieki docelowej
      Provider.of<Apiarys>(context, listen: false).fetchAndSetApiarys()
            .then((_) {
        final apiaryData = Provider.of<Apiarys>(context, listen: false);
        gridItemsApiary = [];
        for(int i = 0; i < apiaryData.items.length; i++){
          gridItemsApiary.add(apiaryData.items[i].pasiekaNr);
        }
      });

      //pobranie danych o ulach z wybranej pasieki
      Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrPasieki)
            .then((_) {
       final hiveData = Provider.of<Hives>(context, listen: false);

        //dane ula Z którego przenosimy
        hiveZ = hiveData.items.where((element) {
          return element.id == ('$nrPasieki.${globals.nrUlaPrzeniesZ}');
        }).toList();
        //liczba ramek w ulu z którego przenosimy
        ramekZ = hiveZ[0].ramek;
        //utworzenie klwiatury wyboru numeru ramki Z
        gridItemsZ=[];
        for(int i = 1; i <= ramekZ; i++){
          gridItemsZ.add(i);
        // print('i = ${gridItems}');
        }

        //dane ula Do którego przenosimy
        hiveDo = hiveData.items.where((element) {
          return element.id == ('$nrPasieki.${globals.nrUlaPrzeniesDo}');
        }).toList();
        //liczba ramek w ulu Do którego przenosimy
        ramekDo = hiveDo[0].ramek;
        //utworzenie klwiatury wyboru numeru ramki Do
        gridItemsDo=[];
        for(int i = 1; i <= ramekDo; i++){
          gridItemsDo.add(i);
        // print('i = ${gridItems}');
        }

        //numery uli w pasiece
        for(int i = 0; i < hiveData.items.length; i++){
          gridItemsHive.add(hiveData.items[i].ulNr);
        //  print('i = ${hiveData.items[i].ulNr}');
        //  print('length = ${hiveData.items.length}');
        }

        //na start pasieka docelowa = źródłowa, więc numery uli takie same
        gridItemsHiveDo = [...gridItemsHive];

      });

      // Pobranie dostępnych korpusów i ramek z danymi
      _refreshSourceData();

      // Ustawienie daty docelowej na ostatni przegląd ula docelowego
      _updateTargetDate(nrPasiekiDo, globals.nrUlaPrzeniesDo);

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

  // Pobranie ostatniej daty przeglądu dla ula docelowego
  void _updateTargetDate(int pasiekaDo, int ulDo) {
    Provider.of<Infos>(context, listen: false)
      .fetchAndSetInfosForHive(pasiekaDo, ulDo)
      .then((_) {
        if (!mounted) return;
        final infoData = Provider.of<Infos>(context, listen: false);
        List<Info> inspections = infoData.items.where((element) {
          return element.kategoria == 'inspection';
        }).toList();

        setState(() {
          if (inspections.isNotEmpty) {
            inspections.sort((a, b) => b.data.compareTo(a.data));
            globals.dataPrzeniesRamke = inspections[0].data;
          } else {
            globals.dataPrzeniesRamke = DateTime.now().toString().substring(0, 10);
          }
        });
      });
  }

  // Odświeżenie dostępnych korpusów i ramek źródłowych
  void _refreshSourceData() {
    Provider.of<Frames>(context, listen: false)
      .fetchAndSetFramesForHive(nrPasieki, globals.nrUlaPrzeniesZ)
      .then((_) {
        final framesData = Provider.of<Frames>(context, listen: false);
        // Ramki dostępne do przeniesienia: mają dane na tę datę, ramkaNr > 0, ramkaNrPo != 0
        List<Frame> availableFrames = framesData.items.where((fr) {
          return fr.data == dateController.text && fr.ramkaNr > 0 && fr.ramkaNrPo != 0;
        }).toList();

        // Unikalne numery korpusów
        Set<int> bodies = {};
        for (var fr in availableFrames) {
          bodies.add(fr.korpusNr);
        }

        setState(() {
          availableKorpusyZ = bodies.toList()..sort();

          if (availableKorpusyZ.isNotEmpty && !availableKorpusyZ.contains(globals.nrKorpusuPrzeniesZ)) {
            globals.nrKorpusuPrzeniesZ = availableKorpusyZ[0];
          }

          _updateAvailableRamkiZ();
        });
      });
  }

  // Aktualizacja dostępnych ramek źródłowych po zmianie korpusu
  void _updateAvailableRamkiZ() {
    final framesData = Provider.of<Frames>(context, listen: false);
    List<Frame> availableFrames = framesData.items.where((fr) {
      return fr.data == dateController.text && fr.ramkaNr > 0 && fr.ramkaNrPo != 0
          && fr.korpusNr == globals.nrKorpusuPrzeniesZ;
    }).toList();

    Set<int> frameNrs = {};
    for (var fr in availableFrames) {
      frameNrs.add(fr.ramkaNr);
    }

    availableRamkiZ = frameNrs.toList()..sort();

    if (availableRamkiZ.isNotEmpty && !availableRamkiZ.contains(globals.nrRamkiPrzeniesZ)) {
      globals.nrRamkiPrzeniesZ = availableRamkiZ[0];
    }
  }

  //wybór numeru ramki
  void _showAlertNr(String wybor, List<int> gridItems, int przycisk) {
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
              height: 355,
              width: 300,
              child:GridView.count(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(15.0),
                crossAxisCount: 3, //ilość kolumn
                childAspectRatio: (3 / dzielnik), //proporcje boków kafli
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: gridItems //Z lub Do w zalezności od argumentu wywołania funkcji
                  .map((data) => InkWell(
                    onTap: () {
                      switch (przycisk) {
                        case 1:
                          setState(() {
                            globals.nrRamkiPrzeniesZ = data;
                          });
                          break;
                        case 2:
                          setState(() {
                            globals.nrRamkiPrzeniesDo = data;
                          });
                          break;                         
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
  void _showAlertNrKorpusu(String wybor, int przycisk, List<int> items) {
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
                children: items
                  .map((data) => InkWell(
                    onTap: () {
                       switch (przycisk) {
                        case 1:
                          setState(() {
                            globals.nrKorpusuPrzeniesZ = data;
                            _updateAvailableRamkiZ();
                          });
                          break;
                        case 2:
                          setState(() {
                            globals.nrKorpusuPrzeniesDo = data;
                          });
                          break;                         
                        default:
                      }
                 
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

  //wybór numeru pasieki docelowej
  void _showAlertNrPasieki(String wybor) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(wybor,textAlign: TextAlign.center,),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 355,
              width: 300,
              child:GridView.count(
                shrinkWrap: true,
                padding: const EdgeInsets.all(15.0),
                crossAxisCount: 3,
                childAspectRatio: (3 / dzielnik),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: gridItemsApiary
                  .map((data) => InkWell(
                    onTap: () {
                      setState(() {
                        nrPasiekiDo = data;
                        globals.nrPasiekiPrzeniesDo = data;
                      });
                      Navigator.of(dialogContext).pop(true);
                      //pobranie uli nowej pasieki docelowej
                      Provider.of<Hives>(context, listen: false).fetchAndSetHives(data)
                            .then((_) {
                        if (!mounted) return;
                        final hiveData = Provider.of<Hives>(context, listen: false);
                        setState(() {
                          //przebudowanie listy uli w pasiece docelowej
                          gridItemsHiveDo = [];
                          for(int i = 0; i < hiveData.items.length; i++){
                            gridItemsHiveDo.add(hiveData.items[i].ulNr);
                          }
                          //ustawienie domyślnego ula docelowego na pierwszy w nowej pasiece
                          if(gridItemsHiveDo.isNotEmpty){
                            globals.nrUlaPrzeniesDo = gridItemsHiveDo[0];
                            //dane ula Do którego przenosimy
                            hiveDo = hiveData.items.where((element) {
                              return element.id == ('$data.${globals.nrUlaPrzeniesDo}');
                            }).toList();
                            //liczba ramek w ulu Do którego przenosimy
                            ramekDo = hiveDo[0].ramek;
                            //utworzenie klawiatury wyboru numeru ramki Do
                            gridItemsDo = [];
                            for(int i = 1; i <= ramekDo; i++){
                              gridItemsDo.add(i);
                            }
                          }
                        });
                        // Aktualizacja daty docelowej dla nowego ula
                        if(gridItemsHiveDo.isNotEmpty){
                          _updateTargetDate(data, globals.nrUlaPrzeniesDo);
                        }
                      });
                    },
                    splashColor: Theme.of(dialogContext).primaryColor,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(dialogContext).primaryColor.withValues(alpha:0.7),
                            Theme.of(dialogContext).primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('$data',
                          style: TextStyle(
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
              Navigator.of(dialogContext).pop();
            },
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
      barrierDismissible: false,
    );
  }

  //wybór numeru ula
  void _showAlertNrUla(String wybor, int przycisk, List<int> gridItemsUl) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(wybor,textAlign: TextAlign.center,),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min, //okno ściśniete w pionie
          children: <Widget>[
            SizedBox(
              height: 355,
              width: 300,
              child:GridView.count(
                //physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(15.0),
                crossAxisCount: 3, //ilość kolumn
                childAspectRatio: (3 / dzielnik), //proporcje boków kafli
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: gridItemsUl //lista numerów ula
                  .map((data) => InkWell(
                    onTap: () {
                       switch (przycisk) {
                        case 1:
                          setState(() {
                            globals.nrUlaPrzeniesZ = data;
                          });
                          Navigator.of(dialogContext).pop(true);
                          //pobranie danych o ulach z wybranej pasieki
                          Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrPasieki)
                                .then((_) {
                            if (!mounted) return;
                            final hiveData = Provider.of<Hives>(context, listen: false);
                            setState(() {
                              //dane ula Z którego przenosimy
                              hiveZ = hiveData.items.where((element) {
                                return element.id == ('$nrPasieki.${globals.nrUlaPrzeniesZ}');
                              }).toList();
                              //liczba ramek w ulu Z którego przenosimy
                              ramekZ = hiveZ[0].ramek;
                              //utworzenie klwiatury wyboru numeru ramki Z
                              gridItemsZ=[];
                              for(int i = 1; i <= ramekZ; i++){
                                gridItemsZ.add(i);
                              }
                            });
                          });
                          return; // nie wykonuj dalszego kodu po switch
                        case 2:
                          setState(() {
                            globals.nrUlaPrzeniesDo = data;
                          });
                          Navigator.of(dialogContext).pop(true);
                          //pobranie danych o ulach z pasieki docelowej
                          Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrPasiekiDo)
                                .then((_) {
                            if (!mounted) return;
                            final hiveData = Provider.of<Hives>(context, listen: false);
                            setState(() {
                              //dane ula Do którego przenosimy
                              hiveDo = hiveData.items.where((element) {
                                return element.id == ('$nrPasiekiDo.${globals.nrUlaPrzeniesDo}');
                              }).toList();
                              //liczba ramek w ulu Do którego przenosimy
                              ramekDo = hiveDo[0].ramek;
                              //utworzenie klwiatury wyboru numeru ramki Do
                              gridItemsDo=[];
                              for(int i = 1; i <= ramekDo; i++){
                                gridItemsDo.add(i);
                              }
                            });
                            // Aktualizacja daty docelowej dla nowego ula
                            _updateTargetDate(nrPasiekiDo, globals.nrUlaPrzeniesDo);
                          });
                          return; // nie wykonuj dalszego kodu po switch
                        default:
                      }
                      Navigator.of(dialogContext).pop(true);
                    },
                    splashColor: Theme.of(dialogContext).primaryColor,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(dialogContext).primaryColor.withValues(alpha:0.7),
                            Theme.of(dialogContext).primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        //color: Theme.of(dialogContext).primaryColor,
                      ),
                      //margin:EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                      //color: Theme.of(dialogContext).primaryColor,
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
              Navigator.of(dialogContext).pop();
            },
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
      barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  // Przywrócenie danych providerów dla źródłowej pasieki/ula i nawigacja wstecz
  void _restoreAndPop({bool afterSave = false}) {
    Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrPasieki).then((_) {
      Provider.of<Infos>(context, listen: false)
        .fetchAndSetInfosForHive(nrPasieki!, _sourceUl).then((_) {
          Provider.of<Frames>(context, listen: false)
            .fetchAndSetFramesForHive(nrPasieki!, _sourceUl).then((_) {
              if (!mounted) return;
              if (afterSave) {
                // Sprawdź czy są jeszcze jakiekolwiek ramki dla tego ula (na dowolną datę)
                final framesData = Provider.of<Frames>(context, listen: false);
                bool hasAnyFrames = framesData.items.any((fr) => fr.ramkaNr > 0 && fr.ramkaNrPo != 0);
                if (hasAnyFrames) {
                  Navigator.of(context).popUntil(ModalRoute.withName(FramesScreen.routeName));
                } else {
                  Navigator.of(context).popUntil(ModalRoute.withName(InfoScreen.routeName));
                }
              } else {
                // Zwykły powrót (przycisk wstecz)
                Navigator.of(context).popUntil(ModalRoute.withName(FramesScreen.routeName));
              }
            });
        });
    });
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
    );
    final ButtonStyle disabledDateStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(2.0),
      backgroundColor: Color.fromARGB(255, 211, 211, 211),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(126.0, 35.0),
    );
//print(dateController.text );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _restoreAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => _restoreAndPop(),
          ),
          title: Text(
            AppLocalizations.of(context)!.mOvingFrame + ' (' + AppLocalizations.of(context)!.apiary + ' $nrPasieki)',
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

// przenieś ramkę z:
                              //SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
 
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.mOveFrameFrom,
                                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color.fromARGB(255, 0, 0, 0))
                                      ),
                                    ]
                                )]
                              ),



                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
  //data przegladu - nieaktywny przycisk
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.inspectionDate),
                                      OutlinedButton(
                                        style: disabledDateStyle,
                                        onPressed: null,
                                        child: Text(dateController.text,
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontSize: 15)),
                                      ),
                                  ]),

  //pasieka/ul - nieaktywny przycisk
                                  SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.aPiary + ' / ' + AppLocalizations.of(context)!.hIve),
                                      OutlinedButton(
                                        style: buttonPasiekaUlStyle,
                                        onPressed: null,
                                        child: Text('$nrPasieki/${globals.nrUlaPrzeniesZ}',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            color: Color.fromARGB(255, 0, 0,0))),
                                      ),
                                  ]),

                                ],
                              ),


                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                //mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[ 
                
//korpus                               
                                SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.bOdy),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: availableKorpusyZ.isNotEmpty ? () {_showAlertNrKorpusu(AppLocalizations.of(context)!.bOdyNumber, 1, availableKorpusyZ);} : null,
                                          child: Text('${globals.nrKorpusuPrzeniesZ}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                        )])  ,

//ramka do przeniesienia
                                SizedBox(width: 10),

                                Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.fRame),
                                      OutlinedButton(
                                            style: buttonStyle,
                                            onPressed: availableRamkiZ.isNotEmpty ? () {_showAlertNr(AppLocalizations.of(context)!.frameNumberBefore, availableRamkiZ, 1);} : null,
                                            child: Text('${globals.nrRamkiPrzeniesZ}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Color.fromARGB(255, 0, 0,0))),
                                          )])
                                                           
                                
                                ],
                              ),


 
 
 
 // przenieś ramkę do:
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
 
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.mOveFrameTo,
                                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color.fromARGB(255, 0, 0, 0))
                                      ),
                                    ]
                                )]
                              ),



//miejsce docelowe po przeniesieniu - wiersz 1: data + pasieka
                            SizedBox(height: 5),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
 //data przegladu ula docelowgo
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
                                              initialDate: DateTime.parse(globals.dataPrzeniesRamke),
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
                                              //dateController.text = formattedDate;
                                              globals.dataPrzeniesRamke = formattedDate;
                                            });
                                          } else {print("Date is not selected");}
                                        },

                                         child: Text(globals.dataPrzeniesRamke  ,
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontSize: 15),),
                                      ),
                                  ]),

  //pasieka docelowa
                                  SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.aPiary),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: () {_showAlertNrPasieki(AppLocalizations.of(context)!.apiaryNr);},
                                          child: Text('$nrPasiekiDo',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                        )])  ,

                              ]),

//miejsce docelowe - wiersz 2: ul + korpus
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
  //ul  docelowy

                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.hIve),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: () {_showAlertNrUla(AppLocalizations.of(context)!.hIveNr, 2, gridItemsHiveDo); },
                                          child: Text('${globals.nrUlaPrzeniesDo}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                        )])  ,
 //korpus   docelowy

                                  SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.bOdy),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: () {_showAlertNrKorpusu(AppLocalizations.of(context)!.bOdyNumber, 2, gridItemsKorpus);},
                                          child: Text('${globals.nrKorpusuPrzeniesDo}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                        )])  ,

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
                                            //ustawienie zmiennej "korpus" jeszcze przed zapisem zeby ustawienie nie znikło jezeli nie będze zapisane
                                            if(_selectedKorpus[0] == true){ //[0]==true to półkorpus; [0]==false to korpus
                                              korpus = 1; globals.korpus = 1;   
                                            }else { 
                                              korpus = 2; globals.korpus = 2;
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
//miejse docelowe ramki
                                SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.fRame),
                                      OutlinedButton(
                                            style: buttonStyle,
                                            onPressed: () {_showAlertNr(AppLocalizations.of(context)!.frameNumberAfter, gridItemsDo, 2);},
                                            child: Text('${globals.nrRamkiPrzeniesDo}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Color.fromARGB(255, 0, 0,0))),
                                          )])

                              ]),
                                            
                       
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


//zapisz
                         
                            MaterialButton(
                              height: 50,
                              shape: const StadiumBorder(
                                side: const BorderSide(color: Color.fromARGB(255, 162, 103, 0)),
                                ),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                //  print('data = ${dateController.text}');
                                //  print('nrPasieki = $nrPasieki, nrUlaZ = ${globals.nrUlaPrzeniesZ}, nrUlaDo = ${globals.nrUlaPrzeniesDo}, nrKorpusuZ = ${globals.nrKorpusuPrzeniesZ}, nrKorpusuDo = ${globals.nrKorpusuPrzeniesDo}');
                                //  print (' nrRamkiZ = ${globals.nrRamkiPrzeniesZ}, nrRamkiDo = ${globals.nrRamkiPrzeniesDo}; korpus = $korpus');
                                 
                                  //przeniesienie ramki do innego korpusu/ula/pasieki
                                  Provider.of<Frames>(context, listen: false)
                                    .fetchAndSetFramesForHive(nrPasieki, globals.nrUlaPrzeniesZ)
                                    .then((_) {
                                      //dla wszystkich zasobów wykonanie kopii ramki i zmiana "przed", "po", korpusu i ewentualnie ula
                                      final framesData1 = Provider.of<Frames>(context, listen: false);
                                        //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu)
                                      List<Frame> frames = framesData1.items.where((fr) {
                                        return fr.ramkaNr == globals.nrRamkiPrzeniesZ && fr.data == dateController.text  && fr.korpusNr == globals.nrKorpusuPrzeniesZ; //return fr.data.contains('2024-04-04');
                                      }).toList();
                                        //print('frames.length = ${frames.length}');
                                        //dla kazdego zasobu - zapis z innym id oraz modyfikacja ramkaNr, ramkaNrPo, korpusNr i ewentualnie ulNr
                                      for (var i = 0; i < frames.length; i++) {
                                        //print('frames[i].zasob = ${frames[i].zasob}');
                                        if(frames[i].zasob != 14){ //jezeli zasób jest rózny od "isDone" czyli prawdopodobnie nie jest = "usuń ramka"
                                          Frames.insertFrame(
                                            '${globals.dataPrzeniesRamke}.$nrPasiekiDo.${globals.nrUlaPrzeniesDo}.${globals.nrKorpusuPrzeniesDo}.0.${globals.nrRamkiPrzeniesDo}.${frames[i].strona}.${frames[i].zasob}',
                                            globals.dataPrzeniesRamke,
                                            nrPasiekiDo,
                                            globals.nrUlaPrzeniesDo,
                                            globals.nrKorpusuPrzeniesDo,
                                            korpus,//2-korpus, 1-półkorpus
                                            0,//ramkaNr przed (0 bo jest wstawiana)
                                            globals.nrRamkiPrzeniesDo, //ramkaNrPo
                                            frames[i].rozmiar,
                                            frames[i].strona,
                                            frames[i].zasob,
                                            frames[i].wartosc,
                                            0);

                                            //ramkaPo zmienić na 0 bo zostaje usunieta z obecnego miejsca
                                            DBHelper.updateRamkaNrPo(frames[i].id, 0);
                                        }
                                        else{ //więc jezeli jest "usuń ramka" to zamień na "wstaw ramka"
                                          Frames.insertFrame(
                                              '${globals.dataPrzeniesRamke}.$nrPasiekiDo.${globals.nrUlaPrzeniesDo}.${globals.nrKorpusuPrzeniesDo}.0.${globals.nrRamkiPrzeniesDo}.${frames[i].strona}.${frames[i].zasob}',
                                              globals.dataPrzeniesRamke,
                                              nrPasiekiDo,
                                              globals.nrUlaPrzeniesDo,
                                              globals.nrKorpusuPrzeniesDo,
                                              korpus,//2-korpus, 1-półkorpus
                                              0,//ramkaNr
                                              globals.nrRamkiPrzeniesDo, //ramkaNrPo
                                              frames[i].rozmiar,
                                              frames[i].strona,
                                              frames[i].zasob,
                                              AppLocalizations.of(context)!.inserted, //wstaw ramka
                                              0);

                                              //ramkaPo zmienić na 0 bo zostaje usunieta z obecnego miejsca
                                              DBHelper.updateRamkaNrPo(frames[i].id, 0);
                                        }
                                      }
                                      //poniewaz moze nie być "zasob == 14"  czyli "usun ramka", na wszelki wypadek zapis:
                                      if (frames.isNotEmpty) {
                                      //"wstaw ramka" dla ramki Do
                                      Frames.insertFrame(
                                              '${globals.dataPrzeniesRamke}.$nrPasiekiDo.${globals.nrUlaPrzeniesDo}.${globals.nrKorpusuPrzeniesDo}.0.${globals.nrRamkiPrzeniesDo}.1.14',
                                              globals.dataPrzeniesRamke,
                                              nrPasiekiDo,
                                              globals.nrUlaPrzeniesDo,
                                              globals.nrKorpusuPrzeniesDo,
                                              korpus,//2-korpus, 1-półkorpus  rozmiar ramki Do
                                              0,//ramkaNr
                                              globals.nrRamkiPrzeniesDo, //ramkaNrPo
                                              frames[0].rozmiar,//rozmiar ramki Z
                                              1,
                                              14,
                                              AppLocalizations.of(context)!.inserted, //wstaw ramka
                                              0);
                                      // i "usuń ramka" dla ramki Z (zostaje w źródłowej pasiece)
                                      Frames.insertFrame(
                                              '${dateController.text}.$nrPasieki.${globals.nrUlaPrzeniesZ}.${globals.nrKorpusuPrzeniesZ}.0.${globals.nrRamkiPrzeniesZ}.1.14',
                                              dateController.text,
                                              nrPasieki!,
                                              globals.nrUlaPrzeniesZ,
                                              globals.nrKorpusuPrzeniesZ,
                                              frames[0].typ,//2-korpus, 1-półkorpus  rozmiar ramki Z
                                              globals.nrRamkiPrzeniesZ,//ramkaNr
                                              0, //ramkaNrPo
                                              frames[0].rozmiar,//rozmiar ramki Z
                                              1,
                                              14,
                                              AppLocalizations.of(context)!.deleted, //usuń ramka
                                              0);
                                      } // if (frames.isNotEmpty)

                                      //sprawdzenie czy w docelowym ulu istnieje przegląd z wybraną datą
                                      //jeśli nie - automatyczne utworzenie wpisu inspection
                                      Provider.of<Infos>(context, listen: false)
                                        .fetchAndSetInfosForHive(nrPasiekiDo, globals.nrUlaPrzeniesDo)
                                        .then((_) {
                                          final infoData = Provider.of<Infos>(context, listen: false);
                                          List<Info> info = infoData.items.where((element) {
                                            return element.data == globals.dataPrzeniesRamke && element.ulNr == globals.nrUlaPrzeniesDo && element.kategoria == 'inspection' && element.parametr == AppLocalizations.of(context)!.inspection;
                                          }).toList();
                                          if(info.isEmpty){
                                            //utworzenie wpisu inspection w docelowym ulu
                                            Infos.insertInfo(
                                              '${globals.dataPrzeniesRamke}.$nrPasiekiDo.${globals.nrUlaPrzeniesDo}.inspection.${AppLocalizations.of(context)!.inspection}',
                                              globals.dataPrzeniesRamke,
                                              nrPasiekiDo,
                                              globals.nrUlaPrzeniesDo,
                                              'inspection',
                                              AppLocalizations.of(context)!.inspection,
                                              'green',
                                              '',
                                              '',
                                              '',
                                              formatterHm.format(DateTime.now()),
                                              '',
                                              0
                                            );
                                          }
                                      });

                                    // Sprawdzenie czy są jeszcze ramki do przeniesienia
                                    Provider.of<Frames>(context, listen: false)
                                      .fetchAndSetFramesForHive(nrPasieki, globals.nrUlaPrzeniesZ)
                                      .then((_) {
                                        if (!mounted) return;
                                        final framesAfterMove = Provider.of<Frames>(context, listen: false);
                                        List<Frame> remainingFrames = framesAfterMove.items.where((fr) {
                                          return fr.data == dateController.text && fr.ramkaNr > 0 && fr.ramkaNrPo != 0;
                                        }).toList();

                                        if (remainingFrames.isEmpty) {
                                          // Nie ma więcej ramek do przeniesienia - przywróć kontekst i wróć
                                          _restoreAndPop(afterSave: true);
                                        } else {
                                          // Są jeszcze ramki - odśwież ekran
                                          Set<int> bodies = {};
                                          for (var fr in remainingFrames) {
                                            bodies.add(fr.korpusNr);
                                          }
                                          setState(() {
                                            availableKorpusyZ = bodies.toList()..sort();
                                            if (availableKorpusyZ.isNotEmpty && !availableKorpusyZ.contains(globals.nrKorpusuPrzeniesZ)) {
                                              globals.nrKorpusuPrzeniesZ = availableKorpusyZ[0];
                                            }
                                            _updateAvailableRamkiZ();
                                          });
                                        }
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
                    ])))));
  }
}
