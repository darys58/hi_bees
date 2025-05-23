
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/harvest.dart';
import '../widgets/harvest_item.dart';
import '../screens/harvest_edit_screen.dart';
import '../globals.dart' as globals;

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});
  static const routeName = '/screen-harvest'; //nazwa trasy do tego ekranu
  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  bool _isInit = true;
  String wybranaData = DateTime.now().toString().substring(0, 4); //aktualny rok

  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<Harvests>(context, listen: false)
          .fetchAndSetZbiory()
          .then((_) {
        //wszystkie zbiory z tabeli zbiory z bazy lokalnej
      });
    }
    _isInit = false;

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    //tworzenie listy lat w których dokonywano zbiory
    List<String> listaLat = [];
    int odRoku = 2022; //zeby najstarszym był rok 2023
    int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    while (odRoku < biezacyRok) {
      listaLat.add(biezacyRok.toString());
      biezacyRok = biezacyRok - 1;
    }
    //pobranie wszystkich zbiorow dla ula
    final zbioryData = Provider.of<Harvests>(context);
    List<Harvest> zbiory = zbioryData.items.where((zb) {
      return zb.data.startsWith(wybranaData);
    }).toList();

    double miod = 0;
    double pylek = 0;
    double pierzga = 0;
    double wosk = 0;
    double propolis = 0;
    double wysokoscStatystyk = 15;

    //dla kazdego rodzaju zbiorów -  podliczenie roczne zbiorów
    for (var i = 0; i < zbiory.length; i++) {
      if (zbiory[i].data.substring(0, 4) == wybranaData) //dla wybranego roku
        switch (zbiory[i].zasobId) {
          case 1:
            zbiory[i].miara == 1
                ? miod = miod + zbiory[i].ilosc //l
                : miod = miod + zbiory[i].ilosc * 0.725; //podano w kg więc trzeba zamienić na l    1kg = 0.72l
            break;
          case 2:
            zbiory[i].miara == 1
                ? pylek = pylek + zbiory[i].ilosc
                : pylek = pylek + zbiory[i].ilosc * 1.579; //l    1kg = 1.579l
            break;
          case 3:
            zbiory[i].miara == 1
                ? pierzga = pierzga + zbiory[i].ilosc
                : pierzga = pierzga + zbiory[i].ilosc * 1.4; //l     1kg = 1.4l ???
            break;
          case 4:
            zbiory[i].miara == 1
                ? wosk = wosk //w litrach nie ma zliczania
                : wosk = wosk + zbiory[i].ilosc; //tylko w kilogramach
            break;
          case 5:
            zbiory[i].miara == 1
                ? propolis = propolis //w litrach nie ma zliczania
                : propolis = propolis + zbiory[i].ilosc; //tylko w kilogramach
            break;
          default:
        }
    }

    if (miod != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (pylek != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (pierzga != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (wosk != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (propolis != 0) wysokoscStatystyk = wysokoscStatystyk + 18;

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            AppLocalizations.of(context)!.hArvests,
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
                HarvestEditScreen.routeName,
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
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey[300], // kolor linii
              height: 1.0,
            ),
          ),
        ),
        body: zbiory.length == 0
            ? Center(
                child: Column(
                  children: <Widget>[
//daty, zeby mozna było wybrać inna datę jezeli nie ma zbiorow w wybranym roku
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
                        AppLocalizations.of(context)!.noHarvestYet,
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
                Container(
                  // decoration: BoxDecoration( 
                  //     border: Border.all(
                  //     color: Colors.black,
                  //     width: 2.0,
                  //   ),),        
                  margin: EdgeInsets.all(1),
                  height: wysokoscStatystyk,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (miod != 0)
                        globals.jezyk == 'pl_PL'
                          ? Text(AppLocalizations.of(context)!.honey + ': ${miod.toStringAsFixed(2).replaceAll('.', ',')} l (${(miod * 1.38).toStringAsFixed(2).replaceAll('.', ',')} kg)',
                            style: const TextStyle(fontSize: 16))
                          : Text(AppLocalizations.of(context)!.honey + ': ${miod.toStringAsFixed(2)} l (${(miod * 1.38).toStringAsFixed(2)} kg)',
                            style: const TextStyle(fontSize: 16)),
                      if (pylek != 0)
                        globals.jezyk == 'pl_PL'
                          ? Text(AppLocalizations.of(context)!.beePollen + ': ${pylek.toStringAsFixed(2).replaceAll('.', ',')} l (${(pylek * 0.67).toStringAsFixed(2).replaceAll('.', ',')} kg)',
                            style: const TextStyle(fontSize: 16))
                          : Text(AppLocalizations.of(context)!.beePollen + ': ${pylek.toStringAsFixed(2)} l (${(pylek * 0.67).toStringAsFixed(2)} kg)',
                            style: const TextStyle(fontSize: 16)),
                      if (pierzga != 0)
                        globals.jezyk == 'pl_PL'
                          ? Text(AppLocalizations.of(context)!.perga + ': ${pierzga.toStringAsFixed(2).replaceAll('.', ',')} l (${(pierzga * 0.73).toStringAsFixed(2).replaceAll('.', ',')} kg)',
                            style: const TextStyle(fontSize: 16))
                          : Text(AppLocalizations.of(context)!.perga + ': ${pierzga.toStringAsFixed(2)} l (${(pierzga * 0.73).toStringAsFixed(2)} kg)',
                            style: const TextStyle(fontSize: 16)),
                      if (wosk != 0)
                        globals.jezyk == 'pl_PL'
                          ? Text(AppLocalizations.of(context)!.wax + ': ${wosk.toString().replaceAll('.', ',')} kg',
                            style: const TextStyle(fontSize: 16))
                          : Text(AppLocalizations.of(context)!.wax + ': ${wosk} kg',
                            style: const TextStyle(fontSize: 16)),
                      if (propolis != 0)
                        globals.jezyk == 'pl_PL'
                          ? Text('propolis: ${propolis.toString().replaceAll('.', ',')} kg',
                            style: const TextStyle(fontSize: 16))
                          : Text('propolis: ${propolis} kg',
                            style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const Divider(
                  height: 10,
                  thickness: 1,
                  indent: 0,
                  endIndent: 0,
                  color: Colors.black,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: zbiory.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: zbiory[i],
                      child: HarvestItem(),
                    ),
                  ),
                )
              ]));
  }
}
