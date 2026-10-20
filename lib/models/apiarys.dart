import 'package:flutter/material.dart';


import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej
import 'apiary.dart';


class Apiarys with ChangeNotifier {
  //provider z MultiProvider - do przeładowania z DBHelper.odswiezPrzegladPasieki
  //(usuwanie ramek nie przechodzi przez ekran, który trzyma kontekst)
  static Apiarys? _biezacy;
  Apiarys() {
    _biezacy = this;
  }

  static Future<void> przeladujBiezacy() async {
    await _biezacy?.fetchAndSetApiarys();
  }

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
    //print('wczytanie wszystkich!!!!!!! danych o pasiekach --> Apiarys <---');
    //print(_items);
    notifyListeners();
  }

  //zapisanie pasieki do bazy lokalnej. [przeglad] tylko dla pasieki bez ramek - data
  //przeglądu pasieki to zawsze najnowszy przegląd ramek (20.10.2026, patrz
  //DBHelper.getDataPrzegladuPasieki); wywołania podają różne daty (wpisu, dzisiejszą)
  static Future<void> insertApiary(String id, int pasieka, int uli,
      String przeglad, String ikona, String opis) async {
    final dataPrzegladu = await DBHelper.getDataPrzegladuPasieki(pasieka) ?? przeglad;
    await DBHelper.insert('pasieki', {
      'id': id, //utworzony klucz unikalny
      'pasiekaNr': pasieka,
      'ileUli': uli,
      'przeglad': dataPrzegladu,
      'ikona': ikona,
      'opis': opis,
    });
  }
}
