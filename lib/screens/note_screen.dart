
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/note.dart';
import '../widgets/note_item.dart';
import '../screens/note_edit_screen.dart';
//import '../globals.dart' as globals;

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});
  static const routeName = '/screen-note'; //nazwa trasy do tego ekranu
  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  bool _isInit = true;
  String wybranaData = DateTime.now().toString().substring(0, 4); //aktualny rok

  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<Notes>(context, listen: false)
          .fetchAndSetNotatki()
          .then((_) {
        //wszystkie znotatki z tabeli notatki z bazy lokalnej
      });
    }
    _isInit = false;

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    //tworzenie listy lat w których dokonywano notatki
    List<String> listaLat = [];
    int odRoku = 2022; //zeby najstarszym był rok 2023
    int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    while (odRoku < biezacyRok) {
      listaLat.add(biezacyRok.toString());
      biezacyRok = biezacyRok - 1;
    }
    //pobranie wszystkich notatek 
    final notatkiData = Provider.of<Notes>(context);
    List<Note> notatki = notatkiData.items.where((no) {
      return no.data.startsWith(wybranaData);
    }).toList();

  

  
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            AppLocalizations.of(context)!.nOtes,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          // title: Text('Edit inspection hive $numerUla'),
          // backgroundColor: Color.fromARGB(255, 233, 140, 0),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () =>
                  //_showAlert(context, frames[0].pasiekaNr, frames[0].ulNr)
                  Navigator.of(context).pushNamed(
                NoteEditScreen.routeName,
                arguments: {'temp': 1},
              ),
              //print('dodaj zbior'),
            ),
            // IconButton(
            //   icon: Icon(Icons.edit),
            //   onPressed: () => Navigator.of(context)
            //       .pushNamed(FramesDetailScreen.routeName, arguments: {
            //     'ul': globals.ulID,
            //     'data': wybranaData,
            //   }),
            // )
          ],
        ),
        body: notatki.length == 0
            ? Center(
                child: Column(
                  children: <Widget>[
//daty, zeby mozna było wybrać inna datę jezeli nie ma notatek w wybranym roku
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 18.0, vertical: 15.0),
                      height: 76, //MediaQuery.of(context).size.height * 0.35,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: listaLat.length,
                          itemBuilder: (context, index) {
                            return Container(
                              //width: MediaQuery.of(context).size.width * 0.6,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    wybranaData = listaLat[index];
                                  });
                                },
                                child: wybranaData == listaLat[index]
                                    ? Card(
                                        color: Colors.white,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.0, vertical: 1.0),
                                          child: Center(
                                              child: Text(
                                            '  ${listaLat[index]}  ', //nazwa
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 17.0),
                                          )),
                                        ),
                                      )
                                    : Card(
                                        color: Colors.white,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.0, vertical: 1.0),
                                          child: Center(
                                              child: Text(
                                            '  ${listaLat[index]}  ',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 17.0),
                                          )),
                                        ),
                                      ),
                              ),
                            );
                          }),
                    ),

                    Container(
                      padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                      child: Text(
                        AppLocalizations.of(context)!.noNoteYet,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(children: <Widget>[
//daty
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 18.0, vertical: 15.0),
                  height: 76, //MediaQuery.of(context).size.height * 0.35,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: listaLat.length,
                      itemBuilder: (context, index) {
                        return Container(
                          //width: MediaQuery.of(context).size.width * 0.6,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                wybranaData = listaLat[index];
                              });
                            },
                            child: wybranaData == listaLat[index]
                                ? Card(
                                    color: Colors.white,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 1.0),
                                      child: Center(
                                          child: Text(
                                        '  ${listaLat[index]}  ', //nazwa
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 17.0),
                                      )),
                                    ),
                                  )
                                : Card(
                                    color: Colors.white,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 1.0),
                                      child: Center(
                                          child: Text(
                                        '  ${listaLat[index]}  ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 17.0),
                                      )),
                                    ),
                                  ),
                          ),
                        );
                      }),
                ),

//Statystyki zbiorów dla biezacego roku
                //if (wybranaKategoria == 'harvest')
                // Container(
                //   // decoration: BoxDecoration( 
                //   //     border: Border.all(
                //   //     color: Colors.black,
                //   //     width: 2.0,
                //   //   ),),        
                //   margin: EdgeInsets.all(1),
                //   height: wysokoscStatystyk,
                //   child: Column(
                //     mainAxisAlignment: MainAxisAlignment.start,
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       if (miod != 0)
                //         Text(AppLocalizations.of(context)!.honey + ': ${miod.toStringAsFixed(2)} l (${(miod * 1.38).toStringAsFixed(2)} kg)',
                //             style: const TextStyle(fontSize: 16)),
                //       if (pylek != 0)
                //         Text(AppLocalizations.of(context)!.beePollen + ': ${pylek.toStringAsFixed(2)} l (${(pylek * 0.67).toStringAsFixed(2)} kg)',
                //             style: const TextStyle(fontSize: 16)),
                //       if (pierzga != 0)
                //         Text(AppLocalizations.of(context)!.perga + ': ${pierzga.toStringAsFixed(2)} l (${(pierzga * 0.73).toStringAsFixed(2)} kg)',
                //             style: const TextStyle(fontSize: 16)),
                //       if (wosk != 0)
                //         Text(AppLocalizations.of(context)!.wax + ': ${wosk} kg',
                //             style: const TextStyle(fontSize: 16)),
                //       if (propolis != 0)
                //         Text('propolis: ${propolis} kg',
                //             style: const TextStyle(fontSize: 16)),
                //     ],
                //   ),
                // ),
                
                // const Divider(
                //   height: 10,
                //   thickness: 1,
                //   indent: 0,
                //   endIndent: 0,
                //   color: Colors.black,
                // ),
                Expanded(
                  child: ListView.builder(
                    itemCount: notatki.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: notatki[i],
                      child: NoteItem(),
                    ),
                  ),
                )
              ]));
  }
}
