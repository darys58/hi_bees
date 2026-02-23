import 'dart:convert'; //obsługa json'a
import 'package:flutter/material.dart';
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej
import 'package:http/http.dart' as http;

class Sale with ChangeNotifier {
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

  Sale({
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

class Sales with ChangeNotifier {
  List<Sale> _items = [];

  List<Sale> get items {
    return [..._items];
  }

   //pobranie sprzedazy z serwera www
  static Future<void> fetchSprzedazFromSerwer(String url) async {
    //const url = 'https://cobytu.com/cbt.php?d=f_dania&uz_id=&woj_id=14&mia_id=1&rest=&lang=pl';
    try {
      final response = await http.get(Uri.parse(url));
      //wycinamy sam JSON z odpowiedzi (serwer moze dodać tekst po JSON)
      String body = response.body.trim();
      final jsonEnd = body.lastIndexOf('}');
      if (jsonEnd != -1 && jsonEnd < body.length - 1) {
        body = body.substring(0, jsonEnd + 1);
      }
      final extractedData = json.decode(body) as Map<String, dynamic>;
      // if (extractedData == null) {
      //   return;
      // }
      
      extractedData.forEach((sprzedazId, sprzedazData) {
        if (sprzedazId != 'brak') {//jezeli są wpisy a tabeli sprzedaz_xxxx
          //zapis do bazy
          DBHelper.insert('sprzedaz', {
            'id': sprzedazId,
            'data': sprzedazData['sp_data'],
            'pasiekaNr': sprzedazData['sp_pasiekaNr'],
            'nazwa': sprzedazData['sp_nazwa'],
            'kategoriaId': sprzedazData['sp_kategoriaId'],
            'ilosc': sprzedazData['sp_ilosc'],
            'miara': sprzedazData['sp_miara'],
            'cena': sprzedazData['sp_cena'],
            'wartosc': sprzedazData['sp_wartosc'],
            'waluta': sprzedazData['sp_waluta'],
            'uwagi': sprzedazData['sp_uwagi'],
            'arch': 2,
          });
        }
      });
    } catch (error) {
      throw (error);
    }
  }


  //pobranie wpisów zbiory z bazy lokalnej
  Future<void> fetchAndSetSprzedaz() async {
    final dataList = await DBHelper.getSprzedaz();
    _items = dataList
        .map(
          (item) => Sale(
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
    //print('wczytanie danych do uruchomienia apki --> Sprzedaz <---');
    //print(_items);
    notifyListeners();
  }

  
  //pobranie nowych wpisów w sprzedaz z bazy lokalnej do archiwizacji
  Future<void> fetchAndSetSprzedazToArch() async {
    final dataList = await DBHelper.getSprzedazToArch();
    _items = dataList
        .map(
          (item) => Sale(
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
    //print('wczytanie wszystkich nowych sprzedaz --> Sprzedaz <---');
    //print(_items);
    notifyListeners();
  }

  //zapisanie danych do bazy lokalnej
  static Future<void> insertSprzedaz(
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
    await DBHelper.insert('sprzedaz', {
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
