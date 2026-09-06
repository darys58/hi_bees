import 'package:flutter/foundation.dart';

class Info with ChangeNotifier {
  final String id;// $formattedDate.$nrXXOfApiary.${hives[i].ulNr}.$kat.$param', 
  final String data;
  final int pasiekaNr;
  final int ulNr;
  final String kategoria; //karmienie, leczenie, matka, wyposazenie
  final String parametr; //
  final String wartosc; //
  final String miara;
  final String pogoda; //ikona pogody
  final String temp; //temperatura
  final String czas;
  final String uwagi;
  final int arch;


  Info({
    required this.id,
    required this.data,
    required this.pasiekaNr,
    required this.ulNr,
    required this.kategoria,
    required this.parametr,
    required this.wartosc,
    required this.miara,
    required this.pogoda,
    required this.temp,
    required this.czas,
    required this.uwagi,
    required this.arch,
  });

  /// Wiersz z tabeli `info` (surowa mapa z sqflite) na obiekt.
  /// Potrzebne tam, gdzie czytamy `info` POZA providerem Infos - ten trzyma
  /// wpisy jednego ula, a cechy matki trzeba czasem znaleźć w ulu POPRZEDNIM
  /// (patrz przenoszenie cech po przełożeniu matki, `infos_screen`
  /// i `hives_screen`).
  factory Info.fromMap(Map<String, dynamic> item) => Info(
        id: item['id'],
        data: item['data'],
        pasiekaNr: item['pasiekaNr'],
        ulNr: item['ulNr'],
        kategoria: item['kategoria'],
        parametr: item['parametr'],
        wartosc: item['wartosc'],
        miara: item['miara'],
        pogoda: item['pogoda'],
        temp: item['temp'],
        czas: item['czas'],
        uwagi: item['uwagi'],
        arch: item['arch'],
      );
}
