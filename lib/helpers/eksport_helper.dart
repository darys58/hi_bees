import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../globals.dart' as globals;

//Eksport do pliku - PDF albo CSV (11.10.2026, prośba usera: "wszystkie pliki do
//wydruku także jako CSV"). Ikonka PDF na ekranach pokazuje najpierw menu z wyborem
//formatu ([wybierzFormat]); CSV powstaje z TYCH SAMYCH wierszy co tabela w PDF.
//
//Format CSV pod Excela/Numbers w ustawieniach europejskich:
//  - separator ';' (przy przecinku dziesiętnym Excel PL/DE/FR otwiera tak od razu
//    w kolumnach; przecinek jako separator rozjechałby liczby "12,50"),
//  - UTF-8 z BOM - bez niego Excel czyta polskie znaki jako Windows-1250,
//  - CRLF między wierszami, pole w cudzysłowie, gdy ma ; " albo nową linię.

enum FormatEksportu { pdf, csv }

/// Menu wyboru formatu. null = użytkownik zamknął menu bez wyboru.
Future<FormatEksportu?> wybierzFormat(BuildContext context) {
  return showModalBottomSheet<FormatEksportu>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('PDF'),
            onTap: () => Navigator.of(ctx).pop(FormatEksportu.pdf),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('CSV'),
            onTap: () => Navigator.of(ctx).pop(FormatEksportu.csv),
          ),
        ],
      ),
    ),
  );
}

/// Liczba do CSV - przecinek dziesiętny przy formacie europejskim (jak w apce i PDF),
/// bez separatora tysięcy, żeby arkusz rozpoznał ją jako liczbę.
String liczbaCsv(num wartosc, {int miejsca = 2}) {
  final String s = wartosc.toStringAsFixed(miejsca);
  return globals.isEuropeanFormat() ? s.replaceAll('.', ',') : s;
}

String _pole(String tekst) {
  if (tekst.contains(';') || tekst.contains('"') || tekst.contains('\n') || tekst.contains('\r')) {
    return '"${tekst.replaceAll('"', '""')}"';
  }
  return tekst;
}

/// Wiersze -> tekst CSV (bez BOM).
String zbudujCsv(List<List<String>> wiersze) =>
    wiersze.map((w) => w.map(_pole).join(';')).join('\r\n') + '\r\n';

/// Zapis do pliku tymczasowego i systemowe "Udostępnij" (poczta, Pliki, Dysk...).
/// [nazwaPliku] bez rozszerzenia. Błąd - SnackBar, jak przy PDF.
Future<void> udostepnijCsv(BuildContext context, String nazwaPliku, List<List<String>> wiersze) async {
  //iOS wymaga niezerowego prostokąta, z którego wysuwa się okno udostępniania
  //("sharePositionOrigin: argument must be set") - środek ekranu, 1x1. Czytane
  //przed pierwszym await (context po await to ostrzeżenie analizatora).
  final Size ekran = MediaQuery.of(context).size;
  try {
    final dir = await getTemporaryDirectory();
    final String bezpieczna = nazwaPliku.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
    final File plik = File('${dir.path}/$bezpieczna.csv');
    //BOM (EF BB BF) + UTF-8
    await plik.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(zbudujCsv(wiersze))]);
    await Share.shareXFiles(
      [XFile(plik.path, mimeType: 'text/csv', name: '$bezpieczna.csv')],
      subject: nazwaPliku,
      sharePositionOrigin: Rect.fromLTWH(ekran.width / 2, ekran.height / 2, 1, 1),
    );
  } catch (e) {
    debugPrint('Błąd eksportu CSV: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV error: $e')));
    }
  }
}
