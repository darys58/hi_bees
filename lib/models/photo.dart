import 'package:flutter/foundation.dart';
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
