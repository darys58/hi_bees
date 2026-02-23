import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../helpers/db_helper.dart';

class Photo with ChangeNotifier {
  final String id;
  final String data;
  final String czas;
  final int pasiekaNr;
  final int ulNr;
  final String sciezka;
  final String uwagi;
  final int arch;

  Photo({
    required this.id,
    required this.data,
    required this.czas,
    required this.pasiekaNr,
    required this.ulNr,
    required this.sciezka,
    required this.uwagi,
    required this.arch,
  });
}

class Photos with ChangeNotifier {
  List<Photo> _items = [];

  List<Photo> get items {
    return [..._items];
  }

  //pobranie zdjęć dla danego ula z bazy lokalnej
  Future<void> fetchAndSetPhotosForHive(int pasieka, int ul) async {
    final dataList = await DBHelper.getPhotosOfHive(pasieka, ul);
    _items = dataList
        .map(
          (item) => Photo(
            id: item['id'],
            data: item['data'],
            czas: item['czas'] ?? '',
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            sciezka: item['sciezka'],
            uwagi: item['uwagi'] ?? '',
            arch: item['arch'] ?? 0,
          ),
        )
        .toList();
    notifyListeners();
  }

  //pobranie wpisów zdjęć z bazy lokalnej
  Future<void> fetchAndSetPhotos() async {
    final dataList = await DBHelper.getZdjecia();
    _items = dataList
        .map(
           (item) => Photo(
            id: item['id'],
            data: item['data'],
            czas: item['czas'] ?? '',
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            sciezka: item['sciezka'],
            uwagi: item['uwagi'] ?? '',
            arch: item['arch'] ?? 0,
          ),
        )
        .toList();
    //print('wczytanie danych do uruchomienia apki --> Zakupy <---');
    //print(_items);
    notifyListeners();
  }

  //pobranie nowych zdjęć z bazy lokalnej do archiwizacji
  Future<void> fetchAndSetPhotosToArch() async {
    final dataList = await DBHelper.getPhotosToArch();
    _items = dataList
        .map(
          (item) => Photo(
            id: item['id'],
            data: item['data'],
            czas: item['czas'] ?? '',
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            sciezka: item['sciezka'],
            uwagi: item['uwagi'] ?? '',
            arch: item['arch'] ?? 0,
          ),
        )
        .toList();
    notifyListeners();
  }

  //import zdjęć z serwera
  static Future<void> fetchZdjeciaFromSerwer(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      //serwer moze zwrócić dodatkowy tekst po JSON np. {"brak":"brak"}Nie ma nic do wyswietlenia...
      //wycinamy sam JSON z odpowiedzi
      String body = response.body.trim();
      final jsonEnd = body.lastIndexOf('}');
      if (jsonEnd != -1 && jsonEnd < body.length - 1) {
        body = body.substring(0, jsonEnd + 1);
      }

      final extractedData = json.decode(body) as Map<String, dynamic>;

      //jezeli serwer zwrócił "brak" to nie ma zdjęć do importu
      if (extractedData.containsKey('brak')) return;

      //tworzenie katalogu dla zdjęć jesli nie ma
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      for (final entry in extractedData.entries) {
        final zdjeciaId = entry.key;
        final zdjeciaData = entry.value;
          //dekodowanie Base64 i zapis pliku
          final String sciezka;
          if (zdjeciaData['zd_base64'] != null && zdjeciaData['zd_base64'] != '') {
            final bytes = base64Decode(zdjeciaData['zd_base64']);
            final fileName = zdjeciaData['zd_sciezka'] ?? '${zdjeciaId}.jpg';
            //wyciągnięcie samej nazwy pliku ze ścieżki
            final bareFileName = fileName.split('/').last;
            final filePath = '${photosDir.path}/$bareFileName';
            await File(filePath).writeAsBytes(bytes);
            sciezka = filePath;
          } else {
            sciezka = zdjeciaData['zd_sciezka'] ?? '';
          }

          await DBHelper.insert('zdjecia', {
            'id': zdjeciaId,
            'data': zdjeciaData['zd_data'],
            'czas': zdjeciaData['zd_czas'] ?? '',
            'pasiekaNr': zdjeciaData['zd_pasiekaNr'],
            'ulNr': zdjeciaData['zd_ulNr'],
            'sciezka': sciezka,
            'uwagi': zdjeciaData['zd_uwagi'] ?? '',
            'arch': 2,
          });
      }
    } catch (error) {
      throw (error);
    }
  }

  //zapisanie zdjęcia do bazy lokalnej
  static Future<void> insertPhoto(
      String id,
      String data,
      String czas,
      int pasieka,
      int ul,
      String sciezka,
      String uwagi,
      int arch) async {
    await DBHelper.insert('zdjecia', {
      'id': id,
      'data': data,
      'czas': czas,
      'pasiekaNr': pasieka,
      'ulNr': ul,
      'sciezka': sciezka,
      'uwagi': uwagi,
      'arch': arch,
    });
  }

  //usunięcie zdjęcia z bazy lokalnej
  static Future<void> deletePhoto(String id) async {
    await DBHelper.deletePhoto(id);
  }
}
