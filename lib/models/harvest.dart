
import 'dart:convert'; //obsługa json'a
import 'package:flutter/material.dart';
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej
import 'package:http/http.dart' as http;
      
class Harvest with ChangeNotifier {
  final int id; //autoincrement 
  final String data; //
  final int pasiekaNr; //
  final int zasobId; //
  final double ilosc; //
  final int miara; //1-l, 2-kg
  final String uwagi; //
  final String g; //średnia waga 1dm2 miodu w tym miodobraniu
  final String h; //
  final int arch; //0-niezarchiwizowane, 1-przesłane do chmury, 2-zaimportowane z chmury

  Harvest({
    required this.id,
    required this.data, 
    required this.pasiekaNr, 
    required this.zasobId, 
    required this.ilosc, 
    required this.miara,
    required this.uwagi,
    required this.g,
    required this.h,
    required this.arch,
  });
}

class Harvests with ChangeNotifier {
  List<Harvest> _items = [];

  List<Harvest> get items {
    return [..._items];
  }

  //pobranie zbiorów z serwera www
  static Future<void> fetchZbioryFromSerwer(String url) async {
    //const url = 'https://cobytu.com/cbt.php?d=f_dania&uz_id=&woj_id=14&mia_id=1&rest=&lang=pl';
    try {
      final response = await http.get(Uri.parse(url));
      //print(json.decode(response.body));

      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      // if (extractedData == null) {
      //   return;
      // }

      extractedData.forEach((zbioryId, zbioryData) {
        if (zbioryId != 'brak') {//jezeli są wpisy a tabeli zbiory_xxxx
          //zapis do bazy
          DBHelper.insert('zbiory', {
            'id': zbioryId,
            'data': zbioryData['zb_data'],
            'pasiekaNr': zbioryData['zb_pasiekaNr'],
            'zasobId': zbioryData['zb_zasobId'],
            'ilosc': zbioryData['zb_ilosc'],
            'miara': zbioryData['zb_miara'],
            'uwagi': zbioryData['zb_uwagi'],
            'g': zbioryData['zb_g'],
            'h': zbioryData['zb_h'],
            'arch': 2,
          });
        }
      });
    } catch (error) {
      throw (error);
    }
  }

  
  //pobranie wpisów zbiory z bazy lokalnej
  Future<void> fetchAndSetZbiory() async {
    final dataList = await DBHelper.getZbiory();
    _items = dataList
        .map(
          (item) => Harvest(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            zasobId: item['zasobId'],
            ilosc: item['ilosc'],
            miara: item['miara'],
            uwagi: item['uwagi'],
            g: item['g'],
            h: item['h'],
            arch: item['arch'],
          ),
        )
        .toList();
    //print('wczytanie danych do uruchomienia apki --> Zbiory <---');
    //print(_items);
    notifyListeners();
  }

  //pobranie nowych wpisów w zbiory z bazy lokalnej do archiwizacji
  Future<void> fetchAndSetZbioryToArch() async {
    final dataList = await DBHelper.getZbioryToArch();
    _items = dataList
        .map(
          (item) => Harvest(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            zasobId: item['zasobId'],
            ilosc: item['ilosc'],
            miara: item['miara'],
            uwagi: item['uwagi'],
            g: item['g'],
            h: item['h'],
            arch: item['arch'],
          ),
        )
        .toList();
    //print('wczytanie wszystkich nowych zbiorów --> Zbiory <---');
    //print(_items);
    notifyListeners();
  }



  //zapisanie danych do bazy lokalnej
  static Future<void> insertZbiory(
   // String id,
    String data,
    int pasiekaNr,
    int zasobId,
    double ilosc,
    int miara,
    String uwagi,
    String g,
    String h,
    int arch,
  ) async {
    await DBHelper.insert('zbiory', {
     // 'id': id,
      'data': data,
      'pasiekaNr': pasiekaNr,
      'zasobId': zasobId,
      'ilosc': ilosc,
      'miara': miara,
      'uwagi': uwagi,
      'g': g,
      'h': h,
      'arch': arch,
    });
  }
}
