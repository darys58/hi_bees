//import 'dart:ffi';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
//import 'package:in_app_purchase/in_app_purchase.dart'; //subskrypcja

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a

import '../models/apiarys.dart';
import '../widgets/apiarys_item.dart';
import '../screens/voice_screen.dart';
import '../screens/subscription_screen.dart';
import '../models/memory.dart';

import '../helpers/db_helper.dart';

//ekran startowy
class ApiarysScreen extends StatefulWidget {
  const ApiarysScreen({super.key});
  static const routeName = '/screen-apiarys'; //nazwa trasy do tego ekranu
  @override
  State<ApiarysScreen> createState() => _ApiarysScreenState();
}

class _ApiarysScreenState extends State<ApiarysScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  final _formKey2 = GlobalKey<FormState>();
//final wersja = ['1','0','0','2','22.05.2020','nic']; //major, minor - wersja(zmiana w bazie), kolejna wersja bo wymaga tego iOS, numer wydania
  //1.0.1.1 30.03.2023 - start
  //1.0.1.4 13.04.2023 - subskrypcja przetestowana w sandboxie w AppStoreConnect 79,99 zł
  final wersja = '1.0.1.4'; //wersja aplikacji
  final dataWersji = '2023-04-13';
  final now = DateTime.now();
  int aktywnosc = 0;

  @override
  void didChangeDependencies() {
    print('apiarys_screen - didChangeDependencies');

    print('apiarys_screen - _isInit = $_isInit');
    if (_isInit) {
      setState(() {
        _isLoading = true; //uruchomienie wskaznika ładowania danych
        // _getId(); //pobranie Id telefonu i zapisanie w globals.deviceId - do identyfikacji uzytkownika apki
      });
      //DBHelper.deleteBase().then((_) {
      _getId().then((_) {
        //pobranie Id telefonu i zapisanie w globals.deviceId - do identyfikacji uzytkownika apki
        //pobranie z bazy lokalnej Memory dla tego smartfona
        print('globals.deviceId = ${globals.deviceId}');
        Provider.of<Memory>(context, listen: false)
            .fetchAndSetMemory(globals.deviceId)
            .then((_) {
          //uzyskanie dostępu do danych
          final memData = Provider.of<Memory>(context, listen: false);
          final mem = memData.items;
          //czy jest wpis w bazie dla tego deviceId? - (wpis moze być ale accessKey niekoniecznie!!!)
          if (mem.isNotEmpty &&
              mem[0].dod != 'bez aktywacji' &&
              mem[0].dod != '') {
            //jezeli jest i data "od" ma normalny format
            globals.key = mem[0].key; //pobranie klucza
            print('1111111111 w init globals.key = ${globals.key}');
            //sprawdzenie daty do której apka jest aktywna
            final data = DateTime.parse(mem[0].ddo);
            print('data do = ${mem[0].ddo}');
            aktywnosc = daysBetween(now, data); //ile dni wazności apki
            print('aktywnisc = $data - $now = $aktywnosc ');
            if (aktywnosc < 30 && aktywnosc >= 0 ) {
              print('2222222222222 aktywnosc < 30');
              _showAlert(
                  context, 'Alert', 'Subscription ends in $aktywnosc days.');
              //pobranie wszystkich pasiek z tabeli pasieki z bazy lokalnej
              Provider.of<Apiarys>(context, listen: false)
                  .fetchAndSetApiarys()
                  .then((_) {
                setState(() {
                  _isLoading = false; //zatrzymanie wskaznika ładowania dań
                });
              });
            } else if (aktywnosc <= -1) {
              //*** Wygasła subskrypcja
              //wymuszenie trybu "bez aktywacji"
              print('333333333333 aktywnosc < -1');

              DBHelper.updateActivate(globals.deviceId, 'bez aktywacji')
                  .then((_) {
                print(
                    'w bez i \'\' aktywność < -1 globals.key = ${globals.key}');
                print('w bez i \'\' aktywność < -1 memory.dod: ${mem[0].dod}');
                //pobranie wszystkich pasiek z tabeli pasieki z bazy lokalnej
                Provider.of<Apiarys>(context, listen: false)
                    .fetchAndSetApiarys()
                    .then((_) {
                  setState(() {
                    _isLoading = false; //zatrzymanie wskaznika ładowania dań
                  });
                });
              });
            } else {
              //*** Jest aktywna subskrypcja
              print('44444444444 aktywnoscok');
              //pobranie wszystkich pasiek z tabeli pasieki z bazy lokalnej
              Provider.of<Apiarys>(context, listen: false)
                  .fetchAndSetApiarys()
                  .then((_) {
                setState(() {
                  _isLoading = false; //zatrzymanie wskaznika ładowania dań
                });
              });
              print('Apka aktywna');
            }

            //jezeli uzytkownik wybrał "bez aktywacji" ma dostęp ale bez "voice control"
          } else if (mem.isNotEmpty && mem[0].dod == 'bez aktywacji') {
            globals.key = mem[0].dod;
            print('w bez aktywności globals.key = ${globals.key}');
            print('w bez aktywności memory.dod: ${mem[0].dod}');
            //pobranie wszystkich pasiek z tabeli pasieki z bazy lokalnej
            Provider.of<Apiarys>(context, listen: false)
                .fetchAndSetApiarys()
                .then((_) {
              setState(() {
                _isLoading = false; //zatrzymanie wskaznika ładowania dań
              });
            });
            final data = DateTime.parse(mem[0].ddo);
            aktywnosc = daysBetween(now, data); //ile dni wazności apki
            print('aktywnisc = $data - $now = $aktywnosc ');

            _showAlert(
                context, 'Alert', 'Subscription ends in $aktywnosc days.');
          } else {
            //jezeli uzytkownik chce aktywować bo wybrał "Aktywuj"
            if (mem.isNotEmpty)
              globals.key = mem[0].dod;
            else
              globals.key = '';
            //jezeli nie ma accessKey
            print('nie ma assessKey');
            print('w else globals.key = ${globals.key}');
            //print('w else memory.dod: ${mem[0].dod}');
          }
          setState(() {
            _isLoading = false; //zatrzymanie wskaznika ładowania danych
          });
          //    });
        });
      });
    }
    _isInit = false;
    // globals.isInit = false;
    super.didChangeDependencies();
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

  //obliczanie róznicy miedzy dwoma datami
  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  //pobieranie Id telefonu  - do identyfikacji apki jako uzytkownika
  Future<void> _getId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      globals.deviceId = 'ios_' +
          iosDeviceInfo
              .identifierForVendor!; // + '_' + iosDeviceInfo.model; // +'_' + wersja[0] + wersja[1] + wersja[2] + wersja[3]; // + '_' + iosDeviceInfo.model
      //return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      globals.deviceId = 'and_' +
          androidDeviceInfo.androidId!; // + '_' + androidDeviceInfo.model;
      //wersja[0] + wersja[1] + wersja[2] + wersja[3]; //androidDeviceInfo.model
      //return androidDeviceInfo.androidId; // unique ID on Android
    }
  }

  //wysyłanie kodu połączenia apki z kontem na cobytu.com
  Future<void> wyslijKod(
    String kod,
  ) async {
    final http.Response response = await http.post(
      Uri.parse('https://hibees.pl/cbt_hi_kod.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "kod_mobile": kod,
        "deviceId": globals.deviceId,
        "wersja": wersja,
      }),
    );
    print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'email') {
        _showAlertOK(context, 'Alert',
            'Thank you for submitting your email address. An activation code for the application will be sent to the address provided.');
        print('wysłano e-mail');
      } else if (odpPost['success'] == 'brak_email') {
        _showAlertOK(context, 'Alert',
            'An error occurred while sending. Send it again.');
        print('wysłano e-mail ale nie zapisał się');
      } else if (odpPost['success'] == 'ok') {
        _showAlertOK(context, 'Success',
            'The application will be active until ' + odpPost['be_do']);
        //zapis do bazy lokalnej z bazy www
        DBHelper.deleteTable('memory').then((_) {
          //kasowanie tabeli bo będzie nowy wpis
          Memory.insertMemory(
            odpPost['be_id'], //id
            odpPost['be_email'],
            //ponizej wtawone wartosci deviceId i wersja a apki, bo www nie zdązy ich zapisać i nie ma ich po pobraniu
            globals.deviceId, //odpPost['be_dev'], //deviceId
            wersja, //odpPost['be_wersja'], //wersja apki
            odpPost['be_kod'], //kod
            odpPost['be_key'], //accessKey
            odpPost['be_od'], //data od
            odpPost['be_do'], // do data
          );
        });
      } else {
        _showAlertOK(
            context, 'Alert', 'Error while activating the application.');
        print('brak danych dla tej apki');
      }

      //Navigator.of(context).pushNamed(OrderScreen.routeName);
      //}
    } else {
      throw Exception('Failed to create OdpPost.');
    }
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
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              DBHelper.updateActivate(globals.deviceId, '').then((_) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    ApiarysScreen.routeName,
                    ModalRoute.withName(ApiarysScreen
                        .routeName)); //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
              }); //'' do memory "od" - kasowanie
            },
            child: Text('Activate'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
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

  // void selectApiary(BuildContext ctx) {
  //   Navigator.of(ctx).pushNamed(HivesScreen.routeName,arguments: {'id': _pasieki[0].pasiekaNr,'title': pasiekaNazwa[0], 'color':color[0] },);
  //    //(MaterialPageRoute(builder: (_){return FramesScreen();},),);
  //}

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 233, 140, 0),
        //shape: CircleBorder(),
        textStyle: const TextStyle(color: Colors.white));

    final apiarysData = Provider.of<Apiarys>(context);
    final apiarys = apiarysData.items; //showFavs ? productsData.favoriteItems :
    //getApiarys().then((_) {
    print('start_screen - drugie pobranie liczby pasiek');
    print(apiarys.length);
    // });
    for (var i = 0; i < apiarys.length; i++) {
      print(
          '${apiarys[i].id},${apiarys[i].pasiekaNr},${apiarys[i].ileUli},${apiarys[i].przeglad},${apiarys[i].ikona},${apiarys[i].opis}');
      print('^^^^^');
    }
    final memData1 = Provider.of<Memory>(context, listen: false);
    final mem1 = memData1.items;

    print(' w ciele globals.key = ${globals.key}');
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        title: const Text(
          'Hi Bees',
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        backgroundColor: Color.fromARGB(
            255, 255, 255, 255), //Color.fromARGB(255, 233, 140, 0),
      ),

      body: _isLoading //jezeli dane są ładowane
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.black)), //kółko ładowania danych
            )
          : globals.key == '' //jezeli nie ma accessKey to trzeba wysłać kod
              ? Center(
                  child: Column(children: <Widget>[
                    Container(
                        padding: const EdgeInsets.all(20),
                        child: mem1.isEmpty
                            ? Text(
                                ('Enter your activation code. If you do not have an activation code, enter your e-mail address to receive free activation for 6 months.\nMore information at hibees.pl'),
                                style: TextStyle(
                                  fontSize: 15,
                                  //color: Colors.grey,
                                ),
                              )
                            : Text(
                                ('Enter your activation code. If you do not have an activation code, enter your e-mail address to receive an activation code after paying for the subscription. You can also use the application without activation but without Voice Control.\nMore information at hibees.pl'),
                                style: TextStyle(
                                  fontSize: 15,
                                  //color: Colors.grey,
                                ),
                              )),
                    Form(
                      key: _formKey2,
                      child: Container(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        child: TextFormField(
                            //initialValue: globals.numer,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: ('Code or e-mail'),
                              labelStyle: TextStyle(color: Colors.black),
                              //hintText: allTranslations
                              //.text('L_WPISZ_KOD_POLACZ'),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return ('Enter code or e-mail');
                              }
                              globals.kod = value;
                              return null;
                            }),
                      ),
                    ),
                    Container(
                      height: 90,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          MaterialButton(
                            shape: const StadiumBorder(),
                            onPressed: () {
                              if (_formKey2.currentState!.validate()) {
                                //jezeli formularz wypełniony poprawnie
                                _isInternet().then(
                                  (inter) {
                                    if (inter) {
                                      wyslijKod(globals.kod);
                                    } else {
                                      print('braaaaaak internetu');
                                      _showAlertOK(context, 'Alert',
                                          'No internet connection.');
                                    }
                                  },
                                );
                              }
                              ;
                              //Navigator.of(context).pushNamed(OrderScreen.routeName);
                            },
                            child: Text('   ' + ('Activate') + '   '),
                            color: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                            disabledColor: Colors.grey,
                            disabledTextColor: Colors.white,
                          ),
                          SizedBox(width: 10),
                          if (mem1.isNotEmpty)
                            MaterialButton(
                              shape: const StadiumBorder(),
                              onPressed: () {
                                DBHelper.updateActivate(globals.deviceId,
                                    'bez aktywacji'); //"bez aktywacji" do memory "od"
                                Navigator.of(context)
                                    .pushNamed(ApiarysScreen.routeName);
                              },
                              child: Text('   ' + ('No activation') + '   '),
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.white,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),
                        ],
                      ),
                    ),
                    if (aktywnosc < 30 && aktywnosc >= 0 ) 
                      Container(
                        height: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            MaterialButton(
                              shape: const StadiumBorder(),
                              onPressed: () {
                                // DBHelper.updateActivate(globals.deviceId,
                                //     'bez aktywacji'); //"bez aktywacji" do memory "od"
                                Navigator.of(context)
                                    .pushNamed(SubsScreen.routeName);
                              },
                              child: Text('   ' + ('Subscription') + '   '),
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.white,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),
                        ],
                      ),
                      )
                    ,


                  ]),
                )

              //jezeli jest accessKey
              : apiarys.length == 0
                  ? Center(
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.only(top: 50),
                            child: const Text(
                              'There are no apiaries yet.',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(25.0),
                      itemCount: apiarys.length,
                      itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                        value: apiarys[i],
                        child: ApiarysItem(),
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 7 / 6,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                    ),
      //=== stopka
      bottomSheet: globals.key == ''
          ? null
          : Container(
              //margin:  EdgeInsets.only(bottom:15),
              height: 100,
              color: Colors.white,
              //width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const SizedBox(
                        width: 9,
                      ),
                      SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            style: buttonStyle,
                            onPressed: () {
                              globals.key == '' //jezeli brak accessKey
                                  ? null
                                  : {
                                      _isInit = true,
                                      Navigator.of(context).pushNamed(
                                        VoiceScreen.routeName,
                                      ),
                                    };
                            },
                            child: Text("VOICE CONTROL",
                                style: TextStyle(fontSize: 14)),
                          )),
                      const SizedBox(
                        width: 15,
                      ), //interpolacja ciągu znaków
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
