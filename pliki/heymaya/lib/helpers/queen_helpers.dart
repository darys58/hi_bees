import 'package:flutter/material.dart';
import 'package:heymaya/l10n/app_localizations.dart';

// Canonical keys for queen source (zrodlo)
const String kSourceBought = 'bought';
const String kSourceCaught = 'caught';
const String kSourceOwn = 'own';

// Canonical keys for queen breed (rasa)
const String kBreedBuckfast = 'buckfast';
const String kBreedItalian = 'italian';
const String kBreedCarniolan = 'carniolan';
const String kBreedCaucasian = 'caucasian';
const String kBreedCentral = 'central';
const String kBreedIberian = 'iberian';
const String kBreedPersian = 'persian';
const String kBreedGreek = 'greek';
const String kBreedEastern = 'eastern';
const String kBreedAnatolian = 'anatolian';
const String kBreedOther = 'other';

// Canonical keys for queen quality (jakość matki)
const String kQualityVeryGood = 'quality_very_good';
const String kQualityGood = 'quality_good';
const String kQualityBig = 'quality_big';
const String kQualityOk = 'quality_ok';
const String kQualityToReplace = 'quality_to_replace';
const String kQualitySmall = 'quality_small';
const String kQualityWeak = 'quality_weak';
const String kQualityOld = 'quality_old';

// Canonical keys for queen mark (znak)
const String kMarkUnmarked = 'unMarked';
const String kMarkWhite = 'mark_white';
const String kMarkYellow = 'mark_yellow';
const String kMarkRed = 'mark_red';
const String kMarkGreen = 'mark_green';
const String kMarkBlue = 'mark_blue';
const String kMarkOther = 'mark_other';

// All known translations for each key (for backward compatibility with old DB values)
const Map<String, String> _allSourceTranslations = {
  // Polish
  'Kupiona': kSourceBought, 'Złapana': kSourceCaught, 'Własna': kSourceOwn,
  // English
  'Bought': kSourceBought, 'Cought': kSourceCaught, 'Own': kSourceOwn,
  // German
  'Gekauft': kSourceBought, 'Gefangen': kSourceCaught, 'Eigene': kSourceOwn,
  // French
  'Achetée': kSourceBought, 'Capturée': kSourceCaught, 'Propre': kSourceOwn,
  // Spanish
  'Comprada': kSourceBought, 'Capturada': kSourceCaught, 'Propia': kSourceOwn,
  // Portuguese
  //'Comprada': kSourceBought, 'Capturada': kSourceCaught, 'Própria': kSourceOwn,
  // Italian
  'Acquistata': kSourceBought, 'Catturata': kSourceCaught, 'Propria': kSourceOwn,
  // Canonical keys map to themselves
  kSourceBought: kSourceBought, kSourceCaught: kSourceCaught, kSourceOwn: kSourceOwn,
};

const Map<String, String> _allBreedTranslations = {
  'Buckfast': kBreedBuckfast, //'buckfast': kBreedBuckfast,
  // Polish
  'Włoszka (Ligustica)': kBreedItalian, 'Krainka (Carnica)': kBreedCarniolan,
  'Kaukaska (Caucasica)': kBreedCaucasian, 'Środkowo europejska (Mellifera)': kBreedCentral,
  'Iberyjska (Iberiensis)': kBreedIberian, 'Perska (Media)': kBreedPersian,
  'Grecka (Cecropia)': kBreedGreek, 'Wschodnia (Cerana)': kBreedEastern,
  'Anatolska (Anatoliaca)': kBreedAnatolian, 'Inna': kBreedOther,
  // English
  'Italian (Ligustica)': kBreedItalian, 'Carniolan (Carnica)': kBreedCarniolan,
  'Caucasian (Caucasica)': kBreedCaucasian, 'Central European (Mellifera)': kBreedCentral,
  'Iberian (Iberiensis)': kBreedIberian, 'Persian (Media)': kBreedPersian,
  'Greek (Cecropia)': kBreedGreek, 'Eastern (Cerana)': kBreedEastern,
  'Anatolian (Anatoliaca)': kBreedAnatolian, 'Other': kBreedOther,
  // German
  'Italienerin (Ligustica)': kBreedItalian, 'Carnica (Carnica)': kBreedCarniolan,
  'Kaukasische (Caucasica)': kBreedCaucasian, 'Dunkle Europäische (Mellifera)': kBreedCentral,
  'Iberische (Iberiensis)': kBreedIberian, 'Persische (Media)': kBreedPersian,
  'Griechische (Cecropia)': kBreedGreek, 'Östliche (Cerana)': kBreedEastern,
  'Anatolische (Anatoliaca)': kBreedAnatolian, 'Andere': kBreedOther,
  // French
  'Italienne (Ligustica)': kBreedItalian, 'Carniolienne (Carnica)': kBreedCarniolan,
  'Caucasienne (Caucasica)': kBreedCaucasian, 'Européenne centrale (Mellifera)': kBreedCentral,
  'Ibérique (Iberiensis)': kBreedIberian, 'Persane (Media)': kBreedPersian,
  'Grecque (Cecropia)': kBreedGreek, 'Orientale (Cerana)': kBreedEastern,
  'Anatolienne (Anatoliaca)': kBreedAnatolian, 'Autre': kBreedOther,
  // Spanish
  'Italiana (Ligustica)': kBreedItalian, 'Carniola (Carnica)': kBreedCarniolan,
  'Caucasica (Caucasica)': kBreedCaucasian, 'Centroeuropea (Mellifera)': kBreedCentral,
  'Iberica (Iberiensis)': kBreedIberian, 'Persa (Media)': kBreedPersian,
  'Griega (Cecropia)': kBreedGreek, 'Oriental (Cerana)': kBreedEastern,
  'Anatolica (Anatoliaca)': kBreedAnatolian, 'Otra': kBreedOther,
  // Portuguese
  'Carniolana (Carnica)': kBreedCarniolan,
  'Caucasiana (Caucasica)': kBreedCaucasian, 'Centro-europeia (Mellifera)': kBreedCentral,
  'Ibérica (Iberiensis)': kBreedIberian,
  'Grega (Cecropia)': kBreedGreek,
  'Anatólica (Anatoliaca)': kBreedAnatolian, 'Outra': kBreedOther,
  // Italian
  //'Carnica (Carnica)': kBreedCarniolan,
  'Europea centrale (Mellifera)': kBreedCentral,
  //'Iberica (Iberiensis)': kBreedIberian, 
  'Persiana (Media)': kBreedPersian,
  'Greca (Cecropia)': kBreedGreek,
  //'Orientale (Cerana)': kBreedEastern,
  'Altra': kBreedOther,
  // Canonical keys
  kBreedBuckfast: kBreedBuckfast, kBreedItalian: kBreedItalian,
  kBreedCarniolan: kBreedCarniolan, kBreedCaucasian: kBreedCaucasian,
  kBreedCentral: kBreedCentral, kBreedIberian: kBreedIberian,
  kBreedPersian: kBreedPersian, kBreedGreek: kBreedGreek,
  kBreedEastern: kBreedEastern, kBreedAnatolian: kBreedAnatolian,
  kBreedOther: kBreedOther,
};

const Map<String, String> _allMarkTranslations = {
  // Polish
  'nie ma znak': kMarkUnmarked, 'nieoznakowana': kMarkUnmarked,
  'ma niebieski znak': kMarkBlue, 'ma zielony znak': kMarkGreen,
  'ma czerwony znak': kMarkRed, 'ma żółty znak': kMarkYellow,
  'ma biały znak': kMarkWhite, 'ma inny znak': kMarkOther,
  // English
  'unmarked': kMarkUnmarked, 'marked blue': kMarkBlue,
  'marked green': kMarkGreen, 'marked red': kMarkRed,
  'marked yellow': kMarkYellow, 'marked white': kMarkWhite,
  'marked other': kMarkOther,
  // German
  'kein Zeichen': kMarkUnmarked, 'blaues Zeichen': kMarkBlue,
  'grünes Zeichen': kMarkGreen, 'rotes Zeichen': kMarkRed,
  'gelbes Zeichen': kMarkYellow, 'weißes Zeichen': kMarkWhite,
  'anderes Zeichen': kMarkOther,
  // French
  'non marquée': kMarkUnmarked, 'marquée bleu': kMarkBlue,
  'marquée vert': kMarkGreen, 'marquée rouge': kMarkRed,
  'marquée jaune': kMarkYellow, 'marquée blanc': kMarkWhite,
  'marquée autre': kMarkOther,
  // Spanish
  'sin marca': kMarkUnmarked, 'marca azul': kMarkBlue,
  'marca verde': kMarkGreen, 'marca roja': kMarkRed,
  'marca amarilla': kMarkYellow, 'marca blanca': kMarkWhite,
  'otra marca': kMarkOther,
  // Portuguese
  'sem marcação': kMarkUnmarked, 'marcação azul': kMarkBlue,
  'marcação verde': kMarkGreen, 'marcação vermelha': kMarkRed,
  'marcação amarela': kMarkYellow, 'marcação branca': kMarkWhite,
  'outra marcação': kMarkOther,
  // Italian
  'non ha segno': kMarkUnmarked, 'ha segno blu': kMarkBlue,
  'ha segno verde': kMarkGreen, 'ha segno rosso': kMarkRed,
  'ha segno giallo': kMarkYellow, 'ha segno bianco': kMarkWhite,
  'ha altro segno': kMarkOther,
  // Canonical keys
  kMarkUnmarked: kMarkUnmarked, kMarkWhite: kMarkWhite,
  kMarkYellow: kMarkYellow, kMarkRed: kMarkRed,
  kMarkGreen: kMarkGreen, kMarkBlue: kMarkBlue,
  kMarkOther: kMarkOther,
};

// Jakość matki - info(kategoria 'queen', parametr "matka  jest") i kolumna ule.matka1.
//
// Do bazy leci GOŁE SŁOWO w języku ustawionym w chwili zapisu, a nie klucz. Wpisy
// zrobione przed zmianą języka albo ściągnięte importem z innego telefonu są więc
// po niemiecku czy po włosku - porównanie z bieżącym l10n ich NIE łapie i matka
// do wymiany dostawała kciuk w górę. Stąd tabela wszystkich tłumaczeń, tak samo
// jak przy rasie i znaku matki.
//
// Są tu też wartości HISTORYCZNE, bo w bazie zostają na zawsze:
//   * "zła"/"canceled"/"schlecht"/... - opcja zastąpiona 06.08.2026 przez "do wymiany",
//   * "to exchange" - angielska etykieta zamieniona wtedy na "old",
//   * 'zła'/'ok' - WEWNĘTRZNE flagi belki ula (ule.matka1), nie etykiety z listy.
const Map<String, String> _allQualityTranslations = {
  // bardzo dobra (pl, en, de, fr, es, it, pt)
  'bardzo dobra': kQualityVeryGood, 'very good': kQualityVeryGood,
  'sehr gut': kQualityVeryGood, 'très bonne': kQualityVeryGood,
  'muy buena': kQualityVeryGood, 'ottima': kQualityVeryGood,
  'muito boa': kQualityVeryGood,
  // dobra
  'dobra': kQualityGood, 'good': kQualityGood, 'gut': kQualityGood,
  'bonne': kQualityGood, 'buena': kQualityGood, 'buona': kQualityGood,
  'boa': kQualityGood,
  // duża ("grande" jest wspólne dla fr/es/it/pt)
  'duża': kQualityBig, 'big': kQualityBig, 'groß': kQualityBig,
  'grande': kQualityBig,
  // ok - jedna wartość dla wszystkich języków, zarazem flaga belki
  'ok': kQualityOk,
  // do wymiany (dawniej "zła")
  'do wymiany': kQualityToReplace, 'to replace': kQualityToReplace,
  'zu ersetzen': kQualityToReplace, 'à remplacer': kQualityToReplace,
  'a reemplazar': kQualityToReplace, 'da sostituire': kQualityToReplace,
  'a substituir': kQualityToReplace,
  'zła': kQualityToReplace, 'canceled': kQualityToReplace,
  'schlecht': kQualityToReplace, 'mauvaise': kQualityToReplace,
  'mala': kQualityToReplace, 'cattiva': kQualityToReplace,
  'má': kQualityToReplace,
  // mała (formy żeńskie z podpowiedzi isVeryGoodCanceled - na wszelki wypadek)
  'mała': kQualitySmall, 'small': kQualitySmall, 'klein': kQualitySmall,
  'petite': kQualitySmall, 'pequeno': kQualitySmall, 'pequena': kQualitySmall,
  'piccolo': kQualitySmall, 'piccola': kQualitySmall,
  // słaba
  'słaba': kQualityWeak, 'weak': kQualityWeak, 'schwach': kQualityWeak,
  'faible': kQualityWeak, 'debil': kQualityWeak, 'débil': kQualityWeak,
  'debole': kQualityWeak, 'fraca': kQualityWeak,
  // stara (en: dawniej "to exchange")
  'stara': kQualityOld, 'old': kQualityOld, 'to exchange': kQualityOld,
  'alt': kQualityOld, 'vieille': kQualityOld, 'vieja': kQualityOld,
  'vecchia': kQualityOld, 'velha': kQualityOld,
  // Canonical keys map to themselves
  kQualityVeryGood: kQualityVeryGood, kQualityGood: kQualityGood,
  kQualityBig: kQualityBig, kQualityOk: kQualityOk,
  kQualityToReplace: kQualityToReplace,
  kQualitySmall: kQualitySmall, kQualityWeak: kQualityWeak,
  kQualityOld: kQualityOld,
};

/// Klucz jakości matki dla wartości z bazy; nieznanej NIE zgadujemy.
String qualityToKey(String value) {
  final v = value.trim();
  return _allQualityTranslations[v] ??
      _allQualityTranslations[v.toLowerCase()] ??
      v;
}

/// Czy jakość matki ma dać kciuk W DÓŁ.
///
/// Wartość nieznana (wpisana ręcznie w prehistorycznej wersji, uszkodzona
/// synchronizacją) liczy się jako DOBRA - lepiej nie straszyć czerwoną ikoną
/// bez pokrycia w danych. Tak samo działały dotąd trzy z czterech miejsc.
bool qualityIsBad(String value) {
  switch (qualityToKey(value)) {
    case kQualityToReplace:
    case kQualitySmall:
    case kQualityWeak:
    case kQualityOld:
      return true;
    default:
      return false;
  }
}

/// Czy jest co pokazywać - pusta jakość i '0' nie rysują kciuka w ogóle.
bool qualityIsSet(String value) {
  final v = value.trim();
  return v.isNotEmpty && v != '0';
}

/// Convert a stored DB value to canonical key.
/// If the value is already a canonical key or unknown, returns it as-is.
String sourceToKey(String value) => _allSourceTranslations[value] ?? value;
String breedToKey(String value) => _allBreedTranslations[value] ?? value;
String markToKey(String value) => _allMarkTranslations[value] ?? value;

/// Get translated display text from canonical key
String sourceToDisplay(String key, AppLocalizations loc) {
  switch (key) {
    case kSourceBought: return loc.bOught;
    case kSourceCaught: return loc.cOught;
    case kSourceOwn: return loc.oWn;
    default: return key; // fallback: show raw value
  }
}

String breedToDisplay(String key, AppLocalizations loc) {
  switch (key) {
    case kBreedBuckfast: return 'Buckfast';
    case kBreedItalian: return loc.iTalian;
    case kBreedCarniolan: return loc.cArniolan;
    case kBreedCaucasian: return loc.cAucasian;
    case kBreedCentral: return loc.cEntral;
    case kBreedIberian: return loc.iBerian;
    case kBreedPersian: return loc.pErsian;
    case kBreedGreek: return loc.gReek;
    case kBreedEastern: return loc.eAster;
    case kBreedAnatolian: return loc.aNatolian;
    case kBreedOther: return loc.oTherQueen;
    default: return key;
  }
}

String markToDisplay(String key, AppLocalizations loc) {
  switch (key) {
    case kMarkUnmarked: return loc.unmarked;
    case kMarkWhite: return loc.markedWhite;
    case kMarkYellow: return loc.markedYellow;
    case kMarkRed: return loc.markedRed;
    case kMarkGreen: return loc.markedGreen;
    case kMarkBlue: return loc.markedBlue;
    case kMarkOther: return loc.markedOther;
    default: return key;
  }
}

/// Znak matki z kolumny `info.wartosc` na tekst w BIEŻĄCYM języku.
///
/// `info.wartosc` dla kategorii "queen" trzyma TEKST - tak porównują ją
/// `infos_screen`, `infos_edit_screen` (lista rozwijana!) i tak trafia na
/// ekran w `info_item`. Tymczasem `queen_item` wstawiał tam do 06.09.2026
/// `matki.znak` NA SUROWO, a to bywa KLUCZ (`mark_white`), bo tak zapisuje
/// `queen_edit_screen`. Takie wiersze zostają w bazie na zawsze i wracają
/// importem z chmury, więc ODCZYT musi je tolerować - stąd ta funkcja.
///
/// Wartości, które znakiem nie są ("nie żyje", "brak", data, cokolwiek),
/// przechodzą NIETKNIĘTE: obie składowe mają fallback na wejście. Efekt
/// uboczny, celowy: znak zapisany po niemiecku czy włosku (import z innego
/// telefonu) pokaże się w języku ustawionym teraz.
String znakMatkiNaEkran(String wartosc, AppLocalizations loc) =>
    markToDisplay(markToKey(wartosc), loc);

/// Get mark icon widget from canonical key
List<Widget> markToIcon(String key) {
  if (key.isEmpty || key == '0') return [];
  switch (key) {
    case kMarkUnmarked:
      return [const Icon(Icons.circle, size: 20.0, color: Color.fromARGB(255, 61, 61, 61))];
    case kMarkWhite:
      return [const Icon(Icons.check_circle_outline_outlined, size: 20.0, color: Color.fromARGB(255, 0, 0, 0))];
    case kMarkYellow:
      return [const Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 215, 208, 0))];
    case kMarkRed:
      return [const Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 255, 0, 0))];
    case kMarkGreen:
      return [const Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 15, 200, 8))];
    case kMarkBlue:
      return [const Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 0, 102, 255))];
    case kMarkOther:
      return [const Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 158, 166, 172))];
    default:
      return [];
  }
}
