import 'package:flutter/foundation.dart';

class Hive with ChangeNotifier {
  final String id;
  final int pasiekaNr;
  final int ulNr;
  final String przeglad; //ostatnia data przelądu
  final String ikona; //1-zielona(ok), 2-zółta(przeznaczenie), 3-czerwona (akcja)
  final String opis; //?
  //bool isFavorite;

  Hive({
    required this.id,
    required this.pasiekaNr,
    required this.ulNr,
    required this.przeglad,
    required this.ikona,
    required this.opis,
    //this.isFavorite = false,
  });

  // void toggleFavoriteStatus() {
  //   isFavorite = !isFavorite;
  //   notifyListeners();
  // }
}
