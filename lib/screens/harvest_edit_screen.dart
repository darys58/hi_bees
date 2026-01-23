import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../globals.dart' as globals;
import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
import 'package:flutter/services.dart';

import '../models/harvest.dart';

class HarvestEditScreen extends StatefulWidget {
  static const routeName = '/harvest_edit';

  @override
  State<HarvestEditScreen> createState() => _HarvestEditScreenState();
}

class _HarvestEditScreenState extends State<HarvestEditScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');
  bool _isInit = true;
  String nowyRok = '0';
  String nowyMiesiac = '0';
  String nowyDzien = '0';
  int? nowyNrPasieki;
  int? nowyZasobId;
  double? nowyIlosc;
  int? nowyMiara;
  String? nowyUwagi;
  bool edycja = false;
  String tytulEkranu = 'Edycja zbioru';
  List<Harvest> zbior = [];
  TextEditingController dateController = TextEditingController();
  DateTime? _selectedDate = DateTime.now(); // domyślnie dziś ; //wybrana data

  @override
  void didChangeDependencies() {
  if (_isInit) {
   // print('wlazł do didChangeDependencies');
    //print('na początek didChangeDependencies: nowyZasobId  = ${dateController.text}');
    final routeArgs =
       ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    final idZbioru = routeArgs['idZbioru'];
    //final temp = routeArgs['temp']; //ślepy argument bo jest błąd jak jest nowy wpis

   //print('idZbioru= $idZbioru');

    if (idZbioru != null) {
      edycja = true;
      //jezeli edycja istniejącego wpisu
      final zbiorData = Provider.of<Harvests>(context, listen: false);
      zbior = zbiorData.items.where((element) {
        //to wczytanie danych zbioru
        return element.id.toString() == '$idZbioru';
      }).toList();
      dateController.text = zbior[0].data;
      nowyRok = zbior[0].data.substring(0, 4);
      nowyMiesiac = zbior[0].data.substring(5, 7);
      nowyDzien = zbior[0].data.substring(8);
      nowyNrPasieki = zbior[0].pasiekaNr;
      nowyZasobId = zbior[0].zasobId;
      nowyIlosc = zbior[0].ilosc;
      nowyMiara = zbior[0].miara;
      nowyUwagi = zbior[0].uwagi;
      tytulEkranu = AppLocalizations.of(context)!.editingHarvest;
    } else {
      edycja = false;
      //jezeli dodanie nowego zbioru
      dateController.text = DateTime.now().toString().substring(0, 10);
      nowyRok = DateFormat('yyyy').format(DateTime.now());
      nowyMiesiac = DateFormat('MM').format(DateTime.now());
      nowyDzien = DateFormat('dd').format(DateTime.now());
      nowyNrPasieki = 1;
      nowyZasobId = 1;
      nowyIlosc = 0;
      nowyMiara = 1;
      nowyUwagi = '';
      tytulEkranu = AppLocalizations.of(context)!.addHarvest;
   }
   //print('zbior = ${zbior[0].data}');
  } //od if (_isInit
    _isInit = false;
//print('na koniec didChangeDependencies: nowyZasobId  = ${dateController.text}');
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
                                    labelText: AppLocalizations.of(context)!.harvestDate,
                                    labelStyle: TextStyle(color: Colors.black),
                                    hintText: AppLocalizations.of(context)!.sElectDate,
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  onTap: () => _selectDate(context),
                                ),
                              ), 

// pasieka
                               SizedBox(
                                height: 20,
                              ),

                              TextFormField(
                                  minLines: 1,
                                  maxLines: 5,
                                  initialValue: nowyNrPasieki.toString(),
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
                                        (AppLocalizations.of(context)!.apiaryNr),
                                    labelStyle: TextStyle(color: Colors.black),
                                    hintText:
                                        (AppLocalizations.of(context)!.apiaryNr),
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                              return (AppLocalizations.of(
                                                          context)!
                                                      .enter +
                                                  ' ' +
                                                  AppLocalizations.of(context)!
                                                      .apiaryNr);
                                            }
                                            nowyNrPasieki = int.parse(value);
                                    return null;
                                  }),
                              
                         
//zasób

                              Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    SizedBox(width: 20),
                                    DropdownButton(
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black54,
                                      ),
                                      value: nowyZasobId, //
                                      items: [
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .honey),
                                            value: 1),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .beePollen),
                                            value: 2),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .perga),
                                            value: 3),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .wax),
                                            value: 4),
                                        DropdownMenuItem(
                                            child: Text('propolis'), value: 5),

                                        // DropdownMenuItem(
                                        //     child: Text(
                                        //         AppLocalizations.of(context)!
                                        //             .toDo),
                                        //     value: 13),
                                        // DropdownMenuItem(
                                        //     child: Text(
                                        //         AppLocalizations.of(context)!
                                        //             .isDone),
                                        //     value: 14),
                                      ], //lista elementów do wyboru
                                      onChanged: (newValue) {
                                        //wybrana nowa wartość - nazwa dodatku
                                        setState(() {
                                          nowyZasobId =
                                              newValue!; // ustawienie nowej wybranej nazwy dodatku
                                          //print('nowy zasób = $nowyZasobId');
                                        });
                                      }, //onChangeDropdownItemWar1,
                                    ),

//ilość

                                    SizedBox(
                                      width: 20,
                                    ),

                                    //if (nowyZasob < 13)
                                    SizedBox(
                                      width: 70,
                                      child: TextFormField(
                                          initialValue: nowyIlosc.toString(),
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText:
                                                (AppLocalizations.of(context)!
                                                    .quantity),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            hintText: (''),
                                          ),
                                          validator: (value) {
                                            if (value!.isEmpty ||
                                                value == '0') {
                                              return (AppLocalizations.of(
                                                          context)!
                                                      .enter +
                                                  ' ' +
                                                  AppLocalizations.of(context)!
                                                      .quantity);
                                            }
                                            //print('nowaWartosc = $nowaWartosc');
                                            nowyIlosc = double.parse(value.replaceAll(',', '.'));
                                            return null;
                                          }),
                                    ),

                                    SizedBox(
                                      width: 20,
                                    ),
                                    nowyZasobId! <
                                            4 //dla miodu, pyłku i pierzgi
                                        ? DropdownButton(
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.black54,
                                            ),
                                            value: nowyMiara, //
                                            items: [
                                              DropdownMenuItem(
                                                  child: Text('l'), value: 1),
                                              DropdownMenuItem(
                                                  child: Text('kg'), value: 2),
                                            ], //lista elementów do wyboru
                                            onChanged: (newValue) {
                                              //wybrana nowa wartość - nazwa dodatku
                                              setState(() {
                                                nowyMiara =
                                                    newValue; // ustawienie nowej wybranej nazwy dodatku
                                                //print('nowy miara = $nowyMiara');
                                              });
                                            }, //onChangeDropdownItemWar1,
                                          )
                                        //dla wosku i propolisu tylko w kg
                                        : Text(
                                            'kg',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ]),
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
                                  if (nowyZasobId! >= 4) nowyMiara = 2;
                                  if (edycja) {
                                    DBHelper.updateZbiory(zbior[0].id, 
                                      dateController.text,
                                      // nowyRok +
                                      //         '-' +
                                      //         nowyMiesiac +
                                      //         '-' +
                                      //         nowyDzien,
                                          nowyNrPasieki!,
                                          nowyZasobId!,
                                          nowyIlosc!,
                                          nowyMiara!,
                                          nowyUwagi!,
                                          '',
                                          '',
                                          0)
                                        .then((_) {
                                      //print( '$nowyNrPasieki, $nowyZasobId, $nowyIlosc, $nowyMiara, $nowyUwagi');
                                       
                                      Provider.of<Harvests>(context,
                                              listen: false)
                                          .fetchAndSetZbiory()
                                          .then((_) {
                                        Navigator.of(context).pop();
                                      });
                                      // });
                                    });
                                  } else {
                                    Harvests.insertZbiory(
                                        //zbior[0].id,
                                        dateController.text,
                                        // nowyRok +
                                        //     '-' +
                                        //     nowyMiesiac +
                                        //     '-' +
                                        //     nowyDzien,
                                        nowyNrPasieki!,
                                        nowyZasobId!,
                                        nowyIlosc!,
                                        nowyMiara!,
                                        nowyUwagi!,
                                        '',
                                        '',
                                        0); //arch
                                    Provider.of<Harvests>(context,
                                            listen: false)
                                        .fetchAndSetZbiory()
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
