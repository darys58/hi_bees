import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert'; //obsługa json'a
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej

//import '../globals.dart' as globals;

class Dodatki1Item with ChangeNotifier {
  final String id; //id: 
  final String a; //ustawienie przełacznika - automatyczny eksport danych przy uruchamianiu aplikacji
  final String b; //
  final String c; //
  final String d; //
  final String e; //średnia waga miodu małej ramki
  final String f; //średnia waga miodu duzej ramki
  final String g; //waga pyłku w jednej miarce/porcji
  final String h; //

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
    print('wczytanie danych do uruchomienia apki --> Dodatki1 <---');
    print(_items);
    notifyListeners();
  }


  // //pobranie danych z serwera www
  // Future<void> fetchMemoryFromSerwer() async {
  //   var url =
  //       Uri.parse('https://hibees.pl/cbt.php?d=hi_bees&kod=${globals.kod}');
  //   print(url);
  //   try {
  //     final response = await http.get(url);
  //     print(json.decode(response.body));

  //     final extractedData = json.decode(response.body) as Map<String, dynamic>;
  //     // if (extractedData == null) {
  //     //   return _items = [];
  //     // }
  //     final List<MemoryItem> loadedItems = [];

  //     extractedData.forEach((numerId, promocjeData) {
  //       loadedItems.add(MemoryItem(
  //         id: numerId,
  //         email: promocjeData['be_email'],
  //         dev: promocjeData['be_dev'],
  //         wer: promocjeData['be_wersja'],
  //         kod: promocjeData['be_kod'],
  //         key: promocjeData['be_key'],
  //         dod: promocjeData['be_od'],
  //         ddo: promocjeData['be_do'],
  //       ));
  //     });
  //     // _items = loadedRests;
  //     print('numer id  = ${loadedItems[0].id}');
  //     notifyListeners();

  //     if (loadedItems[0].id != 'brak ')
  //       _items = loadedItems;
  //     else
  //       _items = [];
  //   } catch (error) {
  //     throw (error);
  //   }
  // }

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
