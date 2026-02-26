
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import 'package:intl/date_symbol_data_local.dart'; //do formatowania daty - dzień tygodnia
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a
import '../globals.dart' as globals;
import 'package:intl/intl.dart';
//import '../helpers/db_helper.dart';
import '../models/weather.dart';
import '../models/weathers.dart';

class Weather5DaysScreen extends StatefulWidget {
  static const routeName = '/weather_5days';

  @override
  State<Weather5DaysScreen> createState() => _Weather5DaysScreenState();
}

class _Weather5DaysScreenState extends State<Weather5DaysScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  String? idPasieki;
  String miasto = 'Konin';
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
  var body;
  // int? nowyZasobId;
  // double? nowyIlosc;
  // int? nowyMiara;
  // String? nowyUwagi;
  // bool edycja = false;
  // String tytulEkranu = 'Edycja zbioru';

  //List<Weather> pogody = [];

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true; //uruchomienie wskaznika ładowania danych
      });
      final pogodaData = Provider.of<Weathers>(context, listen: false);
      List<Weather> pogoda = pogodaData.items.where((ap) {
        return ap.id == (globals.pasiekaID.toString());
        //'numerPasieki'; // jest ==  a było contains ale dla typu String
      }).toList();
      // print('pasieka = ${globals.pasiekaID}');
      // print(pogodaData);
      // print('nnnnnnnnnnn = ${pogoda}');
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
      
      //jezeli są jakieś dane dla pasieki
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
      
      
      _isInternet().then(
        (inter) {
          if (inter) {
            // print('$inter - jest internet');
            //print('pobranie danych o pogodzie');
            if (latitude != '' && longitude != '') {
              getCurrentWeatherCoord(idPasieki.toString(), latitude!, longitude!)?.then((_) {
                setState(() {
                  _isLoading = false; //zatrzymanie wskaznika ładowania danych
                });
              });
            } else if (miasto != '') {
              getCurrentWeather(idPasieki.toString(), miasto)?.then((_) {
                 setState(() {
                  _isLoading = false; //zatrzymanie wskaznika ładowania danych
                });
              });
            }
            //print('ikona po pobraniu');
            //print(icon);
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
      // setState(() {
      //   _isLoading = false; //zatrzymanie wskaznika ładowania danych
      // });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  ///sprawdzenie czy jest internet
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
      "https://api.openweathermap.org/data/2.5/forecast?q=$location&appid=3943495c9983f5f94616a38aa17fcb4d&units=$units");
     //"https://api.openweathermap.org/data/2.5/weather?q=$location&appid=3943495c9983f5f94616a38aa17fcb4d&units=$units"); //https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=-2.15&appid={API key}")
    var response = await http.get(endpoint);
     body = jsonDecode(response.body);
    //  print('dane o pogodzie z miasta -----------------------');
    //  print(body);
    temp = body["list"][5]["main"]["temp"];
    icon = body["list"][5]["weather"][0]["icon"];
    //print('$temp, $icon');
    //String teraz = formatterPogoda.format(now);
     //print('ikona przed zapisem w miasto');
     //print(icon);
  //   Weathers.insertWeather(
  //     idPasieki!,
  //     miasto!,
  //     latitude!,
  //     longitude!,
  //     formatterPogoda.format(now),//'0000-00-00 00:00', //pobranie
  //     temp.toString(), //temp
  //     '', // weatherId,
  //     icon, //icon
  //     units_number!,
  //     lang!,
  //     '',
  //  ).then((_) {
  //     OdswiezPogode(idPasieki!);
  //   });
    return true;
  }

  //pobranie pogody z www dla koordynatów (prognoza 5 dni)
  Future<bool>? getCurrentWeatherCoord(
      String nrPasieki, String lati, String longi) async {
    var endpoint = Uri.parse(
        "https://api.openweathermap.org/data/2.5/forecast?lat=$lati&lon=$longi&appid=3943495c9983f5f94616a38aa17fcb4d&units=$units");
    var response = await http.get(endpoint);
    body = jsonDecode(response.body);
    // print('dane o pogodzie z koordynatów -----------------------');
    // print(body);
    temp = body["list"][5]["main"]["temp"];
    icon = body["list"][5]["weather"][0]["icon"];
    return true;
  }

  // OdswiezPogode(String nrPasieki) {
  //   //pobranie danych o pogodzie dla pasieki
  //   Provider.of<Weathers>(context, listen: false)
  //       .fetchAndSetWeathers()
  //       .then((_) {
  //     final pogodaData = Provider.of<Weathers>(context, listen: false);
  //     pogoda = pogodaData.items.where((ap) {
  //       return ap.id == (idPasieki.toString());
  //       //'numerPasieki'; // jest ==  a było contains ale dla typu String
  //     }).toList();
  //     // setState(() {
  //     temp = double.parse(pogoda![0].temp);
  //     icon = pogoda![0].icon;
  //     //print('setState icon - z bazy po OdswiezPogode');
  //     //  });
  //     Navigator.of(context).pop();
  //   });
  // }

  String zmienDate(String data) {
    String rok = data.substring(0, 4);
    String miesiac = data.substring(5, 7);
    String dzien = data.substring(8);
    if (globals.isEuropeanFormat())
      return '$dzien.$miesiac.$rok';
    else
      return '$rok-$miesiac-$dzien';
  }
 
 
 
  @override
  Widget build(BuildContext context) {
    //print('zaczynamy');
    //initializeDateFormatting('pl_PL', null);
    // final pogodaData = Provider.of<Weathers>(context, listen: false);
    //   List<Weather> pogoda = pogodaData.items.where((ap) {
    //     return ap.id.contains(idPasieki.toString());
    //     //'numerPasieki'; // jest ==  a było contains ale dla typu String
    //   }).toList();
   
   
   
   
  // //  //jezeli są jakieś dane dla pasieki
  //     switch (units_number) {
  //       case 1:
  //         units = 'metric';
  //         stopnie = "\u2103";
  //         break;
  //       case 2:
  //         units = 'standard';
  //         stopnie = "\u212A";
  //         break;
  //       case 3:
  //         units = 'imperial';
  //         stopnie = "\u2109";
  //         break;
  //       default:
  //         units = 'metric';
  //         stopnie = "\u2103";
  //     }
    
    
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: 
            miasto != '' 
              ? Text(
                  AppLocalizations.of(context)!.wEatherForecast + ' - $miasto',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                )
              : Text(
                  AppLocalizations.of(context)!.wEatherForecast,
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
        body: _isLoading //jezeli dane są ładowane
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.black)), //kółko ładowania danych
            )
          : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[                  
//=== 0                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
//dzień - data
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][0]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][0]["dt_txt"].substring(0, 10))
                      ),                     
                  ]),
                  Divider(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][0]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][0]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][0]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][0]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][0]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 1              
                if(body["list"][1]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][1]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][1]["dt_txt"].substring(0, 10))),                     
                  ]), 
                  if(body["list"][1]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10),      
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][1]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][1]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][1]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][1]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][1]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 2              
                if(body["list"][2]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][2]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][2]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][2]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][2]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][2]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][2]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][2]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][2]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 3              
                if(body["list"][3]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][3]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][3]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][3]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][3]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][3]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][3]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][3]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][3]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 4              
                if(body["list"][4]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][4]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][4]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][4]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][4]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][4]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][4]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][4]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][4]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),               
//=== 5              
                if(body["list"][5]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][5]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][5]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][5]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][5]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][5]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][5]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][5]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][5]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 6              
                if(body["list"][6]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][6]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][6]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][6]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][6]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][6]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][6]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][6]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][6]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 7              
                if(body["list"][7]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][7]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][7]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][7]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][7]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][7]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][7]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][7]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][7]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 8              
                if(body["list"][8]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][8]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][8]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][8]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][8]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][8]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][8]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][8]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][8]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 9              
                if(body["list"][9]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][9]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][9]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][9]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][9]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][9]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][9]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][9]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][9]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 10              
                if(body["list"][10]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][10]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][10]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][10]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][10]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][10]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][10]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][10]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][10]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 11              
                if(body["list"][11]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][11]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][11]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][11]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][11]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][11]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][11]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][11]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][11]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 12              
                if(body["list"][12]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][12]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][12]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][12]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][12]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][12]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][12]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][12]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][12]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 13              
                if(body["list"][13]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][13]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][13]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][13]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][13]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][13]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][13]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][13]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][13]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 14              
                if(body["list"][14]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][14]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][14]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][14]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][14]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][14]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][14]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][14]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][14]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),    
//=== 15              
                if(body["list"][15]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][15]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][15]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][15]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][15]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][15]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][15]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][15]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][15]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 16              
                if(body["list"][16]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][16]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][16]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][16]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][16]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][16]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][16]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][16]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][16]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 17              
                if(body["list"][17]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][17]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][17]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][17]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][17]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][17]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][17]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][17]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][17]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 18              
                if(body["list"][18]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][18]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][18]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][18]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][18]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][18]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][18]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][18]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][18]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 19              
                if(body["list"][19]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][19]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][19]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][19]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][19]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][19]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][19]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][19]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][19]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 20              
                if(body["list"][20]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][20]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][20]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][20]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][20]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][20]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][20]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][20]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][20]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 21              
                if(body["list"][21]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][21]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][21]["dt_txt"].substring(0, 10))),                     
                  ]), 
                  if(body["list"][21]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10),      
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][21]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][21]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][21]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][21]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][21]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 22              
                if(body["list"][22]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][22]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][22]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][22]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][22]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][22]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][22]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][22]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][22]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 23              
                if(body["list"][23]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][23]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][23]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][23]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][23]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][23]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][23]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][23]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][23]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 24              
                if(body["list"][24]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][24]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][24]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][24]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][24]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][24]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][24]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][24]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][24]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),               
//=== 25              
                if(body["list"][25]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][25]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][25]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][25]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][25]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][25]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][25]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][25]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][25]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 26              
                if(body["list"][26]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][26]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][26]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][26]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][26]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][26]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][26]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][26]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][26]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 27              
                if(body["list"][27]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][27]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][27]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][27]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][27]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][27]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][27]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][27]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][27]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 28              
                if(body["list"][28]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][28]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][28]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][28]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][28]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][28]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][28]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][28]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][28]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 29              
                if(body["list"][29]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][29]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][29]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][29]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][29]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][29]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][29]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][29]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][29]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 30              
                if(body["list"][30]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][30]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][30]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][30]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][30]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][30]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][30]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][30]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][30]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 31              
                if(body["list"][31]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][31]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][31]["dt_txt"].substring(0, 10))),                     
                  ]), 
                  if(body["list"][31]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10),      
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][31]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][31]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][31]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][31]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][31]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 32              
                if(body["list"][32]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][32]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][32]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][32]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][32]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][32]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][32]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][32]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][32]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 33              
                if(body["list"][33]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][33]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][33]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][33]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][33]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][33]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][33]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][33]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][33]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 34              
                if(body["list"][34]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][34]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][34]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][34]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][34]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][34]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][34]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][34]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][34]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),               
//=== 35              
                if(body["list"][35]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][35]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][35]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][35]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][35]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][35]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][35]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][35]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][35]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 36              
                if(body["list"][36]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][36]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][36]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][36]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][36]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][36]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][36]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][36]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][36]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 37              
                if(body["list"][37]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][37]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][37]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][37]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][37]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][37]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][37]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][37]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][37]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),                  
//=== 38              
                if(body["list"][38]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][38]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][38]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][38]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][38]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][38]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][38]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][38]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      Text((body["list"][38]["pop"]*100).toStringAsFixed(0) + '%'),  
                    ]),
                  Divider(height: 0),
//=== 39              
                if(body["list"][39]["dt_txt"].substring(11, 16) == '00:00')//jezeli nowa doba
                  Row( //dzień - data
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(DateFormat.EEEE(globals.jezyk).format(DateTime.fromMillisecondsSinceEpoch(body["list"][39]["dt"] * 1000)) + " " 
                      + zmienDate(body["list"][39]["dt_txt"].substring(0, 10))),                     
                  ]),
                  if(body["list"][39]["dt_txt"].substring(11, 16) == '00:00') Divider(height: 10), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(body["list"][39]["dt_txt"].substring(11, 16)), //godzina
                      Image.network('https://openweathermap.org/img/wn/${body["list"][39]["weather"][0]["icon"]}.png'), //icon
                      Text(body["list"][39]["main"]["temp"].toStringAsFixed(0) + stopnie), //stopnie
                      Image.asset('assets/image/wind.png', width: 15, height: 15, fit:BoxFit.fill),
                      Text((body["list"][39]["wind"]["speed"]*3.6).toStringAsFixed(0) + ' ' + 'km/h'), 
                      Image.asset('assets/image/rain.png', width: 15, height: 15, fit:BoxFit.fill), 
                      //(body["list"][39]["pop"]*100).toStringAsFixed(0) == '0'
                      //? 
                      Text((body["list"][39]["pop"]*100).toStringAsFixed(0) + '%')
                     // : Text((body["list"][39]["pop"]*100).toStringAsFixed(0) + '%',style: TextStyle(color:Colors.blue)),  
                    ]),
                  Divider(height: 0),
               
                  SizedBox(
                    height: 30,
                  ),


                    ]
                  ))));
  }
}
