import '../globals.dart' as globals;

//Nagłówki zapytań GET do chmury (import z cbt.php?d=f_...) - etap 1b pkt 3, 06.10.2026.
//Token urządzenia w nagłówku X-HB-Token, NIE w adresie: adresy trafiają do logów serwera.
//Bez tokenu (instalacja przed pierwszą synchronizacją) - bez nagłówka; serwer sprawdzi wtedy kod
//z adresu (okres przejściowy, HB_TYLKO_TOKEN_OD w lib/bezpieczenstwo.php).
Map<String, String> naglowkiSerwera() =>
    globals.token.isEmpty ? <String, String>{} : <String, String>{'X-HB-Token': globals.token};
