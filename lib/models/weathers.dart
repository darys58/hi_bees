import 'package:flutter/material.dart';


import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej
import 'weather.dart';


class Weathers with ChangeNotifier {
  List<Weather> _items =
      []; //lista wpisów, dostępna tylko wewnątrz tej klasy, będzie się zmieniać, podkreślenie oznacza ze jest to wartość prywatna klasy

  List<Weather> get items {
    //getter który zwraca kopię zmiennej _items
    return [..._items];
  }

  //pobranie wpisów o pogodzie z bazy lokalnej
   Future<void> fetchAndSetWeathers() async {
    final dataList = await DBHelper.getData('pogoda');
    _items = dataList
        .map(
          (item) => Weather(
            id: item['id'],
            miasto: item['miasto'],
            latitude: item['latitude'],
            longitude: item['longitude'],
            pobranie: item['pobranie'],
            temp: item['temp'],
            weatherId: item['weatherId'],
            icon: item['icon'],
            units: item['units'],
            lang: item['lang'],
            inne: item['inne'],
          ),
        )
        .toList();
    print('wczytanie wszystkich!!!!!!! informacji o pogodzie--> pogoda <---');
    //print(_items);
    notifyListeners();
  }

  //zapisanie pogody dla wybranej pasieki do bazy lokalnej
  static Future<void> insertWeather(
    String id, 
    String miasto, 
    String latitude,
    String longitude, 
    String pobranie, 
    String temp, 
    String weatherId, 
    String icon, 
    int units, 
    String lang,
    String inne) async {
    await DBHelper.insert('pogoda', {
      'id': id, //id pasieki
      'miasto': miasto,
      'latitude': latitude,
      'longitude': longitude,
      'pobranie': pobranie,
      'temp': temp,
      'weatherId': weatherId,
      'icon': icon,
      'units': units,
      'lang': lang,
      'inne': inne,
    });
  }
}
