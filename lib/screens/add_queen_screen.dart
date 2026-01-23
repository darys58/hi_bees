import 'package:flutter/material.dart';
//import 'package:hi_bees/globals.dart';
//import 'package:hi_bees/models/infos.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../globals.dart' as globals;
import 'package:intl/intl.dart';
//import '../helpers/db_helper.dart';
//import '../models/apiarys.dart';
import '../models/queen.dart';
//import '../models/hives.dart';
// import '../models/infos.dart';
// import '../screens/activation_screen.dart';
// import '../models/frames.dart';
// import '../models/hive.dart';
// import 'frames_detail_screen.dart';
import '../models/harvest.dart';
//import 'package:flutter/services.dart';

class AddQueenScreen extends StatefulWidget {
  static const routeName = '/add_queen';

  @override
  State<AddQueenScreen> createState() => _AddQueenScreenState();
}

class _AddQueenScreenState extends State<AddQueenScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');
  var formatterHm = new DateFormat('H:mm');
  
  int nowyNrPasieki = 1;
  int nowyNrUla = 1;
  //double? nowyIlosc;
  String ileRamek = '10';
  String zrodloMatki = ''; //kupiona, złapana, własna
  String rasaMatki = '';// rasa matki
  String liniaMatki = ''; //linia matki
  String znakMatki = ''; // oznaczenie matki
  String opisOpalitka = ''; // cyfry lub litery
  String rodzajUla = '';
  String uwagi = '';
  int pasieka = 0;
  int ul = 0;
  bool edycja = false;
  String tytulEkranu = '';
  List<Harvest> zbior = [];
  TextEditingController dateController = TextEditingController();
  DateTime? _selectedDate = DateTime.now(); // domyślnie dziś ; //wybrana data

  @override
  void didChangeDependencies() {
    // final routeArgs =
    //     ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    // final idZbioru = routeArgs['idZbioru'];
    // final temp =
    //     routeArgs['temp']; //ślepy argument bo jest błąd jak jest nowy wpis

    // print('idZbioru= $idZbioru');

    // if (idZbioru != null) {
    //   edycja = true;
    //   //jezeli edycja istniejącego wpisu
    //   final zbiorData = Provider.of<Harvests>(context, listen: false);
    //   zbior = zbiorData.items.where((element) {
    //     //to wczytanie danych zbioru
    //     return element.id.toString().contains('$idZbioru');
    //   }).toList();
    //   dateController.text = zbior[0].data;
    //   // nowyRok = zbior[0].data.substring(0, 4);
    //   // nowyMiesiac = zbior[0].data.substring(5, 7);
    //   // nowyDzien = zbior[0].data.substring(8);
    //   nowyNrPasieki = zbior[0].pasiekaNr;
    //   nowyZasobId = zbior[0].zasobId;
    //   nowyIlosc = zbior[0].ilosc;
    //   nowyMiara = zbior[0].miara;
    //   nowyUwagi = zbior[0].uwagi;
    //   tytulEkranu = AppLocalizations.of(context)!.editingHarvest;
    // } else {
      edycja = false;
      //jezeli dodanie nowego zbioru
      dateController.text = DateTime.now().toString().substring(0, 10);
      // nowyRok = DateFormat('yyyy').format(DateTime.now());
      // nowyMiesiac = DateFormat('MM').format(DateTime.now());
      // nowyDzien = DateFormat('dd').format(DateTime.now());
      // nowyNrPasieki = 1;
      // nowyNrUla = 1;
      // ileRamek = 10;
      //nowyMiara = 1;
      //nowyUwagi = '';
      tytulEkranu = AppLocalizations.of(context)!.aDdQueen;
      rasaMatki = AppLocalizations.of(context)!.cArniolan;
      rodzajUla = AppLocalizations.of(context)!.hIve;
      zrodloMatki = AppLocalizations.of(context)!.bOught;
      znakMatki = AppLocalizations.of(context)!.unmarked;
  //  }

    super.didChangeDependencies();
  }

   //kalendarz wyboru daty pozyskania matki
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate , // domyślnie dziś
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate); // np. 2025-11-01
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    // final ButtonStyle dataButtonStyle = OutlinedButton.styleFrom(
    //   backgroundColor: Theme.of(context).primaryColor, //Color.fromARGB(255, 233, 140, 0),
    //   shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    //   side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
    //   fixedSize: Size(150.0, 35.0),
    //   textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    // );

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(
            tytulEkranu,
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
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Form(
                        key: _formKey1,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
  
  //data 
                              SizedBox(height: 10,),
                              Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: TextFormField(
                                  controller: dateController,
                                  readOnly: true, // blokuje ręczne wpisywanie
                                  decoration: InputDecoration(                        
                                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                    focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                    labelText: AppLocalizations.of(context)!.dAteAcquisition,
                                    labelStyle: TextStyle(color: Colors.black),
                                    hintText: AppLocalizations.of(context)!.sElectDate,
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  onTap: () => _selectDate(context),
                                ),
                              ),
 


//źródło
                      SizedBox(
                        height: 10,
                      ),              
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        //     SizedBox(
                        //   width: 80,
                        //   child: Text(AppLocalizations.of(context)!.sOurce + ':',
                        //     style: TextStyle(
                        //       //fontWeight: FontWeight.bold,
                        //       fontSize: 15,
                        //       color: Colors.black,
                        //     ),
                        //     softWrap: true, //zawijanie tekstu
                        //     overflow: TextOverflow.fade,
                        //   ),
                        // ),
                        // SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 300,
                              margin: EdgeInsets.only(top: 0, bottom: 0),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: zrodloMatki,  
                                items: [
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.bOught),
                                                  value: AppLocalizations.of(context)!.bOught),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.cOught),
                                                  value: AppLocalizations.of(context)!.cOught),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.oWn),
                                                  value: AppLocalizations.of(context)!.oWn),                                                                                                        
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    zrodloMatki = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),


//rasa             
                        
                       Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        //     SizedBox(
                        //   width: 80,
                        //   child: Text(AppLocalizations.of(context)!.bReed + ':',
                        //     style: TextStyle(
                        //       //fontWeight: FontWeight.bold,
                        //       fontSize: 15,
                        //       color: Colors.black,
                        //     ),
                        //     softWrap: true, //zawijanie tekstu
                        //     overflow: TextOverflow.fade,
                        //   ),
                        // ),
                        // SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 300,
                              margin: EdgeInsets.only(top: 0, bottom: 0),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: rasaMatki,  
                                items: [
                                  DropdownMenuItem(child: Text('Buckfast'),
                                                  value: 'Buckfast'),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.iTalian),
                                                  value: AppLocalizations.of(context)!.iTalian),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.cArniolan),
                                                  value: AppLocalizations.of(context)!.cArniolan), 
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.cAucasian),
                                                  value: AppLocalizations.of(context)!.cAucasian), 
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.cEntral),
                                                  value: AppLocalizations.of(context)!.cEntral), 
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.iBerian),
                                                  value: AppLocalizations.of(context)!.iBerian),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.pErsian),
                                                  value: AppLocalizations.of(context)!.pErsian), 
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.gReek),
                                                  value: AppLocalizations.of(context)!.gReek), 
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.eAster),
                                                  value: AppLocalizations.of(context)!.eAster), 
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.aNatolian),
                                                  value: AppLocalizations.of(context)!.aNatolian),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.oTherQueen),
                                                  value: AppLocalizations.of(context)!.oTherQueen),                
                                                    ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    rasaMatki = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),

//linia matki
                              SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                initialValue: liniaMatki.toString(),
                                keyboardType: TextInputType.text,
                                //inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                  labelText: (AppLocalizations.of(context)!.sUbspecies),
                                  labelStyle: TextStyle(color: Colors.black),
                                  // hintText:
                                  //     (AppLocalizations.of(context)!
                                  //         .vAlue),
                                ),
                                validator: (value) {
                                  // if (value!.isEmpty) {
                                  //   return ('uwagi');
                                  // }
                                  liniaMatki = value!;
                                  return null;
                                }
                              ),

// znak matki - oznaczenie               
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        //     SizedBox(
                        //   width: 90,
                        //   child: Text(AppLocalizations.of(context)!.qUeenMark + ':',
                        //     style: TextStyle(
                        //       //fontWeight: FontWeight.bold,
                        //       fontSize: 15,
                        //       color: Colors.black,
                        //     ),
                        //     softWrap: true, //zawijanie tekstu
                        //     overflow: TextOverflow.fade,
                        //   ),
                        // ),
                        // SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 250,
                              margin: EdgeInsets.only(top: 15, bottom: 15),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: znakMatki,  
                                items: [
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.unmarked),
                                                  value:AppLocalizations.of(context)!.unmarked),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedWhite),
                                                  value:AppLocalizations.of(context)!.markedWhite),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedYellow),
                                                  value:AppLocalizations.of(context)!.markedYellow),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedRed),
                                                  value:AppLocalizations.of(context)!.markedRed),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedGreen),
                                                  value:AppLocalizations.of(context)!.markedGreen),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedBlue),
                                                  value:AppLocalizations.of(context)!.markedBlue),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedOther),
                                                  value:AppLocalizations.of(context)!.markedOther),                                                                       
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    znakMatki = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),
//napis na opalitku
                              // SizedBox(
                              //   height: 20,
                              // ),
                              TextFormField(
                                initialValue: '',
                                keyboardType: TextInputType.text,
                                //inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                  labelText: (AppLocalizations.of(context)!.iNscription),
                                  labelStyle: TextStyle(color: Colors.black),
                                  // hintText:
                                  //     (AppLocalizations.of(context)!
                                  //         .vAlue),
                                ),
                                validator: (value) {
                                  // if (value!.isEmpty) {
                                  //   return ('uwagi');
                                  // }
                                  opisOpalitka = value!;
                                  return null;
                                }
                              ),


//uwagi
                              SizedBox(
                                height: 15,
                              ),
                              // Row(
                              //     mainAxisAlignment: MainAxisAlignment.start,
                              //     crossAxisAlignment: CrossAxisAlignment.end,
                              //     children: <Widget>[
                                    // SizedBox(
                                    //   width: 270,
                                    //   child: 
                                      TextFormField(
                                          minLines: 1,
                                          maxLines: 5,
                                          initialValue:uwagi,
                                          keyboardType: TextInputType.text,
                                          decoration: InputDecoration(
                                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                                            labelText:
                                                (AppLocalizations.of(context)!
                                                    .cOmments),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            // hintText:
                                            //     (AppLocalizations.of(context)!
                                            //         .comments),
                                          ),
                                          validator: (value) {
                                            // if (value!.isEmpty) {
                                            //   return ('uwagi');
                                            // }
                                            uwagi = value!;
                                            return null;
                                          }),
                                    //),
                                 // ]),
                            ]),
                      ),
                      SizedBox(
                        height: 30,
                      ),

  //przyciski
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            //zmień
                            MaterialButton(
                              height: 50,
                              shape: const StadiumBorder(
                                side: const BorderSide(color: Color.fromARGB(255, 162, 103, 0)),),                    
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                  
                                  Queens.insertQueen(
                                    dateController.text,
                                    zrodloMatki,
                                    rasaMatki,
                                    liniaMatki,
                                    znakMatki, 
                                    opisOpalitka,
                                    uwagi,
                                    pasieka,
                                    ul,
                                    '', //dataStraty,
                                    '',//a,
                                    '',//b,
                                    '',//c,
                                    '0', //arch,
                                  ).then((_) {
                                  
                                     
                                      Provider.of<Queens>(context, listen: false)
                                          .fetchAndSetQueens()
                                          .then((_) {
                                        Navigator.of(context).pop();
                                       });
                                  }); //arch
                                }      
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!.saveZ) +
                                  '   '), //Modyfikuj
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.black,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                              
                            ),
                          ]),
                    ]))));
  }
}
