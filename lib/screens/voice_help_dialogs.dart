// Okna pomocy ekranu sterowania głosem (voice_vosk_screen.dart).
//
// DLACZEGO OSOBNY PLIK: pomoc zajmowała ~2160 z 12176 linii voice_vosk_screen,
// a nie dotyka ani nasłuchu, ani bazy, ani paintera - to czysta prezentacja.
// Jedyne, co łączyło ją z ekranem, to pole `openDialog`; tutaj wchodzi ono
// przez callback `poZamknieciu`.
//
// JEDNO ŹRÓDŁO PRAWDY: wcześniej każda fraza istniała w DWÓCH kopiach - w oknie
// zbiorczym `_dialogBuilder` i w oknie tematycznym. Kopie zdążyły się rozjechać
// (okno zbiorcze miało "włacz/wyłacz" bez ogonków, tematyczne "włącz/wyłącz").
// Teraz każda sekcja to jedna funkcja `_sekcja*`, a okno zbiorcze skleja je po
// kolei - poprawka w jednym miejscu wchodzi do obu okien.
//
// ZGODNOŚĆ Z GRAMATYKĄ: każda fraza MUSI dać się dopasować do wyrażenia
// z assets/grammar/pol_vosk.yml - inaczej pomoc uczy komend, których silnik nie
// rozpozna. Po zmianie gramatyki trzeba przejść ten plik i pliki ARB, a potem
// uruchomić (w kontenerze, bez telefonu):
//     python3 pliki/vosk_pomoc_test.py
// Skrypt przepuszcza przez parser każdą frazę, której uczy pomoc, i sprawdza
// dodatkowo, że stare, błędne formy nadal NIE są rozpoznawane.
// UWAGA na aliasy fonetyczne: "nakrop"/"węza"/"pierzga"/"trut" to formy, które
// użytkownik WYMAWIA; gramatyka ma pod nimi "na grób"/"węża"/"pierzcha"/"trud",
// bo tak słyszy je model. To NIE są błędy - nie "poprawiać" ich do postaci
// z pliku YML. Tak samo "półkorpus" (gram. "pół korpus") i "miodobranie"
// (gram. "miodu branie") - wymawia się identycznie.
//
// UWAGA na klucze ARB: `apiary` i `frame` ("pasieka", "ramka") wchodzą
// w stringi zapisywane do bazy (infos_screen, raport_color_screen - "miód =
// mała ramka x"), więc NIE WOLNO zmieniać ich na biernik. Do pomocy służą
// osobne klucze `apiaryAcc` ("pasiekę") i `frameAcc` ("ramkę").

import 'package:flutter/material.dart';
import 'package:hi_bees/l10n/app_localizations.dart';
import '../globals.dart' as globals;

//---------------------------------------------------------------------------
// style - te same, których używały okna przed wydzieleniem
//---------------------------------------------------------------------------

const TextStyle _naglowek =
    TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue);
const TextStyle _warunek =
    TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.blue);
const TextStyle _komentarz =
    TextStyle(fontStyle: FontStyle.italic, color: Colors.blue);
const TextStyle _wymagany = TextStyle(fontWeight: FontWeight.bold);
const TextStyle _opcjonalny = TextStyle(fontStyle: FontStyle.italic);
const TextStyle _wartosc = TextStyle(color: Colors.red);
const TextStyle _wartoscOpc =
    TextStyle(fontStyle: FontStyle.italic, color: Colors.red);

// Wypunktowanie przed KAŻDYM poleceniem. Odstępy między poleceniami zeszły do
// jednej nowej linii, żeby pomoc mieściła się na ekranie w poziomie - w pionie
// polecenia zaczęły się przez to zlewać. Kropka daje oku punkt zaczepienia,
// nie dokładając ani jednej linii wysokości.
// Wstawiać przed pierwszym spanem polecenia, NIE przed nagłówkiem sekcji,
// warunkiem ("kiedy pasieka i ul...") ani wierszami legendy.
const TextSpan _punktor = TextSpan(text: '• ', style: _wymagany);

typedef _Sekcja = List<TextSpan> Function(BuildContext);

//---------------------------------------------------------------------------
// sekcje
//---------------------------------------------------------------------------

// Sesja, dyktowanie notatki i cofanie - polecenia, które pojawiły się dopiero
// po przejściu z Picovoice na Vosk. Wywołanie głosem: "notatki pomóż mi"
// (wartość "notatki" slotu $helpMe w pol_vosk.yml -> case 'notatki'
// w voice_vosk_screen). Tekst po polsku POZA plikami ARB, bo
// sterowanie głosem działa wyłącznie przy globals.jezyk == 'pl_PL' (mamy tylko
// polski model Vosk), więc tłumaczenia nie miałyby czego opisywać - tak samo
// jak w voice_settings_screen.dart. Stąd też strażnik na języku poniżej.
List<TextSpan> _sekcjaSesja(BuildContext context) {
  if (globals.jezyk != 'pl_PL') return const [];
  return [
    TextSpan(text: '\nSesja, notatki i cofanie - powiedz np.:\n', style: _naglowek),
    TextSpan(
        text: '(te polecenia działają zawsze, także bez wybranej pasieki i ula:)\n\n',
        style: _warunek),
    _punktor,
    TextSpan(text: 'Hej Maja', style: _wymagany),
    TextSpan(text: ' start/startujemy/zaczynamy'),
    TextSpan(text: ' - otwiera nasłuch poleceń.\n', style: _komentarz),
    _punktor,
    TextSpan(text: 'Hej Maja', style: _wymagany),
    TextSpan(text: ' stop/koniec/kończymy'),
    TextSpan(text: ' - wraca do czuwania.\n', style: _komentarz),
    _punktor,
    TextSpan(text: 'Zanotuj', style: _wymagany),
    TextSpan(text: '/zapisz notatkę/Hej Maja notatka do przeglądu'),
    TextSpan(
        text: ' - notatka do aktualnego przeglądu.\n',
        style: _komentarz),
    _punktor,
    TextSpan(text: 'Hej Maja notatka do Notesu', style: _wymagany),
    TextSpan(text: ' - notatka do Notesu jako osobny wpis.\n',
        style: _komentarz),
    _punktor,
    TextSpan(text: 'Hej Maja', style: _wymagany),
    TextSpan(text: ' - koniec dyktowania notatki', style: _komentarz),
    TextSpan(text: '.\n', style: _komentarz),
    _punktor,
    TextSpan(text: 'Hej Maja cofnij ostatni zapis/wpis', style: _wymagany),
    TextSpan(text: ' - cofa ostatnie zapisujące polecenie.\n\n',
        style: _komentarz),
  ];
}

// Lokacja zasobu - setApiary, setAllHives, setHivesRange, setHive, setBody,
// setHalfBody, setFrame, setChange, setMoveBody, setFrames
List<TextSpan> _sekcjaLokacja(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    TextSpan(text: '\n' + l.resourceLocationSay, style: _naglowek),
    //otwórz pasiekę numer 1 - biernik (apiaryAcc), bo gramatyka ma "pasiekę"
    TextSpan(text: '\n\n'),
    _punktor,
    TextSpan(text: l.oPen, style: _wymagany),
    TextSpan(text: ' ' + l.apiaryAcc, style: _wymagany),
    TextSpan(text: ' ' + l.number, style: _opcjonalny),
    TextSpan(text: ' 1', style: _wartosc),
    //otwórz wszystkie ule
    TextSpan(text: '.\n'),
    _punktor,
    TextSpan(text: l.oPen, style: _wymagany),
    TextSpan(text: ' ' + l.allHives, style: _wymagany),
    //ustaw ule od do - zakres uli
    TextSpan(text: '.\n'),
    _punktor,
    TextSpan(text: l.sEt, style: _wymagany),
    TextSpan(text: ' ' + l.hivesPlural + ' ' + l.from, style: _wymagany),
    TextSpan(text: ' 1', style: _wartosc),
    TextSpan(text: ' ' + l.to, style: _wymagany),
    TextSpan(text: ' 5', style: _wartosc),
    //otwórz ul numer 5
    TextSpan(text: '.\n'),
    _punktor,
    TextSpan(text: l.oPen, style: _wymagany),
    TextSpan(text: ' ' + l.hive, style: _wymagany),
    TextSpan(text: ' ' + l.number, style: _opcjonalny),
    TextSpan(text: ' 5', style: _wartosc),
    //korpus numer
    TextSpan(text: '.\n'),
    _punktor,
    TextSpan(text: l.oPen, style: _wymagany),
    TextSpan(text: ' ' + l.body + '/' + l.halfBody, style: _wymagany),
    TextSpan(text: ' ' + l.number, style: _opcjonalny),
    TextSpan(text: ' 2', style: _wartosc),
    //ramka numer - tu gramatyka dopuszcza [ramka,ramkę], więc mianownik zostaje
    TextSpan(text: '.\n'),
    _punktor,
    TextSpan(text: l.oPen + ' ' + l.big + '/' + l.small, style: _opcjonalny),
    TextSpan(text: ' ' + l.frame, style: _wymagany),
    TextSpan(text: ' ' + l.number, style: _opcjonalny),
    TextSpan(text: ' 6', style: _wartosc),
    TextSpan(text: ' ' + l.leftRightBoth + '.\n', style: _opcjonalny),
    //ramka po przeglądzie
    _punktor,
    TextSpan(text: l.fRame, style: _wymagany),
    TextSpan(text: ' ' + l.number, style: _opcjonalny),
    TextSpan(text: ' 2 ', style: _wartosc),
    TextSpan(text: l.framesAfter, style: _wymagany),
    TextSpan(text: ' ' + l.number, style: _opcjonalny),
    TextSpan(text: ' 5', style: _wartosc),
    TextSpan(text: '.\n'),
    //przenieś
    _punktor,
    TextSpan(text: l.mOve, style: _wymagany),
    TextSpan(text: ': ' + l.hive + ' ' + l.number + ' 4 ', style: _opcjonalny),
    TextSpan(text: ' ' + l.body + '/' + l.halfBody, style: _wymagany),
    TextSpan(text: ' ' + l.number, style: _opcjonalny),
    TextSpan(text: ' 3', style: _wartosc),
    TextSpan(text: ' ' + l.frame, style: _wymagany),
    TextSpan(text: ' ' + l.number, style: _opcjonalny),
    TextSpan(text: ' 10', style: _wartosc),
    //wstaw ramka
    TextSpan(text: '.\n'),
    _punktor,
    TextSpan(text: l.iNsert, style: _wymagany),
    TextSpan(text: ' ' + l.big + '/' + l.small, style: _opcjonalny),
    TextSpan(text: ' ' + l.frameAcc, style: _wymagany),
    TextSpan(text: ' ' + l.number, style: _opcjonalny),
    TextSpan(text: ' 4', style: _wartosc),
    TextSpan(text: '.\n'),
    //ustaw ramkę od do - biernik (frameAcc), bo setFrames ma [ramkę,ramki]
    _punktor,
    TextSpan(text: l.sEt, style: _wymagany),
    TextSpan(text: ' ' + l.frameAcc + ' ' + l.from, style: _wymagany),
    TextSpan(text: ' 1', style: _wartosc),
    TextSpan(text: ' ' + l.to, style: _wymagany),
    TextSpan(text: ' 9', style: _wartosc),
    TextSpan(text: '.\n\n'),
  ];
}

// Przegląd - setStore
List<TextSpan> _sekcjaPrzeglad(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    TextSpan(text: '\n' + l.inspectionSay + '\n', style: _naglowek),
    TextSpan(text: l.whenTheApiary + '\n\n', style: _komentarz),
    //czerw trut - "trut" to forma wymawiana, gramatyka ma homofon "trud"
    _punktor,
    TextSpan(text: l.bRood, style: _opcjonalny),
    TextSpan(text: ' ' + l.trut, style: _wymagany),
    TextSpan(text: ' 10%', style: _wartosc),
    TextSpan(text: ' ' + l.leftRight + '.\n', style: _opcjonalny),
    //czerw kryty - w PL przymiotnik idzie po rzeczowniku, w EN odwrotnie
    _punktor,
    if (globals.jezyk == 'pl_PL')
      TextSpan(text: l.bRood, style: _opcjonalny)
    else
      TextSpan(text: l.covered, style: _opcjonalny),
    if (globals.jezyk == 'pl_PL')
      TextSpan(text: ' ' + l.covered, style: _wymagany)
    else
      TextSpan(text: ' ' + l.bRood, style: _wymagany),
    TextSpan(text: ' 20%', style: _wartosc),
    TextSpan(text: ' ' + l.leftRight + '.\n', style: _opcjonalny),
    //pozostałe zasoby procentowe
    _punktor,
    TextSpan(text: l.larvaeEggsPollenHoneySealdWaxComb, style: _wymagany),
    TextSpan(text: ' 35%', style: _wartosc),
    TextSpan(text: ' ' + l.leftRight + '.\n', style: _opcjonalny),
    //matka na ramce
    _punktor,
    TextSpan(text: l.queenColors + ' ', style: _wymagany),
    TextSpan(text: l.queen, style: _wymagany),
    TextSpan(text: ' ' + l.leftRight + '.\n', style: _opcjonalny),
    //mateczniki
    _punktor,
    TextSpan(text: '2', style: _wartosc),
    TextSpan(text: ' ' + l.queenCells, style: _wymagany),
    TextSpan(text: ' ' + l.leftRight + '.\n', style: _opcjonalny),
    _punktor,
    TextSpan(text: l.dElete, style: _wymagany),
    TextSpan(text: ' 3', style: _wartosc),
    TextSpan(text: ' ' + l.queenCells, style: _wymagany),
    //ustaw stronę ramki - $siteOfFrame ma też "obu", stąd leftRightBoth
    TextSpan(text: ' ' + l.leftRight + '.\n', style: _opcjonalny),
    _punktor,
    TextSpan(text: l.sEt + ' ', style: _opcjonalny),
    TextSpan(text: ' ' + l.leftRightBoth),
    TextSpan(text: '  ' + l.site, style: _wymagany),
    TextSpan(text: '.\n'),
    //do zrobienia / zostało zrobione
    _punktor,
    TextSpan(text: l.workFrameToExtraction + '.', style: _wymagany),
    TextSpan(text: ' - ' + l.tOdo + '\n', style: _komentarz),
    _punktor,
    TextSpan(text: l.deletedInserted + '.', style: _wymagany),
    TextSpan(text: ' - ' + l.iSdone + '\n\n', style: _komentarz),
  ];
}

// Wyposażenie - setEquipment
List<TextSpan> _sekcjaWyposazenie(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    TextSpan(text: '\n' + l.equipmentSay + '\n', style: _naglowek),
    TextSpan(text: l.whenAtLeastApiaryAndHive + '\n\n', style: _warunek),
    //ustaw ilość ramek w korpusie jest 10
    _punktor,
    TextSpan(text: l.sEt, style: _opcjonalny),
    TextSpan(text: '  ' + l.numberOfFrame, style: _wymagany),
    TextSpan(text: ' ' + l.inBody),
    TextSpan(text: ' ' + l.isIs, style: _opcjonalny),
    TextSpan(text: ' 10', style: _wartosc),
    TextSpan(text: '.\n\n'),
    //krata
    _punktor,
    TextSpan(text: l.eXclud, style: _wymagany),
    TextSpan(text: ' ' + l.onBodyNumber),
    TextSpan(text: ' 1', style: _wartosc),
    TextSpan(text: '.\n\n'),
    _punktor,
    TextSpan(text: l.dElete + ' ' + l.exclud + '.\n\n', style: _wymagany),
    //podłoga
    _punktor,
    TextSpan(text: l.bOttomBoard, style: _wymagany),
    TextSpan(text: ' ' + l.isDisinfectedOkDirty + '.'),
    //zbieracz pyłku - gramatyka ma "zbieracz", nie "poławiacz";
    //lista czasowników to slot $state z pol_vosk.yml (bez "włącz"!)
    TextSpan(text: '\n\n'),
    _punktor,
    if (globals.jezyk == 'pl_PL')
      TextSpan(text: 'Załącz/wyłącz/otwórz/zamknij/ustaw')
    else
      TextSpan(text: 'Bee pollen trap', style: _wymagany),
    if (globals.jezyk == 'pl_PL')
      TextSpan(text: ' zbieracz pyłku.\n\n', style: _wymagany)
    else
      TextSpan(text: ' is on/off/open/close/activated/eliminated.\n\n'),
  ];
}

// Matka - setQueen
List<TextSpan> _sekcjaMatka(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    TextSpan(text: '\n' + l.queenSay + '\n', style: _naglowek),
    TextSpan(text: l.whenAtLeastApiaryAndHive + '\n\n', style: _warunek),
    _punktor,
    TextSpan(text: l.qUeen, style: _wymagany),
    TextSpan(text: ' ' + l.wasBornIn),
    TextSpan(text: ' 23', style: _wartosc),
    TextSpan(text: '.\n\n'),
    _punktor,
    TextSpan(text: l.qUeen, style: _wymagany),
    TextSpan(text: ' ' + l.isVirgine + '.\n\n'),
    _punktor,
    TextSpan(text: l.qUeen, style: _wymagany),
    TextSpan(text: ' ' + l.isFreed + '.\n\n'),
    _punktor,
    TextSpan(text: l.qUeen, style: _wymagany),
    TextSpan(text: ' ' + l.isMarked),
    TextSpan(text: ' ' + l.number, style: _opcjonalny),
    TextSpan(text: ' 55.\n\n', style: _wartoscOpc),
    _punktor,
    TextSpan(text: l.qUeen, style: _wymagany),
    TextSpan(text: ' ' + l.isVeryGoodCanceled + '.\n\n'),
  ];
}

// Rodzina - setColony
List<TextSpan> _sekcjaRodzina(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    TextSpan(text: '\n' + l.colonySay + '\n', style: _naglowek),
    TextSpan(text: l.whenAtLeastApiaryAndHive + '\n\n', style: _warunek),
    _punktor,
    TextSpan(text: l.cOlony, style: _wymagany),
    TextSpan(text: ' ' + l.isIs, style: _opcjonalny),
    TextSpan(text: ' ' + l.deadFlight + '.\n\n'),
    _punktor,
    TextSpan(text: l.cOlony, style: _wymagany),
    TextSpan(text: ' ' + l.isIs, style: _opcjonalny),
    TextSpan(text: ' ' + l.veryWeakStrong + '.\n\n'),
    //osyp - gramatyka ma "martwe pszczoły"/"martwych pszczół"
    _punktor,
    TextSpan(text: l.dEadBees, style: _wymagany),
    TextSpan(text: ' 250', style: _wartosc),
    TextSpan(text: ' ' + l.milliliter + '.\n\n'),
  ];
}

// Dokarmianie - setFeeding
List<TextSpan> _sekcjaDokarmianie(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    TextSpan(text: '\n' + l.feedingSay + '\n', style: _naglowek),
    TextSpan(text: l.whenAtLeastApiaryAndHive + '\n\n', style: _warunek),
    _punktor,
    TextSpan(text: l.syrupOneToOne, style: _wymagany),
    TextSpan(text: ' 1', style: _wartosc),
    TextSpan(text: ' ' + l.point, style: _opcjonalny),
    TextSpan(text: ' 5', style: _wartoscOpc),
    TextSpan(text: ' ' + l.liters + '.\n'),
    _punktor,
    TextSpan(text: l.syrupThreeToTwo, style: _wymagany),
    TextSpan(text: ' 3', style: _wartosc),
    TextSpan(text: ' ' + l.point, style: _opcjonalny),
    TextSpan(text: ' 5', style: _wartoscOpc),
    TextSpan(text: ' ' + l.liters + '.\n'),
    _punktor,
    TextSpan(text: l.bee, style: _opcjonalny),
    TextSpan(text: l.cAndy, style: _wymagany),
    TextSpan(text: ' 1', style: _wartosc),
    TextSpan(text: ' ' + l.point, style: _opcjonalny),
    TextSpan(text: ' 0', style: _wartoscOpc),
    TextSpan(text: ' kilo.\n'),
    _punktor,
    TextSpan(text: l.invert, style: _wymagany),
    TextSpan(text: ' 2', style: _wartosc),
    TextSpan(text: ' ' + l.point, style: _opcjonalny),
    TextSpan(text: ' 7', style: _wartoscOpc),
    TextSpan(text: ' ' + l.liters + '.\n'),
    _punktor,
    TextSpan(text: l.lEftFood, style: _wymagany),
    TextSpan(text: ' 30%', style: _wartosc),
    if (globals.jezyk == 'pl_PL')
      TextSpan(text: ' pokarmu.\n')
    else
      TextSpan(text: '.\n'),
    _punktor,
    TextSpan(text: l.rEmoveFood, style: _wymagany),
    TextSpan(text: ' 30%', style: _wartosc),
    if (globals.jezyk == 'pl_PL')
      TextSpan(text: ' pokarmu.\n\n')
    else
      TextSpan(text: '.\n\n'),
  ];
}

// Leczenie - setTreatment
List<TextSpan> _sekcjaLeczenie(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    TextSpan(text: '\n' + l.treatmentSay + '\n', style: _naglowek),
    TextSpan(text: l.whenAtLeastApiaryAndHive + '\n\n', style: _warunek),
    //"chemia 1. dawka" nie istnieje w gramatyce polskiej - liczba idzie na końcu
    if (globals.jezyk == 'en_US') _punktor,
    if (globals.jezyk == 'en_US') TextSpan(text: l.apivarolChemistry, style: _wymagany),
    if (globals.jezyk == 'en_US') TextSpan(text: ' ' + l.first, style: _wartosc),
    if (globals.jezyk == 'en_US') TextSpan(text: ' ' + l.dosePortionPart + '.\n\n'),
    _punktor,
    TextSpan(text: l.apivarolChemistry, style: _wymagany),
    TextSpan(text: ' ' + l.dosePortionPart + ' ' + l.number),
    TextSpan(text: ' 1', style: _wartosc),
    TextSpan(text: '.\n\n'),
    //paski - gramatyka: $state paski N [sztuk,sztuka,sztuki].
    //Słowa "Biovar" w gramatyce NIE MA, a czasownik stoi PRZED "paski".
    _punktor,
    TextSpan(text: l.rem, style: _wymagany),
    TextSpan(text: ' ' + l.belts, style: _wymagany),
    TextSpan(text: ' 3', style: _wartosc),
    //klucz `mites` to "sztuk" (pasuje do "218 sztuk" przy roztoczach), ale przy
    //trójce po polsku jest "3 sztuki" - gramatyka bierze [sztuk,sztuka,sztuki]
    if (globals.jezyk == 'pl_PL')
      TextSpan(text: ' sztuki.\n\n')
    else
      TextSpan(text: ' ' + l.mites + '.\n\n'),
    _punktor,
    TextSpan(text: l.aCid, style: _wymagany),
    TextSpan(text: ' 40', style: _wartosc),
    TextSpan(text: ' ' + l.milliliter + '.\n\n'),
    _punktor,
    TextSpan(text: l.vArroa, style: _wymagany),
    TextSpan(text: ' 218', style: _wartosc),
    TextSpan(text: ' ' + l.mites + '.\n\n'),
  ];
}

// Zbiory - setHarvest
List<TextSpan> _sekcjaZbiory(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    TextSpan(text: '\n' + l.harvestSay + '\n', style: _naglowek),
    TextSpan(text: l.whenAtLeastApiaryAndHive + '\n\n', style: _warunek),
    _punktor,
    TextSpan(text: l.honeyHarvest, style: _wymagany),
    TextSpan(text: ' 10 ', style: _wartosc),
    TextSpan(text: l.razy, style: _opcjonalny),
    TextSpan(text: ' ' + l.small + '/' + l.big + ' ' + l.frame),
    TextSpan(text: '.\n\n'),
    _punktor,
    TextSpan(text: l.beePollenHarvest, style: _wymagany),
    TextSpan(text: ' 2 ', style: _wartosc),
    TextSpan(text: l.razy, style: _opcjonalny),
    TextSpan(text: ' ' + l.miarka),
    TextSpan(text: '.\n\n'),
    //wariant mililitrowy nie ma "razy" - patrz zbiór pyłku ($hundred) (NN)
    _punktor,
    TextSpan(text: l.beePollenHarvest, style: _wymagany),
    TextSpan(text: ' 825 ', style: _wartosc),
    TextSpan(text: l.milliliter),
    TextSpan(text: '.\n\n'),
    _punktor,
    TextSpan(text: l.beePollenHarvest, style: _wymagany),
    TextSpan(text: ' 0', style: _wartosc),
    TextSpan(text: ' ' + l.point, style: _opcjonalny),
    TextSpan(text: ' 15', style: _wartoscOpc),
    TextSpan(text: ' ' + l.liters + '.\n\n'),
  ];
}

// Data - setDate
List<TextSpan> _sekcjaData(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    TextSpan(text: '\n' + l.dateSay + '\n', style: _naglowek),
    TextSpan(text: '\n'),
    _punktor,
    TextSpan(text: l.setOther),
    TextSpan(text: ' ' + l.day, style: _wymagany),
    TextSpan(text: ' 15', style: _wartosc),
    TextSpan(text: '.\n\n'),
    _punktor,
    TextSpan(text: l.setOther),
    TextSpan(text: ' ' + l.month, style: _wymagany),
    TextSpan(text: ' 3', style: _wartosc),
    TextSpan(text: '.\n\n'),
    _punktor,
    TextSpan(text: l.setOther),
    TextSpan(text: ' ' + l.year, style: _wymagany),
    TextSpan(text: ' 22', style: _wartosc),
    TextSpan(text: '.\n\n'),
    //"ustaw aktualną datę" - gramatyka $date: aktualną, aktualna
    _punktor,
    TextSpan(text: l.sEt),
    TextSpan(text: ' ' + l.current, style: _wymagany),
    TextSpan(text: ' ' + l.datee + '.\n\n'),
  ];
}

// Pomóż mi - setHelp (wartości slotu $helpMe z pol_vosk.yml)
List<TextSpan> _sekcjaPomoc(BuildContext context) {
  final l = AppLocalizations.of(context)!;

  List<TextSpan> pozycja(String haslo) => [
        _punktor,
        TextSpan(text: haslo, style: _wymagany),
        TextSpan(text: ' ' + l.helpMe + '.\n'),
      ];

  return [
    TextSpan(text: '\n' + l.helpSay + ' ', style: _naglowek),
    TextSpan(text: '(' + l.forPreciseHelp + ')\n', style: _warunek),
    //"notatki pomóż mi" -> _sekcjaSesja. Po polsku i za strażnikiem języka
    //z tego samego powodu co sama sekcja: opisuje polecenia, które istnieją
    //tylko w polskim modelu Vosk. Bez strażnika pozycja prowadziłaby do
    //pustego okna, bo _sekcjaSesja zwraca wtedy [].
    if (globals.jezyk == 'pl_PL') ...pozycja('Notatki'),
    ...pozycja(l.lOcation),
    ...pozycja(l.iNspection),
    ...pozycja(l.eQuipment),
    ...pozycja(l.qUeen),
    ...pozycja(l.cOlony),
    //slot $helpMe ma "dokarmianie" i "zbiory" - stąd fEeding/hArvest
    ...pozycja(l.fEeding),
    ...pozycja(l.tReatment),
    ...pozycja(l.hArvest),
    ...pozycja(l.dAte),
    _punktor,
    TextSpan(text: l.closeHelp, style: _wymagany),
    TextSpan(text: '.\n'),
    TextSpan(text: l.whenAtLeastApiaryAndHive + '\n', style: _warunek),
    ...pozycja(l.hIve),
    ...pozycja(l.hIve + ' ' + l.before),
    ...pozycja(l.hIve + ' ' + l.after),
    ...pozycja(l.hIve + ' ' + l.earlier),
    ...pozycja(l.hIve + ' ' + l.later),
  ];
}

// Legenda - opis wyróżnień użytych wyżej
List<TextSpan> _sekcjaLegenda(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    TextSpan(
        text: '\n' + l.legend + ':\n',
        style: TextStyle(
            fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold)),
    TextSpan(text: l.normalOr),
    TextSpan(text: ' ' + l.bold, style: _wymagany),
    TextSpan(text: ' - ' + l.requiredText + '.\n', style: _warunek),
    TextSpan(text: l.italic, style: _opcjonalny),
    TextSpan(text: ' - ' + l.optionalText + '.\n', style: _warunek),
    TextSpan(text: l.text1Text2),
    TextSpan(text: ' - ' + l.selectableText + '.\n', style: _warunek),
    TextSpan(text: ' 2', style: _wartosc),
    TextSpan(text: ' - ' + l.sampleValue + '.\n', style: _warunek),
  ];
}

//---------------------------------------------------------------------------
// wspólne okno
//---------------------------------------------------------------------------

// `poZamknieciu` odkłada z powrotem `openDialog = false` w voice_vosk_screen -
// ekran pilnuje tym polem, żeby dwa okna pomocy nie nałożyły się na siebie.
Future<void> _pokazOkno(
  BuildContext context,
  List<_Sekcja> sekcje,
  VoidCallback? poZamknieciu,
) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: EdgeInsets.only(left: 15, right: 15),
        content: Container(
          child: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: [
                  for (final sekcja in sekcje) ...sekcja(context),
                ],
              ),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.closeHelp),
            onPressed: () {
              Navigator.of(context).pop();
              if (poZamknieciu != null) poZamknieciu();
            },
          ),
        ],
      );
    },
  );
}

//---------------------------------------------------------------------------
// okna wywoływane z ekranu
//---------------------------------------------------------------------------

// pomoc całościowa - przycisk "?" oraz komenda "pomóż mi"
Future<void> pomocPelna(BuildContext context, {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [
      _sekcjaSesja,
      _sekcjaLokacja,
      _sekcjaPrzeglad,
      _sekcjaWyposazenie,
      _sekcjaMatka,
      _sekcjaRodzina,
      _sekcjaDokarmianie,
      _sekcjaLeczenie,
      _sekcjaZbiory,
      _sekcjaData,
      _sekcjaPomoc,
      _sekcjaLegenda,
    ], poZamknieciu);

// polecenie "notatki pomóż mi" - sesja, dyktowanie notatek i cofanie
Future<void> pomocSesja(BuildContext context, {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [_sekcjaSesja], poZamknieciu);

Future<void> pomocLokacja(BuildContext context, {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [_sekcjaLokacja], poZamknieciu);

Future<void> pomocPrzeglad(BuildContext context, {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [_sekcjaPrzeglad], poZamknieciu);

Future<void> pomocWyposazenie(BuildContext context,
        {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [_sekcjaWyposazenie], poZamknieciu);

Future<void> pomocMatka(BuildContext context, {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [_sekcjaMatka], poZamknieciu);

Future<void> pomocRodzina(BuildContext context, {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [_sekcjaRodzina], poZamknieciu);

Future<void> pomocDokarmianie(BuildContext context,
        {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [_sekcjaDokarmianie], poZamknieciu);

Future<void> pomocLeczenie(BuildContext context, {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [_sekcjaLeczenie], poZamknieciu);

Future<void> pomocZbiory(BuildContext context, {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [_sekcjaZbiory], poZamknieciu);

Future<void> pomocData(BuildContext context, {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [_sekcjaData], poZamknieciu);

// "pomóż mi" bez doprecyzowania kategorii - spis komend pomocy + legenda
Future<void> pomocSpisKomend(BuildContext context,
        {VoidCallback? poZamknieciu}) =>
    _pokazOkno(context, [_sekcjaPomoc, _sekcjaLegenda], poZamknieciu);
