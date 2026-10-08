import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../globals.dart' as globals;
import 'db_helper.dart';

//USTAWIENIA BAZY W CHMURZE (08.10.2026): lokalizacje pasiek (tabela pogoda: miasto, współrzędne)
//i własne typy uli (dodatki2). Dotąd tylko w telefonie - ginęły przy zmianie telefonu, a pracownik
//w bazie właściciela ich nie dostawał. Serwer: cbt_hi_ustawienia.php, tylko z tokenem.
//Wysyła wyłącznie WŁASNA baza (właściciel) - pracownik w bazie właściciela tylko pobiera.
//Wszystko po cichu: brak sieci albo stary serwer nie może blokować zapisu ani importu.
//WYSYŁAMY TYLKO ZMIENIONE w tym telefonie (lista kluczy 'p:<nr pasieki>' / 't:<id typu>'
//w SharedPreferences) - właściciel z dwoma telefonami: telefon z domyślnymi ustawieniami
//nie może przy eksporcie nadpisać lokalizacji ustawionej na drugim. Po udanym wysłaniu klucze znikają.
//Przy pierwszym uruchomieniu tej wersji - jednorazowo wszystkie obecne, niedomyślne ustawienia.

const String _adres = 'https://darys.pl/cbt_hi_ustawienia.php';

Future<Map<String, dynamic>?> _zapytaj(Map<String, dynamic> dane) async {
  if (globals.token.isEmpty) return null;
  try {
    final r = await http
        .post(Uri.parse(_adres),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'token': globals.token, ...dane}))
        .timeout(const Duration(seconds: 15));
    final o = json.decode(r.body);
    return o is Map<String, dynamic> ? o : null;
  } catch (_) {
    return null;
  }
}

const String _kZmienione = 'hb_ustawienia_zmienione';
const String _kStart = 'hb_ustawienia_start';

//domyślne wpisy telefonu - nie są ustawieniem użytkownika (hives_screen, apiarys_screen)
bool _domyslnaLokalizacja(Map p) =>
    '${p['miasto'] ?? ''}' == 'Konin' && '${p['latitude'] ?? ''}' == '' && '${p['longitude'] ?? ''}' == '';
bool _domyslnyTyp(Map t) =>
    RegExp(r'^Wielkopolski [ABCD]$').hasMatch('${t['n'] ?? ''}') &&
    '${t['s']}' == '335' && '${t['t']}' == '235' && '${t['v']}' == '335' && '${t['w']}' == '105';

//po zapisie lokalizacji ('p:3') albo typu ula ('t:2') - zapamiętanie i próba wysłania
Future<void> zmienioneUstawienie(String klucz) async {
  if (globals.aktywnaBaza.isNotEmpty) return; //w bazie właściciela zmiany nie idą do chmury
  try {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(_kZmienione) ?? <String>[];
    if (!lista.contains(klucz)) await prefs.setStringList(_kZmienione, [...lista, klucz]);
  } catch (_) {}
  await wyslijUstawieniaBazy();
}

//przy eksporcie (ręcznym i automatycznym) i po zmianie - tylko zapamiętane zmiany
Future<bool> wyslijUstawieniaBazy() async {
  if (globals.aktywnaBaza.isNotEmpty || globals.token.isEmpty) return false;
  try {
    final prefs = await SharedPreferences.getInstance();
    final lok = await DBHelper.getLokalizacjePasiek();
    final typy = await DBHelper.getDodatki2();
    final Set<String> zmienione = {...(prefs.getStringList(_kZmienione) ?? const <String>[])};
    if (prefs.getBool(_kStart) != true) {
      //pierwsze uruchomienie: wszystko, co użytkownik kiedyś ustawił
      for (final p in lok) {
        if (!_domyslnaLokalizacja(p)) zmienione.add('p:${p['id']}');
      }
      for (final t in typy) {
        if (!_domyslnyTyp(t)) zmienione.add('t:${t['id']}');
      }
    }
    final pasieki = [
      for (final p in lok)
        if ((int.tryParse('${p['id']}') ?? 0) > 0 && zmienione.contains('p:${p['id']}'))
          {
            'nr': int.parse('${p['id']}'),
            'miasto': '${p['miasto'] ?? ''}',
            'latitude': '${p['latitude'] ?? ''}',
            'longitude': '${p['longitude'] ?? ''}',
          }
    ];
    final typyUli = [
      for (final t in typy)
        if (zmienione.contains('t:${t['id']}'))
          {for (final k in ['id', 'm', 'n', 's', 't', 'u', 'v', 'w', 'z']) k: '${t[k] ?? ''}'}
    ];
    bool ok = true;
    if (pasieki.isNotEmpty || typyUli.isNotEmpty) {
      final o = await _zapytaj({'akcja': 'zapisz', 'pasieki': pasieki, 'typy_uli': typyUli});
      ok = o != null && o['success'] == 'ok';
    }
    if (ok) {
      await prefs.setStringList(_kZmienione, <String>[]);
      await prefs.setBool(_kStart, true);
    }
    return ok;
  } catch (_) {
    return false;
  }
}

//po imporcie z chmury - własna baza (nowy telefon) albo baza właściciela (pracownik).
//Zwraca true, gdy coś zmieniło się w telefonie (do odświeżenia providerów Weathers / Dodatki2).
Future<bool> pobierzUstawieniaBazy() async {
  final o = await _zapytaj({'akcja': 'pobierz', 'baza': globals.aktywnaBaza});
  if (o == null || o['success'] != 'ok') return false;
  bool zmiany = false;
  try {
    //we własnej bazie zmiany jeszcze niewysłane z tego telefonu są nowsze niż chmura - zostają
    final Set<String> niewyslane = globals.aktywnaBaza.isNotEmpty
        ? <String>{}
        : {...((await SharedPreferences.getInstance()).getStringList(_kZmienione) ?? const <String>[])};
    final String lang = globals.jezyk.length >= 2 ? globals.jezyk.substring(0, 2) : 'pl';
    for (final p in (o['pasieki'] as List?) ?? const []) {
      if (p is! Map) continue;
      final int nr = int.tryParse('${p['nr']}') ?? 0;
      if (nr < 1) continue;
      final String miasto = '${p['miasto'] ?? ''}';
      final String lat = '${p['latitude'] ?? ''}';
      final String lon = '${p['longitude'] ?? ''}';
      if (miasto.isEmpty && (lat.isEmpty || lon.isEmpty)) continue; //pusty wpis nie kasuje lokalnego
      if (niewyslane.contains('p:$nr')) continue;
      if (await DBHelper.zapiszLokalizacjePasieki('$nr', miasto, lat, lon, lang)) zmiany = true;
    }
    for (final t in (o['typy_uli'] as List?) ?? const []) {
      if (t is! Map) continue;
      final String id = '${t['id'] ?? ''}';
      if (!RegExp(r'^[0-9]{1,2}$').hasMatch(id)) continue;
      if (niewyslane.contains('t:$id')) continue;
      String v(String k) => '${t[k] ?? ''}';
      await DBHelper.updateDodatki2(id, v('m'), v('n'), v('s'), v('t'), v('u'), v('v'), v('w'), v('z'));
      zmiany = true;
    }
  } catch (_) {}
  return zmiany;
}
