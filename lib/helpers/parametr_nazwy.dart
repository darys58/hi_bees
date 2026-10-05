import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'queen_helpers.dart'; //jakoscMatkiNaEkran, znakMatkiNaEkran

/// Nazwa parametru do POKAZANIA użytkownikowi.
///
/// Kolumna `info.parametr` trzyma dla leczenia KLUCZE TECHNICZNE - `apivarol`
/// i `biovar` - i te klucze zostają w bazie na zawsze: zależy od nich logika
/// w kilkunastu miejscach (liczniki „ostatnie leczenie w roku"
/// w `infos_screen`, gałęzie formularza w `infos_edit_screen`, zapis głosowy),
/// a import z chmury i tak przywlecze stare wiersze z tymi wartościami.
///
/// Zmienia się WYŁĄCZNIE to, co widać. Do 05.09.2026 wartość kolumny szła na
/// ekran surowa (`info_item.dart`), więc pszczelarz czytał w historii nazwy
/// preparatów - „apivarol" i „biovar" - choć gramatyka głosowa mówi od czasu
/// migracji na Vosk „chemia" i „paski". Ta funkcja jest jedynym miejscem,
/// w którym klucz zamienia się w nazwę, więc ręczne wpisy i głosowe pokazują
/// się identycznie.
///
/// Klucz nieznany wraca BEZ ZMIAN, razem z ewentualną spacją na początku:
/// część zapisów trzyma ją celowo (patrz `" excluder -"` w painterze ramek),
/// a dopasowanie i tak idzie po [String.trim].
String nazwaParametru(BuildContext context, String parametr) {
  final l = AppLocalizations.of(context)!;
  switch (parametr.trim()) {
    case 'apivarol':
      return l.apivarolChemistry;
    case 'biovar':
      return l.treatmentStrips;
    default:
      //wpis zapisany przy innym języku interfejsu - na ekran w BIEŻĄCYM (05.10.2026).
      //Tylko wyświetlanie: w bazie zostaje tekst z chwili zapisu (bez migracji).
      return parametrWBiezacym(context, parametr);
  }
}

/// Napis zbudowany z AppLocalizations we WSZYSTKICH siedmiu językach naraz.
///
/// `info.parametr` (i część `info.wartosc`) zapisuje się w języku interfejsu
/// z chwili zapisu - np. `honey + " = "` to w bazie "miód = " albo "honey = ".
/// Porównanie z napisem bieżącego języka gubiło po zmianie języka wszystkie
/// starsze wpisy, a przeliczenia belek (OdswiezBelkiMatka, OdswiezBelkiZ)
/// i import NADPISYWAŁY przez to kolumny tabeli `ule` pustymi wartościami
/// (analiza 05.10.2026). Tu dopasowanie idzie po zbiorze wszystkich wersji:
///
///     wszystkieJezyki((l) => l.queen + " -").contains(inf.parametr)
///
/// Zbiór zbudowany jest z tych samych plików ARB co zapis, więc nowy klucz
/// albo nowy język nie wymaga dopisywania literałów.
Set<String> wszystkieJezyki(String Function(AppLocalizations l) napis) => {
      for (final locale in AppLocalizations.supportedLocales)
        napis(lookupAppLocalizations(locale)),
    };

/// Parametry `info`, które statystyki i raporty porównują z napisem
/// bieżącego języka (zbiory, wyposażenie, rodzina, matka, karmienie, leczenie).
/// Kolejność ma znaczenie tylko przy napisach identycznych w kilku szablonach:
/// wygrywa wcześniejszy. Dziś to jedynie angielskie "portion" dla porcji
/// i miarki pyłku - wszędzie liczone razem, więc bez skutków.
final List<String Function(AppLocalizations l)> _szablonyParametrow = [
  (l) => l.honey + " = ", //miód w kg
  (l) => l.honey + " = " + l.small + " " + l.frame + " x",
  (l) => l.honey + " = " + l.big + " " + l.frame + " x",
  (l) => l.beePollen + "  = " + l.portion + " x",
  (l) => l.beePollen + "  = " + l.miarka + " x",
  (l) => l.beePollen + " = ", //pyłek w ml
  (l) => " " + l.beePollen + " =  ", //pyłek w l
  (l) => l.excluder,
  (l) => " " + l.excluder + " -",
  (l) => l.bottomBoard + " " + l.isIs,
  (l) => l.beePollenTrap + " " + l.isIs,
  (l) => l.numberOfFrame + " = ",
  (l) => " " + l.colony + " " + l.isIs, //siła rodziny
  (l) => l.colony + " " + l.isIs, //stan rodziny
  (l) => l.deadBees,
  (l) => l.queen + '  ' + l.isIs, //jakość matki
  (l) => l.queenWasBornIn,
  (l) => l.queen + " -", //unasiennienie
  (l) => l.queenIs, //ograniczenie
  (l) => " " + l.queen, //znak matki
  (l) => l.syrup + " 1:1",
  (l) => l.syrup + " 3:2",
  (l) => l.invert,
  (l) => l.candy,
  (l) => l.removedFood,
  (l) => l.leftFood,
  (l) => l.acid,
  (l) => " " + l.acid,
  (l) => l.inspection,
  (l) => l.honey, //belka ula: ule.parametr dla zbioru (OdswiezBelkiZ) - tylko do wyświetlania
];

/// Wartości `info.wartosc` porównywane w statystykach z napisem bieżącego
/// języka i wybierane z list rozwijanych w infos_edit_screen (każda pozycja
/// list musi tu być - inaczej edycja starego wpisu przy innym języku dawała
/// wartość spoza listy i DropdownButton wywracał ekran, 05.10.2026).
/// "usuń"/"zabierz" mają w ES, FR i PT ten sam napis - obie idą w statystyce
/// do tej samej gałęzi. "trutówka" (matka) i "strutowiała" (rodzina) - ten sam
/// napis w DE, ES, FR, IT, PT: rozstrzyga parametr (patrz wartoscWBiezacym).
final List<String Function(AppLocalizations l)> _szablonyWartosci = [
  (l) => l.virgine,
  (l) => l.naturallyMated,
  (l) => l.artificiallyInseminated,
  (l) => l.droneLaying, //_iTrutowka - indeks 3
  (l) => l.freed,
  (l) => l.zalacz,
  (l) => l.set,
  (l) => l.close,
  (l) => l.off,
  (l) => l.open,
  (l) => l.aggressive,
  (l) => l.normal,
  (l) => l.remove,
  (l) => l.delete,
  //matka jest: (wolna wyżej)
  (l) => l.inCage,
  (l) => l.inInsulator,
  (l) => l.isolated,
  //stan rodziny (agresywna wyżej, "ok" bez tłumaczenia)
  (l) => l.gentle,
  (l) => l.swarmingMood,
  (l) => l.inCluster,
  (l) => l.droneBees, //_iStrutowiala
  (l) => l.dead,
  //siła rodziny (normalna wyżej)
  (l) => l.veryStrong,
  (l) => l.strong,
  (l) => l.weak,
  (l) => l.veryWeak,
  //dennica
  (l) => l.dirty,
  (l) => l.clean,
  //krata odgrodowa
  (l) => l.onBodyNumber,
  //znak matki: brak (znaki kolorów tłumaczy znakMatkiNaEkran)
  (l) => l.missing,
  (l) => l.gone,
  //jakości matki CELOWO tu nie ma - patrz jakoscMatkiNaEkran w queen_helpers
];
const int _iTrutowka = 3;
const int _iStrutowiala = 20; //indeks l.droneBees w _szablonyWartosci

//napis w dowolnym z siedmiu języków -> numer szablonu (liczone raz, leniwie)
Map<String, int> _indeksSzablonow(List<String Function(AppLocalizations l)> szablony) {
  final indeks = <String, int>{};
  for (final locale in AppLocalizations.supportedLocales) {
    final l = lookupAppLocalizations(locale);
    for (var i = 0; i < szablony.length; i++) {
      indeks.putIfAbsent(szablony[i](l), () => i);
    }
  }
  return indeks;
}

final Map<String, int> _indeksParametrow = _indeksSzablonow(_szablonyParametrow);
final Map<String, int> _indeksWartosci = _indeksSzablonow(_szablonyWartosci);

/// Zapisany `info.parametr` przełożony na BIEŻĄCY język interfejsu.
///
/// Statystyki i raporty porównują `parametr == loc.honey + " = "` itd., więc
/// po zmianie języka wszystkie wcześniejsze wpisy dawały 0 (analiza
/// 05.10.2026). Zamiast przepisywać setki porównań, lewa strona idzie przez
/// tę funkcję: "miód = " oglądane po angielsku staje się "honey = ".
/// Parametr spoza listy (klucze techniczne: "varroa", "apivarol", "biovar",
/// "tag NFC") wraca bez zmian.
///
/// TYLKO do porównań i liczenia - nie zapisywać wyniku do bazy (id wpisu
/// zawiera parametr w języku zapisu).
String parametrWBiezacym(BuildContext context, String parametr) {
  final l = AppLocalizations.of(context)!;
  //już poprawny w bieżącym języku - bez zmian (przy napisie wspólnym dla dwóch
  //szablonów nie wolno podmienić jednego na drugi)
  if (_napisyBiezace(_szablonyParametrow, l, _biezaceParametry).contains(parametr)) return parametr;
  final i = _indeksParametrow[parametr];
  return i == null ? parametr : _szablonyParametrow[i](l);
}

/// To samo co [parametrWBiezacym] dla `info.wartosc` (stan matki, poławiacz,
/// stan rodziny). Wartość spoza listy wraca bez zmian.
String wartoscWBiezacym(BuildContext context, String wartosc, {String? parametr}) {
  final l = AppLocalizations.of(context)!;
  if (parametr != null) {
    final p = parametrWBiezacym(context, parametr);
    //jakość matki - własne tłumaczenie (dawna "zła" != "zła" agresywna rodzina)
    if (p == l.queen + '  ' + l.isIs) return jakoscMatkiNaEkran(wartosc, l);
    //znak matki - "ma biały znak", klucze "mark_white" itd.
    if (p == " " + l.queen) wartosc = znakMatkiNaEkran(wartosc, l);
  }
  //np. francuskie "retirer" to i "usuń", i "zabierz" - wartość poprawna w bieżącym
  //języku zostaje, inaczej edycja zamieniłaby jedno na drugie
  if (_napisyBiezace(_szablonyWartosci, l, _biezaceWartosci).contains(wartosc)) return wartosc;
  var i = _indeksWartosci[wartosc];
  if (i == null) return wartosc;
  //"drohnenbrütig" itp.: przy stanie rodziny to "strutowiała", nie "trutówka"
  if (i == _iTrutowka && parametr != null &&
      parametrWBiezacym(context, parametr) == l.colony + " " + l.isIs) {
    i = _iStrutowiala;
  }
  return _szablonyWartosci[i](l);
}

//napisy szablonów w bieżącym języku - liczone raz na język (wołane w pętlach statystyk)
final Map<String, Set<String>> _biezaceParametry = {};
final Map<String, Set<String>> _biezaceWartosci = {};
Set<String> _napisyBiezace(List<String Function(AppLocalizations l)> szablony,
        AppLocalizations l, Map<String, Set<String>> pamiec) =>
    pamiec.putIfAbsent(l.localeName, () => {for (final s in szablony) s(l)});

/// Rodzaj ula (`ule.h1`, `info.pogoda` wpisu "liczba ramek =") w BIEŻĄCYM języku.
///
/// Rodzaj zapisuje się tekstem z chwili zapisu: `loc.hIve` ("Ul", "Hive",
/// "Beute"...) albo `loc.nUc` ("Odkład", "Nuc", "Ableger"...), plus stałe
/// "Mini". Rozpoznaje bez względu na wielkość liter (starsze dane: "UL").
/// "Mini" i wartości nieznane wracają bez zmian. Do wyświetlania i formularza.
String rodzajUlaWBiezacym(BuildContext context, String rodzaj) {
  final r = rodzaj.trim().toLowerCase();
  if (r.isEmpty) return rodzaj;
  final l = AppLocalizations.of(context)!;
  if (_rodzajeUl.contains(r)) return l.hIve;
  if (_rodzajeOdklad.contains(r)) return l.nUc;
  return rodzaj;
}

final Set<String> _rodzajeUl = wszystkieJezyki((l) => l.hIve.toLowerCase());
final Set<String> _rodzajeOdklad = wszystkieJezyki((l) => l.nUc.toLowerCase());

/// Jednostka (`info.miara`) w BIEŻĄCYM języku - do wyświetlania i formularza.
///
/// Zapisywane tekstem z chwili zapisu: `loc.dose` ("dawka"), `loc.mites`
/// (warroza: "sztuk"/"mites") i `loc.pieces` (paski: "sztuk"/"units").
/// mites i pieces mają w PL, DE, IT, ES i PT ten sam napis - rozstrzyga
/// [parametr]: "varroa" to roztocza, reszta to sztuki. Jednostki uniwersalne
/// (kg, l, ml, g), liczby i typy ula wracają bez zmian.
String miaraWBiezacym(BuildContext context, String miara, {String? parametr}) {
  if (miara.isEmpty) return miara;
  final l = AppLocalizations.of(context)!;
  final bool warroza = parametr?.trim() == 'varroa';
  if (_dawki.contains(miara)) return l.dose;
  if (_sztuki.contains(miara)) return warroza ? l.mites : l.pieces;
  return miara;
}

final Set<String> _dawki = wszystkieJezyki((l) => l.dose);
final Set<String> _sztuki = {
  ...wszystkieJezyki((l) => l.mites),
  ...wszystkieJezyki((l) => l.pieces),
};

/// Rok raportu/statystyk na ekran. `globals.rokRaportow` i `rokStatystyk` trzymają
/// dla "wszystkich lat" KLUCZ 'wszystkie' (porównywany w kodzie), który szedł do
/// tytułów i PDF po polsku w każdym języku (05.10.2026). Lata wracają bez zmian.
String rokNaEkran(BuildContext context, String rok) =>
    rok == 'wszystkie' ? AppLocalizations.of(context)!.aLl : rok;

/// Zadanie/czynność ramki ("ramka pracy", "trzeba wirować"... - wartość zasobu
/// 13/14, w belce `ule.todo`) w BIEŻĄCYM języku. Zapisywane tekstem z chwili
/// zapisu; nieznane wraca bez zmian. Do wyświetlania ("Aktualności ula").
String zadanieRamkiWBiezacym(BuildContext context, String zadanie) {
  final i = _indeksZadan[zadanie];
  return i == null ? zadanie : _szablonyZadan[i](AppLocalizations.of(context)!);
}

final List<String Function(AppLocalizations l)> _szablonyZadan = [
  (l) => l.workFrame,
  (l) => l.toExtraction,
  (l) => l.toDelete,
  (l) => l.toInsulate,
  (l) => l.deleted,
  (l) => l.inserted,
  (l) => l.insulated,
  (l) => l.movedLeft,
  (l) => l.movedRight,
];
final Map<String, int> _indeksZadan = _indeksSzablonow(_szablonyZadan);
