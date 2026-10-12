import 'package:flutter/material.dart';
import '../models/info.dart'; //wpisZnakuNowszy, wpisMatki
import '../models/queen.dart'; //matkiUlaWKolejnosci
import 'db_helper.dart'; //idMatekUla, wczytajDodatkoweMatki
import 'parametr_nazwy.dart'; //wszystkieJezyki
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

//Przyrostek id wpisu info zapisanego przy PODŁĄCZENIU matki do ula (queen_item,
//od 11.10.2026). Historia matki rysuje przy takim wpisie ikonkę podłączenia.
const String kIdPodlaczeniaMatki = '.connect';
//Przyrostek id wpisu "matka brak" zapisanego przy ODŁĄCZENIU matki od ula (queen_item,
//od 11.10.2026). Własny przyrostek = podłączenie nowej matki tego samego dnia
//(".connect") ani znak z przeglądu (bez przyrostka) go nie nadpiszą.
const String kIdOdlaczeniaMatki = '.disconnect';

/// Moment wpisu info: data + godzina. Czas jest w bazie jako H:mm (bez zera
/// z przodu), więc ORDER BY czas stawia "9:05" za "10:00" - przy dwóch wpisach
/// o znaku z jednego dnia (odłączenie i podłączenie) liczy się prawdziwa godzina.
DateTime momentWpisu(String data, String czas) {
  final DateTime d = DateTime.tryParse(data) ?? DateTime(2000);
  final List<String> cz = czas.split(':');
  if (cz.length < 2) return d;
  return d.add(Duration(
      hours: int.tryParse(cz[0].trim()) ?? 0, minutes: int.tryParse(cz[1].trim()) ?? 0));
}

/// Czy [kandydat] jest NOWSZYM wpisem o znaku matki niż [obecny] (null = jeszcze
/// żadnego). Porównuje datę z godziną ([momentWpisu]). Godzina ma dokładność
/// minuty, więc odłączenie starej matki i podłączenie nowej zaraz po nim mają ten
/// sam moment - wtedy wygrywa PODŁĄCZENIE ([kIdPodlaczeniaMatki]), bo nową matkę
/// podłącza się po odłączeniu poprzedniej. Bez tego o wyniku decydowała kolejność
/// wierszy z bazy i statystyka pokazywała "brak matki" mimo nowej matki w ulu
/// (zgłoszone 12.10.2026).
bool wpisZnakuNowszy(Info kandydat, Info? obecny) {
  if (obecny == null) return true;
  final DateTime a = momentWpisu(kandydat.data, kandydat.czas);
  final DateTime b = momentWpisu(obecny.data, obecny.czas);
  if (a != b) return a.isAfter(b);
  return kandydat.id.endsWith(kIdPodlaczeniaMatki) &&
      !obecny.id.endsWith(kIdPodlaczeniaMatki);
}

/// Moment OSTATNIEGO podłączenia matki [idMatki] do ula, z jego wpisów [wpisy]
/// (null = nie ma takiego wpisu, np. podłączenie sprzed 11.10.2026).
DateTime? momentPodlaczeniaMatki(Iterable<Info> wpisy, String idMatki) {
  if (idMatki.isEmpty) return null;
  DateTime? wynik;
  for (final inf in wpisy) {
    if (inf.pogoda == idMatki && inf.id.endsWith(kIdPodlaczeniaMatki)) {
      final DateTime m = momentWpisu(inf.data, inf.czas);
      if (wynik == null || m.isAfter(wynik)) wynik = m;
    }
  }
  return wynik;
}

/// Moment wejścia do ula każdej z matek [idMatek] - patrz [momentWejsciaMatki].
/// Matka BEZ wpisów w ulu (podłączona przed wprowadzeniem ID matki we wpisach)
/// dostaje rok 1900: siedzi w ulu "od zawsze", czyli przed każdą matką, której
/// podłączenie jest zapisane. Wcześniej szła na KONIEC kolejki - stara matka
/// główna przegrywała wtedy z nowo podłączoną i belka traciła jej cechy
/// (zgłoszone 12.10.2026).
Map<String, DateTime> wejsciaMatek(Iterable<Info> wpisyUla, Iterable<String> idMatek) => {
      for (final id in idMatek)
        id: momentWejsciaMatki(wpisyUla, id) ?? DateTime(1900),
    };

/// Czy wpis o cesze matki dotyczy matki [idMatki], która jest w ulu TERAZ.
/// [wejscia] = moment wejścia do ula każdej żyjącej matki ula ([wejsciaMatek]).
/// - wpis z ID: tylko gdy to ID tej matki,
/// - wpis BEZ ID (puste info.pogoda: zapisy sprzed wprowadzenia matkaID albo
///   zrobione, gdy matki nie było w tabeli matek): należy do matki, która była
///   w ulu SAMA w chwili wpisu. Wpis sprzed podłączenia obecnej matki dotyczył
///   poprzedniej (bez tego statystyka pokazywała jej cechy z "ID" bez numeru),
///   a wpisu z czasu, gdy w ulu były już dwie matki, nie da się przypisać żadnej,
/// - puste [idMatki] (ul bez matki w tabeli matek): każdy wpis.
bool wpisMatki(Info inf, String idMatki, Map<String, DateTime> wejscia) {
  if (idMatki.isEmpty || inf.pogoda == idMatki) return true;
  if (inf.pogoda.isNotEmpty) return false;
  final DateTime moment = momentWpisu(inf.data, inf.czas);
  final obecne = wejscia.entries.where((e) => !moment.isBefore(e.value)).toList();
  return obecne.length == 1 && obecne.first.key == idMatki;
}

//--- KILKA MATEK W ULU (12.10.2026) -------------------------------------------
//W ulu mogą być naraz do [kMaxMatekWUlu] matek (system dwumatkowy, cicha wymiana,
//odkłady w jednym korpusie). O tym, KTO jest w ulu, decyduje tabela matek
//(pasieka, ul, bez daty straty). Cechy liczone są osobno dla każdej matki - po
//jej ID w info.pogoda. MATKA GŁÓWNA = najwcześniej podłączona: jej cechy pokazuje
//belka ula i dla niej zapisuje cechy sterowanie głosem (decyzja usera 12.10.2026).

const int kMaxMatekWUlu = 3;

/// Przyrostek id wpisu info o matce NIEGŁÓWNEJ (np. '.m12'). Id wpisu to
/// data.pasieka.ul.kategoria.parametr - bez niego wpis o jednej matce
/// dodatkowej nadpisywał wpis drugiej z tego samego dnia. Matka główna (i
/// jedyna) ma id bez przyrostka - jak dotąd i jak przy zapisie głosem.
String przyrostekIdMatki(int idMatki, int idGlownej) =>
    idMatki != 0 && idGlownej != 0 && idMatki != idGlownej ? '.m$idMatki' : '';

/// Czy matka żyje - pusta data straty (stare wpisy mają też '0').
bool matkaZyje(String dataStraty) =>
    dataStraty.isEmpty || dataStraty == '0';

/// Moment WEJŚCIA matki [idMatki] do ula, z wpisów tego ula [wpisyUla]:
/// ostatnie podłączenie ([kIdPodlaczeniaMatki]), a gdy go nie ma (podłączenia
/// sprzed 11.10.2026) - najstarszy wpis o matce z jej ID w tym ulu. Null = matka
/// nie ma w tym ulu żadnego wpisu.
DateTime? momentWejsciaMatki(Iterable<Info> wpisyUla, String idMatki) {
  final DateTime? podlaczenie = momentPodlaczeniaMatki(wpisyUla, idMatki);
  if (podlaczenie != null) return podlaczenie;
  DateTime? najstarszy;
  for (final inf in wpisyUla) {
    if (inf.kategoria == 'queen' && inf.pogoda == idMatki) {
      final DateTime m = momentWpisu(inf.data, inf.czas);
      if (najstarszy == null || m.isBefore(najstarszy)) najstarszy = m;
    }
  }
  return najstarszy;
}

/// Żyjące matki z [matki] (już odfiltrowane do jednego ula), w kolejności wejścia
/// do ula: GŁÓWNA pierwsza. Matka bez żadnego wpisu w ulu jest najstarsza (patrz
/// [wejsciaMatek]), remis rozstrzyga niższe ID (wcześniej zarejestrowana).
List<Queen> matkiUlaWKolejnosci(Iterable<Queen> matki, Iterable<Info> wpisyUla) {
  final List<Queen> zywe = matki.where((q) => matkaZyje(q.dataStraty)).toList();
  final Map<String, DateTime> wejscie =
      wejsciaMatek(wpisyUla, zywe.map((q) => q.id.toString()));
  zywe.sort((a, b) {
    final int c = wejscie['${a.id}']!.compareTo(wejscie['${b.id}']!);
    return c != 0 ? c : a.id.compareTo(b.id);
  });
  return zywe;
}

/// ID żyjących matek ula prosto z bazy, GŁÓWNA pierwsza (puste = ul bez matki).
/// Dla ekranów, które nie mają pod ręką providerów (wpis ręczny, głos, belka).
Future<List<int>> idMatekUla(int pasieka, int ul) async {
  final matki = (await DBHelper.getZyweMatkiUla(pasieka, ul))
      .map((m) => Queen.fromMap(m))
      .toList();
  if (matki.length < 2) return matki.map((q) => q.id).toList();
  final wpisy = (await DBHelper.getInfosOfHive(pasieka, ul))
      .map((item) => Info.fromMap(item));
  return matkiUlaWKolejnosci(matki, wpisy).map((q) => q.id).toList();
}

/// Matka NIEGŁÓWNA na belce ula: znak (klucz, np. kMarkWhite) i ograniczenie
/// ('wolna' / 'ograniczona' / '' - jak ule.matka4). Belka ma kolumny tylko dla
/// matki głównej, więc dodatkowe matki pokazujemy z pamięci (decyzja usera
/// 12.10.2026: ikony ograniczenia i znaki zamiast licznika "×2").
class MatkaNaBelce {
  final int id;
  final String znak;
  final String ograniczenie;
  const MatkaNaBelce(this.id, this.znak, this.ograniczenie);
}

/// Dodatkowe (niegłówne) matki uli: klucz "pasieka.ul", kolejność wejścia do ula.
/// Odświeżane przez [wczytajDodatkoweMatki] - przy wczytaniu uli, odświeżeniu
/// belek, podłączeniu/odłączeniu matki i wpisie o matce.
Map<String, List<MatkaNaBelce>> dodatkoweMatkiUli = {};

const Set<String> _ograniczenieWolna = {'wolna', 'freed', 'frei', 'libre', 'libera', 'livre'};

/// [pomin] - ID matki właśnie odłączanej (w bazie wciąż jeszcze przy ulu).
Future<void> wczytajDodatkoweMatki({int? pomin}) async {
  final pZnak = wszystkieJezyki((l) => " " + l.queen);
  final pOgraniczenie = wszystkieJezyki((l) => l.queenIs);
  final Map<String, List<MatkaNaBelce>> wynik = {};
  for (final w in await DBHelper.getIleZywychMatekWUlach()) {
    if (((w['ile'] as int?) ?? 0) < 2) continue;
    final int pasieka = w['pasieka'] as int;
    final int ul = w['ul'] as int;
    final ids = (await idMatekUla(pasieka, ul)).where((id) => id != pomin).toList();
    if (ids.length < 2) continue;
    final matki = await DBHelper.getZyweMatkiUla(pasieka, ul);
    final List<MatkaNaBelce> lista = [];
    for (final id in ids.skip(1)) {
      //wpisy tej matki ze wszystkich uli, najnowsze pierwsze
      final wpisy = (await DBHelper.getInfosOfQueen('$id')).map((m) => Info.fromMap(m));
      String znak = '';
      String ograniczenie = '';
      for (final inf in wpisy) {
        if (inf.wartosc.isEmpty) continue;
        if (znak.isEmpty && pZnak.contains(inf.parametr)) znak = markToKey(inf.wartosc);
        if (ograniczenie.isEmpty && pOgraniczenie.contains(inf.parametr)) {
          ograniczenie = _ograniczenieWolna.contains(inf.wartosc) ? 'wolna' : 'ograniczona';
        }
      }
      if (znak.isEmpty) {
        final rek = matki.where((m) => m['id'] == id).toList();
        if (rek.isNotEmpty) znak = markToKey('${rek[0]['znak'] ?? ''}');
      }
      lista.add(MatkaNaBelce(id, znak, ograniczenie));
    }
    wynik['$pasieka.$ul'] = lista;
  }
  dodatkoweMatkiUli = wynik;
}

/// Znak matki do kolumny ule.matka2 (belka ula): skrót koloru + napis z opalitka,
/// np. "biał 12"; "niez " = nieznaczona, '' = znak nieznany.
String belkaZnakuMatki(String znak, String napis) {
  switch (markToKey(znak)) {
    case kMarkUnmarked: return 'niez ';
    case kMarkWhite: return 'biał ' + napis;
    case kMarkYellow: return 'żółt ' + napis;
    case kMarkRed: return 'czer ' + napis;
    case kMarkGreen: return 'ziel ' + napis;
    case kMarkBlue: return 'nieb ' + napis;
    case kMarkOther: return 'inny ' + napis;
  }
  return '';
}

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
  //"Comprada" i "Capturada" są identyczne z hiszpańskimi (zdublowany klucz mapy nie
  //przejdzie), ale "Própria" jest tylko portugalska - bez niej matka z tym źródłem
  //wywracała listę rozwijaną w queen_edit_screen (05.10.2026)
  'Própria': kSourceOwn,
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

/// Jakość matki z bazy na tekst w BIEŻĄCYM języku (pozycje listy w infos_edit_screen).
/// Osobno od wartoscWBiezacym, bo dawna jakość "zła" to ten sam napis co polska
/// "zła" (agresywna) przy rodzinie - ogólne tłumaczenie dałoby "aggressive".
/// Wartość nieznana wraca bez zmian.
String jakoscMatkiNaEkran(String wartosc, AppLocalizations loc) {
  switch (qualityToKey(wartosc)) {
    case kQualityVeryGood: return loc.veryGood;
    case kQualityGood: return loc.good;
    case kQualityBig: return loc.big;
    case kQualityOk: return 'ok';
    case kQualityToReplace: return loc.canceled;
    case kQualitySmall: return loc.small;
    case kQualityWeak: return loc.weak;
    case kQualityOld: return loc.exchange;
    default: return wartosc;
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
