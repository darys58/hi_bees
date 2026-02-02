import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
import '../models/apiarys.dart';
import '../models/hives.dart';
import '../models/hive.dart';
import '../models/apiary.dart';
import '../models/infos.dart';
import '../globals.dart' as globals;
import '../screens/infos_screen.dart';

class NfcHiveSelectionDialog extends StatefulWidget {
  final String tagId;

  const NfcHiveSelectionDialog({Key? key, required this.tagId}) : super(key: key);

  @override
  State<NfcHiveSelectionDialog> createState() => _NfcHiveSelectionDialogState();
}

class _NfcHiveSelectionDialogState extends State<NfcHiveSelectionDialog> {
  int? _selectedApiary;
  String? _selectedHiveId;
  List<Hive> _availableHives = [];
  bool _isLoading = true;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    await Provider.of<Apiarys>(context, listen: false).fetchAndSetApiarys();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHivesForApiary(int apiaryNr) async {
    await Provider.of<Hives>(context, listen: false).fetchAndSetHives(apiaryNr);
    final hivesData = Provider.of<Hives>(context, listen: false);

    // Filtrowanie uli bez przypisanego tagu NFC (h3 == '0' lub puste)
    if (mounted) {
      setState(() {
        _availableHives = hivesData.items.where((hive) {
          return hive.h3 == '0' || hive.h3.isEmpty;
        }).toList();
        _selectedHiveId = null;
      });
    }
  }

  Future<void> _assignTagToHive() async {
    if (_selectedHiveId == null) return;

    // Zapisanie tagu do bazy
    await DBHelper.updateUle(_selectedHiveId!, 'h3', widget.tagId);
 
    // Znalezienie danych wybranego ula
    final selectedHive = _availableHives.firstWhere(
      (hive) => hive.id == _selectedHiveId,
    );

    // Zamkniecie dialogu
    Navigator.of(context).pop();

    // Pokazanie potwierdzenia
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.nfcTagAssigned),
      ),
    );

    // Nawigacja do ula
    globals.pasiekaID = selectedHive.pasiekaNr;
    globals.ulID = selectedHive.ulNr;
    globals.typUla = selectedHive.h2;
    globals.dataAktualnegoPrzegladu = '';

    Infos.insertInfo(
      '${DateTime.now().toString().substring(0, 10)}.${selectedHive.pasiekaNr}.${selectedHive.ulNr}.equipment.tag NFC',
      DateTime.now().toString().substring(0, 10),
      selectedHive.pasiekaNr,
      selectedHive.ulNr,
      'equipment',
      'tag NFC',
      widget.tagId,
      '',
      '',//info[0].pogoda,
      '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}',//info[0].temp,
      DateFormat('H:mm').format(DateTime.now()),
      '',
      0, //info[0].arch,
    );
      
    Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(selectedHive.pasiekaNr, selectedHive.ulNr)
      .then((_) {
      globals.odswiezBelkiUliDL = true; //odświezenie belek uli
      Navigator.of(context).pop();
    });
    
    
    
    Navigator.of(context).pushNamed(
      InfoScreen.routeName,
      arguments: selectedHive.ulNr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiarysData = Provider.of<Apiarys>(context);
    final apiaries = apiarysData.items;

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.nfcAssignTag),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown pasiek
                  Text(
                    AppLocalizations.of(context)!.nfcSelectApiary,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedApiary,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: apiaries.map((Apiary apiary) {
                      return DropdownMenuItem<int>(
                        value: apiary.pasiekaNr,
                        child: Text('${AppLocalizations.of(context)!.aPiary} ${apiary.pasiekaNr}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedApiary = value;
                      });
                      if (value != null) {
                        _loadHivesForApiary(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown uli
                  if (_selectedApiary != null) ...[
                    Text(
                      AppLocalizations.of(context)!.nfcSelectHive,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _availableHives.isEmpty
                        ? Text(
                            AppLocalizations.of(context)!.nfcNoHivesWithoutTag,
                            style: const TextStyle(color: Colors.red),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedHiveId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _availableHives.map((Hive hive) {
                              return DropdownMenuItem<String>(
                                value: hive.id,
                                child: Text('${AppLocalizations.of(context)!.hIve} ${hive.ulNr}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedHiveId = value;
                              });
                            },
                          ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: _selectedHiveId != null ? _assignTagToHive : null,
          child: Text(AppLocalizations.of(context)!.nfcAssign),
        ),
      ],
    );
  }
}
