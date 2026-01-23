import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/frames.dart';
import '../models/hives.dart';
import '../models/hive.dart';
import '../models/apiarys.dart';
import '../models/infos.dart';
import '../models/info.dart';
import '../helpers/db_helper.dart';
import '../screens/frames_screen.dart';
import '../screens/infos_edit_screen.dart';
import '../globals.dart' as globals;

class InfoItem extends StatelessWidget {
  String zmienDate(String data) {
    String rok = data.substring(0, 4);
    String miesiac = data.substring(5, 7);
    String dzien = data.substring(8);
    return '$dzien.$miesiac.$rok';
  }

  @override
  Widget build(BuildContext context) {
    final info = Provider.of<Info>(context, listen: false);
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
    List<Hive> hive = [];
    
 
    return Dismissible(
      //usuwalny element listy
      key: ValueKey(info.id),
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
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => {
                    Navigator.of(context).pop(true), //skasowanie elementu listy
                    if (info.kategoria == 'inspection')
                      {
                        //kasowanie wszystkich wpisów dotyczących przeglądu dla pasieki, ula i daty
                        DBHelper.deleteInspection(
                                info.data, globals.pasiekaID, globals.ulID)
                            .then((_) {
                          //print('1... kasowanie inspekcji');

                          //kasowanie belki jezeli zgadza się id i data
                          final hiveData =
                              Provider.of<Hives>(context, listen: false);
                          hive = hiveData.items.where((element) {
                            //to wczytanie danych edytowanego ula
                            return element.id == ('${globals.pasiekaID}.${globals.ulID}');
                          }).toList();
                          if (hive[0].przeglad == info.data) {
                            Hives.insertHive(
                              '${hive[0].pasiekaNr}.${hive[0].ulNr}',
                              hive[0].pasiekaNr, //pasieka nr
                              hive[0].ulNr, //ul nr
                              '2000-01-01', //przeglad - zerowanie daty
                              'green', //ikona - zerowanie ikony
                              hive[0].ramek, //opis - ilość ramek w korpusie
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
                              '0',
                              '0',
                              '0',
                              '0',
                              '0',
                              hive[0].matka1,
                              hive[0].matka2,
                              hive[0].matka3,
                              hive[0].matka4,
                              hive[0].matka5,
                              hive[0].h1,
                              hive[0].h2,
                              '0',
                              0,
                            ).then((_) {
                              //pobranie do Hives_items z tabeli ule
                              Provider.of<Hives>(context, listen: false)
                                  .fetchAndSetHives(
                                hive[0].pasiekaNr,
                              );
                            });
                          }

                          Provider.of<Frames>(context, listen: false)
                              .fetchAndSetFramesForHive(
                                  globals.pasiekaID, globals.ulID)
                              .then((_) {
                            //print('2...wczytanie ramek z ula');
                            final framesData =
                                Provider.of<Frames>(context, listen: false);
                            final frames = framesData.items;
                            int ileRamek = frames.length;
                            //print('3... info_item - ilość ramek w ulu =');
                            //print(hives.length);
                            //print(ileRamek);

                            if (ileRamek == 0) {
                              //jezeli nie ma ramek to czy są info?
                              Provider.of<Infos>(context, listen: false)
                                  .fetchAndSetInfosForHive(
                                      globals.pasiekaID, globals.ulID)
                                  .then((_) {
                                //print('4...wczytanie info dla ula');
                                final infosData =
                                    Provider.of<Infos>(context, listen: false);
                                final infos = infosData.items;
                                int ileInfo = infos.length;
                                //print('5... info_item - ilość info dla ula =');
                                //print(hives.length);
                                //print(ileInfo);
                                //jezeli nie ma info
                                if (ileInfo ==
                                    0) //usuwanie ula bo wszystkie przeglady/ramki usunieto
                                  DBHelper.deleteUl(
                                          globals.pasiekaID, globals.ulID)
                                      .then((_) {
                                    Provider.of<Hives>(context, listen: false)
                                        .fetchAndSetHives(globals.pasiekaID)
                                        .then((_) {
                                      //print('6..wczytanie uli ');
                                      final hivesData = Provider.of<Hives>(
                                          context,
                                          listen: false);
                                      final hives = hivesData.items;
                                      int ileUli = hives.length;
                                     // print('7... info_item - ilość uli =');
                                      //print(hives.length);
                                      //print(ileRamek);
                                      if (ileUli > 0) {
                                        DBHelper.updateIleUli(
                                                globals.pasiekaID, ileUli)
                                            .then((_) {
                                          //print('8...info_item: upgrade ilość uli w pasiece');
                                          Provider.of<Apiarys>(context,
                                                  listen: false)
                                              .fetchAndSetApiarys()
                                              .then((_) {
                                            //print('9...info_item: aktualizacja Apiarys_items bo ileUli>0');
                                            Navigator.of(context).pop();
                                          });
                                        });
                                      } else {
                                        DBHelper.deletePasieki(
                                                globals.pasiekaID)
                                            .then((_) {
                                          //print('10... usuwanie pasieki');
                                          Provider.of<Apiarys>(context,
                                                  listen: false)
                                              .fetchAndSetApiarys()
                                              .then((_) {
                                            //print('11...info_item: aktualizacja Apiarys_items bo ileUli=0');
                                            Navigator.of(context).pop();
                                          });
                                        });
                                      }
                                    });
                                  });
                              });
                            }
                          });
                          //kasowanie wpisu o inspekcji w bazie info
                          DBHelper.deleteInfo(info.id).then((_) {
                            //print('10...kasowanie info w bazie');

                            Provider.of<Infos>(context, listen: false)
                                .fetchAndSetInfosForHive(
                                    globals.pasiekaID, globals.ulID)
                                .then((_) {
                              //aktualizacja danych info w Info._item
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   const SnackBar(
                              //     content: Text("The item has been deleted"),
                              //   ),
                              // );
                            });
                          });
                          //komunikat na dole ekranu
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .inspectionDeleted),
                            ),
                          );
                        }),
                      }
                    else //jezeli to nie jest inspection (kasowanie innych info)
                      {
                        //usuwanie info dla pozostałych kategorii - dla pasieki i ula
                        DBHelper.deleteInfo(info.id).then((_) {
                          //print('1.1... kasowanie info');

                          //kasowanie info w belce ula jezeli zgadza się id i data
                          final hiveData =
                              Provider.of<Hives>(context, listen: false);
                          hive = hiveData.items.where((element) {
                            //to wczytanie danych edytowanego ula
                            return element.id == ('${globals.pasiekaID}.${globals.ulID}');
                          }).toList();
                          if (hive[0].przeglad == info.data) {
                            Hives.insertHive(
                              '${hive[0].pasiekaNr}.${hive[0].ulNr}',
                              hive[0].pasiekaNr, //pasieka nr
                              hive[0].ulNr, //ul nr
                              '2000-01-01', //przeglad - zerowanie daty
                              'green', //ikona - zerowanie ikony
                              hive[0].ramek, //opis - ilość ramek w korpusie
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
                              '0',
                              '0',
                              '0',
                              '0',
                              '0',
                              hive[0].matka1,
                              hive[0].matka2,
                              hive[0].matka3,
                              hive[0].matka4,
                              hive[0].matka5,
                              hive[0].h1, //rodzaj ula
                              hive[0].h2,
                              '0',
                              0,
                            ).then((_) {
                              //pobranie do Hives_items z tabeli ule
                              Provider.of<Hives>(context, listen: false)
                                  .fetchAndSetHives(
                                hive[0].pasiekaNr,
                              );
                            });
                          }

                          //ile info dla ula pozostało?
                          Provider.of<Infos>(context, listen: false)
                              .fetchAndSetInfosForHive(
                                  globals.pasiekaID, globals.ulID)
                              .then((_) {
                            final infosData =
                                Provider.of<Infos>(context, listen: false);
                            final infos = infosData.items;
                            int ileInfo = infos.length;
                            //print('2.1... info_item - ilość info dla ula =');
                            //print(hives.length);
                            //print(ileInfo);
                            if (ileInfo == 0) {
                              //jezeli nie ma info to czy są ramki?
                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      globals.pasiekaID, globals.ulID)
                                  .then((_) {
                                //print('3.1...wczytanie ramek z ula');
                                final framesData =
                                    Provider.of<Frames>(context, listen: false);
                                final frames = framesData.items;
                                int ileRamek = frames.length;
                                //print('4.1... info_item - ilość ramek w ulu =');
                                //print(hives.length);
                                //print(ileRamek);
                                //jezeli nie ma ramek
                                if (ileRamek ==
                                    0) //usuwanie ula bo wszystkie przeglady/ramki usunieto
                                  DBHelper.deleteUl(
                                          globals.pasiekaID, globals.ulID)
                                      .then((_) {
                                    Provider.of<Hives>(context, listen: false)
                                        .fetchAndSetHives(globals.pasiekaID)
                                        .then((_) {
                                      //print('5.1...wczytanie uli ');
                                      final hivesData = Provider.of<Hives>(
                                          context,
                                          listen: false);
                                      final hives = hivesData.items;
                                      int ileUli = hives.length;
                                      //print('6.1... info_item - ilość uli =');
                                      //print(hives.length);
                                      //print(ileRamek);
                                      if (ileUli > 0) {
                                        DBHelper.updateIleUli(
                                                globals.pasiekaID, ileUli)
                                            .then((_) {
                                          //print('7.1...info_item: upgrade ilość uli w pasiece');
                                          Provider.of<Apiarys>(context,
                                                  listen: false)
                                              .fetchAndSetApiarys()
                                              .then((_) {
                                            //print('8.1...info_item: aktualizacja Apiarys_items bo ileUli>0');
                                            Navigator.of(context).pop();
                                          });
                                        });
                                      } else {
                                        DBHelper.deletePasieki(
                                                globals.pasiekaID)
                                            .then((_) {
                                          //print('9.1... usuwanie pasieki');
                                          Provider.of<Apiarys>(context,
                                                  listen: false)
                                              .fetchAndSetApiarys()
                                              .then((_) {
                                            //print( '10.1...info_item: aktualizacja Apiarys_items bo ileUli=0');
                                            Navigator.of(context).pop();
                                          });
                                        });
                                      }
                                    });
                                  });
                              });
                            }
                          });

                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   const SnackBar(
                          //     content: Text("The info has been deleted"),
                          //   ),
                          // );
                        }),
                      },
                    // DBHelper.deleteInfo(info.id).then((_) {
                    //   print('4...kasowanie info w bazie');
                    //   Provider.of<Infos>(context, listen: false)
                    //       .fetchAndSetInfosForHive(
                    //           globals.pasiekaID, globals.ulID)
                    //       .then((_) {
                    //     //aktualizacja danych info w Info._item
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(
                    //         content: Text("The item has been deleted"),
                    //       ),
                    //     );
                    //   });
                    // }),
                  },
                  child: Text(AppLocalizations.of(context)!.yesDelete),
                ),
              ],
            );
          },
        );
      },
      child: Card(
         shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
        child: Padding(
            padding: const EdgeInsets.all(1),
            child: 
//****************************** */
//lista przegladów              
              info.kategoria == 'inspection' //jezeli przeglądy
                ? info.parametr == 'likwidacja ula' || info.parametr == 'hive liquidation'  //jezeli jest to usunięcie ula
//element listy dla usuniętego ula                  
                  ? ListTile( 
                    tileColor: info.wartosc == 'red'
                              ? const Color.fromARGB(255, 244, 208, 208)
                              : info.data.substring(0, 4) == globals.rokStatystyk 
                                ? null 
                                : Colors.grey[200],
                    onTap: () {
                      //_showAlert(context, 'Edycja', '${frame.id}');
                      // globals.dataInspekcji = frame.data;
                      Navigator.of(context).pushNamed(
                        InfosEditScreen.routeName,
                        arguments: {'idInfo': info.id},
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: info.wartosc == 'red'
                                          ? const Color.fromARGB(255, 244, 208, 208)
                                          : info.data.substring(0, 4) == globals.rokStatystyk 
                                            ? Colors.white 
                                            : Colors.grey[200],
                      child: Image.asset('assets/image/hi_bees.png'),
                    ),
                    title: globals.jezyk == 'pl_PL'
                        ? Text(
                            '${zmienDate(info.data)}  ${info.czas}  ${info.temp}',
                            style: const TextStyle(fontSize: 14))
                        : Text('${info.data}  ${info.czas}  ${info.temp}',
                            style: const TextStyle(fontSize: 14)),
                    subtitle: RichText(
                        text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                          TextSpan(
                            text: ('${info.parametr} '),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          // TextSpan(
                          //   text: ('${info.wartosc.replaceAll('.', ',')} '),
                          //   style: TextStyle(
                          //       fontSize: 16,
                          //       fontWeight: FontWeight.bold,
                          //       color: Color.fromARGB(255, 0, 0, 0)),
                          // ),
                          // TextSpan(
                          //   text: ('${info.miara}'),
                          //   style: TextStyle(
                          //       fontSize: 16,
                          //       //fontWeight: FontWeight.bold,
                          //       color: Color.fromARGB(255, 0, 0, 0)),
                          // ),
                          TextSpan(
                            text: '\n${info.uwagi}',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          )
                        ])),
                    trailing: const Icon(Icons.edit))
//lista dla przeglądu normalnego a nie usunięcia ula                
                  : ListTile( 
                    //rokStatystyk = DateTime.now().toString().substring(0, 4)
                    tileColor: info.data.substring(0, 4) == globals.rokStatystyk ? null : Colors.grey[200], 
                      onTap: () {
                        globals.dataInspekcji = info.data; //data przeglądu
                        globals.ikonaInspekcji = info.wartosc; //kolor ikony przeglądu
                        Navigator.of(context).pushNamed(
                          FramesScreen.routeName,
                          arguments: info.ulNr,
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor: info.data.substring(0, 4) == globals.rokStatystyk ? Colors.white : Colors.grey[200],
                        child: Image.asset('assets/image/hi_bees.png'),
                      ),
                      title: globals.jezyk == 'pl_PL'
                          ? Text(
                              '${zmienDate(info.data)}  ${info.czas}  ${info.temp}',
                              style: const TextStyle(fontSize: 14))
                          : Text('${info.data}  ${info.czas}  ${info.temp}',
                              style: const TextStyle(fontSize: 14)),
                      subtitle: 
                      //Row(
                        //children: [
                          RichText(
                        text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                          info.wartosc == 'green'
                              ? TextSpan(
                                  text: ('${info.parametr} '),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 159, 3)),
                                )
                              : info.wartosc == 'yellow'
                                 ? TextSpan(
                                    text: ('${info.parametr} '),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 205, 181, 1)),
                                  )
                                  : info.wartosc == 'red'
                                      ? TextSpan(
                                          text: ('${info.parametr} '),
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(255, 179, 2, 2)),
                                        )
                                      : TextSpan(
                                          text: ('${info.parametr} '),
                                          style: TextStyle(
                                              fontSize: 16,
                                              //fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(255, 0, 0, 0)),
                                        ),
                          // TextSpan(
                          //   text: ('${info.parametr} '),
                          //   style: TextStyle(
                          //       fontSize: 16,
                          //       //fontWeight: FontWeight.bold,
                          //       color: Color.fromARGB(255, 0, 0, 0)),
                          // ),
                         
                          TextSpan(
                            text: '\n${info.uwagi}',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          )
                        ])),
                      trailing: const Icon(Icons.arrow_forward_ios))
//******************************************* */
//lista pozostałych info (oprócz przegladu)
//********************************************/                
                : ListTile( 
                  tileColor: info.wartosc == 'brak' || info.wartosc == 'nie ma' || info.wartosc == 'missing' || info.wartosc == 'nie żyje' || info.wartosc == 'dead'
                              ? const Color.fromARGB(255, 244, 208, 208)
                              : info.data.substring(0, 4) == globals.rokStatystyk 
                                ? null 
                                : Colors.grey[200],                    
                    onTap: () {
                      //_showAlert(context, 'Edycja', '${frame.id}');
                      // globals.dataInspekcji = frame.data;
                      Navigator.of(context).pushNamed(
                        InfosEditScreen.routeName,
                        arguments: {'idInfo': info.id},
                      );
                    },
//leading - grafiki                    
                    leading: CircleAvatar(
                        backgroundColor: info.wartosc == 'brak' || info.wartosc == 'nie ma' || info.wartosc == 'missing' || info.wartosc == 'nie żyje' || info.wartosc == 'dead'
                                          ? const Color.fromARGB(255, 244, 208, 208)
                                          : info.data.substring(0, 4) == globals.rokStatystyk 
                                            ? Colors.white 
                                            : Colors.grey[200],
                        
                        child: info.kategoria == 'feeding'
                            ? Image.asset('assets/image/invert.png')
                            : info.kategoria == 'treatment'
                                ? Image.asset('assets/image/apivarol1.png')
                                : info.kategoria == 'equipment'
                                    ? Image.asset('assets/image/korpus.png')
                                    : info.kategoria == 'queen'
                                        ? Image.asset('assets/image/matka1.png')
                                        : info.kategoria == 'colony'
                                            ? Image.asset(
                                                'assets/image/pszczola1.png')
                                            : info.kategoria == 'harvest'
                                                ? Image.asset(
                                                    'assets/image/zbiory.png')
                                                : const Icon(
                                                    Icons.info_rounded,
                                                    color: Colors.black,
                                                  )),
//*********************************************** */
//title - pierwszy wiersz: data, czas temperatura
                    title: globals.jezyk == 'pl_PL'
                        ? Text(
                            '${zmienDate(info.data)}  ${info.czas}  ${info.temp}',
                            style: const TextStyle(fontSize: 14))
                        : Text('${info.data}  ${info.czas}  ${info.temp}',
                            style: const TextStyle(fontSize: 14)),
//drugi wiersz:                   
                    subtitle: RichText(
                        text:                        
                          TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
//jezeli to matka to matkaID na poczatku wiersza z pola "pogoda" + parametr                         
                              info.kategoria == 'queen' 
                                ? TextSpan(
                                    text: ('ID${info.pogoda} ${info.parametr} '),
                                    style: TextStyle(
                                        fontSize: 16,
                                        //fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 0, 0, 0)),
                                  )
//jezeli to nie matka to: sam parametr                         
                                : TextSpan(
                                  text: ('${info.parametr} '),
                                  style: TextStyle(
                                      fontSize: 16,
                                      //fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                  ),
//jezeli to matka (3)unasiennienie to: wartość zmieniana                             
                            info.parametr == AppLocalizations.of(context)!.queen + " -"
                              ? info.wartosc == 'dziewica'
                                ? TextSpan(
                                  text: (AppLocalizations.of(context)!.virgine1), //nieunasienniona
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                )
                                : info.wartosc == 'naturalna'
                                  ? TextSpan(
                                      text: (AppLocalizations.of(context)!.naturallyMated1),//un. naturalnie
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                    : info.wartosc == 'sztuczna' 
                                      ? TextSpan(
                                          text: (AppLocalizations.of(context)!.artificiallyInseminated1),//inseminowana
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(255, 0, 0, 0)),
                                        )
                                      : TextSpan(
                                          text: (AppLocalizations.of(context)!.droneLaying), //trutówka
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(255, 0, 0, 0)),
                                        )
//to jezeli to stan rodziny i wartość "zła"  (agresywna)                                                              
                              : (info.parametr == AppLocalizations.of(context)!.colony + ' ' + AppLocalizations.of(context)!.isIs) && (info.wartosc == AppLocalizations.of(context)!.aggressive)
                                ? TextSpan(
                                  text: (AppLocalizations.of(context)!.aggressive1), //agresywna
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                                  )
                                : (info.parametr == " " + AppLocalizations.of(context)!.colony + ' ' + AppLocalizations.of(context)!.isIs) && (info.wartosc == AppLocalizations.of(context)!.normal)
                                  ? TextSpan(
                                    text: (AppLocalizations.of(context)!.normal1), //normalna
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                    )
//jezeli to nie matka (3) i nie stan rodziny to: wartość  bez modyfikacji                              
                                  : TextSpan(
                                    text: ('${info.wartosc.replaceAll('.', ',')} '),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 0, 0, 0)),
                                  ),
 //drugi wiersz cd.: miara lub inne teksty w zalezności od parametru                        
 //jezeli to "ileRamek =" to nowa linia bo bedzie typ i rodzaj ula
                          if(info.parametr == AppLocalizations.of(context)!.numberOfFrame + " = ")
                            TextSpan(text: ('\n')),
// i warunek tak jak wyzej to: rodzaj ula i typ ula
                          info.parametr == AppLocalizations.of(context)!.numberOfFrame + " = "
                          ? TextSpan(
                              text: (info.pogoda + ' ' + info.miara ), //rodzaj ula
                              style: TextStyle(
                                fontSize: 16,
                                //fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0)),
                            )
//jezeli to "krata odgrodowa - brak" to zamiast "0" będzie "brak"
                          :info.parametr == " " + AppLocalizations.of(context)!.excluder + " -"
                            ? TextSpan(
                              text: AppLocalizations.of(context)!.lack, //brak kraty
                              style: TextStyle(
                                fontSize: 16,
                                //fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0)),
                              )
//miara                            
                            : info.parametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.small +  " " + AppLocalizations.of(context)!.frame +  " x"  ||     
                              info.parametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.big +  " " + AppLocalizations.of(context)!.frame +  " x" 
                              ? TextSpan(
                                  text: (''), //nie wyświetlanie ilości dm2 węzy
                                )
                              : TextSpan(
                                  text: (info.miara ), //np: bez rodzaju ula, bez 0 przy braku kraty,
                                  style: TextStyle(
                                    fontSize: 16,
                                    //fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
//trzeci wiersz: uwagi                          
                          TextSpan(
                            text: '\n${info.uwagi}',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          )
                        ])),
                    // Text(
                    //     '${info.parametr} ${info.wartosc} ${info.miara}',
                    //     style:
                    //         const TextStyle(fontSize: 18, color: Colors.black)),
                    trailing: const Icon(Icons.edit)
                )
        ),
      ),
    );
  }
}
