import '../models/frame.dart';

/// POJEMNOŚĆ JEDNEJ STRONY PLASTRA.
///
/// Zasoby 1..9 (trut, czerw, larwy, jaja, pierzga, miód, zasklep, węza, susz)
/// dzielą tę samą powierzchnię i razem nie mogą przekroczyć 100%. Zasoby 10..14
/// (matka, mateczniki, usunięte mateczniki, „do zrobienia", znaczniki) niczego
/// nie zajmują i do sumy nie wchodzą - tak samo liczyła to ręczna kontrola
/// w `frame_edit_screen` od początku.
///
/// Adres strony to dokładnie te pola, z których powstaje `id` wiersza tabeli
/// `ramka`: data, pasieka, ul, korpus, numer ramki przed i po, strona. Dzięki
/// temu „zajęte" znaczy to samo, co zobaczy painter rysujący plaster.
///
/// [pomijaneZasoby] to numery zasobów, które zapis właśnie ZASTĄPI (insert
/// działa w trybie replace, a `id` zawiera numer zasobu). Bez tego poprawienie
/// istniejącej wartości - „miód 50" na „miód 30" - liczyłoby stary wpis drugi
/// raz i potrafiło odrzucić zmianę zmniejszającą zasób.
int zajeteNaStronie({
  required List<Frame> wszystkieRamki,
  required String data,
  required int pasiekaNr,
  required int ulNr,
  required int korpusNr,
  required int ramkaNr,
  required int ramkaNrPo,
  required int strona,
  Set<int> pomijaneZasoby = const {},
}) {
  int suma = 0;
  for (final Frame fr in wszystkieRamki) {
    if (fr.zasob < 1 || fr.zasob > 9) continue;
    if (pomijaneZasoby.contains(fr.zasob)) continue;
    if (fr.data != data) continue;
    if (fr.pasiekaNr != pasiekaNr) continue;
    if (fr.ulNr != ulNr) continue;
    if (fr.korpusNr != korpusNr) continue;
    if (fr.ramkaNr != ramkaNr) continue;
    if (fr.ramkaNrPo != ramkaNrPo) continue;
    if (fr.strona != strona) continue;
    //wartości bywają w bazie z procentem i bez, zależnie od tego, którędy
    //trafiły (głos, ręczna edycja, import)
    suma += int.tryParse(fr.wartosc.replaceAll(RegExp('%'), '').trim()) ?? 0;
  }
  return suma;
}

/// Ile procent strony jeszcze wolne - nigdy poniżej zera, bo w bazie mogą leżeć
/// wpisy sprzed wprowadzenia kontroli (albo z importu z innego urządzenia).
int wolneNaStronie({
  required List<Frame> wszystkieRamki,
  required String data,
  required int pasiekaNr,
  required int ulNr,
  required int korpusNr,
  required int ramkaNr,
  required int ramkaNrPo,
  required int strona,
  Set<int> pomijaneZasoby = const {},
}) {
  final int wolne = 100 -
      zajeteNaStronie(
        wszystkieRamki: wszystkieRamki,
        data: data,
        pasiekaNr: pasiekaNr,
        ulNr: ulNr,
        korpusNr: korpusNr,
        ramkaNr: ramkaNr,
        ramkaNrPo: ramkaNrPo,
        strona: strona,
        pomijaneZasoby: pomijaneZasoby,
      );
  return wolne < 0 ? 0 : wolne;
}
