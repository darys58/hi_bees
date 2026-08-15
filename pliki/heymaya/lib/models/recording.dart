import 'package:flutter/foundation.dart';

import '../helpers/db_helper.dart';
import '../helpers/recording_helper.dart';

/// Nagranie dyktowanej notatki. Plik leży w Documents/nagrania, a tutaj jest
/// jego opis - patrz [RecordingHelper] (tam też powód, dla którego [sciezka] to
/// sama nazwa pliku, a nie ścieżka bezwzględna).
class Recording {
  const Recording({
    required this.id,
    required this.data,
    required this.czas,
    required this.pasiekaNr,
    required this.ulNr,
    required this.zrodlo,
    required this.powiazanieId,
    required this.sciezka,
    required this.sekundy,
    required this.bajty,
    required this.tekst,
  });

  final String id;
  final String data;
  final String czas;
  final int pasiekaNr;
  final int ulNr;

  /// 'inspection' albo 'notes' - patrz stałe w [RecordingHelper].
  final String zrodlo;

  /// id rekordu, do którego nagranie jest przypięte (info.id albo notatki.id).
  final String powiazanieId;

  /// Sama nazwa pliku, np. "1754308800000.wav".
  final String sciezka;

  final int sekundy;
  final int bajty;

  /// Tekst, który Vosk rozpoznał z tego nagrania - kopia treści notatki z chwili
  /// zapisu. Notatkę można potem poprawić ręcznie, a wtedy porównanie „co
  /// powiedziałem" z „co zrozumiała aplikacja" ma sens tylko z tą kopią.
  final String tekst;

  factory Recording.fromMap(Map<String, dynamic> m) => Recording(
        id: '${m['id']}',
        data: '${m['data'] ?? ''}',
        czas: '${m['czas'] ?? ''}',
        pasiekaNr: (m['pasiekaNr'] ?? 0) as int,
        ulNr: (m['ulNr'] ?? 0) as int,
        zrodlo: '${m['zrodlo'] ?? ''}',
        powiazanieId: '${m['powiazanieId'] ?? ''}',
        sciezka: '${m['sciezka'] ?? ''}',
        sekundy: (m['sekundy'] ?? 0) as int,
        bajty: (m['bajty'] ?? 0) as int,
        tekst: '${m['tekst'] ?? ''}',
      );
}

/// Provider nagrań. Trzyma WSZYSTKIE nagrania naraz - przy tygodniowym
/// przechowywaniu (RecordingHelper.dniPrzechowywania) jest ich najwyżej
/// kilkadziesiąt, a element listy przeglądów i notatek musi umieć w locie
/// odpowiedzieć „czy do tego wpisu jest dźwięk", bez pytania bazy per wiersz.
class Recordings with ChangeNotifier {
  List<Recording> _items = [];

  List<Recording> get items => [..._items];

  bool get isEmpty => _items.isEmpty;

  /// Nagrania przypięte do jednego wpisu (przegląd albo notatka),
  /// OD NAJSTARSZEGO - tak jak były dyktowane.
  ///
  /// Cała lista [_items] jest posortowana od najnowszego (`data DESC, czas DESC`
  /// z bazy), bo tak wygodniej pokazywać nagrania w całości. Ale przy jednym
  /// wpisie kilka nagrań to jedna wypowiedź podzielona na części - druga część
  /// dopowiada pierwszą. Ikonki muszą więc iść od lewej w kolejności nagrywania,
  /// inaczej odsłuchuje się notatkę od końca.
  List<Recording> dla(String zrodlo, String powiazanieId) {
    final List<Recording> moje = _items
        .where((r) => r.zrodlo == zrodlo && r.powiazanieId == powiazanieId)
        .toList();
    //id to millisecondsSinceEpoch z chwili zapisu - najpewniejszy porządek,
    //także gdy nagrania powstały w tej samej sekundzie (czas ma rozdzielczość
    //sekundy). Gdyby id nie było liczbą, zostaje data i czas z bazy.
    moje.sort((Recording a, Recording b) {
      final int? ia = int.tryParse(a.id);
      final int? ib = int.tryParse(b.id);
      if (ia != null && ib != null) return ia.compareTo(ib);
      final int wgDaty = '${a.data} ${a.czas}'.compareTo('${b.data} ${b.czas}');
      return wgDaty != 0 ? wgDaty : a.id.compareTo(b.id);
    });
    return moje;
  }

  /// Czy do tego wpisu jest jakiekolwiek nagranie - do rysowania ikonki.
  bool ma(String zrodlo, String powiazanieId) =>
      _items.any((r) => r.zrodlo == zrodlo && r.powiazanieId == powiazanieId);

  Future<void> fetchAndSetRecordings() async {
    final List<Map<String, dynamic>> dane = await DBHelper.getNagrania();
    _items = dane.map(Recording.fromMap).toList();
    notifyListeners();
  }

  /// Skasowanie jednego nagrania (plik + wpis) i odświeżenie listy.
  Future<void> usun(Recording r) async {
    await RecordingHelper.usun(r.id, r.sciezka);
    _items = _items.where((e) => e.id != r.id).toList();
    notifyListeners();
  }

  /// Skasowanie nagrań przypiętych do kasowanej notatki albo przeglądu.
  Future<void> usunDla(String zrodlo, String powiazanieId) async {
    await RecordingHelper.usunDla(zrodlo, powiazanieId);
    _items = _items
        .where((e) => !(e.zrodlo == zrodlo && e.powiazanieId == powiazanieId))
        .toList();
    notifyListeners();
  }
}
