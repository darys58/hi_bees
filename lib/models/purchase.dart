import 'dart:convert'; //obsługa json'a
import 'package:flutter/material.dart';
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej
import 'package:http/http.dart' as http;

class Purchase with ChangeNotifier {
  final int id; //autoincrement
  final String data; //
  final int pasiekaNr; //
  final String nazwa;
  final int kategoriaId; //
  final double ilosc; //
  final int miara; //
  final double cena;
  final double wartosc;
  final int waluta;
  final String uwagi; //
  final int arch; //0-niezarchiwizowane, 1-przesłane do chmury, 2-zaimportowane z chmury

  Purchase({
    required this.id,
    required this.data,
    required this.pasiekaNr,
    required this.nazwa,
    required this.kategoriaId,
    required this.ilosc,
    required this.miara,
    required this.cena,
    required this.wartosc,
    required this.waluta,
    required this.uwagi,
    required this.arch,
  });
}

class Purchases with ChangeNotifier {
  List<Purchase> _items = [];

  List<Purchase> get items {
    return [..._items];
  }

   //pobranie zakupy z serwera www
  static Future<void> fetchZakupyFromSerwer(String url) async {
    //const url = 'https://cobytu.com/cbt.php?d=f_dania&uz_id=&woj_id=14&mia_id=1&rest=&lang=pl';
    try {
      final response = await http.get(Uri.parse(url));
      //print(json.decode(response.body));

      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      // if (extractedData == null) {
      //   return;
      // }
      
      extractedData.forEach((zakupyId, zakupyData) {
        if (zakupyId != 'brak') {//jezeli są wpisy a tabeli zakupy_xxxx
          //zapis do bazy
          DBHelper.insert('zakupy', {
            'id': zakupyId,
            'data': zakupyData['za_data'],
            'pasiekaNr': zakupyData['za_pasiekaNr'],
            'nazwa': zakupyData['za_nazwa'],
            'kategoriaId': zakupyData['za_kategoriaId'],
            'ilosc': zakupyData['za_ilosc'],
            'miara': zakupyData['za_miara'],
            'cena': zakupyData['za_cena'],
            'wartosc': zakupyData['za_wartosc'],
            'waluta': zakupyData['za_waluta'],
            'uwagi': zakupyData['za_uwagi'],
            'arch': 2,
          });
        }
      });
    } catch (error) {
      throw (error);
    }
  }


  //pobranie wpisów zbiory z bazy lokalnej
  Future<void> fetchAndSetZakupy() async {
    final dataList = await DBHelper.getZakupy();
    _items = dataList
        .map(
          (item) => Purchase(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            nazwa: item['nazwa'],
            kategoriaId: item['kategoriaId'],
            ilosc: item['ilosc'],
            miara: item['miara'],
            cena: item['cena'],
            wartosc: item['wartosc'],
            waluta: item['waluta'],
            uwagi: item['uwagi'],
            arch: item['arch'],
          ),
        )
        .toList();
    //print('wczytanie danych do uruchomienia apki --> Zakupy <---');
    //print(_items);
    notifyListeners();
  }

  
  //pobranie nowych wpisów w zakupy z bazy lokalnej do archiwizacji
  Future<void> fetchAndSetZakupyToArch() async {
    final dataList = await DBHelper.getZakupyToArch();
    _items = dataList
        .map(
          (item) => Purchase(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            nazwa: item['nazwa'],
            kategoriaId: item['kategoriaId'],
            ilosc: item['ilosc'],
            miara: item['miara'],
            cena: item['cena'],
            wartosc: item['wartosc'],
            waluta: item['waluta'],
            uwagi: item['uwagi'],
            arch: item['arch'],
          ),
        )
        .toList();
    //print('wczytanie wszystkich nowych zakupy --> Zakupy <---');
    //print(_items);
    notifyListeners();
  }

  //zapisanie danych do bazy lokalnej
  static Future<void> insertZakupy(
    // String id,
    String data,
    int pasiekaNr,
    String nazwa,
    int kategoriaId,
    double ilosc,
    int miara,
    double cena,
    double wartosc,
    int waluta,
    String uwagi,
    int arch,
  ) async {
    await DBHelper.insert('zakupy', {
      // 'id': id,
      'data': data,
      'pasiekaNr': pasiekaNr,
      'nazwa': nazwa,
      'kategoriaId': kategoriaId,
      'ilosc': ilosc,
      'miara': miara,
      'cena': cena,
      'wartosc': wartosc,
      'waluta': waluta,
      'uwagi': uwagi,
      'arch': arch,
    });
  }
}
