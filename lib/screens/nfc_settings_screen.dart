import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;
import '../helpers/db_helper.dart';

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
    DBHelper.updateDodatki1('c', value);
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
        ],
      ),
    );
  }
}
