import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/purchase.dart';
import '../widgets/purchase_item.dart';
import '../screens/purchase_edit_screen.dart';
import '../globals.dart' as globals;

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});
  static const routeName = '/screen-purchase'; //nazwa trasy do tego ekranu
  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  bool _isInit = true;
  String wybranaData = DateTime.now().toString().substring(0, 4); //aktualny rok

  double brakWartoscPLN = 0; //kategoria brak
  double brakWartoscEUR = 0;
  double brakWartoscUSD = 0;
  double opakowaniaWartoscPLN = 0;
  double opakowaniaWartoscEUR = 0;
  double opakowaniaWartoscUSD = 0;
  double wyposazenieWartoscPLN = 0;
  double wyposazenieWartoscEUR = 0;
  double wyposazenieWartoscUSD = 0;
  double pszczolyWartoscPLN = 0;
  double pszczolyWartoscEUR = 0;
  double pszczolyWartoscUSD = 0;
  double matkiWartoscPLN = 0;
  double matkiWartoscEUR = 0;
  double matkiWartoscUSD = 0;
  double wezaWartoscPLN = 0;
  double wezaWartoscEUR = 0;
  double wezaWartoscUSD = 0;
  double pokarmWartoscPLN = 0;
  double pokarmWartoscEUR = 0;
  double pokarmWartoscUSD = 0;
  double lekiWartoscPLN = 0;
  double lekiWartoscEUR = 0;
  double lekiWartoscUSD = 0;

  double razemWartoscPLN = 0;
  double razemWartoscEUR = 0;
  double razemWartoscUSD = 0;

  double wysokoscStatystyk = 15;

  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<Purchases>(context) //, listen: false
          .fetchAndSetZakupy()
          .then((_) {
        //wszystkie zakupy z tabeli zakupy z bazy lokalnej
      });
    }
    _isInit = false;

    super.didChangeDependencies();
  }

  dodajWartosc1(waluta, wartosc) {
    switch (waluta) {
      case 1:
        brakWartoscPLN += wartosc;
        break;
      case 2:
        brakWartoscEUR += wartosc;
        break;
      case 3:
        brakWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc2(waluta, wartosc) {
    switch (waluta) {
      case 1:
        opakowaniaWartoscPLN += wartosc;
        break;
      case 2:
        opakowaniaWartoscEUR += wartosc;
        break;
      case 3:
        opakowaniaWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc3(waluta, wartosc) {
    switch (waluta) {
      case 1:
        wyposazenieWartoscPLN += wartosc;
        break;
      case 2:
        wyposazenieWartoscEUR += wartosc;
        break;
      case 3:
        wyposazenieWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc4(waluta, wartosc) {
    switch (waluta) {
      case 1:
        pszczolyWartoscPLN += wartosc;
        break;
      case 2:
        pszczolyWartoscEUR += wartosc;
        break;
      case 3:
        pszczolyWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc5(waluta, wartosc) {
    switch (waluta) {
      case 1:
        matkiWartoscPLN += wartosc;
        break;
      case 2:
        matkiWartoscEUR += wartosc;
        break;
      case 3:
        matkiWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc6(waluta, wartosc) {
    switch (waluta) {
      case 1:
        wezaWartoscPLN += wartosc;
        break;
      case 2:
        wezaWartoscEUR += wartosc;
        break;
      case 3:
        wezaWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc7(waluta, wartosc) {
    switch (waluta) {
      case 1:
        pokarmWartoscPLN += wartosc;
        break;
      case 2:
        pokarmWartoscEUR += wartosc;
        break;
      case 3:
        pokarmWartoscUSD += wartosc;
        break;
    }
  }

  dodajWartosc8(waluta, wartosc) {
    switch (waluta) {
      case 1:
        lekiWartoscPLN += wartosc;
        break;
      case 2:
        lekiWartoscEUR += wartosc;
        break;
      case 3:
        lekiWartoscUSD += wartosc;
        break;
    }
  }

  Future<void> _generatePurchasePdf(List<Purchase> zakupy) async {
    if (zakupy.isEmpty) return;

    final loc = AppLocalizations.of(context)!;
    final bool isPl = globals.isEuropeanFormat();

    try {
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      // Sumaryczne wartości per kategoria dla wykresu kołowego
      double brakTotal = brakWartoscPLN + brakWartoscEUR + brakWartoscUSD;
      double opakowaniaTotal = opakowaniaWartoscPLN + opakowaniaWartoscEUR + opakowaniaWartoscUSD;
      double wyposazenieTotal = wyposazenieWartoscPLN + wyposazenieWartoscEUR + wyposazenieWartoscUSD;
      double pszczolyTotal = pszczolyWartoscPLN + pszczolyWartoscEUR + pszczolyWartoscUSD;
      double matkiTotal = matkiWartoscPLN + matkiWartoscEUR + matkiWartoscUSD;
      double wezaTotal = wezaWartoscPLN + wezaWartoscEUR + wezaWartoscUSD;
      double pokarmTotal = pokarmWartoscPLN + pokarmWartoscEUR + pokarmWartoscUSD;
      double lekiTotal = lekiWartoscPLN + lekiWartoscEUR + lekiWartoscUSD;

      // Dane do wykresu kołowego
      final pieColors = <PdfColor>[];
      final pieValues = <double>[];
      final pieNames = <String>[];

      if (brakTotal > 0) {
        pieNames.add(loc.noCaregory);
        pieValues.add(brakTotal);
        pieColors.add(PdfColors.grey);
      }
      if (opakowaniaTotal > 0) {
        pieNames.add(loc.packaging);
        pieValues.add(opakowaniaTotal);
        pieColors.add(PdfColors.amber);
      }
      if (wyposazenieTotal > 0) {
        pieNames.add(loc.equipment);
        pieValues.add(wyposazenieTotal);
        pieColors.add(PdfColors.blue);
      }
      if (pszczolyTotal > 0) {
        pieNames.add(loc.bees);
        pieValues.add(pszczolyTotal);
        pieColors.add(PdfColors.orange);
      }
      if (matkiTotal > 0) {
        pieNames.add(loc.queens);
        pieValues.add(matkiTotal);
        pieColors.add(PdfColors.red);
      }
      if (wezaTotal > 0) {
        pieNames.add(loc.waxFundation);
        pieValues.add(wezaTotal);
        pieColors.add(PdfColor.fromInt(0xFFBDB76B));
      }
      if (pokarmTotal > 0) {
        pieNames.add(loc.food);
        pieValues.add(pokarmTotal);
        pieColors.add(PdfColors.green);
      }
      if (lekiTotal > 0) {
        pieNames.add(loc.medicines);
        pieValues.add(lekiTotal);
        pieColors.add(PdfColors.purple);
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
      String getWalutaText(int w) {
        switch (w) {
          case 1: return 'PLN';
          case 2: return 'EUR';
          case 3: return 'USD';
          default: return '';
        }
      }

      String getKategoriaText(int k) {
        switch (k) {
          case 1: return loc.noCaregory;
          case 2: return loc.packaging;
          case 3: return loc.equipment;
          case 4: return loc.bees;
          case 5: return loc.queens;
          case 6: return loc.waxFundation;
          case 7: return loc.food;
          case 8: return loc.medicines;
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
      pw.Widget buildLegendRow(PdfColor color, String text, {bool bold = false}) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(width: 10, height: 10, color: color),
              pw.SizedBox(width: 5),
              pw.Expanded(
                child: pw.Text(text,
                    style: pw.TextStyle(
                        fontSize: 9,
                        font: bold ? fontBold : fontRegular)),
              ),
            ],
          ),
        );
      }

      List<pw.Widget> legendRows = [];

      void addLegend(PdfColor color, String name, double pln, double eur, double usd) {
        if (pln <= 0 && eur <= 0 && usd <= 0) return;
        String t = '$name: ';
        if (pln > 0) t += ' ${pln.toStringAsFixed(0)} PLN';
        if (eur > 0) t += ' ${eur.toStringAsFixed(0)} EUR';
        if (usd > 0) t += ' ${usd.toStringAsFixed(0)} USD';
        legendRows.add(buildLegendRow(color, t));
      }

      addLegend(PdfColors.grey, loc.noCaregory, brakWartoscPLN, brakWartoscEUR, brakWartoscUSD);
      addLegend(PdfColors.amber, loc.packaging, opakowaniaWartoscPLN, opakowaniaWartoscEUR, opakowaniaWartoscUSD);
      addLegend(PdfColors.blue, loc.equipment, wyposazenieWartoscPLN, wyposazenieWartoscEUR, wyposazenieWartoscUSD);
      addLegend(PdfColors.orange, loc.bees, pszczolyWartoscPLN, pszczolyWartoscEUR, pszczolyWartoscUSD);
      addLegend(PdfColors.red, loc.queens, matkiWartoscPLN, matkiWartoscEUR, matkiWartoscUSD);
      addLegend(PdfColor.fromInt(0xFFBDB76B), loc.waxFundation, wezaWartoscPLN, wezaWartoscEUR, wezaWartoscUSD);
      addLegend(PdfColors.green, loc.food, pokarmWartoscPLN, pokarmWartoscEUR, pokarmWartoscUSD);
      addLegend(PdfColors.purple, loc.medicines, lekiWartoscPLN, lekiWartoscEUR, lekiWartoscUSD);

      // RAZEM
      String razemText = loc.tOTAL + ': ';
      if (razemWartoscPLN > 0) razemText += ' ${razemWartoscPLN.toStringAsFixed(0)} PLN';
      if (razemWartoscEUR > 0) razemText += ' ${razemWartoscEUR.toStringAsFixed(0)} EUR';
      if (razemWartoscUSD > 0) razemText += ' ${razemWartoscUSD.toStringAsFixed(0)} USD';
      legendRows.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 5, left: 15),
        child: pw.Text(razemText, style: pw.TextStyle(fontSize: 10, font: fontBold)),
      ));

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

      // Wiersze tabeli - sortowanie od najstarszego do najnowszego
      final zakupySorted = zakupy.reversed.toList();

      String getPurchaseMiaraText(int m) {
        switch (m) {
          case 1: return loc.pcs;
          case 2: return 'l';
          case 3: return 'kg';
          default: return '';
        }
      }

      List<pw.TableRow> tableRows = [
        pw.TableRow(children: [
          headerCell('L.p.'),
          headerCell(isPl ? 'Data' : 'Date'),
          headerCell(isPl ? 'Kategoria' : 'Category'),
          headerCell(isPl ? 'Nazwa' : 'Name'),
          headerCell(isPl ? 'Ilość' : 'Qty'),
          headerCell(isPl ? 'Cena' : 'Price'),
          headerCell(isPl ? 'Wartość' : 'Value'),
          headerCell(isPl ? 'Uwagi' : 'Notes'),
        ]),
      ];

      for (int i = 0; i < zakupySorted.length; i++) {
        final z = zakupySorted[i];
        String kategoriaText = getKategoriaText(z.kategoriaId);
        String miaraText = getPurchaseMiaraText(z.miara);
        String iloscText = miaraText.isNotEmpty
            ? '${z.ilosc.toInt()} $miaraText'
            : '${z.ilosc.toInt()}';

        tableRows.add(pw.TableRow(
          children: [
            cell('${i + 1}', alignment: pw.Alignment.center),
            cell(formatDate(z.data), alignment: pw.Alignment.center),
            cell(kategoriaText),
            cell(z.nazwa),
            cell(iloscText, alignment: pw.Alignment.centerRight),
            cell(formatValue(z.cena), alignment: pw.Alignment.centerRight),
            cell('${formatValue(z.wartosc)} ${getWalutaText(z.waluta)}', alignment: pw.Alignment.centerRight),
            cell(z.uwagi),
          ],
        ));
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
                  '${loc.pUrchase} $wybranaData',
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

            // Tabela
            content.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FixedColumnWidth(55),
                  2: const pw.FlexColumnWidth(1.4),
                  3: const pw.FlexColumnWidth(2.4),
                  4: const pw.FixedColumnWidth(45),
                  5: const pw.FixedColumnWidth(44),
                  6: const pw.FixedColumnWidth(62),
                  7: const pw.FlexColumnWidth(3),
                },
                children: tableRows,
              ),
            );

            return content;
          },
        ),
      );

      // Udostępnienie PDF
      final Uint8List pdfBytes = await pdf.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'purchase_${wybranaData}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      debugPrint('Błąd generowania PDF zakupów: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    brakWartoscPLN = 0; //kategoria brak
    brakWartoscEUR = 0;
    brakWartoscUSD = 0;
    opakowaniaWartoscPLN = 0;
    opakowaniaWartoscEUR = 0;
    opakowaniaWartoscUSD = 0;
    wyposazenieWartoscPLN = 0;
    wyposazenieWartoscEUR = 0;
    wyposazenieWartoscUSD = 0;
    pszczolyWartoscPLN = 0;
    pszczolyWartoscEUR = 0;
    pszczolyWartoscUSD = 0;
    matkiWartoscPLN = 0;
    matkiWartoscEUR = 0;
    matkiWartoscUSD = 0;
    wezaWartoscPLN = 0;
    wezaWartoscEUR = 0;
    wezaWartoscUSD = 0;
    pokarmWartoscPLN = 0;
    pokarmWartoscEUR = 0;
    pokarmWartoscUSD = 0;
    lekiWartoscPLN = 0;
    lekiWartoscEUR = 0;
    lekiWartoscUSD = 0;
    razemWartoscPLN = 0;
    razemWartoscEUR = 0;
    razemWartoscUSD = 0;
    wysokoscStatystyk = 15;

    //pobranie wszystkich zakupów
    final purchaseDataAll = Provider.of<Purchases>(context);
    List<Purchase> zakupyAll = purchaseDataAll.items.where((pur) {
      return pur.data.startsWith('20');
    }).toList();

    List<String> listaLat = []; //lista lat w których dokonywano zakupy
    int odRoku = int.parse(DateTime.now().toString().substring(0, 4)); //biezący rok

    //poszukanie najstarszego roku w którym dokonano zakupów
    for (var i = 0; i < zakupyAll.length; i++) {
      if(odRoku > int.parse(zakupyAll[i].data.substring(0, 4)))
        odRoku = int.parse(zakupyAll[i].data.substring(0, 4));
    }
    
    //tworzenie listy lat w których dokonywano zakupy
    int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
    while (odRoku <= biezacyRok) {
      listaLat.add(biezacyRok.toString());
      biezacyRok = biezacyRok - 1;
    }

    //pobranie wszystkich zakupów z wybranego roku
    final purchaseData = Provider.of<Purchases>(context);
    List<Purchase> zakupy = purchaseData.items.where((pur) {
      return pur.data.startsWith(wybranaData);
    }).toList();
    
    //dla kazdego rodzaju kategorii -  podliczenie roczne zakupów
    for (var i = 0; i < zakupy.length; i++) {
      if (zakupy[i].data.substring(0, 4) == wybranaData) //dla wybranego roku
        switch (zakupy[i].kategoriaId) {
          //1-brak, 2-opakowania, 3-wyposazenie, 4-pszczoły, 5-matka, 6-węza, 7-pokarm, 8-leki,
          case 1: //brak
            dodajWartosc1(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 2:
            dodajWartosc2(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 3:
            dodajWartosc3(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 4:
            dodajWartosc4(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 5:
            dodajWartosc5(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 6:
            dodajWartosc6(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 7:
            dodajWartosc7(zakupy[i].waluta, zakupy[i].wartosc);
            break;
          case 8:
            dodajWartosc8(zakupy[i].waluta, zakupy[i].wartosc);
            break;
        }

      if (i == zakupy.length - 1) {
        razemWartoscPLN = brakWartoscPLN +
            opakowaniaWartoscPLN +
            wyposazenieWartoscPLN +
            pszczolyWartoscPLN +
            matkiWartoscPLN +
            wezaWartoscPLN +
            pokarmWartoscPLN +
            lekiWartoscPLN;
        razemWartoscEUR = brakWartoscEUR +
            opakowaniaWartoscEUR +
            wyposazenieWartoscEUR +
            pszczolyWartoscEUR +
            matkiWartoscEUR +
            wezaWartoscEUR +
            pokarmWartoscEUR +
            lekiWartoscEUR;
        razemWartoscUSD = brakWartoscUSD +
            opakowaniaWartoscUSD +
            wyposazenieWartoscUSD +
            pszczolyWartoscUSD +
            matkiWartoscUSD +
            wezaWartoscUSD +
            pokarmWartoscUSD +
            lekiWartoscUSD;
      }
    }

    if (brakWartoscPLN != 0 || brakWartoscEUR != 0 || brakWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;
    if (opakowaniaWartoscPLN != 0 ||
        opakowaniaWartoscEUR != 0 ||
        opakowaniaWartoscUSD != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (wyposazenieWartoscPLN != 0 ||
        wyposazenieWartoscEUR != 0 ||
        wyposazenieWartoscUSD != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (pszczolyWartoscPLN != 0 ||
        pszczolyWartoscEUR != 0 ||
        pszczolyWartoscUSD != 0) wysokoscStatystyk = wysokoscStatystyk + 18;
    if (matkiWartoscPLN != 0 || matkiWartoscEUR != 0 || matkiWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;
    if (wezaWartoscPLN != 0 || wezaWartoscEUR != 0 || wezaWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;
    if (pokarmWartoscPLN != 0 || pokarmWartoscEUR != 0 || pokarmWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;
    if (lekiWartoscPLN != 0 || lekiWartoscEUR != 0 || lekiWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;
    if (razemWartoscPLN != 0 || razemWartoscEUR != 0 || razemWartoscUSD != 0)
      wysokoscStatystyk = wysokoscStatystyk + 18;

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            AppLocalizations.of(context)!.pUrchase,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          // title: Text('Edit inspection hive $numerUla'),
          // backgroundColor: Color.fromARGB(255, 233, 140, 0),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () =>
                  Navigator.of(context).pushNamed(
                PurchaseEditScreen.routeName,
                arguments: {'temp': 1},
              ),
            ),
            IconButton(
              icon: Icon(Icons.picture_as_pdf, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () => _generatePurchasePdf(zakupy),
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
        body: zakupy.length == 0
            ? Center(
                child: Column(
                  children: <Widget>[
//daty, zeby mozna było wybrać inna datę jezeli nie ma zakupów w wybranym roku
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
                        AppLocalizations.of(context)!.noPurchaseYet,
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

//Statystyki zakupyy dla wybranego roku
                //if (wybranaKategoria == 'harvest')
                Container(
                  // decoration: BoxDecoration(
                  //     border: Border.all(
                  //     color: Colors.black,
                  //     width: 2.0,
                  //   ),),
                  margin: EdgeInsets.all(1),
                  height: wysokoscStatystyk,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //zakupy bez kategorii
                      if (brakWartoscPLN != 0 ||
                          brakWartoscEUR != 0 ||
                          brakWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.noCaregory) +
                                        ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (brakWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${brakWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (brakWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (brakWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${brakWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (brakWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (brakWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${brakWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (brakWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),

//zakupy opakowań
                      if (opakowaniaWartoscPLN != 0 ||
                          opakowaniaWartoscEUR != 0 ||
                          opakowaniaWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.packaging) +
                                        ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (opakowaniaWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${opakowaniaWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (opakowaniaWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (opakowaniaWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${opakowaniaWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (opakowaniaWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (opakowaniaWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${opakowaniaWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (opakowaniaWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy wyposazenia
                      if (wyposazenieWartoscPLN != 0 ||
                          wyposazenieWartoscEUR != 0 ||
                          wyposazenieWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.equipment) +
                                        ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (wyposazenieWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${wyposazenieWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wyposazenieWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wyposazenieWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${wyposazenieWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wyposazenieWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wyposazenieWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${wyposazenieWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wyposazenieWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy pszczół
                      if (pszczolyWartoscPLN != 0 ||
                          pszczolyWartoscEUR != 0 ||
                          pszczolyWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.bees) + ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (pszczolyWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${pszczolyWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pszczolyWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pszczolyWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${pszczolyWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pszczolyWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pszczolyWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${pszczolyWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pszczolyWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy matek
                      if (matkiWartoscPLN != 0 ||
                          matkiWartoscEUR != 0 ||
                          matkiWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text: (AppLocalizations.of(context)!.queens) +
                                    ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (matkiWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${matkiWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (matkiWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (matkiWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${matkiWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (matkiWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (matkiWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${matkiWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (matkiWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy węzy
                      if (wezaWartoscPLN != 0 ||
                          wezaWartoscEUR != 0 ||
                          wezaWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text: (AppLocalizations.of(context)!
                                        .waxFundation) +
                                    ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (wezaWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${wezaWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wezaWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wezaWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${wezaWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wezaWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wezaWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${wezaWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (wezaWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy pokarmu
                      if (pokarmWartoscPLN != 0 ||
                          pokarmWartoscEUR != 0 ||
                          pokarmWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.food) + ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (pokarmWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${pokarmWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pokarmWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pokarmWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${pokarmWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pokarmWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pokarmWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${pokarmWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (pokarmWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),
//zakupy leków
                      if (lekiWartoscPLN != 0 ||
                          lekiWartoscEUR != 0 ||
                          lekiWartoscUSD != 0)
                        RichText(
                            text: TextSpan(
                                text:
                                    (AppLocalizations.of(context)!.medicines) +
                                        ': ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                children: [
                              if (lekiWartoscPLN != 0)
                                TextSpan(
                                  text:
                                      (' ${lekiWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (lekiWartoscPLN != 0)
                                TextSpan(
                                  text: (' PLN'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (lekiWartoscEUR != 0)
                                TextSpan(
                                  text:
                                      (' ${lekiWartoscEUR.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (lekiWartoscEUR != 0)
                                TextSpan(
                                  text: (' EUR'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (lekiWartoscUSD != 0)
                                TextSpan(
                                  text:
                                      (' ${lekiWartoscUSD.toStringAsFixed(0)}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (lekiWartoscUSD != 0)
                                TextSpan(
                                  text: (' USD'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ])),

  //RAZEM
                      SizedBox(height: 5),
                      RichText(
                          text: TextSpan(
                              text:
                                  (AppLocalizations.of(context)!.tOTAL) + ': ',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                              children: [
                            if (razemWartoscPLN != 0)
                              TextSpan(
                                text:
                                    (' ${razemWartoscPLN.toStringAsFixed(0).replaceAll('.', ',')}'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (razemWartoscPLN != 0)
                              TextSpan(
                                text: (' PLN'),
                                style: TextStyle(
                                  fontSize: 12,
                                  //fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (razemWartoscEUR != 0)
                              TextSpan(
                                text: (' ${razemWartoscEUR.toStringAsFixed(0)}'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (razemWartoscEUR != 0)
                              TextSpan(
                                text: (' EUR'),
                                style: TextStyle(
                                  fontSize: 12,
                                  //fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (razemWartoscUSD != 0)
                              TextSpan(
                                text: (' ${razemWartoscUSD.toStringAsFixed(0)}'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (razemWartoscUSD != 0)
                              TextSpan(
                                text: (' USD'),
                                style: TextStyle(
                                  fontSize: 12,
                                  //fontWeight: FontWeight.bold,
                                ),
                              ),
                          ])),
                    ],
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
                    itemCount: zakupy.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: zakupy[i],
                      child: PurchaseItem(),
                    ),
                  ),
                )
              ]));
  }
}
