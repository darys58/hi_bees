import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert'; //obsługa json'a
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej

//import '../globals.dart' as globals;

class Dodatki2Item with ChangeNotifier {
  final String id; //id:1 
  final String m; //TYP A
  final String n; //nazwa własna ula
  final String s; //szerokość wewnętrzna ramka duza
  final String t; //wysokość wewnętrzna ramka duza
  final String u; //powierzchnia wnętrza ramki w mm2 (plastra)
  final String v; //szerokość wewnętrzna ramka mała
  final String w; //wysokość wewnętrzna ramka mała
  final String z; //powierzchnia wnętrza ramki w mm2 (plastra)

  Dodatki2Item({
    required this.id,
    required this.m, 
    required this.n, 
    required this.s, 
    required this.t, 
    required this.u,
    required this.v,
    required this.w,
    required this.z,
  });
}

class Dodatki2 with ChangeNotifier {
  List<Dodatki2Item> _items = [];

  List<Dodatki2Item> get items {
    return [..._items];
  }

  //pobranie wpisów dodatki1 z bazy lokalnej
  Future<void> fetchAndSetDodatki2() async {
    final dataList = await DBHelper.getDodatki2();
    _items = dataList
        .map(
          (item) => Dodatki2Item(
            id: item['id'],
            m: item['m'],
            n: item['n'],
            s: item['s'],
            t: item['t'],
            u: item['u'],
            v: item['v'],
            w: item['w'],
            z: item['z'],
          ),
        )
        .toList();
    //print('wczytanie danych do uruchomienia apki --> Dodatki1 <---');
    //print(_items);
    notifyListeners();
  }


  //zapisanie danych do bazy lokalnej
  static Future<void> insertDodatki2(
    String id,
    String m,
    String n,
    String s,
    String t,
    String u,
    String v,
    String w,
    String z,
  ) async {
    await DBHelper.insert('dodatki2', {
      'id': id,
      'm': m,
      'n': n,
      's': s,
      't': t,
      'u': u,
      'v': v,
      'w': w,
      'z': z,
    });
  }
}
