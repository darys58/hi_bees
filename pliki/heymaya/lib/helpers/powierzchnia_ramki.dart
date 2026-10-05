import '../models/dodatki2.dart';

/// Powierzchnia węzy (plastra) w ramce w mm2 - jako tekst, bo tak idzie do
/// kolumny `info.pogoda` przy zbiorze miodu "z małych/dużych ramek".
///
/// Statystyki, raporty i belka liczą zbiór jako
/// `ilość ramek x waga 1 dm2 x pogoda / 10000`, a pusta `pogoda` oznacza
/// ramkę wielkopolską (35175 / 78725). Tabela stała do 05.10.2026 tylko
/// w infos_edit_screen - zapis głosowy jej nie znał i wpisywał do `pogoda`
/// pusty tekst albo (gdy wcześniej padła komenda o matce) ID matki, przez co
/// zbiór z głosu dawał w statystyce i raporcie 0.
///
/// [typUla] to `ule.h2` (np. 'WIELKOPOLSKI', 'TYP A'), [dod2] - typy własne
/// uli z tabeli dodatki2. Dla typu nieznanego zwraca '0'.
String dmRamkiUla(String typUla, {required bool mala, required List<Dodatki2Item> dod2}) {
  //typy własne (TYP A..D) - brak wiersza w dodatki2 nie może wywrócić zapisu
  String wlasny(int i) => dod2.length > i ? (mala ? dod2[i].z : dod2[i].u) : '0';
  if (mala) {
    switch (typUla) {
    case 'WIELKOPOLSKI': return '35175'; //dm2, węza: 335x105 (mała ramka: 360x130)
    case 'DADANT': return '49680';       //dm2, węza: 414x120 (mała ramka: 435x145)
    case 'OSTROWSKIEJ': return '68675';  //dm2, węza: 335x205 (ramka: 360x230)
    case 'WARSZAWSKI ZWYKŁY': return '28600';  //dm2, węza: 220x130 (mała ramka: 240x160)
    case 'WARSZAWSKI POSZERZANY': return '35175';  //dm2, węza: 335x105 (mała ramka: 360x130)
    case 'APIPOL': return '37260';  //dm2, węza: 414x90 (ramka: 435x115)
    case 'LANGSTROTH': return '37260';  //dm2, węza: 414x90 (mała ramka: 435x115)
    case 'ZANDER': return '74100';  //dm2, węza: 390x190 (ramka: 420x220)
    case 'GERSTUNG': return '39100';  //dm2, węza: 230x170 (mała ramka: 260x200)
    case 'APIMAYE': return '37260';  //dm2, węza: 414x90 (mała ramka: 435x115)
    case 'DEUTSCH NORMAL': return '49680'; //dm2, węza: 414x120 (mała ramka: 435x145)
    case 'NORMALMASS': return '84000';  //dm2, węza: 400x210 (ramka: 435x240)
    case 'FRANKENBEUTE': return '50600';  //dm2, węza: 440x115 (mała ramka: 470x145)
    case 'NATIONAL': return '88150';  //dm2, węza: 430x205 (ramka: 460x235)
    case 'WBC': return '37260';  //dm2, węza: 414x90 (mała ramka: 435x115)
    case 'WIELKOPOLSKI GÓRSKI': return '51925';  //dm2, węza: 335x155 (ramka: 360x180)
    case 'TYP A': return wlasny(0);  //dm2, ramka mała własna TYP A
    case 'TYP B': return wlasny(1);  //dm2, ramka mała własna TYP B
    case 'TYP C': return wlasny(2);  //dm2, ramka mała własna TYP C
    case 'TYP D': return wlasny(3);  //dm2, ramka mała własna TYP D
    }
  } else {
    switch (typUla) {
    case 'WIELKOPOLSKI': return '78725'; //dm2, węza: 335x235 (duza ramka: 360x260)
    case 'DADANT': return '109710'; //dm2, węza: 414x265 (duza ramka: 435x300)
    case 'OSTROWSKIEJ': return '68675';  //dm2, węza: 335x205 (ramka: 360x230)
    case 'WARSZAWSKI ZWYKŁY': return '88000';  //dm2, węza: 220x400 (duza ramka: 240x435)
    case 'WARSZAWSKI POSZERZANY': return '112000';  //dm2, węza: 280x400 (duza ramka: 300x435)
    case 'APIPOL': return '37260';  //dm2, węza: 414x90 (ramka: 435x115)
    case 'LANGSTROTH': return '84870';  //dm2, węza: 414x205 (duza ramka: 435x230)
    case 'ZANDER': return '74100';  //dm2, węza: 390x190 (ramka: 420x220)
    case 'GERSTUNG': return '64400';  //dm2, węza: 280x230 (duza ramka: 410x260)
    case 'APIMAYE': return '86820';  //dm2, węza: 424x205 (duza ramka: 448x232)
    case 'DEUTSCH NORMAL': return '109710'; //dm2, węza: 414x265 (duza ramka: 435x300)
    case 'NORMALMASS': return '84000';  //dm2, węza: 400x210 (ramka: 435x240)
    case 'FRANKENBEUTE': return '118800';  //dm2, węza: 440x270 (duza ramka: 470x300)
    case 'NATIONAL': return '88150';  //dm2, węza: 430x205 (ramka: 460x235)
    case 'WBC': return '84870';  //dm2, węza: 414x205 (duza ramka: 435x230)
    case 'WIELKOPOLSKI GÓRSKI': return '51925';  //dm2, węza: 335x155 (ramka: 360x180)
    case 'TYP A': return wlasny(0);  //dm2, ramka duza własna TYP A
    case 'TYP B': return wlasny(1);  //dm2, ramka duza własna TYP B
    case 'TYP C': return wlasny(2);  //dm2, ramka duza własna TYP C
    case 'TYP D': return wlasny(3);  //dm2, ramka duza własna TYP D
    }
  }
  return '0'; //dla typów innych niz powyzsze
}
