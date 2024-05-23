import 'package:flutter/foundation.dart';

class Hive with ChangeNotifier {
  final String id;
  final int pasiekaNr;
  final int ulNr;
  final String przeglad; //ostatnia data przelądu
  final String
      ikona; //1-zielona(ok), 2-zółta(przeznaczenie), 3-czerwona (brak matki ?)
  final int ramek; // ilość ramek
  final int korpusNr;
  final int trut;
  final int czerw;
  final int larwy;
  final int jaja;
  final int pierzga;
  final int miod;
  final int dojrzaly;
  final int weza;
  final int susz;
  final int matka;
  final int mateczniki;
  final int usunmat;
  final String todo;
  final String kategoria;
  final String parametr;
  final String wartosc;
  final String miara;
  final String matka1;
  final String matka2;
  final String matka3;
  final String matka4;
  final String matka5;
  final String h1; //zapas 1
  final String h2; //zapas 2
  final String h3; //zapas 3
  final int aktual; //0-dane aktualne lub stan po wczytaniu danych z chmury 1-nieaktualne zasoby, 

  //bool isFavorite;

  Hive({
    required this.id,
    required this.pasiekaNr,
    required this.ulNr,
    required this.przeglad,
    required this.ikona,
    required this.ramek,
    required this.korpusNr,
    required this.trut,
    required this.czerw,
    required this.larwy,
    required this.jaja,
    required this.pierzga,
    required this.miod,
    required this.dojrzaly,
    required this.weza,
    required this.susz,
    required this.matka,
    required this.mateczniki,
    required this.usunmat,
    required this.todo,
    required this.kategoria,
    required this.parametr,
    required this.wartosc,
    required this.miara,
    required this.matka1,
    required this.matka2,
    required this.matka3,
    required this.matka4,
    required this.matka5,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.aktual,
    //this.isFavorite = false,
  });

  // void toggleFavoriteStatus() {
  //   isFavorite = !isFavorite;
  //   notifyListeners();
  // }
}
