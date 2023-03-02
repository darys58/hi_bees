import 'package:flutter/material.dart';

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

 

//pobranie wpisów o ramce z bazy lokalnej
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
            uwagi: item['uwagi'],
          ),
        )
        .toList();
    print('wczytanie wszystkich!!!!!!! informacji --> Infos <---');
    //print(_items);
    notifyListeners();
  }

  //pobranie wpisów o info z bazy lokalnej
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
            uwagi: item['uwagi'],
          ),
        )
        .toList();
    print('wczytanie info dla podanego ula i pasieki ---> Infos <---');
    //print(_items);
    notifyListeners();
  }


  //zapisanie ramki do bazy lokalnej
  static Future<void> insertInfo(
      String id,
      String data,
      int pasieka,
      int ul,
      String kategoria,
      String parametr,
      String wartosc,
      String miara,
      String uwagi) async {
    await DBHelper.insert('info', {
      'id': id, 
      'data': data,
      'pasiekaNr': pasieka,
      'ulNr': ul,
      'kategoria': kategoria,
      'parametr': parametr,
      'wartosc': wartosc,
      'miara': miara,
      'uwagi': uwagi,
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
