import 'package:flutter/material.dart';
import 'package:hi_bees/globals.dart';
import 'package:hi_bees/models/infos.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../globals.dart' as globals;
import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
 import '../models/apiarys.dart';
// import '../models/frame.dart';
 import '../models/hives.dart';
// import '../models/infos.dart';
// import '../screens/activation_screen.dart';
// import '../models/frames.dart';
// import '../models/hive.dart';
// import 'frames_detail_screen.dart';
import '../models/harvest.dart';
import 'package:flutter/services.dart';

class AddHiveScreen extends StatefulWidget {
  static const routeName = '/add_hive';

  @override
  State<AddHiveScreen> createState() => _AddHiveScreenState();
}

class _AddHiveScreenState extends State<AddHiveScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');
  var formatterHm = new DateFormat('H:mm');
  
  int nowyNrPasieki = 1;
  int nowyNrUla = 1;
  //double? nowyIlosc;
  String ileRamek = '10';
  String nowyUwagi = '';
  bool edycja = false;
  String tytulEkranu = '';
  List<Harvest> zbior = [];
  TextEditingController dateController = TextEditingController();

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
      tytulEkranu = AppLocalizations.of(context)!.aDdHive;
  //  }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
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
                              TextField(
                                  controller:
                                      dateController, //editing controller of this TextField
                                  decoration:  InputDecoration(
                                      icon: Icon(Icons
                                          .calendar_today), //icon of text field
                                      labelText: AppLocalizations.of(context)!.noteDate
                                      ),
                                  readOnly:
                                      true, // when true user cannot edit text
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.parse(dateController.text),
                                      firstDate: DateTime(2000), 
                                      lastDate: DateTime(2101));
                                    if (pickedDate != null) {
                                      String formattedDate =
                                          DateFormat('yyyy-MM-dd').format( pickedDate); 

                                      setState(() {
                                        dateController.text = formattedDate; 
                                      });
                                    } else {
                                      print("Date is not selected");
                                    }
                                  }),                           

// // pasieka
//                               Row(
//                                   //mainAxisAlignment: MainAxisAlignment.center,
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   crossAxisAlignment: CrossAxisAlignment.end,
//                                   children: <Widget>[
//                                     SizedBox(
//                                       width: 70,
//                                       child: Text(
//                                         AppLocalizations.of(context)!.apiaryNr +
//                                             ':',
//                                         style: TextStyle(
//                                           //fontWeight: FontWeight.bold,
//                                           fontSize: 15,
//                                           color: Colors.black,
//                                         ),
//                                         softWrap: true, //zawijanie tekstu
//                                         overflow: TextOverflow.fade,
//                                       ),
//                                     ),
//                                     SizedBox(width: 20),
//                                     SizedBox(
//                                       width: 180,
//                                       child: TextFormField(
//                                           initialValue:
//                                               nowyNrPasieki.toString(),
//                                           keyboardType: TextInputType.number,
//                                           decoration: InputDecoration(
//                                             labelText: (''),
//                                             labelStyle:
//                                                 TextStyle(color: Colors.black),
//                                             hintText:
//                                                 (AppLocalizations.of(context)!
//                                                     .apiaryNr),
//                                           ),
//                                           validator: (value) {
//                                             if (value!.isEmpty) {
//                                               return (AppLocalizations.of(
//                                                           context)!
//                                                       .enter +
//                                                   ' ' +
//                                                   AppLocalizations.of(context)!
//                                                       .apiaryNr);
//                                             }
//                                             nowyNrPasieki = int.parse(value);
//                                             return null;
//                                           }),
//                                     ),
//                                   ]),
// // ul
//                               Row(
//                                   //mainAxisAlignment: MainAxisAlignment.center,
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   crossAxisAlignment: CrossAxisAlignment.end,
//                                   children: <Widget>[
//                                     SizedBox(
//                                       width: 70,
//                                       child: Text(
//                                         AppLocalizations.of(context)!.hiveNr +
//                                             ':',
//                                         style: TextStyle(
//                                           //fontWeight: FontWeight.bold,
//                                           fontSize: 15,
//                                           color: Colors.black,
//                                         ),
//                                         softWrap: true, //zawijanie tekstu
//                                         overflow: TextOverflow.fade,
//                                       ),
//                                     ),
//                                     SizedBox(width: 20),
//                                     SizedBox(
//                                       width: 180,
//                                       child: TextFormField(
//                                           initialValue:
//                                               nowyNrUla.toString(),
//                                           keyboardType: TextInputType.number,
//                                           decoration: InputDecoration(
//                                             labelText: (''),
//                                             labelStyle:
//                                                 TextStyle(color: Colors.black),
//                                             hintText:
//                                                 (AppLocalizations.of(context)!
//                                                     .apiaryNr),
//                                           ),
//                                           validator: (value) {
//                                             if (value!.isEmpty) {
//                                               return (AppLocalizations.of(
//                                                           context)!
//                                                       .enter +
//                                                   ' ' +
//                                                   AppLocalizations.of(context)!
//                                                       .apiaryNr);
//                                             }
//                                             nowyNrUla = int.parse(value);
//                                             return null;
//                                           }),
//                                     ),
//                                   ]),
//numer pasieki
                              SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                initialValue: nowyNrPasieki.toString(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                  labelText: (AppLocalizations.of(context)!.apiaryNr),
                                  labelStyle: TextStyle(color: Colors.black),
                                  // hintText:
                                  //     (AppLocalizations.of(context)!
                                  //         .vAlue),
                                ),
                                validator: (value) {
                                  // if (value!.isEmpty) {
                                  //   return ('uwagi');
                                  // }
                                  nowyNrPasieki = int.parse(value!);
                                  return null;
                                }
                              ),

//numer ula
                              SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                initialValue: nowyNrUla.toString(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                  labelText: (AppLocalizations.of(context)!.hIveNr),
                                  labelStyle: TextStyle(color: Colors.black),
                                  // hintText:
                                  //     (AppLocalizations.of(context)!
                                  //         .vAlue),
                                ),
                                validator: (value) {
                                  // if (value!.isEmpty) {
                                  //   return ('uwagi');
                                  // }
                                  nowyNrUla = int.parse(value!);
                                  return null;
                                }
                              ),


//ile ramek
                              SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                initialValue: ileRamek,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                  labelText: (AppLocalizations.of(context)!.nUmberOfFrameInBody),
                                  labelStyle: TextStyle(color: Colors.black),
                                  // hintText:
                                  //     (AppLocalizations.of(context)!
                                  //         .vAlue),
                                ),
                                validator: (value) {
                                  // if (value!.isEmpty) {
                                  //   return ('uwagi');
                                  // }
                                  ileRamek = value!;
                                  return null;
                                }
                              ),

//uwagi
                              SizedBox(
                                height: 20,
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
                                          initialValue: nowyUwagi,
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
                                            nowyUwagi = value!;
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
                              shape: const StadiumBorder(),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                  
                                  Infos.insertInfo(
                                    '${dateController.text}.$nowyNrPasieki.$nowyNrUla.equipment.' + AppLocalizations.of(context)!.numberOfFrame + " = ",
                                    dateController.text,
                                    nowyNrPasieki,
                                    nowyNrUla,
                                    'equipment',
                                    AppLocalizations.of(context)!.numberOfFrame + " = ",
                                    ileRamek,
                                    '',
                                    '',
                                    '',
                                    formatterHm.format(DateTime.now()),
                                    nowyUwagi,
                                    0, //info[0].arch,
                                  ).then((_) {
                                     Hives.insertHive(
                                      '$nowyNrPasieki.$nowyNrUla',
                                      nowyNrPasieki, //pasieka nr
                                      nowyNrUla, //ul nr
                                      dateController.text, //przeglad
                                      'green', //ikona
                                      int.parse(ileRamek), //opis - ilość ramek w korpusie
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      '',
                                      '',
                                      '',
                                      '',
                                      '',
                                      '',
                                      '',
                                      '',
                                      '',
                                      '',
                                    ).then((_) {
                                      //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
                                      Provider.of<Hives>(context, listen: false).fetchAndSetHives(nowyNrPasieki,)
                                        .then((_) {
                                          final hivesData = Provider.of<Hives>(context,listen: false);
                                          final hives = hivesData.items;
                                          int ileUli = hives.length;

                                          //zapis do tabeli "pasieki"
                                          Apiarys.insertApiary(
                                            '${nowyNrPasieki}',
                                            nowyNrPasieki, //pasieka nr
                                            ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
                                            dateController.text, //przeglad
                                            'green', //ikona
                                            '??', //opis
                                          ).then((_) {
                                            Provider.of<Apiarys>(context,listen: false).fetchAndSetApiarys()
                                            .then((_) {
                                              Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(nowyNrPasieki, nowyNrUla)
                                                .then((_) {
                                                  Navigator.of(context).pop();
                                              });
                                            });
                                          });
                                        });
                                    });
                                    // Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(nowyNrPasieki, nowyNrUla)
                                    // .then((_) {
                                    //   Navigator.of(context).pop();
                                    // });
                                  }); //arch
                                }      
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!.saveZ) +
                                  '   '), //Modyfikuj
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.white,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),
                          ]),
                    ]))));
  }
}
