import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

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
      return parametr;
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
];

/// Wartości `info.wartosc` porównywane w statystykach z napisem bieżącego
/// języka. "usuń"/"zabierz" mają w ES, FR i PT ten sam napis - obie idą
/// w statystyce do tej samej gałęzi.
final List<String Function(AppLocalizations l)> _szablonyWartosci = [
  (l) => l.virgine,
  (l) => l.naturallyMated,
  (l) => l.artificiallyInseminated,
  (l) => l.droneLaying,
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
];

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
  final i = _indeksParametrow[parametr];
  return i == null ? parametr : _szablonyParametrow[i](AppLocalizations.of(context)!);
}

/// To samo co [parametrWBiezacym] dla `info.wartosc` (stan matki, poławiacz,
/// stan rodziny). Wartość spoza listy wraca bez zmian.
String wartoscWBiezacym(BuildContext context, String wartosc) {
  final i = _indeksWartosci[wartosc];
  return i == null ? wartosc : _szablonyWartosci[i](AppLocalizations.of(context)!);
}
