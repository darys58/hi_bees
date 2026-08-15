import 'package:flutter/material.dart';

class Apiary with ChangeNotifier {
  final String id;
  final int pasiekaNr;
  final int ileUli; //ilość uli w pasiece
  final String przeglad; //data ostatniego przelądu
  final String
      ikona; //1-zielona(ok), 2-zółta(przeznaczenie), 3-czerwona (akcja)
  final String opis; //?
  //bool isFavorite;

  Apiary({
    required this.id,
    required this.pasiekaNr,
    required this.ileUli,
    required this.przeglad,
    required this.ikona,
    required this.opis,
    //this.isFavorite = false,
  });
}
