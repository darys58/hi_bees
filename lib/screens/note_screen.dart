
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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

  //kalendarz zadań - podgląd zaplanowanych zadań
  Future<void> _showTaskCalendar(BuildContext context) async {
    // Pobierz świeże dane notatek
    await Provider.of<Notes>(context, listen: false).fetchAndSetNotatki();
    final allNotes = Provider.of<Notes>(context, listen: false).items;

    // Buduj mapę dni z istniejącymi zadaniami
    final Map<DateTime, List<Note>> taskMap = {};
    for (final note in allNotes) {
      if (note.priorytet == 'true' && note.pole1.isNotEmpty) {
        try {
          final date = DateTime.parse(note.pole1);
          final normalizedDate = DateTime.utc(date.year, date.month, date.day);
          taskMap.putIfAbsent(normalizedDate, () => []);
          taskMap[normalizedDate]!.add(note);
        } catch (_) {
          // Pomiń notatki z nieprawidłową datą
        }
      }
    }

    DateTime focusedDay = DateTime.now();
    DateTime? selectedDay;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            final normalizedSelected = selectedDay != null
                ? DateTime.utc(selectedDay!.year, selectedDay!.month, selectedDay!.day)
                : null;
            final tasksOnDay = normalizedSelected != null
                ? taskMap[normalizedSelected] ?? []
                : <Note>[];

            return Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                    child: Text(
                      AppLocalizations.of(context)!.taskCalendar,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TableCalendar<Note>(
                    locale: Localizations.localeOf(context).toString(),
                    firstDay: DateTime(2000),
                    lastDay: DateTime(2100),
                    focusedDay: focusedDay,
                    selectedDayPredicate: (day) =>
                        selectedDay != null && isSameDay(selectedDay, day),
                    eventLoader: (day) {
                      final normalizedDay = DateTime.utc(day.year, day.month, day.day);
                      return taskMap[normalizedDay] ?? [];
                    },
                    calendarBuilders: CalendarBuilders<Note>(
                      markerBuilder: (context, day, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            bottom: 1,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onDaySelected: (selected, focused) {
                      setDialogState(() {
                        selectedDay = selected;
                        focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) {
                      setDialogState(() {
                        focusedDay = focused;
                      });
                    },
                  ),
                  // Lista zadań na wybrany dzień
                  if (selectedDay != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: tasksOnDay.isNotEmpty
                          ? ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 150),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(),
                                    Text(
                                      DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(selectedDay!),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    SizedBox(height: 4),
                                    ...tasksOnDay.map((note) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Text(
                                            '- ${note.tytul}: ${note.notatka}',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                AppLocalizations.of(context)!.taskNoTasks,
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //tworzenie listy lat w których dokonywano notatki
    // List<String> listaLat = [];
    // int odRoku = 2022; //zeby najstarszym był rok 2023
    // int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    // while (odRoku < biezacyRok) {
    //   listaLat.add(biezacyRok.toString());
    //   biezacyRok = biezacyRok - 1;
    // }

    //pobranie wszystkich notatek
    final noteDataAll = Provider.of<Notes>(context);
    List<Note> notatkiAll = noteDataAll.items.where((pur) {
      return pur.data.startsWith('20');
    }).toList();

    List<String> listaLat = []; //lista lat w których dokonywano notatek
    int odRoku = int.parse(DateTime.now().toString().substring(0, 4)); //biezący rok

    //poszukanie najstarszego roku w którym dokonano notatek
    for (var i = 0; i < notatkiAll.length; i++) {
      if(odRoku > int.parse(notatkiAll[i].data.substring(0, 4)))
        odRoku = int.parse(notatkiAll[i].data.substring(0, 4));
    }
    
    //tworzenie listy lat w których dokonywano notatek
    int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    while (odRoku <= biezacyRok) {
      listaLat.add(biezacyRok.toString());
      biezacyRok = biezacyRok - 1;
    }
   
    //pobranie wszystkich notatek z wybranego roku
    final notatkiData = Provider.of<Notes>(context);
    List<Note> notatki = notatkiData.items.where((no) {
      return no.data.startsWith(wybranaData); //z datą zaczynajacą się od wybranego roku
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
            IconButton(
              icon: Icon(Icons.calendar_month, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () => _showTaskCalendar(context),
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
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey[300], // kolor linii
              height: 1.0,
            ),
          ),
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
