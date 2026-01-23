import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert'; //obsługa json'a
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej

//import '../globals.dart' as globals;

class Dodatki1Item with ChangeNotifier {
  final String id; //id:1 
  final String a; //ustawienie przełacznika - automatyczny eksport danych przy uruchamianiu aplikacji
  final String b; //średnia waga miodu na 1dm2 plastra miodu
  final String c; //
  final String d; //
  final String e; //średnia waga miodu małej ramki (dla obliczania ilości miodu w latach 2023-2025)
  final String f; //średnia waga miodu duzej ramki (dla obliczania ilości miodu w latach 2023-2025)
  final String g; //waga pyłku w jednej miarce/porcji
  final String h; //ilość uli na stronie raportów

  Dodatki1Item({
    required this.id,
    required this.a, 
    required this.b, 
    required this.c, 
    required this.d, 
    required this.e,
    required this.f,
    required this.g,
    required this.h,
  });
}

class Dodatki1 with ChangeNotifier {
  List<Dodatki1Item> _items = [];

  List<Dodatki1Item> get items {
    return [..._items];
  }

  //pobranie wpisów dodatki1 z bazy lokalnej
  Future<void> fetchAndSetDodatki1() async {
    final dataList = await DBHelper.getDodatki1();
    _items = dataList
        .map(
          (item) => Dodatki1Item(
            id: item['id'],
            a: item['a'],
            b: item['b'],
            c: item['c'],
            d: item['d'],
            e: item['e'],
            f: item['f'],
            g: item['g'],
            h: item['h'],
          ),
        )
        .toList();
    //print('wczytanie danych do uruchomienia apki --> Dodatki1 <---');
    //print(_items);
    notifyListeners();
  }


  //zapisanie danych do bazy lokalnej
  static Future<void> insertDodatki1(
    String id,
    String a,
    String b,
    String c,
    String d,
    String e,
    String f,
    String g,
    String h,
  ) async {
    await DBHelper.insert('dodatki1', {
      'id': id,
      'a': a,
      'b': b,
      'c': c,
      'd': d,
      'e': e,
      'f': f,
      'g': g,
      'h': h,
    });
  }
}
