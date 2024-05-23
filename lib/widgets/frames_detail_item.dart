import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import '../models/infos.dart';
// import '../models/hives.dart';
// import '../models/apiarys.dart';
// import '../models/info.dart';
import '../helpers/db_helper.dart';
import '../screens/frame_edit_screen.dart';
import '../screens/frame_edit_screen2.dart';
import '../globals.dart' as globals;
import '../models/frames.dart';
import '../models/frame.dart';
import '../models/hives.dart';
import '../models/hive.dart';
import '../models/infos.dart';

class FramesDetailItem extends StatefulWidget {
  @override
  State<FramesDetailItem> createState() => _FramesDetailItemState();
}

class _FramesDetailItemState extends State<FramesDetailItem> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  //int rozmiarRamki = 0;
  String nowaData = '0';
  String nowuNrPasieki = '0';
  List<Hive> hive = [];

//   //edycja wpisu o ramce
//   void _showAlert(BuildContext context, String nazwa, String idRamki) {
//     final frameData = Provider.of<Frames>(context, listen: false);
//     final ramka = frameData.items.where((element) {
//       return element.id.contains(idRamki);
//     }).toList();

//     rozmiarRamki = ramka[0].rozmiar;

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(builder: (context, setState) {
//           return AlertDialog(
//             title: Text(nazwa),
//             content: Container(
//                 //padding: EdgeInsets.only( right: 20),
// //formularz
//                 child: Form(
//               key: _formKey1,
//               child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: <Widget>[
//                     //data
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       children: <Widget>[
//                         // Text(
//                         //   'Data',
//                         //   style: TextStyle(
//                         //     //fontWeight: FontWeight.bold,
//                         //     fontSize: 16,
//                         //     color: Colors.black,
//                         //   ),
//                         // ),
//                         // SizedBox(width: 15),
//                         SizedBox(
//                           width: 60,
//                           child: TextFormField(
//                               initialValue: ramka[0].data,
//                               keyboardType: TextInputType.streetAddress,
//                               decoration: InputDecoration(
//                                 labelText: ('rok'),
//                                 labelStyle: TextStyle(color: Colors.black),
//                                 hintText: ('RRRR'),
//                               ),
//                               validator: (value) {
//                                 if (value!.isEmpty) {
//                                   return ('wpisz rok');
//                                 }
//                                 nowaData = value;
//                                 return null;
//                               }),
//                         ),
//                         SizedBox(width: 15),
//                         SizedBox(
//                           width: 60,
//                           child: TextFormField(
//                               initialValue: ramka[0].data,
//                               keyboardType: TextInputType.streetAddress,
//                               decoration: InputDecoration(
//                                 labelText: ('miesiac'),
//                                 labelStyle: TextStyle(color: Colors.black),
//                                 hintText: ('MM'),
//                               ),
//                               validator: (value) {
//                                 if (value!.isEmpty) {
//                                   return ('wpisz miesiac');
//                                 }
//                                 nowaData = value;
//                                 return null;
//                               }),
//                         ),
//                         SizedBox(width: 15),
//                         SizedBox(
//                           width: 60,
//                           child: TextFormField(
//                               initialValue: ramka[0].data,
//                               keyboardType: TextInputType.streetAddress,
//                               decoration: InputDecoration(
//                                 labelText: ('dzień'),
//                                 labelStyle: TextStyle(color: Colors.black),
//                                 hintText: ('DD'),
//                               ),
//                               validator: (value) {
//                                 if (value!.isEmpty) {
//                                   return ('wpisz dzień');
//                                 }
//                                 nowaData = value;
//                                 return null;
//                               }),
//                         ),
//                       ],
//                     ),

// // pasieka - ul - korpus
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       children: <Widget>[
//                         // Text(
//                         //   'Data',
//                         //   style: TextStyle(
//                         //     //fontWeight: FontWeight.bold,
//                         //     fontSize: 16,
//                         //     color: Colors.black,
//                         //   ),
//                         // ),
//                         // SizedBox(width: 15),
//                         SizedBox(
//                           width: 60,
//                           child: TextFormField(
//                               initialValue: ramka[0].pasiekaNr.toString(),
//                               keyboardType: TextInputType.streetAddress,
//                               decoration: InputDecoration(
//                                 labelText: ('pasieka'),
//                                 labelStyle: TextStyle(color: Colors.black),
//                                 hintText: ('np. 1'),
//                               ),
//                               validator: (value) {
//                                 if (value!.isEmpty) {
//                                   return ('nr pasieki');
//                                 }
//                                 nowaData = value;
//                                 return null;
//                               }),
//                         ),
//                         SizedBox(width: 15),
//                         SizedBox(
//                           width: 60,
//                           child: TextFormField(
//                               initialValue: ramka[0].ulNr.toString(),
//                               keyboardType: TextInputType.streetAddress,
//                               decoration: InputDecoration(
//                                 labelText: ('ul'),
//                                 labelStyle: TextStyle(color: Colors.black),
//                                 hintText: ('np. 10'),
//                               ),
//                               validator: (value) {
//                                 if (value!.isEmpty) {
//                                   return ('nr ula');
//                                 }
//                                 nowaData = value;
//                                 return null;
//                               }),
//                         ),
//                         SizedBox(width: 15),
//                         SizedBox(
//                           width: 60,
//                           child: TextFormField(
//                               initialValue: ramka[0].korpusNr.toString(),
//                               keyboardType: TextInputType.streetAddress,
//                               decoration: InputDecoration(
//                                 labelText: ('korpus'),
//                                 labelStyle: TextStyle(color: Colors.black),
//                                 hintText: ('np. 2'),
//                               ),
//                               validator: (value) {
//                                 if (value!.isEmpty) {
//                                   return ('nr korpusu');
//                                 }
//                                 nowaData = value;
//                                 return null;
//                               }),
//                         ),
//                       ],
//                     ),

//                     //korpus / półkorpus

//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: <Widget>[
// //półkorpus
//                         TextButton.icon(
//                             onPressed: () {
//                               setState(() {
//                                 rozmiarRamki = 1;
//                               });
//                             },
//                             icon: Radio(
//                                 value: 1,
//                                 groupValue: rozmiarRamki,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     rozmiarRamki = value!;
//                                   });
//                                 }),
//                             label: Text('korpus')),
// //korpus
//                         TextButton.icon(
//                             onPressed: () {
//                               setState(() {
//                                 rozmiarRamki = 2;
//                               });
//                             },
//                             icon: Radio(
//                                 value: 2,
//                                 groupValue: rozmiarRamki,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     rozmiarRamki = value!;
//                                   });
//                                 }),
//                             label: Text('półkorpus')),
//                       ],
//                     ),

// // ramka mała duza
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       children: <Widget>[
// //mała
//                         TextButton.icon(
//                             onPressed: () {
//                               setState(() {
//                                 rozmiarRamki = 1;
//                               });
//                             },
//                             icon: Radio(
//                                 value: 1,
//                                 groupValue: rozmiarRamki,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     rozmiarRamki = value!;
//                                   });
//                                 }),
//                             label: Text('mała')),
// //duza
//                         TextButton.icon(
//                             onPressed: () {
//                               setState(() {
//                                 rozmiarRamki = 2;
//                               });
//                             },
//                             icon: Radio(
//                                 value: 2,
//                                 groupValue: rozmiarRamki,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     rozmiarRamki = value!;
//                                   });
//                                 }),
//                             label: Text('duza')),
//                       ],
//                     ),

// //lewa prawa obie

//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: <Widget>[
// //lewa
//                         TextButton.icon(
//                             onPressed: () {
//                               setState(() {
//                                 rozmiarRamki = 1;
//                               });
//                             },
//                             icon: Radio(
//                                 value: 1,
//                                 groupValue: rozmiarRamki,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     rozmiarRamki = value!;
//                                   });
//                                 }),
//                             label: Text('lewa')),

// //prawa
//                         TextButton.icon(
//                             onPressed: () {
//                               setState(() {
//                                 rozmiarRamki = 2;
//                               });
//                             },
//                             icon: Radio(
//                                 value: 2,
//                                 groupValue: rozmiarRamki,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     rozmiarRamki = value!;
//                                   });
//                                 }),
//                             label: Text('prawa')),
// //  //obie
// //                           TextButton.icon(
// //                               onPressed: () {
// //                                 setState(() {
// //                                   rozmiarRamki = 2;
// //                                 });
// //                               },
// //                               icon: Radio(
// //                                   value: 2,
// //                                   groupValue: rozmiarRamki,
// //                                   onChanged: (value) {
// //                                     setState(() {
// //                                       rozmiarRamki = value!;
// //                                     });
// //                                   }),
// //                               label: Text('obie')),
//                       ],
//                     ),

// //  //numer pasieki
// //                       SizedBox(
// //                         width: 200,
// //                         child: TextFormField(
// //                           initialValue: ramka[0].pasiekaNr.toString(),
// //                           keyboardType: TextInputType.streetAddress,
// //                           decoration: InputDecoration(
// //                             labelText:'numer pasieki',
// //                             labelStyle:
// //                                 TextStyle(color: Colors.black),
// //                             hintText: 'wpisz numer pasieki',
// //                           ),
// //                           validator: (value) {
// //                             if (value!.isEmpty) {
// //                               return 'wpisz numer pasieki';
// //                             }
// //                             nowuNrPasieki = value;
// //                             return null;
// //                           }),
// //                       ),

//                     Row(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: <Widget>[
//                           // DropdownButton(
//                           //     style: TextStyle(
//                           //       fontSize: 18,
//                           //       color: Colors.black54,
//                           //     ),
//                           //     value:
//                           //         'wwwwww', //ustawiona, widoczna wartość
//                           //     items:
//                           //         _listaCzasowDostaw, //lista elementów do wyboru
//                           //     onChanged: (String newValue) {
//                           //       //wybrana nowa wartość - nazwa dodatku
//                           //       setState(() {
//                           //         _czasDostawy =
//                           //             newValue; // ustawienie nowej wybranej nazwy dodatku
//                           //         print(
//                           //             '_czasDostawy = $_czasDostawy');
//                           //       });
//                           //     } //onChangeDropdownItemWar1,
//                           //     ),

//                           SizedBox(
//                             width: 100,
//                             child: TextFormField(
//                                 initialValue: ramka[0].data,
//                                 keyboardType: TextInputType.streetAddress,
//                                 decoration: InputDecoration(
//                                   labelText: ('wartość'),
//                                   labelStyle: TextStyle(color: Colors.black),
//                                   hintText: ('wpisz wartosc'),
//                                 ),
//                                 validator: (value) {
//                                   if (value!.isEmpty) {
//                                     return ('wpisz wartosc');
//                                   }
//                                   nowaData = value;
//                                   return null;
//                                 }),
//                           ),
//                         ]),

// //                       Row(
// //                         mainAxisAlignment: MainAxisAlignment.start,
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: <Widget>[
// // //rozmiar ramki mała
// //                           TextButton.icon(
// //                               onPressed: () {
// //                                 setState(() {
// //                                   rozmiarRamki = 1;
// //                                 });
// //                               },
// //                               icon: Radio(
// //                                   value: 1,
// //                                   groupValue: rozmiarRamki,
// //                                   onChanged: (value) {
// //                                     setState(() {
// //                                       rozmiarRamki = value!;
// //                                     });
// //                                   }),
// //                               label: Text('mała')),
// // //rozmiar ramki duza
// //                           TextButton.icon(
// //                               onPressed: () {
// //                                 setState(() {
// //                                   rozmiarRamki = 2;
// //                                 });
// //                               },
// //                               icon: Radio(
// //                                   value: 2,
// //                                   groupValue: rozmiarRamki,
// //                                   onChanged: (value) {
// //                                     setState(() {
// //                                       rozmiarRamki = value!;
// //                                     });
// //                                   }),
// //                               label: Text('duza')),
// //                         ],
// //                       )
//                   ])

//               // Text(ramka[0].id),
//               // Form(
//               //   key: _formKey2,
//               //   child: Container(
//               //     padding: EdgeInsets.only(left: 20, right: 20),
//               //     child: TextFormField(
//               //         //initialValue: globals.numer,
//               //         keyboardType: TextInputType.emailAddress,
//               //         decoration: InputDecoration(
//               //           labelText: (AppLocalizations.of(context)!.codeOrEmail),
//               //           labelStyle: TextStyle(color: Colors.black),
//               //           hintText: ramka[0].wartosc,
//               //         ),
//               //         validator: (value) {
//               //           if (value!.isEmpty) {
//               //             return (AppLocalizations.of(context)!.enterCodeOrEmail);
//               //           }
//               //           globals.kod = value;
//               //           return null;
//               //         }),
//               //   ),
//               // ),
//               ,
//             )),
//             actions: <Widget>[
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: Text(AppLocalizations.of(context)!.cancel),
//               ),
//             ],
//             elevation: 24.0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15.0),
//             ),
//           );
//           //barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
//         });
//       },
//       barrierDismissible:
//           false, //zeby zaciemnione tło było zablokowane na kliknięcia
//     );
//   }

  @override
  Widget build(BuildContext context) {
    final frame = Provider.of<Frame>(context, listen: false);

    // List<Color> color = [
    //   const Color.fromARGB(255, 252, 193, 104),
    //   const Color.fromARGB(255, 255, 114, 104),
    //   const Color.fromARGB(255, 104, 187, 254),
    //   const Color.fromARGB(255, 83, 215, 88),
    //   const Color.fromARGB(255, 203, 174, 85),
    //   const Color.fromARGB(255, 253, 182, 76),
    //   const Color.fromARGB(255, 255, 86, 74),
    //   const Color.fromARGB(255, 71, 170, 251),
    //   Color.fromARGB(255, 61, 214, 66),
    //   Color.fromARGB(255, 210, 170, 49),
    // ];
    String korpus = '';
    if (frame.typ == 1)
      korpus = AppLocalizations.of(context)!.halfBody;
    else if (frame.typ == 2) korpus = AppLocalizations.of(context)!.body;
    
    String rozmiar = '';
    if (frame.rozmiar == 1)
      rozmiar = AppLocalizations.of(context)!.small;
    else if (frame.rozmiar == 2) rozmiar = AppLocalizations.of(context)!.big;
    
    String strona = '';
    if (frame.strona == 1)
      strona = AppLocalizations.of(context)!.left;
    else if (frame.strona == 2) strona = AppLocalizations.of(context)!.right;
    
    String zasob = '';
    switch (frame.zasob) {
      case 1:
        zasob = AppLocalizations.of(context)!.drone;
        break;
      case 2:
        zasob = AppLocalizations.of(context)!.broodCovered;
        break;
      case 3:
        zasob = AppLocalizations.of(context)!.larvae;
        break;
      case 4:
        zasob = AppLocalizations.of(context)!.eggs;
        break;
      case 5:
        zasob = AppLocalizations.of(context)!.pollen;
        break;
      case 6:
        zasob = AppLocalizations.of(context)!.honey;
        break;
      case 7:
        zasob = AppLocalizations.of(context)!.honeySealed;
        break;
      case 8:
        zasob = AppLocalizations.of(context)!.waxFundation;
        break;
      case 9: 
        zasob = AppLocalizations.of(context)!.waxComb;
        break;
      case 10:
        zasob = AppLocalizations.of(context)!.queen;
        break;
      case 11:
        zasob = AppLocalizations.of(context)!.queenCells;
        break;
      case 12:
        zasob = AppLocalizations.of(context)!.deleteQueenCells;
        break;
      case 13:
        zasob = AppLocalizations.of(context)!.frame + " ";
        break;
      case 14:
        zasob = AppLocalizations.of(context)!.frame + " ";
        break;
    }
//1-trut,2-czerw,3-larwy,4-jaja,5-pierzga,6-zasklep,7-miód,8-susz,9-węza,10-matka,
    //ilość lub wartość zasobu        11-mateczniki,12-delMat,13-przeznaczenie,14-akcja
    return Dismissible(
      //usuwalny element listy
      key: ValueKey(frame.id),
      background: Container(
        color: Colors.red,
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.delete,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (DismissDirection direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.removeThisItem),
              content: Text(AppLocalizations.of(context)!.deletePermanently),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => {
                    print('ile ramek zostało do skasowania = '),
                    print(globals.ileRamek),
                    if (globals.ileRamek > 1)
                      {
                        DBHelper.deleteFrame(frame.id).then((_) {
                          print('3... kasowanie elementu inspekcji');

                          //zeby nie stracić danych zebranych podczas przeglądu w widoku zbirczym uli
                          final hiveData =
                              Provider.of<Hives>(context, listen: false);
                          hive = hiveData.items.where((element) {
                            //to wczytanie danych edytowanego ula
                            return element.id
                                .contains('${frame.pasiekaNr}.${frame.ulNr}');
                          }).toList();
                          String ikona = hive[0].ikona;
                          int korpusNr = hive[0].korpusNr;
                          int trut = hive[0].trut;
                          int czerw = hive[0].czerw;
                          int larwy = hive[0].larwy;
                          int jaja = hive[0].jaja;
                          int pierzga = hive[0].pierzga;
                          int miod = hive[0].miod;
                          int dojrzaly = hive[0].dojrzaly;
                          int weza = hive[0].weza;
                          int susz = hive[0].susz;
                          int matka = hive[0].matka;
                          int mateczniki = hive[0].mateczniki;
                          int usunmat = hive[0].usunmat;
                          String todo = hive[0].todo;
                          String matka1 = hive[0].matka1;
                          String matka2 = hive[0].matka2;
                          String matka3 = hive[0].matka3;
                          String matka4 = hive[0].matka4;
                          String matka5 = hive[0].matka5;

                          // jezeli usuwano wpis z przeglądu ula z datą taką jak ostatni przegląd ula to modyfikacja danych
                          if ('${frame.pasiekaNr}.${frame.ulNr}' ==
                                  hive[0].id &&
                              frame.data == hive[0].przeglad &&
                              frame.korpusNr == hive[0].korpusNr) {
                            switch (frame.zasob) {
                              case 1:
                                trut = trut -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 2:
                                czerw = czerw -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 3:
                                larwy = larwy -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 4:
                                jaja = jaja -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 5:
                                pierzga = pierzga -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 6:
                                miod = miod -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 7:
                                dojrzaly = dojrzaly -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 8:
                                weza = weza -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 9:
                                susz = susz -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 10:
                                matka = matka -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 11:
                                mateczniki = mateczniki -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 12:
                                usunmat = usunmat -
                                    int.parse(frame.wartosc
                                        .replaceAll(RegExp('%'), ''));
                                break;
                              case 13:
                                todo = '0';
                                break;
                            }
                          }

                          //ewentualna zmiana ikony ula
                          if ((todo != '' && todo != '0') && (ikona != 'red' || ikona != 'orange')) {
                              ikona = 'yellow';
                          }else if ((todo == '' || todo == '0') && (ikona =='yellow'))ikona ='green';
      
                          
                          Hives.insertHive(
                            '${frame.pasiekaNr}.${frame.ulNr}',
                            hive[0].pasiekaNr, //pasieka nr
                            hive[0].ulNr, //ul nr
                            hive[0].przeglad, //przeglad
                            ikona, //ikona
                            hive[0].ramek, //opis - ilość ramek w korpusie
                            korpusNr,
                            trut,
                            czerw,
                            larwy,
                            jaja,
                            pierzga,
                            miod,
                            dojrzaly,
                            weza,
                            susz,
                            matka,
                            mateczniki,
                            usunmat,
                            todo,
                            '0',
                            '0',
                            '0',
                            '0',
                            matka1,
                            matka2,
                            matka3,
                            matka4,
                            matka5,
                            '0',
                            '0',
                            '0',
                            1, //nieaktualne zasoby bo mogła być zmiana ???
                          ).then((_) {
                            //ustawienie szarej ikony w info o przeglądzie
                            Infos.insertInfo(
                                '${hive[0].przeglad}.${hive[0].pasiekaNr}.${hive[0].ulNr}.inspection.' + AppLocalizations.of(context)!.inspection, //id
                                hive[0].przeglad, //data
                                hive[0].pasiekaNr, //pasiekaNr
                                hive[0].ulNr, //ulNr
                                'inspection', //karegoria
                                AppLocalizations.of(context)!.inspection, //parametr
                                AppLocalizations.of(context)!.edited, //wartosc
                                '', //miara
                                '',//pogoda
                                '',//temp
                                '00:00', //czas
                                '',//uwagi
                                0);
                            //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
                            Provider.of<Hives>(context, listen: false)
                                .fetchAndSetHives(
                              frame.pasiekaNr,
                            );
                          });

                          Navigator.of(context)
                              .pop(true); //skasowanie elementu listy
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   const SnackBar(
                          //     content: Text("The item has been deleted"),
                          //   ),
                          // );
                          Provider.of<Frames>(context, listen: false)
                              .fetchAndSetFramesForHive(
                                  globals.pasiekaID, globals.ulID)
                              .then((_) {
                            print('4... aktualizacja ramek w frames.item');
                          });
                        }),
                      }
                    else
                      {
                        print('details_item - ileRamek=${globals.ileRamek}'),
                        print('5... nie mozna usunąć oststniego elementu'),
                        Navigator.of(context).pop(false),
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                                title: Text(
                                    AppLocalizations.of(context)!.cantDelete),
                                content: Text(AppLocalizations.of(context)!
                                    .deleteWholeIspection),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text(
                                        AppLocalizations.of(context)!.cancel),
                                  ),
                                ]);
                          },
                        ),
                      }
                  },
                  child: Text(AppLocalizations.of(context)!.yesDelete),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: 5,//było 15
          vertical: 4,
        ),
        child: Padding(
            padding: const EdgeInsets.all(1),
            child: ListTile(
                onTap: () {
                  //_showAlert(context, 'Edycja', '${frame.id}');
                  // globals.dataInspekcji = frame.data;
                  Navigator.of(context).pushNamed(
                    FrameEditScreen.routeName,
                    arguments: {'idRamki': frame.id},
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: //Image.asset('assets/image/hi_bees.png'),
                      Text('${frame.korpusNr}\n${frame.ramkaNr}/${frame.ramkaNrPo}',
                          style: const TextStyle(fontSize: 16,),
                          textAlign: TextAlign.center),
                ),
                title: Text(
                    "$korpus ${frame.korpusNr}, $rozmiar " +
                        AppLocalizations.of(context)!.smallFrame +
                        " ${frame.ramkaNr} $strona",
                    style: const TextStyle(fontSize: 16)),
                subtitle: Text('$zasob ${frame.wartosc}',
                    style: const TextStyle(fontSize: 16, color: Colors.black)),
                trailing: const Icon(Icons.edit)
                //trailing: const Icon(Icons.arrow_forward_ios)
                )),
      ),
    );
  }
}
