import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_beep/flutter_beep.dart';

import '../globals.dart' as globals;
import '../screens/hives_screen.dart';
import '../screens/apiarys_screen.dart';
import '../models/apiary.dart';

class ApiarysItem extends StatelessWidget {
  List<Color> color = [
    const Color.fromARGB(255, 252, 193, 104),
    const Color.fromARGB(255, 255, 114, 104),
    const Color.fromARGB(255, 104, 187, 254),
    const Color.fromARGB(255, 99, 255, 104),
    const Color.fromARGB(255, 255, 217, 104),
    const Color.fromARGB(255, 253, 182, 76),
    const Color.fromARGB(255, 255, 86, 74),
    const Color.fromARGB(255, 71, 170, 251),
    const Color.fromARGB(255, 70, 255, 76),
    const Color.fromARGB(255, 255, 209, 73),
  ];

  @override
  Widget build(BuildContext context) {
    final apiary = Provider.of<Apiary>(context, listen: false);

    //int ileUli = 0;

    //obliczanie róznicy miedzy dwoma datami
    int daysBetween(DateTime from, DateTime to) {
      from = DateTime(from.year, from.month, from.day);
      to = DateTime(to.year, to.month, to.day);
      return (to.difference(from).inHours / 24).round();
    }

    //obliczenie ile dni od odtatniego przeglądu
    final przeglad = DateTime.parse(apiary.przeglad);
    final now = DateTime.now();
    final difference = daysBetween(przeglad, now);
    print('apiary.przeglad');
    print('${apiary.przeglad}');

    return InkWell(
      onTap: () {
        //FlutterBeep.playSysSound(iOSSoundIDs.Headset_TransitionEnd);
        globals.pasiekaID = apiary.pasiekaNr;
        Navigator.of(context).pushNamed(
          HivesScreen.routeName,
          arguments: {'numerPasieki': apiary.pasiekaNr},
        );
      },
      splashColor: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(255, 115, 115, 115).withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(1, 3), // changes position of shadow
            ),
          ],
          gradient: LinearGradient(
            colors: [
              color[int.parse(apiary.id) - 1].withOpacity(0.7),
              color[int.parse(apiary.id) - 1],
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              //całą zawatość kolmny stanowi wiersz
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Container(
                    //zeby zrobić margines wokół części tekstowej
                    padding: const EdgeInsets.all(
                        6.00), //margines wokół części tekstowej
                    child: Column(
                      //ustawienie elementów jeden pod drugim - tytuł i opis
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Apiary ${apiary.id}',
                          style: Theme.of(context).textTheme.headline6,

//nazwa pasieki

                          // style: const TextStyle(
                          //   fontSize: 15,
                          //   color: Color.fromARGB(255, 0, 0, 0),
                          //   fontWeight: FontWeight.bold,
                          //),
                          softWrap: false, //zawijanie tekstu
                          overflow: TextOverflow.fade, //skracanie tekstu
                        ),
                        Container(
//pojemnik na datę ostatniego przeglądu
                          padding: const EdgeInsets.only(top: 2),
                          height: 18,
                          child:
                              //ilość dni od ostatniego przegladu
                              apiary.ileUli != '1'
                                  ? Text(
                                      '${apiary.ileUli} hives / $difference days',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color.fromARGB(255, 69, 69, 69),
                                      ),
                                      softWrap: true, //zawijanie tekstu
                                      maxLines: 2, //ilość wierszy opisu
                                      overflow: TextOverflow
                                          .ellipsis, //skracanie tekstu
                                    )
                                  : Text(
                                      '${apiary.ileUli} hive / $difference days',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color.fromARGB(255, 69, 69, 69),
                                      ),
                                      softWrap: true, //zawijanie tekstu
                                      maxLines: 2, //ilość wierszy opisu
                                      overflow: TextOverflow
                                          .ellipsis, //skracanie tekstu
                                    ),
                        ),
                        Padding(
                          //odstępy dla wiersza z ikonami
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
//rząd z ikonami
                            mainAxisAlignment: MainAxisAlignment
                                .spaceAround, //główna oś wyrównywania
                            children: <Widget>[
                              //elementy rzędu które sa widzetami
                              Row(
                                children: <Widget>[
                                  // Icon( //jezeli np. kelner bo typ = 6
                                  //     Icons.thumb_up_off_alt,
                                  //     color: Color.fromARGB(255, 0, 253, 76),
                                  //   ),
                                  const SizedBox(
                                    width: 0,
                                  ),
//ikona zielona, zółta, czerwona
                                  apiary.ikona == 'green'
                                      ? const Icon(
                                          Icons.hive,
                                          color: Color.fromARGB(255, 0, 255, 0),
                                        )
                                      : apiary.ikona == 'yellow'
                                          ? const Icon(
                                              Icons.hive,
                                              color: Color.fromARGB(
                                                  255, 255, 251, 0),
                                            )
                                          : const Icon(
                                              Icons.hive,
                                              color: Color.fromARGB(
                                                  255, 255, 0, 0),
                                            ),
                                  const SizedBox(
                                    width: 0,
                                  ), //odległość
                                  // Icon( //jezeli np. kelner bo typ = 6
                                  //     Icons.thumb_down_off_alt,
                                  //     color: Color.fromARGB(255, 253, 3, 3),
                                  // ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Text(
        //   'Apiary ${apiary.id}',
        //   style: Theme.of(context).textTheme.headline6,
        // ),
      ),
    );
  }
}
