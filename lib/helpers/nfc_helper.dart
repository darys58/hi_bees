import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../helpers/db_helper.dart';
import '../globals.dart' as globals;
import '../models/hives.dart';
import '../screens/infos_screen.dart';
import '../screens/summary_screen.dart';
import '../widgets/nfc_hive_selection_dialog.dart';

class NfcHelper {

 
  // Sprawdzenie dostepnosci NFC
  static Future<bool> isNfcAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  // Glowna logika skanowania NFC
  static Future<void> handleNfcScan(BuildContext context) async {
    bool isAvailable = await isNfcAvailable();

    if (!isAvailable) {
      _showNfcNotAvailableDialog(context);
      return;
    }

   // _showScanningDialog(context);

    try {
      NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso15693}, //bez tego wywala się bład
        onDiscovered: (NfcTag tag) async {
          try {
            String? tagId = _extractTagId(tag); // Wyodrebnienie ID z tagu NFC

            if (tagId == null) {
              Navigator.of(context).pop(); // Zamknij dialog skanowania jezeli nie odczytano taga
              _showErrorDialog(context, AppLocalizations.of(context)!.nfcTagReadError1);
              NfcManager.instance.stopSession();
              return;
            }

           // Navigator.of(context).pop(); // Zamknij dialog skanowania, potrzebne jazeli działa _showScanningDialog(context);1

            // Szukanie ula przypisanego do tagu
            final hiveData = await _findHiveByNfcTag(tagId);

            if (hiveData != null) {
              // Tag jest przypisany - nawiguj do ula
              await _navigateToHive(context, hiveData);
            } else {
              // Tag nie jest przypisany - pokaz dialog wyboru ula
              _showHiveSelectionDialog(context, tagId);
            }

            NfcManager.instance.stopSession();
          } catch (e) {
            Navigator.of(context).pop();
            _showErrorDialog(context, AppLocalizations.of(context)!.nfcTagReadError2);
            NfcManager.instance.stopSession();
          }
        },
        // onError: (error) async {
        //   //Navigator.of(context).pop();
        //   _showErrorDialog(context, AppLocalizations.of(context)!.nfcTagReadError3);
        // },
      );
  
  
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog(context, AppLocalizations.of(context)!.nfcTagReadError4);
    }
  }

  // Wyodrebnienie ID z tagu NFC
  static String? _extractTagId(NfcTag tag) {
    try {
      // Probujemy rozne technologie NFC
      final nfcA = tag.data['nfca'];
      if (nfcA != null && nfcA['identifier'] != null) {
        return _bytesToHex(Uint8List.fromList(List<int>.from(nfcA['identifier'])));
      }

      final nfcB = tag.data['nfcb'];
      if (nfcB != null && nfcB['identifier'] != null) {
        return _bytesToHex(Uint8List.fromList(List<int>.from(nfcB['identifier'])));
      }

      final nfcV = tag.data['nfcv'];
      if (nfcV != null && nfcV['identifier'] != null) {
        return _bytesToHex(Uint8List.fromList(List<int>.from(nfcV['identifier'])));
      }

      final miFare = tag.data['mifare'];
      if (miFare != null && miFare['identifier'] != null) {
        return _bytesToHex(Uint8List.fromList(List<int>.from(miFare['identifier'])));
      }

      final iso15693 = tag.data['iso15693'];
      if (iso15693 != null && iso15693['identifier'] != null) {
        return _bytesToHex(Uint8List.fromList(List<int>.from(iso15693['identifier'])));
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Konwersja bajtow na hex string
  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
  }

  // Wyszukanie ula po tagu NFC
  static Future<Map<String, dynamic>?> _findHiveByNfcTag(String tagId) async {
    final hives = await DBHelper.getHiveByH3(tagId);
    if (hives.isNotEmpty) {
      return hives.first;
    }
    return null;
  }

  // Nawigacja do ula
  static Future<void> _navigateToHive(BuildContext context, Map<String, dynamic> hiveData) async {
    globals.pasiekaID = hiveData['pasiekaNr'];
    globals.ulID = hiveData['ulNr'];
    globals.typUla = hiveData['h2'] ?? '0';
    globals.dataAktualnegoPrzegladu = '';

    if (globals.nfcMode == 'summary') {

      // Pobierz dane uli dla pasieki przed nawigacją do podsumowania
      await Provider.of<Hives>(context, listen: false)
          .fetchAndSetHives(hiveData['pasiekaNr']).then((_) {
        Navigator.of(context).pushNamed(
          SummaryScreen.routeName,
          arguments: <String, int>{'ulNr': hiveData['ulNr'] as int, 'pasiekaNr': hiveData['pasiekaNr'] as int},
        );
      });
    } else {
      Navigator.of(context).pushNamed(
        InfoScreen.routeName,
        arguments: hiveData['ulNr'],
      );
    }
  }

  // Dialog podczas skanowania
  // static void _showScanningDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (context) => AlertDialog(
  //       title: Text(AppLocalizations.of(context)!.nfcScanning),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const CircularProgressIndicator(),
  //           const SizedBox(height: 20),
  //           Text(AppLocalizations.of(context)!.nfcHoldNearTag),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             NfcManager.instance.stopSession();
  //             Navigator.of(context).pop();
  //           },
  //           child: Text(AppLocalizations.of(context)!.cancel),
  //         ),
  //       ],
  //     ),
  //   ).then((_) {
  //     // Zatrzymaj sesje NFC jesli dialog zostal zamkniety
  //     NfcManager.instance.stopSession();
  //   });
  // }

  // Dialog NFC niedostepne
  static void _showNfcNotAvailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.alert),
        content: Text(AppLocalizations.of(context)!.nfcNotAvailable),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Dialog bledu
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Dialog wyboru ula dla nowego tagu
  static void _showHiveSelectionDialog(BuildContext context, String tagId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NfcHiveSelectionDialog(tagId: tagId),
    );
  }
}
