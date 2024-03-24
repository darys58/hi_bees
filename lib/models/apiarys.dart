import 'package:flutter/material.dart';


import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej
import 'apiary.dart';


class Apiarys with ChangeNotifier {
  List<Apiary> _items =
      []; //lista wpisów, dostępna tylko wewnątrz tej klasy, będzie się zmieniać, podkreślenie oznacza ze jest to wartość prywatna klasy

  List<Apiary> get items {
    //getter który zwraca kopię zmiennej _items
    return [..._items];
  }

  //pobranie wpisów o ramce z bazy lokalnej
  Future<void> fetchAndSetApiarys() async {
    final dataList = await DBHelper.getApiarys();
    _items = dataList
        .map(
          (item) => Apiary(
            id: item['id'],
            pasiekaNr: item['pasiekaNr'],
            ileUli: item['ileUli'],
            przeglad: item['przeglad'],
            ikona: item['ikona'],
            opis: item['opis'],
          ),
        )
        .toList();
    print('wczytanie wszystkich!!!!!!! danych o pasiekach --> Apiarys <---');
    //print(_items);
    notifyListeners();
  }

  //zapisanie pasieki do bazy lokalnej
  static Future<void> insertApiary(String id, int pasieka, int uli,
      String przeglad, String ikona, String opis) async {
    await DBHelper.insert('pasieki', {
      'id': id, //utworzony klucz unikalny
      'pasiekaNr': pasieka,
      'ileUli': uli,
      'przeglad': przeglad,
      'ikona': ikona,
      'opis': opis,
    });
  }
}
