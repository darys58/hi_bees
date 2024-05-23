import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;

import '../screens/parametr_edit_screen.dart';
import '../models/info.dart';
import '../models/infos.dart';
import '../models/dodatki1.dart';

class ParametrScreen extends StatefulWidget {
  static const routeName = '/parametr';

  @override
  State<ParametrScreen> createState() => _ParametrScreenState();
}

class _ParametrScreenState extends State<ParametrScreen> {
  bool _isInit = true;
  int miodMala = 0;
  int miodDuza = 0;

  @override
  void didChangeDependencies() {
    // print('import_screen - didChangeDependencies');

    // print('import_screen - _isInit = $_isInit');

    if (_isInit) {
      Provider.of<Infos>(context, listen: false).fetchAndSetInfos().then((_) {
        //wszystkie informacje dla wybranej pasieki i ula
      });
      //uzyskanie dostępu do danych z tabeli dodatki1
      // final dod1Data = Provider.of<Dodatki1>(context, listen: false);
      // final dod1 = dod1Data.items;
      // if (dod1[0].a == 'true') {
      //   //a - przełącznik eksportu danych
      //   setState(() {
      //     isSwitched = true;
      //   });
      // } else {
      //   setState(() {
      //     isSwitched = false;
      //   });
      // }
      // });
    }
    _isInit = false;
    //Provider.of<Rests>(context, listen: false).fetchAndSetRests(); //dostawca restauracji
    super.didChangeDependencies();
  }

  // // void _showAlertAnuluj(BuildContext context, String nazwa, String text) {
  // Future<bool> _isInternet() async {
  //   var connectivityResult = await (Connectivity().checkConnectivity());
  //   if (connectivityResult == ConnectivityResult.mobile) {
  //     print("Connected to Mobile Network");
  //     return true;
  //   } else if (connectivityResult == ConnectivityResult.wifi) {
  //     print("Connected to WiFi");
  //     return true;
  //   } else {
  //     print("Unable to connect. Please Check Internet Connection");
  //     return false;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    //uzyskanie dostępu do danych w pamięci
    // final memData = Provider.of<Memory>(context, listen: false);
    // final mem = memData.items;
    final dod1Data = Provider.of<Dodatki1>(context);
    final dod1 = dod1Data.items;

    //pobranie danych info z wybranej kategorii
    final infosData = Provider.of<Infos>(context);
    List<Info> infos = infosData.items.where((inf) {
      return inf.kategoria.contains('harvest');
    }).toList();

    miodMala = 0;
    miodDuza = 0;

    //****** ZBIORY*****  dla harvest:
    for (var i = 0; i < infos.length; i++) {
      //print('i=$i');
      //dla roku statystyk i danego rodzaju zbioru (miód, mała ramka)
      if (infos[i].data.substring(0, 4) == globals.rokStatystyk &&
          infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x") {
        miodMala = miodMala + (int.parse(infos[i].wartosc) * int.parse(dod1[0].e));
        //print('mała=$miodMala ');
      }
      //dla  roku statystyk i danego rodzaju zbioru (miód, duza ramka)
      if (infos[i].data.substring(0, 4) == globals.rokStatystyk &&
          infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x") {
        miodDuza = miodDuza + (int.parse(infos[i].wartosc) * int.parse(dod1[0].f));
        //print('duza=$miodDuza');
      }
    }

    // wybór roku do statystyk
    void _showAlertYear() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectStatYear),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if(2023 <= int.parse(DateTime.now().toString().substring(0, 4)))
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2023';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName,
                  );
              }, child: Text(('2023'),style: TextStyle(fontSize: 18))
              ),  
            if(2024 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2024';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName, 
                );
              }, child: Text(('2024'),style: TextStyle(fontSize: 18))
              ),
            if(2025 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2025';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName, 
                );
              }, child: Text(('2025'),style: TextStyle(fontSize: 18))
              ),
            if(2026 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2026';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName, 
                );
              }, child: Text(('2026'),style: TextStyle(fontSize: 18))
              ),
            if(2027 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2027';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName, 
                );
              }, child: Text(('2027'),style: TextStyle(fontSize: 18))
              ),
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

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          actions: <Widget>[          
            IconButton(
              icon: Icon(Icons.query_stats, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () => 
                  _showAlertYear(),              
            ),
          ],
          title: Text(
            AppLocalizations.of(context)!.pArameterization,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
        ),
        body: dod1.isEmpty
            ? Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 50),
                      child: Text(
                        AppLocalizations.of(context)!.noData,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                children: <Widget>[
//waga małej
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          ParametrEditScreen.routeName,
                          arguments: {'pole': 'e', 'wartosc': dod1[0].e});
                    },
                    child: Card(
                      child: ListTile(
                        //leading: Icon(Icons.settings),
                        title: Text(
                            AppLocalizations.of(context)!.weightSmallFrame +
                                ' = ' +
                                dod1[0].e +
                                ' g'),
                        subtitle:
                            Text(AppLocalizations.of(context)!.zMalychW + '${globals.rokStatystyk}: ${miodMala / 1000} kg (z ${(miodMala + miodDuza) / 1000} kg)'),
                        trailing: const Icon(Icons.edit),
                        //trailing: Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
                  //waga duzej

                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          ParametrEditScreen.routeName,
                          arguments: {'pole': 'f', 'wartosc': dod1[0].f});
                    },
                    child: Card(
                      child: ListTile(
                        //leading: Icon(Icons.settings),
                        title: Text(
                            AppLocalizations.of(context)!.weightBigFrame +
                                ' = ' +
                                dod1[0].f +
                                ' g'),
                        subtitle: Text(AppLocalizations.of(context)!.zDuzychW + '${globals.rokStatystyk}: ${miodDuza/1000} kg (z ${(miodMala + miodDuza) / 1000} kg) '),
                        trailing: const Icon(Icons.edit),
                      ),
                    ),
                  ),
//pojemnosc małej miarki
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          ParametrEditScreen.routeName,
                          arguments: {'pole': 'g', 'wartosc': dod1[0].g});
                    },
                    child: Card(
                      child: ListTile(
                        //leading: Icon(Icons.settings),
                        title: Text(
                            AppLocalizations.of(context)!.weightPortion +
                                ' = ' +
                                dod1[0].g +
                                ' ml'),

                        trailing: const Icon(Icons.edit),
                      ),
                    ),
                  ),

//zwłoka
                  // GestureDetector(
                  //   onTap: () {
                  //     Navigator.of(context).pushNamed(
                  //         ParametrEditScreen.routeName,
                  //         arguments: {'pole': 'h', 'wartosc': dod1[0].h});
                  //   },
                  //   child: Card(
                  //     child: ListTile(
                  //       //leading: Icon(Icons.settings),
                  //       title: Text('Zwłoka pico = ' + dod1[0].h + ' ms'),

                  //       trailing: const Icon(Icons.edit),
                  //     ),
                  //   ),
                  // ),

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
