import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heymaya/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
// import '../models/infos.dart';
// import '../models/hives.dart';
import '../models/apiarys.dart';
// import '../models/info.dart';
import '../helpers/db_helper.dart';
import '../helpers/colony_helpers.dart'; //kolor ikony ula ze stanem rodziny
import '../screens/queen_edit_screen.dart';
import '../screens/queen_history_screen.dart';
//import '../screens/infos_screen.dart';
import '../globals.dart' as globals;
//import '../models/frames.dart';
import '../models/queen.dart';
import '../helpers/queen_helpers.dart';
import '../models/hives.dart';
import '../models/hive.dart';
import '../models/infos.dart';
import '../helpers/prawa_zespolu.dart'; //blokady w bazie właściciela (etap 2 część B)

class QueenItem extends StatefulWidget {
  @override
  State<QueenItem> createState() => _QueenItemState();
}

class _QueenItemState extends State<QueenItem> {
  //final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //int rozmiarRamki = 0;
  var formatterHm = new DateFormat('H:mm');
  String nowaData = '0';
  String nowuNrPasieki = '0';
  List<Hive> hive = [];
  String? nazwaZbioru;
  String? miara;
  TextEditingController dateController = TextEditingController();


  //Odłączenie matki od ula (11.10.2026): wpis "matka brak" w ulu, z którego matka
  //wychodzi (pogoda = ID matki, więc widać go też w historii matki), i belka ula
  //jak przy ręcznym wpisie "brak" w infos_edit_screen: matka2 = 'brak', pozostałe
  //cechy puste, ikona czerwona. Id z przyrostkiem [kIdOdlaczeniaMatki], żeby
  //podłączenie nowej matki tego samego dnia nie nadpisało tego wpisu.
  //[wpis] false - usuwanie matki zarejestrowanej przez pomyłkę (15.10.2026): belka
  //ula jak przy odłączeniu, ale BEZ wpisu "matka brak" w historii
  Future<void> _zapiszOdlaczenie(BuildContext context, Queen matki, {bool wpis = true}) async {
    final loc = AppLocalizations.of(context)!;
    final int pasieka = matki.pasieka;
    final int ul = matki.ul;
    final String data = DateTime.now().toString().substring(0, 10);
    //KILKA MATEK W ULU (12.10.2026): czy po odłączeniu zostaje inna matka? Matka
    //odłączana jest jeszcze w tabeli z tym ulem (pasieka/ul zerujemy po tej metodzie).
    final List<int> matkiPrzed = await idMatekUla(pasieka, ul);
    final List<int> pozostale = matkiPrzed.where((id) => id != matki.id).toList();
    //wpis "brak" z ID TEJ matki zostaje zawsze - jest jej historią; cechy innych
    //matek liczą się po ich ID, więc ten wpis ich nie rusza
    if (wpis) await Infos.insertInfo(
      //.m<ID> - dwie matki odłączone tego samego dnia z jednego ula (12.10.2026)
      '$data.$pasieka.$ul.queen. ' + loc.queen + '.m${matki.id}' + kIdOdlaczeniaMatki,
      data,
      pasieka,
      ul,
      'queen',
      " " + loc.queen, //parametr jak wpis o znaku
      loc.missing, //"brak"
      '',
      matki.id.toString(), //pogoda - matkaID
      globals.tempNaWpis(globals.aktualTemp, globals.stopnie),
      formatterHm.format(DateTime.now()),
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

  //Matka BEZ HISTORII (15.10.2026) - jej jedyne wpisy to podłączenie/odłączenie od
  //ula (id z przyrostkiem .connect/.disconnect). Tylko taką da się usunąć: chodzi
  //o matkę zarejestrowaną przez pomyłkę albo testowo. Podłączenia sprzed 11.10.2026
  //nie mają przyrostka - taka matka liczy się jako "z historią" (bezpieczniej).
  Future<List<String>?> _wpisyMatkiBezHistorii(Queen matki) async {
    final wpisy = await DBHelper.getInfosOfQueen(matki.id.toString());
    final ids = wpisy.map((w) => '${w['id']}').toList();
    final bool bezHistorii = ids.every((id) =>
        id.endsWith(kIdPodlaczeniaMatki) || id.endsWith(kIdOdlaczeniaMatki));
    return bezHistorii ? ids : null;
  }

  Future<void> _usunMatke(BuildContext context, Queen matki) async {
    final loc = AppLocalizations.of(context)!;
    final ids = await _wpisyMatkiBezHistorii(matki);
    if (!context.mounted) return;
    if (ids == null) {
      //matka z historią - odmowa (oznaczyć jako utraconą)
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(loc.queenDeleteRefused),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    final bool? usun = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(loc.queenDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(loc.queenDelete)),
        ],
      ),
    );
    if (usun != true || !context.mounted) return;
    //wpisy podłączenia to historia ula - prawo do info
    if (ids.isNotEmpty && !mogeZapisac(context, [czInfo], pasieka: matki.pasieka)) return;
    //matka w ulu - belka jak po odłączeniu (bez wpisu "brak"), zanim zniknie z tabeli
    if (matkaZyje(matki.dataStraty) && matki.ul != 0) {
      await _zapiszOdlaczenie(context, matki, wpis: false);
    }
    for (final id in ids) {
      await DBHelper.deleteInfo(id);
    }
    await DBHelper.deleteQueen(matki.id);
    if (!context.mounted) return;
    await Provider.of<Queens>(context, listen: false).fetchAndSetQueens();
    if (!context.mounted) return;
    if (matki.pasieka == globals.pasiekaID && matki.ul == globals.ulID && matki.ul != 0) {
      await Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(matki.pasieka, matki.ul);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matki = Provider.of<Queen>(context, listen: false);
    dateController.text = DateTime.now().toString().substring(0, 10); //globals.dataWpisu; //ostatnio wybrana data 
    // List<Color> color = [
    //   const Color.fromARGB(255, 252, 193, 104),
    //   const Color.fromARGB(255, 255, 114, 104),
    //   const Color.fromARGB(255, 104, 187, 254),
    //   const Color.fromARGB(255, 83, 215, 88),
    //   const Color.fromARGB(255, 203, 174, 85),
    //   const Color.fromARGB(255, 253, 182, 76),
    //   const Color.fromARGB(255, 255, 86, 74),
    //   const Color.fromARGB(255, 71, 170, 251),
    //   Color.fromARGB(255, 61, 214, 66),
    //   Color.fromARGB(255, 210, 170, 49),
    // ];
    // switch (notatki.status) {
    //   case 1:
    //     nazwaZbioru = AppLocalizations.of(context)!.honey;
    //     break;
    //   case 2:
    //     nazwaZbioru = AppLocalizations.of(context)!.beePollen;
    //     break;
    //   case 3:
    //     nazwaZbioru = AppLocalizations.of(context)!.perga;
    //     break;
    //   case 4:
    //     nazwaZbioru = AppLocalizations.of(context)!.wax;
    //     break;
    //   case 5:
    //     nazwaZbioru = 'propolis';
    //     break;
    // }

    // switch (notatki.priorytet) {
    //   case 1:
    //     miara = 'l';
    //     break;
    //   case 2:
    //     miara = 'kg';
    //     break;
    // }

    return  Dismissible(
      ///usuwalny element listy
      key: ValueKey(matki.id),
      background: Container(
        color: Colors.blue,
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              
              Icon(
                Icons.history,
                color: Colors.white,
                size: 40,
              ),
              SizedBox(width:20),
              if(matki.dataStraty == '' && matki.ul != 0)
                Icon(
                  Icons.highlight_off,
                  color: Colors.white,
                  size: 40,
                ),
              SizedBox(width:20),
              Icon(
                Icons.edit,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (DismissDirection direction) async {
        //etap 2 część B: bez prawa edycji zostaje tylko Historia, w treści - powód
        final String? blokadaMatki = powodBlokady(AppLocalizations.of(context)!, [czMatki], edycja: true, wyslany: matki.arch != 0);
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.wHatDoYouWant),
              content: blokadaMatki != null
                        ? Text(blokadaMatki)
                        : matki.dataStraty == '' && matki.ul != 0
                        ? Text(AppLocalizations.of(context)!.dIsconnectOrEdit)
                        : Text(AppLocalizations.of(context)!.eDitQueen),
              
              actions: [
                //Historia
                TextButton(
                  onPressed: () => {Navigator.of(context).pop(false),
                    Navigator.of(context).pushNamed(
                      QueenHistoryScreen.routeName,
                      arguments: {'queenId': matki.id},
                    ),
                  },
                  child: Text(AppLocalizations.of(context)!.queenHistory),
                ),
                //Odłacz matkę - jezeli matka zyje
                if(matki.dataStraty == '' && matki.ul != 0 && blokadaMatki == null)
                  TextButton(
                    onPressed: () async {
                      //potwierdzenie (11.10.2026) - "Odłącz" stoi obok "Historia",
                      //łatwo trafić w nie przypadkiem
                      final bool? odlacz = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext ctx) => AlertDialog(
                          content: Text(AppLocalizations.of(ctx)!.dIsconnectQueenConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(AppLocalizations.of(ctx)!.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text(AppLocalizations.of(ctx)!.dIsconnectQueen),
                            ),
                          ],
                        ),
                      );
                      if (odlacz != true) return;
                      //odłączenie dopisuje do historii ula "matka brak" (11.10.2026) - prawo do info
                      if (!mogeZapisac(context, [czInfo], pasieka: matki.pasieka)) return;
                      await _zapiszOdlaczenie(context, matki);
                      DBHelper.updateQueen(matki.id, 'pasieka', 0).then((_) {
                        DBHelper.updateQueen(matki.id, 'ul', 0).then((_) {
                          DBHelper.updateQueen(matki.id, 'arch', 0);
                          
                          //DBHelper.upgradeQueen(matki.id).then((_) {
                          //print('3... usuwanie matki z ula - pasieka=0, ul=0');

                          Navigator.of(context).pop(true); //skasowanie elementu listy
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   const SnackBar(
                          //     content: Text("The item has been deleted"),
                          //   ),
                          // );
                          Provider.of<Queens>(context, listen: false)
                              .fetchAndSetQueens()
                              .then((_) {
                                Navigator.of(context).pop(false);
                            //print('4... aktualizacja zbiorow w note_item');
                          });
                       
                        });
                      });
                    },
                    child: Text(AppLocalizations.of(context)!.dIsconnectQueen), //Odłacz matkę
                  ),
                
                //Edytuj
                if (blokadaMatki == null)
                TextButton(
                  onPressed: () => {Navigator.of(context).pop(false),
                    Navigator.of(context).pushNamed(
                      QueenEditScreen.routeName,
                      arguments: {'idQueen': matki.id},
                    ),
                  },
                  child: Text(AppLocalizations.of(context)!.eDit), //Edytuj matkę
                ),
                //Usuń - tylko matka bez historii (błędna/testowa rejestracja),
                //z historią - komunikat o odmowie (15.10.2026)
                if (blokadaMatki == null)
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(false);
                    //this.context - kontekst elementu listy; "context" tutaj to
                    //zamknięte właśnie okno dialogowe
                    await _usunMatke(this.context, matki);
                  },
                  child: Text(AppLocalizations.of(context)!.queenDelete),
                ),
                //Anuluj
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context)!.cancel), // Anuluj
                ),
                
                

              ],
            );
          },
        );
      },
      child: Card(
         shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
        color:  Colors.white,
        margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 4,
        ),
        child: Padding(
            padding: const EdgeInsets.all(1),
            child: ListTile(
              tileColor: matki.dataStraty != ''  
                ? const Color.fromARGB(255, 244, 208, 208) //matka stracona
                : matki.ul == globals.ulID && matki.pasieka == globals.pasiekaID && globals.ulID != 0 && matki.dataStraty.isEmpty
                  ? const Color.fromARGB(255, 205, 250, 207) //matka w biezącym ulu
                  : matki.ul > 0 && matki.dataStraty.isEmpty
                    ? Colors.grey[200] //matka w innym ulu
                    : Colors.white, 
              onTap: () {
                //_showAlert(context, 'Edycja', '${frame.id}');
                // globals.dataInspekcji = frame.data;
                // Navigator.of(context).pushNamed(
                //   QueenEditScreen.routeName,
                //   arguments: {'idQueen': matki.id},
                // );
                //jezeli matka jest stracona to nie mozna jej dołączyć do ula
                //musi nie mieć dataStraty i nie być podłaczona do innego ula
                if(matki.dataStraty == '' && matki.ul == 0 && globals.ulID != 0){
                  //etap 2 część B: podłączenie zmienia matkę i dopisuje wpis do historii ula (info)
                  if (!mogeZapisac(context, [czMatki], edycja: true, wyslany: matki.arch != 0) ||
                      !mogeZapisac(context, [czInfo], pasieka: globals.pasiekaID)) return;
                  //KILKA MATEK W ULU (12.10.2026): do kMaxMatekWUlu żyjących matek
                  final int ileWUlu = Provider.of<Queens>(context, listen: false).items
                      .where((q) => q.pasieka == globals.pasiekaID &&
                          q.ul == globals.ulID && matkaZyje(q.dataStraty))
                      .length;
                  if (ileWUlu >= kMaxMatekWUlu) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .queenHiveFull(kMaxMatekWUlu.toString())),
                    ));
                    return;
                  }
                  DBHelper.updateQueen(matki.id, 'pasieka', globals.pasiekaID);
                  DBHelper.updateQueen(matki.id, 'ul', globals.ulID);
                  DBHelper.updateQueen(matki.id, 'arch', 0);
                  Infos.insertInfo(
                    //".connect" na końcu id = wpis z chwili podłączenia matki do ula
                    //(11.10.2026) - historia matki rysuje przy nim ikonkę. Id nie jest
                    //nigdzie rozbierane; osobne id = przegląd z tego dnia go nie nadpisze.
                    //.m<ID> - dwie matki podłączone tego samego dnia do jednego ula (12.10.2026)
                    '${dateController.text}.${globals.pasiekaID}.${globals.ulID}.queen. ' + AppLocalizations.of(context)!.queen + '.m${matki.id}' + kIdPodlaczeniaMatki,
                    dateController.text,
                    globals.pasiekaID,
                    globals.ulID,
                    'queen',
                    " " + AppLocalizations.of(context)!.queen, //oznaczenie matki
                    //info.wartosc dla kategorii "queen" to TEKST W BIEŻĄCYM
                    //JĘZYKU - infos_screen porównuje go z loc.markedWhite itd.,
                    //a info_item wyświetla wprost. matki.znak bywa tymczasem
                    //KLUCZEM ("mark_white"), bo tak zapisuje queen_edit_screen;
                    //wpisywany tu na surowo pokazywał się na przeglądzie jako
                    //"mark_white" i nie dawał ikonki (zgłoszone 06.09.2026).
                    znakMatkiNaEkran(matki.znak, AppLocalizations.of(context)!),
                    matki.napis,
                    matki.id.toString(), //pogoda - tu matkaID
                    globals.tempNaWpis(globals.aktualTemp, globals.stopnie),
                    formatterHm.format(DateTime.now()),
                    matki.uwagi,
                    0, //info[0].arch,
                  ).then((_) {
                    //belka ula pokazuje matkę GŁÓWNĄ (najwcześniej podłączoną) - nowa
                    //matka jest nią tylko w ulu bez innej żyjącej matki
                    final String idUla = '${globals.pasiekaID}.${globals.ulID}';
                    final Future<void> belka = ileWUlu == 0
                        ? DBHelper.updateUleMatka2(idUla, belkaZnakuMatki(matki.znak, matki.napis))
                            .then((_) => DBHelper.updateUle(idUla, 'ikona', 'green'))
                        : Future<void>.value();
                    belka.then((_) {
                      wczytajDodatkoweMatki().then((_) { //ikony matek niegłównych na belce
                        //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
                        Provider.of<Hives>(context, listen: false).fetchAndSetHives(globals.pasiekaID)
                          .then((_) {
                            final hivesData = Provider.of<Hives>(context,listen: false);
                            final hives = hivesData.items;
                            int ileUli = hives.length;

                        //ustawienie ikony dla pasieki
                            //najgorsza ikona uli, z uwzględnieniem stanu rodziny (colony_helpers)
                            globals.ikonaPasieki = ikonaPasiekiZUli(hives.map((h) => ikonaNaBelce(h.ikona, h.stanRodziny, matka3: h.matka3,
        todo: h.todo, mateczniki: h.mateczniki, usunmat: h.usunmat)));
                            for (var i = 0; i < hives.length; i++) {
                              //print('i=$i');
                              //print( 'hives[i].ikona = ${hives[i].ikona}');
                                  //print('============== globals.ikonaPasieki ===== ${globals.ikonaPasieki}');
                                  // print(
                                  //     '${hives[i].id},${hives[i].pasiekaNr},${hives[i].ulNr},${hives[i].przeglad},${hives[i].ikona},${hives[i].ramek}');
                                  // print('*****');
                            }
                            //ilość uli zlikwidowanych  - do obliczenia nilości uli w pasiece
                            final hiveZlikwidowane = hivesData.items.where((element) {
                                    return element.ikona == ('black');
                                  });                     
                            //zapis do tabeli "pasieki"
                            Apiarys.insertApiary(
                              '${globals.pasiekaID}',
                              globals.pasiekaID, //pasieka nr
                              ileUli - hiveZlikwidowane.length, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
                              dateController.text, //przeglad
                              globals.ikonaPasieki, //ikona
                              '??', //opis
                            ).then((_) {
                              Provider.of<Apiarys>(context,listen: false).fetchAndSetApiarys()
                                .then((_) {

                                  Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(globals.pasiekaID, globals.ulID)
                                    .then((_) {
                                      Provider.of<Queens>(context, listen: false).fetchAndSetQueens()
                                        .then((_) {
                                          Navigator.of(context).pop();
                                        }); 
                                    
                                    });
                                            // print(
                                            //     'edit_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy');
                                  });
                                });
                              });
                            });
                          });                              
                  });
              };
              //Navigator.of(context).pop();
              // Navigator.of(context).pushNamed(
              //     InfoScreen.routeName,
              //     arguments: matki.ul,
              //     //arguments: {'idQueen': matki.id},
              //   );
              },
              leading: Container(
                height:70,
                //alignment: Alignment.center,
                child: 
                    Text('ID\n${matki.id}',
                      style: const TextStyle(color: Colors.black, fontSize: 18)),
                
               ),
              // globals.jezyk == 'pl_PL'
              //   ?  Text("${matki.data.substring(8)}.${matki.data.substring(5, 7)}  ${matki.rasa}", 
              //     style: const TextStyle(fontSize: 16))
              //   : Text("${matki.data.substring(5, 7)}-${matki.data.substring(8)}  ${matki.rasa}", 
              //     style: const TextStyle(fontSize: 16)),
            
              title: RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                    TextSpan(
                      text: ('${matki.linia} '),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                    TextSpan(
                      text: breedToDisplay(breedToKey(matki.rasa), AppLocalizations.of(context)!),
                      style: TextStyle(
                          fontSize: 14,
                          //fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0)),
                      ),

                    ])),
              subtitle: Column(
                children: [
                  Row(
                    children: [
//znak?
                      ...markToIcon(markToKey(matki.znak)),


//numer opalitka                      
  
                        if(matki.napis != '' && matki.napis != '0') 
                          Text(
                          ' ${matki.napis}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color.fromARGB(255, 69, 69, 69),
                          )),
                        // if(hive.matka2 != '' && hive.matka2 != '0')
                        //   SizedBox(width: 5),
//pasieka                  
                        if(matki.pasieka != 0) 
                          RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              TextSpan(
                                text: (' ' + AppLocalizations.of(context)!.aPiary + ': '), 
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
//numer pasieki czarny - matka zyje                             
                              matki.dataStraty == ''
                                ? TextSpan(
                                  text: ('${matki.pasieka}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  )
//numer pasieki siwy - strata matki
                                : TextSpan(
                                    text: ('${matki.pasieka}'),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey),
                                    ),
                              ])),
                          // Text('  ' + AppLocalizations.of(context)!.aPiary +
                          // ': ${matki.pasieka},',
                          // style: const TextStyle(
                          //  // fontWeight: FontWeight.bold,
                          //   fontSize: 13,
                          //   color: Color.fromARGB(255, 69, 69, 69),
                          // )),
                        if(matki.pasieka == 0) 
                          Text('  ' + AppLocalizations.of(context)!.aPiary +
                          ': ' + AppLocalizations.of(context)!.lack,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 69, 69, 69),
                          )),
   //ul                 
                        if(matki.ul != 0) 
                          RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              TextSpan(
                                text: (' ' + AppLocalizations.of(context)!.hIve + ': '), 
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
 //numer ula czarny = matka zyje                             
                              matki.dataStraty == ''
                                ? TextSpan(
                                    text: ('${matki.ul}'),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 0, 0, 0)),
                                    )
//numer ula szary - strata matki                                   
                                    : TextSpan(
                                      text: ('${matki.ul}'),
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey),
                                      ),
                              
                              ])),
                        //   Text('  ' + AppLocalizations.of(context)!.hIve +
                        //   ': ${matki.ul},',
                        //   style: const TextStyle(
                        //    // fontWeight: FontWeight.bold,
                        //     fontSize: 13,
                        //     color: Color.fromARGB(255, 69, 69, 69),
                        //   )),
                        if(matki.ul == 0) 
                          Text('  ' + AppLocalizations.of(context)!.hIve +
                          ': ' + AppLocalizations.of(context)!.lack,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 69, 69, 69),
                          )),
                   ],
                  ),
                    
                  Row(children: [
//zrodlo                  
                    if(matki.zrodlo != '' && matki.zrodlo  != '0')
                      Text(sourceToDisplay(sourceToKey(matki.zrodlo), AppLocalizations.of(context)!),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color.fromARGB(255, 0, 0, 0),
                      )),
//rok pozyskania                  

                    if(matki.data != '' && matki.data  != '0')
                      Text(' ${matki.data }',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color.fromARGB(255, 0, 0, 0),
                      )),  
                      
                    ]),

//strata matki                   
                  if(matki.dataStraty != '' && matki.dataStraty  != '0')
                    Row(children: [              
                      Text(AppLocalizations.of(context)!.lOst,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color.fromARGB(255, 0, 0, 0),
                      )),
//data straty                                     
                      Text(' ${matki.dataStraty }',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color.fromARGB(255, 0, 0, 0),
                      )),
                        
                      
                    ]),
 //uwagi         
                if(matki.uwagi != '' && matki.uwagi  != '0')      
                     Row(children: [    
                          Expanded(
                            child: Text('${matki.uwagi }',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 0, 0, 0),
                          )),
                          ),                   
                    ])]),
              
              // RichText(
              //     text: TextSpan(
              //         style: TextStyle(color: Colors.black),
              //         children: [
              //       TextSpan(
              //         text: ('${matki.linia}'),
              //         style: TextStyle(
              //             fontSize: 16,
              //             //fontWeight: FontWeight.bold,
              //             color: Color.fromARGB(255, 0, 0, 0)),
              //       ),
              //       TextSpan(
              //         text: '\n${matki.uwagi}',
              //         style: TextStyle(
              //             fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
              //       )
              //     ])),

              trailing:  
                Column(
                  children: [
                    matki.ul == 0 && globals.ulID != 0 //jezeli jest się w jakimś ulu a nie w Apiary
                      ? Icon(Icons.touch_app, size: 50, color: Colors.green,)
                      : Icon(Icons.swipe_left, size: 45, color: Colors.blue,),
                    // SizedBox(height: 5,),
                    // matki.ul != 0
                    //   ? Icon(Icons.swipe_left, size: 32,)
                    //   : Icon(Icons.swipe_left, size: 19,)
                  ]
                ),
              isThreeLine: true,
              //trailing: const Icon(Icons.arrow_forward_ios)
            )),
      ),
    );
  }
}
