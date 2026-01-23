import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/sale.dart';
import '../widgets/sale_item.dart';
import '../screens/sale_edit_screen.dart';
import '../globals.dart' as globals;

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});
  static const routeName = '/screen-sale'; //nazwa trasy do tego ekranu
  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  bool _isInit = true;
  String wybranaData = DateTime.now().toString().substring(0, 4); //aktualny rok
  double miod = 0; //ilość w l
  double miodWartoscInnaPLN = 0; //wartość miodu w nietypowym opakowaniu (miara = '')
  double miodWartoscInnaEUR = 0;
  double miodWartoscInnaUSD = 0;
  double miodWartoscPLN = 0; //wartość
  double miodWartoscEUR = 0;
  double miodWartoscUSD = 0;
  double pylek = 0; //ilość w l
  double pylekWartoscPLN = 0;
  double pylekWartoscEUR = 0;
  double pylekWartoscUSD = 0;
  double pylekWartoscInnaPLN = 0;
  double pylekWartoscInnaEUR = 0;
  double pylekWartoscInnaUSD = 0;
  double pierzga = 0; //ilość w l
  double pierzgaWartoscPLN = 0;
  double pierzgaWartoscEUR = 0;
  double pierzgaWartoscUSD = 0;
  double pierzgaWartoscInnaPLN = 0;
  double pierzgaWartoscInnaEUR = 0;
  double pierzgaWartoscInnaUSD = 0;
  double woskWartoscPLN = 0;
  double woskWartoscEUR = 0;
  double woskWartoscUSD = 0;
  double propolisWartoscPLN = 0;
  double propolisWartoscEUR = 0;
  double propolisWartoscUSD = 0;

  double razemWartoscPLN = 0;
  double razemWartoscEUR = 0;
  double razemWartoscUSD = 0;
  double wysokoscStatystyk = 15;

  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<Sales>(context) //, listen: false
          .fetchAndSetSprzedaz()
          .then((_) {
        //wszystkie sprzedaz z tabeli sprzedaz z bazy lokalnej
      });
    }
    _isInit = false;

    super.didChangeDependencies();
  }

  dodajWartoscMiodu(waluta, wartosc) {
    switch (waluta) {
      case 1:
        miodWartoscPLN += wartosc;
        break;
      case 2:
        miodWartoscEUR += wartosc;
        break;
      case 3:
        miodWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartoscPylku(waluta, wartosc) {
    switch (waluta) {
      case 1:
        pylekWartoscPLN += wartosc;
        break;
      case 2:
        pylekWartoscEUR += wartosc;
        break;
      case 3:
        pylekWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartoscPierzgi(waluta, wartosc) {
    switch (waluta) {
      case 1:
        pierzgaWartoscPLN += wartosc;
        break;
      case 2:
        pierzgaWartoscEUR += wartosc;
        break;
      case 3:
        pierzgaWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartoscWosku(waluta, wartosc) {
    switch (waluta) {
      case 1:
        woskWartoscPLN += wartosc;
        break;
      case 2:
        woskWartoscEUR += wartosc;
        break;
      case 3:
        woskWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartoscPropolisu(waluta, wartosc) {
    switch (waluta) {
      case 1:
        propolisWartoscPLN += wartosc;
        break;
      case 2:
        propolisWartoscEUR += wartosc;
        break;
      case 3:
        propolisWartoscUSD += wartosc;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    miod = 0; //ilość w l
    miodWartoscInnaPLN = 0; //wartość miodu w nietypowym opakowaniu (miara = '')
    miodWartoscInnaEUR = 0;
    miodWartoscInnaUSD = 0;
    miodWartoscPLN = 0; //wartość
    miodWartoscEUR = 0;
    miodWartoscUSD = 0;
    pylek = 0;
    pylekWartoscPLN = 0;
    pylekWartoscEUR = 0;
    pylekWartoscUSD = 0;
    pylekWartoscInnaPLN = 0;
    pylekWartoscInnaEUR = 0;
    pylekWartoscInnaUSD = 0;
    pierzga = 0;
    pierzgaWartoscPLN = 0;
    pierzgaWartoscEUR = 0;
    pierzgaWartoscUSD = 0;
    pierzgaWartoscInnaPLN = 0;
    pierzgaWartoscInnaEUR = 0;
    pierzgaWartoscInnaUSD = 0;
    woskWartoscPLN = 0;
    woskWartoscEUR = 0;
    woskWartoscUSD = 0;
    propolisWartoscPLN = 0;
    propolisWartoscEUR = 0;
    propolisWartoscUSD = 0;
    razemWartoscPLN = 0;
    razemWartoscEUR = 0;
    razemWartoscUSD = 0;
    wysokoscStatystyk = 15;

    // //tworzenie listy lat w których dokonywano sprzedaz
    // List<String> listaLat = [];
    // int odRoku = 2022; //zeby najstarszym był rok 2023
    // int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    // while (odRoku < biezacyRok) {
    //   listaLat.add(biezacyRok.toString());
    //   biezacyRok = biezacyRok - 1;
    // }
    
    //pobranie wszystkich sprzedazy
    final saleDataAll = Provider.of<Sales>(context);
    List<Sale> sprzedazAll = saleDataAll.items.where((pur) {
      return pur.data.startsWith('20');
    }).toList();

    List<String> listaLat = []; //lista lat w których dokonywano sprzedazy
    int odRoku = int.parse(DateTime.now().toString().substring(0, 4)); //biezący rok

    //poszukanie najstarszego roku w którym dokonano sprzedazy
    for (var i = 0; i < sprzedazAll.length; i++) {
      if(odRoku > int.parse(sprzedazAll[i].data.substring(0, 4)))
        odRoku = int.parse(sprzedazAll[i].data.substring(0, 4));
    }
    
    //tworzenie listy lat w których dokonywano sprzedazy
    int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    while (odRoku <= biezacyRok) {
      listaLat.add(biezacyRok.toString());
      biezacyRok = biezacyRok - 1;
    }
    
    //pobranie wszystkich sprzedazy z wybranego roku
    final saleData = Provider.of<Sales>(context);
    List<Sale> sprzedaz = saleData.items.where((sa) {
      return sa.data.startsWith(wybranaData);
    }).toList();

    //dla kazdego rodzaju produktów -  podliczenie roczne sprzedazy
    for (var i = 0; i < sprzedaz.length; i++) {
      if (sprzedaz[i].data.substring(0, 4) == wybranaData) //dla wybranego roku
        switch (sprzedaz[i].kategoriaId) {
          //1-miód, 2-pyłek, 3-pierzga, 4-wosk, 5-kit, (6-świeczki, 7-propolis, 8-maść, 9-odkład, 10-matka, )
          case 1:
            switch (sprzedaz[i].miara) {
              case 1: //opakowanie nieokreslone
                switch (sprzedaz[i].waluta) {
                  case 1:
                    miodWartoscInnaPLN += sprzedaz[i].wartosc;
                    break;
                  case 2:
                    miodWartoscInnaEUR += sprzedaz[i].wartosc;
                    break;
                  case 3:
                    miodWartoscInnaUSD += sprzedaz[i].wartosc;
                    break;
                }
                break;
              case 2:
                miod += sprzedaz[i].ilosc * 0.9; //słoik 0,9 l
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 3: //słoik 0,72 l
                miod += sprzedaz[i].ilosc * 0.72; //l
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 4:
                miod += sprzedaz[i].ilosc * 0.5; //l
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 5:
                miod += sprzedaz[i].ilosc * 0.35; //l
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 6:
                miod += sprzedaz[i].ilosc * 0.315; //l
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 7:
                miod += sprzedaz[i].ilosc * 0.200; //l
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 8:
                miod += sprzedaz[i].ilosc * 0.100; //l
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 9:
                miod += sprzedaz[i].ilosc * 0.05; //l
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 10:
                miod += sprzedaz[i].ilosc * 0.03; //l
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 21:
                miod += sprzedaz[i].ilosc * 0.725; //l 1000g
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 22:
                miod += sprzedaz[i].ilosc * 0.362; //l 500g
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 23:
                miod += sprzedaz[i].ilosc * 0.18; //l 250g
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 24:
                miod += sprzedaz[i].ilosc * 0.072; //l 100g
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 25:
                miod += sprzedaz[i].ilosc * 0.036; //l 50g
                dodajWartoscMiodu(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
            }
            break;
          // case 2:
          //   sprzedaz[i].miara == 1
          //       ? pylek = pylek + sprzedaz[i].ilosc
          //       : pylek = pylek + sprzedaz[i].ilosc * 1.493; //1kg = 1.5l
          //   break;
          case 2: //pylek
            switch (sprzedaz[i].miara) {
              case 1: //opakowanie niestandardowe
                switch (sprzedaz[i].waluta) {
                  case 1:
                    pylekWartoscInnaPLN += sprzedaz[i].wartosc;
                    break;
                  case 2:
                    pylekWartoscInnaEUR += sprzedaz[i].wartosc;
                    break;
                  case 3:
                    pylekWartoscInnaUSD += sprzedaz[i].wartosc;
                    break;
                }
                break;
              case 2:
                pylek += sprzedaz[i].ilosc * 0.9; //w słoiku 0,9l
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 3:
                pylek += sprzedaz[i].ilosc * 0.72; //l
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 4:
                pylek += sprzedaz[i].ilosc * 0.5; //l
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 5:
                pylek += sprzedaz[i].ilosc * 0.35; //l
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 6:
                pylek += sprzedaz[i].ilosc * 0.315; //l
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 7:
                pylek += sprzedaz[i].ilosc * 0.200; //l
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 8:
                pylek += sprzedaz[i].ilosc * 0.100; //l
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 9:
                pylek += sprzedaz[i].ilosc * 0.05; //l
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 10:
                pylek += sprzedaz[i].ilosc * 0.03; //l
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 21:
                pylek += sprzedaz[i].ilosc * 1.579; //l 1000g  (1,579l = 1kg)
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 22:
                pylek += sprzedaz[i].ilosc * 0.789; //l 500g  (0,589 l = 0,5kg)
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 23:
                pylek += sprzedaz[i].ilosc * 0.395; //l 250g
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 24:
                pylek += sprzedaz[i].ilosc * 0.158; //l 100g
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 25:
                pylek += sprzedaz[i].ilosc * 0.079; //l 50g
                dodajWartoscPylku(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
            }
            break;
          // case 3:
          //   sprzedaz[i].miara == 1
          //       ? pierzga = pierzga + sprzedaz[i].ilosc
          //       : pierzga = pierzga + sprzedaz[i].ilosc * 1.4; //1kg = 1.4l ???
          //   break;
          case 3:
            switch (sprzedaz[i].miara) {
              case 1:
                switch (sprzedaz[i].waluta) {
                  case 1:
                    pierzgaWartoscInnaPLN += sprzedaz[i].wartosc;
                    break;
                  case 2:
                    pierzgaWartoscInnaEUR += sprzedaz[i].wartosc;
                    break;
                  case 3:
                    pierzgaWartoscInnaUSD += sprzedaz[i].wartosc;
                    break;
                }
                break;
              case 2:
                pierzga += sprzedaz[i].ilosc * 0.9; //w słoiku 0,9l
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 3:
                pierzga += sprzedaz[i].ilosc * 0.72; //l
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 4:
                pierzga += sprzedaz[i].ilosc * 0.5; //l
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 5:
                pierzga += sprzedaz[i].ilosc * 0.35; //l
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 6:
                pierzga += sprzedaz[i].ilosc * 0.315; //l
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 7:
                pierzga += sprzedaz[i].ilosc * 0.200; //l
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 8:
                pierzga += sprzedaz[i].ilosc * 0.100; //l
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 9:
                pierzga += sprzedaz[i].ilosc * 0.05; //l
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 10:
                pierzga += sprzedaz[i].ilosc * 0.03; //l
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 21:
                pierzga +=
                    sprzedaz[i].ilosc * 1.4; //l 1000g  (1,4l = 1kg)???????
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 22:
                pierzga += sprzedaz[i].ilosc * 0.7; //l 500g  (0,7 = 0,5kg)
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 23:
                pierzga += sprzedaz[i].ilosc * 0.35; //l 250g
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 24:
                pierzga += sprzedaz[i].ilosc * 0.14; //l 100g
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
              case 25:
                pierzga += sprzedaz[i].ilosc * 0.07; //l 50g
                dodajWartoscPierzgi(sprzedaz[i].waluta, sprzedaz[i].wartosc);
                break;
            }
            break;

          case 4: // nie ma zliczania ilości
            switch (sprzedaz[i].waluta) {
              case 1:
                woskWartoscPLN += sprzedaz[i].wartosc;
                break;
              case 2:
                woskWartoscEUR += sprzedaz[i].wartosc;
                break;
              case 3:
                woskWartoscUSD += sprzedaz[i].wartosc;
                break;
            }
            break;

          case 5:
            switch (sprzedaz[i].waluta) {
              case 1:
                propolisWartoscPLN += sprzedaz[i].wartosc;
                break;
              case 2:
                propolisWartoscEUR += sprzedaz[i].wartosc;
                break;
              case 3:
                propolisWartoscUSD += sprzedaz[i].wartosc;
                break;
            }
            break;
          default:
        }
      if (i == sprzedaz.length - 1) {
        razemWartoscPLN = miodWartoscInnaPLN +
            miodWartoscPLN +
            pylekWartoscInnaPLN +
            pylekWartoscPLN +
            pierzgaWartoscInnaPLN +
            pierzgaWartoscPLN +
            woskWartoscPLN +
            propolisWartoscPLN;
        razemWartoscEUR = miodWartoscInnaEUR +
            miodWartoscEUR +
            pylekWartoscInnaEUR +
            pylekWartoscEUR +
            pierzgaWartoscInnaEUR +
            pierzgaWartoscEUR +
            woskWartoscEUR +
            propolisWartoscEUR;
        razemWartoscUSD = miodWartoscInnaUSD +
            miodWartoscUSD +
            pylekWartoscInnaUSD +
            pylekWartoscUSD +
            pierzgaWartoscInnaUSD +
            pierzgaWartoscUSD +
            woskWartoscUSD +
            propolisWartoscUSD;
      }
      //print('miod = $miod');
      //print('pylek = $pylek');
      //print('pierzga = $pierzga');
    }

    if (miod != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (miodWartoscInnaPLN != 0 ||
        miodWartoscInnaEUR != 0 ||
        miodWartoscInnaUSD != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (pylek != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (pylekWartoscInnaPLN != 0 ||
        pylekWartoscInnaEUR != 0 ||
        pylekWartoscInnaUSD != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (pierzga != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (pierzgaWartoscInnaPLN != 0 ||
        pierzgaWartoscInnaEUR != 0 ||
        pierzgaWartoscInnaUSD != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (woskWartoscPLN != 0 || woskWartoscEUR != 0 || woskWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;
    if (propolisWartoscPLN != 0 ||
        propolisWartoscEUR != 0 ||
        propolisWartoscUSD != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (razemWartoscPLN != 0 || razemWartoscEUR != 0 || razemWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            AppLocalizations.of(context)!.sAle,
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
                SaleEditScreen.routeName,
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
        body: sprzedaz.length == 0
            ? Center(
                child: Column(
                  children: <Widget>[
//daty, zeby mozna było wybrać inna datę jezeli nie ma sprzedazy w wybranym roku
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
                      padding:
                          const EdgeInsets.only(top: 50, left: 20, right: 20),
                      child: Text(
                        AppLocalizations.of(context)!.noSaleYet,
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

//Statystyki sprzedazy dla wybranego roku
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
        //sprzedaz miodu
                      if (miod != 0)
                        RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              globals.jezyk == 'pl_PL'
                                  ? TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po polsku
                                      text: (AppLocalizations.of(context)!
                                              .honey +
                                          ': ${miod.toStringAsFixed(1).replaceAll('.', ',')} l (${(miod * 1.38).toStringAsFixed(1).replaceAll('.', ',')} kg)'),
                                      style: TextStyle(
                                          fontSize: 16,
                                          //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  : TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po angielsku
                                      text: (AppLocalizations.of(context)!
                                              .honey +
                                          ': ${miod.toStringAsFixed(1)} l (${(miod * 1.38).toStringAsFixed(1)} kg)'),
                                      style: TextStyle(
                                          fontSize: 16,
                                          //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),
                              if (miodWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${miodWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (miodWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (miodWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${miodWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (miodWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (miodWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${miodWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (miodWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),

      //sprzedaz miodu w innych opakowaniach
                      if (miodWartoscInnaPLN != 0 ||
                          miodWartoscInnaEUR != 0 ||
                          miodWartoscInnaUSD != 0)
                        RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              TextSpan(
                                text: (AppLocalizations.of(context)!.honey +
                                    ': ' +
                                    AppLocalizations.of(context)!.otherSales),
                                style: TextStyle(
                                    fontSize: 16,
                                    //fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
                              if (miodWartoscInnaPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${miodWartoscInnaPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (miodWartoscInnaPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (miodWartoscInnaEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${miodWartoscInnaEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (miodWartoscInnaEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      //fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (miodWartoscInnaUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${miodWartoscInnaUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (miodWartoscInnaUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      //fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                            ])),

                      // if (pylek != 0)
                      //   globals.jezyk == 'pl_PL'
                      //       ? Text(
                      //           AppLocalizations.of(context)!.beePollen +
                      //               ': ${pylek.toStringAsFixed(2).replaceAll('.', ',')} l (${(pylek * 0.634).toStringAsFixed(2).replaceAll('.', ',')} kg) ${pylekWartoscPLN.toStringAsFixed(2).replaceAll('.', ',')} PLN',
                      //           style: const TextStyle(fontSize: 16))
                      //       : Text(
                      //           AppLocalizations.of(context)!.beePollen +
                      //               ': ${pylek.toStringAsFixed(2)} l (${(pylek * 0.634).toStringAsFixed(2)} kg) ${pylekWartoscPLN.toStringAsFixed(2)} PLN',
                      //           style: const TextStyle(fontSize: 16)),
      //sprzedaz pyłku
                      if (pylek != 0)
                        RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              globals.jezyk == 'pl_PL'
                                  ? TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po polsku
                                      text: (AppLocalizations.of(context)!
                                              .beePollen +
                                          ': ${pylek.toStringAsFixed(1).replaceAll('.', ',')} l (${(pylek * 0.634).toStringAsFixed(1).replaceAll('.', ',')} kg)'),
                                      style: TextStyle(
                                          fontSize: 16,
                                          //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  : TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po angielsku
                                      text: (AppLocalizations.of(context)!
                                              .beePollen +
                                          ': ${pylek.toStringAsFixed(1)} l (${(pylek * 0.634).toStringAsFixed(1)} kg)'),
                                      style: TextStyle(
                                          fontSize: 16,
                                          //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),
                              if (pylekWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${pylekWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pylekWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pylekWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${pylekWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pylekWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pylekWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${pylekWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pylekWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),

//sprzedaz pyleku w innych opakowaniach
                      if (pylekWartoscInnaPLN != 0 ||
                          pylekWartoscInnaEUR != 0 ||
                          pylekWartoscInnaUSD != 0)
                        RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              TextSpan(
                                text: (AppLocalizations.of(context)!.beePollen +
                                    ': ' +
                                    AppLocalizations.of(context)!.otherSales),
                                style: TextStyle(
                                    fontSize: 16,
                                    //fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
                              if (pylekWartoscInnaPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${pylekWartoscInnaPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pylekWartoscInnaPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pylekWartoscInnaEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${pylekWartoscInnaEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (pylekWartoscInnaEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      //fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (pylekWartoscInnaUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${pylekWartoscInnaUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (pylekWartoscInnaUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      //fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                            ])),

                      // if (pierzga != 0)
                      //   globals.jezyk == 'pl_PL'
                      //       ? Text(
                      //           AppLocalizations.of(context)!.perga +
                      //               ': ${pierzga.toStringAsFixed(2).replaceAll('.', ',')} l (${(pierzga * 0.75).toStringAsFixed(2).replaceAll('.', ',')} kg) ${pierzgaWartoscPLN.toStringAsFixed(2).replaceAll('.', ',')} PLN',
                      //           style: const TextStyle(fontSize: 16))
                      //       : Text(
                      //           AppLocalizations.of(context)!.perga +
                      //               ': ${pierzga.toStringAsFixed(2)} l (${(pierzga * 0.75).toStringAsFixed(2)} kg) ${pierzgaWartoscPLN.toStringAsFixed(2)} PLN',
                      //           style: const TextStyle(fontSize: 16)),

  //sprzedaz pierzgi
                      if (pierzga != 0)
                        RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              globals.jezyk == 'pl_PL'
                                  ? TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po polsku
                                      text: (AppLocalizations.of(context)!
                                              .perga +
                                          ': ${pierzga.toStringAsFixed(1).replaceAll('.', ',')} l (${(pierzga * 0.555).toStringAsFixed(1).replaceAll('.', ',')} kg)'),
                                      style: TextStyle(
                                          fontSize: 16,
                                          //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  : TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po angielsku
                                      text: (AppLocalizations.of(context)!
                                              .perga +
                                          ': ${pierzga.toStringAsFixed(1)} l (${(pierzga * 0.555).toStringAsFixed(1)} kg)'),
                                      style: TextStyle(
                                          fontSize: 16,
                                          //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),
                              if (pierzgaWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${pierzgaWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pierzgaWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pierzgaWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${pierzgaWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pierzgaWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pierzgaWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${pierzgaWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pierzgaWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),

  //sprzedaz pierzgi w innych opakowaniach
                      if (pierzgaWartoscInnaPLN != 0 ||
                          pierzgaWartoscInnaEUR != 0 ||
                          pierzgaWartoscInnaUSD != 0)
                        RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              TextSpan(
                                text: (AppLocalizations.of(context)!.perga +
                                    ': ' +
                                    AppLocalizations.of(context)!.otherSales),
                                style: TextStyle(
                                    fontSize: 16,
                                    //fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
                              if (pierzgaWartoscInnaPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${pierzgaWartoscInnaPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pierzgaWartoscInnaPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pierzgaWartoscInnaEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${pierzgaWartoscInnaEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (pierzgaWartoscInnaEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      //fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (pierzgaWartoscInnaUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${pylekWartoscInnaUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (pierzgaWartoscInnaUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      //fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                            ])),
  //sprzedaz wosku

                      if (woskWartoscPLN != 0 ||
                          woskWartoscEUR != 0 ||
                          woskWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.wax + ': '),
                                style: TextStyle(
                                    fontSize: 16,
                                    //fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
                              if (woskWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${woskWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (woskWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (woskWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${woskWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (woskWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      //fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (woskWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${woskWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (woskWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      //fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                            ])),
  //sprzedaz propolisu
                      if (propolisWartoscPLN != 0 ||
                          propolisWartoscEUR != 0 ||
                          propolisWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              TextSpan(
                                text: ('propolis: '),
                                style: TextStyle(
                                    fontSize: 16,
                                    //fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
                              if (propolisWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${propolisWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (propolisWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (propolisWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${propolisWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (propolisWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      //fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (propolisWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${propolisWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                              if (propolisWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      //fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                            ])),
  //RAZEM
                      SizedBox(height: 5),
                      RichText(
                          text: TextSpan(
                              text:
                                  (AppLocalizations.of(context)!.tOTAL) + ': ',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                              children: [
                            if (razemWartoscPLN != 0)
                              TextSpan(
                                text:
                                    (' ${razemWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (razemWartoscPLN != 0)
                              TextSpan(
                                text: (' PLN'),
                                style: TextStyle(
                                  fontSize: 12,
                                  //fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (razemWartoscEUR != 0)
                              TextSpan(
                                text:
                                    (' ${razemWartoscEUR.toStringAsFixed(0)}'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (razemWartoscEUR != 0)
                              TextSpan(
                                text: (' EUR'),
                                style: TextStyle(
                                  fontSize: 12,
                                  //fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (razemWartoscUSD != 0)
                              TextSpan(
                                text:
                                    (' ${razemWartoscUSD.toStringAsFixed(0)}'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (razemWartoscUSD != 0)
                              TextSpan(
                                text: (' USD'),
                                style: TextStyle(
                                  fontSize: 12,
                                  //fontWeight: FontWeight.bold,
                                ),
                              ),
                          ])),
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
                    itemCount: sprzedaz.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: sprzedaz[i],
                      child: SaleItem(),
                    ),
                  ),
                )
              ]));
  }
}
