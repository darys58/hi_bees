import 'dart:convert';
import 'dart:io';
import 'dart:math'; //min()

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../globals.dart' as globals;
import 'db_helper.dart';
import 'eksport_kod.dart';
import 'serwer_token.dart';

//SYNCHRONIZACJA USUNIĘĆ z chmurą (16.10.2026, pliki/plan_synchronizacja_usuniec.md).
//Usunięcia lokalne trafiają do kolejki w tabeli "usuniete" (DBHelper.zglosUsuniete).
// - wyslij: kolejka -> cbt_hi_usuniete.php, ZAWSZE przed wierszami (każdy eksport i przed importem),
// - zastosuj: po imporcie lista usuniętych z chmury (cbt.php?d=f_usuniete) + to, co nadal czeka
//   w kolejce, kasowane lokalnie - inaczej import przywraca usunięte wpisy.
class UsunieteHelper {
  static const int _porcja = 1000; //serwer przyjmuje najwyżej 2000 wpisów w żądaniu
  static Future<bool>? _wysylanie; //auto-eksport i eksport ręczny nie wysyłają kolejki dwa razy naraz

  //Wysłanie kolejki do bieżącej bazy (prefiks jak w eksporcie wierszy: globals.prefiksTabel(memory.kod)).
  //Zwraca true, gdy kolejka jest pusta (wszystko przyjęte albo nie było nic do wysłania).
  //"czesciowo" (część odrzucona przez prawa, D3) też czyści kolejkę - ponowne wysłanie nic nie zmieni.
  static Future<bool> wyslij() {
    return _wysylanie ??= _wyslij().whenComplete(() => _wysylanie = null);
  }

  static Future<bool> _wyslij() async {
    try {
      final kolejka = await DBHelper.getUsuniete();
      if (kolejka.isEmpty) return true;
      final mem = await DBHelper.getData('memory');
      final kod = mem.isEmpty ? '' : '${mem.first['kod'] ?? ''}'.trim();
      if (kod.isEmpty) return false; //bez konta serwer i tak nic nie usunie
      final prefiks = globals.prefiksTabel(kod);

      //id, które istnieją lokalnie (wpis odtworzony z tym samym id, np. edycja ramki) - nie usuwamy
      //ich w chmurze, eksport wierszy i tak nadpisze tam starą wersję
      final Map<String, List<String>> wgTabel = {};
      for (final w in kolejka) {
        wgTabel.putIfAbsent('${w['tabela']}', () => []).add('${w['id']}');
      }
      final Set<String> istniejace = {};
      for (final e in wgTabel.entries) {
        for (final id in await DBHelper.istniejaceId(e.key, e.value)) {
          istniejace.add('${e.key}|$id');
        }
      }
      bool jest(Map<String, dynamic> w) => istniejace.contains('${w['tabela']}|${w['id']}');
      await DBHelper.usunZKolejki(kolejka.where(jest).toList());
      final doWyslania = kolejka.where((w) => !jest(w)).toList();

      bool wszystko = true;
      for (int i = 0; i < doWyslania.length; i += _porcja) {
        final porcja = doWyslania.sublist(i, min(i + _porcja, doWyslania.length));
        final lista = porcja.map((w) => {'tabela': '${w['tabela']}', 'id': '${w['id']}'}).toList();
        //"tabela" na końcu - eksportZKodem dokleja kod i token po ostatnim "tabela"
        final jsonData = '{"usuniete":${jsonEncode(lista)},"total":${lista.length}, "tabela":"${prefiks}_usuniete"}';
        final response = await http
            .post(
              Uri.parse('https://darys.pl/cbt_hi_usuniete.php'),
              headers: {'Content-Type': 'application/json; charset=UTF-8'},
              body: await eksportZKodem(jsonData),
            )
            .timeout(const Duration(seconds: 60));
        final String wynik = response.statusCode >= 200 && response.statusCode < 300
            ? '${(_json(response.body) ?? const {})['success'] ?? ''}'
            : 'http ${response.statusCode}';
        if (wynik == 'ok' || wynik == 'czesciowo') {
          await DBHelper.usunZKolejki(porcja);
        } else {
          debugPrint('Usunięcia do chmury: $wynik');
          wszystko = false;
        }
      }
      return wszystko;
    } catch (e) {
      debugPrint('Usunięcia do chmury - błąd: $e');
      return false;
    }
  }

  //Lista usuniętych z chmury (import). null - nie udało się pobrać (import idzie dalej bez niej).
  static Future<List<Map<String, String>>?> pobierz(String prefiks) async {
    try {
      final response = await http
          .get(
            Uri.parse('https://darys.pl/cbt.php?d=f_usuniete&kod=${globals.kod}&tab=${prefiks}_usuniete'),
            headers: naglowkiSerwera(), //token urządzenia
          )
          .timeout(const Duration(seconds: 60));
      final odp = _json(response.body);
      final lista = odp?['usuniete'];
      if (lista is! List) return null;
      return lista
          .whereType<Map>()
          .map((w) => {'tabela': '${w['t'] ?? ''}', 'id': '${w['id'] ?? ''}'})
          .toList();
    } catch (e) {
      debugPrint('Usunięcia z chmury - błąd: $e');
      return null;
    }
  }

  //Usunięcie lokalne wpisów z listy chmury [zChmury] i z własnej kolejki (to, czego nie udało się wysłać
  //przed importem). Wiersze z arch = 0 zostają (D2). Usuwa też pliki zdjęć i ule/pasieki, które
  //zostały bez ramek i info. Wołane po zapisie zaimportowanych ramek i drugi raz po zapisie info.
  static Future<void> zastosuj(List<Map<String, String>>? zChmury) async {
    try {
      final kolejka = await DBHelper.getUsuniete();
      final wpisy = <Map<String, String>>[
        ...?zChmury,
        ...kolejka.map((w) => {'tabela': '${w['tabela']}', 'id': '${w['id']}'}),
      ];
      final wynik = await DBHelper.usunWskazane(wpisy);
      for (final sciezka in wynik.pliki) {
        try {
          final plik = File(sciezka);
          if (await plik.exists()) await plik.delete();
        } catch (_) {}
      }
      await DBHelper.usunPusteUle(wynik.ule);
    } catch (e) {
      debugPrint('Usunięcia lokalne po imporcie - błąd: $e');
    }
  }

  //JSON z odpowiedzi serwera (serwer bywa, że dokleja tekst za JSON-em)
  static Map<String, dynamic>? _json(String body) {
    var b = body.trim();
    final koniec = b.lastIndexOf('}');
    if (koniec == -1) return null;
    b = b.substring(0, koniec + 1);
    final poczatek = b.indexOf('{');
    if (poczatek == -1) return null;
    final odp = json.decode(b.substring(poczatek));
    return odp is Map<String, dynamic> ? odp : null;
  }
}
