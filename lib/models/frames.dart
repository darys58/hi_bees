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


  //pobranie ramek z serwera www - tylko download (HTTP GET + JSON decode)
  static Future<List<MapEntry<String, dynamic>>> downloadFramesFromSerwer(String url) async {
    final response = await http.get(Uri.parse(url));
    //wycinamy sam JSON z odpowiedzi (serwer moze dodać tekst po JSON)
    String body = response.body.trim();
    final jsonEnd = body.lastIndexOf('}');
    if (jsonEnd != -1 && jsonEnd < body.length - 1) {
      body = body.substring(0, jsonEnd + 1);
    }
    final extractedData = json.decode(body) as Map<String, dynamic>;
    return extractedData.entries.where((e) => e.key != 'brak').toList();
  }

  //zapis pobranych ramek do bazy lokalnej z progressem
  static Future<int> saveFramesToDb(List<MapEntry<String, dynamic>> entries, {Function(int current, int total)? onProgress}) async {
    final total = entries.length;
    int current = 0;
    for (var entry in entries) {
      DBHelper.insert('ramka', {
        'id': entry.key,
        'data': entry.value['ra_data'],
        'pasiekaNr': entry.value['ra_pasiekaNr'],
        'ulNr': entry.value['ra_ulNr'],
        'korpusNr': entry.value['ra_korpusNr'],
        'typ': entry.value['ra_typ'],
        'ramkaNr': entry.value['ra_ramkaNr'],
        'ramkaNrPo': entry.value['ra_ramkaNrPo'],
        'rozmiar': entry.value['ra_rozmiar'],
        'strona': entry.value['ra_strona'],
        'zasob': entry.value['ra_zasob'],
        'wartosc': entry.value['ra_wartosc'],
        'arch': 2,
      });
      current++;
      if (onProgress != null && (current % 100 == 0 || current == total)) {
        onProgress(current, total);
        await Future.delayed(Duration.zero); //oddanie sterowania do UI
      }
    }
    return total;
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


