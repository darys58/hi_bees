import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej
import './info.dart';

class Infos with ChangeNotifier {
  //klasa Meals jest zmiksowana z klasą ChangeNotifier która pozwala ustalać tunele komunikacyjne przy pomocy obiektu context
  List<Info> _items =
      []; //lista wpisów, dostępna tylko wewnątrz tej klasy, będzie się zmieniać, podkreślenie oznacza ze jest to wartość prywatna klasy

  List<Info> get items {
    //getter który zwraca kopię zmiennej _items
    return [..._items]; //... - operator rozprzestrzeniania
  }

   //pobranie info z serwera www
  static Future<void> fetchInfosFromSerwer(String url) async {
    //const url = 'https://cobytu.com/cbt.php?d=f_dania&uz_id=&woj_id=14&mia_id=1&rest=&lang=pl';
    try {
      final response = await http.get(Uri.parse(url));
      // print('response od info');
      // print(json.decode(response.body));
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      // if (extractedData == null) {
      //   return;
      // }
      extractedData.forEach((infoId, infoData) {
        if (infoId != 'brak') {//jezeli są wpisy a tabeli info_xxxx
          //zapis info do bazy
          DBHelper.insert('info', {
            'id': infoId,
            'data': infoData['in_data'],
            'pasiekaNr': infoData['in_pasiekaNr'],
            'ulNr': infoData['in_ulNr'],
            'kategoria': infoData['in_kategoria'],
            'parametr': infoData['in_parametr'],
            'wartosc': infoData['in_wartosc'],
            'miara': infoData['in_miara'],
            'pogoda': infoData['in_pogoda'],
            'temp': infoData['in_temp'],
            'czas': infoData['in_czas'],
            'uwagi': infoData['in_uwagi'],
            'arch': 2,
          });
        }
      });
    } catch (error) {
      throw (error);
    }
  }


//pobranie wszystkich wpisów o info z bazy lokalnej
  Future<void> fetchAndSetInfos() async {
    final dataList = await DBHelper.getData('info');
    _items = dataList
        .map(
          (item) => Info(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            kategoria: item['kategoria'],
            parametr: item['parametr'],
            wartosc: item['wartosc'],
            miara: item['miara'],
            pogoda: item['pogoda'],
            temp: item['temp'],
            czas: item['czas'],
            uwagi: item['uwagi'],
            arch: item['arch'],
          ),
        )
        .toList();
    //print('wczytanie wszystkich!!!!!!! informacji --> Infos <---');
    //print(_items);
    notifyListeners();
  }


  //pobranie nowych wpisów o info z bazy lokalnej do archiwizacji
  Future<void> fetchAndSetInfosToArch() async {
    final dataList = await DBHelper.getInfosToArch();
    _items = dataList
        .map(
          (item) => Info(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            kategoria: item['kategoria'],
            parametr: item['parametr'],
            wartosc: item['wartosc'],
            miara: item['miara'],
            pogoda: item['pogoda'],
            temp: item['temp'],
            czas: item['czas'],
            uwagi: item['uwagi'],
            arch: item['arch'],
          ),
        )
        .toList();
    //print('wczytanie wszystkich nowych informacji --> Infos <---');
    //print(_items);
    notifyListeners();
  }

  //pobranie wpisów o info dla jednego ula z bazy lokalnej
  Future<void> fetchAndSetInfosForHive(pasieka, ul) async {
    final dataList = await DBHelper.getInfosOfHive(pasieka, ul);
    _items = dataList
        .map(
          (item) => Info(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            kategoria: item['kategoria'],
            parametr: item['parametr'],
            wartosc: item['wartosc'],
            miara: item['miara'],
            pogoda: item['pogoda'],
            temp: item['temp'],
            czas: item['czas'],
            uwagi: item['uwagi'],
            arch: item['arch']!,
          ),
        )
        .toList();
    //print('wczytanie info dla podanego ula i pasieki ---> Infos <---');
    //print(_items);
    notifyListeners();
  }


  //zapisanie info do bazy lokalnej
  static Future<void> insertInfo(
      String id,
      String data,
      int pasieka,
      int ul,
      String kategoria,
      String parametr,
      String wartosc,
      String miara,
      String pogoda,
      String temp,
      String czas,
      String uwagi,
      int arch) async {
    await DBHelper.insert('info', {
      'id': id, 
      'data': data,
      'pasiekaNr': pasieka,
      'ulNr': ul,
      'kategoria': kategoria,
      'parametr': parametr,
      'wartosc': wartosc,
      'miara': miara,
      'pogoda': pogoda,
      'temp': temp,
      'czas': czas,
      'uwagi': uwagi,
      'arch': arch,
    });
  }



  /* 
  //usuwanie wszystkich dań z bazy lokalnej
  static Future<void> deleteAllMeals()async{
     await DBHelper.deleteTable('dania');

  }

  static Future<void> updateFavorite(id, fav)async{
     await DBHelper.updateFav(id, fav);

  }

  static Future<void> updateKoszyk(id, ile)async{
     await DBHelper.updateIle(id, ile);

  }
*/
}
