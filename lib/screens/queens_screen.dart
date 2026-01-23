
import 'package:flutter/material.dart';
import 'package:hi_bees/screens/add_queen_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/queen.dart';
import '../widgets/queen_item.dart';
//import '../screens/note_edit_screen.dart';
import '../globals.dart' as globals;

class QueenScreen extends StatefulWidget {
  const QueenScreen({super.key});
  static const routeName = '/screen-queen'; //nazwa trasy do tego ekranu
  @override
  State<QueenScreen> createState() => _QueenScreenState();
}

class _QueenScreenState extends State<QueenScreen> {
  bool _isInit = true;
  String wybranaData = globals.rokMatek; //DateTime.now().toString().substring(0, 4); //aktualny rok
  String nowaKategoria = '0';
  String nowyParametr = '0';
  String nowyWartosc = '0';
  int pasieka = 0;
  int ul = 0;
  String widok = 'all'; // przycisk z nazwą widoku
  
  void didChangeDependencies() {
    if (_isInit) {
      final routeArgs =
          ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
      //final idInfo = routeArgs['idInfo'];
      final kategoria = routeArgs['kategoria'];
      final parametr = routeArgs['parametr'];
      final wartosc = routeArgs['wartosc'];
      final idPasieki = routeArgs['idPasieki'];
      final idUla = routeArgs['idUla'];
      
      nowyWartosc  = wartosc.toString();
      nowyParametr = parametr.toString();
      nowaKategoria = kategoria.toString();
      pasieka = int.parse(idPasieki.toString());
      ul = int.parse(idUla.toString());

      globals.ulID = ul; //zeby ustawić numer ula na zero jak jest wejście do ZARZADZANIA MATKAMI z Apiary a nie z Hive
      
      Provider.of<Queens>(context, listen: false)
          .fetchAndSetQueens()
          .then((_) {
        //wszystkie matki z tabeli matki z bazy lokalnej
      });
    }
    _isInit = false;

    super.didChangeDependencies();
  }

//inne widoki
   void _showAlertOdswiez() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.qUeens + ':'),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, //minimalna wysokośc okna dialogowego
          children: <Widget>[
             
 //dostępne dla tego ula           
            if(globals.ulID != 0) //jezeli jest określony numer ula
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.widokMatek = 'activ';
                Navigator.of(context).pushNamed(
                  QueenScreen.routeName, 
                    arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': AppLocalizations.of(context)!.queenIs, //Start
                              'wartosc': AppLocalizations.of(context)!.freed, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                  );
              }, child: Text((AppLocalizations.of(context)!.activ),style: TextStyle(fontSize: 18))
              ),

//zarejestrowane, bez ula
              if(globals.ulID == 0) 
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.widokMatek = 'activ';
                Navigator.of(context).pushNamed(
                  QueenScreen.routeName, 
                    arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': AppLocalizations.of(context)!.queenIs, //Start
                              'wartosc': AppLocalizations.of(context)!.freed, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                  );
              }, child: Text((AppLocalizations.of(context)!.register),style: TextStyle(fontSize: 18))
              ),  
        
//zyjące w tej pasiece
              if(globals.ulID != 0) 
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.widokMatek = 'livingInApiary';
                Navigator.of(context).pushNamed(
                  QueenScreen.routeName, 
                    arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': AppLocalizations.of(context)!.queenIs, //Start
                              'wartosc': AppLocalizations.of(context)!.freed, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                  );
              }, child: Text((AppLocalizations.of(context)!.livingInApiary),style: TextStyle(fontSize: 18))
              ),
//wszstkie zyjace
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.widokMatek = 'living';
                Navigator.of(context).pushNamed(
                  QueenScreen.routeName, 
                    arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': AppLocalizations.of(context)!.queenIs, //Start
                              'wartosc': AppLocalizations.of(context)!.freed, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                  );
              }, child: Text((AppLocalizations.of(context)!.living),style: TextStyle(fontSize: 18))
              ),
//wszystkie stracone
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.widokMatek = 'lost';
                Navigator.of(context).pushNamed(
                  QueenScreen.routeName, 
                    arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': AppLocalizations.of(context)!.queenIs, //Start
                              'wartosc': AppLocalizations.of(context)!.freed, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                  );
              }, child: Text((AppLocalizations.of(context)!.lost),style: TextStyle(fontSize: 18))
              ),
//wszystkie
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.widokMatek = 'all';
                Navigator.of(context).pushNamed(
                  QueenScreen.routeName, 
                    arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': AppLocalizations.of(context)!.queenIs, //Start
                              'wartosc': AppLocalizations.of(context)!.freed, //wartość domyślna
                              'idPasieki': pasieka, 
                              'idUla':ul,},
                  );
              }, child: Text((AppLocalizations.of(context)!.all),style: TextStyle(fontSize: 18))
              ), 
              // SizedBox(height: 20,),
              // Text(AppLocalizations.of(context)!.rAports + ':', style: TextStyle(fontSize: 22)),
              // SizedBox(height: 10,),

              // TextButton(onPressed: (){
              //   Navigator.of(context).pop();
              //  // Navigator.of(context).pop();
              //   //globals.odswiezBelkiUliDL = true;
              //   Navigator.of(context).pushNamed(
              //       RaportScreen.routeName,
              //       arguments: {'numerPasieki': globals.pasiekaID },
              //     );
              // }, child: Text((AppLocalizations.of(context)!.hArvestReports),style: TextStyle(fontSize: 18))
              // ),  

              // TextButton(onPressed: (){
              //   Navigator.of(context).pop();
              //  // Navigator.of(context).pop();
              //   //globals.odswiezBelkiUliDL = true;
              //   Navigator.of(context).pushNamed(
              //       Raport2Screen.routeName,
              //       arguments: {'numerPasieki': globals.pasiekaID },
              //     );
              // }, child: Text((AppLocalizations.of(context)!.tReatmentReports),style: TextStyle(fontSize: 18))
              // ),    
 
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

  @override
  Widget build(BuildContext context) {

    // final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    // final widokMatek = routeArgs['widokMatek'];

    //tworzenie listy lat w których dokonywano notatki
    //List<String> listaLat = [];
    //int odRoku = 2022; //zeby najstarszym był rok 2023
    //int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    //listaLat.add('20'); //najpierw "Wszystkie" lata
    // while (odRoku < biezacyRok) { //i kolejne lata
    //   listaLat.add(biezacyRok.toString());
    //   biezacyRok = biezacyRok - 1;
    // }

    //pobranie wszystkich matek
    final queenDataAll = Provider.of<Queens>(context);
    List<Queen> zakupyAll = queenDataAll.items.where((pur) {
      return pur.data.startsWith('20');
    }).toList();

    List<String> listaLat = []; //lista lat w których pozyskano matki
    int odRoku = int.parse(DateTime.now().toString().substring(0, 4)); //biezący rok

    //poszukanie najstarszego roku w którym pozyskano matki
    for (var i = 0; i < zakupyAll.length; i++) {
      if(odRoku > int.parse(zakupyAll[i].data.substring(0, 4)))
        odRoku = int.parse(zakupyAll[i].data.substring(0, 4));
    }
    
    //tworzenie listy lat w których pozyskiwano matki
    int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    listaLat.add('20'); //najpierw "Wszystkie" lata
    while (odRoku <= biezacyRok) {
      listaLat.add(biezacyRok.toString());
      biezacyRok = biezacyRok - 1;
    }
    
    
    //pobranie wszystkich matek dla wybranego roku lub wszystkich
    final queenData = Provider.of<Queens>(context);
    List<Queen> matki;
    if(globals.widokMatek == 'activ' && globals.ulID != 0){
      matki = queenData.items.where((ma) {
        return ma.data.startsWith(wybranaData) && (ma.pasieka == pasieka && ma.ul == ul || ma.ul == 0) && ma.dataStraty.isEmpty; //zyjace i z datą zaczynajacą się od wybranego roku
      }).toList();
    }else if(globals.widokMatek == 'activ' && globals.ulID == 0){
      matki = queenData.items.where((ma) {
        return ma.data.startsWith(wybranaData) && (ma.pasieka == 0 && ma.ul == 0 || ma.ul == 0) && ma.dataStraty.isEmpty; //zyjace i z datą zaczynajacą się od wybranego roku
      }).toList();
    }else if(globals.widokMatek == 'living'){
       matki = queenData.items.where((ma) {
            return ma.data.startsWith(wybranaData) && ma.dataStraty.isEmpty; //zyjące i z datą zaczynajacą się od wybranego roku
          }).toList();
    }else if(globals.widokMatek == 'livingInApiary'){
       matki = queenData.items.where((ma) {
            return ma.data.startsWith(wybranaData) && ma.pasieka == pasieka && ma.dataStraty.isEmpty; //zyjące i z datą zaczynajacą się od wybranego roku
          }).toList();
    }else if(globals.widokMatek == 'lost'){
       matki = queenData.items.where((ma) {
            return ma.data.startsWith(wybranaData) && ma.dataStraty.isNotEmpty; //utracone i z datą zaczynajacą się od wybranego roku
          }).toList();
    }else{
      globals.widokMatek = 'all';
      matki = queenData.items.where((ma) {
        return ma.data.startsWith(wybranaData); //z datą zaczynajacą się od wybranego roku
      }).toList();
    }

    switch (globals.widokMatek){
        case 'all': widok = '   ${AppLocalizations.of(context)!.qUeens}: ${AppLocalizations.of(context)!.all}   ';
        break;
        case 'activ': if (globals.ulID == 0) //jezeli zarządzanie matkami z Apiary
                        widok = '   ${AppLocalizations.of(context)!.qUeens}: ${AppLocalizations.of(context)!.register}   ';
                      else  widok = '   ${AppLocalizations.of(context)!.qUeens}: ${AppLocalizations.of(context)!.activ}   ';
        break;
        case 'living': widok = '   ${AppLocalizations.of(context)!.qUeens}: ${AppLocalizations.of(context)!.living}   ';
        break;
        case 'livingInApiary': widok = '   ${AppLocalizations.of(context)!.qUeens}: ${AppLocalizations.of(context)!.livingInApiary}   ';
        break;
        case 'lost': widok = '   ${AppLocalizations.of(context)!.qUeens}: ${AppLocalizations.of(context)!.lost}   ';
        break;
      }

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: 
          globals.ulID == 0
            ? Text(
              AppLocalizations.of(context)!.aDdingQueen,
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 18.0),
            )
           : Text(
              '${AppLocalizations.of(context)!.aDdQueenToHive} $ul',
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            ),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          // title: Text('Edit inspection hive $numerUla'),
          // backgroundColor: Color.fromARGB(255, 233, 140, 0),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () =>
                  //_showAlert(context, frames[0].pasiekaNr, frames[0].ulNr)
                  Navigator.of(context).pushNamed(AddQueenScreen.routeName),
              //     Navigator.of(context).pushNamed(
              //   AddQueenScreen.routeName.routeName,
              //   arguments: {'temp': 1},
              // ),
              //print('dodaj zbior'),
            ),

          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey[300], // kolor linii
              height: 1.0,
            ),
          ),
        ),
        body: matki.isEmpty
//jezeli matek nie ma          
          ? Center(
            child: Column(
              children: <Widget>[
  //daty, zeby mozna było wybrać inna datę jezeli nie ma notatek w wybranym roku
                Container(
                  padding: EdgeInsets.symmetric(
                  horizontal: 18.0, vertical: 15.0),
                  height: 76, //MediaQuery.of(context).size.height * 0.35,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: listaLat.length,
                    itemBuilder: (context, index) {
                      return Container(
                        //width: MediaQuery.of(context).size.width * 0.6,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                               wybranaData = listaLat[index];
                               globals.rokMatek = wybranaData;
                            });
                          },
                          child: wybranaData == listaLat[index]
                            ? Card(
                                color: Colors.white,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 1.0),
                                  child: Center(
                                      child: 
                                        wybranaData == '20' && index == 0 
                                         ? Text('  ${AppLocalizations.of(context)!.aLl}   ', //nazwa
                                           style: const TextStyle(color: Colors.black,fontSize: 17.0),
                                          )
                                        : Text('  ${listaLat[index]}  ', //nazwa
                                           style: const TextStyle(color: Colors.black,fontSize: 17.0),
                                          )
                                    ),
                                ),
                              )
                            : Card(
                              color: Colors.white,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 1.0),
                                child: Center(
                                    child: 
                                      index == 0 
                                        ? Text('  ${AppLocalizations.of(context)!.aLl}   ',
                                          style: TextStyle(color: Colors.grey,fontSize: 17.0),
                                          )
                                        : Text('  ${listaLat[index]}  ',
                                          style: TextStyle(color: Colors.grey,fontSize: 17.0),
                                          )  
                                  ),
                              ),
                            ),
                          ),
                        );
                      }),
                ),

    //rodzaj widoku               
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                  height: 50, //MediaQuery.of(context).size.height * 0.35,
                  child:
                    TextButton(onPressed: () => 
                        _showAlertOdswiez(),  
                      style: TextButton.styleFrom(
                        side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
                        // shape: RoundedRectangleBorder(
                        // borderRadius: BorderRadius.circular(50),
                      // ),
                      ),
                      child:  Text(widok,style: const TextStyle(fontSize: 18)),
                      
                      ),                
                ),
  //brak matek - napis
                    Container(
                      padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                      child: Text(
                        AppLocalizations.of(context)!.noQueensYet,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            
//jezeli matki są            
            : Column(children: <Widget>[
  //daty
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 18.0, vertical: 15.0),
                  height: 76, //MediaQuery.of(context).size.height * 0.35,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: listaLat.length,
                      itemBuilder: (context, index) {
                        return Container(
                          //width: MediaQuery.of(context).size.width * 0.6,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                wybranaData = listaLat[index];
                                globals.rokMatek = wybranaData;
                              });
                            },
                            child: wybranaData == listaLat[index]
                                ? Card(
                                    color: Colors.white,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 1.0),
                                      child: Center(
                                      child: 
                                        wybranaData == '20' && index == 0 //jezeli jest to pierwszy element listaLat == '20'
                                         ? Text('  ${AppLocalizations.of(context)!.aLl}   ', //wszystkie
                                           style: const TextStyle(color: Colors.black,fontSize: 17.0),
                                          )
                                        : Text('  ${listaLat[index]}  ', //nazwa
                                           style: const TextStyle(color: Colors.black,fontSize: 17.0),
                                          )
                                    ),
                                    ),
                                  )
                                : Card(
                                    color: Colors.white,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 1.0),
                                      child: Center(
                                    child: 
                                      index == 0 
                                        ? Text('  ${AppLocalizations.of(context)!.aLl}  ', //wszystkie
                                          style: TextStyle(color: Colors.grey,fontSize: 17.0),
                                          )
                                        : Text('  ${listaLat[index]}  ',
                                          style: TextStyle(color: Colors.grey,fontSize: 17.0),
                                          )  
                                  ),
                                    ),
                                  ),
                          ),
                        );
                      }),
                ),
  //rodzaj widoku               
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                  height: 50, //MediaQuery.of(context).size.height * 0.35,
                  child:
                    TextButton(onPressed: () => 
                        _showAlertOdswiez(),  
                      style: TextButton.styleFrom(
                        side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
                        // shape: RoundedRectangleBorder(
                        // borderRadius: BorderRadius.circular(50),
                       // ),
                      ),
                      child:  Text(widok,style: const TextStyle(fontSize: 18)),
                      
                      ),                
                ),

//lista matek
                Expanded(
                  child: ListView.builder(
                    itemCount: matki.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: matki[i],
                      child: QueenItem(),
                    ),
                  ),
                )
              ]));
  }
}
