import 'package:flutter/material.dart';
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej


import 'hive.dart';

class Hives with ChangeNotifier {

  List<Hive> _items =
      []; //lista wpisów, dostępna tylko wewnątrz tej klasy, będzie się zmieniać, podkreślenie oznacza ze jest to wartość prywatna klasy

  List<Hive> get items {
    //getter który zwraca kopię zmiennej _items
    return [..._items];
  }

  //pobranie wpisów o ulach z tabeli ule z bazy lokalnej
  Future<void> fetchAndSetHives(nrPasieki) async {
    final dataList = await DBHelper.getHives(nrPasieki);
    _items = dataList
        .map(
          (item) => Hive(
            id: item['id'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            przeglad: item['przeglad'],
            ikona: item['ikona'],
            opis: item['opis'],
          ),
        )
        .toList();
    print('wczytanie wszystkich!!!!!!! danych o ulach --> Hives <---');
    //print(_items);
    notifyListeners();
  }

   //zapisanie ula do bazy lokalnej
  static Future<void> insertHive(
      String id,
      int pasieka,
      int ul,
      String przeglad,
      String ikona,
      String opis) async {
    await DBHelper.insert('ule', {
      'id': id, //utworzony klucz unikalny  pasiekaNr.ulNr.
      'pasiekaNr': pasieka,
      'ulNr': ul,
      'przeglad': przeglad,
      'ikona': ikona,
      'opis': opis,
    });
  }


  
  // List<Hive> get favoriteItems {
  //   return _items.where((prodItem) => prodItem.isFavorite).toList();
  // }

  // Hive findById(String id) {
  //   return _items.firstWhere((prod) => prod.id == id);
  // }

  // void showFavoritesOnly() {
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }

  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  //addHive
  void addProduct() {
    // _items.add(value);
    notifyListeners();
  }
}
