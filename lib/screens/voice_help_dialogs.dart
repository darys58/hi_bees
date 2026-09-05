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
// po przejściu z Picovoice na Vosk. Wywołanie głosem: "notatki pomóż mi" /
// "notes help me" (wartość slotu $helpMe -> case 'notatki'/'notes'
// w voice_vosk_screen).
//
// Tekst POZA plikami ARB, po polsku i po angielsku obok siebie. Powód ten sam
// co w voice_settings_screen.dart: sterowanie głosem działa tylko dla tych
// dwóch języków (brama w apiarys_screen), więc pozostałe pięć nie miałoby
// czego opisywać, a klucze ARB trzeba by dokładać w siedmiu plikach.
//
// DO 04.09.2026 funkcja zwracała PUSTĄ LISTĘ poza pl_PL - strażnik został
// z czasów, gdy głos działał wyłącznie po polsku. Efekt: po angielsku
// "notes help me" było rozpoznawane, ale otwierało puste okno, a użytkownik
// nie miał SKĄD się dowiedzieć, jak brzmią polecenia sesji, notatek
// i cofania (zgłoszone z urządzenia).
List<TextSpan> _sekcjaSesja(BuildContext context) {
  if (globals.jezyk == 'en_US') return _sekcjaSesjaEn();
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

//Angielski odpowiednik _sekcjaSesja. Każda fraza pochodzi WPROST
//z assets/grammar/eng_vosk.yml (intencje voiceStart, voiceStop, voiceNote,
//voiceNotepad, voiceUndo) - pilnuje tego pliki/vosk_pomoc_test_en.py.
List<TextSpan> _sekcjaSesjaEn() {
  return [
    TextSpan(
        text: '\nSession, notes and undo - say e.g.:\n', style: _naglowek),
    TextSpan(
        text: '(these work always, even with no apiary and hive selected:)\n\n',
        style: _warunek),
    _punktor,
    TextSpan(text: 'Hey Maya', style: _wymagany),
    TextSpan(text: ' start/begin'),
    TextSpan(text: ' - opens command listening.\n', style: _komentarz),
    _punktor,
    TextSpan(text: 'Hey Maya', style: _wymagany),
    TextSpan(text: ' stop/done/finished'),
    TextSpan(text: ' - back to standby.\n', style: _komentarz),
    _punktor,
    TextSpan(text: 'Note', style: _wymagany),
    TextSpan(text: '/write note/Hey Maya note for inspection'),
    TextSpan(
        text: ' - note for the current inspection.\n', style: _komentarz),
    _punktor,
    TextSpan(text: 'Hey Maya note for notepad', style: _wymagany),
    TextSpan(text: ' - note saved to the Notepad as a separate entry.\n',
        style: _komentarz),
    _punktor,
    TextSpan(text: 'Hey Maya', style: _wymagany),
    TextSpan(text: ' - ends note dictation', style: _komentarz),
    TextSpan(text: '.\n', style: _komentarz),
    _punktor,
    TextSpan(text: 'Hey Maya undo last save/entry', style: _wymagany),
    TextSpan(text: ' - undoes the last saving command.\n\n',
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
    //l.frames, NIE l.frameAcc: setFrames ma w gramatyce liczbę MNOGĄ
    //("frames from X to Y" / "[ramkę,ramki] od X do Y"). frameAcc daje po
    //angielsku "frame" (l.poj.), więc podpowiadał komendę, której silnik nie
    //zna - zgłoszone z urządzenia 04.09.2026. PL "ramki" też jest w gramatyce.
    TextSpan(text: ' ' + l.frames + ' ' + l.from, style: _wymagany),
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
    //czerw trut - "trut" to forma wymawiana, gramatyka ma homofon "trud".
    //Szyk jak przy czerwiu krytym niżej: PL ma przymiotnik PO rzeczowniku
    //("czerw trut"), EN przed ("drone brood" - gramatyka: drone (brood)).
    //Bez tego rozdzielenia pomoc EN uczyła "brood drone", czyli odwrotnie
    //niż rozumie silnik (zgłoszone przy audycie pomocy 04.09.2026).
    _punktor,
    if (globals.jezyk == 'pl_PL')
      TextSpan(text: l.bRood, style: _opcjonalny)
    else
      TextSpan(text: l.trut, style: _wymagany),
    if (globals.jezyk == 'pl_PL')
      TextSpan(text: ' ' + l.trut, style: _wymagany)
    else
      TextSpan(text: ' ' + l.bRood, style: _opcjonalny),
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
    // Zgłoszenie z urządzenia 03.09.2026: help pokazywał "on the" ("Set on
    // the left/right/both side"), ale eng_vosk.yml dla TEJ komendy (goły
    // $siteOfFrame, bez wartości procentowej) NIE MA "(on) (the)" jako
    // opcjonalnych słów - w przeciwieństwie do pozostałych komend na tej
    // liście (food/queen/queenCells), które je mają. l.leftRightBoth ("on
    // the left/right/both") jest więc poprawne wszędzie indziej na tej
    // liście, ale nie tutaj - stąd goła wersja tylko dla angielskiego.
    // Polski ma "z" jako OPCJONALNE w tej samej komendzie, więc
    // l.leftRightBoth ("z lewej/prawej/obu") zostaje poprawne bez zmian.
    TextSpan(
        text: ' ' +
            (globals.jezyk == 'en_US'
                ? l.left + '/' + l.right + '/' + l.both
                : l.leftRightBoth)),
    TextSpan(text: '  ' + l.site, style: _wymagany),
    TextSpan(text: '.\n'),
    //do zrobienia / zostało zrobione
    // Zgłoszenie z urządzenia 03.09.2026: "to extraction"/"to delete" (stary
    // tekst app_en.arb, z czasów eng1.yml) nie działały - eng_vosk.yml ma
    // "to extract"/"to remove" (POPRAWKA z KROK 2). ARB poprawiony, żeby
    // help mówił to, co gramatyka naprawdę rozumie.
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
    //Po angielsku MÓWI się "grid"/"grate" (słowa "excluder" nie ma w słowniku
    //modelu Vosk), ale apka zapisuje i wyświetla "excluder" - tak samo jak
    //przy wpisie ręcznym. Decyzja usera 04.09.2026: nazwy w apce NIE
    //zmieniamy, bo rozjechałaby się z ręczną edycją; zamiast tego pomoc
    //uprzedza, że zapis będzie brzmiał inaczej niż polecenie.
    if (globals.jezyk == 'en_US')
      TextSpan(text: '.  - ' + l.save.toLowerCase() + ': "' + l.excluder + '"\n\n',
          style: _komentarz)
    else
      TextSpan(text: '.\n\n'),
    _punktor,
    //l.exclud ("excluder") jest też etykietą przycisku w infos_screen, więc
    //zostaje - ale słowa "excluder" NIE MA w słowniku modelu EN (patrz nagłówek
    //eng_vosk.yml), więc po angielsku pomoc pokazuje działające synonimy.
    if (globals.jezyk == 'en_US')
      TextSpan(text: l.dElete + ' grid/grate.\n\n', style: _wymagany)
    else
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
      //lista MUSI pochodzić ze slotu $state w eng_vosk.yml (insert/remove/
      //on/off/open/close/set) - "activated"/"eliminated" nigdy tam nie było
      TextSpan(text: ' is on/off/open/close/set.\n\n'),
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
    //l.belts to SŁOWO POLECENIA („paski"), nie miara - od 05.09.2026 miarą
    //jest osobny klucz `pieces` („sztuk"/„units"), bo jeden klucz w dwóch
    //rolach dawał wpis „Paski wstaw 3 paski". Gramatyka angielska mówi
    //[strip,strips] i [unit,units], więc pomoc pokazuje te słowa wprost.
    //Polski ma tu ten sam wyjątek niżej („sztuki").
    if (globals.jezyk == 'en_US')
      TextSpan(text: ' strips', style: _wymagany)
    else
      TextSpan(text: ' ' + l.belts, style: _wymagany),
    TextSpan(text: ' 3', style: _wartosc),
    //klucz `mites` to "sztuk" (pasuje do "218 sztuk" przy roztoczach), ale przy
    //trójce po polsku jest "3 sztuki" - gramatyka bierze [sztuk,sztuka,sztuki]
    if (globals.jezyk == 'pl_PL')
      TextSpan(text: ' sztuki.\n\n')
    else
      TextSpan(text: ' units.\n\n'),
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
    //"notatki pomóż mi" / "notes help me" -> _sekcjaSesja. Wartość slotu
    //$helpMe brzmi "notatki" (pol_vosk.yml) albo "notes" (eng_vosk.yml), stąd
    //dwie formy. Do 04.09.2026 pozycja była TYLKO po polsku, bo _sekcjaSesja
    //zwracała poza pl_PL pustą listę - teraz ma wersję angielską, więc pokazuje
    //się w obu językach. Pozostałe pięć języków nie ma sterowania głosem
    //(brama w apiarys_screen), więc tam pozycja dalej odpada.
    if (globals.jezyk == 'pl_PL') ...pozycja('Notatki'),
    if (globals.jezyk == 'en_US') ...pozycja('Notes'),
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
/// Zawołanie zapisane WIELKĄ literą - jedyny wyjątek od reguły niżej, bo to
/// imię. Klucze, nie regex: po zamianie na małe litery szukamy dokładnie tych
/// dwóch form.
const Map<String, String> _zawolania = {
  'hej maja': 'Hej Maja',
  'hey maya': 'Hey Maya',
};

/// Polecenia w pomocy piszemy MAŁĄ literą - to słowa DO WYPOWIEDZENIA, nie
/// zdania, a gramatyka (`pol_vosk.yml`, `eng_vosk.yml`) jest w całości małymi.
/// Do 05.09.2026 część fraz szła z wielkiej, część z małej, zależnie od tego,
/// czy tekst brał się z ARB (gdzie ten sam klucz bywa etykietą pola, np.
/// „Wartość"), czy był wpisany w tym pliku - zgłoszone z urządzenia.
///
/// Zamiana jest TUTAJ, a nie w plikach ARB, właśnie dlatego: te same klucze
/// opisują pola formularzy na innych ekranach, gdzie wielka litera jest
/// poprawna.
///
/// Objaśnienia (nagłówek sekcji, warunek, komentarz po myślniku) to zdania
/// i zostają nietknięte. Polecenie to span w jednym ze stylów poleceń ALBO
/// BEZ STYLU: dalszy ciąg frazy idzie w tym pliku bez stylu („Ustaw inny"
/// przed pogrubionym „dzień", „Załącz/wyłącz/otwórz/zamknij/ustaw" przed
/// „zbieracz pyłku"), więc pominięcie takich spanów zostawiało w pomocy
/// dokładnie ten bałagan, o który poszło zgłoszenie.
///
/// Legenda idzie tą samą drogą: jej wiersze („Normalny lub pogrubiony -
/// tekst wymagany") to też nie zdania, tylko podpisy stylów, więc wielka
/// litera na początku była tam równie przypadkowa. Nagłówek „Legenda:" ma
/// własny styl wpisany w miejscu, więc zostaje - jak każdy inny nagłówek.
TextSpan _poleceniaMalymi(TextSpan span) {
  const List<TextStyle> stylePolecen = [
    _wymagany,
    _opcjonalny,
    _wartosc,
    _wartoscOpc,
  ];
  final String? tekst = span.text;
  final bool polecenie =
      span.style == null || stylePolecen.contains(span.style);
  if (tekst == null || !polecenie) return span;
  String maly = tekst.toLowerCase();
  _zawolania.forEach((male, wielkie) {
    maly = maly.replaceAll(male, wielkie);
  });
  return TextSpan(text: maly, style: span.style);
}

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
                  for (final sekcja in sekcje)
                    ...sekcja(context).map(_poleceniaMalymi),
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
