import 'dart:async';

import '../models/infos.dart';
import 'colony_helpers.dart'; //zadanieDoZrobienia, otwarteMateczniki, gorszaIkona
import 'db_helper.dart';
import 'parametr_nazwy.dart'; //wszystkieJezyki

//KOLOR PRZEGLĄDU (20.10.2026) - `info.wartosc` wpisu przeglądu (kategoria inspection),
//którym info_item barwi napis "przegląd". Do 20.10.2026 był to kolor belki z chwili
//PIERWSZEGO zapisu danego dnia i nigdy się nie zmieniał. Teraz jest ustawiany przy
//każdym zapisie ramki z zadaniem lub matecznikami (Frames.insertFrame, DBHelper.deleteFrame,
//updateRamkaNrPo, moveRamkaTo*) i przy zakładaniu wpisu przeglądu (Infos.insertInfo):
//- żółty: zadanie "do zrobienia" inne niż "można izolować",
//- pomarańczowy: mateczniki nieusunięte (więcej mateczników niż usuniętych),
//- inaczej zielony.
//Liczone z ramek TEGO przeglądu (data, pasieka, ul; wszystkie korpusy, widok "po").
//Te same zasady barwią ikonę ula na belce - colony_helpers.ikonaNaBelce.

/// Kolor przeglądu z wierszy ramek (zasob, wartosc) - zasoby 11, 12, 13.
String kolorPrzegladuZRamek(Iterable<Map<String, dynamic>> ramki) {
  var kolor = 'green';
  var mateczniki = 0, usuniete = 0;
  for (final r in ramki) {
    final String wartosc = '${r['wartosc'] ?? ''}';
    final int ile = int.tryParse(wartosc.replaceAll('%', '').trim()) ?? 0;
    switch (r['zasob']) {
      case 11:
        mateczniki += ile;
        break;
      case 12:
        usuniete += ile;
        break;
      case 13:
        if (zadanieDoZrobienia(wartosc)) kolor = gorszaIkona(kolor, 'yellow');
        break;
    }
  }
  if (otwarteMateczniki(mateczniki, usuniete)) kolor = gorszaIkona(kolor, 'orange');
  return kolor;
}

//zapisy ramek idą seriami (obie strony, kilka ramek) - jedno przeliczenie na przegląd,
//po ostatnim zapisie serii
final Map<String, Timer> _czekajace = {};

/// Przeliczenie koloru przeglądu [data] ula [pasieka].[ul] chwilę po ostatnim zapisie.
void zaplanujKolorPrzegladu(String data, int pasieka, int ul) {
  final klucz = '$data.$pasieka.$ul';
  _czekajace.remove(klucz)?.cancel();
  _czekajace[klucz] = Timer(const Duration(milliseconds: 400), () {
    _czekajace.remove(klucz);
    aktualizujKolorPrzegladu(data, pasieka, ul).catchError((_) {});
  });
}

/// Jak [zaplanujKolorPrzegladu], z id ramki (data.pasieka.ul.korpus.przed.po.strona.zasob).
/// Inne zasoby niż 11-13 koloru nie zmieniają. [ulDocelowy] - ramka przeniesiona do innego ula.
void zaplanujKolorPrzegladuRamki(String idRamki, {int? ulDocelowy}) {
  final c = idRamki.split('.');
  if (c.length < 3) return;
  final pasieka = int.tryParse(c[1]), ul = int.tryParse(c[2]);
  if (pasieka == null || ul == null) return;
  final zasob = c.length >= 8 ? int.tryParse(c[7]) : null;
  if (zasob != null && (zasob < 11 || zasob > 13)) return;
  zaplanujKolorPrzegladu(c[0], pasieka, ul);
  if (ulDocelowy != null && ulDocelowy != ul) zaplanujKolorPrzegladu(c[0], pasieka, ulDocelowy);
}

/// Zapis koloru we wpisie przeglądu (gdy jest i kolor się zmienił) oraz w providerze Infos.
Future<void> aktualizujKolorPrzegladu(String data, int pasieka, int ul) async {
  //wpis przeglądu z innego języka ma inne id
  final id = await DBHelper.inspectionId(data, pasieka, ul, wszystkieJezyki((l) => l.inspection));
  if (id == null) return;
  final kolor = kolorPrzegladuZRamek(await DBHelper.getZadaniaIMatecznikiPrzegladu(data, pasieka, ul));
  if (await DBHelper.getInfoWartosc(id) == kolor) return; //bez zmiany - bez ponownego eksportu
  await DBHelper.updateInfoWartosc(id, kolor);
  Infos.zmienWartoscWpisu(id, kolor);
}
