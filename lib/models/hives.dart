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
  Future<void> fetchAndSetHivesAll() async {
    final dataList = await DBHelper.getData('ule');
    _items = dataList
        .map(
          (item) => Hive(
            id: item['id'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            przeglad: item['przeglad'],
            ikona: item['ikona'],
            ramek: item['ramek'],
            korpusNr: item['korpusNr'],
            trut: item['trut'],
            czerw: item['czerw'],
            larwy: item['larwy'],
            jaja: item['jaja'],
            pierzga: item['pierzga'],
            miod: item['miod'],
            dojrzaly: item['dojrzaly'],
            weza: item['weza'],
            susz: item['susz'],
            matka: item['matka'],
            mateczniki: item['mateczniki'],
            usunmat: item['usunmat'],
            todo: item['todo'],
            kategoria: item['kategoria'],
            parametr: item['parametr'],
            wartosc: item['wartosc'],
            miara: item['miara'],
            matka1: item['matka1'],
            matka2: item['matka2'],
            matka3: item['matka3'],
            matka4: item['matka4'],
            matka5: item['matka5'],
            h1: item['h1'],
            h2: item['h2'],
            h3: item['h3'],
            aktual: item['aktual'],
          ),
        )
        .toList();
    //print('wczytanie wszystkich!!!!!!! danych o ulach z wszystkich pasiek --> Hives <---');
    //print(_items);
    notifyListeners();
  }




  //pobranie wpisów o ulach z danej pasieki z tabeli ule z bazy lokalnej
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
            ramek: item['ramek'],
            korpusNr: item['korpusNr'],
            trut: item['trut'],
            czerw: item['czerw'],
            larwy: item['larwy'],
            jaja: item['jaja'],
            pierzga: item['pierzga'],
            miod: item['miod'],
            dojrzaly: item['dojrzaly'],
            weza: item['weza'],
            susz: item['susz'],
            matka: item['matka'],
            mateczniki: item['mateczniki'],
            usunmat: item['usunmat'],
            todo: item['todo'],
            kategoria: item['kategoria'],
            parametr: item['parametr'],
            wartosc: item['wartosc'],
            miara: item['miara'],
            matka1: item['matka1'],
            matka2: item['matka2'],
            matka3: item['matka3'],
            matka4: item['matka4'],
            matka5: item['matka5'],
            h1: item['h1'],
            h2: item['h2'],
            h3: item['h3'],
            aktual: item['aktual'],
          ),
        )
        .toList();
    //print('wczytanie wszystkich!!!!!!! danych o ulach z pasieki nr $nrPasieki --> Hives <---');
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
      int ramek,
      int korpusNr,
      int trut,
      int czerw,
      int larwy,
      int jaja,
      int pierzga,
      int miod,
      int dojrzaly,
      int weza,
      int susz,
      int matka,
      int mateczniki,
      int usunmat, 
      String todo,
      String kategoria,
      String parametr,
      String wartosc,
      String miara,
      String matka1,
      String matka2,
      String matka3,
      String matka4,
      String matka5,
      String h1,
      String h2,
      String h3,
      int aktual,
      ) async {
    await DBHelper.insert('ule', {
      'id': id, //utworzony klucz unikalny  pasiekaNr.ulNr.
      'pasiekaNr': pasieka,
      'ulNr': ul,
      'przeglad': przeglad,
      'ikona': ikona,
      'ramek': ramek,
      'korpusNr': korpusNr,
      'trut': trut,
      'czerw': czerw,
      'larwy': larwy,
      'jaja':jaja,
      'pierzga': pierzga,
      'miod': miod,
      'dojrzaly': dojrzaly,
      'weza': weza,
      'susz': susz,
      'matka': matka,
      'mateczniki': mateczniki,
      'usunmat': usunmat,
      'todo': todo, 
      'kategoria': kategoria,
      'parametr': parametr,
      'wartosc': wartosc,
      'miara': miara,
      'matka1': matka1,
      'matka2': matka2,
      'matka3': matka3,
      'matka4': matka4,
      'matka5': matka5,
      'h1': h1,
      'h2': h2,
      'h3': h3,
      'aktual': aktual,
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
