import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:hi_bees/l10n/app_localizations.dart';
import '../globals.dart' as globals;
import 'baza_zespolu.dart';
import 'db_helper.dart';
import 'subskrypcja.dart';

//USUWANIE KONTA z aplikacji (08.10.2026) - wymóg Apple (wytyczna 5.1.1(v)) i RODO.
//Serwer (cbt_hi_usun_konto.php, z tokenem) FIZYCZNIE usuwa konto, kopię w chmurze ze zdjęciami,
//ustawienia, pracę zespołową, tokeny i stan subskrypcji. Decyzje usera 08.10.2026:
//dane pasiek NA TELEFONIE zostają, aplikacja wraca do ekranu aktywacji; bazy właścicieli
//(praca zespołowa) są z telefonu usuwane. Subskrypcji w SKLEPIE to nie anuluje - mówimy o tym.

const String _adres = 'https://darys.pl/cbt_hi_usun_konto.php';

//części z kolumną arch (0 = niewysłane, 1 = wysłane, 2 = z importu) - jak HB_TABELE na serwerze
const List<String> _tabeleArch = ['ramka', 'info', 'zbiory', 'sprzedaz', 'zakupy', 'notatki', 'matki', 'zdjecia'];

//Okna potwierdzenia, usunięcie na serwerze i sprzątanie w telefonie.
//Po sukcesie ekran startowy budowany od nowa - pokaże ekran aktywacji.
Future<void> pokazUsuwanieKonta(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  if (globals.token.isEmpty) {
    _komunikat(context, l.accDeleteNoToken);
    return;
  }

  //1. co zostanie usunięte, co zostaje, subskrypcja w sklepie
  final bool? dalej = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.accDelete),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.accDeleteInfo),
            const SizedBox(height: 12),
            Text(l.accDeleteSubscription, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (Subskrypcja.aktywnaWSklepie)
              TextButton(onPressed: () => Subskrypcja.zarzadzaj(), child: Text(l.subManage)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l.cancel)),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.accDelete, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (dalej != true || !context.mounted) return;

  //2. drugie potwierdzenie - operacji nie można cofnąć
  final bool? napewno = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.accDeleteConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l.no)),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.accDeleteButton, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (napewno != true || !context.mounted) return;

  //3. serwer - z kółkiem postępu
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  final bool ok = await _usunNaSerwerze();
  if (ok) await _wyczyscTelefon();
  if (!context.mounted) return;
  Navigator.of(context).pop(); //kółko postępu

  if (!ok) {
    _komunikat(context, l.accDeleteError);
    return;
  }
  _komunikat(context, l.accDeleted);
  Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
}

void _komunikat(BuildContext context, String tekst) {
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tekst), duration: const Duration(seconds: 5)));
}

Future<bool> _usunNaSerwerze() async {
  try {
    final r = await http
        .post(Uri.parse(_adres),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'token': globals.token, 'potwierdzam': 'USUN'}))
        .timeout(const Duration(seconds: 60)); //usuwanie zdjęć może chwilę potrwać
    final odp = json.decode(r.body);
    return odp is Map && odp['success'] == 'ok';
  } catch (_) {
    return false;
  }
}

//Sprzątanie po usunięciu konta na serwerze. Każdy krok osobno - błąd jednego nie zatrzymuje reszty.
Future<void> _wyczyscTelefon() async {
  //własna baza (konto w memory przechodzi do jej pliku)
  try {
    if (globals.aktywnaBaza.isNotEmpty) await przelaczBaze('', '', 0);
  } catch (e) {
    debugPrint('usunKonto przelaczBaze: $e');
  }
  //pliki baz właścicieli (hibees_XXXX.db) - to nie dane tego użytkownika
  try {
    final String katalog = await sql.getDatabasesPath();
    for (final f in Directory(katalog).listSync()) {
      final String nazwa = p.basename(f.path);
      if (RegExp(r'^hibees_[0-9A-Z]{4}\.db$').hasMatch(nazwa)) await sql.deleteDatabase(f.path);
    }
  } catch (e) {
    debugPrint('usunKonto bazy właścicieli: $e');
  }
  //kopii w chmurze już nie ma - wszystko jako niewysłane, żeby po nowej aktywacji eksport wysłał całość
  try {
    final db = await DBHelper.database();
    for (final t in _tabeleArch) {
      try {
        await db.rawUpdate('UPDATE $t SET arch = 0 WHERE arch <> 0');
      } catch (_) {} //starsza baza bez tabeli - pomijamy
    }
  } catch (e) {
    debugPrint('usunKonto arch: $e');
  }
  //konto w memory: puste key = aplikacja nieaktywowana (ekran aktywacji); język, urządzenie i daty
  //zostają (start robi DateTime.parse(ddo)); puste id - SDK sklepu nie zaloguje się na stare konto
  try {
    final db = await DBHelper.database();
    await db.update('memory', {'id': '', 'email': '', 'kod': '', 'key': ''});
  } catch (e) {
    debugPrint('usunKonto memory: $e');
  }
  //osobno - przy nieudanej migracji v6 tych kolumn może nie być, a to nie może zatrzymać kroku wyżej
  try {
    final db = await DBHelper.database();
    await db.update('memory', {'token': '', 'stanowisko': ''});
  } catch (e) {
    debugPrint('usunKonto memory token: $e');
  }
  //ustawienia bazy (lokalizacje, typy uli) - przy nowym koncie wysłać od nowa wszystkie
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hb_ustawienia_zmienione');
    await prefs.remove('hb_ustawienia_start');
  } catch (_) {}
  await Subskrypcja.wyloguj();
  globals.key = '';
  globals.keyMemory = '';
  globals.kod = '';
  globals.token = '';
  globals.stanowisko = 0;
}
