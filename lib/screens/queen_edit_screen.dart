import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../globals.dart' as globals;
import 'package:intl/intl.dart';
//import '../helpers/db_helper.dart';
//import 'package:flutter/services.dart';
import '../models/queen.dart';

class QueenEditScreen extends StatefulWidget {
  static const routeName = '/queen_edit';

  @override
  State<QueenEditScreen> createState() => _QueenEditScreenState();
}

class _QueenEditScreenState extends State<QueenEditScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');

  //String nowyData = '0';
  // String nowyRok = '0';
  // String nowyMiesiac = '0';
  // String nowyDzien = '0';
  bool _isInit = true;
  String rasa = '';
  String linia = '';
  String znak = '';
  String napis = '';
  String zrodlo = '';
  String uwagi = '';
  int pasieka = 0;
  int ul = 0;
  String dataStratyMatki = '';
  bool edycja = false;
  String tytulEkranu = '';
  //bool isChecked = false;
  List<Queen> queens = [];
  final TextEditingController dateController = TextEditingController();
  final TextEditingController dateControllerStraty = TextEditingController();
  //final TextEditingController _controller = TextEditingController();
  DateTime? _selectedDateLoss = DateTime.now(); // domyślnie dziś ; //wybrana data
  DateTime? _selectedDatePoz = DateTime.now(); // domyślnie dziś ; //wybrana data
  String test = 'test start';
  // @override
  // void initState() {
  //   dateController.text = DateTime.now().toString().substring(0, 10);
  //   super.initState();
  // }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final routeArgs =
          ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
      final idQueen = routeArgs['idQueen'];
      //final temp = routeArgs['temp']; //ślepy argument bo jest błąd jak jest nowy wpis

      //print('idQueen= $idQueen');

      if (idQueen != null) {
        edycja = true;
        //jezeli edycja istniejącego wpisu
        final queenData = Provider.of<Queens>(context, listen: false);
        queens = queenData.items.where((element) {
          //to wczytanie danych notatkiu
          return element.id.toString() == '$idQueen';
        }).toList();

        // if (notatki[0].priorytet == 'true') {
        //   setState(() {
        //     isChecked = true;
        //   });
        // } else {
        //   setState(() {
        //     isChecked = false;
        //   });
        // }
        dateController.text = queens[0].data;
        if(queens[0].dataStraty != '') {
          dateControllerStraty.text = queens[0].dataStraty;
          _selectedDateLoss = DateTime.parse(queens[0].dataStraty);
        }
        
        // nowyRok = notatki[0].data.substring(0, 4);
        // nowyMiesiac = notatki[0].data.substring(5, 7);
        // nowyDzien = notatki[0].data.substring(8);
        rasa = queens[0].rasa;
        linia = queens[0].linia;
        znak = queens[0].znak;
        napis = queens[0].napis;
        zrodlo = queens[0].zrodlo;
        pasieka = queens[0].pasieka;
        ul = queens[0].ul;
        uwagi = queens[0].uwagi;
        //dataStraty = queens[0].dataStraty;
        tytulEkranu = AppLocalizations.of(context)!.eDitingQueen + ' ID $idQueen';
      } else {
        edycja = false;
        //jezeli dodanie nowej matki
        dateController.text = DateTime.now().toString().substring(0, 10);
        //dateControllerStraty.text = DateTime.now().toString().substring(0, 10);
        // nowyRok = DateFormat('yyyy').format(DateTime.now());
        // nowyMiesiac = DateFormat('MM').format(DateTime.now());
        // nowyDzien = DateFormat('dd').format(DateTime.now());       
        rasa = AppLocalizations.of(context)!.cArniolan;
        zrodlo = AppLocalizations.of(context)!.bOught;
        znak = AppLocalizations.of(context)!.unmarked;
        linia = '';
        napis = '';
        uwagi = '';
        //dataStraty = '';
        tytulEkranu = AppLocalizations.of(context)!.aDdQueen;
      }
    } //od if (_isInit) {
    _isInit = false;
    super.didChangeDependencies();
  }

  //kalendarz wyboru daty pozyskania matki
  Future<void> _selectDatePoz(BuildContext context) async {
    final DateTime? pickedDatePoz = await showDatePicker(
      context: context,
      initialDate: _selectedDatePoz , // domyślnie dziś
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDatePoz != null) {
      setState(() {
        _selectedDatePoz = pickedDatePoz;
        dateController.text = DateFormat('yyyy-MM-dd').format(pickedDatePoz); // np. 2025-11-01
      });
    }
  }

  //kalendarz wyboru daty straty matki
  Future<void> _selectDateLoss(BuildContext context) async {
    final DateTime? pickedDateLoss = await showDatePicker(
      context: context,
      initialDate: _selectedDateLoss , // domyślnie dziś
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDateLoss != null) {
      setState(() {
        _selectedDateLoss = pickedDateLoss;
        dateControllerStraty.text = DateFormat('yyyy-MM-dd').format(pickedDateLoss); // np. 2025-11-01
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
 
 //data pozyskania matki
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
                                  onTap: () => _selectDatePoz(context),
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
                                value: zrodlo,  
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
                                    zrodlo = newValue!.toString(); 
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
                                value: rasa,  
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
                                    rasa = newValue!.toString(); 
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
                                initialValue: linia.toString(),
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
                                  linia = value!;
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
                                value: znak,  
                                items: [
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.unmarked),
                                                  value:AppLocalizations.of(context)!.unmarked),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedWhite),
                                                  value:AppLocalizations.of(context)!.markedWhite),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedYellow),
                                                  value:AppLocalizations.of(context)!.markedYellow),
                                  //DropdownMenuItem(child: Row( children:[Text(AppLocalizations.of(context)!.markedRed),Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 255, 0, 0),)]),
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
                                    znak = newValue!.toString(); 
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
                                initialValue: napis,
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
                                  napis = value!;
                                  return null;
                                }
                              ),


//data straty matki
                              SizedBox(height: 10,),
                              Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: TextFormField(
                                  controller: dateControllerStraty,
                                  //readOnly: true, // blokuje ręczne wpisywanie
                                  decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                  labelText: AppLocalizations.of(context)!.dAteLoss,
                                  labelStyle: TextStyle(color: Colors.black),
                                  // hintText:
                                  //     (AppLocalizations.of(context)!
                                  //         .vAlue),
                             
                                  //  labelText: 'Data straty matki',
                                    hintText: AppLocalizations.of(context)!.sElectDate,
                                    suffixIcon: Icon(Icons.calendar_today),
                                   // border: OutlineInputBorder(),
                                  ),
                                  onTap: () => _selectDateLoss(context),
                                ),
                              ),
                             
                     

//uwagi
                              SizedBox(
                                height: 10,
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
                                side: const BorderSide(color: Color.fromARGB(255, 162, 103, 0)),
                                ),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                  // if (nowyZasobId! >= 4) nowyMiara = 2;
                                  if (edycja) {
                                    Queens.editQueen(
                                            queens[0].id,
                                            dateController.text,
                                            zrodlo,
                                            rasa,
                                            linia,
                                            znak,
                                            napis,
                                            uwagi,
                                            pasieka,
                                            ul,
                                            dateControllerStraty.text,
                                            '',//a,
                                            '',//b,
                                            '',//c,
                                            '0', //arch,
                                            )
                                        .then((_) {
                                      // print(
                                      //     '$nowyNrPasieki, $nowyZasobId, $nowyIlosc, $nowyMiara, $nowyUwagi');

                                      Provider.of<Queens>(context, listen: false)
                                          .fetchAndSetQueens()
                                          .then((_) {
                                        Navigator.of(context).pop();
                                      });
                                      // });
                                    });
                                  } else {
                                    Queens.insertQueen(
                                      dateController.text,
                                        zrodlo,
                                        rasa,
                                        linia,
                                        znak,
                                        napis,
                                        uwagi,
                                        pasieka,
                                        ul,
                                        dateControllerStraty.text,
                                        '',//a,
                                        '',//b,
                                        '',//c,
                                        '0', //arch,
                                        ); //arch
                                    Provider.of<Queens>(context, listen: false)
                                        .fetchAndSetQueens()
                                        .then((_) {
                                      Navigator.of(context).pop();
                                    });
                                  }
                                }
                                ;
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
