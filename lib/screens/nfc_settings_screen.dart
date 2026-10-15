import 'package:flutter/material.dart';
import 'package:hi_bees/l10n/app_localizations.dart';
import '../globals.dart' as globals;
import '../helpers/db_helper.dart';
import 'qr_codes_print_screen.dart';

class NfcSettingsScreen extends StatefulWidget {
  static const routeName = '/nfc-settings';

  @override
  State<NfcSettingsScreen> createState() => _NfcSettingsScreenState();
}

class _NfcSettingsScreenState extends State<NfcSettingsScreen> {
  late String _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = globals.nfcMode;
  }

  void _onModeChanged(String value) {
    setState(() {
      _selectedMode = value;
    });
    globals.nfcMode = value;
    DBHelper.updateDodatki1('c', globals.zapisTrybuNfc()); //z przyrostkiem czytnika QR
  }

  //czytnik na stronie startowej: tag NFC albo kod QR (etap 2 kodów QR, 15.10.2026)
  void _onReaderChanged(String value) {
    setState(() => globals.czytnikUla = value);
    DBHelper.updateDodatki1('c', globals.zapisTrybuNfc());
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          AppLocalizations.of(context)!.nfcSettings,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: ListView(
        children: <Widget>[
          //wybór czytnika - przycisk na stronie startowej uruchamia wybrany
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(AppLocalizations.of(context)!.qrReaderTitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          RadioListTile<String>(
            title: Text(AppLocalizations.of(context)!.qrReaderNfc),
            value: 'nfc',
            groupValue: globals.czytnikUla,
            onChanged: (value) => _onReaderChanged(value!),
          ),
          RadioListTile<String>(
            title: Text(AppLocalizations.of(context)!.qrReaderQr),
            subtitle: Text(AppLocalizations.of(context)!.qrReaderQrDesc, style: const TextStyle(fontSize: 12)),
            value: 'qr',
            groupValue: globals.czytnikUla,
            onChanged: (value) => _onReaderChanged(value!),
          ),
          Divider(height: 1),
          RadioListTile<String>(
            title: Text(AppLocalizations.of(context)!.nfcModeOff),
            subtitle: Text(
              AppLocalizations.of(context)!.nfcModeOffDesc,
              style: TextStyle(fontSize: 12),
            ),
            value: 'off',
            groupValue: _selectedMode,
            onChanged: (value) => _onModeChanged(value!),
          ),
          Divider(height: 1),
          RadioListTile<String>(
            title: Text(AppLocalizations.of(context)!.nfcModeInfo),
            subtitle: Text(
              AppLocalizations.of(context)!.nfcModeInfoDesc,
              style: TextStyle(fontSize: 12),
            ),
            value: 'info',
            groupValue: _selectedMode,
            onChanged: (value) => _onModeChanged(value!),
          ),
          Divider(height: 1),
          RadioListTile<String>(
            title: Text(AppLocalizations.of(context)!.nfcModeSummary),
            subtitle: Text(
              AppLocalizations.of(context)!.nfcModeSummaryDesc,
              style: TextStyle(fontSize: 12),
            ),
            value: 'summary',
            groupValue: _selectedMode,
            onChanged: (value) => _onModeChanged(value!),
          ),
          //KODY QR (15.10.2026, plan pliki/plan_kody_qr.md) - etap 1: wydruk;
          //wybór czytnika NFC / QR dojdzie w etapie 2 (odczyt)
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text(AppLocalizations.of(context)!.qrSection,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: Text(AppLocalizations.of(context)!.qrPrint),
            subtitle: Text(AppLocalizations.of(context)!.qrPrintDesc, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(QrCodesPrintScreen.routeName),
          ),
        ],
      ),
    );
  }
}
