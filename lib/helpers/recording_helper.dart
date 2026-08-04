import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'db_helper.dart';

/// Nagrania dyktowanych notatek - pliki na telefonie plus wpisy w tabeli
/// "nagrania".
///
/// PO CO TO JEST: transkrypcja z Vosk bywa przekręcona (mały model, praca przy
/// ulu, wiatr w mikrofon). Nagranie jest DOWODEM - gdy tekst notatki jest
/// nieczytelny, użytkownik odsłuchuje, co naprawdę powiedział. Dlatego tekst i
/// dźwięk są NIEZALEŻNE: brak nagrania nie psuje notatki, a brak tekstu (model
/// nic nie rozpoznał) nie kasuje nagrania.
///
/// USTALENIA (04.08.2026):
/// - nagrywana jest WYŁĄCZNIE dyktowana notatka, nie cała sesja głosowa,
/// - nagrania zostają NA TELEFONIE - do chmury (darys.pl) nie idą wcale,
///   w archiwum jest sam tekst notatki. Stąd brak odpowiednika
///   `_wyslijJednoZdjecieAwait` i pola `arch`, które przy zdjęciach steruje
///   wysyłką (tu zostaje 0 na zawsze),
/// - plik ginie razem z notatką albo po [dniPrzechowywania] dniach - patrz
///   [sprzataj].
///
/// FORMAT: WAV PCM 16-bit LE, 16 kHz, mono - dokładnie to, co silnik podaje
/// recognizerowi (VoskEngine._karmDyktowanie). Nic nie przekodowujemy: bajty są
/// już w pamięci, a każdy kodek to albo nowa zależność, albo drugi strumień
/// audio - czyli ta klasa błędów iOS, która kosztowała najwięcej czasu w
/// migracji na Vosk. Cena: 32 kB na sekundę, czyli ~2,9 MB przy twardym limicie
/// notatki (90 s). Przy tygodniowym przechowywaniu i braku wysyłki to nie ma
/// znaczenia.
class RecordingHelper {
  RecordingHelper._();

  /// Parametry strumienia z VoskEngine. Muszą się zgadzać, bo nagłówek WAV
  /// opisuje bajty, których sami nie oglądamy.
  static const int rate = 16000;
  static const int kanaly = 1;
  static const int bitow = 16;

  /// Bajtów na sekundę dźwięku - do przeliczania rozmiaru na czas.
  static const int bajtowNaSekunde = rate * kanaly * (bitow ~/ 8);

  /// Po tylu dniach nagranie znika samo (sprzątanie przy starcie aplikacji).
  /// Notatka ZOSTAJE - kasujemy wyłącznie dźwięk, który po tygodniu nikomu już
  /// nie służy do sprawdzania transkrypcji, a zajmuje megabajty.
  static const int dniPrzechowywania = 7;

  /// Nazwa katalogu w Documents. Osobny, żeby sprzątanie nigdy nie sięgnęło
  /// zdjęć (te leżą w `photos` i mają zupełnie inny cykl życia).
  static const String _katalog = 'nagrania';

  /// Źródła nagrania - do czego jest przypięte.
  static const String zrodloPrzeglad = 'inspection'; // uwagi rekordu przeglądu
  static const String zrodloNotes = 'notes'; // wpis w tabeli "notatki"

  static Future<Directory> katalog() async {
    final Directory app = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${app.path}/$_katalog');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Pełna ścieżka pliku nagrania.
  ///
  /// W bazie trzymamy SAMĄ NAZWĘ pliku, a nie ścieżkę - katalog Documents na
  /// iOS ma w ścieżce identyfikator kontenera, który zmienia się przy
  /// aktualizacji aplikacji. Zapisana ścieżka bezwzględna wskazywałaby wtedy w
  /// pustkę (tak działają dziś zdjęcia - `sciezka` z pełną ścieżką).
  static Future<File> plik(String nazwa) async {
    final Directory dir = await katalog();
    return File('${dir.path}/$nazwa');
  }

  /// Ile sekund dźwięku to tyle bajtów PCM.
  static int sekundZBajtow(int bajty) =>
      (bajty / bajtowNaSekunde).round();

  /// Rozmiar do pokazania użytkownikowi ("1,4 MB").
  static String opisRozmiaru(int bajty) {
    if (bajty >= 1024 * 1024) {
      return '${(bajty / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
    }
    return '${(bajty / 1024).round()} kB';
  }

  /// Czas nagrania jako "0:07".
  static String opisCzasu(int sekundy) {
    final int m = sekundy ~/ 60;
    final int s = sekundy % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Zapisanie surowego PCM jako plik WAV plus wpis w bazie.
  ///
  /// Zwraca id nagrania albo null, gdy zapis się nie udał. NIE RZUCA: nagranie
  /// jest dodatkiem do notatki, a notatka jest już wtedy w bazie - awaria
  /// dźwięku nie ma prawa wyglądać jak nieudany zapis notatki.
  static Future<String?> zapisz({
    required Uint8List pcm,
    required String zrodlo,
    required String powiazanieId,
    required String data,
    required String czas,
    required int pasiekaNr,
    required int ulNr,
    required String tekst,
  }) async {
    if (pcm.isEmpty) return null;
    try {
      final String id = '${DateTime.now().millisecondsSinceEpoch}';
      final String nazwa = '$id.wav';
      final File f = await plik(nazwa);
      await f.writeAsBytes(_wav(pcm), flush: true);
      await DBHelper.insert('nagrania', {
        'id': id,
        'data': data,
        'czas': czas,
        'pasiekaNr': pasiekaNr,
        'ulNr': ulNr,
        'zrodlo': zrodlo,
        'powiazanieId': powiazanieId,
        'sciezka': nazwa,
        'sekundy': sekundZBajtow(pcm.length),
        'bajty': pcm.length + 44, // z nagłówkiem - tyle waży plik na dysku
        'tekst': tekst,
        'uwagi': '',
        'arch': 0, // nagrania nie idą do chmury - patrz opis klasy
      });
      debugPrint('Nagranie zapisane: $nazwa '
          '(${opisRozmiaru(pcm.length + 44)}, ${sekundZBajtow(pcm.length)} s)');
      return id;
    } catch (e) {
      debugPrint('Nagranie: zapis nie powiódł się - $e');
      return null;
    }
  }

  /// Skasowanie jednego nagrania - plik i wpis.
  static Future<void> usun(String id, String nazwaPliku) async {
    try {
      final File f = await plik(nazwaPliku);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('Nagranie: nie udało się skasować pliku $nazwaPliku - $e');
    }
    try {
      await DBHelper.deleteNagranie(id);
    } catch (e) {
      debugPrint('Nagranie: nie udało się skasować wpisu $id - $e');
    }
  }

  /// Skasowanie nagrań przypiętych do notatki albo przeglądu. Wołane RAZEM z
  /// kasowaniem tego, do czego są przypięte - stąd brak pytania o potwierdzenie.
  static Future<void> usunDla(String zrodlo, String powiazanieId) async {
    try {
      final List<Map<String, dynamic>> wpisy =
          await DBHelper.getNagraniaDla(zrodlo, powiazanieId);
      for (final Map<String, dynamic> w in wpisy) {
        await usun('${w['id']}', '${w['sciezka'] ?? ''}');
      }
    } catch (e) {
      debugPrint('Nagranie: kasowanie dla $zrodlo/$powiazanieId - $e');
    }
  }

  /// Sprzątanie przy starcie aplikacji. Trzy rzeczy naraz:
  ///  1. nagrania starsze niż [dniPrzechowywania],
  ///  2. SIEROTY - nagrania po notatce albo przeglądzie, którego już nie ma.
  ///     To jest jedyne miejsce, które ogarnia kasowanie kaskadowe (usunięty ul,
  ///     zlikwidowana pasieka, wyczyszczona baza przy imporcie): dopisywanie
  ///     kasowania nagrań do każdej takiej ścieżki byłoby nie do upilnowania,
  ///  3. pliki bez wpisu w bazie (przerwany zapis, ręczne grzebanie w plikach).
  ///
  /// NIE RZUCA i nie blokuje startu - to sprzątanie, a nie funkcja aplikacji.
  static Future<void> sprzataj() async {
    try {
      final String granica = DateTime.now()
          .subtract(const Duration(days: dniPrzechowywania))
          .toIso8601String()
          .substring(0, 10);

      final List<Map<String, dynamic>> wszystkie = await DBHelper.getNagrania();
      if (wszystkie.isEmpty) {
        await _usunOsieroconePliki(const <String>{});
        return;
      }

      final Set<String> idInfo = await DBHelper.getIdyTabeli('info');
      final Set<String> idNotatek = await DBHelper.getIdyTabeli('notatki');

      final Set<String> zostajace = <String>{};
      int stare = 0;
      int sieroty = 0;
      for (final Map<String, dynamic> w in wszystkie) {
        final String id = '${w['id']}';
        final String nazwa = '${w['sciezka'] ?? ''}';
        final String dataNagrania = '${w['data'] ?? ''}';
        final String zrodlo = '${w['zrodlo'] ?? ''}';
        final String powiazanie = '${w['powiazanieId'] ?? ''}';

        // Data krótsza niż 10 znaków = wpis nie do oceny; nie kasujemy niczego
        // "na wszelki wypadek", bo to jedyna kopia dźwięku.
        final bool przeterminowane =
            dataNagrania.length >= 10 && dataNagrania.compareTo(granica) < 0;
        final bool osierocone = zrodlo == zrodloPrzeglad
            ? !idInfo.contains(powiazanie)
            : zrodlo == zrodloNotes
                ? !idNotatek.contains(powiazanie)
                : false;

        if (przeterminowane || osierocone) {
          if (przeterminowane) stare++;
          if (osierocone && !przeterminowane) sieroty++;
          await usun(id, nazwa);
        } else if (nazwa.isNotEmpty) {
          zostajace.add(nazwa);
        }
      }
      final int plikow = await _usunOsieroconePliki(zostajace);
      if (stare + sieroty + plikow > 0) {
        debugPrint('Nagrania - sprzątanie: $stare przeterminowanych, '
            '$sieroty osieroconych, $plikow plików bez wpisu.');
      }
    } catch (e) {
      debugPrint('Nagrania: sprzątanie nie powiodło się - $e');
    }
  }

  /// Pliki w katalogu, których nie ma już w bazie. Zwraca liczbę skasowanych.
  static Future<int> _usunOsieroconePliki(Set<String> zostajace) async {
    int ile = 0;
    try {
      final Directory dir = await katalog();
      await for (final FileSystemEntity e in dir.list()) {
        if (e is! File) continue;
        final String nazwa = e.uri.pathSegments.last;
        if (zostajace.contains(nazwa)) continue;
        await e.delete();
        ile++;
      }
    } catch (e) {
      debugPrint('Nagrania: przegląd katalogu - $e');
    }
    return ile;
  }

  /// Ile miejsca zajmują wszystkie nagrania (do pokazania w Ustawieniach).
  static Future<int> zajeteMiejsce() async {
    int suma = 0;
    try {
      final Directory dir = await katalog();
      await for (final FileSystemEntity e in dir.list()) {
        if (e is File) suma += await e.length();
      }
    } catch (e) {
      debugPrint('Nagrania: liczenie miejsca - $e');
    }
    return suma;
  }

  /// Nagłówek WAV (44 bajty) doklejony do surowego PCM.
  static Uint8List _wav(Uint8List pcm) {
    final int dane = pcm.length;
    final ByteData h = ByteData(44);
    void znaki(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        h.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    znaki(0, 'RIFF');
    h.setUint32(4, 36 + dane, Endian.little); // rozmiar pliku - 8
    znaki(8, 'WAVE');
    znaki(12, 'fmt ');
    h.setUint32(16, 16, Endian.little); // długość bloku fmt
    h.setUint16(20, 1, Endian.little); // 1 = PCM bez kompresji
    h.setUint16(22, kanaly, Endian.little);
    h.setUint32(24, rate, Endian.little);
    h.setUint32(28, bajtowNaSekunde, Endian.little);
    h.setUint16(32, kanaly * (bitow ~/ 8), Endian.little); // blockAlign
    h.setUint16(34, bitow, Endian.little);
    znaki(36, 'data');
    h.setUint32(40, dane, Endian.little);

    final Uint8List out = Uint8List(44 + dane);
    out.setRange(0, 44, h.buffer.asUint8List());
    out.setRange(44, 44 + dane, pcm);
    return out;
  }
}
