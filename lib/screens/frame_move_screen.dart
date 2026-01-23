
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;
import 'package:intl/intl.dart';

import '../helpers/db_helper.dart';
//import '../models/apiarys.dart';
import '../models/frame.dart';
import '../models/hives.dart';
//import '../models/infos.dart';
//import '../screens/activation_screen.dart';
import '../models/frames.dart';
import '../models/hive.dart';
// import 'package:flutter/services.dart';
//import 'frames_detail_screen.dart';

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


  
  
  @override
  void didChangeDependencies() {
    if (_isInit) {
      //print('na poczatek didChangeDependencies: nowyZasobId  = ${dateController.text}');
      final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
      //final idRamki = routeArgs['idRamki']; //pobiera z frames_detail_item.dart
      final idPasieki = routeArgs['idPasieki'];
      //final idUla = routeArgs['idUla'];
      final idZasobu = routeArgs['idZasobu'];
      //print('ramka = $idRamki, pasieka = $idPasieki , ul = $idUla');

    
        //jezeli dodanie nowego wpisu (tylko dla aktualnie wybranej pasieki i ula)
        dateController.text = globals.dataWpisu; //DateTime.now().toString().substring(0, 10);
        // nowyRok = DateFormat('yyyy').format(DateTime.now());
        // nowyMiesiac = DateFormat('MM').format(DateTime.now());
        // nowyDzien = DateFormat('dd').format(DateTime.now());
        nrPasieki = int.parse('$idPasieki');
        // nrUlaZ = int.parse('$idUla');
        // nrKorpusuZ = globals.nowyNrKorpusu; //zapamiętany ostatni wybór
        // nrRamkiZ = globals.nowyNrRamki;
        // nrRamkiDo = globals.nowyNrRamki;
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
         print('i = ${hiveData.items[i].ulNr}');
         print('length = ${hiveData.items.length}');
        } 
      
      });
      
      
         
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
  void _showAlertNrKorpusu(String wybor, int przycisk) {
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
                       switch (przycisk) {
                        case 1:
                          setState(() {
                            globals.nrKorpusuPrzeniesZ = data;
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

  //wybór numeru ula
  void _showAlertNrUla(String wybor, int przycisk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                children: gridItemsHive //lista numerów ula 
                  .map((data) => InkWell(
                    onTap: () {
                       switch (przycisk) {
                        case 1:
                          setState(() {
                            globals.nrUlaPrzeniesZ = data;
                            //pobranie danych o ulach z wybranej pasieki
                            Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrPasieki)
                                  .then((_) {
                              final hiveData = Provider.of<Hives>(context, listen: false);
                                                                  //dane ula Do którego przenosimy
                              hiveDo = hiveData.items.where((element) {
                                return element.id == ('$nrPasieki.${globals.nrUlaPrzeniesZ}');
                              }).toList();
                              //liczba ramek w ulu Do którego przenosimy
                              ramekZ = hiveZ[0].ramek; 
                              //utworzenie klwiatury wyboru numeru ramki Do
                              gridItemsZ=[];
                              for(int i = 1; i <= ramekZ; i++){
                                gridItemsZ.add(i);
                              // print('i = ${gridItems}');
                              } 
                             });
                          });
                          break;
                        case 2:
                          setState(() {
                            globals.nrUlaPrzeniesDo = data;
                            //pobranie danych o ulach z wybranej pasieki
                            Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrPasieki)
                                  .then((_) {
                              final hiveData = Provider.of<Hives>(context, listen: false);
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
                            });
                          });
                          break;                         
                        default:
                      }
                      Navigator.of(context).pop(true);
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
    // final ButtonStyle buttonPasiekaUlStyle = OutlinedButton.styleFrom(
    //   padding: const EdgeInsets.all(2.0),
    //   backgroundColor: Color.fromARGB(255, 211, 211, 211),
    //   shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    //   side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
    //   fixedSize: Size(83.0, 35.0),
    //   textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    // );
    // final ButtonStyle buttonSumaZasobow = OutlinedButton.styleFrom(
    //   padding: const EdgeInsets.all(2.0),
    //   backgroundColor: Color.fromARGB(255, 211, 211, 211),
    //   shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    //   side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
    //   fixedSize: Size(85.0, 35.0),
    //   textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    // );
//print(dateController.text );
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
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


// //data - pasieka - ul - korpus
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//  //data przeglądu  
//                                   Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.center,
//                                     children: [
//                                       Text(AppLocalizations.of(context)!.inspectionDate),
//                                       OutlinedButton(
//                                         style: dataButtonStyle,
//                                         onPressed: () async {
//                                           DateTime? pickedDate =
//                                             await showDatePicker(
//                                               context: context,
//                                               initialDate: DateTime.parse(dateController.text),
//                                               firstDate: DateTime(2000),
//                                               lastDate: DateTime(2101),
//                                               builder:(context , child){
//                                                 return Theme( data: Theme.of(context).copyWith(  // override MaterialApp ThemeData
//                                                   colorScheme: ColorScheme.light(
//                                                     primary: Color.fromARGB(255, 236, 167, 63),//header and selced day background color
//                                                     onPrimary: Colors.white, // titles and 
//                                                     onSurface: Colors.black, // Month days , years 
//                                                   ),
//                                                   textButtonTheme: TextButtonThemeData(
//                                                     style: TextButton.styleFrom(
//                                                       foregroundColor: Colors.black, // ok , cancel    buttons
//                                                     ),
//                                                   ),
//                                                 ),  child: child!   );  // pass child to this child
//                                               }
//                                             );
//                                           if (pickedDate != null) {
//                                             String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
//                                             setState(() {
//                                               dateController.text = formattedDate;
//                                               globals.dataWpisu = formattedDate;
//                                             });
//                                           } else {print("Date is not selected");}
//                                         },
  
//                                          child: Text(dateController.text ,
//                                           style: const TextStyle(
//                                             color: Color.fromARGB(255, 0, 0, 0),
//                                             fontSize: 15),),   
//                                       ),
//                                   ]),                                                             
//  //pasieka                             
//                                   SizedBox(width: 10),
//                                   Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.center,
//                                     children: [
//                                       Text(AppLocalizations.of(context)!.aPiary),
//                                       OutlinedButton(
//                                           style: buttonPasiekaUlStyle,
//                                           onPressed: null,
//                                           child: Text('$nrPasieki',
//                                             style: const TextStyle(
//                                               fontSize: 17,
//                                               color: Color.fromARGB(255, 0, 0,0))),
//                                         )]) ,                                                     
//                                ],
//                               ),




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
                                //mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[ 
  //data przegladu
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
  
  //ul        
                   
                                  SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.hIve),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: () {_showAlertNrUla(AppLocalizations.of(context)!.hIveNr,1);},
                                          child: Text('${globals.nrUlaPrzeniesZ}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color.fromARGB(255, 0, 0,0))),
                                        )])  ,                    
// //korpus                               
//                                 SizedBox(width: 10),
//                                   Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.center,
//                                     children: [
//                                       Text(AppLocalizations.of(context)!.bOdy),
//                                       OutlinedButton(
//                                           style: buttonStyle,
//                                           onPressed: () {_showAlertNrKorpusu(AppLocalizations.of(context)!.bOdyNumber,1);},
//                                           child: Text('$nrKorpusuZ',
//                                             style: const TextStyle(
//                                               fontSize: 18,
//                                               color: Color.fromARGB(255, 0, 0,0))),
//                                         )])  ,                                                         
                               


                              
// //ramka do przeniesienia                            
//                                 SizedBox(width: 10),

//                                 Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.center,
//                                     children: [
//                                       Text(AppLocalizations.of(context)!.fRame),
//                                       OutlinedButton(
//                                             style: buttonStyle,
//                                             onPressed: () {_showAlertNr(AppLocalizations.of(context)!.frameNumberBefore,1);},
//                                             child: Text('$nrRamkiZ',
//                                               style: const TextStyle(
//                                                 fontSize: 18,
//                                                 color: Color.fromARGB(255, 0, 0,0))),
//                                           )])
                              
  
                                
                                
                                ],
                              ),


// // przenieś ramkę z:
//                               SizedBox(height: 20),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
 
//                                   Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.center,
//                                     children: [
//                                       Text(AppLocalizations.of(context)!.mOveFrameFrom,
//                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color.fromARGB(255, 0, 0, 0))
//                                       ),
//                                     ]
//                                 )]
//                               ),



                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                //mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[ 
  //data przegladu
  //                                 Column(
  //                                   mainAxisAlignment: MainAxisAlignment.center,
  //                                   crossAxisAlignment: CrossAxisAlignment.center,
  //                                   children: [
  //                                     Text(AppLocalizations.of(context)!.inspectionDate),
  //                                     OutlinedButton(
  //                                       style: dataButtonStyle,
  //                                       onPressed: () async {
  //                                         DateTime? pickedDate =
  //                                           await showDatePicker(
  //                                             context: context,
  //                                             initialDate: DateTime.parse(dateController.text),
  //                                             firstDate: DateTime(2000),
  //                                             lastDate: DateTime(2101),
  //                                             builder:(context , child){
  //                                               return Theme( data: Theme.of(context).copyWith(  // override MaterialApp ThemeData
  //                                                 colorScheme: ColorScheme.light(
  //                                                   primary: Color.fromARGB(255, 236, 167, 63),//header and selced day background color
  //                                                   onPrimary: Colors.white, // titles and 
  //                                                   onSurface: Colors.black, // Month days , years 
  //                                                 ),
  //                                                 textButtonTheme: TextButtonThemeData(
  //                                                   style: TextButton.styleFrom(
  //                                                     foregroundColor: Colors.black, // ok , cancel    buttons
  //                                                   ),
  //                                                 ),
  //                                               ),  child: child!   );  // pass child to this child
  //                                             }
  //                                           );
  //                                         if (pickedDate != null) {
  //                                           String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
  //                                           setState(() {
  //                                             dateController.text = formattedDate;
  //                                             globals.dataWpisu = formattedDate;
  //                                           });
  //                                         } else {print("Date is not selected");}
  //                                       },
  
  //                                        child: Text(dateController.text ,
  //                                         style: const TextStyle(
  //                                           color: Color.fromARGB(255, 0, 0, 0),
  //                                           fontSize: 15),),   
  //                                     ),
  //                                 ]),    
  
  // //ul        
                   
  //                                 SizedBox(width: 10),
  //                                 Column(
  //                                   mainAxisAlignment: MainAxisAlignment.center,
  //                                   crossAxisAlignment: CrossAxisAlignment.center,
  //                                   children: [
  //                                     Text(AppLocalizations.of(context)!.hIve),
  //                                     OutlinedButton(
  //                                         style: buttonStyle,
  //                                         onPressed: () {_showAlertNrUla(AppLocalizations.of(context)!.hIveNr,1);},
  //                                         child: Text('$nrUlaZ',
  //                                           style: const TextStyle(
  //                                             fontSize: 18,
  //                                             color: Color.fromARGB(255, 0, 0,0))),
  //                                       )])  ,                    
//korpus                               
                                SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.bOdy),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: () {_showAlertNrKorpusu(AppLocalizations.of(context)!.bOdyNumber,1);},
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
                                            onPressed: () {_showAlertNr(AppLocalizations.of(context)!.frameNumberBefore, gridItemsZ, 1);},
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



//miejsce docelowe po przeniesieniu
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
  
  
  //ul  docelowy      
                   
                                  SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.hIve),
                                      OutlinedButton(
                                          style: buttonStyle,
                                          onPressed: () {_showAlertNrUla(AppLocalizations.of(context)!.hIveNr, 2); },
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
                                          onPressed: () {_showAlertNrKorpusu(AppLocalizations.of(context)!.bOdyNumber,2);},
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
                                 print('data = ${dateController.text}');
                                 print('nrPasieki = $nrPasieki, nrUlaZ = ${globals.nrUlaPrzeniesZ}, nrUlaDo = ${globals.nrUlaPrzeniesDo}, nrKorpusuZ = ${globals.nrKorpusuPrzeniesZ}, nrKorpusuDo = ${globals.nrKorpusuPrzeniesDo}');
                                 print (' nrRamkiZ = ${globals.nrRamkiPrzeniesZ}, nrRamkiDo = ${globals.nrRamkiPrzeniesDo}; korpus = $korpus');
                                 //ustawienie zmiennej "korpus"
                                //  if(_selectedKorpus[0] == true){ //[0]==true to półkorpus; [0]==false to korpus
                                //     korpus = 1; globals.korpus = 1;   
                                //   }else { 
                                //     korpus = 2; globals.korpus = 2;
                                //   }
                                  // int typ;
                                  // nrTempHive = nrUlaDo; 
                                  // if(nrTempBody != 0) { typ = 2;} 
                                  // else {nrTempBody = nrTempHalfBody; typ = 1;}//(KOM1) przypisanie korpusowi numeru półkorpusa zeby nie tworzyć nowej zmiennej
                                  // // print('nrTempBody = $nrTempBody');
                                  // // print('typ = $typ');
                                  // //ustalenie numeru korpusu dla pobrania wpisów do zmiany dla ramki po
                                  // if (nrXOfBody != 0) {
                                  //   _korpusNr = nrXOfBody;
                                  // } else {
                                  //   _korpusNr = nrXOfHalfBody;
                                  // }
                                  //przeniesienie ramki do innego korpusu
                                  Provider.of<Frames>(context, listen: false)
                                    .fetchAndSetFramesForHive(nrPasieki, globals.nrUlaPrzeniesZ)
                                    .then((_) {  
                                      //dla wszystkich zasobów wykonanie kopii ramki i zmiana "przed", "po", korpusu i ewentualnie ula
                                      final framesData1 = Provider.of<Frames>(context, listen: false);
                                        //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu)
                                      List<Frame> frames = framesData1.items.where((fr) {
                                        return fr.ramkaNr == globals.nrRamkiPrzeniesZ && fr.data == dateController.text  && fr.korpusNr == globals.nrKorpusuPrzeniesZ; //return fr.data.contains('2024-04-04');
                                      }).toList();
                                        print('frames.length = ${frames.length}');
                                        //dla kazdego zasobu - zapis z innym id oraz modyfikacja ramkaNr, ramkaNrPo, korpusNr i ewentualnie ulNr
                                      for (var i = 0; i < frames.length; i++) {
                                        //print ('przeniesiona do ul = $nrTempHive, korpus = $nrTempBody, ramka = $nrTempFrame');
                                        //DBHelper.moveRamkaToBody(frames[i].id, nrTempHave, nrTempBody, nrTempFrame);
                                        //print('frames[i].zasob = ${frames[i].zasob}');
                                        if(frames[i].zasob != 14){ //jezeli zasób jest rózny od "isDone" czyli prawdopodobnie nie jest = "usuń ramka"
                                          print('${globals.dataPrzeniesRamke}.$nrPasieki.${globals.nrUlaPrzeniesDo}.${globals.nrKorpusuPrzeniesDo}.0.${globals.nrRamkiPrzeniesDo}.${frames[i].strona}.${frames[i].zasob}');
                                          Frames.insertFrame(
                                            '${globals.dataPrzeniesRamke}.$nrPasieki.${globals.nrUlaPrzeniesDo}.${globals.nrKorpusuPrzeniesDo}.0.${globals.nrRamkiPrzeniesDo}.${frames[i].strona}.${frames[i].zasob}',
                                            globals.dataPrzeniesRamke,
                                            nrPasieki!,
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
                                              '${globals.dataPrzeniesRamke}.$nrPasieki.${globals.nrUlaPrzeniesDo}.${globals.nrKorpusuPrzeniesDo}.0.${globals.nrRamkiPrzeniesDo}.${frames[i].strona}.${frames[i].zasob}',
                                              globals.dataPrzeniesRamke,
                                              nrPasieki!,
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
                                      //"wstaw ramka" dla ramki Do
                                      Frames.insertFrame(
                                              '${globals.dataPrzeniesRamke}.$nrPasieki.${globals.nrUlaPrzeniesDo}.${globals.nrKorpusuPrzeniesDo}.0.${globals.nrRamkiPrzeniesDo}.1.14',
                                              globals.dataPrzeniesRamke,
                                              nrPasieki!,
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
                                      // i "usuń ramka" dla ramki Z
                                      Frames.insertFrame(
                                              '${globals.dataWpisu}.$nrPasieki.${globals.nrUlaPrzeniesZ}.${globals.nrKorpusuPrzeniesZ}.0.${globals.nrRamkiPrzeniesZ}.1.14',
                                              globals.dataWpisu,
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
                                       print('${globals.dataWpisu}.$nrPasieki.${globals.nrUlaPrzeniesZ}.${globals.nrKorpusuPrzeniesZ}.0.${globals.nrRamkiPrzeniesZ}.1.14');
                                             
                                    Provider.of<Frames>(context, listen: false)
                                      .fetchAndSetFramesForHive(nrPasieki, globals.nrUlaPrzeniesZ)
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
