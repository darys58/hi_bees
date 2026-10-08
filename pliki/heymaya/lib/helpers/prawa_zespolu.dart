import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../globals.dart' as globals;
import 'baza_zespolu.dart';

//Blokady zapisu w bazie właściciela (etap 2 część B, 07.10.2026). Prawa - globals.prawaBazy (baza_zespolu.dart).
//We własnej bazie wszystko wolno - funkcje od razu zwracają "wolno".
//Zasady: odczyt+zapis = wszystko; sam zapis = dopisywanie + poprawianie/usuwanie własnych wpisów,
//dopóki nie poszły do chmury (B1: serwer ich jeszcze nie zna, więc przyjmie); sam odczyt = podgląd.
//Serwer i tak odrzuca zapis bez prawa - blokady oszczędzają pracy, która by przepadła.

//klucze części jak na serwerze
const String czNotatki = 'notatki', czZbiory = 'zbiory', czZakupy = 'zakupy', czSprzedaz = 'sprzedaz',
    czMatki = 'matki', czRamka = 'ramka', czInfo = 'info', czZdjecia = 'zdjecia';

String nazwaCzesci(AppLocalizations l, String c) {
  switch (c) {
    case czNotatki: return l.nOtes;
    case czZbiory: return l.hArvests;
    case czZakupy: return l.pUrchase;
    case czSprzedaz: return l.sAle;
    case czMatki: return l.qUeens;
    case czRamka: return l.fRames;
    case czInfo: return l.iNfos;
    case czZdjecia: return l.pHotos;
  }
  return c;
}

//null = wolno, inaczej treść komunikatu. [czesci] - części, do których idzie zapis;
//[edycja] - zmiana albo usunięcie istniejącego wpisu; [wyslany] - wpis był już w chmurze (arch != 0);
//[pasieka] - pasieka wpisu (0 = ogólne, zawsze w zakresie)
String? powodBlokady(AppLocalizations l, List<String> czesci,
    {bool edycja = false, bool wyslany = true, int? pasieka}) {
  if (globals.aktywnaBaza.isEmpty) return null;
  if (globals.zapisBazyWstrzymany) return l.teamBlockedSubscription;
  for (final c in czesci) {
    if (!globals.mogeDopisac(c)) return l.teamBlockedWrite(nazwaCzesci(l, c));
    if (edycja && wyslany && !globals.mogeEdytowac(c)) return l.teamBlockedEdit(nazwaCzesci(l, c));
  }
  if (pasieka != null && !globals.pasiekaWZakresie(pasieka)) return l.teamBlockedApiary('$pasieka');
  return null;
}

//true = wolno; przy blokadzie komunikat na dole ekranu
bool mogeZapisac(BuildContext context, List<String> czesci,
    {bool edycja = false, bool wyslany = true, int? pasieka}) {
  if (globals.aktywnaBaza.isEmpty) return true;
  final l = AppLocalizations.of(context)!;
  final powod = powodBlokady(l, czesci, edycja: edycja, wyslany: wyslany, pasieka: pasieka);
  if (powod == null) return true;
  pokazBlokade(context, powod);
  return false;
}

//operacje tylko dla właściciela (B3: usuwanie i przenoszenie uli, pełny eksport)
bool tylkoWlasciciel(BuildContext context) {
  if (globals.aktywnaBaza.isEmpty) return true;
  pokazBlokade(context, AppLocalizations.of(context)!.teamBlockedOwnerOnly);
  return false;
}

void pokazBlokade(BuildContext context, String tekst) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(tekst)));
}

//Odpowiedź serwera na eksport części [czesc] (B4). true = oznaczyć wysłane wpisy jako przesłane (arch = 1).
//We własnej bazie jak dotąd: tylko "ok". W bazie właściciela:
//- "zpisano tylko X z Y" (serwer odrzucił pojedyncze wiersze: pasieka spoza zakresu, zmiana przy samym
//  zapisie) i odrzucone zdjęcie ("bład zapisu") - komunikat i oznaczenie: odrzucone zostają tylko w telefonie,
//  następny import je nadpisze, a nie wracają przy każdym eksporcie;
//- "error - niepoprawna tabela" (cała część odrzucona: brak prawa, abonament, odwołany dostęp - albo kłopot
//  z tokenem) - komunikat BEZ oznaczania, żeby kłopot z tokenem nie zgubił pracy; prawa odświeżane z serwera.
//[komunikaty] - gdy podane, komunikat trafia tam (podsumowanie eksportu), a nie na dół ekranu.
bool eksportDoOznaczenia(BuildContext context, dynamic success, String czesc, String jsonData,
    {List<String>? komunikaty}) {
  final String odp = '${success ?? ''}';
  if (odp == 'ok') return true;
  if (globals.aktywnaBaza.isEmpty) return false;
  //liczba wysłanych z pola "total" - JSON eksportu jest sklejany z tekstów, więc bez pełnego dekodowania
  final String wyslane = RegExp(r'"total":\s*(\d+)').firstMatch(jsonData)?.group(1) ?? '';
  String? przyjete, wszystkie;
  bool oznaczyc = false;
  final m = RegExp(r'zpisano tylko (\d+) z (\d+)').firstMatch(odp);
  if (m != null) {
    przyjete = m.group(1);
    wszystkie = m.group(2);
    oznaczyc = true;
  } else if (czesc == czZdjecia && odp == 'bład zapisu') {
    przyjete = '0';
    wszystkie = '1';
    oznaczyc = true;
  } else if (odp == 'error - niepoprawna tabela') {
    przyjete = '0';
    wszystkie = wyslane;
    odswiezPrawaBazy();
  }
  if (przyjete != null && context.mounted) {
    final l = AppLocalizations.of(context)!;
    final tekst = l.teamExportRejected(przyjete, wszystkie ?? '', nazwaCzesci(l, czesc));
    if (komunikaty != null) {
      komunikaty.add(tekst);
    } else {
      pokazBlokade(context, tekst);
    }
  }
  return oznaczyc;
}
