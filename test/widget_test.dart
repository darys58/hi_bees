// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hi_bees/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget( MyApp()); //const

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
/*
I/flutter (24197): DBHelper - pobieranie dodatki 1 
I/flutter (24197): wczytanie danych do uruchomienia apki --> Dodatki1 <---  na poczatku skryptu
I/flutter (24197): [Instance of 'Dodatki1Item']

I/flutter (24197): DBHelper - pobieranie notatek
I/flutter (24197): DBHelper - pobieranie zakupy
I/flutter (24197): DBHelper - pobieranie sprzedaz
I/flutter (24197): DBHelper - pobieranie zbiory
I/flutter (24197): DBHelper - pobieranie z tabeli info
I/flutter (24197): DBHelper - pobieranie z tabeli ramka


I/flutter (24197): wczytanie danych do uruchomienia apki --> Zbiory <--- wczytanie notatek


I/flutter (24197): [Instance of 'Note', Instance of 'Note', Instance of 'Note', Instance of 'Note', Instance of 'Note', Instance of 'Note', Instance of 'Note', Instance of 'Note', Instance of 'Note', Instance of 'Note', Instance of 'Note', Instance of 'Note', Instance of 'Note']
I/flutter (24197): {"notatki":[{"id": "20","data": "2024-05-05","tytul": "Akacja","pasiekaNr": 0,"ulNr": 0,"notatka": "Zakwitła u Nowaka 22 st.C","status": 0,"priorytet": "false","uwagi": "","arch": 2},{"id": "19","data": "2024-04-26","tytul": "Głóg","pasiekaNr": 0,"ulNr": 0,"notatka": "Zakwitł na łące","status": 0,"priorytet": "false","uwagi": "","arch": 2},{"id": "18","data": "2024-04-14","tytul": "Bez","pasiekaNr": 0,"ulNr": 0,"notatka": "z Pabianic zakwitł","status": 0,"priorytet": "false","uwagi": "","arch": 2},{"id": "14","data": "2024-04-09","tytul": "Atak wiosny","pasiekaNr": 0,"ulNr": 0,"notatka": "Zakładanie krat i półnadstawek, ule zalewane nakropem, dzikie zabudowy w ulach","status": 0,"priorytet": "false","uwagi": "","arch": 2},{"id": "13","data": "2024-04-08","tytul": "Rzepak i mniszek","pasiekaNr": 0,"ulNr": 0,"notatka": "Początek kwitnienia 27 st.C","status": 0,"priorytet": "false","uwagi": "","arch": 2},{"id": "12","data": "2024-04-06","tytul": "Drzewa owocowe","pasiekaNr": 0,"ulNr": 0,"notatka": "�

I/flutter (24197): wczytanie danych do uruchomienia apki --> Zakupy <---
I/flutter (24197): [Instance of 'Purchase', Instance of 'Purchase', Instance of 'Purchase', Instance of 'Purchase', Instance of 'Purchase', Instance of 'Purchase', Instance of 'Purchase']
I/flutter (24197): {"zakupy":[{"id": "7","data": "2024-05-16","pasiekaNr": 1,"nazwa": "Węza 2,5kg","kategoriaId": 6,"ilosc": 1.0,"miara": 1,"cena": 193.99,"wartosc": 193.99,"waluta": 1,"uwagi": "185,00 od pasieka-jurajska","arch": 1},{"id": "5","data": "2024-02-27","pasiekaNr": 1,"nazwa": "Słoik 0,9 l","kategoriaId": 2,"ilosc": 344.0,"miara": 1,"cena": 1.0,"wartosc": 550.0,"waluta": 1,"uwagi": "pakowane po 8 szt / po 12,80 zł, Tarnowo P. tel: 7","arch": 2},{"id": "6","data": "2024-02-27","pasiekaNr": 1,"nazwa": "Rękawice długie","kategoriaId": 3,"ilosc": 1.0,"miara": 1,"cena": 41.0,"wartosc": 41.0,"waluta": 1,"uwagi": "rozmiar 11, Tarnowo P.","arch": 2},{"id": "4","data": "2024-02-03","pasiekaNr": 1,"nazwa": "Zmiotka mała","kategoriaId": 3,"ilosc": 1.0,"miara": 1,"cena": 12.0,"wartosc": 12.0,"waluta": 1,"uwagi": "Łysoń, Tarnowo Podgórne, Poznańska 157","arch": 2},{"id": "2","data": "2024-02-02","pasiekaNr": 1,"nazwa": "Nakrętka Q82/6 metalowa","kategoriaId": 2,"ilosc": 400.0,"miara": 1,"cena": 0.0,"wartosc": 0.0,"wa
I/flutter (24197): Connected to WiFi
I/flutter (24197): wczytanie danych do uruchomienia apki --> Sprzedaz <---
I/flutter (24197): [Instance of 'Sale', Insta

I/flutter (24197): {"notatki":[{"id": "20","data": "2024-05-05","tytul": "Akacja","pasiekaNr": 0,"ulNr": 0,"notatka": "Zakwitła u Nowaka 22 st.C","status": 0,"priorytet": "false","uwagi": "","arch": 2},{"id": "19","data": "2024-04-26","tytul": "Głóg","pasiekaNr": 0,"ulNr": 0,"notatka": "Zakwitł na łące","status": 0,"priorytet": "false","uwagi": "","arch": 2},{"id": "18","data": "2024-04-14","tytul": "Bez","pasiekaNr": 0,"ulNr": 0,"notatka": "z Pabianic zakwitł","status": 0,"priorytet": "false","uwagi": "","arch": 2},{"id": "14","data": "2024-04-09","tytul": "Atak wiosny","pasiekaNr": 0,"ulNr": 0,"notatka": "Zakładanie krat i półnadstawek, ule zalewane nakropem, dzikie zabudowy w ulach","status": 0,"priorytet": "false","uwagi": "","arch": 2},{"id": "13","data": "2024-04-08","tytul": "Rzepak i mniszek","pasiekaNr": 0,"ulNr": 0,"notatka": "Początek kwitnienia 27 st.C","status": 0,"priorytet": "false","uwagi": "","arch": 2},{"id": "12","data": "2024-04-06","tytul": "Drzewa owocowe","pasiekaNr": 0,"ulNr": 0,"notatka": "�
I/flutter (24197): wczytanie danych do uruchomienia apki --> Zakupy <---
I/flutter (24197): [Instance of 'Purchase', Instance of 'Purchase', Instance of 'Purchase', Instance of 'Purchase', Instance of 'Purchase', Instance of 'Purchase', Instance of 'Purchase']
I/flutter (24197): {"zakupy":[{"id": "7","data": "2024-05-16","pasiekaNr": 1,"nazwa": "Węza 2,5kg","kategoriaId": 6,"ilosc": 1.0,"miara": 1,"cena": 193.99,"wartosc": 193.99,"waluta": 1,"uwagi": "185,00 od pasieka-jurajska","arch": 1},{"id": "5","data": "2024-02-27","pasiekaNr": 1,"nazwa": "Słoik 0,9 l","kategoriaId": 2,"ilosc": 344.0,"miara": 1,"cena": 1.0,"wartosc": 550.0,"waluta": 1,"uwagi": "pakowane po 8 szt / po 12,80 zł, Tarnowo P. tel: 7","arch": 2},{"id": "6","data": "2024-02-27","pasiekaNr": 1,"nazwa": "Rękawice długie","kategoriaId": 3,"ilosc": 1.0,"miara": 1,"cena": 41.0,"wartosc": 41.0,"waluta": 1,"uwagi": "rozmiar 11, Tarnowo P.","arch": 2},{"id": "4","data": "2024-02-03","pasiekaNr": 1,"nazwa": "Zmiotka mała","kategoriaId": 3,"ilosc": 1.0,"miara": 1,"cena": 12.0,"wartosc": 12.0,"waluta": 1,"uwagi": "Łysoń, Tarnowo Podgórne, Poznańska 157","arch": 2},{"id": "2","data": "2024-02-02","pasiekaNr": 1,"nazwa": "Nakrętka Q82/6 metalowa","kategoriaId": 2,"ilosc": 400.0,"miara": 1,"cena": 0.0,"wartosc": 0.0,"wa
I/flutter (24197): Connected to WiFi
I/flutter (24197): wczytanie danych do uruchomienia apki --> Sprzedaz <---
I/flutter (24197): [Instance of 'Sale', Instance of 'Sale', Instance of 'Sale', Instance of 'Sale', Instance of 'Sale', Instance of 'Sale']
I/flutter (24197): {"sprzedaz":[{"id": "4","data": "2024-05-16","pasiekaNr": 1,"nazwa": "wiosenny","kategoriaId": 1,"ilosc": 9.0,"miara": 2,"cena": 40.0,"wartosc": 360.0,"waluta": 1,"uwagi": "od Eli","arch": 1},{"id": "5","data": "2024-05-16","pasiekaNr": 1,"nazwa": "wiosenny","kategoriaId": 1,"ilosc": 2.0,"miara": 3,"cena": 35.0,"wartosc": 70.0,"waluta": 1,"uwagi": "od Eli","arch": 1},{"id": "6","data": "2024-05-16","pasiekaNr": 1,"nazwa": "wiosenny","kategoriaId": 2,"ilosc": 1.0,"miara": 2,"cena": 50.0,"wartosc": 50.0,"waluta": 1,"uwagi": "od Eli","arch": 1},{"id": "1","data": "2024-05-14","pasiekaNr": 1,"nazwa": "wiosenny","kategoriaId": 1,"ilosc": 2.0,"miara": 2,"cena": 40.0,"wartosc": 80.0,"waluta": 1,"uwagi": "Marcin Ł.","arch": 2},{"id": "2","data": "2024-05-14","pasiekaNr": 1,"nazwa": "wiosenny","kategoriaId": 1,"ilosc": 1.0,"miara": 2,"cena": 40.0,"wartosc": 40.0,"waluta": 1,"uwagi": "Aneta B.","arch": 2},{"id": "3","data": "2024-05-14","pasiekaNr": 1,"nazwa": "wiosenny","kategoriaId": 1,"ilosc": 2.0,"miara": 2,"cena
2
I/flutter (24197): Connected to WiFi
I/flutter (24197): wczytanie danych do uruchomienia apki --> Zbiory <---
I/flutter (24197): [Instance of 'Harvest', Instance of 'Harvest', Instance of 'Harvest', Instance of 'Harvest', Instance of 'Harvest', Instance of 'Harvest', Instance of 'Harvest', Instance of 'Harvest', Instance of 'Harvest', Instance of 'Harvest', Instance of 'Harvest']
I/flutter (24197): {"zbiory":[{"id": "11","data": "2024-05-11","pasiekaNr": 1,"zasobId": 1,"ilosc": "80.0","miara": "1","uwagi": "Pierwsze miodobranie, wiosenny","g": "","h": "","arch": 2},{"id": "10","data": "2024-05-05","pasiekaNr": 1,"zasobId": 2,"ilosc": "2.7","miara": "1","uwagi": "3 dni z wszystkich uli","g": "","h": "","arch": 2},{"id": "9","data": "2024-05-01","pasiekaNr": 1,"zasobId": 2,"ilosc": "3.25","miara": "1","uwagi": "przez 3 dni z 10 uli","g": "","h": "","arch": 2},{"id": "8","data": "2024-04-01","pasiekaNr": 1,"zasobId": 2,"ilosc": "1.2","miara": "1","uwagi": "przez 3 dni","g": "","h": "","arch": 2},{"id": "6","data": "2023-12-01","pasiekaNr": 1,"zasobId": 4,"ilosc": "10.6","miara": "2","uwagi": "klarowany","g": "","h": "","arch": 2},{"id": "7","data": "2023-08-31","pasiekaNr": 1,"zasobId": 2,"ilosc": "8.0","miara": "1","uwagi": "około","g": "","h": "","arch": 2},{"id": "5","data": "2023-08-12","pasiekaNr": 1,"zasobId": 1,"ilosc": "45.0","miara": "1","uwagi": "późnoletni ? resztki nawłoć? ciemny","g": ""
I/flutter (24197): Connected to WiFi
I/flutter (24197): wczytanie wszystkich!!!!!!! informacji --> Infos <---
I/flutter (24197): 818



I/flutter (24197): {"info":[{"id": "2023-04-01.1.14.queen. queen is","data": "2023-04-01","pasiekaNr": 1,"ulNr": 14,"kategoria": "queen","parametr": " queen is","wartosc": "unmarked","miara": "","miara": "","pogoda": "","temp": "","czas": "11:03","arch": 2},{"id": "2023-04-01.1.14.queen.queen is ","data": "2023-04-01","pasiekaNr": 1,"ulNr": 14,"kategoria": "queen","parametr": "queen is ","wartosc": "good","miara": "","miara": "","pogoda": "","temp": "","czas": "11:03","arch": 2},{"id": "2023-04-01.1.15.queen. queen is","data": "2023-04-01","pasiekaNr": 1,"ulNr": 15,"kategoria": "queen","parametr": " queen is","wartosc": "marked","miara": "","miara": "","pogoda": "","temp": "","czas": "11:03","arch": 2},{"id": "2023-04-01.1.15.queen.queen is ","data": "2023-04-01","pasiekaNr": 1,"ulNr": 15,"kategoria": "queen","parametr": "queen is ","wartosc": "good","miara": "","miara": "","pogoda": "","temp": "","czas": "11:03","arch": 2},{"id": "2023-04-01.1.6.queen. queen is","data": "2023-04-01","pasiekaNr": 1,"ulNr": 6,"kategoria": "quee
I/flutter (24197): wczytanie wszystkich!!!!!!! danych o ramkach --> Frames <---
I/flutter (24197): {"ramka":[{"id": "2024-05-11.1.12.3.1.1.1.6","data": "2024-05-11","pasiekaNr": 1,"ulNr": 12,"korpusNr": 3,"typ": 1,"ramkaNr": 1,"ramkaNrPo": 1,"rozmiar": 1,"strona": 1,"zasob": 6,"wartosc": "30%","arch": 1},{"id": "2024-05-11.1.12.3.1.1.2.6","data": "2024-05-11","pasiekaNr": 1,"ulNr": 12,"korpusNr": 3,"typ": 1,"ramkaNr": 1,"ramkaNrPo": 1,"rozmiar": 1,"strona": 2,"zasob": 6,"wartosc": "60%","arch": 1},{"id": "2024-05-11.1.12.3.2.0.1.6","data": "2024-05-11","pasiekaNr": 1,"ulNr": 12,"korpusNr": 3,"typ": 1,"ramkaNr": 2,"ramkaNrPo": 0,"rozmiar": 1,"strona": 1,"zasob": 6,"wartosc": "90%","arch": 1},{"id": "2024-05-11.1.12.3.2.0.2.6","data": "2024-05-11","pasiekaNr": 1,"ulNr": 12,"korpusNr": 3,"typ": 1,"ramkaNr": 2,"ramkaNrPo": 0,"rozmiar": 1,"strona": 2,"zasob": 6,"wartosc": "90%","arch": 1},{"id": "2024-05-11.1.12.3.2.0.2.7","data": "2024-05-11","pasiekaNr": 1,"ulNr": 12,"korpusNr": 3,"typ": 1,"ramkaNr": 2,"ramkaNrPo": 0,"rozmiar": 1,"strona": 2,"zasob": 7,"wartosc": "5%","arch": 1},{"id": "2024-05-11.1.12.3.3.0
2
I/flutter (24197): Connected to WiFi
I/flutter (24197): true - jest internet
I/flutter (24197): response.body:
I/flutter (24197): {"success":"ok"}
I/flutter (24197): DBHelper - pobieranie tabeli notatki do achiwizacji
I/flutter (24197): wczytanie wszystkich nowych zbiorów --> Zbiory <---
I/flutter (24197): response.body:
I/flutter (24197): {"success":"ok"}
I/flutter (24197): DBHelper - pobieranie tabeli zbiory do achiwizacji
I/flutter (24197): response.body:
I/flutter (24197): {"success":"ok"}
I/flutter (24197): DBHelper - pobieranie tabeli sprzedaz do achiwizacji
I/flutter (24197): response.body:
I/flutter (24197): {"success":"ok"}

I/flutter (24197): DBHelper - pobieranie tabeli zakupy do achiwizacji
I/flutter (24197): wczytanie wszystkich nowych zbiorów --> Zbiory <---
I/flutter (24197): wczytanie wszystkich nowych sprzedaz --> Sprzedaz <---
I/flutter (24197): wczytanie wszystkich nowych zakupy --> Zakupy <---
I/flutter (24197): response.body:
I/flutter (24197): {"success":"ok"}
I/flutter (24197): DBHelper - pobieranie ramek do achiwizacji
I/flutter (24197): wczytanie nowych danych o ramkach do archiwizacji ---> Frames <---
I/flutter (24197): response.body:
I/flutter (24197): {"success":"ok"}
I/flutter (24197): DBHelper - pobieranie info do achiwizacji
I/flutter (24197): wczytanie wszystkich nowych informacji --> Infos <---
*/