
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import 'package:sqflite/sqlite_api.dart';

//metody statyczne w klasie są po to, zeby nie tworzyć instancji tej klasy
//ale pracować z tymi metodami jak z funkcjami. Klasa jest opakowaniem dla metod,
//które mogłyby być napisane jako funkcje poza ta klasą.

//dostep do bazy - otwarcie bazy lub utworzenie nowej jesli nie było.
class DBHelper {
  /*
  static Database _database;

  Future<Database> get database async{
    if (_database != null)
    return _database;
    _database = await initDB();
    return _database;
  }

  initDB() async{
    final dataPath = await sql.getDatabasesPath();
    String dbPath = path.join(dataPath,'cobytu.db');
    return await sql.openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE dania(id TEXT PRIMARY KEY, nazwa TEXT, opis TEXT, idwer TEXT, wersja TEXT, foto TEXT, gdzie TEXT, kategoria TEXT, podkat TEXT, srednia TEXT, alergeny TEXT, cena TEXT, czas TEXT, waga TEXT, kcal TEXT, lubi TEXT, fav TEXT, stolik TEXT)'
          );
    
      }
      );
  }
*/

  static Future<Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    final path = join(dbPath, "hibees.db"); //ściekzka do bazy i nazwa bazy

//print('openDatabase !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    return sql.openDatabase(path, onCreate: (db, version) async {
      print('DBHelper - tworzenie tabeli');
      await db.execute(
        'CREATE TABLE ramka(id TEXT PRIMARY KEY, data TEXT, pasiekaNr INTEGER, ulNr INTEGER, korpusNr INTEGER, typ INTEGER, ramkaNr INTEGER, rozmiar INTEGER, strona INTEGER, zasob INTEGER, wartosc TEXT)'); 
         // 'CREATE TABLE ramka(id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT, pasiekaId TEXT, ulId TEXT, korpusNr TEXT, polkorpusNr TEXT, ramkaNr TEXT, rozmiar TEXT, miodL TEXT, miodP TEXT, zasklepL TEXT, zasklepP TEXT, pierzgaL TEXT, pierzgaP TEXT, czerwL TEXT, czerwP TEXT, larwyL TEXT, larwyP TEXT, jajaL TEXT, jajaP TEXT, trutL TEXT, trutP TEXT, wezaL TEXT, wezaP TEXT, suszL TEXT, suszP TEXT, matecznikiL TEXT, matecznikiP TEXT, delMatL TEXT, delMatP TEXT, matkaL TEXT, matkaP TEXT, przeznaczenie TEXT, akcja TEXT)');
      await db.execute(
        'CREATE TABLE ule(id TEXT PRIMARY KEY, pasiekaNr INTEGER, ulNr INTEGER, przeglad TEXT, ikona TEXT, opis TEXT)');
      await db.execute(
        'CREATE TABLE pasieki(id TEXT PRIMARY KEY, pasiekaNr INTEGER, ileUli INTEGER, przeglad TEXT, ikona TEXT, opis TEXT)');
      await db.execute(
        'CREATE TABLE info(id TEXT PRIMARY KEY, data TEXT, pasiekaNr INTEGER, ulNr INTEGER, kategoria TEXT, parametr TEXT, wartosc TEXT, miara TEXT, uwagi TEXT)');
      await db.execute(
        'CREATE TABLE memory(id TEXT PRIMARY KEY, email TEXT, dev TEXT, wer TEXT, kod TEXT, key TEXT, od TEXT, do TEXT)');
      await db.execute(
        'CREATE TABLE dodatki1(id TEXT PRIMARY KEY, a TEXT, b TEXT, c TEXT, d TEXT, e TEXT, f TEXT, h TEXT, i TEXT)');
      await db.execute(
        'CREATE TABLE dodatki2(id TEXT PRIMARY KEY, a TEXT, b TEXT, c TEXT, d TEXT, e TEXT, f TEXT, h TEXT, i TEXT)');
      
      //    'CREATE TABLE podkategorie(id TEXT PRIMARY KEY, kolejnosc TEXT, kaId TEXT, nazwa TEXT)');
    }, version: 1);
  }

  static Future<void> deleteBase() async {
    final dbPath = await sql.getDatabasesPath();
    print('DBHelper - kasowanie bazy danych');
    await sql.deleteDatabase(join(dbPath, "hibees.db"));
  }

//zapis do bazy
  static Future<void> insert(String table, Map<String, Object> data) async {
    final db = await DBHelper.database();
    print('DBHelper - wstawianie do tabeli $table');
    db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //odczyt z bazy całej tabeli
  static Future<List<Map<dynamic, dynamic>>> getData(String table) async {
    final db = await DBHelper.database();
    print('DBHelper - pobieranie z tabeli $table');
    return db.query(table);
  }

  //usuwanie tabeli z bazy
  static Future<void> deleteTable(String table) async {
    final db = await DBHelper.database();
    print('DBHelper - kasowanie tabeli $table');
    db.delete(table);
  }

     
  //odczyt z tabeli pasieki - pasieki w kolejności - dla apiarys_screen
  static Future<List<Map<String, dynamic>>> getApiarys() async {
    final db = await DBHelper.database();
    print('DBHelper - pobieranie pasiek');
    return db.rawQuery(
        'SELECT * FROM pasieki ORDER BY pasiekaNr ASC');
  }

  //update pasieki- ilość uli w pasiece - dla voice_screen
  static Future<void> updateIleUli(int pasieka, int ile) async {
    final db = await DBHelper.database();
    print('db_helpers: update pasieki - ile uli w pasiece $pasieka ile=$ile');
    db.update('pasieki', {'ileUli': ile}, where: 'pasiekaNr = ?', whereArgs: [pasieka]);
  }

 
  //update memory - czy bez aktywacji - dla apiarys_screen
  static Future<void> updateActivate(String dev, String text) async {
    final db = await DBHelper.database();
    print('db_helpers: update memory - praca bez aktywacji');
    db.update('memory', {'od': text}, where: 'dev = ?', whereArgs: [dev]);
  }
 
  //odczyt z tabeli ule - ule z wybranej pasieki - dla hives_screen
  static Future<List<Map<String, dynamic>>> getHives(nrPasieki) async {
    final db = await DBHelper.database();
    print('DBHelper - pobieranie uli z pasieki $nrPasieki');
    return db.rawQuery(
        'SELECT * FROM ule WHERE  pasiekaNr = ? ORDER BY ulNr ASC',[nrPasieki]);
  }


   //odczyt z bazy ramka z unikalnymi datami dla danego ula i pasieki - dla frames_screen
  static Future<List<Map<String, dynamic>>> getDate(int pasieka, int ul) async {
    final db = await DBHelper.database();
    print('DBHelper - pobieranie dat dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT data FROM ramka WHERE pasiekaNr=? and ulNr = ? ORDER BY data DESC',[pasieka, ul]);
  }

  //pobieranie ramek dla danego ula i pasieki - dla frames
  static Future<List<Map<String, dynamic>>> getFramesOfHive(int pasieka, int ul) async {
    final db = await DBHelper.database();
    print('DBHelper - pobieranie ramek z ula nr $ul dla pasieki nr $pasieka');
    return  db.query("ramka",where: "pasiekaNr=? and ulNr=? ORDER BY korpusNr, ramkaNr, zasob ASC", whereArgs: [pasieka, ul]);
  }

   //pobieranie info dla danego ula i pasieki - dla infos
  static Future<List<Map<String, dynamic>>> getInfosOfHive(int pasieka, int ul) async {
    final db = await DBHelper.database();
    print('DBHelper - pobieranie info dla ula nr $ul dla pasieki nr $pasieka');
    return  db.query("info",where: "pasiekaNr=? and ulNr=? ORDER BY data DESC", whereArgs: [pasieka, ul]);
  }

  
   //odczyt z bazy unikalnych numerów korpusów dla danego ula i pasieki i daty - dla frames_screen
  static Future<List<Map<String, dynamic>>> getKorpus(int pasieka, int ul, String wybranaData) async {
    final db = await DBHelper.database();
    print('DBHelper - pobieranie unikalnych numerów korpusów dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT korpusNr, typ FROM ramka WHERE data=? and pasiekaNr=? and ulNr = ? ORDER BY korpusNr ASC',[wybranaData, pasieka, ul]);
  }

  //odczyt z tabeli memory  - dla apiary_screen
  static Future<List<Map<String, dynamic>>> getMem(String dev) async {
    final db = await DBHelper.database();
    print('DBHelper - pobieranie memory dla dev = $dev');
    return db.rawQuery(
        'SELECT * FROM memory WHERE  dev = ?',[dev]);
  }
  
  
  //usuniecie rekordu z tabeli info - dla frame_screen 
  static Future<void> deleteInfo(String id) async {
    final db = await DBHelper.database();
    print('DBhelper: delete info id = $id');
    db.delete('info', where: 'id= ?', whereArgs: [id]);
  }

  //usuniecie rekordu z tabeli ule - dla info_item 
  static Future<void> deleteUl(int pasieka, int ul) async {
    final db = await DBHelper.database();
    print('DBhelper: delete ul nr = $ul');
    db.delete('ule', where: 'pasiekaNr=? and ulNr=?', whereArgs: [pasieka,ul]);
  }

   //usuniecie rekordu z tabeli pasieki - dla info_item 
  static Future<void> deletePasieki(int pasieka) async {
    final db = await DBHelper.database();
    print('DBhelper: delete pasieki nr = $pasieka');
    db.delete('pasieki', where: 'pasiekaNr=? ', whereArgs: [pasieka]);
  }

  //usuniecie rekordu o podanym id z tabeli ramka - dla frame_detail_screen 
  static Future<void> deleteFrame(String id) async {
    final db = await DBHelper.database();
    print('DBhelper: delete ramka id = $id');
    db.delete('ramka', where: 'id= ?', whereArgs: [id]);
  }
  
   //usuniecie rekordów z tabeli ramka dla danej daty, pasieki i ula - dla frame_detail_screen 
  static Future<void> deleteInspection(String data, int pasieka, int ul) async {
    final db = await DBHelper.database();
    print('DBhelper: delete ramki dla: data = $data, pasieka = $pasieka, ul = $ul');
    db.delete('ramka', where: 'data=? and pasiekaNr=? and ulNr =?', whereArgs: [data,pasieka,ul]);
  }
  
  
  // //odczyt z bazy jednej ramki
  //  static Future<List<Map<String, dynamic>>> getFrame(String ul) async {
  //   final db = await DBHelper.database();
  //   print('pobieranie ula dla $ul');
  //   return db.rawQuery('SELECT  * FROM ramka WHERE ulId = ?', [ul]);
  // }

  // static Future<List<Map<String, dynamic>>> isFrame(String pasiekaId, String ulId) async {
  //   final db = await DBHelper.database();
  //   print('pobieranie id ramki dla PasiekaId = $pasiekaId');
  //   var ramka = await db.query("ramka",
  //       where: "pasiekaId=? and ulId=?", whereArgs: [pasiekaId, ulId]);
  //   //int wyn = ramka.isNotEmpty ? ramka.length : 0;
  //   return ramka;
  // }
  


/*
  //update polubienia dania
  static Future<void> updateFav(String id, String fav) async {
    final db = await DBHelper.database();
    print('update dania fav');
    db.update('dania', {'fav': fav}, where: 'id = ?', whereArgs: [id]);
  }

  //update koszyka/stolika dania - ilość dań w koszyku
  static Future<void> updateIle(String id, String ile) async {
    final db = await DBHelper.database();
    print('db_helpers: update dania - ile w koszyku da=$id ile=$ile');
    db.update('dania', {'stolik': ile}, where: 'id = ?', whereArgs: [id]);
  }

  //odczyt z bazy restauracji z unikalnymi województwami - dla location
  static Future<List<Map<String, dynamic>>> getWoj(String table) async {
    final db = await DBHelper.database();
    print('pobieranie wojewodztw z tabeli $table');
    return db
        .rawQuery('SELECT DISTINCT woj, wojId FROM $table ORDER BY woj ASC ');
  }

  //odczyt z bazy restauracji z unikalnymi miastami dla danego województwa - dla location
  static Future<List<Map<String, dynamic>>> getMia(String woj) async {
    final db = await DBHelper.database();
    print('pobieranie miast dla $woj');
    return db.rawQuery(
        'SELECT DISTINCT miasto, miaId FROM restauracje WHERE woj = ? ORDER BY miasto ASC',
        [woj]);
  }

  //odczyt z bazy restauracji dla danego miasta - dla location
  static Future<List<Map<String, dynamic>>> getRests(String miasto) async {
    final db = await DBHelper.database();
    print('pobieranie restauracji dla $miasto');
    return db.rawQuery(
        'SELECT  * FROM restauracje WHERE miasto = ? ORDER BY nazwa ASC',
        [miasto]);
  }

  //odczyt z bazy restauracji dla danego id - dla meal_item - potrzebne modMenu
  static Future<List<Map<String, dynamic>>> getRestWithId(String restId) async {
    final db = await DBHelper.database();
    print('db_helpers: pobieranie restauracji dla id = $restId');
    return db.rawQuery('SELECT  * FROM restauracje WHERE id = ?', [restId]);
  }

  //odczyt rekordu z bazy memory
  static Future<List<Map<String, dynamic>>> getMemory(String nazwa) async {
    final db = await DBHelper.database();
    print('pobieranie memory dla $nazwa');
    return db.rawQuery('SELECT  * FROM memory WHERE nazwa = ?', [nazwa]);
  }

  //czy jest danie o podanym id
  static Future<bool> isMeal(String daId) async {
    final db = await DBHelper.database();
    print('pobieranie dania dla daId = $daId');
    var danie = await db.query("dania", where: "id=?", whereArgs: [daId]);
    return danie.isNotEmpty ? true : false;
  }

  //pobranie dania o podanym id
  static Future<List<Map<String, dynamic>>>  getMeal(String daId) async {
    final db = await DBHelper.database();
    print('pobieranie dania dla daId = $daId');
    var danie = await db.query("dania", where: "id=?", whereArgs: [daId]);
    return danie.isNotEmpty ? db.rawQuery('SELECT  * FROM dania WHERE id = ?', [daId]) : null;
  }
*/

}
/*class DbHelper {
      static const NEW_DB_VERSION = 2;

      static final DbHelper _instance = DbHelper.internal();

      factory DbHelper() => _instance;

      DbHelper.internal();

      Database _db;

      Future<Database> get db async {
        if (_db != null) {
          return _db;
        } else {
          _db = await initDb();
          return _db;
        }
      }

      Future<Database> initDb() async {

        final databasesPath = await getDatabasesPath();
        final path = join(databasesPath, "database.db");

        var db = await openDatabase(path);

        //if database does not exist yet it will return version 0
        if (await db.getVersion() < NEW_DB_VERSION) {

          db.close();

          //delete the old database so you can copy the new one
          await deleteDatabase(path);

          try {
            await Directory(dirname(path)).create(recursive: true);
          } catch (_) {}

          //copy db from assets to database folder
          ByteData data = await rootBundle.load("assets/databases/database.db");
          List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          await File(path).writeAsBytes(bytes, flush: true);

          //open the newly created db 
          db = await openDatabase(path);

          //set the new version to the copied db so you do not need to do it manually on your bundled database.db
          db.setVersion(NEW_DB_VERSION);

        }

        return db;
      }*/
