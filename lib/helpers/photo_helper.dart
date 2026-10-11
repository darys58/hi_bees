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
}
