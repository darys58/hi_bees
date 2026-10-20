import 'package:flutter/material.dart';
import 'package:hi_bees/l10n/app_localizations.dart';

import '../models/hive.dart';
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
}

/// ul -> zadania i mateczniki z ramek pasieki [pasieka].
Future<Map<int, RamkiProblemuUla>> ramkiProblemowPasieki(int pasieka) async {
  final wynik = <int, RamkiProblemuUla>{};
  for (final r in await DBHelper.getZadaniaIMatecznikiPasieki(pasieka)) {
    final u = wynik.putIfAbsent(r['ulNr'] as int, () => RamkiProblemuUla());
    final String wartosc = '${r['wartosc'] ?? ''}';
    final int ile = int.tryParse(wartosc.replaceAll('%', '').trim()) ?? 0;
    switch (r['zasob']) {
      case 11:
        u.mateczniki += ile;
        break;
      case 12:
        u.usuniete += ile;
        break;
      case 13:
        if (zadanieDoZrobienia(wartosc)) {
          u.zadania.putIfAbsent(wartosc, () => <String>{}).add('${r['korpusNr']}.${r['ramkaNr']}');
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
