import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../globals.dart' as globals;
import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';

class NoteEditScreen extends StatefulWidget {
  static const routeName = '/note_edit';

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');

  //String nowyData = '0';
  // String nowyRok = '0';
  // String nowyMiesiac = '0';
  // String nowyDzien = '0';
  int? nowyNrPasieki;
  int? nowyNrUla;
  String? nowyTytul;
  String? nowyNotatka;
  String? nowyPriorytet;
  String? nowyUwagi;
  bool edycja = false;
  String tytulEkranu = 'Edycja notatki';
  bool isChecked = false;
  List<Note> notatki = [];
  TextEditingController dateController = TextEditingController();

  // @override
  // void initState() {
  //   dateController.text = DateTime.now().toString().substring(0, 10);
  //   super.initState();
  // }

  @override
  void didChangeDependencies() {
    final routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    final idNotatki = routeArgs['idNotatki'];
    final temp =
        routeArgs['temp']; //ślepy argument bo jest błąd jak jest nowy wpis

    print('idNotatki= $idNotatki');

    if (idNotatki != null) {
      edycja = true;
      //jezeli edycja istniejącego wpisu
      final notatkiData = Provider.of<Notes>(context, listen: false);
      notatki = notatkiData.items.where((element) {
        //to wczytanie danych notatkiu
        return element.id.toString().contains('$idNotatki');
      }).toList();

      if (notatki[0].priorytet == 'true') {
        setState(() {
          isChecked = true;
        });
      } else {
        setState(() {
          isChecked = false;
        });
      }
      dateController.text = notatki[0].data;
      // nowyRok = notatki[0].data.substring(0, 4);
      // nowyMiesiac = notatki[0].data.substring(5, 7);
      // nowyDzien = notatki[0].data.substring(8);
      nowyNrPasieki = notatki[0].pasiekaNr;
      nowyNrUla = notatki[0].ulNr;
      nowyTytul = notatki[0].tytul;
      nowyNotatka = notatki[0].notatka;
      nowyPriorytet = notatki[0].priorytet;
      nowyUwagi = notatki[0].uwagi;
      tytulEkranu = AppLocalizations.of(context)!.editingNote;
    } else {
      edycja = false;
      //jezeli dodanie nowego notatkiu
      dateController.text = DateTime.now().toString().substring(0, 10);
      // nowyRok = DateFormat('yyyy').format(DateTime.now());
      // nowyMiesiac = DateFormat('MM').format(DateTime.now());
      // nowyDzien = DateFormat('dd').format(DateTime.now());
      nowyNrPasieki = 0;
      nowyNrUla = 0;
      nowyPriorytet = 'false';
      nowyTytul = '';
      nowyNotatka = '';
      nowyUwagi = '';
      tytulEkranu = AppLocalizations.of(context)!.addNote;
    }

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
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.start,
                              //   crossAxisAlignment: CrossAxisAlignment.end,
                              //   children: <Widget>[
                              //     SizedBox(
                              //       width: 70,
                              //       child: Text(
                              //         AppLocalizations.of(context)!
                              //                 .harvestDate +
                              //             ':',
                              //         style: TextStyle(
                              //           //fontWeight: FontWeight.bold,
                              //           fontSize: 15,
                              //           color: Colors.black,
                              //         ),
                              //         softWrap: true, //zawijanie tekstu
                              //         overflow: TextOverflow.fade,
                              //       ),
                              //     ),
                              //     SizedBox(width: 20),
                              //     SizedBox(
                              //       width: 50,
                              //       child: TextFormField(
                              //           initialValue: nowyRok,
                              //           keyboardType: TextInputType.number,
                              //           decoration: InputDecoration(
                              //             labelText:
                              //                 (AppLocalizations.of(context)!
                              //                     .year),
                              //             labelStyle:
                              //                 TextStyle(color: Colors.black),
                              //             hintText:
                              //                 (AppLocalizations.of(context)!
                              //                     .yYYY),
                              //           ),
                              //           validator: (value) {
                              //             if (value!.isEmpty) {
                              //               return (AppLocalizations.of(
                              //                           context)!
                              //                       .enter +
                              //                   ' ' +
                              //                   AppLocalizations.of(context)!
                              //                       .year);
                              //             }
                              //             nowyRok = value;
                              //             return null;
                              //           }),
                              //     ),
                              //     SizedBox(width: 15),
                              //     SizedBox(
                              //       width: 60,
                              //       child: TextFormField(
                              //           initialValue: nowyMiesiac,
                              //           keyboardType: TextInputType.number,
                              //           decoration: InputDecoration(
                              //             labelText:
                              //                 (AppLocalizations.of(context)!
                              //                     .month),
                              //             labelStyle:
                              //                 TextStyle(color: Colors.black),
                              //             hintText: ('MM'),
                              //           ),
                              //           validator: (value) {
                              //             if (value!.isEmpty) {
                              //               return (AppLocalizations.of(
                              //                           context)!
                              //                       .enter +
                              //                   ' ' +
                              //                   AppLocalizations.of(context)!
                              //                       .month);
                              //             }
                              //             nowyMiesiac = value;
                              //             return null;
                              //           }),
                              //     ),
                              //     SizedBox(width: 15),
                              //     SizedBox(
                              //       width: 50,
                              //       child: TextFormField(
                              //           initialValue: nowyDzien,
                              //           keyboardType: TextInputType.number,
                              //           decoration: InputDecoration(
                              //             labelText:
                              //                 (AppLocalizations.of(context)!
                              //                     .day),
                              //             labelStyle:
                              //                 TextStyle(color: Colors.black),
                              //             hintText: ('DD'),
                              //           ),
                              //           validator: (value) {
                              //             if (value!.isEmpty) {
                              //               return (AppLocalizations.of(
                              //                           context)!
                              //                       .enter +
                              //                   ' ' +
                              //                   AppLocalizations.of(context)!
                              //                       .day);
                              //             }
                              //             nowyDzien = value;
                              //             return null;
                              //           }),
                              //     ),
                              //   ],
                              // ),

// pasieka
                              Row(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        AppLocalizations.of(context)!.apiaryNr +
                                            ':',
                                        style: TextStyle(
                                          //fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                        softWrap: true, //zawijanie tekstu
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    SizedBox(
                                      width: 40,
                                      child: TextFormField(
                                          initialValue:
                                              nowyNrPasieki.toString(),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: InputDecoration(
                                            labelText: (''),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            //hintText:
                                            //   (AppLocalizations.of(context)!
                                            //       .apiaryNr),
                                          ),
                                          validator: (value) {
                                            // if (value!.isEmpty) {
                                            //   return (AppLocalizations.of(
                                            //           context)!
                                            //       .enter);
                                            // }
                                            nowyNrPasieki = int.parse(value!);
                                            return null;
                                          }),
                                    ),
//numer ula
                                    SizedBox(width: 20),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        AppLocalizations.of(context)!.hIveNr +
                                            ':',
                                        style: TextStyle(
                                          //fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                        softWrap: true, //zawijanie tekstu
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    SizedBox(
                                      width: 40,
                                      child: TextFormField(
                                          initialValue: nowyNrUla.toString(),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: InputDecoration(
                                            labelText: (''),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            //hintText:
                                            //   (AppLocalizations.of(context)!
                                            //       .hiveNr),
                                          ),
                                          validator: (value) {
                                            // if (value!.isEmpty) {
                                            //   return (AppLocalizations.of(
                                            //           context)!
                                            //       .enter);
                                            // }
                                            nowyNrUla = int.parse(value!);
                                            return null;
                                          }),
                                    ),
                                  ]),
//tytul
                              Row(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        AppLocalizations.of(context)!.tItle +
                                            ':',
                                        style: TextStyle(
                                          //fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                        softWrap: true, //zawijanie tekstu
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    SizedBox(
                                      width: 200,
                                      child: TextFormField(
                                          initialValue: nowyTytul.toString(),
                                          keyboardType: TextInputType.text,
                                          decoration: InputDecoration(
                                            labelText: (''),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            //hintText:
                                            //   (AppLocalizations.of(context)!
                                            //       .apiaryNr),
                                          ),
                                          validator: (value) {
                                            // if (value!.isEmpty) {
                                            //   return (AppLocalizations.of(
                                            //           context)!
                                            //       .enter);
                                            // }
                                            nowyTytul = value;
                                            return null;
                                          }),
                                    ),
                                  ]),

//notatka
                              SizedBox(
                                height: 20,
                              ),

                              TextFormField(
                                  minLines: 1,
                                  maxLines: 5,
                                  initialValue: nowyNotatka,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.grey)),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.blue)),
                                    labelText:
                                        (AppLocalizations.of(context)!.nOte),
                                    labelStyle: TextStyle(color: Colors.black),
                                    hintText:
                                        (AppLocalizations.of(context)!.nOte),
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return ('wpisz notatkę');
                                    }
                                    nowyNotatka = value;
                                    return null;
                                  }),

//priorytet
                              SizedBox(
                                height: 20,
                              ),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Checkbox(
                                      checkColor: Colors.white,
                                      activeColor: Color.fromARGB(255, 0, 0, 0),
                                      //fillColor: MaterialStateProperty.Color(0xFF42A5F5),
                                      value: isChecked,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          isChecked = value!;
                                          nowyPriorytet = value.toString();
                                        });
                                      },
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Text(AppLocalizations.of(context)!.toDo),
                                  ]),

// //zasób

//                               Row(
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   crossAxisAlignment: CrossAxisAlignment.end,
//                                   children: <Widget>[
//                                     DropdownButton(
//                                       style: TextStyle(
//                                         fontSize: 18,
//                                         color: Colors.black54,
//                                       ),
//                                       value: nowyZasobId, //
//                                       items: [
//                                         DropdownMenuItem(
//                                             child: Text(
//                                                 AppLocalizations.of(context)!
//                                                     .honey),
//                                             value: 1),
//                                         DropdownMenuItem(
//                                             child: Text(
//                                                 AppLocalizations.of(context)!
//                                                     .beePollen),
//                                             value: 2),
//                                         DropdownMenuItem(
//                                             child: Text(
//                                                 AppLocalizations.of(context)!
//                                                     .perga),
//                                             value: 3),
//                                         DropdownMenuItem(
//                                             child: Text(
//                                                 AppLocalizations.of(context)!
//                                                     .wax),
//                                             value: 4),
//                                         DropdownMenuItem(
//                                             child: Text('propolis'), value: 5),

//                                         // DropdownMenuItem(
//                                         //     child: Text(
//                                         //         AppLocalizations.of(context)!
//                                         //             .toDo),
//                                         //     value: 13),
//                                         // DropdownMenuItem(
//                                         //     child: Text(
//                                         //         AppLocalizations.of(context)!
//                                         //             .isDone),
//                                         //     value: 14),
//                                       ], //lista elementów do wyboru
//                                       onChanged: (newValue) {
//                                         //wybrana nowa wartość - nazwa dodatku
//                                         setState(() {
//                                           nowyZasobId =
//                                               newValue!; // ustawienie nowej wybranej nazwy dodatku
//                                           //print('nowy zasób = $nowyZasobId');
//                                         });
//                                       }, //onChangeDropdownItemWar1,
//                                     ),

//ilość

                              //   SizedBox(
                              //     width: 20,
                              //   ),

                              //   //if (nowyZasob < 13)
                              //   SizedBox(
                              //     width: 70,
                              //     child: TextFormField(
                              //         initialValue: nowyIlosc.toString(),
                              //         keyboardType: TextInputType.number,
                              //         decoration: InputDecoration(
                              //           labelText:
                              //               (AppLocalizations.of(context)!
                              //                   .quantity),
                              //           labelStyle:
                              //               TextStyle(color: Colors.black),
                              //           hintText: (''),
                              //         ),
                              //         validator: (value) {
                              //           if (value!.isEmpty ||
                              //               value == '0') {
                              //             return (AppLocalizations.of(
                              //                         context)!
                              //                     .enter +
                              //                 ' ' +
                              //                 AppLocalizations.of(context)!
                              //                     .quantity);
                              //           }
                              //           //print('nowaWartosc = $nowaWartosc');
                              //           nowyIlosc = double.parse(value);
                              //           return null;
                              //         }),
                              //   ),

                              //   SizedBox(
                              //     width: 20,
                              //   ),
                              //   nowyZasobId! <
                              //           4 //dla miodu, pyłku i pierzgi
                              //       ? DropdownButton(
                              //           style: TextStyle(
                              //             fontSize: 18,
                              //             color: Colors.black54,
                              //           ),
                              //           value: nowyMiara, //
                              //           items: [
                              //             DropdownMenuItem(
                              //                 child: Text('l'), value: 1),
                              //             DropdownMenuItem(
                              //                 child: Text('kg'), value: 2),
                              //           ], //lista elementów do wyboru
                              //           onChanged: (newValue) {
                              //             //wybrana nowa wartość - nazwa dodatku
                              //             setState(() {
                              //               nowyMiara =
                              //                   newValue; // ustawienie nowej wybranej nazwy dodatku
                              //               //print('nowy miara = $nowyMiara');
                              //             });
                              //           }, //onChangeDropdownItemWar1,
                              //         )
                              //       //dla wosku i propolisu tylko w kg
                              //       : Text(
                              //           'kg',
                              //           style: TextStyle(
                              //             fontSize: 18,
                              //             color: Colors.grey,
                              //           ),
                              //         ),
                              // ]),
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
                                    enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.grey)),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.blue)),
                                    labelText: (AppLocalizations.of(context)!
                                        .cOmments),
                                    labelStyle: TextStyle(color: Colors.black),
                                    // hintText:
                                    //     (AppLocalizations.of(context)!
                                    //         .comments),
                                  ),
                                  validator: (value) {
                                    // if (value!.isEmpty) {
                                    //   return ('uwagi');
                                    // }
                                    nowyUwagi = value;
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
                                  // if (nowyZasobId! >= 4) nowyMiara = 2;
                                  if (edycja) {
                                    DBHelper.updateNotatki(
                                            notatki[0].id,
                                            dateController.text,
                                            // nowyRok +
                                            //     '-' +
                                            //     nowyMiesiac +
                                            //     '-' +
                                            //     nowyDzien,
                                            nowyTytul!,
                                            nowyNrPasieki!,
                                            nowyNrUla!,
                                            nowyNotatka!,
                                            0,
                                            nowyPriorytet!,
                                            nowyUwagi!,
                                            0)
                                        .then((_) {
                                      // print(
                                      //     '$nowyNrPasieki, $nowyZasobId, $nowyIlosc, $nowyMiara, $nowyUwagi');

                                      Provider.of<Notes>(context, listen: false)
                                          .fetchAndSetNotatki()
                                          .then((_) {
                                        Navigator.of(context).pop();
                                      });
                                      // });
                                    });
                                  } else {
                                    Notes.insertNotatki(
                                      dateController.text,
                                        //notatki[0].id,
                                        nowyTytul!,
                                        nowyNrPasieki!,
                                        nowyNrUla!,
                                        nowyNotatka!,
                                        0,
                                        nowyPriorytet!,
                                        nowyUwagi!,
                                        0); //arch
                                    Provider.of<Notes>(context, listen: false)
                                        .fetchAndSetNotatki()
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
                              textColor: Colors.white,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),
                          ]),
                    ]))));
  }
}
