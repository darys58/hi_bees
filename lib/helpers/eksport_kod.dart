import 'dart:convert';

import '../globals.dart' as globals;
import 'db_helper.dart';

//Etap 1b pracy zespołowej (06.10.2026): eksport do chmury (cbt_hi_backup_v8.php) niesie kod
//aktywacyjny, żeby serwer mógł sprawdzić, że tabela "XXXX_..." należy do tego konta.
//Kod z tabeli memory - to samo źródło co prefiks w "tabela" (globals.prefiksTabel(mem[0].kod)).
//globals.kod się nie nadaje: na ekranie aktywacji trzyma wpisany tekst (także e-mail).
//Kod doklejany tylko, gdy jego 4 pierwsze znaki zgadzają się z prefiksem tabeli. W każdym innym
//przypadku JSON idzie bez zmian - serwer w okresie przejściowym przyjmuje eksport bez kodu,
//a eksport ze złym kodem by odrzucił (i doliczył nieudaną próbę).
//Od pkt 3 (06.10.2026) obok kodu idzie token urządzenia z memory.token, gdy już jest.
Future<String> eksportZKodem(String jsonData) async {
  try {
    final mem = await DBHelper.getData('memory');
    if (mem.isEmpty) return jsonData;
    final kod = (mem.first['kod'] ?? '').toString().trim();
    if (kod.isEmpty) return jsonData;
    //"tabela" jest na końcu JSON-a - szukamy od niej, nie w całym (zdjęcia mają base64)
    final poz = jsonData.lastIndexOf('"tabela"');
    if (poz == -1) return jsonData;
    final prefiks = RegExp(r'^"tabela"\s*:\s*"([^"_]{4})_')
        .firstMatch(jsonData.substring(poz))
        ?.group(1);
    if (prefiks == null ||
        prefiks.toUpperCase() != globals.prefiksTabel(kod)) {
      return jsonData;
    }
    final koniec = jsonData.lastIndexOf('}');
    if (koniec < poz) return jsonData;
    //token urządzenia (etap 1b pkt 3) - serwer sprawdza go PRZED kodem
    final token = (mem.first['token'] ?? '').toString();
    final dodatek = token.isEmpty ? '' : ', "token":${jsonEncode(token)}';
    return '${jsonData.substring(0, koniec)}, "kod":${jsonEncode(kod)}$dodatek}';
  } catch (_) {
    return jsonData;
  }
}
