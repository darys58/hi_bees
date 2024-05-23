import 'package:flutter/material.dart';

class Weather with ChangeNotifier {
  final String id; //id pasieki
  final String miasto;//nazwa maiasta
  final String latitude; //szerokość geograficzna
  final String longitude; //długość geograficzna
  final String pobranie; //data i czas pobrania pogody
  final String temp; //temperatura
  final String weatherId; //id wyniku pogody
  final String icon; //ikona pogody
  final int units; //1-metric - Celsiusz, 2-standard - Kelvin, 3-Fahrenheit - imperial
  final String lang; //język opcjonalnie
  final String inne; //zapasowe
  
  Weather({
    required this.id,
    required this.miasto,
    required this.latitude,
    required this.longitude,
    required this.pobranie,
    required this.temp,
    required this.weatherId,
    required this.icon,
    required this.units,
    required this.lang,
    required this.inne,  
  });
}
