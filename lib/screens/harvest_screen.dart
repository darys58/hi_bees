import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:hi_bees/l10n/app_localizations.dart';

import '../models/harvest.dart';
import '../widgets/harvest_item.dart';
import '../screens/harvest_edit_screen.dart';
import '../globals.dart' as globals;
import '../helpers/prawa_zespolu.dart'; //blokady w bazie właściciela (etap 2 część B)
import '../helpers/eksport_helper.dart'; //menu PDF/CSV, zapis CSV

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});
  static const routeName = '/screen-harvest'; //nazwa trasy do tego ekranu
  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

//sumy zbiorów jednej pasieki (albo wszystkich razem) - przeliczenia jak dotąd:
//miód, pyłek, pierzga w litrach (kg -> l), wosk i propolis tylko w kg
class _SumyZbiorow {
  double miod = 0;
  double pylek = 0;
  double pierzga = 0;
  double wosk = 0;
  double propolis = 0;

  void dodaj(Harvest z) {
    switch (z.zasobId) {
      case 1: miod += z.miara == 1 ? z.ilosc : z.ilosc * 0.725; break; //1kg = 0.725l
      case 2: pylek += z.miara == 1 ? z.ilosc : z.ilosc * 1.579; break; //1kg = 1.579l
      case 3: pierzga += z.miara == 1 ? z.ilosc : z.ilosc * 1.8; break; //1kg = 1.8l
      case 4: if (z.miara != 1) wosk += z.ilosc; break; //tylko w kilogramach
      case 5: if (z.miara != 1) propolis += z.ilosc; break; //tylko w kilogramach
    }
  }

  bool get puste => miod == 0 && pylek == 0 && pierzga == 0 && wosk == 0 && propolis == 0;
}

//zasoby w kolejności podsumowań i wykresu: nazwa, suma, jednostka sumy,
//przelicznik na kg (pyłek 0,56 wszędzie - ustalenie usera 15.10.2026), kolor w PDF
class _ZasobSum {
  final String Function(AppLocalizations l) nazwa;
  final double Function(_SumyZbiorow s) ile;
  final String jm;
  final double naKg;
  final PdfColor kolor;
  const _ZasobSum(this.nazwa, this.ile, this.jm, this.naKg, this.kolor);
}

final List<_ZasobSum> _zasobySum = [
  _ZasobSum((l) => l.honey, (s) => s.miod, 'l', 1.45, PdfColors.amber),
  _ZasobSum((l) => l.beePollen, (s) => s.pylek, 'l', 0.56, PdfColors.orange),
  _ZasobSum((l) => l.perga, (s) => s.pierzga, 'l', 0.56, PdfColors.green),
  _ZasobSum((l) => l.wax, (s) => s.wosk, 'kg', 1, PdfColor.fromInt(0xFFBDB76B)),
  _ZasobSum((l) => 'propolis', (s) => s.propolis, 'kg', 1, PdfColors.brown),
];

//sumy zbiorów wybranego roku osobno dla każdej pasieki, pasieki rosnąco
Map<int, _SumyZbiorow> _sumyPasiek(List<Harvest> zbiory, String rok) {
  final Map<int, _SumyZbiorow> sumy = {};
  for (final z in zbiory) {
    if (!z.data.startsWith(rok)) continue;
    sumy.putIfAbsent(z.pasiekaNr, () => _SumyZbiorow()).dodaj(z);
  }
  sumy.removeWhere((_, s) => s.puste);
  final klucze = sumy.keys.toList()..sort();
  return {for (final k in klucze) k: sumy[k]!};
}

//jaśniejszy odcień koloru zasobu dla kolejnej pasieki na wykresie (pierwsza - kolor bazowy)
PdfColor _odcien(PdfColor c, int i, int ile) {
  if (ile <= 1 || i == 0) return c;
  final f = 0.6 * i / (ile - 1);
  return PdfColor(c.red + (1 - c.red) * f, c.green + (1 - c.green) * f, c.blue + (1 - c.blue) * f);
}

class _HarvestScreenState extends State<HarvestScreen> {
  bool _isInit = true;
  String wybranaData = DateTime.now().toString().substring(0, 4); //aktualny rok

  double miod = 0;
  double pylek = 0;
  double pierzga = 0;
  double wosk = 0;
  double propolis = 0;
  double wysokoscStatystyk = 15;

  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<Harvests>(context, listen: false)
          .fetchAndSetZbiory()
          .then((_) {
        //wszystkie zbiory z tabeli zbiory z bazy lokalnej
      });
    }
    _isInit = false;

    super.didChangeDependencies();
  }

  //CSV zbiorów (11.10.2026) - te same kolumny co tabela w PDF, ilość osobno od
  //jednostki, żeby arkusz mógł je sumować; na końcu podsumowanie z legendy PDF
  //(ilość w l albo kg i przeliczenie na kg jak w PDF).
  Future<void> _generateHarvestCsv(List<Harvest> zbiory) async {
    if (zbiory.isEmpty) return;
    final loc = AppLocalizations.of(context)!;
    final bool isPl = globals.isEuropeanFormat();

    String zasob(int z) {
      switch (z) {
        case 1: return loc.honey;
        case 2: return loc.beePollen;
        case 3: return loc.perga;
        case 4: return loc.wax;
        case 5: return 'propolis';
        default: return '';
      }
    }
    String miara(int m) => m == 1 ? 'l' : m == 2 ? 'kg' : '';
    String data(String d) {
      if (d.length < 10) return d;
      return isPl ? '${d.substring(8, 10)}.${d.substring(5, 7)}.${d.substring(0, 4)}'
                  : '${d.substring(5, 7)}-${d.substring(8, 10)}-${d.substring(0, 4)}';
    }

    final List<List<String>> wiersze = [
      ['${loc.hArvests} $wybranaData'],
      ['Hey Maya ${data(DateTime.now().toString().substring(0, 10))}'],
      [],
      [
        'L.p.',
        isPl ? 'Data' : 'Date',
        isPl ? 'Zasób' : 'Resource',
        isPl ? 'Ilość' : 'Qty',
        isPl ? 'J.m.' : 'Unit',
        isPl ? 'Uwagi' : 'Notes',
      ],
    ];
    //przy kilku pasiekach (15.10.2026) - wpisy i podsumowanie osobno dla każdej
    //pasieki, na końcu podsumowanie razem
    final sumyPasiek = _sumyPasiek(zbiory, wybranaData);
    final bool kilka = sumyPasiek.length > 1;
    final List<String> naglowek = wiersze.removeLast(); //wiersz z nazwami kolumn - przed każdą sekcją
    final zbiorySorted = zbiory.reversed.toList(); //od najstarszego, jak w PDF
    void wpisy(List<Harvest> lista) {
      for (int i = 0; i < lista.length; i++) {
        final z = lista[i];
        wiersze.add([
          '${i + 1}',
          data(z.data),
          zasob(z.zasobId),
          liczbaCsv(z.ilosc),
          miara(z.miara),
          z.uwagi,
        ]);
      }
    }
    void podsumowanie(_SumyZbiorow s) {
      wiersze.add([
        isPl ? 'Zasób' : 'Resource',
        isPl ? 'Ilość' : 'Qty',
        isPl ? 'J.m.' : 'Unit',
        isPl ? 'Ilość (kg)' : 'Qty (kg)',
      ]);
      for (final r in _zasobySum) {
        final v = r.ile(s);
        if (v > 0) wiersze.add([r.nazwa(loc), liczbaCsv(v), r.jm, liczbaCsv(v * r.naKg)]);
      }
    }
    if (!kilka) {
      wiersze.add(naglowek);
      wpisy(zbiorySorted);
      //podsumowanie - to samo co legenda przy wykresie w PDF (przeliczniki l -> kg jak w PDF)
      wiersze.add([]);
      final razem = _SumyZbiorow();
      for (final z in zbiorySorted) {
        if (z.data.startsWith(wybranaData)) razem.dodaj(z);
      }
      podsumowanie(razem);
    } else {
      sumyPasiek.forEach((nr, sumy) {
        wiersze.add(['${loc.aPiary} $nr']);
        wiersze.add(naglowek);
        wpisy(zbiorySorted.where((z) => z.pasiekaNr == nr).toList());
        wiersze.add([]);
        podsumowanie(sumy);
        wiersze.add([]);
      });
      wiersze.add([loc.total]);
      final razem = _SumyZbiorow();
      for (final z in zbiorySorted) {
        if (z.data.startsWith(wybranaData)) razem.dodaj(z);
      }
      podsumowanie(razem);
    }

    await udostepnijCsv(context, 'harvest_$wybranaData', wiersze);
  }

  Future<void> _generateHarvestPdf(List<Harvest> zbiory) async {
    if (zbiory.isEmpty) return;

    final loc = AppLocalizations.of(context)!;
    final bool isPl = globals.isEuropeanFormat();

    try {
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      // Dane do wykresu kołowego. Przy kilku pasiekach (15.10.2026) JEDEN wykres,
      // ale kawałek każdego zasobu podzielony na pasieki (odcienie koloru zasobu).
      final sumyPasiek = _sumyPasiek(zbiory, wybranaData);
      final bool kilka = sumyPasiek.length > 1;
      final List<int> nrPasiek = sumyPasiek.keys.toList();
      final pieColors = <PdfColor>[];
      final pieValues = <double>[];
      for (final r in _zasobySum) {
        for (int i = 0; i < nrPasiek.length; i++) {
          final v = r.ile(sumyPasiek[nrPasiek[i]]!);
          if (v <= 0) continue;
          pieValues.add(v);
          pieColors.add(_odcien(r.kolor, i, nrPasiek.length));
        }
      }

      List<pw.Dataset> pieDatasets = [];
      final pieTotal = pieValues.fold(0.0, (sum, v) => sum + v);
      for (int i = 0; i < pieValues.length; i++) {
        final v = pieValues[i];
        if (v.isNaN || v.isInfinite || v <= 0) continue;
        final percent = (v / pieTotal * 100).toStringAsFixed(1);
        pieDatasets.add(pw.PieDataSet(
          value: v,
          color: pieColors[i],
          legend: '$percent%',
          legendStyle: pw.TextStyle(fontSize: 8, font: fontBold),
        ));
      }

      // Helpery
      String getZasobText(int z) {
        switch (z) {
          case 1: return loc.honey;
          case 2: return loc.beePollen;
          case 3: return loc.perga;
          case 4: return loc.wax;
          case 5: return 'propolis';
          default: return '';
        }
      }

      String getMiaraText(int m) {
        switch (m) {
          case 1: return 'l';
          case 2: return 'kg';
          default: return '';
        }
      }

      String formatDate(String data) {
        if (data.length < 10) return data;
        String day = data.substring(8, 10);
        String month = data.substring(5, 7);
        String year = data.substring(0, 4);
        return isPl ? '$day.$month.$year' : '$month-$day-$year';
      }

      String formatValue(double val) {
        return isPl
            ? val.toStringAsFixed(2).replaceAll('.', ',')
            : val.toStringAsFixed(2);
      }

      // Legenda
      pw.Widget buildLegendRow(PdfColor color, String text) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(width: 10, height: 10, color: color),
              pw.SizedBox(width: 5),
              pw.Expanded(
                child: pw.Text(text,
                    style: pw.TextStyle(fontSize: 9, font: fontRegular)),
              ),
            ],
          ),
        );
      }

      //wiersz legendy: "miód: 12,40 l (17,98 kg)"; przy kilku pasiekach pod sumą
      //zasobu wiersz każdej pasieki w jej odcieniu z wykresu
      String opisSumy(_ZasobSum r, double v) => r.jm == 'l'
          ? '${formatValue(v)} l (${formatValue(v * r.naKg)} kg)'
          : '${formatValue(v)} kg';
      List<pw.Widget> legendRows = [];
      final razem = _SumyZbiorow();
      for (final sumy in sumyPasiek.values) {
        razem
          ..miod += sumy.miod
          ..pylek += sumy.pylek
          ..pierzga += sumy.pierzga
          ..wosk += sumy.wosk
          ..propolis += sumy.propolis;
      }
      for (final r in _zasobySum) {
        final v = r.ile(razem);
        if (v <= 0) continue;
        legendRows.add(buildLegendRow(r.kolor, '${r.nazwa(loc)}: ${opisSumy(r, v)}'));
        if (!kilka) continue;
        for (int i = 0; i < nrPasiek.length; i++) {
          final vp = r.ile(sumyPasiek[nrPasiek[i]]!);
          if (vp <= 0) continue;
          legendRows.add(pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12),
            child: buildLegendRow(_odcien(r.kolor, i, nrPasiek.length),
                '${loc.aPiary} ${nrPasiek[i]}: ${opisSumy(r, vp)}'),
          ));
        }
      }

      // Komórka tabeli
      pw.Widget cell(String text, {pw.Alignment alignment = pw.Alignment.centerLeft}) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(3),
          alignment: alignment,
          child: pw.Text(text, style: pw.TextStyle(fontSize: 8, font: fontRegular)),
        );
      }

      pw.Widget headerCell(String text) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(3),
          color: PdfColors.grey200,
          alignment: pw.Alignment.center,
          child: pw.Text(text, style: pw.TextStyle(fontSize: 8, font: fontBold)),
        );
      }

      // Wiersze tabeli - sortowanie od najstarszego do najnowszego; przy kilku
      // pasiekach osobna tabela dla każdej (numeracja od 1 w każdej)
      final zbiorySorted = zbiory.reversed.toList();

      pw.Widget tabela(List<Harvest> lista) {
        final List<pw.TableRow> tableRows = [
          pw.TableRow(children: [
            headerCell('L.p.'),
            headerCell(isPl ? 'Data' : 'Date'),
            headerCell(isPl ? 'Zasób' : 'Resource'),
            headerCell(isPl ? 'Ilość' : 'Qty'),
            headerCell(isPl ? 'Uwagi' : 'Notes'),
          ]),
        ];
        for (int i = 0; i < lista.length; i++) {
          final z = lista[i];
          String miaraText = getMiaraText(z.miara);
          String iloscText = miaraText.isNotEmpty
              ? '${formatValue(z.ilosc)} $miaraText'
              : formatValue(z.ilosc);
          tableRows.add(pw.TableRow(
            children: [
              cell('${i + 1}', alignment: pw.Alignment.center),
              cell(formatDate(z.data), alignment: pw.Alignment.center),
              cell(getZasobText(z.zasobId)),
              cell(iloscText, alignment: pw.Alignment.centerRight),
              cell(z.uwagi),
            ],
          ));
        }
        return pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(28),
            1: const pw.FixedColumnWidth(55),
            2: const pw.FlexColumnWidth(0.8),
            3: const pw.FixedColumnWidth(55),
            4: const pw.FlexColumnWidth(4),
          },
          children: tableRows,
        );
      }

      // Tworzenie PDF
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context ctx) {
            List<pw.Widget> content = [
              pw.Center(
                child: pw.Text(
                  '${loc.hArvests} $wybranaData',
                  style: pw.TextStyle(fontSize: 18, font: fontBold),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Hey Maya  ${isPl ? '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}' : DateTime.now().toString().substring(0, 10)}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey, font: fontRegular),
                ),
              ),
              pw.SizedBox(height: 20),
            ];

            // Wykres kołowy + legenda
            if (pieDatasets.isNotEmpty) {
              content.add(
                pw.Center(
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 300,
                        height: 300,
                        child: pw.Chart(
                          grid: pw.PieGrid(),
                          datasets: pieDatasets,
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Container(
                        width: 260,
                        padding: const pw.EdgeInsets.only(top: 24),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: legendRows,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              content.add(pw.SizedBox(height: 20));
            }

            // Tabela - przy kilku pasiekach nagłówek "Pasieka N" i tabela każdej
            if (!kilka) {
              content.add(tabela(zbiorySorted));
            } else {
              for (final nr in nrPasiek) {
                content.add(pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
                  child: pw.Text('${loc.aPiary} $nr',
                      style: pw.TextStyle(fontSize: 12, font: fontBold)),
                ));
                content.add(tabela(zbiorySorted.where((z) => z.pasiekaNr == nr).toList()));
              }
            }

            return content;
          },
        ),
      );

      // Udostępnienie PDF
      final Uint8List pdfBytes = await pdf.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'harvest_${wybranaData}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      debugPrint('Błąd generowania PDF zbiorów: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //tworzenie listy lat w których dokonywano zbiory
    // List<String> listaLat = [];
    // int odRoku = 2022; //zeby najstarszym był rok 2023
    // int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    // while (odRoku < biezacyRok) {
    //   listaLat.add(biezacyRok.toString());
    //   biezacyRok = biezacyRok - 1;
    // }

     //pobranie wszystkich zbiorów
    final harvestDataAll = Provider.of<Harvests>(context);
    List<Harvest> zbioryAll = harvestDataAll.items.where((pur) {
      return pur.data.startsWith('20');
    }).toList();

    List<String> listaLat = []; //lista lat w których dokonywano zbiorów
    int odRoku = int.parse(DateTime.now().toString().substring(0, 4)); //biezący rok

    //poszukanie najstarszego roku w którym dokonano zbiorów
    for (var i = 0; i < zbioryAll.length; i++) {
      if(odRoku > int.parse(zbioryAll[i].data.substring(0, 4)))
        odRoku = int.parse(zbioryAll[i].data.substring(0, 4));
    }
    
    //tworzenie listy lat w których dokonywano zbiorów
    int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    while (odRoku <= biezacyRok) {
      listaLat.add(biezacyRok.toString());
      biezacyRok = biezacyRok - 1;
    }
    
    
    //pobranie wszystkich zbiorow dla ula z wybranego roku
    final zbioryData = Provider.of<Harvests>(context);
    List<Harvest> zbiory = zbioryData.items.where((zb) {
      return zb.data.startsWith(wybranaData);
    }).toList();

    miod = 0;
    pylek = 0;
    pierzga = 0;
    wosk = 0;
    propolis = 0;
    wysokoscStatystyk = 15;

    //dla kazdego rodzaju zbiorów -  podliczenie roczne zbiorów
    for (var i = 0; i < zbiory.length; i++) {
      if (zbiory[i].data.substring(0, 4) == wybranaData) //dla wybranego roku
        switch (zbiory[i].zasobId) {
          case 1:
            zbiory[i].miara == 1
                ? miod = miod + zbiory[i].ilosc //l
                : miod = miod + zbiory[i].ilosc * 0.725; //podano w kg więc trzeba zamienić na l    1kg = 0.72l
            break;
          case 2:
            zbiory[i].miara == 1
                ? pylek = pylek + zbiory[i].ilosc 
                : pylek = pylek + zbiory[i].ilosc * 1.579; //l    1kg = 1.579l
            break;
          case 3:
            zbiory[i].miara == 1
                ? pierzga = pierzga + zbiory[i].ilosc
                : pierzga = pierzga + zbiory[i].ilosc * 1.8; //l     1kg = 1.8l 
            break;
          case 4:
            zbiory[i].miara == 1
                ? wosk = wosk //w litrach nie ma zliczania
                : wosk = wosk + zbiory[i].ilosc; //tylko w kilogramach
            break;
          case 5:
            zbiory[i].miara == 1
                ? propolis = propolis //w litrach nie ma zliczania
                : propolis = propolis + zbiory[i].ilosc; //tylko w kilogramach
            break;
          default:
        }
    }

    //sumy osobno dla każdej pasieki (prośba usera 15.10.2026) - przy jednej pasiece
    //ekran jak dotąd, przy kilku: każda pasieka, a pod spodem "Razem"
    final Map<int, _SumyZbiorow> sumyPasiek = _sumyPasiek(zbiory, wybranaData);
    final List<int> pasiekiZeZbiorami = sumyPasiek.keys.toList();
    final razem = _SumyZbiorow()
      ..miod = miod
      ..pylek = pylek
      ..pierzga = pierzga
      ..wosk = wosk
      ..propolis = propolis;

    if (miod != 0) wysokoscStatystyk = wysokoscStatystyk + 20;
    if (pylek != 0) wysokoscStatystyk = wysokoscStatystyk + 20;
    if (pierzga != 0) wysokoscStatystyk = wysokoscStatystyk + 20;
    if (wosk != 0) wysokoscStatystyk = wysokoscStatystyk + 20;
    if (propolis != 0) wysokoscStatystyk = wysokoscStatystyk + 20;

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            AppLocalizations.of(context)!.hArvests,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          // title: Text('Edit inspection hive $numerUla'),
          // backgroundColor: Color.fromARGB(255, 233, 140, 0),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () {
                if (!mogeZapisac(context, [czZbiory])) return; //etap 2 część B
                Navigator.of(context).pushNamed(HarvestEditScreen.routeName, arguments: {'temp': 1});
              },
            ),
            IconButton(
              icon: Icon(Icons.picture_as_pdf, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () async {
                if (zbiory.isEmpty) return;
                final format = await wybierzFormat(context); //menu PDF / CSV
                if (format == FormatEksportu.pdf) _generateHarvestPdf(zbiory);
                if (format == FormatEksportu.csv) _generateHarvestCsv(zbiory);
              },
            ),
            // IconButton(
            //   icon: Icon(Icons.edit),
            //   onPressed: () => Navigator.of(context)
            //       .pushNamed(FramesDetailScreen.routeName, arguments: {
            //     'ul': globals.ulID,
            //     'data': wybranaData,
            //   }),
            // )
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey[300], // kolor linii
              height: 1.0,
            ),
          ),
        ),
        body: zbiory.length == 0
            ? Center(
                child: Column(
                  children: <Widget>[
//daty, zeby mozna było wybrać inna datę jezeli nie ma zbiorow w wybranym roku
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 18.0, vertical: 15.0),
                      height: 76, //MediaQuery.of(context).size.height * 0.35,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: listaLat.length,
                          itemBuilder: (context, index) {
                            return Container(
                              //width: MediaQuery.of(context).size.width * 0.6,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    wybranaData = listaLat[index];
                                  });
                                },
                                child: wybranaData == listaLat[index]
                                    ? Card(
                                        color: Colors.white,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.0, vertical: 1.0),
                                          child: Center(
                                              child: Text(
                                            '  ${listaLat[index]}  ', //nazwa
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 17.0),
                                          )),
                                        ),
                                      )
                                    : Card(
                                        color: Colors.white,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.0, vertical: 1.0),
                                          child: Center(
                                              child: Text(
                                            '  ${listaLat[index]}  ',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 17.0),
                                          )),
                                        ),
                                      ),
                              ),
                            );
                          }),
                    ),

                    Container(
                      padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                      child: Text(
                        AppLocalizations.of(context)!.noHarvestYet,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(children: <Widget>[
//daty
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 18.0, vertical: 15.0),
                  height: 76, //MediaQuery.of(context).size.height * 0.35,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: listaLat.length,
                      itemBuilder: (context, index) {
                        return Container(
                          //width: MediaQuery.of(context).size.width * 0.6,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                wybranaData = listaLat[index];
                              });
                            },
                            child: wybranaData == listaLat[index]
                                ? Card(
                                    color: Colors.white,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 1.0),
                                      child: Center(
                                          child: Text(
                                        '  ${listaLat[index]}  ', //nazwa
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 17.0),
                                      )),
                                    ),
                                  )
                                : Card(
                                    color: Colors.white,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 1.0),
                                      child: Center(
                                          child: Text(
                                        '  ${listaLat[index]}  ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 17.0),
                                      )),
                                    ),
                                  ),
                          ),
                        );
                      }),
                ),

//Statystyki zbiorów dla biezacego roku - przy kilku pasiekach osobno każda i "Razem"
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: SingleChildScrollView(
                    child: Container(
                      margin: EdgeInsets.all(1), //bez width - blok wyśrodkowany jak dotąd
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pasiekiZeZbiorami.length > 1) ...[
                            for (final nr in pasiekiZeZbiorami) ...[
                              Text('${AppLocalizations.of(context)!.aPiary} $nr',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ..._wierszeSum(context, sumyPasiek[nr]!, 16),
                              const SizedBox(height: 6),
                            ],
                            Text(AppLocalizations.of(context)!.total,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                          ..._wierszeSum(context, razem, 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(
                  height: 10,
                  thickness: 1,
                  indent: 0,
                  endIndent: 0,
                  color: Colors.black,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: zbiory.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: zbiory[i],
                      child: HarvestItem(),
                    ),
                  ),
                )
              ]));
  }

  //wiersze sum zbiorów: miód "l (kg)" z ilością pogrubioną, pozostałe jak dotąd
  List<Widget> _wierszeSum(BuildContext context, _SumyZbiorow s, double rozmiar) {
    final loc = AppLocalizations.of(context)!;
    final eu = globals.isEuropeanFormat();
    String l2(double v) => eu ? v.toStringAsFixed(2).replaceAll('.', ',') : v.toStringAsFixed(2);
    String kg(double v) => eu ? v.toString().replaceAll('.', ',') : '$v';
    final styl = TextStyle(fontSize: rozmiar, color: const Color.fromARGB(255, 0, 0, 0));
    final gruby = styl.copyWith(fontWeight: FontWeight.bold);
    return [
      if (s.miod != 0)
        RichText(text: TextSpan(style: const TextStyle(color: Colors.black), children: [
          TextSpan(text: loc.honey + ': ', style: styl),
          TextSpan(text: '${l2(s.miod)} l', style: gruby),
          TextSpan(text: ' (${l2(s.miod * 1.45)} kg)', style: styl),
        ])),
      if (s.pylek != 0)
        Text(loc.beePollen + ': ${l2(s.pylek)} l (${l2(s.pylek * 0.56)} kg)', style: styl),
      if (s.pierzga != 0)
        Text(loc.perga + ': ${l2(s.pierzga)} l (${l2(s.pierzga * 0.56)} kg)', style: styl),
      if (s.wosk != 0)
        Text(loc.wax + ': ${kg(s.wosk)} kg', style: styl),
      if (s.propolis != 0)
        Text('propolis: ${kg(s.propolis)} kg', style: styl),
    ];
  }
}
