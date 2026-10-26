import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/photo.dart';

//Zapis zdjęcia ula - wspólny dla ekranu ula (infos_screen, image_picker) i sterowania
//głosem (voice_vosk_screen, pakiet camera, 11.10.2026). Plik idzie do <Documents>/photos,
//wpis do tabeli zdjecia; arch = 0, więc eksport do chmury wyśle go jak każde inne zdjęcie.
class PhotoHelper {
  //zdjęcie ze ścieżki tymczasowej (aparat/galeria) -> katalog aplikacji + baza
  static Future<void> zapiszZdjecie(String sciezkaZrodla, int pasieka, int ul) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final now = DateTime.now();
    String timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    //dwa zdjęcia w tej samej sekundzie (głosem "pstryk" pod rząd) - przyrostek, inaczej
    //drugie nadpisałoby pierwsze (ten sam plik i to samo id w bazie)
    final String bazaZnacznika = timestamp;
    int n = 1;
    while (await File('${photosDir.path}/${pasieka}_${ul}_$timestamp.jpg').exists()) {
      timestamp = '${bazaZnacznika}_$n';
      n++;
    }
    final fileName = '${pasieka}_${ul}_$timestamp.jpg';
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
