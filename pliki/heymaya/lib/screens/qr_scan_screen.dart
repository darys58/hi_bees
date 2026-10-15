import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:heymaya/l10n/app_localizations.dart';
import '../globals.dart' as globals;
import '../helpers/db_helper.dart';
import '../helpers/qr_helper.dart';
import '../models/memory.dart';

/// Odczytany kod QR -> wiersz ula z tabeli "ule" (Map) albo komunikat (String).
/// Wspólne dla skanera w trybie ręcznym i w sterowaniu głosem (etap 3, 15.10.2026).
Future<Object> sprawdzKodQrUla(BuildContext context, String tresc) async {
  final loc = AppLocalizations.of(context)!;
  final kod = rozbierzKodQr(tresc);
  if (kod == null) return loc.qrNotHiveCode;
  //prefiks konta - jak przy wydruku kodów (kod z pamięci, nie globals.kod)
  final mem = Provider.of<Memory>(context, listen: false).items;
  final prefiks = globals.prefiksTabel(mem.isNotEmpty ? mem[0].kod : globals.kod);
  if (kod.prefiksKonta != prefiks) return loc.qrOtherAccount;
  if (!globals.pasiekaWZakresie(kod.pasieka)) return loc.voiceNfcHiveOutOfRange;
  final ule = await DBHelper.getHives(kod.pasieka);
  final ul = ule.where((r) => r['ulNr'] == kod.ul).toList();
  if (ul.isEmpty) return '${loc.qrHiveNotFound} (${loc.aPiary} ${kod.pasieka}, ${loc.hIve} ${kod.ul})';
  return Map<String, dynamic>.from(ul.first);
}

/// Skaner kodu QR ula (etap 2 planu pliki/plan_kody_qr.md, 15.10.2026).
/// Po odczycie poprawnego kodu zamyka się i ZWRACA wiersz ula z tabeli "ule"
/// (jak NFC: pasiekaNr, ulNr, h2) - otwiera go wołający przez NfcHelper.otworzUl,
/// tą samą ścieżką co tag NFC. Kod obcy / z innego konta / ul nieistniejący /
/// pasieka poza zakresem - komunikat na dole i skanowanie dalej.
class QrScanScreen extends StatefulWidget {
  static const routeName = '/qr-scan';

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _kontroler = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _sprawdzam = false;
  String? _komunikat;

  @override
  void dispose() {
    _kontroler.dispose();
    super.dispose();
  }

  Future<void> _odczyt(BarcodeCapture odczyt) async {
    if (_sprawdzam) return;
    final String? tresc = odczyt.barcodes.isEmpty ? null : odczyt.barcodes.first.rawValue;
    if (tresc == null || tresc.isEmpty) return;
    _sprawdzam = true;
    final wynik = await sprawdzKodQrUla(context, tresc);
    if (!mounted) return;
    if (wynik is Map<String, dynamic>) {
      Navigator.of(context).pop(wynik);
      return;
    }
    setState(() => _komunikat = wynik as String);
    //chwila na przeczytanie komunikatu, potem skanowanie dalej
    await Future.delayed(const Duration(seconds: 2));
    _sprawdzam = false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final double ramka = MediaQuery.of(context).size.width * 0.65;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: Text(loc.qrScanTitle, style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
        actions: [
          //latarka - kod w cieniu daszka albo o zmierzchu
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _kontroler.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _kontroler, onDetect: _odczyt),
          //celownik
          Center(
            child: Container(
              width: ramka,
              height: ramka,
              decoration: BoxDecoration(
                border: Border.all(color: const Color.fromARGB(255, 252, 193, 104), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          //podpowiedź albo komunikat o złym kodzie
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _komunikat == null ? Colors.black54 : const Color.fromARGB(220, 183, 28, 28),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _komunikat ?? loc.qrScanHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
