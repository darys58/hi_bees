import 'package:flutter/material.dart';
import 'package:heymaya/l10n/app_localizations.dart';

import '../models/hive.dart';
import '../models/hives.dart'; //podsumowaniePasieki - lokalny odczyt uli ze stanem rodziny
import '../models/info.dart'; //stanMatkiUla
import 'queen_helpers.dart'; //stanMatkiUla - ta sama logika co belka matki
import 'colony_helpers.dart'; //ikonaStanuRodziny, zadanieDoZrobienia, kolorIkonyUla
import 'db_helper.dart';
import 'parametr_nazwy.dart'; //wszystkieJezyki, zadanieRamkiWBiezacym, kolejnoscZadaniaRamki

//WIDOK ULI Z PROBLEMAMI - PODSUMOWANIE (20.10.2026). Pod szarym paskiem "Ule z problemami"
//zbiorczo: matki (brak, do wymiany, nieunasienniona, trutowa), stan rodziny (chora,
//strutowiała, agresywna, w nastroju do ucieczki, nie żyje), mateczniki, zadania ramek
//("do zrobienia" bez "można izolować") i ule zlikwidowane - każdy wiersz z liczbą i numerami uli.
//Matki i rodzina z belek uli (dlatego kafelek odświeża belki "o zasobach i matkach"),
//mateczniki i zadania z RAMEK: ostatni przegląd każdego korpusu (jak Aktualności ula),
//widok "po" (ramkaNrPo <> 0) - belka zna tylko ostatni korpus.

/// Zadania i mateczniki jednego ula z ostatniego przeglądu każdego korpusu.
class RamkiProblemuUla {
  final Map<String, Set<String>> zadania = {}; //zadanie -> korpus.ramka (obie strony raz)
  int mateczniki = 0;
  int usuniete = 0;
  int get otwarte => mateczniki > usuniete ? mateczniki - usuniete : 0;
  //daty przeglądów, z których są mateczniki i zadania - notatki przeglądu w podsumowaniu głosu
  final Set<String> daty = {};
}

/// ul -> zadania i mateczniki z ramek pasieki [pasieka].
Future<Map<int, RamkiProblemuUla>> ramkiProblemowPasieki(int pasieka) async {
  final wynik = <int, RamkiProblemuUla>{};
  for (final r in await DBHelper.getZadaniaIMatecznikiPasieki(pasieka)) {
    final u = wynik.putIfAbsent(r['ulNr'] as int, () => RamkiProblemuUla());
    final String wartosc = '${r['wartosc'] ?? ''}';
    final int ile = int.tryParse(wartosc.replaceAll('%', '').trim()) ?? 0;
    final String data = '${r['data'] ?? ''}';
    switch (r['zasob']) {
      case 11:
        u.mateczniki += ile;
        u.daty.add(data);
        break;
      case 12:
        u.usuniete += ile;
        u.daty.add(data);
        break;
      case 13:
        if (zadanieDoZrobienia(wartosc)) {
          u.zadania.putIfAbsent(wartosc, () => <String>{}).add('${r['korpusNr']}.${r['ramkaNr']}');
          u.daty.add(data);
        }
        break;
    }
  }
  return wynik;
}

//stany rodziny w kolejności wierszy: wartości we wszystkich językach -> etykieta
List<(Set<String>, String Function(AppLocalizations))> _stanyRodziny() => [
      (wszystkieJezyki((l) => l.dead), (l) => l.dead),
      (wszystkieJezyki((l) => l.colonySick), (l) => l.colonySick),
      (wszystkieJezyki((l) => l.droneBees), (l) => l.droneBees),
      ({...wszystkieJezyki((l) => l.aggressive), ...wszystkieJezyki((l) => l.aggressive1)}, (l) => l.aggressive1),
      ({...wszystkieJezyki((l) => l.swarmingMood), 'swarming'}, (l) => l.swarmingMood),
    ];

/// Panel podsumowania problemów pasieki. [ule] - wszystkie ule pasieki,
/// [ramki] - wynik [ramkiProblemowPasieki] (null - jeszcze się liczy).
Widget panelProblemowPasieki(BuildContext context, List<Hive> ule, Map<int, RamkiProblemuUla>? ramki) {
  final l = AppLocalizations.of(context)!;
  final wiersze = <Widget>[];

  //[numery] - numery uli; [liczba] - zamiast liczby uli (np. liczba ramek);
  //[dopiski] - przy numerze ula w nawiasie (np. ile ramek w tym ulu)
  void wiersz(List<Widget> ikony, String opis, List<int> numery,
      {int? liczba, Map<int, int>? dopiski}) {
    if (numery.isEmpty) return;
    numery.sort();
    final listaUli = numery
        .map((n) => dopiski == null ? '$n' : '$n (${dopiski[n]})')
        .join(', ');
    wiersze.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Row(children: [
              for (var i = 0; i < ikony.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                ikony[i],
              ],
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('${l.hivesPlural}: $listaUli',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${liczba ?? numery.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    ));
  }

  Widget obrazek(String sciezka) => Image.asset(sciezka, width: 22, height: 22, fit: BoxFit.contain);
  const czerwony = Color.fromARGB(255, 255, 0, 0);

  //ule zlikwidowane - tylko w swoim wierszu, poza tym pomijane
  final zlikwidowane = ule.where((h) => h.ikona == 'black').toList();
  final czynne = ule.where((h) => h.ikona != 'black').toList();
  List<int> gdzie(bool Function(Hive) warunek) =>
      czynne.where(warunek).map((h) => h.ulNr).toList();

  //MATKA
  final matka = obrazek('assets/image/matka1.png');
  wiersz([matka, const Icon(Icons.dangerous_outlined, size: 22, color: czerwony)],
      '${l.qUeen}: ${l.missing}', gdzie((h) => h.matka2.startsWith('brak')));
  wiersz([matka, const Icon(Icons.thumb_down_outlined, size: 22, color: czerwony)],
      '${l.qUeen}: ${l.canceled}', gdzie((h) => h.matka1 == 'zła'));
  wiersz([matka, const Icon(Icons.egg_outlined, size: 22, color: czerwony)],
      '${l.qUeen}: ${l.virgine1}', gdzie((h) => h.matka3 == 'nieunasienniona'));
  wiersz([matka, const Icon(Icons.egg_outlined, size: 22, color: czerwony)],
      '${l.qUeen}: ${l.droneLaying}', gdzie((h) => h.matka3 == 'trutowa'));

  //RODZINA
  final pszczola = obrazek('assets/image/pszczola1.png');
  for (final (wartosci, etykieta) in _stanyRodziny()) {
    final nazwa = etykieta(l);
    wiersz([pszczola, if (ikonaStanuRodziny(nazwa, size: 22) != null) ikonaStanuRodziny(nazwa, size: 22)!],
        '${l.cOlony}: $nazwa', gdzie((h) => wartosci.contains(h.stanRodziny.trim())));
  }

  //RAMKI - mateczniki i zadania
  if (ramki != null) {
    final przeglad = obrazek('assets/image/hi_bees.png');
    final numeryCzynnych = czynne.map((h) => h.ulNr).toSet();
    final zMatecznikami = <int, int>{
      for (final e in ramki.entries)
        if (numeryCzynnych.contains(e.key) && e.value.otwarte > 0) e.key: e.value.otwarte,
    };
    wiersz([przeglad, const Icon(Icons.circle, size: 14, color: Color.fromARGB(255, 255, 17, 0))],
        l.queenCellsCount[0].toUpperCase() + l.queenCellsCount.substring(1),
        zMatecznikami.keys.toList(),
        liczba: zMatecznikami.values.fold<int>(0, (a, b) => a + b),
        dopiski: zMatecznikami);

    //zadanie (w bieżącym języku) -> ul -> ile ramek; ten sam napis z różnych języków sumowany
    final zadania = <String, Map<int, int>>{};
    final kolejnosc = <String, int>{};
    for (final e in ramki.entries) {
      if (!numeryCzynnych.contains(e.key)) continue;
      for (final z in e.value.zadania.entries) {
        final nazwa = zadanieRamkiWBiezacym(context, z.key);
        final naUl = zadania.putIfAbsent(nazwa, () => <int, int>{});
        naUl[e.key] = (naUl[e.key] ?? 0) + z.value.length;
        kolejnosc[nazwa] = kolejnoscZadaniaRamki(z.key);
      }
    }
    final nazwy = zadania.keys.toList()..sort((a, b) => kolejnosc[a]!.compareTo(kolejnosc[b]!));
    for (final nazwa in nazwy) {
      final naUl = zadania[nazwa]!;
      wiersz([przeglad, Icon(Icons.change_history, size: 20, color: kolorIkonyUla('yellow'))],
          '${l.toDo}: $nazwa', naUl.keys.toList(),
          liczba: naUl.values.fold<int>(0, (a, b) => a + b), dopiski: naUl);
    }
  }

  //UL ZLIKWIDOWANY
  wiersz([Icon(Icons.hive, size: 22, color: kolorIkonyUla('black'))],
      l.hivesExistLiquidated[0].toUpperCase() + l.hivesExistLiquidated.substring(1),
      zlikwidowane.map((h) => h.ulNr).toList());

  if (wiersze.isEmpty) return const SizedBox.shrink();
  return Card(
    margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: wiersze),
    ),
  );
}

//PODSUMOWANIE PASIEKI W STEROWANIU GŁOSEM (28.10.2026). Po "otwórz pasiekę X" nakładka
//z listą uli z problemami, NAJPILNIEJSZE NA GÓRZE - od którego ula zacząć i co tam zrobić.
//Te same rodzaje problemów co panelProblemowPasieki, ale dane NIEZALEŻNE od trybu belek:
//belki matek (matka1/2) są aktualne tylko w trybie "o zasobach i matkach" (inne tryby je
//zerują), więc stan matki liczy stanMatkiUla() z wpisów info - tą samą logiką co
//OdswiezBelkiMatka w hives_screen (bez zapisu do bazy).

/// Problemy z matką jednego ula (tylko te, które trafiają do podsumowania).
class StanMatkiUla {
  bool brak = false;
  bool doWymiany = false;
  String stan = ''; //'nieunasienniona' / 'trutowa' / ''
  //uwagi z wpisów, które dały powyższe problemy (podsumowanie w sterowaniu głosem)
  final List<String> uwagi = [];
}

/// Stan matki ula [ul] z wpisów info - odpowiednik OdswiezBelkiMatka (matka1/2/3).
/// [wpisyUla] - info ula, najnowsze pierwsze (null = pobrać z bazy).
Future<StanMatkiUla> stanMatkiUla(int pasieka, int ul, {List<Info>? wpisyUla}) async {
  final wynik = StanMatkiUla();
  final List<Info> wpisy = wpisyUla ??
      (await DBHelper.getInfosOfHive(pasieka, ul)).map((m) => Info.fromMap(m)).toList();
  final pJakosc = wszystkieJezyki((l) => l.queen + '  ' + l.isIs); //matka1
  final pZnak = wszystkieJezyki((l) => " " + l.queen); //matka2
  final pStan = wszystkieJezyki((l) => l.queen + " -"); //matka3

  //matka w ulu TERAZ: główna z tabeli matek, bez niej - z najnowszego wpisu o znaku
  final List<int> matkiUla = await idMatekUla(pasieka, ul);
  String idMatki = matkiUla.isNotEmpty ? matkiUla.first.toString() : '';
  if (matkiUla.isEmpty) {
    Info? wpisZnaku;
    for (final inf in wpisy) {
      if (inf.kategoria == 'queen' && pZnak.contains(inf.parametr) &&
          inf.wartosc.isNotEmpty && wpisZnakuNowszy(inf, wpisZnaku)) {
        wpisZnaku = inf;
        idMatki = inf.pogoda;
      }
    }
  }
  final Map<String, DateTime> wejscia = matkiUla.isNotEmpty
      ? wejsciaMatek(wpisy, matkiUla.map((id) => '$id'))
      : {idMatki: momentPodlaczeniaMatki(wpisy, idMatki) ?? DateTime(1900)};
  bool tejMatki(Info inf) => wpisMatki(inf, idMatki, wejscia);

  //matka siedzi teraz w innym ulu (tabela matek) - tu nie pokazujemy jej cech
  bool gdzieIndziej = false;
  final int? idLiczba = int.tryParse(idMatki);
  if (idLiczba != null && idLiczba > 0) {
    final miejsce = await DBHelper.getMiejsceMatki(idLiczba);
    if (miejsce.isNotEmpty && (miejsce[0]['pasieka'] != pasieka || miejsce[0]['ul'] != ul)) {
      gdzieIndziej = true;
    }
  }

  //cechy przeniesione z poprzedniego ula tej matki
  List<Info> wpisyMatki = [];
  if (idMatki.isNotEmpty) {
    wpisyMatki = (await DBHelper.getInfosOfQueen(idMatki)).map((m) => Info.fromMap(m)).toList();
  }
  Info? przeniesiony(Set<String> parametry) {
    for (final inf in wpisyMatki) {
      if (parametry.contains(inf.parametr) && inf.wartosc.isNotEmpty &&
          (inf.ulNr != ul || inf.pasiekaNr != pasieka)) return inf;
    }
    return null;
  }

  //najnowszy wpis tej matki o cesze (lista z bazy: najnowsze pierwsze)
  Info? cecha(Set<String> parametry) {
    for (final inf in wpisy) {
      if (inf.kategoria == 'queen' && inf.wartosc.isNotEmpty &&
          parametry.contains(inf.parametr) && tejMatki(inf)) return inf;
    }
    return przeniesiony(parametry);
  }

  final jakosc = cecha(pJakosc);
  if (jakosc != null && qualityIsBad(jakosc.wartosc)) wynik.doWymiany = true;
  final stan = cecha(pStan);
  if (stan != null) {
    if (wszystkieJezyki((l) => l.virgine).contains(stan.wartosc) || stan.wartosc == 'virgin') {
      wynik.stan = 'nieunasienniona';
    } else if (czyMatkaTrutowa(stan.wartosc)) {
      wynik.stan = 'trutowa';
    }
  }

  //znak matki: najnowszy wpis tej matki, a bez niego - wpisy z ostatniej daty o znaku
  Info? znak;
  for (final inf in wpisy) {
    if (inf.kategoria == 'queen' && pZnak.contains(inf.parametr) &&
        inf.wartosc.isNotEmpty && tejMatki(inf) && wpisZnakuNowszy(inf, znak)) znak = inf;
  }
  if (znak == null) {
    for (final inf in wpisy) {
      if (inf.kategoria == 'queen' && pZnak.contains(inf.parametr)) {
        znak = inf;
        break;
      }
    }
  }
  if (znak != null && const {'nie ma', 'gone', 'brak', 'missing'}.contains(markToKey(znak.wartosc))) {
    wynik.brak = true;
    wynik.doWymiany = false;
    wynik.stan = '';
  }
  if (gdzieIndziej && !wynik.brak) {
    wynik.doWymiany = false;
    wynik.stan = '';
  }
  if (wynik.brak) wynik.uwagi.add(znak!.uwagi);
  if (wynik.doWymiany) wynik.uwagi.add(jakosc!.uwagi);
  if (wynik.stan.isNotEmpty) wynik.uwagi.add(stan!.uwagi);
  return wynik;
}

/// Dane do [panelUliDoZrobienia] - liczone bez kontekstu (async), panel buduje się potem.
class PodsumowaniePasieki {
  final int pasieka;
  final List<Hive> ule;
  final Map<int, RamkiProblemuUla> ramki;
  final Map<int, StanMatkiUla> matki;
  final Map<int, List<String>> uwagi; //ul -> notatki z wpisów o jego problemach
  PodsumowaniePasieki(this.pasieka, this.ule, this.ramki, this.matki, this.uwagi);
}

Future<PodsumowaniePasieki> podsumowaniePasieki(int pasieka) async {
  final dostawca = Hives();
  await dostawca.fetchAndSetHives(pasieka); //z stanRodziny; lokalny obiekt - provider aplikacji bez zmian
  final ule = dostawca.items.where((h) => h.ikona != 'black').toList(); //zlikwidowane pomijamy
  final ramki = await ramkiProblemowPasieki(pasieka);
  final pStanuRodziny = wszystkieJezyki((l) => l.colony + " " + l.isIs);
  final problemyRodziny = {for (final (wartosci, _) in _stanyRodziny()) ...wartosci};
  final matki = <int, StanMatkiUla>{};
  final uwagi = <int, List<String>>{};
  for (final h in ule) {
    final wpisy = (await DBHelper.getInfosOfHive(pasieka, h.ulNr)).map((m) => Info.fromMap(m)).toList();
    final m = await stanMatkiUla(pasieka, h.ulNr, wpisyUla: wpisy);
    matki[h.ulNr] = m;
    //NOTATKI przy problemach (28.10.2026): uwagi wpisów, które dały problem - matka (znak,
    //jakość, stan), rodzina (najnowszy wpis o stanie), ramki (przegląd z dnia mateczników/zadań)
    final lista = <String>[...m.uwagi];
    if (problemyRodziny.contains(h.stanRodziny.trim())) {
      Info? najnowszy;
      for (final inf in wpisy) {
        if (pStanuRodziny.contains(inf.parametr) &&
            (najnowszy == null ||
                momentWpisu(inf.data, inf.czas).isAfter(momentWpisu(najnowszy.data, najnowszy.czas)))) {
          najnowszy = inf;
        }
      }
      if (najnowszy != null) lista.add(najnowszy.uwagi);
    }
    final r = ramki[h.ulNr];
    if (r != null && (r.otwarte > 0 || r.zadania.isNotEmpty)) {
      for (final inf in wpisy) {
        if (inf.kategoria == 'inspection' && r.daty.contains(inf.data)) lista.add(inf.uwagi);
      }
    }
    //bez pustych i powtórzeń (ta sama notatka bywa w kilku wpisach jednego przeglądu)
    final czyste = <String>[];
    for (final u in lista) {
      final t = u.trim();
      if (t.isNotEmpty && !czyste.contains(t)) czyste.add(t);
    }
    if (czyste.isNotEmpty) uwagi[h.ulNr] = czyste;
  }
  return PodsumowaniePasieki(pasieka, ule, ramki, matki, uwagi);
}

//pilność koloru: im mniej, tym wcześniej na liście
const Map<String, int> _pilnosc = {'red': 0, 'dead': 1, 'orange': 2, 'yellow': 3};

/// Lista uli z problemami, najpilniejsze na górze: kolor (czerwony, martwa rodzina,
/// pomarańczowy, żółty), potem liczba problemów, potem numer ula.
Widget panelUliDoZrobienia(BuildContext context, PodsumowaniePasieki d) {
  final l = AppLocalizations.of(context)!;
  final stanyRodziny = _stanyRodziny();
  final wiersze = <(int, String, List<String>)>[]; //ul, najgorszy kolor, problemy

  for (final h in d.ule) {
    final problemy = <(String, String)>[]; //kolor, opis
    final m = d.matki[h.ulNr];
    if (m != null) {
      if (m.brak) problemy.add(('red', '${l.qUeen}: ${l.missing}'));
      if (m.stan == 'trutowa') problemy.add(('red', '${l.qUeen}: ${l.droneLaying}'));
      if (m.doWymiany) problemy.add(('orange', '${l.qUeen}: ${l.canceled}'));
      if (m.stan == 'nieunasienniona') problemy.add(('orange', '${l.qUeen}: ${l.virgine1}'));
    }
    for (final (wartosci, etykieta) in stanyRodziny) {
      if (!wartosci.contains(h.stanRodziny.trim())) continue;
      final String kolor = switch (ocenaStanuRodziny(h.stanRodziny)) {
        OcenaRodziny.martwa => 'dead',
        OcenaRodziny.zla => 'red',
        _ => 'orange',
      };
      problemy.add((kolor, '${l.cOlony}: ${etykieta(l)}'));
    }
    final r = d.ramki[h.ulNr];
    if (r != null) {
      if (r.otwarte > 0) problemy.add(('orange', '${l.queenCellsCount} ${r.otwarte}'));
      final zadania = r.zadania.keys.toList()
        ..sort((a, b) => kolejnoscZadaniaRamki(a).compareTo(kolejnoscZadaniaRamki(b)));
      final policzone = <String, int>{}; //ten sam napis z różnych języków sumowany
      for (final z in zadania) {
        final nazwa = zadanieRamkiWBiezacym(context, z);
        policzone[nazwa] = (policzone[nazwa] ?? 0) + r.zadania[z]!.length;
      }
      for (final e in policzone.entries) {
        problemy.add(('yellow', '${e.key} (${e.value})'));
      }
    }
    if (problemy.isEmpty) continue;
    final najgorszy = problemy
        .map((p) => p.$1)
        .reduce((a, b) => _pilnosc[a]! <= _pilnosc[b]! ? a : b);
    wiersze.add((h.ulNr, najgorszy, problemy.map((p) => p.$2).toList()));
  }
  wiersze.sort((a, b) {
    final k = _pilnosc[a.$2]!.compareTo(_pilnosc[b.$2]!);
    if (k != 0) return k;
    final n = b.$3.length.compareTo(a.$3.length);
    return n != 0 ? n : a.$1.compareTo(b.$1);
  });

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        wiersze.isEmpty
            ? '${l.aPiary} ${d.pasieka}: ${l.noHivesWithProblems}'
            : '${l.aPiary} ${d.pasieka} – ${l.hivesWithProblems}: ${wiersze.length}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      for (final (ul, kolor, problemy) in wiersze)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hive, size: 28, color: kolorIkonyUla(kolor)),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text('${l.hIve} $ul',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              //problemy i notatki W JEDNEJ LINII (w poziomie mieści się mało uli),
              //notatki pogrubione i ciemne - czytelne w słońcu (prośba usera 28.10.2026)
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
                    children: [
                      TextSpan(text: problemy.join(' · ')),
                      for (final u in d.uwagi[ul] ?? const <String>[])
                        TextSpan(
                            text: ' · „$u”',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
