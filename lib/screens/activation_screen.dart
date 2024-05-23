import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a
import 'dart:io';
//import '../screens/import_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/apiarys_screen.dart';
import '../models/memory.dart';
import '../helpers/db_helper.dart';

class ActivationScreen extends StatefulWidget {
  static const routeName = '/activation';

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _formKey3 = GlobalKey<FormState>();

// @override
  Future<void> wyslijKod(String kod) async {
    final http.Response response = await http.post(
      Uri.parse('https://hibees.pl/cbt_hi_kod.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "kod_mobile": kod,
        "deviceId": globals.deviceId,
        "wersja": globals.wersja,
        "jezyk": globals.jezyk,
      }),
    );
    print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'email') {
        _showAlertOK(context, AppLocalizations.of(context)!.alert,
            AppLocalizations.of(context)!.activationCodeWillBeSent);
        print('wysłano e-mail');
      } else if (odpPost['success'] == 'brak_email') {
        _showAlertOK(context, AppLocalizations.of(context)!.alert,
            AppLocalizations.of(context)!.sendAgain);
        print('wysłano e-mail ale nie zapisał się');
      } else if (odpPost['success'] == 'ok') {
        _showAlertOK(context, AppLocalizations.of(context)!.success,
            AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej z bazy www
        DBHelper.deleteTable('memory').then((_) {
          //kasowanie tabeli bo będzie nowy wpis
          Memory.insertMemory(
            odpPost['be_id'], //id
            odpPost['be_email'],
            //ponizej wtawone wartosci deviceId i wersja a apki, bo www nie zdązy ich zapisać i nie ma ich po pobraniu
            //globals.deviceId, //
            odpPost['be_dev'], //deviceId
            //globals.wersja, //
            odpPost['be_wersja'], //wersja apki
            odpPost['be_kod'], //kod
            odpPost['be_key'], //accessKey
            odpPost['be_od'], //data od
            odpPost['be_do'], // do data
            '', //globals.memJezyk, //memjezyk - język ustawiony w Ustawienia/Język apki
            '', //zapas
            '', //zapas
          );
        });
      } else {
        _showAlertOK(context, AppLocalizations.of(context)!.alert,
            AppLocalizations.of(context)!.errorWhileActivating);
        print('brak danych dla tej apki');
      }

      //Navigator.of(context).pushNamed(OrderScreen.routeName);
      //}
    } else {
      throw Exception('Failed to create OdpPost.');
    }
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
              //_setPrefers('reload',
              //    'true'); //dane nieaktualne - trzeba przeładować dane z serwera
              Navigator.of(context).pushNamedAndRemoveUntil(
                  ApiarysScreen.routeName,
                  ModalRoute.withName(ApiarysScreen
                      .routeName)); //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
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
            AppLocalizations.of(context)!.aCtivation,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
              child: Column(children: <Widget>[
            Container(
                padding: const EdgeInsets.all(20),
                child: Text(
                  (AppLocalizations.of(context)!.enterYourActivationCode),
                  style: TextStyle(
                    fontSize: 15,
                  ),
                )),
            Form(
              key: _formKey3,
              child: Container(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: TextFormField(
                    //initialValue: globals.numer,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: (AppLocalizations.of(context)!.codeOrEmail),
                      labelStyle: TextStyle(color: Colors.black),
                      //hintText: allTranslations
                      //.text('L_WPISZ_KOD_POLACZ'),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return (AppLocalizations.of(context)!.enterCodeOrEmail);
                      }
                      globals.kod = value;
                      return null;
                    }),
              ),
            ),
            //Przyciski
            Container(
              height: 90,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  //Aktywuj
                  MaterialButton(
                    shape: const StadiumBorder(),
                    onPressed: () {
                      if (_formKey3.currentState!.validate()) {
                        //jezeli formularz wypełniony poprawnie
                        _isInternet().then(
                          (inter) {
                            if (inter) {
                              wyslijKod(globals.kod);
                            } else {
                              print('braaaaaak internetu');
                              _showAlertOK(
                                  context,
                                  AppLocalizations.of(context)!.alert,
                                  AppLocalizations.of(context)!.noInternet);
                            }
                          },
                        );
                      }
                      ;
                      //Navigator.of(context).pushNamed(OrderScreen.routeName);
                    },
                    child: Text('   ' +
                        (AppLocalizations.of(context)!.activate) +
                        '   '), //AKTYWUJ===========================
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    disabledColor: Colors.grey,
                    disabledTextColor: Colors.white,
                  ),
                  // SizedBox(width: 10),
                  // //Bez aktywacji
                  // //if (mem1.isNotEmpty)
                  // MaterialButton(
                  //   shape: const StadiumBorder(),
                  //   onPressed: () {
                  //     DBHelper.updateActivate(globals.deviceId,
                  //         'bez aktywacji'); //"bez aktywacji" do memory "od"
                  //     Navigator.of(context).pushNamed(ApiarysScreen.routeName);
                  //   },
                  //   child: Text('   ' +
                  //       (AppLocalizations.of(context)!.noActivation) +
                  //       '   '), //BEZ AKTYWACJI =========================
                  //   color: Theme.of(context).primaryColor,
                  //   textColor: Colors.white,
                  //   disabledColor: Colors.grey,
                  //   disabledTextColor: Colors.white,
                  // ),
                ],
              ),
            ),

//subskrypcja wyłaczona ze wzgledu na polityke Picovoice
            //Subskrybuj
            // if (Platform.isIOS)
            //   Container(
            //     height: 90,
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: <Widget>[
            //         MaterialButton(
            //           shape: const StadiumBorder(),
            //           onPressed: () {
            //             Navigator.of(context).pushNamed(SubsScreen.routeName);
            //           },
            //           child: Text('   ' +
            //               (AppLocalizations.of(context)!.subscription) +
            //               '   '), //SUBSKRYBUJ ========================
            //           color: Theme.of(context).primaryColor,
            //           textColor: Colors.white,
            //           disabledColor: Colors.grey,
            //           disabledTextColor: Colors.white,
            //         ),
            //       ],
            //     ),
            //   ),
          ])),
        ));
  }
}
