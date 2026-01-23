//dane dań
import 'dart:convert'; //obsługa json'a
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej
import './frame.dart';

class Frames with ChangeNotifier {
  //klasa Meals jest zmiksowana z klasą ChangeNotifier która pozwala ustalać tunele komunikacyjne przy pomocy obiektu context
  List<Frame> _items =
      []; //lista wpisów, dostępna tylko wewnątrz tej klasy, będzie się zmieniać, podkreślenie oznacza ze jest to wartość prywatna klasy

  List<Frame> get items {
    //getter który zwraca kopię zmiennej _items
    return [..._items]; //... - operator rozprzestrzeniania
  }

  //metoda szukająca dania o danym id - przeniesiona z meal_detail_screen.dart
  // Frame findById(String id) {
  //   return _items.firstWhere((ml) => ml.id ==  id);
  // }


  //pobranie ramek z serwera www
  static Future<void> fetchFramesFromSerwer(String url) async {
    //const url = 'https://cobytu.com/cbt.php?d=f_dania&uz_id=&woj_id=14&mia_id=1&rest=&lang=pl';
    try {
      final response = await http.get(Uri.parse(url));
      //print(json.decode(response.body));

      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      // if (extractedData == null) {
      //   return;
      // }

      extractedData.forEach((ramkaId, ramkaData) {
        if (ramkaId != 'brak') {//jezeli są wpisy a tabeli xxxx_ramka
          //zapis ramki do bazy
          DBHelper.insert('ramka', {
            'id': ramkaId,
            'data': ramkaData['ra_data'],
            'pasiekaNr': ramkaData['ra_pasiekaNr'],
            'ulNr': ramkaData['ra_ulNr'],
            'korpusNr': ramkaData['ra_korpusNr'],
            'typ': ramkaData['ra_typ'],
            'ramkaNr': ramkaData['ra_ramkaNr'],
            'ramkaNrPo': ramkaData['ra_ramkaNrPo'],
            'rozmiar': ramkaData['ra_rozmiar'],
            'strona': ramkaData['ra_strona'],
            'zasob': ramkaData['ra_zasob'],
            'wartosc': ramkaData['ra_wartosc'],
            'arch': 2,
          });
        }
      });
    } catch (error) {
      throw (error);
    }
  }

//pobranie wszystkich wpisów o ramce z bazy lokalnej
  Future<void> fetchAndSetFrames() async {
    final dataList = await DBHelper.getData('ramka');
    _items = dataList
        .map(
          (item) => Frame(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            korpusNr: item['korpusNr'],
            typ: item['typ'],
            ramkaNr: item['ramkaNr'],
            ramkaNrPo: item['ramkaNrPo'],
            rozmiar: item['rozmiar'],
            strona: item['strona'],
            zasob: item['zasob'],
            wartosc: item['wartosc'],
            arch: item['arch']!,
          ),
        )
        .toList();
    //print('wczytanie wszystkich!!!!!!! danych o ramkach --> Frames <---');
    //print(_items);
    notifyListeners();
  }

  //pobranie wpisów o ramce z bazy lokalnej dla podanego ula
  Future<void> fetchAndSetFramesForHive(pasieka, ul) async {
    final dataList = await DBHelper.getFramesOfHive(pasieka, ul);
    _items = dataList
        .map(
          (item) => Frame(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            korpusNr: item['korpusNr'],
            typ: item['typ'],
            ramkaNr: item['ramkaNr'],
            ramkaNrPo: item['ramkaNrPo'],
            rozmiar: item['rozmiar'],
            strona: item['strona'],
            zasob: item['zasob'],
            wartosc: item['wartosc'],
            arch: item['arch']!,
          ),
        )
        .toList();
    //print('wczytanie danych o ramkach dla podanego ula i pasieki ---> Frames <---');
    //print(_items);
    notifyListeners();
  }

  //pobranie nowych wpisów o ramce z bazy lokalnej do archiwizacji
  Future<void> fetchAndSetFramesToArch() async {
    final dataList = await DBHelper.getFramesToArch();
    _items = dataList
        .map(
          (item) => Frame(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            korpusNr: item['korpusNr'],
            typ: item['typ'],
            ramkaNr: item['ramkaNr'],
            ramkaNrPo: item['ramkaNrPo'],
            rozmiar: item['rozmiar'],
            strona: item['strona'],
            zasob: item['zasob'],
            wartosc: item['wartosc'],
            arch: item['arch']!,
          ),
        )
        .toList();
    //print('wczytanie nowych danych o ramkach do archiwizacji ---> Frames <---');
    //print(_items);
    notifyListeners();
  }

  //pobranie ramki z bazy lokalnej dla podanego id
  Future<void> fetchAndSetFrameForId(idRamki) async {
    final dataList = await DBHelper.getFrame(idRamki);
    _items = dataList
        .map(
          (item) => Frame(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            korpusNr: item['korpusNr'],
            typ: item['typ'],
            ramkaNr: item['ramkaNr'],
            ramkaNrPo: item['ramkaNrPo'],
            rozmiar: item['rozmiar'],
            strona: item['strona'],
            zasob: item['zasob'],
            wartosc: item['wartosc'],
            arch: item['arch']!,
          ),
        )
        .toList();
    //print('wczytanie ramki dla podanego id ---> Frame <---');
    //print(_items);
    notifyListeners();
  }

 

  //zapisanie ramki do bazy lokalnej
  static Future<void> insertFrame(
      String id,
      String data,
      int pasieka,
      int ul,
      int korpus,
      int typ,
      int ramka,
      int ramkaPo,
      int rozmiar,
      int strona,
      int zasob,
      String wartosc,
      int arch) async {
    await DBHelper.insert('ramka', {
      'id': id, //utworzony klucz unikalny
      'data': data,
      'pasiekaNr': pasieka,
      'ulNr': ul,
      'korpusNr': korpus,
      'typ': typ,
      'ramkaNr': ramka,
      'ramkaNrPo': ramkaPo,
      'rozmiar': rozmiar,
      'strona': strona,
      'zasob': zasob,
      'wartosc': wartosc,
      'arch': arch,
    });
  }
  
}


