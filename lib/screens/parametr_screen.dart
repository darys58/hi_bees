import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;
import '../screens/parametry_ula_screen.dart';
import '../screens/parametr_edit_screen.dart';
//import '../models/info.dart';
import '../models/infos.dart';
import '../models/dodatki1.dart';
import '../models/dodatki2.dart';

class ParametrScreen extends StatefulWidget {
  static const routeName = '/parametr';

  @override
  State<ParametrScreen> createState() => _ParametrScreenState();
}

class _ParametrScreenState extends State<ParametrScreen> {
  bool _isInit = true;
  double miodMala = 0;
  double miodDuza = 0;

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

    final dod2Data = Provider.of<Dodatki2>(context);
    final dod2 = dod2Data.items;
    
    for (var i = 0; i < dod2.length; i++) {
    // print( '${dod2[0].id}, ${dod2[0].m}, ${dod2[0].n}, ${dod2[0].s}, ${dod2[0].t}, ${dod2[0].u}, ${dod2[0].v}, ${dod2[0].w}, ${dod2[0].z}');
    // print( '${dod2[1].id}, ${dod2[1].m}, ${dod2[1].n}, ${dod2[1].s}, ${dod2[1].t}, ${dod2[1].u}, ${dod2[1].v}, ${dod2[1].w}, ${dod2[1].z}');
    // int i = 2;
    // print( '${dod2[i].id}, ${dod2[i].m}, ${dod2[i].n}, ${dod2[i].s}, ${dod2[i].t}, ${dod2[i].u}, ${dod2[i].v}, ${dod2[i].w}, ${dod2[i].z}');
    //  i = 3;
    //print('i = $i');
    //print( '${dod2[i].id}, ${dod2[i].m}, ${dod2[i].n}, ${dod2[i].s}, ${dod2[i].t}, ${dod2[i].u}, ${dod2[i].v}, ${dod2[i].w}, ${dod2[i].z}');
    }
//  i = 4;
//     print( '${dod2[i].id}, ${dod2[i].m}, ${dod2[i].n}, ${dod2[i].s}, ${dod2[i].t}, ${dod2[i].u}, ${dod2[i].v}, ${dod2[i].w}, ${dod2[i].z}');

    //pobranie danych info z wybranej kategorii
    // final infosData = Provider.of<Infos>(context);
    // List<Info> infos = infosData.items.where((inf) {
    //   return inf.kategoria == ('harvest');
    // }).toList();

    miodMala = 0;
    miodDuza = 0;

    //****** ZBIORY*****  dla harvest:
    // for (var i = 0; i < infos.length; i++) {
    //   //print('i=$i');
    //   //dla roku statystyk i danego rodzaju zbioru (miód, mała ramka)
    //   if (infos[i].data.substring(0, 4) == globals.rokStatystyk &&
    //       infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x") {
    //     miodMala = miodMala + (double.parse(infos[i].wartosc) * int.parse(dod1[0].e));
    //     //print('mała=$miodMala ');
    //   }
    //   //dla  roku statystyk i danego rodzaju zbioru (miód, duza ramka)
    //   if (infos[i].data.substring(0, 4) == globals.rokStatystyk &&
    //       infos[i].parametr == AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x") {
    //     miodDuza = miodDuza + (double.parse(infos[i].wartosc) * int.parse(dod1[0].f));
    //     //print('duza=$miodDuza');
    //   }
    // }

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
              }, child: globals.rokStatystyk == '2023'
                        ? Text(('> 2023 <'),style: TextStyle(fontSize: 18))
                        : Text(('2023'),style: TextStyle(fontSize: 18))
              ),  
            if(2024 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2024';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName, 
                );
              }, child: globals.rokStatystyk == '2024'
                        ? Text(('> 2024 <'),style: TextStyle(fontSize: 18))
                        : Text(('2024'),style: TextStyle(fontSize: 18))
              ),
            if(2025 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2025';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName, 
                );
              }, child: globals.rokStatystyk == '2025'
                        ? Text(('> 2025 <'),style: TextStyle(fontSize: 18))
                        : Text(('2025'),style: TextStyle(fontSize: 18))
              ),
            if(2026 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2026';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName, 
                );
              }, child: globals.rokStatystyk == '2026'
                        ? Text(('> 2026 <'),style: TextStyle(fontSize: 18))
                        : Text(('2026'),style: TextStyle(fontSize: 18))
              ),
            if(2027 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2027';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName, 
                );
              }, child: globals.rokStatystyk == '2027'
                        ? Text(('> 2027 <'),style: TextStyle(fontSize: 18))
                        : Text(('2027'),style: TextStyle(fontSize: 18))
              ),
            if(2028 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2028';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName, 
                );
              }, child: globals.rokStatystyk == '2028'
                        ? Text(('> 2028 <'),style: TextStyle(fontSize: 18))
                        : Text(('2028'),style: TextStyle(fontSize: 18))
              ),
            if(2029 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2029';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName, 
                );
              }, child: globals.rokStatystyk == '2029'
                        ? Text(('> 2029 <'),style: TextStyle(fontSize: 18))
                        : Text(('2029'),style: TextStyle(fontSize: 18))
              ),
            if(2030 <= int.parse(DateTime.now().toString().substring(0, 4)))  
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.rokStatystyk = '2030';
                Navigator.of(context).pushNamed(
                    ParametrScreen.routeName, 
                );
              }, child: globals.rokStatystyk == '2030'
                        ? Text(('> 2030 <'),style: TextStyle(fontSize: 18))
                        : Text(('2030'),style: TextStyle(fontSize: 18))
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
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey[300], // kolor linii
              height: 1.0,
            ),
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
                  // GestureDetector(
                  //   onTap: () {
                  //     Navigator.of(context).pushNamed(
                  //         ParametrEditScreen.routeName,
                  //         arguments: {'pole': 'e', 'wartosc': dod1[0].e});
                  //   },
                  //   child: Card(
                  //     child: ListTile(
                  //       //leading: Icon(Icons.settings),
                  //       title: Text(
                  //           AppLocalizations.of(context)!.weightSmallFrame +
                  //               ' = ' +
                  //               dod1[0].e +
                  //               ' g'),
                  //       subtitle:
                  //           Text(AppLocalizations.of(context)!.zMalychW + '${globals.rokStatystyk}: ${miodMala / 1000} kg (z ${(miodMala + miodDuza) / 1000} kg)'),
                  //       trailing: const Icon(Icons.edit),
                  //       //trailing: Icon(Icons.chevron_right),
                  //     ),
                  //   ),
                  // ),

//ilość uli na stronie raportu
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          ParametrEditScreen.routeName,
                          arguments: {'pole': 'h', 'wartosc': dod1[0].h});
                    },
                    child: Card(
                      child: ListTile(
                        //leading: Icon(Icons.settings),
                        title: Text(
                            AppLocalizations.of(context)!.hivesOnSite +
                                ' = ' +
                                dod1[0].h),

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

//waga 1dm2 ramki

                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          ParametrEditScreen.routeName,
                          arguments: {'pole': 'b', 'wartosc': dod1[0].b});
                    },
                    child: Card(
                      child: ListTile(
                        //leading: Icon(Icons.settings),
                        title: Text(
                            AppLocalizations.of(context)!.weightDmFrame + AppLocalizations.of(context)!.zObuStron +
                                ' = ' +
                                dod1[0].b +
                                ' g'),
                        //subtitle: Text(AppLocalizations.of(context)!.zObuStron), //' + '${globals.rokStatystyk}: ${miodDuza/1000} kg (z ${(miodMala + miodDuza) / 1000} kg) '),
                        trailing: const Icon(Icons.edit),
                      ),
                    ),
                  ), 
//ul TYP A

                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          ParametryUlaScreen.routeName,
                          arguments: {'typ': 'TYP A', 'indexX': 0});
                    },
                    child: Card(
                      child: ListTile(
                        //leading: Icon(Icons.settings),
                        title: Text(
                            '${AppLocalizations.of(context)!.hIve } ${dod2[0].m} (${dod2[0].n})\n'//Ul TYPA Wielkopolski A
                            + '${AppLocalizations.of(context)!.frameDimensions}'),
                        subtitle: Text('${AppLocalizations.of(context)!.big}: ${dod2[0].s}x${dod2[0].t}, ${AppLocalizations.of(context)!.small}: ${dod2[0].v}x${dod2[0].w}'),
                        trailing: const Icon(Icons.edit),
                      ),
                    ),
                  ),

//ul TYP B

                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          ParametryUlaScreen.routeName,
                          arguments: {'typ': 'TYP B', 'indexX': 1});
                    },
                    child: Card(
                      child: ListTile(
                        //leading: Icon(Icons.settings),
                        title: Text(
                            '${AppLocalizations.of(context)!.hIve } ${dod2[1].m} (${dod2[1].n})\n'//Ul TYP B Wielkopolski B
                            + '${AppLocalizations.of(context)!.frameDimensions}'),
                        subtitle: Text('${AppLocalizations.of(context)!.big}: ${dod2[1].s}x${dod2[1].t}, ${AppLocalizations.of(context)!.small}: ${dod2[1].v}x${dod2[1].w}'),
                        trailing: const Icon(Icons.edit),
                      ),
                    ),
                  ),

//ul TYP C

                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          ParametryUlaScreen.routeName,
                          arguments: {'typ': 'TYP C', 'indexX': 2});
                    },
                    child: Card(
                      child: ListTile(
                        //leading: Icon(Icons.settings),
                        title: Text(
                            '${AppLocalizations.of(context)!.hIve } ${dod2[2].m} (${dod2[2].n})\n'//Ul TYP B Wielkopolski B
                            + '${AppLocalizations.of(context)!.frameDimensions}'),
                        subtitle: Text('${AppLocalizations.of(context)!.big}: ${dod2[2].s}x${dod2[2].t}, ${AppLocalizations.of(context)!.small}: ${dod2[2].v}x${dod2[2].w}'),
                        trailing: const Icon(Icons.edit),
                      ),
                    ),
                  ),

//ul TYP D

                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          ParametryUlaScreen.routeName,
                          arguments: {'typ': 'TYP D', 'indexX': 3});
                    },
                    child: Card(
                      child: ListTile(
                        //leading: Icon(Icons.settings),
                        title: Text(
                            '${AppLocalizations.of(context)!.hIve } ${dod2[3].m} (${dod2[3].n})\n'//Ul TYP B Wielkopolski B
                            + '${AppLocalizations.of(context)!.frameDimensions}'),
                        subtitle: Text('${AppLocalizations.of(context)!.big}: ${dod2[3].s}x${dod2[3].t}, ${AppLocalizations.of(context)!.small}: ${dod2[3].v}x${dod2[3].w}'),
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
