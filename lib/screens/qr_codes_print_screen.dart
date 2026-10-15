import 'dart:math' show min;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:hi_bees/l10n/app_localizations.dart';
import '../globals.dart' as globals;
import '../helpers/db_helper.dart';
import '../helpers/qr_helper.dart';
import '../models/apiarys.dart';
import '../models/memory.dart';

/// Wydruk kodów QR uli (etap 1 planu pliki/plan_kody_qr.md, 15.10.2026).
/// Naklejki 6×6 cm, 3 kolumny × 4 wiersze na arkuszu A4, z liniami cięcia.
/// Wejście: ustawienia "Obsługa NFC i QR".
class QrCodesPrintScreen extends StatefulWidget {
  static const routeName = '/qr-codes-print';

  @override
  State<QrCodesPrintScreen> createState() => _QrCodesPrintScreenState();
}

class _QrCodesPrintScreenState extends State<QrCodesPrintScreen> {
  int? _pasieka;
  List<int> _ule = []; //numery uli wybranej pasieki (bez zlikwidowanych)
  final TextEditingController _od = TextEditingController();
  final TextEditingController _do = TextEditingController();
  bool _pracuje = false;

  @override
  void initState() {
    super.initState();
    _pasieka = globals.pasiekaID > 0 ? globals.pasiekaID : null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<Apiarys>(context, listen: false).fetchAndSetApiarys();
      final pasieki = Provider.of<Apiarys>(context, listen: false).items;
      if (_pasieka == null || !pasieki.any((a) => a.pasiekaNr == _pasieka)) {
        _pasieka = pasieki.isNotEmpty ? pasieki.first.pasiekaNr : null;
      }
      await _wczytajUle();
    });
  }

  @override
  void dispose() {
    _od.dispose();
    _do.dispose();
    super.dispose();
  }

  Future<void> _wczytajUle() async {
    if (_pasieka == null) {
      if (mounted) setState(() => _ule = []);
      return;
    }
    final rows = await DBHelper.getHives(_pasieka);
    final ule = rows
        .where((r) => '${r['ikona']}' != 'black') //ule zlikwidowane pominięte
        .map((r) => r['ulNr'] as int)
        .toList()
      ..sort();
    if (!mounted) return;
    setState(() {
      _ule = ule;
      _od.text = ule.isNotEmpty ? '${ule.first}' : '';
      _do.text = ule.isNotEmpty ? '${ule.last}' : '';
    });
  }

  //prefiks konta do kodu - jak przy eksporcie (kod z pamięci, nie globals.kod)
  String _prefiks() {
    final mem = Provider.of<Memory>(context, listen: false).items;
    return globals.prefiksTabel(mem.isNotEmpty ? mem[0].kod : globals.kod);
  }

  Future<void> _utworzPdf() async {
    final loc = AppLocalizations.of(context)!;
    final od = int.tryParse(_od.text) ?? 0;
    final doo = int.tryParse(_do.text) ?? 0;
    final wybrane = _ule.where((u) => u >= od && u <= doo).toList();
    if (_pasieka == null || wybrane.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.qrNoHives)),
      );
      return;
    }
    final String prefiks = _prefiks();
    final int pasieka = _pasieka!;
    setState(() => _pracuje = true);
    try {
      final fontBold = await PdfGoogleFonts.robotoBold();
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      const double cm = PdfPageFormat.cm;
      const double bok = 6 * cm; //naklejka 6×6 cm
      const int kolumny = 3, wiersze = 4, naStronie = kolumny * wiersze;

      pw.Widget naklejka(int ul) => pw.Container(
            width: bok,
            height: bok,
            //linia cięcia
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            padding: const pw.EdgeInsets.all(0.35 * cm),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(
                      errorCorrectLevel: pw.BarcodeQRCorrectionLevel.high), //brud, słońce
                  data: kodQrUla(prefiks, pasieka, ul),
                  width: 4.0 * cm,
                  height: 4.0 * cm,
                ),
                pw.SizedBox(height: 0.15 * cm),
                pw.Text('${loc.hIve} $ul',
                    style: pw.TextStyle(font: fontBold, fontSize: 18)),
                pw.Text('${loc.aPiary} $pasieka',
                    style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
          );

      final pdf = pw.Document();
      for (int s = 0; s < wybrane.length; s += naStronie) {
        final strona = wybrane.sublist(s, min(s + naStronie, wybrane.length));
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          //18 × 24 cm naklejek wyśrodkowane na A4 (21 × 29,7 cm)
          margin: const pw.EdgeInsets.symmetric(horizontal: 1.5 * cm, vertical: 2.85 * cm),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (int w = 0; w < wiersze; w++)
                if (w * kolumny < strona.length)
                  pw.Row(
                    children: [
                      for (int k = 0; k < kolumny; k++)
                        if (w * kolumny + k < strona.length) naklejka(strona[w * kolumny + k]),
                    ],
                  ),
            ],
          ),
        ));
      }
      final Uint8List bajty = await pdf.save();
      await Printing.sharePdf(
        bytes: bajty,
        filename: 'qr_pasieka${pasieka}_ule_${wybrane.first}-${wybrane.last}.pdf',
      );
    } catch (e) {
      debugPrint('Błąd PDF kodów QR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF error: $e')));
      }
    } finally {
      if (mounted) setState(() => _pracuje = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final pasieki = Provider.of<Apiarys>(context).items.map((a) => a.pasiekaNr).toSet().toList()..sort();
    final od = int.tryParse(_od.text) ?? 0;
    final doo = int.tryParse(_do.text) ?? 0;
    final ile = _ule.where((u) => u >= od && u <= doo).length;
    final arkuszy = (ile / 12).ceil();

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: Text(loc.qrPrint, style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[300], height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(loc.qrPrintDesc, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 16),
          //pasieka
          Row(
            children: [
              Expanded(child: Text(loc.nfcSelectApiary, style: const TextStyle(fontSize: 16))),
              DropdownButton<int>(
                value: pasieki.contains(_pasieka) ? _pasieka : null,
                items: [
                  for (final p in pasieki)
                    DropdownMenuItem(value: p, child: Text('${loc.aPiary} $p')),
                ],
                onChanged: (p) {
                  setState(() => _pasieka = p);
                  _wczytajUle();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          //zakres uli
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _od,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: loc.qrFromHive, border: const OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _do,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: loc.qrToHive, border: const OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ile == 0
                ? loc.qrNoHives
                : '${loc.qrLabels}: $ile  •  ${loc.qrSheets}: $arkuszy',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _pracuje || ile == 0 ? null : _utworzPdf,
              icon: _pracuje
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              label: Text(loc.qrCreatePdf),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 252, 193, 104),
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
