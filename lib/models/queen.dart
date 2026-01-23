import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej

//import '../globals.dart' as globals;

class Queen with ChangeNotifier {
  final int id; //id: 
  final String data; // data pozyskania matki
  final String zrodlo; //kupiona, złapana, własna
  final String rasa; // krainka, etc
  final String linia; //Ka-Prim, etc
  final String znak; //biały, niebieski itp
  final String napis; //15, TM itp
  final String uwagi; 
  final int pasieka; //umiejscowienie
  final int ul;      //---''---
  final String dataStraty; //data straty matki
  final String a;
  final String b;
  final String c; //?
  final int arch;

  Queen({
    required this.id,
    required this.data, 
    required this.zrodlo, 
    required this.rasa, 
    required this.linia, 
    required this.znak,
    required this.napis,
    required this.uwagi,
    required this.pasieka,
    required this.ul,
    required this.dataStraty,
    required this.a,
    required this.b,
    required this.c,
    required this.arch,
  });
}

class Queens with ChangeNotifier {
  List<Queen> _items = [];

  List<Queen> get items {
    return [..._items];
  }

  //pobranie wpisów Matki z bazy lokalnej
  Future<void> fetchAndSetQueens() async {
    final dataList = await DBHelper.getQueens();
    _items = dataList
        .map(
          (item) => Queen(
            id: item['id'],
            data: item['data'],
            zrodlo: item['zrodlo'],
            rasa: item['rasa'],
            linia: item['linia'],
            znak: item['znak'],
            napis: item['napis'],
            uwagi: item['uwagi'],
            pasieka: item['pasieka'],
            ul: item['ul'],
            dataStraty: item['dataStraty'],
            a: item['a'],
            b: item['b'],
            c: item['c'],
            arch: item['arch'],
          ),
        )
        .toList();
    //print('wczytanie danych do uruchomienia apki --> Matki <---');
    //print(_items);
    notifyListeners();
  }


  //pobranie nowych wpisów w sprzedaz z bazy lokalnej do archiwizacji
  Future<void> fetchAndSetQueensToArch() async {
    final dataList = await DBHelper.getMatkiToArch();
    _items = dataList
        .map(
          (item) => Queen(
            id: item['id'],
            data: item['data'],
            zrodlo: item['zrodlo'],
            rasa: item['rasa'],
            linia: item['linia'],
            znak: item['znak'],
            napis: item['napis'],
            uwagi: item['uwagi'],
            pasieka: item['pasieka'],
            ul: item['ul'],
            dataStraty: item['dataStraty'],
            a: item['a'],
            b: item['b'],
            c: item['c'],
            arch: item['arch'],
          ),
        )
        .toList();
    //print('wczytanie wszystkich nowych matek--> Matki <---');
    //print(_items);
    notifyListeners();
  }


//pobranie matki z serwera www
  static Future<void> fetchQueensFromSerwer(String url) async {
    //const url = 'https://cobytu.com/cbt.php?d=f_dania&uz_id=&woj_id=14&mia_id=1&rest=&lang=pl';
    try {
      final response = await http.get(Uri.parse(url));
      //print(json.decode(response.body));

      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      // if (extractedData == null) {
      //   return;
      // }
      
      extractedData.forEach((matkiId, matkiData) {
        if (matkiId != 'brak') {//jezeli są wpisy a tabeli matki_xxxx
          //zapis do bazy
          DBHelper.insert('matki', {
            'id': matkiId,
            'data': matkiData['ma_data'],
            'zrodlo': matkiData['ma_zrodlo'],
            'rasa': matkiData['ma_rasa'],
            'linia': matkiData['ma_linia'],
            'znak': matkiData['ma_znak'],
            'napis': matkiData['ma_napis'],
            'uwagi': matkiData['ma_uwagi'],
            'pasieka': matkiData['ma_pasieka'],
            'ul': matkiData['ma_ul'],
            'dataStraty': matkiData['ma_dataStraty'],
            'a': matkiData['ma_a'],
            'b': matkiData['ma_b'],
            'c': matkiData['ma_c'],
            'arch': 2,
          });
        }
      });
    } catch (error) {
      throw (error);
    }
  }



  //dodawnie matki do bazy lokalnej
  static Future<void> insertQueen(
    //String id,
    String data,
    String zrodlo,
    String rasa,
    String linia,
    String znak,
    String napis,
    String uwagi,
    int pasieka,
    int ul,
    String dataStraty,
    String a,
    String b,
    String c,
    String arch, //arch
  ) async {
    await DBHelper.insert('matki', {
      //'id': id,
      'data': data,
      'zrodlo': zrodlo,
      'rasa': rasa,
      'linia': linia,
      'znak': znak,
      'napis': napis,
      'uwagi': uwagi,
      'pasieka': pasieka,
      'ul': ul,
      'dataStraty': dataStraty,
      'a': a,
      'b': b,
      'c': c,
      'arch': arch,
    });
  }

  //edycja (nadpisanie) matki w bazie lokalnej
  static Future<void> editQueen(
    int id,
    String data,
    String zrodlo,
    String rasa,
    String linia,
    String znak,
    String napis,
    String uwagi,
    int pasieka,
    int ul,
    String dataStraty,
    String a,
    String b,
    String c,
    String arch, //arch
  ) async {
    await DBHelper.insert('matki', {
      'id': id,
      'data': data,
      'zrodlo': zrodlo,
      'rasa': rasa,
      'linia': linia,
      'znak': znak,
      'napis': napis,
      'uwagi': uwagi,
      'pasieka': pasieka,
      'ul': ul,
      'dataStraty': dataStraty,
      'a': a,
      'b': b,
      'c': c,
      'arch': arch,
    });
  }
}
