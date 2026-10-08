import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../globals.dart' as globals;
import 'db_helper.dart';

//Przełączanie baz: własna <-> baza właściciela, w której użytkownik jest pracownikiem (etap 2, 07.10.2026).
//Każda baza to osobny plik SQLite (globals.plikBazy()); wybór zapamiętany w SharedPreferences.

const String _kBaza = 'hb_aktywna_baza';
const String _kEmail = 'hb_aktywna_baza_email';
const String _kPrawa = 'hb_aktywna_baza_prawa'; //część B: prawa i zakres pasiek w bazie właściciela

//wywoływane w main() PRZED pierwszym otwarciem bazy
Future<void> wczytajAktywnaBaze() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String baza = prefs.getString(_kBaza) ?? '';
    globals.aktywnaBaza = RegExp(r'^[0-9A-Z]{4}$').hasMatch(baza) ? baza : '';
    globals.aktywnaBazaEmail = globals.aktywnaBaza.isEmpty ? '' : (prefs.getString(_kEmail) ?? '');
    if (globals.aktywnaBaza.isNotEmpty) {
      final zapisane = jsonDecode(prefs.getString(_kPrawa) ?? '{}');
      if (zapisane is Map) ustawPrawaBazy(zapisane);
    }
  } catch (_) {
    globals.aktywnaBaza = ''; //w razie kłopotu - własna baza
    globals.aktywnaBazaEmail = '';
  }
}

//Przełączenie na bazę [prefiks] ('' = własna). [stanowisko] - numer tej instalacji w bazie docelowej
//(z serwera, lista zespołu); dla własnej bazy brany z jej zapisanego konta.
//Konto (memory: kod, token, abonament, język...) przechodzi z bieżącego pliku do docelowego, żeby
//tokeny i ustawienia zmienione w jednej bazie nie wracały do starych w drugiej.
//Po powrocie ekran startowy trzeba zbudować od nowa (Navigator.pushNamedAndRemoveUntil('/')).
Future<void> przelaczBaze(String prefiks, String email, int stanowisko, [Map? baza]) async {
  final konto = await DBHelper.getMemory(); //bieżący plik
  final Map<String, Object?>? wiersz =
      konto.isNotEmpty ? Map<String, Object?>.from(konto.first) : null;

  globals.aktywnaBaza = prefiks;
  globals.aktywnaBazaEmail = prefiks.isEmpty ? '' : email;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaza, globals.aktywnaBaza);
    await prefs.setString(_kEmail, globals.aktywnaBazaEmail);
  } catch (_) {}
  ustawPrawaBazy(baza ?? const {}); //[baza] - wpis z listy zespołu (pasieki, prawa, zapis_mozliwy)
  await _zapiszPrawaBazy();

  String st = stanowisko > 0 ? '$stanowisko' : '';
  if (prefiks.isEmpty) {
    //powrót do własnej bazy - jej stanowisko z jej zapisanego konta
    try {
      final docelowe = await DBHelper.getMemory(); //już plik docelowy
      if (docelowe.isNotEmpty) st = (docelowe.first['stanowisko'] ?? '').toString();
    } catch (_) {}
  }
  if (wiersz != null) {
    wiersz['stanowisko'] = st;
    await DBHelper.zastapKonto(wiersz);
  }
  globals.stanowisko = 0;
  globals.ustawStanowisko(st);
}

//prawa z wpisu listy zespołu: {pasieki: '*'|'1,3', prawa: {notatki: {odczyt: 1, zapis: 0}, ...}, zapis_mozliwy}
void ustawPrawaBazy(Map baza) {
  final Map<String, Map<String, bool>> prawa = {};
  final p = baza['prawa'];
  if (p is Map) {
    p.forEach((czesc, r) {
      if (r is Map) prawa['$czesc'] = {'odczyt': '${r['odczyt']}' == '1', 'zapis': '${r['zapis']}' == '1'};
    });
  }
  globals.prawaBazy = prawa;
  final String pasieki = '${baza['pasieki'] ?? '*'}'.trim();
  globals.pasiekiBazy = pasieki.isEmpty ? '*' : pasieki;
  globals.zapisBazyWstrzymany = baza['zapis_mozliwy'] == false;
}

Future<void> _zapiszPrawaBazy() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrawa, jsonEncode({
      'pasieki': globals.pasiekiBazy,
      'prawa': {
        for (final e in globals.prawaBazy.entries)
          e.key: {'odczyt': e.value['odczyt'] == true ? 1 : 0, 'zapis': e.value['zapis'] == true ? 1 : 0}
      },
      'zapis_mozliwy': !globals.zapisBazyWstrzymany,
    }));
  } catch (_) {}
}

//Aktualne prawa w bazie właściciela z serwera (start aplikacji, ekran zespołu). Właściciel mógł je
//zmienić albo odwołać dostęp - wtedy wszystko zablokowane (serwer i tak nic nie przyjmie).
//Zwraca false, gdy dostępu już nie ma; null - nie wiadomo (brak sieci, własna baza).
Future<bool?> odswiezPrawaBazy([Map<String, dynamic>? lista]) async {
  if (globals.aktywnaBaza.isEmpty) return null;
  _ostatnieOdswiezeniePraw = DateTime.now();
  if (lista == null) {
    if (globals.token.isEmpty) return null;
    try {
      final r = await http
          .post(Uri.parse('https://darys.pl/cbt_hi_zespol.php'),
              headers: {'Content-Type': 'application/json; charset=UTF-8'},
              body: jsonEncode({'token': globals.token, 'akcja': 'lista'}))
          .timeout(const Duration(seconds: 15));
      final o = json.decode(r.body);
      if (o is! Map<String, dynamic>) return null;
      lista = o;
    } catch (_) {
      return null;
    }
  }
  if (lista['success'] != 'ok') return null;
  Map? moja;
  for (final b in (lista['jako_pracownik'] as List?) ?? const []) {
    if (b is Map && b['status'] == 'aktywny' && b['prefiks'] == globals.aktywnaBaza) moja = b;
  }
  ustawPrawaBazy(moja ?? const {'pasieki': '*', 'prawa': {}, 'zapis_mozliwy': false});
  await _zapiszPrawaBazy();
  return moja != null;
}

//Odświeżenie praw nie częściej niż co [odstep] - start aplikacji, powrót z tła, automatyczny eksport.
//Bez tego zmiana praw u właściciela docierała dopiero po wejściu w "Pracę zespołową".
DateTime? _ostatnieOdswiezeniePraw;
Future<bool?> odswiezPrawaJesliTrzeba({Duration odstep = const Duration(seconds: 30)}) async {
  if (globals.aktywnaBaza.isEmpty) return null;
  final ostatnie = _ostatnieOdswiezeniePraw;
  if (ostatnie != null && DateTime.now().difference(ostatnie) < odstep) return null;
  return odswiezPrawaBazy();
}
