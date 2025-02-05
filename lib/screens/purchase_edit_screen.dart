import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../globals.dart' as globals;
import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
import '../globals.dart' as globals;

import '../models/purchase.dart';

class PurchaseEditScreen extends StatefulWidget {
  static const routeName = '/purchase_edit';

  @override
  State<PurchaseEditScreen> createState() => _PurchaseEditScreenState();
}

class _PurchaseEditScreenState extends State<PurchaseEditScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');
  bool _isInit = true;
  String nowyRok = '0';
  String nowyMiesiac = '0';
  String nowyDzien = '0';
  int? nowyNrPasieki;
  String? nowaNazwa;
  int? nowaKategoriaId;
  int? nowyIlosc;
  double? nowaCena;
  double? nowaWartosc;
  int? nowyMiara;
  int nowaWaluta = 1;
  String? nowyUwagi;
  bool edycja = false;
  String tytulEkranu = 'Edycja zakupów';
  List<Purchase> zakupy = [];
  TextEditingController dateController = TextEditingController();

  @override
  
  void didChangeDependencies() {
    if (_isInit) {
      if (globals.jezyk == 'pl_PL')
        nowaWaluta = 1;
      else if (globals.jezyk == 'en_US')
        nowaWaluta = 2;
      else
        nowaWaluta = 3;

      final routeArgs =
          ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
      final idZakupy = routeArgs['idZakupy'];
      //final temp = routeArgs['temp']; //ślepy argument bo jest błąd jak jest nowy wpis

      print('idZakupy= $idZakupy');

      if (idZakupy != null) {
        edycja = true;
        //jezeli edycja istniejącego wpisu
        final zakupyData = Provider.of<Purchases>(context, listen: false);
        zakupy = zakupyData.items.where((element) {
          //to wczytanie danych zakupyu
          return element.id.toString().contains('$idZakupy');
        }).toList();
        dateController.text = zakupy[0].data;
        nowyRok = zakupy[0].data.substring(0, 4);
        nowyMiesiac = zakupy[0].data.substring(5, 7);
        nowyDzien = zakupy[0].data.substring(8);
        nowyNrPasieki = zakupy[0].pasiekaNr;
        nowaNazwa = zakupy[0].nazwa;
        nowaKategoriaId = zakupy[0].kategoriaId;
        nowyIlosc = zakupy[0].ilosc.toInt();
        nowaCena = zakupy[0].cena;
        nowaWartosc = zakupy[0].wartosc;
        nowyMiara = zakupy[0].miara;
        nowaWaluta = zakupy[0].waluta;
        nowyUwagi = zakupy[0].uwagi;
        tytulEkranu = AppLocalizations.of(context)!.editingPurchase;
      } else {
        edycja = false;
        //jezeli dodanie nowego zakupyu
        dateController.text = DateTime.now().toString().substring(0, 10);
        nowyRok = DateFormat('yyyy').format(DateTime.now());
        nowyMiesiac = DateFormat('MM').format(DateTime.now());
        nowyDzien = DateFormat('dd').format(DateTime.now());
        nowyNrPasieki = 1;
        nowaKategoriaId = 1;
        nowyIlosc = 0;
        nowaCena = 0;
        nowyMiara = 1;
        nowyUwagi = '';
        tytulEkranu = AppLocalizations.of(context)!.addPurchase;
      }
    } //od if (_isInit) {
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {

     final ButtonStyle dataButtonStyle = OutlinedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor, //Color.fromARGB(255, 233, 140, 0),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(150.0, 35.0),
      textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    );

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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
 //data 
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(AppLocalizations.of(context)!.purchaseData),
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
                                             // globals.dataWpisu = formattedDate;
                                            });
                                          } else {print("Date is not selected");}
                                        },
  
                                         child: Text(dateController.text ,
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontSize: 15),),   
                                      ),
                                  ]),  
                                ]),
                             
                             
                              // TextField(
                              //     controller:
                              //         dateController, //editing controller of this TextField
                              //     decoration:  InputDecoration(
                              //         icon: Icon(Icons
                              //             .calendar_today), //icon of text field
                              //         labelText: AppLocalizations.of(context)!.noteDate
                              //         ),
                              //     readOnly:
                              //         true, // when true user cannot edit text
                              //     onTap: () async {
                              //       DateTime? pickedDate = await showDatePicker(
                              //         context: context,
                              //         initialDate: DateTime.parse(dateController.text),
                              //         firstDate: DateTime(2000), 
                              //         lastDate: DateTime(2101));
                              //       if (pickedDate != null) {
                              //         String formattedDate =
                              //             DateFormat('yyyy-MM-dd').format( pickedDate); 

                              //         setState(() {
                              //           dateController.text = formattedDate; 
                              //         });
                              //       } else {
                              //         print("Date is not selected");
                              //       }
                              //     }),


                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.start,
                              //   crossAxisAlignment: CrossAxisAlignment.end,
                              //   children: <Widget>[
                              //     SizedBox(
                              //       width: 70,
                              //       child: Text(
                              //         AppLocalizations.of(context)!.dAte +
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
                           //   ),

// pasieka
                              // Row(
                              //     //mainAxisAlignment: MainAxisAlignment.center,
                              //     mainAxisAlignment: MainAxisAlignment.start,
                              //     crossAxisAlignment: CrossAxisAlignment.end,
                              //     children: <Widget>[
                              //       SizedBox(
                              //         width: 70,
                              //         child: Text(
                              //           AppLocalizations.of(context)!.apiaryNr +
                              //               ':',
                              //           style: TextStyle(
                              //             //fontWeight: FontWeight.bold,
                              //             fontSize: 15,
                              //             color: Colors.black,
                              //           ),
                              //           softWrap: true, //zawijanie tekstu
                              //           overflow: TextOverflow.fade,
                              //         ),
                              //       ),
                              //       SizedBox(width: 20),
                              //       SizedBox(
                              //         width: 180,
                              //         child: TextFormField(
                              //             initialValue:
                              //                 nowyNrPasieki.toString(),
                              //             keyboardType: TextInputType.number,
                              //             decoration: InputDecoration(
                              //               labelText: (''),
                              //               labelStyle:
                              //                   TextStyle(color: Colors.black),
                              //               hintText:
                              //                   (AppLocalizations.of(context)!
                              //                       .apiaryNr),
                              //             ),
                              //             validator: (value) {
                              //               if (value!.isEmpty) {
                              //                 return (AppLocalizations.of(
                              //                             context)!
                              //                         .enter +
                              //                     ' ' +
                              //                     AppLocalizations.of(context)!
                              //                         .apiaryNr);
                              //               }
                              //               nowyNrPasieki = int.parse(value);
                              //               return null;
                              //             }),
                              //       ),
                              //     ]),

// nazwa
                             SizedBox(
                                height: 20,
                              ),

                              TextFormField(
                                  minLines: 1,
                                  maxLines: 5,
                                  initialValue: nowaNazwa,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.grey)),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.blue)),
                                    labelText:
                                        (AppLocalizations.of(context)!.nAme),
                                    labelStyle: TextStyle(color: Colors.black),
                                    hintText:
                                        (AppLocalizations.of(context)!.nAme),
                                  ),
                                  validator: (value) {
                                    // if (value!.isEmpty) {
                                    //   return (AppLocalizations.of(context)!.enterNote);
                                    // }
                                    nowaNazwa = value;
                                    return null;
                                  }),
                             
                             
                              // Row(
                              //     //mainAxisAlignment: MainAxisAlignment.center,
                              //     mainAxisAlignment: MainAxisAlignment.start,
                              //     crossAxisAlignment: CrossAxisAlignment.end,
                              //     children: <Widget>[
                              //       SizedBox(
                              //         width: 70,
                              //         child: Text(
                              //           AppLocalizations.of(context)!.nAme +
                              //               ':',
                              //           style: TextStyle(
                              //             //fontWeight: FontWeight.bold,
                              //             fontSize: 15,
                              //             color: Colors.black,
                              //           ),
                              //           softWrap: true, //zawijanie tekstu
                              //           overflow: TextOverflow.fade,
                              //         ),
                              //       ),
                              //       SizedBox(width: 20),
                              //       SizedBox(
                              //         width: 180,
                              //         child: TextFormField(
                              //             initialValue: nowaNazwa,
                              //             keyboardType: TextInputType.text,
                              //             decoration: InputDecoration(
                              //               labelText: (''),
                              //               labelStyle:
                              //                   TextStyle(color: Colors.black),
                              //               hintText:
                              //                   (AppLocalizations.of(context)!
                              //                       .nAme),
                              //             ),
                              //             validator: (value) {
                              //               // if (value!.isEmpty) {
                              //               //   return (AppLocalizations.of(
                              //               //               context)!
                              //               //           .enter +
                              //               //       ' ' +
                              //               //       AppLocalizations.of(context)!
                              //               //           .nAme);
                              //               // }
                              //               nowaNazwa = value;
                              //               return null;
                              //             }),
                              //       ),
                              //     ]),


//kategoria
                              SizedBox(height: 15),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 75,
                                      child: Text(
                                        AppLocalizations.of(context)!.cAtegory +
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
                                    DropdownButton(
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black54,
                                      ),
                                      value: nowaKategoriaId, //
                                      items: [
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .lack),
                                            value: 1),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .packaging),
                                            value: 2),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .equipment),
                                            value: 3),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .bees),
                                            value: 4),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .queens),
                                            value: 5),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .waxFundation),
                                            value: 6),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .food),
                                            value: 7),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .medicines),
                                            value: 8),

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
                                          nowaKategoriaId =
                                              newValue!; // ustawienie nowej wybranej nazwy dodatku
                                          //print('nowy zasób = $nowaKategoriaId');
                                        });
                                      }, //onChangeDropdownItemWar1,
                                    ),
//miara
                                    SizedBox(
                                      width: 17,
                                    ),

                                    
                                    //dla wosku i propolisu tylko w kg
                                  ]),


//ilość, miara, cena,  waluta

                              SizedBox(
                                height: 20,
                              ),

                              Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
//ilość

                                    SizedBox(
                                      width: 10,
                                    ),

                                    //if (nowyZasob < 13)
                                    SizedBox(
                                      width: 45,
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
                                            nowyIlosc = int.parse(value);
                                            return null;
                                          }),
                                    ),
//miara
                                    SizedBox(
                                      width: 10,
                                    ),
                                    DropdownButton(
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.black54,
                                      ),
                                      value: nowyMiara, //
                                      items: [
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .pcs), value: 1),
                                        DropdownMenuItem(
                                            child: Text('l'), value: 2),
                                        DropdownMenuItem(
                                            child: Text('kg'), value: 3),
                                        
                                      ], //lista elementów do wyboru
                                      onChanged: (newValue) {
                                        //wybrana nowa wartość - nazwa dodatku
                                        setState(() {
                                          nowyMiara =
                                              newValue; // ustawienie nowej wybranej nazwy dodatku
                                          //print('nowy miara = $nowyMiara');
                                        });
                                      }, //onChangeDropdownItemWar1,
                                    ),

//cena

                                    SizedBox(
                                      width: 20,
                                    ),

                                    //if (nowyZasob < 13)
                                    SizedBox(
                                      width: 70,
                                      child: TextFormField(
                                          initialValue: nowaCena.toString(),
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText:
                                                (AppLocalizations.of(context)!
                                                    .pRice),
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
                                                      .pRice);
                                            }

                                            nowaCena = double.parse(
                                                value.replaceAll(',', '.'));
                                            nowaWartosc =
                                                nowyIlosc! * nowaCena!;
                                            return null;
                                          }),
                                    ),
                                    //wartosc

                                    // SizedBox(
                                    //   width: 20,
                                    // ),

                                    // //if (nowyZasob < 13)
                                    // SizedBox(
                                    //   width: 50,
                                    //   child: Text(nowaWartosc.toString()),
                                    // ),

//waluta
                                    SizedBox(
                                      width: 10,
                                    ),
                                    DropdownButton(
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black54,
                                      ),
                                      value: nowaWaluta, //
                                      items: [
                                        DropdownMenuItem(
                                            child: Text('PLN'), value: 1),
                                        DropdownMenuItem(
                                            child: Text('EUR'), value: 2),
                                        DropdownMenuItem(
                                            child: Text('USD'), value: 3),
                                      ], //lista elementów do wyboru
                                      onChanged: (newValue) {
                                        //wybrana nowa wartość - nazwa dodatku
                                        setState(() {
                                          nowaWaluta =
                                              newValue!; // ustawienie nowej wybranej nazwy dodatku
                                          //print('nowy miara = $nowyMiara');
                                        });
                                      }, //onChangeDropdownItemWar1,
                                    ),
                                    //dla wosku i propolisu tylko w kg
                                  ]),

//uwagi
                              SizedBox(
                                height: 40,
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
                              shape: const StadiumBorder(),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                  //if (nowaKategoriaId! >= 4) nowyMiara = 2;
                                  if (edycja) {
                                    
                                      print(
                                          '$nowyNrPasieki, $nowaNazwa, $nowaKategoriaId, $nowyIlosc, $nowyMiara, $nowaCena, $nowaWartosc, $nowaWaluta, $nowyUwagi');
                                      DBHelper.updateZakupy(
                                        zakupy[0].id,
                                        dateController.text,
                                        // nowyRok +
                                        //     '-' +
                                        //     nowyMiesiac +
                                        //     '-' +
                                        //     nowyDzien,
                                        nowyNrPasieki!,
                                        nowaNazwa!,
                                        nowaKategoriaId!,
                                        nowyIlosc!.toDouble(),
                                        nowyMiara!,
                                        nowaCena!,
                                        nowaWartosc!,
                                        nowaWaluta,
                                        nowyUwagi!,
                                        0, //arch
                                      );
                                      Provider.of<Purchases>(context, listen: false)
                                          .fetchAndSetZakupy()
                                          .then((_) {
                                        Navigator.of(context).pop();
                                      
                                      // });
                                    });
                                  } else {
                                    Purchases.insertZakupy(
                                      //zakupy[0].id,
                                      dateController.text,
                                      // nowyRok +
                                      //     '-' +
                                      //     nowyMiesiac +
                                      //     '-' +
                                      //     nowyDzien,
                                      nowyNrPasieki!,
                                      nowaNazwa!,
                                      nowaKategoriaId!,
                                      nowyIlosc!.toDouble(),
                                      nowyMiara!,
                                      nowaCena!,
                                      nowaWartosc!,
                                      nowaWaluta,
                                      nowyUwagi!,
                                      0, //arch
                                    );
                                    Provider.of<Purchases>(context, listen: false)
                                        .fetchAndSetZakupy()
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
