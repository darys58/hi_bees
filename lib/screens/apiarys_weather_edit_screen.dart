import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a
//import '../globals.dart' as globals;
import 'package:intl/intl.dart';
//import '../helpers/db_helper.dart';
import '../models/weather.dart';
import '../models/weathers.dart';

class WeatherEditScreen extends StatefulWidget {
  static const routeName = '/weather_edit';

  @override
  State<WeatherEditScreen> createState() => _WeatherEditScreenState();
}

class _WeatherEditScreenState extends State<WeatherEditScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');

  String? idPasieki;
  String? miasto;
  String? latitude;
  String? longitude;
  int? units_number;
  String? lang;
  double temp = 0.0;
  String icon = ''; //tymczasowo...
  String units = 'metric';
  String stopnie = '\u2103';
  var now = new DateTime.now();
  var formatterPogoda = new DateFormat('yyyy-MM-dd HH:mm');
  List<Weather>? pogoda;
  // int? nowyZasobId;
  // double? nowyIlosc;
  // int? nowyMiara;
  // String? nowyUwagi;
  // bool edycja = false;
  // String tytulEkranu = 'Edycja zbioru';

  List<Weather> pogody = [];

  @override
  void didChangeDependencies() {
    final routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    idPasieki = routeArgs['idPasieki'].toString();

    //print('idPasieki= $idPasieki');

    // Provider.of<Weathers>(context, listen: false)
    //     .fetchAndSetWeathers()
    //     .then((_) {
    //   //uzyskanie dostępu do danych z tabeli 'pogoda'
      final pogodaData = Provider.of<Weathers>(context, listen: false);
      List<Weather> pogoda = pogodaData.items.where((ap) {
        return ap.id.contains(idPasieki.toString());
        //'numerPasieki'; // jest ==  a było contains ale dla typu String
      }).toList();
      // print(pogodaData);
      // print('nnnnnnnnnnn = ${pogoda[0].id}');
      if (pogoda.length == 0) {
        //jezeli nie ma danych dla wybranej pasieki
        //print('brak danych o lokalizacji pasieki');
        miasto = '';
        latitude = '';
        longitude = '';
        units_number = 1;
        lang = 'pl';
      } else {
        //jezeli są jakie dane dla pasieki
        miasto = pogoda[0].miasto;
        latitude = pogoda[0].latitude;
        longitude = pogoda[0].longitude;
        units_number = pogoda[0].units;
        lang = pogoda[0].lang;
        //print('${pogoda[0].id}, ${pogoda[0].miasto}, ${pogoda[0].latitude},${pogoda[0].longitude}, ${pogoda[0].pobranie},${pogoda[0].temp},${pogoda[0].units},${pogoda[0].icon}');
      }
 //   });

    // edycja = true;
    // //jezeli edycja istniejącego wpisu
    // final zbiorData = Provider.of<Harvests>(context, listen: false);
    // zbior = zbiorData.items.where((element) {
    //   //to wczytanie danych zbioru
    //   return element.id.toString().contains('$idZbioru');
    // }).toList();

    super.didChangeDependencies();
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
    //String teraz = formatterPogoda.format(now);
    // print('ikona przed zapisem w miasto');
    // print(icon);
    Weathers.insertWeather(
      idPasieki!,
      miasto!,
      latitude!,
      longitude!,
      formatterPogoda.format(now),//'0000-00-00 00:00', //pobranie
      temp.toString(), //temp
      '', // weatherId,
      icon, //icon
      units_number!,
      lang!,
      '',
   ).then((_) {
      OdswiezPogode(idPasieki!);
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
    //String teraz = formatterPogoda.format(now);
    // print('ikona przed zapisem w koo');
    // print(icon);
    Weathers.insertWeather(
      idPasieki!,
      miasto!,
      latitude!,
      longitude!,
      formatterPogoda.format(now),//'0000-00-00 00:00', //pobranie
      temp.toString(), //temp
      '', // weatherId,
      icon, //icon
      units_number!,
      lang!,
      '',
    ).then((_) {
      OdswiezPogode(idPasieki!);
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
        return ap.id.contains(idPasieki.toString());
        //'numerPasieki'; // jest ==  a było contains ale dla typu String
      }).toList();
      // setState(() {
      temp = double.parse(pogoda![0].temp);
      icon = pogoda![0].icon;
      //print('setState icon - z bazy po OdswiezPogode');
      //  });
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    //print('zaczynamy');
    
    // final pogodaData = Provider.of<Weathers>(context, listen: false);
    //   List<Weather> pogoda = pogodaData.items.where((ap) {
    //     return ap.id.contains(idPasieki.toString());
    //     //'numerPasieki'; // jest ==  a było contains ale dla typu String
    //   }).toList();
   
   
   
   
  //  //jezeli są jakieś dane dla pasieki
      switch (units_number) {
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
    
    
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(
            AppLocalizations.of(context)!.apiaryAdition,
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
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.only(
                    top: 20, left: 20, right: 20, bottom: 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Form(
                        key: _formKey1,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                 // mainAxisAlignment: MainAxisAlignment.start,
                                  //crossAxisAlignment: CrossAxisAlignment.end,
                                  child: 
                                    Text(AppLocalizations.of(context)!.locationApiary,
                                        style: TextStyle(
                                            //fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                            //maxLines: 2,
                                            softWrap: true, //zawijanie tekstu
                                            overflow: TextOverflow.fade,
                                            ),
                                  ),
// pasieka
                              Row(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 105,
                                      child: Text(
                                        AppLocalizations.of(context)!.city + ':',
                                        style: TextStyle(
                                          //fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                        softWrap: true, //zawijanie tekstu
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                          initialValue: miasto,
                                          keyboardType: TextInputType.name,
                                          decoration: InputDecoration(
                                            labelText: (''),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            hintText: 'np.: Konin',
                                          ),
                                          validator: (value) {
                                            // if (value!.isEmpty) {
                                            //   return (AppLocalizations.of(
                                            //               context)!
                                            //           .enter +
                                            //       ' ' +
                                            //       'nazwę miasta');
                                            // }
                                            miasto = value;
                                            return null;
                                          }),
                                    ),
                                  ]),
//latitude
                              Row(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 105,
                                      child: Text(
                                        AppLocalizations.of(context)!.latitude + ':',
                                        style: TextStyle(
                                          //fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                        softWrap: true, //zawijanie tekstu
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                          initialValue: latitude,
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText: (''),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            hintText: 'np.: 52.25314',
                                          ),
                                          validator: (value) {
                                            // if (value!.isEmpty) {
                                            //   return (AppLocalizations.of(
                                            //               context)!
                                            //           .enter +
                                            //       ' ' +
                                            //       'szerokość');
                                            // }
                                            latitude = value;
                                            return null;
                                          }),
                                    ),
                                  ]),

//longitude
                              Row(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 105,
                                      child: Text(
                                        AppLocalizations.of(context)!.longitude + ':',
                                        style: TextStyle(
                                          //fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                        softWrap: true, //zawijanie tekstu
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                          initialValue: longitude,
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText: (''),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            hintText: 'np.:18.1976522',
                                          ),
                                          validator: (value) {
                                            // if (value!.isEmpty) {
                                            //   return (AppLocalizations.of(
                                            //               context)!
                                            //           .enter +
                                            //       ' ' +
                                            //       'długość');
                                            // }
                                            longitude = value;
                                            return null;
                                          }),
                                    ),
                                  ]),

//jednostka
                              SizedBox(height: 20),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 105,
                                      child: Text(
                                        AppLocalizations.of(context)!.temperatureUnit + ':',
                                        style: TextStyle(
                                          //fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                        softWrap: true, //zawijanie tekstu
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    DropdownButton(
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black54,
                                      ),
                                      value: units_number, //
                                      items: [
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .celsius),
                                            value: 1),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .kelvin),
                                            value: 2),
                                        DropdownMenuItem(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .fahrenheit),
                                            value: 3),
                                      ], //lista elementów do wyboru
                                      onChanged: (newValue) {
                                        //wybrana nowa wartość - nazwa dodatku
                                        setState(() {
                                          units_number =
                                              newValue!; 
                                        });
                                      }, //onChangeDropdownItemWar1,
                                    ),
                                  ]),

//uwagi

                              // Row(
                              //     mainAxisAlignment: MainAxisAlignment.start,
                              //     crossAxisAlignment: CrossAxisAlignment.end,
                              //     children: <Widget>[
                              //       SizedBox(
                              //         width: 270,
                              //         child: TextFormField(
                              //             minLines: 1,
                              //             maxLines: 5,
                              //             initialValue: nowyUwagi,
                              //             keyboardType: TextInputType.text,
                              //             decoration: InputDecoration(
                              //               labelText:
                              //                   (AppLocalizations.of(context)!
                              //                       .cOmments),
                              //               labelStyle:
                              //                   TextStyle(color: Colors.black),
                              //               hintText:
                              //                   (AppLocalizations.of(context)!
                              //                       .comments),
                              //             ),
                              //             validator: (value) {
                              //               // if (value!.isEmpty) {
                              //               //   return ('uwagi');
                              //               // }
                              //               nowyUwagi = value;
                              //               return null;
                              //             }),
                              //       ),
                              //     ]),
                            ]),
                      ),
                      SizedBox(
                        height: 30,
                      ),

//przyciski
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            //zmień
                            MaterialButton(
                              height: 50,
                              shape: const StadiumBorder(),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                  //print('$idPasieki,$miasto,$latitude,$longitude,$units,$lang');
                                  
                                  //poniewaz wciśnięto zapis to aktualizacja z www
                                  _isInternet().then(
                                    (inter) {
                                      if (inter) {
                                        // print('$inter - jest internet');
                                        //print('pobranie danych o pogodzie');
                                        if (latitude != '' && longitude != '') {
                                          getCurrentWeatherCoord(idPasieki.toString(),
                                              latitude!, longitude!);
                                        } else if (miasto != '') {
                                          getCurrentWeather(idPasieki.toString(), miasto!);
                                        }
                                        //print('ikona po pobraniu');
                                       // print(icon);
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
                                        Navigator.of(context).pop();
                                      }
                                    },
                                  );
                                  
                                  
                                  
                                  
                                  // Weathers.insertWeather(
                                  //   idPasieki!,
                                  //   miasto!,
                                  //   latitude!,
                                  //   longitude!,
                                  //   formatterPogoda.format(now),//'0000-00-00 00:00', //pobranie
                                  //   temp.toString(), //temp
                                  //   '', // weatherId,
                                  //   icon, //icon
                                  //   units_number!,
                                  //   lang!,
                                  //   '',
                                  // );
                                  // Provider.of<Weathers>(context, listen: false)
                                  //     .fetchAndSetWeathers()
                                  //     .then((_) {
                                  //   Navigator.of(context).pop();
                                  // });
                                
                                
                                };
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!.saveZ) +
                                  '   '), //Modyfikuj
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.white,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),
                          ]),
                    ]))));
  }
}
