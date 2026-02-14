import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/harvest.dart';
import '../widgets/harvest_item.dart';
import '../screens/harvest_edit_screen.dart';
import '../globals.dart' as globals;

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});
  static const routeName = '/screen-harvest'; //nazwa trasy do tego ekranu
  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
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

  Future<void> _generateHarvestPdf(List<Harvest> zbiory) async {
    if (zbiory.isEmpty) return;

    final loc = AppLocalizations.of(context)!;
    final bool isPl = globals.jezyk == 'pl_PL';

    try {
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      // Dane do wykresu kołowego
      final pieColors = <PdfColor>[];
      final pieValues = <double>[];
      final pieNames = <String>[];

      if (miod > 0) {
        pieNames.add(loc.honey);
        pieValues.add(miod);
        pieColors.add(PdfColors.amber);
      }
      if (pylek > 0) {
        pieNames.add(loc.beePollen);
        pieValues.add(pylek);
        pieColors.add(PdfColors.orange);
      }
      if (pierzga > 0) {
        pieNames.add(loc.perga);
        pieValues.add(pierzga);
        pieColors.add(PdfColors.green);
      }
      if (wosk > 0) {
        pieNames.add(loc.wax);
        pieValues.add(wosk);
        pieColors.add(PdfColor.fromInt(0xFFBDB76B));
      }
      if (propolis > 0) {
        pieNames.add('propolis');
        pieValues.add(propolis);
        pieColors.add(PdfColors.brown);
      }

      List<pw.Dataset> pieDatasets = [];
      for (int i = 0; i < pieValues.length; i++) {
        final v = pieValues[i];
        if (v.isNaN || v.isInfinite || v <= 0) continue;
        pieDatasets.add(pw.PieDataSet(
          value: v,
          color: pieColors[i],
          legend: pieNames[i],
          legendStyle: pw.TextStyle(fontSize: 0.01, font: fontRegular),
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

      List<pw.Widget> legendRows = [];

      if (miod > 0) {
        String t = isPl
            ? '${loc.honey}: ${miod.toStringAsFixed(2).replaceAll('.', ',')} l (${(miod * 1.38).toStringAsFixed(2).replaceAll('.', ',')} kg)'
            : '${loc.honey}: ${miod.toStringAsFixed(2)} l (${(miod * 1.38).toStringAsFixed(2)} kg)';
        legendRows.add(buildLegendRow(PdfColors.amber, t));
      }
      if (pylek > 0) {
        String t = isPl
            ? '${loc.beePollen}: ${pylek.toStringAsFixed(2).replaceAll('.', ',')} l (${(pylek * 0.56).toStringAsFixed(2).replaceAll('.', ',')} kg)'
            : '${loc.beePollen}: ${pylek.toStringAsFixed(2)} l (${(pylek * 0.56).toStringAsFixed(2)} kg)';
        legendRows.add(buildLegendRow(PdfColors.orange, t));
      }
      if (pierzga > 0) {
        String t = isPl
            ? '${loc.perga}: ${pierzga.toStringAsFixed(2).replaceAll('.', ',')} l (${(pierzga * 0.56).toStringAsFixed(2).replaceAll('.', ',')} kg)'
            : '${loc.perga}: ${pierzga.toStringAsFixed(2)} l (${(pierzga * 0.56).toStringAsFixed(2)} kg)';
        legendRows.add(buildLegendRow(PdfColors.green, t));
      }
      if (wosk > 0) {
        String t = isPl
            ? '${loc.wax}: ${wosk.toStringAsFixed(2).replaceAll('.', ',')} kg'
            : '${loc.wax}: ${wosk.toStringAsFixed(2)} kg';
        legendRows.add(buildLegendRow(PdfColor.fromInt(0xFFBDB76B), t));
      }
      if (propolis > 0) {
        String t = isPl
            ? 'propolis: ${propolis.toStringAsFixed(2).replaceAll('.', ',')} kg'
            : 'propolis: ${propolis.toStringAsFixed(2)} kg';
        legendRows.add(buildLegendRow(PdfColors.brown, t));
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

      // Wiersze tabeli - sortowanie od najstarszego do najnowszego
      final zbiorySorted = zbiory.reversed.toList();

      List<pw.TableRow> tableRows = [
        pw.TableRow(children: [
          headerCell('L.p.'),
          headerCell(isPl ? 'Data' : 'Date'),
          headerCell(isPl ? 'Zasób' : 'Resource'),
          headerCell(isPl ? 'Ilość' : 'Qty'),
          headerCell(isPl ? 'Miara' : 'Unit'),
          headerCell(isPl ? 'Uwagi' : 'Notes'),
        ]),
      ];

      for (int i = 0; i < zbiorySorted.length; i++) {
        final z = zbiorySorted[i];

        tableRows.add(pw.TableRow(
          children: [
            cell('${i + 1}', alignment: pw.Alignment.center),
            cell(formatDate(z.data), alignment: pw.Alignment.center),
            cell(getZasobText(z.zasobId)),
            cell(formatValue(z.ilosc), alignment: pw.Alignment.centerRight),
            cell(getMiaraText(z.miara), alignment: pw.Alignment.center),
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
                  '${loc.hArvests} $wybranaData',
                  style: pw.TextStyle(fontSize: 18, font: fontBold),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Hey Maya  ${DateTime.now().toString().substring(0, 10)}',
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
                        width: 150,
                        height: 150,
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
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FixedColumnWidth(50),
                  4: const pw.FixedColumnWidth(35),
                  5: const pw.FlexColumnWidth(3),
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
              onPressed: () =>
                  Navigator.of(context).pushNamed(
                HarvestEditScreen.routeName,
                arguments: {'temp': 1},
              ),
            ),
            IconButton(
              icon: Icon(Icons.picture_as_pdf, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () => _generateHarvestPdf(zbiory),
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

//Statystyki zbiorów dla biezacego roku
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
                      if (miod != 0)
                         RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.black),
                              children: [
                                  globals.jezyk == 'pl_PL'
                                  ? TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po polsku
                                      text: AppLocalizations.of(context)!.honey + ': ',
                                        style: TextStyle(fontSize: 18, //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  : TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po angielsku
                                      text: AppLocalizations.of(context)!.honey + ': ',
                                        style: TextStyle(fontSize: 18,//fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),
                                  globals.jezyk == 'pl_PL'
                                  ? TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po polsku
                                      text: '${miod.toStringAsFixed(2).replaceAll('.', ',')} l',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  : TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po angielsku
                                      text: '${miod.toStringAsFixed(2)} l',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),
                                  globals.jezyk == 'pl_PL'
                                  ? TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po polsku
                                      text: ' (${(miod * 1.38).toStringAsFixed(2).replaceAll('.', ',')} kg)',
                                        style: TextStyle(fontSize: 18, //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  : TextSpan(
                                      //miód: ilość w litrach (ilość w kg) - po angielsku
                                      text: ' (${(miod * 1.38).toStringAsFixed(2)} kg)',
                                        style: TextStyle(fontSize: 18,//fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),
                                ])),

                        // globals.jezyk == 'pl_PL'
                        //   ? Text(AppLocalizations.of(context)!.honey + ': ${miod.toStringAsFixed(2).replaceAll('.', ',')} l (${(miod * 1.38).toStringAsFixed(2).replaceAll('.', ',')} kg)',
                        //     style:  TextStyle(fontSize: 16))
                        //   : Text(AppLocalizations.of(context)!.honey + ': ${miod.toStringAsFixed(2)} l (${(miod * 1.38).toStringAsFixed(2)} kg)',
                        //     style:  TextStyle(fontSize: 16)),
                      if (pylek != 0)
                         RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.black),
                              children: [
                                  globals.jezyk == 'pl_PL'
                                  ? TextSpan(
                                      text: AppLocalizations.of(context)!.beePollen + ': ${pylek.toStringAsFixed(2).replaceAll('.', ',')} l (${(pylek * 0.56).toStringAsFixed(2).replaceAll('.', ',')} kg)',
                                      style: TextStyle(fontSize: 18, //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  : TextSpan(
                                      text: AppLocalizations.of(context)!.beePollen + ': ${pylek.toStringAsFixed(2)} l (${(pylek * 0.67).toStringAsFixed(2)} kg)',
                                      style: TextStyle(fontSize: 18,//fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),

                                ])),
                      // if (pylek != 0)
                      //   globals.jezyk == 'pl_PL'
                      //     ? Text(AppLocalizations.of(context)!.beePollen + ': ${pylek.toStringAsFixed(2).replaceAll('.', ',')} l (${(pylek * 0.56).toStringAsFixed(2).replaceAll('.', ',')} kg)',
                      //       style: TextStyle(fontSize: 16))
                      //     : Text(AppLocalizations.of(context)!.beePollen + ': ${pylek.toStringAsFixed(2)} l (${(pylek * 0.67).toStringAsFixed(2)} kg)',
                      //       style: TextStyle(fontSize: 16)),
                      if (pierzga != 0)
                         RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.black),
                              children: [
                                  globals.jezyk == 'pl_PL'
                                  ? TextSpan(
                                      text: AppLocalizations.of(context)!.perga + ': ${pierzga.toStringAsFixed(2).replaceAll('.', ',')} l (${(pierzga * 0.56).toStringAsFixed(2).replaceAll('.', ',')} kg)',
                                      style: TextStyle(fontSize: 18, //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  : TextSpan(
                                      text: AppLocalizations.of(context)!.perga + ': ${pierzga.toStringAsFixed(2)} l (${(pierzga * 0.56).toStringAsFixed(2)} kg)',
                                      style: TextStyle(fontSize: 18,//fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),

                                ])),
                      // if (pierzga != 0)
                      //   globals.jezyk == 'pl_PL'
                      //     ? Text(AppLocalizations.of(context)!.perga + ': ${pierzga.toStringAsFixed(2).replaceAll('.', ',')} l (${(pierzga * 0.56).toStringAsFixed(2).replaceAll('.', ',')} kg)',
                      //       style: TextStyle(fontSize: 16))
                      //     : Text(AppLocalizations.of(context)!.perga + ': ${pierzga.toStringAsFixed(2)} l (${(pierzga * 0.56).toStringAsFixed(2)} kg)',
                      //       style: TextStyle(fontSize: 16)),
                      
                      if (wosk != 0)
                         RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.black),
                              children: [
                                  globals.jezyk == 'pl_PL'
                                  ? TextSpan(
                                      text: AppLocalizations.of(context)!.wax + ': ${wosk.toString().replaceAll('.', ',')} kg',
                                      style: TextStyle(fontSize: 18, //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  : TextSpan(
                                      text: AppLocalizations.of(context)!.wax + ': ${wosk} kg',
                                      style: TextStyle(fontSize: 18,//fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),

                                ])),
                      // if (wosk != 0)
                      //   globals.jezyk == 'pl_PL'
                      //     ? Text(AppLocalizations.of(context)!.wax + ': ${wosk.toString().replaceAll('.', ',')} kg',
                      //       style: TextStyle(fontSize: 16))
                      //     : Text(AppLocalizations.of(context)!.wax + ': ${wosk} kg',
                      //       style: TextStyle(fontSize: 16)),
                       if (propolis != 0)
                         RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.black),
                              children: [
                                  globals.jezyk == 'pl_PL'
                                  ? TextSpan(
                                      text: 'propolis: ${propolis.toString().replaceAll('.', ',')} kg',
                                      style: TextStyle(fontSize: 18, //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  : TextSpan(
                                      text: 'propolis: ${propolis} kg',
                                      style: TextStyle(fontSize: 18,//fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),

                                ])),
                      
                      // if (propolis != 0)
                      //   globals.jezyk == 'pl_PL'
                      //     ? Text('propolis: ${propolis.toString().replaceAll('.', ',')} kg',
                      //       style: TextStyle(fontSize: 16))
                      //     : Text('propolis: ${propolis} kg',
                      //       style: TextStyle(fontSize: 16)),
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
                    itemCount: zbiory.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: zbiory[i],
                      child: HarvestItem(),
                    ),
                  ),
                )
              ]));
  }
}
