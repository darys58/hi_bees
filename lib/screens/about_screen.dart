import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
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
                  title: Text(AppLocalizations.of(context)!.activationCode + mem[0].kod),
                  trailing: IconButton(
                    icon: Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: mem[0].kod));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(mem[0].kod),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),
 //subskrypcja do:     
            mem.isNotEmpty
              ? Card(
                  child: ListTile(
                    //leading: Icon(Icons.settings),
                    title:Text(AppLocalizations.of(context)!.subscryptionTo + AppLocalizations.of(context)!.noLimits),
                    // title: globals.isEuropeanFormat()
                    // ? Text(AppLocalizations.of(context)!.subscryptionTo + zmienDate(mem[0].ddo))
                    // : Text(AppLocalizations.of(context)!.subscryptionTo + mem[0].ddo),
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

            SizedBox(height: 50),

          
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 0.0),
                  child: Column(                    
                    children: [
     //www                
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse('https://www.heymaya.eu');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.language, color: Colors.orange[700]),
                            SizedBox(width: 12),
                            Text(
                              'www.heymaya.eu',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[700],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            SizedBox(width: 22),
                          ],
                        ),
                      ),
                      SizedBox(height: 22),
     //email                 
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse('mailto:maya@heymaya.eu');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.email, color: Colors.orange[700]),
                            SizedBox(width: 12),
                            Text(
                              'maya@heymaya.eu',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[700],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            SizedBox(width: 18),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: 42),
                    Text(AppLocalizations.of(context)!.sUpport),
                    SizedBox(height: 22),
 //patronite                     
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse('https://patronite.pl/heymaya');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.handshake, color: Colors.orange[700]),
                            SizedBox(width: 12),
                            Text(
                              'patronite.pl/heymaya',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[700],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            SizedBox(width: 18),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: 22),
   //suppi                   
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse('https://suppi.pl/heymaya');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.coffee, color: Colors.orange[700]),
                            SizedBox(width: 12),
                            Text(
                              'suppi.pl/heymaya',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[700],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            SizedBox(width: 18),
                          ],
                        ),
                      ),
                    
                    
                    ],
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

           
          ],
        ));
  }
}