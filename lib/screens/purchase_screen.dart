import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/purchase.dart';
import '../widgets/purchase_item.dart';
import '../screens/purchase_edit_screen.dart';
//import '../globals.dart' as globals;

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});
  static const routeName = '/screen-purchase'; //nazwa trasy do tego ekranu
  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  bool _isInit = true;
  String wybranaData = DateTime.now().toString().substring(0, 4); //aktualny rok

  double brakWartoscPLN = 0; //kategoria brak
  double brakWartoscEUR = 0;
  double brakWartoscUSD = 0;
  double opakowaniaWartoscPLN = 0;
  double opakowaniaWartoscEUR = 0;
  double opakowaniaWartoscUSD = 0;
  double wyposazenieWartoscPLN = 0;
  double wyposazenieWartoscEUR = 0;
  double wyposazenieWartoscUSD = 0;
  double pszczolyWartoscPLN = 0;
  double pszczolyWartoscEUR = 0;
  double pszczolyWartoscUSD = 0;
  double matkiWartoscPLN = 0;
  double matkiWartoscEUR = 0;
  double matkiWartoscUSD = 0;
  double wezaWartoscPLN = 0;
  double wezaWartoscEUR = 0;
  double wezaWartoscUSD = 0;
  double pokarmWartoscPLN = 0;
  double pokarmWartoscEUR = 0;
  double pokarmWartoscUSD = 0;
  double lekiWartoscPLN = 0;
  double lekiWartoscEUR = 0;
  double lekiWartoscUSD = 0;

  double razemWartoscPLN = 0;
  double razemWartoscEUR = 0;
  double razemWartoscUSD = 0;

  double wysokoscStatystyk = 15;

  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<Purchases>(context) //, listen: false
          .fetchAndSetZakupy()
          .then((_) {
        //wszystkie zakupy z tabeli zakupy z bazy lokalnej
      });
    }
    _isInit = false;

    super.didChangeDependencies();
  }

  dodajWartosc1(waluta, wartosc) {
    switch (waluta) {
      case 1:
        brakWartoscPLN += wartosc;
        break;
      case 2:
        brakWartoscEUR += wartosc;
        break;
      case 3:
        brakWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc2(waluta, wartosc) {
    switch (waluta) {
      case 1:
        opakowaniaWartoscPLN += wartosc;
        break;
      case 2:
        opakowaniaWartoscEUR += wartosc;
        break;
      case 3:
        opakowaniaWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc3(waluta, wartosc) {
    switch (waluta) {
      case 1:
        wyposazenieWartoscPLN += wartosc;
        break;
      case 2:
        wyposazenieWartoscEUR += wartosc;
        break;
      case 3:
        wyposazenieWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc4(waluta, wartosc) {
    switch (waluta) {
      case 1:
        pszczolyWartoscPLN += wartosc;
        break;
      case 2:
        pszczolyWartoscEUR += wartosc;
        break;
      case 3:
        pszczolyWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc5(waluta, wartosc) {
    switch (waluta) {
      case 1:
        matkiWartoscPLN += wartosc;
        break;
      case 2:
        matkiWartoscEUR += wartosc;
        break;
      case 3:
        matkiWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc6(waluta, wartosc) {
    switch (waluta) {
      case 1:
        wezaWartoscPLN += wartosc;
        break;
      case 2:
        wezaWartoscEUR += wartosc;
        break;
      case 3:
        wezaWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc7(waluta, wartosc) {
    switch (waluta) {
      case 1:
        pokarmWartoscPLN += wartosc;
        break;
      case 2:
        pokarmWartoscEUR += wartosc;
        break;
      case 3:
        pokarmWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc8(waluta, wartosc) {
    switch (waluta) {
      case 1:
        lekiWartoscPLN += wartosc;
        break;
      case 2:
        lekiWartoscEUR += wartosc;
        break;
      case 3:
        lekiWartoscUSD += wartosc;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    brakWartoscPLN = 0; //kategoria brak
    brakWartoscEUR = 0;
    brakWartoscUSD = 0;
    opakowaniaWartoscPLN = 0;
    opakowaniaWartoscEUR = 0;
    opakowaniaWartoscUSD = 0;
    wyposazenieWartoscPLN = 0;
    wyposazenieWartoscEUR = 0;
    wyposazenieWartoscUSD = 0;
    pszczolyWartoscPLN = 0;
    pszczolyWartoscEUR = 0;
    pszczolyWartoscUSD = 0;
    matkiWartoscPLN = 0;
    matkiWartoscEUR = 0;
    matkiWartoscUSD = 0;
    wezaWartoscPLN = 0;
    wezaWartoscEUR = 0;
    wezaWartoscUSD = 0;
    pokarmWartoscPLN = 0;
    pokarmWartoscEUR = 0;
    pokarmWartoscUSD = 0;
    lekiWartoscPLN = 0;
    lekiWartoscEUR = 0;
    lekiWartoscUSD = 0;
    razemWartoscPLN = 0;
    razemWartoscEUR = 0;
    razemWartoscUSD = 0;
    wysokoscStatystyk = 15;

    //tworzenie listy lat w których dokonywano zakupy
    List<String> listaLat = [];
    int odRoku = 2022; //zeby najstarszym był rok 2023
    int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    while (odRoku < biezacyRok) {
      listaLat.add(biezacyRok.toString());
      biezacyRok = biezacyRok - 1;
    }
    //pobranie wszystkich zakupów
    final purchaseData = Provider.of<Purchases>(context);
    List<Purchase> zakupy = purchaseData.items.where((pur) {
      return pur.data.startsWith(wybranaData);
    }).toList();

    //dla kazdego rodzaju kategorii -  podliczenie roczne zakupów
    for (var i = 0; i < zakupy.length; i++) {
      if (zakupy[i].data.substring(0, 4) == wybranaData) //dla wybranego roku
        switch (zakupy[i].kategoriaId) {
          //1-brak, 2-opakowania, 3-wyposazenie, 4-pszczoły, 5-matka, 6-węza, 7-pokarm, 8-leki,
          case 1: //brak
            dodajWartosc1(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 2:
            dodajWartosc2(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 3:
            dodajWartosc3(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 4:
            dodajWartosc4(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 5:
            dodajWartosc5(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 6:
            dodajWartosc6(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 7:
            dodajWartosc7(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 8:
            dodajWartosc8(zakupy[i].waluta, zakupy[i].wartosc);
            break;
        }

      if (i == zakupy.length - 1) {
        razemWartoscPLN = brakWartoscPLN +
            opakowaniaWartoscPLN +
            wyposazenieWartoscPLN +
            pszczolyWartoscPLN +
            matkiWartoscPLN +
            wezaWartoscPLN +
            pokarmWartoscPLN +
            lekiWartoscPLN;
        razemWartoscEUR = brakWartoscEUR +
            opakowaniaWartoscEUR +
            wyposazenieWartoscEUR +
            pszczolyWartoscEUR +
            matkiWartoscEUR +
            wezaWartoscEUR +
            pokarmWartoscEUR +
            lekiWartoscEUR;
        razemWartoscUSD = brakWartoscUSD +
            opakowaniaWartoscUSD +
            wyposazenieWartoscUSD +
            pszczolyWartoscUSD +
            matkiWartoscUSD +
            wezaWartoscUSD +
            pokarmWartoscUSD +
            lekiWartoscUSD;
      }
    }

    if (brakWartoscPLN != 0 || brakWartoscEUR != 0 || brakWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;
    if (opakowaniaWartoscPLN != 0 ||
        opakowaniaWartoscEUR != 0 ||
        opakowaniaWartoscUSD != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (wyposazenieWartoscPLN != 0 ||
        wyposazenieWartoscEUR != 0 ||
        wyposazenieWartoscUSD != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (pszczolyWartoscPLN != 0 ||
        pszczolyWartoscEUR != 0 ||
        pszczolyWartoscUSD != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (matkiWartoscPLN != 0 || matkiWartoscEUR != 0 || matkiWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;
    if (wezaWartoscPLN != 0 || wezaWartoscEUR != 0 || wezaWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;
    if (pokarmWartoscPLN != 0 || pokarmWartoscEUR != 0 || pokarmWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;
    if (lekiWartoscPLN != 0 || lekiWartoscEUR != 0 || lekiWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;
    if (razemWartoscPLN != 0 || razemWartoscEUR != 0 || razemWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            AppLocalizations.of(context)!.pUrchase,
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
                PurchaseEditScreen.routeName,
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
        body: zakupy.length == 0
            ? Center(
                child: Column(
                  children: <Widget>[
//daty, zeby mozna było wybrać inna datę jezeli nie ma zakupów w wybranym roku
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
                        AppLocalizations.of(context)!.noPurchaseYet,
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

//Statystyki zakupyy dla wybranego roku
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
                      //zakupy bez kategorii
                      if (brakWartoscPLN != 0 ||
                          brakWartoscEUR != 0 ||
                          brakWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.noCaregory) +
                                        ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (brakWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${brakWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (brakWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (brakWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${brakWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (brakWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (brakWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${brakWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (brakWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),

//zakupy opakowań
                      if (opakowaniaWartoscPLN != 0 ||
                          opakowaniaWartoscEUR != 0 ||
                          opakowaniaWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.packaging) +
                                        ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (opakowaniaWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${opakowaniaWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (opakowaniaWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (opakowaniaWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${opakowaniaWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (opakowaniaWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (opakowaniaWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${opakowaniaWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (opakowaniaWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy wyposazenia
                      if (wyposazenieWartoscPLN != 0 ||
                          wyposazenieWartoscEUR != 0 ||
                          wyposazenieWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.equipment) +
                                        ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (wyposazenieWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${wyposazenieWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wyposazenieWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wyposazenieWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${wyposazenieWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wyposazenieWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wyposazenieWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${wyposazenieWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wyposazenieWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy pszczół
                      if (pszczolyWartoscPLN != 0 ||
                          pszczolyWartoscEUR != 0 ||
                          pszczolyWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.bees) + ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (pszczolyWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${pszczolyWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pszczolyWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pszczolyWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${pszczolyWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pszczolyWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pszczolyWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${pszczolyWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pszczolyWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy matek
                      if (matkiWartoscPLN != 0 ||
                          matkiWartoscEUR != 0 ||
                          matkiWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text: (AppLocalizations.of(context)!.queens) +
                                    ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (matkiWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${matkiWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (matkiWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (matkiWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${matkiWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (matkiWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (matkiWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${matkiWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (matkiWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy węzy
                      if (wezaWartoscPLN != 0 ||
                          wezaWartoscEUR != 0 ||
                          wezaWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text: (AppLocalizations.of(context)!
                                        .waxFundation) +
                                    ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (wezaWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${wezaWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wezaWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wezaWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${wezaWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wezaWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wezaWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${wezaWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wezaWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy pokarmu
                      if (pokarmWartoscPLN != 0 ||
                          pokarmWartoscEUR != 0 ||
                          pokarmWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.food) + ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (pokarmWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${pokarmWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pokarmWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pokarmWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${pokarmWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pokarmWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pokarmWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${pokarmWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pokarmWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy leków
                      if (lekiWartoscPLN != 0 ||
                          lekiWartoscEUR != 0 ||
                          lekiWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.medicines) +
                                        ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (lekiWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${lekiWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (lekiWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (lekiWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${lekiWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (lekiWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (lekiWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${lekiWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (lekiWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
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
                                text: (' ${razemWartoscEUR.toStringAsFixed(0)}'),
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
                                text: (' ${razemWartoscUSD.toStringAsFixed(0)}'),
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
                    itemCount: zakupy.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: zakupy[i],
                      child: PurchaseItem(),
                    ),
                  ),
                )
              ]));
  }
}
