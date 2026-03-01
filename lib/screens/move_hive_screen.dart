import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../helpers/db_helper.dart';
import '../globals.dart' as globals;
import '../models/apiarys.dart';
import '../models/hive.dart' as hive_model;
import '../models/hives.dart';
import '../models/infos.dart';

class MoveHiveScreen extends StatefulWidget {
  static const routeName = '/move_hive';

  @override
  State<MoveHiveScreen> createState() => _MoveHiveScreenState();
}

class _MoveHiveScreenState extends State<MoveHiveScreen> {
  final _formKey = GlobalKey<FormState>();
  var formatterHm = DateFormat('H:mm');

  //tryb przenoszenia: true = z historią, false = bez historii
  bool _withHistory = true;

  //źródło
  int? _srcPasieka;
  int? _srcUl;
  List<hive_model.Hive> _srcHives = [];

  //cel
  int _dstPasieka = 1;
  int _dstUl = 1;

  //walidacja
  String? _validationMessage;
  bool _isNewApiary = false;
  bool _isProcessing = false;

  Future<void> _loadHivesForApiary(int pasieka) async {
    await Provider.of<Hives>(context, listen: false).fetchAndSetHives(pasieka);
    final hivesData = Provider.of<Hives>(context, listen: false);
    setState(() {
      _srcHives = List.from(hivesData.items);
      _srcUl = null;
    });
  }

  Color _hiveStatusColor(String ikona) {
    switch (ikona) {
      case 'green':
        return const Color.fromARGB(255, 0, 255, 0);
      case 'yellow':
        return const Color.fromARGB(255, 233, 229, 1);
      case 'orange':
        return const Color.fromARGB(255, 233, 132, 1);
      case 'red':
        return const Color.fromARGB(255, 255, 0, 0);
      case 'black':
        return const Color.fromARGB(255, 0, 0, 0);
      default:
        return const Color.fromARGB(255, 100, 100, 100);
    }
  }

  Future<void> _validate() async {
    if (_srcPasieka == null || _srcUl == null) {
      setState(() {
        _validationMessage = null;
        _isNewApiary = false;
      });
      return;
    }

    //ta sama pozycja
    if (_srcPasieka == _dstPasieka && _srcUl == _dstUl) {
      setState(() {
        _validationMessage = AppLocalizations.of(context)!.cannotMoveSameLocation;
        _isNewApiary = false;
      });
      return;
    }

    //czy ul docelowy istnieje
    final exists = await DBHelper.hiveExists(_dstPasieka, _dstUl);
    if (exists) {
      setState(() {
        _validationMessage = AppLocalizations.of(context)!.hiveAlreadyExists;
        _isNewApiary = false;
      });
      return;
    }

    //czy pasieka docelowa istnieje
    final apiaryExists = await DBHelper.apiaryExists(_dstPasieka);
    setState(() {
      _validationMessage = null;
      _isNewApiary = !apiaryExists;
    });
  }

  Future<void> _performMove() async {
    if (_srcPasieka == null || _srcUl == null) return;
    if (_validationMessage != null) return;

    if (_withHistory) {
      setState(() => _isProcessing = true);
      try {
        await _moveWithHistory();
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    } else {
      //bez historii - najpierw dialog (przed spinnerem), potem operacje
      await _moveWithoutHistory();
    }
  }

  Future<void> _moveWithHistory() async {
    final srcP = _srcPasieka!;
    final srcU = _srcUl!;

    //jeśli pasieka docelowa nie istnieje - utwórz
    if (_isNewApiary) {
      await Apiarys.insertApiary(
        '$_dstPasieka',
        _dstPasieka,
        0,
        DateTime.now().toString().substring(0, 10),
        'green',
        '??',
      );
    }

    //przeniesienie z historią
    await DBHelper.moveHiveWithHistory(srcP, srcU, _dstPasieka, _dstUl);

    //wpisy info o przeniesieniu we wszystkich kategoriach (nowy ul)
    final today = DateTime.now().toString().substring(0, 10);
    final timeNow = formatterHm.format(DateTime.now());
    final loc = AppLocalizations.of(context)!;
    final parametr = loc.hiveTransfer;
    final uwagi = loc.movedFrom(srcP, srcU);
    final temp = '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}';

    //inspection
    await Infos.insertInfo(
      '$today.$_dstPasieka.$_dstUl.inspection.$parametr',
      today, _dstPasieka, _dstUl, 'inspection',
      parametr, '', '', '', temp, timeNow, uwagi, 0,
    );
    //equipment
    await Infos.insertInfo(
      '$today.$_dstPasieka.$_dstUl.equipment.$parametr',
      today, _dstPasieka, _dstUl, 'equipment',
      parametr, '', '', '', temp, timeNow, uwagi, 0,
    );
    //colony
    await Infos.insertInfo(
      '$today.$_dstPasieka.$_dstUl.colony.$parametr',
      today, _dstPasieka, _dstUl, 'colony',
      parametr, '', '', '', temp, timeNow, uwagi, 0,
    );
    //queen - z ID matki
    int? matkaIdUla;
    final queenData = await DBHelper.getQueenID(_dstPasieka, _dstUl);
    if (queenData.isNotEmpty) {
      matkaIdUla = queenData[0]['id'] as int;
    }
    await Infos.insertInfo(
      '$today.$_dstPasieka.$_dstUl.queen.$parametr',
      today, _dstPasieka, _dstUl, 'queen',
      parametr, '', '', '${matkaIdUla ?? ''}', temp, timeNow, uwagi, 0,
    );
    //harvest
    await Infos.insertInfo(
      '$today.$_dstPasieka.$_dstUl.harvest.$parametr',
      today, _dstPasieka, _dstUl, 'harvest',
      parametr, '', '', '', temp, timeNow, uwagi, 0,
    );
    //feeding
    await Infos.insertInfo(
      '$today.$_dstPasieka.$_dstUl.feeding.$parametr',
      today, _dstPasieka, _dstUl, 'feeding',
      parametr, '', '', '', temp, timeNow, uwagi, 0,
    );
    //treatment
    await Infos.insertInfo(
      '$today.$_dstPasieka.$_dstUl.treatment.$parametr',
      today, _dstPasieka, _dstUl, 'treatment',
      parametr, '', '', '', temp, timeNow, uwagi, 0,
    );

    //aktualizacja ileUli w pasiece źródłowej
    final srcCount = await DBHelper.getHiveCount(srcP);
    if (srcCount == 0) {
      await DBHelper.deletePasieki(srcP);
    } else {
      await DBHelper.updateIleUli(srcP, srcCount);
    }

    //aktualizacja ileUli w pasiece docelowej
    final dstCount = await DBHelper.getHiveCount(_dstPasieka);
    await DBHelper.updateIleUli(_dstPasieka, dstCount);

    //odświeżenie providerów i powrót
    if (mounted) {
      await Provider.of<Apiarys>(context, listen: false).fetchAndSetApiarys();

      String msg = AppLocalizations.of(context)!.hiveMoved;
      if (srcCount == 0) {
        msg += '. ${AppLocalizations.of(context)!.emptyApiaryDeleted(srcP)}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop();
    }
  }

  Future<void> _moveWithoutHistory() async {
    final srcP = _srcPasieka!;
    final srcU = _srcUl!;

    //najpierw dialog: co zrobić ze starym ulem
    final result = await _showOldHiveDialog(srcP, srcU);

    //anulowanie - wycofanie z przenoszenia
    if (result == null) {
      return;
    }

    setState(() => _isProcessing = true);

    try {

    //pobranie danych starego ula
    await Provider.of<Hives>(context, listen: false).fetchAndSetHives(srcP);
    final hivesData = Provider.of<Hives>(context, listen: false);
    final oldHive = hivesData.items.firstWhere((h) => h.ulNr == srcU);

    //jeśli pasieka docelowa nie istnieje - utwórz
    if (_isNewApiary) {
      await Apiarys.insertApiary(
        '$_dstPasieka',
        _dstPasieka,
        0,
        DateTime.now().toString().substring(0, 10),
        'green',
        '??',
      );
    }

    final today = DateTime.now().toString().substring(0, 10);
    final uwagi = AppLocalizations.of(context)!.movedFrom(srcP, srcU);

    //utworzenie nowego ula z parametrami technicznymi
    await Hives.insertHive(
      '$_dstPasieka.$_dstUl',
      _dstPasieka,
      _dstUl,
      today,
      'green',
      oldHive.ramek,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      '', '', '', '', '',
      oldHive.matka1,
      oldHive.matka2,
      oldHive.matka3,
      oldHive.matka4,
      oldHive.matka5,
      oldHive.h1, //rodzaj
      oldHive.h2, //typ
      '', //h3 tag NFC
      0,
    );

    //rekord info/equipment dla nowego ula
    await Infos.insertInfo(
      '$today.$_dstPasieka.$_dstUl.equipment.${AppLocalizations.of(context)!.numberOfFrame} = ',
      today,
      _dstPasieka,
      _dstUl,
      'equipment',
      '${AppLocalizations.of(context)!.numberOfFrame} = ',
      '${oldHive.ramek}',
      oldHive.h2, //typ ula
      oldHive.h1, //rodzaj ula
      '',
      formatterHm.format(DateTime.now()),
      uwagi,
      0,
    );

    //przeniesienie matek
    await DBHelper.moveQueens(srcP, srcU, _dstPasieka, _dstUl);

    //wyzerowanie matka1-5 w starym ulu
    await DBHelper.updateUleMatka1('$srcP.$srcU', '');
    await DBHelper.updateUleMatka2('$srcP.$srcU', '');
    await DBHelper.updateUleMatka3('$srcP.$srcU', '');
    await DBHelper.updateUleMatka4('$srcP.$srcU', '');
    await DBHelper.updateUleMatka5('$srcP.$srcU', '');

    //aktualizacja ileUli w pasiece docelowej
    final dstCount = await DBHelper.getHiveCount(_dstPasieka);
    await DBHelper.updateIleUli(_dstPasieka, dstCount);

    //czynności dotyczące starego ula
    if (result == 'liquidate') {
      //czarna ikona = likwidacja
      await DBHelper.updateUle('$srcP.$srcU', 'ikona', 'black');

      //wpisy o likwidacji we wszystkich kategoriach
      final timeNow = formatterHm.format(DateTime.now());
      final loc = AppLocalizations.of(context)!;
      final parametr = loc.hiveLiquidation;
      final uwagiOld = loc.movedTo(_dstPasieka, _dstUl);
      final temp = '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}';

      //inspection
      await Infos.insertInfo(
        '$today.$srcP.$srcU.inspection.$parametr',
        today, srcP, srcU, 'inspection',
        parametr, '', '', '', temp, timeNow, uwagiOld, 0,
      );
      //equipment
      await Infos.insertInfo(
        '$today.$srcP.$srcU.equipment.$parametr',
        today, srcP, srcU, 'equipment',
        parametr, '', '', '', temp, timeNow, uwagiOld, 0,
      );
      //colony
      await Infos.insertInfo(
        '$today.$srcP.$srcU.colony.$parametr',
        today, srcP, srcU, 'colony',
        parametr, '', '', '', temp, timeNow, uwagiOld, 0,
      );
      //queen - z ID matki
      int? matkaIdUla;
      final queenData = await DBHelper.getQueenID(srcP, srcU);
      if (queenData.isNotEmpty) {
        matkaIdUla = queenData[0]['id'] as int;
      }
      await Infos.insertInfo(
        '$today.$srcP.$srcU.queen.$parametr',
        today, srcP, srcU, 'queen',
        parametr, '', '', '${matkaIdUla ?? ''}', temp, timeNow, uwagiOld, 0,
      );
      //harvest
      await Infos.insertInfo(
        '$today.$srcP.$srcU.harvest.$parametr',
        today, srcP, srcU, 'harvest',
        parametr, '', '', '', temp, timeNow, uwagiOld, 0,
      );
      //feeding
      await Infos.insertInfo(
        '$today.$srcP.$srcU.feeding.$parametr',
        today, srcP, srcU, 'feeding',
        parametr, '', '', '', temp, timeNow, uwagiOld, 0,
      );
      //treatment
      await Infos.insertInfo(
        '$today.$srcP.$srcU.treatment.$parametr',
        today, srcP, srcU, 'treatment',
        parametr, '', '', '', temp, timeNow, uwagiOld, 0,
      );
    } else if (result == 'delete') {
      //kaskadowe kasowanie
      final photoPaths = await DBHelper.deleteHiveCascade(srcP, srcU);
      for (final path in photoPaths) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      //przeliczenie uli w pasiece źródłowej
      final srcCount = await DBHelper.getHiveCount(srcP);
      if (srcCount == 0) {
        await DBHelper.deletePasieki(srcP);
      } else {
        await DBHelper.updateIleUli(srcP, srcCount);
      }
    }
    //leave = nic nie robimy ze starym ulem

    //odświeżenie providerów i powrót
    if (mounted) {
      await Provider.of<Apiarys>(context, listen: false).fetchAndSetApiarys();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.hiveMoved)),
      );
      Navigator.of(context).pop();
    }

    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showOldHiveDialog(int srcP, int srcU) async {
    final loc = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(loc.whatToDoWithOldHive),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${loc.aPiary} $srcP / ${loc.hive} $srcU',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                '${loc.leaveHive} - ${loc.leaveHiveDesc}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              SizedBox(height: 8),
              Text(
                '${loc.liquidateHive} - ${loc.liquidateHiveDesc}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              SizedBox(height: 8),
              Text(
                '${loc.deleteOldHive} - ${loc.deleteOldHiveDesc}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('leave'),
            child: Text(loc.leaveHive),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('liquidate'),
            child: Text(loc.liquidateHive),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('delete'),
            child: Text(
              loc.deleteOldHive,
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(loc.cancel),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final apiarysData = Provider.of<Apiarys>(context);
    final apiaryList = apiarysData.items;

    // po usunięciu pasieki źródłowej resetuj wybór
    if (_srcPasieka != null &&
        !apiaryList.any((a) => a.pasiekaNr == _srcPasieka)) {
      _srcPasieka = null;
      _srcUl = null;
      _srcHives = [];
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          AppLocalizations.of(context)!.moveHive,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: Colors.grey[300], height: 1.0),
        ),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.moving),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //tryb przenoszenia
                      Text(
                        _withHistory
                            ? AppLocalizations.of(context)!.moveWithHistory
                            : AppLocalizations.of(context)!.moveWithoutHistory,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _withHistory
                            ? AppLocalizations.of(context)!.moveWithHistoryDesc
                            : AppLocalizations.of(context)!.moveWithoutHistoryDesc,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ToggleButtons(
                              isSelected: [_withHistory, !_withHistory],
                              onPressed: (index) {
                                setState(() => _withHistory = index == 0);
                              },
                              borderRadius: BorderRadius.circular(8),
                              selectedColor: Colors.black,
                              fillColor: Theme.of(context).primaryColor,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(AppLocalizations.of(context)!.moveWithHistory),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(AppLocalizations.of(context)!.moveWithoutHistory),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 25),

                      //ŹRÓDŁO
                      Text(
                        AppLocalizations.of(context)!.sourceApiary,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.selectApiary,
                          border: OutlineInputBorder(),
                        ),
                        value: _srcPasieka,
                        items: apiaryList
                            .map((a) => DropdownMenuItem<int>(
                                  value: a.pasiekaNr,
                                  child: Text('${AppLocalizations.of(context)!.aPiary} ${a.pasiekaNr}'),
                                ))
                            .toList(),
                        onChanged: (val) async {
                          if (val == null) return;
                          setState(() => _srcPasieka = val);
                          await _loadHivesForApiary(val);
                          _validate();
                        },
                      ),

                      SizedBox(height: 15),
                      Text(
                        AppLocalizations.of(context)!.selectHive,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      if (_srcPasieka != null && _srcHives.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _srcHives.map((hive) {
                              final isSelected = _srcUl == hive.ulNr;
                              final statusColor = _hiveStatusColor(hive.ikona);
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _srcUl = hive.ulNr);
                                    _validate();
                                  },
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.hive,
                                          color: statusColor,
                                          size: 28,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${hive.ulNr}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      else if (_srcPasieka != null && _srcHives.isEmpty)
                        Text(
                          '-',
                          style: TextStyle(color: Colors.grey),
                        ),

                      SizedBox(height: 25),

                      //CEL
                      Text(
                        AppLocalizations.of(context)!.destApiaryNr,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        initialValue: _dstPasieka.toString(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.destApiaryNr,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            _dstPasieka = parsed;
                            _validate();
                          }
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) return AppLocalizations.of(context)!.destApiaryNr;
                          final parsed = int.tryParse(val);
                          if (parsed == null || parsed <= 0) return AppLocalizations.of(context)!.destApiaryNr;
                          return null;
                        },
                      ),

                      SizedBox(height: 15),
                      TextFormField(
                        initialValue: _dstUl.toString(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.destHiveNr,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            _dstUl = parsed;
                            _validate();
                          }
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) return AppLocalizations.of(context)!.destHiveNr;
                          final parsed = int.tryParse(val);
                          if (parsed == null || parsed <= 0) return AppLocalizations.of(context)!.destHiveNr;
                          return null;
                        },
                      ),

                      SizedBox(height: 10),

                      //komunikaty walidacji
                      if (_validationMessage != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            _validationMessage!,
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),

                      if (_isNewApiary && _validationMessage == null)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            AppLocalizations.of(context)!.newApiaryWillBeCreated,
                            style: TextStyle(color: Colors.blue, fontSize: 13),
                          ),
                        ),

                      SizedBox(height: 30),

                      //przycisk PRZENIEŚ
                      Center(
                        child: MaterialButton(
                          height: 50,
                          shape: StadiumBorder(
                            side: BorderSide(color: Color.fromARGB(255, 162, 103, 0)),
                          ),
                          onPressed: (_srcPasieka == null || _srcUl == null || _validationMessage != null)
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    _performMove();
                                  }
                                },
                          color: Theme.of(context).primaryColor,
                          textColor: Colors.black,
                          disabledColor: Colors.grey,
                          disabledTextColor: Colors.white,
                          child: Text('   ${AppLocalizations.of(context)!.move}   '),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
