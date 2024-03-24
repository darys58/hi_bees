import 'package:flutter/material.dart';
import 'package:hi_bees/helpers/db_helper.dart';
//import 'package:hi_bees/models/purchase.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../all_translations.dart';
// import 'languages.dart';
// import 'orders_screen.dart';
// import 'specials_screen.dart';
// import 'settings_screen.dart';
import 'package:intl/intl.dart';
import '../globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/frames.dart';
import '../models/infos.dart';
import '../models/hives.dart';
import '../models/apiarys.dart';
import '../models/memory.dart';
import '../models/dodatki1.dart';
import '../models/harvest.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../models/note.dart';
import '../screens/apiarys_screen.dart';

class ImportScreen extends StatefulWidget {
  static const routeName = '/import';

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isInit = true;
  bool isSwitched = false;
  var now = new DateTime.now();
  var formatter = new DateFormat('yyyy-MM-dd');
  //var formatterHm = new DateFormat('H:mm');
  String formattedDate = '';
  int iloscDoWyslania = 0;
  //String komunikat = 'komunikat';

  @override
  void didChangeDependencies() {
    //print('import_screen - didChangeDependencies');

    //print('import_screen - _isInit = $_isInit');

    if (_isInit) {
      Provider.of<Dodatki1>(context, listen: false)
          .fetchAndSetDodatki1()
          .then((_) {
        //uzyskanie dostępu do danych z tabeli dodatki1
        final dod1Data = Provider.of<Dodatki1>(context, listen: false);
        final dod1 = dod1Data.items;
        if (dod1[0].a == 'true') {
          //a - przełącznik eksportu danych
          setState(() {
            isSwitched = true;
          });
        } else {
          setState(() {
            isSwitched = false;
          });
        }
      });
    }
    _isInit = false;
    //Provider.of<Rests>(context, listen: false).fetchAndSetRests(); //dostawca restauracji
    super.didChangeDependencies();
  }

  //dialog z ładowaniem importu
  showLoaderDialog(BuildContext context, String text) {
    AlertDialog alert = AlertDialog(
      content: new Row(
        children: [
          CircularProgressIndicator(),
          Container(
              margin: EdgeInsets.only(left: 7),
              child:
                  Text(text + '\n' + AppLocalizations.of(context)!.pleaseWait)),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void _showAlert(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),

            //progress bar
            // Container(
            //     alignment: Alignment.topCenter,
            //     margin: EdgeInsets.all(20),
            //     child: LinearProgressIndicator(
            //       value: 0.7,
            //       valueColor:
            //           new AlwaysStoppedAnimation<Color>(Colors.deepOrange),
            //       backgroundColor: Colors.grey,
            //     )),

            //Text(komunikat),
          ],
        ),
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  void _showAlertOK(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();

            //   Navigator.of(context).pushNamedAndRemoveUntil(
            //       ImportScreen.routeName,
            //       ModalRoute.withName(ImportScreen
            //           .routeName)); //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
             },
            child: Text('OK'),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  void _showAlertAnuluj(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  void _showAlertImport(BuildContext context, String nazwa, String text) {
    formattedDate = formatter.format(now);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              //czy jest internet
              _isInternet().then((inter) {
                if (inter != null && inter) {
                  //print('jest internet');

                  // Navigator.of(context).pop();

                  // _showAlert(
                  //     context,
                  //     (AppLocalizations.of(context)!.alert),
                  //     (AppLocalizations.of(context)!.dataImport +
                  //         ' - ' +
                  //         AppLocalizations.of(context)!.pleaseWait));

                  // Navigator.of(context).pop();
                  showLoaderDialog(
                      context, AppLocalizations.of(context)!.dataImport);

                  //import notatek
                  Notes.fetchNotatkiFromSerwer(
                          'https://hibees.pl/cbt.php?d=f_notatki&kod=${globals.kod}&tab=notatki_${globals.kod.substring(0, 4)}')
                      .then((_) {
                    // setState(() {
                    //   komunikat = 'Import notatek';
                    // });
                    Provider.of<Notes>(context, listen: false)
                        .fetchAndSetNotatki();
                  });

                  //import zakupów
                  Purchases.fetchZakupyFromSerwer(
                          'https://hibees.pl/cbt.php?d=f_zakupy&kod=${globals.kod}&tab=zakupy_${globals.kod.substring(0, 4)}')
                      .then((_) {
                    // setState(() {
                    //   komunikat = 'Import zakupów';
                    // });
                    Provider.of<Purchases>(context, listen: false)
                        .fetchAndSetZakupy();
                  });

                  //import sprzedazy
                  Sales.fetchSprzedazFromSerwer(
                          'https://hibees.pl/cbt.php?d=f_sprzedaz&kod=${globals.kod}&tab=sprzedaz_${globals.kod.substring(0, 4)}')
                      .then((_) {
                    // setState(() {
                    //   komunikat = 'Import sprzedazy';
                    // });
                    Provider.of<Sales>(context, listen: false)
                        .fetchAndSetSprzedaz();
                  });

                  //import zbiorów
                  Harvests.fetchZbioryFromSerwer(
                          'https://hibees.pl/cbt.php?d=f_zbiory&kod=${globals.kod}&tab=zbiory_${globals.kod.substring(0, 4)}')
                      .then((_) {
                    // setState(() {
                    //   komunikat = 'Import zbiorów';
                    // });
                    Provider.of<Harvests>(context, listen: false)
                        .fetchAndSetZbiory();
                  });

                  //import ramek
                  Frames.fetchFramesFromSerwer(
                          'https://hibees.pl/cbt.php?d=f_ramka&kod=${globals.kod}&tab=ramka_${globals.kod.substring(0, 4)}')
                      .then((_) {
                    // setState(() {
                    //   komunikat = 'Import zawartości ramek';
                    // });
                    Provider.of<Frames>(context, listen: false)
                        .fetchAndSetFrames()
                        .then((_) {
                      final framesAllData =
                          Provider.of<Frames>(context, listen: false);
                      final ramki = framesAllData.items;
                      //print('ilość wpisów w tabeli ramka');
                      // print(ramki.length);
                      int i = 0;
                      while (ramki.length > i) {
                        //wpis do tabeli ule na podstawie ramki
                        Hives.insertHive(
                          '${ramki[i].pasiekaNr}.${ramki[i].ulNr}',
                          ramki[i].pasiekaNr, //pasieka nr
                          ramki[i].ulNr, //ul nr
                          formattedDate, //przeglad (aktualna data)
                          'green', //ikona
                          10, //opis - ilość ramek w korpusie
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
                          '0',
                          '0',
                          '0',
                          '0',
                          '0',
                        );
                        i++;
                      }

                      //import info
                      Infos.fetchInfosFromSerwer(
                              'https://hibees.pl/cbt.php?d=f_info&kod=${globals.kod}&tab=info_${globals.kod.substring(0, 4)}')
                          .then((_) {
                        // setState(() {
                        //   komunikat = 'Import informacji o ulu';
                        // });
                        Provider.of<Infos>(context, listen: false)
                            .fetchAndSetInfos()
                            .then((_) {
                          final infosAllData =
                              Provider.of<Infos>(context, listen: false);
                          final info = infosAllData.items;
                          //print('ilość wpisów w tabeli info');
                          //print(info.length);
                          int i = 0;
                          while (info.length > i) {
                            //wpis do tabeli ule na podstawie info
                            Hives.insertHive(
                              '${info[i].pasiekaNr}.${info[i].ulNr}',
                              info[i].pasiekaNr, //pasieka nr
                              info[i].ulNr, //ul nr
                              formattedDate, //przeglad (aktualna data)
                              'green', //ikona
                              10, //opis - ilość ramek w korpusie
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
                              '0',
                              '0',
                              '0',
                              '0',
                              '0',
                            );
                            i++;
                          }
                        }); //pobranie info z z bazy lokalnej i wpis do uli
                      }); //pobranie info z internetu

                      //pobranie danych z tabeli ule (wszystkie ule z wszystkich pasiek)
                      Provider.of<Hives>(context, listen: false)
                          .fetchAndSetHivesAll()
                          .then((_) {
                        print(
                            '-------------> wszystkie ule z wszystkich pasiek - wpis 0 uli');
                        final hivesData =
                            Provider.of<Hives>(context, listen: false);
                        final hives = hivesData.items;
                        //int ileUli = hives.length; //źle bo to wszystkie ule a nie dla konkretnej pasieki
                        //zapis do tabeli "pasieki"
                        int i = 0;
                        while (hives.length > i) {
                          Apiarys.insertApiary(
                            '${hives[i].pasiekaNr}',
                            hives[i].pasiekaNr, //pasieka nr
                            0, //ile uli - nie wiadomo bo nie ma podziału na pasieki
                            formattedDate, //przeglad (aktualna data)
                            'green', //ikona
                            '??', //opis
                          );
                          i++;
                        }
                        //pobranie danych o pasiekach (jeszcze jest zła ilość uli w pasiece)
                        Provider.of<Apiarys>(context, listen: false)
                            .fetchAndSetApiarys()
                            .then((_) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              ApiarysScreen.routeName,
                              ModalRoute.withName(ApiarysScreen
                                  .routeName)); //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
                          //komunikat na dole ekranu
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(AppLocalizations.of(context)!.importEnd),
                            ),
                          );
                          print('koniec importu');
                        });
                      }); //pobranie uli z lokalnej i wpis do pasieki
                    }); //pobranie ramek z loklnej i wpis do uli
                  }); //pobranie ramek z internetu

                } else {
                  print('braaaaaak internetu');
                  Navigator.of(context).pop();
                  _showAlertAnuluj(
                      context,
                      (AppLocalizations.of(context)!.brakInternetu),
                      (AppLocalizations.of(context)!.uruchomPonownie));
                }
              });
            },
            child: Text(AppLocalizations.of(context)!.importuj),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  //sprawdzenie czy jest internet
  Future<bool> _isInternet() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      print("Connected to Mobile Network");
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      print("Connected to WiFi");
      return true;
    } else {
      print("Unable to connect. Please Check Internet Connection");
      return false;
    }
  }

  void _showAlertExportAll(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              //print('wysłanie wszystkich danych do chmury ========= ');
              showLoaderDialog(
                  context, AppLocalizations.of(context)!.eXportData);

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli notatki - wszystkie
              Provider.of<Notes>(context, listen: false)
                  .fetchAndSetNotatki()
                  .then((_) {
                final notatkiArchData =
                    Provider.of<Notes>(context, listen: false);
                final notatki = notatkiArchData.items;
                // print('ilość nowych wpisów w tabeli notatki');
                // print(info.length);
                iloscDoWyslania = notatki.length;

                if (notatki.length > 0) {
                  String jsonData = '{"notatki":[';
                  int i = 0;
                  while (notatki.length > i) {
                    jsonData += '{"id": "${notatki[i].id}",';
                    jsonData += '"data": "${notatki[i].data}",';
                    jsonData += '"tytul": "${notatki[i].tytul}",';
                    jsonData += '"pasiekaNr": ${notatki[i].pasiekaNr},';
                    jsonData += '"ulNr": ${notatki[i].ulNr},';
                    jsonData += '"notatka": "${notatki[i].notatka}",';
                    jsonData += '"status": ${notatki[i].status},';
                    jsonData += '"priorytet": "${notatki[i].priorytet}",';
                    jsonData += '"uwagi": "${notatki[i].uwagi}",';
                    jsonData += '"arch": ${notatki[i].arch}}';
                    i++;
                    if (notatki.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${notatki.length}, "tabela":"notatki_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupNotatki(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli zakupy - wszystkie
              Provider.of<Purchases>(context, listen: false)
                  .fetchAndSetZakupy()
                  .then((_) {
                final zakupyArchData =
                    Provider.of<Purchases>(context, listen: false);
                final zakupy = zakupyArchData.items;
                // print('ilość nowych wpisów w tabeli zakupy');
                // print(info.length);
                iloscDoWyslania = zakupy.length;

                if (zakupy.length > 0) {
                  String jsonData = '{"zakupy":[';
                  int i = 0;
                  while (zakupy.length > i) {
                    jsonData += '{"id": "${zakupy[i].id}",';
                    jsonData += '"data": "${zakupy[i].data}",';
                    jsonData += '"pasiekaNr": ${zakupy[i].pasiekaNr},';
                    jsonData += '"nazwa": "${zakupy[i].nazwa}",';
                    jsonData += '"kategoriaId": ${zakupy[i].kategoriaId},';
                    jsonData += '"ilosc": ${zakupy[i].ilosc},';
                    jsonData += '"miara": ${zakupy[i].miara},';
                    jsonData += '"cena": ${zakupy[i].cena},';
                    jsonData += '"wartosc": ${zakupy[i].wartosc},';
                    jsonData += '"waluta": ${zakupy[i].waluta},';
                    jsonData += '"uwagi": "${zakupy[i].uwagi}",';
                    jsonData += '"arch": ${zakupy[i].arch}}';
                    i++;
                    if (zakupy.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${zakupy.length}, "tabela":"zakupy_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupZakupy(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli sprzedaz - wszystkie
              Provider.of<Sales>(context, listen: false)
                  .fetchAndSetSprzedaz()
                  .then((_) {
                final sprzedazArchData =
                    Provider.of<Sales>(context, listen: false);
                final sprzedaz = sprzedazArchData.items;
                // print('ilość nowych wpisów w tabeli info');
                // print(info.length);
                iloscDoWyslania = sprzedaz.length;

                if (sprzedaz.length > 0) {
                  String jsonData = '{"sprzedaz":[';
                  int i = 0;
                  while (sprzedaz.length > i) {
                    jsonData += '{"id": "${sprzedaz[i].id}",';
                    jsonData += '"data": "${sprzedaz[i].data}",';
                    jsonData += '"pasiekaNr": ${sprzedaz[i].pasiekaNr},';
                    jsonData += '"nazwa": "${sprzedaz[i].nazwa}",';
                    jsonData += '"kategoriaId": ${sprzedaz[i].kategoriaId},';
                    jsonData += '"ilosc": ${sprzedaz[i].ilosc},';
                    jsonData += '"miara": ${sprzedaz[i].miara},';
                    jsonData += '"cena": ${sprzedaz[i].cena},';
                    jsonData += '"wartosc": ${sprzedaz[i].wartosc},';
                    jsonData += '"waluta": ${sprzedaz[i].waluta},';
                    jsonData += '"uwagi": "${sprzedaz[i].uwagi}",';
                    jsonData += '"arch": ${sprzedaz[i].arch}}';
                    i++;
                    if (sprzedaz.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${sprzedaz.length}, "tabela":"sprzedaz_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupSprzedaz(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli zbiry - wszstkie
              Provider.of<Harvests>(context, listen: false)
                  .fetchAndSetZbiory()
                  .then((_) {
                final zbioryArchData =
                    Provider.of<Harvests>(context, listen: false);
                final zbiory = zbioryArchData.items;
                // print('ilość nowych wpisów w tabeli info');
                // print(info.length);
                iloscDoWyslania = zbiory.length;

                if (zbiory.length > 0) {
                  String jsonData = '{"zbiory":[';
                  int i = 0;
                  while (zbiory.length > i) {
                    jsonData += '{"id": "${zbiory[i].id}",';
                    jsonData += '"data": "${zbiory[i].data}",';
                    jsonData += '"pasiekaNr": ${zbiory[i].pasiekaNr},';
                    jsonData += '"zasobId": ${zbiory[i].zasobId},';
                    jsonData += '"ilosc": "${zbiory[i].ilosc}",';
                    jsonData += '"miara": "${zbiory[i].miara}",';
                    jsonData += '"uwagi": "${zbiory[i].uwagi}",';
                    jsonData += '"g": "${zbiory[i].g}",';
                    jsonData += '"h": "${zbiory[i].h}",';
                    jsonData += '"arch": ${zbiory[i].arch}}';
                    i++;
                    if (zbiory.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${zbiory.length}, "tabela":"zbiory_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupZbiory(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli info - wszystkie wpisy
              Provider.of<Infos>(context, listen: false)
                  .fetchAndSetInfos()
                  .then((_) {
                final infoAllData = Provider.of<Infos>(context, listen: false);
                final info = infoAllData.items;
                //print('ilość wszystkich wpisów w tabeli info');
                print(info.length);
                iloscDoWyslania = info.length;

                if (info.length > 0) {
                  String jsonData = '{"info":[';
                  int i = 0;
                  while (info.length > i) {
                    jsonData += '{"id": "${info[i].id}",';
                    jsonData += '"data": "${info[i].data}",';
                    jsonData += '"pasiekaNr": ${info[i].pasiekaNr},';
                    jsonData += '"ulNr": ${info[i].ulNr},';
                    jsonData += '"kategoria": "${info[i].kategoria}",';
                    jsonData += '"parametr": "${info[i].parametr}",';
                    jsonData += '"wartosc": "${info[i].wartosc}",';
                    jsonData += '"miara": "${info[i].miara}",';
                    jsonData += '"miara": "${info[i].miara}",';
                    jsonData += '"pogoda": "${info[i].pogoda}",';
                    jsonData += '"temp": "${info[i].temp}",';
                    jsonData += '"czas": "${info[i].czas}",';
                    jsonData += '"arch": ${info[i].arch}}';
                    i++;
                    if (info.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${info.length}, "tabela":"info_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupInfo(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        Navigator.of(context).pop();
                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli ramka - wszystkie wpisy
              Provider.of<Frames>(context, listen: false)
                  .fetchAndSetFrames()
                  .then((_) {
                final framesAllData =
                    Provider.of<Frames>(context, listen: false);
                final ramki = framesAllData.items;
                // print('ilość wszystkich wpisów w tabeli ramka');
                // print(ramki.length);

                //informacja o ilości rekordów do wysłania
                iloscDoWyslania += ramki.length;
                if (iloscDoWyslania > 0)
                  _showAlertOK(
                      context,
                      AppLocalizations.of(context)!.alert,
                      AppLocalizations.of(context)!.dataToSend +
                          ' = $iloscDoWyslania');
                else
                  _showAlertOK(context, AppLocalizations.of(context)!.alert,
                      AppLocalizations.of(context)!.noDataToSend);

                if (ramki.length > 0) {
                  String jsonData = '{"ramka":[';
                  int i = 0;
                  while (ramki.length > i) {
                    jsonData += '{"id": "${ramki[i].id}",';
                    jsonData += '"data": "${ramki[i].data}",';
                    jsonData += '"pasiekaNr": ${ramki[i].pasiekaNr},';
                    jsonData += '"ulNr": ${ramki[i].ulNr},';
                    jsonData += '"korpusNr": ${ramki[i].korpusNr},';
                    jsonData += '"typ": ${ramki[i].typ},';
                    jsonData += '"ramkaNr": ${ramki[i].ramkaNr},';
                    jsonData += '"rozmiar": ${ramki[i].rozmiar},';
                    jsonData += '"strona": ${ramki[i].strona},';
                    jsonData += '"zasob": ${ramki[i].zasob},';
                    jsonData += '"wartosc": "${ramki[i].wartosc}",';
                    jsonData += '"arch": ${ramki[i].arch}}';
                    i++;
                    if (ramki.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${ramki.length}, "tabela":"ramka_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        print('$inter - jest internet');
                        wyslijBackupRamka(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        // _showAlertAnuluj(
                        //     context,
                        //     AppLocalizations.of(context)!.alert,
                        //     AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli ramki do archiwizacji
              }); //od pobrania ramek

             // Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  void _showAlertExportNew(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {

              showLoaderDialog(
                  context, AppLocalizations.of(context)!.eXportData);

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli notatki - tylko wpisy z arch=0
              Provider.of<Notes>(context, listen: false)
                  .fetchAndSetNotatkiToArch()
                  .then((_) {
                final notatkiArchData =
                    Provider.of<Notes>(context, listen: false);
                final notatki = notatkiArchData.items;
                // print('ilość nowych wpisów w tabeli notatki');
                // print(info.length);
                iloscDoWyslania = notatki.length;

                if (notatki.length > 0) {
                  String jsonData = '{"notatki":[';
                  int i = 0;
                  while (notatki.length > i) {
                    jsonData += '{"id": "${notatki[i].id}",';
                    jsonData += '"data": "${notatki[i].data}",';
                    jsonData += '"tytul": "${notatki[i].tytul}",';
                    jsonData += '"pasiekaNr": ${notatki[i].pasiekaNr},';
                    jsonData += '"ulNr": ${notatki[i].ulNr},';
                    jsonData += '"notatka": "${notatki[i].notatka}",';
                    jsonData += '"status": ${notatki[i].status},';
                    jsonData += '"priorytet": "${notatki[i].priorytet}",';
                    jsonData += '"uwagi": "${notatki[i].uwagi}",';
                    jsonData += '"arch": ${notatki[i].arch}}';
                    i++;
                    if (notatki.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${notatki.length}, "tabela":"notatki_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupNotatki(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli zakupy - tylko wpisy z arch=0
              Provider.of<Purchases>(context, listen: false)
                  .fetchAndSetZakupyToArch()
                  .then((_) {
                final zakupyArchData =
                    Provider.of<Purchases>(context, listen: false);
                final zakupy = zakupyArchData.items;
                // print('ilość nowych wpisów w tabeli zakupy');
                // print(info.length);
                iloscDoWyslania = zakupy.length;

                if (zakupy.length > 0) {
                  String jsonData = '{"zakupy":[';
                  int i = 0;
                  while (zakupy.length > i) {
                    jsonData += '{"id": "${zakupy[i].id}",';
                    jsonData += '"data": "${zakupy[i].data}",';
                    jsonData += '"pasiekaNr": ${zakupy[i].pasiekaNr},';
                    jsonData += '"nazwa": "${zakupy[i].nazwa}",';
                    jsonData += '"kategoriaId": ${zakupy[i].kategoriaId},';
                    jsonData += '"ilosc": ${zakupy[i].ilosc},';
                    jsonData += '"miara": ${zakupy[i].miara},';
                    jsonData += '"cena": ${zakupy[i].cena},';
                    jsonData += '"wartosc": ${zakupy[i].wartosc},';
                    jsonData += '"waluta": ${zakupy[i].waluta},';
                    jsonData += '"uwagi": "${zakupy[i].uwagi}",';
                    jsonData += '"arch": ${zakupy[i].arch}}';
                    i++;
                    if (zakupy.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${zakupy.length}, "tabela":"zakupy_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupZakupy(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli sprzedaz - tylko wpisy z arch=0
              Provider.of<Sales>(context, listen: false)
                  .fetchAndSetSprzedazToArch()
                  .then((_) {
                final sprzedazArchData =
                    Provider.of<Sales>(context, listen: false);
                final sprzedaz = sprzedazArchData.items;
                // print('ilość nowych wpisów w tabeli info');
                // print(info.length);
                iloscDoWyslania = sprzedaz.length;

                if (sprzedaz.length > 0) {
                  String jsonData = '{"sprzedaz":[';
                  int i = 0;
                  while (sprzedaz.length > i) {
                    jsonData += '{"id": "${sprzedaz[i].id}",';
                    jsonData += '"data": "${sprzedaz[i].data}",';
                    jsonData += '"pasiekaNr": ${sprzedaz[i].pasiekaNr},';
                    jsonData += '"nazwa": "${sprzedaz[i].nazwa}",';
                    jsonData += '"kategoriaId": ${sprzedaz[i].kategoriaId},';
                    jsonData += '"ilosc": ${sprzedaz[i].ilosc},';
                    jsonData += '"miara": ${sprzedaz[i].miara},';
                    jsonData += '"cena": ${sprzedaz[i].cena},';
                    jsonData += '"wartosc": ${sprzedaz[i].wartosc},';
                    jsonData += '"waluta": ${sprzedaz[i].waluta},';
                    jsonData += '"uwagi": "${sprzedaz[i].uwagi}",';
                    jsonData += '"arch": ${sprzedaz[i].arch}}';
                    i++;
                    if (sprzedaz.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${sprzedaz.length}, "tabela":"sprzedaz_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupSprzedaz(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli zbiory - tylko wpisy z arch=0
              Provider.of<Harvests>(context, listen: false)
                  .fetchAndSetZbioryToArch()
                  .then((_) {
                final zbioryArchData =
                    Provider.of<Harvests>(context, listen: false);
                final zbiory = zbioryArchData.items;
                // print('ilość nowych wpisów w tabeli info');
                // print(info.length);
                iloscDoWyslania = zbiory.length;

                if (zbiory.length > 0) {
                  String jsonData = '{"zbiory":[';
                  int i = 0;
                  while (zbiory.length > i) {
                    jsonData += '{"id": "${zbiory[i].id}",';
                    jsonData += '"data": "${zbiory[i].data}",';
                    jsonData += '"pasiekaNr": ${zbiory[i].pasiekaNr},';
                    jsonData += '"zasobId": ${zbiory[i].zasobId},';
                    jsonData += '"ilosc": "${zbiory[i].ilosc}",';
                    jsonData += '"miara": "${zbiory[i].miara}",';
                    jsonData += '"uwagi": "${zbiory[i].uwagi}",';
                    jsonData += '"g": "${zbiory[i].g}",';
                    jsonData += '"h": "${zbiory[i].h}",';
                    jsonData += '"arch": ${zbiory[i].arch}}';
                    i++;
                    if (zbiory.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${zbiory.length}, "tabela":"zbiory_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupZbiory(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli info - tylko wpisy z arch=0
              Provider.of<Infos>(context, listen: false)
                  .fetchAndSetInfosToArch()
                  .then((_) {
                final infoArchData = Provider.of<Infos>(context, listen: false);
                final info = infoArchData.items;
                // print('ilość nowych wpisów w tabeli info');
                // print(info.length);
                iloscDoWyslania = info.length;

                if (info.length > 0) {
                  String jsonData = '{"info":[';
                  int i = 0;
                  while (info.length > i) {
                    jsonData += '{"id": "${info[i].id}",';
                    jsonData += '"data": "${info[i].data}",';
                    jsonData += '"pasiekaNr": ${info[i].pasiekaNr},';
                    jsonData += '"ulNr": ${info[i].ulNr},';
                    jsonData += '"kategoria": "${info[i].kategoria}",';
                    jsonData += '"parametr": "${info[i].parametr}",';
                    jsonData += '"wartosc": "${info[i].wartosc}",';
                    jsonData += '"miara": "${info[i].miara}",';
                    jsonData += '"pogoda": "${info[i].pogoda}",';
                    jsonData += '"temp": "${info[i].temp}",';
                    jsonData += '"czas": "${info[i].czas}",';
                    jsonData += '"uwagi": "${info[i].uwagi}",';
                    jsonData += '"arch": ${info[i].arch}}';
                    i++;
                    if (info.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${info.length}, "tabela":"info_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupInfo(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli ramka - tylko wpisy z arch=0
              Provider.of<Frames>(context, listen: false)
                  .fetchAndSetFramesToArch()
                  .then((_) {
                final framesArchData =
                    Provider.of<Frames>(context, listen: false);
                final ramki = framesArchData.items;
                // print('ilość nowych wpisów w tabeli ramka');
                // print(ramki.length);

                //informacja o ilości rekordów do wysłania
                iloscDoWyslania += ramki.length;
                if (iloscDoWyslania > 0)
                  _showAlertOK(
                      context,
                      AppLocalizations.of(context)!.alert,
                      AppLocalizations.of(context)!.dataToSend +
                          ' = $iloscDoWyslania');
                else
                  _showAlertOK(context, AppLocalizations.of(context)!.alert,
                      AppLocalizations.of(context)!.noDataToSend);

                if (ramki.length > 0) {
                  String jsonData = '{"ramka":[';
                  int i = 0;
                  while (ramki.length > i) {
                    jsonData += '{"id": "${ramki[i].id}",';
                    jsonData += '"data": "${ramki[i].data}",';
                    jsonData += '"pasiekaNr": ${ramki[i].pasiekaNr},';
                    jsonData += '"ulNr": ${ramki[i].ulNr},';
                    jsonData += '"korpusNr": ${ramki[i].korpusNr},';
                    jsonData += '"typ": ${ramki[i].typ},';
                    jsonData += '"ramkaNr": ${ramki[i].ramkaNr},';
                    jsonData += '"rozmiar": ${ramki[i].rozmiar},';
                    jsonData += '"strona": ${ramki[i].strona},';
                    jsonData += '"zasob": ${ramki[i].zasob},';
                    jsonData += '"wartosc": "${ramki[i].wartosc}",';
                    jsonData += '"arch": ${ramki[i].arch}}';
                    i++;
                    if (ramki.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${ramki.length}, "tabela":"ramka_${mem[0].kod.substring(0, 4)}"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        print('$inter - jest internet');
                        wyslijBackupRamka(jsonData); //jsonData
                      } else {
                        print('braaaaaak internetu');
                        // _showAlertAnuluj(
                        //     context,
                        //     AppLocalizations.of(context)!.alert,
                        //     AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli ramki do archiwizacji
              }); //od pobrania ramek

             // Navigator.of(context).pop();

              // DBHelper.updateActivate(globals.deviceId, '').then((_) {
              //   Navigator.of(context).pushNamedAndRemoveUntil(
              //       ApiarysScreen.routeName,
              //       ModalRoute.withName(ApiarysScreen
              //           .routeName)); //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
              // }); //'' do memory "od" - kasowanie
            },
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  //kasowanie zawartości tabeli ramka, info, ule i pasieki
  void _showAlertDeleteRamkaInfo(
      BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              DBHelper.deleteTable('ramka').then((_) {
                DBHelper.deleteTable('info').then((_) {
                  DBHelper.deleteTable('ule').then((_) {
                    DBHelper.deleteTable('pasieki').then((_) {
                      DBHelper.deleteTable('zbiory').then((_) {
                        DBHelper.deleteTable('sprzedaz').then((_) {
                          DBHelper.deleteTable('zakupy').then((_) {
                            DBHelper.deleteTable('notatki').then((_) {
                              //pobranie wszystkich pasiek z tabeli pasieki z bazy lokalnej
                              //zeby wykasowaćdane o pasiekach z pamięci
                              Provider.of<Apiarys>(context, listen: false)
                                  .fetchAndSetApiarys()
                                  .then((_) {
                                Navigator.of(context).pop();
                              });
                            });
                          });
                        });
                      });
                    });
                  });
                });
              });
            },
            child: Text(AppLocalizations.of(context)!.dElete),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  //wysyłanie backupu ramka
  Future<void> wyslijBackupRamka(String jsonData1) async {
    //String jsonData1
    //print("z funkcji wysyłania");
    final http.Response response = await http.post(
      Uri.parse('https://hibees.pl/cbt_hi_backup10.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela ramka w postaci jsona
    );
    print("response.body:");
    print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Frames>(context, listen: false)
            .fetchAndSetFramesToArch()
            .then((_) {
          //dla tabeli RAMKI
          final framesAllData = Provider.of<Frames>(context, listen: false);
          final ramki = framesAllData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli ramka');
          //print(ramki.length);
          int i = 0;
          while (ramki.length > i) {
            DBHelper.updateRamkaArch(ramki[i].id); //zapis arch = 1
            i++;
          }

          //komunikat na dole ekranu
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.inspectionDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu info
  Future<void> wyslijBackupInfo(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://hibees.pl/cbt_hi_backup10.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    print("response.body:");
    print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Infos>(context, listen: false)
            .fetchAndSetInfosToArch()
            .then((_) {
          //dla tabeli INFO
          final infoArchData = Provider.of<Infos>(context, listen: false);
          final info = infoArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli info');
          //print(info.length);
          int i = 0;
          while (info.length > i) {
            DBHelper.updateInfoArch(info[i].id); //zapis arch = 1
            i++;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.infoDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu zbiory
  Future<void> wyslijBackupZbiory(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://hibees.pl/cbt_hi_backup10.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    print("response.body:");
    print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Harvests>(context, listen: false)
            .fetchAndSetZbioryToArch()
            .then((_) {
          //dla tabeli ZBIORY
          final zbioryArchData = Provider.of<Harvests>(context, listen: false);
          final zbiory = zbioryArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli zbiory');
          //print(zbiory.length);
          int i = 0;
          while (zbiory.length > i) {
            DBHelper.updateZbioryArch(zbiory[i].id); //zapis arch = 1
            i++;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.harvestDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu sprzedaz
  Future<void> wyslijBackupSprzedaz(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://hibees.pl/cbt_hi_backup10.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    print("response.body:");
    print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Sales>(context, listen: false)
            .fetchAndSetSprzedazToArch()
            .then((_) {
          //dla tabeli SPRZEDAZ
          final sprzedazArchData = Provider.of<Sales>(context, listen: false);
          final sprzedaz = sprzedazArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli sprzedaz');
          //print(sprzedaz.length);
          int i = 0;
          while (sprzedaz.length > i) {
            DBHelper.updateSprzedazArch(sprzedaz[i].id); //zapis arch = 1
            i++;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.saleDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu zakupów
  Future<void> wyslijBackupZakupy(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://hibees.pl/cbt_hi_backup10.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    print("response.body:");
    print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Purchases>(context, listen: false)
            .fetchAndSetZakupyToArch()
            .then((_) {
          //dla tabeli ZAKUPY
          final zakupyArchData = Provider.of<Purchases>(context, listen: false);
          final zakupy = zakupyArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli sprzedaz');
          //print(sprzedaz.length);
          int i = 0;
          while (zakupy.length > i) {
            DBHelper.updateZakupyArch(zakupy[i].id); //zapis arch = 1
            i++;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.purchaseDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu notatek
  Future<void> wyslijBackupNotatki(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://hibees.pl/cbt_hi_backup10.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    print("response.body:");
    print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Notes>(context, listen: false)
            .fetchAndSetNotatkiToArch()
            .then((_) {
          //dla tabeli NOTATKI
          final notatkiArchData = Provider.of<Notes>(context, listen: false);
          final notatki = notatkiArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli sprzedaz');
          //print(sprzedaz.length);
          int i = 0;
          while (notatki.length > i) {
            DBHelper.updateNotatkiArch(notatki[i].id); //zapis arch = 1
            i++;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noteDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  @override
  Widget build(BuildContext context) {
    //komunikat = AppLocalizations.of(context)!.dopisanieDoBazy;

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(
            AppLocalizations.of(context)!.zarzadzanieDanymi,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
        ),
        body: ListView(
          children: <Widget>[
// //język
//             GestureDetector(
//               onTap: () {
//                 Navigator.of(context).pushNamed(LanguagesScreen.routeName);
//               },
//               child: Card(
//                 child: ListTile(
//                   leading: Icon(Icons.translate),
//                   title: Text(allTranslations.text('L_JEZYK')),
//                   trailing: Icon(Icons.chevron_right),
//                 ),
//               ),
//             ),

// //zamówienia
//             GestureDetector(
//               onTap: () {
//                 //czy jest internet
//                 _isInternet().then((inter) {
//                   if (inter != null && inter) {
//                     Navigator.of(context).pushNamed(OrdersScreen.routeName);
//                   } else {
//                     print('braaaaaak internetu');
//                     _showAlertAnuluj(
//                         context,
//                         allTranslations.text('L_BRAK_INTERNETU'),
//                         allTranslations.text('L_URUCHOM_INTERNETU'));
//                   }
//                 });
//               },
//               child: Card(
//                 child: ListTile(
//                   leading: Icon(Icons.list),
//                   title: Text(allTranslations.text('L_ZAMOWIENIA')),
//                   trailing: Icon(Icons.chevron_right),
//                 ),
//               ),
//             ),

// //promocje
//             GestureDetector(
//               onTap: () {
//                 //czy jest internet
//                 _isInternet().then((inter) {
//                   if (inter != null && inter) {
//                     print('wiecej - specialsScreen');
//                     Navigator.of(context).pushNamed(SpecialsScreen.routeName);
//                   } else {
//                     print('braaaaaak internetu');
//                     _showAlertAnuluj(
//                         context,
//                         allTranslations.text('L_BRAK_INTERNETU'),
//                         allTranslations.text('L_URUCHOM_INTERNETU'));
//                   }
//                 });
//               },
//               child: Card(
//                 child: ListTile(
//                   leading: Icon(Icons.notifications),
//                   title: Text(allTranslations.text('L_PROMOCJE')),
//                   trailing: Icon(Icons.chevron_right),
//                 ),
//               ),
//             ),

//import danych
            GestureDetector(
              onTap: () {
                _showAlertImport(context, (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.importowanie));
                //Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.import),
                  subtitle: Text(AppLocalizations.of(context)!.dopisanieDoBazy),//Text(komunikat),
                  //trailing: Icon(Icons.chevron_right),
                ),
              ),
            ),

//eksport nowych danych teraz
            GestureDetector(
              onTap: () {
                _showAlertExportNew(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.exportNewData));
                //Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.exportNewToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.onlyNew),
                ),
              ),
            ),

//eksport wszystkich danych teraz
            GestureDetector(
              onTap: () {
                _showAlertExportAll(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.exportAllData));
                //Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.exportAllToCloud),
                  //subtitle: Text(AppLocalizations.of(context)!.onlyNew),
                ),
              ),
            ),

//eksport danych automatycznie przy uruchamianiu aplikacji
            Card(
              child: ListTile(
                //leading: Icon(Icons.settings),
                title: Text(AppLocalizations.of(context)!.autoEksportDoChmury),
                subtitle:
                    Text(AppLocalizations.of(context)!.onlyInspection),
                trailing: Switch.adaptive(
                  value: isSwitched,
                  onChanged: (value) {
                    DBHelper.updateDodatki1('a', '$value');
                    setState(() {
                      isSwitched = value;
                      print(isSwitched);
                    });
                  },
                ),
              ),
            ),

//usunięcie wszystkich danych o przeglądach i info
            GestureDetector(
              onTap: () {
                _showAlertDeleteRamkaInfo(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.deleteRamkaInfo));
                //Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.deleteAllData),
                  //subtitle: Text(AppLocalizations.of(context)!.aboutHiveApiary),
                ),
              ),
            ),
//polityka prywatności
//             GestureDetector(
//               onTap: () {
//                 //czy jest internet
//                 _isInternet().then((inter) {
//                   if (inter != null && inter) {
//                     _launchURL(
//                         'https://www.cobytu.com/index.php?d=polityka&mobile=1');
//                     // Navigator.of(context).pushNamed(LanguagesScreen.routeName);
//                   } else {
//                     print('braaaaaak internetu');
//                     _showAlertAnuluj(
//                         context,
//                         allTranslations.text('L_BRAK_INTERNETU'),
//                         allTranslations.text('L_URUCHOM_INTERNETU'));
//                   }
//                 });
//               },
//               child: Card(
//                 child: ListTile(
//                   leading: Icon(Icons.security),
//                   title: Text(allTranslations.text('L_POLITYKA')),
//                   trailing: Icon(Icons.chevron_right),
//                 ),
//               ),
//             ),

// //regulamin
//             GestureDetector(
//               onTap: () {
//                 //czy jest internet
//                 _isInternet().then((inter) {
//                   if (inter != null && inter) {
//                     _launchURL(
//                         'https://www.cobytu.com/index.php?d=regulamin&mobile=1');
//                     // Navigator.of(context).pushNamed(LanguagesScreen.routeName);
//                   } else {
//                     print('braaaaaak internetu');
//                     _showAlertAnuluj(
//                         context,
//                         allTranslations.text('L_BRAK_INTERNETU'),
//                         allTranslations.text('L_URUCHOM_INTERNETU'));
//                   }
//                 });
//               },
//               child: Card(
//                 child: ListTile(
//                   leading: Icon(Icons.library_books),
//                   title: Text(allTranslations.text('L_REGULAMIN')),
//                   trailing: Icon(Icons.chevron_right),
//                 ),
//               ),
//             ),

            /* Card(child: ListTile(title: Text('One-line ListTile'))),
            Card(
              child: ListTile(
                leading: FlutterLogo(),
                title: Text('One-line with leading widget'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('One-line with trailing widget'),
                trailing: Icon(Icons.more_vert),
              ),
            ), 
        
            Card(
              child: ListTile(
                title: Text('One-line dense ListTile'),
                dense: true,
              ),
            ),
            Card(
              child: ListTile(
                leading: FlutterLogo(size: 56.0),
                title: Text('Two-line ListTile'),
                subtitle: Text('Here is a second line'),
                trailing: Icon(Icons.more_vert),
              ),
            ),
            Card(
              child: ListTile(
                leading: FlutterLogo(size: 72.0),
                title: Text('Three-line ListTile'),
                subtitle: Text(
                  'A sufficiently long subtitle warrants three lines.'
                ),
                trailing: Icon(Icons.more_vert),
                isThreeLine: true,
              ),
           ),
       */
          ],
        ));
  }
}
/*
final String language = allTranslations.currentLanguage;
final String buttonText = language == 'pl' ? '=> English' : '=> Français'; 

child: Column(
          children: <Widget>[
            RaisedButton(
              child: Text(buttonText),
              onPressed: () async {
                await allTranslations.setNewLanguage(language == 'pl' ? 'en' : 'pl');
                setState((){
                  //lll
               });
              },
            ),
            Text(allTranslations.text('ulubione')),
          ],
        ),*/
