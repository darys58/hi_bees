import 'package:flutter/material.dart';
import 'package:hi_bees/helpers/db_helper.dart';
//import 'package:hi_bees/models/purchase.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../all_translations.dart';
// import 'languages.dart';
// import 'orders_screen.dart';
// import 'specials_screen.dart';
// import 'settings_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; //blokowanie ekranu
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
import '../models/queen.dart';
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
  //int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
  String biezacyRok = DateTime.now().toString().substring(0, 4); //aktualny rok
  //var formatterHm = new DateFormat('H:mm');
  String formattedDate = '';
  int iloscDoWyslania = 0;
  //String komunikat = 'komunikat';
  // bool wyborDanych = false;
  // bool archNotatki = true;
  // bool archZbiory = true;
  // bool archZakupy = true;
  // bool archSprzedaz = true;
  // bool archInfo = true;
  // bool archRamki = true;
  // bool archOstatniRok = true;
  String test = 'start';
  double count = 0;
  Map<String, String> _nfcTags = {}; // Przechowywanie tagow NFC podczas importu
  
  
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

  //dialog z ładowaniem importu i eksportu
  showLoaderDialog (BuildContext context, String text) async {
    WakelockPlus.enable(); //blokada wyłaczania ekranu
    AlertDialog alert = AlertDialog(
      content: new Row(
        children: [
          CircularProgressIndicator(),
          Container(
            margin: EdgeInsets.only(left: 7),
            child: Text(text + '\n' + AppLocalizations.of(context)!.pleaseWait)),
        ],
      ),
    );
    
    
    // AlertDialog(
    //     key: ValueKey(count),
    //     title: const Text("Loading..."),
    //     content: LinearProgressIndicator(
    //       value: count,
    //       backgroundColor: Colors.grey,
    //       color: Colors.green,
    //       minHeight: 10,
    //     ),
    //   );
    

    //wyświetlenie okienka ładowania
    showDialog(
      barrierDismissible: false, //zablokowanie tła
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  // void _showAlert(BuildContext context, String nazwa, String text) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text(nazwa),
  //       content: Column(
  //         //zeby tekst był wyśrodkowany w poziomie
  //         mainAxisSize: MainAxisSize.min,
  //         children: <Widget>[
  //           Text(text),

  //           //progress bar
  //           // Container(
  //           //     alignment: Alignment.topCenter,
  //           //     margin: EdgeInsets.all(20),
  //           //     child: LinearProgressIndicator(
  //           //       value: 0.7,
  //           //       valueColor:
  //           //           new AlwaysStoppedAnimation<Color>(Colors.deepOrange),
  //           //       backgroundColor: Colors.grey,
  //           //     )),

  //           //Text(komunikat),
  //         ],
  //       ),
  //       elevation: 24.0,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(15.0),
  //       ),
  //     ),
  //     barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
  //   );
  // }

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
              WakelockPlus.disable(); //usunięcie blokowania wygaszania ekranu
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

  //import danych
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
                if (inter) {
                  //print('jest internet');

                  // Navigator.of(context).pop();

                  // _showAlert(
                  //     context,
                  //     (AppLocalizations.of(context)!.alert),
                  //     (AppLocalizations.of(context)!.dataImport +
                  //         ' - ' +
                  //         AppLocalizations.of(context)!.pleaseWait));

                  // Navigator.of(context).pop();
                  showLoaderDialog( context, AppLocalizations.of(context)!.dataImport);

                  // Zapisanie tagow NFC przed importem
                  DBHelper.getData('ule').then((hives) {
                    _nfcTags.clear();
                    for (var hive in hives) {
                      if (hive['h3'] != null && hive['h3'] != '0' && hive['h3'] != '') {
                        _nfcTags[hive['id']] = hive['h3'];
                      }
                    }
                  });

                  //import notatek
                  Notes.fetchNotatkiFromSerwer(
                          'https://darys.pl/cbt.php?d=f_notatki&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_notatki')
                      .then((_) {
                    // setState(() {
                    //   komunikat = 'Import notatek';
                    // });
                    Provider.of<Notes>(context, listen: false)
                        .fetchAndSetNotatki();
                  });

//import zakupów
//https://www.darys.pl/cbt.php?d=f_zakupy&kod=00012105&tab=0001_zakupy
                  Purchases.fetchZakupyFromSerwer(
                          'https://darys.pl/cbt.php?d=f_zakupy&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_zakupy')
                      .then((_) {
                    // setState(() {
                    //   komunikat = 'Import zakupów';
                    // });
                    Provider.of<Purchases>(context, listen: false)
                        .fetchAndSetZakupy();
                  });

  //import sprzedazy
                  Sales.fetchSprzedazFromSerwer(
                          'https://darys.pl/cbt.php?d=f_sprzedaz&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_sprzedaz')
                      .then((_) {
                    // setState(() {
                    //   komunikat = 'Import sprzedazy';
                    // });
                    Provider.of<Sales>(context, listen: false)
                        .fetchAndSetSprzedaz();
                  });

//import matki
                  Queens.fetchQueensFromSerwer(
                          'https://darys.pl/cbt.php?d=f_matki&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_matki')
                      .then((_) {
                    // setState(() {
                    //   komunikat = 'Import sprzedazy';
                    // });
                    Provider.of<Queens>(context, listen: false)
                        .fetchAndSetQueens();
                  });                  

//import zbiorów
                  Harvests.fetchZbioryFromSerwer(
                          'https://darys.pl/cbt.php?d=f_zbiory&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_zbiory')
                      .then((_) {
                    // setState(() {
                    //   komunikat = 'Import zbiorów';
                    // });
                    Provider.of<Harvests>(context, listen: false)
                        .fetchAndSetZbiory();
                  });

//import ramek
                  Frames.fetchFramesFromSerwer(
                          'https://darys.pl/cbt.php?d=f_ramka&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_ramka')
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
                      //print(ramki.length);
                      int i = 0;
                      while (ramki.length > i) {
                        //wpis do tabeli ule na podstawie ramki
                        Hives.insertHive(
                          '${ramki[i].pasiekaNr}.${ramki[i].ulNr}',
                          ramki[i].pasiekaNr, //pasieka nr
                          ramki[i].ulNr, //ul nr
                          formattedDate, //przeglad (aktualna data)
                          'green', //ikona
                          10, //warto≥ść domyślna - ilość ramek w korpusie
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
                          AppLocalizations.of(context)!.hIve,//h1 wartosc domyślna rodzaju ula - Ul
                          '0',
                          '0',
                          0, //aktualny - stan po wczytaniu z chmury
                        );
                        i++;
                        //print('ramki w insertHive $i');
                      }

 //import info i odbudowa tabeli pasieki i ule
                      Infos.fetchInfosFromSerwer(
                              'https://darys.pl/cbt.php?d=f_info&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_info')
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
                            //print(info[i].parametr);
                            //wpis do tabeli ule na podstawie info
                            if(info[i].parametr == AppLocalizations.of(context)!.numberOfFrame + ' = ' ){ //jezeli jest rodzaj ula
                              //print('parametr = ${AppLocalizations.of(context)!.numberOfFrame + ' = '}');
                              //print('i = $i');
                              Hives.insertHive(
                                '${info[i].pasiekaNr}.${info[i].ulNr}',
                                info[i].pasiekaNr, //pasieka nr
                                info[i].ulNr, //ul nr
                                formattedDate, //przeglad (aktualna data)
                                'green', //ikona
                                int.parse(info[i].wartosc), //ilość ramek w korpusie
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
                                info[i].pogoda,//h1 - rodzaj ula
                                info[i].miara, //h2 - typ ula
                                '0',
                                0, //aktualny - stan po wczytaniu z chmury
                              );
                            }
                            i++;
                            //print('info w insertHive $i');
                          }
               
                          //pobranie danych z tabeli ule (wszystkie ule z wszystkich pasiek)
                          Provider.of<Hives>(context, listen: false)
                              .fetchAndSetHivesAll()
                              .then((_) {
                            //print('-------------> wszystkie ule z wszystkich pasiek - wpis 0 uli');
                            final hivesData =
                                Provider.of<Hives>(context, listen: false);
                            final hives = hivesData.items;
                            //int ileUli = hives.length; //źle bo to wszystkie ule a nie dla konkretnej pasieki
                            //zapis do tabeli "pasieki"
                            int i = 0;
                            while (hives.length > i) {
                              //print('data w apiary po imporcie = $formattedDate');
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
                            globals.odswiezBelkiUli = true;

                            // Przywrocenie tagow NFC po imporcie
                            Future<void> restoreNfcTags() async {
                              for (var entry in _nfcTags.entries) {
                                await DBHelper.updateUle(entry.key, 'h3', entry.value);
                              }
                            }
                            restoreNfcTags().then((_) {

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
                              //print('koniec importu');
                            });
                          }); //przywrocenie tagow NFC
                          }); //pobranie uli z lokalnej i wpis do pasieki
                        }); //pobranie info z z bazy lokalnej i wpis do uli
                      }); //pobranie info z internetu
                    }); //pobranie ramek z loklnej i wpis do uli
                  }); //pobranie ramek z internetu

                } else {
                  //print('braaaaaak internetu');
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
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      // Mobile network available.
      return true;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      // Wi-fi is available.
      // Note for Android: When both mobile and Wi-Fi are turned on system will return Wi-Fi only as active network type
      return true;
    } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
      // Bluetooth connection available.
      return true;
    } else if (connectivityResult.contains(ConnectivityResult.other)) {
      // Connected to a network which is not in the above mentioned networks.
      return false;
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      // No available network types
      return false;
    }else return false;
  }

  //eksport wszystkich danych Notatki
  void _showAlertExportAllNotatki(BuildContext context, String nazwa, String text) {
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
            onPressed: () async{
              //print('wysłanie wszystkich danych do chmury ========= ');
              showLoaderDialog (context, AppLocalizations.of(context)!.eXportData);// wskaźnik wysyłania
              await Future.delayed(const Duration(seconds: 1)); //zeby pojawił sie wskaźnik wysyłania jak jest malo danych
              iloscDoWyslania = 0;

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli notatki - wszystkie 
                Provider.of<Notes>(context, listen: false) //DBHelper - pobieranie notatek
                    .fetchAndSetNotatki() //wczytanie danych do uruchomienia apki --> Notatki <---
                    .then((_) {
                  final notatkiArchData = Provider.of<Notes>(context, listen: false);
                  final notatki = notatkiArchData.items;
                  // print('ilość nowych wpisów w tabeli notatki');
                  // print(info.length);
                  iloscDoWyslania = notatki.length;
                    
                    if (iloscDoWyslania > 0)
                      _showAlertOK(
                          context,
                          AppLocalizations.of(context)!.alert,
                          AppLocalizations.of(context)!.dataToSend +
                              ' = $iloscDoWyslania');
                    else
                      _showAlertOK(context, AppLocalizations.of(context)!.alert,
                        AppLocalizations.of(context)!.noDataToSend);
                  
                  //przygotowanie notatek do wysyłki
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
                      jsonData += '"pole1": "${notatki[i].pole1}",';
                      jsonData += '"pole2": "${notatki[i].pole2}",';
                      jsonData += '"pole3": "${notatki[i].pole3}",';
                      jsonData += '"uwagi": "${notatki[i].uwagi}",';
                      jsonData += '"arch": ${notatki[i].arch}}';
                      i++;
                      if (notatki.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${notatki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_notatki"}'; //pierwsze cztery cyfry kodu XXXX_zakupy

                    //print(jsonData); //json przygotowany poprawnie
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupNotatki(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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
      barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  //eksport wszystkich danych Zakupy
  void _showAlertExportAllZakupy(BuildContext context, String nazwa, String text) {
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
            onPressed: () async{
              //print('wysłanie wszystkich danych do chmury ========= ');
              showLoaderDialog (context, AppLocalizations.of(context)!.eXportData);// wskaźnik wysyłania
              await Future.delayed(const Duration(seconds: 1)); 
              iloscDoWyslania = 0;

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
             
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
                     
                    if (iloscDoWyslania > 0)
                      _showAlertOK(
                          context,
                          AppLocalizations.of(context)!.alert,
                          AppLocalizations.of(context)!.dataToSend +
                              ' = $iloscDoWyslania');
                    else
                      _showAlertOK(context, AppLocalizations.of(context)!.alert,
                        AppLocalizations.of(context)!.noDataToSend);
                    
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
                        '],"total":${zakupy.length}, "tabela":"${mem[0].kod.substring(0, 4)}_zakupy"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupZakupy(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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
      barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  //eksport wszystkich danych Sprzedaz
  void _showAlertExportAllSprzedaz(BuildContext context, String nazwa, String text) {
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
            onPressed: () async{
              //print('wysłanie wszystkich danych do chmury ========= ');
              showLoaderDialog (context, AppLocalizations.of(context)!.eXportData);// wskaźnik wysyłania
              await Future.delayed(const Duration(seconds: 1)); 
              iloscDoWyslania = 0;

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli sprzedaz - wszystkie
                Provider.of<Sales>(context, listen: false)
                    .fetchAndSetSprzedaz()
                    .then((_) {
                  final sprzedazArchData =
                      Provider.of<Sales>(context, listen: false);
                  final sprzedaz = sprzedazArchData.items;
                   //print('ilość nowych wpisów w tabeli info');
                   //print(sprzedaz.length);
                  iloscDoWyslania = sprzedaz.length;
                  
                    if (iloscDoWyslania > 0)
                      _showAlertOK(
                          context,
                          AppLocalizations.of(context)!.alert,
                          AppLocalizations.of(context)!.dataToSend +
                              ' = $iloscDoWyslania');
                    else
                      _showAlertOK(context, AppLocalizations.of(context)!.alert,
                        AppLocalizations.of(context)!.noDataToSend);
                  
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
                        '],"total":${sprzedaz.length}, "tabela":"${mem[0].kod.substring(0, 4)}_sprzedaz"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupSprzedaz(jsonData); //jsonData
                        } else {
                         // print('braaaaaak internetu');
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
      barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  //eksport wszystkich danych Matki
  void _showAlertExportAllMatki(BuildContext context, String nazwa, String text) {
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
            onPressed: () async{
              //print('wysłanie wszystkich danych do chmury ========= ');
              showLoaderDialog (context, AppLocalizations.of(context)!.eXportData);// wskaźnik wysyłania
              await Future.delayed(const Duration(seconds: 1)); 
              iloscDoWyslania = 0;

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli matki - wszystkie
                Provider.of<Queens>(context, listen: false)
                    .fetchAndSetQueens()
                    .then((_) {
                  final matkiArchData =
                      Provider.of<Queens>(context, listen: false);
                  final matki = matkiArchData.items;
                   //print('ilość nowych wpisów w tabeli matki');
                   //print(matki.length);
                  iloscDoWyslania = matki.length;
                  
                    if (iloscDoWyslania > 0)
                      _showAlertOK(
                          context,
                          AppLocalizations.of(context)!.alert,
                          AppLocalizations.of(context)!.dataToSend +
                              ' = $iloscDoWyslania');
                    else
                      _showAlertOK(context, AppLocalizations.of(context)!.alert,
                        AppLocalizations.of(context)!.noDataToSend);
                  
                  if (matki.length > 0) {
                    String jsonData = '{"matki":[';
                    int i = 0;
                    while (matki.length > i) {
                      jsonData += '{"id": "${matki[i].id}",';
                      jsonData += '"data": "${matki[i].data}",';
                      jsonData += '"zrodlo": "${matki[i].zrodlo}",';
                      jsonData += '"rasa": "${matki[i].rasa}",';
                      jsonData += '"linia": "${matki[i].linia}",';
                      jsonData += '"znak": "${matki[i].znak}",';
                      jsonData += '"napis": "${matki[i].napis}",';
                      jsonData += '"uwagi": "${matki[i].uwagi}",';
                      jsonData += '"pasieka": ${matki[i].pasieka},';
                      jsonData += '"ul": ${matki[i].ul},';
                      jsonData += '"dataStraty": "${matki[i].dataStraty}",';
                      jsonData += '"a": "${matki[i].a}",';
                      jsonData += '"b": "${matki[i].b}",';
                      jsonData += '"c": "${matki[i].c}",';
                      jsonData += '"arch": ${matki[i].arch}}';
                      i++;
                      if (matki.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${matki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_matki"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupMatki(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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
      barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }


  //eksport wszystkich danych Zbiory
  void _showAlertExportAllZbiory(BuildContext context, String nazwa, String text) {
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
            onPressed: () async{
              //print('wysłanie wszystkich danych do chmury ========= ');
              showLoaderDialog (context, AppLocalizations.of(context)!.eXportData);// wskaźnik wysyłania
              await Future.delayed(const Duration(seconds: 1)); 
              iloscDoWyslania = 0;

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli zbiory - wszstkie
                Provider.of<Harvests>(context, listen: false)
                    .fetchAndSetZbiory()
                    .then((_) {
                  final zbioryArchData =
                      Provider.of<Harvests>(context, listen: false);
                  final zbiory = zbioryArchData.items;
                  // print('ilość nowych wpisów w tabeli info');
                  // print(info.length);
                  iloscDoWyslania = zbiory.length;
                  
                    if (iloscDoWyslania > 0)
                      _showAlertOK(
                          context,
                          AppLocalizations.of(context)!.alert,
                          AppLocalizations.of(context)!.dataToSend +
                              ' = $iloscDoWyslania');
                    else
                      _showAlertOK(context, AppLocalizations.of(context)!.alert,
                        AppLocalizations.of(context)!.noDataToSend);
                  
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
                        '],"total":${zbiory.length}, "tabela":"${mem[0].kod.substring(0, 4)}_zbiory"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupZbiory(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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
      barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  //eksport wszystkich danych Info
  void _showAlertExportAllInfo(BuildContext context, String nazwa, String text) {
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

          //tylko z biezącego roku
           TextButton(
            onPressed: () async{
              //print('wysłanie wszystkich danych do chmury ========= ');
              showLoaderDialog (context, AppLocalizations.of(context)!.eXportData);// wskaźnik wysyłania
              await Future.delayed(const Duration(seconds: 1)); 
              iloscDoWyslania = 0;

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli info - wszystkie wpisy
                Provider.of<Infos>(context, listen: false)
                    .fetchAndSetInfos()
                    .then((_) {
                  final infoAllData = Provider.of<Infos>(context, listen: false);
                  //final info = infoAllData.items;
                  final info  = infoAllData.items.where((inf) {
                    return inf.data.startsWith(biezacyRok); //z datą zaczynajacą się od wybranego roku
                  }).toList();
                  //print('ilość wszystkich z biezącego roku wpisów w tabeli info');
                  //print(info.length);
                  iloscDoWyslania = info.length;
                  
                    if (iloscDoWyslania > 0)
                      _showAlertOK(
                          context,
                          AppLocalizations.of(context)!.alert,
                          AppLocalizations.of(context)!.dataToSend +
                              ' = $iloscDoWyslania');
                    else
                      _showAlertOK(context, AppLocalizations.of(context)!.alert,
                          AppLocalizations.of(context)!.noDataToSend);

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
                        '],"total":${info.length}, "tabela":"${mem[0].kod.substring(0, 4)}_info"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupInfo(jsonData); //jsonData
                        } else {
                          //print('braaaak internetu');
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
            
            },
            child: Text(AppLocalizations.of(context)!.oNly + ' $biezacyRok'),
          ),

          //wszystkie informacje z wszystkich lat          
          TextButton(
            onPressed: () async{
              //print('wysłanie wszystkich danych do chmury ========= ');
              showLoaderDialog (context, AppLocalizations.of(context)!.eXportData);// wskaźnik wysyłania
              await Future.delayed(const Duration(seconds: 1)); 
              iloscDoWyslania = 0;

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli info - wszystkie wpisy
                Provider.of<Infos>(context, listen: false)
                    .fetchAndSetInfos()
                    .then((_) {
                  final infoAllData = Provider.of<Infos>(context, listen: false);
                  final info = infoAllData.items;
                  //print('ilość wszystkich wpisów w tabeli info');
                  //print(info.length);
                  iloscDoWyslania = info.length;
                  
                    if (iloscDoWyslania > 0)
                      _showAlertOK(
                          context,
                          AppLocalizations.of(context)!.alert,
                          AppLocalizations.of(context)!.dataToSend +
                              ' = $iloscDoWyslania');
                    else
                      _showAlertOK(context, AppLocalizations.of(context)!.alert,
                          AppLocalizations.of(context)!.noDataToSend);

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
                      //print(i);
                      
                      // setState(() {
                      //   count = i.toDouble();
                      // print('test $count');
                    // });
                      
                      if (info.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${info.length}, "tabela":"${mem[0].kod.substring(0, 4)}_info"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupInfo(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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
            
            },
            child: Text(AppLocalizations.of(context)!.aLl),
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
      barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }
 
  //eksport wszystkich danych Ramki
  void _showAlertExportAllRamki(BuildContext context, String nazwa, String text) {
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
          //dane o ramkach tylko z tego roku
          TextButton(
            onPressed: () async{
              //print('wysłanie wszystkich danych do chmury ========= ');
              showLoaderDialog (context, AppLocalizations.of(context)!.eXportData);// wskaźnik wysyłania
              await Future.delayed(const Duration(seconds: 1)); 
              iloscDoWyslania = 0;

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli ramka - wszystkie wpisy z tego roku
                Provider.of<Frames>(context, listen: false)
                    .fetchAndSetFrames()
                    .then((_) {
                  final framesAllData = Provider.of<Frames>(context, listen: false);
                  //final ramki = framesAllData.items;
                  final ramki  = framesAllData.items.where((ra) {
                    return ra.data.startsWith(biezacyRok); //z datą zaczynajacą się od wybranego roku
                  }).toList();
                  // print('ilość wszystkich wpisów z biezącego roku w tabeli ramka');
                  //print(ramki.length);

                  //informacja o ilości rekordów do wysłania
                  iloscDoWyslania = ramki.length;
                  
                  //okno wyświetla się dopiero po wysłaniu danych
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
                      jsonData += '"ramkaNrPo": ${ramki[i].ramkaNrPo},';
                      jsonData += '"rozmiar": ${ramki[i].rozmiar},';
                      jsonData += '"strona": ${ramki[i].strona},';
                      jsonData += '"zasob": ${ramki[i].zasob},';
                      jsonData += '"wartosc": "${ramki[i].wartosc}",';
                      jsonData += '"arch": ${ramki[i].arch}}';
                      i++;
                      //print(i);
                      if (ramki.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${ramki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_ramka"}'; //pierwsze cztery cyfry kodu ramka_XXXX
                    //print('utworzono jsonData');        
                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          //print('$inter - jest internet');
                          wyslijBackupRamka(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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

               //Navigator.of(context).pop();
              
            
            },
            child: Text(AppLocalizations.of(context)!.oNly + ' $biezacyRok'), //AppLocalizations.of(context)!.eXport),
          ),
  
          //Dane o ramkach z wszystkich lat        
          TextButton(
            onPressed: () async{
              //print('wysłanie wszystkich danych do chmury ========= ');
              showLoaderDialog (context, AppLocalizations.of(context)!.eXportData);// wskaźnik wysyłania
              await Future.delayed(const Duration(seconds: 1)); 
              iloscDoWyslania = 0;

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli ramka - wszystkie wpisy
                Provider.of<Frames>(context, listen: false)
                    .fetchAndSetFrames()
                    .then((_) {
                  final framesAllData =
                      Provider.of<Frames>(context, listen: false);
                  final ramki = framesAllData.items;
                  // print('ilość wszystkich wpisów w tabeli ramka');
                  //print(ramki.length);

                  //informacja o ilości rekordów do wysłania
                  iloscDoWyslania = ramki.length;
                  
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
                      jsonData += '"ramkaNrPo": ${ramki[i].ramkaNrPo},';
                      jsonData += '"rozmiar": ${ramki[i].rozmiar},';
                      jsonData += '"strona": ${ramki[i].strona},';
                      jsonData += '"zasob": ${ramki[i].zasob},';
                      jsonData += '"wartosc": "${ramki[i].wartosc}",';
                      jsonData += '"arch": ${ramki[i].arch}}';
                      i++;
                      if (ramki.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${ramki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_ramka"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          //print('$inter - jest internet');
                          wyslijBackupRamka(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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

               //Navigator.of(context).pop();
              
            
            },
            child: Text(AppLocalizations.of(context)!.aLl),
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
      barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }
  
  
  //eksport wszystkich danych
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
            onPressed: () async{
              //print('wysłanie wszystkich danych do chmury ========= ');
              showLoaderDialog (context, AppLocalizations.of(context)!.eXportData);// wskaźnik wysyłania
              await Future.delayed(const Duration(seconds: 1)); 
              iloscDoWyslania = 0;

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli notatki - wszystkie
                Provider.of<Notes>(context, listen: false) //DBHelper - pobieranie notatek
                    .fetchAndSetNotatki() //wczytanie danych do uruchomienia apki --> Notatki <---
                    .then((_) {
                  final notatkiArchData = Provider.of<Notes>(context, listen: false);
                  final notatki = notatkiArchData.items;
                  // print('ilość nowych wpisów w tabeli notatki');
                  // print(info.length);
                  iloscDoWyslania += notatki.length;
                     
                  //przygotowanie notatek do wysyłki
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
                      jsonData += '"pole1": "${notatki[i].pole1}",';
                      jsonData += '"pole2": "${notatki[i].pole2}",';
                      jsonData += '"pole3": "${notatki[i].pole3}",';
                      jsonData += '"uwagi": "${notatki[i].uwagi}",';
                      jsonData += '"arch": ${notatki[i].arch}}';
                      i++;
                      if (notatki.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${notatki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_notatki"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                    //print(jsonData); //json przygotowany poprawnie
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupNotatki(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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
                  iloscDoWyslania += zakupy.length;
                     
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
                        '],"total":${zakupy.length}, "tabela":"${mem[0].kod.substring(0, 4)}_zakupy"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupZakupy(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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
                  iloscDoWyslania += sprzedaz.length;
                  
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
                        '],"total":${sprzedaz.length}, "tabela":"${mem[0].kod.substring(0, 4)}_sprzedaz"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupSprzedaz(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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

              //BACKUP tabeli matki - wszystkie
                Provider.of<Queens>(context, listen: false)
                    .fetchAndSetQueens()
                    .then((_) {
                  final matkiArchData =
                      Provider.of<Queens>(context, listen: false);
                  final matki = matkiArchData.items;
                  // print('ilość nowych wpisów w tabeli info');
                  // print(info.length);
                  iloscDoWyslania += matki.length;
                  
                  if (matki.length > 0) {
                    String jsonData = '{"matki":[';
                    int i = 0;
                    while (matki.length > i) {
                      jsonData += '{"id": "${matki[i].id}",';
                      jsonData += '"data": "${matki[i].data}",';
                      jsonData += '"zrodlo": "${matki[i].zrodlo}",';
                      jsonData += '"rasa": "${matki[i].rasa}",';
                      jsonData += '"linia": "${matki[i].linia}",';
                      jsonData += '"znak": "${matki[i].znak}",';
                      jsonData += '"napis": "${matki[i].napis}",';
                      jsonData += '"uwagi": "${matki[i].uwagi}",';
                      jsonData += '"pasieka": ${matki[i].pasieka},';
                      jsonData += '"ul": ${matki[i].ul},';
                      jsonData += '"dataStraty": "${matki[i].dataStraty}",';
                      jsonData += '"a": "${matki[i].a}",';
                      jsonData += '"b": "${matki[i].b}",';
                      jsonData += '"c": "${matki[i].c}",';
                      jsonData += '"arch": ${matki[i].arch}}';
                      i++;
                      if (matki.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${matki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_matki"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupMatki(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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


              //BACKUP tabeli zbiory - wszystkie
                Provider.of<Harvests>(context, listen: false)
                    .fetchAndSetZbiory()
                    .then((_) {
                  final zbioryArchData =
                      Provider.of<Harvests>(context, listen: false);
                  final zbiory = zbioryArchData.items;
                  // print('ilość nowych wpisów w tabeli info');
                  // print(info.length);
                  iloscDoWyslania += zbiory.length;
                                   
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
                        '],"total":${zbiory.length}, "tabela":"${mem[0].kod.substring(0, 4)}_zbiory"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupZbiory(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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
                  //print(info.length);
                  iloscDoWyslania += info.length;
                  
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
                        '],"total":${info.length}, "tabela":"${mem[0].kod.substring(0, 4)}_info"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupInfo(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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
                      jsonData += '"ramkaNrPo": ${ramki[i].ramkaNrPo},';
                      jsonData += '"rozmiar": ${ramki[i].rozmiar},';
                      jsonData += '"strona": ${ramki[i].strona},';
                      jsonData += '"zasob": ${ramki[i].zasob},';
                      jsonData += '"wartosc": "${ramki[i].wartosc}",';
                      jsonData += '"arch": ${ramki[i].arch}}';
                      i++;
                      if (ramki.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${ramki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_ramka"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                         // print('$inter - jest internet');
                          wyslijBackupRamka(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
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

               //Navigator.of(context).pop();
              
            
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
      barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  
  //eksport wszystkich ale tylko nowych danych
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
              
              iloscDoWyslania = 0;
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
                iloscDoWyslania += notatki.length;
                
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
                    jsonData += '"pole1": "${notatki[i].pole1}",';
                    jsonData += '"pole2": "${notatki[i].pole2}",';
                    jsonData += '"pole3": "${notatki[i].pole3}",';
                    jsonData += '"uwagi": "${notatki[i].uwagi}",';
                    jsonData += '"arch": ${notatki[i].arch}}';
                    i++;
                    if (notatki.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${notatki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_notatki"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupNotatki(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
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
                 iloscDoWyslania += zakupy.length;
                // if (iloscDoWyslania > 0)
                //   _showAlertOK(
                //       context,
                //       AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.dataToSend +
                //           ' = $iloscDoWyslania');
                // else
                //   _showAlertOK(context, AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.noDataToSend);

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
                      '],"total":${zakupy.length}, "tabela":"${mem[0].kod.substring(0, 4)}_zakupy"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupZakupy(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
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
                iloscDoWyslania += sprzedaz.length;
                //if (iloscDoWyslania > 0)
                //   _showAlertOK(
                //       context,
                //       AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.dataToSend +
                //           ' = $iloscDoWyslania');
                // else
                //   _showAlertOK(context, AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.noDataToSend);

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
                      '],"total":${sprzedaz.length}, "tabela":"${mem[0].kod.substring(0, 4)}_sprzedaz"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupSprzedaz(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
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

              //BACKUP tabeli matki - tylko wpisy z arch=0
              Provider.of<Queens>(context, listen: false)
                  .fetchAndSetQueensToArch()
                  .then((_) {
                final matkiArchData =
                    Provider.of<Queens>(context, listen: false);
                final matki = matkiArchData.items;
                // print('ilość nowych wpisów w tabeli info');
                // print(info.length);
                iloscDoWyslania += matki.length;
                //if (iloscDoWyslania > 0)
                //   _showAlertOK(
                //       context,
                //       AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.dataToSend +
                //           ' = $iloscDoWyslania');
                // else
                //   _showAlertOK(context, AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.noDataToSend);

                if (matki.length > 0) {
                  String jsonData = '{"matki":[';
                  int i = 0;
                  while (matki.length > i) {
                    jsonData += '{"id": "${matki[i].id}",';
                    jsonData += '"data": "${matki[i].data}",';
                    jsonData += '"zrodlo": "${matki[i].zrodlo}",';
                    jsonData += '"rasa": "${matki[i].rasa}",';
                    jsonData += '"linia": "${matki[i].linia}",';
                    jsonData += '"znak": "${matki[i].znak}",';
                    jsonData += '"napis": "${matki[i].napis}",';
                    jsonData += '"uwagi": "${matki[i].uwagi}",';
                    jsonData += '"pasieka": ${matki[i].pasieka},';
                    jsonData += '"ul": ${matki[i].ul},';
                    jsonData += '"dataStraty": "${matki[i].dataStraty}",';
                    jsonData += '"a": "${matki[i].a}",';
                    jsonData += '"b": "${matki[i].b}",';
                    jsonData += '"c": "${matki[i].c}",';
                    jsonData += '"arch": ${matki[i].arch}}';
                    i++;
                    if (matki.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${matki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_matki"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupMatki(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
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
                iloscDoWyslania += zbiory.length;

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
                      '],"total":${zbiory.length}, "tabela":"${mem[0].kod.substring(0, 4)}_zbiory"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupZbiory(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
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
                iloscDoWyslania += info.length;
                // if (iloscDoWyslania > 0)
                //   _showAlertOK(
                //       context,
                //       AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.dataToSend +
                //           ' = $iloscDoWyslania');
                // else
                //   _showAlertOK(context, AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.noDataToSend);

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
                      '],"total":${info.length}, "tabela":"${mem[0].kod.substring(0, 4)}_info"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupInfo(jsonData); //jsonData
                      } else {
                       // print('braaaaaak internetu');
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
                    jsonData += '"ramkaNrPo": ${ramki[i].ramkaNrPo},';
                    jsonData += '"rozmiar": ${ramki[i].rozmiar},';
                    jsonData += '"strona": ${ramki[i].strona},';
                    jsonData += '"zasob": ${ramki[i].zasob},';
                    jsonData += '"wartosc": "${ramki[i].wartosc}",';
                    jsonData += '"arch": ${ramki[i].arch}}';
                    i++;
                    if (ramki.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${ramki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_ramka"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        //print('$inter - jest internet');
                        wyslijBackupRamka(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
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

  //kasowanie zawartości wszystkich tabeli 
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
                              DBHelper.deleteTable('matki').then((_) {
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




  //kasowanie danych na serwerze zewnętrznym (w chmurze)
  void _showAlertDeleteDataOnSerwer(
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
              WyslijPolecenieKasowania();
                                               
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


//wyslania polecenia kasowania wszystkich danych  na serwerze w chmurze
  Future<void> WyslijPolecenieKasowania() async {
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_del_database.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "kod_mobile": globals.kod,
        "deviceId": globals.deviceId,
        "wersja": globals.wersja,
        "jezyk": globals.jezyk,
      }),
    );
    //print('$kod ${globals.deviceId} $wersja ${globals.jezyk}');
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        _showAlertOK(context, AppLocalizations.of(context)!.success,
            AppLocalizations.of(context)!.deleteOk );//+ odpPost['be_do']);
        //zapis do bazy lokalnej z bazy www
        // DBHelper.deleteTable('memory').then((_) {
        //   //kasowanie tabeli bo będzie nowy wpis
        //   Memory.insertMemory(
        //     odpPost['be_id'], //id
        //     odpPost['be_email'],
        //     //ponizej wstawone wartosci deviceId i wersja z apki, bo www nie zdązy ich zapisać i nie ma ich po pobraniu
        //     //globals.deviceId, //
        //     odpPost['be_dev'], //deviceId
        //     //wersja, //
        //     odpPost['be_wersja'], //wersja apki
        //     odpPost['be_kod'], //kod
        //     odpPost['be_key'], //accessKey
        //     odpPost['be_od'], //data od
        //     odpPost['be_do'], // do data
        //     '', //globals.memJezyk, //memjezyk - język ustawiony w Ustawienia/Język apki
        //     '', //zapas
        //     '', //zapas
        //   );
        // });
      } else {
        _showAlertOK(context, AppLocalizations.of(context)!.alert,
            AppLocalizations.of(context)!.errorWhileActivating);
        // print('brak danych dla tej apki');
      }

      //Navigator.of(context).pushNamed(OrderScreen.routeName);
      //}
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }




  //wysyłanie backupu ramka
  Future<void> wyslijBackupRamka(String jsonData1) async {
    //String jsonData1
    //print("z funkcji wysyłania");
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v6.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela ramka w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Frames>(context, listen: false)
            .fetchAndSetFramesToArch() //pobranie z bazy lokalnej ramki z arch=0 zeby zmianic na arch=1
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
            //print('po wysłaniu $i');
          }
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
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
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu info
  Future<void> wyslijBackupInfo(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v6.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
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
            //print(i);
          }
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.infoDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu zbiory
  Future<void> wyslijBackupZbiory(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v6.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
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
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.harvestDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu sprzedaz
  Future<void> wyslijBackupSprzedaz(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v6.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
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
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.saleDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu matki
  Future<void> wyslijBackupMatki(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v6.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Queens>(context, listen: false)
            .fetchAndSetQueensToArch()
            .then((_) {
          //dla tabeli Matki
          final matkiArchData = Provider.of<Queens>(context, listen: false);
          final matki = matkiArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli matki');
          //print(matki.length);
          int i = 0;
          while (matki.length > i) {
            DBHelper.updateMatkiArch(matki[i].id); //zapis arch = 1
            i++;
          }

//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.queenDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu zakupów
  Future<void> wyslijBackupZakupy(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v6.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
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
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.purchaseDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu notatek
  Future<void> wyslijBackupNotatki(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v6.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("notatki - response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') { //jezeli wysyłka się powiodła
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        
        //zapis do bazy lokalnej informacji ze zarchiwizowano nowe notatki
        Provider.of<Notes>(context, listen: false) //DBHelper - pobieranie z tabeli notatki do achiwizacji notatek z arch=0
            .fetchAndSetNotatkiToArch() //wczytanie wszystkich nowych zbiorów --> NotatkiToArch <---
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
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noteDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
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
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey[300], // kolor linii
              height: 1.0,
            ),
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
                      //print(isSwitched);
                    });
                  },
                ),
              ),
            ),
                
                // setState(() {
                //   wyborDanych ? wyborDanych = false : wyborDanych = true;
                //   //print(isSwitched);
                // });

//eksport wybranych danych Notatki
            GestureDetector(
              onTap: () {               
                _showAlertExportAllNotatki(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.nOtes + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.nOtes),
                  subtitle: Text(AppLocalizations.of(context)!.eXportNote),
                ),
              ),
            ),

//eksport wybranych danych Zbiory
            GestureDetector(
              onTap: () {               
                _showAlertExportAllZbiory(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.hArvests + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.hArvests),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportHarvest),
                ),
              ),
            ),          

//eksport wybranych danych Zakupy
            GestureDetector(
              onTap: () {               
                _showAlertExportAllZakupy(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.pUrchase + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.pUrchase),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportPurchase),
                ),
              ),
            ), 

//eksport wybranych danych Sprzedaz
            GestureDetector(
              onTap: () {               
                _showAlertExportAllSprzedaz(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.sAle + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.sAle),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportSale),
                ),
              ),
            ),  

//eksport wybranych danych Matki
            GestureDetector(
              onTap: () {               
                _showAlertExportAllMatki(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.qUeens + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.qUeens),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportQueens),
                ),
              ),
            ), 

//eksport wybranych danych Ramki
            GestureDetector(
              onTap: () {               
                _showAlertExportAllRamki(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.fRames + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.fRames),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportFrame),
                ),
              ),
            ),  

//eksport wybranych danych Info
            GestureDetector(
              onTap: () {               
                _showAlertExportAllInfo(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.iNfos + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.iNfos),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportInfo),
                ),
              ),
            ),


          
      /*    
          if(wyborDanych)
            Card(
              child: ListTile(
                title: Text('     Notatki'),
                trailing: Switch.adaptive(
                    value: archNotatki,
                    onChanged: (value) {
                      setState(() {
                        archNotatki = value;
                        print(archNotatki);
                      });
                    },
                )  
              ),
            ),
          if(wyborDanych)
            Card(
              child: ListTile(
                title: Text('     Zbiory'),
                trailing: Switch.adaptive(
                    value: archZbiory,
                    onChanged: (value) {
                      setState(() {
                        archZbiory = value;
                        print(archZbiory);
                      });
                    },
                )  
              ),
            ),
          if(wyborDanych)
            Card(
              child: ListTile(
                title: Text('     Zakupy'),
                trailing: Switch.adaptive(
                    value: archZakupy,
                    onChanged: (value) {
                      setState(() {
                        archZakupy = value;
                        print(archZakupy);
                      });
                    },
                )  
              ),
            ),
          if(wyborDanych)
            Card(
              child: ListTile(
                title: Text('     Sprzedaz'),
                trailing: Switch.adaptive(
                    value: archSprzedaz,
                    onChanged: (value) {
                      setState(() {
                        archSprzedaz = value;
                        print(archSprzedaz);
                      });
                    },
                )  
              ),
            ),
            if(wyborDanych)
            Card(
              child: ListTile(
                title: Text('     Przeglądy ramek'),
                trailing: Switch.adaptive(
                    value: archRamki,
                    onChanged: (value) {
                      setState(() {
                        archRamki = value;
                        print(archRamki);
                      });
                    },
                )  
              ),
            ),
            if(wyborDanych)
            Card(
              child: ListTile(
                title: Text('     Pozostałe informacje'),
                trailing: Switch.adaptive(
                    value: archInfo,
                    onChanged: (value) {
                      setState(() {
                        archInfo = value;
                        print(archInfo);
                      });
                    },
                )  
              ),
            ),
            if(wyborDanych)
            Card(
              child: ListTile(
                title: Text('     Tylko z biezącego roku'),
                trailing: Switch.adaptive(
                    value: archOstatniRok,
                    onChanged: (value) {
                      setState(() {
                        archOstatniRok = value;
                        print(archOstatniRok);
                      });
                    },
                )  
              ),
            ),
 */
 //eksport wwszystkich danych teraz         
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
                  title: Text(AppLocalizations.of(context)!.exportAllToCloud),//wszystkich wybranych
                  subtitle: Text(AppLocalizations.of(context)!.backupAllData),
                ),
              ),
            ),        


//usunięcie wszystkich danych w tabelach lokalnych
            GestureDetector(
              onTap: () {
                _showAlertDeleteRamkaInfo(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.deleteRamkaInfo)); //usunięcie wszystkich danych lokalnie
                //Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.deleteAllData),
                  subtitle: Text(AppLocalizations.of(context)!.onlyInLocalDatabase),
                ),
              ),
            ),

//usunięcie wszystkich danych w chmurze (zmiany nazw tabeli na" data_czas_prefix_nazwaTabeli"
            GestureDetector(
              onTap: () {
                _showAlertDeleteDataOnSerwer(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.deleteDataOnSerwer));
                //Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.deleteAllDataOnSerwer),
                  subtitle: Text(AppLocalizations.of(context)!.allDatabaseOnSerwer),
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

