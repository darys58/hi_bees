import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
// import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;
import '../main.dart';
import '../helpers/db_helper.dart';

import '../screens/import_screen.dart';
import '../screens/about_screen.dart';
import '../screens/parametr_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/nfc_settings_screen.dart';
import '../screens/apiarys_all_map_screen.dart';
import '../screens/notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';

  // Future<void> _launchURL(String url) async {
  //   if (await canLaunch(url)) {
  //     await launch(url, forceWebView: true);
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  // }

  // void _showAlertAnuluj(BuildContext context, String nazwa, String text) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text(nazwa),
  //       content: Column(
  //         //zeby tekst był wyśrodkowany w poziomie
  //         mainAxisSize: MainAxisSize.min,
  //         children: <Widget>[
  //           Text(text),
  //         ],
  //       ),
  //       actions: <Widget>[
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //           },
  //           child: Text(AppLocalizations.of(context)!.cancel),
  //         ),
  //       ],
  //       elevation: 24.0,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(15.0),
  //       ),
  //     ),
  //     barrierDismissible:
  //         false, //zeby zaciemnione tło było zablokowane na kliknięcia
  //   );
  // }

  //sprawdzenie czy jest internet
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

  /// Lista dostępnych języków z nazwami natywnymi
  static const List<Map<String, String>> _languages = [
    {'code': 'system', 'name': 'System', 'flag': '🌐'},
    {'code': 'pl', 'name': 'Polski', 'flag': '🇵🇱'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
  ];

  String _currentLanguageName() {
    final code = globals.memJezyk;
    final lang = _languages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => _languages[0],
    );
    return lang['name']!;
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cHooseLanguage),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (ctx, index) {
              final lang = _languages[index];
              final isSelected = globals.memJezyk == lang['code'];
              return ListTile(
                leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(
                  lang['code'] == 'system'
                      ? AppLocalizations.of(context)!.systemLanguage
                      : lang['name']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _changeLanguage(context, lang['code']!);
                },
              );
            },
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
    );
  }

  void _changeLanguage(BuildContext context, String langCode) {
    // Zapisz do bazy danych
    if (globals.deviceId.isNotEmpty) {
      DBHelper.updateJezyk(globals.deviceId, langCode);
    }
    // Ustaw locale
    MyApp.setLocale(langCode);
    // Odśwież globals.jezyk po zmianie
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Locale myLocale = Localizations.localeOf(context);
        globals.jezyk = myLocale.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
   
    //uzyskanie dostępu do danych w pamięci
    // final memData = Provider.of<Memory>(context, listen: false);
    // final mem = memData.items;

   

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(
            AppLocalizations.of(context)!.settings,
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

//zarządzanie danymi
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(ImportScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.storage),
                  title: Text(AppLocalizations.of(context)!.zarzadzanieDanymi),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
            ),
//parametryzacja
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(ParametrScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.tune),
                  title: Text(AppLocalizations.of(context)!.pArameterization),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
            ),
//kalkulator
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(CalculatorScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.calculate),
                  title: Text(AppLocalizations.of(context)!.calculator),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
            ),
//język
            GestureDetector(
              onTap: () {
                _showLanguageDialog(context);
              },
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.translate),
                  title: Text(AppLocalizations.of(context)!.lAnguage),
                  subtitle: Text(_currentLanguageName()),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
            ),
//Lokalizacje pasiek
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(ApiarysAllMapScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.map),
                  title: Text(AppLocalizations.of(context)!.apiaryLocations),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
            ),
//Obsługa NFC
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(NfcSettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.nfc),
                  title: Text(AppLocalizations.of(context)!.nfcSettings),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
            ),
//Powiadomienia
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(NotificationSettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text(AppLocalizations.of(context)!.notificationSettings),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
            ),
//Subskrypcja aplikacji
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AboutScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text(AppLocalizations.of(context)!.about),
                  trailing: Icon(Icons.chevron_right),
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
