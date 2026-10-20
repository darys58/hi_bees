import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'db_helper.dart'; //getStanyRodziny
import 'parametr_nazwy.dart'; //wszystkieJezyki

/// Ocena stanu rodziny (`info.wartosc` wpisu "rodzina jest", kategoria colony).
///
/// Ustalone z userem 15.10.2026:
/// - dobra: łagodna, ok, w kłębie - zielony kciuk w górę
/// - uwaga: agresywna, w nastroju do ucieczki - pomarańczowy znak ostrzeżenia (20.10.2026, było żółte)
/// - zla: strutowiała, chora - czerwony kciuk w dół
/// - martwa: nie żyje - czarny krzyżyk
/// Ta sama ocena ma wyznaczać kolor ikony na belce ula (kolor najgorszy
/// z matki, rodziny i "do zrobienia").
enum OcenaRodziny { brak, dobra, uwaga, zla, martwa }

//wartości we WSZYSTKICH językach - info.wartosc jest w języku z chwili zapisu.
//"strutowiała" ma w DE, ES, FR, IT, PT ten sam napis co "trutówka" (matka) -
//tu bez znaczenia, bo oceniamy tylko wpisy o stanie rodziny.
final Set<String> _uwaga = {
  ...wszystkieJezyki((l) => l.aggressive), //zapisywane "zła" (etykieta aggressive1)
  ...wszystkieJezyki((l) => l.aggressive1),
  ...wszystkieJezyki((l) => l.swarmingMood),
  'swarming', //krótka forma z gramatyki EN (przeliczana na swarmingMood, na wszelki wypadek)
};
final Set<String> _zla = {
  ...wszystkieJezyki((l) => l.droneBees),
  ...wszystkieJezyki((l) => l.colonySick),
};
final Set<String> _martwa = wszystkieJezyki((l) => l.dead);

OcenaRodziny ocenaStanuRodziny(String wartosc) {
  final w = wartosc.trim();
  if (w.isEmpty) return OcenaRodziny.brak;
  if (_martwa.contains(w)) return OcenaRodziny.martwa;
  if (_zla.contains(w)) return OcenaRodziny.zla;
  if (_uwaga.contains(w)) return OcenaRodziny.uwaga;
  return OcenaRodziny.dobra; //łagodna, ok, okej, w kłębie
}

/// Ikonka przed stanem rodziny w statystyce (jak kciuk przy jakości matki).
Icon? ikonaStanuRodziny(String wartosc, {double size = 20.0}) {
  switch (ocenaStanuRodziny(wartosc)) {
    case OcenaRodziny.brak:
      return null;
    case OcenaRodziny.dobra:
      return Icon(Icons.thumb_up_outlined, size: size, color: const Color.fromARGB(255, 15, 200, 8));
    case OcenaRodziny.uwaga:
      return Icon(Icons.warning_amber_rounded, size: size, color: const Color.fromARGB(255, 233, 132, 1));
    case OcenaRodziny.zla:
      return Icon(Icons.thumb_down_outlined, size: size, color: const Color.fromARGB(255, 255, 1, 1));
    case OcenaRodziny.martwa:
      //ten sam kształt co brak matki, tylko czarny
      return Icon(Icons.dangerous_outlined, size: size, color: const Color.fromARGB(255, 0, 0, 0));
  }
}

//siła rodziny (wpis " rodzina jest", z wiodącą spacją) we wszystkich językach;
//"norma" to zapis, "normalna" (normal1) to etykieta - obie na wszelki wypadek
final Set<String> _bardzoSilna = wszystkieJezyki((l) => l.veryStrong);
final Set<String> _silna = wszystkieJezyki((l) => l.strong);
final Set<String> _normalna = {
  ...wszystkieJezyki((l) => l.normal),
  ...wszystkieJezyki((l) => l.normal1),
};
final Set<String> _slaba = wszystkieJezyki((l) => l.weak);
final Set<String> _bardzoSlaba = wszystkieJezyki((l) => l.veryWeak);

/// "Buźka" przed siłą rodziny w statystyce - od uśmiechniętej (bardzo silna)
/// do smutnej (bardzo słaba). Siła NIE wpływa na kolor ikony na belce ula
/// (decyzja usera 15.10.2026). Wartość spoza listy - bez ikonki.
Icon? ikonaSilyRodziny(String wartosc, {double size = 20.0}) {
  final w = wartosc.trim();
  if (_bardzoSilna.contains(w)) {
    return Icon(Icons.sentiment_very_satisfied, size: size, color: const Color.fromARGB(255, 15, 200, 8));
  }
  if (_silna.contains(w)) {
    return Icon(Icons.sentiment_satisfied_alt, size: size, color: const Color.fromARGB(255, 120, 190, 8));
  }
  if (_normalna.contains(w)) {
    return Icon(Icons.sentiment_neutral, size: size, color: const Color.fromARGB(255, 215, 208, 0));
  }
  if (_slaba.contains(w)) {
    return Icon(Icons.sentiment_dissatisfied, size: size, color: const Color.fromARGB(255, 233, 132, 1));
  }
  if (_bardzoSlaba.contains(w)) {
    return Icon(Icons.sentiment_very_dissatisfied, size: size, color: const Color.fromARGB(255, 255, 1, 1));
  }
  return null;
}

//parametr wpisu o stanie rodziny ("rodzina jest") we wszystkich językach. Siła
//rodziny ma ten sam napis z wiodącą spacją - IN go nie łapie.
final Set<String> _parametryStanu = wszystkieJezyki((l) => l.colony + " " + l.isIs);

//czas zapisywany jako H:mm - "9:05" przegrywał w porównaniu napisów z "10:00"
String _kluczCzasu(Object? data, Object? czas) {
  var c = (czas as String?) ?? '';
  if (c.indexOf(':') == 1) c = '0$c';
  return '${(data as String?) ?? ''} $c';
}

/// Najnowszy stan rodziny każdego ula: 'pasieka.ul' -> info.wartosc.
/// [pasieka] null = wszystkie pasieki. Liczone przy wczytywaniu uli (Hives),
/// NIE zapisywane do tabeli "ule" - źródłem prawdy zostaje info, więc nie trzeba
/// niczego przeliczać po imporcie, edycji czy usunięciu wpisu.
Future<Map<String, String>> stanyRodzinUli([Object? pasieka]) async {
  final najnowsze = await _najnowszeWpisy(_parametryStanu, pasieka);
  return najnowsze.map((id, r) => MapEntry(id, (r['wartosc'] as String?) ?? ''));
}

//najnowszy (data, czas) wpis o podanych parametrach dla każdego ula: 'pasieka.ul' -> wiersz
Future<Map<String, Map<String, dynamic>>> _najnowszeWpisy(Set<String> parametry, Object? pasieka) async {
  final rows = await DBHelper.getStanyRodziny(parametry, pasieka);
  final Map<String, Map<String, dynamic>> wynik = {};
  final Map<String, String> klucze = {};
  for (final r in rows) {
    final id = '${r['pasiekaNr']}.${r['ulNr']}';
    final k = _kluczCzasu(r['data'], r['czas']);
    if (klucze[id] == null || k.compareTo(klucze[id]!) > 0) {
      klucze[id] = k;
      wynik[id] = r;
    }
  }
  return wynik;
}

final Set<String> _parametrySily = wszystkieJezyki((l) => " " + l.colony + " " + l.isIs);

/// Ostatni stan i siła rodziny ula - do belki "o rodzinie" (Ostatnie informacje).
class CechyRodzinyUla {
  String stan = '';
  String stanData = '';
  String sila = '';
  String silaData = '';
  /// data nowszego z dwóch wpisów - "przegląd" na belce (ile dni temu)
  String get data => stanData.compareTo(silaData) >= 0 ? stanData : silaData;
}

Future<Map<String, CechyRodzinyUla>> cechyRodzinUli(Object? pasieka) async {
  final stany = await _najnowszeWpisy(_parametryStanu, pasieka);
  final sily = await _najnowszeWpisy(_parametrySily, pasieka);
  final Map<String, CechyRodzinyUla> wynik = {};
  stany.forEach((id, r) {
    final c = wynik.putIfAbsent(id, () => CechyRodzinyUla());
    c.stan = (r['wartosc'] as String?) ?? '';
    c.stanData = (r['data'] as String?) ?? '';
  });
  sily.forEach((id, r) {
    final c = wynik.putIfAbsent(id, () => CechyRodzinyUla());
    c.sila = (r['wartosc'] as String?) ?? '';
    c.silaData = (r['data'] as String?) ?? '';
  });
  return wynik;
}

//kolejność od najlepszego: kolor NAJGORSZY wygrywa (ustalenie 15.10.2026)
const List<String> _kolejnoscIkon = ['green', 'yellow', 'orange', 'red', 'dead'];

/// Gorszy z dwóch kolorów ikony (green < yellow < orange < red < dead).
String gorszaIkona(String a, String b) => _gorsza(a, b);

String _gorsza(String a, String b) {
  final ia = _kolejnoscIkon.indexOf(a), ib = _kolejnoscIkon.indexOf(b);
  if (ia < 0) return b;
  if (ib < 0) return a;
  return ia >= ib ? a : b;
}

//"można izolować" to podpowiedź, nie zadanie - nie barwi przeglądu ani belki (20.10.2026)
final Set<String> _zadaniaBezKoloru = wszystkieJezyki((l) => l.toInsulate);

/// Czy zadanie ramki ("do zrobienia", zasób 13 / `ule.todo`) barwi przegląd
/// i belkę na żółto. Puste i '0' = brak zadania.
bool zadanieDoZrobienia(String? todo) {
  final t = (todo ?? '').trim();
  return t.isNotEmpty && t != '0' && !_zadaniaBezKoloru.contains(t);
}

/// Mateczniki nieusunięte: więcej mateczników (zasób 11) niż usuniętych (zasób 12)
/// - pomarańczowy przegląd i belka (20.10.2026).
bool otwarteMateczniki(int mateczniki, int usuniete) => mateczniki > usuniete;

/// Kolor ikony na belce ula: najgorszy z zapisanej `ule.ikona` (matka,
/// "do zrobienia"), zasobów z belki i stanu rodziny. 'black' = ul zlikwidowany - zostaje bez
/// zmian. 'dead' = rodzina nie żyje: czarna ikona, ale belka NIE jest
/// zaciemniona i ul liczy się dalej do pasieki (zaciemnienie i odliczanie
/// sprawdzają ikona == 'black').
/// [matka3] = `ule.matka3`: 'trutowa' (matka strutowiała) daje czerwony - liczone
/// tu, a nie zapisywane w `ule.ikona`, bo tam czerwony znaczy "brak matki"
/// i każda kolejna cecha matki zamieniała go na pomarańczowy (15.10.2026).
/// [todo], [mateczniki], [usunmat] = kolumny `ule` (belka). Żółty w `ule.ikona`
/// pochodzi wyłącznie z "do zrobienia", więc liczony jest tu od nowa z [todo]
/// (stare wpisy "można izolować" przestają barwić bez ponownego zapisu);
/// nieusunięte mateczniki dają pomarańczowy (20.10.2026). [todo] null = bez zmian.
String ikonaNaBelce(String ikona, String stanRodziny,
    {String matka3 = '', String? todo, int mateczniki = 0, int usunmat = 0}) {
  if (ikona == 'black') return ikona;
  if (matka3 == 'trutowa') ikona = _gorsza(ikona, 'red');
  if (todo != null) {
    if (ikona == 'yellow') ikona = 'green';
    if (zadanieDoZrobienia(todo)) ikona = _gorsza(ikona, 'yellow');
  }
  if (otwarteMateczniki(mateczniki, usunmat)) ikona = _gorsza(ikona, 'orange');
  switch (ocenaStanuRodziny(stanRodziny)) {
    case OcenaRodziny.brak:
    case OcenaRodziny.dobra:
      return ikona;
    case OcenaRodziny.uwaga:
      return _gorsza(ikona, 'orange');
    case OcenaRodziny.zla:
      return _gorsza(ikona, 'red');
    case OcenaRodziny.martwa:
      return 'dead';
  }
}

/// Ikona pasieki z ikon jej uli (już przeliczonych [ikonaNaBelce]): najgorsza
/// z green/yellow/orange/red. Ul zlikwidowany się nie liczy, rodzina martwa
/// liczy się jak czerwona (pasieka nie ma czarnej ikony).
String ikonaPasiekiZUli(Iterable<String> ikonyUli) {
  var wynik = 'green';
  for (final i in ikonyUli) {
    if (i == 'black') continue;
    wynik = _gorsza(wynik, i == 'dead' ? 'red' : i);
  }
  return wynik;
}

/// Kolor ikony ula (Icons.hive) dla wartości z [ikonaNaBelce].
Color kolorIkonyUla(String ikona) {
  switch (ikona) {
    case 'green':
      return const Color.fromARGB(255, 0, 255, 0);
    case 'yellow':
      return const Color.fromARGB(255, 233, 229, 1);
    case 'orange':
      return const Color.fromARGB(255, 233, 132, 1);
    case 'red':
      return const Color.fromARGB(255, 255, 0, 0);
    case 'black':
    case 'dead':
      return const Color.fromARGB(255, 0, 0, 0);
    default:
      return const Color.fromARGB(255, 100, 100, 100);
  }
}
