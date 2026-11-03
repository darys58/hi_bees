import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heymaya/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../globals.dart' as globals;
import '../models/apiarys.dart';
import '../models/hives.dart';
import '../models/infos.dart';
import '../models/queen.dart';
import 'db_helper.dart';
import 'colony_helpers.dart'; //kolor ikony ula ze stanem rodziny
import 'queen_helpers.dart';

//Wydzielone 30.10.2026 z queen_item.dart - to samo robi odłączenie matki od ula
//(queen_item) i ustawienie daty straty matki podłączonej do ula (queen_edit_screen).
//Wołać, ZANIM matka zniknie z ula w bazie (pasieka/ul = 0 albo data straty):
//idMatekUla liczy matki przed zmianą, żeby wiedzieć, czy w ulu zostaje inna.

//Odłączenie matki od ula (11.10.2026): wpis "matka brak" w ulu, z którego matka
//wychodzi (pogoda = ID matki, więc widać go też w historii matki), i belka ula
//jak przy ręcznym wpisie "brak" w infos_edit_screen: matka2 = 'brak', pozostałe
//cechy puste, ikona czerwona. Id z przyrostkiem [kIdOdlaczeniaMatki], żeby
//podłączenie nowej matki tego samego dnia nie nadpisało tego wpisu.
//[wpis] false - usuwanie matki zarejestrowanej przez pomyłkę (15.10.2026): belka
//ula jak przy odłączeniu, ale BEZ wpisu "matka brak" w historii
Future<void> zapiszOdlaczenieMatki(BuildContext context, Queen matki,
    {bool wpis = true, String? data}) async {
  final loc = AppLocalizations.of(context)!;
  final int pasieka = matki.pasieka;
  final int ul = matki.ul;
  //[data] - dzień wpisu "brak"; przy stracie matki = data straty (30.10.2026)
  final String dzien = data ?? DateTime.now().toString().substring(0, 10);
  //KILKA MATEK W ULU (12.10.2026): czy po odłączeniu zostaje inna matka? Matka
  //odłączana jest jeszcze w tabeli z tym ulem (pasieka/ul zerujemy po tej metodzie).
  final List<int> matkiPrzed = await idMatekUla(pasieka, ul);
  final List<int> pozostale = matkiPrzed.where((id) => id != matki.id).toList();
  //wpis "brak" z ID TEJ matki zostaje zawsze - jest jej historią; cechy innych
  //matek liczą się po ich ID, więc ten wpis ich nie rusza
  if (wpis) await Infos.insertInfo(
    //.m<ID> - dwie matki odłączone tego samego dnia z jednego ula (12.10.2026)
    '$dzien.$pasieka.$ul.queen. ' + loc.queen + '.m${matki.id}' + kIdOdlaczeniaMatki,
    dzien,
    pasieka,
    ul,
    'queen',
    " " + loc.queen, //parametr jak wpis o znaku
    loc.missing, //"brak"
    '',
    matki.id.toString(), //pogoda - matkaID
    globals.tempNaWpis(globals.aktualTemp, globals.stopnie),
    DateFormat('H:mm').format(DateTime.now()),
    '',
    0,
  );
  final String idUla = '$pasieka.$ul';
  await wczytajDodatkoweMatki(pomin: matki.id); //ikony matek niegłównych na belce
  if (pozostale.isNotEmpty) {
    //w ulu zostaje matka - belka bez "brak" i bez czerwonej ikony. Gdy odłączana
    //była GŁÓWNĄ, belka dostaje znak nowej głównej; resztę cech dolicza
    //odświeżenie belek (ikona oka), bo liczą się z wpisów
    if (matkiPrzed.isNotEmpty && matkiPrzed.first == matki.id) {
      final nowa = await DBHelper.getZyweMatkiUla(pasieka, ul);
      final glowna = nowa.where((m) => m['id'] == pozostale.first).toList();
      await DBHelper.updateUleMatka1(idUla, '');
      await DBHelper.updateUleMatka2(idUla, glowna.isEmpty ? ''
          : belkaZnakuMatki('${glowna[0]['znak'] ?? ''}', '${glowna[0]['napis'] ?? ''}'));
      await DBHelper.updateUleMatka3(idUla, '');
      await DBHelper.updateUleMatka4(idUla, '');
      await DBHelper.updateUleMatka5(idUla, '');
    }
  } else {
    await DBHelper.updateUleMatka1(idUla, '');
    await DBHelper.updateUleMatka2(idUla, 'brak');
    await DBHelper.updateUleMatka3(idUla, '');
    await DBHelper.updateUleMatka4(idUla, '');
    await DBHelper.updateUleMatka5(idUla, '');
    await DBHelper.updateUle(idUla, 'ikona', 'red');
  }
  //ikona pasieki z ikon jej uli - tak samo jak przy podłączaniu
  final ule = await DBHelper.getHives(pasieka);
  final stany = await stanyRodzinUli(pasieka); //stan rodziny też barwi ikonę
  final String ikonaPasieki = ikonaPasiekiZUli(ule.map((u) =>
      ikonaNaBelce((u['ikona'] as String?) ?? '', stany[u['id']] ?? '',
          matka3: (u['matka3'] as String?) ?? '',
          todo: (u['todo'] as String?) ?? '',
          mateczniki: (u['mateczniki'] as int?) ?? 0,
          usunmat: (u['usunmat'] as int?) ?? 0)));
  await DBHelper.updateIkonaPasieki(pasieka, ikonaPasieki);
  if (pasieka == globals.pasiekaID) globals.ikonaPasieki = ikonaPasieki;
  if (!context.mounted) return;
  await Provider.of<Apiarys>(context, listen: false).fetchAndSetApiarys();
  if (!context.mounted) return;
  if (pasieka == globals.pasiekaID) {
    await Provider.of<Hives>(context, listen: false).fetchAndSetHives(pasieka);
    if (!context.mounted) return;
    if (ul == globals.ulID) {
      await Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(pasieka, ul);
    }
  }
}
