//dane dań
//import 'dart:convert'; //obsługa json'a
import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
import '../helpers/db_helper.dart'; //dostęp do bazy lokalnej
import './frame.dart';

class Frames with ChangeNotifier {
  //klasa Meals jest zmiksowana z klasą ChangeNotifier która pozwala ustalać tunele komunikacyjne przy pomocy obiektu context
  List<Frame> _items =
      []; //lista wpisów, dostępna tylko wewnątrz tej klasy, będzie się zmieniać, podkreślenie oznacza ze jest to wartość prywatna klasy

  List<Frame> get items {
    //getter który zwraca kopię zmiennej _items
    return [..._items]; //... - operator rozprzestrzeniania
  }

  //metoda szukająca dania o danym id - przeniesiona z meal_detail_screen.dart
  // Frame findById(String id) {
  //   return _items.firstWhere((ml) => ml.id ==  id);
  // }

  /* 
  //pobranie bazy dań z serwera www
  static Future<void> fetchMealsFromSerwer(String url) async {
    //const url = 'https://cobytu.com/cbt.php?d=f_dania&uz_id=&woj_id=14&mia_id=1&rest=&lang=pl';
    try {
      final response = await http.get(url);
      print(json.decode(response.body));
    
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      
      extractedData.forEach((mealId, mealData) {
        //zapis dania do bazy
        DBHelper.insert('dania', {
        'id': mealId,                         //'2160'
        'nazwa': mealData['da_nazwa'],        //'Kurczak z zielonym pieprzem'
        'opis': mealData['da_opis'],          //'Pier\u015b z kurczaka w sosie \u015bmietanowym z zielonym pieprzem'
        'idwer': mealData['da_id_wer'],       //'0'
        'wersja': mealData['da_wersja'],      //''
        'foto': mealData['da_foto'],          //'https://www.cobytu.com/foto/' + 124/filet_z_pieprzem1_4026_m.jpg'      
        'gdzie': mealData['da_gdzie'],        //'Siesta'
        'kategoria': mealData['da_kategoria'],//'4'    
        'podkat': mealData['da_podkategoria'],//'106,107',
        'rodzaj': mealData['da_rodzaj'],      //'Czerwone,Słodkie'
        'srednia': mealData['da_srednia'],    //'0.00' 
        'alergeny': mealData['alergeny'],     //'mleko'
        'cena': mealData['cena'],             //'25.00' 
        'czas': mealData['da_czas'],          //'25'  
        'waga': mealData['waga'],             //'500'
        'kcal': mealData['kcal'],             //'675'
        'lubi': mealData['ud0_da_lubi'],      //'83'        
        'fav': mealData['fav'],               //'0'
        'stolik': mealData['na_stoliku'],     //'0'
        });
      });
      
    } catch (error) {
      throw (error);
    }
  }
*/

//pobranie wpisów o ramce z bazy lokalnej
  Future<void> fetchAndSetFrames() async {
    final dataList = await DBHelper.getData('ramka');
    _items = dataList
        .map(
          (item) => Frame(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            korpusNr: item['korpusNr'],
            typ: item['typ'],
            ramkaNr: item['ramkaNr'],
            rozmiar: item['rozmiar'],
            strona: item['strona'],
            zasob: item['zasob'],
            wartosc: item['wartosc'],
          ),
        )
        .toList();
    print('wczytanie wszystkich!!!!!!! danych o ramkach --> Frames <---');
    //print(_items);
    notifyListeners();
  }

  //pobranie wpisów o ramce z bazy lokalnej
  Future<void> fetchAndSetFramesForHive(pasieka, ul) async {
    final dataList = await DBHelper.getFramesOfHive(pasieka, ul);
    _items = dataList
        .map(
          (item) => Frame(
            id: item['id'],
            data: item['data'],
            pasiekaNr: item['pasiekaNr'],
            ulNr: item['ulNr'],
            korpusNr: item['korpusNr'],
            typ: item['typ'],
            ramkaNr: item['ramkaNr'],
            rozmiar: item['rozmiar'],
            strona: item['strona'],
            zasob: item['zasob'],
            wartosc: item['wartosc'],
          ),
        )
        .toList();
    print('wczytanie danych o ramkach dla podanego ula i pasieki ---> Frames <---');
    //print(_items);
    notifyListeners();
  }
//'CREATE TABLE ramka(id TEXT PRIMARY KEY, data TEXT, pasiekaId TEXT, ulId TEXT, korpusNr TEXT,
//korpusTyp TEXT, ramkaNr TEXT, rozmiar TEXT, miodL TEXT, miodP TEXT, zasklepL TEXT, zasklepP TEXT,
//pierzgaL TEXT, pierzgaP TEXT, czerwL TEXT, czerwP TEXT, larwyL TEXT, larwyP TEXT, jajaL TEXT, jajaP TEXT,
//trutL TEXT, trutP TEXT, wezaL TEXT, wezaP TEXT, suszL TEXT, suszP TEXT, matecznikiL TEXT, matecznikiP TEXT,
//delMatL TEXT, delMatP TEXT, matkaL TEXT, matkaP TEXT, przeznaczenie TEXT, akcja TEXT)');

  //zapisanie rekordu memory do bazy lokalnej
  // static Future<void> insertMemory(String nazwa, String a, String b, String c,
  //     String d, String e, String f) async {
  //   await DBHelper.insert('memory', {
  //     'nazwa': nazwa,
  //     'a': a,
  //     'b': b,
  //     'c': c,
  //     'd': d,
  //     'e': e,
  //     'f': f,
  //   });
  // }
//'CREATE TABLE ramka(id TEXT PRIMARY KEY, data TEXT, pasiekaId TEXT, ulId TEXT, korpusNr TEXT,
//korpusTyp TEXT, ramkaNr TEXT, rozmiar TEXT, miodL TEXT, miodP TEXT, zasklepL TEXT, zasklepP TEXT,
//pierzgaL TEXT, pierzgaP TEXT, czerwL TEXT, czerwP TEXT, larwyL TEXT, larwyP TEXT, jajaL TEXT, jajaP TEXT,
//trutL TEXT, trutP TEXT, wezaL TEXT, wezaP TEXT, suszL TEXT, suszP TEXT, matecznikiL TEXT, matecznikiP TEXT,
//delMatL TEXT, delMatP TEXT, matkaL TEXT, matkaP TEXT, przeznaczenie TEXT, akcja TEXT)');

  //zapisanie ramki do bazy lokalnej
  static Future<void> insertFrame(
      String id,
      String data,
      int pasieka,
      int ul,
      int korpus,
      int typ,
      int ramka,
      int rozmiar,
      int strona,
      int zasob,
      String wartosc) async {
    await DBHelper.insert('ramka', {
      'id': id, //utworzony klucz unikalny
      'data': data,
      'pasiekaNr': pasieka,
      'ulNr': ul,
      'korpusNr': korpus,
      'typ': typ,
      'ramkaNr': ramka,
      'rozmiar': rozmiar,
      'strona': strona,
      'zasob': zasob,
      'wartosc': wartosc,
    });
  }
  /* 
  //usuwanie wszystkich dań z bazy lokalnej
  static Future<void> deleteAllMeals()async{
     await DBHelper.deleteTable('dania');

  }

  static Future<void> updateFavorite(id, fav)async{
     await DBHelper.updateFav(id, fav);

  }

  static Future<void> updateKoszyk(id, ile)async{
     await DBHelper.updateIle(id, ile);

  }
*/
}

// class Mems {
//   //zapisanie rekordu memory do bazy lokalnej
//   static Future<void> insertMemory(String nazwa, String a, String b, String c,
//       String d, String e, String f) async {
//     await DBHelper.insert('memory', {
//       'nazwa': nazwa,
//       'a': a,
//       'b': b,
//       'c': c,
//       'd': d,
//       'e': e,
//       'f': f,
//     });
//   }
// }
/*
import 'meal.dart';

 var MEALS = [
  Meal(
    id: '2160',            
    nazwa: 'Kurczak z zielonym pieprzem',   
    opis: 'Pier\u015b z kurczaka w sosie \u015bmietanowym z zielonym pieprzem',      
    idwer: '0',        
    wersja: '',       
    foto: 'https://www.cobytu.com/foto/124/filet_z_pieprzem1_4026_m.jpg',         
    gdzie: 'Siesta',        
    kategoria: '4',     
    podkat: ['106','110'],  
    srednia: '0.00',       
    alergeny: ' mleko',      
    cena:'25.00',           
    czas: '25',         
    waga: '500',        
    kcal: '675',         
    lubi: '83',          
    fav: '0',           
    stolik: '0',
  ),
  Meal(
    id: '2341',            
    nazwa: 'Awokado Kaburamaki',   
    opis: 'Pier\u015b z kurczaka w sosie \u015bmietanowym z zielonym pieprzem',      
    idwer: '0',        
    wersja: '',       
    foto: 'https://www.cobytu.com/foto/124/filet_z_pieprzem1_4026_m.jpg',         
    gdzie: 'Siesta',        
    kategoria: '4',     
    podkat: ['106','110'],  
    srednia: '0.00',       
    alergeny: ' mleko',      
    cena:'25.00',           
    czas: '25',         
    waga: '500',        
    kcal: '675',         
    lubi: '83',          
    fav: '0',           
    stolik: '0',
  ),
  Meal(
    id: '374',            
    nazwa: '\u0141oso\u015b z grilla',   
    opis: 'Pier\u015b z kurczaka w sosie \u015bmietanowym z zielonym pieprzem',      
    idwer: '0',        
    wersja: '',       
    foto: 'https://www.cobytu.com/foto/15/losos_grillowany_0809_1_m.jpg',         
    gdzie: 'Siesta',        
    kategoria: '4',     
    podkat: ['106','107'],  
    srednia: '0.00',       
    alergeny: ' mleko',      
    cena:'25.00',           
    czas: '25',         
    waga: '500',        
    kcal: '675',         
    lubi: '83',          
    fav: '0',           
    stolik: '0',
  ),
];
*/

//"id":"2341","foto":"co.jpg","gdzie":"Egao Sushi","kategoria":"4","podkategoria":"107,155","nazwa":"Awokado Kaburamaki","opis":"Sushi wielosk\u0142adnikowe. Sk\u0142ad: awokado na zewn\u0105trz, ser, orzechy nerkowca, grillowany \u0142oso\u015b, og\u00f3rek","id_wer":"0","wersja":"4 sztuki","srednia":"0.00","alergeny":" mleko","cena":"24.00","czas":"20","waga":"220","kcal":"491","ud0_lubi":"84","fav":"0","na_stoliku":"0"}

//{"id":"374","foto":"15\/losos_grillowany_0809_1_m.jpg","gdzie":"Kresowianka","kategoria":"4","podkategoria":"106,107","nazwa":"\u0141oso\u015b z grilla","opis":"Grillowany \u0142oso\u015b podawany z cukini\u0105 z grilla","id_wer":"0","wersja":"","srednia":"4.00","alergeny":" ryby","cena":"28.00","czas":"20","waga":"150","kcal":"246","ud0_lubi":"92","fav":"0","na_stoliku":"0"}
