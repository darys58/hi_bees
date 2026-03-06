import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
