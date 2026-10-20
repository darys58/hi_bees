import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import 'package:sqflite/sqlite_api.dart';
import '../globals.dart' as globals; //plikBazy() - własna baza albo baza właściciela (etap 2)
import 'kolor_przegladu.dart'; //kolor przeglądu po zmianie ramek
import '../models/apiarys.dart'; //przeładowanie kafelków pasiek po zmianie daty przeglądu

//metody statyczne w klasie są po to, zeby nie tworzyć instancji tej klasy
//ale pracować z tymi metodami jak z funkcjami. Klasa jest opakowaniem dla metod,
//które mogłyby być napisane jako funkcje poza ta klasą.

//dostep do bazy - otwarcie bazy lub utworzenie nowej jesli nie było.
class DBHelper {
  

  static Future<Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    final path = join(dbPath, globals.plikBazy()); //ściekzka do bazy i nazwa bazy (hibees.db albo hibees_XXXX.db - etap 2)

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
          'CREATE TABLE memory(id TEXT PRIMARY KEY, email TEXT, dev TEXT, wer TEXT, kod TEXT, key TEXT, od TEXT, do TEXT, memjezyk TEXT, mem1 Text, mem2 TEXT, token TEXT, stanowisko TEXT)');
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
      await db.execute(
          'CREATE TABLE powiadomienia(id INTEGER PRIMARY KEY AUTOINCREMENT, infoId TEXT, pasiekaNr INTEGER, ulNr INTEGER, kategoria TEXT, parametr TEXT, dni INTEGER, godzina INTEGER, minuta INTEGER, dataInfo TEXT, dataNotif TEXT, aktywne INTEGER)');
      await db.execute(_createNagrania);
      await db.execute(_createUsuniete);

      //    'CREATE TABLE podkategorie(id TEXT PRIMARY KEY, kolejnosc TEXT, kaId TEXT, nazwa TEXT)');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      try {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE notatki ADD COLUMN pole1 TEXT');
          await db.execute('ALTER TABLE notatki ADD COLUMN pole2 TEXT');
          await db.execute('ALTER TABLE notatki ADD COLUMN pole3 TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
              'CREATE TABLE IF NOT EXISTS zdjecia(id TEXT PRIMARY KEY, data TEXT, czas TEXT, pasiekaNr INTEGER, ulNr INTEGER, sciezka TEXT, uwagi TEXT, arch INTEGER)');
        }
        if (oldVersion < 4) {
          await db.execute(
              'CREATE TABLE IF NOT EXISTS powiadomienia(id INTEGER PRIMARY KEY AUTOINCREMENT, infoId TEXT, pasiekaNr INTEGER, ulNr INTEGER, kategoria TEXT, parametr TEXT, dni INTEGER, godzina INTEGER, minuta INTEGER, dataInfo TEXT, dataNotif TEXT, aktywne INTEGER)');
        }
        if (oldVersion < 5) {
          //nagrania dyktowanych notatek - patrz RecordingHelper
          await db.execute(_createNagrania);
        }
        if (oldVersion < 6) {
          //token urządzenia (etap 1b pkt 3, 06.10.2026) - zastępuje kod w żądaniach do chmury
          await db.execute('ALTER TABLE memory ADD COLUMN token TEXT');
        }
        if (oldVersion < 7) {
          //stanowisko instalacji w bazie (etap 2, 07.10.2026) - do unikalnych id wpisów, patrz insertZNowymId
          await db.execute('ALTER TABLE memory ADD COLUMN stanowisko TEXT');
        }
        if (oldVersion < 8) {
          //kolejka usunięć do chmury (16.10.2026) - patrz _createUsuniete
          await db.execute(_createUsuniete);
        }
      } catch (e) {
        debugPrint('Błąd migracji bazy danych (v$oldVersion -> v$newVersion): $e');
      }
    }, version: 8);
  }

  //Nagrania dyktowanych notatek. Zbudowane jak "zdjecia" (ten sam zestaw pól
  //kontekstowych), z trzema różnicami:
  // - "sciezka" to SAMA NAZWA pliku, nie ścieżka bezwzględna: katalog Documents
  //   na iOS zmienia identyfikator kontenera przy aktualizacji aplikacji,
  // - "zrodlo" + "powiazanieId" mówią, do czego nagranie jest przypięte:
  //   'inspection' -> id rekordu z tabeli info, 'notes' -> id z tabeli notatki,
  // - "arch" zostaje 0 na zawsze - nagrania NIE idą do chmury (decyzja z
  //   04.08.2026, przy 32 kB/s transfer byłby nieproporcjonalny do korzyści).
  static const String _createNagrania =
      'CREATE TABLE IF NOT EXISTS nagrania(id TEXT PRIMARY KEY, data TEXT, czas TEXT, '
      'pasiekaNr INTEGER, ulNr INTEGER, zrodlo TEXT, powiazanieId TEXT, sciezka TEXT, '
      'sekundy INTEGER, bajty INTEGER, tekst TEXT, uwagi TEXT, arch INTEGER)';

  //KOLEJKA USUNIĘĆ do chmury (16.10.2026, pliki/plan_synchronizacja_usuniec.md).
  //Każde usunięcie wiersza z tabel wysyłanych do chmury (ramka, info, zbiory, sprzedaz, zakupy,
  //notatki, matki, zdjecia) zapisuje tu jego id - bez względu na arch, bo arch = 0 znaczy
  //"jest zmiana do wysłania", a nie "nigdy nie wysłany". Kolejka idzie do cbt_hi_usuniete.php
  //PRZED wierszami w każdym eksporcie (UsunieteHelper.wyslij); serwer zapamiętuje tylko id,
  //które naprawdę miał. Kolejka nie jest częścią eksportu "wierszy".
  static const String _createUsuniete =
      'CREATE TABLE IF NOT EXISTS usuniete(tabela TEXT, id TEXT, data TEXT, PRIMARY KEY(tabela, id))';

  //tabele synchronizowane z chmurą - tylko z nich usunięcia trafiają do kolejki
  static const List<String> tabeleChmury = [
    'ramka', 'info', 'zbiory', 'sprzedaz', 'zakupy', 'notatki', 'matki', 'zdjecia'
  ];

  //zapis usuniętych id do kolejki - w tej samej bazie/transakcji co samo usunięcie
  //(db albo txn), żeby nie zgubić zgłoszenia
  static Future<void> zglosUsuniete(DatabaseExecutor db, String tabela, Iterable<Object?> idy) async {
    if (!tabeleChmury.contains(tabela) || idy.isEmpty) return;
    //błąd kolejki nie może zatrzymać samego usuwania (np. tabela nie powstała przy migracji)
    try {
      final teraz = DateTime.now().toString().substring(0, 19);
      final batch = db.batch();
      for (final id in idy) {
        final tekst = '${id ?? ''}';
        if (tekst.isEmpty) continue;
        batch.insert('usuniete', {'tabela': tabela, 'id': tekst, 'data': teraz},
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Kolejka usunięć - błąd zapisu: $e');
    }
  }

  //id wierszy spełniających warunek - przed usunięciem wielu wierszy naraz
  static Future<List<Object?>> _idyGdzie(DatabaseExecutor db, String tabela, String where, List<Object?> args) async {
    final w = await db.query(tabela, columns: ['id'], where: where, whereArgs: args);
    return w.map((e) => e['id']).toList();
  }

  //cała kolejka usunięć
  static Future<List<Map<String, dynamic>>> getUsuniete() async {
    final db = await DBHelper.database();
    return db.query('usuniete', orderBy: 'data');
  }

  //zdjęcie z kolejki wpisów przyjętych przez serwer
  static Future<void> usunZKolejki(List<Map<String, dynamic>> wpisy) async {
    if (wpisy.isEmpty) return;
    final db = await DBHelper.database();
    final batch = db.batch();
    for (final w in wpisy) {
      batch.delete('usuniete', where: 'tabela = ? AND id = ?', whereArgs: [w['tabela'], '${w['id']}']);
    }
    await batch.commit(noResult: true);
  }

  //Usunięcie lokalne wierszy wskazanych przez chmurę (import) albo przez własną kolejkę
  //(gdy jej wysłanie się nie udało - żeby import nie przywrócił usuniętych).
  //D2: wiersz z arch = 0 (niewysłana zmiana) zostaje; przy eksporcie wróci na serwer i zdejmie
  //swoje id z listy usuniętych. Bez zgłaszania do kolejki - to nie są nowe usunięcia.
  //Zwraca: pliki - ścieżki usuniętych zdjęć, których nie używa już żaden wiersz (do skasowania z dysku),
  //ule - "pasieka.ul" uli, z których usunięto ramki albo info (patrz usunPusteUle).
  static Future<({List<String> pliki, Set<String> ule})> usunWskazane(List<Map<String, String>> wpisy) async {
    final List<String> pliki = [];
    final Set<String> ule = {};
    if (wpisy.isEmpty) return (pliki: pliki, ule: ule);
    final db = await DBHelper.database();
    await db.transaction((txn) async {
      final Set<String> sciezki = {};
      const warunek = 'id = ? AND (arch IS NULL OR arch != 0)';
      for (final w in wpisy) {
        final tabela = w['tabela'] ?? '';
        final id = w['id'] ?? '';
        if (!tabeleChmury.contains(tabela) || id.isEmpty) continue;
        if (tabela == 'zdjecia') {
          final z = await txn.query('zdjecia', columns: ['sciezka'], where: warunek, whereArgs: [id]);
          for (final r in z) {
            final s = '${r['sciezka'] ?? ''}';
            if (s.isNotEmpty) sciezki.add(s);
          }
        } else if (tabela == 'ramka' || tabela == 'info') {
          final u = await txn.query(tabela, columns: ['pasiekaNr', 'ulNr'], where: warunek, whereArgs: [id]);
          for (final r in u) {
            ule.add('${r['pasiekaNr']}.${r['ulNr']}');
          }
        }
        await txn.delete(tabela, where: warunek, whereArgs: [id]);
      }
      //plik zdjęcia tylko wtedy, gdy żaden inny wiersz go nie wskazuje (przeniesiony ul: nowe id, ten sam plik)
      for (final s in sciezki) {
        final ile = await txn.rawQuery('SELECT COUNT(*) AS c FROM zdjecia WHERE sciezka = ?', [s]);
        if (((ile.first['c'] as int?) ?? 0) == 0) pliki.add(s);
      }
    });
    return (pliki: pliki, ule: ule);
  }

  //Po usunięciach z chmury: ul bez żadnej ramki i info znika (usunięty albo przeniesiony na innym
  //telefonie), a pasieka bez uli - też (jak przy usuwaniu ula w apiarys_screen). Tylko wskazane ule -
  //nowo dodany ul bez przeglądów na tym telefonie zostaje.
  static Future<void> usunPusteUle(Set<String> ule) async {
    if (ule.isEmpty) return;
    final db = await DBHelper.database();
    await db.transaction((txn) async {
      final Set<int> pasieki = {};
      for (final klucz in ule) {
        final cz = klucz.split('.');
        if (cz.length != 2) continue;
        final p = int.tryParse(cz[0]);
        final u = int.tryParse(cz[1]);
        if (p == null || u == null) continue;
        final r = await txn.rawQuery(
            'SELECT (SELECT COUNT(*) FROM ramka WHERE pasiekaNr = ? AND ulNr = ?) + '
            '(SELECT COUNT(*) FROM info WHERE pasiekaNr = ? AND ulNr = ?) AS c', [p, u, p, u]);
        if (((r.first['c'] as int?) ?? 0) > 0) continue;
        await txn.delete('ule', where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [p, u]);
        pasieki.add(p);
      }
      for (final p in pasieki) {
        final r = await txn.rawQuery('SELECT COUNT(*) AS c FROM ule WHERE pasiekaNr = ?', [p]);
        if (((r.first['c'] as int?) ?? 0) == 0) {
          await txn.delete('pasieki', where: 'pasiekaNr = ?', whereArgs: [p]);
        }
      }
    });
  }

  //id z listy, które istnieją lokalnie (wpis odtworzony z tym samym id) - tych nie wysyłamy jako usuniętych
  static Future<Set<String>> istniejaceId(String tabela, List<String> idy) async {
    final Set<String> wynik = {};
    if (!tabeleChmury.contains(tabela) || idy.isEmpty) return wynik;
    final db = await DBHelper.database();
    for (int i = 0; i < idy.length; i += 500) {
      final porcja = idy.sublist(i, i + 500 < idy.length ? i + 500 : idy.length);
      final w = await db.query(tabela, columns: ['id'],
          where: 'id IN (${_znakiZapytania(porcja.length)})', whereArgs: porcja);
      wynik.addAll(w.map((e) => '${e['id']}'));
    }
    return wynik;
  }

  static Future<void> deleteBase() async {
    final dbPath = await sql.getDatabasesPath();
   // print('DBHelper - kasowanie bazy danych');
    await sql.deleteDatabase(join(dbPath, globals.plikBazy()));
  }

//zapis do bazy
  static Future<void> insert(String table, Map<String, Object> data) async {
    final db = await DBHelper.database();
    //print('DBHelper - wstawianie do tabeli $table');
    await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //batch insert z konfliktem REPLACE, commit w chunkach - używane przy imporcie
  //chunkSize 500 = jeden commit = jeden fsync na 500 rekordów zamiast 1:1
  //zapis zwracający id wstawionego rekordu (rowid). Potrzebny tam, gdzie klucz
  //jest AUTOINCREMENT i dopiero po zapisie wiadomo, do czego przypiąć załącznik
  //- np. nagranie dyktowanej notatki w Notesie (patrz RecordingHelper).
  //NOWY WPIS Z UNIKALNYM ID - notatki, zbiory, zakupy, sprzedaż, matki (etap 2, 07.10.2026).
  //Dotąd id nadawał SQLite (największe + 1), więc dwa telefony piszące do jednej bazy w chmurze
  //nadawały te same numery, a eksport (DELETE + INSERT po id na serwerze) nadpisywał cudze wpisy.
  //    id = (największe id w tabeli div 100 + 1) * 100 + stanowisko
  //stanowisko 1..99 = numer tej instalacji w bazie, z serwera (be_stanowisko); 0 = jeszcze nieznany.
  //Ostatnie dwie cyfry różnią instalacje, licznik rośnie z czasem (także po imporcie cudzych wpisów),
  //więc "aktualna matka = największe id" działa dalej. Stare wpisy zostają ze starymi numerami -
  //nowe są zawsze większe. Odczyt MAX i zapis w jednej transakcji.
  static Future<int> insertZNowymId(String table, Map<String, Object> data, int stanowisko) async {
    final db = await DBHelper.database();
    return db.transaction((txn) async {
      final wynik = await txn.rawQuery('SELECT MAX(id) AS m FROM $table');
      final int max = int.tryParse('${wynik.first['m'] ?? 0}') ?? 0;
      final int st = (stanowisko >= 0 && stanowisko <= 99) ? stanowisko : 0;
      final int id = (max ~/ 100 + 1) * 100 + st;
      final Map<String, Object> wiersz = Map<String, Object>.from(data);
      wiersz['id'] = id;
      await txn.insert(table, wiersz, conflictAlgorithm: ConflictAlgorithm.abort);
      return id;
    });
  }

  //podmiana wiersza konta w memory BIEŻĄCEGO pliku bazy (przełączanie baz, etap 2) - w jednej transakcji,
  //bo deleteTable nie czeka na skasowanie
  static Future<void> zastapKonto(Map<String, Object?> wiersz) async {
    final db = await DBHelper.database();
    await db.transaction((txn) async {
      await txn.delete('memory');
      await txn.insert('memory', wiersz);
    });
  }

  static Future<int> insertZwrocId(String table, Map<String, Object> data) async {
    final db = await DBHelper.database();
    return db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<int> batchInsert(
    String table,
    List<Map<String, Object?>> rows, {
    int chunkSize = 500,
    void Function(int current, int total)? onProgress,
  }) async {
    final total = rows.length;
    if (total == 0) return 0;
    final db = await DBHelper.database();
    for (int i = 0; i < total; i += chunkSize) {
      final end = (i + chunkSize < total) ? i + chunkSize : total;
      final batch = db.batch();
      for (int j = i; j < end; j++) {
        batch.insert(table, rows[j], conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      if (onProgress != null) {
        onProgress(end, total);
        await Future.delayed(Duration.zero);
      }
    }
    return total;
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

  //Oznaczenie jako wysłanych (arch = 1) TYLKO wierszy z wysłanej paczki (16.10.2026). Dotąd po wysłaniu
  //czytano z bazy wszystkie arch = 0 od nowa, więc wpis dodany w trakcie wysyłania (auto-eksport w tle
  //przy starcie + polecenie głosowe) dostawał arch = 1, choć nie poszedł do chmury.
  static Future<void> oznaczWyslane(String tabela, Iterable<Object?> idy) async {
    if (idy.isEmpty) return;
    final db = await DBHelper.database();
    final batch = db.batch();
    for (final id in idy) {
      batch.update(tabela, {'arch': 1}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  //update tabeli ramki - rekord zarchiwizowany - dla import_screen
  static Future<void> updateRamkaArch(String id) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update ramka - id=$id');
    db.update('ramka', {'arch': 1}, where: 'id = ?', whereArgs: [id]);
  }

  //Zmiany "w miejscu" (to samo id) ustawiają arch = 0 - inaczej nie trafiłyby do chmury
  //(eksport "wyślij nowe" bierze tylko arch = 0), 16.10.2026.

  //update tabeli ramki - przeniesienie ramki do innego korpusa - dla voice_screen
  static Future<void> moveRamkaToBody(String id, int ul, int korpus, int ramka) async {
    final db = await DBHelper.database();
    //print('db_helpers: przenieś ramka - id=$id, ulNr=$ul, korpusNr=$korpus, ramkaNr = $ramka');
    await db.update('ramka', {'ulNr': ul, 'korpusNr': korpus, 'typ': 2, 'ramkaNr': 0, 'ramkaNrPo': ramka, 'arch': 0}, where: 'id = ?', whereArgs: [id]);
    zaplanujKolorPrzegladuRamki(id, ulDocelowy: ul); //kolor przeglądu obu uli
  }

  //update tabeli ramki - przeniesienie ramki do innego półkorpusa - dla voice_screen
  static Future<void> moveRamkaToHalfBody(String id, int ul, int korpus, int ramka) async {
    final db = await DBHelper.database();
    //print('db_helpers: przenieś ramka - id=$id, ulNr=$ul, korpusNr=$korpus, ramkaNr = $ramka');
    await db.update('ramka', {'ulNr': ul, 'korpusNr': korpus, 'typ': 1, 'ramkaNr': 0, 'ramkaNrPo': ramka, 'arch': 0}, where: 'id = ?', whereArgs: [id]);
    zaplanujKolorPrzegladuRamki(id, ulDocelowy: ul); //kolor przeglądu obu uli
  }
  
  //update tabeli ramki - ustawienie "ramkaNrPo" - dla frame_edit_screen i voice_screen
  static Future<void> updateRamkaNrPo(String id, int ramkaNrPo) async {
    final db = await DBHelper.database();
    //print('db_helpers: update ramkaNrPo - id=$id, ramkaNrPo = $ramkaNrPo');
    await db.update('ramka', {'ramkaNrPo': ramkaNrPo, 'arch': 0}, where: 'id = ?', whereArgs: [id]);
    zaplanujKolorPrzegladuRamki(id); //ramka usunięta (po = 0) przestaje liczyć się do koloru
  }

   //update tabeli ramki - ustawienie "ramkaNr" - dla frame_edit_screen? i voice_screen
  static Future<void> updateRamkaNr(String id, int ramkaNr) async {
    final db = await DBHelper.database();
    //print('db_helpers: update ramkaNr - id=$id, ramkaNr = $ramkaNr');
    db.update('ramka', {'ramkaNr': ramkaNr, 'arch': 0}, where: 'id = ?', whereArgs: [id]);
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
    await db.update('info', {'wartosc': wart, 'arch': 0}, where: 'id = ?', whereArgs: [id]);
  }

  //wartość rekordu info (null = nie ma rekordu) - kolor przeglądu (kolor_przegladu.dart)
  static Future<String?> getInfoWartosc(String id) async {
    final db = await DBHelper.database();
    final result = await db.query('info', columns: ['wartosc'], where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isEmpty ? null : result[0]['wartosc'] as String?;
  }

  //zadania (13), mateczniki (11) i usunięte mateczniki (12) z ramek przeglądu - widok "po"
  //(ramkaNrPo <> 0, jak belka), wszystkie korpusy - kolor przeglądu (kolor_przegladu.dart)
  static Future<List<Map<String, dynamic>>> getZadaniaIMatecznikiPrzegladu(String data, int pasieka, int ul) async {
    final db = await DBHelper.database();
    return db.rawQuery(
        'SELECT zasob, wartosc FROM ramka WHERE data = ? AND pasiekaNr = ? AND ulNr = ? '
        'AND zasob IN (11, 12, 13) AND ramkaNrPo <> 0',
        [data, pasieka, ul]);
  }

  //mateczniki, usunięte mateczniki i zadania z OSTATNIEGO przeglądu każdego korpusu każdego
  //ula pasieki (widok "po") - podsumowanie widoku uli z problemami (problemy_pasieki.dart)
  static Future<List<Map<String, dynamic>>> getZadaniaIMatecznikiPasieki(int pasieka) async {
    final db = await DBHelper.database();
    return db.rawQuery(
        'SELECT r.ulNr, r.korpusNr, r.ramkaNr, r.zasob, r.wartosc FROM ramka r '
        'JOIN (SELECT ulNr, korpusNr, MAX(data) AS d FROM ramka WHERE pasiekaNr = ? '
        'GROUP BY ulNr, korpusNr) o ON r.ulNr = o.ulNr AND r.korpusNr = o.korpusNr AND r.data = o.d '
        'WHERE r.pasiekaNr = ? AND r.zasob IN (11, 12, 13) AND r.ramkaNrPo <> 0',
        [pasieka, pasieka]);
  }

  //uwagi z rekordu info - dla dyktowanej notatki (voice_vosk_screen)
  //null = NIE MA takiego rekordu (a '' = rekord jest, tylko bez uwag). Ta
  //różnica decyduje, czy notatkę dopisać, czy najpierw utworzyć przegląd.
  static Future<String?> getInfoUwagi(String id) async {
    final db = await DBHelper.database();
    final result = await db.query('info',
      columns: ['uwagi'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return (result[0]['uwagi'] ?? '').toString();
  }

  //update tabeli info - same uwagi - dla dyktowanej notatki (voice_vosk_screen)
  //UWAGA: notatki NIE WOLNO zapisywać przez Infos.insertInfo. Rekord przeglądu
  //ma składane id, a DBHelper.insert to ConflictAlgorithm.replace - wstawienie
  //"tylko uwag" wyzerowałoby w nim czas, wartość i temperaturę.
  //arch = 0: wpis wysłany już do chmury (auto-eksport) bez tego nie pojechałby
  //drugi raz i dopisana uwaga zostałaby tylko na telefonie.
  static Future<void> updateInfoUwagi(String id, String uwagi) async {
    final db = await DBHelper.database();
    await db.update('info', {'uwagi': uwagi, 'arch': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  //Zapis wpisu info z ZACHOWANIEM istniejących uwag - dla sterowania głosem.
  //Głos zapisuje wpisy z pustymi uwagami, a id jest składane (data.pasieka.ul.
  //kategoria.parametr) i insert to ConflictAlgorithm.replace. Bez tego „rodzina ok",
  //„zanotuj ...", a potem „rodzina słaba" tego samego dnia kasowało uwagę.
  //Odczyt i zapis w jednej transakcji - zapisy w ekranie głosowym nie są awaitowane.
  static Future<void> insertInfoZachowujacUwagi(Map<String, Object> data) async {
    final db = await DBHelper.database();
    await db.transaction((txn) async {
      final Map<String, Object> wiersz = Map<String, Object>.from(data);
      if ('${wiersz['uwagi'] ?? ''}'.isEmpty) {
        final stary = await txn.query('info',
            columns: ['uwagi'], where: 'id = ?', whereArgs: [wiersz['id']], limit: 1);
        if (stary.isNotEmpty) {
          final String uwagi = (stary[0]['uwagi'] ?? '').toString();
          if (uwagi.isNotEmpty) wiersz['uwagi'] = uwagi;
        }
      }
      await txn.insert('info', wiersz, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  //Wpisy info, do których komenda „zanotuj" dopisuje notatkę: ostatni zapis głosem
  //(data, pasieka, kategoria, parametr). [ule] puste = wszystkie ule pasieki (tryb
  //„wszystkie ule"), inaczej tylko te numery. Posortowane po numerze ula.
  static Future<List<Map<String, dynamic>>> getInfoDoUwagi(String data,
      int pasieka, String kategoria, String parametr, List<int> ule) async {
    final db = await DBHelper.database();
    String where = 'data = ? AND pasiekaNr = ? AND kategoria = ? AND parametr = ?';
    final List<Object> args = [data, pasieka, kategoria, parametr];
    if (ule.isNotEmpty) {
      where += ' AND ulNr IN (${List.filled(ule.length, '?').join(',')})';
      args.addAll(ule);
    }
    return db.query('info',
        columns: ['id', 'ulNr', 'uwagi'],
        where: where,
        whereArgs: args,
        orderBy: 'ulNr');
  }

  //update pasieki- ilość uli w pasiece - dla voice_screen
  static Future<void> updateIleUli(int pasieka, int ile) async {
    final db = await DBHelper.database();
    //print('db_helpers: update pasieki - ile uli w pasiece $pasieka ile=$ile');
    db.update('pasieki', {'ileUli': ile},
        where: 'pasiekaNr = ?', whereArgs: [pasieka]);
  }

  //update pasieki - data ostatniego przeglądu - dla notatki dyktowanej głosem.
  //Osobna metoda zamiast Apiarys.insertApiary: insert to ConflictAlgorithm.replace
  //po id, więc przepisałby przy okazji ileUli, ikonę i opis - notatka nie ma o nich
  //pojęcia i wstawiłaby tam wartości zastępcze.
  //DATA PRZEGLĄDU PASIEKI (20.10.2026) = najnowszy przegląd ramek w pasiece - patrz
  //getDataPrzegladuPasieki; [data] tylko gdy pasieka nie ma jeszcze żadnych ramek.
  static Future<void> updatePrzegladPasieki(int pasieka, String data) async {
    final db = await DBHelper.database();
    await db.update('pasieki', {'przeglad': await getDataPrzegladuPasieki(pasieka) ?? data},
        where: 'pasiekaNr = ?', whereArgs: [pasieka]);
  }

  //DATA PRZEGLĄDU PASIEKI (20.10.2026) - dni od przeglądu na kafelku pasieki (apiarys_item).
  //Do 20.10.2026 pole pasieki.przeglad nadpisywał każdy zapis własną datą (wpis z datą
  //wsteczną cofał ją, odświeżanie dokarmiania/leczenia wpisywało dzisiejszą) - teraz jest
  //to zawsze najnowsza data przeglądu ramek w pasiece. null - pasieka bez ramek.
  static Future<String?> getDataPrzegladuPasieki(int pasieka) async {
    final db = await DBHelper.database();
    final r = await db.rawQuery('SELECT MAX(data) AS d FROM ramka WHERE pasiekaNr = ?', [pasieka]);
    final d = r.isEmpty ? null : r.first['d'] as String?;
    return (d == null || d.isEmpty) ? null : d;
  }

  //przeliczenie daty przeglądu pasieki po usunięciu/przeniesieniu ramek
  //(pasieka bez ramek - data zostaje)
  static Future<void> odswiezPrzegladPasieki(int pasieka) async {
    final d = await getDataPrzegladuPasieki(pasieka);
    if (d == null) return;
    final db = await DBHelper.database();
    await db.update('pasieki', {'przeglad': d}, where: 'pasiekaNr = ?', whereArgs: [pasieka]);
    await Apiarys.przeladujBiezacy(); //kafelek pasieki na ekranie startowym
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

  //update memory - mem1 (widoczność kategorii w Aktualności ula)
  static Future<void> updateMem1(String dev, String text) async {
    final db = await DBHelper.database();
    db.update('memory', {'mem1': text}, where: 'dev = ?', whereArgs: [dev]);
  }

  //update memory - mem2 (ostatnio zaproponowana użytkownikowi wersja apki - anty-spam dialogu o aktualizacji)
  static Future<void> updateMem2(String dev, String text) async {
    final db = await DBHelper.database();
    db.update('memory', {'mem2': text}, where: 'dev = ?', whereArgs: [dev]);
  }

  //update memory - pola konta z serwera (key, od, do) - synchronizacja przy starcie apki
  //(apiarys_screen: _synchronizujKonto). Po id, nie po dev - id to be_id z serwera.
  static Future<void> updateKonto(String id, Map<String, String> pola) async {
    final db = await DBHelper.database();
    await db.update('memory', pola, where: 'id = ?', whereArgs: [id]);
  }

  //update dodatki1 - dla import_screen
  static Future<void> updateDodatki1(String pole, String wartosc) async {
    final db = await DBHelper.database();
  //  print('db_helpers: update dodatki1 - pole = $pole , wartość = $wartosc ');
    db.update('dodatki1', {'$pole': wartosc}, where: 'id = ?', whereArgs: ['1']);
  }

  //przeniesienie matek z jednego ula do drugiego - dla move_hive_screen
  static Future<void> moveQueens(int srcPasieka, int srcUl, int dstPasieka, int dstUl) async {
    final db = await DBHelper.database();
    await db.update('matki', {'pasieka': dstPasieka, 'ul': dstUl, 'arch': 0},
        where: 'pasieka = ? AND ul = ?', whereArgs: [srcPasieka, srcUl]);
  }

  //update matki - dla import_screen
  static Future<void> updateQueen(int id, String pole, int wartosc) async {
    final db = await DBHelper.database();
    //print('db_helpers: update matki $id: pole = $pole , wartość = $wartosc ');
    db.update('matki', {'$pole': wartosc}, where: 'id = ?', whereArgs: [id]);
  }

//update ule, pola np. ikona - dla import_screen
  //await przy db.update: wołający, który CZEKA na tę metodę i zaraz potem czyta
  //ule z bazy (notatka głosowa przestawiająca datę przeglądu), bez tego czytałby
  //stan sprzed zapisu. Wołającym "wystrzel i zapomnij" nic to nie zmienia.
  static Future<void> updateUle(String id, String pole, String wartosc) async {
    final db = await DBHelper.database();
    //print('db_helpers: update ule $id: pole = $pole , wartość = $wartosc ');
    await db.update('ule', {'$pole': wartosc}, where: 'id = ?', whereArgs: [id]);
  }

  //batch update pojedynczego pola w tabeli ule - używane przy przywracaniu po imporcie
  //kolumn, których nie da się odtworzyć z serwera: h3 (tagi NFC), h2 (typ ula), h1 (rodzaj)
  //tylkoGdyPuste = kopia lokalna tylko ŁATA DZIURY po odbudowie z info, a nie nadpisuje jej.
  //Dla h1/h2 to istotne: lokalna wartość sama bywa pamiątką po starszym imporcie, więc
  //gdy info niesie rodzaj/typ, to ono ma rację - inaczej raz zepsuta belka nigdy by się
  //nie naprawiła. Dla h3 (NFC) serwer nie ma nic, więc dziura jest zawsze.
  static Future<void> batchUpdateUleField(String field, Map<String, String> entries,
      {bool tylkoGdyPuste = false}) async {
    if (entries.isEmpty) return;
    final db = await DBHelper.database();
    final batch = db.batch();
    final warunek = tylkoGdyPuste
        ? "id = ? AND ($field IS NULL OR $field = '' OR $field = '0')"
        : 'id = ?';
    for (final entry in entries.entries) {
      batch.update('ule', {field: entry.value}, where: warunek, whereArgs: [entry.key]);
    }
    await batch.commit(noResult: true);
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

  //update ula w tabeli ule - liczba ramek korpusu (voice_vosk_screen,
  //setEquipment "number of frames in body"). Dopisane 03.09.2026: komenda
  //głosowa zapisywała wpis "info" (widoczny w historii), ale samo pole
  //ule.ramek nigdy się nie zmieniało - zapisDoBazy() w voice_vosk_screen.dart,
  //jedyne miejsce, które je stosowało, jest wołane WYŁĄCZNIE przy zapisie
  //zasobu ramki (setStore), a nie przy tej komendzie. Ręczna edycja
  //(infos_edit_screen) aktualizuje ule.ramek bezpośrednio, stąd różnica.
  static Future<void> updateUleRamek(String id, int wartosc) async {
    final db = await DBHelper.database();
    db.update('ule', {'ramek': wartosc}, where: 'id = ?', whereArgs: [id]);
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

  //LOKALIZACJE PASIEK W CHMURZE (08.10.2026, helpers/ustawienia_bazy.dart) - z tabeli pogoda
  //bierzemy tylko miejsce (miasto, współrzędne); temp/ikona/pobranie to podręczna pogoda telefonu.
  static Future<List<Map<String, dynamic>>> getLokalizacjePasiek() async {
    final db = await DBHelper.database();
    return db.rawQuery('SELECT id, miasto, latitude, longitude FROM pogoda');
  }

  //lokalizacja z chmury: istniejący wpis - zmiana samego miejsca (przy innym miejscu pogoda do
  //ponownego pobrania); brak wpisu - nowy z pustą pogodą. Zwraca, czy coś się zmieniło.
  static Future<bool> zapiszLokalizacjePasieki(
      String id, String miasto, String latitude, String longitude, String lang) async {
    final db = await DBHelper.database();
    final rows = await db.query('pogoda', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final r = rows.first;
      if (r['miasto'] == miasto && r['latitude'] == latitude && r['longitude'] == longitude) return false;
      await db.update('pogoda',
          {'miasto': miasto, 'latitude': latitude, 'longitude': longitude, 'pobranie': '0000-00-00 00:00'},
          where: 'id = ?', whereArgs: [id]);
      return true;
    }
    await db.insert('pogoda', {
      'id': id, 'miasto': miasto, 'latitude': latitude, 'longitude': longitude,
      'pobranie': '0000-00-00 00:00', 'temp': '', 'weatherId': '', 'icon': '',
      'units': 1, 'lang': lang, 'inne': '',
    });
    return true;
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

  //znaki zapytania dla "parametr IN (...)"
  static String _znakiZapytania(int ile) => List.filled(ile, '?').join(',');

  //NOWE RAMKI Z WĘZĄ (15.10.2026) - ramka WSTAWIONA w przeglądzie (przed = 0, po > 0;
  //tak zapisuje ją formularz i głos "wstaw ramkę numer X") z węzą - zasob 8 (NIE 9 -
  //to susz; komentarz w models/frame.dart miał je zamienione, poprawione 15.10.2026).
  //Jedna ramka = jeden wiersz (DISTINCT bez strony), więc węza na obu stronach albo
  //w kolejnych przeglądach (ta ramka ma wtedy przed > 0) nie liczy się podwójnie.
  static Future<List<Map<String, dynamic>>> getNoweRamkiZWeza(int pasieka, int ul) async {
    final db = await DBHelper.database();
    return db.rawQuery(
        'SELECT DISTINCT data, korpusNr, ramkaNrPo FROM ramka WHERE pasiekaNr = ? AND ulNr = ? '
        "AND zasob = 8 AND ramkaNr = 0 AND ramkaNrPo > 0 "
        "AND wartosc NOT IN ('', '0', '0%')", //wartość zapisywana z "%", np. "100%"
        [pasieka, ul]);
  }

  //wpisy o stanie rodziny ("rodzina jest", parametry we wszystkich językach) - do
  //koloru ikony na belce ula (colony_helpers.stanyRodzinUli); pasieka null = wszystkie
  static Future<List<Map<String, dynamic>>> getStanyRodziny(Iterable<String> parametry, Object? pasieka) async {
    if (parametry.isEmpty) return [];
    final db = await DBHelper.database();
    return db.rawQuery(
        'SELECT pasiekaNr, ulNr, wartosc, data, czas FROM info WHERE wartosc <> \'\' '
        'and parametr IN (${_znakiZapytania(parametry.length)})'
        '${pasieka != null ? ' and pasiekaNr = ?' : ''}',
        [...parametry, if (pasieka != null) pasieka]);
  }

  //Liczba ramek (ramek), rodzaj (h1) i typ ula (h2) w tabeli "ule" z NAJNOWSZEGO
  //(data, czas) wpisu "liczba ramek =" ula - jedynego nośnika tych danych.
  //parametry: wersje językowe parametru (wszystkieJezyki z parametr_nazwy.dart).
  //Do 05.10.2026 belkę ustawiał każdy pisarz osobno, z wartości, którą akurat miał:
  //wpis z wcześniejszą datą, edycja starego wpisu, usunięcie wpisu, dane ula
  //nieodświeżone po zapisie głosem - belka pokazywała wtedy poprzednią liczbę ramek.
  //Brak wpisu = nic nie zmieniamy; puste pogoda/miara (stare wpisy głosowe) nie kasują rodzaju/typu.
  static Future<void> przeliczRamkiZInfo(int pasieka, int ul, Iterable<String> parametry) async {
    if (parametry.isEmpty) return;
    final db = await DBHelper.database();
    final rows = await db.rawQuery(
        'SELECT wartosc, pogoda, miara FROM info WHERE pasiekaNr = ? and ulNr = ? and kategoria = ? '
        'and parametr IN (${_znakiZapytania(parametry.length)}) ORDER BY data DESC, czas DESC LIMIT 1',
        [pasieka, ul, 'equipment', ...parametry]);
    if (rows.isEmpty) return;
    final ramek = int.tryParse((rows[0]['wartosc'] as String?) ?? '');
    final rodzaj = (rows[0]['pogoda'] as String?) ?? '';
    final typ = (rows[0]['miara'] as String?) ?? '';
    final zmiany = <String, Object?>{
      if (ramek != null) 'ramek': ramek,
      if (rodzaj.isNotEmpty) 'h1': rodzaj,
      if (typ.isNotEmpty) 'h2': typ,
    };
    if (zmiany.isEmpty) return;
    await db.update('ule', zmiany, where: 'id = ?', whereArgs: ['$pasieka.$ul']);
  }

  //odczyt z bazy info z unikalnymi datami dla danego ula, pasieki, kategorii, parametru - dla hives_screen
  //parametry: WSZYSTKIE wersje językowe parametru (wszystkieJezyki z parametr_nazwy.dart),
  //bo info.parametr jest zapisany w języku z chwili zapisu
  static Future<List<Map<String, dynamic>>> getDateInfo(int pasieka, int ul, String kategoria, Iterable<String> parametry) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dat info dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT data FROM info WHERE pasiekaNr=? and ulNr = ? and kategoria = ? and parametr IN (${_znakiZapytania(parametry.length)}) ORDER BY data DESC',
        [pasieka, ul, kategoria, ...parametry]);
  }

  //odczyt z bazy info z unikalnymi datami dla danego ula, pasieki i kategorii feeding lub treatment - dla hives_screen
  //kategoria: '' - dokarmianie LUB leczenie (razem), 'feeding' - tylko dokarmianie, 'treatment' - tylko leczenie
  static Future<List<Map<String, dynamic>>> getDateInfoDL(int pasieka, int ul,
      {String kategoria = ''}) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dat infoDL dla ula nr $ul');
    if (kategoria.isNotEmpty) {
      return db.rawQuery(
          'SELECT DISTINCT data FROM info WHERE pasiekaNr=? and ulNr = ? and kategoria = ? ORDER BY data DESC',
          [pasieka, ul, kategoria]);
    }
    return db.rawQuery(
        'SELECT DISTINCT data FROM info WHERE pasiekaNr=? and ulNr = ? and (kategoria = ? or kategoria = ?) ORDER BY data DESC',
        [pasieka, ul,'feeding','treatment']);
  }

  //odczyt z bazy info z unikalnymi datami dla danego ula, pasieki i kategorii harvest - dla hives_screen
  static Future<List<Map<String, dynamic>>> getDateInfoZkg(int pasieka, int ul, Iterable<String> parametry) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dat infoDL dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT data FROM info WHERE pasiekaNr=? and ulNr = ? and kategoria = ? and parametr IN (${_znakiZapytania(parametry.length)}) ORDER BY data DESC',
        [pasieka, ul,'harvest', ...parametry]);
  } 

  //odczyt z bazy info z unikalnymi datami dla danego ula, pasieki i kategorii harvest - dla hives_screen
  static Future<List<Map<String, dynamic>>> getDateInfoZmr(int pasieka, int ul, Iterable<String> parametry) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dat infoDL dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT data FROM info WHERE pasiekaNr=? and ulNr = ? and kategoria = ? and parametr IN (${_znakiZapytania(parametry.length)}) ORDER BY data DESC',
        [pasieka, ul,'harvest', ...parametry]);
  }

   //odczyt z bazy info z unikalnymi datami dla danego ula, pasieki i kategorii harvest - dla hives_screen
  static Future<List<Map<String, dynamic>>> getDateInfoZdr(int pasieka, int ul, Iterable<String> parametry) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie dat infoDL dla ula nr $ul');
    return db.rawQuery(
        'SELECT DISTINCT data FROM info WHERE pasiekaNr=? and ulNr = ? and kategoria = ? and parametr IN (${_znakiZapytania(parametry.length)}) ORDER BY data DESC',
        [pasieka, ul,'harvest', ...parametry]);
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

  //Wpisy o JEDNEJ matce ze WSZYSTKICH pasiek i uli - kolumna info.pogoda
  //trzyma dla kategorii "queen" matkaID. Potrzebne po przełożeniu matki do
  //innego ula: cechy (jakość, unasiennienie, ograniczenie, rocznik) zostają
  //przy wpisach zrobionych w ulu POPRZEDNIM, a nowy ul ma na starcie tylko
  //wpis o znaku. Sortowanie jak w getInfosOfHive - najnowsze pierwsze.
  static Future<List<Map<String, dynamic>>> getInfosOfQueen(String matkaID) async {
    final db = await DBHelper.database();
    return db.query("info",
        where: "kategoria='queen' and pogoda=? ORDER BY data DESC, czas DESC",
        whereArgs: [matkaID]);
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
  //gdzie siedzi matka wg tabeli matek (pasieka, ul) - pusta lista, gdy nie ma takiej matki
  static Future<List<Map<String, dynamic>>> getMiejsceMatki(int id) async {
    final db = await DBHelper.database();
    return db.rawQuery('SELECT pasieka, ul FROM matki WHERE id = ?', [id]);
  }

  static Future<List<Map<String, dynamic>>> getQueens() async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie matek');
    return db.rawQuery('SELECT * FROM matki ORDER BY id DESC');
  }

  //żyjące matki ula (bez daty straty) - kilka matek w ulu (queen_helpers.idMatekUla)
  static Future<List<Map<String, dynamic>>> getZyweMatkiUla(int pasieka, int ul) async {
    final db = await DBHelper.database();
    return db.rawQuery(
        "SELECT * FROM matki WHERE pasieka = ? AND ul = ? "
        "AND (dataStraty IS NULL OR dataStraty = '' OR dataStraty = '0') ORDER BY id",
        [pasieka, ul]);
  }

  //liczba żyjących matek w każdym ulu - licznik "×2" na belce ula
  static Future<List<Map<String, dynamic>>> getIleZywychMatekWUlach() async {
    final db = await DBHelper.database();
    return db.rawQuery(
        "SELECT pasieka, ul, COUNT(*) AS ile FROM matki WHERE ul > 0 "
        "AND (dataStraty IS NULL OR dataStraty = '' OR dataStraty = '0') GROUP BY pasieka, ul");
  }

  //odczyt ID matki tabeli matki  - dla infos_screen
  static Future<List<Map<String, dynamic>>> getQueenID(int pasieka, int ul,) async {
    final db = await DBHelper.database();
  //  print('DBHelper - pobieranie ID matki dla ula x');
    //Matka utracona (dataStraty) zostaje w tabeli z numerem pasieki i ula, więc ul
    //może mieć kilka matek. Bez ORDER BY SQLite zwracał najstarszą (zwykle pierwszą
    //matkę ula), a nie aktualną. Najpierw żyjące, potem najnowsze - tak jak
    //ekrany czytające z providera Queens (ORDER BY id DESC).
    return db.rawQuery(
        "SELECT id FROM matki WHERE pasieka=? and ul = ? "
        "ORDER BY (dataStraty IS NULL OR dataStraty = '' OR dataStraty = '0') DESC, id DESC",
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

  //sprawdzenie czy rekord inspekcji istnieje w bazie (bezpośrednio, nie przez provider)
  //parametry: wersje językowe parametru przeglądu (wszystkieJezyki((l) => l.inspection)).
  //Do 05.10.2026 tylko bieżący język - przegląd zapisany przy innym języku nie był
  //znajdowany i tego samego dnia powstawał DRUGI wpis przeglądu (id z innym parametrem).
  static Future<bool> inspectionExists(String data, int pasieka, int ul, Iterable<String> parametry) async {
    return (await inspectionId(data, pasieka, ul, parametry)) != null;
  }

  //id istniejącego wpisu przeglądu (data, pasieka, ul) w dowolnym języku albo null -
  //żeby dopisywać do niego (notatka dyktowana), a nie zakładać drugi
  static Future<String?> inspectionId(String data, int pasieka, int ul, Iterable<String> parametry) async {
    if (parametry.isEmpty) return null;
    final db = await DBHelper.database();
    final result = await db.query('info',
      columns: ['id'],
      where: 'data = ? AND pasiekaNr = ? AND ulNr = ? AND kategoria = ? AND parametr IN (${_znakiZapytania(parametry.length)})',
      whereArgs: [data, pasieka, ul, 'inspection', ...parametry],
      limit: 1,
    );
    return result.isEmpty ? null : result[0]['id'] as String?;
  }

  //usuniecie rekordu z tabeli info - dla frame_screen
  static Future<void> deleteInfo(String id) async {
    final db = await DBHelper.database();
    //print('DBhelper: delete info id = $id');
    await db.delete('info', where: 'id= ?', whereArgs: [id]);
    await zglosUsuniete(db, 'info', [id]); //kolejka usunięć do chmury
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
    await db.delete('ramka', where: 'id= ?', whereArgs: [id]);
    await zglosUsuniete(db, 'ramka', [id]); //kolejka usunięć do chmury
    zaplanujKolorPrzegladuRamki(id); //kolor przeglądu z zadań i mateczników
    final pasieka = int.tryParse(id.split('.').length > 1 ? id.split('.')[1] : '');
    if (pasieka != null) await odswiezPrzegladPasieki(pasieka); //data przeglądu pasieki
  }

  //usuniecie rekordu o podanym id z tabeli zbiory - dla harvest_edit_screen, harvest_item
  static Future<void> deleteZbiory(int id) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete zbiory id = $id');
    await db.delete('zbiory', where: 'id= ?', whereArgs: [id]);
    await zglosUsuniete(db, 'zbiory', [id]); //kolejka usunięć do chmury
  }

  //usuniecie rekordu o podanym id z tabeli notatki - dla notes_edit_screen, harvest_item
  static Future<void> deleteNotatki(int id) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete notatki id = $id');
    await db.delete('notatki', where: 'id= ?', whereArgs: [id]);
    await zglosUsuniete(db, 'notatki', [id]); //kolejka usunięć do chmury
  }

   //usuniecie rekordu o podanym id z tabeli matki - dla queen_item (15.10.2026:
  //tylko matka BEZ historii, patrz matkaBezHistorii w queen_item)
  static Future<void> deleteQueen(int id) async {
    final db = await DBHelper.database();
    await db.delete('matki', where: 'id= ?', whereArgs: [id]);
    await zglosUsuniete(db, 'matki', [id]); //kolejka usunięć do chmury
  }

  //usuniecie rekordu o podanym id z tabeli sprzedaz - dla sale_edit_screen, sale_item
  static Future<void> deleteSprzedaz(int id) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete sprzedaz id = $id');
    await db.delete('sprzedaz', where: 'id= ?', whereArgs: [id]);
    await zglosUsuniete(db, 'sprzedaz', [id]); //kolejka usunięć do chmury
  }

  //usuniecie rekordu o podanym id z tabeli zakupy - dla sale_edit_screen, sale_item
  static Future<void> deleteZakupy(int id) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete zakupy id = $id');
    await db.delete('zakupy', where: 'id= ?', whereArgs: [id]);
    await zglosUsuniete(db, 'zakupy', [id]); //kolejka usunięć do chmury
  }

  //usuniecie rekordów z tabeli ramka dla danej daty, pasieki i ula - dla frame_detail_screen
  static Future<void> deleteInspection(String data, int pasieka, int ul) async {
    final db = await DBHelper.database();
  //  print('DBhelper: delete ramki dla: data = $data, pasieka = $pasieka, ul = $ul');
    const where = 'data=? and pasiekaNr=? and ulNr =?';
    final idy = await _idyGdzie(db, 'ramka', where, [data, pasieka, ul]);
    await db.delete('ramka', where: where, whereArgs: [data, pasieka, ul]);
    await zglosUsuniete(db, 'ramka', idy); //kolejka usunięć do chmury
    await odswiezPrzegladPasieki(pasieka); //data przeglądu pasieki
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
  //[zglos] = false - ciche sprzątanie wpisu bez pliku na tym telefonie (nie usuwa zdjęcia z chmury)
  static Future<void> deletePhoto(String id, {bool zglos = true}) async {
    final db = await DBHelper.database();
    await db.delete('zdjecia', where: 'id= ?', whereArgs: [id]);
    if (zglos) await zglosUsuniete(db, 'zdjecia', [id]); //kolejka usunięć do chmury
  }

  //=== NAGRANIA dyktowanych notatek (patrz RecordingHelper) ==================

  //wszystkie nagrania - dla providera Recordings i dla sprzątania
  static Future<List<Map<String, dynamic>>> getNagrania() async {
    final db = await DBHelper.database();
    return db.query('nagrania', orderBy: 'data DESC, czas DESC');
  }

  //nagrania przypięte do jednej notatki albo jednego przeglądu
  static Future<List<Map<String, dynamic>>> getNagraniaDla(
      String zrodlo, String powiazanieId) async {
    final db = await DBHelper.database();
    return db.query('nagrania',
        where: 'zrodlo=? and powiazanieId=?',
        whereArgs: [zrodlo, powiazanieId],
        orderBy: 'czas');
  }

  //Przepięcie nagrań na inne id wpisu. Potrzebne przy EDYCJI przeglądu:
  //infos_edit_screen kasuje stary rekord i zapisuje nowy pod id złożonym z daty,
  //pasieki, ula i parametru - po zmianie którejkolwiek z tych rzeczy nagranie
  //zostałoby sierotą (patrz RecordingHelper.sprzataj).
  static Future<void> przepnijNagrania(
      String zrodlo, String stareId, String noweId) async {
    final db = await DBHelper.database();
    await db.update(
      'nagrania',
      {'powiazanieId': noweId},
      where: 'zrodlo=? and powiazanieId=?',
      whereArgs: [zrodlo, stareId],
    );
  }

  static Future<void> deleteNagranie(String id) async {
    final db = await DBHelper.database();
    await db.delete('nagrania', where: 'id= ?', whereArgs: [id]);
  }

  //Same identyfikatory tabeli - do wykrywania nagrań-sierot (RecordingHelper.
  //sprzataj). Bierzemy jedną kolumnę zamiast całych rekordów, bo przy kilku
  //tysiącach przeglądów to różnica między kilkoma kB a kilkoma MB w pamięci.
  static Future<Set<String>> getIdyTabeli(String tabela) async {
    final db = await DBHelper.database();
    final List<Map<String, dynamic>> w = await db.query(tabela, columns: ['id']);
    return w.map((e) => '${e['id']}').toSet();
  }

  //pobieranie ostatniej daty info per ul dla danej kategorii - dla powiadomień
  static Future<List<Map<String, dynamic>>> getLatestInfoPerHive(String kategoria) async {
    final db = await DBHelper.database();
    return db.rawQuery(
      'SELECT pasiekaNr, ulNr, MAX(data) as lastDate FROM info WHERE kategoria = ? AND arch = 0 GROUP BY pasiekaNr, ulNr',
      [kategoria]
    );
  }

  //pobieranie aktywnych notatek z datą zadania - dla powiadomień
  static Future<List<Map<String, dynamic>>> getActiveNotesWithTaskDate() async {
    final db = await DBHelper.database();
    return db.rawQuery(
      "SELECT id, tytul, pole1 FROM notatki WHERE status = 0 AND pole1 IS NOT NULL AND pole1 != '' AND arch = 0"
    );
  }

  //zapis powiadomienia indywidualnego - dla infos_edit_screen
  static Future<int> insertPowiadomienie(Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    return db.insert('powiadomienia', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //usuwanie powiadomienia po infoId - dla infos_edit_screen
  static Future<void> deletePowiadomienieByInfoId(String infoId) async {
    final db = await DBHelper.database();
    db.delete('powiadomienia', where: 'infoId = ?', whereArgs: [infoId]);
  }

  //pobieranie aktywnych powiadomień indywidualnych - dla notification_helper
  static Future<List<Map<String, dynamic>>> getActivePowiadomienia() async {
    final db = await DBHelper.database();
    final today = DateTime.now().toString().substring(0, 10);
    return db.rawQuery(
      'SELECT * FROM powiadomienia WHERE aktywne = 1 AND dataNotif >= ?',
      [today]
    );
  }

  //pobieranie powiadomienia po infoId - dla infos_edit_screen (edycja)
  static Future<List<Map<String, dynamic>>> getPowiadomienieByInfoId(String infoId) async {
    final db = await DBHelper.database();
    return db.rawQuery('SELECT * FROM powiadomienia WHERE infoId = ?', [infoId]);
  }

  //usunięcie powiadomienia po id - dla notification_settings_screen
  static Future<void> deletePowiadomienie(int id) async {
    final db = await DBHelper.database();
    await db.delete('powiadomienia', where: 'id = ?', whereArgs: [id]);
  }

  //czyszczenie starych/nieaktywnych powiadomień z bazy
  static Future<void> cleanupPowiadomienia() async {
    final db = await DBHelper.database();
    final today = DateTime.now().toString().substring(0, 10);
    await db.delete('powiadomienia', where: 'aktywne = 0 OR dataNotif < ?', whereArgs: [today]);
  }

  //sprawdzenie czy ul istnieje w danej pasiece
  static Future<bool> hiveExists(int pasieka, int ul) async {
    final db = await DBHelper.database();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ule WHERE pasiekaNr = ? AND ulNr = ?',
      [pasieka, ul],
    );
    return (result.first['cnt'] as int) > 0;
  }

  //sprawdzenie czy pasieka istnieje
  static Future<bool> apiaryExists(int pasieka) async {
    final db = await DBHelper.database();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM pasieki WHERE pasiekaNr = ?',
      [pasieka],
    );
    return (result.first['cnt'] as int) > 0;
  }

  //pobranie liczby uli w pasiece
  static Future<int> getHiveCount(int pasieka) async {
    final db = await DBHelper.database();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ule WHERE pasiekaNr = ?',
      [pasieka],
    );
    return result.first['cnt'] as int;
  }

  //kaskadowe usunięcie ula i wszystkich powiązanych danych
  //zwraca listę ścieżek zdjęć do fizycznego usunięcia
  static Future<List<String>> deleteHiveCascade(int pasieka, int ul) async {
    final db = await DBHelper.database();

    //1. pobrać ścieżki zdjęć
    final photos = await db.rawQuery(
      'SELECT sciezka FROM zdjecia WHERE pasiekaNr = ? AND ulNr = ?',
      [pasieka, ul],
    );
    final List<String> photoPaths = photos
        .where((p) => p['sciezka'] != null && (p['sciezka'] as String).isNotEmpty)
        .map((p) => p['sciezka'] as String)
        .toList();

    //1a. id usuwanych wierszy - do kolejki usunięć do chmury
    const gdzieUl = 'pasiekaNr = ? AND ulNr = ?';
    final Map<String, List<Object?>> usuwane = {
      for (final t in ['ramka', 'info', 'notatki', 'zdjecia']) t: await _idyGdzie(db, t, gdzieUl, [pasieka, ul]),
    };

    //2. usunięcie ramek
    await db.delete('ramka', where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [pasieka, ul]);
    //3. usunięcie info
    await db.delete('info', where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [pasieka, ul]);
    //4. usunięcie notatek
    await db.delete('notatki', where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [pasieka, ul]);
    //5. usunięcie zdjęć z bazy
    await db.delete('zdjecia', where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [pasieka, ul]);
    //6. usunięcie powiadomień
    await db.delete('powiadomienia', where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [pasieka, ul]);
    //7. zerowanie matek (nie usuwamy, przenosimy do "wolnych") - arch = 0, żeby zmiana poszła do chmury
    await db.update('matki', {'pasieka': 0, 'ul': 0, 'arch': 0},
        where: 'pasieka = ? AND ul = ?', whereArgs: [pasieka, ul]);
    //8. usunięcie ula
    await db.delete('ule', where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [pasieka, ul]);
    //9. zgłoszenie usunięć do chmury
    for (final e in usuwane.entries) {
      await zglosUsuniete(db, e.key, e.value);
    }
    await odswiezPrzegladPasieki(pasieka); //data przeglądu pasieki

    return photoPaths;
  }

  //helper: przebudowa ID ramki - zamiana pasiekaNr i ulNr w ID
  //format ID: "data.pasiekaNr.ulNr.korpus.ramka.ramkaPo.strona.zasob"
  static String _rebuildRamkaId(String oldId, int dstPasieka, int dstUl) {
    final parts = oldId.split('.');
    if (parts.length >= 3) {
      parts[1] = dstPasieka.toString();
      parts[2] = dstUl.toString();
    }
    return parts.join('.');
  }

  //helper: przebudowa ID info - zamiana pasiekaNr i ulNr w ID
  //format ID: "data.pasiekaNr.ulNr.kategoria.parametr"
  static String _rebuildInfoId(String oldId, int dstPasieka, int dstUl) {
    final parts = oldId.split('.');
    if (parts.length >= 3) {
      parts[1] = dstPasieka.toString();
      parts[2] = dstUl.toString();
    }
    return parts.join('.');
  }

  //helper: przebudowa ID zdjecia - zamiana pasiekaNr i ulNr w ID
  //format ID: "data.timestamp.pasiekaNr.ulNr"
  static String _rebuildZdjeciaId(String oldId, int dstPasieka, int dstUl) {
    final parts = oldId.split('.');
    if (parts.length >= 4) {
      parts[2] = dstPasieka.toString();
      parts[3] = dstUl.toString();
    }
    return parts.join('.');
  }

  //przeniesienie ula z historią do nowej lokalizacji
  static Future<void> moveHiveWithHistory(int srcPasieka, int srcUl, int dstPasieka, int dstUl) async {
    final db = await DBHelper.database();

    //1. ramka - przebudowa ID
    final ramki = await db.query('ramka',
        where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [srcPasieka, srcUl]);
    for (final r in ramki) {
      final oldId = r['id'] as String;
      final newId = _rebuildRamkaId(oldId, dstPasieka, dstUl);
      final newData = Map<String, dynamic>.from(r);
      newData['id'] = newId;
      newData['pasiekaNr'] = dstPasieka;
      newData['ulNr'] = dstUl;
      newData['arch'] = 0;
      await db.delete('ramka', where: 'id = ?', whereArgs: [oldId]);
      await db.insert('ramka', newData, conflictAlgorithm: ConflictAlgorithm.replace);
      if (newId != oldId) await zglosUsuniete(db, 'ramka', [oldId]); //stary id do usunięcia z chmury
    }

    //2. info - przebudowa ID
    final infos = await db.query('info',
        where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [srcPasieka, srcUl]);
    //zbieramy mapowanie starych infoId na nowe (dla powiadomień)
    final Map<String, String> infoIdMap = {};
    for (final i in infos) {
      final oldId = i['id'] as String;
      final newId = _rebuildInfoId(oldId, dstPasieka, dstUl);
      infoIdMap[oldId] = newId;
      final newData = Map<String, dynamic>.from(i);
      newData['id'] = newId;
      newData['pasiekaNr'] = dstPasieka;
      newData['ulNr'] = dstUl;
      newData['arch'] = 0;
      await db.delete('info', where: 'id = ?', whereArgs: [oldId]);
      await db.insert('info', newData, conflictAlgorithm: ConflictAlgorithm.replace);
      if (newId != oldId) await zglosUsuniete(db, 'info', [oldId]); //stary id do usunięcia z chmury
    }

    //3. notatki - UPDATE (autoincrement ID)
    await db.update('notatki', {'pasiekaNr': dstPasieka, 'ulNr': dstUl, 'arch': 0},
        where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [srcPasieka, srcUl]);

    //4. zdjecia - przebudowa ID
    final zdjecia = await db.query('zdjecia',
        where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [srcPasieka, srcUl]);
    for (final z in zdjecia) {
      final oldId = z['id'] as String;
      final newId = _rebuildZdjeciaId(oldId, dstPasieka, dstUl);
      final newData = Map<String, dynamic>.from(z);
      newData['id'] = newId;
      newData['pasiekaNr'] = dstPasieka;
      newData['ulNr'] = dstUl;
      newData['arch'] = 0;
      await db.delete('zdjecia', where: 'id = ?', whereArgs: [oldId]);
      await db.insert('zdjecia', newData, conflictAlgorithm: ConflictAlgorithm.replace);
      if (newId != oldId) await zglosUsuniete(db, 'zdjecia', [oldId]); //stary id do usunięcia z chmury
    }

    //5. powiadomienia - UPDATE + przebudowa infoId
    final powiad = await db.query('powiadomienia',
        where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [srcPasieka, srcUl]);
    for (final p in powiad) {
      final oldInfoId = p['infoId'] as String?;
      final newInfoId = (oldInfoId != null && infoIdMap.containsKey(oldInfoId))
          ? infoIdMap[oldInfoId]
          : oldInfoId;
      await db.update(
        'powiadomienia',
        {'pasiekaNr': dstPasieka, 'ulNr': dstUl, 'infoId': newInfoId},
        where: 'id = ?',
        whereArgs: [p['id']],
      );
    }

    //6. matki - UPDATE
    await db.update('matki', {'pasieka': dstPasieka, 'ul': dstUl, 'arch': 0},
        where: 'pasieka = ? AND ul = ?', whereArgs: [srcPasieka, srcUl]);

    //7. ul - pobrać stary, usunąć, wstawić z nowym ID
    final hiveRows = await db.query('ule',
        where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [srcPasieka, srcUl]);
    if (hiveRows.isNotEmpty) {
      final hiveData = Map<String, dynamic>.from(hiveRows.first);
      await db.delete('ule', where: 'pasiekaNr = ? AND ulNr = ?', whereArgs: [srcPasieka, srcUl]);
      hiveData['id'] = '$dstPasieka.$dstUl';
      hiveData['pasiekaNr'] = dstPasieka;
      hiveData['ulNr'] = dstUl;
      await db.insert('ule', hiveData, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    //data przeglądu obu pasiek
    await odswiezPrzegladPasieki(srcPasieka);
    if (dstPasieka != srcPasieka) await odswiezPrzegladPasieki(dstPasieka);
  }

  // === Optymalizacja odbudowy uli i pasiek (import_screen) ===
  // Zastępuje pętle po ramkach/info/ulach jednym zapytaniem SQL + batchem.

  //odbudowa tabeli `ule` z unikalnych uli znalezionych w tabeli `ramka`
  static Future<int> rebuildHivesFromFrames({
    required String formattedDate,
    required String hiveLabel,
  }) async {
    final db = await DBHelper.database();
    final rows = await db.rawQuery('SELECT DISTINCT pasiekaNr, ulNr FROM ramka');
    if (rows.isEmpty) return 0;
    final batch = db.batch();
    for (final row in rows) {
      final p = row['pasiekaNr'] as int;
      final u = row['ulNr'] as int;
      batch.insert('ule', {
        'id': '$p.$u',
        'pasiekaNr': p,
        'ulNr': u,
        'przeglad': formattedDate,
        'ikona': 'green',
        'ramek': 10,
        'korpusNr': 0,
        'trut': 0, 'czerw': 0, 'larwy': 0, 'jaja': 0, 'pierzga': 0,
        'miod': 0, 'dojrzaly': 0, 'weza': 0, 'susz': 0,
        'matka': 0, 'mateczniki': 0, 'usunmat': 0,
        'todo': '0', 'kategoria': '0', 'parametr': '0', 'wartosc': '0', 'miara': '0',
        'matka1': '0', 'matka2': '0', 'matka3': '0', 'matka4': '0', 'matka5': '0',
        'h1': hiveLabel, 'h2': '0', 'h3': '0',
        'aktual': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    return rows.length;
  }

  //aktualizacja stanu uli na podstawie najnowszego chronologicznie wpisu info
  //parametr ∈ frameCountParams -> ikona 'green', ramek = wartosc, h1 = pogoda, h2 = miara
  //(frameCountParams = "liczba ramek = " we WSZYSTKICH językach - do 05.10.2026 szedł tylko
  //bieżący i wpis zapisany w innym języku dawał po imporcie ramek=10 i domyślny rodzaj ula)
  //parametr ∈ liquidationValues -> ikona 'black', reszta (ramek, h1, h2) z ostatniego
  //wpisu "liczba ramek =" tego ula, a dopiero w jego braku wartości domyślne
  static Future<void> applyInfoStateToHives({
    required Set<String> liquidationValues,
    required Set<String> frameCountParams,
    required String formattedDate,
    required String hiveLabel,
  }) async {
    if (liquidationValues.isEmpty || frameCountParams.isEmpty) return;
    final db = await DBHelper.database();
    final args = <Object?>[...frameCountParams, ...liquidationValues];
    final rows = await db.rawQuery(
      'SELECT pasiekaNr, ulNr, parametr, wartosc, pogoda, miara, data, czas '
      'FROM info WHERE parametr IN (${_znakiZapytania(frameCountParams.length)}) '
      'OR parametr IN (${_znakiZapytania(liquidationValues.length)})',
      args,
    );
    if (rows.isEmpty) return;

    //dla każdego ula wybieramy wpis z najwyższym (data, czas)
    bool nowszy(Map<String, Object?> a, Map<String, Object?> b) {
      final cmpD = (a['data'] as String? ?? '').compareTo(b['data'] as String? ?? '');
      return cmpD > 0 ||
          (cmpD == 0 &&
              (a['czas'] as String? ?? '').compareTo(b['czas'] as String? ?? '') > 0);
    }

    //osobno najnowszy wpis "liczba ramek =", bo TYLKO on niesie rodzaj ula (pogoda),
    //typ ula (miara) i liczbę ramek. Wpis o likwidacji tych pól nie ma, więc dla ula
    //zlikwidowanego bierzemy je stąd - wcześniej szły tu wartości domyślne i belka
    //"Mini (ULI WE 1)" zamieniała się po imporcie na "Ul ( 10)".
    final Map<String, Map<String, Object?>> latest = {};
    final Map<String, Map<String, Object?>> latestFrames = {};
    for (final row in rows) {
      final key = '${row['pasiekaNr']}.${row['ulNr']}';
      final cur = latest[key];
      if (cur == null || nowszy(row, cur)) latest[key] = row;
      if (frameCountParams.contains(row['parametr'] as String? ?? '')) {
        final curF = latestFrames[key];
        if (curF == null || nowszy(row, curF)) latestFrames[key] = row;
      }
    }

    final batch = db.batch();
    for (final entry in latest.entries) {
      final r = entry.value;
      final p = r['pasiekaNr'] as int;
      final u = r['ulNr'] as int;
      final parametr = r['parametr'] as String? ?? '';

      final Map<String, Object?> record;
      if (frameCountParams.contains(parametr)) {
        record = {
          'id': entry.key,
          'pasiekaNr': p, 'ulNr': u,
          'przeglad': formattedDate,
          'ikona': 'green',
          'ramek': int.tryParse((r['wartosc'] as String?) ?? '') ?? 10,
          'korpusNr': 0,
          'trut': 0, 'czerw': 0, 'larwy': 0, 'jaja': 0, 'pierzga': 0,
          'miod': 0, 'dojrzaly': 0, 'weza': 0, 'susz': 0,
          'matka': 0, 'mateczniki': 0, 'usunmat': 0,
          'todo': '0', 'kategoria': '0', 'parametr': '0', 'wartosc': '0', 'miara': '0',
          'matka1': '0', 'matka2': '0', 'matka3': '0', 'matka4': '0', 'matka5': '0',
          'h1': (r['pogoda'] as String?) ?? '0',
          'h2': (r['miara'] as String?) ?? '0',
          'h3': '0',
          'aktual': 0,
        };
      } else if (liquidationValues.contains(parametr)) {
        //ul zlikwidowany ma zostać w belce taki, jaki był - zmienia się tylko ikona
        final fr = latestFrames[entry.key];
        final frRodzaj = (fr?['pogoda'] as String?) ?? '';
        final frTyp = (fr?['miara'] as String?) ?? '';
        record = {
          'id': entry.key,
          'pasiekaNr': p, 'ulNr': u,
          'przeglad': formattedDate,
          'ikona': 'black',
          'ramek': int.tryParse((fr?['wartosc'] as String?) ?? '') ?? 10,
          'korpusNr': 0,
          'trut': 0, 'czerw': 0, 'larwy': 0, 'jaja': 0, 'pierzga': 0,
          'miod': 0, 'dojrzaly': 0, 'weza': 0, 'susz': 0,
          'matka': 0, 'mateczniki': 0, 'usunmat': 0,
          'todo': '0', 'kategoria': '0', 'parametr': '0', 'wartosc': '0', 'miara': '0',
          'matka1': '0', 'matka2': '0', 'matka3': '0', 'matka4': '0', 'matka5': '0',
          'h1': frRodzaj.isNotEmpty ? frRodzaj : hiveLabel,
          'h2': frTyp.isNotEmpty ? frTyp : '0',
          'h3': '0',
          'aktual': 0,
        };
      } else {
        continue;
      }
      batch.insert('ule', record, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  //odbudowa tabeli `pasieki` z unikalnych numerów pasiek w tabeli `ule`
  static Future<int> rebuildApiariesFromHives({
    required String formattedDate,
  }) async {
    final db = await DBHelper.database();
    final rows = await db.rawQuery('SELECT DISTINCT pasiekaNr FROM ule');
    if (rows.isEmpty) return 0;
    //data przeglądu pasieki = najnowszy przegląd ramek (20.10.2026, patrz getDataPrzegladuPasieki)
    final przeglady = {
      for (final r in await db.rawQuery('SELECT pasiekaNr, MAX(data) AS d FROM ramka GROUP BY pasiekaNr'))
        r['pasiekaNr']: r['d'] as String?
    };
    final batch = db.batch();
    for (final row in rows) {
      final p = row['pasiekaNr'] as int;
      final String? d = przeglady[p];
      batch.insert('pasieki', {
        'id': '$p',
        'pasiekaNr': p,
        'ileUli': 0,
        'przeglad': (d == null || d.isEmpty) ? formattedDate : d,
        'ikona': 'green',
        'opis': '??',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    return rows.length;
  }

}
