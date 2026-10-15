// Format kodu QR ula (lib/helpers/qr_helper.dart, plan pliki/plan_kody_qr.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:hi_bees/helpers/qr_helper.dart';

void main() {
  test('kod zawiera pasiekę, ul i prefiks konta', () {
    expect(kodQrUla('AB12', 2, 15), 'heymaya:ul?p=2&u=15&k=AB12');
  });

  test('odczyt własnego kodu', () {
    final k = rozbierzKodQr(kodQrUla('AB12', 2, 15))!;
    expect(k.pasieka, 2);
    expect(k.ul, 15);
    expect(k.prefiksKonta, 'AB12');
  });

  test('obce i uszkodzone kody odrzucone', () {
    expect(rozbierzKodQr('https://example.com'), isNull);
    expect(rozbierzKodQr('heymaya:ul?p=2&k=AB12'), isNull); //brak ula
    expect(rozbierzKodQr('heymaya:ul?p=x&u=3&k=AB12'), isNull);
    expect(rozbierzKodQr('heymaya:ul?p=2&u=3'), isNull); //brak prefiksu
    expect(rozbierzKodQr('heymaya:ul?p=0&u=3&k=AB12'), isNull);
  });
}
