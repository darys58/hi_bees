import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;

import '../screens/activation_screen.dart';
import '../models/memory.dart';

class AboutScreen extends StatelessWidget {
  static const routeName = '/about';



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

  String zmienDate(String data) {
    String rok = data.substring(0, 4);
    String miesiac = data.substring(5, 7);
    String dzien = data.substring(8);
    return '$dzien.$miesiac.$rok';
  }

  @override
  Widget build(BuildContext context) {
   
    //uzyskanie dostępu do danych w pamięci
    final memData = Provider.of<Memory>(context, listen: false);
    final mem = memData.items;

   

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(
            AppLocalizations.of(context)!.about,
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
//wersja    
            mem.isNotEmpty 
            ? Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.versionApp + mem[0].wer),
                  //trailing: Icon(Icons.chevron_right),
                ),
              )
              : Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.versionApp + globals.wersja),
                  //trailing: Icon(Icons.chevron_right),
                ),
              ),
 //kod    
            if(mem.isNotEmpty)
              Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.activationCode + mem[0].kod),
                  
                  //trailing: Icon(Icons.chevron_right),
                ),
              ),
 //subskrypcja do:     
            mem.isNotEmpty
              ? Card(
                  child: ListTile(
                    //leading: Icon(Icons.settings),
                    title: globals.jezyk == 'pl_PL'
                    ? Text(AppLocalizations.of(context)!.subscryptionTo + zmienDate(mem[0].ddo))
                    : Text(AppLocalizations.of(context)!.subscryptionTo + mem[0].ddo),
                    subtitle: Text(mem[0].key.substring(0, 10)),
                    //trailing: Icon(Icons.chevron_right),
                  ),
                )
                : Card(
                  child: ListTile(
                    //leading: Icon(Icons.settings),
                    title: Text(AppLocalizations.of(context)!.subscryptionTo + AppLocalizations.of(context)!.noSubscryption),
                    //subtitle: Text(mem[0].key.substring(0, 10)),
                    //trailing: Icon(Icons.chevron_right),
                  ),
                ),
  //aktywuj    
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(ActivationScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.refreshActivation),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),           
             ),




//ustawienia
            // GestureDetector(
            //   onTap: () {
            //     Navigator.of(context).pushNamed(ImportScreen.routeName);
            //   },
            //   child: Card(
            //     child: ListTile(
            //       leading: Icon(Icons.settings),
            //       title: Text(AppLocalizations.of(context)!.zarzadzanieDanymi),
            //       trailing: Icon(Icons.chevron_right),
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
