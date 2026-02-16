//import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import 'package:sqflite/sqlite_api.dart';

//metody statyczne w klasie są po to, zeby nie tworzyć instancji tej klasy
//ale pracować z tymi metodami jak z funkcjami. Klasa jest opakowaniem dla metod,
//które mogłyby być napisane jako funkcje poza ta klasą.

//dostep do bazy - otwarcie bazy lub utworzenie nowej jesli nie było.
class DBHelper {
  

  static Future<Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    final path = join(dbPath, "hibees.db"); //ściekzka do bazy i nazwa bazy

//print('openDatabase !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    return sql.openDatabase(path, onCreate: (db, version) async {
      //print('DBHelper - tworzenie tabeli');
      await db.execute(
          'CREATE TABLE ramka(id TEXT PRIMARY KEY, data TEXT, pasiekaNr INTEGER, ulNr INTEGER, korpusNr INTEGER, typ INTEGER, ramkaNr INTEGER, ramkaNrPo INTEGER, rozmiar INTEGER, strona INTEGER, zasob INTEGER, wartosc TEXT, arch INTEGER)');
      // 'CREATE TABLE ramka(id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT, pasiekaId TEXT, ulId TEXT, korpusNr TEXT, polkorpusNr TEXT, ramkaNr TEXT, rozmiar TEXT, miodL TEXT, miodP TEXT, zasklepL TEXT, zasklepP TEXT, pierzgaL TEXT, pierzgaP TEXT, czerwL TEXT, czerwP TEXT, larwyL TEXT, larwyP TEXT, jajaL TEXT, jajaP TEXT, trutL TEXT, trutP TEXT, wezaL TEXT, wezaP TEXT, suszL TEXT, suszP TEXT, matecznikiL TEXT, matecznikiP TEXT, delMatL TEXT, delMatP TEXT, matkaL TEXT, matkaP TEXT, przeznaczenie TEXT, akcja TEXT)');
      await db.execute(
          'CREATE TABLE ule(id TEXT PRIMARY KEY, pasiekaNr INTEGER, ulNr INTEGER, przeglad TEXT, ikona TEXT, ramek INTEGER, korpusNr INTEGER, trut INTEGER, czerw INTEGER, larwy INTEGER, jaja INTEGER, pierzga INTEGER, miod INTEGER, dojrzaly INTEGER, weza INTEGER, susz INTEGER, matka INTEGER, mateczniki INTEGER, usunmat INTEGER, todo TEXT, kategoria TEXT, parametr TEXT, wartosc TEXT, miara TEXT, matka1 TEXT, matka2 TEXT, matka3 TEXT, matka4 TEXT, matka5 TEXT, h1 TEXT, h2 TEXT, h3 TEXT, aktual INTEGER)');
      await db.execute(
          'CREATE TABLE pasieki(id TEXT PRIMARY KEY, pasiekaNr INTEGER, ileUli INTEGER, przeglad TEXT, ikona TEXT, opis TEXT)');
      await db.execute(
          'CREATE TABLE info(id TEXT PRIMARY KEY, data TEXT, pasiekaNr INTEGER, ulNr INTEGER, kategoria TEXT, parametr TEXT, wartosc TEXT, miara TEXT, pogoda TEXT, temp TEXT, czas TEXT, uwagi TEXT, arch INTEGER)');
      await db.execute(
          'CREATE TABLE memory(id TEXT PRIMARY KEY, email TEXT, dev TEXT, wer TEXT, kod TEXT, key TEXT, od TEXT, do TEXT, memjezyk TEXT, mem1 Text, mem2 TEXT)');
      await db.execute(
          'CREATE TABLE dodatki1(id TEXT PRIMARY KEY, a TEXT, b TEXT, c TEXT, d TEXT, e TEXT, f TEXT, g TEXT, h TEXT)');
      await db.execute(
          'CREATE TABLE dodatki2(id TEXT PRIMARY KEY, m TEXT, n TEXT, s TEXT, t TEXT, u TEXT, v TEXT, w TEXT, z TEXT)');
      await db.execute(
          'CREATE TABLE zbiory(id INTEGER PRIMARY KEY, data TEXT, pasiekaNr INTEGER, zasobId INTEGER, ilosc REAL, miara INTEGER, uwagi TEXT, g TEXT, h TEXT, arch INTEGER)');
      await db.execute(
          'CREATE TABLE zakupy(id INTEGER PRIMARY KEY, data TEXT, pasiekaNr INTEGER, nazwa TEXT, kategoriaId INTEGER, ilosc REAL, miara INTEGER, cena REAL, wartosc REAL, waluta INTEGER, uwagi TEXT, arch INTEGER)');
      await db.execute(
          'CREATE TABLE sprzedaz(id INTEGER PRIMARY KEY, data TEXT, pasiekaNr INTEGER, nazwa TEXT, kategoriaId INTEGER, ilosc REAL, miara INTEGER, cena REAL, wartosc REAL, waluta INTEGER, uwagi TEXT, arch INTEGER)');
      await db.execute(
          'CREATE TABLE notatki(id INTEGER PRIMARY KEY, data TEXT, tytul TEXT, pasiekaNr INTEGER, ulNr INTEGER, notatka TEXT, status INTEGER, priorytet TEXT, pole1 TEXT, pole2 TEXT, pole3 TEXT, uwagi TEXT, arch INTEGER)');
      await db.execute(
          'CREATE TABLE pogoda(id TEXT PRIMARY KEY, miasto TEXT, latitude TEXT, longitude TEXT, pobranie TEXT, temp TEXT, weatherId TEXT, icon TEXT, units INTEGER, lang TEXT, inne TEXT)');
      await db.execute(
          'CREATE TABLE matki(id INTEGER PRIMARY KEY, data TEXT, zrodlo TEXT, rasa TEXT, linia TEXT, znak TEXT, napis TEXT, uwagi TEXT, pasieka INTEGER, ul INTEGER, dataStraty TEXT, a TEXT, b TEXT, c TEXT, arch INTEGER)');
      await db.execute(
          'CREATE TABLE zdjecia(id TEXT PRIMARY KEY, data TEXT, czas TEXT, pasiekaNr INTEGER, ulNr INTEGER, sciezka TEXT, uwagi TEXT, arch INTEGER)');

      //    'CREATE TABLE podkategorie(id TEXT PRIMARY KEY, kolejnosc TEXT, kaId TEXT, nazwa TEXT)');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE notatki ADD COLUMN pole1 TEXT');
        await db.execute('ALTER TABLE notatki ADD COLUMN pole2 TEXT');
        await db.execute('ALTER TABLE notatki ADD COLUMN pole3 TEXT');
      }
      if (oldVersion < 3) {
        await db.execute(
            'CREATE TABLE zdjecia(id TEXT PRIMARY KEY, data TEXT, czas TEXT, pasiekaNr INTEGER, ulNr INTEGER, sciezka TEXT, uwagi TEXT, arch INTEGER)');
      }
    }, version: 3);
  }

  static Future<void> deleteBase() async {
    final dbPath = await sql.getDatabasesPath();
   // print('DBHelper - kasowanie bazy danych');
    await sql.deleteDatabase(join(dbPath, "hibees.db"));
  }

//zapis do bazy
  static Future<void> insert(String table, Map<String, Object> data) async {
    final db = await DBHelper.database();
    //print('DBHelper - wstawianie do tabeli $table');
    db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //odczyt z bazy całej tabeli
  static Future<List<Map<dynamic, dynamic>>> getData(String table) async {
    final db = await DBHelper.database();
   // print('DBHelper - pobieranie z tabeli $table');
    return db.query(table);
  }

  //usuwanie tabeli z bazy
  static Future<void> deleteTable(String table) async {
    final db = await DBHelper.database();
   // print('DBHelper - kasowanie tabeli $table');
    db.delete(table);
  }

  //odczyt z tabeli pasieki - pasieki w kolejności - dla apiarys_screen
  static Future<List<Map<String, dynamic>>> getApiarys() async {
    final db = await DBHelper.database();
   // print('DBHelper - pobieranie pasiek');
    return db.rawQuery('SELECT * FROM pasieki ORDER BY pasiekaNr ASC');
  }

  //update tabeli ramki - rekord zarchiwizowany - dla import_screen
  static Future<void> updateRamkaArch(String id) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update ramka - id=$id');
    db.update('ramka', {'arch': 1}, where: 'id = ?', whereArgs: [id]);
  }

  //update tabeli ramki - przeniesienie ramki do innego korpusa - dla voice_screen
  static Future<void> moveRamkaToBody(String id, int ul, int korpus, int ramka) async {
    final db = await DBHelper.database();
    //print('db_helpers: przenieś ramka - id=$id, ulNr=$ul, korpusNr=$korpus, ramkaNr = $ramka');
    db.update('ramka', {'ulNr': ul, 'korpusNr': korpus, 'typ': 2, 'ramkaNr': 0, 'ramkaNrPo': ramka}, where: 'id = ?', whereArgs: [id]);
  }

  //update tabeli ramki - przeniesienie ramki do innego półkorpusa - dla voice_screen
  static Future<void> moveRamkaToHalfBody(String id, int ul, int korpus, int ramka) async {
    final db = await DBHelper.database();
    //print('db_helpers: przenieś ramka - id=$id, ulNr=$ul, korpusNr=$korpus, ramkaNr = $ramka');
    db.update('ramka', {'ulNr': ul, 'korpusNr': korpus, 'typ': 1, 'ramkaNr': 0, 'ramkaNrPo': ramka}, where: 'id = ?', whereArgs: [id]);
  }
  
  //update tabeli ramki - ustawienie "ramkaNrPo" - dla frame_edit_screen i voice_screen
  static Future<void> updateRamkaNrPo(String id, int ramkaNrPo) async {
    final db = await DBHelper.database();
    //print('db_helpers: update ramkaNrPo - id=$id, ramkaNrPo = $ramkaNrPo');
    db.update('ramka', {'ramkaNrPo': ramkaNrPo}, where: 'id = ?', whereArgs: [id]);
  }

   //update tabeli ramki - ustawienie "ramkaNr" - dla frame_edit_screen? i voice_screen
  static Future<void> updateRamkaNr(String id, int ramkaNr) async {
    final db = await DBHelper.database();
    //print('db_helpers: update ramkaNr - id=$id, ramkaNr = $ramkaNr');
    db.update('ramka', {'ramkaNr': ramkaNr}, where: 'id = ?', whereArgs: [id]);
  }

  //update tabeli info - rekord zarchiwizowany - dla import_screen
  static Future<void> updateInfoArch(String id) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update info - id=$id');
    db.update('info', {'arch': 1}, where: 'id = ?', whereArgs: [id]);
  }

  //update tabeli zbiory - rekord zarchiwizowany - dla import_screen
  static Future<void> updateZbioryArch(int id) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update zbiory - id=$id');
    db.update('zbiory', {'arch': 1}, where: 'id = ?', whereArgs: [id]);
  }

  //update tabeli notatki - rekord zarchiwizowany - dla import_screen
  static Future<void> updateNotatkiArch(int id) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update notatki - id=$id');
    db.update('notatki', {'arch': 1}, where: 'id = ?', whereArgs: [id]);
  }

  //update tabeli sprzedaz - rekord zarchiwizowany - dla import_screen
  static Future<void> updateSprzedazArch(int id) async {
    final db = await DBHelper.database();
   // print('db_helpers: update sprzedaz - id=$id');
    db.update('sprzedaz', {'arch': 1}, where: 'id = ?', whereArgs: [id]);
  }

  //update tabeli matki - rekord zarchiwizowany - dla import_screen
  static Future<void> updateMatkiArch(int id) async {
    final db = await DBHelper.database();
    //print('db_helpers: update matki - id=$id');
    db.update('matki', {'arch': 1}, where: 'id = ?', whereArgs: [id]);
  }

  //update tabeli zakupy - rekord zarchiwizowany - dla import_screen
  static Future<void> updateZakupyArch(int id) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update zakupy - id=$id');
    db.update('zakupy', {'arch': 1}, where: 'id = ?', whereArgs: [id]);
  }

  //update tabeli zdjecia - rekord zarchiwizowany - dla import_screen
  static Future<void> updatePhotoArch(String id) async {
    final db = await DBHelper.database();
    db.update('zdjecia', {'arch': 1}, where: 'id = ?', whereArgs: [id]);
  }

  //update tabeli info - wartość = edit = szara ikona - dla frame_edit_screen
  static Future<void> updateInfoWartosc(String id,  String wart) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update info - id=$id');
    db.update('info', {'wartosc': wart}, where: 'id = ?', whereArgs: [id]);
  }

  //update pasieki- ilość uli w pasiece - dla voice_screen
  static Future<void> updateIleUli(int pasieka, int ile) async {
    final db = await DBHelper.database();
    //print('db_helpers: update pasieki - ile uli w pasiece $pasieka ile=$ile');
    db.update('pasieki', {'ileUli': ile},
        where: 'pasiekaNr = ?', whereArgs: [pasieka]);
  }

  //update pasieki- ikona pasieki - dla voice_screen
  static Future<void> updateIkonaPasieki(int pasieka, String ikona) async {
    final db = await DBHelper.database();
    //print('db_helpers: update pasieki - ikona pasieki $pasieka ikona=$ikona');
    db.update('pasieki', {'ikona': ikona},
        where: 'pasiekaNr = ?', whereArgs: [pasieka]);
  }

  //update memory - czy bez aktywacji - dla apiarys_screen
  static Future<void> updateActivate(String dev, String text) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update memory - praca bez aktywacji');
    db.update('memory', {'od': text}, where: 'dev = ?', whereArgs: [dev]);
  }

  //update memory - jezyk - dla language_screen
  static Future<void> updateJezyk(String dev, String text) async {
    final db = await DBHelper.database();
 //   print('db_helpers: update memory - jezyk ustawiony w aplikacji');
    db.update('memory', {'memjezyk': text}, where: 'dev = ?', whereArgs: [dev]);
  }

  //update dodatki1 - dla import_screen
  static Future<void> updateDodatki1(String pole, String wartosc) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update dodatki1 - pole = $pole , wartość = $wartosc ');
    db.update('dodatki1', {'$pole': wartosc}, where: 'id = ?', whereArgs: ['1']);
  }

  //update matki - dla import_screen
  static Future<void> updateQueen(int id, String pole, int wartosc) async {
    final db = await DBHelper.database();
    //print('db_helpers: update matki $id: pole = $pole , wartość = $wartosc ');
    db.update('matki', {'$pole': wartosc}, where: 'id = ?', whereArgs: [id]);
  }

//update ule, pola np. ikona - dla import_screen
  static Future<void> updateUle(String id, String pole, String wartosc) async {
    final db = await DBHelper.database();
    //print('db_helpers: update ule $id: pole = $pole , wartość = $wartosc ');
    db.update('ule', {'$pole': wartosc}, where: 'id = ?', whereArgs: [id]);
  }
  
  //update ula w tabeli ule - info o matce1 - dla hives_screen
  static Future<void> updateUleMatka1(String id, String wartosc) async {
    final db = await DBHelper.database();
   //print('db_helpers: update ule - id=$id, matka1 = $wartosc');
    db.update('ule', {'matka1': wartosc}, where: 'id = ?', whereArgs: [id]);
  }
  
  //update ula w tabeli ule - info o matce2 - dla hives_screen
  static Future<void> updateUleMatka2(String id, String wartosc) async {
    final db = await DBHelper.database();
  // print('db_helpers: update matka2 - id=$id, matka2 = $wartosc');
    db.update('ule', {'matka2': wartosc}, where: 'id = ?', whereArgs: [id]);
  }
  
  //update ula w tabeli ule - info o matce3 - dla hives_screen
  static Future<void> updateUleMatka3(String id, String wartosc) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update ule - id=$id, matka3 = $wartosc');
    db.update('ule', {'matka3': wartosc}, where: 'id = ?', whereArgs: [id]);
  }

  //update ula w tabeli ule - info o matce4 - dla hives_screen
  static Future<void> updateUleMatka4(String id, String wartosc) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update ule - id=$id, matka4 = $wartosc');
    db.update('ule', {'matka4': wartosc}, where: 'id = ?', whereArgs: [id]);
  }

  //update ula w tabeli ule - info o matce5 - dla hives_screen
  static Future<void> updateUleMatka5(String id, String wartosc) async {
    final db = await DBHelper.database();
   // print('db_helpers: update ule - id=$id, matka5 = $wartosc');
    db.update('ule', {'matka5': wartosc}, where: 'id = ?', whereArgs: [id]);
  }
  
  //update dodatki2 - dla parametry_ula_screen
  static Future<void> updateDodatki2(
    String id,
    String m,
    String n,
    String s,
    String t,
    String u,
    String v,
    String w,
    String z, 
  ) async {
    final db = await DBHelper.database();
    //print('db_helpers: update dodatki2 - id = $id, m = $m, n = $n, s = $s');
    db.update(
        'dodatki2',
        {
          'm': m,
          'n': n,
          's': s,
          't': t,
          'u': u,
          'v': v,
          'w': w,
          'z': z,
        },
        where: 'id = ?',
        whereArgs: [id]);
  }
  
  //update zakupy - dla purchase_edit_screen
  static Future<void> updateZakupy(
    int id,
    String data,
    int pasiekaNr,
    String nazwa,
    int kategoriaId,
    double ilosc,
    int miara,
    double cena,
    double wartosc,
    int waluta,
    String uwagi,
    int arch,
  ) async {
    final db = await DBHelper.database();
    //print('db_helpers: update zakupy - id = $id, zasob = $zasobId, ilosc = $ilosc, miara = $miara');
    db.update(
        'zakupy',
        {
          'data': data,
          'pasiekaNr': pasiekaNr,
          'nazwa': nazwa,
          'kategoriaId': kategoriaId,
          'ilosc': ilosc,
          'miara': miara,
          'cena': cena,
          'wartosc': wartosc,
          'waluta': waluta,
          'uwagi': uwagi,
          'arch': arch
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  //update sprzedaz - dla sale_edit_screen
  static Future<void> updateSprzedaz(
    int id,
    String data,
    int pasiekaNr,
    String nazwa,
    int kategoriaId,
    double ilosc,
    int miara,
    double cena,
    double wartosc,
    int waluta,
    String uwagi,
    int arch,
  ) async {
    final db = await DBHelper.database();
    //print('db_helpers: update spraedaz - id = $id, zasob = $zasobId, ilosc = $ilosc, miara = $miara');
    db.update(
        'sprzedaz',
        {
          'data': data,
          'pasiekaNr': pasiekaNr,
          'nazwa': nazwa,
          'kategoriaId': kategoriaId,
          'ilosc': ilosc,
          'miara': miara,
          'cena': cena,
          'wartosc': wartosc,
          'waluta': waluta,
          'uwagi': uwagi,
          'arch': arch
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  //update zbiory - dla harvest_edit_screen
  static Future<void> updateZbiory(
      int id,
      String data,
      int pasiekaNr,
      int zasobId,
      double ilosc,
      int miara,
      String uwagi,
      String g,
      String h,
      int arch) async {
    final db = await DBHelper.database();
//print('db_helpers: update zbiory - id = $id, zasob = $zasobId, ilosc = $ilosc, miara = $miara');
    db.update(
        'zbiory',
        {
          'data': data,
          'pasiekaNr': pasiekaNr,
          'zasobId': zasobId,
          'ilosc': ilosc,
          'miara': miara,
          'uwagi': uwagi,
          'g': g,
          'h': h,
          'arch': arch
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  //update notatki - dla notes_edit_screen
  static Future<void> updateNotatki(
      int id,
      String data,
      String tytul,
      int pasiekaNr,
      int ulNr,
      String notatka,
      int status,
      String priorytet,
      String pole1,
      String pole2,
      String pole3,
      String uwagi,
      int arch) async {
    final db = await DBHelper.database();
//print('db_helpers: update notatki - id = $id, zasob = $zasobId, ilosc = $ilosc, miara = $miara');
    db.update(
        'notatki',
        {
          'data': data,
          'tytul': tytul,
          'pasiekaNr': pasiekaNr,
          'ulNr': ulNr,
          'notatka': notatka,
          'status': status,
          'priorytet': priorytet,
          'pole1': pole1,
          'pole2': pole2,
          'pole3': pole3,
          'uwagi': uwagi,
          'arch': arch
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  //update pogoda - dla voice_screen
  static Future<void> updatePogoda(
      String id, String pobranie, double temp, String icon) async {
    final db = await DBHelper.database();
    //print( 'db_helpers: update pogoda - id = $id, pobranie = $pobranie, temp = $temp, icon = $icon');
    db.update('pogoda', {'pobranie': pobranie, 'temp': temp, 'icon': icon},
        where: 'id = ?', whereArgs: [id]);
  }

  //odczyt z tabeli ule - ule z wybranej pasieki - dla hives_screen
  static Future<List<Map<String, dynamic>>> getHives(nrPasieki) async {
    final db = await DBHelper.database();
    //print('DBHelper - pobieranie uli z pasieki $nrPasieki');
    return db.rawQuery(
        'SELECT * FROM ule WHERE  pasiekaNr = ? ORDER BY ulNr ASC',
        [nrPasieki]);
  }

  //odczyt z tabeli ule - ul po tagu NFC (h3) - dla nfc_helper
  static Future<List<Map<String, dynamic>>> getHiveByH3(String h3Value) async {
    final db = await DBHelper.database();
    return db.rawQuery('SELECT * FROM ule WHERE h3 = ?', [h3Value]);
  }

  //odczyt z bazy ramka z unikalnymi datami dla danego ula i pasieki - dla frames_screen
  static Future<List<Map<String, dynamic>>> getDate(int pasieka, int ul) async {
    final db = await DBHelper.database();
   // print('DBHelper - pobieranie dat dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT data FROM ramka WHERE pasiekaNr=? and ulNr = ? ORDER BY data DESC',
        [pasieka, ul]);
  }

  //odczyt z bazy info z unikalnymi datami dla danego ula, pasieki, kategorii, parametru - dla hives_screen
  static Future<List<Map<String, dynamic>>> getDateInfo(int pasieka, int ul, String kategoria, String parametr) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dat info dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT data FROM info WHERE pasiekaNr=? and ulNr = ? and kategoria = ? and parametr = ? ORDER BY data DESC',
        [pasieka, ul, kategoria, parametr]);
  }

  //odczyt z bazy info z unikalnymi datami dla danego ula, pasieki i kategorii feeding lub treatment - dla hives_screen
  static Future<List<Map<String, dynamic>>> getDateInfoDL(int pasieka, int ul) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dat infoDL dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT data FROM info WHERE pasiekaNr=? and ulNr = ? and (kategoria = ? or kategoria = ?) ORDER BY data DESC',
        [pasieka, ul,'feeding','treatment']);
  }

  //odczyt z bazy info z unikalnymi datami dla danego ula, pasieki i kategorii harvest - dla hives_screen
  static Future<List<Map<String, dynamic>>> getDateInfoZkg(int pasieka, int ul, String parametr) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dat infoDL dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT data FROM info WHERE pasiekaNr=? and ulNr = ? and kategoria = ? and parametr = ? ORDER BY data DESC',
        [pasieka, ul,'harvest', parametr]);
  } 

  //odczyt z bazy info z unikalnymi datami dla danego ula, pasieki i kategorii harvest - dla hives_screen
  static Future<List<Map<String, dynamic>>> getDateInfoZmr(int pasieka, int ul, String parametr) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dat infoDL dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT data FROM info WHERE pasiekaNr=? and ulNr = ? and kategoria = ? and parametr = ? ORDER BY data DESC',
        [pasieka, ul,'harvest', parametr]);
  }

   //odczyt z bazy info z unikalnymi datami dla danego ula, pasieki i kategorii harvest - dla hives_screen
  static Future<List<Map<String, dynamic>>> getDateInfoZdr(int pasieka, int ul, String parametr) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dat infoDL dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT data FROM info WHERE pasiekaNr=? and ulNr = ? and kategoria = ? and parametr = ? ORDER BY data DESC',
        [pasieka, ul,'harvest', parametr]);
  }

  //pobieranie ramek dla danego ula i pasieki - dla frames
  static Future<List<Map<String, dynamic>>> getFramesOfHive(
      int pasieka, int ul) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie ramek z ula nr $ul dla pasieki nr $pasieka');
    return db.query("ramka",
        where: "pasiekaNr=? and ulNr=? ORDER BY korpusNr, ramkaNr, zasob ASC",
        whereArgs: [pasieka, ul]);
  }

  //pobieranie wszystkich ramek do achiwizacji dla apiarys_screen
  static Future<List<Map<String, dynamic>>> getFramesToArch() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie ramek do achiwizacji');
    return db.query("ramka", where: "arch=?", whereArgs: [0]);
  }

  //pobieranie info dla danego ula i pasieki - dla infos
  static Future<List<Map<String, dynamic>>> getInfosOfHive(
      int pasieka, int ul) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie info dla ula nr $ul dla pasieki nr $pasieka');
    return db.query("info",
        where: "pasiekaNr=? and ulNr=? ORDER BY data DESC, czas DESC",
        whereArgs: [pasieka, ul]);
  }

  //pobieranie info dla danej pasieki - dla raportów
  static Future<List<Map<String, dynamic>>> getInfosOfApiary(
      int pasieka) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie info dla pasieki nr $pasieka');
    return db.query("info",
        where: "pasiekaNr=? ORDER BY data DESC, czas DESC",
        whereArgs: [pasieka]);
  }

  //pobieranie wszystkich nowych info do achiwizacji dla import_screen
  static Future<List<Map<String, dynamic>>> getInfosToArch() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie info do achiwizacji');
    return db.query("info", where: "arch=?", whereArgs: [0]);
  }

  //pobieranie wszystkich nowych zbiory do achiwizacji dla import_screen
  static Future<List<Map<String, dynamic>>> getZbioryToArch() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie tabeli zbiory do achiwizacji');
    return db.query("zbiory", where: "arch=?", whereArgs: [0]);
  }

  //pobieranie wszystkich nowych notatek do achiwizacji dla import_screen
  static Future<List<Map<String, dynamic>>> getNotatkiToArch() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie tabeli notatki do achiwizacji');
    return db.query("notatki", where: "arch=?", whereArgs: [0]);
  }

  //pobieranie wszystkich nowych sprzedaz do achiwizacji dla import_screen
  static Future<List<Map<String, dynamic>>> getSprzedazToArch() async {
    final db = await DBHelper.database();
   // print('DBHelper - pobieranie tabeli sprzedaz do achiwizacji');
    return db.query("sprzedaz", where: "arch=?", whereArgs: [0]);
  }

  //pobieranie wszystkich nowych matek do achiwizacji dla import_screen
  static Future<List<Map<String, dynamic>>> getMatkiToArch() async {
    final db = await DBHelper.database();
   // print('DBHelper - pobieranie tabeli matki do achiwizacji');
    return db.query("matki", where: "arch=?", whereArgs: [0]);
  }

  //pobieranie wszystkich nowych zakupy do achiwizacji dla import_screen
  static Future<List<Map<String, dynamic>>> getZakupyToArch() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie tabeli zakupy do achiwizacji');
    return db.query("zakupy", where: "arch=?", whereArgs: [0]);
  }

  //pobieranie wszystkich nowych zdjec do achiwizacji dla import_screen
  static Future<List<Map<String, dynamic>>> getPhotosToArch() async {
    final db = await DBHelper.database();
    return db.query("zdjecia", where: "arch=?", whereArgs: [0]);
  }

  //odczyt z tabeli ramka rekordu o danym id  - dla frames_detail_item
  static Future<List<Map<String, dynamic>>> getFrame(String id) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie ramki o id = $id');
    return db.rawQuery('SELECT * FROM ramka WHERE  id = ?', [id]);
  }

  //odczyt z bazy unikalnych numerów korpusów dla danego ula i pasieki i daty - dla frames_screen
  static Future<List<Map<String, dynamic>>> getKorpus(
      int pasieka, int ul, String wybranaData) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie unikalnych numerów korpusów dla pasieki = $pasieka, ul nr $ul, data = $wybranaData');
    return db.rawQuery(
        'SELECT DISTINCT korpusNr, typ FROM ramka WHERE data=? and pasiekaNr=? and ulNr = ? ORDER BY korpusNr ASC',
        [wybranaData, pasieka, ul]);
  }

  //odczyt z tabeli memory dla urzadzenia - dla apiary_screen
  static Future<List<Map<String, dynamic>>> getMem(String dev) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie memory dla dev = $dev');
    return db.rawQuery('SELECT * FROM memory WHERE  dev = ? OR dev = "test"', [dev]);
  }
  //odczyt z tabeli memory  - dla apiary_screen - logowanie bez device
  static Future<List<Map<String, dynamic>>> getMemory() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie memory dla dev = $dev');
    return db.rawQuery('SELECT * FROM memory');
  }

  //odczyt z tabeli dodatki1  - dla apiary_screen
  static Future<List<Map<String, dynamic>>> getDodatki1() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dodatki 1');
    return db.rawQuery('SELECT * FROM dodatki1');
  }

  //odczyt z tabeli dodatki1  - dla apiary_screen
  static Future<List<Map<String, dynamic>>> getDodatki2() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dodatki 1');
    return db.rawQuery('SELECT * FROM dodatki2');
  }

  //odczyt z tabeli matki  - dla apiary_screen, infos_screen
  static Future<List<Map<String, dynamic>>> getQueens() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie matek');
    return db.rawQuery('SELECT * FROM matki ORDER BY id DESC');
  }

  //odczyt ID matki tabeli matki  - dla infos_screen
  static Future<List<Map<String, dynamic>>> getQueenID(int pasieka, int ul,) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie ID matki dla ula x');
    return db.rawQuery('SELECT id FROM matki WHERE pasieka=? and ul = ?',
        [pasieka, ul]);
  }

  //odczyt z tabeli zbiory - dla harvest_screen
  static Future<List<Map<String, dynamic>>> getZbiory() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie zbiory');
    return db.rawQuery('SELECT * FROM zbiory ORDER BY data DESC');
  }

  //odczyt/pobranie wszystkich danych z tabeli notatki - dla note_screen
  static Future<List<Map<String, dynamic>>> getNotatki() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie notatek');
    return db.rawQuery('SELECT * FROM notatki ORDER BY data DESC');
  }

   //odczyt z tabeli notatki - dla apiary_screen - inny sort
  static Future<List<Map<String, dynamic>>> getNotatkiASC() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie notatek Priotytet');
    return db.rawQuery('SELECT * FROM notatki ORDER BY data ASC');
  }

  //odczyt z tabeli sprzedaz - dla sale_screen
  static Future<List<Map<String, dynamic>>> getSprzedaz() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie sprzedaz');
    return db.rawQuery('SELECT * FROM sprzedaz ORDER BY data DESC');
  }

  //odczyt z tabeli zakupy - dla purchase_screen
  static Future<List<Map<String, dynamic>>> getZakupy() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie zakupy');
    return db.rawQuery('SELECT * FROM zakupy ORDER BY data DESC');
  }

  //odczyt z tabeli zdjecia - dla import_screen i photo.dart
  static Future<List<Map<String, dynamic>>> getZdjecia() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie zakupy');
    return db.rawQuery('SELECT * FROM zdjecia ORDER BY data DESC');
  }

  //usuniecie rekordu z tabeli info - dla frame_screen
  static Future<void> deleteInfo(String id) async {
    final db = await DBHelper.database();
    //print('DBhelper: delete info id = $id');
    db.delete('info', where: 'id= ?', whereArgs: [id]);
  }

  //usuniecie rekordu z tabeli ule - dla info_item
  static Future<void> deleteUl(int pasieka, int ul) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete ul nr = $ul');
    db.delete('ule', where: 'pasiekaNr=? and ulNr=?', whereArgs: [pasieka, ul]);
  }

  //usuniecie rekordu z tabeli pasieki - dla info_item
  static Future<void> deletePasieki(int pasieka) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete pasieki nr = $pasieka');
    db.delete('pasieki', where: 'pasiekaNr=? ', whereArgs: [pasieka]);
  }

  //usuniecie rekordu o podanym id z tabeli ramka - dla frame_detail_screen
  static Future<void> deleteFrame(String id) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete ramka id = $id');
    db.delete('ramka', where: 'id= ?', whereArgs: [id]);
  }

  //usuniecie rekordu o podanym id z tabeli zbiory - dla harvest_edit_screen, harvest_item
  static Future<void> deleteZbiory(int id) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete zbiory id = $id');
    db.delete('zbiory', where: 'id= ?', whereArgs: [id]);
  }

  //usuniecie rekordu o podanym id z tabeli notatki - dla notes_edit_screen, harvest_item
  static Future<void> deleteNotatki(int id) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete notatki id = $id');
    db.delete('notatki', where: 'id= ?', whereArgs: [id]);
  }

   //usuniecie rekordu o podanym id z tabeli matki - dla , queen_item
  // static Future<void> deleteQueen(int id) async {
  //   final db = await DBHelper.database();
  // //  print('DBhelper: delete matki id = $id');
  //   db.delete('matki', where: 'id= ?', whereArgs: [id]);
  // }

  //usuniecie rekordu o podanym id z tabeli sprzedaz - dla sale_edit_screen, sale_item
  static Future<void> deleteSprzedaz(int id) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete sprzedaz id = $id');
    db.delete('sprzedaz', where: 'id= ?', whereArgs: [id]);
  }

  //usuniecie rekordu o podanym id z tabeli zakupy - dla sale_edit_screen, sale_item
  static Future<void> deleteZakupy(int id) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete zakupy id = $id');
    db.delete('zakupy', where: 'id= ?', whereArgs: [id]);
  }

  //usuniecie rekordów z tabeli ramka dla danej daty, pasieki i ula - dla frame_detail_screen
  static Future<void> deleteInspection(String data, int pasieka, int ul) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete ramki dla: data = $data, pasieka = $pasieka, ul = $ul');
    db.delete('ramka',
        where: 'data=? and pasiekaNr=? and ulNr =?',
        whereArgs: [data, pasieka, ul]);
  }

  //pobieranie zdjęć dla danego ula i pasieki - dla infos_screen
  static Future<List<Map<String, dynamic>>> getPhotosOfHive(int pasieka, int ul) async {
    final db = await DBHelper.database();
    return db.query("zdjecia",
        where: "pasiekaNr=? and ulNr=?",
        whereArgs: [pasieka, ul],
        orderBy: "data DESC, czas DESC");
  }

  //usuniecie zdjęcia z tabeli zdjecia - dla infos_screen
  static Future<void> deletePhoto(String id) async {
    final db = await DBHelper.database();
    db.delete('zdjecia', where: 'id= ?', whereArgs: [id]);
  }

}
