import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/photo.dart';

//Zapis zdjęcia ula - wspólny dla ekranu ula (infos_screen, image_picker) i sterowania
//głosem (voice_vosk_screen, pakiet camera, 11.10.2026). Plik idzie do <Documents>/photos,
//wpis do tabeli zdjecia; arch = 0, więc eksport do chmury wyśle go jak każde inne zdjęcie
//(poza filmami - patrz niżej).
class PhotoHelper {
  //FILMY (28.10.2026): leżą w tym samym katalogu i tej samej tabeli co zdjęcia,
  //rozróżnia je tylko rozszerzenie pliku (bez migracji bazy). Decyzja usera: filmy
  //zostają TYLKO na telefonie - zapytania eksportu do chmury pomijają je (sqlBezFilmow),
  //a usunięcie filmu nie trafia do kolejki usunięć.
  static const List<String> rozszerzeniaFilmow = ['mp4', 'mov', 'm4v'];

  //USTAWIENIA FILMU (Ustawienia -> Sterowanie głosem, 28.10.2026), zapamiętane w telefonie.
  //Długość dotyczy też przycisku "Film" w przeglądzie. Dźwięk - tylko sterowanie głosem:
  //na czas nagrania Vosk oddaje mikrofon, komendy wracają po zakończeniu filmu.
  static const List<int> dlugosciFilmu = [15, 30, 60];
  static int sekundyFilmu = 30;
  static bool filmZDzwiekiem = false;
  static Duration get maxFilmu => Duration(seconds: sekundyFilmu);

  static const String _kSekundy = 'film_sekundy';
  static const String _kDzwiek = 'film_z_dzwiekiem';

  static Future<void> wczytajUstawieniaFilmu() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int s = prefs.getInt(_kSekundy) ?? 30;
      sekundyFilmu = dlugosciFilmu.contains(s) ? s : 30;
      filmZDzwiekiem = prefs.getBool(_kDzwiek) ?? false;
    } catch (_) {} //zostają domyślne
  }

  static Future<void> zapiszUstawieniaFilmu() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kSekundy, sekundyFilmu);
      await prefs.setBool(_kDzwiek, filmZDzwiekiem);
    } catch (_) {}
  }

  static bool jestFilm(String sciezka) =>
      rozszerzeniaFilmow.contains(sciezka.split('.').last.toLowerCase());

  //warunek SQL do zapytań o zdjęcia wysyłane do chmury
  static const String sqlBezFilmow =
      "lower(sciezka) NOT LIKE '%.mp4' AND lower(sciezka) NOT LIKE '%.mov' AND lower(sciezka) NOT LIKE '%.m4v'";

  //film ze ścieżki tymczasowej (aparat) -> katalog aplikacji + baza; rozszerzenie
  //zostaje z pliku źródłowego (iOS image_picker daje .MOV, pakiet camera .mp4)
  static Future<void> zapiszFilm(String sciezkaZrodla, int pasieka, int ul) async {
    String roz = sciezkaZrodla.split('.').last.toLowerCase();
    if (!rozszerzeniaFilmow.contains(roz)) roz = 'mp4';
    await zapiszZdjecie(sciezkaZrodla, pasieka, ul, rozszerzenie: roz);
  }

  //zdjęcie ze ścieżki tymczasowej (aparat/galeria) -> katalog aplikacji + baza
  static Future<void> zapiszZdjecie(String sciezkaZrodla, int pasieka, int ul,
      {String rozszerzenie = 'jpg'}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final now = DateTime.now();
    String timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    //dwa zdjęcia w tej samej sekundzie (głosem "pstryk" pod rząd) - przyrostek, inaczej
    //drugie nadpisałoby pierwsze (ten sam plik i to samo id w bazie). Id nie zawiera
    //rozszerzenia, więc zdjęcie i film z tej samej sekundy też muszą się różnić.
    final String bazaZnacznika = timestamp;
    int n = 1;
    Future<bool> zajety(String t) async {
      for (final r in ['jpg', ...rozszerzeniaFilmow]) {
        if (await File('${photosDir.path}/${pasieka}_${ul}_$t.$r').exists()) return true;
      }
      return false;
    }
    while (await zajety(timestamp)) {
      timestamp = '${bazaZnacznika}_$n';
      n++;
    }
    final fileName = '${pasieka}_${ul}_$timestamp.$rozszerzenie';
    final savedPath = '${photosDir.path}/$fileName';

    await File(sciezkaZrodla).copy(savedPath);

    final dataStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final czasStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final id = '$dataStr.$timestamp.$pasieka.$ul';

    await Photos.insertPhoto(
      id,
      dataStr,
      czasStr,
      pasieka,
      ul,
      savedPath,
      '',
      0,
    );
  }

  //Katalog zdjęć <Documents>/photos. Na iOS ścieżka kontenera aplikacji (UUID) ZMIENIA SIĘ
  //po każdej instalacji/aktualizacji, a w bazie leży pełna ścieżka z chwili zapisu - po
  //restarcie nowej wersji File(sciezka) nie istniał, a _loadPhotos kasował wpis z bazy
  //(zgłoszenie 26.10.2026: zdjęcia znikały). Plik zawsze leży w photos/, więc liczy się
  //tylko nazwa pliku - jak w nagraniach (RecordingHelper.plik).
  static Future<String> katalogZdjec() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/photos';
  }

  //zapisana w bazie ścieżka -> ścieżka w bieżącym katalogu zdjęć
  static String wKatalogu(String zapisana, String katalog) {
    if (zapisana.isEmpty) return zapisana;
    return '$katalog/${zapisana.split('/').last}';
  }

  //jw., gdy katalogu nie ma pod ręką (usuwanie plików)
  static Future<String> biezacaSciezka(String zapisana) async =>
      wKatalogu(zapisana, await katalogZdjec());
}
