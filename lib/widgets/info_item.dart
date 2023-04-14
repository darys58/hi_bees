import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/frames.dart';
import '../models/hives.dart';
import '../models/apiarys.dart';
import '../models/infos.dart';
import '../models/info.dart';
import '../helpers/db_helper.dart';
import '../screens/frames_screen.dart';
import '../globals.dart' as globals;

class InfoItem extends StatelessWidget {
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
              title: Text('Are you sure to remove this item?'),
              content: Text('It will delete item permanently.'),
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
                        //kasowanie wpisów dotyczących przeglądu dla pasieki, ula i daty
                        DBHelper.deleteInspection(
                                info.data, globals.pasiekaID, globals.ulID)
                            .then((_) {
                          print('1... kasowanie inspekcji');
                          Provider.of<Frames>(context, listen: false)
                              .fetchAndSetFramesForHive(
                                  globals.pasiekaID, globals.ulID)
                              .then((_) {
                            print('2...wczytanie ramek z ula');
                            final framesData =
                                Provider.of<Frames>(context, listen: false);
                            final frames = framesData.items;
                            int ileRamek = frames.length;
                            print('3... info_item - ilość ramek w ulu =');
                            //print(hives.length);
                            print(ileRamek);

                            if (ileRamek == 0) {
                            //jezeli nie ma ramek to czy są info?
                              Provider.of<Infos>(context, listen: false)
                                  .fetchAndSetInfosForHive(
                                      globals.pasiekaID, globals.ulID)
                                  .then((_) {
                                print('4...wczytanie info dla ula');
                                final infosData =
                                    Provider.of<Infos>(context, listen: false);
                                final infos = infosData.items;
                                int ileInfo = infos.length;
                                print('5... info_item - ilość info dla ulu =');
                                //print(hives.length);
                                print(ileInfo);
                                //jezeli nie ma info
                                if (ileInfo == 0)//usuwanie ula bo wszystkie przeglady/ramki usunieto
                                  DBHelper.deleteUl(globals.pasiekaID, globals.ulID)
                                    .then((_) {
                                  Provider.of<Hives>(context, listen: false)
                                      .fetchAndSetHives(globals.pasiekaID)
                                      .then((_) {
                                    print('6..wczytanie uli ');
                                    final hivesData = Provider.of<Hives>(context,
                                        listen: false);
                                    final hives = hivesData.items;
                                    int ileUli = hives.length;
                                    print('7... info_item - ilość uli =');
                                    //print(hives.length);
                                    print(ileRamek);
                                    if (ileUli > 0) {
                                      DBHelper.updateIleUli(
                                              globals.pasiekaID, ileUli)
                                          .then((_) {
                                        print(
                                            '8...info_item: upgrade ilość uli w pasiece');
                                        Provider.of<Apiarys>(context,
                                                listen: false)
                                            .fetchAndSetApiarys()
                                            .then((_) {
                                          print(
                                              '9...info_item: aktualizacja Apiarys_items bo ileUli>0');
                                          Navigator.of(context).pop();
                                        });
                                      });
                                    } else {
                                      DBHelper.deletePasieki(globals.pasiekaID)
                                          .then((_) {
                                        print('10... usuwanie pasieki');
                                        Provider.of<Apiarys>(context,
                                                listen: false)
                                            .fetchAndSetApiarys()
                                            .then((_) {
                                          print(
                                              '11...info_item: aktualizacja Apiarys_items bo ileUli=0');
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
                            print('10...kasowanie info w bazie');
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
                            const SnackBar(
                              content: Text("The inspection has been deleted"),
                            ),
                          );
                        }),
                      }
                    else
                      {
                        //usuwanie info dla pozostałych kategorii - dla pasieki i ula
                        DBHelper.deleteInfo(info.id).then((_) {
                          print('1.1... kasowanie info');
                          //ile info dla ula pozostało?
                          Provider.of<Infos>(context, listen: false)
                              .fetchAndSetInfosForHive(
                                  globals.pasiekaID, globals.ulID)
                              .then((_) {
                            final infosData =
                                Provider.of<Infos>(context, listen: false);
                            final infos = infosData.items;
                            int ileInfo = infos.length;
                            print('2.1... info_item - ilość info dla ula =');
                            //print(hives.length);
                            print(ileInfo);
                            if (ileInfo == 0) {
                              //jezeli nie ma info to czy są ramki?
                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      globals.pasiekaID, globals.ulID)
                                  .then((_) {
                                print('3.1...wczytanie ramek z ula');
                                final framesData =
                                    Provider.of<Frames>(context, listen: false);
                                final frames = framesData.items;
                                int ileRamek = frames.length;
                                print('4.1... info_item - ilość ramek w ulu =');
                                //print(hives.length);
                                print(ileRamek);
                                //jezeli nie ma ramek
                                if (ileRamek ==
                                    0) //usuwanie ula bo wszystkie przeglady/ramki usunieto
                                  DBHelper.deleteUl(
                                          globals.pasiekaID, globals.ulID)
                                      .then((_) {
                                    Provider.of<Hives>(context, listen: false)
                                        .fetchAndSetHives(globals.pasiekaID)
                                        .then((_) {
                                      print('5.1...wczytanie uli ');
                                      final hivesData = Provider.of<Hives>(
                                          context,
                                          listen: false);
                                      final hives = hivesData.items;
                                      int ileUli = hives.length;
                                      print('6.1... info_item - ilość uli =');
                                      //print(hives.length);
                                      print(ileRamek);
                                      if (ileUli > 0) {
                                        DBHelper.updateIleUli(
                                                globals.pasiekaID, ileUli)
                                            .then((_) {
                                          print(
                                              '7.1...info_item: upgrade ilość uli w pasiece');
                                          Provider.of<Apiarys>(context,
                                                  listen: false)
                                              .fetchAndSetApiarys()
                                              .then((_) {
                                            print(
                                                '8.1...info_item: aktualizacja Apiarys_items bo ileUli>0');
                                            Navigator.of(context).pop();
                                          });
                                        });
                                      } else {
                                        DBHelper.deletePasieki(
                                                globals.pasiekaID)
                                            .then((_) {
                                          print('9.1... usuwanie pasieki');
                                          Provider.of<Apiarys>(context,
                                                  listen: false)
                                              .fetchAndSetApiarys()
                                              .then((_) {
                                            print(
                                                '10.1...info_item: aktualizacja Apiarys_items bo ileUli=0');
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
                  child: Text('Yes Delete'),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
        child: Padding(
            padding: const EdgeInsets.all(1),
            child: info.kategoria == 'inspection' //przeglądy
                ? ListTile(
                    onTap: () {
                      globals.dataInspekcji = info.data;
                      Navigator.of(context).pushNamed(
                        FramesScreen.routeName,
                        arguments: info.ulNr,
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Image.asset('assets/image/hi_bees.png'),
                    ),
                    title: Text('${info.data}  ${info.uwagi}',
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                        '${info.parametr}  ${info.wartosc} ${info.miara}',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.black)),
                    trailing: const Icon(Icons.arrow_forward_ios))
                : ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: info.kategoria == 'feeding'
                            ? Image.asset('assets/image/invert.png')
                            : info.kategoria == 'treatment'
                                ? Image.asset('assets/image/apivarol1.png')
                                : info.kategoria == 'equipment'
                                    ? Image.asset(
                                        'assets/image/korpus.png') //construction_rounded)//verified_user_rounded) //info_rounded) //visability_rounded //check
                                    : info.kategoria ==
                                            'queen' //done_outline_rounted //face //female_rounded
                                        ? Image.asset(
                                            'assets/image/matka1.png') //done_outline_rounted //face //female_rounded
                                        : info.kategoria ==
                                            'colony' //done_outline_rounted //face //female_rounded
                                        ? Image.asset(
                                            'assets/image/pszczola1.png') //done_outline_rounted //face //female_rounded
                                        : const Icon(
                                            Icons.info_rounded,
                                            color: Colors.black,
                                          )),
                    title: Text('${info.data}  ${info.uwagi}',
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                        '${info.parametr} ${info.wartosc} ${info.miara}',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.black)),
                  )),
      ),
    );
  }
}
