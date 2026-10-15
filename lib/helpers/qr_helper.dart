// Kody QR na ulach (plan: pliki/plan_kody_qr.md, wariant A, 15.10.2026).
//
// W kodzie jest numer pasieki i ula oraz prefiks konta - bez przypisywania jak
// przy tagu NFC i bez zmian w bazie. Prefiks (4 znaki, globals.prefiksTabel -
// w pracy zespołowej prefiks bazy właściciela) chroni przed kodem z cudzej
// pasieki: inny pszczelarz ma te same numery uli, ale inny prefiks.
// Po przeniesieniu ula do innej pasieki kod trzeba wydrukować na nowo.

const String _schemat = 'heymaya:ul';

/// Treść kodu QR ula, np. "heymaya:ul?p=2&u=15&k=AB12".
String kodQrUla(String prefiksKonta, int pasieka, int ul) =>
    '$_schemat?p=$pasieka&u=$ul&k=$prefiksKonta';

/// Odczytany kod QR ula.
class KodQrUla {
  final int pasieka;
  final int ul;
  final String prefiksKonta;
  const KodQrUla(this.pasieka, this.ul, this.prefiksKonta);
}

/// Rozbiór odczytanego kodu; null = to nie jest kod ula Hey Maya
/// (do odczytu w etapie 2 - tryb ręczny i głos).
KodQrUla? rozbierzKodQr(String tresc) {
  final t = tresc.trim();
  if (!t.startsWith('$_schemat?')) return null;
  final Uri? uri = Uri.tryParse(t.replaceFirst('$_schemat?', 'https://x/?'));
  if (uri == null) return null;
  final p = int.tryParse(uri.queryParameters['p'] ?? '');
  final u = int.tryParse(uri.queryParameters['u'] ?? '');
  final k = uri.queryParameters['k'] ?? '';
  if (p == null || u == null || p < 1 || u < 1 || k.isEmpty) return null;
  return KodQrUla(p, u, k);
}
