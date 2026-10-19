import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../globals.dart' as globals;

//ZGODA NA INFORMACJE O NOWOŚCIACH (newsletter) - 18.10.2026. Regulamin rozdz. 4 ust. 6: informacje
//handlowe e-mailem tylko za odrębną, dobrowolną zgodą (art. 398 PKE). Domyślnie BRAK zgody.
//Stan trzyma serwer (cbt_hi_zgoda.php, dziennik hb_zgody - dowód kiedy i skąd zgodę wyrażono);
//telefon pamięta tylko ostatni znany stan, żeby przełącznik nie migał przy otwarciu Ustawień.
//Zgoda zaznaczona przy aktywacji czeka w SharedPreferences, aż po kodzie przyjdzie token -
//między wpisaniem e-maila a kodu ekran aktywacji jest zamykany.
class Newsletter {
  static const String _adres = 'https://darys.pl/cbt_hi_zgoda.php';
  static const String _kStan = 'hb_newsletter_zgoda';
  static const String _kPrzyAktywacji = 'hb_newsletter_przy_aktywacji';
  //wersja treści zgody (napisy newsletterActivation / newsletterSubtitle) - zmienić przy zmianie treści
  static const String wersjaTresci = '2026-10';

  static Future<Map<String, dynamic>?> _zapytaj(Map<String, dynamic> dane) async {
    if (globals.token.isEmpty) return null;
    try {
      final r = await http
          .post(Uri.parse(_adres),
              headers: {'Content-Type': 'application/json; charset=UTF-8'},
              body: jsonEncode({'token': globals.token, ...dane}))
          .timeout(const Duration(seconds: 15));
      final o = json.decode(r.body);
      return o is Map<String, dynamic> && o['success'] == 'ok' ? o : null;
    } catch (_) {
      return null;
    }
  }

  //ostatni znany stan (bez sieci)
  static Future<bool> zapamietanyStan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kStan) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _zapamietaj(bool zgoda) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kStan, zgoda);
    } catch (_) {}
  }

  //stan z serwera; null = brak tokenu / sieci
  static Future<bool?> pobierz() async {
    final o = await _zapytaj({'akcja': 'pobierz'});
    if (o == null) return null;
    final zgoda = '${o['zgoda']}' == '1';
    await _zapamietaj(zgoda);
    return zgoda;
  }

  //zapis na serwerze; false = nie udało się (stan bez zmian)
  static Future<bool> zapisz(bool zgoda, String zrodlo) async {
    final o = await _zapytaj({
      'akcja': 'zapisz',
      'zgoda': zgoda ? 1 : 0,
      'zrodlo': zrodlo,
      'tresc': wersjaTresci,
      'jezyk': globals.jezyk,
      'wersja': globals.wersja,
    });
    if (o == null) return false;
    await _zapamietaj('${o['zgoda']}' == '1');
    return true;
  }

  //pole wyboru na ekranie aktywacji
  static Future<bool> przyAktywacji() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kPrzyAktywacji) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> ustawPrzyAktywacji(bool zgoda) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (zgoda) {
        await prefs.setBool(_kPrzyAktywacji, true);
      } else {
        await prefs.remove(_kPrzyAktywacji);
      }
    } catch (_) {}
  }

  //po udanej aktywacji (jest token): zgoda zaznaczona przy aktywacji idzie na serwer.
  //Niezaznaczone pole NICZEGO nie wycofuje - ponowna aktywacja nie kasuje wcześniejszej zgody.
  static Future<void> poAktywacji() async {
    if (!await przyAktywacji()) return;
    if (await zapisz(true, 'aktywacja')) await ustawPrzyAktywacji(false);
  }
}
