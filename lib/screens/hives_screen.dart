import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import 'package:hi_bees/screens/apiarys_weather_edit_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:provider/provider.dart';
import '../helpers/db_helper.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a
import '../globals.dart' as globals;
import '../models/hives.dart';
import '../models/weather.dart';
import '../models/weathers.dart';
import '../widgets/hives_item.dart';
import '../models/apiarys.dart';
import '../screens/apiarys_weather_edit_screen.dart';
import '../screens/apiary_weather_5Days.dart';

class HivesScreen extends StatefulWidget {
  static const routeName = '/screen-hives';

  @override
  State<HivesScreen> createState() => _HivesScreenState();
}

class _HivesScreenState extends State<HivesScreen> {
  bool _isInit = true;
  String numerPasieki = '';
  //String pobranie = '';
  double temp = 0.0;
  String icon = ''; //tymczasowo...
  String units = 'metric';
  String stopnie = '\u2103';
  var now = new DateTime.now();
  var formatterPogoda = new DateFormat('yyyy-MM-dd HH:mm');
  List<Weather>? pogoda;

  @override
  void didChangeDependencies() {
    //print('hives_screen - didChangeDependencies');

    //_isInit = globals.isInit;
    //print('hives_screen - _isInit = $_isInit');
    if (_isInit) {
      //pobranie danych o pogodzie dla pasieki
      //  Provider.of<Weathers>(context, listen: false)
      //   .fetchAndSetWeathers();
      //.then((_) {});
      Provider.of<Hives>(context, listen: false)
          .fetchAndSetHives(globals.pasiekaID)
          .then((_) {
        //wszystkie ule z tabeli ule z bazy lokalnej

        // setState(() {
        //   // _isLoading = false; //zatrzymanie wskaznika ładowania dań
        // });
      });

      //dostawca
      // setState(() {
      //   // _isLoading = false; //zatrzymanie wskaznika ładowania dań
      //     });
      //  });
    }
    //  Provider.of<Weathers>(context, listen: false)
    //   .fetchAndSetWeathers();
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

  //pobranie pogody z www dla miasta i aktualizacja wpisu w bazie
  Future<bool>? getCurrentWeather(String nrPasieki, String location) async {
    var endpoint = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=$location&appid=3943495c9983f5f94616a38aa17fcb4d&units=$units"); //https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=-2.15&appid={API key}")
    var response = await http.get(endpoint);
    var body = jsonDecode(response.body);
    // print('dane o pogodzie z miasta -----------------------');
    // print(body);
    temp = body["main"]["temp"];
    icon = body["weather"][0]["icon"];
    //print('$temp, $icon');
    String teraz = formatterPogoda.format(now);
    // print('ikona przed zapisem w miasto');
    // print(icon);
    DBHelper.updatePogoda(nrPasieki, teraz, temp, icon).then((_) {
      OdswiezPogode(numerPasieki);
    });
    return true;
  }

  //pobranie pogody z www dla koordynatów i aktualizacja wpisu w bazie
  Future<bool>? getCurrentWeatherCoord(
      String nrPasieki, String lati, String longi) async {
    var endpoint = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$lati&lon=$longi&appid=3943495c9983f5f94616a38aa17fcb4d&units=$units"); //https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=-2.15&appid={API key}")
    var response = await http.get(endpoint);
    var body = jsonDecode(response.body);
    // print('dane o pogodzie z koordynatów -----------------------');
    // print(body);
    temp = body["main"]["temp"];
    icon = body["weather"][0]["icon"];
    //print('$temp, $icon');
    String teraz = formatterPogoda.format(now);
    // print('ikona przed zapisem w koo');
    // print(icon);
    DBHelper.updatePogoda(nrPasieki, teraz, temp, icon).then((_) {
      OdswiezPogode(numerPasieki);
    }); //
    return true;
  }

  OdswiezPogode(String nrPasieki) {
    //pobranie danych o pogodzie dla pasieki
    Provider.of<Weathers>(context, listen: false)
        .fetchAndSetWeathers()
        .then((_) {
      final pogodaData = Provider.of<Weathers>(context, listen: false);
      pogoda = pogodaData.items.where((ap) {
        return ap.id.contains(numerPasieki.toString());
        //'numerPasieki'; // jest ==  a było contains ale dla typu String
      }).toList();
      // setState(() {
      temp = double.parse(pogoda![0].temp);
      icon = pogoda![0].icon;
      //print('setState icon - z bazy po OdswiezPogode');
      //  });
    });
  }

  @override
  Widget build(BuildContext context) {
    final routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    final numerPasieki = routeArgs['numerPasieki'];
    //  final startBoxTitle = routeArgs['title'];
    //  final startBoxColor = routeArgs['color'];

    final hivesData = Provider.of<Hives>(context);
    final hives = hivesData.items; //showFavs ? productsData.favoriteItems :
    // print('hives_screen - ilość uli =');
    // print(hives.length);
    
    //ustawienie ikony dla pasieki na podstawie ikon ulowych
    globals.ikonaPasieki = 'green';
    for (var i = 0; i < hives.length; i++) {
      switch (hives[i].ikona){
        case 'red': globals.ikonaPasieki = 'red';
        break;
        case 'orange': if(globals.ikonaPasieki == 'yellow' || globals.ikonaPasieki == 'green') globals.ikonaPasieki = 'orange';
        break;
        case 'yellow': if(globals.ikonaPasieki == 'green') globals.ikonaPasieki = 'yellow';
        break;
      }
    }
    
    //aktualizacja ikony pasieki
    DBHelper.updateIkonaPasieki(int.parse(numerPasieki.toString()), globals.ikonaPasieki ); 
    //aktualizacja pasieki  - pobranie danych z bazy
    Provider.of<Apiarys>(context, listen: false).fetchAndSetApiarys();


    final pogodaData = Provider.of<Weathers>(context, listen: false);
    pogoda = pogodaData.items.where((ap) {
      return ap.id.contains(numerPasieki.toString());
      //'numerPasieki'; // jest ==  a było contains ale dla typu String
    }).toList();
    if (pogoda!.length == 0) {
      //jezeli nie ma danych dla wybranej pasieki - wpisz Konin (było: nie rób nic)
       Weathers.insertWeather(
        globals.pasiekaID.toString(),
        'Konin',
        '',
        '',
        '0000-00-00 00:00', //pobranie
        '', //temp
        '', // weatherId,
        '', //icon
        1,
        'pl',
        '',
      );
      print('brak danych o lokalizacji pasieki więc wpisujemy Konin');
    } else {
      print('dane o pogodzie pobrane z bazy lolalnej!!!!!!!!!!!!!!!!');
      //pobranie danych z bazy lokalnej na wypadek gdyby nie było internetu lub dane byłyby świeze
      pogoda![0].temp != '' ? temp = double.parse(pogoda![0].temp) : temp = 500; //500 - fikcyjna temp zeby jej nie wyswietlać
      pogoda![0].icon != '' ? icon = pogoda![0].icon : icon = '';
      print(
          '=================${pogoda![0].id},${pogoda![0].miasto},${pogoda![0].pobranie},${pogoda![0].temp},${pogoda![0].icon},${pogoda![0].miasto},');

      //jezeli są jakieś dane dla pasieki
      switch (pogoda![0].units) {
        case 1:
          units = 'metric';
          stopnie = "\u2103";
          break;
        case 2:
          units = 'standard';
          stopnie = "\u212A";
          break;
        case 3:
          units = 'imperial';
          stopnie = "\u2109";
          break;
        default:
          units = 'metric';
          stopnie = "\u2103";
      }
      var now = DateTime.now();
      // print('data now =');
      // print('=$now=');
      // print('data pobrana z bazy = ');
      // print('=${pogoda![0].pobranie}=');
      final data = DateTime.parse(pogoda![0].pobranie);
      final difference = now.difference(data);
      // print('difference');
      // print(difference.inMinutes);
      //jezeli powyzej 30 minut od ostatniego pobrania pogody
      if (difference.inMinutes > 15) {
        //print('wejście do ifa difference');
        //to aktualizacja z www
        _isInternet().then(
          (inter) {
            if (inter) {
              // print('$inter - jest internet');
              print('pobranie danych o pogodzie');
              if (pogoda![0].latitude != '' && pogoda![0].longitude != '') {
                getCurrentWeatherCoord(numerPasieki.toString(),
                    pogoda![0].latitude, pogoda![0].longitude);
              } else if (pogoda![0].miasto != '') {
                getCurrentWeather(numerPasieki.toString(), pogoda![0].miasto);
              }
              print('ikona po pobraniu');
              print(icon);
            } else {
              // print('braaaaaak internetu');
               //komunikat na dole ekranu
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.pogodaNieaktualna),
                ),
              );
              //dane o pogodzie nie będą aktualizowane a pobrane z bazy
              // setState(() {
              //   temp = double.parse(pogoda![0].temp);
              //   icon = pogoda![0].icon;
              //print('setState icon - z bazy bo nie ma internetu - else1');
              // });
            }
          },
        );
      } else {
        //to pobranie z bazy lokalnej
        // setState(() {
        //   temp = double.parse(pogoda![0].temp);
        //   icon = pogoda![0].icon;
       // print('setState icon - z bazy bo świeze dane - else2');
        // });
        //print('ikona w else2');
        //print(icon);
      }
      //print('${pogoda[0].id}, ${pogoda[0].miasto}, ${pogoda[0].latitude}');
    }
    print('ikona przed Scaffold');
    print(icon);

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            AppLocalizations.of(context)!.aPiary + " $numerPasieki",
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          //   title: Text('Apiary $numerPasieki'),
          //   backgroundColor: Color.fromARGB(255, 233, 140, 0),
          actions: <Widget>[
            if (icon != '')
              IconButton(
                icon: Image.network(
                  //     //obrazek pogody pobierany z neta
                  'https://openweathermap.org/img/wn/$icon.png', //adres internetowy
                  height: 50, //wysokość obrazka
                  //     //width: 140,
                  fit: BoxFit.cover, //dopasowanie do pojemnika
                ),
                onPressed: () => Navigator.of(context).pushNamed(Weather5DaysScreen.routeName),
              ),
            if(temp != 500) //bo była np zmiana lokalizacji
            Center(
                child: Text('${temp.toStringAsFixed(0)}$stopnie',
                    style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)))),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => Navigator.of(context)
                  .pushNamed(WeatherEditScreen.routeName, arguments: {
                'idPasieki': globals.pasiekaID,
              }),
            )
          ],
        ),
        body: hives.length == 0
            ? Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 50),
                      child: Text(
                        AppLocalizations.of(context)!.thereAreNoHives,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            :
            //kafelki
            // GridView.builder(
            //   padding: const EdgeInsets.all(10.0),
            //   itemCount: hives.length,
            //   itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
            //     value: hives[i],
            //     child: HivesItem(),
            //   ),
            //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //     crossAxisCount: 3,
            //     childAspectRatio: 6/ 8,
            //     crossAxisSpacing: 10,
            //     mainAxisSpacing: 10,
            //   ),
            // ),

            //lista
            Column(children: <Widget>[
                // Image.network(
                //   //     //obrazek pogody pobierany z neta
                //   'https://openweathermap.org/img/wn/$icon.png', //adres internetowy
                //   height: 50, //wysokość obrazka
                //   //     //width: 140,
                //   fit: BoxFit.cover, //dopasowanie do pojemnika
                // ),
                Expanded(
                  child: ListView.builder(
                    itemCount: hives.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: hives[i],
                      child: HivesItem(),
                    ),
                  ),
                )
              ]));
  }
}
