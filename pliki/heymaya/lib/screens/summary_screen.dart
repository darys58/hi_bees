import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heymaya/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
//import '../models/hive.dart';
import '../models/hives.dart';
import '../models/info.dart';
import '../models/infos.dart';
import '../models/queen.dart';
import '../models/photo.dart';
import '../models/dodatki1.dart';
import '../models/harvest.dart';
import '../models/note.dart';
import '../globals.dart' as globals;
import '../helpers/queen_helpers.dart';
import '../helpers/colony_helpers.dart'; //kolor ikony ula ze stanem rodziny
import '../widgets/hives_item.dart';
import '../helpers/parametr_nazwy.dart'; //klucz bazy -> nazwa na ekran
import '../helpers/powierzchnia_ramki.dart'; //dmZWpisu - powierzchnia węzy z wpisu zbioru
import '../helpers/db_helper.dart';
import '../helpers/photo_helper.dart'; //jestFilm - film wśród zdjęć ula
import '../widgets/film_widgets.dart'; //miniatura i odtwarzacz filmu ula

class SummaryScreen extends StatefulWidget {
  static const routeName = '/screen-summary';

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  String _inspectionNote = '';
  Map<String, int> _zadaniaRamek = {}; //zadanie ramki (bieżący język) -> ile ramek, z ostatniego przeglądu każdego korpusu
  List<Queen> _queens = [];
  String _colonyForce = ''; //data ostatniego wpisu siły rodziny
  String _colonyState = ''; //data ostatniego wpisu stanu rodziny
  Icon? _colonyForceIcon; //buźka siły rodziny (colony_helpers)
  Icon? _colonyStateIcon; //ikonka stanu rodziny (colony_helpers)
  String _colonyForceName = ''; //podpis pod ikonką siły (np. "silna")
  String _colonyStateName = ''; //podpis pod ikonką stanu (np. "agresywna")
  Info? _lastFeeding;
  Info? _lastTreatment;
  double _lastHarvestHoneyKg = 0;
  String _lastHarvestHoneyDate = '';
  double _lastHarvestPollenL = 0;
  String _lastHarvestPollenDate = '';
  //sumy roczne (rok ostatniego wpisu) - jak w statystyce dokarmiania "(2026: 12 l)"
  double _yearHarvestHoneyKg = 0;
  double _yearHarvestPollenL = 0;
  double? _yearFeeding; //null - bez sumy (pokarm zabrany/pozostały)
  double? _yearTreatment;
  List<Note> _hiveNotes = [];
  List<Photo> _photos = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, int>;
      final pasiekaNr = args['pasiekaNr']!;
      final ulNr = args['ulNr']!;

      final hivesData = Provider.of<Hives>(context, listen: false);
      final hiveList = hivesData.items.where((h) =>
          h.ulNr == ulNr && h.pasiekaNr == pasiekaNr && h.korpusNr > 0);

      Future<void> loadInfos() async {
        final infosData = Provider.of<Infos>(context, listen: false);
        await infosData.fetchAndSetInfosForHive(pasiekaNr, ulNr);

        // Znajdź hive żeby pobrać datę przeglądu
        final hivesData2 = Provider.of<Hives>(context, listen: false);
        final hiveList2 = hivesData2.items.where((h) =>
            h.ulNr == ulNr && h.pasiekaNr == pasiekaNr);
        if (hiveList2.isNotEmpty) {
          final hive = hiveList2.first;
          // Szukaj notatki z przeglądu (kategoria == 'inspection', ta sama data)
          final inspectionInfos = infosData.items.where((info) =>
              info.kategoria == 'inspection' &&
              info.data == hive.przeglad &&
              info.uwagi.isNotEmpty);
          if (inspectionInfos.isNotEmpty) {
            _inspectionNote = inspectionInfos.first.uwagi;
          }
        }

        // Załaduj matki dla tego ula
        final queensData = Provider.of<Queens>(context, listen: false);
        await queensData.fetchAndSetQueens();
        _queens = queensData.items.where((q) =>
            q.pasieka == pasiekaNr && q.ul == ulNr && q.dataStraty == '').toList();

        // Colony info (siła i stan rodziny) - DATA wpisu, nazwę zastępuje ikonka.
        // Po DOKŁADNYM parametrze: kategoria colony to też osyp ("martwe pszczoły"),
        // który wchodził tu jako stan rodziny i pokazywał liczbę (zgłoszenie 15.10.2026).
        final locR = AppLocalizations.of(context)!;
        final pStan = locR.colony + " " + locR.isIs;
        final pSila = " " + locR.colony + " " + locR.isIs;
        DateTime latestColonyForce = DateTime(2000);
        DateTime latestColonyState = DateTime(2000);
        for (final info in infosData.items) {
          if (info.kategoria != 'colony' || info.wartosc.isEmpty) continue;
          final infoDate = DateTime.parse(info.data);
          final parametr = parametrWBiezacym(context, info.parametr);
          if (parametr == pSila && infoDate.isAfter(latestColonyForce)) {
            latestColonyForce = infoDate;
            _colonyForce = _zmienDateCala(info.data);
            _colonyForceIcon = ikonaSilyRodziny(info.wartosc, size: 24);
            _colonyForceName = wartoscWBiezacym(context, info.wartosc);
          } else if (parametr == pStan && infoDate.isAfter(latestColonyState)) {
            latestColonyState = infoDate;
            _colonyState = _zmienDateCala(info.data);
            _colonyStateIcon = ikonaStanuRodziny(info.wartosc, size: 24);
            _colonyStateName = wartoscWBiezacym(context, info.wartosc, parametr: info.parametr);
          }
        }

        //zapis "zła"/"norma" -> etykiety "agresywna"/"normalna", jak w statystyce rodziny
        if (_colonyStateName == locR.aggressive) _colonyStateName = locR.aggressive1;
        if (_colonyForceName == locR.normal) _colonyForceName = locR.normal1;

        // Last feeding
        DateTime latestFeeding = DateTime(2000);
        for (final info in infosData.items) {
          if (info.kategoria == 'feeding') {
            final infoDate = DateTime.parse(info.data);
            if (infoDate.isAfter(latestFeeding)) {
              latestFeeding = infoDate;
              _lastFeeding = info;
            }
          }
        }

        // Last treatment
        DateTime latestTreatment = DateTime(2000);
        for (final info in infosData.items) {
          if (info.kategoria == 'treatment') {
            final infoDate = DateTime.parse(info.data);
            if (infoDate.isAfter(latestTreatment)) {
              latestTreatment = infoDate;
              _lastTreatment = info;
            }
          }
        }

        //sumy roczne dokarmiania i leczenia - ten sam parametr i miara co ostatni wpis,
        //w roku ostatniego wpisu (pokarm zabrany/pozostały bez sumy, jak w statystyce)
        double? sumaRoczna(Info? ostatni) {
          if (ostatni == null) return null;
          final param = parametrWBiezacym(context, ostatni.parametr);
          if (param == locR.removedFood || param == locR.leftFood) return null;
          final miara = miaraWBiezacym(context, ostatni.miara, parametr: ostatni.parametr);
          final rok = ostatni.data.substring(0, 4);
          double suma = 0;
          for (final info in infosData.items) {
            if (info.kategoria == ostatni.kategoria && info.data.startsWith(rok) &&
                parametrWBiezacym(context, info.parametr) == param &&
                miaraWBiezacym(context, info.miara, parametr: info.parametr) == miara) {
              suma += double.tryParse(info.wartosc.replaceAll(',', '.')) ?? 0;
            }
          }
          return suma;
        }
        _yearFeeding = sumaRoczna(_lastFeeding);
        _yearTreatment = sumaRoczna(_lastTreatment);

        // Last honey/pollen harvest from info records (same formula as chart in infos_screen)
        final loc = AppLocalizations.of(context)!;
        final dod1Data = Provider.of<Dodatki1>(context, listen: false);
        final dod1 = dod1Data.items;
        if (dod1.isNotEmpty) {
          final paramHoneySmall = '${loc.honey} = ${loc.small} ${loc.frame} x';
          final paramHoneyBig = '${loc.honey} = ${loc.big} ${loc.frame} x';
          final paramHoneyKg = '${loc.honey} = ';
          final paramPollenPortion = '${loc.beePollen}  = ${loc.portion} x';
          final paramPollenMiarka = '${loc.beePollen}  = ${loc.miarka} x';
          final paramPollenMl = '${loc.beePollen} = ';
          final paramPollenL = ' ${loc.beePollen} =  ';

          // Find the latest harvest date for honey and for pollen
          String latestHoneyDate = '';
          String latestPollenDate = '';
          for (final info in infosData.items) {
            if (info.kategoria == 'harvest' && info.wartosc.isNotEmpty) {
              if (parametrWBiezacym(context, info.parametr) == paramHoneySmall || parametrWBiezacym(context, info.parametr) == paramHoneyBig || parametrWBiezacym(context, info.parametr) == paramHoneyKg) {
                if (latestHoneyDate.isEmpty || info.data.compareTo(latestHoneyDate) > 0) {
                  latestHoneyDate = info.data;
                }
              } else if (parametrWBiezacym(context, info.parametr) == paramPollenPortion || parametrWBiezacym(context, info.parametr) == paramPollenMiarka ||
                         parametrWBiezacym(context, info.parametr) == paramPollenMl || parametrWBiezacym(context, info.parametr) == paramPollenL) {
                if (latestPollenDate.isEmpty || info.data.compareTo(latestPollenDate) > 0) {
                  latestPollenDate = info.data;
              }
            }
          }
          }

          // Waga 1 dm² miodu dla daty miodobrania - harvest.g z miodobrania +-3 dni, inaczej domyślna
          final defaultWagaDm2 = int.parse(dod1[0].b);
          final harvestsData = Provider.of<Harvests>(context, listen: false);
          int wagaDlaDaty(String data) {
            for (var h in harvestsData.items) {
              if (h.zasobId == 1 && h.pasiekaNr == globals.pasiekaID && h.g.isNotEmpty) {
                DateTime hDt = DateTime.parse(h.data.substring(0, 10));
                DateTime lDt = DateTime.parse(data.substring(0, 10));
                if (hDt.difference(lDt).inDays.abs() <= 3) {
                  return int.tryParse(h.g) ?? defaultWagaDm2;
                }
              }
            }
            return defaultWagaDm2;
          }
          // Miód z wpisu w gramach (small frames + big frames + kg)
          double gramyMiodu(Info info, int wagaDm2) {
            final p = parametrWBiezacym(context, info.parametr);
            if (p == paramHoneySmall) {
              double dm = dmZWpisu(info.pogoda, mala: true) /*pogoda, nie miara - tam zapisuje ją wpis*/;
              return (double.tryParse(info.wartosc) ?? 0) * wagaDm2 * dm / 10000;
            } else if (p == paramHoneyBig) {
              double dm = dmZWpisu(info.pogoda, mala: false) /*pogoda, nie miara - tam zapisuje ją wpis*/;
              return (double.tryParse(info.wartosc) ?? 0) * wagaDm2 * dm / 10000;
            } else if (p == paramHoneyKg) {
              return (double.tryParse(info.wartosc) ?? 0) * 1000;
            }
            return 0;
          }
          // Pyłek z wpisu w ml (miarka/portion + ml + l)
          final mlPerMiarka = int.tryParse(dod1[0].g) ?? 0;
          double mlPylku(Info info) {
            final p = parametrWBiezacym(context, info.parametr);
            if (p == paramPollenPortion || p == paramPollenMiarka) {
              return (double.tryParse(info.wartosc) ?? 0) * mlPerMiarka;
            } else if (p == paramPollenMl) {
              return double.tryParse(info.wartosc) ?? 0;
            } else if (p == paramPollenL) {
              return (double.tryParse(info.wartosc) ?? 0) * 1000;
            }
            return 0;
          }

          // Sum all honey from the latest honey date + w roku tego miodobrania
          if (latestHoneyDate.isNotEmpty) {
            double totalGrams = 0;
            double yearGrams = 0;
            final rok = latestHoneyDate.substring(0, 4);
            final wagi = <String, int>{}; //data miodobrania -> waga dm²
            for (final info in infosData.items) {
              if (info.kategoria == 'harvest' && info.data.startsWith(rok) && info.wartosc.isNotEmpty) {
                final g = gramyMiodu(info, wagi.putIfAbsent(info.data, () => wagaDlaDaty(info.data)));
                yearGrams += g;
                if (info.data == latestHoneyDate) totalGrams += g;
              }
            }
            _lastHarvestHoneyKg = totalGrams / 1000;
            _lastHarvestHoneyDate = latestHoneyDate;
            _yearHarvestHoneyKg = yearGrams / 1000;
          }

          // Sum all pollen from the latest pollen date + w roku tego zbioru
          if (latestPollenDate.isNotEmpty) {
            double totalMl = 0;
            double yearMl = 0;
            final rok = latestPollenDate.substring(0, 4);
            for (final info in infosData.items) {
              if (info.kategoria == 'harvest' && info.data.startsWith(rok) && info.wartosc.isNotEmpty) {
                final ml = mlPylku(info);
                yearMl += ml;
                if (info.data == latestPollenDate) totalMl += ml;
              }
            }
            _lastHarvestPollenL = totalMl / 1000;
            _lastHarvestPollenDate = latestPollenDate;
            _yearHarvestPollenL = yearMl / 1000;
          }
        }

        // Zadania ramek ("Do zrobienia") - z ostatniego przeglądu każdego korpusu (jak belki)
        final ramki = await DBHelper.getFramesOfHive(pasiekaNr, ulNr);
        if (!mounted) return;
        final ostatniaData = <int, String>{}; //korpusNr -> data ostatniego przeglądu
        for (final r in ramki) {
          final korpus = r['korpusNr'] as int;
          final data = r['data'] as String;
          if ((ostatniaData[korpus] ?? '').compareTo(data) < 0) ostatniaData[korpus] = data;
        }
        final zadania = <String, Set<String>>{}; //zadanie -> korpus.ramka (jedna ramka liczona raz, obie strony)
        for (final r in ramki) {
          final zadanie = r['wartosc'] as String;
          if (r['zasob'] == 13 &&
              r['data'] == ostatniaData[r['korpusNr']] &&
              zadanie.isNotEmpty && zadanie != '0') {
            zadania.putIfAbsent(zadanie, () => <String>{}).add('${r['korpusNr']}.${r['ramkaNr']}');
          }
        }
        final kolejne = zadania.keys.toList()
          ..sort((a, b) => kolejnoscZadaniaRamki(a).compareTo(kolejnoscZadaniaRamki(b)));
        _zadaniaRamek = {};
        for (final zadanie in kolejne) { //zadanie z innego języka - w bieżącym; ten sam napis z różnych języków sumowany
          final nazwa = zadanieRamkiWBiezacym(context, zadanie);
          _zadaniaRamek[nazwa] = (_zadaniaRamek[nazwa] ?? 0) + zadania[zadanie]!.length;
        }

        // Photos for this hive
        if (!mounted) return;
        final photosProvider = Provider.of<Photos>(context, listen: false);
        await photosProvider.fetchAndSetPhotosForHive(pasiekaNr, ulNr);
        if (!mounted) return;
        final allPhotos = photosProvider.items;
        final existingPhotos = <Photo>[];
        for (final photo in allPhotos) {
          if (File(photo.sciezka).existsSync()) {
            existingPhotos.add(photo);
          }
        }
        _photos = existingPhotos;

        // Notes for this hive
        if (!mounted) return;
        final notesData = Provider.of<Notes>(context, listen: false);
        await notesData.fetchAndSetNotatki();
        if (!mounted) return;
        _hiveNotes = notesData.items.where((n) =>
            n.pasiekaNr == pasiekaNr && n.ulNr == ulNr).toList();
      }

      if (hiveList.isEmpty) {
        Provider.of<Hives>(context, listen: false)
            .fetchAndSetHives(pasiekaNr)
            .then((_) => loadInfos())
            .then((_) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        loadInfos().then((_) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, int>;
    final ulNr = args['ulNr']!;
    final pasiekaNr = args['pasiekaNr']!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.hiveNews),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hivesData = Provider.of<Hives>(context, listen: false);
    final hiveList = hivesData.items.where((h) =>
        h.ulNr == ulNr && h.pasiekaNr == pasiekaNr);

    if (hiveList.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.hiveNews),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.nOData),
        ),
      );
    }

    final hive = hiveList.first;

    // Wszystkie korpusy dla tego ula (do wyświetlenia belek zasobów)
    final allKorpus = hivesData.items.where((h) =>
        h.ulNr == ulNr && h.pasiekaNr == pasiekaNr && h.korpusNr > 0)
        .toList()
      ..sort((a, b) => a.korpusNr.compareTo(b.korpusNr));

    //obliczanie różnicy między dwoma datami
    int daysBetween(DateTime from, DateTime to) {
      from = DateTime(from.year, from.month, from.day);
      to = DateTime(to.year, to.month, to.day);
      return (to.difference(from).inHours / 24).round();
    }

    final przeglad = DateTime.parse(hive.przeglad);
    final now = DateTime.now();
    final difference = daysBetween(przeglad, now);

    //ikona koloru ula
    Icon hiveIcon = Icon(Icons.hive, size: 30,
        color: kolorIkonyUla(ikonaNaBelce(hive.ikona, hive.stanRodziny, matka3: hive.matka3,
            todo: hive.todo, mateczniki: hive.mateczniki, usunmat: hive.usunmat)));

    // Szerokość belki zasobów
    final double barWidth = MediaQuery.of(context).size.width - 80;

    // Czy sekcja "Przegląd ramek" ma cokolwiek do wyświetlenia
    final bool hasFrameReviewData = allKorpus.isNotEmpty ||
        hive.matka > 0 || hive.mateczniki > 0 || hive.usunmat > 0 ||
        (hive.todo.isNotEmpty && hive.todo != '0') ||
        _zadaniaRamek.isNotEmpty ||
        _inspectionNote.isNotEmpty;

    // "Do zrobienia": wszystkie zadania ramek z liczbą ramek; bez ramek - zadanie z belki
    final String todoTekst = _zadaniaRamek.isNotEmpty
        ? _zadaniaRamek.entries.map((e) => '${e.key} (${e.value})').join(', ')
        : (hive.todo.isNotEmpty && hive.todo != '0')
            ? zadanieRamkiWBiezacym(context, hive.todo)
            : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.hiveNews),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx > 300) {
            Navigator.of(context).pop();
          }
        },
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        children: [
          // --- Segment 1: Połączone info o ulu ---
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wiersz 1: ikona + ul/pasieka + kółko koloru pasieki
                  Row(
                    children: [
                      hiveIcon,
                      const SizedBox(width: 12),
                      Text(
                        '${AppLocalizations.of(context)!.hIve} ${hive.ulNr}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${AppLocalizations.of(context)!.aPiary} ${hive.pasiekaNr}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _apiaryColor(hive.pasiekaNr),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Wiersz 2: typ ula + ilość ramek
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        '${rodzajUlaWBiezacym(context, hive.h1)} ${hive.h2} (${hive.ramek})',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Wiersz 3: dni od przeglądu
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        difference > 365
                            ? '? ${AppLocalizations.of(context)!.sinceLastInspection}'
                            : '$difference ${AppLocalizations.of(context)!.sinceLastInspection}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // if (hasFrameReviewData)
          //   const SizedBox(height: 8),

          // --- Segment 2: Ramki ---
          if (hasFrameReviewData && globals.showSummaryFrames)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tytuł "Przegląd ramek"
                  Row(
                    children: [
                      Image.asset('assets/image/hi_bees.png', width: 22, height: 22, fit: BoxFit.fill),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.frameReview,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Belki zasobów dla wszystkich korpusów
                  for (final korpusHive in allKorpus)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            child: Text('${korpusHive.korpusNr}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              color: const Color.fromARGB(172, 223, 223, 223),
                              child: CustomPaint(
                                painter: MyHiveRow(ul: korpusHive),
                                size: Size(barWidth, 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (allKorpus.isNotEmpty)
                    const SizedBox(height: 4),

                  // Informacje o matce
                  if (hive.matka > 0 || hive.mateczniki > 0 || hive.usunmat > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          if (hive.matka > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, size: 12, color: Color.fromARGB(255, 59, 59, 59)),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.queenSeen,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          if (hive.mateczniki > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, size: 12, color: Color.fromARGB(255, 255, 17, 0)),
                                const SizedBox(width: 4),
                                Text(
                                  '${AppLocalizations.of(context)!.queenCellsCount}: ${hive.mateczniki}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          if (hive.usunmat > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, size: 12, color: Color.fromARGB(255, 153, 125, 125)),
                                const SizedBox(width: 4),
                                Text(
                                  '${AppLocalizations.of(context)!.removedCellsCount}: ${hive.usunmat}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                  // Do zrobienia
                  if (todoTekst.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.toDo}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              todoTekst, //zadania ramek w bieżącym języku z liczbą ramek
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Notatka z przeglądu
                  if (_inspectionNote.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _inspectionNote,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --- Segment: Galeria zdjęć ---
          if (_photos.isNotEmpty && globals.showSummaryPhotos)
            // Card(
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   child: 
              
              Padding(
                padding: const EdgeInsets.all(6),
                child: 
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (ctx, i) {
                      final photo = _photos[i];
                      final dataFormatted = photo.data.length >= 10
                          ? '${photo.data.substring(8, 10)}.${photo.data.substring(5, 7)}.${photo.data.substring(0, 4)}'
                          : photo.data;
                      return GestureDetector(
                        onTap: () => _showPhotoPreview(photo),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: PhotoHelper.jestFilm(photo.sciezka)
                                    ? MiniaturaFilmu(sciezka: photo.sciezka)
                                    : Image.file(
                                  File(photo.sciezka),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dataFormatted,
                                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
       //     ),

          // --- Segment: brak matki ---
          //ul bez podłączonej matki, a przegląd zapisał "brak matki" (matka2) - segment
          //Matka się nie pokazuje, więc informacja o braku osobno (zgłoszenie 21.10.2026)
          if (_queens.isEmpty && globals.showSummaryQueen && hive.matka2.length >= 4 &&
              ['brak', 'miss', 'gone', 'nie '].contains(hive.matka2.substring(0, 4)))
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Image.asset('assets/image/matka1.png', width: 22, height: 22, fit: BoxFit.contain),
                    const SizedBox(width: 6),
                    const Icon(Icons.dangerous_outlined, size: 24.0, color: Color.fromARGB(255, 255, 0, 0)),
                    const SizedBox(width: 6),
                    Text(
                      '${AppLocalizations.of(context)!.qUeen}: ${AppLocalizations.of(context)!.missing}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

          // --- Segment: Matka ---
          if (_queens.isNotEmpty && globals.showSummaryQueen)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int qi = 0; qi < _queens.length; qi++) ...[
                      if (qi > 0) const SizedBox(height: 8),
                      // Wiersz 1: ID, linia (bold), rasa
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: '${AppLocalizations.of(context)!.qUeen} (ID${_queens[qi].id}) ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            TextSpan(
                              text: '${_queens[qi].linia} ',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            TextSpan(
                              text: breedToDisplay(breedToKey(_queens[qi].rasa), AppLocalizations.of(context)!),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Wiersz 2: ikona znaku, napis, źródło, data
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ...markToIcon(markToKey(_queens[qi].znak)),
                          Text(' ${_queens[qi].napis} ',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          Text('  ${sourceToDisplay(sourceToKey(_queens[qi].zrodlo), AppLocalizations.of(context)!)} ${_zmienDateCala(_queens[qi].data)} ',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ],
                      ),
                      // Wiersz 3: ikony z przeglądu (matka4, matka1, matka3, matka2, matka5)
                      if (hive.matka4 != '' && hive.matka4 != '0' ||
                          hive.matka1 != '' && hive.matka1 != '0' ||
                          hive.matka3 != '' && hive.matka3 != '0' ||
                          hive.matka2 != '' && hive.matka2 != '0' ||
                          hive.matka5 != '' && hive.matka5 != '0')
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // matka4 - ograniczenie
                              if (hive.matka4 == 'wolna' || hive.matka4 == 'freed')
                                Image.asset('assets/image/matka12.png', width: 30, height: 18, fit: BoxFit.fill)
                              else if (hive.matka4 == 'ograniczona' || hive.matka4 == 'in a cage' || hive.matka4 == 'in the insulator')
                                Image.asset('assets/image/matka11.png', width: 28, height: 17, fit: BoxFit.fill),
                              if (hive.matka4 != '' && hive.matka4 != '0')
                                const SizedBox(width: 10),
                              // matka1 - jakość; wartości (także te w innych językach
                              // i sprzed zamiany "zła" na "do wymiany") zna queen_helpers
                              if (qualityIsSet(hive.matka1))
                                qualityIsBad(hive.matka1)
                                    ? const Icon(Icons.thumb_down_outlined, size: 24.0, color: Color.fromARGB(255, 255, 1, 1))
                                    : const Icon(Icons.thumb_up_outlined, size: 24.0, color: Color.fromARGB(255, 15, 200, 8)),
                              if (hive.matka1 != '' && hive.matka1 != '0')
                                const SizedBox(width: 10),
                              // matka3 - unasiennienie
                              if (hive.matka3 == 'unasienniona' || hive.matka3 == 'naturally mated' || hive.matka3 == 'artificially inseminated')
                                const Icon(Icons.egg, size: 24.0, color: Color.fromARGB(255, 15, 200, 8))
                              else if (hive.matka3 == 'nieunasienniona' || hive.matka3 == 'virgine')
                                const Icon(Icons.egg_outlined, size: 24.0, color: Color.fromARGB(255, 255, 0, 0))
                              else if (hive.matka3 == 'trutowa' || hive.matka3 == 'drone laying')
                                const Icon(Icons.egg_outlined, size: 24.0, color: Color.fromARGB(255, 255, 0, 0)),
                              if (hive.matka3 != '' && hive.matka3 != '0')
                                const SizedBox(width: 10),
                              // matka2 - znak (kolor)
                              if (hive.matka2 != '' && hive.matka2 != '0' && hive.matka2.length >= 4)
                                if (hive.matka2.substring(0, 4) == 'niez' || hive.matka2.substring(0, 4) == 'unma')
                                  const Icon(Icons.circle, size: 24.0, color: Color.fromARGB(255, 61, 61, 61))
                                else if (hive.matka2.substring(0, 4) == 'brak' || hive.matka2.substring(0, 4) == 'miss' || hive.matka2.substring(0, 4) == 'gone' || hive.matka2.substring(0, 4) == 'nie ')
                                  const Icon(Icons.dangerous_outlined, size: 24.0, color: Color.fromARGB(255, 255, 0, 0))
                                else if (hive.matka2.substring(0, 4) == 'inny' || hive.matka2.substring(0, 4) == 'mark')
                                  const Icon(Icons.check_circle_rounded, size: 24.0, color: Color.fromARGB(255, 158, 166, 172))
                                else if (hive.matka2.substring(0, 4) == 'biał' || hive.matka2.substring(0, 4) == 'ma b')
                                  const Icon(Icons.check_circle_outline_outlined, size: 24.0, color: Color.fromARGB(255, 0, 0, 0))
                                else if (hive.matka2.substring(0, 4) == 'żółt')
                                  const Icon(Icons.check_circle_rounded, size: 24.0, color: Color.fromARGB(255, 215, 208, 0))
                                else if (hive.matka2.substring(0, 4) == 'czer')
                                  const Icon(Icons.check_circle_rounded, size: 24.0, color: Color.fromARGB(255, 255, 0, 0))
                                else if (hive.matka2.substring(0, 4) == 'ziel')
                                  const Icon(Icons.check_circle_rounded, size: 24.0, color: Color.fromARGB(255, 15, 200, 8))
                                else if (hive.matka2.substring(0, 4) == 'nieb')
                                  const Icon(Icons.check_circle_rounded, size: 24.0, color: Color.fromARGB(255, 0, 102, 255)),
                              // matka2 - napis na opalitku
                              if (hive.matka2 != '' && hive.matka2 != '0' && hive.matka2.length > 4 && hive.matka2.substring(4).isNotEmpty)
                                Text(hive.matka2.substring(4),
                                  style: const TextStyle(fontSize: 15, color: Color.fromARGB(255, 69, 69, 69)),
                                ),
                              if (hive.matka2 != '' && hive.matka2 != '0')
                                const SizedBox(width: 10),
                              // matka5 - rocznik
                              if (hive.matka5 != '' && hive.matka5 != '0' && hive.matka5.length > 2)
                                Text("'${hive.matka5.substring(2)}",
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),

          // --- Segment: Rodzina ---
          //pod segmentem Matka, bez słowa "Rodzina" (mieści się w jednej linii) -
          //pszczoła, potem ikonka stanu i siły rodziny z DATĄ wpisu w nawiasie (bez nazw,
          //prośba usera 15.10.2026). Miejsce na kolejne cechy - dokładać do Wrap.
          if ((_colonyForce.isNotEmpty || _colonyState.isNotEmpty) && globals.showSummaryColony)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Image.asset('assets/image/pszczola1.png', width: 22, height: 22, fit: BoxFit.fill),
                    if (_colonyState.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _cechaRodziny(_colonyStateIcon, _colonyState, _colonyStateName),
                    ],
                    if (_colonyForce.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _cechaRodziny(_colonyForceIcon, _colonyForce, _colonyForceName),
                    ],
                  ],
                ),
              ),
            ),

          // --- Segment: Zbiory ---
          if ((_lastHarvestHoneyKg > 0 || _lastHarvestPollenL > 0) && globals.showSummaryHarvest)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_lastHarvestHoneyKg > 0)
                    Row(
                      children: [
                        Image.asset('assets/image/zbiory.png', width: 22, height: 22, fit: BoxFit.fill),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppLocalizations.of(context)!.honey} '
                            '${globals.isEuropeanFormat() ? _lastHarvestHoneyKg.toStringAsFixed(1).replaceAll('.', ',') : _lastHarvestHoneyKg.toStringAsFixed(1)} '
                            'kg '
                              '(${_zmienDateCala(_lastHarvestHoneyDate)}) '
                              '(${_lastHarvestHoneyDate.substring(0, 4)}: ${_liczba(_yearHarvestHoneyKg, 1)} kg)',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    if (_lastHarvestHoneyKg > 0 && _lastHarvestPollenL > 0)
                      const SizedBox(height: 4),
                    if (_lastHarvestPollenL > 0)
                      Row(
                        children: [
                          Image.asset('assets/image/zbiory.png', width: 22, height: 22, fit: BoxFit.fill),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${AppLocalizations.of(context)!.beePollen} '
                              '${globals.isEuropeanFormat() ? _lastHarvestPollenL.toStringAsFixed(2).replaceAll('.', ',') : _lastHarvestPollenL.toStringAsFixed(2)} '
                              'l '
                              '(${_zmienDateCala(_lastHarvestPollenDate)}) '
                              '(${_lastHarvestPollenDate.substring(0, 4)}: ${_liczba(_yearHarvestPollenL, 2)} l)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

          // --- Segment: Dokarmianie ---
          if (_lastFeeding != null && globals.showSummaryFeeding)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   AppLocalizations.of(context)!.feeding[0].toUpperCase() +
                    //       AppLocalizations.of(context)!.feeding.substring(1),
                    //   style: const TextStyle(
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 16,
                    //   ),
                    // ),
                    // const SizedBox(height: 6),
                    Row(
                      children: [
                        Image.asset('assets/image/invert.png', width: 22, height: 22, fit: BoxFit.fill),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${nazwaParametru(context, _lastFeeding!.parametr)} ${_lastFeeding!.wartosc} ${miaraWBiezacym(context, _lastFeeding!.miara, parametr: _lastFeeding!.parametr)} (${_zmienDateCala(_lastFeeding!.data)})'
                            '${_yearFeeding == null ? '' : ' (${_lastFeeding!.data.substring(0, 4)}: ${_liczba(_yearFeeding!, 2)} ${miaraWBiezacym(context, _lastFeeding!.miara, parametr: _lastFeeding!.parametr)})'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // --- Segment: Leczenie ---
          if (_lastTreatment != null && globals.showSummaryTreatment)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   AppLocalizations.of(context)!.tReatment,
                    //   style: const TextStyle(
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 16,
                    //   ),
                    // ),
                    // const SizedBox(height: 6),
                    Row(
                      children: [
                        Image.asset('assets/image/apivarol1.png', width: 22, height: 22, fit: BoxFit.fill),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${nazwaParametru(context, _lastTreatment!.parametr)} ${_lastTreatment!.wartosc} ${miaraWBiezacym(context, _lastTreatment!.miara, parametr: _lastTreatment!.parametr)} (${_zmienDateCala(_lastTreatment!.data)})'
                            '${_yearTreatment == null ? '' : ' (${_lastTreatment!.data.substring(0, 4)}: ${_liczba(_yearTreatment!, 2)} ${miaraWBiezacym(context, _lastTreatment!.miara, parametr: _lastTreatment!.parametr)})'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // --- Segment: Zadania (Do zrobienia) ---
          // Sortowanie: najpierw z datą zadania (pole1) wg daty zadania ASC,
          // potem bez daty zadania wg daty utworzenia (data) ASC
          if (_hiveNotes.where((n) => n.priorytet == 'true').isNotEmpty)
            () {
              final taskiZPole1 = _hiveNotes.where((n) => n.priorytet == 'true' && n.pole1.isNotEmpty).toList()
                ..sort((a, b) => a.pole1.compareTo(b.pole1));
              final taskiBezPole1 = _hiveNotes.where((n) => n.priorytet == 'true' && n.pole1.isEmpty).toList()
                ..sort((a, b) => a.data.compareTo(b.data));
              final sortedTasks = [...taskiZPole1, ...taskiBezPole1];
              return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      for (int ni = 0; ni < sortedTasks.length; ni++) ...[
                        if (ni > 0) const Divider(height: 12),
                        () {
                          final task = sortedTasks[ni];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Wiersz 1: "Do zrobienia (data zadania)"
                    Text(
                                task.pole1.isNotEmpty
                                    ? '${AppLocalizations.of(context)!.toDo} (${_zmienDatePelna(task.pole1)})'
                                    : AppLocalizations.of(context)!.toDo,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: task.pole1.isEmpty
                                      ? const Color.fromARGB(255, 189, 165, 0) // żółty - bez daty zadania
                                      : !DateTime.parse(task.pole1).isAfter(DateTime.now())
                                          ? Colors.red // czerwony - data zadania <= dziś
                                          : const Color.fromARGB(255, 162, 103, 0), // pomarańczowy - data zadania > dziś
                                ),
                              ),
                              // Wiersz 2: tytuł
                              Text(
                                task.tytul,
                      style: const TextStyle(
                                  fontSize: 14,
                        fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Wiersz 3: treść zadania
                              if (task.notatka.isNotEmpty)
                                Text(
                                  task.notatka,
                                  style: const TextStyle(fontSize: 14),
                      ),
                              // Wiersz 4: uwagi (jeśli są)
                              if (task.uwagi.isNotEmpty)
                                Text(
                                  task.uwagi,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          );
                        }(),
                      ],
                    ],
                  ),
                ),
              );
            }(),

          // --- Segment: Notatki (zwykłe, bez zadań) ---
          // Sortowanie wg daty utworzenia DESC (najnowsze na górze)
          if (_hiveNotes.where((n) => n.priorytet != 'true').isNotEmpty)
            () {
              final sortedNotes = _hiveNotes.where((n) => n.priorytet != 'true').toList()
                ..sort((a, b) => b.data.compareTo(a.data));
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int ni = 0; ni < sortedNotes.length; ni++) ...[
                      if (ni > 0) const Divider(height: 12),
                        () {
                          final note = sortedNotes[ni];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Row(
                        children: [
                          Text(
                                    '${_zmienDatePelna(note.data)} ',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Expanded(
                            child: Text(
                                      note.tytul,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                              if (note.notatka.isNotEmpty)
                        Text(
                                  note.notatka,
                          style: const TextStyle(fontSize: 14),
                        ),
                              if (note.uwagi.isNotEmpty)
                                Text(
                                  note.uwagi,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          );
                        }(),
                    ],
                  ],
                ),
              ),
              );
            }(),
        ],
      ),
      ),
    );
  }

  void _showPhotoPreview(Photo photo) {
    final bool film = PhotoHelper.jestFilm(photo.sciezka);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            if (film)
              OdtwarzaczFilmu(sciezka: photo.sciezka)
            else
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(photo.sciezka),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${photo.data}  ${photo.czas}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 30),
                    onPressed: () async {
                      //iOS wymaga niezerowego prostokąta, z którego wysuwa się okno
                      //udostępniania ("sharePositionOrigin: argument must be set") -
                      //bez niego wyjątek i przycisk nic nie robił. Środek ekranu, 1x1.
                      final Size ekran = MediaQuery.of(ctx).size;
                      try {
                        await Share.shareXFiles(
                          [XFile(photo.sciezka, mimeType: film ? 'video/mp4' : 'image/jpeg')],
                          sharePositionOrigin: Rect.fromLTWH(ekran.width / 2, ekran.height / 2, 1, 1),
                        );
                      } catch (e) {
                        debugPrint('Błąd udostępniania zdjęcia: $e');
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Share error: $e')));
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }

  Color _apiaryColor(int pasiekaNr) {
    const colory = [
      Color.fromARGB(255, 252, 193, 104),
      Color.fromARGB(255, 255, 114, 104),
      Color.fromARGB(255, 104, 187, 254),
      Color.fromARGB(255, 83, 215, 88),
      Color.fromARGB(255, 203, 174, 85),
      Color.fromARGB(255, 248, 168, 48),
      Color.fromARGB(255, 255, 86, 74),
      Color.fromARGB(255, 71, 170, 251),
      Color.fromARGB(255, 61, 214, 66),
      Color.fromARGB(255, 210, 170, 49),
    ];
    int idx = pasiekaNr;
    while (idx > 10) {
      idx = idx - 10;
    }
    return colory[idx - 1];
  }

  String _zmienDatePelna(String data) {
    if (data.length < 10) return data;
    String rok = data.substring(0, 4);
    String miesiac = data.substring(5, 7);
    String dzien = data.substring(8, 10);
    if (globals.isEuropeanFormat()) {
      return '$dzien.$miesiac.$rok';
    } else {
      return '$rok-$miesiac-$dzien';
    }
  }

  //cecha rodziny w Aktualnościach: ikonka + (data), pod spodem drobna nazwa
  //cechy - sama ikonka nie mówi dokładnie, o co chodzi (prośba usera 15.10.2026)
  Widget _cechaRodziny(Icon? ikona, String data, String nazwa) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ikona != null) ...[ikona, const SizedBox(width: 4)],
            Text('($data)', style: const TextStyle(fontSize: 14)),
          ],
        ),
        if (nazwa.isNotEmpty)
          Text(nazwa,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
      ],
    );
  }

  //liczba na ekran - [miejsca] po przecinku bez końcowych zer, przecinek w formacie europejskim
  String _liczba(double v, int miejsca) {
    String t = v.toStringAsFixed(miejsca);
    if (t.contains('.')) t = t.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return globals.isEuropeanFormat() ? t.replaceAll('.', ',') : t;
  }

  String _zmienDateCala(String data) {
    if (data.length < 10) return data;
    String rok = data.substring(2, 4);
    String miesiac = data.substring(5, 7);
    String dzien = data.substring(8, 10);
    if (globals.isEuropeanFormat()) {
      return '$dzien.$miesiac.$rok';
    } else {
      return '$rok-$miesiac-$dzien';
    }
  }
}
