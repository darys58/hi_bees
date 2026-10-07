import 'package:shared_preferences/shared_preferences.dart';

import '../globals.dart' as globals;
import 'db_helper.dart';

//Przełączanie baz: własna <-> baza właściciela, w której użytkownik jest pracownikiem (etap 2, 07.10.2026).
//Każda baza to osobny plik SQLite (globals.plikBazy()); wybór zapamiętany w SharedPreferences.

const String _kBaza = 'hb_aktywna_baza';
const String _kEmail = 'hb_aktywna_baza_email';

//wywoływane w main() PRZED pierwszym otwarciem bazy
Future<void> wczytajAktywnaBaze() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String baza = prefs.getString(_kBaza) ?? '';
    globals.aktywnaBaza = RegExp(r'^[0-9A-Z]{4}$').hasMatch(baza) ? baza : '';
    globals.aktywnaBazaEmail = globals.aktywnaBaza.isEmpty ? '' : (prefs.getString(_kEmail) ?? '');
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
Future<void> przelaczBaze(String prefiks, String email, int stanowisko) async {
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
