import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../globals.dart' as globals;
import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
import '../helpers/notification_helper.dart';
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
  bool _isInit = true;
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
  TextEditingController pole1Controller = TextEditingController();
  DateTime? _selectedDate = DateTime.now(); // domyślnie dziś ; //wybrana data
  DateTime? _selectedDatePole1 = DateTime.now();
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
      final idNotatki = routeArgs['idNotatki'];
      //final temp = routeArgs['temp']; //ślepy argument bo jest błąd jak jest nowy wpis

      //print('idNotatki= $idNotatki');

      if (idNotatki != null) {
        edycja = true;
        //jezeli edycja istniejącego wpisu
        final notatkiData = Provider.of<Notes>(context, listen: false);
        notatki = notatkiData.items.where((element) {
          //to wczytanie danych notatkiu
          return element.id.toString() == '$idNotatki';
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
        pole1Controller.text = notatki[0].pole1;
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
    } //od if (_isInit) {
    _isInit = false;
    super.didChangeDependencies();
  }

  //kalendarz wyboru daty 
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

  //kalendarz wyboru daty zadania (pole1)
  Future<void> _selectDatePole1(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDatePole1,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDatePole1 = pickedDate;
        pole1Controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
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
                                    labelText: AppLocalizations.of(context)!.noteDate,
                                    labelStyle: TextStyle(color: Colors.black),
                                    hintText: AppLocalizations.of(context)!.sElectDate,
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  onTap: () => _selectDate(context),
                                ),
                              ),
 
 
                          
// pasieka
                             SizedBox(
                                height: 15,
                              ),
                              Row(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        minLines: 1,
                                        maxLines: 2,
                                        initialValue: nowyNrPasieki.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.grey)),
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.blue)),
                                          labelText: (AppLocalizations.of(context)!.apiaryNr),
                                          labelStyle: TextStyle(color: Colors.black),
                                          //hintText:  (AppLocalizations.of(context)!.apiaryNr),
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(context)!.enter);
                                          }
                                          nowyNrPasieki = int.parse(value);
                                          return null;
                                        }
                                      ),
                                    ),
                                   
//numer ula
                                  SizedBox(
                                    width: 150,
                                    child: TextFormField(
                                      minLines: 1,
                                      maxLines: 2,
                                      initialValue: nowyNrUla.toString(),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.grey)),
                                        focusedBorder: OutlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.blue)),
                                        labelText:
                                            (AppLocalizations.of(context)!.hIveNr),
                                        labelStyle: TextStyle(color: Colors.black),
                                        //hintText:(AppLocalizations.of(context)!.hIveNr),
                                      ),
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return (AppLocalizations.of(context)!.enter);
                                        }
                                        nowyNrUla = int.parse(value);
                                        return null;
                                     }
                                    ), 
                                  ),
                                    
                                  ]),
//tytul
                               SizedBox(
                                height: 15,
                              ),
                              TextFormField(
                                  minLines: 1,
                                  maxLines: 2,
                                  initialValue: nowyTytul.toString(),
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.grey)),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.blue)),
                                    labelText:
                                        (AppLocalizations.of(context)!.tItle),
                                    labelStyle: TextStyle(color: Colors.black),
                                    hintText:
                                        (AppLocalizations.of(context)!.tItle),
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return (AppLocalizations.of(context)!.enterTitleNote);
                                    }
                                    nowyTytul = value;
                                    return null;
                                  }),
    

//notatka
                              SizedBox(
                                height: 15,
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
                                      return (AppLocalizations.of(context)!.enterNote);
                                    }
                                    nowyNotatka = value;
                                    return null;
                                  }),

//priorytet
                              SizedBox(
                                height: 15,
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
                                          if (!isChecked) {
                                            pole1Controller.text = '';
                                          }
                                        });
                                      },
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Text(AppLocalizations.of(context)!.toDo),
                                  ]),

//data zadania (pole1) - widoczne tylko gdy "Do zrobienia" zaznaczone
                              if (isChecked)
                              Padding(
                                padding: const EdgeInsets.only(top: 15.0),
                                child: TextFormField(
                                  controller: pole1Controller,
                                  //readOnly: true, // blokuje ręczne wpisywanie
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                                    labelText: AppLocalizations.of(context)!.taskDate,
                                    labelStyle: TextStyle(color: Colors.black),
                                    hintText: AppLocalizations.of(context)!.sElectDate,
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  onTap: () => _selectDatePole1(context),
                                ),
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
                              height: 50,
                              shape: const StadiumBorder(
                                side: const BorderSide(color: Color.fromARGB(255, 162, 103, 0)),
                                ),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                  // if (nowyZasobId! >= 4) nowyMiara = 2;
                                  if (edycja) {
                                    DBHelper.updateNotatki(
                                            notatki[0].id,
                                            dateController.text,
                                            nowyTytul!,
                                            nowyNrPasieki!,
                                            nowyNrUla!,
                                            nowyNotatka!,
                                            0,
                                            nowyPriorytet!,
                                            pole1Controller.text,
                                            notatki[0].pole2,
                                            notatki[0].pole3,
                                            nowyUwagi!,
                                            0)
                                        .then((_) {
                                      // print(
                                      //     '$nowyNrPasieki, $nowyZasobId, $nowyIlosc, $nowyMiara, $nowyUwagi');
                                      NotificationHelper.scheduleAllNotifications();
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
                                        pole1Controller.text,
                                        '',
                                        '',
                                        nowyUwagi!,
                                        0); //arch
                                    NotificationHelper.scheduleAllNotifications();
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
                              textColor: Colors.black,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),
                          ]),
                    ]))));
  }
}
