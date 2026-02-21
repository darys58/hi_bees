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

   //pobranie info z serwera www - tylko download (HTTP GET + JSON decode)
  static Future<List<MapEntry<String, dynamic>>> downloadInfosFromSerwer(String url) async {
    final response = await http.get(Uri.parse(url));
    final extractedData = json.decode(response.body) as Map<String, dynamic>;
    return extractedData.entries.where((e) => e.key != 'brak').toList();
  }

  //zapis pobranych info do bazy lokalnej z progressem
  static Future<int> saveInfosToDb(List<MapEntry<String, dynamic>> entries, {Function(int current, int total)? onProgress}) async {
    final total = entries.length;
    int current = 0;
    for (var entry in entries) {
      DBHelper.insert('info', {
        'id': entry.key,
        'data': entry.value['in_data'],
        'pasiekaNr': entry.value['in_pasiekaNr'],
        'ulNr': entry.value['in_ulNr'],
        'kategoria': entry.value['in_kategoria'],
        'parametr': entry.value['in_parametr'],
        'wartosc': entry.value['in_wartosc'],
        'miara': entry.value['in_miara'],
        'pogoda': entry.value['in_pogoda'],
        'temp': entry.value['in_temp'],
        'czas': entry.value['in_czas'],
        'uwagi': entry.value['in_uwagi'],
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

  //pobranie wpisów o info dla jednegj pasieki z bazy lokalnej
  Future<void> fetchAndSetInfosForApiary(pasieka) async {
    final dataList = await DBHelper.getInfosOfApiary(pasieka);
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


}
