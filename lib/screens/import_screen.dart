import 'package:flutter/material.dart';
import 'package:hi_bees/helpers/db_helper.dart';
//import 'package:hi_bees/models/purchase.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../all_translations.dart';
// import 'languages.dart';
// import 'orders_screen.dart';
// import 'specials_screen.dart';
// import 'settings_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; //blokowanie ekranu
import 'package:intl/intl.dart';
import '../globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a
import 'dart:math'; //min()
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/frames.dart';
import '../models/infos.dart';
import '../models/hives.dart';
import '../models/apiarys.dart';
import '../models/memory.dart';
import '../models/dodatki1.dart';
import '../models/harvest.dart';
import '../models/sale.dart';
import '../models/queen.dart';
import '../models/purchase.dart';
import '../models/note.dart';
import '../models/photo.dart';
import 'dart:io';
import '../screens/apiarys_screen.dart';

class ImportScreen extends StatefulWidget {
  static const routeName = '/import';

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isInit = true;
  bool isSwitched = false;
  var now = new DateTime.now();
  var formatter = new DateFormat('yyyy-MM-dd');
  //int biezacyRok = int.parse(DateTime.now().toString().substring(0, 4));
  String biezacyRok = DateTime.now().toString().substring(0, 4); //aktualny rok
  //var formatterHm = new DateFormat('H:mm');
  String formattedDate = '';
  int iloscDoWyslania = 0;
  //String komunikat = 'komunikat';
  // bool wyborDanych = false;
  // bool archNotatki = true;
  // bool archZbiory = true;
  // bool archZakupy = true;
  // bool archSprzedaz = true;
  // bool archInfo = true;
  // bool archRamki = true;
  // bool archOstatniRok = true;
  Map<String, String> _nfcTags = {}; // Przechowywanie tagow NFC podczas importu
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<String> _progressLabelNotifier = ValueNotifier<String>('');
  int _completedSteps = 0;
  int _totalSteps = 1;
  
  
  @override
  void didChangeDependencies() {
    //print('import_screen - didChangeDependencies');

    //print('import_screen - _isInit = $_isInit');

    if (_isInit) {
      Provider.of<Dodatki1>(context, listen: false)
          .fetchAndSetDodatki1()
          .then((_) {
        //uzyskanie dostępu do danych z tabeli dodatki1
        final dod1Data = Provider.of<Dodatki1>(context, listen: false);
        final dod1 = dod1Data.items;
        if (dod1[0].a == 'true') {
          //a - przełącznik eksportu danych
          setState(() {
            isSwitched = true;
          });
        } else {
          setState(() {
            isSwitched = false;
          });
        }
      });
    }
    _isInit = false;
    //Provider.of<Rests>(context, listen: false).fetchAndSetRests(); //dostawca restauracji
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    _progressLabelNotifier.dispose();
    super.dispose();
  }

  void _updateProgress(String label) {
    _completedSteps++;
    _progressNotifier.value = _completedSteps / _totalSteps;
    _progressLabelNotifier.value = label;
  }

  //sub-progress wewnątrz bieżącego kroku (fraction 0.0-1.0)
  void _setSubProgress(double fraction, String label) {
    _progressNotifier.value = (_completedSteps + fraction.clamp(0.0, 1.0)) / _totalSteps;
    _progressLabelNotifier.value = label;
  }

  //dialog z postępem operacji (import, export all, export new)
  showProgressDialog(BuildContext context, String title, int totalSteps) {
    WakelockPlus.enable();
    _completedSteps = 0;
    _totalSteps = totalSteps;
    _progressNotifier.value = 0.0;
    _progressLabelNotifier.value = '';
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: _progressNotifier,
                builder: (context, progress, _) {
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        minHeight: 10,
                      ),
                      SizedBox(height: 8),
                      Text('${(progress * 100).toInt()}%'),
                    ],
                  );
                },
              ),
              SizedBox(height: 4),
              ValueListenableBuilder<String>(
                valueListenable: _progressLabelNotifier,
                builder: (context, label, _) {
                  return Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  //--- Wersja 3: Sekwencyjny eksport z paczkami ---
  static const int _batchSize = 500;

  //generyczne wysyłanie JSON do serwera - zwraca true jeśli sukces
  Future<bool> _wyslijBatch(String jsonData) async {
    try {
      final response = await http.post(
        Uri.parse('https://darys.pl/cbt_hi_backup_v8.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonData,
      );
      if (response.statusCode >= 200 && response.statusCode <= 400) {
        final odpPost = json.decode(response.body);
        return odpPost['success'] == 'ok';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  //wysyłanie jednego zdjęcia (wersja await)
  Future<bool> _wyslijJednoZdjecieAwait(dynamic photo, String prefix) async {
    String base64Data = '';
    try {
      final file = File(photo.sciezka);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        base64Data = base64Encode(bytes);
      }
    } catch (e) {
      //plik nie istnieje - wysyłamy same metadane
    }
    final fileName = photo.sciezka.split('/').last;
    String jsonData = '{"zdjecia":[';
    jsonData += '{"id": "${photo.id}",';
    jsonData += '"data": "${photo.data}",';
    jsonData += '"czas": "${photo.czas}",';
    jsonData += '"pasiekaNr": ${photo.pasiekaNr},';
    jsonData += '"ulNr": ${photo.ulNr},';
    jsonData += '"sciezka": "$fileName",';
    jsonData += '"uwagi": "${photo.uwagi}",';
    jsonData += '"arch": ${photo.arch},';
    jsonData += '"base64": "$base64Data"}';
    jsonData += '],"total":1, "tabela":"${prefix}_zdjecia"}';
    bool ok = await _wyslijBatch(jsonData);
    if (ok) {
      DBHelper.updatePhotoArch(photo.id);
    }
    return ok;
  }

  //budowanie JSON dla notatek
  String _buildNotatkiJson(List notatki, String tabela) {
    String jsonData = '{"notatki":[';
    for (int i = 0; i < notatki.length; i++) {
      jsonData += '{"id": "${notatki[i].id}",';
      jsonData += '"data": "${notatki[i].data}",';
      jsonData += '"tytul": "${notatki[i].tytul}",';
      jsonData += '"pasiekaNr": ${notatki[i].pasiekaNr},';
      jsonData += '"ulNr": ${notatki[i].ulNr},';
      jsonData += '"notatka": "${notatki[i].notatka}",';
      jsonData += '"status": ${notatki[i].status},';
      jsonData += '"priorytet": "${notatki[i].priorytet}",';
      jsonData += '"pole1": "${notatki[i].pole1}",';
      jsonData += '"pole2": "${notatki[i].pole2}",';
      jsonData += '"pole3": "${notatki[i].pole3}",';
      jsonData += '"uwagi": "${notatki[i].uwagi}",';
      jsonData += '"arch": ${notatki[i].arch}}';
      if (i < notatki.length - 1) jsonData += ',';
    }
    jsonData += '],"total":${notatki.length}, "tabela":"$tabela"}';
    return jsonData;
  }

  //budowanie JSON dla zakupów
  String _buildZakupyJson(List zakupy, String tabela) {
    String jsonData = '{"zakupy":[';
    for (int i = 0; i < zakupy.length; i++) {
      jsonData += '{"id": "${zakupy[i].id}",';
      jsonData += '"data": "${zakupy[i].data}",';
      jsonData += '"pasiekaNr": ${zakupy[i].pasiekaNr},';
      jsonData += '"nazwa": "${zakupy[i].nazwa}",';
      jsonData += '"kategoriaId": ${zakupy[i].kategoriaId},';
      jsonData += '"ilosc": ${zakupy[i].ilosc},';
      jsonData += '"miara": ${zakupy[i].miara},';
      jsonData += '"cena": ${zakupy[i].cena},';
      jsonData += '"wartosc": ${zakupy[i].wartosc},';
      jsonData += '"waluta": ${zakupy[i].waluta},';
      jsonData += '"uwagi": "${zakupy[i].uwagi}",';
      jsonData += '"arch": ${zakupy[i].arch}}';
      if (i < zakupy.length - 1) jsonData += ',';
    }
    jsonData += '],"total":${zakupy.length}, "tabela":"$tabela"}';
    return jsonData;
  }

  //budowanie JSON dla sprzedaży
  String _buildSprzedazJson(List sprzedaz, String tabela) {
    String jsonData = '{"sprzedaz":[';
    for (int i = 0; i < sprzedaz.length; i++) {
      jsonData += '{"id": "${sprzedaz[i].id}",';
      jsonData += '"data": "${sprzedaz[i].data}",';
      jsonData += '"pasiekaNr": ${sprzedaz[i].pasiekaNr},';
      jsonData += '"nazwa": "${sprzedaz[i].nazwa}",';
      jsonData += '"kategoriaId": ${sprzedaz[i].kategoriaId},';
      jsonData += '"ilosc": ${sprzedaz[i].ilosc},';
      jsonData += '"miara": ${sprzedaz[i].miara},';
      jsonData += '"cena": ${sprzedaz[i].cena},';
      jsonData += '"wartosc": ${sprzedaz[i].wartosc},';
      jsonData += '"waluta": ${sprzedaz[i].waluta},';
      jsonData += '"uwagi": "${sprzedaz[i].uwagi}",';
      jsonData += '"arch": ${sprzedaz[i].arch}}';
      if (i < sprzedaz.length - 1) jsonData += ',';
    }
    jsonData += '],"total":${sprzedaz.length}, "tabela":"$tabela"}';
    return jsonData;
  }

  //budowanie JSON dla matek
  String _buildMatkiJson(List matki, String tabela) {
    String jsonData = '{"matki":[';
    for (int i = 0; i < matki.length; i++) {
      jsonData += '{"id": "${matki[i].id}",';
      jsonData += '"data": "${matki[i].data}",';
      jsonData += '"zrodlo": "${matki[i].zrodlo}",';
      jsonData += '"rasa": "${matki[i].rasa}",';
      jsonData += '"linia": "${matki[i].linia}",';
      jsonData += '"znak": "${matki[i].znak}",';
      jsonData += '"napis": "${matki[i].napis}",';
      jsonData += '"uwagi": "${matki[i].uwagi}",';
      jsonData += '"pasieka": ${matki[i].pasieka},';
      jsonData += '"ul": ${matki[i].ul},';
      jsonData += '"dataStraty": "${matki[i].dataStraty}",';
      jsonData += '"a": "${matki[i].a}",';
      jsonData += '"b": "${matki[i].b}",';
      jsonData += '"c": "${matki[i].c}",';
      jsonData += '"arch": ${matki[i].arch}}';
      if (i < matki.length - 1) jsonData += ',';
    }
    jsonData += '],"total":${matki.length}, "tabela":"$tabela"}';
    return jsonData;
  }

  //budowanie JSON dla zbiorów
  String _buildZbioryJson(List zbiory, String tabela) {
    String jsonData = '{"zbiory":[';
    for (int i = 0; i < zbiory.length; i++) {
      jsonData += '{"id": "${zbiory[i].id}",';
      jsonData += '"data": "${zbiory[i].data}",';
      jsonData += '"pasiekaNr": ${zbiory[i].pasiekaNr},';
      jsonData += '"zasobId": ${zbiory[i].zasobId},';
      jsonData += '"ilosc": "${zbiory[i].ilosc}",';
      jsonData += '"miara": "${zbiory[i].miara}",';
      jsonData += '"uwagi": "${zbiory[i].uwagi}",';
      jsonData += '"g": "${zbiory[i].g}",';
      jsonData += '"h": "${zbiory[i].h}",';
      jsonData += '"arch": ${zbiory[i].arch}}';
      if (i < zbiory.length - 1) jsonData += ',';
    }
    jsonData += '],"total":${zbiory.length}, "tabela":"$tabela"}';
    return jsonData;
  }

  //budowanie JSON dla info
  String _buildInfoJson(List info, String tabela) {
    String jsonData = '{"info":[';
    for (int i = 0; i < info.length; i++) {
      jsonData += '{"id": "${info[i].id}",';
      jsonData += '"data": "${info[i].data}",';
      jsonData += '"pasiekaNr": ${info[i].pasiekaNr},';
      jsonData += '"ulNr": ${info[i].ulNr},';
      jsonData += '"kategoria": "${info[i].kategoria}",';
      jsonData += '"parametr": "${info[i].parametr}",';
      jsonData += '"wartosc": "${info[i].wartosc}",';
      jsonData += '"miara": "${info[i].miara}",';
      jsonData += '"pogoda": "${info[i].pogoda}",';
      jsonData += '"temp": "${info[i].temp}",';
      jsonData += '"czas": "${info[i].czas}",';
      jsonData += '"uwagi": "${info[i].uwagi}",';
      jsonData += '"arch": ${info[i].arch}}';
      if (i < info.length - 1) jsonData += ',';
    }
    jsonData += '],"total":${info.length}, "tabela":"$tabela"}';
    return jsonData;
  }

  //budowanie JSON dla ramek
  String _buildRamkiJson(List ramki, String tabela) {
    String jsonData = '{"ramka":[';
    for (int i = 0; i < ramki.length; i++) {
      jsonData += '{"id": "${ramki[i].id}",';
      jsonData += '"data": "${ramki[i].data}",';
      jsonData += '"pasiekaNr": ${ramki[i].pasiekaNr},';
      jsonData += '"ulNr": ${ramki[i].ulNr},';
      jsonData += '"korpusNr": ${ramki[i].korpusNr},';
      jsonData += '"typ": ${ramki[i].typ},';
      jsonData += '"ramkaNr": ${ramki[i].ramkaNr},';
      jsonData += '"ramkaNrPo": ${ramki[i].ramkaNrPo},';
      jsonData += '"rozmiar": ${ramki[i].rozmiar},';
      jsonData += '"strona": ${ramki[i].strona},';
      jsonData += '"zasob": ${ramki[i].zasob},';
      jsonData += '"wartosc": "${ramki[i].wartosc}",';
      jsonData += '"arch": ${ramki[i].arch}}';
      if (i < ramki.length - 1) jsonData += ',';
    }
    jsonData += '],"total":${ramki.length}, "tabela":"$tabela"}';
    return jsonData;
  }

  //oznaczanie arch=1 po eksporcie
  Future<void> _markArchAll() async {
    //notatki
    await Provider.of<Notes>(context, listen: false).fetchAndSetNotatkiToArch();
    final notatkiArch = Provider.of<Notes>(context, listen: false).items;
    for (var n in notatkiArch) { DBHelper.updateNotatkiArch(n.id); }
    //zakupy
    await Provider.of<Purchases>(context, listen: false).fetchAndSetZakupyToArch();
    final zakupyArch = Provider.of<Purchases>(context, listen: false).items;
    for (var z in zakupyArch) { DBHelper.updateZakupyArch(z.id); }
    //sprzedaz
    await Provider.of<Sales>(context, listen: false).fetchAndSetSprzedazToArch();
    final sprzedazArch = Provider.of<Sales>(context, listen: false).items;
    for (var s in sprzedazArch) { DBHelper.updateSprzedazArch(s.id); }
    //matki
    await Provider.of<Queens>(context, listen: false).fetchAndSetQueensToArch();
    final matkiArch = Provider.of<Queens>(context, listen: false).items;
    for (var m in matkiArch) { DBHelper.updateMatkiArch(m.id); }
    //zbiory
    await Provider.of<Harvests>(context, listen: false).fetchAndSetZbioryToArch();
    final zbioryArch = Provider.of<Harvests>(context, listen: false).items;
    for (var z in zbioryArch) { DBHelper.updateZbioryArch(z.id); }
    //info
    await Provider.of<Infos>(context, listen: false).fetchAndSetInfosToArch();
    final infoArch = Provider.of<Infos>(context, listen: false).items;
    for (var inf in infoArch) { DBHelper.updateInfoArch(inf.id); }
    //ramki
    await Provider.of<Frames>(context, listen: false).fetchAndSetFramesToArch();
    final ramkiArch = Provider.of<Frames>(context, listen: false).items;
    for (var r in ramkiArch) { DBHelper.updateRamkaArch(r.id); }
    //zdjecia - arch oznaczane per zdjęcie w _wyslijJednoZdjecieAwait
  }

  //eksport WSZYSTKICH danych - wersja 3 - sekwencyjna z paczkami
  void _showAlertExportAllV3(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              //sprawdzenie internetu
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }

              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              // Faza 1: Pobranie wszystkich danych z lokalnej bazy
              await Provider.of<Notes>(context, listen: false).fetchAndSetNotatki();
              final notatki = Provider.of<Notes>(context, listen: false).items;

              await Provider.of<Purchases>(context, listen: false).fetchAndSetZakupy();
              final zakupy = Provider.of<Purchases>(context, listen: false).items;

              await Provider.of<Sales>(context, listen: false).fetchAndSetSprzedaz();
              final sprzedaz = Provider.of<Sales>(context, listen: false).items;

              await Provider.of<Queens>(context, listen: false).fetchAndSetQueens();
              final matki = Provider.of<Queens>(context, listen: false).items;

              await Provider.of<Harvests>(context, listen: false).fetchAndSetZbiory();
              final zbiory = Provider.of<Harvests>(context, listen: false).items;

              await Provider.of<Infos>(context, listen: false).fetchAndSetInfos();
              final info = Provider.of<Infos>(context, listen: false).items;

              await Provider.of<Photos>(context, listen: false).fetchAndSetPhotos();
              final zdjecia = Provider.of<Photos>(context, listen: false).items;

              await Provider.of<Frames>(context, listen: false).fetchAndSetFrames();
              final ramki = Provider.of<Frames>(context, listen: false).items;

              iloscDoWyslania = notatki.length + zakupy.length + sprzedaz.length +
                  matki.length + zbiory.length + info.length +
                  zdjecia.length + ramki.length;

              // Faza 2: Obliczenie kroków dynamicznie
              int infoBatches = info.isEmpty ? 0 : (info.length / _batchSize).ceil();
              int frameBatches = ramki.isEmpty ? 0 : (ramki.length / _batchSize).ceil();
              int totalSteps = 5 + infoBatches + zdjecia.length + frameBatches;
              if (totalSteps < 1) totalSteps = 1;

              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, totalSteps);
              await Future.delayed(const Duration(milliseconds: 500));

              // Faza 3: Wysyłanie sekwencyjne z progress barem

              // 1. Notatki
              _updateProgress(AppLocalizations.of(context)!.nOtes + '...');
              if (notatki.isNotEmpty) {
                await _wyslijBatch(_buildNotatkiJson(notatki, '${prefix}_notatki'));
              }

              // 2. Zakupy
              _updateProgress(AppLocalizations.of(context)!.pUrchase + '...');
              if (zakupy.isNotEmpty) {
                await _wyslijBatch(_buildZakupyJson(zakupy, '${prefix}_zakupy'));
              }

              // 3. Sprzedaż
              _updateProgress(AppLocalizations.of(context)!.sAle + '...');
              if (sprzedaz.isNotEmpty) {
                await _wyslijBatch(_buildSprzedazJson(sprzedaz, '${prefix}_sprzedaz'));
              }

              // 4. Matki
              _updateProgress(AppLocalizations.of(context)!.queens + '...');
              if (matki.isNotEmpty) {
                await _wyslijBatch(_buildMatkiJson(matki, '${prefix}_matki'));
              }

              // 5. Zbiory
              _updateProgress(AppLocalizations.of(context)!.harvest + '...');
              if (zbiory.isNotEmpty) {
                await _wyslijBatch(_buildZbioryJson(zbiory, '${prefix}_zbiory'));
              }

              // 6. Info w paczkach po _batchSize
              for (int b = 0; b < infoBatches; b++) {
                int start = b * _batchSize;
                int end = min(start + _batchSize, info.length);
                _updateProgress('Info ${b + 1}/$infoBatches...');
                await _wyslijBatch(_buildInfoJson(info.sublist(start, end), '${prefix}_info'));
              }

              // 7. Zdjęcia po jednym
              for (int i = 0; i < zdjecia.length; i++) {
                _updateProgress('${AppLocalizations.of(context)!.pHotos} ${i + 1}/${zdjecia.length}...');
                await _wyslijJednoZdjecieAwait(zdjecia[i], prefix);
              }

              // 8. Ramki w paczkach po _batchSize
              for (int b = 0; b < frameBatches; b++) {
                int start = b * _batchSize;
                int end = min(start + _batchSize, ramki.length);
                _updateProgress('${AppLocalizations.of(context)!.frames} ${b + 1}/$frameBatches...');
                await _wyslijBatch(_buildRamkiJson(ramki.sublist(start, end), '${prefix}_ramka'));
              }

              // Faza 4: Oznaczenie arch=1
              await _markArchAll();

              // Faza 5: Podsumowanie
              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false,
    );
  }

  //eksport NOWYCH danych (arch=0) - wersja 3 - sekwencyjna z paczkami
  void _showAlertExportNewV3(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              //sprawdzenie internetu
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }

              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              // Faza 1: Pobranie danych do archiwizacji (arch=0)
              await Provider.of<Notes>(context, listen: false).fetchAndSetNotatkiToArch();
              final notatki = Provider.of<Notes>(context, listen: false).items;

              await Provider.of<Purchases>(context, listen: false).fetchAndSetZakupyToArch();
              final zakupy = Provider.of<Purchases>(context, listen: false).items;

              await Provider.of<Sales>(context, listen: false).fetchAndSetSprzedazToArch();
              final sprzedaz = Provider.of<Sales>(context, listen: false).items;

              await Provider.of<Queens>(context, listen: false).fetchAndSetQueensToArch();
              final matki = Provider.of<Queens>(context, listen: false).items;

              await Provider.of<Harvests>(context, listen: false).fetchAndSetZbioryToArch();
              final zbiory = Provider.of<Harvests>(context, listen: false).items;

              await Provider.of<Infos>(context, listen: false).fetchAndSetInfosToArch();
              final info = Provider.of<Infos>(context, listen: false).items;

              await Provider.of<Photos>(context, listen: false).fetchAndSetPhotosToArch();
              final zdjecia = Provider.of<Photos>(context, listen: false).items;

              await Provider.of<Frames>(context, listen: false).fetchAndSetFramesToArch();
              final ramki = Provider.of<Frames>(context, listen: false).items;

              iloscDoWyslania = notatki.length + zakupy.length + sprzedaz.length +
                  matki.length + zbiory.length + info.length +
                  zdjecia.length + ramki.length;

              // Faza 2: Obliczenie kroków dynamicznie
              int infoBatches = info.isEmpty ? 0 : (info.length / _batchSize).ceil();
              int frameBatches = ramki.isEmpty ? 0 : (ramki.length / _batchSize).ceil();
              int totalSteps = 5 + infoBatches + zdjecia.length + frameBatches;
              if (totalSteps < 1) totalSteps = 1;

              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, totalSteps);
              await Future.delayed(const Duration(milliseconds: 500));

              // Faza 3: Wysyłanie sekwencyjne z progress barem

              // 1. Notatki
              _updateProgress(AppLocalizations.of(context)!.nOtes + '...');
              if (notatki.isNotEmpty) {
                await _wyslijBatch(_buildNotatkiJson(notatki, '${prefix}_notatki'));
              }

              // 2. Zakupy
              _updateProgress(AppLocalizations.of(context)!.pUrchase + '...');
              if (zakupy.isNotEmpty) {
                await _wyslijBatch(_buildZakupyJson(zakupy, '${prefix}_zakupy'));
              }

              // 3. Sprzedaż
              _updateProgress(AppLocalizations.of(context)!.sAle + '...');
              if (sprzedaz.isNotEmpty) {
                await _wyslijBatch(_buildSprzedazJson(sprzedaz, '${prefix}_sprzedaz'));
              }

              // 4. Matki
              _updateProgress(AppLocalizations.of(context)!.queens + '...');
              if (matki.isNotEmpty) {
                await _wyslijBatch(_buildMatkiJson(matki, '${prefix}_matki'));
              }

              // 5. Zbiory
              _updateProgress(AppLocalizations.of(context)!.harvest + '...');
              if (zbiory.isNotEmpty) {
                await _wyslijBatch(_buildZbioryJson(zbiory, '${prefix}_zbiory'));
              }

              // 6. Info w paczkach po _batchSize
              for (int b = 0; b < infoBatches; b++) {
                int start = b * _batchSize;
                int end = min(start + _batchSize, info.length);
                _updateProgress('Info ${b + 1}/$infoBatches...');
                await _wyslijBatch(_buildInfoJson(info.sublist(start, end), '${prefix}_info'));
              }

              // 7. Zdjęcia po jednym
              for (int i = 0; i < zdjecia.length; i++) {
                _updateProgress('${AppLocalizations.of(context)!.pHotos} ${i + 1}/${zdjecia.length}...');
                await _wyslijJednoZdjecieAwait(zdjecia[i], prefix);
              }

              // 8. Ramki w paczkach po _batchSize
              for (int b = 0; b < frameBatches; b++) {
                int start = b * _batchSize;
                int end = min(start + _batchSize, ramki.length);
                _updateProgress('${AppLocalizations.of(context)!.frames} ${b + 1}/$frameBatches...');
                await _wyslijBatch(_buildRamkiJson(ramki.sublist(start, end), '${prefix}_ramka'));
              }

              // Faza 4: Oznaczenie arch=1
              await _markArchAll();

              // Faza 5: Podsumowanie
              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false,
    );
  }

  //dialog z ładowaniem importu i eksportu
  showLoaderDialog (BuildContext context, String text) async {
    WakelockPlus.enable(); //blokada wyłaczania ekranu
    AlertDialog alert = AlertDialog(
      content: new Row(
        children: [
          CircularProgressIndicator(),
          Container(
            margin: EdgeInsets.only(left: 7),
            child: Text(text + '\n' + AppLocalizations.of(context)!.pleaseWait)),
        ],
      ),
    );
    
    
    // AlertDialog(
    //     key: ValueKey(count),
    //     title: const Text("Loading..."),
    //     content: LinearProgressIndicator(
    //       value: count,
    //       backgroundColor: Colors.grey,
    //       color: Colors.green,
    //       minHeight: 10,
    //     ),
    //   );
    

    //wyświetlenie okienka ładowania
    showDialog(
      barrierDismissible: false, //zablokowanie tła
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }


  void _showAlertOK(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              WakelockPlus.disable(); //usunięcie blokowania wygaszania ekranu
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();

            //   Navigator.of(context).pushNamedAndRemoveUntil(
            //       ImportScreen.routeName,
            //       ModalRoute.withName(ImportScreen
            //           .routeName)); //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
             },
            child: Text('OK'),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  void _showAlertAnuluj(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  //import danych - sekwencyjny async/await z progress barem
  void _showAlertImport(BuildContext context, String nazwa, String text) {
    formattedDate = formatter.format(now);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              //sprawdzenie internetu
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(
                    context,
                    (AppLocalizations.of(context)!.brakInternetu),
                    (AppLocalizations.of(context)!.uruchomPonownie));
                return;
              }

              showProgressDialog(context, AppLocalizations.of(context)!.dataImport, 16);

              final loc = AppLocalizations.of(context)!;

              // Zapisanie tagow NFC przed importem
              final hivesRaw = await DBHelper.getData('ule');
              _nfcTags.clear();
              for (var hive in hivesRaw) {
                if (hive['h3'] != null && hive['h3'] != '0' && hive['h3'] != '') {
                  _nfcTags[hive['id']] = hive['h3'];
                }
              }

              // 1. Import notatek
              _updateProgress(loc.nOtes + '...');
              await Notes.fetchNotatkiFromSerwer(
                  'https://darys.pl/cbt.php?d=f_notatki&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_notatki');
              await Provider.of<Notes>(context, listen: false).fetchAndSetNotatki();
              final notatki = Provider.of<Notes>(context, listen: false).items;
              _progressLabelNotifier.value = '${loc.nOtes}: ${notatki.length}';

              // 2. Import zakupów
              _updateProgress(loc.pUrchase + '...');
              await Purchases.fetchZakupyFromSerwer(
                  'https://darys.pl/cbt.php?d=f_zakupy&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_zakupy');
              await Provider.of<Purchases>(context, listen: false).fetchAndSetZakupy();
              final zakupy = Provider.of<Purchases>(context, listen: false).items;
              _progressLabelNotifier.value = '${loc.pUrchase}: ${zakupy.length}';

              // 3. Import sprzedaży
              _updateProgress(loc.sAle + '...');
              await Sales.fetchSprzedazFromSerwer(
                  'https://darys.pl/cbt.php?d=f_sprzedaz&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_sprzedaz');
              await Provider.of<Sales>(context, listen: false).fetchAndSetSprzedaz();
              final sprzedaz = Provider.of<Sales>(context, listen: false).items;
              _progressLabelNotifier.value = '${loc.sAle}: ${sprzedaz.length}';

              // 4. Import matek
              _updateProgress(loc.queens + '...');
              await Queens.fetchQueensFromSerwer(
                  'https://darys.pl/cbt.php?d=f_matki&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_matki');
              await Provider.of<Queens>(context, listen: false).fetchAndSetQueens();
              final matki = Provider.of<Queens>(context, listen: false).items;
              _progressLabelNotifier.value = '${loc.queens}: ${matki.length}';

              // 5. Import zbiorów
              _updateProgress(loc.harvest + '...');
              await Harvests.fetchZbioryFromSerwer(
                  'https://darys.pl/cbt.php?d=f_zbiory&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_zbiory');
              await Provider.of<Harvests>(context, listen: false).fetchAndSetZbiory();
              final zbiory = Provider.of<Harvests>(context, listen: false).items;
              _progressLabelNotifier.value = '${loc.harvest}: ${zbiory.length}';

              // 6. Import zdjęć
              _updateProgress(loc.pHotos + '...6');
              await Photos.fetchZdjeciaFromSerwer(
                  'https://darys.pl/cbt.php?d=f_zdjecia&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_zdjecia');
              await Provider.of<Photos>(context, listen: false).fetchAndSetPhotosForHive(0, 0);
              _progressLabelNotifier.value = loc.pHotos;

              // 7. Pobieranie ramek z serwera
              _updateProgress('${loc.downloading} ${loc.frames}...');
              final ramkiEntries = await Frames.downloadFramesFromSerwer(
                  'https://darys.pl/cbt.php?d=f_ramka&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_ramka');
              _progressLabelNotifier.value = '${loc.downloading} ${loc.frames}: ${ramkiEntries.length} 7';

              // 8. Zapis ramek do bazy z sub-progressem
              final ramkiCount = await Frames.saveFramesToDb(ramkiEntries,
                  onProgress: (current, total) {
                    _setSubProgress(current / total, '${loc.savingToDb} ${loc.frames}: $current/$total');
                  },
              );
              _updateProgress('${loc.frames}: $ramkiCount');
              await Provider.of<Frames>(context, listen: false).fetchAndSetFrames();
              final ramki = Provider.of<Frames>(context, listen: false).items;

              // 9. Odbudowa uli z ramek
              _updateProgress('${loc.rebuildingHives} (${loc.frames})...');
              for (int i = 0; i < ramki.length; i++) {
                await Hives.insertHive(
                  '${ramki[i].pasiekaNr}.${ramki[i].ulNr}',
                  ramki[i].pasiekaNr,
                  ramki[i].ulNr,
                  formattedDate,
                  'green',
                  10,
                  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                  '0', '0', '0', '0', '0', '0', '0', '0', '0', '0',
                  loc.hIve,
                  '0',
                  '0',
                  0,
                );
                if (i % 500 == 0 || i == ramki.length - 1) {
                  _setSubProgress((i + 1) / ramki.length, '${loc.rebuildingHives} (${loc.frames}): ${i + 1}/${ramki.length}');
                  await Future.delayed(Duration.zero); //oddanie sterowania do UI
                }
              }

              // 10. Pobieranie info z serwera
              _updateProgress('${loc.downloading} Info...');
              final infoEntries = await Infos.downloadInfosFromSerwer(
                  'https://darys.pl/cbt.php?d=f_info&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_info');
              _progressLabelNotifier.value = '${loc.downloading} Info: ${infoEntries.length}';

              // 11. Zapis info do bazy z sub-progressem
              final infoCount = await Infos.saveInfosToDb(infoEntries,
                  onProgress: (current, total) {
                    _setSubProgress(current / total, '${loc.savingToDb} Info: $current/$total');
                  },
              );
              _updateProgress('Info: $infoCount');
              await Provider.of<Infos>(context, listen: false).fetchAndSetInfos();
              final info = Provider.of<Infos>(context, listen: false).items;

              // 12. Aktualizacja uli z info
              _updateProgress('${loc.rebuildingHives} (Info)...');
              for (int i = 0; i < info.length; i++) {
                if (info[i].parametr == loc.numberOfFrame + ' = ') {
                  await Hives.insertHive(
                    '${info[i].pasiekaNr}.${info[i].ulNr}',
                    info[i].pasiekaNr,
                    info[i].ulNr,
                    formattedDate,
                    'green',
                    int.parse(info[i].wartosc),
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    '0', '0', '0', '0', '0', '0', '0', '0', '0', '0',
                    info[i].pogoda,
                    info[i].miara,
                    '0',
                    0,
                  );
                }
                if (i % 200 == 0 || i == info.length - 1) {
                  _setSubProgress((i + 1) / info.length, '${loc.rebuildingHives} (Info): ${i + 1}/${info.length}');
                  await Future.delayed(Duration.zero); //oddanie sterowania do UI
                }
              }

              // 13. Ładowanie uli
              _updateProgress(loc.rebuildingHives + '...');
              await Provider.of<Hives>(context, listen: false).fetchAndSetHivesAll();
              final hives = Provider.of<Hives>(context, listen: false).items;
              _progressLabelNotifier.value = '${loc.rebuildingHives}: ${hives.length}';
              await Future.delayed(const Duration(milliseconds: 500));

              // 14. Odbudowa pasiek
              _updateProgress(loc.rebuildingApiaries + '...');
              for (int i = 0; i < hives.length; i++) {
                await Apiarys.insertApiary(
                  '${hives[i].pasiekaNr}',
                  hives[i].pasiekaNr,
                  0,
                  formattedDate,
                  'green',
                  '??',
                );
              }
              globals.odswiezBelkiUli = true;
              _progressLabelNotifier.value = '${loc.rebuildingApiaries}: ${hives.length}';
              await Future.delayed(const Duration(milliseconds: 500));

              // 15. Przywrócenie tagów NFC
              _updateProgress('NFC...');
              for (var entry in _nfcTags.entries) {
                await DBHelper.updateUle(entry.key, 'h3', entry.value);
              }
              _progressLabelNotifier.value = 'NFC: ${_nfcTags.length}';
              await Future.delayed(const Duration(milliseconds: 500));

              // 16. Finalizacja - pobranie pasiek
              _updateProgress(loc.finalization + '...');
              await Provider.of<Apiarys>(context, listen: false).fetchAndSetApiarys();
              await Future.delayed(const Duration(milliseconds: 500));

              // Nawigacja do ekranu głównego
              Navigator.of(context).pushNamedAndRemoveUntil(
                  ApiarysScreen.routeName,
                  ModalRoute.withName(ApiarysScreen.routeName));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.importEnd),
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.importuj),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false,
    );
  }

  //sprawdzenie czy jest internet
  Future<bool> _isInternet() async { 
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      // Mobile network available.
      return true;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      // Wi-fi is available.
      // Note for Android: When both mobile and Wi-Fi are turned on system will return Wi-Fi only as active network type
      return true;
    } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
      // Bluetooth connection available.
      return true;
    } else if (connectivityResult.contains(ConnectivityResult.other)) {
      // Connected to a network which is not in the above mentioned networks.
      return false;
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      // No available network types
      return false;
    }else return false;
  }

  //eksport wszystkich danych Notatki - z progress barem
  void _showAlertExportAllNotatki(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }
              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              await Provider.of<Notes>(context, listen: false).fetchAndSetNotatki();
              final notatki = Provider.of<Notes>(context, listen: false).items;
              iloscDoWyslania = notatki.length;

              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, notatki.isEmpty ? 1 : 2);
              await Future.delayed(const Duration(milliseconds: 500));

              // wysyłanie
              _updateProgress(AppLocalizations.of(context)!.nOtes + '...');
              if (notatki.isNotEmpty) {
                await _wyslijBatch(_buildNotatkiJson(notatki, '${prefix}_notatki'));
              }

              // arch=1
              _updateProgress('arch...');
              await Provider.of<Notes>(context, listen: false).fetchAndSetNotatkiToArch();
              final notatkiArch = Provider.of<Notes>(context, listen: false).items;
              for (var n in notatkiArch) { DBHelper.updateNotatkiArch(n.id); }

              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false,
    );
  }

  //eksport wszystkich danych Zakupy - z progress barem
  void _showAlertExportAllZakupy(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }
              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              await Provider.of<Purchases>(context, listen: false).fetchAndSetZakupy();
              final zakupy = Provider.of<Purchases>(context, listen: false).items;
              iloscDoWyslania = zakupy.length;

              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, zakupy.isEmpty ? 1 : 2);
              await Future.delayed(const Duration(milliseconds: 500));

              // wysyłanie
              _updateProgress(AppLocalizations.of(context)!.pUrchase + '...');
              if (zakupy.isNotEmpty) {
                await _wyslijBatch(_buildZakupyJson(zakupy, '${prefix}_zakupy'));
              }

              // arch=1
              _updateProgress('arch...');
              await Provider.of<Purchases>(context, listen: false).fetchAndSetZakupyToArch();
              final zakupyArch = Provider.of<Purchases>(context, listen: false).items;
              for (var z in zakupyArch) { DBHelper.updateZakupyArch(z.id); }

              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false,
    );
  }

  //eksport wszystkich danych Sprzedaz - z progress barem
  void _showAlertExportAllSprzedaz(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }
              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              await Provider.of<Sales>(context, listen: false).fetchAndSetSprzedaz();
              final sprzedaz = Provider.of<Sales>(context, listen: false).items;
              iloscDoWyslania = sprzedaz.length;

              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, sprzedaz.isEmpty ? 1 : 2);
              await Future.delayed(const Duration(milliseconds: 500));

              // wysyłanie
              _updateProgress(AppLocalizations.of(context)!.sAle + '...');
              if (sprzedaz.isNotEmpty) {
                await _wyslijBatch(_buildSprzedazJson(sprzedaz, '${prefix}_sprzedaz'));
              }

              // arch=1
              _updateProgress('arch...');
              await Provider.of<Sales>(context, listen: false).fetchAndSetSprzedazToArch();
              final sprzedazArch = Provider.of<Sales>(context, listen: false).items;
              for (var s in sprzedazArch) { DBHelper.updateSprzedazArch(s.id); }

              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false,
    );
  }

  //eksport wszystkich danych Matki - z progress barem
  void _showAlertExportAllMatki(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }
              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              await Provider.of<Queens>(context, listen: false).fetchAndSetQueens();
              final matki = Provider.of<Queens>(context, listen: false).items;
              iloscDoWyslania = matki.length;

              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, matki.isEmpty ? 1 : 2);
              await Future.delayed(const Duration(milliseconds: 500));

              // wysyłanie
              _updateProgress(AppLocalizations.of(context)!.queens + '...');
              if (matki.isNotEmpty) {
                await _wyslijBatch(_buildMatkiJson(matki, '${prefix}_matki'));
              }

              // arch=1
              _updateProgress('arch...');
              await Provider.of<Queens>(context, listen: false).fetchAndSetQueensToArch();
              final matkiArch = Provider.of<Queens>(context, listen: false).items;
              for (var m in matkiArch) { DBHelper.updateMatkiArch(m.id); }

              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false,
    );
  }

  //eksport wszystkich danych Zbiory - z progress barem
  void _showAlertExportAllZbiory(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }
              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              await Provider.of<Harvests>(context, listen: false).fetchAndSetZbiory();
              final zbiory = Provider.of<Harvests>(context, listen: false).items;
              iloscDoWyslania = zbiory.length;

              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, zbiory.isEmpty ? 1 : 2);
              await Future.delayed(const Duration(milliseconds: 500));

              // wysyłanie
              _updateProgress(AppLocalizations.of(context)!.harvest + '...');
              if (zbiory.isNotEmpty) {
                await _wyslijBatch(_buildZbioryJson(zbiory, '${prefix}_zbiory'));
              }

              // arch=1
              _updateProgress('arch...');
              await Provider.of<Harvests>(context, listen: false).fetchAndSetZbioryToArch();
              final zbioryArch = Provider.of<Harvests>(context, listen: false).items;
              for (var z in zbioryArch) { DBHelper.updateZbioryArch(z.id); }

              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false,
    );
  }

  //eksport wszystkich danych Info - z progress barem i batch
  void _showAlertExportAllInfo(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[

          //tylko z biezącego roku
          TextButton(
            onPressed: () async {
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }
              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              await Provider.of<Infos>(context, listen: false).fetchAndSetInfos();
              final info = Provider.of<Infos>(context, listen: false).items.where((inf) {
                return inf.data.startsWith(biezacyRok);
              }).toList();
              iloscDoWyslania = info.length;

              int batches = info.isEmpty ? 0 : (info.length / _batchSize).ceil();
              int totalSteps = (batches > 0 ? batches : 1) + 1; // batche + arch
              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, totalSteps);
              await Future.delayed(const Duration(milliseconds: 500));

              // wysyłanie w paczkach
              for (int b = 0; b < batches; b++) {
                int start = b * _batchSize;
                int end = min(start + _batchSize, info.length);
                _updateProgress('Info ${b + 1}/$batches...');
                await _wyslijBatch(_buildInfoJson(info.sublist(start, end), '${prefix}_info'));
              }
              if (batches == 0) _updateProgress('Info...');

              // arch=1
              _updateProgress('arch...');
              await Provider.of<Infos>(context, listen: false).fetchAndSetInfosToArch();
              final infoArch = Provider.of<Infos>(context, listen: false).items;
              for (var inf in infoArch) { DBHelper.updateInfoArch(inf.id); }

              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.oNly + ' $biezacyRok'),
          ),

          //wszystkie informacje z wszystkich lat
          TextButton(
            onPressed: () async {
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }
              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              await Provider.of<Infos>(context, listen: false).fetchAndSetInfos();
              final info = Provider.of<Infos>(context, listen: false).items;
              iloscDoWyslania = info.length;

              int batches = info.isEmpty ? 0 : (info.length / _batchSize).ceil();
              int totalSteps = (batches > 0 ? batches : 1) + 1; // batche + arch
              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, totalSteps);
              await Future.delayed(const Duration(milliseconds: 500));

              // wysyłanie w paczkach
              for (int b = 0; b < batches; b++) {
                int start = b * _batchSize;
                int end = min(start + _batchSize, info.length);
                _updateProgress('Info ${b + 1}/$batches...');
                await _wyslijBatch(_buildInfoJson(info.sublist(start, end), '${prefix}_info'));
              }
              if (batches == 0) _updateProgress('Info...');

              // arch=1
              _updateProgress('arch...');
              await Provider.of<Infos>(context, listen: false).fetchAndSetInfosToArch();
              final infoArch = Provider.of<Infos>(context, listen: false).items;
              for (var inf in infoArch) { DBHelper.updateInfoArch(inf.id); }

              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.aLl),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false,
    );
  }
 
  //eksport wszystkich danych Ramki - z progress barem i batch
  void _showAlertExportAllRamki(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          //dane o ramkach tylko z tego roku
          TextButton(
            onPressed: () async {
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }
              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              await Provider.of<Frames>(context, listen: false).fetchAndSetFrames();
              final ramki = Provider.of<Frames>(context, listen: false).items.where((ra) {
                return ra.data.startsWith(biezacyRok);
              }).toList();
              iloscDoWyslania = ramki.length;

              int batches = ramki.isEmpty ? 0 : (ramki.length / _batchSize).ceil();
              int totalSteps = (batches > 0 ? batches : 1) + 1; // batche + arch
              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, totalSteps);
              await Future.delayed(const Duration(milliseconds: 500));

              // wysyłanie w paczkach
              for (int b = 0; b < batches; b++) {
                int start = b * _batchSize;
                int end = min(start + _batchSize, ramki.length);
                _updateProgress('${AppLocalizations.of(context)!.frames} ${b + 1}/$batches...');
                await _wyslijBatch(_buildRamkiJson(ramki.sublist(start, end), '${prefix}_ramka'));
              }
              if (batches == 0) _updateProgress('${AppLocalizations.of(context)!.frames}...');

              // arch=1
              _updateProgress('arch...');
              await Provider.of<Frames>(context, listen: false).fetchAndSetFramesToArch();
              final ramkiArch = Provider.of<Frames>(context, listen: false).items;
              for (var r in ramkiArch) { DBHelper.updateRamkaArch(r.id); }

              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.oNly + ' $biezacyRok'),
          ),

          //Dane o ramkach z wszystkich lat
          TextButton(
            onPressed: () async {
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }
              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              await Provider.of<Frames>(context, listen: false).fetchAndSetFrames();
              final ramki = Provider.of<Frames>(context, listen: false).items;
              iloscDoWyslania = ramki.length;

              int batches = ramki.isEmpty ? 0 : (ramki.length / _batchSize).ceil();
              int totalSteps = (batches > 0 ? batches : 1) + 1; // batche + arch
              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, totalSteps);
              await Future.delayed(const Duration(milliseconds: 500));

              // wysyłanie w paczkach
              for (int b = 0; b < batches; b++) {
                int start = b * _batchSize;
                int end = min(start + _batchSize, ramki.length);
                _updateProgress('${AppLocalizations.of(context)!.frames} ${b + 1}/$batches...');
                await _wyslijBatch(_buildRamkiJson(ramki.sublist(start, end), '${prefix}_ramka'));
              }
              if (batches == 0) _updateProgress('${AppLocalizations.of(context)!.frames}...');

              // arch=1
              _updateProgress('arch...');
              await Provider.of<Frames>(context, listen: false).fetchAndSetFramesToArch();
              final ramkiArch = Provider.of<Frames>(context, listen: false).items;
              for (var r in ramkiArch) { DBHelper.updateRamkaArch(r.id); }

              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.aLl),
          ),

          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  //eksport wszystkich danych - wszystkie tabele
  void _showAlertExportAll(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async{
              //print('wysłanie wszystkich danych do chmury ========= ');
              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, 8);
              await Future.delayed(const Duration(seconds: 1));
              iloscDoWyslania = 0;

              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli notatki - wszystkie
                Provider.of<Notes>(context, listen: false) //DBHelper - pobieranie notatek
                    .fetchAndSetNotatki() //wczytanie danych do uruchomienia apki --> Notatki <---
                    .then((_) {
                  final notatkiArchData = Provider.of<Notes>(context, listen: false);
                  final notatki = notatkiArchData.items;
                  // print('ilość nowych wpisów w tabeli notatki');
                  // print(info.length);
                  iloscDoWyslania += notatki.length;
                  _updateProgress(AppLocalizations.of(context)!.nOtes + '...');

                  //przygotowanie notatek do wysyłki
                  if (notatki.length > 0) {
                    String jsonData = '{"notatki":[';
                    int i = 0;
                    while (notatki.length > i) {
                      jsonData += '{"id": "${notatki[i].id}",';
                      jsonData += '"data": "${notatki[i].data}",';
                      jsonData += '"tytul": "${notatki[i].tytul}",';
                      jsonData += '"pasiekaNr": ${notatki[i].pasiekaNr},';
                      jsonData += '"ulNr": ${notatki[i].ulNr},';
                      jsonData += '"notatka": "${notatki[i].notatka}",';
                      jsonData += '"status": ${notatki[i].status},';
                      jsonData += '"priorytet": "${notatki[i].priorytet}",';
                      jsonData += '"pole1": "${notatki[i].pole1}",';
                      jsonData += '"pole2": "${notatki[i].pole2}",';
                      jsonData += '"pole3": "${notatki[i].pole3}",';
                      jsonData += '"uwagi": "${notatki[i].uwagi}",';
                      jsonData += '"arch": ${notatki[i].arch}}';
                      i++;
                      if (notatki.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${notatki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_notatki"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                    //print(jsonData); //json przygotowany poprawnie
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupNotatki(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
                          Navigator.of(context).pop();

                          _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                        }
                      },
                    );
                  } else {
                    // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    //     AppLocalizations.of(context)!.noDataToSend);
                  } //jeśli sa ramki do archiwizacji
                });

              
              //BACKUP tabeli zakupy - wszystkie
                Provider.of<Purchases>(context, listen: false)
                    .fetchAndSetZakupy()
                    .then((_) {
                  final zakupyArchData =
                      Provider.of<Purchases>(context, listen: false);
                  final zakupy = zakupyArchData.items;
                  // print('ilość nowych wpisów w tabeli zakupy');
                  // print(info.length);
                  iloscDoWyslania += zakupy.length;
                  _updateProgress(AppLocalizations.of(context)!.pUrchase + '...');

                  if (zakupy.length > 0) {
                    String jsonData = '{"zakupy":[';
                    int i = 0;
                    while (zakupy.length > i) {
                      jsonData += '{"id": "${zakupy[i].id}",';
                      jsonData += '"data": "${zakupy[i].data}",';
                      jsonData += '"pasiekaNr": ${zakupy[i].pasiekaNr},';
                      jsonData += '"nazwa": "${zakupy[i].nazwa}",';
                      jsonData += '"kategoriaId": ${zakupy[i].kategoriaId},';
                      jsonData += '"ilosc": ${zakupy[i].ilosc},';
                      jsonData += '"miara": ${zakupy[i].miara},';
                      jsonData += '"cena": ${zakupy[i].cena},';
                      jsonData += '"wartosc": ${zakupy[i].wartosc},';
                      jsonData += '"waluta": ${zakupy[i].waluta},';
                      jsonData += '"uwagi": "${zakupy[i].uwagi}",';
                      jsonData += '"arch": ${zakupy[i].arch}}';
                      i++;
                      if (zakupy.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${zakupy.length}, "tabela":"${mem[0].kod.substring(0, 4)}_zakupy"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupZakupy(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
                          Navigator.of(context).pop();

                          _showAlertAnuluj(
                              context,
                              AppLocalizations.of(context)!.alert,
                              AppLocalizations.of(context)!.noInternet);
                        }
                      },
                    );
                  } else {
                    // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    //     AppLocalizations.of(context)!.noDataToSend);
                  } //jeśli sa ramki do archiwizacji
                });

              //BACKUP tabeli sprzedaz - wszystkie
                Provider.of<Sales>(context, listen: false)
                    .fetchAndSetSprzedaz()
                    .then((_) {
                  final sprzedazArchData =
                      Provider.of<Sales>(context, listen: false);
                  final sprzedaz = sprzedazArchData.items;
                  // print('ilość nowych wpisów w tabeli info');
                  // print(info.length);
                  iloscDoWyslania += sprzedaz.length;
                  _updateProgress(AppLocalizations.of(context)!.sAle + '...');

                  if (sprzedaz.length > 0) {
                    String jsonData = '{"sprzedaz":[';
                    int i = 0;
                    while (sprzedaz.length > i) {
                      jsonData += '{"id": "${sprzedaz[i].id}",';
                      jsonData += '"data": "${sprzedaz[i].data}",';
                      jsonData += '"pasiekaNr": ${sprzedaz[i].pasiekaNr},';
                      jsonData += '"nazwa": "${sprzedaz[i].nazwa}",';
                      jsonData += '"kategoriaId": ${sprzedaz[i].kategoriaId},';
                      jsonData += '"ilosc": ${sprzedaz[i].ilosc},';
                      jsonData += '"miara": ${sprzedaz[i].miara},';
                      jsonData += '"cena": ${sprzedaz[i].cena},';
                      jsonData += '"wartosc": ${sprzedaz[i].wartosc},';
                      jsonData += '"waluta": ${sprzedaz[i].waluta},';
                      jsonData += '"uwagi": "${sprzedaz[i].uwagi}",';
                      jsonData += '"arch": ${sprzedaz[i].arch}}';
                      i++;
                      if (sprzedaz.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${sprzedaz.length}, "tabela":"${mem[0].kod.substring(0, 4)}_sprzedaz"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupSprzedaz(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
                          Navigator.of(context).pop();

                          _showAlertAnuluj(
                              context,
                              AppLocalizations.of(context)!.alert,
                              AppLocalizations.of(context)!.noInternet);
                        }
                      },
                    );
                  } else {
                    // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    //     AppLocalizations.of(context)!.noDataToSend);
                  } //jeśli sa ramki do archiwizacji
                });

              //BACKUP tabeli matki - wszystkie
                Provider.of<Queens>(context, listen: false)
                    .fetchAndSetQueens()
                    .then((_) {
                  final matkiArchData =
                      Provider.of<Queens>(context, listen: false);
                  final matki = matkiArchData.items;
                  // print('ilość nowych wpisów w tabeli info');
                  // print(info.length);
                  iloscDoWyslania += matki.length;
                  _updateProgress(AppLocalizations.of(context)!.queens + '...');

                  if (matki.length > 0) {
                    String jsonData = '{"matki":[';
                    int i = 0;
                    while (matki.length > i) {
                      jsonData += '{"id": "${matki[i].id}",';
                      jsonData += '"data": "${matki[i].data}",';
                      jsonData += '"zrodlo": "${matki[i].zrodlo}",';
                      jsonData += '"rasa": "${matki[i].rasa}",';
                      jsonData += '"linia": "${matki[i].linia}",';
                      jsonData += '"znak": "${matki[i].znak}",';
                      jsonData += '"napis": "${matki[i].napis}",';
                      jsonData += '"uwagi": "${matki[i].uwagi}",';
                      jsonData += '"pasieka": ${matki[i].pasieka},';
                      jsonData += '"ul": ${matki[i].ul},';
                      jsonData += '"dataStraty": "${matki[i].dataStraty}",';
                      jsonData += '"a": "${matki[i].a}",';
                      jsonData += '"b": "${matki[i].b}",';
                      jsonData += '"c": "${matki[i].c}",';
                      jsonData += '"arch": ${matki[i].arch}}';
                      i++;
                      if (matki.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${matki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_matki"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupMatki(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
                          Navigator.of(context).pop();

                          _showAlertAnuluj(
                              context,
                              AppLocalizations.of(context)!.alert,
                              AppLocalizations.of(context)!.noInternet);
                        }
                      },
                    );
                  } else {
                    // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    //     AppLocalizations.of(context)!.noDataToSend);
                  } //jeśli sa ramki do archiwizacji
                });


              //BACKUP tabeli zbiory - wszystkie
                Provider.of<Harvests>(context, listen: false)
                    .fetchAndSetZbiory()
                    .then((_) {
                  final zbioryArchData =
                      Provider.of<Harvests>(context, listen: false);
                  final zbiory = zbioryArchData.items;
                  // print('ilość nowych wpisów w tabeli info');
                  // print(info.length);
                  iloscDoWyslania += zbiory.length;
                  _updateProgress(AppLocalizations.of(context)!.harvest + '...');

                  if (zbiory.length > 0) {
                    String jsonData = '{"zbiory":[';
                    int i = 0;
                    while (zbiory.length > i) {
                      jsonData += '{"id": "${zbiory[i].id}",';
                      jsonData += '"data": "${zbiory[i].data}",';
                      jsonData += '"pasiekaNr": ${zbiory[i].pasiekaNr},';
                      jsonData += '"zasobId": ${zbiory[i].zasobId},';
                      jsonData += '"ilosc": "${zbiory[i].ilosc}",';
                      jsonData += '"miara": "${zbiory[i].miara}",';
                      jsonData += '"uwagi": "${zbiory[i].uwagi}",';
                      jsonData += '"g": "${zbiory[i].g}",';
                      jsonData += '"h": "${zbiory[i].h}",';
                      jsonData += '"arch": ${zbiory[i].arch}}';
                      i++;
                      if (zbiory.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${zbiory.length}, "tabela":"${mem[0].kod.substring(0, 4)}_zbiory"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupZbiory(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
                          Navigator.of(context).pop();

                          _showAlertAnuluj(
                              context,
                              AppLocalizations.of(context)!.alert,
                              AppLocalizations.of(context)!.noInternet);
                        }
                      },
                    );
                  } else {
                    // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    //     AppLocalizations.of(context)!.noDataToSend);
                  } //jeśli sa ramki do archiwizacji
                });

              //BACKUP tabeli info - wszystkie wpisy
                Provider.of<Infos>(context, listen: false)
                    .fetchAndSetInfos()
                    .then((_) {
                  final infoAllData = Provider.of<Infos>(context, listen: false);
                  final info = infoAllData.items;
                  //print('ilość wszystkich wpisów w tabeli info');
                  //print(info.length);
                  iloscDoWyslania += info.length;
                  _updateProgress('Info...');

                  if (info.length > 0) {
                    String jsonData = '{"info":[';
                    int i = 0;
                    while (info.length > i) {
                      jsonData += '{"id": "${info[i].id}",';
                      jsonData += '"data": "${info[i].data}",';
                      jsonData += '"pasiekaNr": ${info[i].pasiekaNr},';
                      jsonData += '"ulNr": ${info[i].ulNr},';
                      jsonData += '"kategoria": "${info[i].kategoria}",';
                      jsonData += '"parametr": "${info[i].parametr}",';
                      jsonData += '"wartosc": "${info[i].wartosc}",';
                      jsonData += '"miara": "${info[i].miara}",';
                      jsonData += '"pogoda": "${info[i].pogoda}",';
                      jsonData += '"temp": "${info[i].temp}",';
                      jsonData += '"czas": "${info[i].czas}",';
                      jsonData += '"uwagi": "${info[i].uwagi}",';
                      jsonData += '"arch": ${info[i].arch}}';
                      i++;
                      if (info.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${info.length}, "tabela":"${mem[0].kod.substring(0, 4)}_info"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                          wyslijBackupInfo(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
                          Navigator.of(context).pop();
                          _showAlertAnuluj(
                              context,
                              AppLocalizations.of(context)!.alert,
                              AppLocalizations.of(context)!.noInternet);
                        }
                      },
                    );
                  } else {
                    // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    //     AppLocalizations.of(context)!.noDataToSend);
                  } //jeśli sa ramki do archiwizacji
                });

              //BACKUP tabeli zdjecia - razem ze wszystkimi tabelami -zastanowic sie czy wysyłać razem z innymi tabelami - moze długo trwać
              Provider.of<Photos>(context, listen: false)
                  .fetchAndSetPhotos()
                  .then((_) {
                final photosArchData =
                    Provider.of<Photos>(context, listen: false);
                final zdjecia = photosArchData.items;
                iloscDoWyslania += zdjecia.length;
                _updateProgress(AppLocalizations.of(context)!.pHotos + '...');

                if (zdjecia.length > 0) {
                  _wyslijZdjeciaPoJednym(zdjecia, mem, 0);
                }
              }); //od pobrania zdjec


              //BACKUP tabeli ramka - wszystkie wpisy
                Provider.of<Frames>(context, listen: false)
                    .fetchAndSetFrames()
                    .then((_) {
                  final framesAllData =
                      Provider.of<Frames>(context, listen: false);
                  final ramki = framesAllData.items;
                  // print('ilość wszystkich wpisów w tabeli ramka');
                  // print(ramki.length);

                  //informacja o ilości rekordów do wysłania
                  iloscDoWyslania += ramki.length;
                  _updateProgress(AppLocalizations.of(context)!.frames + '...');

                  if (iloscDoWyslania > 0)
                    _showAlertOK(
                        context,
                        AppLocalizations.of(context)!.alert,
                        AppLocalizations.of(context)!.dataToSend +
                            ' = $iloscDoWyslania');
                  else
                    _showAlertOK(context, AppLocalizations.of(context)!.alert,
                        AppLocalizations.of(context)!.noDataToSend);

                  if (ramki.length > 0) {
                    String jsonData = '{"ramka":[';
                    int i = 0;
                    while (ramki.length > i) {
                      jsonData += '{"id": "${ramki[i].id}",';
                      jsonData += '"data": "${ramki[i].data}",';
                      jsonData += '"pasiekaNr": ${ramki[i].pasiekaNr},';
                      jsonData += '"ulNr": ${ramki[i].ulNr},';
                      jsonData += '"korpusNr": ${ramki[i].korpusNr},';
                      jsonData += '"typ": ${ramki[i].typ},';
                      jsonData += '"ramkaNr": ${ramki[i].ramkaNr},';
                      jsonData += '"ramkaNrPo": ${ramki[i].ramkaNrPo},';
                      jsonData += '"rozmiar": ${ramki[i].rozmiar},';
                      jsonData += '"strona": ${ramki[i].strona},';
                      jsonData += '"zasob": ${ramki[i].zasob},';
                      jsonData += '"wartosc": "${ramki[i].wartosc}",';
                      jsonData += '"arch": ${ramki[i].arch}}';
                      i++;
                      if (ramki.length > i) jsonData += ',';
                    }
                    jsonData +=
                        '],"total":${ramki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_ramka"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                    //print(jsonData);
                    _isInternet().then(
                      (inter) {
                        if (inter) {
                         // print('$inter - jest internet');
                          wyslijBackupRamka(jsonData); //jsonData
                        } else {
                          //print('braaaaaak internetu');
                          // _showAlertAnuluj(
                          //     context,
                          //     AppLocalizations.of(context)!.alert,
                          //     AppLocalizations.of(context)!.noInternet);
                        }
                      },
                    );
                  } else {
                    // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    //     AppLocalizations.of(context)!.noDataToSend);
                  } //jeśli ramki do archiwizacji
                }); //od pobrania ramek

               //Navigator.of(context).pop();

            },//od wysłania wszystkie tabele
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }


  //eksport wszystkich ale tylko nowych danych
  void _showAlertExportNew(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {

              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, 8);

              iloscDoWyslania = 0;
              //uzyskanie dostępu do danych w pamięci
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;

              //BACKUP tabeli notatki - tylko wpisy z arch=0
              Provider.of<Notes>(context, listen: false)
                  .fetchAndSetNotatkiToArch()
                  .then((_) {
                final notatkiArchData =
                    Provider.of<Notes>(context, listen: false);
                final notatki = notatkiArchData.items;
                // print('ilość nowych wpisów w tabeli notatki');
                // print(info.length);
                iloscDoWyslania += notatki.length;
                _updateProgress(AppLocalizations.of(context)!.nOtes + '...');

                if (notatki.length > 0) {
                  String jsonData = '{"notatki":[';
                  int i = 0;
                  while (notatki.length > i) {
                    jsonData += '{"id": "${notatki[i].id}",';
                    jsonData += '"data": "${notatki[i].data}",';
                    jsonData += '"tytul": "${notatki[i].tytul}",';
                    jsonData += '"pasiekaNr": ${notatki[i].pasiekaNr},';
                    jsonData += '"ulNr": ${notatki[i].ulNr},';
                    jsonData += '"notatka": "${notatki[i].notatka}",';
                    jsonData += '"status": ${notatki[i].status},';
                    jsonData += '"priorytet": "${notatki[i].priorytet}",';
                    jsonData += '"pole1": "${notatki[i].pole1}",';
                    jsonData += '"pole2": "${notatki[i].pole2}",';
                    jsonData += '"pole3": "${notatki[i].pole3}",';
                    jsonData += '"uwagi": "${notatki[i].uwagi}",';
                    jsonData += '"arch": ${notatki[i].arch}}';
                    i++;
                    if (notatki.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${notatki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_notatki"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupNotatki(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli zakupy - tylko wpisy z arch=0
              Provider.of<Purchases>(context, listen: false)
                  .fetchAndSetZakupyToArch()
                  .then((_) {
                final zakupyArchData =
                    Provider.of<Purchases>(context, listen: false);
                final zakupy = zakupyArchData.items;
                // print('ilość nowych wpisów w tabeli zakupy');
                // print(info.length);
                 iloscDoWyslania += zakupy.length;
                _updateProgress(AppLocalizations.of(context)!.pUrchase + '...');
                // if (iloscDoWyslania > 0)
                //   _showAlertOK(
                //       context,
                //       AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.dataToSend +
                //           ' = $iloscDoWyslania');
                // else
                //   _showAlertOK(context, AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.noDataToSend);

                if (zakupy.length > 0) {
                  String jsonData = '{"zakupy":[';
                  int i = 0;
                  while (zakupy.length > i) {
                    jsonData += '{"id": "${zakupy[i].id}",';
                    jsonData += '"data": "${zakupy[i].data}",';
                    jsonData += '"pasiekaNr": ${zakupy[i].pasiekaNr},';
                    jsonData += '"nazwa": "${zakupy[i].nazwa}",';
                    jsonData += '"kategoriaId": ${zakupy[i].kategoriaId},';
                    jsonData += '"ilosc": ${zakupy[i].ilosc},';
                    jsonData += '"miara": ${zakupy[i].miara},';
                    jsonData += '"cena": ${zakupy[i].cena},';
                    jsonData += '"wartosc": ${zakupy[i].wartosc},';
                    jsonData += '"waluta": ${zakupy[i].waluta},';
                    jsonData += '"uwagi": "${zakupy[i].uwagi}",';
                    jsonData += '"arch": ${zakupy[i].arch}}';
                    i++;
                    if (zakupy.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${zakupy.length}, "tabela":"${mem[0].kod.substring(0, 4)}_zakupy"}'; //pierwsze cztery cyfry kodu zakupy_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupZakupy(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli sprzedaz - tylko wpisy z arch=0
              Provider.of<Sales>(context, listen: false)
                  .fetchAndSetSprzedazToArch()
                  .then((_) {
                final sprzedazArchData =
                    Provider.of<Sales>(context, listen: false);
                final sprzedaz = sprzedazArchData.items;
                // print('ilość nowych wpisów w tabeli info');
                // print(info.length);
                iloscDoWyslania += sprzedaz.length;
                _updateProgress(AppLocalizations.of(context)!.sAle + '...');
                //if (iloscDoWyslania > 0)
                //   _showAlertOK(
                //       context,
                //       AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.dataToSend +
                //           ' = $iloscDoWyslania');
                // else
                //   _showAlertOK(context, AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.noDataToSend);

                if (sprzedaz.length > 0) {
                  String jsonData = '{"sprzedaz":[';
                  int i = 0;
                  while (sprzedaz.length > i) {
                    jsonData += '{"id": "${sprzedaz[i].id}",';
                    jsonData += '"data": "${sprzedaz[i].data}",';
                    jsonData += '"pasiekaNr": ${sprzedaz[i].pasiekaNr},';
                    jsonData += '"nazwa": "${sprzedaz[i].nazwa}",';
                    jsonData += '"kategoriaId": ${sprzedaz[i].kategoriaId},';
                    jsonData += '"ilosc": ${sprzedaz[i].ilosc},';
                    jsonData += '"miara": ${sprzedaz[i].miara},';
                    jsonData += '"cena": ${sprzedaz[i].cena},';
                    jsonData += '"wartosc": ${sprzedaz[i].wartosc},';
                    jsonData += '"waluta": ${sprzedaz[i].waluta},';
                    jsonData += '"uwagi": "${sprzedaz[i].uwagi}",';
                    jsonData += '"arch": ${sprzedaz[i].arch}}';
                    i++;
                    if (sprzedaz.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${sprzedaz.length}, "tabela":"${mem[0].kod.substring(0, 4)}_sprzedaz"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupSprzedaz(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli matki - tylko wpisy z arch=0
              Provider.of<Queens>(context, listen: false)
                  .fetchAndSetQueensToArch()
                  .then((_) {
                final matkiArchData =
                    Provider.of<Queens>(context, listen: false);
                final matki = matkiArchData.items;
                // print('ilość nowych wpisów w tabeli info');
                // print(info.length);
                iloscDoWyslania += matki.length;
                _updateProgress(AppLocalizations.of(context)!.queens + '...');
                //if (iloscDoWyslania > 0)
                //   _showAlertOK(
                //       context,
                //       AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.dataToSend +
                //           ' = $iloscDoWyslania');
                // else
                //   _showAlertOK(context, AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.noDataToSend);

                if (matki.length > 0) {
                  String jsonData = '{"matki":[';
                  int i = 0;
                  while (matki.length > i) {
                    jsonData += '{"id": "${matki[i].id}",';
                    jsonData += '"data": "${matki[i].data}",';
                    jsonData += '"zrodlo": "${matki[i].zrodlo}",';
                    jsonData += '"rasa": "${matki[i].rasa}",';
                    jsonData += '"linia": "${matki[i].linia}",';
                    jsonData += '"znak": "${matki[i].znak}",';
                    jsonData += '"napis": "${matki[i].napis}",';
                    jsonData += '"uwagi": "${matki[i].uwagi}",';
                    jsonData += '"pasieka": ${matki[i].pasieka},';
                    jsonData += '"ul": ${matki[i].ul},';
                    jsonData += '"dataStraty": "${matki[i].dataStraty}",';
                    jsonData += '"a": "${matki[i].a}",';
                    jsonData += '"b": "${matki[i].b}",';
                    jsonData += '"c": "${matki[i].c}",';
                    jsonData += '"arch": ${matki[i].arch}}';
                    i++;
                    if (matki.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${matki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_matki"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupMatki(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli zbiory - tylko wpisy z arch=0
              Provider.of<Harvests>(context, listen: false)
                  .fetchAndSetZbioryToArch()
                  .then((_) {
                final zbioryArchData =
                    Provider.of<Harvests>(context, listen: false);
                final zbiory = zbioryArchData.items;
                // print('ilość nowych wpisów w tabeli info');
                // print(info.length);
                iloscDoWyslania += zbiory.length;
                _updateProgress(AppLocalizations.of(context)!.harvest + '...');

                if (zbiory.length > 0) {
                  String jsonData = '{"zbiory":[';
                  int i = 0;
                  while (zbiory.length > i) {
                    jsonData += '{"id": "${zbiory[i].id}",';
                    jsonData += '"data": "${zbiory[i].data}",';
                    jsonData += '"pasiekaNr": ${zbiory[i].pasiekaNr},';
                    jsonData += '"zasobId": ${zbiory[i].zasobId},';
                    jsonData += '"ilosc": "${zbiory[i].ilosc}",';
                    jsonData += '"miara": "${zbiory[i].miara}",';
                    jsonData += '"uwagi": "${zbiory[i].uwagi}",';
                    jsonData += '"g": "${zbiory[i].g}",';
                    jsonData += '"h": "${zbiory[i].h}",';
                    jsonData += '"arch": ${zbiory[i].arch}}';
                    i++;
                    if (zbiory.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${zbiory.length}, "tabela":"${mem[0].kod.substring(0, 4)}_zbiory"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupZbiory(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

              //BACKUP tabeli info - tylko wpisy z arch=0
              Provider.of<Infos>(context, listen: false)
                  .fetchAndSetInfosToArch()
                  .then((_) {
                final infoArchData = Provider.of<Infos>(context, listen: false);
                final info = infoArchData.items;
                // print('ilość nowych wpisów w tabeli info');
                // print(info.length);
                iloscDoWyslania += info.length;
                _updateProgress('Info...');
                // if (iloscDoWyslania > 0)
                //   _showAlertOK(
                //       context,
                //       AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.dataToSend +
                //           ' = $iloscDoWyslania');
                // else
                //   _showAlertOK(context, AppLocalizations.of(context)!.alert,
                //       AppLocalizations.of(context)!.noDataToSend);

                if (info.length > 0) {
                  String jsonData = '{"info":[';
                  int i = 0;
                  while (info.length > i) {
                    jsonData += '{"id": "${info[i].id}",';
                    jsonData += '"data": "${info[i].data}",';
                    jsonData += '"pasiekaNr": ${info[i].pasiekaNr},';
                    jsonData += '"ulNr": ${info[i].ulNr},';
                    jsonData += '"kategoria": "${info[i].kategoria}",';
                    jsonData += '"parametr": "${info[i].parametr}",';
                    jsonData += '"wartosc": "${info[i].wartosc}",';
                    jsonData += '"miara": "${info[i].miara}",';
                    jsonData += '"pogoda": "${info[i].pogoda}",';
                    jsonData += '"temp": "${info[i].temp}",';
                    jsonData += '"czas": "${info[i].czas}",';
                    jsonData += '"uwagi": "${info[i].uwagi}",';
                    jsonData += '"arch": ${info[i].arch}}';
                    i++;
                    if (info.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${info.length}, "tabela":"${mem[0].kod.substring(0, 4)}_info"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        wyslijBackupInfo(jsonData); //jsonData
                      } else {
                       // print('braaaaaak internetu');
                        Navigator.of(context).pop();

                        _showAlertAnuluj(
                            context,
                            AppLocalizations.of(context)!.alert,
                            AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli sa ramki do archiwizacji
              });

               
              //BACKUP tabeli zdjecia - tylko wpisy z arch=0
              Provider.of<Photos>(context, listen: false)
                  .fetchAndSetPhotosToArch()
                  .then((_) {
                final photosArchData =
                    Provider.of<Photos>(context, listen: false);
                final zdjecia = photosArchData.items;
                iloscDoWyslania += zdjecia.length;
                _updateProgress(AppLocalizations.of(context)!.pHotos + '...');

                if (zdjecia.length > 0) {
                  _wyslijZdjeciaPoJednym(zdjecia, mem, 0);
                }
              }); //od pobrania zdjec

              
              
              //BACKUP tabeli ramka - tylko wpisy z arch=0
              Provider.of<Frames>(context, listen: false)
                  .fetchAndSetFramesToArch()
                  .then((_) {
                final framesArchData =
                    Provider.of<Frames>(context, listen: false);
                final ramki = framesArchData.items;
                // print('ilość nowych wpisów w tabeli ramka');
                // print(ramki.length);

                //informacja o ilości rekordów do wysłania
                iloscDoWyslania += ramki.length;
                _updateProgress(AppLocalizations.of(context)!.frames + '...');
                if (iloscDoWyslania > 0)
                  _showAlertOK(
                      context,
                      AppLocalizations.of(context)!.alert,
                      AppLocalizations.of(context)!.dataToSend +
                          ' = $iloscDoWyslania');
                else
                  _showAlertOK(context, AppLocalizations.of(context)!.alert,
                      AppLocalizations.of(context)!.noDataToSend);

                if (ramki.length > 0) {
                  String jsonData = '{"ramka":[';
                  int i = 0;
                  while (ramki.length > i) {
                    jsonData += '{"id": "${ramki[i].id}",';
                    jsonData += '"data": "${ramki[i].data}",';
                    jsonData += '"pasiekaNr": ${ramki[i].pasiekaNr},';
                    jsonData += '"ulNr": ${ramki[i].ulNr},';
                    jsonData += '"korpusNr": ${ramki[i].korpusNr},';
                    jsonData += '"typ": ${ramki[i].typ},';
                    jsonData += '"ramkaNr": ${ramki[i].ramkaNr},';
                    jsonData += '"ramkaNrPo": ${ramki[i].ramkaNrPo},';
                    jsonData += '"rozmiar": ${ramki[i].rozmiar},';
                    jsonData += '"strona": ${ramki[i].strona},';
                    jsonData += '"zasob": ${ramki[i].zasob},';
                    jsonData += '"wartosc": "${ramki[i].wartosc}",';
                    jsonData += '"arch": ${ramki[i].arch}}';
                    i++;
                    if (ramki.length > i) jsonData += ',';
                  }
                  jsonData +=
                      '],"total":${ramki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_ramka"}'; //pierwsze cztery cyfry kodu ramka_XXXX

                  //print(jsonData);
                  _isInternet().then(
                    (inter) {
                      if (inter) {
                        //print('$inter - jest internet');
                        wyslijBackupRamka(jsonData); //jsonData
                      } else {
                        //print('braaaaaak internetu');
                        // _showAlertAnuluj(
                        //     context,
                        //     AppLocalizations.of(context)!.alert,
                        //     AppLocalizations.of(context)!.noInternet);
                      }
                    },
                  );
                } else {
                  // _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                  //     AppLocalizations.of(context)!.noDataToSend);
                } //jeśli ramki do archiwizacji
              }); //od pobrania ramek

     
   
            },
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }

  
  //kasowanie zawartości wszystkich tabeli 
  void _showAlertDeleteRamkaInfo(
      BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              DBHelper.deleteTable('ramka').then((_) {
                DBHelper.deleteTable('info').then((_) {
                  DBHelper.deleteTable('ule').then((_) {
                    DBHelper.deleteTable('pasieki').then((_) {
                      DBHelper.deleteTable('zbiory').then((_) {
                        DBHelper.deleteTable('sprzedaz').then((_) {
                          DBHelper.deleteTable('zakupy').then((_) {
                            DBHelper.deleteTable('notatki').then((_) {
                              DBHelper.deleteTable('matki').then((_) {
                                //pobranie wszystkich pasiek z tabeli pasieki z bazy lokalnej
                                //zeby wykasowaćdane o pasiekach z pamięci
                                Provider.of<Apiarys>(context, listen: false)
                                    .fetchAndSetApiarys()
                                    .then((_) {
                                  Navigator.of(context).pop();
                                });
                              });
                            });
                          });
                        });
                      });
                    });
                  });
                });
              });
            },
            child: Text(AppLocalizations.of(context)!.dElete),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }




  //kasowanie danych na serwerze zewnętrznym (w chmurze)
  void _showAlertDeleteDataOnSerwer(
      BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              WyslijPolecenieKasowania();
                                               
            },
            child: Text(AppLocalizations.of(context)!.dElete),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }


//wyslania polecenia kasowania wszystkich danych  na serwerze w chmurze
  Future<void> WyslijPolecenieKasowania() async {
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_del_database.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "kod_mobile": globals.kod,
        "deviceId": globals.deviceId,
        "wersja": globals.wersja,
        "jezyk": globals.jezyk,
      }),
    );
    //print('$kod ${globals.deviceId} $wersja ${globals.jezyk}');
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        _showAlertOK(context, AppLocalizations.of(context)!.success,
            AppLocalizations.of(context)!.deleteOk );//+ odpPost['be_do']);
        //zapis do bazy lokalnej z bazy www
        // DBHelper.deleteTable('memory').then((_) {
        //   //kasowanie tabeli bo będzie nowy wpis
        //   Memory.insertMemory(
        //     odpPost['be_id'], //id
        //     odpPost['be_email'],
        //     //ponizej wstawone wartosci deviceId i wersja z apki, bo www nie zdązy ich zapisać i nie ma ich po pobraniu
        //     //globals.deviceId, //
        //     odpPost['be_dev'], //deviceId
        //     //wersja, //
        //     odpPost['be_wersja'], //wersja apki
        //     odpPost['be_kod'], //kod
        //     odpPost['be_key'], //accessKey
        //     odpPost['be_od'], //data od
        //     odpPost['be_do'], // do data
        //     '', //globals.memJezyk, //memjezyk - język ustawiony w Ustawienia/Język apki
        //     '', //zapas
        //     '', //zapas
        //   );
        // });
      } else {
        _showAlertOK(context, AppLocalizations.of(context)!.alert,
            AppLocalizations.of(context)!.errorWhileActivating);
        // print('brak danych dla tej apki');
      }

      //Navigator.of(context).pushNamed(OrderScreen.routeName);
      //}
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }




  //wysyłanie backupu ramka
  Future<void> wyslijBackupRamka(String jsonData1) async {
    //String jsonData1
    //print("z funkcji wysyłania");
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v8.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela ramka w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Frames>(context, listen: false)
            .fetchAndSetFramesToArch() //pobranie z bazy lokalnej ramki z arch=0 zeby zmianic na arch=1
            .then((_) {
          //dla tabeli RAMKI
          final framesAllData = Provider.of<Frames>(context, listen: false);
          final ramki = framesAllData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli ramka');
          //print(ramki.length);
          int i = 0;
          while (ramki.length > i) {
            DBHelper.updateRamkaArch(ramki[i].id); //zapis arch = 1
            i++;
            //print('po wysłaniu $i');
          }
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          //komunikat na dole ekranu
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.inspectionDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu info
  Future<void> wyslijBackupInfo(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v8.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Infos>(context, listen: false)
            .fetchAndSetInfosToArch()
            .then((_) {
          //dla tabeli INFO
          final infoArchData = Provider.of<Infos>(context, listen: false);
          final info = infoArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli info');
          //print(info.length);
          int i = 0;
          while (info.length > i) {
            DBHelper.updateInfoArch(info[i].id); //zapis arch = 1
            i++;
            //print(i);
          }
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.infoDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu zbiory
  Future<void> wyslijBackupZbiory(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v8.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Harvests>(context, listen: false)
            .fetchAndSetZbioryToArch()
            .then((_) {
          //dla tabeli ZBIORY
          final zbioryArchData = Provider.of<Harvests>(context, listen: false);
          final zbiory = zbioryArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli zbiory');
          //print(zbiory.length);
          int i = 0;
          while (zbiory.length > i) {
            DBHelper.updateZbioryArch(zbiory[i].id); //zapis arch = 1
            i++;
          }
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.harvestDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu sprzedaz
  Future<void> wyslijBackupSprzedaz(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v8.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Sales>(context, listen: false)
            .fetchAndSetSprzedazToArch()
            .then((_) {
          //dla tabeli SPRZEDAZ
          final sprzedazArchData = Provider.of<Sales>(context, listen: false);
          final sprzedaz = sprzedazArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli sprzedaz');
          //print(sprzedaz.length);
          int i = 0;
          while (sprzedaz.length > i) {
            DBHelper.updateSprzedazArch(sprzedaz[i].id); //zapis arch = 1
            i++;
          }
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.saleDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu matki
  Future<void> wyslijBackupMatki(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v8.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Queens>(context, listen: false)
            .fetchAndSetQueensToArch()
            .then((_) {
          //dla tabeli Matki
          final matkiArchData = Provider.of<Queens>(context, listen: false);
          final matki = matkiArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli matki');
          //print(matki.length);
          int i = 0;
          while (matki.length > i) {
            DBHelper.updateMatkiArch(matki[i].id); //zapis arch = 1
            i++;
          }

//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.queenDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu zakupów
  Future<void> wyslijBackupZakupy(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v8.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
  //zapis do bazy lokalnej
        Provider.of<Purchases>(context, listen: false)
            .fetchAndSetZakupyToArch()
            .then((_) {
    //dla tabeli ZAKUPY
          final zakupyArchData = Provider.of<Purchases>(context, listen: false);
          final zakupy = zakupyArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli sprzedaz');
          //print(sprzedaz.length);
          int i = 0;
          while (zakupy.length > i) {
            DBHelper.updateZakupyArch(zakupy[i].id); //zapis arch = 1
            i++;
          }
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.purchaseDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu notatek
  Future<void> wyslijBackupNotatki(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v8.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("notatki - response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') { //jezeli wysyłka się powiodła
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        
        //zapis do bazy lokalnej informacji ze zarchiwizowano nowe notatki
        Provider.of<Notes>(context, listen: false) //DBHelper - pobieranie z tabeli notatki do achiwizacji notatek z arch=0
            .fetchAndSetNotatkiToArch() //wczytanie wszystkich nowych zbiorów --> NotatkiToArch <---
            .then((_) {
          //dla tabeli NOTATKI
          final notatkiArchData = Provider.of<Notes>(context, listen: false);
          final notatki = notatkiArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli sprzedaz');
          //print(sprzedaz.length);
          int i = 0;
          while (notatki.length > i) {
            DBHelper.updateNotatkiArch(notatki[i].id); //zapis arch = 1
            i++;
          }
//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noteDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  
  //PĘTLA WYSYŁANIA ZDJĘĆ (PO JEDNYM)
  //wysyłanie zdjęć po jednym (Base64 duże pliki) encodr pfoto + przygotowanie jsonData i wyslijBackupZdjecia
  void _wyslijZdjeciaPoJednym(List<Photo> zdjecia, List<dynamic> mem, int index) async {
    if (index >= zdjecia.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.photoDataSend),
        ),
      );
      return;
    }

    final photo = zdjecia[index];
    String base64Data = '';
    try {
      final file = File(photo.sciezka);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        base64Data = base64Encode(bytes);
      }
    } catch (e) {
      //plik nie istnieje - wysyłamy same metadane
    }

    //wyciągnięcie samej nazwy pliku ze ścieżki
    final fileName = photo.sciezka.split('/').last;

    String jsonData = '{"zdjecia":[';
    jsonData += '{"id": "${photo.id}",';
    jsonData += '"data": "${photo.data}",';
    jsonData += '"czas": "${photo.czas}",';
    jsonData += '"pasiekaNr": ${photo.pasiekaNr},';
    jsonData += '"ulNr": ${photo.ulNr},';
    jsonData += '"sciezka": "$fileName",';
    jsonData += '"uwagi": "${photo.uwagi}",';
    jsonData += '"arch": ${photo.arch},';
    jsonData += '"base64": "$base64Data"}';
    jsonData += '],"total":1, "tabela":"${mem[0].kod.substring(0, 4)}_zdjecia"}';

    _isInternet().then((inter) {
      if (inter) {
        wyslijBackupZdjecia(jsonData, zdjecia, mem, index);
      }
    });
  }

  //wysyłanie jednego zdjęcia i jeśli ok to przygotowanie następnego w _wyslijZdjeciaPoJednym
  Future<void> wyslijBackupZdjecia(String jsonData1, List<Photo> zdjecia, List<dynamic> mem, int index) async {
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v8.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1,
    );
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        //oznaczenie zdjęcia jako zarchiwizowane
        DBHelper.updatePhotoArch(zdjecia[index].id);
        //wysłanie następnego zdjęcia
        _wyslijZdjeciaPoJednym(zdjecia, mem, index + 1);
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  
  //eksport wszystkich danych Zdjecia - z progress barem per zdjęcie
  void _showAlertExportAllZdjecia(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              if (!await _isInternet()) {
                Navigator.of(context).pop();
                _showAlertAnuluj(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noInternet);
                return;
              }
              iloscDoWyslania = 0;
              final memData = Provider.of<Memory>(context, listen: false);
              final mem = memData.items;
              final prefix = mem[0].kod.substring(0, 4);

              await Provider.of<Photos>(context, listen: false).fetchAndSetPhotos();
              final zdjecia = Provider.of<Photos>(context, listen: false).items;
              iloscDoWyslania = zdjecia.length;

              int totalSteps = zdjecia.isEmpty ? 1 : zdjecia.length;
              showProgressDialog(context, AppLocalizations.of(context)!.eXportData, totalSteps);
              await Future.delayed(const Duration(milliseconds: 500));

              // wysyłanie zdjęć po jednym
              for (int i = 0; i < zdjecia.length; i++) {
                _updateProgress('${AppLocalizations.of(context)!.pHotos} ${i + 1}/${zdjecia.length}...');
                await _wyslijJednoZdjecieAwait(zdjecia[i], prefix);
              }
              if (zdjecia.isEmpty) _updateProgress('${AppLocalizations.of(context)!.pHotos}...');

              if (iloscDoWyslania > 0)
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.dataToSend + ' = $iloscDoWyslania');
              else
                _showAlertOK(context, AppLocalizations.of(context)!.alert,
                    AppLocalizations.of(context)!.noDataToSend);
            },
            child: Text(AppLocalizations.of(context)!.eXport),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible: false,
    );
  }

 
 
 
 @override
  Widget build(BuildContext context) {
    //komunikat = AppLocalizations.of(context)!.dopisanieDoBazy;

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(
            AppLocalizations.of(context)!.zarzadzanieDanymi,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey[300], // kolor linii
              height: 1.0,
            ),
          ),
        ),
        body: ListView(
          children: <Widget>[

//import danych
            GestureDetector(
              onTap: () {
                _showAlertImport(context, (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.importowanie));
                //Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.import, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(AppLocalizations.of(context)!.dopisanieDoBazy),//Text(komunikat),
                  //trailing: Icon(Icons.chevron_right),
                ),
              ),
            ),

//eksport nowych danych teraz
            GestureDetector(
              onTap: () {
                _showAlertExportNewV3(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.exportNewData));
                //Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.exportNewToCloud, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(AppLocalizations.of(context)!.onlyNew),
                ),
              ),
            ),

//eksport danych automatycznie przy uruchamianiu aplikacji
            Card(
              child: ListTile(
                //leading: Icon(Icons.settings),
                title: Text(AppLocalizations.of(context)!.autoEksportDoChmury, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text(AppLocalizations.of(context)!.onlyInspection),
                trailing: Switch.adaptive(
                  value: isSwitched,
                  onChanged: (value) {
                    DBHelper.updateDodatki1('a', '$value');
                    setState(() {
                      isSwitched = value;
                      //print(isSwitched);
                    });
                  },
                ),
              ),
            ),
                
                // setState(() {
                //   wyborDanych ? wyborDanych = false : wyborDanych = true;
                //   //print(isSwitched);
                // });

//eksport wwszystkich danych teraz         
            GestureDetector(
              onTap: () {
                _showAlertExportAllV3(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.exportAllData));
                //Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.exportAllToCloud, style: const TextStyle(fontWeight: FontWeight.bold)),//wszystkich wybranych
                  subtitle: Text(AppLocalizations.of(context)!.backupAllData),
                ),
              ),
            ),  




//eksport wybranych danych Notatki
            GestureDetector(
              onTap: () {               
                _showAlertExportAllNotatki(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.nOtes + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.nOtes),
                  subtitle: Text(AppLocalizations.of(context)!.eXportNote),
                ),
              ),
            ),

//eksport wybranych danych Zbiory
            GestureDetector(
              onTap: () {               
                _showAlertExportAllZbiory(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.hArvests + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.hArvests),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportHarvest),
                ),
              ),
            ),          

//eksport wybranych danych Zakupy
            GestureDetector(
              onTap: () {               
                _showAlertExportAllZakupy(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.pUrchase + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.pUrchase),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportPurchase),
                ),
              ),
            ), 

//eksport wybranych danych Sprzedaz
            GestureDetector(
              onTap: () {               
                _showAlertExportAllSprzedaz(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.sAle + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.sAle),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportSale),
                ),
              ),
            ),  

//eksport wybranych danych Matki
            GestureDetector(
              onTap: () {               
                _showAlertExportAllMatki(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.qUeens + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.qUeens),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportQueens),
                ),
              ),
            ), 

//eksport wybranych danych Ramki
            GestureDetector(
              onTap: () {               
                _showAlertExportAllRamki(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.fRames + '. ' + AppLocalizations.of(context)!.exportDataToCloud)); 
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.fRames),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportFrame),
                ),
              ),
            ),  

//eksport wybranych danych Info
            GestureDetector(
              onTap: () {
                _showAlertExportAllInfo(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.iNfos + '. ' + AppLocalizations.of(context)!.exportDataToCloud));
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.iNfos),//(AppLocalizations.of(context)!.exportAllToCloud),
                  subtitle: Text(AppLocalizations.of(context)!.eXportInfo),
                ),
              ),
            ),

//eksport wybranych danych Zdjecia
            GestureDetector(
              onTap: () {
                _showAlertExportAllZdjecia(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.pHotos + '. ' + AppLocalizations.of(context)!.exportDataToCloud));
              },
              child: Card(
                child: ListTile(
                  title: Text(AppLocalizations.of(context)!.pHotos),
                  subtitle: Text(AppLocalizations.of(context)!.eXportPhoto),
                ),
              ),
            ),

//import Zdjecia
            // GestureDetector(
            //   onTap: () {
            //       Photos.fetchZdjeciaFromSerwer(
            //       'https://darys.pl/cbt.php?d=f_zdjecia&kod=${globals.kod}&tab=${globals.kod.substring(0, 4)}_zdjecia')
            //         .then((_) {
            //           Provider.of<Photos>(context, listen: false)
            //               .fetchAndSetPhotosForHive(0, 0); //odswiezenie - nie jest kluczowe
            //         });
            //       },
            //   child: Card(
            //     child: ListTile(
            //       title: Text(AppLocalizations.of(context)!.pHotos),
            //       subtitle: Text(AppLocalizations.of(context)!.import),
            //     ),
            //   ),
            // ),

 
       


//usunięcie wszystkich danych w tabelach lokalnych
            GestureDetector(
              onTap: () {
                _showAlertDeleteRamkaInfo(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.deleteRamkaInfo)); //usunięcie wszystkich danych lokalnie
                //Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.deleteAllData, style: const TextStyle(color: Color.fromARGB(255, 252, 1, 1))),
                  subtitle: Text(AppLocalizations.of(context)!.onlyInLocalDatabase),
                ),
              ),
            ),

//usunięcie wszystkich danych w chmurze (zmiany nazw tabeli na" data_czas_prefix_nazwaTabeli"
            GestureDetector(
              onTap: () {
                _showAlertDeleteDataOnSerwer(
                    context,
                    (AppLocalizations.of(context)!.alert),
                    (AppLocalizations.of(context)!.deleteDataOnSerwer));
                //Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
              child: Card(
                child: ListTile(
                  //leading: Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.deleteAllDataOnSerwer, style: const TextStyle(color: Color.fromARGB(255, 252, 1, 1))),
                  subtitle: Text(AppLocalizations.of(context)!.allDatabaseOnSerwer),
                ),
              ),
            ),



//polityka prywatności
//             GestureDetector(
//               onTap: () {
//                 //czy jest internet
//                 _isInternet().then((inter) {
//                   if (inter != null && inter) {
//                     _launchURL(
//                         'https://www.cobytu.com/index.php?d=polityka&mobile=1');
//                     // Navigator.of(context).pushNamed(LanguagesScreen.routeName);
//                   } else {
//                     print('braaaaaak internetu');
//                     _showAlertAnuluj(
//                         context,
//                         allTranslations.text('L_BRAK_INTERNETU'),
//                         allTranslations.text('L_URUCHOM_INTERNETU'));
//                   }
//                 });
//               },
//               child: Card(
//                 child: ListTile(
//                   leading: Icon(Icons.security),
//                   title: Text(allTranslations.text('L_POLITYKA')),
//                   trailing: Icon(Icons.chevron_right),
//                 ),
//               ),
//             ),

// //regulamin
//             GestureDetector(
//               onTap: () {
//                 //czy jest internet
//                 _isInternet().then((inter) {
//                   if (inter != null && inter) {
//                     _launchURL(
//                         'https://www.cobytu.com/index.php?d=regulamin&mobile=1');
//                     // Navigator.of(context).pushNamed(LanguagesScreen.routeName);
//                   } else {
//                     print('braaaaaak internetu');
//                     _showAlertAnuluj(
//                         context,
//                         allTranslations.text('L_BRAK_INTERNETU'),
//                         allTranslations.text('L_URUCHOM_INTERNETU'));
//                   }
//                 });
//               },
//               child: Card(
//                 child: ListTile(
//                   leading: Icon(Icons.library_books),
//                   title: Text(allTranslations.text('L_REGULAMIN')),
//                   trailing: Icon(Icons.chevron_right),
//                 ),
//               ),
//             ),

            /* Card(child: ListTile(title: Text('One-line ListTile'))),
            Card(
              child: ListTile(
                leading: FlutterLogo(),
                title: Text('One-line with leading widget'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('One-line with trailing widget'),
                trailing: Icon(Icons.more_vert),
              ),
            ), 
        
            Card(
              child: ListTile(
                title: Text('One-line dense ListTile'),
                dense: true,
              ),
            ),
            Card(
              child: ListTile(
                leading: FlutterLogo(size: 56.0),
                title: Text('Two-line ListTile'),
                subtitle: Text('Here is a second line'),
                trailing: Icon(Icons.more_vert),
              ),
            ),
            Card(
              child: ListTile(
                leading: FlutterLogo(size: 72.0),
                title: Text('Three-line ListTile'),
                subtitle: Text(
                  'A sufficiently long subtitle warrants three lines.'
                ),
                trailing: Icon(Icons.more_vert),
                isThreeLine: true,
              ),
           ),
       */
          ],
        ));
  }
}

