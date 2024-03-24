import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej

import '../globals.dart' as globals;

class MemoryItem with ChangeNotifier {
  final String id; //be_id: String
  final String email; //be_email: String
  final String dev; //be_dev: String  device
  final String wer; //wersja apki
  final String kod; //be_kod: String kod hi_bees
  final String key; //be_key: String key picovoice
  final String dod; //be_od: String  data od
  final String ddo; //be_do: String  data do
  final String memjezyk; //ustawienie jezyka w Ustawienia/Jezyk w apce
  final String mem1; //na zapas
  final String mem2; //na zapas

  MemoryItem({
    required this.id,
    required this.email,
    required this.dev,
    required this.wer,
    required this.kod,
    required this.key,
    required this.dod,
    required this.ddo,
    required this.memjezyk,
    required this.mem1,
    required this.mem2,
  });
}

class Memory with ChangeNotifier {
  List<MemoryItem> _items = [];

  List<MemoryItem> get items {
    return [..._items];
  }

  //pobranie wpisów memory z bazy lokalnej
  Future<void> fetchAndSetMemory(device) async {
    final dataList = await DBHelper.getMem(device);
    _items = dataList
        .map(
          (item) => MemoryItem(
            id: item['id'],
            email: item['email'],
            dev: item['dev'],
            wer: item['wer'],
            kod: item['kod'],
            key: item['key'],
            dod: item['od'],
            ddo: item['do'],
            memjezyk: item['memjezyk'],
            mem1: item['mem1'],
            mem2: item['mem2'],
          ),
        )
        .toList();
    print('wczytanie danych do uruchomienia apki --> Memory <---');
    print(_items);
    notifyListeners();
  }


  //pobranie danych z serwera www
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
  static Future<void> insertMemory(
    String id,
    String email,
    String dev,
    String wer,
    String kod,
    String key,
    String dod,
    String ddo,
    String memjezyk,
    String mem1,
    String mem2,
  ) async {
    await DBHelper.insert('memory', {
      'id': id,
      'email': email,
      'dev': dev,
      'wer': wer,
      'kod': kod,
      'key': key,
      'od': dod,
      'do': ddo,
      'memjezyk': memjezyk,
      'mem1': mem1,
      'mem2': mem2,
    });
  }
}
