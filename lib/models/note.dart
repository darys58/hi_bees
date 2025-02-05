import 'dart:convert'; //obsługa json'a
import 'package:flutter/material.dart';
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej
import 'package:http/http.dart' as http;

class Note with ChangeNotifier {
  final int id; //autoincrement
  final String data; //
  final String tytul; //
  final int pasiekaNr; //
  final int ulNr; //
  final String notatka; //
  final int status; //
  final String priorytet; //
  final String uwagi; //
  final int
      arch; //0-niezarchiwizowane, 1-przesłane do chmury, 2-zaimportowane z chmury

  Note({
    required this.id,
    required this.data,
    required this.tytul,
    required this.pasiekaNr,
    required this.ulNr,
    required this.notatka,
    required this.status,
    required this.priorytet,
    required this.uwagi,
    required this.arch,
  });
}

class Notes with ChangeNotifier {
  List<Note> _items = [];

  List<Note> get items {
    return [..._items];
  }

 

  //pobranie notatek z serwera www
  static Future<void> fetchNotatkiFromSerwer(String url) async {
    //const url = 'https://cobytu.com/cbt.php?d=f_dania&uz_id=&woj_id=14&mia_id=1&rest=&lang=pl';
    try {
      final response = await http.get(Uri.parse(url));
      //print(json.decode(response.body));

      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      // if (extractedData == null) {
      //   return;
      // }

      extractedData.forEach((notatkiId, notatkiData) {
        if (notatkiId != 'brak') {  //jezeli są wpisy a tabeli notatki_xxxx
          //zapis do bazy
          DBHelper.insert('notatki', {
            'id': notatkiId,
            'data': notatkiData['no_data'],
            'tytul': notatkiData['no_tytul'],
            'pasiekaNr': notatkiData['no_pasiekaNr'],
            'ulNr': notatkiData['no_ulNr'],
            'notatka': notatkiData['no_notatka'],
            'status': notatkiData['no_status'],
            'priorytet': notatkiData['no_priorytet'],
            'uwagi': notatkiData['no_uwagi'],
            'arch': 2,
          });
        }
      });
    } catch (error) {
      throw (error);
    }
  }


  //pobranie wpisów notatki z bazy lokalnej
  Future<void> fetchAndSetNotatki() async {
    final dataList = await DBHelper.getNotatki();
    _items = dataList
        .map(
          (item) => Note(
            id: item['id'],
            data: item['data'],
            tytul: item['tytul'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            notatka: item['notatka'],
            status: item['status'],
            priorytet: item['priorytet'],
            uwagi: item['uwagi'],
            arch: item['arch'],
          ),
        )
        .toList();
    //print('wczytanie danych do uruchomienia apki --> Notatki <---');
    //print(_items);
    notifyListeners();
  }

  //pobranie wpisów notatki z bazy lokalnej - odwrotny sort dla apiary_screen
  Future<void> fetchAndSetNotatkiASC() async {
    final dataList = await DBHelper.getNotatkiASC();
    _items = dataList
        .map(
          (item) => Note(
            id: item['id'],
            data: item['data'],
            tytul: item['tytul'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            notatka: item['notatka'],
            status: item['status'],
            priorytet: item['priorytet'],
            uwagi: item['uwagi'],
            arch: item['arch'],
          ),
        )
        .toList();
    //print('wczytanie danych do uruchomienia apki --> Notatki ASC <---');
    //print(_items);
    notifyListeners();
  }

  //pobranie nowych wpisów w notatki z bazy lokalnej do archiwizacji
  Future<void> fetchAndSetNotatkiToArch() async {
    final dataList = await DBHelper.getNotatkiToArch();
    _items = dataList
        .map(
          (item) => Note(
            id: item['id'],
            data: item['data'],
            tytul: item['tytul'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            notatka: item['notatka'],
            status: item['status'],
            priorytet: item['priorytet'],
            uwagi: item['uwagi'],
            arch: item['arch'],
          ),
        )
        .toList();
    //('wczytanie wszystkich nowych zbiorów --> NotatkiToArch <---');
    //print(_items);
    notifyListeners();
  }

  //zapisanie danych do bazy lokalnej
  static Future<void> insertNotatki(
    // String id,
    String data,
    String tytul,
    int pasiekaNr,
    int ulNr,
    String notatka,
    int status,
    String priorytet,
    String uwagi,
    int arch,
  ) async {
    await DBHelper.insert('notatki', {
      // 'id': id,
      'data': data,
      'tytul': tytul,
      'pasiekaNr': pasiekaNr,
      'ulNr': ulNr,
      'notatka': notatka,
      'status': status,
      'priorytet': priorytet,
      'uwagi': uwagi,
      'arch': arch,
    });
  }
}
