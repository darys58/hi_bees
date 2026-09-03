// STEROWANIE GŁOSEM NA VOSKU - jedyny produkcyjny ekran głosowy aplikacji.
//
// SKĄD SIĘ WZIĄŁ: kopia voice_screen2.dart (Picovoice/Rhino) z WYMIENIONĄ
// WARSTWĄ WEJŚCIA. Cała logika pasieczna - switch prettyPrintInference (~3600
// linii), zapisy do bazy, rysowanie korpusu, dialogi pomocy - została bez
// zmian, bo lib/helpers/vosk_grammar.dart oddaje dokładnie ten sam kształt
// danych, co RhinoInference: {isUnderstood, intent, slots}.
//
// CO JEST INACZEJ NIŻ W voice_screen2:
//   1. Brak przycisku START. Nasłuch rusza sam po wejściu na ekran i trwa,
//      dopóki ekran jest otwarty. Rolę przycisku przejęły komendy:
//        "Hej Maja start"  ("zaczynamy", "startujemy") -> nasłuch komend,
//        "Hej Maja stop"   ("kończymy", "koniec") -> powrót do czuwania.
//      "Hej Maja" nie jest już osobnym silnikiem wake-word (Porcupine), tylko
//      zwykłą frazą gramatyki - patrz intencje voiceStart/voiceStop w
//      assets/grammar/pol_vosk.yml.
//   2. Dwie gramatyki. W czuwaniu recognizer zna WYŁĄCZNIE frazy sesji (6),
//      więc rozmowa przy ulu nie ma jak otworzyć nasłuchu komend.
//   3. Odzywki Mai wracają, ale nie bez ograniczeń. Reguła z 10.06.2026 ("nie
//      graj mp3 z mową, gdy silnik nasłuchuje") była wymuszona tym, że przy
//      Rhino nie mieliśmy dostępu do strumienia audio. Tu mikrofon jest nasz:
//      na czas odtwarzania VoskEngine przestaje karmić recognizer.
//      ALE TO NIE JEST SZCZELNE (zmierzone na urządzeniu 02.08.2026): bufor
//      wejścia iOS oddaje próbki z opóźnieniem, więc mowa nagrana w oknie
//      wyciszenia potrafi dotrzeć już PO jego zamknięciu i wraca z Vosk jako
//      fraza. Dlatego POTWIERDZENIE KOMENDY (najczęstszy dźwięk, po każdej
//      dobrej komendzie) to krótki sygnał systemowy, a nie okej.mp3 -
//      patrz _beepPotwierdzenia(). Odzywki rzadkie (start/close/nie_rozumiem)
//      zostają mową; gdyby i one zaczęły przeciekać, dźwignią jest
//      VoskEngine._ogonWyciszenia (dziś 300 ms).
//   4. Każde przerwanie (telefon, Siri, tło, utrata mikrofonu) kończy się
//      POWROTEM DO CZUWANIA, nigdy cichym zawieszeniem. Decyzja z 01.08.2026.
//   5. Dyktowanie notatki (nasłuch swobodny, recognizer bez gramatyki) ma DWA
//      UJŚCIA - patrz [UjscieNotatki]:
//        "zanotuj" / "zapisz notatkę" / "Hej Maja notatka do przeglądu"
//              -> uwagi dzisiejszego przeglądu wybranego ula (tabela "info"),
//        "Hej Maja notatka do notesu"
//              -> nowy wpis w Notesie (tabela "notatki").
//      Jedno i drugie kończy "Hej Maja".
//
// Warstwa audio siedzi w lib/helpers/vosk_engine.dart - tu jej nie ma.
import 'dart:async';
//dart:io (Platform) i flutter_beep były potrzebne tylko do rozgałęzienia sygnału
//potwierdzenia komendy - po przejściu na SoundHelper.beep() sygnał jest ten sam
//na obu platformach i oba importy zniknęły (inaczej `flutter analyze` zgłasza
//unused_import).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //stąd Uint8List - surowe PCM notatki
import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
//import 'package:hi_bees/helpers/db_helper.dart';
import 'package:provider/provider.dart';
import '../helpers/queen_helpers.dart';
import '../helpers/sound_helper.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:hi_bees/l10n/app_localizations.dart';
import '../helpers/vosk_engine.dart';
import '../helpers/vosk_grammar.dart';
import '../helpers/db_helper.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a
import '../globals.dart' as globals;
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../models/frame.dart';
import '../models/frames.dart';
import '../models/hive.dart';
import '../models/hives.dart';
import '../models/apiarys.dart';
import '../models/info.dart';
import '../models/infos.dart';
import '../models/note.dart'; //Notes - notatka dyktowana do Notesu
import '../models/recording.dart'; //Recordings - nagrania dyktowanych notatek
import '../helpers/recording_helper.dart'; //zapis WAV + cykl życia nagrań
import '../helpers/undo_helper.dart'; //cofanie ("Hej Maja cofnij ostatni zapis")
import 'voice_help_dialogs.dart'; //okna pomocy - wydzielone z tego pliku
import '../models/weather.dart';
import '../models/weathers.dart';
//import '../models/dodatki1.dart';
//void main() {
//  runApp(MyApp());
//}

//Gdzie ma trafić dyktowana notatka. Komenda otwierająca mówi to wprost
//("Hej Maja notatka do przeglądu" / "Hej Maja notatka do notesu"), bo pomyłka
//jest droga: to dwie różne tabele i dwa różne miejsca w aplikacji.
enum UjscieNotatki {
  /// Uwagi dzisiejszego przeglądu wybranego ula (tabela "info", kategoria
  /// "inspection"). Wymaga wybranej pasieki i ula.
  przeglad,

  /// Samodzielny wpis w Notesie (tabela "notatki"). Pasieka i ul są opcjonalne -
  /// jeśli są wybrane, zapisujemy je jako kontekst notatki.
  notes,
}

class VoiceVoskScreen extends StatefulWidget {
  static const routeName = '/screen-voice-vosk'; //nazwa trasy do tego ekranu

  const VoiceVoskScreen({super.key});

  @override
  _VoiceVoskScreenState createState() => _VoiceVoskScreenState();
}

class _VoiceVoskScreenState extends State<VoiceVoskScreen>
    with WidgetsBindingObserver {
  //final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isInit = true;
  bool isError = false;
  String errorMessage = "";
  bool isButtonDisabled = false; //czy klawisz nieaktywny?
  bool isProcessing =
      false; //czy trwa nasłuch komend (po "Hej Maja start")
  String rhinoText = "";

  //warstwa wejścia: mikrofon -> Vosk -> gramatyka. Cała obsługa audio,
  //przerwań i wyciszania odzywek siedzi w VoskEngine (helpers/vosk_engine.dart)
  VoskEngine? _engine;
  VoskGrammar? _gramatyka;
  String _stanNasluchu = ''; //opis stanu silnika - pokazywany na ekranie
  //ostatni komunikat SILNIKA (czuwam / słucham komend / odzyskuję mikrofon).
  //Komunikaty o pojedynczych frazach nadpisują pasek stanu, więc bez tej kopii
  //nie da się po komendzie wrócić do informacji, w jakim trybie jest nasłuch.
  String _stanBazowy = '';
  //mikrofon milczy, choć silnik jest gotowy (rozmowa telefoniczna, Siri, inna
  //aplikacja). To NIE jest awaria - silnik ponawia sam - ale ikona musi to
  //pokazać, bo zielone ucho przy martwym mikrofonie wprowadza w błąd
  bool _mikrofonMilczy = false;
  String _partial = ''; //tekst "w locie", w trakcie mówienia
  //dyktowanie notatki (do przeglądu albo do notesu): trwa / tekst zebrany do tej pory.
  //Tekst pokazujemy ZAWSZE, także bez diagnostyki - inaczej niż surowy partial
  //komend (patrz [_opisFrazy]): tutaj tekst z Vosk jest produktem, a nie
  //podglądem wnętrza silnika, i użytkownik musi widzieć, co zostanie zapisane.
  bool _dyktuje = false;
  String _tekstNotatki = '';
  //Ujście BIEŻĄCEGO dyktowania - ustawiane przez komendę otwierającą i czytane
  //dopiero przy zapisie (silnik oddaje tekst osobnym callbackiem, więc nie ma
  //jak przekazać tego parametrem). Domyślnie przegląd: tak działały jedyne
  //komendy notatki do 04.08.2026 ("zanotuj", "zapisz notatkę").
  UjscieNotatki _ujscieNotatki = UjscieNotatki.przeglad;
  //KOMUNIKAT NOTATKI MA WŁASNĄ LINIJKĘ, a nie pasek stanu.
  //Powód (03.08.2026): pasek stanu przepisuje KAŻDA domknięta fraza z Vosk
  //(_opisFrazy), a każdemu niepowodzeniu notatki towarzyszy odzywka Mai, która
  //przecieka z głośnika do mikrofonu (znane od 02.08.2026 - opóźniony bufor
  //wejścia iOS jest dłuższy niż ogon wyciszenia). Efekt: komunikat typu
  //„Notatka niedostępna: ..." albo „Najpierw wybierz pasiekę i ul." znikał po
  //ułamku sekundy, przepisany echem własnej odzywki - z zewnątrz nie do
  //odróżnienia od „aplikacja w ogóle nic nie powiedziała".
  String _komunikatNotatki = '';
  Timer? _timerKomunikatuNotatki;
  //ŚLAD WEJŚCIA W DYKTOWANIE - tylko przy włączonej diagnostyce.
  //Wejście w notatkę to łańcuszek kroków, z których każdy potrafi się urwać po
  //cichu (odzywka, wyciszenie mikrofonu, budowa recognizera). Bez tego jedyną
  //informacją zwrotną z urządzenia jest „nic się nie dzieje", a konsola Xcode
  //przy `flutter run --release` bywa poza zasięgiem. Ostatni krok zostaje na
  //ekranie, więc od razu widać, gdzie łańcuszek się zatrzymał.
  String _sladNotatki = '';
  //wczytana gramatyka nie zna którejś z nowych intencji (notatka, cofanie) -
  //czyli w pakiecie apki siedzi stary assets/grammar/pol_vosk.yml. Komunikat
  //zostaje na ekranie do końca sesji, bo bez niego objaw wygląda jak zepsuta
  //funkcja, a nie jak stary plik.
  bool _gramatykaNieaktualna = false;
  bool _silnikGotowy = false;
  Timer? _inferenceTimer; //timer zastępujący Future.delayed - anulowalny przy nowej komendzie
  //flaga odroczonego dźwięku 'okej' - gra się dopiero po pętli slotów, jezeli 'zapisałam' (success) nie wyparł go
  bool _pendingOpenBeep = false;
  double heightScreen = 601;
  //WARIANT WIERSZY STREFY 1: true = pudełka niższe i węższe, cyfry mniejsze.
  //Liczony RAZ na budowę ekranu, w [LayoutBuilder] - patrz komentarz tam.
  //Wcześniej każdy z dziewięciu wierszy powtarzał ten sam warunek
  //`heightScreen < 590 && orientacja == portrait && !voice2LiveLandscape`,
  //przez co w poziomie zawsze wychodził wariant DUŻY - a lewa kolumna ma tam
  //połowę szerokości ekranu i pudełka po 100 px wchodziły na siebie.
  bool _maleWiersze = false;
  bool czyJesWidget = false;
  // String rhinoModelPath = 'assets/models/rhino_params_pl.pv';
  // String porcupineModelPath = 'assets/models/porcupine_params_pl.pv';
  var now = new DateTime.now();
  var formatter = new DateFormat('yyyy-MM-dd');
  var formatterHm = new DateFormat('H:mm');
  var formatterPogoda = new DateFormat('yyyy-MM-dd HH:mm');
  String formattedDate = '';
  String ustawianaData = '';
  String formatedTime = '';
  List<Frames> frame = [];
  List<Hive> hive = [];
  //String ikona = '';
  //String opis = '';
  int ileUli = 0;
  String miejsce = '0';
  String zapis = '0'; //co i ile zostanie zapisane w bazie

  //COFANIE OSTATNICH ZAPISÓW. Stos migawek żyje tylko tyle, co ten ekran -
  //ratuje pomyłkę sprzed kilkunastu sekund przy otwartym ulu, nie zastępuje
  //historii zmian. Szczegóły modelu w lib/helpers/undo_helper.dart.
  final StosCofania _stosCofania = StosCofania();
  //czy BIEŻĄCA komenda coś zapisała - ustawiane przez zapisDoBazy /
  //zapisInfoDoBazy, czytane po switchu w _obsluzKomende
  bool _zapisWTejKomendzie = false;
  //cofanie w toku - obejmuje TAKŻE odświeżanie providerów po przywróceniu
  //plastra, więc jest szersze niż blokada wewnątrz StosCofania
  bool _cofanieWToku = false;
  bool openDialog = false; //czy otwarte jest jakieś okno pomocy
  double hightSave =
      100; //wysokość wiersza "Save" - zapis zasobu lub info do bazy
  double marginRow = 10; //marginesy dla wierszy 'ul,korpus,ramka' i...
  int matkaID = 0; //numer id matki - index z tabeli "matka"
  //Locale myLocale = 'en_US'
  //AudioPlayer player = AudioPlayer();
//String  test = "0";
  bool readyApiary = false; //ustalony numer pasieki
  bool readyAllHives = false; //polecenia dla wszy
  bool readyHive = false; //ustalony numer ula
  bool readyBody = false; //ustalony numer korpusu
  bool readyHalfBody = false; //ustalony numer półkorpusu
  bool readyFrame = false; //ustalony numer ramki
  bool readyStory = false; //gotowość do zapisu w bazie poszczególnych produktów
  bool readyInfo = false; //gotowość do zapisu info
  bool readyFrames = false; //ustalony zakres kilku ramek

  //intents
  String intention = '';

  //slots
  String? help; //wywołanie pomocy całej
  String? helpMe; //wywołanie pomocy w poszczególnych kategoriach
  String? apiaryState; //stan pasieki
  int nrXXOfApiary = 0; //numer pasieki
  int nrXXOfApairyTemp = 0;
  String? allHivesState;
  //ZAKRES ULI ("ustaw ule od X do Y") - nie jest osobnym trybem, tylko
  //zawężeniem trybu zbiorczego. Komenda ustawia readyAllHives = true i te
  //granice; zero w którejkolwiek = tryb obejmuje CAŁĄ pasiekę, czyli zachowuje
  //się dokładnie jak "ustaw wszystkie ule".
  String? hivesRangeState;
  int nrXXOdHive = 0;
  int nrXXOdHiveTemp = 0;
  int nrXXDoHive = 0;
  int nrXXDoHiveTemp = 0;
  String? hiveState;
  int nrXXOfHive = 0;
  int nrXXOfHiveTemp = 0; //tymczasowy numer ula potrzebny przy resecie bo inna kolejność pól w slocie
  int nrXXOfHiveH = 0;
  int nrTempHive = 0; //numer ula do którego przenoszona jest ramka
  String? bodyState;
  int nrXOfBody = 0;
  int nrXOfBodyTemp = 0;
  String? halfBodyState;
  int nrXOfHalfBody = 0;
  int nrXOfHalfBodyTemp = 0;
  int nrTempBody = 0; //numer korpusu do którego przenoszona jest ramka
  int nrTempHalfBody = 0;//j.w.
  String? frameState; //ramka
  String? framesState; //ramki
  int nrXXOdFrame = 0;
  int nrXXOdFrameTemp = 0;
  int nrXXDoFrame = 0;
  int nrXXDoFrameTemp = 0;
  int nrXXOfFrame = 0;
  int nrXXOfFramePo = 0;
  int nrXXOfFrameTemp = 0;
  int nrTempFrame = 0; //numer ramki który otrzymuje przeniesiona ramka do innego korpusu
  String siteOfFrame = '0'; //both, whole, left, right, obie
  String sizeOfFrame = '0'; //big, small   2-duza, 1-mała
  String? site; //left, right  - dla moved
  String kolorMatki =
      '1'; //1-czarna,2-zółta,3-czerwona,4-zielona,5-niebieska,6-biała,7-inna
  //store
  String honey = '0';
  String honeySeald = '0';
  String pollen = '0';
  String brood = '0';
  String larvae = '0';
  String eggs = '0';
  String wax = '0';
  String waxComb = '0';
  String queen = '0';
  String queenCells = '0';
  String delQCells = '0';
  String drone = '0';
  String toDo = '';
  String isDone = '';
  int zapisZas = 0;
  String zapisWart = '0';

  //dla hive
  String ikona = 'green'; //pobierana z aktualnego ula
  int ramek = 10; //pobierane z aktualnego ula
  int korpusNr = 0;
  int trut = 0;
  int czerw = 0;
  int larwy = 0;
  int jaja = 0;
  int pierzga = 0;
  int miod = 0;
  int dojrzaly = 0;
  int weza = 0;
  int susz = 0;
  int matka = 0;
  int mateczniki = 0;
  int usunmat = 0;
  String todo = '0';
  String matka1 = '';
  String matka2 = '';
  String matka3 = '';
  String matka4 = '';
  String matka5 = '';
  String rodzajUla = '';
  String typUla = '';
  String tagNFC = '';

  int _korpusNr = 0; //aktualny numer korpusa
  int _typ = 0; //2-korpus, 1-półkorpus
  int _rozmiar = 0; //2-big, 1-small
  int _nowaIloscRamek = 0; //zmieniana poleceniem głosowym
  bool _ulPo = true; //true="Po", false="przed" - ul wyświetlany w "ul pomóz mi"
  //int _strona = 0;

  String syrup1to1I = '0';
  String syrup1to1D = '0';
  String syrup3to2I = '0';
  String syrup3to2D = '0';
  String candyI = '0';
  String candyD = '0';
  String invertI = '0';
  String invertD = '0';
  String removedFood = '0';
  String leftFood = '0';
  String queenNumber = '';
  String queenAlpha1 = '';
  String queenAlpha2 = '';
  String queenMark = '';
  String biovarState = '';
  String biovarBelts = '';
  String varroaH = '';
  String varroaXX = '';
  String beePollenHarvestHML = '0';
  String beePollenHarvestML = '0';
  String beePollenHarvestI = '0';
  String beePollenHarvestD = '0';
  String acidH = '0';
  String acidXX = '0';
  String deadBeeHML = '0';
  String deadBeeML = '0';

  //zmienne dla funkcji "pokaz ul"
  int indexDaty = 0; //0-data bieząca, 1-data wcześniejsza od 0
  String wybranaData =
      DateTime.now().toString().substring(0, 10); //aktualna data
  List<Frame> _korpusy = []; //unikalne korpusy dla "pokaz ul"
  List<Frame> _daty = []; //unikalne daty
  double widthCanvas = 0; //szerokość płótna
  double highCanvas = 0; //wysokość płótna

  //=== TRZY NIEZALEŻNE STREFY EKRANU (04.08.2026) ===
  //1. dane komendy (buildAnswerArea) - gdzie jesteśmy: pasieka, ul, korpus,
  //   ramka, zasób, zapis,
  //2. korpus (buildKorpusArea) - jeden korpus w widoku "po", z datą nad nim,
  //3. teksty (buildPasekStanu / buildRhinoTextArea) - notatka, komunikaty, błędy.
  //
  //Do 04.08.2026 strefy dzieliły się flexem odziedziczonym po Picovoice
  //(4 / 2 / 0-4), a rysunek korpusu nie miał żadnego ograniczenia rozmiaru i
  //rozlewał się na sąsiadów. Dwie przyczyny, obie w [MyHive]:
  // - painter maluje numery ramek POZA zadeklarowanym `size` (y = -16 nad
  //   obrysem i high+3 pod nim), a CustomPaint niczego nie przycina - stąd
  //   numery wchodziły na teksty nad korpusem w układzie pionowym,
  // - szerokość jest sztywna (widthCanvas = ramek * 20 + 20), więc ul
  //   20-ramkowy to 420 px, które w układzie poziomym wychodziły na lewy panel.
  //Teraz strefa 2 ma wysokość LICZONĄ z typu korpusu, jest przycięta (ClipRect)
  //i w razie potrzeby przeskalowana w dół (FittedBox) - cały korpus jest zawsze
  //widoczny bez przewijania, bo przy ulu nie ma jak przewijać w rękawicach.
  static const double _kNaglowekKorpusu = 22; //wiersz "po <data przeglądu>"
  static const double _kNumeryRamek = 18; //pas na numery ramek nad i pod obrysem
  static const double _kZapasKorpusu = 8; //margines estetyczny strefy korpusu
  static const double _kMinStrefaTekstu = 64; //minimum dla strefy 3 w poziomie

  //STAŁE WYSOKOŚCI STREF 1 i 2 (04.08.2026). Wcześniej obie strefy zajmowały
  //tyle, ile akurat miały treści, więc dopóki nie było otwartej pasieki i ula,
  //wiersz uli i komunikaty podjeżdżały pod pasek tytułu, a przy pierwszej
  //komendzie zjeżdżały w dół - ekran "skakał" przy każdym słowie. Teraz obie
  //strefy dostają miejsce policzone z NAJWYŻSZEGO możliwego układu i trzymają
  //je niezależnie od tego, co jest wypełnione.
  //
  //STREFA 1 - suma wierszy [buildAnswerArea] w wariancie dla większych ekranów:
  //   padding kontenera 2 * 15                        30
  //   wiersz pasieki                                  45
  //   wiersz ul/korpus/ramka 92 + 2 * marginRow(10)  112
  //   dane matki (ikona 24 + margines 5)              29
  //   rozmiar i strona ramki                          45
  //   zapisywany zasób albo info (wyklucza się        110
  //     wzajemnie) hightSave(100) + marginRow(10)
  //Wiersza "wszystkie ule" (60 + 2 * 10 = 80) NIE liczymy: nigdy nie stoi razem
  //z wierszem ul/korpus/ramka, bo `readyAllHives = true` zawsze zeruje
  //`readyHive`, a każde `readyHive = true` zeruje `readyAllHives`. Jest przy tym
  //niższy od tamtego (80 < 112), więc to wiersz ul/korpus/ramka wyznacza maksimum.
  static const double _kStrefaDanych = 371;
  //ten sam rachunek dla wariantu MAŁEGO ([_maleWiersze]: ekrany za niskie na
  //układ duży oraz KAŻDY układ poziomy), gdzie wiersze mają mniejsze warianty:
  //30 + 40 + (60 + 2 * marginRow) + 29 + 40 + (85 + marginRow).
  //Wiersz "wszystkie ule" odpada tak samo jak wyżej; tu oba wykluczające się
  //wiersze mają po 80 px, więc obojętne, który zostaje w sumie.
  //15.08.2026: ostatni składnik urósł z 75 na 85 px - pudełko "Zapis:" nie
  //mieściło dwóch linii (rachunek przy tamtym pudełku).
  static const double _kStrefaDanychMala = 314;
  //STREFA 2 - najwyższy korpus (typ 2 => 2 * 75 + 30 = 180) z pasami na numery
  //ramek, nagłówkiem daty i zapasem: 22 + (180 + 2 * 18) + 2 * 8
  static const double _kStrefaKorpusu = 254;

  //zmienne pogodowe
  String pobranie = '';
  double temp = 0.0;
  String icon = '';
  String units = 'metric';
  String stopnie = '\u2103';

  int zwloka = 1500;

  final _sound = SoundHelper();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); //przerwania: telefon, tło, Siri
    _sound.init(); //preload dźwięków
    // Orientacja zależy od trybu pracy ekranu: podgląd korpusu na żywo
    // potrzebuje poziomu, podpowiedzi komend czytelniejsze są w pionie.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      if (globals.voice2LivePodglad) DeviceOrientation.landscapeLeft,
      if (globals.voice2LivePodglad) DeviceOrientation.landscapeRight,
    ]);
    setState(() {
      isButtonDisabled = true;
      rhinoText = "";
      WakelockPlus.enable(); //blokada wyłaczania ekranu
    });

    //DANE DO TESTOWANIA TEGO EKRANU
    // readyApiary = true; //ustalony numer pasieki
    // readyAllHives = false; //polecenia dla wszy
    // readyHive = true; //ustalony numer ula
    // readyBody = true; //ustalony numer korpusu
    // readyHalfBody = false; //ustalony numer półkorpusu
    // readyFrame = true; //ustalony numer ramki
    // readyStory = true; //gotowość do zapisu w bazie poszczególnych produktów
    // readyInfo = false; //gotowość do zapisu info
    // readyFrames = false; //ustalony zakres kilku ramek
    
    // nrXXOfApiary = 1; //numer pasieki
    // nrXXOfHive = 1;
    // nrXOfBody = 1;
    // nrXXOdFrame = 0;
    // nrXXDoFrame = 0;
    // nrXXOfFrame = 10;
    // nrXXOfFramePo = 10;


    // Model i mikrofon startują po pierwszej klatce - _uruchomVosk() woła
    // setState (pasek stanu), a to w trakcie budowania drzewa kończy się
    // asercją "setState called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) => _uruchomVosk());
  }

  @override
  void dispose() {
    _inferenceTimer?.cancel(); //anulowanie timera
    _timerKomunikatuNotatki?.cancel(); //kasowanie komunikatu notatki
    WidgetsBinding.instance.removeObserver(this);
    //nasłuch jest ciągły, więc wyjście z ekranu MUSI zwolnić mikrofon
    _engine?.zamknij();
    _sound.dispose(); //zwolnienie odtwarzaczy dźwięku
    WakelockPlus.disable(); //usunięcie blokady wygaszania ekranu
    // Powrót do wymuszonej orientacji pionowej
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  void didChangeDependencies() {

    if (_isInit) {
      formattedDate = formatter.format(now);

      // final dod1Data = Provider.of<Dodatki1>(context);
      // final dod1 = dod1Data.items;
      // zwloka = int.parse(dod1[0].h);
      //Locale myLocale = Localizations.localeOf(context);
      //print(myLocale);
      // Provider.of<Frames>(context, listen: false).fetchAndSetFrames().then((_) {
      //   print('voice_screen: pobrano wszystkie ramki z bazy lokalnej do voice');
      // });
    }
    // Provider.of<Hives>(context, listen: false)
    //       .fetchAndSetHives(globals.pasiekaID)
    //       .then((_) {
    //     //wszystkie ule z tabeli ule z bazy lokalnej
    //   });
    _isInit = false;

    super.didChangeDependencies();
  }

 //sprawdzenie czy jest internet
  Future<bool> _isInternet() async { 
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      // Mobile network available.
      return true;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      // Wi-fi is available.
      // Note for Android: When both mobile and Wi-Fi are turned on system will return Wi-Fi only as active network type
      return true;
    } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
      // Bluetooth connection available.
      return true;
    } else if (connectivityResult.contains(ConnectivityResult.other)) {
      // Connected to a network which is not in the above mentioned networks.
      return false;
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      // No available network types
      return false;
    }else return false;
  }

  // ---- warstwa wejścia: Vosk ----------------------------------------------

  //wczytanie gramatyki, pobranie modelu i start nasłuchu w CZUWANIU
  Future<void> _uruchomVosk() async {
    if (!mounted) return;
    setState(() {
      isButtonDisabled = true;
      _stanNasluchu = 'Przygotowuję rozpoznawanie mowy...';
    });

    // Wybór języka silnika - NIEZALEŻNY kod od globals.jezyk (locale, np.
    // 'pl_PL'/'en_US'), bo VoskGrammar/VoskEngine znają tylko dwa krótkie
    // kody i mają się nie rozjechać przy kolejnych językach UI. Bramka w
    // apiarys_screen.dart na razie i tak wpuszcza tu tylko 'pl_PL'/'en_US'.
    final String jezykSilnika = globals.jezyk == 'en_US' ? 'en' : 'pl';
    final String sciezkaGramatyki = jezykSilnika == 'en'
        ? 'assets/grammar/eng_vosk.yml'
        : 'assets/grammar/pol_vosk.yml';

    try {
      //ta sama gramatyka generuje słownik dla recognizera i parsuje wynik
      _gramatyka =
          await VoskGrammar.zAssetu(sciezkaGramatyki, jezyk: jezykSilnika);
    } catch (e) {
      _bladSilnika('Błąd gramatyki poleceń:\n$e');
      return;
    }

    //KONTROLA WCZYTANEGO ASSETU. Gramatyka jest assetem, a assety NIE odświeżają
    //się przy hot reloadzie - w zbudowanej apce potrafi siedzieć starsza wersja
    //pliku niż ta w repo. Objaw jest mylący: komenda notatki brzmi wtedy dla
    //Vosk jak najbliższa znana fraza, więc ekran melduje „przyjęte: ..." i
    //wykonuje CUDZĄ komendę, zamiast powiedzieć, że notatki nie zna (zgłoszenie
    //z 03.08.2026). Sprawdzenie jest darmowe i od razu wskazuje winnego.
    if (!_gramatyka!.intencje.contains('voiceNote') ||
        !_gramatyka!.intencje.contains('voiceNotepad') ||
        !_gramatyka!.intencje.contains('voiceUndo')) {
      debugPrint('VOSK: wczytana gramatyka NIE ZNA intencji notatki albo '
          'cofania (voiceNote/voiceNotepad/voiceUndo) - w pakiecie jest stary '
          'assets/grammar/pol_vosk.yml');
      //FLAGA, nie komunikat na pasku: pasek stanu zaraz i tak nadpisze silnik
      //('Przygotowuję rozpoznawanie mowy...'), a to jest informacja, która ma
      //zostać na ekranie do końca sesji.
      if (mounted) setState(() => _gramatykaNieaktualna = true);
    }

    _engine = VoskEngine(
      gramatyka: _gramatyka!,
      jezyk: jezykSilnika,
      //okno na sklejenie komendy rozciętej przez Vosk = ta sama zwłoka,
      //którą ekran daje sobie na dokończenie przetwarzania komendy
      oknoSklejania: Duration(milliseconds: zwloka),
      onStan: (opis, tryb) {
        if (!mounted) return;
        setState(() {
          _stanNasluchu = opis;
          _stanBazowy = opis;
          isProcessing = tryb == TrybNasluchu.komendy;
          _mikrofonMilczy = tryb == TrybNasluchu.wylaczony;
          //nasłuch znów działa - kasujemy błąd, inaczej po odzyskaniu
          //mikrofonu ekran zostałby na zawsze w stanie awarii
          if (tryb != TrybNasluchu.wylaczony) {
            isError = false;
            errorMessage = "";
            isButtonDisabled = false;
          }
        });
      },
      onPartial: (tekst) {
        if (!mounted) return;
        setState(() => _partial = tekst);
      },
      onDyktowanieTekst: (tekst) {
        if (!mounted) return;
        setState(() => _tekstNotatki = tekst);
      },
      onKoniecDyktowania: _zapiszNotatke,
      onFraza: _naFraze,
      onBlad: _bladSilnika,
    );

    final bool ok = await _engine!.uruchom();
    if (!mounted) return;
    setState(() {
      _silnikGotowy = ok;
      isButtonDisabled = !ok;
      if (ok) rhinoText = "";
    });
  }

  //domknięta fraza z Vosk: najpierw sesja, potem bramka, potem logika pasieczna
  void _naFraze(VoskFraza f) {
    if (!mounted) return;
    setState(() => _partial = '');

    //1. komendy sterujące sesją - obsługiwane PRZED switchem pasiecznym
    if (f.inference.isUnderstood == true) {
      if (f.inference.intent == 'voiceStart') {
        _startSesji();
        return;
      }
      if (f.inference.intent == 'voiceStop') {
        _stopSesji();
        return;
      }
    }

    //2. w czuwaniu nic poza frazami sesji nas nie interesuje
    if (_engine?.tryb != TrybNasluchu.komendy) return;

    //3. bramka. Odrzucone IGNORUJEMY PO CICHU: przy nasłuchu ciągłym mikrofon
    //łapie rozmowę przy ulu, a sygnał błędu po każdym zdaniu byłby nie do
    //zniesienia. Ślad zostaje najwyżej na pasku stanu - ile go widać, o tym
    //decyduje [_opisFrazy] i przełącznik diagnostyki.
    setState(() => _stanNasluchu = _opisFrazy(f));
    if (!f.przyjeta) return;
    //ślad w konsoli Xcode - jedyne miejsce, gdzie widać ZARAZEM tekst z Vosk i
    //intent, na który został sparsowany. Na ekranie to samo pokazuje wyłącznie
    //diagnostyka; tutaj jest zawsze, bo bez tego zdalna diagnoza „komenda nic
    //nie robi" sprowadza się do zgadywania.
    debugPrint('VOSK fraza: „${f.tekst}" → ${f.inference.intent} '
        '${f.inference.slots}');

    //4. dyktowanie notatki - przechwytywane przed switchem pasiecznym, ale
    //DOPIERO PO bramce (inaczej niż voiceStart/voiceStop, które ją omijają):
    //pomyłkowe wejście w dyktowanie zabiera mikrofon na kilkadziesiąt sekund
    //i kończy się wpisem w bazie, więc niepewne rozpoznanie ma je odrzucić.
    if (f.inference.intent == 'voiceNote') {
      _zacznijNotatke(UjscieNotatki.przeglad);
      return;
    }
    if (f.inference.intent == 'voiceNotepad') {
      _zacznijNotatke(UjscieNotatki.notes);
      return;
    }

    //5. cofanie ostatniego zapisu - tak jak dyktowanie, PO bramce pewności:
    //komenda zmienia bazę, więc niepewne rozpoznanie ma ją odrzucić. Do switcha
    //pasiecznego nie trafia, bo nie jest komendą pasieczną - nie ma ustawiać
    //żadnego kontekstu ani czyścić slotów.
    if (f.inference.intent == 'voiceUndo') {
      _cofnijOstatniZapis();
      return;
    }

    _obsluzKomende(f.inference);
  }

  //Opis frazy na pasku stanu.
  //
  //SUROWY TEKST Z VOSK TRAFIA NA EKRAN WYŁĄCZNIE W DIAGNOSTYCE. Gramatyka stoi
  //na aliasach fonetycznych - „pierzcha" zamiast pierzga, „węża" zamiast węza,
  //„miodu branie" zamiast miodobranie, „na grób" zamiast nakrop - bo poprawnych
  //form NIE MA w słowniku modelu (patrz komentarze w assets/grammar/pol_vosk.yml).
  //Komenda działa prawidłowo, ale pszczelarz, który zobaczy „przyjęte: pierzcha
  //50 procent", uzna to za błąd aplikacji. Dlatego na produkcji pokazujemy
  //wyłącznie sam fakt nieudanego rozpoznania, bez cytatu i bez liczb.
  String _opisFrazy(VoskFraza f) {
    if (globals.voiceDiagnostyka) {
      if (!f.przyjeta) return 'pominięte: „${f.tekst}" (${f.powod})';
      //INTENT, nie sam tekst. Bez niego „przyjęte: ..." nie odróżnia komendy
      //zrozumianej ZGODNIE Z ZAMIAREM od zrozumianej jako CO INNEGO - a to była
      //cała zagadka nieruszającej notatki (03.08.2026): pasek meldował
      //„przyjęte", ekran wykonywał obcą komendę i nikt nie widział, którą.
      final String intent = f.inference.intent ?? '?';
      //pewność przy komendach PRZYJĘTYCH - inaczej nie da się na urządzeniu
      //ocenić, jak blisko progu chodzą normalnie wypowiadane komendy
      if (f.sredniaConf < 0) return 'przyjęte: „${f.tekst}" → $intent';
      return 'przyjęte: „${f.tekst}" → $intent '
          '(śr. ${f.sredniaConf.toStringAsFixed(2)}, '
          'min ${f.minConf.toStringAsFixed(2)})';
    }

    //przyjęta komenda mówi sama za siebie: Maja się odzywa i odświeża się
    //podgląd korpusu. Wracamy do komunikatu o trybie nasłuchu
    if (f.przyjeta) return _stanBazowy;

    //fraza z [unk] to mowa spoza gramatyki, czyli w praktyce rozmowa przy ulu,
    //a nie nieudana komenda - meldunek po każdym zdaniu byłby czystym szumem
    if (f.unk > 0) return _stanBazowy;

    //tu użytkownik naprawdę mówił do aplikacji: albo komenda nie pasowała do
    //żadnego wzorca, albo przepadła na progu pewności
    return 'Nie zrozumiałam polecenia.';
  }

  //otwarcie sesji: "Hej Maja start" zastąpiło przycisk START
  Future<void> _startSesji() async {
    final VoskEngine? e = _engine;
    if (e == null || e.tryb == TrybNasluchu.komendy) return;
    _inferenceTimer?.cancel();
    if (!e.nagrywa) {
      //mikrofon mógł paść (telefon, tło, Siri) - najpierw go odzyskaj.
      //wznowOdNowa, bo to świadome działanie użytkownika: nie każemy mu czekać
      //na kolejny krok backoffu
      if (!await e.wznowOdNowa()) return;
    }
    await e.ustawTryb(TrybNasluchu.komendy);
    if (e.tryb != TrybNasluchu.komendy) return; //przełączenie się nie udało
    if (!mounted) return;
    setState(() {
      isProcessing = true;
      rhinoText = AppLocalizations.of(context)!.hiBeesDetected;
    });
    _zagraj('start'); //"czekam na polecenia"
  }

  //zamknięcie sesji: "Hej Maja stop" -> powrót do czuwania, ekran zostaje
  Future<void> _stopSesji() async {
    final VoskEngine? e = _engine;
    if (e == null || e.tryb != TrybNasluchu.komendy) return;
    _inferenceTimer?.cancel();
    await e.ustawTryb(TrybNasluchu.czuwanie);
    if (!mounted) return;
    setState(() {
      isProcessing = false;
      rhinoText = "";
    });
    _zagraj('listening'); //"czekam"
  }

  //Komunikat o notatce - patrz [_komunikatNotatki]. Sam się kasuje po 25 s,
  //żeby „Zapisałam notatkę." nie wisiało na ekranie przez cały przegląd.
  void _powiedzONotatce(String tekst) {
    _timerKomunikatuNotatki?.cancel();
    if (!mounted) return;
    setState(() => _komunikatNotatki = tekst);
    if (tekst.isEmpty) return;
    _timerKomunikatuNotatki = Timer(const Duration(seconds: 25), () {
      if (!mounted) return;
      setState(() => _komunikatNotatki = '');
    });
  }

  //DYKTOWANIE NOTATKI
  //
  //"zanotuj" / "zapisz notatkę" / "Hej Maja notatka do przeglądu" -> uwagi
  //dzisiejszego przeglądu tego ula. "Hej Maja notatka do notesu" -> nowy wpis
  //w Notesie. Jedno i drugie otwiera ten sam nasłuch swobodny (recognizer bez
  //gramatyki); różni je wyłącznie [ujscie], czyli miejsce zapisu.
  //
  //Notatka przeglądu trafia do rekordu KONKRETNEGO ula, więc bez wybranej
  //pasieki i ula nie ma jej gdzie zapisać - i trzeba to powiedzieć, bo sama
  //cisza w odpowiedzi na komendę wygląda jak awaria aplikacji. Notatka do
  //notesu takiego warunku nie ma: to samodzielny wpis, można ją podyktować
  //zaraz po otwarciu sesji.
  Future<void> _zacznijNotatke(UjscieNotatki ujscie) async {
    final VoskEngine? e = _engine;
    if (e == null) return;
    _ujscieNotatki = ujscie;
    //CAŁA METODA POD JEDNYM try. Leci bez await z [_naFraze], więc wyjątek z
    //dowolnego jej miejsca nie ma dokąd wypłynąć - przepada w pustce, a ekran
    //zostaje w trybie komend, bez ikony i bez słowa wyjaśnienia. Dokładnie tak
    //wyglądało zgłoszenie z 03.08.2026 (winna była odzywka „słucham", patrz
    //[_zagraj]), więc pojedyncze łatanie znanego winowajcy nie wystarczy:
    //łańcuszek jest długi i każdy jego krok sięga do wtyczek audio.
    try {
      if (ujscie == UjscieNotatki.przeglad &&
          (nrXXOfApiary == 0 || nrXXOfHive == 0)) {
        _slad('brak pasieki albo ula');
        _powiedzONotatce('Notatka do przeglądu: najpierw powiedz, która pasieka '
            'i który ul (np. „pasieka jeden", „ul siedem"). Notatkę do notesu '
            'możesz dyktować od razu.');
        await _zagraj('nie_rozumiem');
        return;
      }
      _powiedzONotatce(''); //nowa notatka - stary komunikat traci ważność
      _inferenceTimer?.cancel();
      _slad('polecenie przyjęte');
      //"słucham" PRZED wejściem w dyktowanie, nigdy po: w dyktowaniu mikrofon
      //przyjmuje wszystko, więc odzywka Mai wpisałaby się w treść notatki.
      //Odzywka jest jednak DODATKIEM, nie warunkiem - gdy odtwarzacz padnie,
      //wchodzimy w dyktowanie bez niej. Cicha notatka jest do przeżycia,
      //milcząco pominięta komenda nie jest.
      await _zagraj('wake_word');
      _slad('po odzywce');
      //po odzywce silnik trzyma jeszcze ogon wyciszenia, na którego końcu
      //RESETUJE recognizer. Wejście w dyktowanie przed tym resetem kosztowałoby
      //pierwsze słowa notatki, więc czekamy, aż mikrofon naprawdę wróci
      for (int i = 0; i < 20 && (_engine?.wyciszony ?? false); i++) {
        await Future.delayed(const Duration(milliseconds: 25));
      }
      if (!mounted) return;
      setState(() {
        _dyktuje = true;
        _tekstNotatki = '';
      });
      _slad('włączam dyktowanie');
      //Przełącznik nagrywania czytamy PRZY KAŻDEJ notatce, a nie raz przy
      //budowie silnika - użytkownik może go wyłączyć w Ustawieniach w trakcie
      //pracy i następna notatka ma być już bez dźwięku.
      e.nagrywajNotatke = globals.nagrywajNotatki;
      //Zawieszone wywołanie kanału też musi mieć wyjście - stąd twardy limit
      //czasu zamiast czekania w nieskończoność.
      bool ok = false;
      String? awaria;
      try {
        ok = await e.zacznijDyktowanie().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            awaria = 'silnik nie odpowiedział w 5 s';
            return false;
          },
        );
      } catch (err) {
        awaria = '$err';
      }
      if (ok) {
        _slad('dyktowanie działa');
        return;
      }
      //Po limicie czasu silnik mógł mimo wszystko wejść w dyktowanie - wtedy
      //mikrofon nagrywałby notatkę, o której ekran już nie wie. Domykamy ją.
      if (awaria != null && e.dyktuje) {
        try {
          await e.przerwijDyktowanie();
        } catch (_) {}
      }
      //silnik nie wszedł w dyktowanie - recognizery dyktowania nie powstały
      //przy starcie. Reszta sterowania głosem działa dalej, ale notatki nie
      //będzie. POWÓD POKAZUJEMY WPROST: samo "niedostępne" nie daje się
      //zdiagnozować po teście na urządzeniu, a to jedyna informacja, jaka do
      //nas wraca
      if (!mounted) return;
      final String powod = awaria ?? e.powodOdmowyDyktowania ?? 'nieznany powód';
      debugPrint('Notatka: dyktowanie nie ruszyło - $powod');
      setState(() => _dyktuje = false);
      _slad('odmowa: $powod');
      _powiedzONotatce('Notatka niedostępna: $powod');
      await _zagraj('nie_rozumiem');
    } catch (err, stos) {
      //Ostatnia deska ratunku. Bez niej awaria dowolnego kroku wygląda z
      //zewnątrz identycznie jak zignorowana komenda.
      debugPrint('Notatka: awaria wejścia w dyktowanie - $err\n$stos');
      if (!mounted) return;
      setState(() => _dyktuje = false);
      _slad('awaria: $err');
      _powiedzONotatce('Notatka: awaria ($err)');
    }
  }

  //Ostatni krok wejścia w dyktowanie - patrz [_sladNotatki]. Do konsoli leci
  //zawsze, na ekran tylko przy włączonej diagnostyce.
  void _slad(String krok) {
    debugPrint('Notatka [krok]: $krok');
    if (!mounted || !globals.voiceDiagnostyka) return;
    setState(() => _sladNotatki = krok);
  }

  //Koniec dyktowania. Notatka przeglądu idzie do pola "uwagi" rekordu przeglądu
  //(kategoria "inspection") dla dzisiejszej daty i wybranego ula; notatka do
  //notesu - do tabeli "notatki" przez [_zapiszDoNotesu].
  //
  //DOPISUJEMY, nigdy nie nadpisujemy: rekord przeglądu jest jeden na dzień i
  //ul, więc druga notatka tego samego dnia bez doklejenia skasowałaby pierwszą.
  //
  //Zapis idzie przez DBHelper.updateInfoUwagi, a NIE przez Infos.insertInfo:
  //insert to ConflictAlgorithm.replace po składanym id, więc wstawienie samych
  //uwag wyzerowałoby w istniejącym rekordzie czas, wartość i temperaturę.
  //
  //Zapisujemy przy KAŻDYM powodzie zakończenia - także po limicie czasu i po
  //utracie mikrofonu. Notatka ucięta w pół zdania jest do poprawienia w ekranie
  //notatek, notatka utracona nie jest.
  Future<void> _zapiszNotatke(String tekst, PowodKoncaDyktowania powod) async {
    if (!mounted) return;
    _slad('koniec dyktowania (${powod.name}), ${tekst.trim().length} znaków');
    setState(() {
      _dyktuje = false;
      _tekstNotatki = '';
    });

    //Ścieżka dźwiękowa notatki - patrz [RecordingHelper]. Odbieramy ją TU, na
    //samym początku: bufor żyje w silniku tylko do następnego dyktowania, a
    //dalej jest kilka miejsc, z których ta metoda potrafi wyjść.
    final VoskEngine? silnik = _engine;
    final Uint8List? nagranie = silnik?.pcmOstatniejNotatki;
    final bool nagranieZDzwiekiem = silnik?.nagranieMaDzwiek ?? false;
    silnik?.porzucNagranie(); //bufor mamy u siebie - silnik ma go nie trzymać

    final String rozpoznane = tekst.trim();
    //Notatka bez ani jednego rozpoznanego słowa, ale z SŁYSZALNYM dźwiękiem, to
    //dokładnie ten przypadek, dla którego nagrania powstały: model nie poradził
    //sobie z mową, a pszczelarz mówił. Zapisujemy wpis z treścią zastępczą, żeby
    //nagranie miało do czego być przypięte i dało się go odsłuchać. Cisza (nikt
    //nic nie powiedział) leci starą drogą - nie ma czego ratować.
    final bool ratujemyNagranie =
        rozpoznane.isEmpty && nagranie != null && nagranieZDzwiekiem;
    if (rozpoznane.isEmpty && !ratujemyNagranie) {
      _powiedzONotatce('Nie usłyszałam notatki - nic nie zapisałam.');
      await _zagraj('nie_rozumiem');
      return;
    }
    final String tresc = rozpoznane.isEmpty ? _trescBezTekstu : rozpoznane;

    if (ustawianaData != '')
      formattedDate = ustawianaData;
    else
      formattedDate = formatter.format(now);
    final String godzina = formatterHm.format(DateTime.now());

    //notes ma własną tabelę i własne pola - dalej idzie osobną drogą
    if (_ujscieNotatki == UjscieNotatki.notes) {
      await _zapiszDoNotesu(
        tresc,
        powod,
        nagranie: nagranie,
        rozpoznane: rozpoznane,
        czas: godzina,
      );
      return;
    }

    final String wpis = '$godzina - $tresc';
    final String idInfo = '$formattedDate.$nrXXOfApiary.$nrXXOfHive.inspection.'
        '${AppLocalizations.of(context)!.inspection}';

    //ZAPIS POD KONTROLĄ: ta metoda jest wołana z callbacka silnika, więc
    //wyjątek z bazy nie miałby gdzie wypłynąć - użytkownik zobaczyłby ciszę
    //i uznał, że notatka się zapisała. Treść pokazujemy przy błędzie na ekranie,
    //żeby dało się ją przepisać ręcznie, zanim zniknie.
    try {
      //null = rekordu przeglądu jeszcze nie ma ('' = jest, tylko bez uwag)
      final String? uwagi = await DBHelper.getInfoUwagi(idInfo);
      if (!mounted) return; //dalej sięgamy po context (lokalizacja, provider)
      if (uwagi == null) {
        //notatka padła przed pierwszą komendą zapisującą zasób - przegląd
        //zakładamy tak samo jak zapisDoBazy, tylko od razu z uwagami
        await Infos.insertInfo(
          idInfo, //id
          formattedDate, //data
          nrXXOfApiary, //pasiekaNr
          nrXXOfHive, //ulNr
          'inspection', //kategoria
          AppLocalizations.of(context)!.inspection, //parametr
          _ikonaUla(), //wartosc
          '', //miara
          '', //ikona pogody
          '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}', //temp
          godzina, //czas
          wpis, //uwagi
          0, //arch
        );
        globals.dataAktualnegoPrzegladu = formattedDate;
      } else {
        await DBHelper.updateInfoUwagi(
          idInfo,
          uwagi.trim().isEmpty ? wpis : '$uwagi\n$wpis',
        );
      }

      if (!mounted) return;
      await Provider.of<Infos>(context, listen: false)
          .fetchAndSetInfosForHive(nrXXOfApiary, nrXXOfHive);
    } catch (err) {
      debugPrint('Notatka: zapis nie powiódł się - $err');
      if (!mounted) return;
      _powiedzONotatce('Notatki NIE udało się zapisać ($err). Treść: „$tresc"');
      await _zagraj('error');
      return;
    }
    if (!mounted) return;
    //Nagranie PO zapisie notatki: bez rekordu przeglądu nie ma do czego go
    //przypiąć. Odwrotnie już nie - notatka bez nagrania jest w porządku.
    final bool zapisaneNagranie = await _zapiszNagranie(
      nagranie,
      zrodlo: RecordingHelper.zrodloPrzeglad,
      powiazanieId: idInfo,
      czas: godzina,
      tekst: rozpoznane,
    );
    if (!mounted) return;
    //Belka ula POZA głównym try: notatka jest już w bazie, więc potknięcie na
    //dacie przeglądu nie ma prawa zamienić się w komunikat "nie udało się zapisać".
    await _przestawDatePrzegladu();
    if (!mounted) return;
    _powiedzONotatce(_komunikatPoZapisie(
      powod,
      ratujemyNagranie: ratujemyNagranie,
      zapisaneNagranie: zapisaneNagranie,
      co: 'notatkę',
      gdzie: 'przy przeglądzie',
    ));
    //odzywka MOWĄ, nie sygnałem: notatka to rzadka, świadoma czynność i
    //użytkownik musi wiedzieć, że tekst wylądował w bazie. Przy komendach
    //"zapisałam" było za długie i zastąpił je beep - patrz [_playSuccess]
    await _zagraj(ratujemyNagranie ? 'nie_rozumiem' : 'success');
  }

  //Treść zastępcza wpisu, z którego Vosk nie wyciągnął ani jednego słowa, a w
  //nagraniu coś słychać. Bez niej nagranie nie miałoby do czego być przypięte,
  //a użytkownik nie miałby czego szukać w Notesie ani w przeglądzie.
  static const String _trescBezTekstu = '(nagranie - nie rozpoznałam słów)';

  //Zapis pliku WAV plus wpis w tabeli "nagrania". Zwraca true, gdy nagranie
  //jest na dysku. NIE RZUCA - notatka jest w tym momencie już zapisana, więc
  //awaria dźwięku nie ma prawa wyglądać jak nieudany zapis notatki.
  Future<bool> _zapiszNagranie(
    Uint8List? pcm, {
    required String zrodlo,
    required String powiazanieId,
    required String czas,
    required String tekst,
  }) async {
    if (pcm == null || pcm.isEmpty) return false;
    final String? id = await RecordingHelper.zapisz(
      pcm: pcm,
      zrodlo: zrodlo,
      powiazanieId: powiazanieId,
      data: formattedDate,
      czas: czas,
      pasiekaNr: nrXXOfApiary,
      ulNr: nrXXOfHive,
      tekst: tekst,
    );
    if (id == null) {
      debugPrint('Notatka: nagranie NIE zostało zapisane.');
      return false;
    }
    if (!mounted) return true;
    //odświeżenie listy, żeby ikonka głośnika pojawiła się przy notatce od razu
    try {
      await Provider.of<Recordings>(context, listen: false)
          .fetchAndSetRecordings();
    } catch (e) {
      debugPrint('Notatka: odświeżenie nagrań - $e');
    }
    return true;
  }

  //Komunikat po zapisie. Trzy rzeczy, o których użytkownik musi wiedzieć:
  //co zapisano, czy dyktowanie ucięło się na limicie i czy tekst w ogóle
  //powstał (gdy nie - jedyną treścią wpisu jest nagranie).
  //[co] jest w bierniku („notatkę"), [gdzie] w miejscowniku („przy notatce") -
  //komunikat idzie na ekran i ma się dać przeczytać.
  String _komunikatPoZapisie(
    PowodKoncaDyktowania powod, {
    required bool ratujemyNagranie,
    required bool zapisaneNagranie,
    required String co,
    required String gdzie,
  }) {
    if (ratujemyNagranie) {
      return 'Nie rozpoznałam słów, ale nagranie zapisałam - odsłuchaj je '
          '$gdzie.';
    }
    final String limit = powod == PowodKoncaDyktowania.limitCzasu
        ? ' (osiągnięty limit długości)'
        : '';
    final String dzwiek = zapisaneNagranie ? ' razem z nagraniem' : '';
    return 'Zapisałam $co$dzwiek$limit.';
  }

  //NOTATKA DO NOTESU - drugie ujście dyktowania ("Hej Maja notatka do notesu").
  //
  //Wpis idzie do tabeli "notatki", czyli tam, gdzie lądują notatki zakładane
  //ręcznie w Notesie - i tak samo jak one jest osobnym rekordem, a nie doklejką
  //do przeglądu. Nie wymaga wybranej pasieki ani ula; jeśli są znane, zapisujemy
  //je jako kontekst (lista notatek pokazuje wtedy „pasieka/ul" przy wpisie).
  //
  //Daty zadania (pole1) dyktując nie ma jak podać, więc zostaje pusta - i
  //dlatego NIE wołamy NotificationHelper.scheduleAllNotifications(): planowanie
  //powiadomień dotyczy wyłącznie notatek z datą zadania.
  Future<void> _zapiszDoNotesu(
    String tresc,
    PowodKoncaDyktowania powod, {
    Uint8List? nagranie,
    String rozpoznane = '',
    String czas = '',
  }) async {
    //ZAPIS POD KONTROLĄ - tak samo jak przy notatce przeglądu: metoda leci
    //z callbacka silnika, więc wyjątek z bazy nie miałby gdzie wypłynąć, a
    //użytkownik uznałby ciszę za udany zapis.
    final int idNotatki;
    try {
      //id z bazy (AUTOINCREMENT), bo do niego przypinamy nagranie - inaczej nie
      //dałoby się odróżnić dwóch notatek podyktowanych tego samego dnia.
      idNotatki = await Notes.insertNotatki(
        formattedDate, //data
        _tytulZTresci(tresc), //tytul
        nrXXOfApiary, //pasiekaNr - 0, gdy nie wybrano
        nrXXOfHive, //ulNr - 0, gdy nie wybrano
        tresc, //notatka
        0, //status - nowa, tak jak przy ręcznym dodawaniu
        'false', //priorytet - dyktując nie ma jak go ustawić
        '', //pole1 - data zadania
        '', //pole2
        '', //pole3
        '', //uwagi
        0, //arch
      );
      if (!mounted) return;
      await Provider.of<Notes>(context, listen: false).fetchAndSetNotatki();
    } catch (err) {
      debugPrint('Notatka do notesu: zapis nie powiódł się - $err');
      if (!mounted) return;
      _powiedzONotatce('Notatki NIE udało się zapisać ($err). Treść: „$tresc"');
      await _zagraj('error');
      return;
    }
    final bool zapisaneNagranie = await _zapiszNagranie(
      nagranie,
      zrodlo: RecordingHelper.zrodloNotes,
      powiazanieId: '$idNotatki',
      czas: czas,
      tekst: rozpoznane,
    );
    if (!mounted) return;
    _powiedzONotatce(_komunikatPoZapisie(
      powod,
      ratujemyNagranie: rozpoznane.isEmpty,
      zapisaneNagranie: zapisaneNagranie,
      co: 'notatkę w notesie',
      gdzie: 'w Notesie',
    ));
    await _zagraj(rozpoznane.isEmpty ? 'nie_rozumiem' : 'success');
  }

  //Tytuł notatki z jej treści. Lista notatek pokazuje w belce datę i TYTUŁ, a
  //edytor notatki wymaga tytułu niepustego (walidator w note_edit_screen) -
  //dyktujący nie ma jak podać go osobno, więc bierzemy początek treści.
  //Ucinamy na granicy słowa: „trzeba dokupić węzy na wios..." czyta się gorzej
  //niż krótszy, ale całościowy początek zdania.
  String _tytulZTresci(String tresc) {
    const int limit = 30;
    if (tresc.length <= limit) return tresc;
    final String kawalek = tresc.substring(0, limit);
    final int spacja = kawalek.lastIndexOf(' ');
    //za krótki pierwszy wyraz - lepiej uciąć w połowie niż zostawić dwie litery
    return '${spacja >= 10 ? kawalek.substring(0, spacja) : kawalek}...';
  }

  //Data ostatniego przeglądu na belce ULA (pole "przeglad" tabeli "ule") oraz na
  //belce PASIEKI (to samo pole w tabeli "pasieki") - z nich liczy się "ile dni od
  //przeglądu" w widoku uli i pasiek. Notatka JEST przeglądem, więc przestawia obie
  //daty tak samo jak zapis zasobu.
  //
  //Aktualizujemy WYŁĄCZNIE to jedno pole (updateUle / updatePrzegladPasieki), a nie
  //cały rekord przez insertHive / insertApiary: insert nadpisałby licznikami zasobów
  //i ilością uli to, co zebrał przegląd - notatka nie ma o nich pojęcia.
  //
  //Data idzie tylko DO PRZODU. Notatka dopisana do starszego przeglądu (praca na
  //ustawionej dacie) nie ma prawa cofnąć belki i udawać, że ul nie był oglądany
  //od tamtej pory. Ul i pasieka są sprawdzane OSOBNO: pasieka trzyma datę
  //najświeższego przeglądu ze wszystkich uli, więc bywa nowsza niż ten jeden ul.
  Future<void> _przestawDatePrzegladu() async {
    final DateTime? nowa = DateTime.tryParse(formattedDate);
    if (nowa == null) return;
    try {
      //belka ula
      final String idUla = '$nrXXOfApiary.$nrXXOfHive';
      final List<Hive> ule = Provider.of<Hives>(context, listen: false)
          .items
          .where((h) => h.id == idUla)
          .toList();
      if (ule.isNotEmpty) {
        final DateTime? stara = DateTime.tryParse(ule[0].przeglad);
        if (stara == null || nowa.isAfter(stara)) {
          await DBHelper.updateUle(idUla, 'przeglad', formattedDate);
          if (!mounted) return;
          //odświeżenie providera, żeby belka pokazała nową datę bez wychodzenia z ekranu
          await Provider.of<Hives>(context, listen: false)
              .fetchAndSetHives(nrXXOfApiary);
        }
      }

      //belka pasieki
      if (!mounted) return;
      //typ wnioskowany - model Apiary nie jest w tym pliku importowany
      final pasieki = Provider.of<Apiarys>(context, listen: false)
          .items
          .where((p) => p.pasiekaNr == nrXXOfApiary)
          .toList();
      if (pasieki.isEmpty) {
        //nie porównujemy w ciemno z bazą - bez znanej daty nie ma jak sprawdzić,
        //czy nasza jest nowsza, a cofnięcie belki pasieki byłoby gorsze niż jej
        //nieprzestawienie
        debugPrint('Notatka: pasieki $nrXXOfApiary nie ma w providerze - '
            'data przeglądu pasieki bez zmian.');
        return;
      }
      final DateTime? staraPasieki = DateTime.tryParse(pasieki[0].przeglad);
      if (staraPasieki != null && !nowa.isAfter(staraPasieki)) return;
      await DBHelper.updatePrzegladPasieki(nrXXOfApiary, formattedDate);
      if (!mounted) return;
      await Provider.of<Apiarys>(context, listen: false).fetchAndSetApiarys();
    } catch (err) {
      //notatka jest ważniejsza niż data na belce - o błędzie tylko do konsoli
      debugPrint('Notatka: nie udało się przestawić daty przeglądu - $err');
    }
  }

  //ikona wybranego ula - do rekordu przeglądu zakładanego przez notatkę.
  //Pole "wartosc" przeglądu trzyma właśnie ikonę; notatka nie zmienia stanu
  //ula, więc bierzemy bieżącą, a przy jej braku zieloną.
  String _ikonaUla() {
    final List<Hive> ule = Provider.of<Hives>(context, listen: false)
        .items
        .where((h) => h.id == '$nrXXOfApiary.$nrXXOfHive')
        .toList();
    return ule.isEmpty ? 'green' : ule[0].ikona;
  }

  //ręczny odpowiednik komend sesji - gdy w pasiece jest zbyt głośno
  void _przelaczSesjeRecznie() {
    if (_engine == null || !_silnikGotowy) return;
    //w dyktowaniu ten sam gest KOŃCZY NOTATKĘ: użytkownik, którego "Hej Maja"
    //nie zostało usłyszane, musiałby inaczej czekać na ciszę albo na limit
    //czasu. Tekst zebrany do tej pory i tak zostanie zapisany.
    if (_engine!.dyktuje) {
      _engine!.przerwijDyktowanie();
      return;
    }
    _engine!.tryb == TrybNasluchu.komendy ? _stopSesji() : _startSesji();
  }

  //każdy dźwięk gramy z WYCISZONYM mikrofonem - inaczej Vosk usłyszy Maję
  //i jej słowa trafią do rozpoznawania jako komenda (patrz historia wake-worda
  //z 10.06.2026: to dokładnie ten błąd, tylko wtedy nie dało się go obejść)
  //
  //ODZYWKA NIGDY NIE PRZERYWA TEGO, CO ROBI EKRAN. Większość wywołań leci bez
  //await, więc wyjątek z odtwarzacza przepadał tam po cichu - ale tam, gdzie na
  //odzywkę CZEKAMY (wejście w dyktowanie notatki), zabierał ze sobą resztę
  //metody. Tak wyglądało zgłoszenie z 03.08.2026: po „zanotuj" Maja mówiła
  //„słucham" i na tym się kończyło - żadnej ikony, żadnego komunikatu, a
  //następne zdanie wracało jako „pominięte: ...", bo silnik został w komendach.
  Future<void> _zagraj(String nazwa) async {
    final VoskEngine? e = _engine;
    if (e == null) {
      await _sound.play(nazwa);
      return;
    }
    e.wyciszNaOdzywke();
    try {
      await _sound.playAndWait(nazwa);
    } catch (err) {
      debugPrint('Głos: odzywka „$nazwa" nie zagrała - $err');
    } finally {
      //wyciszenie MUSI zostać zdjęte także po awarii - inaczej mikrofon
      //zostaje głuchy na zawsze i sterowanie głosem umiera bez komunikatu
      e.wznowPoOdzywce();
    }
  }

  //potwierdzenie przyjęcia komendy: krótki sygnał systemowy zamiast okej.mp3.
  //Zgłoszone z urządzenia 02.08.2026: mowa Mai i tak przecieka do mikrofonu
  //(bufor wejścia iOS oddaje dźwięk z opóźnieniem większym niż ogon wyciszenia),
  //więc "okej" wracało z Vosk jako fraza i zaśmiecało pasek stanu. Beep jest
  //krótszy i przede wszystkim NIE JEST MOWĄ - nawet jeśli przecieknie, nie ma
  //z czego zbudować słowa. Ten sam sygnał był w voice_screen2 (linie ~447/499).
  //
  //Od 14.08.2026 gra go SoundHelper.beep(), a nie pakiet `flutter_beep`. Dźwięk
  //na iOS jest DOKŁADNIE TEN SAM (`iOSSoundIDs.JBL_NoMatch` to stała 1116,
  //podawana teraz wprost do `AudioServicesPlaySystemSound` w AppDelegate.swift);
  //pakiet odpadł dlatego, że na Androidzie nie przechodzi buildu od AGP 8 - stoi
  //na wtyczkowym build.gradle bez `namespace` i zatrzymuje build jeszcze na
  //konfiguracji Gradle. Skoro i tak trzeba było napisać to samo po stronie
  //Androida, obie platformy wołają teraz własny kanał.
  Future<void> _beepPotwierdzenia() async {
    final VoskEngine? e = _engine;
    e?.wyciszNaOdzywke();
    try {
      await _sound.beep();
      //beep() wraca po WYSŁANIU sygnału, nie po wybrzmieniu - stąd stałe okno.
      //Krótsze niż okej.mp3, więc mikrofon wraca SZYBCIEJ niż dotąd.
      await Future.delayed(const Duration(milliseconds: 250));
    } finally {
      e?.wznowPoOdzywce();
    }
  }

  void _bladSilnika(String opis) {
    if (!mounted) return;
    setState(() {
      isError = true;
      errorMessage = opis;
      isProcessing = false;
    });
  }

  //przerwania: telefon, Siri, budzik, przejście w tło. Mikrofon nie wraca sam,
  //a po powrocie ZAWSZE lądujemy w czuwaniu - komendy trzeba otworzyć na nowo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_silnikGotowy) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _inferenceTimer?.cancel();
      _engine?.wstrzymaj();
      if (mounted) {
        setState(() {
          isProcessing = false;
          rhinoText = "";
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      //wznowOdNowa, nie wznow: powrót na wierzch kasuje historię nieudanych
      //prób, więc po rozmowie telefonicznej nie czekamy jeszcze na backoff
      _engine?.wznowOdNowa();
    }
  }

  //ręczna próba odzyskania mikrofonu. Po przerwaniu silnik ponawia sam, ale
  //ikona daje użytkownikowi natychmiastową furtkę - do 02.08.2026 była w tym
  //stanie WYŁĄCZONA i jedynym wyjściem było opuszczenie ekranu.
  Future<void> _odzyskajMikrofon() async {
    final VoskEngine? e = _engine;
    if (e == null) {
      await _uruchomVosk(); //silnik w ogóle nie wstał - spróbuj od początku
      return;
    }
    setState(() => _stanNasluchu = 'Próbuję odzyskać mikrofon...');
    //gotowy = model i recognizery żyją, brakuje tylko strumienia. Jeśli padło
    //wcześniej (model), wracamy do pełnego startu NA TYM SAMYM silniku - nowy
    //obiekt zostawiłby stary rekorder i dwa recognizery w pamięci.
    final bool ok = e.gotowy ? await e.wznowOdNowa() : await e.uruchom();
    if (!mounted) return;
    setState(() {
      _silnikGotowy = e.gotowy;
      isButtonDisabled = !e.gotowy;
      if (!ok) _stanNasluchu = 'Mikrofon nadal zajęty. Próbuję dalej...';
    });
  }

  //Czy tryb zbiorczy jest zawężony do przedziału numerów uli.
  //Warunek `readyAllHives` jest tu celowo: gdy tryb gaśnie (wybór jednego ula,
  //zmiana pasieki - kilkanaście miejsc ustawia readyAllHives = false), zakres
  //ma przestać obowiązywać SAM, bez dopisywania zerowania w każdym z nich.
  bool get _zakresUliAktywny =>
      readyAllHives && nrXXOdHive != 0 && nrXXDoHive != 0;

  //Ule objęte bieżącym zapisem zbiorczym. Bez zakresu - cała pasieka, czyli
  //zachowanie sprzed dołożenia komendy "ustaw ule od X do Y".
  List<Hive> _uleObjeteZapisem(List<Hive> wszystkie) {
    if (!_zakresUliAktywny) return wszystkie;
    return wszystkie
        .where((ul) => ul.ulNr >= nrXXOdHive && ul.ulNr <= nrXXDoHive)
        .toList();
  }

  //Numery uli z zakresu - dla migawki cofania. Numery bez istniejącego ula nic
  //nie kosztują: odczyt po prostu nie znajdzie dla nich wierszy.
  List<int> get _numeryUliZZakresu =>
      [for (var nr = nrXXOdHive; nr <= nrXXDoHive; nr++) nr];

  void resetZakresUli() {
    hivesRangeState = null;
    nrXXOdHive = 0;
    nrXXOdHiveTemp = 0;
    nrXXDoHive = 0;
    nrXXDoHiveTemp = 0;
  }

  //"ule od dziesięć do pięć" ma znaczyć to samo co "od pięć do dziesięć" -
  //przy ulu nikt nie będzie powtarzał komendy przez kolejność liczb.
  void _uporzadkujZakresUli() {
    if (nrXXOdHive != 0 && nrXXDoHive != 0 && nrXXOdHive > nrXXDoHive) {
      final int pomoc = nrXXOdHive;
      nrXXOdHive = nrXXDoHive;
      nrXXDoHive = pomoc;
    }
  }

  //Włączenie trybu zbiorczego przez "ustaw ule od X do Y". Skutki uboczne są
  //TE SAME co przy "ustaw wszystkie ule" (case 'setAllHives') - jedyną różnicą
  //są granice zakresu, których ta metoda celowo NIE dotyka.
  void _wlaczTrybZbiorczyDlaZakresu() {
    readyAllHives = true;
    //UI wiersza zbiorczego czyta allHivesState; wartość inna niż `close`
    //oznacza "otwarte", więc zakres pokazuje się w tym samym wierszu
    allHivesState = AppLocalizations.of(context)!.set;
    readyHive = false;
    hiveState = AppLocalizations.of(context)!.close;
    nrXXOfHive = 0;
    bodyState = AppLocalizations.of(context)!.close;
    readyBody = false;
    globals.ikonaUla = 'green'; //"zerowanie" ikony ula
    if (nrXXOfApiary != 0) {
      aktualizacjaPogody(nrXXOfApiary); //wpis do tabeli 'pogoda'
    }
    resetSumowania();
    resetBody();
    resetStory();
    resetInfo();
  }

  //Intencje, które COKOLWIEK zapisują do bazy - tylko dla nich zdejmujemy
  //migawkę do cofania. Reszta (setHive, setBody, setApiary, setDate, setHelp)
  //ustawia jedynie kontekst komendy i nie ma czego cofać.
  static const Set<String> _intentyZapisujace = {
    'setStore',     //zasoby na ramce
    'setFrames',    //zasoby dla zakresu ramek
    'setFrame',     //wstawienie ramki (zasob 14)
    'setChange',    //zmiana numeru "po" ramki - przenumerowanie korpusu
    'setMoveBody',  //przeniesienie ramki do innego korpusu LUB ULA
    'setEquipment', //krata odgrodowa, podłoga, poławiacz, ilość ramek
    'setQueen',     //matka
    'setFeeding',   //dokarmianie
    'setTreatment', //leczenie
    'setColony',    //stan rodziny, osyp
    'setHarvest',   //zbiory
  };

  //Intencje zmieniające kontekst - po nich stos cofania jest czyszczony, bo
  //cofnięcie dotyczyłoby ula/korpusu/daty, których użytkownik już nie widzi.
  static const Set<String> _intentyKontekstu = {
    'setApiary',
    'setHive',
    'setBody',
    'setHalfBody',
    'setDate',
    //"ustaw wszystkie ule" SAMO NIC NIE ZAPISUJE - przestawia tylko tryb
    //(readyAllHives = true, nrXXOfHive = 0), więc nie ma go w intencjach
    //zapisujących. Jest za to zmianą kontekstu dokładnie tak samo jak
    //"ustaw ul 5": bez czyszczenia stosu zostawały na nim migawki jednego ula
    //sprzed przełączenia i "cofnij" sięgało po nie zamiast po wpis zbiorczy.
    'setAllHives',
    //"ustaw ule od X do Y" - ten sam tryb, tylko węższy, więc i ten sam powód
    //czyszczenia stosu: migawka sprzed zmiany zakresu dotyczy innych uli.
    'setHivesRange',
  };

  //KOMENDA PASIECZNA. VoskInference ma ten sam kształt co dawny RhinoInference
  //({isUnderstood, intent, slots}), więc prettyPrintInference i cały switch
  //pod nim zostały bez zmian - to jest sens całej migracji.
  void _obsluzKomende(VoskInference inference) {
    //anulowanie poprzedniego timera - zapobiega wyścigowi przy szybkich komendach
    _inferenceTimer?.cancel();

    if (!mounted) return; //widget już nie istnieje - nie przetwarzaj

    //MIGAWKA DO COFANIA - MUSI BYĆ PIERWSZA. Zapisy w switchu nie są awaitowane
    //(lecą w łańcuchach .then() po fetchAndSetHives), więc jedyne, co gwarantuje
    //nam stan SPRZED komendy, to zakolejkowanie transakcji odczytu zanim
    //cokolwiek zapisze. Wywołanie jest celowo bez await: gdybyśmy tu czekali,
    //trzeba by zrobić asynchroniczne całe prettyPrintInference i switch pod nim.
    final Future<MigawkaZapisu?>? przyszlaMigawka = _przygotujMigawke(inference);

    if (_intentyKontekstu.contains(inference.intent)) _stosCofania.wyczysc();

    _zapisWTejKomendzie = false; //ustawiają go zapisDoBazy / zapisInfoDoBazy
    setState(() {
      rhinoText = prettyPrintInference(inference);
    });

    //Dopiero TERAZ wiadomo, czy komenda cokolwiek zapisała i pod jakim opisem -
    //`zapis` to ten sam tekst, który ekran pokazuje w wierszu "Zapis:".
    //
    //NIE UŻYWAMY tu readyStory/readyInfo: te flagi są LEPKIE, zostają w stanie
    //ekranu po poprzedniej komendzie, więc komenda odrzucona przez własny
    //warunek (np. zasób bez wybranego ula) odkładałaby na pięciopozycyjny stos
    //pustą migawkę i wypychała z niego prawdziwą.
    //
    //setChange i setMoveBody piszą z pominięciem obu funkcji zapisu (kasują i
    //wstawiają ramki wprost w switchu, przenumerowując korpus), więc dla nich
    //migawkę odkładamy zawsze - to jedyne dwa takie miejsca.
    final bool zapisano = _zapisWTejKomendzie ||
        inference.intent == 'setChange' ||
        inference.intent == 'setMoveBody';
    //ŚLAD W KONSOLI XCODE - jedyne miejsce, w którym widać ZARAZEM wszystkie
    //trzy warunki odłożenia kroku. Bez niego objaw "nie ma czego cofnąć" nie
    //odróżnia braku migawki od braku sygnału zapisu i od wyczyszczonego stosu.
    debugPrint('Cofanie: ${inference.intent} '
        'migawka=${przyszlaMigawka != null} zapis=$zapisano '
        'stos=${_stosCofania.ile}');
    if (przyszlaMigawka != null && zapisano) {
      //ODŁOŻENIE JEST SYNCHRONICZNE. Wcześniej krok dopisywał się dopiero po
      //doczytaniu migawki (await w środku), więc o kolejności na stosie
      //decydował wyścig z synchronicznym `wyczysc()` komendy kontekstowej.
      _stosCofania.odloz(przyszlaMigawka, zapis);
    }

    //live podgląd korpusu - odświeżenie gdy intencja zmienia zawartość korpusu
    //lub zmienia wybór pasieki/ula/korpusu
    const _liveRefreshIntents = {
      'setStore',     //zasoby na ramkach (w tym matka, mateczniki, toDo, isDone)
      'setChange',    //zmiana numeru "po" ramki
      'setMoveBody',  //przeniesienie ramki do innego korpusu
      'setFrames',    //zasoby dla zakresu ramek
      'setFrame',     //wstawienie nowej ramki (zapisuje zasob 14 "wstaw ramka")
      'setEquipment', //krata odgrodowa, zmiana ilości ramek
      'setApiary',    //zmiana pasieki
      'setHive',      //wybór ula - załadowanie widoku z ostatniego przeglądu
      'setBody',      //wybór korpusu
      'setHalfBody',  //wybór półkorpusu
    };
    if (globals.voice2LivePodglad &&
        inference.isUnderstood == true &&
        _liveRefreshIntents.contains(inference.intent) &&
        readyApiary && readyHive &&
        nrXXOfApiary != 0 && nrXXOfHive != 0) {
      _refreshLiveView();
    }

    //anulowalny timer zastępujący Future.delayed - przy nowej komendzie stary
    //timer jest anulowany. Po zwłoce sprzątamy ekran po komendzie; sesja trwa
    //dalej, więc NIE ma tu już żadnego dźwięku ani powrotu do wake-worda -
    //następną komendę można powiedzieć od razu, bez "Hej Maja".
    _inferenceTimer = Timer(Duration(milliseconds: zwloka), () {
      if (!mounted) return; //sprawdzenie mounted wewnątrz timera
      setState(() {
        rhinoText = "";
      });
    });
  }

  //Zdejmuje migawkę bazy sprzed komendy. Zwraca null dla komend, które niczego
  //nie zapisują - wtedy nie ma po co czytać bazy.
  //
  //ZAKRES dobieramy z intencji ORAZ ze stanu ekranu, bo od niego zależy, ile
  //trzeba przeczytać:
  //  - setMoveBody może przenieść ramkę do innego ula, którego numeru NIE ZNAMY
  //    przed wykonaniem komendy (siedzi w slocie) - stąd cała pasieka Z ramkami.
  //    Komenda jest rzadka, więc szerszy odczyt jest tańszy niż cofanie, które
  //    zgubiłoby ul docelowy,
  //  - tryb "wszystkie ule" (readyAllHives) pisze info i belkę dla KAŻDEGO ula
  //    pasieki, ale ramek nie rusza - stąd cała pasieka BEZ tabeli `ramka`.
  //    Uwaga: to STAN, a nie intencja bieżącej komendy - patrz warunek niżej,
  //  - reszta dotyczy wybranego ula.
  Future<MigawkaZapisu?>? _przygotujMigawke(VoskInference inference) {
    if (inference.isUnderstood != true) return null;
    final String? intent = inference.intent;
    if (intent == null || !_intentyZapisujace.contains(intent)) return null;
    if (nrXXOfApiary == 0) return null; //bez pasieki nie ma czego zrzucać

    //ta sama data, którą wyliczą zapisDoBazy / zapisInfoDoBazy
    final String data =
        ustawianaData != '' ? ustawianaData : formatter.format(now);

    final ZakresPlastra zakres;
    if (intent == 'setMoveBody') {
      zakres = ZakresPlastra.pasieka(data, nrXXOfApiary);
    } else if (readyAllHives) {
      //"WSZYSTKIE ULE" TO TRYB, NIE INTENCJA - i tu był błąd.
      //Zakres brany z samej intencji dawał ZakresPlastra.ul dla komendy, która
      //pisze do CAŁEJ pasieki: "ustaw wszystkie ule" (setAllHives) tylko włącza
      //tryb, a wpis robi dopiero następna komenda z inną intencją
      //("ciasto 2 kilogramy" = setFeeding). W trybie wszystkich uli
      //nrXXOfHive == 0, więc gałąź `else` niżej wychodziła przez `return null`
      //i migawki NIE BYŁO WCALE - a "cofnij" zdejmowało ze stosu starszą
      //migawkę jednego ula. Stąd objaw: cofa w jednym ulu, w pozostałych wpis
      //zostaje.
      //Bez ramek: włączenie trybu woła resetBody(), które zeruje readyFrame
      //i readyFrames, a każda komenda ramkowa wymaga jednej z tych flag (albo
      //readyHive, też zerowanego) - w tym trybie tabela `ramka` jest nietykana.
      //
      //ZAKRES ULI zawęża ten sam tryb, więc i migawkę: pusta lista `uleNr`
      //znaczy "cała pasieka", a lista numerów - dokładnie te ule, do których
      //poleci zapis. Czytanie całej pasieki też by zadziałało, ale cofanie
      //przywracałoby wtedy wiersze uli, których komenda w ogóle nie dotknęła.
      zakres = _zakresUliAktywny
          ? ZakresPlastra(
              data: data,
              pasiekaNr: nrXXOfApiary,
              uleNr: _numeryUliZZakresu,
              zRamkami: false,
            )
          : ZakresPlastra.pasieka(data, nrXXOfApiary, zRamkami: false);
    } else {
      if (nrXXOfHive == 0) return null;
      zakres = ZakresPlastra.ul(data, nrXXOfApiary, nrXXOfHive);
    }

    debugPrint('Cofanie: zdejmuję migawkę $intent, zakres='
        '${zakres.calaPasieka ? "pasieka ${zakres.pasiekaNr}" : "ul ${zakres.uleNr}"}'
        '${zakres.zRamkami ? " z ramkami" : " bez ramek"}, data=${zakres.data}');

    return _stosCofania.przygotuj(
      zakres,
      pasiekaNr: nrXXOfApiary,
      ulNr: nrXXOfHive,
      korpusNr: nrXOfBody != 0 ? nrXOfBody : nrXOfHalfBody,
    );
  }

  //"Hej Maja cofnij ostatni zapis" - przywraca stan bazy sprzed ostatniej
  //ZAPISUJĄCEJ komendy. Komunikat idzie na pasek stanu, a nie tylko dźwiękiem:
  //przy ulu w rękawicach trzeba WIDZIEĆ, co zniknęło, zanim powie się to jeszcze
  //raz.
  //
  //Komendy kontekstowe ("ustaw ul 5", "otwórz korpus 2") niczego nie zapisują,
  //więc nie trafiają na stos - cofanie sięga do ostatniego WPISU, nie do
  //ostatniej wypowiedzi. Tak też myśli użytkownik.
  //
  //ZNANE OGRANICZENIE: zapisy poprzedniej komendy nie są awaitowane, więc gdyby
  //cofanie weszło, ZANIM jej łańcuch .then() dobiegnie końca, spóźniony zapis
  //nałożyłby się z powrotem na przywrócony stan. Okno to kilkadziesiąt
  //milisekund, a wypowiedzenie całej frazy z zawołaniem trwa około dwóch sekund,
  //więc w praktyce jest zamknięte. Objaw byłby widoczny (wartość wraca na
  //ekran), nie cichy - wtedy wystarczy powtórzyć komendę.
  Future<void> _cofnijOstatniZapis() async {
    //BLOKADA NA CAŁĄ METODĘ, nie tylko na transakcję bazy. Stos zwalnia swoją
    //blokadę zaraz po przywróceniu plastra, a potem trwa jeszcze odświeżanie
    //providerów - druga fraza "cofnij", która wpadnie w to okno, zastałaby stos
    //już zdjęty i zameldowała "nie ma czego cofnąć" TUŻ PO udanym cofnięciu.
    if (_cofanieWToku) return;
    _cofanieWToku = true;
    try {
      final WynikCofania wynik = await _stosCofania.cofnij();
      if (!mounted) return;

      if (wynik.stan == StanCofania.brak) {
        setState(
            () => _stanNasluchu = AppLocalizations.of(context)!.undoNothing);
        beep('error');
        return;
      }

      if (wynik.stan == StanCofania.blad) {
        //baza odmówiła (migawka albo przywracanie) - ZAPIS ZOSTAJE, więc nie
        //wolno tego pokazać jako pustego stosu. Powód dopisujemy tylko przy
        //włączonej diagnostyce: to komunikat dla nas, nie dla pszczelarza.
        final String powod = globals.voiceDiagnostyka &&
                _stosCofania.ostatniBlad != null
            ? ': ${_stosCofania.ostatniBlad}'
            : '';
        setState(() =>
            _stanNasluchu = AppLocalizations.of(context)!.undoFailed + powod);
        beep('error');
        return;
      }

      final MigawkaZapisu cofnieta = wynik.migawka!;

      //providery trzymają dane z PRZED cofnięcia - bez tego ekran i widok uli
      //pokazywałyby wartości, których nie ma już w bazie
      try {
        await Provider.of<Apiarys>(context, listen: false).fetchAndSetApiarys();
        if (!mounted) return;
        if (cofnieta.ulNr == 0) {
          //TRYB "WSZYSTKIE ULE": cofnięcie objęło każdy ul pasieki, a wybranego
          //ula nie ma (nrXXOfHive == 0), więc nie ma czego odświeżać po ulu -
          //ani ramek, bo w tym trybie tabela `ramka` jest nietykana. Zostają
          //belki uli, na których widać dokarmianie i leczenie.
          await Provider.of<Hives>(context, listen: false)
              .fetchAndSetHives(cofnieta.pasiekaNr);
        } else if (globals.voice2LivePodglad && cofnieta.pasiekaNr != 0) {
          await _refreshLiveView(); //odświeża Frames, Infos, Hives i płótno
        } else {
          await Provider.of<Frames>(context, listen: false)
              .fetchAndSetFramesForHive(cofnieta.pasiekaNr, cofnieta.ulNr);
          await Provider.of<Infos>(context, listen: false)
              .fetchAndSetInfosForHive(cofnieta.pasiekaNr, cofnieta.ulNr);
          await Provider.of<Hives>(context, listen: false)
              .fetchAndSetHives(cofnieta.pasiekaNr);
        }
      } catch (e) {
        debugPrint('Cofanie: odświeżenie widoku nie powiodło się - $e');
      }

      if (!mounted) return;
      setState(() {
        _stanNasluchu =
            '${AppLocalizations.of(context)!.undoDone}: ${wynik.opis}';
        //wiersz "Zapis:" pokazywał to, czego już nie ma w bazie
        zapis = '0';
        readyStory = false;
        readyInfo = false;
        rhinoText = '';
      });
      await _beepPotwierdzenia();
    } finally {
      _cofanieWToku = false;
    }
  }

  //Gramatyka mówi po ludzku, baza trzyma jedno brzmienie.
  //
  //Vosk zwraca wartość slotu DOSŁOWNIE tak, jak stoi w pol_vosk.yml. Przy
  //migracji z Picovoice część wartości dostała ładniejszą/poprawniejszą formę
  //("usuń ramkę" zamiast "usuń ramka", "dziewicza" zamiast "dziewica"), ale
  //reszta aplikacji porównuje te stringi ZNAK W ZNAK z wartościami z ARB - bo
  //te same pola zapisuje też ręczna edycja (infos_edit_screen) i to na nich
  //stoją ikony ula, raporty i historia matki. Rozjazd nie wywala niczego z
  //błędem: komenda jest przyjmowana, zapisywana i... nie robi nic widocznego
  //albo (gorzej) zapisuje stan odwrotny do wypowiedzianego.
  //
  //Dlatego wartości sprowadzamy do postaci kanonicznej JEDEN RAZ, tutaj, zanim
  //cokolwiek je zobaczy. Gramatyka zostaje przy formach, które naprawdę padają
  //przy ulu i są w słowniku modelu (pliki/vosk_slownik_pl.txt).
  //
  //DOPISUJĄC WARTOŚĆ DO SLOTU w pol_vosk.yml/eng_vosk.yml sprawdź, czy taki
  //string jest w app_pl.arb/app_en.arb. Jeśli nie ma - dopisz przeliczenie
  //tutaj, w mapowaniu dla właściwego języka.
  void _ujednolicWartosciSlotow(VoskInference inference) {
    final sloty = inference.slots;
    if (sloty == null || sloty.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final Map<String, Map<String, String>> mapowanie =
        globals.jezyk == 'en_US' ? _mapowanieSlotowEn(l10n) : _mapowanieSlotowPl(l10n);

    for (final klucz in sloty.keys.toList()) {
      final kanon = mapowanie[klucz]?[sloty[klucz]];
      if (kanon != null) sloty[klucz] = kanon;
    }
  }

  //klucz slotu -> {forma z gramatyki: forma kanoniczna (ARB)}
  Map<String, Map<String, String>> _mapowanieSlotowPl(AppLocalizations l10n) => {
        //trójkąt pod ramką + zmiana numeru ramki po przeglądzie (painter ~11570,
        //warunki ~1926 / ~5527 / ~5554, frames_screen ~1997)
        'isDone': {
          'usuń ramkę': l10n.deleted, //"usuń ramka"
          'wstaw ramkę': l10n.inserted, //"wstaw ramka"
        },
        //_rozmiar ramki w zapisDoBazy (~5354) - bez tego "otwórz MAŁĄ ramkę"
        //zapisywało ramkę dużą
        'sizeOfFrame': {
          'małą': l10n.small,
          'dużą': l10n.big,
        },
        //ikona matki: matka3 = nieunasienniona (~6211), hives_screen ~871,
        //infos_screen ~504, queen_history_screen ~269
        'queenState': {
          'dziewicza': l10n.virgine, //"dziewica"
        },
        //ikona matki: matka2 = niez (switch ~6168), hives_screen ~946,
        //queen_helpers.dart _allMarkTranslations
        'queenMark': {
          'nie ma znaku': l10n.unmarked, //"nie ma znak"
        },
        //ikona matki: matka1 = zła (~6149). "do wymiany" jest teraz OSOBNĄ pozycją listy
        //(l10n.canceled - dawna "zła"), więc głos zapisuje dokładnie to, co da się
        //wybrać ręcznie; wcześniej podmienialiśmy je na "stara"
        'queenQuality': {
          'do wymiany': l10n.canceled, //"do wymiany"
          'okej': 'ok',
        },
        //infos_screen ~931 tłumaczy zapis na etykietę - ręczna edycja zapisuje
        //"norma", więc głos też musi
        'colonyForce': {
          'normalna': l10n.normal, //"norma"
        },
        //infos_screen ~946; "zawiązała kłąb" zostaje w gramatyce, bo słowa
        //"kłębie" NIE MA w słowniku modelu - kanoniczne jest "w kłębie"
        'colonyState': {
          'agresywna': l10n.aggressive, //"zła"
          'zawiązała kłąb': l10n.inCluster, //"w kłębie"
          'okej': 'ok',
        },
        //dennica - wartość idzie do info jako tekst, ale ma brzmieć tak samo jak
        //z ręcznej edycji
        'bottomBoard': {
          'wyczyszczona': l10n.clean, //"czysta"
          'okej': 'ok',
        },
      };

  //Dopisane 03.09.2026 razem z eng_vosk.yml - dużo krótsza niż polska tabela
  //wyżej. Powód: słowa w eng_vosk.yml były DOBIERANE tak, żeby już równać się
  //kanonicznej wartości z app_en.arb (patrz komentarze w eng_vosk.yml), więc
  //większość slotów (isDone, sizeOfFrame, queenMark, colonyForce) w ogóle nie
  //potrzebuje przeliczenia - "deleted"=="deleted", "small"=="small" itd. Każda
  //pozycja niżej sprawdzona znak w znak wobec app_en.arb.
  //
  //UWAGA - to NIE jest pełny audyt jak ten z 04.08.2026 dla polskiego (patrz
  //komentarze na końcu pol_vosk.yml): sprawdzone tylko wartości SLOTÓW z tej
  //metody, NIE każde miejsce w kodzie, które porównuje te stringi dalej.
  //Znaleziony przy okazji I NAPRAWIONY: voice_vosk_screen.dart ~6636 oczekiwał
  //surowego "virgin" - dopisane "virgine" (patrz komentarz tam). NIE
  //naprawiony: slot queenMark ma wartość "gone" bez odpowiadającego
  //`case 'gone':` w switchu belki matki (jest tylko dla "missing"/"nie ma"/
  //"brak") - do naprawy razem z resztą audytu (pamięć sesji
  //"voice_english_scoping").
  Map<String, Map<String, String>> _mapowanieSlotowEn(AppLocalizations l10n) => {
        'queenState': {
          'virgin': l10n.virgine, //app_en.arb: "virgine" (literówka w ARB)
        },
        'queenQuality': {
          'to exchange': l10n.canceled, //app_en.arb canceled = "to replace"
          'okay': 'ok',
        },
        'colonyState': {
          'okay': 'ok',
        },
        'bottomBoard': {
          'cleaned': l10n.clean, //app_en.arb clean = "clean"
          'okay': 'ok',
        },
      };

  String prettyPrintInference(VoskInference inference) {
    _pendingOpenBeep = false; //reset przed każdą nową inferencją - zabezpieczenie przed stanem z poprzedniej komendy
    _ujednolicWartosciSlotow(inference); //MUSI być przed switchem intencji
    if (siteOfFrame == '0') siteOfFrame = AppLocalizations.of(context)!.both;
    if (sizeOfFrame == '0') sizeOfFrame = AppLocalizations.of(context)!.big;
    String printText = ""; //ogólny - intent
    String printText1 = ""; //dla części State
    //print( '5 prettyPrintInference tworzenie tekstów i przetwarzanie komend głosowych na działania apki...........................');
    
    if (inference.isUnderstood!) {
      //printText += "5  I uderstood :)\n";
    } else {
      printText +=
          AppLocalizations.of(context)!.iNotUderstood; //"I not uderstood :(";
      beep('error');
    }

//***** OBSŁUGA MODELU GŁOSOWEGO  ******/
//**************************************/

    if (inference.isUnderstood!) {
      switch (inference.intent) {

//setStore - zasoby na ramce        
        case 'setStore':
          printText += AppLocalizations.of(context)!.store; //" Store:";
          //intention = 'setStore';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              //print('key ------ $key');
              switch (key) { 
                case 'siteOfFrame':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    beep('open');
                    printText1 += AppLocalizations.of(context)!.siteOfFrame;
                    //"\n Site of frame =";
                    printText1 += " ${slots[key]}";
                    siteOfFrame = '${slots[key]}';
                    resetInfo();
                    readyInfo = false;
                  }
                  break;
                case 'drone':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 += "\n" + AppLocalizations.of(context)!.drone + " =";
                    printText1 += " ${slots[key]}";
                    drone = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis =
                        AppLocalizations.of(context)!.drone + " = ${slots[key]}";
                    zapisZas = 1;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(1, '${slots[key]}'); //
                  }
                  break;
                case 'brood':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.broodCovered + " =";
                    printText1 += " ${slots[key]}";
                    brood = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis = AppLocalizations.of(context)!.broodCovered +
                        " = ${slots[key]}";
                    zapisZas = 2;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(2, '${slots[key]}'); //
                  }
                  break;
                case 'larvae':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.larvae + " =";
                    printText1 += " ${slots[key]}";
                    larvae = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis =
                        AppLocalizations.of(context)!.larvae + " = ${slots[key]}";
                    zapisZas = 3;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(3, '${slots[key]}'); //
                  }
                  break;
                case 'eggs':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 += "\n" + AppLocalizations.of(context)!.eggs + " =";
                    printText1 += " ${slots[key]}";
                    eggs = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis = AppLocalizations.of(context)!.eggs + " = ${slots[key]}";
                    zapisZas = 4;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(4, '${slots[key]}'); //
                  }
                  break;
                case 'pollen':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.pollen + " =";
                    printText1 += " ${slots[key]}";
                    pollen = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis =
                        AppLocalizations.of(context)!.pollen + " = ${slots[key]}";
                    zapisZas = 5;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(5, '${slots[key]}');
                  }
                  break;
                case 'food':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 += "\n" + AppLocalizations.of(context)!.food + " =";
                    printText1 += " ${slots[key]}";
                    honey = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis = AppLocalizations.of(context)!.food + " = ${slots[key]}";
                    zapisZas = 6;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(6, '${slots[key]}'); //2-honey
                  }
                  break;
                case 'honey':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 += "\n" + AppLocalizations.of(context)!.honey + " =";
                    printText1 += " ${slots[key]}";
                    honey = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis =
                        AppLocalizations.of(context)!.honey + " = ${slots[key]}";
                    zapisZas = 6;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(6, '${slots[key]}'); //2-honey
                  }
                  break;
                case 'honeySealed':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.honeySealed + " =";
                    printText1 += " ${slots[key]}";
                    honeySeald = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis = AppLocalizations.of(context)!.honeySealed +
                        " = ${slots[key]}";
                    zapisZas = 7;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(7, '${slots[key]}'); //1-honeySealed
                  }
                  break;
                case 'wax':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.waxFundation + " =";
                    printText1 += " ${slots[key]}";
                    wax = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis = AppLocalizations.of(context)!.waxFundation +
                        " = ${slots[key]}";
                    zapisZas = 8;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(8, '${slots[key]}'); //
                  }
                  break;
                case 'waxComb':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.waxComb + " =";
                    printText1 += " ${slots[key]}";
                    waxComb = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis =
                        AppLocalizations.of(context)!.waxComb + " = ${slots[key]}";
                    zapisZas = 9;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(8, '${slots[key]}'); //
                  }
                  break;
                case 'queen':
                  if (readyApiary == true &&
                      readyHive == true &&
                      (readyBody == true || readyHalfBody == true) &&
                      readyFrame == true) {
                    printText1 += "\n" +
                        AppLocalizations.of(context)!.queen +
                        " = ${slots[key]}";
                    if (globals.jezyk == "pl_PL") {
                      switch (slots[key]) {
                        //zawiera kolor znacznika
                        case 'czarna':
                          queen = '1';
                          break;
                        case 'żółta':
                          queen = '2';
                          break;
                        case 'czerwona':
                          queen = '3';
                          break;
                        case 'zielona':
                          queen = '4';
                          break;
                        case 'niebieska':
                          queen = '5';
                          break;
                        case 'biała':
                          queen = '6';
                          break;
                        case 'inna':
                          queen = '7';
                          break;
                        default:
                          queen = '1';
                      }
                    } else {
                      switch (slots[key]) {
                        //zawiera kolor znacznika
                        case 'black':
                          queen = '1';
                          break;
                        case 'yellow':
                          queen = '2';
                          break;
                        case 'red':
                          queen = '3';
                          break;
                        case 'green':
                          queen = '4';
                          break;
                        case 'blue':
                          queen = '5';
                          break;
                        case 'white':
                          queen = '6';
                          break;
                        case 'other':
                          queen = '7';
                          break;
                        default:
                          queen = '1';
                      }
                    }
                    //queen = '1'; //'${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis =
                        AppLocalizations.of(context)!.queen + " = ${slots[key]}";
                    zapisZas = 10;
                    zapisWart = queen;
                    //zapisDoBazy(10, '1'); //'${slots[key]}'
                  }
                  break;
                case 'queenCells':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.queenCells + " =";
                    printText1 += " ${slots[key]}";
                    queenCells = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis = AppLocalizations.of(context)!.queenCells +
                        " = ${slots[key]}";
                    zapisZas = 11;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(11, '${slots[key]}'); //
                  }
                  break;
                case 'delQCells':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 += "\n" +
                        AppLocalizations.of(context)!.deleteQueenCells +
                        " =";
                    printText1 += " ${slots[key]}";
                    delQCells = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis = AppLocalizations.of(context)!.deleteQueenCells +
                        " = ${slots[key]}";
                    zapisZas = 12;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(12, '${slots[key]}'); //
                  }
                  break;
                case 'toDo':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    printText1 += "\n" + AppLocalizations.of(context)!.toDo + " =";
                    printText1 += " ${slots[key]}";
                    toDo = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis = AppLocalizations.of(context)!.toDo + " = ${slots[key]}";
                    zapisZas = 13;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(13, '${slots[key]}'); //
                  }
                  break;
                case 'isDone':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    //wartość slotu jest już kanoniczna - patrz
                    //_ujednolicWartosciSlotow() na początku tej metody
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.isDone + " =";
                    printText1 += " ${slots[key]}";
                    isDone = '${slots[key]}';
                    readyStory = true;
                    resetInfo();
                    readyInfo = false;
                    zapis =
                        AppLocalizations.of(context)!.isDone + " = ${slots[key]}";
                    zapisZas = 14;
                    zapisWart = '${slots[key]}';
                    //zapisDoBazy(14, '${slots[key]}'); //
                  }
                  break;
              }
            }
            //oprócz znaczka "isDone" pod ramką zmianiany jest równiez "numerPo" ramki
            String zapisWartTemp = zapisWart; //pamięć tymczasowa wartości zapisWart bo zapisDoBazy go kasuje
            //zapis do tabeli "ramka" jezeli jest jakiś zasób
            if (zapisZas > 0) zapisDoBazy(zapisZas, zapisWart);

            //dla "wstaw ramka" nie ma tutaj zmian bo wstawiana jest tu jedna ramka której nie było - czyli komendą "wstaw ramka numer X"
            
            //dla jednej ramki !!! (dla wielu ramek jest robione podczas "zapisDoBazy" dla "readyFrames")
            //dla "usuń ramka"
            if(readyFrames == false && (zapisWartTemp == 'usuń ramka' || zapisWartTemp == 'deleted')){
              nrXXOfFramePo = 0;    
              //ustalenie numeru korpusu dla pobrania wpisów do zmiany dla ramki po
              if (nrXOfBody != 0) {
                  _korpusNr = nrXOfBody;
                } else {
                  _korpusNr = nrXOfHalfBody;
                }
              //zmiana istniejących wpisów bo zmiana numeru ramki po przeglądzie
              Provider.of<Frames>(context, listen: false)
                .fetchAndSetFramesForHive(nrXXOfApiary, nrXXOfHive)
                .then((_) {  
                  //dla wszystkich zasobów dla ramki z numerem "przed" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
                  final framesData1 = Provider.of<Frames>(context, listen: false);
                    //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu)
                  List<Frame> frames = framesData1.items.where((fr) {
                    return fr.ramkaNr == nrXXOfFrame && fr.data == formattedDate && fr.korpusNr == _korpusNr; //return fr.data.contains('2024-04-04');
                  }).toList();
                  //print('frames.length = ${frames.length}');
                    //dla kazdego zasobu modyfikacja ramkaNrPo
                  for (var i = 0; i < frames.length; i++) {
                    //print('w pętli id: ${frames[i].id}, ramkaPrzed: ${frames[i].ramkaNr}, ramkaPo: ${frames[i].ramkaNrPo}, zasób: ${frames[i].zasob}');
                    DBHelper.updateRamkaNrPo(frames[i].id, 0); //ramkaPo = 0 czyli usunięta
                  }
                Provider.of<Frames>(context, listen: false)
                  .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                  .then((_) {
                  //Navigator.of(context).pop();
                });
              }); 
            } 

            //dla "przesuń w lewo"
            if(readyFrames == false && (zapisWartTemp == 'przesuń w lewo' || zapisWartTemp == 'moved left')){
              nrXXOfFramePo = nrXXOfFramePo - 1;    
              //ustalenie numeru korpusu dla pobrania wpisów do zmiany dla ramki po
              if (nrXOfBody != 0) {
                  _korpusNr = nrXOfBody;
                } else {
                  _korpusNr = nrXOfHalfBody;
                }
              //zmiana istniejących wpisów bo zmiana numeru ramki po przeglądzie
              Provider.of<Frames>(context, listen: false)
                .fetchAndSetFramesForHive(nrXXOfApiary, nrXXOfHive)
                .then((_) {  
                  //dla wszystkich zasobów dla ramki z numerem "przed" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
                  final framesData1 = Provider.of<Frames>(context, listen: false);
                    //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu)
                  List<Frame> frames = framesData1.items.where((fr) {
                    return fr.ramkaNr == nrXXOfFrame && fr.data == formattedDate && fr.korpusNr == _korpusNr; //return fr.data.contains('2024-04-04');
                  }).toList();
                  //print('frames.length = ${frames.length}');
                    //dla kazdego zasobu modyfikacja ramkaNrPo
                  for (var i = 0; i < frames.length; i++) {
                    //print('w pętli id: ${frames[i].id}, ramkaPrzed: ${frames[i].ramkaNr}, ramkaPo: ${frames[i].ramkaNrPo}, zasób: ${frames[i].zasob}');
                    DBHelper.updateRamkaNrPo(frames[i].id, nrXXOfFramePo); //nrXXOfFramePo ma wartośc o 1 mniejszą
                  }
                Provider.of<Frames>(context, listen: false)
                  .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                  .then((_) {
                  //Navigator.of(context).pop();
                });
              }); 
            } 

            //dla "przesuń w prawo"
            if(readyFrames == false && (zapisWartTemp == 'przesuń w prawo' || zapisWartTemp == 'moved right')){
              // print('przesuń w prawo jedna ramkę !!!!!');
              // print('readyFrames = $readyFrames');
              nrXXOfFramePo = nrXXOfFramePo + 1; 
              //ustalenie numeru korpusu dla pobrania wpisów do zmiany dla ramki po
              if (nrXOfBody != 0) {
                  _korpusNr = nrXOfBody;
                } else {
                  _korpusNr = nrXOfHalfBody;
                }
              //zmiana istniejących wpisów bo zmiana numeru ramki po przeglądzie
              Provider.of<Frames>(context, listen: false)
                .fetchAndSetFramesForHive(nrXXOfApiary, nrXXOfHive)
                .then((_) {  
                  //dla wszystkich zasobów dla ramki z numerem "przed" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
                  final framesData1 = Provider.of<Frames>(context, listen: false);
                    //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu)
                  List<Frame> frames = framesData1.items.where((fr) {
                    return fr.ramkaNr == nrXXOfFrame && fr.data == formattedDate && fr.korpusNr == _korpusNr; //return fr.data.contains('2024-04-04');
                  }).toList();
                    //  print('nrXXOfHive = $nrXXOfHive');
                    //  print('frames.length = ${frames.length}');
                    //dla kazdego zasobu modyfikacja ramkaNrPo
                  for (var i = 0; i < frames.length; i++) {
                    //print('w pętli id: ${frames[i].id}, ramkaPrzed: ${frames[i].ramkaNr}, ramkaPo: ${frames[i].ramkaNrPo}, zasób: ${frames[i].zasob}');
                    DBHelper.updateRamkaNrPo(frames[i].id, nrXXOfFramePo); //nrXXOfFramePo ma wartośc o 1 większą
                  }
                Provider.of<Frames>(context, listen: false)
                  .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                  .then((_) {
                  //Navigator.of(context).pop();
                });
              }); 
            } 

            zapisWartTemp = '';

          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;

//setFrame - ustawienie numeru ramki          
        case 'setFrame':
          printText += AppLocalizations.of(context)!.frame; //" frame";
          //intention = 'setFrame';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) {      
                case 'frameState':
                  frameState = '${slots[key]}';
                  if (frameState == AppLocalizations.of(context)!.close) {
                    beep('close');
                    printText1 += " ${slots[key]}";
                    readyFrame = false;
                    nrXXOfFrame = 0;
                    nrXXOfFramePo = 0;
                    nrXXOfFrameTemp = 0;
                    resetStory();
                  } else if ((frameState == AppLocalizations.of(context)!.open ||
                        frameState == AppLocalizations.of(context)!.set) && (readyApiary == true &&
                        readyHive == true && (readyBody == true || readyHalfBody == true))) {
                      printText1 += " ${slots[key]}";
                      nrXXOfFrame = nrXXOfFrameTemp;
                      nrXXOfFramePo = nrXXOfFrameTemp;  
                      nrXXOfFrameTemp = 0;
                      readyFrame = true;
                      readyFrames = false;
                      beep('open');
                      resetStory();
                      //wstaw ramkę numer 3 - numer ramki 0/3 (decyduje słowo "wstaw" lub "insert")
                  } else if(frameState == AppLocalizations.of(context)!.insert && (readyApiary == true &&
                        readyHive == true && (readyBody == true || readyHalfBody == true))){
                      printText1 += " ${slots[key]}";
                      nrXXOfFrame = 0;
                      nrXXOfFramePo = nrXXOfFrameTemp;  
                      nrXXOfFrameTemp = 0;
                      readyFrame = true;
                      readyFrames = false;
                      beep('open');
                      resetStory();
                  }
                  break;
                case 'nrXXOfFrame':
                  nrXXOfFrame = int.parse('${slots[key]}');
                  if ((frameState == AppLocalizations.of(context)!.open ||
                          frameState == AppLocalizations.of(context)!.set) &&
                      (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true))) {
                    beep('open');
                    printText1 += " ${slots[key]}";
                    readyFrame = true;
                    readyFrames = false;
                    nrXXOfFrameTemp = nrXXOfFrame;
                    nrXXOfFramePo = nrXXOfFrame;
                    resetStory(); //kasowanie zmiennych przechowujących biezace zasoby ramki (bo nowa ramka)
                  } else if (frameState == AppLocalizations.of(context)!.insert  && (readyApiary == true &&
                        readyHive == true && (readyBody == true || readyHalfBody == true))) {
                      printText1 += " ${slots[key]}";
                      nrXXOfFramePo = nrXXOfFrame;  
                      nrXXOfFrame = 0;
                      nrXXOfFrameTemp = 0;
                      readyFrame = true;
                      readyFrames = false;
                      beep('open');
                      resetStory();
                  } else {
                    if (readyApiary == true &&
                        readyHive == true &&
                        (readyBody == true || readyHalfBody == true)) {
                      printText1 += " ${slots[key]}";
                      nrXXOfFrameTemp = nrXXOfFrame;
                      nrXXOfFrame = 0;
                      nrXXOfFramePo = 0;
                      readyFrame = false;
                      resetStory();
                    }
                  }
                  break;
                case 'sizeOfFrame': //OfFrame
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    beep('open');
                    printText1 += AppLocalizations.of(context)!.sizeOfFrame;
                    //"\n Size of frame =";
                    printText1 += " ${slots[key]}";
                    sizeOfFrame = '${slots[key]}';
                    resetInfo();
                    readyInfo = false;
                  }
                  break;
                case 'siteOfFrame':
                  if (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true) &&
                          readyFrame == true ||
                      readyFrames == true) {
                    beep('open');
                    printText1 += AppLocalizations.of(context)!.siteOfFrame;
                    //"\n Site of frame =";
                    printText1 += " ${slots[key]}";
                    siteOfFrame = '${slots[key]}';
                    resetInfo();
                    readyInfo = false;
                  }
                  break;
              }
            }
            //jezeli polecenie: "wstaw ramkę numer XX" - zapis oznaczenia "trójkątem" pod ramką
            if(frameState == AppLocalizations.of(context)!.insert){
              zapisZas = 14;
              zapisWart = AppLocalizations.of(context)!.insert + ' ' + AppLocalizations.of(context)!.frame;
              //zapis "trójkąta - wstaw ramka" do tabeli "ramka" 
              zapisDoBazy(zapisZas, zapisWart);
              frameState = AppLocalizations.of(context)!.open; //zmiana insert na open zeby następne komendy miały otwarte ramki              
            }
          
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;

//setChange - zmiana numeru ramki po przegladzie          
        case 'setChange':
          printText += AppLocalizations.of(context)!.changeFrame; //" frame";
          intention = 'setChange';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            // print('ZMIANA RAMEK');
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              //print('key ------ $key');
              switch (key) {
                case 'nrXXOfFrame':
                  nrXXOfFrame = int.parse('${slots[key]}');
                  if ((frameState == AppLocalizations.of(context)!.open ||
                          frameState == AppLocalizations.of(context)!.set) &&
                      (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true))) {
                    beep('open');
                    printText1 += " ${slots[key]}";
                    readyFrame = true;
                    readyFrames = false;
                    // nrXXOfFrameTemp = nrXXOfFrame;
                    // nrXXOfFramePo = nrXXOfFrame;
                    resetStory(); //kasowanie zmiennych przechowujących biezace zasoby ramki (bo nowa ramka)
                  } else {
                    if (readyApiary == true &&
                        readyHive == true &&
                        (readyBody == true || readyHalfBody == true)) {
                      printText1 += " ${slots[key]}";
                      // nrXXOfFrameTemp = nrXXOfFrame;
                      nrXXOfFrame = 0;
                      // nrXXOfFramePo = 0;
                      readyFrame = false;
                      resetStory();
                    }
                  }
                  break;
                case 'nrXXOfFramePo':
                  nrXXOfFramePo = int.parse('${slots[key]}');
                  if ((frameState == AppLocalizations.of(context)!.open ||
                          frameState == AppLocalizations.of(context)!.set) &&
                      (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true))) {
                    beep('open');
                    printText1 += " ${slots[key]}";
                    readyFrame = true;
                    readyFrames = false;
                    //??? nrXXOfFrameTemp = nrXXOfFrame;
                    resetStory(); //kasowanie zmiennych przechowujących biezace zasoby ramki (bo nowa ramka)
                  } else {
                    if (readyApiary == true &&
                        readyHive == true &&
                        (readyBody == true || readyHalfBody == true)) {
                      printText1 += " ${slots[key]}";
                      //??? nrXXOfFrameTemp = nrXXOfFrame;
                      nrXXOfFramePo = 0;
                      readyFrame = false;
                      resetStory();
                    }
                  }
                break;
              }
            };
            //ustalenie numeru korpusu dla pobrania wpisów do zmiany dla ramki po
            if (nrXOfBody != 0) {
                _korpusNr = nrXOfBody;
              } else {
                _korpusNr = nrXOfHalfBody;
              }
            //zmiana istniejących wpisów bo zmiana numeru ramki po przeglądzie
            Provider.of<Frames>(context, listen: false)
              .fetchAndSetFramesForHive(nrXXOfApiary, nrXXOfHive)
              .then((_) {  
                //dla wszystkich zasobów dla ramki z numerem "przed" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
                final framesData1 = Provider.of<Frames>(context, listen: false);
                  //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu)
                List<Frame> frames = framesData1.items.where((fr) {
                  return fr.ramkaNr == nrXXOfFrame && fr.data == formattedDate && fr.korpusNr == _korpusNr; //return fr.data.contains('2024-04-04');
                }).toList();
                  //dla kazdego zasobu modyfikacja ramkaNrPo
                for (var i = 0; i < frames.length; i++) {
                  //print(' id: ${frames[i].id}, ramkaPrzed: ${frames[i].ramkaNr}, ramkaPo: ${frames[i].ramkaNrPo}, zasób: ${frames[i].zasob}');
                  DBHelper.updateRamkaNrPo(frames[i].id, nrXXOfFramePo);
                }
              Provider.of<Frames>(context, listen: false)
                .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                .then((_) {
                //Navigator.of(context).pop();
              });
            });  
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setTempBody - przeniesienie ramki do innego korpusu
        case 'setMoveBody':
        //print('setMoveBody');
        printText += AppLocalizations.of(context)!.moveFrame; 
          intention = 'setMoveBody';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            // print('Przeniesienie RAMEK');
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              //print('key ------ $key');
              switch (key) {
                case 'nrTempHive':
                  nrTempHive = int.parse('${slots[key]}');
                  if ((frameState == AppLocalizations.of(context)!.open ||
                          frameState == AppLocalizations.of(context)!.set) &&
                      (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true))) {
                    beep('open');
                    printText1 += " ul ${slots[key]}";
                    readyFrame = true;
                    readyFrames = false;
                    // nrXXOfFrameTemp = nrXXOfFrame;
                    // nrXXOfFramePo = nrXXOfFrame;
                    //resetStory(); //kasowanie zmiennych przechowujących biezace zasoby ramki (bo nowa ramka)
                  } else {
                    if (readyApiary == true &&
                        readyHive == true &&
                        (readyBody == true || readyHalfBody == true)) {
                      printText1 += " ul ${slots[key]}";
                      // nrXXOfFrameTemp = nrXXOfFrame;
                      //nrXXOfFrame = 0;
                      // nrXXOfFramePo = 0;
                      readyFrame = false;
                      //resetStory();
                    }
                  }
                  break;
                case 'nrTempBody':
                  nrTempBody = int.parse('${slots[key]}');
                  if ((frameState == AppLocalizations.of(context)!.open ||
                          frameState == AppLocalizations.of(context)!.set) &&
                      (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true))) {
                    beep('open');
                    printText1 += " korpus ${slots[key]}";
                    readyFrame = true;
                    readyFrames = false;
                    // nrXXOfFrameTemp = nrXXOfFrame;
                    // nrXXOfFramePo = nrXXOfFrame;
                    //resetStory(); //kasowanie zmiennych przechowujących biezace zasoby ramki (bo nowa ramka)
                  } else {
                    if (readyApiary == true &&
                        readyHive == true &&
                        (readyBody == true || readyHalfBody == true)) {
                      printText1 += " korpus ${slots[key]}";
                      // nrXXOfFrameTemp = nrXXOfFrame;
                      //nrXXOfFrame = 0;
                      // nrXXOfFramePo = 0;
                      readyFrame = false;
                     // resetStory();
                    }
                  }
                  break;
                case 'nrTempHalfBody':
                //print('nrTempHalfBody');
                  nrTempHalfBody = int.parse('${slots[key]}');
                  nrTempBody = 0; //zeby usunać poprzedni numer półnadstawki przypisywany nizej (idź do KOM1)
                  if ((frameState == AppLocalizations.of(context)!.open ||
                          frameState == AppLocalizations.of(context)!.set) &&
                      (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true))) {
                    beep('open');
                    printText1 += " półkorpus ${slots[key]}";
                    readyFrame = true;
                    readyFrames = false;
                    // nrXXOfFrameTemp = nrXXOfFrame;
                    // nrXXOfFramePo = nrXXOfFrame;
                    //resetStory(); //kasowanie zmiennych przechowujących biezace zasoby ramki (bo nowa ramka)
                  } else {
                    if (readyApiary == true &&
                        readyHive == true &&
                        (readyBody == true || readyHalfBody == true)) {
                      printText1 += " polkorpus ${slots[key]}";
                      // nrXXOfFrameTemp = nrXXOfFrame;
                      //nrXXOfFrame = 0;
                      // nrXXOfFramePo = 0;
                      readyFrame = false;
                      //resetStory();
                    }
                  }
                  break;
                case 'nrTempFrame':
                //print('nrTempFrame');
                  nrTempFrame = int.parse('${slots[key]}');
                  if ((frameState == AppLocalizations.of(context)!.open ||
                          frameState == AppLocalizations.of(context)!.set) &&
                      (readyApiary == true &&
                          readyHive == true &&
                          (readyBody == true || readyHalfBody == true))) {
                    beep('open');
                    printText1 += " ramka ${slots[key]}";
                    readyFrame = true;
                    readyFrames = false;
                    //nrXXOfFrameTemp = nrXXOfFrame;
                    //nrXXOfFramePo = nrXXOfFrame;
                    resetStory(); //kasowanie zmiennych przechowujących biezace zasoby ramki (bo nowa ramka)
                  } else {
                    if (readyApiary == true &&
                        readyHive == true &&
                        (readyBody == true || readyHalfBody == true)) {
                      printText1 += " ramka ${slots[key]}";
                      //nrXXOfFrameTemp = nrXXOfFrame;
                      //nrXXOfFrame = 0;
                      //nrXXOfFramePo = 0;
                      readyFrame = false;
                      resetStory();
                    }
                  }
                  break;
              }; 
            }; 
              int typ;
              if(nrTempHive == 0) nrTempHive = nrXXOfHive; //przenoszenie w tym samym ulu
              if(nrTempBody != 0) { typ = 2;} 
              else {nrTempBody = nrTempHalfBody; typ = 1;}//(KOM1) przypisanie korpusowi numeru półkorpusa zeby nie tworzyć nowej zmiennej
              // print('nrTempBody = $nrTempBody');
              // print('typ = $typ');
              //ustalenie numeru korpusu dla pobrania wpisów do zmiany dla ramki po
              if (nrXOfBody != 0) {
                _korpusNr = nrXOfBody;
              } else {
                _korpusNr = nrXOfHalfBody;
              }
              //przeniesienie ramki do innego korpusu
              Provider.of<Frames>(context, listen: false)
                .fetchAndSetFramesForHive(nrXXOfApiary, nrXXOfHive)
                .then((_) {  
                  //dla wszystkich zasobów wykonanie kopii ramki i zmiana "przed", "po", korpusu i ewentualnie ula
                  final framesData1 = Provider.of<Frames>(context, listen: false);
                    //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu)
                  List<Frame> frames = framesData1.items.where((fr) {
                    return fr.ramkaNr == nrXXOfFrame && fr.data == formattedDate && fr.korpusNr == _korpusNr; //return fr.data.contains('2024-04-04');
                  }).toList();
                    print('frames.length = ${frames.length}');
                    //dla kazdego zasobu - zapis z innym id oraz modyfikacja ramkaNr, ramkaNrPo, korpusNr i ewentualnie ulNr
                  for (var i = 0; i < frames.length; i++) {
                    //print ('przeniesiona do ul = $nrTempHive, korpus = $nrTempBody, ramka = $nrTempFrame');
                    //DBHelper.moveRamkaToBody(frames[i].id, nrTempHave, nrTempBody, nrTempFrame);
                    //print('frames[i].zasob = ${frames[i].zasob}');
                    if(frames[i].zasob != 14){ //jezeli zasób jest rózny od "isDone" czyli prawdopodobnie nie jest = "usuń ramka"
                      Frames.insertFrame(
                        '$formattedDate.$nrXXOfApiary.$nrTempHive.$nrTempBody.0.$nrTempFrame.${frames[i].strona}.${frames[i].zasob}',
                        formattedDate,
                        nrXXOfApiary,
                        nrTempHive,
                        nrTempBody,
                        typ,//2-korpus, 1-półkorpus
                        0,//ramkaNr przed (0 bo jest wstawiana)
                        nrTempFrame, //ramkaNrPo 
                        frames[i].rozmiar,
                        frames[i].strona,
                        frames[i].zasob,
                        frames[i].wartosc,
                        0);
                        
                        //ramkaPo zmienić na 0 bo zostaje usunieta z obecnego miejsca
                        DBHelper.updateRamkaNrPo(frames[i].id, 0);
                    }
                    else{ //więc jezeli jest "usuń ramka" to zamień na "wstaw ramka"
                      Frames.insertFrame(
                          '$formattedDate.$nrXXOfApiary.$nrTempHive.$nrTempBody.0.$nrTempFrame.${frames[i].strona}.${frames[i].zasob}',
                          formattedDate,
                          nrXXOfApiary,
                          nrTempHive,
                          nrTempBody,
                          typ,//2-korpus, 1-półkorpus
                          0,//ramkaNr
                          nrTempFrame, //ramkaNrPo 
                          frames[i].rozmiar,
                          frames[i].strona,
                          frames[i].zasob,
                          AppLocalizations.of(context)!.inserted, //wstaw ramka
                          0);
                          
                          //ramkaPo zmienić na 0 bo zostaje usunieta z obecnego miejsca 
                          DBHelper.updateRamkaNrPo(frames[i].id, 0);
                    }
                  }
                Provider.of<Frames>(context, listen: false)
                  .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                  .then((_) {
                  //Navigator.of(context).pop();
                });
              }); 
            } else {
                //jezeli nie zdekodowano slotu czyli parametrów intencji
                printText = AppLocalizations.of(context)!.error;
                beep('error');
              }
              printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
                  ? {
                      printText = AppLocalizations.of(context)!.wrongCommand,
                      beep('error'),
                    }
                  : printText += printText1;
              break;
//setHive - ustawienie numeru ula        
        case 'setHive':
          printText += AppLocalizations.of(context)!.hive; //" Hive"
          intention = 'setHive';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              //print('key ------ $key');
              switch (key) { 
                case 'hiveState':
                  hiveState = '${slots[key]}';
                  if (hiveState == AppLocalizations.of(context)!.close) {
                    beep('close');
                    printText1 += " ${slots[key]}";
                    readyHive = false;
                    nrXXOfHive = 0;
                    nrXXOfHiveTemp = 0;
                    bodyState = AppLocalizations.of(context)!.close;
                    readyBody = false;
                    readyInfo = false;
                    globals.ikonaUla = 'green'; //"zerowanie" ikony ula
                    resetSumowania();
                    resetBody();
                    resetStory();
                  } else {
                    if (readyApiary == true ||
                        (readyApiary == false && nrXXOfApiary == 0)) {
                      //otwieranie Hive jezeli otwarto Apiary lub jest tylko jedna (lub pierwsza) pasieka
                      printText1 += " ${slots[key]}";
                      nrXXOfHive =
                          nrXXOfHiveTemp; //bo inna kolejnośc wartości w slocie (patrz wydruk)- zmienić kolejność case???
                      nrXXOfHiveTemp = 0;
                      readyHive = true;
                      readyAllHives = false;
                      globals.ikonaUla = 'green'; //"zerowanie" ikony ula
                      allHivesState = AppLocalizations.of(context)!.close;
                      beep('open');
                      if (readyApiary == false && nrXXOfApiary == 0) {
                        readyApiary = true;
                        nrXXOfApiary = 1;
                      } //bo tylko jedna (lub pierwsza) pasieka
                      if (nrXXOfApiary != 0) {
                        //wpis do tabeli 'pogoda'
                        aktualizacjaPogody(nrXXOfApiary);
                      }
                    }
                  }
                  break;
                case 'nrXXOfHive':
                  nrXXOfHive = int.parse('${slots[key]}'); 
                  if(nrXXOfHiveH > 0){ //jezeli były setki
                    nrXXOfHive = nrXXOfHive + nrXXOfHiveH; //dodaj do dziesiatek
                    nrXXOfHiveH = 0;//zerój setki zeby sie znów nie dodawały
                  }
                  if ((hiveState == AppLocalizations.of(context)!.open ||
                          hiveState == AppLocalizations.of(context)!.set) &&
                      (readyApiary == true ||
                          (readyApiary == false && nrXXOfApiary == 0))) {
                    //numer Hive jezeli otwarto Apiary
                    
                    printText1 += " " + nrXXOfHive.toString();
                    if (readyApiary == false && nrXXOfApiary == 0) {
                      readyApiary = true;
                      nrXXOfApiary = 1;
                    }
                    readyHive = true;
                    readyAllHives = false;
                    allHivesState = AppLocalizations.of(context)!.close;
                    beep('open');
                    nrXXOfHiveTemp = nrXXOfHive;
                    bodyState = AppLocalizations.of(context)!.close;
                    readyBody = false;
                    readyInfo = false;
                    globals.ikonaUla = 'green'; //"zerowanie" ikony ula
                    resetSumowania();
                    resetBody();
                    resetStory();
                  } else {
                    printText1 += " " + nrXXOfHive.toString();
                    nrXXOfHiveTemp = nrXXOfHive;
                    nrXXOfHive = 0;
                    bodyState = AppLocalizations.of(context)!.close;
                    readyHive = false;
                    readyBody = false;
                    readyInfo = false;
                    resetSumowania();
                    resetBody();
                    resetStory();
                  }
                  break;

                case 'nrXXOfHiveH':             
                    if (globals.jezyk == "pl_PL") {
                      switch (slots[key]) {
                        case 'sto':
                          nrXXOfHiveH = 100;
                          break;
                        case 'dwieście':
                          nrXXOfHiveH = 200;
                          break;
                        case 'trzysta':
                          nrXXOfHiveH = 300;
                          break;
                        case 'czterysta':
                          nrXXOfHiveH = 400;
                          break;
                        case 'pięćset':
                          nrXXOfHiveH = 500;
                          break;
                        case 'sześćset':
                          nrXXOfHiveH = 600;
                          break;
                        case 'siedemset':
                          nrXXOfHiveH = 700;
                          break;
                        case 'osiemset':
                          nrXXOfHiveH = 800;
                          break;
                        case 'dziewięćset':
                          nrXXOfHiveH = 900;
                          break;
                        default:
                          nrXXOfHiveH = 0;
                      }
                    } else {
                      switch (slots[key]) {
                        case 'one hundred':
                          nrXXOfHiveH = 100;
                          break;
                        case 'two hundred':
                          nrXXOfHiveH = 200;
                          break;
                        case 'three hundred':
                          nrXXOfHiveH = 300;
                          break;
                        case 'four hundred':
                          nrXXOfHiveH = 400;
                          break;
                        case 'five hundred':
                          nrXXOfHiveH = 500;
                          break;
                        case 'six hundred':
                          nrXXOfHiveH = 600;
                          break;
                        case 'seven hundred':
                          nrXXOfHiveH = 700;
                          break;
                        case 'eight hundred':
                          nrXXOfHiveH = 800;
                          break;
                        case 'nine hundred':
                          nrXXOfHiveH = 900;
                          break;
                        default:
                          nrXXOfHiveH = 0;
                      }
                    }
                    //jezeli są tylko setki to wykonanie czynności takich jak przy dziesiątkach
                    if (slots.length == 2){
                      nrXXOfHive = nrXXOfHiveH; 
                      nrXXOfHiveH = 0;//zerój setki zeby sie znów nie dodawały
                      
                      if ((hiveState == AppLocalizations.of(context)!.open ||
                              hiveState == AppLocalizations.of(context)!.set) &&
                          (readyApiary == true ||
                              (readyApiary == false && nrXXOfApiary == 0))) {
                        //numer Hive jezeli otwarto Apiary                   
                        printText1 += " " + nrXXOfHive.toString();
                        if (readyApiary == false && nrXXOfApiary == 0) {
                          readyApiary = true;
                          nrXXOfApiary = 1;
                        }
                        readyHive = true;
                        readyAllHives = false;
                        allHivesState = AppLocalizations.of(context)!.close;
                        beep('open');
                        nrXXOfHiveTemp = nrXXOfHive;
                        bodyState = AppLocalizations.of(context)!.close;
                        readyBody = false;
                        readyInfo = false;
                        globals.ikonaUla = 'green'; //"zerowanie" ikony ula
                        resetSumowania();
                        resetBody();
                        resetStory();
                      } else {
                        printText1 += " " + nrXXOfHive.toString();
                        nrXXOfHiveTemp = nrXXOfHive;
                        nrXXOfHive = 0;
                        bodyState = AppLocalizations.of(context)!.close;
                        readyHive = false;
                        readyBody = false;
                        readyInfo = false;
                        resetSumowania();
                        resetBody();
                        resetStory();
                      }
                    }                 
                    // nrXXOfHive = nrXXOfHiveH + nrXXOfHive; //dodanie setek do numeru ula
                    // nrXXOfHiveH = 0; //zerowanie setek zeby się znowu nie dodało
                        
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setBody - ustawienie numeru korpusa
        case 'setBody':
          printText += AppLocalizations.of(context)!.body; //" Body";
          //intention = 'setBody';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              //print('key ------ $key');
              switch (key) { 
                case 'bodyState':
                  bodyState = '${slots[key]}';
                  if (bodyState == AppLocalizations.of(context)!.close) {
                    printText1 += " ${slots[key]}";
                    readyBody = false;
                    beep('close');
                    halfBodyState = AppLocalizations.of(context)!.close;
                    readyFrame = false;
                    nrXOfBodyTemp = 0;
                    resetSumowania();
                    resetBody();
                    resetStory();
                  } else {
                    if (readyApiary == true && readyHive == true) {
                      //otwieranie Body jezeli otwarto Apiary i Hive
                      printText1 += " ${slots[key]}";
                      if (nrXOfBodyTemp != 0) {
                        nrXOfBody = nrXOfBodyTemp;
                        sizeOfFrame = AppLocalizations.of(context)!.big;
                      }
                      // if (nrXOfHalfBodyTemp != 0) {
                      //   nrXOfHalfBody = nrXOfHalfBodyTemp;
                      //   sizeOfFrame = 'small';
                      // }
                      readyAllHives = false;
                      allHivesState = AppLocalizations.of(context)!.close;
                      halfBodyState = AppLocalizations.of(context)!.close;
                      readyHalfBody = false;
                      nrXOfBodyTemp = 0;
                      nrXOfHalfBodyTemp = 0;
                      readyBody = true;
                      beep('open');
                      resetSumowania();
                      resetFrame();
                      resetStory();
                    }
                  }
                  break;
                case 'nrXOfBody':
                  nrXOfBody = int.parse('${slots[key]}');
                  if ((bodyState == AppLocalizations.of(context)!.open ||
                          bodyState == AppLocalizations.of(context)!.set) &&
                      (readyApiary == true && readyHive == true)) {
                    printText1 += " ${slots[key]}";
                    readyBody = true;
                    beep('open');
                    nrXOfBodyTemp = nrXOfBody;
                    nrXOfHalfBody = 0;
                    nrXOfHalfBodyTemp = 0;
                    readyHalfBody = false;
                    readyAllHives = false;
                    allHivesState = AppLocalizations.of(context)!.close;
                    sizeOfFrame = AppLocalizations.of(context)!.big; //bo korpus
                    resetSumowania();
                    resetFrame();
                    resetStory();
                  } else {
                    printText1 += " ${slots[key]}";
                    nrXOfBodyTemp = nrXOfBody;
                    nrXOfBody = 0;
                    nrXOfHalfBody = 0;
                    readyBody = false;
                    //beep('close');
                    resetSumowania();
                    resetFrame();
                    resetStory();
                  }
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setHalfBody - ustawienie numeru półkorpusa        
        case 'setHalfBody':
          printText += AppLocalizations.of(context)!.halfBody; //" Half body";
          //intention = 'setHalfBody';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) { 
                case 'halfBodyState':
                  halfBodyState = '${slots[key]}';
                  if (halfBodyState == AppLocalizations.of(context)!.close) {
                    printText1 += " ${slots[key]}";
                    readyHalfBody = false;
                    beep('close');
                    nrXOfHalfBodyTemp = 0;
                    resetSumowania();
                    resetBody();
                    resetFrame();
                    resetStory();
                  } else {
                    if (readyApiary == true && readyHive == true) {
                      //otwieranie Body jezeli otwarto Apiary i Hive
                      printText1 += " ${slots[key]}";
                      if (nrXOfHalfBodyTemp != 0) {
                        nrXOfHalfBody = nrXOfHalfBodyTemp;
                        sizeOfFrame = AppLocalizations.of(context)!.small;
                      }
                      readyAllHives = false;
                      allHivesState = AppLocalizations.of(context)!.close;
                      nrXOfHalfBodyTemp = 0;
                      readyHalfBody = true;
                      readyBody = false;
                      bodyState = AppLocalizations.of(context)!.close;
                      nrXOfBody = 0;
                      beep('open');
                      resetSumowania();
                      resetFrame();
                      resetStory();
                    }
                  }
                  break;
                case 'nrXOfHalfBody':
                  nrXOfHalfBody = int.parse('${slots[key]}');
                  if ((halfBodyState == AppLocalizations.of(context)!.open ||
                          halfBodyState == AppLocalizations.of(context)!.set) &&
                      (readyApiary == true && readyHive == true)) {
                    printText1 += " ${slots[key]}";
                    readyHalfBody = true;
                    readyBody = false;
                    bodyState = AppLocalizations.of(context)!.close;
                    nrXOfBody = 0;
                    beep('open');
                    //nrXOfHalfBodyTemp = nrXOfHalfBody;
                    //nrXOfHalfBody = 0;
                    nrXOfHalfBodyTemp = 0;
                    sizeOfFrame =
                        AppLocalizations.of(context)!.small; //bo półkorpus
                    readyAllHives = false;
                    allHivesState = AppLocalizations.of(context)!.close;
                    resetSumowania();
                    resetFrame();
                    resetStory();
                  } else {
                    printText1 += " ${slots[key]}";
                    nrXOfHalfBodyTemp = nrXOfHalfBody;
                    nrXOfHalfBody = 0;
                    readyBody = false;
                    nrXOfBody = 0;
                    resetSumowania();
                    resetFrame();
                    resetStory();
                  }
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setQueen - ustawiania parametrów matki w info        
        case 'setQueen':
          printText += AppLocalizations.of(context)!.queen; //" Queen:";
          //intention = 'setQueen';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) { 
                case 'queenState': //
                  if (readyApiary == true && readyHive == true) {
                    printText1 += "\n" + AppLocalizations.of(context)!.queen + " =";
                    printText1 += "  ${slots[key]}";
                    zapis =
                        AppLocalizations.of(context)!.queen + " - ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'queen',
                        AppLocalizations.of(context)!.queen + " -",
                        '${slots[key]}',
                        ''); //
                  }
                  break;
                case 'queenStart': //
                  if (readyApiary == true && readyHive == true) {
                    printText1 += "\n" + AppLocalizations.of(context)!.queen + " =";
                    printText1 += "  ${slots[key]}";
                    zapis =
                        AppLocalizations.of(context)!.queenIs + " ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy('queen', AppLocalizations.of(context)!.queenIs,
                        '${slots[key]}', ''); //
                  }
                  break;
                case 'queenMark': //
                  if (readyApiary == true && readyHive == true) {
                    printText1 += "\n" + AppLocalizations.of(context)!.queen + " =";
                    printText1 += "  ${slots[key]}";
                    queenMark = '${slots[key]}';
                    if (slots.length == 2) { queenAlpha1 = '';queenAlpha2 = '';}
                    else queenNumber = ''; //bo pamięta poprzednie ustawienia numeru
                    zapis = AppLocalizations.of(context)!.queen +
                        " $queenMark " +
                        " $queenNumber$queenAlpha1$queenAlpha2";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'queen',
                        ' ' + AppLocalizations.of(context)!.queen,
                        '${slots[key]}',
                        '$queenNumber$queenAlpha1$queenAlpha2'); //
                  }
                  break;
                case 'queenNumber': //
                  if (readyApiary == true && readyHive == true) {
                    printText1 += "\n" + AppLocalizations.of(context)!.queen + " =";
                    printText1 += "  ${slots[key]}";
                    queenNumber = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.queen + 
                        " $queenMark " +
                        " ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'queen',
                        " " + AppLocalizations.of(context)!.queen,
                        '$queenMark',
                        '${slots[key]}'); //numer matki tu bo potrzebne do info zamiast belki
                  }
                  break;
                case 'queenAlpha1': //
                  if (readyApiary == true && readyHive == true) {
                    printText1 += "\n" + AppLocalizations.of(context)!.queen + " =";
                    printText1 += "  ${slots[key]}";
                    queenAlpha1 = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.queen + 
                        " $queenMark " +
                        " $queenAlpha1$queenAlpha2";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'queen',
                        " " + AppLocalizations.of(context)!.queen,
                        '$queenMark',
                        '$queenAlpha1$queenAlpha2'); //numer matki tu bo potrzebne do info zamiast belki
                  }
                  break;
                   case 'queenAlpha2': //
                    if (readyApiary == true && readyHive == true) {
                      printText1 += "\n" + AppLocalizations.of(context)!.queen + " =";
                      printText1 += "  ${slots[key]}";
                      queenAlpha2 = '${slots[key]}';
                      zapis = AppLocalizations.of(context)!.queen +
                        " $queenMark " +
                         " $queenAlpha1$queenAlpha2";
                      readyInfo = true;
                      zapisInfoDoBazy(
                        'queen',
                        " " + AppLocalizations.of(context)!.queen,
                        '$queenMark',
                        '$queenAlpha1$queenAlpha2'); //numer matki tu bo potrzebne do info zamiast belki
                  }
                  break;
                case 'queenQuality': //
                  if (readyApiary == true && readyHive == true) {
                    printText1 += "\n" + AppLocalizations.of(context)!.queen + " =";
                    printText1 += "  ${slots[key]}";
                    zapis =
                        AppLocalizations.of(context)!.queenIs + " ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'queen',
                        AppLocalizations.of(context)!.queen +
                            '  ' +
                            AppLocalizations.of(context)!.isIs,
                        '${slots[key]}',
                        ''); //
                  }
                  break;
                case 'queenBorn': //
                  if (readyApiary == true && readyHive == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.queenWasBornIn20;
                    printText1 += "${slots[key]}";
                    zapis = AppLocalizations.of(context)!.queenWasBornIn20 +
                        "${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'queen',
                        AppLocalizations.of(context)!.queenWasBornIn,
                        '20${slots[key]}',
                        ''); //
                  }
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setEquipment - ustawienia parametrów wyposarzenia w info        
        case 'setEquipment':
          printText += AppLocalizations.of(context)!.equipment; //" Equipment:";
          //intention = 'setEquipment';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) { 
                case 'numberOfFrame':
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.numberOfFrame + " =";
                    printText1 += " ${slots[key]}";
                    _nowaIloscRamek  = int.parse('${slots[key]}');
                    zapis = AppLocalizations.of(context)!.numberOfFrame +
                        " = ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'equipment',
                        AppLocalizations.of(context)!.numberOfFrame + " = ",
                        '${slots[key]}',
                        ''); //
                  }
                  break;
                case 'excluder': //krata odgrodowa
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.excluder + " = ";
                    printText1 += AppLocalizations.of(context)!.on +
                        " ${slots[key]} " +
                        AppLocalizations.of(context)!.body;
                    zapis = AppLocalizations.of(context)!.excluder +
                        " " +
                        AppLocalizations.of(context)!.on +
                        " ${slots[key]} " +
                        AppLocalizations.of(context)!.body;
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'equipment',
                        AppLocalizations.of(context)!.excluder,
                        AppLocalizations.of(context)!.onBodyNumber,
                        '${slots[key]}'); //
                  }
                  break;
                case 'excluderDel': //krata odgrodowa
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.excluder + " =";
                    printText1 += " ${slots[key]}";
                    zapis =
                        AppLocalizations.of(context)!.excluder + " ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'equipment',
                        " " + AppLocalizations.of(context)!.excluder + " -",
                        '', //${slots[key]} //nic zeby lepiej wyglądało. Bo wyświetla się '0'
                        '0'); //remove
                  }
                  break;
                case 'bottomBoard': //dennica
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.bottomBoard + " =";
                    printText1 += " ${slots[key]}";
                    zapis = AppLocalizations.of(context)!.bottomBoard +
                        " " +
                        AppLocalizations.of(context)!.isIs +
                        " ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'equipment',
                        AppLocalizations.of(context)!.bottomBoard +  " " + AppLocalizations.of(context)!.isIs,
                        '${slots[key]}',
                        '');
                  }
                  break;
                case 'beePolenTrap': //poławiacz pyłku
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.beePollenTrap + " =";
                    printText1 += " ${slots[key]}";
                    zapis = AppLocalizations.of(context)!.beePollenTrap +
                        " " +
                        AppLocalizations.of(context)!.isIs +
                        " ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'equipment',
                        AppLocalizations.of(context)!.beePollenTrap + " " + AppLocalizations.of(context)!.isIs,
                        '${slots[key]}',
                        '');
                  }
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setFeeding - ustawienie parametrów dokarmiania w info
        case 'setFeeding':
          printText += AppLocalizations.of(context)!.feeding; //" Feeding:";
          //intention = 'feeding';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) { 
                case 'syrup1to1I': //syrop 1 do 1 część całkowita w litrach
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.syrup + " 1:1 =";
                    printText1 += "  ${slots[key]} l";
                    syrup1to1I = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.syrup +
                        " 1:1 = $syrup1to1I" +
                        AppLocalizations.of(context)!.kropka +
                        "$syrup1to1D l";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'feeding',
                        AppLocalizations.of(context)!.syrup + " 1:1",
                        "$syrup1to1I" + '.' + "$syrup1to1D",
                        "l"); //
                  }
                  break;
                case 'syrup1to1D': //syrop 1 do 1 część dziesiętna
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.syrup + " 1:1 =";
                    printText1 += "  0.${slots[key]} l";
                    syrup1to1D = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.syrup +
                        " 1:1 = $syrup1to1I" +
                        AppLocalizations.of(context)!.kropka +
                        "$syrup1to1D l";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'feeding',
                        AppLocalizations.of(context)!.syrup + " 1:1",
                        "$syrup1to1I" + '.' + "$syrup1to1D",
                        "l"); //
                  }
                  break;
                case 'syrup3to2I': //syrop 3 do 2 część całkowita w litrach
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.syrup + " 3:2 =";
                    printText1 += "  ${slots[key]} l";
                    syrup3to2I = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.syrup +
                        " 3:2 = $syrup3to2I" +
                        AppLocalizations.of(context)!.kropka +
                        "$syrup3to2D l";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'feeding',
                        AppLocalizations.of(context)!.syrup + " 3:2",
                        "$syrup3to2I" + '.' + "$syrup3to2D",
                        "l"); //
                  }
                  break;
                case 'syrup3to2D': //syrop 3 do 2 część dziesiętna
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.syrup + " 3:2 =";
                    printText1 += "  0.${slots[key]} l";
                    syrup3to2D = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.syrup +
                        " 3:2 = $syrup3to2I" +
                        AppLocalizations.of(context)!.kropka +
                        "$syrup3to2D l";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'feeding',
                        AppLocalizations.of(context)!.syrup + " 3:2",
                        "$syrup3to2I" + '.' + "$syrup3to2D",
                        "l"); //
                  }
                  break;
                case 'candyI': //candy część całkowita w litrach
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 += "\n" + AppLocalizations.of(context)!.candy + " =";
                    printText1 += "  ${slots[key]} kg";
                    candyI = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.candy +
                        " = $candyI" +
                        AppLocalizations.of(context)!.kropka +
                        "$candyD kg";
                    readyInfo = true;
                    zapisInfoDoBazy('feeding', AppLocalizations.of(context)!.candy,
                        "$candyI" + '.' + "$candyD", "kg"); //
                  }
                  break;
                case 'candyD': //candy część dziesiętna
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 += "\n" + AppLocalizations.of(context)!.candy + " =";
                    printText1 += "  ${slots[key]} kg";
                    candyD = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.candy +
                        " = $candyI" +
                        AppLocalizations.of(context)!.kropka +
                        "$candyD kg";
                    readyInfo = true;
                    zapisInfoDoBazy('feeding', AppLocalizations.of(context)!.candy,
                        "$candyI" + '.' + "$candyD", "kg"); //
                  }
                  break;
                case 'invertI': //invert część całkowita w litrach
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.invert + " =";
                    printText1 += "  ${slots[key]}";
                    invertI = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.invert +
                        " = $invertI" +
                        AppLocalizations.of(context)!.kropka +
                        "$invertD l";
                    readyInfo = true;
                    zapisInfoDoBazy('feeding', AppLocalizations.of(context)!.invert,
                        "$invertI" + '.' + "$invertD", "l"); //
                  }
                  break;
                case 'invertD': //invert część dziesiętna
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.invert + " =";
                    printText1 += "  ${slots[key]}";
                    invertD = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.invert +
                        " = $invertI" +
                        AppLocalizations.of(context)!.kropka +
                        "$invertD l";
                    readyInfo = true;
                    zapisInfoDoBazy('feeding', AppLocalizations.of(context)!.invert,
                        "$invertI" + '.' + "$invertD", "l"); //
                  }
                  break;
                case 'removedFood': //usunięto pokarm
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.removedFood + " =";
                    printText1 += "  ${slots[key]}";
                    removedFood = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.removedFood +
                        " = ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'feeding',
                        AppLocalizations.of(context)!.removedFood,
                        removedFood,
                        ''); //
                  }
                  break;
                case 'leftFood': //pozostał (niezjedzony) pokarm
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.leftFood + " =";
                    printText1 += "  ${slots[key]}";
                    leftFood = '${slots[key]}';
                    zapis =
                        AppLocalizations.of(context)!.leftFood + " = ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy('feeding',
                        AppLocalizations.of(context)!.leftFood, leftFood, ''); //
                  }
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setTreatment - ustawienie parametrów leczenia w info
        case 'setTreatment':
          printText += AppLocalizations.of(context)!.treatment; //" Treatment:";
         // intention = 'treatment';
         if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) { 
                case 'apivarol': //
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 += "\n Apiwarol =";
                    printText1 +=
                        "  ${slots[key]} " + AppLocalizations.of(context)!.dose;
                    zapis = 'Apiwarol = ${slots[key]} ' +
                        AppLocalizations.of(context)!.dose;
                    readyInfo = true;
                    zapisInfoDoBazy('treatment', 'apivarol', '${slots[key]}',
                        AppLocalizations.of(context)!.dose); //
                  }
                  break;
                case 'biovar': //
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 += "\n Biowar =";
                    printText1 += "  ${slots[key]} " +
                        '$biovarBelts ' +
                        AppLocalizations.of(context)!.belts;
                    biovarState = '${slots[key]}';
                    zapis = 'Biowar = ${slots[key]} ' +
                        '$biovarBelts ' +
                        AppLocalizations.of(context)!.belts;
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'treatment',
                        'biovar',
                        '${slots[key]}' + ' $biovarBelts',
                        AppLocalizations.of(context)!.belts); //
                  }
                  break;
                case 'biovarBelts': //
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    printText1 += "\n Biowar =";
                    printText1 += '$biovarState ' +
                        "${slots[key]} " +
                        AppLocalizations.of(context)!.belts;
                    biovarBelts = '${slots[key]}';
                    zapis = 'Biowar = ' +
                        '$biovarState ' +
                        ' ${slots[key]} ' +
                        AppLocalizations.of(context)!.belts;
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'treatment',
                        'biovar',
                        '$biovarState' + ' ${slots[key]}',
                        AppLocalizations.of(context)!.belts); //
                  }
                  break;
                case 'acid': //
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    acidXX = '${slots[key]}';
                    if (slots.length == 1)
                      acidH = ''; //zerowanie setek bo sa tylko dwie cyfry
                    printText1 += '\n' + AppLocalizations.of(context)!.acid + ' =';
                    printText1 += " $acidH$acidXX " +
                        AppLocalizations.of(context)!.milliliter;
                    zapis = AppLocalizations.of(context)!.acid +
                        ' = $acidH$acidXX ' +
                        AppLocalizations.of(context)!.milliliter;
                    readyInfo = true;
                    zapisInfoDoBazy('treatment', AppLocalizations.of(context)!.acid,
                        '$acidH$acidXX', 'ml'); //
                  }
                  break;
                case 'acidH':
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    if (globals.jezyk == "pl_PL") {
                      switch (slots[key]) {
                        case 'sto':
                          acidH = '1';
                          break;
                        case 'dwieście':
                          acidH = '2';
                          break;
                        case 'trzysta':
                          acidH = '3';
                          break;
                        case 'czterysta':
                          acidH = '4';
                          break;
                        case 'pięćset':
                          acidH = '5';
                          break;
                        case 'sześćset':
                          acidH = '6';
                          break;
                        case 'siedemset':
                          acidH = '7';
                          break;
                        case 'osiemset':
                          acidH = '8';
                          break;
                        case 'dziewięćset':
                          acidH = '9';
                          break;
                        default:
                          acidH = '9';
                      }
                    } else {
                      switch (slots[key]) {
                        case 'one hundred':
                          acidH = '1';
                          break;
                        case 'two hundred':
                          acidH = '2';
                          break;
                        case 'three hundred':
                          acidH = '3';
                          break;
                        case 'four hundred':
                          acidH = '4';
                          break;
                        case 'five hundred':
                          acidH = '5';
                          break;
                        case 'six hundred':
                          acidH = '6';
                          break;
                        case 'seven hundred':
                          acidH = '7';
                          break;
                        case 'eight hundred':
                          acidH = '8';
                          break;
                        case 'nine hundred':
                          acidH = '9';
                          break;
                        default:
                          acidH = '9';
                      }
                    }
                    if (slots.length == 1)
                      acidXX = '00'; //dwa zera bo jest tylko cyfra setek
                    printText1 += "\n" + AppLocalizations.of(context)!.acid + " =";
                    printText1 += " $acidH" +
                        '$acidXX ' +
                        AppLocalizations.of(context)!.milliliter;
                    zapis = AppLocalizations.of(context)!.acid +
                        " = $acidH" +
                        '$acidXX ' +
                        AppLocalizations.of(context)!.milliliter;
                    readyInfo = true;
                    zapisInfoDoBazy('treatment', AppLocalizations.of(context)!.acid,
                        '$acidH$acidXX', 'ml'); //
                  }
                  break;
                case 'varroa': //
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    varroaXX = '${slots[key]}';
                    if (slots.length == 1)
                      varroaH = ''; //zerowanie setek bo sa tylko dwie cyfry
                    printText1 +=
                        '\n' + AppLocalizations.of(context)!.vArroa + ' =';
                    printText1 +=
                        " $varroaH$varroaXX " + AppLocalizations.of(context)!.mites;
                    zapis = AppLocalizations.of(context)!.vArroa +
                        ' = $varroaH$varroaXX ' +
                        AppLocalizations.of(context)!.mites;
                    readyInfo = true;
                    zapisInfoDoBazy('treatment', 'varroa', '$varroaH$varroaXX',
                        AppLocalizations.of(context)!.mites); //
                  }
                  break;
                case 'varroaH':
                  if (readyApiary == true &&
                      (readyHive == true || readyAllHives == true)) {
                    if (globals.jezyk == "pl_PL") {
                      switch (slots[key]) {
                        case 'sto':
                          varroaH = '1';
                          break;
                        case 'dwieście':
                          varroaH = '2';
                          break;
                        case 'trzysta':
                          varroaH = '3';
                          break;
                        case 'czterysta':
                          varroaH = '4';
                          break;
                        default:
                          varroaH = '5';
                      }
                    } else {
                      switch (slots[key]) {
                        case 'one hundred':
                          varroaH = '1';
                          break;
                        case 'two hundred':
                          varroaH = '2';
                          break;
                        case 'three hundred':
                          varroaH = '3';
                          break;
                        case 'four hundred':
                          varroaH = '4';
                          break;
                        default:
                          varroaH = '5';
                      }
                    }
                    if (slots.length == 1)
                      varroaXX = '00'; //dwa zera bo jest tylko cyfra setek
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.vArroa + " =";
                    printText1 += " $varroaH" +
                        '$varroaXX ' +
                        AppLocalizations.of(context)!.mites;
                    zapis = AppLocalizations.of(context)!.vArroa +
                        " = $varroaH" +
                        '$varroaXX ' +
                        AppLocalizations.of(context)!.mites;
                    readyInfo = true;
                    zapisInfoDoBazy('treatment', 'varroa', '$varroaH$varroaXX',
                        AppLocalizations.of(context)!.mites); //
                  }
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setColony - ustawianie parametrów rodziny w info
        case 'setColony':
          printText += AppLocalizations.of(context)!.setColony; //" Colony:";
          //intention = 'setColony';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) { 
                case 'colonyForce': //
                  if (readyApiary == true && readyHive == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.colony + " =";
                    printText1 += " ${slots[key]}";
                    zapis = AppLocalizations.of(context)!.colony +
                        " " +
                        AppLocalizations.of(context)!.isIs +
                        " ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'colony',
                        " " +
                            AppLocalizations.of(context)!.colony +
                            " " +
                            AppLocalizations.of(context)!.isIs,
                        '${slots[key]}',
                        '');
                  }
                  break;
                case 'colonyState': //
                  if (readyApiary == true && readyHive == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.colony + " =";
                    printText1 += " ${slots[key]}";
                    zapis = AppLocalizations.of(context)!.colony +
                        " " +
                        AppLocalizations.of(context)!.isIs +
                        " ${slots[key]}";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'colony',
                        AppLocalizations.of(context)!.colony +
                            " " +
                            AppLocalizations.of(context)!.isIs,
                        '${slots[key]}',
                        '');
                  }
                  break;
                case 'deadBeeML': //
                  if (readyApiary == true && readyHive == true) {
                    deadBeeML = '${slots[key]}';
                    if (slots.length == 1)
                      deadBeeHML = ''; //zerowanie setek bo sa tylko dwie cyfry
                    printText1 +=
                        '\n' + AppLocalizations.of(context)!.deadBees + ' =';
                    printText1 += " $deadBeeHML$deadBeeML " +
                        AppLocalizations.of(context)!.milliliter;
                    zapis = AppLocalizations.of(context)!.deadBees +
                        ' = $deadBeeHML$deadBeeML ' +
                        AppLocalizations.of(context)!.milliliter;
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'colony',
                        AppLocalizations.of(context)!.deadBees,
                        '$deadBeeHML$deadBeeML',
                        'ml'); //
                  }
                  break;
                case 'deadBeeHML':
                  if (readyApiary == true && readyHive == true) {
                    if (globals.jezyk == "pl_PL") {
                      switch (slots[key]) {
                        case 'sto':
                          deadBeeHML = '1';
                          break;
                        case 'dwieście':
                          deadBeeHML = '2';
                          break;
                        case 'trzysta':
                          deadBeeHML = '3';
                          break;
                        case 'czterysta':
                          deadBeeHML = '4';
                          break;
                        case 'pięćset':
                          deadBeeHML = '5';
                          break;
                        case 'sześćset':
                          deadBeeHML = '6';
                          break;
                        case 'siedemset':
                          deadBeeHML = '7';
                          break;
                        case 'osiemset':
                          deadBeeHML = '8';
                          break;
                        case 'dziewięćset':
                          deadBeeHML = '9';
                          break;
                        default:
                          deadBeeHML = '9';
                      }
                    } else {
                      switch (slots[key]) {
                        case 'one hundred':
                          deadBeeHML = '1';
                          break;
                        case 'two hundred':
                          deadBeeHML = '2';
                          break;
                        case 'three hundred':
                          deadBeeHML = '3';
                          break;
                        case 'four hundred':
                          deadBeeHML = '4';
                          break;
                        case 'five hundred':
                          deadBeeHML = '5';
                          break;
                        case 'six hundred':
                          deadBeeHML = '6';
                          break;
                        case 'seven hundred':
                          deadBeeHML = '7';
                          break;
                        case 'eight hundred':
                          deadBeeHML = '8';
                          break;
                        case 'nine hundred':
                          deadBeeHML = '9';
                          break;
                        default:
                          deadBeeHML = '9';
                      }
                    }
                    if (slots.length == 1)
                      deadBeeML = '00'; //dwa zera bo jest tylko cyfra setek
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.deadBees + " =";
                    printText1 += " $deadBeeHML" +
                        '$deadBeeML ' +
                        AppLocalizations.of(context)!.milliliter;
                    zapis = AppLocalizations.of(context)!.deadBees +
                        " = $deadBeeHML" +
                        '$deadBeeML ' +
                        AppLocalizations.of(context)!.milliliter;
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'colony',
                        AppLocalizations.of(context)!.deadBees,
                        '$deadBeeHML$deadBeeML',
                        'ml'); //
                  }
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setHelp - sekcja pomocy
        case 'setHelp':
          printText += AppLocalizations.of(context)!.helpMe; //" Help me:";
          //intention = 'setHelp';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) { 
                case 'help':
                  help = '${slots[key]}';
                  if (globals.jezyk == "pl_PL") {
                    switch (help) {
                      case 'pomóż mi':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocSpisKomend(context, poZamknieciu: () => openDialog = false);
                        beep('open');
                        openDialog = true;
                        break;
                      case 'zamknij pomoc':
                        if (openDialog) {
                          printText1 = ' ${slots[key]}';
                          Navigator.pop(context);
                          openDialog = false;
                          beep('close');
                        }
                        break;
                    }
                  } else {
                    switch (help) {
                      case 'help me':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocSpisKomend(context, poZamknieciu: () => openDialog = false);
                        beep('open');
                        openDialog = true;
                        break;
                      case 'close help':
                        if (openDialog) {
                          printText1 = ' ${slots[key]}';
                          Navigator.pop(context);
                          openDialog = false;
                          beep('close');
                        }
                        break;
                    }
                  }
                  break;

                case 'helpMe':
                  helpMe = '${slots[key]}';
                  if (globals.jezyk == "pl_PL") {
                    switch (helpMe) {
                      //sesja, dyktowanie notatek i cofanie - polecenia, które
                      //powstały dopiero przy Vosku. Tylko w gałęzi polskiej,
                      //bo slot $helpMe ma "notatki" wyłącznie w pol_vosk.yml.
                      case 'notatki':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocSesja(context, poZamknieciu: () => openDialog = false);
                        beep('open');
                        openDialog = true;
                        break;
                      case 'lokacja':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocLokacja(context, poZamknieciu: () => openDialog = false);
                        beep('open');
                        openDialog = true;
                        break;
                      case 'przegląd':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocPrzeglad(context, poZamknieciu: () => openDialog = false);
                        beep('open');
                        openDialog = true;
                        break;
                      case 'wyposażenie':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocWyposazenie(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      //gramatyka Rhino miała tu "pokarm", pol_vosk.yml mówi
                      //"dokarmianie" (tak samo jak app_pl.arb: feeding).
                      //Stara etykieta zostaje, żeby nic nie regresowało.
                      case 'pokarm':
                      case 'dokarmianie':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocDokarmianie(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'leczenie':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocLeczenie(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'matka':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocMatka(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'rodzina':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocRodzina(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      //j.w. - Rhino miał "zbiór", pol_vosk.yml ma "zbiory"
                      //(app_pl.arb: harvest)
                      case 'zbiór':
                      case 'zbiory':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocZbiory(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'data':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocData(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'ul': //to samo co "ul po"
                        if (readyApiary == true && readyHive == true) {
                          _ulPo = true; //wyswitlany jest ul po przegladzie
                          if (openDialog) Navigator.pop(context); //zamknij okno
                          printText1 = ' ${slots[key]}';
                          getDaty(nrXXOfApiary, nrXXOfHive).then((_) {
                            //pobranie dat z bazy
                            if (_daty.isNotEmpty) {
                              //print('wybrana = $wybranaData');
                              wybranaData = _daty[indexDaty].data;
                            } //najwcześniejsza data pobrana z bazy
                            //pobranie informacji o korpusach w wybranym ulu
                            getKorpusy(nrXXOfApiary, nrXXOfHive, wybranaData)
                                .then((_) {
                              //ilość rekordów oznacza ilość korpusów i informacje o ich typach(1-półkorpus, 2-korpus)

                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      nrXXOfApiary, nrXXOfHive)
                                  .then((_) {
                                //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
                                Provider.of<Infos>(context, listen: false)
                                    .fetchAndSetInfosForHive(
                                        nrXXOfApiary, nrXXOfHive)
                                    .then((_) {
                                  //wszystkie informacje dla wybranego pasieki i ula

                                  Provider.of<Hives>(context, listen: false)
                                      .fetchAndSetHives(nrXXOfApiary)
                                      .then((_) {
                                    //wszystkie ule z tabeli ule z bazy lokalnej

                                    //obliczane wielkości płótna dla wszystkich korpusów w ulu
                                    widthCanvas = 0; //szerokość płótna
                                    highCanvas = 0; //wysokość płótna
                                    for (var i = 0; i < _korpusy.length; i++) {
                                      highCanvas += _korpusy[i].typ * 75 +
                                          30; //wysokość półkorpusa + 2 po 15 na padding
                                    }
                                    final hivesData =
                                        Provider.of<Hives>(context, listen: false);
                                    List<Hive> hive = hivesData.items.where((hv) {
                                      return hv.ulNr ==
                                          nrXXOfHive; // jest ==  a było contain ale dla typu String
                                    }).toList();
                                    widthCanvas = hive[0].ramek * 20 +
                                        20; //opis zawiera ilość ramek, po 20px na ramkę i 2 x 10px na padding

                                    _dialogBuilderHive(context);
                                    openDialog = true;
                                    beep('open');
                                  });
                                });
                              });
                            });
                          });
                        }
                        break;
                      case 'ul po': //to samo co "ul"
                        if (readyApiary == true && readyHive == true) {
                          _ulPo = true; //wyswitlany jest ul po przegladzie
                          if (openDialog) Navigator.pop(context); //zamknij okno
                          printText1 = ' ${slots[key]}';
                          getDaty(nrXXOfApiary, nrXXOfHive).then((_) {
                            //pobranie dat z bazy
                            if (_daty.isNotEmpty) {
                              //print('wybrana = $wybranaData');
                              wybranaData = _daty[indexDaty].data;
                            } //najwcześniejsza data pobrana z bazy
                            //pobranie informacji o korpusach w wybranym ulu
                            getKorpusy(nrXXOfApiary, nrXXOfHive, wybranaData)
                                .then((_) {
                              //ilość rekordów oznacza ilość korpusów i informacje o ich typach(1-półkorpus, 2-korpus)

                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      nrXXOfApiary, nrXXOfHive)
                                  .then((_) {
                                //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
                                Provider.of<Infos>(context, listen: false)
                                    .fetchAndSetInfosForHive(
                                        nrXXOfApiary, nrXXOfHive)
                                    .then((_) {
                                  //wszystkie informacje dla wybranego pasieki i ula

                                  Provider.of<Hives>(context, listen: false)
                                      .fetchAndSetHives(nrXXOfApiary)
                                      .then((_) {
                                    //wszystkie ule z tabeli ule z bazy lokalnej

                                    //obliczane wielkości płótna dla wszystkich korpusów w ulu
                                    widthCanvas = 0; //szerokość płótna
                                    highCanvas = 0; //wysokość płótna
                                    for (var i = 0; i < _korpusy.length; i++) {
                                      highCanvas += _korpusy[i].typ * 75 +
                                          30; //wysokość półkorpusa + 2 po 15 na padding
                                    }
                                    final hivesData =
                                        Provider.of<Hives>(context, listen: false);
                                    List<Hive> hive = hivesData.items.where((hv) {
                                      return hv.ulNr ==
                                          nrXXOfHive; // jest ==  a było contain ale dla typu String
                                    }).toList();
                                    widthCanvas = hive[0].ramek * 20 +
                                        20; //opis zawiera ilość ramek, po 20px na ramkę i 2 x 10px na padding

                                    _dialogBuilderHive(context);
                                    openDialog = true;
                                    beep('open');
                                  });
                                });
                              });
                            });
                          });
                        }
                        break;
                      case 'ul przed':
                        if (readyApiary == true && readyHive == true) {
                          _ulPo = false; //wyswitlany jest ul przed przeglądem
                          if (openDialog) Navigator.pop(context); //zamknij okno
                          printText1 = ' ${slots[key]}';
                          getDaty(nrXXOfApiary, nrXXOfHive).then((_) {
                            //pobranie dat z bazy
                            if (_daty.isNotEmpty) {
                              //print('wybrana = $wybranaData');
                              wybranaData = _daty[indexDaty].data;
                            } //najwcześniejsza data pobrana z bazy
                            //pobranie informacji o korpusach w wybranym ulu
                            getKorpusy(nrXXOfApiary, nrXXOfHive, wybranaData)
                                .then((_) {
                              //ilość rekordów oznacza ilość korpusów i informacje o ich typach(1-półkorpus, 2-korpus)

                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      nrXXOfApiary, nrXXOfHive)
                                  .then((_) {
                                //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
                                Provider.of<Infos>(context, listen: false)
                                    .fetchAndSetInfosForHive(
                                        nrXXOfApiary, nrXXOfHive)
                                    .then((_) {
                                  //wszystkie informacje dla wybranego pasieki i ula

                                  Provider.of<Hives>(context, listen: false)
                                      .fetchAndSetHives(nrXXOfApiary)
                                      .then((_) {
                                    //wszystkie ule z tabeli ule z bazy lokalnej

                                    //obliczane wielkości płótna dla wszystkich korpusów w ulu
                                    widthCanvas = 0; //szerokość płótna
                                    highCanvas = 0; //wysokość płótna
                                    for (var i = 0; i < _korpusy.length; i++) {
                                      highCanvas += _korpusy[i].typ * 75 +
                                          30; //wysokość półkorpusa + 2 po 15 na padding
                                    }
                                    final hivesData =
                                        Provider.of<Hives>(context, listen: false);
                                    List<Hive> hive = hivesData.items.where((hv) {
                                      return hv.ulNr ==
                                          nrXXOfHive; // jest ==  a było contain ale dla typu String
                                    }).toList();
                                    widthCanvas = hive[0].ramek * 20 +
                                        20; //opis zawiera ilość ramek, po 20px na ramkę i 2 x 10px na padding

                                    _dialogBuilderHive(context);
                                    openDialog = true;
                                    beep('open');
                                  });
                                });
                              });
                            });
                          });
                        }
                        break;
                      case 'ul wcześniej':
                        if (readyApiary == true && readyHive == true) {
                          if (openDialog) Navigator.pop(context); //zamknij okno
                          printText1 = ' ${slots[key]}';
                          indexDaty = indexDaty + 1;
                          getDaty(nrXXOfApiary, nrXXOfHive).then((_) {
                            //pobranie dat z bazy
                            if (indexDaty == _daty.length)
                              indexDaty = indexDaty - 1;
                            if (_daty.isNotEmpty) {
                              //print('wybrana = $wybranaData');
                              wybranaData = _daty[indexDaty].data;
                            } //najwcześniejsza data pobrana z bazy

                            //pobranie informacji o korpusach w wybranym ulu
                            getKorpusy(nrXXOfApiary, nrXXOfHive, wybranaData)
                                .then((_) {
                              //ilość rekordów oznacza ilość korpusów i informacje o ich typach(1-półkorpus, 2-korpus)

                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      nrXXOfApiary, nrXXOfHive)
                                  .then((_) {
                                //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
                                Provider.of<Infos>(context, listen: false)
                                    .fetchAndSetInfosForHive(
                                        nrXXOfApiary, nrXXOfHive)
                                    .then((_) {
                                  //wszystkie informacje dla wybranego pasieki i ula

                                  Provider.of<Hives>(context, listen: false)
                                      .fetchAndSetHives(nrXXOfApiary)
                                      .then((_) {
                                    //wszystkie ule z tabeli ule z bazy lokalnej

                                    //obliczane wielkości płótna dla wszystkich korpusów w ulu
                                    widthCanvas = 0; //szerokość płótna
                                    highCanvas = 0; //wysokość płótna
                                    for (var i = 0; i < _korpusy.length; i++) {
                                      highCanvas += _korpusy[i].typ * 75 +
                                          30; //wysokość półkorpusa + 2 po 15 na padding
                                    }
                                    final hivesData =
                                        Provider.of<Hives>(context, listen: false);
                                    //final hives = hivesData.items;
                                    List<Hive> hive = hivesData.items.where((hv) {
                                      return hv.ulNr ==
                                          nrXXOfHive; // jest ==  a było contain ale dla typu String
                                    }).toList();
                                    widthCanvas = hive[0].ramek * 20 +
                                        20; //opis zawiera ilość ramek, po 20px na ramkę i 2 x 10px na padding

                                    _dialogBuilderHive(context);
                                    openDialog = true;
                                    beep('open');
                                  });
                                });
                              });
                            });
                          });
                        }
                        break;
                      case 'ul później':
                        if (readyApiary == true && readyHive == true) {
                          if (openDialog) Navigator.pop(context); //zamknij okno
                          printText1 = ' ${slots[key]}';
                          indexDaty = indexDaty - 1;
                          if (indexDaty < 0) indexDaty = 0;
                          getDaty(nrXXOfApiary, nrXXOfHive).then((_) {
                            //pobranie dat z bazy
                            if (_daty.isNotEmpty) {
                              //print('wybrana = $wybranaData');
                              wybranaData = _daty[indexDaty].data;
                            } //najwcześniejsza data pobrana z bazy

                            //pobranie informacji o korpusach w wybranym ulu
                            getKorpusy(nrXXOfApiary, nrXXOfHive, wybranaData)
                                .then((_) {
                              //ilość rekordów oznacza ilość korpusów i informacje o ich typach(1-półkorpus, 2-korpus)

                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      nrXXOfApiary, nrXXOfHive)
                                  .then((_) {
                                //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
                                Provider.of<Infos>(context, listen: false)
                                    .fetchAndSetInfosForHive(
                                        nrXXOfApiary, nrXXOfHive)
                                    .then((_) {
                                  //wszystkie informacje dla wybranego pasieki i ula

                                  Provider.of<Hives>(context, listen: false)
                                      .fetchAndSetHives(nrXXOfApiary)
                                      .then((_) {
                                    //wszystkie ule z tabeli ule z bazy lokalnej

                                    //obliczane wielkości płótna dla wszystkich korpusów w ulu
                                    widthCanvas = 0; //szerokość płótna
                                    highCanvas = 0; //wysokość płótna
                                    for (var i = 0; i < _korpusy.length; i++) {
                                      highCanvas += _korpusy[i].typ * 75 +
                                          30; //wysokość półkorpusa + 2 po 15 na padding
                                    }
                                    final hivesData =
                                        Provider.of<Hives>(context, listen: false);
                                    List<Hive> hive = hivesData.items.where((hv) {
                                      return hv.ulNr ==
                                          nrXXOfHive; // jest ==  a było contain ale dla typu String
                                    }).toList();
                                    widthCanvas = hive[0].ramek * 20 +
                                        20; //opis zawiera ilość ramek, po 20px na ramkę i 2 x 10px na padding

                                    _dialogBuilderHive(context);
                                    openDialog = true;
                                    beep('open');
                                  });
                                });
                              });
                            });
                          });
                        }
                        break;
                    }
                  } else {
                    switch (helpMe) {
                      case 'location':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocLokacja(context, poZamknieciu: () => openDialog = false);
                        beep('open');
                        openDialog = true;
                        break;
                      case 'inspection':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocPrzeglad(context, poZamknieciu: () => openDialog = false);
                        beep('open');
                        openDialog = true;
                        break;
                      case 'equipment':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocWyposazenie(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'feeding':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocDokarmianie(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'treatment':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocLeczenie(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'queen':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocMatka(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'colony':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocRodzina(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'harvest':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocZbiory(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'date':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        pomocData(context, poZamknieciu: () => openDialog = false);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'hive': //to samo co "after"
                        _ulPo = true; //wyswitlany jest ul po przegladzie
                        if (readyApiary == true && readyHive == true) {
                          if (openDialog) Navigator.pop(context); //zamknij okno
                          printText1 = ' ${slots[key]}';
                          getDaty(globals.pasiekaID, globals.ulID).then((_) {
                            //pobranie dat z bazy
                            if (_daty.isNotEmpty) {
                              //print('wybrana = $wybranaData');
                              wybranaData = _daty[indexDaty].data;
                            } //najwcześniejsza data pobrana z bazy
                            //pobranie informacji o korpusach w wybranym ulu
                            getKorpusy(globals.pasiekaID, globals.ulID, wybranaData)
                                .then((_) {
                              //ilość rekordów oznacza ilość korpusów i informacje o ich typach(1-półkorpus, 2-korpus)

                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      globals.pasiekaID, globals.ulID)
                                  .then((_) {
                                //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
                                Provider.of<Infos>(context, listen: false)
                                    .fetchAndSetInfosForHive(
                                        globals.pasiekaID, globals.ulID)
                                    .then((_) {
                                  //wszystkie informacje dla wybranego pasieki i ula

                                  Provider.of<Hives>(context, listen: false)
                                      .fetchAndSetHives(globals.pasiekaID)
                                      .then((_) {
                                    //wszystkie ule z tabeli ule z bazy lokalnej

                                    //obliczane wielkości płótna dla wszystkich korpusów w ulu
                                    widthCanvas = 0; //szerokość płótna
                                    highCanvas = 0; //wysokość płótna
                                    for (var i = 0; i < _korpusy.length; i++) {
                                      highCanvas += _korpusy[i].typ * 75 +
                                          30; //wysokość półkorpusa + 2 po 15 na padding
                                    }
                                    final hivesData =
                                        Provider.of<Hives>(context, listen: false);
                                    List<Hive> hive = hivesData.items.where((hv) {
                                      return hv.ulNr ==
                                          nrXXOfHive; // jest ==  a było contain ale dla typu String
                                    }).toList();
                                    widthCanvas = hive[0].ramek * 20 +
                                        20; //opis zawiera ilość ramek, po 20px na ramkę i 2 x 10px na padding

                                    _dialogBuilderHive(context);
                                    openDialog = true;
                                    beep('open');
                                  });
                                });
                              });
                            });
                          });
                        }
                        break;
                      case 'hive after':
                        _ulPo = true; //wyswitlany jest ul po przegladzie
                        if (readyApiary == true && readyHive == true) {
                          if (openDialog) Navigator.pop(context); //zamknij okno
                          printText1 = ' ${slots[key]}';
                          getDaty(globals.pasiekaID, globals.ulID).then((_) {
                            //pobranie dat z bazy
                            if (_daty.isNotEmpty) {
                              //print('wybrana = $wybranaData');
                              wybranaData = _daty[indexDaty].data;
                            } //najwcześniejsza data pobrana z bazy
                            //pobranie informacji o korpusach w wybranym ulu
                            getKorpusy(globals.pasiekaID, globals.ulID, wybranaData)
                                .then((_) {
                              //ilość rekordów oznacza ilość korpusów i informacje o ich typach(1-półkorpus, 2-korpus)

                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      globals.pasiekaID, globals.ulID)
                                  .then((_) {
                                //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
                                Provider.of<Infos>(context, listen: false)
                                    .fetchAndSetInfosForHive(
                                        globals.pasiekaID, globals.ulID)
                                    .then((_) {
                                  //wszystkie informacje dla wybranego pasieki i ula

                                  Provider.of<Hives>(context, listen: false)
                                      .fetchAndSetHives(globals.pasiekaID)
                                      .then((_) {
                                    //wszystkie ule z tabeli ule z bazy lokalnej

                                    //obliczane wielkości płótna dla wszystkich korpusów w ulu
                                    widthCanvas = 0; //szerokość płótna
                                    highCanvas = 0; //wysokość płótna
                                    for (var i = 0; i < _korpusy.length; i++) {
                                      highCanvas += _korpusy[i].typ * 75 +
                                          30; //wysokość półkorpusa + 2 po 15 na padding
                                    }
                                    final hivesData =
                                        Provider.of<Hives>(context, listen: false);
                                    List<Hive> hive = hivesData.items.where((hv) {
                                      return hv.ulNr ==
                                          nrXXOfHive; // jest ==  a było contain ale dla typu String
                                    }).toList();
                                    widthCanvas = hive[0].ramek * 20 +
                                        20; //opis zawiera ilość ramek, po 20px na ramkę i 2 x 10px na padding

                                    _dialogBuilderHive(context);
                                    openDialog = true;
                                    beep('open');
                                  });
                                });
                              });
                            });
                          });
                        }
                        break;
                      case 'hive before':
                        _ulPo = false; //wyswitlany jest ul przed przeglądem
                        if (readyApiary == true && readyHive == true) {
                          if (openDialog) Navigator.pop(context); //zamknij okno
                          printText1 = ' ${slots[key]}';
                          getDaty(globals.pasiekaID, globals.ulID).then((_) {
                            //pobranie dat z bazy
                            if (_daty.isNotEmpty) {
                              //print('wybrana = $wybranaData');
                              wybranaData = _daty[indexDaty].data;
                            } //najwcześniejsza data pobrana z bazy
                            //pobranie informacji o korpusach w wybranym ulu
                            getKorpusy(globals.pasiekaID, globals.ulID, wybranaData)
                                .then((_) {
                              //ilość rekordów oznacza ilość korpusów i informacje o ich typach(1-półkorpus, 2-korpus)

                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      globals.pasiekaID, globals.ulID)
                                  .then((_) {
                                //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
                                Provider.of<Infos>(context, listen: false)
                                    .fetchAndSetInfosForHive(
                                        globals.pasiekaID, globals.ulID)
                                    .then((_) {
                                  //wszystkie informacje dla wybranego pasieki i ula

                                  Provider.of<Hives>(context, listen: false)
                                      .fetchAndSetHives(globals.pasiekaID)
                                      .then((_) {
                                    //wszystkie ule z tabeli ule z bazy lokalnej

                                    //obliczane wielkości płótna dla wszystkich korpusów w ulu
                                    widthCanvas = 0; //szerokość płótna
                                    highCanvas = 0; //wysokość płótna
                                    for (var i = 0; i < _korpusy.length; i++) {
                                      highCanvas += _korpusy[i].typ * 75 +
                                          30; //wysokość półkorpusa + 2 po 15 na padding
                                    }
                                    final hivesData =
                                        Provider.of<Hives>(context, listen: false);
                                    List<Hive> hive = hivesData.items.where((hv) {
                                      return hv.ulNr ==
                                          nrXXOfHive; // jest ==  a było contain ale dla typu String
                                    }).toList();
                                    widthCanvas = hive[0].ramek * 20 +
                                        20; //opis zawiera ilość ramek, po 20px na ramkę i 2 x 10px na padding

                                    _dialogBuilderHive(context);
                                    openDialog = true;
                                    beep('open');
                                  });
                                });
                              });
                            });
                          });
                        }
                        break;
                      case 'hive earlier':
                        if (readyApiary == true && readyHive == true) {
                          if (openDialog) Navigator.pop(context); //zamknij okno
                          printText1 = ' ${slots[key]}';
                          indexDaty = indexDaty + 1;
                          getDaty(globals.pasiekaID, globals.ulID).then((_) {
                            //pobranie dat z bazy
                            if (_daty.isNotEmpty) {
                              //print('wybrana = $wybranaData');
                              wybranaData = _daty[indexDaty].data;
                            } //najwcześniejsza data pobrana z bazy

                            //pobranie informacji o korpusach w wybranym ulu
                            getKorpusy(globals.pasiekaID, globals.ulID, wybranaData)
                                .then((_) {
                              //ilość rekordów oznacza ilość korpusów i informacje o ich typach(1-półkorpus, 2-korpus)

                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      globals.pasiekaID, globals.ulID)
                                  .then((_) {
                                //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
                                Provider.of<Infos>(context, listen: false)
                                    .fetchAndSetInfosForHive(
                                        globals.pasiekaID, globals.ulID)
                                    .then((_) {
                                  //wszystkie informacje dla wybranego pasieki i ula

                                  Provider.of<Hives>(context, listen: false)
                                      .fetchAndSetHives(globals.pasiekaID)
                                      .then((_) {
                                    //wszystkie ule z tabeli ule z bazy lokalnej

                                    //obliczane wielkości płótna dla wszystkich korpusów w ulu
                                    widthCanvas = 0; //szerokość płótna
                                    highCanvas = 0; //wysokość płótna
                                    for (var i = 0; i < _korpusy.length; i++) {
                                      highCanvas += _korpusy[i].typ * 75 +
                                          30; //wysokość półkorpusa + 2 po 15 na padding
                                    }
                                    final hivesData =
                                        Provider.of<Hives>(context, listen: false);
                                    //final hives = hivesData.items;
                                    List<Hive> hive = hivesData.items.where((hv) {
                                      return hv.ulNr ==
                                          nrXXOfHive; // jest ==  a było contain ale dla typu String
                                    }).toList();
                                    widthCanvas = hive[0].ramek * 20 +
                                        20; //opis zawiera ilość ramek, po 20px na ramkę i 2 x 10px na padding

                                    _dialogBuilderHive(context);
                                    openDialog = true;
                                    beep('open');
                                  });
                                });
                              });
                            });
                          });
                        }
                        break;
                      case 'hive later':
                        if (readyApiary == true && readyHive == true) {
                          if (openDialog) Navigator.pop(context); //zamknij okno
                          printText1 = ' ${slots[key]}';
                          indexDaty = indexDaty - 1;
                          if (indexDaty < 0) indexDaty = 0;
                          getDaty(globals.pasiekaID, globals.ulID).then((_) {
                            //pobranie dat z bazy
                            if (_daty.isNotEmpty) {
                              //print('wybrana = $wybranaData');
                              wybranaData = _daty[indexDaty].data;
                            } //najwcześniejsza data pobrana z bazy

                            //pobranie informacji o korpusach w wybranym ulu
                            getKorpusy(globals.pasiekaID, globals.ulID, wybranaData)
                                .then((_) {
                              //ilość rekordów oznacza ilość korpusów i informacje o ich typach(1-półkorpus, 2-korpus)

                              Provider.of<Frames>(context, listen: false)
                                  .fetchAndSetFramesForHive(
                                      globals.pasiekaID, globals.ulID)
                                  .then((_) {
                                //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
                                Provider.of<Infos>(context, listen: false)
                                    .fetchAndSetInfosForHive(
                                        globals.pasiekaID, globals.ulID)
                                    .then((_) {
                                  //wszystkie informacje dla wybranego pasieki i ula

                                  Provider.of<Hives>(context, listen: false)
                                      .fetchAndSetHives(globals.pasiekaID)
                                      .then((_) {
                                    //wszystkie ule z tabeli ule z bazy lokalnej

                                    //obliczane wielkości płótna dla wszystkich korpusów w ulu
                                    widthCanvas = 0; //szerokość płótna
                                    highCanvas = 0; //wysokość płótna
                                    for (var i = 0; i < _korpusy.length; i++) {
                                      highCanvas += _korpusy[i].typ * 75 +
                                          30; //wysokość półkorpusa + 2 po 15 na padding
                                    }
                                    final hivesData =
                                        Provider.of<Hives>(context, listen: false);
                                    List<Hive> hive = hivesData.items.where((hv) {
                                      return hv.ulNr ==
                                          nrXXOfHive; // jest ==  a było contain ale dla typu String
                                    }).toList();
                                    widthCanvas = hive[0].ramek * 20 +
                                        20; //opis zawiera ilość ramek, po 20px na ramkę i 2 x 10px na padding

                                    _dialogBuilderHive(context);
                                    openDialog = true;
                                    beep('open');
                                  });
                                });
                              });
                            });
                          });
                        }
                        break;
                    }
                  }
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setDate - zmiana daty 
        case 'setDate':
          printText += AppLocalizations.of(context)!.date; //" Date:"
          //intention = 'setDate';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) { 
                case 'dateDay':
                  printText1 += "\n" + AppLocalizations.of(context)!.day + " =";
                  printText1 += " ${slots[key]}";
                  if (ustawianaData == '') {
                    ustawianaData = formatter.format(now);
                    String a = ustawianaData.substring(0, 8);
                    String b = slots[key]
                        .toString()
                        .padLeft(2, '0'); //i.toString().padLeft(2, '0');
                    ustawianaData = a + b;
                    formattedDate = ustawianaData;
                  } else {
                    String a = ustawianaData.substring(0, 8);
                    String b = slots[key]
                        .toString()
                        .padLeft(2, '0'); //i.toString().padLeft(2, '0');
                    ustawianaData = a + b;
                    formattedDate = ustawianaData;
                  }
                  beep('open');
                  break;
                case 'dateMonth':
                  printText1 += "\n" + AppLocalizations.of(context)!.month + " =";
                  printText1 += " ${slots[key]}";
                  if (ustawianaData == '') {
                    ustawianaData = formatter.format(now);
                    String a = ustawianaData.substring(0, 5);
                    String b = slots[key]
                        .toString()
                        .padLeft(2, '0'); //i.toString().padLeft(2, '0');
                    String c = ustawianaData.substring(7);
                    ustawianaData = a + b + c;
                    formattedDate = ustawianaData;
                  } else {
                    String a = ustawianaData.substring(0, 5);
                    String b = slots[key]
                        .toString()
                        .padLeft(2, '0'); //i.toString().padLeft(2, '0');
                    String c = ustawianaData.substring(7);
                    ustawianaData = a + b + c;
                    formattedDate = ustawianaData;
                  }
                  beep('open');
                  break;
                case 'dateYear':
                  printText1 += "\n" + AppLocalizations.of(context)!.year + " =";
                  printText1 += " ${slots[key]}";
                  if (ustawianaData == '') {
                    ustawianaData = formatter.format(now);
                    String a = ustawianaData.substring(0, 2);
                    String b = slots[key]
                        .toString()
                        .padLeft(2, '0'); //i.toString().padLeft(2, '0');
                    String c = ustawianaData.substring(4);
                    ustawianaData = a + b + c;
                    formattedDate = ustawianaData;
                  } else {
                    String a = ustawianaData.substring(0, 2);
                    String b = slots[key]
                        .toString()
                        .padLeft(2, '0'); //i.toString().padLeft(2, '0');
                    String c = ustawianaData.substring(4);
                    ustawianaData = a + b + c;
                    formattedDate = ustawianaData;
                  }
                  beep('open');
                  break;
                case 'currentDate':
                  printText1 += "\n" + AppLocalizations.of(context)!.date;
                  printText1 += " ${slots[key]}";
                  ustawianaData = '';
                  formattedDate = formatter.format(now);
                  beep('open');
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setHarvest - zbiory w sekcji info
        case 'setHarvest':
          printText += AppLocalizations.of(context)!.harvest; //" harvest:";
          //intention = 'setHarvest';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) { 
                case 'honeySmallHarvest': //zbiory miodu ilość małych ramek
                  if (readyApiary == true && readyHive == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.honey + " = ";
                    printText1 += " ${slots[key]} " +
                        AppLocalizations.of(context)!.small +
                        " " +
                        AppLocalizations.of(context)!.frame;
                    zapis = AppLocalizations.of(context)!.harvest +
                        ": " +
                        AppLocalizations.of(context)!.honey +
                        " ${slots[key]} x " +
                        AppLocalizations.of(context)!.small +
                        " " +
                        AppLocalizations.of(context)!.frame;
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'harvest',
                        AppLocalizations.of(context)!.honey +
                            " = " +
                            AppLocalizations.of(context)!.small +
                            " " +
                            AppLocalizations.of(context)!.frame +
                            " x",
                        '${slots[key]}',
                        '');
                  }
                  break;
                case 'honeyBigHarvest': //zbiory miodu ilość duzych ramek
                  if (readyApiary == true && readyHive == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.honey + " = ";
                    printText1 += " ${slots[key]} " +
                        AppLocalizations.of(context)!.big +
                        " " +
                        AppLocalizations.of(context)!.frame;
                    zapis = AppLocalizations.of(context)!.harvest +
                        ": " +
                        AppLocalizations.of(context)!.honey +
                        " ${slots[key]} x " +
                        AppLocalizations.of(context)!.big +
                        " " +
                        AppLocalizations.of(context)!.frame;
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'harvest',
                        AppLocalizations.of(context)!.honey +
                            " = " +
                            AppLocalizations.of(context)!.big +
                            " " +
                            AppLocalizations.of(context)!.frame +
                            " x",
                        '${slots[key]}',
                        '');
                  }
                  break;
                case 'beePollenHarvestML': //zbiory pyłku w mililitrach - część dziesiątki/jedności
                  if (readyApiary == true && readyHive == true) {
                    beePollenHarvestML = '${slots[key]}';
                    if (slots.length == 1)
                      beePollenHarvestHML =
                          ''; //zerowanie setek bo sa tylko dwie cyfry
                    printText1 +=
                        '\n' + AppLocalizations.of(context)!.beePollen + ' =';
                    printText1 += " $beePollenHarvestHML$beePollenHarvestML ml";
                    zapis = AppLocalizations.of(context)!.beePollen +
                        ' = $beePollenHarvestHML$beePollenHarvestML ml';
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'harvest',
                        AppLocalizations.of(context)!.beePollen + " = ",
                        '$beePollenHarvestHML$beePollenHarvestML',
                        "ml"); //
                  }
                  break;
                case 'beePollenHarvestHML': //zbiory pyłku w mililitrach - setki
                  if (readyApiary == true && readyHive == true) {
                    if (globals.jezyk == "pl_PL") {
                      switch (slots[key]) {
                        case 'sto':
                          beePollenHarvestHML = '1';
                          break;
                        case 'dwieście':
                          beePollenHarvestHML = '2';
                          break;
                        case 'trzysta':
                          beePollenHarvestHML = '3';
                          break;
                        case 'czterysta':
                          beePollenHarvestHML = '4';
                          break;
                        case 'pięćset':
                          beePollenHarvestHML = '5';
                          break;
                        case 'sześćset':
                          beePollenHarvestHML = '6';
                          break;
                        case 'siedemset':
                          beePollenHarvestHML = '7';
                          break;
                        case 'osiemset':
                          beePollenHarvestHML = '8';
                          break;
                        case 'dziewięćset':
                          beePollenHarvestHML = '9';
                          break;
                        default:
                          beePollenHarvestHML = '0';
                      }
                    } else {
                      switch (slots[key]) {
                        case 'one hundred':
                          beePollenHarvestHML = '1';
                          break;
                        case 'two hundred':
                          beePollenHarvestHML = '2';
                          break;
                        case 'three hundred':
                          beePollenHarvestHML = '3';
                          break;
                        case 'four hundred':
                          beePollenHarvestHML = '4';
                          break;
                        case 'five hundred':
                          beePollenHarvestHML = '5';
                          break;
                        case 'six hundred':
                          beePollenHarvestHML = '6';
                          break;
                        case 'seven hundred':
                          beePollenHarvestHML = '7';
                          break;
                        case 'eight hundred':
                          beePollenHarvestHML = '8';
                          break;
                        case 'nine hundred':
                          beePollenHarvestHML = '9';
                          break;
                        default:
                          beePollenHarvestHML = '0';
                      }
                    }
                    if (slots.length == 1)
                      beePollenHarvestML =
                          '00'; //dwa zera bo jest tylko cyfra setek
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.beePollen + " =";
                    printText1 +=
                        " $beePollenHarvestHML" + '$beePollenHarvestML ml';
                    zapis = AppLocalizations.of(context)!.beePollen +
                        " = $beePollenHarvestHML" +
                        '$beePollenHarvestML ml';
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'harvest',
                        AppLocalizations.of(context)!.beePollen + " = ",
                        '$beePollenHarvestHML$beePollenHarvestML',
                        "ml"); //
                  }
                  break;

                case 'beePollenHarvest': //zbiory pyłku w miarce
                  if (readyApiary == true && readyHive == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.beePollen + " = ";
                    printText1 +=
                        " ${slots[key]} " + AppLocalizations.of(context)!.miarka;
                    zapis = AppLocalizations.of(context)!.harvest +
                        ": " +
                        AppLocalizations.of(context)!.beePollen +
                        " ${slots[key]} x " +
                        AppLocalizations.of(context)!.miarka;
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'harvest',
                        AppLocalizations.of(context)!.beePollen +
                            "  = " +
                            AppLocalizations.of(context)!.miarka +
                            " x",
                        '${slots[key]}',
                        '');
                  }
                  break;
                case 'beePollenHarvestI': //zbiory pyłku częśc całkowita w litrach
                  if (readyApiary == true && readyHive == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.beePollen + " = ";
                    printText1 += "  ${slots[key]} l";
                    beePollenHarvestI = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.beePollen +
                        "  = $beePollenHarvestI" +
                        AppLocalizations.of(context)!.kropka +
                        "$beePollenHarvestD l";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'harvest',
                        " " + AppLocalizations.of(context)!.beePollen + " =  ",
                        "$beePollenHarvestI" + '.' + "$beePollenHarvestD",
                        "l"); //
                  }
                  break;
                case 'beePollenHarvestD': //zbiory pyłku częśc dziesiętna w litrach
                  if (readyApiary == true && readyHive == true) {
                    printText1 +=
                        "\n" + AppLocalizations.of(context)!.beePollen + " = ";
                    printText1 += "  ${slots[key]} l";
                    beePollenHarvestD = '${slots[key]}';
                    zapis = AppLocalizations.of(context)!.beePollen +
                        "  = $beePollenHarvestI" +
                        AppLocalizations.of(context)!.kropka +
                        "$beePollenHarvestD l";
                    readyInfo = true;
                    zapisInfoDoBazy(
                        'harvest',
                        " " + AppLocalizations.of(context)!.beePollen + " =  ",
                        "$beePollenHarvestI" + '.' + "$beePollenHarvestD",
                        "l"); //
                  }
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setFrames - ustawienie zakresu ramek od - do
        case 'setFrames':
          printText += AppLocalizations.of(context)!.frames; //" frames:";
          //intention = 'setFrames';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) { 
                case 'framesState': //zakres ramek od do
              framesState = '${slots[key]}';
              if (framesState == AppLocalizations.of(context)!.close) {
                beep('close');
                printText1 += " ${slots[key]}";
                readyFrames = false;
                nrXXOdFrame = 0;
                nrXXDoFrame = 0;
                nrXXOdFrameTemp = 0;
                nrXXDoFrameTemp = 0;
                resetStory();
              } else {
                if (readyApiary == true &&
                    readyHive == true &&
                    (readyBody == true || readyHalfBody == true)) {
                  printText1 += " ${slots[key]}";
                  nrXXDoFrame = nrXXDoFrameTemp;
                  nrXXOdFrame = nrXXOdFrameTemp;
                  nrXXDoFrameTemp = 0;
                  nrXXOdFrameTemp = 0;
                  readyFrames = true;
                  readyFrame = false;
                  beep('open');
                  resetStory();
                }
              }
              break;
            case 'nrXXOdFrame':
              nrXXOdFrame = int.parse('${slots[key]}');
              if ((framesState == AppLocalizations.of(context)!.open ||
                      framesState == AppLocalizations.of(context)!.set) &&
                  (readyApiary == true &&
                      readyHive == true &&
                      (readyBody == true || readyHalfBody == true))) {
                beep('open');
                printText1 += " ${slots[key]}";
                readyFrames = true;
                readyFrame = false;
                nrXXOdFrameTemp = nrXXOdFrame;
                resetStory(); //kasowanie zmiennych przechowujących biezace zasoby ramki (bo nowa ramka)
              } else {
                if (readyApiary == true &&
                    readyHive == true &&
                    (readyBody == true || readyHalfBody == true)) {
                  printText1 += " ${slots[key]}";
                  nrXXOdFrameTemp = nrXXOdFrame;
                  nrXXOdFrame = 0;
                  readyFrames = false;
                  resetStory();
                }
              }
              break;
            case 'nrXXDoFrame':
              nrXXDoFrame = int.parse('${slots[key]}');
              if ((framesState == AppLocalizations.of(context)!.open ||
                      framesState == AppLocalizations.of(context)!.set) &&
                  (readyApiary == true &&
                      readyHive == true &&
                      (readyBody == true || readyHalfBody == true))) {
                beep('open');
                printText1 += " ${slots[key]}";
                readyFrames = true;
                readyFrame = false;
                nrXXDoFrameTemp = nrXXDoFrame;
                resetStory(); //kasowanie zmiennych przechowujących biezace zasoby ramki (bo nowa ramka)
              } else {
                if (readyApiary == true &&
                    readyHive == true &&
                    readyBody == true) {
                  printText1 += " ${slots[key]}";
                  nrXXDoFrameTemp = nrXXDoFrame;
                  nrXXDoFrame = 0;
                  readyFrames = false;
                  resetStory();
                }
              }
              break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;
//setAllHives - ustawienie wszystkich uli w pasiece
        case 'setAllHives':
          printText += AppLocalizations.of(context)!.allHives; //" All Hives";
          //intention = 'setAllHives';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) { 
                case 'allHivesState':
                  allHivesState = '${slots[key]}';
                  if (allHivesState == AppLocalizations.of(context)!.close) {
                    beep('close');
                    printText1 += AppLocalizations.of(context)!
                        .allHivesAre; //"\n All Hives are";
                    printText1 += " ${slots[key]}";
                    readyAllHives = false;
                    readyHive = false;
                    hiveState = AppLocalizations.of(context)!.close;
                    nrXXOfHive = 0;
                    bodyState = AppLocalizations.of(context)!.close;
                    readyBody = false;
                    readyInfo = false;
                    globals.ikonaUla = 'green'; //"zerowanie" ikony ula
                    resetZakresUli();
                    resetSumowania();
                    resetBody();
                    resetStory();
                    //Navigator.pop(context);
                  } else {
                    if (readyApiary == true) {
                      printText1 += AppLocalizations.of(context)!.allHivesAre;
                      printText1 += " ${slots[key]}";
                      readyAllHives = true;
                      //"wszystkie ule" po "ule od X do Y" ma znowu znaczyć CAŁĄ
                      //pasiekę - bez tego zostawałyby stare granice zakresu
                      resetZakresUli();
                      beep('open');
                      readyHive = false;
                      hiveState = AppLocalizations.of(context)!.close;
                      nrXXOfHive = 0;
                      bodyState = AppLocalizations.of(context)!.close;
                      readyBody = false;
                      globals.ikonaUla = 'green'; //"zerowanie" ikony ula
                      if (nrXXOfApiary != 0) {
                        //wpis do tabeli 'pogoda'
                        aktualizacjaPogody(nrXXOfApiary);
                      }
                      resetSumowania();
                      resetBody();
                      resetStory();
                      resetInfo();
                      // pomocSpisKomend(context, poZamknieciu: () => openDialog = false);
                    }
                  }
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;

//setHivesRange - zakres uli "ustaw ule od X do Y"
//To NIE jest trzeci tryb pracy, tylko zawężenie trybu zbiorczego: włącza
//readyAllHives dokładnie tak jak "ustaw wszystkie ule" i dokłada granice
//nrXXOdHive/nrXXDoHive, po których filtruje się pętla zapisu. Dzięki temu
//wpis info, belka ula i cofanie działają bez żadnych dodatkowych gałęzi.
//Układ slotów przepisany z setFrames (para od-do z wariantami Temp na wypadek,
//gdy liczby przyjdą przed czasownikiem), skutki uboczne z setAllHives.
        case 'setHivesRange':
          printText += AppLocalizations.of(context)!.hivesPlural; //" ule"
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              switch (key) {
                case 'hivesRangeState':
                  hivesRangeState = '${slots[key]}';
                  if (hivesRangeState ==
                      AppLocalizations.of(context)!.close) {
                    beep('close');
                    printText1 += " ${slots[key]}";
                    //zamknięcie zakresu gasi CAŁY tryb zbiorczy, a nie tylko
                    //granice - inaczej "zamknij ule od 3 do 7" cicho rozszerzyłoby
                    //zapis na całą pasiekę zamiast go zatrzymać
                    readyAllHives = false;
                    allHivesState = AppLocalizations.of(context)!.close;
                    readyHive = false;
                    hiveState = AppLocalizations.of(context)!.close;
                    nrXXOfHive = 0;
                    bodyState = AppLocalizations.of(context)!.close;
                    readyBody = false;
                    readyInfo = false;
                    globals.ikonaUla = 'green'; //"zerowanie" ikony ula
                    resetZakresUli();
                    resetSumowania();
                    resetBody();
                    resetStory();
                  } else {
                    if (readyApiary == true) {
                      printText1 += " ${slots[key]}";
                      //granice mogły paść przed czasownikiem - wtedy czekają w Temp
                      nrXXOdHive = nrXXOdHiveTemp;
                      nrXXDoHive = nrXXDoHiveTemp;
                      nrXXOdHiveTemp = 0;
                      nrXXDoHiveTemp = 0;
                      _uporzadkujZakresUli();
                      _wlaczTrybZbiorczyDlaZakresu();
                      beep('open');
                    }
                  }
                  break;
                case 'nrXXOdHive':
                  nrXXOdHive = int.parse('${slots[key]}');
                  //warunek jest "cokolwiek poza zamknięciem", a NIE "otwórz albo
                  //ustaw" jak w setFrames. Slot $state ma dziewięć wartości i
                  //przy zawężonej liście "wstaw ule od 3 do 7" wpadałoby w gałąź
                  //else, zerując granice - a wtedy tryb zbiorczy pisze do CAŁEJ
                  //pasieki. Przy ramkach to pomyłka o jedną ramkę, przy ulach
                  //o całą pasiekę, więc tu nie ma miejsca na cichy fallback.
                  if (hivesRangeState != null &&
                      hivesRangeState !=
                          AppLocalizations.of(context)!.close &&
                      readyApiary == true) {
                    beep('open');
                    printText1 += " ${slots[key]}";
                    //granica jest już zastosowana, więc Temp zostaje PUSTY.
                    //Inaczej przeżyłby do następnej komendy, a case czasownika
                    //czyta go w ciemno - "ustaw ule od 10 do 12" po wcześniejszym
                    //"od 5 do 9" porównywałoby 10 ze starą dziewiątką i zamieniało
                    //granice miejscami.
                    _uporzadkujZakresUli();
                  } else {
                    if (readyApiary == true) {
                      printText1 += " ${slots[key]}";
                      nrXXOdHiveTemp = nrXXOdHive;
                      nrXXOdHive = 0;
                    }
                  }
                  break;
                case 'nrXXDoHive':
                  nrXXDoHive = int.parse('${slots[key]}');
                  //patrz komentarz przy nrXXOdHive
                  if (hivesRangeState != null &&
                      hivesRangeState !=
                          AppLocalizations.of(context)!.close &&
                      readyApiary == true) {
                    beep('open');
                    printText1 += " ${slots[key]}";
                    //Temp zostaje pusty - patrz komentarz przy nrXXOdHive
                    _uporzadkujZakresUli();
                  } else {
                    if (readyApiary == true) {
                      printText1 += " ${slots[key]}";
                      nrXXDoHiveTemp = nrXXDoHive;
                      nrXXDoHive = 0;
                    }
                  }
                  break;
              }
            }
          } else {
            //jezeli nie zdekodowano slotu czyli parametrów intencji
            printText = AppLocalizations.of(context)!.error;
            beep('error');
          }
          printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
              ? {
                  printText = AppLocalizations.of(context)!.wrongCommand,
                  beep('error'),
                }
              : printText += printText1;
          break;

//setApiary - numer pasieki
        case 'setApiary':
          printText += AppLocalizations.of(context)!.apiary; //" Apiary";
          intention = 'setApiary';
          if (inference.slots!.isNotEmpty) {
            Map<String, String> slots = inference.slots!;
            //dla kazdego elementu slotu (parametru w wypowiadanej komendzie)
            for (String key in slots.keys) {
              //print('key ------ $key');
              switch (key) {         
                case 'apiaryState':
                  apiaryState = '${slots[key]}';
                  if (apiaryState == AppLocalizations.of(context)!.close) {
                    beep('close');
                    printText1 += " ${slots[key]}";
                    readyApiary = false;
                    nrXXOfApiary = 0;
                    nrXXOfApairyTemp = 0;
                    readyHive = false;
                    nrXXOfHive = 0;
                    bodyState = AppLocalizations.of(context)!.close;
                    readyBody = false;
                    readyInfo = false;
                    resetSumowania();
                    resetBody();
                    resetStory();
                    resetInfo();
                  } else {
                    // przypadek dla odwrotnej kolejności wnioskowania lub/i przy ustawianiu Apiary
                    printText1 += " ${slots[key]}";
                    readyApiary = true; //ustawienie Apairy
                    beep('open');
                    nrXXOfApiary =
                        nrXXOfApairyTemp; // ustawienie numeru Apairy z temp
                    nrXXOfApairyTemp = 0;
                    //zerowanie Hive, Body i Frame
                    readyHive = false;
                    hiveState = AppLocalizations.of(context)!.close;
                    readyAllHives = false;
                    allHivesState = AppLocalizations.of(context)!.close;
                    nrXXOfHive = 0;
                    bodyState = AppLocalizations.of(context)!.close;
                    readyBody = false;
                    readyInfo = false;
                    // globals.ikonaPasieki = 'green'; //"zerowanie" ikony pasieki
                    resetSumowania();
                    resetBody();
                    resetStory();
                  }
                  break;
                case 'nrXXOfApiary':
                  nrXXOfApiary = int.parse('${slots[key]}');
                  if (apiaryState == AppLocalizations.of(context)!.open ||
                      apiaryState == AppLocalizations.of(context)!.set) {
                    printText1 += " ${slots[key]}";
                    nrXXOfApairyTemp = nrXXOfApiary;
                    readyApiary =
                        true; // ustawienie Apairy - kolejność wnioskowania poprawna
                    beep('open');
                    //zerowanie danych Hive, Body i Frame
                    readyHive = false;
                    hiveState = AppLocalizations.of(context)!.close;
                    readyAllHives = false;
                    allHivesState = AppLocalizations.of(context)!.close;
                    nrXXOfHive = 0;
                    bodyState = AppLocalizations.of(context)!.close;
                    readyBody = false;
                    readyInfo = false;
                    // globals.ikonaPasieki = 'green'; //"zerowanie" ikony pasieki
                    resetSumowania();
                    resetBody();
                    resetStory();
                  } else {
                    //przypadek kiedy najpierw będzie numer a pózniej status pasieki (a teraz jest close)
                    printText1 += " ${slots[key]}";
                    nrXXOfApairyTemp = nrXXOfApiary;
                    nrXXOfApiary = 0;
                    readyApiary = false;
                    readyHive = false;
                    nrXXOfHive = 0;
                    bodyState = AppLocalizations.of(context)!.close;
                    readyBody = false;
                    readyInfo = false;
                    resetSumowania();
                    resetBody();
                    resetStory();
                  }
                  break;
                }
              }
            } else {
              //jezeli nie zdekodowano slotu czyli parametrów intencji
              printText = AppLocalizations.of(context)!.error;
              beep('error');
            }
            printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
                ? {
                    printText = AppLocalizations.of(context)!.wrongCommand,
                    beep('error'),
                  }
                : printText += printText1;
          break;
      } //od switch intent
    } //od if (inference.isUnderstood!)

    //koniec przetwarzania inferencji - odtwórz odroczone 'okej' jezeli nic go nie wyparło
    //(zapisałam/zamknięte/błąd kasują odroczone 'okej', dzięki czemu nie słychać podwójnych dźwięków)
    _flushPendingOpenBeep();

    print('wynik = $printText');
    return printText;
  }


  //pobranie pogody z www dla miasta i aktualizacja wpisu w bazie
  Future<bool>? getCurrentWeather(String location) async {
    var endpoint = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=$location&appid=3943495c9983f5f94616a38aa17fcb4d&units=$units"); //https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=-2.15&appid={API key}")
    var response = await http.get(endpoint);
    var body = jsonDecode(response.body);
    //print('dane o pogodzie z miasta -----------------------');
    //print(body);
    temp = body["main"]["temp"];
    icon = body["weather"][0]["icon"];
    //print('$temp, $icon');
    String teraz = formatterPogoda.format(now);

    DBHelper.updatePogoda(nrXXOfApiary.toString(), teraz, temp, icon); //
    return true;
  }

  //pobranie pogody z www dla koordynatów i aktualizacja wpisu w bazie
  Future<bool>? getCurrentWeatherCoord(String lati, String longi) async {
    var endpoint = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$lati&lon=$longi&appid=3943495c9983f5f94616a38aa17fcb4d&units=$units"); //https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=-2.15&appid={API key}")
    var response = await http.get(endpoint);
    var body = jsonDecode(response.body);
    //print('dane o pogodzie z koordynatów -----------------------');
    //print(body);
    temp = body["main"]["temp"];
    icon = body["weather"][0]["icon"];
    //print('$temp, $icon');
    String teraz = formatterPogoda.format(now);

    DBHelper.updatePogoda(nrXXOfApiary.toString(), teraz, temp, icon); //
    return true;
  }

  // POGODA - uaktualne dane o pogodzie dla pasiek
  aktualizacjaPogody(int numerPasieki) {
    Provider.of<Weathers>(context, listen: false)
        .fetchAndSetWeathers()
        .then((_) {
      //uzyskanie dostępu do danych z tabeli 'pogoda'
      final pogodaData = Provider.of<Weathers>(context, listen: false);
      List<Weather> pogoda = pogodaData.items.where((ap) {
        return ap.id == (numerPasieki.toString());
        //'numerPasieki'; // jest ==  a było contains ale dla typu String
      }).toList();

      if (pogoda.length == 0) {
        //jezeli nie ma danych dla wybranej pasieki
        //print('brak danych o lokalizacji pasieki');
        pobranie = '';
        temp = 0.0;
        icon = '';
        units = 'metric';
      } else {
        //jezeli są jakieś dane dla pasieki
        switch (pogoda[0].units) {
          case 1:
            units = 'metric';
            stopnie = "\u2103";
            break;
          case 2:
            units = 'standard';
            stopnie = "\u212A";
            break;
          case 3:
            units = 'imperial';
            stopnie = "\u2109";
            break;
          default:
            units = 'metric';
            stopnie = "\u2103";
        }
        now = DateTime.now();
        final data = DateTime.parse(pogoda[0].pobranie);
        final difference = now.difference(data);
        //print('difference');
        //print(difference.inMinutes);
        //jezeli powyzej 30 minut od ostatniego pobrania pogody
        if (difference.inMinutes > 30) {
          //to aktualizacja z www
          _isInternet().then(
            (inter) {
              if (inter) {
                // print('$inter - jest internet');
                //print('pobranie danych o pogodzie');
                if (pogoda[0].latitude != '' && pogoda[0].longitude != '') {
                  getCurrentWeatherCoord(
                      pogoda[0].latitude, pogoda[0].longitude);
                } else if (pogoda[0].miasto != '') {
                  getCurrentWeather(pogoda[0].miasto);
                }
              } else {
                // print('braaaaaak internetu');
                //dane o pogodzie nie będą aktualizowane a pobrane z bazy
                temp = double.parse(pogoda[0].temp);
                icon = pogoda[0].icon;
              }
            },
          );
        } else {
          //to pobranie z bazy lokalnej
          temp = double.parse(pogoda[0].temp);
          icon = pogoda[0].icon;
        }
        //print('${pogoda[0].id}, ${pogoda[0].miasto}, ${pogoda[0].latitude}');
      }
    });
  }

  sumujZasob(int co, ile) {
    //print('sumowanie  ========== zas = $co,  wart = $ile');
    //dodawanie zasobów w ramach korpusu (dla danego hive)
    switch (co) {
      case 1:
        trut = trut + int.parse(drone.replaceAll(RegExp('%'), ''));
        break;
      case 2:
        czerw = czerw + int.parse(brood.replaceAll(RegExp('%'), ''));
        //print('czerw w switch = $czerw , brood = $brood');
        break;
      case 3:
        larwy = larwy + int.parse(larvae.replaceAll(RegExp('%'), ''));
        break;
      case 4:
        jaja = jaja + int.parse(eggs.replaceAll(RegExp('%'), ''));
        break;
      case 5:
        pierzga = pierzga + int.parse(pollen.replaceAll(RegExp('%'), ''));
        break;
      case 6:
        miod = miod + int.parse(honey.replaceAll(RegExp('%'), ''));
        break;
      case 7:
        dojrzaly = dojrzaly + int.parse(honeySeald.replaceAll(RegExp('%'), ''));
        break;
      case 8:
        weza = weza + int.parse(wax.replaceAll(RegExp('%'), ''));
        break;
      case 9:
        susz = susz + int.parse(waxComb.replaceAll(RegExp('%'), ''));
        break;
      case 10:
        matka = int.parse(queen);
        break;
      case 11:
        mateczniki = mateczniki + int.parse(queenCells);
        ;
        break;
      case 12:
        usunmat = usunmat + int.parse(delQCells);
        ;
        break;
      case 13:
        todo = toDo; //zapamiętanie ostatniego toDo w korpusie
        ;
        break;
    }
  }

  zapisDoBazy(int zas, wart) {
    _zapisWTejKomendzie = true; //migawka do cofania trafi na stos po switchu
    zapisZas = 0; //zerowanie parametów wywołania tej funkcji
    zapisWart = '0'; //j.w.

//** data i czas przeglądu, rozmiar ramki */
    if (ustawianaData != '')
      formattedDate = ustawianaData;
    else
      formattedDate = formatter.format(now);
    formatedTime = formatterHm.format(now);

    if (sizeOfFrame == AppLocalizations.of(context)!.big) {
      _rozmiar = 2;
    } else if (sizeOfFrame == AppLocalizations.of(context)!.small) {
      _rozmiar = 1;
    }

//** numer korpusa */
    if (nrXOfBody != 0) {
      _korpusNr = nrXOfBody;
      _typ = 2;
    } else {
      _korpusNr = nrXOfHalfBody;
      _typ = 1;
    }
    // int tempKorpusNr =
    //     korpusNr; //czy przed zapisem korpusNr był 0 (bo czy dopisywać czy liczyć od nowa)
    // korpusNr = _korpusNr;

    Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrXXOfApiary)
      .then((_) {
        //pobranie danych o ulu bo mogą byc dane do których trzeba dopisać dodaną wartość do belki
        final hiveData = Provider.of<Hives>(context, listen: false);
        hive = hiveData.items.where((element) {
          return element.id == ('$nrXXOfApiary.$nrXXOfHive');
        }).toList();

      //jezeli ul istnieje
      if (hive.isNotEmpty)
      //jezeli data i korpus wcześniej zapisane zgadza sie z obecnym zapisem to dopisywanie
      if (_korpusNr == hive[0].korpusNr && formattedDate == hive[0].przeglad) {
        //przypisanie istniejacych danych o ulu - bo dopisywanie
        ikona = hive[0].ikona;
        ramek = hive[0].ramek;
        korpusNr = hive[0].korpusNr;
        trut = hive[0].trut;
        czerw = hive[0].czerw;
        larwy = hive[0].larwy;
        jaja = hive[0].jaja;
        pierzga = hive[0].pierzga;
        miod = hive[0].miod;
        dojrzaly = hive[0].dojrzaly;
        weza = hive[0].weza;
        susz = hive[0].susz;
        matka = hive[0].matka;
        mateczniki = hive[0].mateczniki;
        usunmat = hive[0].usunmat;
        todo = hive[0].todo;
        matka1 = hive[0].matka1;
        matka2 = hive[0].matka2;
        matka3 = hive[0].matka3;
        matka4 = hive[0].matka4;
        matka5 = hive[0].matka5;
        rodzajUla = hive[0].h1;
        typUla = hive[0].h2;
        tagNFC = hive[0].h3;
      } else {
        ikona = 'green'; //hive[0].ikona;
        ramek = hive[0].ramek;
        korpusNr = _korpusNr; //zerowanie belki bo nowe zliczanie
        trut = 0;
        czerw = 0;
        larwy = 0;
        jaja = 0;
        pierzga = 0;
        miod = 0;
        dojrzaly = 0;
        weza = 0;
        susz = 0;
        matka = 0;
        mateczniki = 0;
        usunmat = 0;
        todo = '0';
        matka1 = hive[0].matka1;
        matka2 = hive[0].matka2;
        matka3 = hive[0].matka3;
        matka4 = hive[0].matka4;
        matka5 = hive[0].matka5;
        rodzajUla = hive[0].h1;
        typUla = hive[0].h2;
        tagNFC = hive[0].h3;
      }
      // print(
      //     'przeglad hive poczatek korpus ${korpusNr}: t${trut}, c${czerw}, l${larwy}, j${jaja}, p${pierzga}, m${miod}, d${dojrzaly},w${weza}, s${susz}, m${matka}, mt${mateczniki}, dm${usunmat} , td${todo} m1${matka1} m2${matka2} m3${matka3} m4${matka4} m5${matka5}');
//    });
    // else {
    //   korpusNr = 0;
    //   trut = 0;
    //   czerw = 0;
    //   larwy = 0;
    //   jaja = 0;
    //   pierzga = 0;
    //   miod = 0;
    //   dojrzaly = 0;
    //   weza = 0;
    //   susz = 0;
    //   matka = 0;
    //   mateczniki = 0;
    //   usunmat = 0;
    //   todo = '0';
    // }

    //data.       pasiekaNr.    ulNr.     korpusNr.   ramkaNr.   strona.  zasob
    //String id = '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$nrXOfBody.$nrXXOfFrame.$_strona.$zas';
    //print('zapis do bazy ----------- zasob=$zas wartosc=$wart');

    if (readyFrames) {
      //dla zakresu ramek w korpusie lub półkorpusie

      //print('readyFrames wejście w zapis do bazy=================');
      //jezeli ustawione jest miejsce do zapisu
      if (nrXXOfApiary != 0 &&
          nrXXOfHive != 0 &&
          _korpusNr != 0 &&
          nrXXOdFrame != 0) {
        //print('if wejscie przed for');
        //zapis w pętli dia zakresu ramek
        for (var i = nrXXOdFrame; i <= nrXXDoFrame; i++) {
          //print('pętla for - i = $i');
          if (siteOfFrame == 'left' ||
              siteOfFrame == 'lewa' ||
              siteOfFrame == 'lewej' ||
              siteOfFrame == 'lewą') {
            Frames.insertFrame(
                '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$i.$i.1.$zas',
                formattedDate,
                nrXXOfApiary,
                nrXXOfHive,
                _korpusNr,
                _typ,
                i,
                i, //ramka po ??? i trzeba zmienić id - dodać ramkaNrPo (tu sie chyba nie da)
                _rozmiar,
                1, //lewa
                zas,
                wart,
                0);
            sumujZasob(zas, wart);
          } else if (siteOfFrame == 'right' ||
              siteOfFrame == 'prawa' ||
              siteOfFrame == 'prawej' ||
              siteOfFrame == 'prawą') {
            Frames.insertFrame(
                '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$i.$i.2.$zas',
                formattedDate,
                nrXXOfApiary,
                nrXXOfHive,
                _korpusNr,
                _typ,
                i,
                i, //ramka po ???
                _rozmiar,
                2, //prawa
                zas,
                wart,
                0);
            sumujZasob(zas, wart);
          } else {
            //bo both lub whole
            Frames.insertFrame(
                '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$i.$i.1.$zas',
                formattedDate,
                nrXXOfApiary,
                nrXXOfHive,
                _korpusNr,
                _typ,
                i,
                i,
                _rozmiar,
                1, //lewa
                zas,
                wart,
                0);
            sumujZasob(zas, wart);
            if(zas < 13 ){ //kod nie jest wykonywany dla toDo i isDone (ograniczenie ilości znaczków  - wystarczą tylko dla lewej strony )
              Frames.insertFrame(
                  '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$i.$i.2.$zas',
                  formattedDate,
                  nrXXOfApiary,
                  nrXXOfHive,
                  _korpusNr,
                  _typ,
                  i,
                  i,
                  _rozmiar,
                  2, //prawa
                  zas,
                  wart,
                  0);
              sumujZasob(zas, wart);
            }
          }
        } //od for
       
        //automatyczna zmiana numeru "ramkaNr" po "isDone" dla zakresu zamek (najpierw komenda "ustaw ramka od X do Y"     
        //dla "wstaw ramka"
            if(wart == 'wstaw ramka' || wart == 'inserted'){
              nrXXOfFrame = 0;    
              //wstawienie ramek z numerem 0/X dla zakresu ramek
              Provider.of<Frames>(context, listen: false)
                .fetchAndSetFramesForHive(nrXXOfApiary, nrXXOfHive)
                .then((_) {  
                  //dla wszystkich zasobów dla ramki z numerem "przed" nalezy ustawić taką samą wartość "ramkaNr" = 0 zeby cała ramka z zasobami była nową ramką wstawioną 0/X
                  final framesData1 = Provider.of<Frames>(context, listen: false);
                    //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu i tylko dla ramek z numerem "po" róznym od zera - bo z zerem są ramki usuniete wcześniej z tych miejsc)
                  List<Frame> frames = framesData1.items.where((fr) {
                    return fr.ramkaNr >= nrXXOdFrame && fr.ramkaNr <= nrXXDoFrame && fr.ramkaNrPo != 0 && fr.data == formattedDate && fr.korpusNr == _korpusNr; //return fr.data.contains('2024-04-04');
                  }).toList();
                  //print('frames.length = ${frames.length}');
                    //dla kazdego zasobu modyfikacja ramkaNrPo
                  for (var i = 0; i < frames.length; i++) {
                    //print('w pętli id: ${frames[i].id}, ramkaPrzed: ${frames[i].ramkaNr}, ramkaPo: ${frames[i].ramkaNrPo}, zasób: ${frames[i].zasob}');
                    DBHelper.updateRamkaNr(frames[i].id, 0); //ramkaNr = 0 czyli wstawiona
                  }
                Provider.of<Frames>(context, listen: false)
                  .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                  .then((_) {
                  //Navigator.of(context).pop();
                });
              }); 
            } 
        //automatyczna zmiana numeru "ramkaPo" po "isDone" dla zakresu zamek (najpierw komenda "ustaw ramka od X do Y")
        //dla "usuń ramka"
            if(wart == 'usuń ramka' || wart == 'deleted'){
              nrXXOfFramePo = 0;    
              Provider.of<Frames>(context, listen: false)
                .fetchAndSetFramesForHive(nrXXOfApiary, nrXXOfHive)
                .then((_) {  
                  //dla wszystkich zasobów dla ramki z numerem "przed" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
                  final framesData1 = Provider.of<Frames>(context, listen: false);
                    //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu)
                  List<Frame> frames = framesData1.items.where((fr) {
                    return fr.ramkaNr >= nrXXOdFrame && fr.ramkaNr <= nrXXDoFrame && fr.data == formattedDate && fr.korpusNr == _korpusNr; //return fr.data.contains('2024-04-04');
                  }).toList();
                  //print('frames.length = ${frames.length}');
                    //dla kazdego zasobu modyfikacja ramkaNrPo - nie wystarczy!!!
                    //dla kazdego zasobu - usuń rekord zasobu i zapisz go z ramkaNrPo = 0 i z nowym id gdzie ramka po = 0
                  for (var i = 0; i < frames.length; i++) {
                    //print('w pętli id: ${frames[i].id}, ramkaPrzed: ${frames[i].ramkaNr}, ramkaPo: ${frames[i].ramkaNrPo}, zasób: ${frames[i].zasob}');
                   // DBHelper.updateRamkaNrPo(frames[i].id, 0); //ramkaPo = 0 czyli usunięta
                    DBHelper.deleteFrame(frames[i].id).then((_) {  //kasowanie ramki bo będzie nowa
                      Frames.insertFrame(
                        '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.${frames[i].ramkaNr}.0.${frames[i].strona}.${frames[i].zasob}',
                        formattedDate,
                        nrXXOfApiary,
                        nrXXOfHive,
                        _korpusNr,
                        _typ,//2-korpus, 1-półkorpus
                        frames[i].ramkaNr,//ramkaNr
                        0, //ramkaNrPo 
                        frames[i].rozmiar,
                        frames[i].strona,
                        frames[i].zasob,
                        frames[i].wartosc,
                        0);
                    });
                  }
                Provider.of<Frames>(context, listen: false)
                  .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                  .then((_) {
                  //Navigator.of(context).pop();
                });
              }); 
              //zerowanie zasobów bo ramki zostały usuniete (źle bo wszystkie zasoby usunięte a usuniete moze było tylko kilka ramek)
              trut = 0;
              czerw = 0;
              larwy = 0;
              jaja = 0;
              pierzga = 0;
              miod = 0;
              dojrzaly = 0;
              weza = 0;
              susz = 0;
              matka = 0;
              mateczniki = 0;
              usunmat = 0;
              todo = '0';
            } 

            //dla "przesuń w lewo"
            if(wart == 'przesuń w lewo' || wart == 'moved left'){
              Provider.of<Frames>(context, listen: false)
                .fetchAndSetFramesForHive(nrXXOfApiary, nrXXOfHive)
                .then((_) {  
                  //dla wszystkich zasobów dla ramki z numerem "przed" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
                  final framesData1 = Provider.of<Frames>(context, listen: false);
                    //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu)
                  List<Frame> frames = framesData1.items.where((fr) {
                    return fr.ramkaNr >= nrXXOdFrame && fr.ramkaNr <= nrXXDoFrame && fr.data == formattedDate && fr.korpusNr == _korpusNr; //return fr.data.contains('2024-04-04');
                  }).toList();
                  //print('frames.length = ${frames.length}');
                    //dla kazdego zasobu modyfikacja ramkaNrPo
                  for (var i = 0; i < frames.length; i++) {
                    //print('w pętli id: ${frames[i].id}, ramkaPrzed: ${frames[i].ramkaNr}, ramkaPo: ${frames[i].ramkaNrPo}, zasób: ${frames[i].zasob}');
                    DBHelper.updateRamkaNrPo(frames[i].id, frames[i].ramkaNrPo - 1); //ramkaNrPo ma wartośc o 1 mniejszą
                  }
                Provider.of<Frames>(context, listen: false)
                  .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                  .then((_) {
                  //Navigator.of(context).pop();
                });
              }); 
            } 

            //dla "przesuń w prawo"
            if(wart == 'przesuń w prawo' || wart == 'moved right'){
              Provider.of<Frames>(context, listen: false)
                .fetchAndSetFramesForHive(nrXXOfApiary, nrXXOfHive)
                .then((_) {  
                  //dla wszystkich zasobów dla ramki z numerem "przed" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
                  final framesData1 = Provider.of<Frames>(context, listen: false);
                    //wszystkie zasoby tej ramki (i z wybranej daty dla ula i tylko dla wybranego korpusu)
                  List<Frame> frames = framesData1.items.where((fr) {
                    return fr.ramkaNr >= nrXXOdFrame && fr.ramkaNr <= nrXXDoFrame && fr.data == formattedDate &&  fr.korpusNr == _korpusNr; //return fr.data.contains('2024-04-04');
                  }).toList();
                    //  print('nrXXOfHive = $nrXXOfHive');
                    //  print('frames.length = ${frames.length}');
                    //dla kazdego zasobu modyfikacja ramkaNrPo
                  for (var i = 0; i < frames.length; i++) {
                    //print('w pętli id: ${frames[i].id}, ramkaPrzed: ${frames[i].ramkaNr}, ramkaPo: ${frames[i].ramkaNrPo}, zasób: ${frames[i].zasob}');
                    DBHelper.updateRamkaNrPo(frames[i].id, frames[i].ramkaNrPo + 1); //ramkaNrPo ma wartośc o 1 większą
                    //print('numer ramkaPo  = ${frames[i].ramkaNrPo + 1} ');
                  }
                Provider.of<Frames>(context, listen: false)
                  .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                  .then((_) {
                  //Navigator.of(context).pop();
                });
              }); 
            } 


      } else {
        beep('error');
      }
    } else {
      //dla jednej ramki
      if (nrXXOfApiary != 0 &&
          nrXXOfHive != 0 &&
          _korpusNr != 0 &&
          (nrXXOfFrame != 0 || nrXXOfFramePo != 0)) {
        if (siteOfFrame == 'left' ||
            siteOfFrame == 'lewa' ||
            siteOfFrame == 'lewej' ||
            siteOfFrame == 'lewą') {
          Frames.insertFrame(
              '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$nrXXOfFrame.$nrXXOfFramePo.1.$zas',
              formattedDate,
              nrXXOfApiary,
              nrXXOfHive,
              _korpusNr,
              _typ,
              nrXXOfFrame,
              nrXXOfFramePo, //ramka po 
              _rozmiar,
              1, //lewa
              zas,
              wart,
              0);
          sumujZasob(zas, wart);
        } else if (siteOfFrame == 'right' ||
            siteOfFrame == 'prawa' ||
            siteOfFrame == 'prawej' ||
            siteOfFrame == 'prawą') {
          Frames.insertFrame(
              '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$nrXXOfFrame.$nrXXOfFramePo.2.$zas',
              formattedDate,
              nrXXOfApiary,
              nrXXOfHive,
              _korpusNr,
              _typ,
              nrXXOfFrame,
              nrXXOfFramePo, //ramka po 
              _rozmiar,
              2, //prawa
              zas,
              wart,
              0);
          sumujZasob(zas, wart);
        } else {
          //bo both lub whole
          Frames.insertFrame(
              '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$nrXXOfFrame.$nrXXOfFramePo.1.$zas',
              formattedDate,
              nrXXOfApiary,
              nrXXOfHive,
              _korpusNr,
              _typ,
              nrXXOfFrame,
              nrXXOfFramePo, //ramka po
              _rozmiar,
              1, //lewa
              zas,
              wart,
              0);
          sumujZasob(zas, wart);
          Frames.insertFrame(
              '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$nrXXOfFrame.$nrXXOfFramePo.2.$zas',
              formattedDate,
              nrXXOfApiary,
              nrXXOfHive,
              _korpusNr,
              _typ,
              nrXXOfFrame,
              nrXXOfFramePo, //ramka po ???
              _rozmiar,
              2, //prawa
              zas,
              wart,
              0);
          sumujZasob(zas, wart);
        }
      } else {
        beep('error');
      }
    }
    //zasób został zapisany do tabeli "ramki"

    // ikona ula zółta jezeli zasobem była czynność do zrobienia
    //o ile nie była czerwona lub pomarańczowa, bo problemy z matką są wazniejsze
    if ((todo != '' && todo != '0') && (ikona != 'red' || ikona != 'orange')) {
        ikona = 'yellow';
    }else if ((todo == '' || todo == '0') && (ikona =='yellow'))ikona ='green';
      
    
    // if (toDo != '' && (globals.ikonaPasieki != 'red' || globals.ikonaPasieki != 'orange')) {
    //   globals.ikonaPasieki = 'yellow';
    // }

    if(_nowaIloscRamek > 0) ramek = _nowaIloscRamek; //zmieniono ilość ramek
    
    // print(
    //     'zapis Hive do bazy korpus = $korpusNr, todo = $todo, usunmat = $usunmat *******************');
    //print('przegląd korpus po zapisie ${korpusNr}: t${trut}, c${czerw}, l${larwy}, j${jaja}, p${pierzga}, m${miod}, d${dojrzaly},w${weza}, s${susz}, m${matka}, mt${mateczniki}, dm${usunmat} , td${todo} m1${matka1} m2${matka2} m3${matka3} m4${matka4} m5${matka5}');

    //wpis do tabeli "ule"
    Hives.insertHive(
      '$nrXXOfApiary.$nrXXOfHive',
      nrXXOfApiary, //pasieka nr
      nrXXOfHive, //ul nr
      formattedDate, //przeglad
      ikona, //ikona
      ramek, //ramek - ilość ramek w korpusie
      korpusNr,
      trut,
      czerw,
      larwy,
      jaja,
      pierzga,
      miod,
      dojrzaly,
      weza,
      susz,
      matka,
      mateczniki,
      usunmat,
      todo,
      '0',
      '0',
      '0',
      '0',
      matka1,
      matka2,
      matka3,
      matka4,
      matka5,
      rodzajUla,
      typUla,
      tagNFC,
      1, //nieaktualne - zmiana zasobu
    ).then((_) {
      //odświeżenie live podglądu korpusu DOPIERO po zapisaniu zasobów ramek i danych ula do bazy
      //(wywołanie w inferenceCallback trafiało do bazy przed zapisem = pokazywało poprzedni przegląd)
      if (globals.voice2LivePodglad) _refreshLiveView();
      //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
      Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrXXOfApiary)
      .then((_) {
        final hivesData = Provider.of<Hives>(context, listen: false);
        final hives = hivesData.items;
        ileUli = hives.length;
        //print('voice_screen - ilość uli = $ileUli');
        // print(hives.length);
        // print(ileUli);

        //ilość uli zlikwidowanych  - do obliczenia nilości uli w pasiece
        final hiveZlikwidowane = hivesData.items.where((element) {
                return element.ikona == ('black');
              }); 

        //zapis do tabeli "pasieki"
        Apiarys.insertApiary(
          '$nrXXOfApiary',
          nrXXOfApiary, //pasieka nr
          ileUli - hiveZlikwidowane.length, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
          formattedDate, //przeglad
          globals.ikonaPasieki, //ikona nie zmieniana w tym skrypcie
          '??', //opis
        ).then((_) {
          Provider.of<Apiarys>(context, listen: false)
              .fetchAndSetApiarys()
              .then((_) {
            //print('voice_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy po InsertHive w zapisDoBazy');
          });
        });
      });
    });
  });

    // zapisInfoDoBazy('inspection', AppLocalizations.of(context)!.inspection,
    //     globals.ikonaUla, '');
    
    //zapis info o przegladzie do bazy (podczas przeglądu tylko raz na poczatku przegladu zeby była godzina rozpoczecia przegladu i ewentualnie notatka jesli kiedykolwiek sie pojawi zeby jej nie stracić)
    //więc jeśli nie zapisywano jeszcze info przegladu lub zpisano info o innym przeglądzie niz obecny określony przez datę
    if(globals.dataAktualnegoPrzegladu == '' || globals.dataAktualnegoPrzegladu != '$formattedDate' || globals.ulID != nrXXOfHive || globals.pasiekaID != nrXXOfApiary){
      // to pobranie wszystkich info dla ula
      final infoData = Provider.of<Infos>(context, listen: false);
      //pobranie info o tym przeglądzie jezeli jest (czyli zgadza się data, nr ula, kategoria i parametr)
      List<Info> info = infoData.items.where((element) { 
        return element.data == formattedDate && element.ulNr == nrXXOfHive && element.kategoria == 'inspection' && element.parametr == '${AppLocalizations.of(context)!.inspection}'; //data, nr ula, kategoria i parametr
      }).toList();
      //i jezeli wpis o przeglądzie juz jest to
      if(info.isNotEmpty){ 
        //to zapisz w globals datę tego przeglądu
        globals.dataAktualnegoPrzegladu = '$formattedDate';
        //print('info = ${info[0].id}, kategoria = ${info[0].kategoria}, czas = ${info[0].czas}');
      }else{ //a jezeli jeszcze nie ma takego wpisu w providerze
        //dodatkowe sprawdzenie bezpośrednio w bazie (provider może nie być jeszcze załadowany)
        DBHelper.inspectionExists(formattedDate, nrXXOfApiary, nrXXOfHive, AppLocalizations.of(context)!.inspection).then((exists) {
          if(exists){
            globals.dataAktualnegoPrzegladu = '$formattedDate';
          }else{
            //to zapis przegladu do info 'inspection"
            Infos.insertInfo(
              '$formattedDate.$nrXXOfApiary.$nrXXOfHive.inspection.${AppLocalizations.of(context)!.inspection}', //id
              formattedDate, //data
              nrXXOfApiary, //pasiekaNr
              nrXXOfHive, //ulNr
              'inspection', //karegoria
              AppLocalizations.of(context)!.inspection, //parametr
              ikona, //wartosc
              '', //miara
              '',//icon, //ikona pogody
              '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}', //'${temp.toStringAsFixed(0)}$stopnie', //temperatura zaokrąglona do 1 stopnia
              formatterHm.format(DateTime.now()), //formatedTime, //czas
              '', //uwagi
              0 //arch
            ).then((_) {
              Provider.of<Infos>(context, listen: false)
                  .fetchAndSetInfosForHive(nrXXOfApiary,nrXXOfHive)
                  .then((_) {
              });
            });
          }
        });
      }
    }//else{print('juz jest wpis = ${globals.dataAktualnegoPrzegladu}');}

    
    // Infos.insertInfo(
    //     '$formattedDate.$nrXXOfApiary.$nrXXOfHive.inspection.${AppLocalizations.of(context)!.inspection}', //id
    //     formattedDate, //data
    //     nrXXOfApiary, //pasiekaNr
    //     nrXXOfHive, //ulNr
    //     'inspection', //karegoria
    //     AppLocalizations.of(context)!.inspection, //parametr
    //     globals.ikonaUla, //wartosc
    //     '', //miara
    //     icon, //ikona pogody
    //     '${temp.toStringAsFixed(0)}$stopnie', //temperatura zaokrąglona do 1 stopnia
    //     formatedTime, //czas
    //     '', //uwagi
    //     0); //niezarchiwizowane

    _playSuccess();
    //print('beep - success - insertInfo - zapis info do bazy');

  }


  /** ZAPIS INFO DO BAZY */

  //info(id TEXT PRIMARY KEY, pasiekaNr INTEGER, ileUli INTEGER, data TEXT, kategoria TEXT, parametr TEXT, wartosc TEXT, miara TEXT, uwagi TEXT)');
  zapisInfoDoBazy(String kat, String param, String wart, String miar) async {
    _zapisWTejKomendzie = true; //migawka do cofania trafi na stos po switchu
    //Wpis "liczba ramek =" jest JEDYNYM, z którego import odtwarza belkę ula:
    //pole pogoda = rodzaj ula (h1), pole miara = typ ula (h2). Dla niego muszą tam
    //trafić dane ula, a nie ikona pogody i pusty ciąg - inaczej po imporcie Odkład
    //gubił słowo "Odkład", a ulik weselny skrót typu.
    final bool toLiczbaRamek =
        param == AppLocalizations.of(context)!.numberOfFrame + " = ";
    if (ustawianaData != '')
      formattedDate = ustawianaData;
    else
      formattedDate = formatter.format(now);

    formatedTime = formatterHm.format(now);
    //print('czas $formatedTime');

    if (readyAllHives) {
      //** WPIS DLA WSZYSTKICH uli w pasiece
      //pobranie do Hives_items z tabeli ule - ule z pasieki do której ma być wpis
      Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrXXOfApiary)
      .then((_) {
        final hivesData = Provider.of<Hives>(context, listen: false);
        //JEDYNE miejsce, w którym "ustaw ule od X do Y" różni się od "ustaw
        //wszystkie ule" - bez zakresu zwraca całą listę, czyli zachowanie
        //sprzed dołożenia tej komendy.
        final hives = _uleObjeteZapisem(hivesData.items);
        //print('ilość uli do wpisania info = ${hives.length}');

        for (var i = 0; i < hives.length; i++) {
          //print('wpis nr $i');
          Infos.insertInfo(
              '$formattedDate.$nrXXOfApiary.${hives[i].ulNr}.$kat.$param', //id
              formattedDate, //data
              nrXXOfApiary, //pasiekaNr
              hives[i].ulNr, //ulNr
              kat, //karegoria
              param, //parametr
              wart, //wartosc
              toLiczbaRamek ? hives[i].h2 : miar, //miara (dla ramek: typ ula)
              toLiczbaRamek ? hives[i].h1 : icon, //ikona pogody (dla ramek: rodzaj ula)
              '${temp.toStringAsFixed(0)}$stopnie', //temperatura zaokrąglona do 1 stopnia
              formatedTime, //czas
              '', //uwagi
              0); //niezarchiwizowane
          //print('kategoria');
          //print(kat);
          //jezeli dokarmianie lub leczenie to zmiana danych do wyświetlania belki w widoku uli
          if (kat == 'feeding' || kat == 'treatment') {

            //zeby nie stracić danych zebranych podczas przeglądu w widoku zbiorczym uli
            //UWAGA: odczyt MUSI byc synchroniczny. Wczesniej byl tu zagniezdzony
            //fetchAndSetHives().then(...), ktorego nikt nie awaitowal - insertHive ponizej
            //wykonywal sie PRZED callbackiem i zapisywal stare/puste wartosci (m.in. h2 = typ ula,
            //przez co znikal skrot typu w belce, a typ jednego ula wedrowal na inne).
            //Lista "hives" pobrana wyzej ma juz pelne rekordy, wiec dodatkowy fetch byl zbedny.
            final biezacyUl = hives[i];
            hive = [biezacyUl];

            //pobranie danych o ulu
            ikona = biezacyUl.ikona;
            ramek = biezacyUl.ramek;
            trut = biezacyUl.trut;
            czerw = biezacyUl.czerw;
            larwy = biezacyUl.larwy;
            jaja = biezacyUl.jaja;
            pierzga = biezacyUl.pierzga;
            miod = biezacyUl.miod;
            dojrzaly = biezacyUl.dojrzaly;
            weza = biezacyUl.weza;
            susz = biezacyUl.susz;
            matka = biezacyUl.matka;
            mateczniki = biezacyUl.mateczniki;
            usunmat = biezacyUl.usunmat;
            todo = biezacyUl.todo;
            matka1 = biezacyUl.matka1;
            matka2 = biezacyUl.matka2;
            matka3 = biezacyUl.matka3;
            matka4 = biezacyUl.matka4;
            matka5 = biezacyUl.matka5;
            rodzajUla = biezacyUl.h1;
            typUla = biezacyUl.h2;
            tagNFC = biezacyUl.h3;
            // print(
            //     'wstawianie do tabeli ule !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ul = ${hives[i].ulNr}');
            //wpis do tabeli "ule"
            Hives.insertHive(
              '$nrXXOfApiary.${hives[i].ulNr}',
              nrXXOfApiary, //pasieka nr
              hives[i].ulNr, //ul nr
              formattedDate, //przeglad
              ikona, //ikona
              ramek, //ramek - ilość ramek w korpusie
              0, //korpusNr,
              trut,
              czerw,
              larwy,
              jaja,
              pierzga,
              miod, //?????????
              dojrzaly,
              weza,
              susz,
              matka,
              mateczniki,
              usunmat,
              todo,
              kat,
              param,
              wart,
              miar,
              matka1,
              matka2,
              matka3, //?????????/
              matka4,
              matka5,
              rodzajUla,
              typUla,
              tagNFC,
              0,
            );
          }
        }
      });
      _playSuccess();
      //print('beep - success - zapis ula do bazy');

    } else {
      //** WAPIS DLA JEDNEGO ula */

      // if (wart == 'brak' || wart == 'nie ma' || wart == 'missing') {
      //   //jezeli jest informacja ze nie ma matki w ulu
      //   globals.ikonaUla = 'red';
      //   globals.ikonaPasieki = 'red';
      // } else {
      //   //korpusNr = 0; //zeby nie wyświetlał danych o korpusie tylko tekst info
      // }
//print('ZAPIS INFO DO BAZY zzzzzzzzzzzzzzzzzzzzzz');
  //jezeli info dotyczy matki
      if(kat == 'queen'){
        //pobranie ID matki przypisanej do tego ula
        final data = await DBHelper.getQueenID(nrXXOfApiary, nrXXOfHive);
        if (data.isNotEmpty) {
          matkaID = data[0]['id'] as int; //numer id matki - index z tabeli "matka"
        }
      }
      //rodzaj i typ ula do wpisu "liczba ramek =" - patrz komentarz na początku metody
      String rodzajDoInfo = '';
      String typDoInfo = miar;
      if (toLiczbaRamek) {
        final ule = Provider.of<Hives>(context, listen: false).items.where((element) {
          return element.id == ('$nrXXOfApiary.$nrXXOfHive');
        }).toList();
        if (ule.isNotEmpty) {
          rodzajDoInfo = ule[0].h1;
          typDoInfo = ule[0].h2;
        }
      }
      Infos.insertInfo(
          '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$kat.$param', //id
          formattedDate, //data
          nrXXOfApiary, //pasiekaNr
          nrXXOfHive, //ulNr
          kat, //karegoria
          param, //parametr
          wart, //wartosc
          toLiczbaRamek ? typDoInfo : miar, //miara (dla ramek: typ ula)
          toLiczbaRamek //ikona pogody (dla ramek: rodzaj ula)
            ? rodzajDoInfo
            : matkaID > 0 //jezeli jest ID matki a jak nie ma to ''
              ?  matkaID.toString()
              :'',
          '${temp.toStringAsFixed(0)}$stopnie', //temperatura zaokrąglona do 1 stopnia
          formatedTime, //czas
          '', //uwagi
          0); //niezarchiwizowane
      // print('voice_screen: zapis Info do bazy ?????????????????????????????');

      // print(
      //     'zapis Hive do bazy: korpus = $korpusNr, kat = $kat, param = $param, wart = $wart, miar = $miar *******************');

      //jezeli wpis  dotyczy leczenia lub dokarmiania lub matki
      if (kat == 'feeding' || kat == 'treatment' || kat == 'queen') {
        //to dla dokarmiania lub leczena
        if (kat == 'feeding' || kat == 'treatment')
          korpusNr = 0; //blokada wyswietlania przeladu w belce
        
        int tempKorpusNr = 0; //wyjątkowo, potrzebne dla aktualizacji info o matce

        //zeby nie stracić danych zebranych podczas przeglądu w widoku zbiorczym uli
      Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrXXOfApiary)
      .then((_) {
          final hiveData = Provider.of<Hives>(context, listen: false);
          hive = hiveData.items.where((element) {
            //to wczytanie danych ula
            return element.id == ('$nrXXOfApiary.$nrXXOfHive');
          }).toList();
  
        if (hive.isNotEmpty) {
          //pobranie danych o ulu
          ikona = hive[0].ikona;
          ramek = hive[0].ramek;
          tempKorpusNr = hive[0].korpusNr; //wyjątkowo, potrzebne dla aktualizacji info o matce
          trut = hive[0].trut;
          czerw = hive[0].czerw;
          larwy = hive[0].larwy;
          jaja = hive[0].jaja;
          pierzga = hive[0].pierzga;
          miod = hive[0].miod;
          dojrzaly = hive[0].dojrzaly;
          weza = hive[0].weza;
          susz = hive[0].susz;
          matka = hive[0].matka;
          mateczniki = hive[0].mateczniki;
          usunmat = hive[0].usunmat;
          todo = hive[0].todo;
          matka1 = hive[0].matka1;
          matka2 = hive[0].matka2;
          matka3 = hive[0].matka3;
          matka4 = hive[0].matka4;
          matka5 = hive[0].matka5;
          rodzajUla = hive[0].h1;
          typUla = hive[0].h2;
          tagNFC = hive[0].h3;
        } else {
          korpusNr = 0;
        }
          // print(
          //         'info poczatek dla jednego ${hive[0].ulNr}: t${hive[0].trut}, c${hive[0].czerw}, l${hive[0].larwy}, j${hive[0].jaja}, p${hive[0].pierzga}, m${hive[0].miod}, d${hive[0].dojrzaly},w${hive[0].weza}, s${hive[0].susz}, m${hive[0].matka}, mt${hive[0].mateczniki}, dm${hive[0].usunmat} , td${hive[0].todo} m1${hive[0].matka1} m2${hive[0].matka2} m3${hive[0].matka3} m4${hive[0].matka4} m5${hive[0].matka5}');
         
        //jezeli info jest o matce
        if (kat == 'queen') {
          korpusNr = tempKorpusNr; //zeby nie stracić belki z przegledem jezeli jest
//Quality - matka1
          if (param == AppLocalizations.of(context)!.queen + '  ' +  AppLocalizations.of(context)!.isIs) 
            //jakość matki znają queen_helpers - lista literałów łapała tylko polski
            //i angielski, więc np. niemieckie "zu ersetzen" szło na kciuk w górę
            if (qualityIsBad(wart)) {
              matka1 = 'zła';
              if (ikona == 'red') {//bo był brak matki                
                ikona = 'orange';
                // globals.ikonaPasieki = 'orange';
              }
              if (matka2 == 'brak') matka2 = '';
            } else {
              matka1 = 'ok';
              if (ikona == 'red') {//bo był brak matki                
                ikona = 'orange';
                // globals.ikonaPasieki = 'orange';
              }
              if (matka2 == 'brak') matka2 = '';
            }
//Mark + Number
          if (param == " " + AppLocalizations.of(context)!.queen){
            switch (wart) {
              case 'nie ma znak': matka2 = 'niez'; //nieznaczona
                break;
              case 'unmarked': matka2 = 'niez'; //nieznaczona
                break;
              case 'ma inny znak': matka2 = 'inny ' + miar; //kolor + numer matki
                break;
              case 'marker other': matka2 = 'inny ' + miar; //kolor + numer matki
                break;
              case 'ma biały znak': matka2 = 'biał ' + miar; //kolor + numer matki
                break;
              case 'marker white': matka2 = 'biał ' + miar; //kolor + numer matki
                break;
              case 'ma żółty znak': matka2 = 'żółt ' + miar; //kolor + numer matki
                break;
              case 'marked yellow': matka2 = 'żółt ' + miar; //kolor + numer matki
                break;
              case 'ma czerwony znak': matka2 = 'czer ' + miar; //kolor + numer matki
                break;
              case 'marked red': matka2 = 'czer ' + miar; //kolor + numer matki
                break;
              case 'ma zielony znak': matka2 = 'ziel ' + miar; //kolor + numer matki
                break;
              case 'marked green': matka2 = 'ziel ' + miar; //kolor + numer matki
                break;
              case 'ma niebieski znak': matka2 = 'nieb ' + miar; //kolor + numer matki
                break;
              case 'marked blue': matka2 = 'nieb ' + miar; //kolor + numer matki
                break;
              case 'nie ma': matka2 = 'brak'; matka1 = ''; matka3 = ''; matka4 = '';matka5 = '';
                ikona = 'red';
                // globals.ikonaPasieki = 'red';
                break;
              case 'missing': matka2 = 'brak'; matka1 = ''; matka3 = ''; matka4 = '';matka5 = '';
                ikona = 'red';
                // globals.ikonaPasieki = 'red';
                break;
              case 'brak': matka2 = 'brak'; matka1 = ''; matka3 = ''; matka4 = ''; matka5 = '';
                ikona = 'red';
                // globals.ikonaPasieki = 'red';
                break;
            }
          }
          if (param == AppLocalizations.of(context)!.queen + " -") //State
            // 'virgine' dopisane 03.09.2026: _ujednolicWartosciSlotow zapisuje
            // teraz dla angielskiego l10n.virgine ("virgine", literówka w ARB),
            // nie surowe "virgin" - to porównanie musi znać obie formy.
            if (wart == 'dziewica' || wart == 'virgin' || wart == 'virgine') {
              matka3 = 'nieunasienniona';
              if (ikona == 'red') { //bo był brak matki
                ikona = 'orange';
                // globals.ikonaPasieki = 'orange';
              }
              if (matka2 == 'brak') matka2 = '';
            } else {
              matka3 = 'unasienniona';
              if (ikona != 'yellow') { //jezeli nie toDo
                ikona = 'green';
                // globals.ikonaPasieki = 'green'; 
              }
              if (matka2 == 'brak') matka2 = '';
            }

          if (param == AppLocalizations.of(context)!.queenIs) //Start
            if (wart == 'wolna' || wart == 'freed'){
              matka4 = 'wolna';
              if (ikona == 'red') {//bo był brak matki
                ikona = 'orange';
                // globals.ikonaPasieki = 'orange';
              }
              if (matka2 == 'brak') matka2 = '';
            } else{
              matka4 = 'ograniczona';
              if (ikona == 'red') {  //bo był brak matki
                ikona = 'orange';
                // globals.ikonaPasieki = 'orange';
              }
              if (matka2 == 'brak') matka2 = '';
            }

          if (param == AppLocalizations.of(context)!.queenWasBornIn){ //Born
            matka5 = wart;
            if (ikona == 'red') {
              //bo był brak matki
              ikona = 'orange';
              // globals.ikonaPasieki = 'orange';
            }
            if (matka2 == 'brak') matka2 = '';
          }
        }

        //wpis do tabeli "ule"
        Hives.insertHive(
          '$nrXXOfApiary.$nrXXOfHive',
          nrXXOfApiary, //pasieka nr
          nrXXOfHive, //ul nr
          formattedDate, //przeglad
          ikona, //ikona
          ramek, //ramek - ilość ramek w korpusie
          korpusNr,
          trut,
          czerw,
          larwy,
          jaja,
          pierzga,
          miod,
          dojrzaly,
          weza,
          susz,
          matka,
          mateczniki,
          usunmat,
          todo,
          kat,
          param,
          wart,
          miar,
          matka1,
          matka2,
          matka3,
          matka4,
          matka5,
          rodzajUla,
          typUla,
          tagNFC,
          0,
        ).then((_) {
          //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
          Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrXXOfApiary,)
          .then((_) {
            final hivesData = Provider.of<Hives>(context, listen: false);
            final hives = hivesData.items;
            ileUli = hives.length;
            //print('voice_screen - ilość uli = $ileUli');
            // print(hives.length);
            // print(ileUli);

            //ilość uli zlikwidowanych  - do obliczenia nilości uli w pasiece
            final hiveZlikwidowane = hivesData.items.where((element) {
                    return element.ikona == ('black');
                  }); 

            //zapis do tabeli "pasieki"
            Apiarys.insertApiary(
              '$nrXXOfApiary',
              nrXXOfApiary, //pasieka nr
              ileUli - hiveZlikwidowane.length, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
              formattedDate, //przeglad
              globals.ikonaPasieki, //ikona nie zmieniana w tym skrypcie
              '??', //opis
            ).then((_) {
              Provider.of<Apiarys>(context, listen: false)
                  .fetchAndSetApiarys()
                  .then((_) {
                //print( 'voice_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy po insertHive');
              });
            });
          });
        });
      });
      _playSuccess();
         // print('beep - success - zapis Info do bazy');

      }else{
        _playSuccess();
          // print('beep - success - zapis Info do bazy');
      }
    }
  }

  resetSumowania() {
    korpusNr = 0;
    trut = 0;
    czerw = 0;
    larwy = 0;
    jaja = 0;
    pierzga = 0;
    miod = 0;
    dojrzaly = 0;
    weza = 0;
    susz = 0;
    matka = 0;
    mateczniki = 0;
    usunmat = 0;
    todo = '';
  }

  resetBody() {
    //print('kasowanie body');
    nrXOfBody = 0;
    nrXOfBodyTemp = 0;
    nrXOfHalfBody = 0;
    nrXOfHalfBodyTemp = 0;
    frameState = AppLocalizations.of(context)!.close;
    readyFrame = false;
    nrXXOfFrame = 0;
    nrXXOfFramePo = 0;
    readyFrames = false;
    nrXXOdFrame = 0;
    nrXXDoFrame = 0;
  }

  resetFrame() {
    readyFrame = false;
    nrXXOfFrame = 0;
    nrXXOfFramePo = 0;
    readyFrames = false;
    nrXXOdFrame = 0;
    nrXXDoFrame = 0;
  }

  resetStory() {
    //print('resetowanie Store');
    resetInfo();
    readyInfo = false;
    readyStory = false;
    honey = '0';
    honeySeald = '0';
    pollen = '0';
    brood = '0';
    larvae = '0';
    eggs = '0';
    wax = '0';
    waxComb = '0';
    queen = '0';
    queenCells = '0';
    delQCells = '0';
    drone = '0';
    toDo = '';
    isDone = '';
  }

  resetInfo() {
    syrup1to1I = '0';
    syrup1to1D = '0';
    syrup3to2I = '0';
    syrup3to2D = '0';
    candyI = '0';
    candyD = '0';
    invertI = '0';
    invertD = '0';
    removedFood = '0';
    leftFood = '0';
    queenNumber = '';
    queenAlpha1 = '';
    queenAlpha2 = '';
    queenMark = '';
    varroaH = '';
    varroaXX = '';
    beePollenHarvestHML = '';
    beePollenHarvestML = '';
    beePollenHarvestI = '';
    beePollenHarvestD = '';
    acidH = '';
    acidXX = '';
    deadBeeHML = '';
    deadBeeML = '';
  }

  //Nasłuch startuje sam przy wejściu na ekran i nie ma przycisku START -
  //sesję komend otwiera "Hej Maja start", a zamyka "Hej Maja stop"
  //(_startSesji / _stopSesji przy warstwie wejścia). Ikona na pasku pokazuje
  //stan i służy jako ręczna awaryjna alternatywa, gdy w pasiece jest za głośno.

  beep(m) {
    switch (m) {
      case 'close':
        _pendingOpenBeep = false; //zamknięcie kasuje odroczone 'okej'
        _zagraj('close');
        break;
      case 'open':
        //nie gramy od razu - odraczamy do końca przetwarzania inferencji
        //dzięki temu gdy po pętli slotów pojawi się 'zapisałam' (success),
        //nie usłyszymy 'okej' + 'zapisałam' tylko samo 'zapisałam'
        _pendingOpenBeep = true;
        break;
      case 'error':
        _pendingOpenBeep = false; //błąd kasuje odroczone 'okej'
        _zagraj('nie_rozumiem');
        break;
    }
  }

  //potwierdź zapis i skasuj ewentualne odroczone potwierdzenie (to je wypiera)
  void _playSuccess() {
    _pendingOpenBeep = false;
    //_zagraj('success'); //zmiana do testów bo jest za długie
    _beepPotwierdzenia(); //było _zagraj('open') = okej.mp3
  }

  //odtwórz odroczone potwierdzenie, jeżeli nic innego go nie wyparło
  void _flushPendingOpenBeep() {
    if (_pendingOpenBeep) {
      _pendingOpenBeep = false;
      _beepPotwierdzenia();
    }
  }

//funkcje getDaty i getKorpusy potrzebne dla funkcji "pokaz ul"
//pobranie listy ramek z unikalnymi datami dla wybranego ula i pasieki z bazy lokalnej
  Future<List<Frame>> getDaty(pasieka, ul) async {
    final dataList = await DBHelper.getDate(pasieka, ul); //numer wybranego ula
    //print('getDaty: pasieka $pasieka ul $ul');
    _daty = dataList
        .map(
          (item) => Frame(
            id: '0', //data bo jak id to problem !!!
            data: item['data'],
            pasiekaNr: 0,
            ulNr: 0,
            korpusNr: 0,
            typ: 0,
            ramkaNr: 0,
            ramkaNrPo: 0,
            rozmiar: 0,
            strona: 0,
            zasob: 0,
            wartosc: '0',
            arch: 0,
          ),
        )
        .toList();
    //print('daty = $_daty');
    return _daty;
  }

  //pobranie listy ramek z unikalnymi korpusami dla wybranego ula i pasieki z bazy lokalnej
  Future<List<Frame>> getKorpusy(pasieka, ul, data) async {
    final dataList = await DBHelper.getKorpus(
        pasieka, ul, data); //numer wybranego ula, pasieki i wybranej daty
    _korpusy = dataList
        .map(
          (item) => Frame(
            id: '0', //korpusNr bo jak id to problem !!!
            data: '0',
            pasiekaNr: 0,
            ulNr: 0,
            korpusNr: item['korpusNr'],
            typ: item['typ'],
            ramkaNr: 0,
            ramkaNrPo: 0,
            rozmiar: 0,
            strona: 0,
            zasob: 0,
            wartosc: '0',
            arch: 0,
          ),
        )
        .toList();
    return _korpusy;
  }

  //okno dialogowe pokazujące ul po przeglądzie - polecenie "ul (wczesniej,później) pomóz mi"
  Future<void> _dialogBuilderHive(BuildContext context) {
    final framesData = Provider.of<Frames>(context, listen: false);
    //ramki z wybranej daty dla ula
   
    List<Frame> frames = [];
    if(_ulPo)
      frames = framesData.items.where((fr) {
        return fr.data == (wybranaData) && fr.ramkaNrPo > 0; //tylko ramki "Po" 
      }).toList();
    else
      frames = framesData.items.where((fr) {
        return fr.data == (wybranaData) && fr.ramkaNr > 0; //tylko ramki "Po" 
      }).toList();
    // print(
    //     'frames_screen - ilość stron ramek w pasiece ${globals.pasiekaID} ulu ${globals.ulID}');
    // print(frames.length);

    // // var frame = Provider.of<Frames>(context);
    // print(' frames - dane z bazy::::::::::::::::::::');
    // for (var i = 0; i < frames.length; i++) {
    //   print(
    //       '${frames[i].id},${frames[i].data},${frames[i].pasiekaNr},${frames[i].ulNr},${frames[i].korpusNr},${frames[i].typ},${frames[i].ramkaNr},${frames[i].rozmiar}');
    //   print('${frames[i].strona},${frames[i].zasob},${frames[i].wartosc}');
    //   print('-----');
    // }

    //info z wybranej daty dla ula
    final infosData = Provider.of<Infos>(context, listen: false);
    List<Info> infos = infosData.items.where((inf) {
      return inf.data == (wybranaData);
    }).toList();
    // print(' infos  - dane z bazy::::::::::::::::::::');
    // for (var i = 0; i < infos.length; i++) {
    //   print(
    //       '${infos[i].id},${infos[i].data},${infos[i].pasiekaNr},${infos[i].ulNr},${infos[i].kategoria},${infos[i].parametr},${infos[i].wartosc},${infos[i].miara}');
    //   print('=======');
    // }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: Column(children: <Widget>[
                SizedBox(height: 10),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _ulPo 
                        ? Text(AppLocalizations.of(context)!.after)
                        : Text(AppLocalizations.of(context)!.before),
                      Text('  ${_daty[indexDaty].data}',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                SizedBox(height: 10),
                Container(
                  //szare body
                  //alignment: Alignment.center,
                  color: Color.fromARGB(173, 173, 173, 173),
                  // ignore: sort_child_properties_last
                  child: CustomPaint(
                    painter: MyHive(
                        ulPo: _ulPo,
                        ramki: frames,
                        korpusy: _korpusy,
                        width: widthCanvas,
                        high: highCanvas,
                        informacje: infos),
                    size: Size(widthCanvas, highCanvas),
                  ),
                  margin: EdgeInsets.all(10),
                  //padding: EdgeInsets.all(10),
                ),
              ]),
              //rysunek ula z ostatniego przeglądu
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.closeHelp),
              onPressed: () {
                Navigator.of(context).pop();
                openDialog = false;
              },
            ),
          ],
        );
      },
    );
  }

  // void onPlayAudio(String path) async {
  //   AudioPlayer audioPlayer = AudioPlayer();
  //   await audioPlayer.play(path, isLocal: true);
  // }

  @override
  Widget build(BuildContext context) {
    //przekazanie hiveId z hive_item za pomocą navigatora
    //final hiveId = ModalRoute.of(context)!.settings.arguments as String; // is the id!

//dla mniejszych ekranów zmiana wysokośći wiersza  'Save' - zapis zasobu do bazy
//sony Z3 592px, mały ios 568px
//
//UWAGA na pasmo 590-600 px (Sony Z3 = 592). Ta korekta pochodzi z czasów, gdy
//wariant "mały" wybierał warunek `heightScreen < 590` i takie ekrany dostawały
//wariant DUŻY (fontSize 20) w niższym kontenerze. Od 14.08.2026 decyduje
//[_maleWiersze] liczone z miejsca, które treść naprawdę dostała, i te ekrany idą
//już wariantem małym - korekta zostaje jako zabezpieczenie na wypadek, gdyby
//wariant duży trafił tam mimo wszystko (inny rozkład stref, mniejszy pasek
//tytułu). A tekst `zapis` zawija się na dwie linie - najdłuższe
//komunikaty info to np. "rodzina jest w nastroju do ucieczki" (34 znaki), matka ze
//znakiem i numerem, osyp pszczół, a po niemiecku/francusku prawie każdy dłuższy
//zwrot. Przy 60 px druga linia wychodziła poza kontener (pasy przepełnienia).
//
//RACHUNEK NA DWIE LINIE - POPRAWIONY 15.08.2026. Poprzedni ("dwie linie
//pogrubionej dwudziestki 2 * ~23 => 77 px, stąd 80") był ZANIŻONY, bo zakładał
//wysokość linii ~1,15. Tymczasem style tych tekstów ustawiają SAM `fontSize`,
//a `height` dziedziczą po `bodyMedium` Material 3, gdzie wynosi **1,43**:
//linia dwudziestki to 28,6 px, a nie 23. Z etykietą wychodzi 77,2 px czystego
//tekstu, więc 80 px pudełka (minus obwódka 6 i padding 10 + 3) NIE mogło
//wystarczyć. Teraz teksty `zapis` mają `height: 1.2` podane jawnie, a pudełka
//własne wysokości - i jedno, i drugie opisane przy nich samych. Ta korekta
//pasma podnosi więc 80 na 90. Strefa 1 przewija się w środku
//(SingleChildScrollView), a `_kStrefaDanych` liczy dla tego wiersza 110 px.
    heightScreen = MediaQuery.of(context).size.height;
    // print('wysokość ekranu');
    // print(heightScreen);
    if (heightScreen < 600 && heightScreen > 590) {
      hightSave = 90;
      marginRow = 7;
    }
    //dane z bazy
    //final framesData = Provider.of<Frames>(context);
    //List<Frame> frames = framesData.items.toList();

    // print('voice_screen: początek budowy ekranu - dane z bazy:::::');
    // for (var i = 0; i < frames.length; i++) {
    //   print('${frames[i].id}');
    //   print(
    //       '${frames[i].data},${frames[i].pasiekaNr},${frames[i].ulNr},${frames[i].korpusNr},${frames[i].typ},${frames[i].ramkaNr},${frames[i].rozmiar}');
    //   print('${frames[i].strona},${frames[i].zasob},${frames[i].wartosc}');
    //   print('-----');
    // }

//var frame = Provider.of<Frames>(context, listen: false).fetchAndSetFrames().then((_) {
    //    print('wczytanie danych');
    // });
    //    frame = frameData.items.where((fr) {
    //      return fr.pasiekaId.contains('1');
    //   }).toList();

   

//print('if ($matka1 != '' || $matka2 != '' || $matka3 != '' || $matka4 != '' || $matka5 != '' )');
 //print ('ekran voice (readyApiary $readyApiary && readyHive $readyHive && nrXXOfHive != 0 $nrXXOfHive && nrXXOfApiary != 0 $nrXXOfApiary) ');

      //zeby pokazać dane matki na ekranie voice
    if(readyApiary && readyHive && nrXXOfApiary != 0 && nrXXOfHive != 0 && nrXXOfApiary != 0){  
      Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrXXOfApiary,)
      .then((_) {       
        final hiveData = Provider.of<Hives>(context, listen: false);
        hive = hiveData.items.where((element) {
          //to wczytanie danych ula jezeli został otwarty
          return element.id == ('$nrXXOfApiary.$nrXXOfHive');
        }).toList();
            // print('voice hive (${hive[0].matka1} != '' || ${hive[0].matka2} != '' || ${hive[0].matka3} != '' || ${hive[0].matka4} != '' || ${hive[0].matka5} != '' )');
            // print(
            //       ' voice hive ${hive[0].ulNr}: t${hive[0].trut}, c${hive[0].czerw}, l${hive[0].larwy}, j${hive[0].jaja}, p${hive[0].pierzga}, m${hive[0].miod}, d${hive[0].dojrzaly},w${hive[0].weza}, s${hive[0].susz}, m${hive[0].matka}, mt${hive[0].mateczniki}, dm${hive[0].usunmat} , td${hive[0].todo} m1${hive[0].matka1} m2${hive[0].matka2} m3${hive[0].matka3} m4${hive[0].matka4} m5${hive[0].matka5}');
      //print('widget "build" uruchomiony - mozna działać !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      //czyJesWidget = true;   
      }); 
    }

print('openDialog = $openDialog');
    return MaterialApp(
      home: Scaffold(
        //BIAŁE TŁO JAWNIE. Ten ekran opakowuje się we WŁASNY [MaterialApp] bez
        //motywu, więc nie dziedziczy `scaffoldBackgroundColor` z main.dart i
        //dostawał domyślny motyw Material 3: `surface` = jasny róż (#FEF7FF).
        //Widać go było wszędzie tam, gdzie nie sięga biały kontener strefy -
        //w poziomie na lewej kolumnie i pod obszarem komunikatów.
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            AppLocalizations.of(context)!.voiceControlSmall,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          // backgroundColor: Color.fromARGB(255, 233, 140, 0),
          // title: Text('Voice Control'),
          // //automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () => {
              WakelockPlus.disable(), //usunięcie blokowania wygaszania ekranu
              Navigator.of(context).pop()
            },
          ),
          actions: <Widget>[
            //WSKAŹNIK STANU, nie przycisk startu: mikrofon pracuje od wejścia
            //na ekran. Czerwona kropka = sesja komend otwarta ("Hej Maja
            //start"), zielone ucho = czuwanie. Dotknięcie robi to samo co
            //komenda - awaryjnie, gdy w pasiece jest za głośno na rozpoznanie.
            //W stanie awarii (przekreślony mikrofon) dotknięcie PONAWIA próbę
            //odzyskania mikrofonu - wcześniej ikona była tu martwa i jedynym
            //wyjściem po rozmowie telefonicznej było opuszczenie ekranu.
            //DYKTOWANIE MA WŁASNĄ IKONĘ, i to właśnie tutaj, w pasku tytułu:
            //jest widoczna w KAŻDYM układzie ekranu. Podgląd notatki i pasek
            //stanu potrafią zniknąć razem z sekcją tekstową (live podgląd
            //korpusu), a użytkownik musi wiedzieć, że mikrofon nagrywa notatkę,
            //a nie czeka na komendę. Zgłoszenie z 03.08.2026: po „Hej Maja
            //zanotuj" ekran wyglądał identycznie jak przed nią.
            IconButton(
              icon: Icon(
                _dyktuje
                    ? Icons.edit_note
                    : ((isError || _mikrofonMilczy)
                        ? Icons.mic_off
                        : (isProcessing ? Icons.mic : Icons.hearing)),
                color: _dyktuje
                    ? Color.fromARGB(255, 0, 90, 200)
                    : ((isError || _mikrofonMilczy)
                        ? Color.fromARGB(255, 200, 0, 0)
                        : (isButtonDisabled
                            ? Colors.grey
                            : (isProcessing
                                ? Color.fromARGB(255, 200, 0, 0)
                                : Color.fromARGB(255, 0, 150, 0)))),
                size: 30,
              ),
              tooltip: _dyktuje
                  ? 'Dyktuję notatkę — dotknij, by zakończyć'
                  : ((isError || _mikrofonMilczy)
                      ? 'Mikrofon niedostępny — dotknij, by spróbować ponownie'
                      : (isProcessing
                          ? 'Słucham poleceń — „Hej Maja stop"'
                          : 'Czuwam — „Hej Maja start"')),
              //lambda, nie referencja: obie gałęzie muszą mieć ten sam typ
              //void Function(), inaczej wnioskowanie nie da VoidCallback?
              onPressed: (isError || _mikrofonMilczy)
                  ? () {
                      _odzyskajMikrofon();
                    }
                  : (isButtonDisabled ? null : _przelaczSesjeRecznie),
            ),
            IconButton(
              icon:
                  Icon(Icons.help_center, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () => pomocPelna(context, poZamknieciu: () => openDialog = false),
            )
          ],
        ),
        //TRZY STREFY - podział zależy od tego, czy live podgląd korpusu jest
        //włączony, i od orientacji. Wysokości liczymy z [LayoutBuilder], bo
        //strefa 2 musi znać miejsce, którym dysponuje: dopiero wtedy wie, czy
        //korpus mieści się w skali 1:1, czy trzeba go zmniejszyć.
        body: LayoutBuilder(
          builder: (BuildContext ctx, BoxConstraints wymiary) {
            final double wysokosc = wymiary.maxHeight;
            final bool poziom =
                MediaQuery.of(context).orientation == Orientation.landscape ||
                    globals.voice2LiveLandscape;

            //WYBÓR WARIANTU WIERSZY STREFY 1 (14.08.2026). Do tej pory decydowała
            //stała `heightScreen < 590`, czyli WYSOKOŚĆ CAŁEGO EKRANU - liczba
            //zgadnięta z dwóch urządzeń (mały iPhone 568, Sony Z3 592). Dawała
            //dwa błędne wyniki:
            //  * w POZIOMIE warunek celowo wykluczał orientację landscape, więc
            //    wychodził wariant duży - a strefa 1 jest tam wąską lewą kolumną
            //    i pudełka 100 px z cyframi 50 px wchodziły na siebie;
            //  * w PIONIE na telefonach z ekranem wyższym od 590 px, ale nie na
            //    tyle wysokim, żeby zmieścić pełny układ (zgłoszenie z Samsunga),
            //    wychodził wariant duży, po czym strefy jechały w dół skalowaniem
            //    proporcjonalnym - czyli i tak było ciasno, tylko brzydziej.
            //Teraz pytamy o to, co naprawdę mamy: czy DUŻY układ mieści się w
            //wysokości, którą dostała treść ekranu (`wymiary.maxHeight`, czyli
            //bez paska tytułu i statusu). Jeżeli nie - od razu bierzemy wariant
            //mały, który do 624 px schodzi bez żadnego skalowania.
            //
            //SKALA CZCIONKI SYSTEMOWEJ wchodzi do rachunku, bo pudełka mają
            //STAŁE wysokości, a teksty w nich rosną razem z ustawieniem
            //"rozmiar czcionki" w systemie (na Androidzie to zwykłe ustawienie
            //ekranu, nie funkcja dostępności - dlatego bywa podniesione).
            final double skalaTekstu =
                MediaQuery.textScalerOf(context).scale(14) / 14;
            //UKŁAD KLASYCZNY dzieli wysokość proporcjami (strefa 1 to Expanded
            //flex 4 z sześciu), a układ z live podglądem daje strefie 1 stałe
            //`_kStrefaDanych` obok korpusu i minimum tekstów - stąd dwa progi.
            final double potrzebaNaDuze = globals.voice2LivePodglad
                ? _kStrefaDanych + _kStrefaKorpusu + 2 + _kMinStrefaTekstu
                : _kStrefaDanych * 6 / 4;
            _maleWiersze =
                poziom || wysokosc < potrzebaNaDuze * math.max(1.0, skalaTekstu);

            //UKŁAD KLASYCZNY (bez live podglądu) - bez zmian: dane u góry,
            //teksty z notatką do czterech linii, na dole błąd silnika.
            if (!globals.voice2LivePodglad) {
              return Column(
                children: [
                  buildAnswerArea(context),
                  //buildStartButton(context),
                  buildRhinoTextArea(context),
                  buildErrorMessage(context),
                ],
              );
            }

            //UKŁAD POZIOMY: lewa kolumna to strefa 1, prawa to strefa 2 nad
            //strefą 3. Teksty siedzą POD korpusem, a nie w lewym panelu - dane
            //komendy i komunikaty silnika to dwie różne rzeczy i mieszanie ich
            //w jednej kolumnie kazało szukać komunikatu wśród numerów ramek.
            if (poziom) {
              //w poziomie strefa 1 jest całą lewą kolumną - jej wysokość i tak
              //wyznacza ekran, więc stała dotyczy tylko strefy korpusu
              final double strefaKorpusu = math.min(
                  _kStrefaKorpusu, wysokosc - _kMinStrefaTekstu);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: buildAnswerArea(context, flex: false),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        buildKorpusArea(context, maxWysokosc: strefaKorpusu),
                        _kreska(),
                        //STREFA 3. Do 03.08.2026 układ z live podglądem nie
                        //budował ani [buildRhinoTextArea], ani
                        //[buildErrorMessage] - miejsce zajmował korpus - więc
                        //dyktowanie notatki było w nim CAŁKOWICIE nieme.
                        //Teraz strefa ma własne, stałe miejsce i nic go jej nie
                        //zabiera.
                        Expanded(
                          child: SingleChildScrollView(
                            child: buildPasekStanu(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            //UKŁAD PIONOWY z live podglądem: strefy 1 i 2 mają STAŁE wysokości
            //(_kStrefaDanych, _kStrefaKorpusu), a cała reszta ekranu należy do
            //tekstów. Wcześniej strefy dzieliły się procentami wysokości i
            //kurczyły do treści, więc bez otwartej pasieki wszystko podjeżdżało
            //do góry, a po pierwszej komendzie układ się przestawiał.
            //Na bardzo niskich ekranach obie stałe naraz mogą się nie zmieścić
            //(304 + 254 + kreski + minimum tekstów) - wtedy skracamy je
            //PROPORCJONALNIE, zostawiając strefie 3 jej minimum. Wysokość dalej
            //jest stała dla danego urządzenia, więc nic nie skacze: strefa 1
            //przewija się w środku, a korpus zmniejsza [FittedBox].
            double strefaDanych =
                _maleWiersze ? _kStrefaDanychMala : _kStrefaDanych;
            double strefaKorpusu = _kStrefaKorpusu;
            final double doPodzialu = wysokosc - 2 - _kMinStrefaTekstu; //2 kreski
            if (strefaDanych + strefaKorpusu > doPodzialu && doPodzialu > 0) {
              final double skala = doPodzialu / (strefaDanych + strefaKorpusu);
              strefaDanych = strefaDanych * skala;
              strefaKorpusu = strefaKorpusu * skala;
            }
            return Column(
              children: [
                SizedBox(
                  height: strefaDanych,
                  child: SingleChildScrollView(
                    child: buildAnswerArea(context, flex: false),
                  ),
                ),
                _kreska(),
                buildKorpusArea(context, maxWysokosc: strefaKorpusu),
                _kreska(),
                Expanded(
                  child: SingleChildScrollView(
                    child: buildPasekStanu(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
   
  }

  
  
  //SZEROKOŚĆ, jakiej potrzebuje wiersz "ul / korpus / półkorpus / ramka".
  //Pudełka tego wiersza mają SZTYWNE szerokości, a [Row] ze `spaceEvenly` nie
  //ma jak ich zwęzić - przy braku miejsca po prostu wychodzą poza kontener
  //i nachodzą na siebie. W pionie miejsca starczało zawsze, ale w POZIOMIE
  //strefa 1 jest tylko lewą połową ekranu: na małym iPhonie (568 x 320) to
  //ok. 250 px, a same trzy pudełka to 260 px w wariancie małym i 300 w dużym.
  //Liczymy więc, ile wiersz naprawdę zajmie - widoczność każdego pudełka
  //wynika z tych samych flag `ready*`, którymi są w wierszu obudowane.
  //UWAGA: te liczby MUSZĄ się zgadzać z `width:` pudełek niżej.
  double _szerokoscWierszaUla() {
    double suma = 0;
    if (readyHive) suma += _maleWiersze ? 80 : 100;
    if (readyBody) suma += 100;
    if (readyHalfBody) suma += 100;
    if (readyFrame) suma += _maleWiersze ? 80 : 100;
    if (readyFrames) suma += _maleWiersze ? 80 : 100;
    return suma;
  }

  //Wiersz zostaje BEZ ZMIAN, dopóki się mieści - dopiero gdy zabraknie
  //szerokości, całość zjeżdża proporcjonalnie w dół ([FittedBox]). Wtedy
  //pudełka stykają się bokami i są niższe, ale wszystkie są widoczne w całości.
  //Skalowanie w dół nie psuje budżetu strefy 1: wiersz może być tylko niższy
  //niż policzone dla niego 112 px (duży) / 80 px (mały).
  Widget _dopasujWiersz(double potrzeba, Widget wiersz) {
    if (potrzeba <= 0) return wiersz;
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints c) =>
          potrzeba <= c.maxWidth
              ? wiersz
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: SizedBox(width: potrzeba, child: wiersz),
                ),
    );
  }

  buildAnswerArea(BuildContext context, {bool flex = true}) {
    //ODSTĘP NAD OBWÓDKĄ WIERSZA PASIEKI to górna część `padding` tego kontenera
    //(15 px; wewnątrz obwódki jest jeszcze własny padding wiersza). W poziomie
    //zdejmujemy go do zera: strefa 1 jest tam wąską lewą kolumną i każdy piksel
    //wysokości jest potrzebny na wiersze, a odstęp od paska tytułu daje już sam
    //AppBar. W pionie zostaje 15 px - tam miejsca nie brakuje, a wiersz pasieki
    //wklejony w pasek tytułu wyglądałby na jego przedłużenie.
    final bool poziom =
        MediaQuery.of(context).orientation == Orientation.landscape ||
            globals.voice2LiveLandscape;
    final content = Container(
          color: Color.fromARGB(255, 255, 255, 255),
          alignment: Alignment.center,
          padding: EdgeInsets.fromLTRB(15, poziom ? 0 : 15, 15, 15),
          child: Column(
            children: [
            
//wiersz pasieka
              _maleWiersze
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (readyApiary)
                          Expanded(
                            child: Container(
                              height: 40,
                              //PIONOWO NA ŚRODKU (15.08.2026). Było
                              //`topCenter` + padding górny 1: tekst 17 px zajmuje
                              //ok. 24 px z 33 px wnętrza, więc pod spodem zostawało
                              //9 px pustego i wiersz wyglądał na przyklejony do
                              //górnej obwódki. Padding pionowy zdejmujemy do zera -
                              //centrowanie robi teraz `Alignment.center`, a nie
                              //ręcznie dobrana górna szpara.
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    //color: Colors.black,
                                    width: 3.0,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(20),
                                //color: Colors.yellowAccent,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  nrXXOfApiary != 0
                                      ? Text(
                                          AppLocalizations.of(context)!.apiary +
                                              " nr $nrXXOfApiary   ($formattedDate)",
                                          style: const TextStyle(
                                            fontSize: 17,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          softWrap: false, //zawijanie tekstu
                                          overflow: TextOverflow
                                              .fade, //skracanie tekstu
                                        )
                                      : Text(
                                          AppLocalizations.of(context)!.apiary +
                                              " nr $nrXXOfApiary - " +
                                              AppLocalizations.of(context)!
                                                  .invalidApiaryNumber,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color:
                                                Color.fromARGB(255, 255, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          softWrap: false, //zawijanie tekstu
                                          overflow: TextOverflow
                                              .fade, //skracanie tekstu
                                        ),
                                  //if (nrXXOfApiary == 0)  beep('error'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                 : 
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (readyApiary)
                          Expanded(
                            child: Container(
                              height: 45,
                              //PIONOWO NA ŚRODKU - patrz bliźniaczy wiersz
                              //w wariancie małym wyżej (tu tekst 20 px zostawiał
                              //5 px pustego pod spodem).
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    //color: Colors.black,
                                    width: 3.0,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(20),
                                //color: Colors.yellowAccent,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  nrXXOfApiary != 0
                                      ? Text(
                                          AppLocalizations.of(context)!.apiary +
                                              " nr $nrXXOfApiary   ($formattedDate)",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          softWrap: false, //zawijanie tekstu
                                          overflow: TextOverflow
                                              .fade, //skracanie tekstu
                                        )
                                      : Text(
                                          AppLocalizations.of(context)!.apiary +
                                              " nr $nrXXOfApiary - " +
                                              AppLocalizations.of(context)!
                                                  .invalidApiaryNumber,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color:
                                                Color.fromARGB(255, 255, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          softWrap: false, //zawijanie tekstu
                                          overflow: TextOverflow
                                              .fade, //skracanie tekstu
                                        ),
                                  //if (nrXXOfApiary == 0)  beep('error'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

//wiersz wszystkie ule

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                //wszystkie
                if (readyAllHives)
                  Expanded(
                    child: Container(
                      //width: 100,
                      height: 60,
                      margin: EdgeInsets.only(top: 10, bottom: 10),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border:
                            Border.all(width: 3.0, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          //Text(AppLocalizations.of(context)!.hive),
                          allHivesState != AppLocalizations.of(context)!.close
                              ? Text(
                                  //przy zakresie MUSI być widać granice: bez nich
                                  //ekran wygląda identycznie jak przy zapisie do
                                  //całej pasieki, a to dwie różne komendy
                                  _zakresUliAktywny
                                      ? '${AppLocalizations.of(context)!.hivesPlural} $nrXXOdHive-$nrXXDoHive'
                                      : AppLocalizations.of(context)!
                                          .allTheHivesAreOpen,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  softWrap: false, //zawijanie tekstu
                                  overflow:
                                      TextOverflow.fade, //skracanie tekstu
                                )
                              : Text(
                                  AppLocalizations.of(context)!
                                      .allHivesAreClose,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Color.fromARGB(255, 255, 0, 0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  softWrap: false, //zawijanie tekstu
                                  overflow:
                                      TextOverflow.fade, //skracanie tekstu
                                ),
                          //if (nrXXOfHive == 0)  beep('error'),
                        ],
                      ),
                    ),
                  ),
              ]),

//wiersz z ul, korpus ramka (o [_dopasujWiersz] patrz komentarz przy metodzie)
              _dopasujWiersz(_szerokoscWierszaUla(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
//ul numer
                if (readyHive)
                  _maleWiersze
                      ? Container(
                          width: 80,
                          height: 60,
                          margin: EdgeInsets.only(
                              top: marginRow, bottom: marginRow),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                width: 3.0, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(AppLocalizations.of(context)!.hive),
                              
                              nrXXOfHive != 0
                                  ? Text(
                                      "$nrXXOfHive",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 20,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    )
                                  : Text(
                                      "$nrXXOfHive",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 20,
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    ),
                            ],
                          ),
                        )
                      : 
                        Container(
                          width: 100,
                          height: 92,
                          margin: EdgeInsets.only(
                              top: marginRow, bottom: marginRow),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                width: 3.0, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(AppLocalizations.of(context)!.hive),
                                nrXXOfHive != 0
                                  ? nrXXOfHive < 100 //numer ula dwucyfrowy
                                    ? Text(
                                        "$nrXXOfHive",
                                        style: const TextStyle(
                                          height: 1.0,
                                          fontSize: 50,
                                          color: Color.fromARGB(255, 0, 0, 0),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        // softWrap: false, //zawijanie tekstu
                                        // overflow: TextOverflow.fade, //skracanie tekstu
                                      )
                                    : Text( //numer ula trzycyfrowy
                                        "$nrXXOfHive",
                                        style: const TextStyle(
                                          height: 1.0,
                                          fontSize: 40,
                                          color: Color.fromARGB(255, 0, 0, 0),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        // softWrap: false, //zawijanie tekstu
                                        // overflow: TextOverflow.fade, //skracanie tekstu
                                      )
                                  : Text(
                                      "$nrXXOfHive",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 50,
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    ),
                            ],
                          ),
                        
                        
                        ),
//korpus numer
                if (readyBody)
                  _maleWiersze
                      ? Container(
                          width: 100,
                          height: 60,
                          padding: const EdgeInsets.all(4),
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            border: Border.all(
                                width: 3.0, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(AppLocalizations.of(context)!.body),
                              nrXOfBody != 0
                                  ? Text(
                                      "$nrXOfBody",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 20,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      softWrap: false, //zawijanie tekstu
                                      overflow:
                                          TextOverflow.fade, //skracanie tekstu
                                    )
                                  : Text(
                                      "$nrXOfBody",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 20,
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      softWrap: false, //zawijanie tekstu
                                      overflow:
                                          TextOverflow.fade, //skracanie tekstu
                                    ),
                            ],
                          ),
                        )
                     : 
                      Container(
                          width: 100,
                          height: 92,
                          padding: const EdgeInsets.all(4),
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            border: Border.all(
                                width: 3.0, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(AppLocalizations.of(context)!.body),
                              nrXOfBody != 0
                                  ? Text(
                                      "$nrXOfBody",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 50,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    )
                                  : Text(
                                      "$nrXOfBody",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 50,
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    ),
                            ],
                          ),
                        ),
//półkorpus numer
                if (readyHalfBody)
                  _maleWiersze
                      ? Container(
                          width: 100,
                          height: 60,
                          padding: const EdgeInsets.all(4),
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            border: Border.all(
                                //color: Colors.black,
                                width: 3.0,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(AppLocalizations.of(context)!.halfBody),
                              nrXOfHalfBody != 0
                                  ? Text(
                                      "$nrXOfHalfBody",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 20,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    )
                                  : Text(
                                      "$nrXOfHalfBody",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 20,
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    ),
                            ],
                          ),
                        )
                     : 
                      Container(
                          width: 100,
                          height: 92,
                          padding: const EdgeInsets.all(4),
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            border: Border.all(
                                //color: Colors.black,
                                width: 3.0,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(AppLocalizations.of(context)!.halfBody),
                              nrXOfHalfBody != 0
                                  ? Text(
                                      "$nrXOfHalfBody",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 50,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    )
                                  : Text(
                                      "$nrXOfHalfBody",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 50,
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    ),
                            ],
                          ),
                        ),
                
//ramka numer
                if (readyFrame)
                  _maleWiersze
                      ? Container(
                          width: 80,
                          height: 60,
                          padding: const EdgeInsets.all(4),
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            border: Border.all(
                                //color: Colors.black,
                                width: 3.0,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                            //color: Colors.yellowAccent,
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(AppLocalizations.of(context)!.frame),
                              nrXXOfFrame != 0 || nrXXOfFramePo != 0
                                  ? Text(
                                      "$nrXXOfFrame/$nrXXOfFramePo",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 20,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    )
                                  : Text(
                                      "$nrXXOfFrame",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 20,
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    ),
                            ],
                          ),
                        )
                     : 
                      Container(
                          width: 100,
                          height: 92,
                          padding: const EdgeInsets.all(4),
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            border: Border.all(
                                //color: Colors.black,
                                width: 3.0,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                            //color: Colors.yellowAccent,
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(AppLocalizations.of(context)!.frame),
                              nrXXOfFrame != 0 || nrXXOfFramePo != 0
                                  ? Text(
                                      "$nrXXOfFrame/$nrXXOfFramePo",
                                      style: const TextStyle(
                                        //height: 1.0,
                                        fontSize: 30,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    )
                                  : Text(
                                      "$nrXXOfFrame",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 50,
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    ),
                            ],
                          ),
                        ),

//ramki od do
                if (readyFrames)
                  _maleWiersze
                      ? Container(
                          width: 80,
                          height: 60,
                          padding: const EdgeInsets.all(4),
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            border: Border.all(
                                //color: Colors.black,
                                width: 3.0,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                            //color: Colors.yellowAccent,
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(AppLocalizations.of(context)!.frames),
                              nrXXOdFrame != 0
                                  ? Text(
                                      "$nrXXOdFrame-$nrXXDoFrame",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 15,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    )
                                  : Text(
                                      "$nrXXOdFrame",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 20,
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    ),
                            ],
                          ),
                        )
                     : 
                      Container(
                          width: 100,
                          height: 92,
                          padding: const EdgeInsets.all(4),
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            border: Border.all(
                                //color: Colors.black,
                                width: 3.0,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(20),
                            //color: Colors.yellowAccent,
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(AppLocalizations.of(context)!.frames),
                              nrXXOdFrame != 0
                                  ? Text(
                                      "$nrXXOdFrame-$nrXXDoFrame",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 30,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    )
                                  : Text(
                                      "$nrXXOdFrame",
                                      style: const TextStyle(
                                        height: 1.0,
                                        fontSize: 50,
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // softWrap: false, //zawijanie tekstu
                                      // overflow: TextOverflow.fade, //skracanie tekstu
                                    ),
                            ],
                          ),
                        ),
              ])),

//informacje o  matce
              if (readyApiary && readyHive && nrXXOfHive != 0 && hive.isNotEmpty)
                 if(hive.isNotEmpty) 
                  Container(
                    margin: EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
  //wolna                      
                        if(hive.isNotEmpty && hive[0].matka4 == 'wolna')
                            Image.asset('assets/image/matka1.png',
                                width: 30, height: 20, fit: BoxFit.fill)
                        else if(hive[0].matka4 == 'ograniczona')
                          Image.asset('assets/image/matka11.png',
                              width: 30, height: 20, fit: BoxFit.fill),
                        if(hive.isNotEmpty && hive[0].matka4 != '' && hive[0].matka4 != '0')
                          SizedBox(width: 8),
  //ok //brak                    
                        if(hive.isNotEmpty && qualityIsSet(hive[0].matka1))
                          qualityIsBad(hive[0].matka1)
                            ? Icon(Icons.thumb_down_outlined,color: Color.fromARGB(255, 255, 0, 0),)
                            : Icon(Icons.thumb_up_outlined,color: Color.fromARGB(255, 15, 200, 8),),
                        if(hive.isNotEmpty && hive[0].matka1 != '' && hive[0].matka1 != '0')
                          SizedBox(width: 5),
  //unasienniona?                    
                        if(hive.isNotEmpty && hive[0].matka3 == 'unasienniona')                  
                          Icon(Icons.egg,color: Color.fromARGB(255, 15, 200, 8),)
                        else if(hive[0].matka3 == 'nieunasienniona') Icon(Icons.egg_outlined,color: Color.fromARGB(255, 255, 0, 0),), 
                        if(hive.isNotEmpty && hive[0].matka3 != '' && hive[0].matka3 != '0')
                          SizedBox(width: 5),
  //znak? numer?    
                        if(hive.isNotEmpty && hive[0].matka2 != '' && hive[0].matka2 != '0') 
                          if(hive.isNotEmpty && hive[0].matka2.substring(0, 4) == 'niez')
                            Icon(Icons.circle,color: Color.fromARGB(255, 61, 61, 61),)
                          else if(hive.isNotEmpty && hive[0].matka2 != '' && hive[0].matka2 != '0') if(hive[0].matka2.substring(0, 4) == 'brak')
                            Icon(Icons.dangerous_outlined,color: Color.fromARGB(255, 255, 0, 0))
                          else if(hive.isNotEmpty && hive[0].matka2 != '' && hive[0].matka2 != '0') if(hive[0].matka2.substring(0, 4) == 'inny')
                            Icon(Icons.check_circle_rounded,color: Color.fromARGB(255, 158, 166, 172),)
                          else if(hive.isNotEmpty && hive[0].matka2 != '' && hive[0].matka2 != '0') if(hive[0].matka2.substring(0, 4) == 'biał')
                            Icon(Icons.check_circle_outline_outlined,color: Color.fromARGB(255, 0, 0, 0),)
                          else if(hive.isNotEmpty && hive[0].matka2 != '' && hive[0].matka2 != '0') if(hive[0].matka2.substring(0, 4) == 'żółt')
                            Icon(Icons.check_circle_rounded,color: Color.fromARGB(255, 215, 208, 0),)
                          else if(hive.isNotEmpty && hive[0].matka2 != '' && hive[0].matka2 != '0') if(hive[0].matka2.substring(0, 4) == 'czer')
                            Icon(Icons.check_circle_rounded,color: Color.fromARGB(255, 255, 0, 0),)
                          else if(hive.isNotEmpty && hive[0].matka2 != '' && hive[0].matka2 != '0') if(hive[0].matka2.substring(0, 4) == 'ziel')
                            Icon(Icons.check_circle_rounded,color: Color.fromARGB(255, 15, 200, 8),)
                          else if(hive.isNotEmpty && hive[0].matka2 != '' && hive[0].matka2 != '0') if(hive[0].matka2.substring(0, 4) == 'nieb')
                            Icon(Icons.check_circle_rounded,color: Color.fromARGB(255, 0, 102, 255),),
                            
                        if(hive.isNotEmpty && hive[0].matka2 != '' && hive[0].matka2 != '0')
                          if(hive[0].matka2.substring(4) != '')
                            Text('${hive[0].matka2.substring(4)}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color.fromARGB(255, 69, 69, 69),
                              )),                    
  //rok urodzenia                   
                        if(hive.isNotEmpty && hive[0].matka5 != '' && hive[0].matka5 != '0')
                          Text('  \'${hive[0].matka5.substring(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color.fromARGB(255, 0, 0, 0),
                          )),
                      ],
                    ),
                  ),    


//wiersz opis ramki
              if (readyFrame || readyFrames)
                if (nrXXOfFrame != 0 || nrXXOfFramePo != 0 || nrXXOdFrame != 0)
                  _maleWiersze
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                //width: 100,
                                height: 40,
                                //PADDING PIONOWY 3 ZAMIAST 5 I TEKST W [FittedBox]
                                //(15.08.2026 - zgłoszenie „brakuje 2 px" z Samsunga).
                                //Rachunek: 40 - obwódka 6 - padding 5 + 5 = 24 px
                                //wnętrza, a tekst 18 px zajmuje 25,7 px, bo styl
                                //ustawia tylko `fontSize` i DZIEDZICZY `height: 1.43`
                                //z Material 3 (bodyMedium). Stąd dokładnie owe
                                //„BOTTOM OVERFLOWED BY 2.0 PIXELS".
                                //[FittedBox] zdejmuje przy okazji drugą pułapkę tego
                                //wiersza: „duża ramka na prawej stronie" to 28 znaków
                                //i na węższym ekranie zawijało się na drugą linię -
                                //wtedy brakowałoby nie 2 px, a 26. Teraz tekst
                                //w razie potrzeby maleje, zamiast wyjść poza obwódkę.
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 3),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      //color: Colors.black,
                                      width: 3.0,
                                      style: BorderStyle.solid),
                                  borderRadius: BorderRadius.circular(20),
                                  //color: Colors.yellowAccent,
                                ),
                                //color: Colors.blue,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "$sizeOfFrame " +
                                        AppLocalizations.of(context)!.frameOn +
                                        " $siteOfFrame " +
                                        AppLocalizations.of(context)!.site,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                alignment: Alignment.center,
                              ),
                            ),
                          ],
                        )
                     : 
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                //width: 100,
                                height: 45,
                                //to samo co w wariancie małym wyżej: tu zapas był
                                //0,4 px (33 px wnętrza na tekst 28,6 px), czyli
                                //wystarczyło minimalnie podnieść czcionkę systemową,
                                //żeby wiersz zaczął przepełniać
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 3),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      //color: Colors.black,
                                      width: 3.0,
                                      style: BorderStyle.solid),
                                  borderRadius: BorderRadius.circular(20),
                                  //color: Colors.yellowAccent,
                                ),
                                //color: Colors.blue,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "$sizeOfFrame " +
                                        AppLocalizations.of(context)!.frameOn +
                                        " $siteOfFrame " +
                                        AppLocalizations.of(context)!.site,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                alignment: Alignment.center,
                              ),
                            ),
                          ],
                        ),

//zapis zasobu
              if (readyStory && !readyInfo)
                _maleWiersze
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            //TE SAME 85 px i fontSize 18 co pudełko info nizej.
                            //Historia: 60 px przy fontSize 20 to było miejsce na
                            //JEDNĄ linię, a najdłuższe teksty zasobu się zawijają:
                            //"Do zrobienia = trzeba wirować" (29 znaków),
                            //"Zrobiono = przesuń w prawo", a po francusku
                            //"cellules royales supprimées = 12" (32). Podniesienie
                            //do 75 px MIAŁO dać dwie linie, ale rachunek był zły -
                            //patrz komentarz na początku [build]: styl ustawia sam
                            //`fontSize`, więc linia ma 1,43 * 18 = 25,7 px, a nie
                            //~21. Dwie linie z etykietą to 71,5 px, przy 75 px
                            //wysokości zostawało 62 px wnętrza - brakowało 10 px
                            //(sprawdzone 15.08.2026 na Samsungu).
                            //Teraz: 85 px, padding górny 5 => 74 px wnętrza,
                            //a tekst dostał `height: 1.2` => potrzeba 63 px.
                            //`_kStrefaDanychMala` liczy dla tego wiersza te 85 px
                            //(zasób i info wykluczają się wzajemnie).
                            child: Container(
                              //width: 100,
                              height: 85,
                              margin: EdgeInsets.only(top: marginRow),
                              padding:
                                  EdgeInsets.only(top: 5, left: 20, right: 20),
                              //color: Colors.blue,
                              child: Column(
                                children: [
                                  Text(
                                      AppLocalizations.of(context)!.save + ':'),
                                  nrXXOfApiary != 0 &&
                                          nrXXOfHive != 0 &&
                                          _korpusNr != 0 &&
                                          (nrXXOfFrame != 0 || nrXXOfFramePo != 0 || nrXXOdFrame != 0)
                                      ? Text(
                                          zapis,
                                          //`height` JAWNIE: bez niego linia bierze
                                          //1,43 z Material 3 i dwie linie nie mieszczą
                                          //się w pudełku (patrz komentarz wyżej)
                                          style: TextStyle(
                                            height: 1.2,
                                            fontSize: 18,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Text(
                                          AppLocalizations.of(context)!.noSave,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color:
                                                Color.fromARGB(255, 255, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          softWrap: false, //zawijanie tekstu
                                          overflow: TextOverflow
                                              .fade, //skracanie tekstu
                                        ),
                                ],
                              ),

                              alignment: Alignment.topCenter,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    //color: Colors.black,
                                    width: 3.0,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(20),
                                //color: Colors.yellowAccent,
                              ),
                            ),
                          ),
                        ],
                      )
                   : 
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              //width: 100,
                              height: hightSave,
                              margin: EdgeInsets.only(top: marginRow),
                              padding: EdgeInsets.only(
                                  top: marginRow,
                                  bottom: 3,
                                  left: 20,
                                  right: 20),
                              //color: Colors.blue,
                              child: Column(
                                children: [
                                  Text(
                                      AppLocalizations.of(context)!.save + ':'),
                                  nrXXOfApiary != 0 &&
                                          nrXXOfHive != 0 &&
                                          _korpusNr != 0 &&
                                          (nrXXOfFrame != 0 || nrXXOfFramePo != 0 || nrXXOdFrame != 0)
                                      ? Text(
                                          zapis,
                                          //`height` JAWNIE - jak w wariancie małym:
                                          //przy dziedziczonym 1,43 dwie linie
                                          //z etykietą to 77 px z 81 px wnętrza,
                                          //czyli zapas mniejszy niż jedna kropka
                                          style: TextStyle(
                                            height: 1.2,
                                            fontSize: 20,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Text(
                                          AppLocalizations.of(context)!.noSave,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color:
                                                Color.fromARGB(255, 255, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          softWrap: false, //zawijanie tekstu
                                          overflow: TextOverflow
                                              .fade, //skracanie tekstu
                                        ),
                                ],
                              ),

                              alignment: Alignment.topCenter,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    //color: Colors.black,
                                    width: 3.0,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(20),
                                //color: Colors.yellowAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
//zapis info
              if (readyInfo)
                _maleWiersze 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              //width: 100,
                              //85 px i padding górny 5 - jak w bliźniaczym pudełku
                              //zasobu wyżej; tam jest cały rachunek na dwie linie
                              height: 85,
                              margin: EdgeInsets.only(top: marginRow),
                              padding:
                                  EdgeInsets.only(top: 5, left: 20, right: 20),
                              child: Column(
                                children: [
                                  Text(AppLocalizations.of(context)!.save +
                                      " info:"),
                                  nrXXOfApiary != 0 &&
                                          (nrXXOfHive != 0 || readyAllHives)
                                      ? Text(
                                          zapis,
                                          //`height` JAWNIE - patrz pudełko zasobu
                                          style: TextStyle(
                                            height: 1.2,
                                            fontSize: 18,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Text(
                                          AppLocalizations.of(context)!
                                              .noSaveInfo,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color:
                                                Color.fromARGB(255, 255, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          softWrap: false, //zawijanie tekstu
                                          overflow: TextOverflow
                                              .fade, //skracanie tekstu
                                        ),
                                ],
                              ),

                              alignment: Alignment.topCenter,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    //color: Colors.black,
                                    width: 3.0,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(20),
                                //color: Colors.yellowAccent,
                              ),
                            ),
                          ),
                        ],
                      )
                   : 
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              //width: 100,
                              height: hightSave,
                              margin: EdgeInsets.only(top: marginRow),
                              padding: EdgeInsets.only(
                                  top: marginRow,
                                  bottom: 3,
                                  left: 20,
                                  right: 20),
                              child: Column(
                                children: [
                                  Text(AppLocalizations.of(context)!.save +
                                      " info:"),
                                  nrXXOfApiary != 0 &&
                                          (nrXXOfHive != 0 || readyAllHives)
                                      ? Text(
                                          zapis,
                                          //`height` JAWNIE - patrz pudełko zasobu
                                          style: TextStyle(
                                            height: 1.2,
                                            fontSize: 20,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Text(
                                          AppLocalizations.of(context)!
                                              .noSaveInfo,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color:
                                                Color.fromARGB(255, 255, 0, 0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          softWrap: false, //zawijanie tekstu
                                          overflow: TextOverflow
                                              .fade, //skracanie tekstu
                                        ),
                                ],
                              ),

                              alignment: Alignment.topCenter,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    //color: Colors.black,
                                    width: 3.0,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(20),
                                //color: Colors.yellowAccent,
                              ),
                            ),
                          ),
                        ],
                      ),

             
            ],
          ));
    return flex ? Expanded(flex: 4, child: content) : content;
  }

  buildRhinoTextArea(BuildContext context, {bool flex = true}) {
    //podgląd dyktowanej notatki pokazujemy OD KOŃCA: liczy się to, co użytkownik
    //mówi teraz, a 90 sekund tekstu i tak nie zmieści się w tym miejscu ekranu
    final String podgladNotatki = _tekstNotatki.length > 160
        ? '…${_tekstNotatki.substring(_tekstNotatki.length - 160)}'
        : _tekstNotatki;
    final content = Container(
            alignment: Alignment.center,
            color: Color.fromARGB(255, 255, 255, 255),
            //margin: EdgeInsets.all(15),
            padding: EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rhinoText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: heightScreen < 600 ? 15 : 18),
                ),
                //DYKTOWANIE: surowy tekst z Vosk pokazujemy ZAWSZE, także bez
                //przełącznika diagnostyki. To jedyne takie miejsce w aplikacji -
                //tutaj tekst nie jest podglądem wnętrza silnika, tylko treścią,
                //która za chwilę trafi do bazy, więc użytkownik MUSI ją widzieć.
                if (_dyktuje)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          //ujście w nagłówku, nie tylko w komendzie: między
                          //„notatka do przeglądu" a „notatka do notesu" ekran
                          //wygląda identycznie, a tekst ląduje gdzie indziej
                          _ujscieNotatki == UjscieNotatki.notes
                              ? 'Notatka do notesu - zakończ słowami „Hej Maja"'
                              : 'Notatka do przeglądu - zakończ słowami „Hej Maja"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color.fromARGB(255, 120, 120, 120),
                              fontSize: 12),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            podgladNotatki.isEmpty
                                ? 'słucham...'
                                : podgladNotatki,
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: heightScreen < 600 ? 14 : 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                //tekst "w locie" - widać, że mikrofon pracuje, zanim Vosk
                //domknie frazę. Szary, bo to podgląd, a nie wynik.
                //Bez diagnostyki pokazujemy samo wielokropkowe "słucham...":
                //partial to surowy strumień z Vosk, więc migałyby w nim aliasy
                //fonetyczne z gramatyki (patrz [_opisFrazy]) - i to jeszcze
                //bardziej surowe niż w domkniętej frazie.
                if (_partial.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      globals.voiceDiagnostyka ? _partial : 'słucham...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color.fromARGB(255, 130, 130, 130),
                          fontSize: 13,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                //stan nasłuchu: czuwanie / komendy / przerwanie / nieudane
                //rozpoznanie. Bez tego użytkownik nie ma jak odróżnić "nie
                //usłyszało" od "usłyszało i odrzuciło". Treść buduje
                //[_opisFrazy] - surowy tekst z Vosk tylko przy diagnostyce.
                if (_stanNasluchu.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _stanNasluchu,
                      textAlign: TextAlign.center,
                      //TWARDY bezpiecznik wysokości: strefa tekstów ma stałą
                      //wysokość (trzy strefy ekranu), a w stanie potrafi
                      //wylądować treść wyjątku - natywny błąd iOS ma czasem
                      //kilkaset linii i rozsadzał Column (zgłoszenie
                      //05.08.2026). Skracamy też u źródła (VoskEngine._blad),
                      //ale ekran nie ma prawa paść od DOWOLNEGO komunikatu.
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isError
                              ? Color.fromARGB(255, 200, 0, 0)
                              : Color.fromARGB(255, 90, 90, 90),
                          fontSize: 12),
                    ),
                  ),
                //osobna, TRWAŁA linijka notatki - patrz [_komunikatNotatki].
                //Nie może dzielić miejsca ze stanem nasłuchu, bo ten jest
                //przepisywany przez każdą kolejną frazę z Vosk.
                if (_komunikatNotatki.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _komunikatNotatki,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color.fromARGB(255, 0, 90, 200),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                //ślad kroków wejścia w dyktowanie - patrz [_sladNotatki]
                if (globals.voiceDiagnostyka && _sladNotatki.isNotEmpty)
                  _sladNotatkiWidget(),
                //stary asset gramatyki w pakiecie - patrz [_gramatykaNieaktualna]
                if (_gramatykaNieaktualna) _ostrzezenieOGramatyce(),
              ],
            ));
    return flex ? Expanded(flex: 2, child: content) : content;
  }

  //Jedno ostrzeżenie dla obu układów ekranu: wczytana gramatyka nie zna komendy
  //notatki. Bez niego objaw jest nie do rozszyfrowania - Vosk mapuje "zanotuj"
  //na najbliższą ZNANĄ frazę, więc ekran melduje "przyjęte: ..." i wykonuje
  //cudzą komendę, zamiast przyznać, że komendy notatki nie ma w gramatyce.
  //Ostatni krok wejścia w dyktowanie notatki - patrz [_sladNotatki]. Widoczny
  //tylko przy włączonej diagnostyce (poza nią jest bezużyteczny dla pszczelarza
  //i tylko myli), za to w OBU układach ekranu.
  Widget _sladNotatkiWidget() => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'notatka: $_sladNotatki',
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: Color.fromARGB(255, 140, 100, 0), fontSize: 11),
        ),
      );

  Widget _ostrzezenieOGramatyce() => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'UWAGA: wczytana gramatyka nie zna polecenia notatki albo cofania - w '
          'pakiecie apki jest stary plik assets/grammar/pol_vosk.yml. Zbuduj '
          'apkę od nowa (pełny restart, nie hot reload).',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Color.fromARGB(255, 200, 0, 0), fontSize: 12),
        ),
      );

  //odświeżenie danych dla live podglądu korpusu - wywoływane po komendzie głosowej
  //która zmienia zawartość korpusu lub wybór pasieki/ula/korpusu.
  //Gdy rozpoczęto nowy przegląd dzisiaj - pokazuje dzisiejszy przegląd.
  //W przeciwnym razie - ostatni istniejący przegląd "po".
  Future<void> _refreshLiveView() async {
    try {
      //pobranie wszystkich dat przeglądów dla wybranego ula (posortowane DESC)
      await getDaty(nrXXOfApiary, nrXXOfHive);

      final bool todayHasReview =
          _daty.any((d) => d.data == formattedDate);
      if (todayHasReview) {
        wybranaData = formattedDate; //nowy przegląd - pokaż aktualny
      } else if (_daty.isNotEmpty) {
        wybranaData = _daty[0].data; //najnowsza istniejąca data (ORDER BY data DESC)
      } else {
        wybranaData = formattedDate; //brak przeglądów - pusty widok
      }

      await getKorpusy(nrXXOfApiary, nrXXOfHive, wybranaData);
      await Provider.of<Frames>(context, listen: false)
          .fetchAndSetFramesForHive(nrXXOfApiary, nrXXOfHive);
      await Provider.of<Infos>(context, listen: false)
          .fetchAndSetInfosForHive(nrXXOfApiary, nrXXOfHive);
      await Provider.of<Hives>(context, listen: false)
          .fetchAndSetHives(nrXXOfApiary);

      //przeliczenie rozmiarów płótna (jak w _dialogBuilderHive)
      widthCanvas = 0;
      highCanvas = 0;
      for (var i = 0; i < _korpusy.length; i++) {
        highCanvas += _korpusy[i].typ * 75 + 30;
      }
      final hivesData = Provider.of<Hives>(context, listen: false);
      final hv = hivesData.items.where((h) => h.ulNr == nrXXOfHive).toList();
      if (hv.isNotEmpty) {
        widthCanvas = hv[0].ramek * 20 + 20;
      }
      if (mounted) setState(() {});
    } catch (e) {
      //print('_refreshLiveView error: $e');
    }
  }

  //Cienka linia rozdzielająca strefy - żeby było widać, że to trzy osobne
  //obszary, a nie jeden ciąg tekstu z rysunkiem w środku.
  Widget _kreska() => Container(
        height: 1,
        color: const Color.fromARGB(255, 225, 225, 225),
      );

  //Nagłówek strefy 2: słowo "po" i data przeglądu - dokładnie jak w okienku
  //pomocy [_dialogBuilderHive]. Bez tego wiersza widok korpusu kłamie: przy ulu,
  //w którym dziś jeszcze nie było przeglądu, pokazuje ostatni istniejący (patrz
  //[_refreshLiveView]), a użytkownik ma prawo sądzić, że patrzy na dzisiejszy.
  //Dzisiejszy przegląd jest oznaczony kropką i zielenią - to jedyne odróżnienie
  //"pracuję na żywo" od "oglądam historię".
  Widget _naglowekKorpusu(BuildContext context) {
    final bool dzis = wybranaData == formattedDate;
    final Color kolor = dzis
        ? const Color.fromARGB(255, 0, 130, 0)
        : const Color.fromARGB(255, 60, 60, 60);
    return SizedBox(
      height: _kNaglowekKorpusu,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (dzis) ...[
            Icon(Icons.fiber_manual_record, size: 9, color: kolor),
            const SizedBox(width: 5),
          ],
          Text(
            AppLocalizations.of(context)!.after,
            style: TextStyle(fontSize: 14, color: kolor),
          ),
          Text(
            '  $wybranaData',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: kolor),
          ),
        ],
      ),
    );
  }

  //Strefa 2 bez danych do narysowania. Zajmuje CAŁE swoje miejsce, a nie tyle,
  //ile potrzebuje napis - inaczej ekran przeskakiwałby przy pierwszej komendzie,
  //bo strefa nagle rosłaby do rozmiaru korpusu.
  Widget _pustaStrefaKorpusu(BuildContext context, double maxWysokosc) =>
      SizedBox(
        height: maxWysokosc,
        child: Center(
          child: Text(AppLocalizations.of(context)!.hive,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
      );

  //STREFA 2 - live podgląd jednego korpusu (widok "po") z datą przeglądu nad
  //rysunkiem. Miejsce dostaje z góry, STAŁE (_kStrefaKorpusu), policzone z
  //najwyższego możliwego korpusu:
  //
  //   nagłówek "po <data>"          _kNaglowekKorpusu
  //   numery ramek nad obrysem      _kNumeryRamek
  //   korpus  = typ * 75 + 30       105 px (półkorpus) / 180 px (korpus)
  //   numery ramek pod obrysem      _kNumeryRamek
  //   zapas estetyczny              2 * _kZapasKorpusu
  //
  //Rysunek niższy od tego (półkorpus) zostaje wyśrodkowany w strefie - strefa
  //się pod niego NIE kurczy, bo wtedy teksty spod spodu podskakiwałyby przy
  //każdej zmianie korpusu.
  //
  //Pas na numery ramek MUSI być zarezerwowany, bo painter maluje je poza swoim
  //`size` (y = -16 i high+3) - bez tego wchodzą na sąsiednie strefy. Gdy tyle
  //miejsca nie ma (pełny korpus na niskim ekranie w poziomie albo ul 20-ramkowy
  //szerszy niż panel), [FittedBox] zmniejsza rysunek tak, żeby zmieścił się w
  //całości. Przewijania tu nie ma świadomie: przy ulu, w rękawicach, nie ma jak
  //przewijać, a niepełny korpus na ekranie jest gorszy niż korpus mniejszy.
  Widget buildKorpusArea(BuildContext context, {required double maxWysokosc}) {
    //Skrajnie niski ekran (okno wielozadaniowe iPada, klawiatura systemowa):
    //strefa 2 wtedy w ogóle się nie pokazuje. Lepiej oddać całe miejsce
    //komunikatom, niż wcisnąć nieczytelny skrawek korpusu.
    if (maxWysokosc < _kNaglowekKorpusu + 40) return const SizedBox.shrink();

    final framesData = Provider.of<Frames>(context, listen: false);
    //widok "po" - pomijamy ramki usunięte (ramkaNrPo == 0), zgodnie z _dialogBuilderHive
    final frames = framesData.items.where((fr) {
      return fr.data == wybranaData && fr.ramkaNrPo > 0;
    }).toList();
    final infos = Provider.of<Infos>(context, listen: false)
        .items.where((inf) => inf.data == wybranaData).toList();

    if (_korpusy.isEmpty || frames.isEmpty || widthCanvas == 0) {
      return _pustaStrefaKorpusu(context, maxWysokosc);
    }

    //tylko aktualnie modyfikowany korpus - przy orientacji poziomej dwa się nie mieszczą
    int activeKorpusNr = nrXOfBody != 0 ? nrXOfBody : nrXOfHalfBody;
    //jezeli brak wyboru albo wybrany numer nie istnieje - pokaż najwyższy (ostatnio dodany)
    if (activeKorpusNr == 0 ||
        !_korpusy.any((k) => k.korpusNr == activeKorpusNr)) {
      activeKorpusNr = _korpusy
          .map((k) => k.korpusNr)
          .reduce((a, b) => a > b ? a : b);
    }
    final activeKorpus =
        _korpusy.where((k) => k.korpusNr == activeKorpusNr).toList();
    final activeFrames =
        frames.where((f) => f.korpusNr == activeKorpusNr).toList();

    if (activeKorpus.isEmpty || activeFrames.isEmpty) {
      return _pustaStrefaKorpusu(context, maxWysokosc);
    }

    final double activeHigh =
        (activeKorpus[0].typ * 75 + 30).toDouble(); //wysokość jednego korpusu
    final double wysokoscRysunku = activeHigh + 2 * _kNumeryRamek;
    //strefa bierze CAŁE przydzielone miejsce, także dla półkorpusu - miejsce
    //jest policzone dla najwyższego korpusu i ma być stałe. Niższy rysunek
    //zostaje wyśrodkowany, zamiast podciągać do góry teksty spod spodu.

    return SizedBox(
      height: maxWysokosc,
      child: Column(
        children: [
          _naglowekKorpusu(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: _kZapasKorpusu),
              child: ClipRect(
                child: FittedBox(
                  //scaleDown, nie contain: przy typowym ulu (12 ramek,
                  //półkorpus) rysunek zostaje w skali 1:1 i nic się nie
                  //powiększa ponad naturalny rozmiar.
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: widthCanvas,
                    height: wysokoscRysunku,
                    child: Padding(
                      //miejsce na numery ramek malowane nad i pod obrysem
                      padding: const EdgeInsets.symmetric(
                          vertical: _kNumeryRamek),
                      child: Container(
                        color: const Color.fromARGB(173, 173, 173, 173),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: MyHive(
                              ulPo: true,
                              ramki: activeFrames,
                              korpusy: activeKorpus,
                              width: widthCanvas,
                              high: activeHigh,
                              informacje: infos,
                            ),
                            size: Size(widthCanvas, activeHigh),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Kompaktowy pasek stanu do układu z live podglądem korpusu. Pokazuje TO SAMO,
  //co sekcja tekstowa w układzie klasycznym, tylko w jednej linijce na element:
  //dyktowaną notatkę, komunikat stanu i błąd silnika. Bez niego live podgląd
  //ukrywał wszystko, co silnik ma do powiedzenia - łącznie z powodem, dla
  //którego notatka nie ruszyła.
  Widget buildPasekStanu(BuildContext context) {
    final String podglad = _tekstNotatki.length > 90
        ? '…${_tekstNotatki.substring(_tekstNotatki.length - 90)}'
        : _tekstNotatki;
    final bool cokolwiek = rhinoText.isNotEmpty ||
        _dyktuje ||
        isError ||
        _stanNasluchu.isNotEmpty ||
        _komunikatNotatki.isNotEmpty ||
        (globals.voiceDiagnostyka && _sladNotatki.isNotEmpty) ||
        _gramatykaNieaktualna;
    if (!cokolwiek) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Color.fromARGB(255, 255, 255, 255),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //ECHO KOMENDY - to samo, co w układzie klasycznym pokazuje
          //[buildRhinoTextArea]. Układ z live podglądem go do 04.08.2026 nie
          //budował, więc jedyne potwierdzenie „przyjęłam to i to" nie miało
          //gdzie się pokazać; zostawał sam rysunek, po którym trzeba było
          //zgadywać, czy komenda w ogóle weszła.
          if (rhinoText.isNotEmpty)
            Text(
              rhinoText,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: heightScreen < 600 ? 14 : 15),
            ),
          if (_dyktuje)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.edit_note,
                    size: 18, color: Color.fromARGB(255, 0, 90, 200)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    podglad.isEmpty
                        ? 'Notatka - mów, zakończ słowami „Hej Maja"'
                        : podglad,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0), fontSize: 14),
                  ),
                ),
              ],
            ),
          if (isError && errorMessage.isNotEmpty)
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Color.fromARGB(255, 200, 0, 0), fontSize: 12),
            )
          else if (_stanNasluchu.isNotEmpty)
            Text(
              _stanNasluchu,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Color.fromARGB(255, 90, 90, 90), fontSize: 12),
            ),
          //osobna, TRWAŁA linijka notatki - patrz [_komunikatNotatki]
          if (_komunikatNotatki.isNotEmpty)
            Text(
              _komunikatNotatki,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Color.fromARGB(255, 0, 90, 200),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          //ślad kroków wejścia w dyktowanie - patrz [_sladNotatki]
          if (globals.voiceDiagnostyka && _sladNotatki.isNotEmpty)
            _sladNotatkiWidget(),
          //stary asset gramatyki w pakiecie - patrz [_gramatykaNieaktualna]
          if (_gramatykaNieaktualna) _ostrzezenieOGramatyce(),
        ],
      ),
    );
  }

  buildErrorMessage(BuildContext context, {bool flex = true}) {
    final content = Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 10),
            padding: EdgeInsets.all(5),
            decoration: !isError
                ? null
                : BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(5)),
            child: !isError
                ? null
                : Text(
                    errorMessage,
                    //jak wyżej: treść wyjątku bywa wielolinijkowa, a to pole
                    //siedzi w Expanded o stałej wysokości
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ));
    return flex ? Expanded(flex: isError ? 4 : 0, child: content) : content;
  }

}

class MyHive extends CustomPainter {
  bool ulPo; //w "ul pomóz mi": false="przed", true="po"
  List<Frame> ramki;
  List<Frame> korpusy;
  double width;
  double high;
  List<Info> informacje;

  MyHive({
    required this.ulPo, 
    required this.ramki,
    required this.korpusy,
    required this.width,
    required this.high,
    required this.informacje,
    // required this.sides, required this.radius, required this.radians
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()..strokeWidth = 1; //linia ramki
    Paint lineExcluder = Paint()..strokeWidth = 3; //linia ramki
    Paint obrysPaint = Paint()
      ..strokeWidth = 1
      ..color = Color.fromARGB(255, 122, 122, 122); //obrys
    Paint honeyPaint = Paint()
      ..strokeWidth = 4
      ..color = Color.fromARGB(255, 222, 156,
          1); //(1) honey / miód, nakrop 255, 252, 193, 104//,255, 206, 144, 1
    Paint sealedPaint = Paint()
      ..strokeWidth = 4
      ..color =
          Color.fromARGB(255, 131, 92, 0); //(2) sealed / zasklep, miód poszyty
    Paint pollenPaint = Paint()
      ..strokeWidth = 4
      ..color = Color.fromARGB(255, 0, 197, 0); //(3) pollen / pierzga
    Paint broodPaint = Paint()
      ..strokeWidth = 4
      ..color = Color.fromARGB(255, 255, 17, 0); //(4) brook / czerw
    Paint larvaePaint = Paint()
      ..strokeWidth = 4
      ..color = Color.fromARGB(255, 253, 195, 192); //(5) larvae / larwy
    Paint eggPaint = Paint()
      ..strokeWidth = 4
      ..color = Color.fromARGB(255, 255, 255, 255); //(6) eggs / jaja
    Paint dronePaint = Paint()
      ..strokeWidth = 4
      ..color = Color.fromARGB(255, 114, 0, 0); //(7) drone / trut
    Paint waxPaint = Paint()
      ..strokeWidth = 1
      ..color = Color.fromARGB(255, 255, 255, 0); //(8) wax / węza
    Paint combPaint = Paint()
      ..strokeWidth = 4
      ..color = Color.fromARGB(
          255, 255, 255, 0); //(9) comb, wax comb / susz, woszczyna
    Paint matkaBlack = Paint()
      ..color = Color.fromARGB(255, 0, 0, 0)
      ..style = PaintingStyle.fill; //matka black
    Paint matkaWhite = Paint()
      ..color = Color.fromARGB(255, 255, 255, 255)
      ..style = PaintingStyle.fill; //matkaWhite
    Paint matkaYellow = Paint()
      ..color = Color.fromARGB(255, 255, 255, 0)
      ..style = PaintingStyle.fill; //matkaYellow
    Paint matkaRed = Paint()
      ..color = Color.fromARGB(255, 255, 0, 0)
      ..style = PaintingStyle.fill; //matkaRed
    Paint matkaGreen = Paint()
      ..color = Color.fromARGB(255, 0, 255, 0)
      ..style = PaintingStyle.fill; //matkaGreen
    Paint matkaBlue = Paint()
      ..color = Color.fromARGB(255, 0, 89, 255)
      ..style = PaintingStyle.fill; //matkaBlue
    Paint matkaOther = Paint()
      ..color = Color.fromARGB(255, 125, 125, 125)
      ..style = PaintingStyle.fill; //matkaOther - ten sam szary co w frames_screen
    Paint matecznik = Paint()
      ..color = Color.fromARGB(255, 255, 17, 0)
      ..style = PaintingStyle.fill
      ..strokeWidth = 1; //matecznik
    Paint delMat = Paint()
      ..color = Color.fromARGB(255, 153, 125, 125)
      ..style = PaintingStyle.fill //stroke
      ..strokeWidth = 1; //mateczniki usuniete

    Paint paintStroke = Paint()
      ..color = Color.fromARGB(255, 0, 0, 0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke //fill
      ..strokeCap = StrokeCap.round;
    // Paint paintStroke = Paint()
    //   ..color = Color.fromARGB(255, 0, 0, 0)
    //   ..strokeWidth = 1
    //   ..style = PaintingStyle.fill //stroke
    //   ..strokeCap = StrokeCap.round;
    double startNastZas =
        0; //start następnego zasobu - do sprawdzania czy nowy zasób przekracza 100%
    //wielokąty
    double sides = 3;
    double radius = 5;
    double radians = 0; //kąt - początek rysowania
    //3.14 - trójkąt w lewo, //1,57(/2) - w dół //(/6) - w górę, 0 - w prawo
    //double wDol = math.pi/2; //1,57 - trójkąt w dół
    var path = Path();

    //text
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 15,
    );

    //text numery ramek
    final textStyle1 = TextStyle(
      color: Color.fromARGB(255, 170, 170, 170),
      fontSize: 12,
    );


    //======= obrysy korpusów =======
    double obrysPoziomy = 0;
    Map<int, double> obrys = {}; //key:nr korpusu, value:obrys poziomy (górny)
    Map<String, double> startyZasobow =
        {}; //key: korpusNr.ramkaNr.strona, value: start kolejnego zasobu (dla ramek i zasobów)
    Map<String, double> startyMaxZasobow =
        {}; //key: korpusNr.ramkaNr.strona, value: start pierwszego zasobu (dla matek, mateczników)

    //canvas.drawLine(Offset(0, 0), Offset(width, 0), obrysPaint); //obrys 0 (górna krawędz)
    canvas.drawLine(Offset(0, high), Offset(width, high),
        obrysPaint); //obrys high (dolna krawędz)
    canvas.drawLine(Offset(0, 0), Offset(0, high), obrysPaint); //obrys lewy
    canvas.drawLine(
        Offset(width, 0), Offset(width, high), obrysPaint); //obrys prawy

    //tworzenie mapay = [kolejny korpus]: obrys poziomy (górny)
    for (var i = 0; i < korpusy.length; i++) {
      obrysPoziomy =
          korpusy[i].typ * 75 + 30; //wysokość półkorpusa + 2x15 na padding
      obrys[i + 1] = obrysPoziomy;
      // print('obrys i=${(i + 1)} - $obrys');
    }

    //krata odgrodowa - jeśli załozona w wybraanej dacie
    String excluder = '0';
    for (var i = 0; i < informacje.length; i++) {
      //print('i = $i');
      //print('excluder1 = $excluder');
      if ((informacje[i].parametr == 'excluder') ||
          (informacje[i].parametr == 'excluder -') ||
          (informacje[i].parametr == 'krata odgrodowa') ||
          (informacje[i].parametr == 'krata odgrodowa -')) {
        excluder = informacje[i]
            .miara; //zamiana pola wartosc z miara zeby poprawnie wyświetlać na listTail
        //print('excluder2 = $excluder');
        //print('informacje ${informacje[i].wartosc} ');
      }
    }
    //print('excluder = $excluder');
    //rysowanie obrysów poziomych (górnych)
    double temp = high; //maksymalna wysokość płótna
    for (var i = 0; i < obrys.length; i++) {
      // print('rysowanie obrysów i=$i');
      temp -= obrys[i + 1]!;
      canvas.drawLine(Offset(0, temp), Offset(width, temp), obrysPaint);
      if ((excluder != '0') && (int.parse(excluder) == 1 + i)) {
        canvas.drawLine(Offset(0, temp), Offset(width, temp), lineExcluder);
      }
      //numer korpusu
      var textSpan = TextSpan(
        text: '${korpusy[i].korpusNr}', //numer korpusu
        style: textStyle,
      );
      var textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: 20,
      );
      final offset = Offset(3, temp + 1);
      textPainter.paint(canvas, offset);
      // print('linia dla i=$i - ${temp}');
    }

    
    //numery ramek pod korpusem
    for (var i = 0; i < globals.iloscRamek; i++) {
      var textSpan = TextSpan(
        text: '${i+1}', //numer ramki
        style: textStyle1,
      );
      var textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: 20,
      );
      final offset = Offset(10 + (i * 20) + 6.toDouble(), high + 3);
      textPainter.paint(canvas, offset); //rysowanie numeru korpusa
      final offset1 = Offset(10 + (i * 20) + 6.toDouble(),  -16);
      textPainter.paint(canvas, offset1); //rysowanie numeru korpusa
    }
    
    
    
    
    //utworzenie mapy startyZasobow = key:korpusNr.ramkaNr.ramkaNr, value: start kolejnego zasobu
    if(ulPo)
      for (var i = 0; i < ramki.length; i++) {
        double startMaxZasobu = ramki[i].rozmiar * 75; //wielkość ramki
        startyZasobow['${ramki[i].korpusNr}.${ramki[i].ramkaNrPo}.${ramki[i].strona}'] = startMaxZasobu; //modyfikowane dla kolejnych zasobów
        startyMaxZasobow['${ramki[i].korpusNr}.${ramki[i].ramkaNrPo}.${ramki[i].strona}'] = startMaxZasobu; //nie są modyfikowane, odniesienie dla pozycji matek, mateczników
      }
    else 
      for (var i = 0; i < ramki.length; i++) {
          double startMaxZasobu = ramki[i].rozmiar * 75; //wielkość ramki
          startyZasobow['${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] = startMaxZasobu; //modyfikowane dla kolejnych zasobów
          startyMaxZasobow['${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] = startMaxZasobu; //nie są modyfikowane, odniesienie dla pozycji matek, mateczników
        }
    //print(startyZasobow);

    int brakKorpusow = 0;
    if (ramki[0].korpusNr == 1) {
      brakKorpusow = 0;
    }
    if (ramki[0].korpusNr == 2) {
      brakKorpusow = 1;
    }
    if (ramki[0].korpusNr == 3) {
      brakKorpusow = 2;
    }
    if (ramki[0].korpusNr == 4) {
      brakKorpusow = 3;
    }
    if (ramki[0].korpusNr == 5) {
      brakKorpusow = 4;
    }
    if (ramki[0].korpusNr == 6) {
      brakKorpusow = 5;
    }
    if (ramki[0].korpusNr == 7) {
      brakKorpusow = 6;
    }
    if (ramki[0].korpusNr == 8) {
      brakKorpusow = 7;
    }
    if (ramki[0].korpusNr == 9) {
      brakKorpusow = 8;
    }
    if (ramki[0].korpusNr == 10) {
      brakKorpusow = 9;
    }

    // print('korpusNr = ${ramki[0].korpusNr}');
    // print('brakKorpusow = $brakKorpusow');
    //  ========= rysowanie ramek =========
    int numerRamki = 0;
    for (var i = 0; i < ramki.length; i++) {
      //wyswietlany ul przed lub po przeglądzie
      if (ulPo) numerRamki = ramki[i].ramkaNrPo;
      else numerRamki = ramki[i].ramkaNr;
      double start = high;
      //ustalenie poziomu startu obliczania pozycji ramek w korpusie
      // print('przed for - start = $start');
      for (var j = 1; j <= ramki[i].korpusNr - brakKorpusow; j++) {
        // print('for - $j <= ramki[$i].korpusNr = ${ramki[i].korpusNr}');
        start = start - obrys[j]!; //odejmowany obrys korpusu nr "j"
        // print('for - start = $start');
        if (start == 0.0) break;
      }
      //start zasobu ramki 'i' modyfikowany i odczytywany z mapy startyZasobow
      double startZasobu = startyZasobow[
          '${ramki[i].korpusNr}.$numerRamki.${ramki[i].strona}']!;

      int wartoscInt = 0;
      if (ramki[i].zasob < 13) {
        wartoscInt = int.parse(
            (ramki[i].wartosc.replaceAll(RegExp('%'), ''))); // bez '%'
      }

      switch (ramki[i].zasob) {
        case 1:
          //print('case 1');
          //print('start dla ramki ${ramki[i].ramkaNr} = $start');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek
          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                dronePaint); //zasob 1 - drone // dla strony lewej i prawej

            //print('${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}');
            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 2:
          //print('case 2');
          //print('start dla ramki ${numerRamki} = $start');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek
          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                broodPaint); //zasob 2 - brook // dla strony lewej i prawej

            //print('${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}');
            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 3:
          //print('case 3');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek
          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                larvaePaint); //zasob 3 - larvae // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }

          break;
        case 4:
          //print('case 4');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek
          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                eggPaint); //zasob 4 - egg // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 5:
          //print('case 5');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                pollenPaint); //zasob 5 - pollen // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 6:
          //print('case 6');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                honeyPaint); //zasob 6 - miód // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 7:
          //print('case 7');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                sealedPaint); //zasob 7 - zasklep // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 8:
          //('case 9');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                waxPaint); //zasob 9 - węza // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 9:
          //print('case 8');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                combPaint); //zasob 8 - susz // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 10:
          //print('case 10');
          //canvas.drawCircle(Offset(100, 100), 3, matka);
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          switch (ramki[i].wartosc) {
            case '1':
              canvas.drawCircle(
                  Offset(
                      10 +
                          (numerRamki - 1) * 20 +
                          (ramki[i].strona * 12) -
                          8,
                      start + 20),
                  3,
                  matkaBlack);
              break;
            case '2':
              canvas.drawCircle(
                  Offset(
                      10 +
                          (numerRamki - 1) * 20 +
                          (ramki[i].strona * 12) -
                          8,
                      start + 20),
                  3,
                  matkaYellow);
              break;
            case '3':
              canvas.drawCircle(
                  Offset(
                      10 +
                          (numerRamki - 1) * 20 +
                          (ramki[i].strona * 12) -
                          8,
                      start + 20),
                  3,
                  matkaRed);
              break;
            case '4':
              canvas.drawCircle(
                  Offset(
                      10 +
                          (numerRamki - 1) * 20 +
                          (ramki[i].strona * 12) -
                          8,
                      start + 20),
                  3,
                  matkaGreen);
              break;
            case '5':
              canvas.drawCircle(
                  Offset(
                      10 +
                          (numerRamki - 1) * 20 +
                          (ramki[i].strona * 12) -
                          8,
                      start + 20),
                  3,
                  matkaBlue);
              break;
            case '6':
              canvas.drawCircle(
                  Offset(
                      10 +
                          (numerRamki - 1) * 20 +
                          (ramki[i].strona * 12) -
                          8,
                      start + 20),
                  3,
                  matkaWhite);
              break;
            //matka "inna" - komenda "inna matka ...". Bez tego case'a podgląd
            //rysował ją domyślną CZARNĄ kropką, czyli nie do odróżnienia od
            //matki czarnej (queen = '1'). frames_screen.dart (~1631) ma to samo.
            case '7':
              canvas.drawCircle(
                  Offset(
                      10 +
                          (numerRamki - 1) * 20 +
                          (ramki[i].strona * 12) -
                          8,
                      start + 20),
                  3,
                  matkaOther);
              break;
            default:
              canvas.drawCircle(
                  Offset(
                      10 +
                          (numerRamki - 1) * 20 +
                          (ramki[i].strona * 12) -
                          8,
                      start + 20),
                  3,
                  matkaBlack);
          }
          break;
        case 11:
          //print('case 11');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek

          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          double temp = startyMaxZasobow[
                  '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! +
              5;
          for (var a = 0; a < int.parse(ramki[i].wartosc); a++) {
            canvas.drawCircle(
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 12) -
                        8,
                    start + temp),
                3,
                matecznik);
            temp = temp - 10;
          }
          break;
        case 12:
          //print('case 12');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek

          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          double temp = startyMaxZasobow[
                  '${ramki[i].korpusNr}.${numerRamki}.${ramki[i].strona}']! +
              5;
          for (var a = 0; a < int.parse(ramki[i].wartosc); a++) {
            canvas.drawCircle(
                Offset(
                    10 +
                        (numerRamki - 1) * 20 +
                        (ramki[i].strona * 12) -
                        8,
                    start + temp),
                3,
                delMat);
            temp = temp - 10;
          }
          break;
        case 13: //to Do
          //print('case 13');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek

          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          switch (ramki[i].wartosc) {
            case 'work frame': //ramka pracy
              var angle = (math.pi * 2) / 4; //kąt (4 - kwadrat)
              radians = math.pi / 4;

              Offset center =
                  Offset(10 + (numerRamki - 1) * 20 + 10, start + 6);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'to delete': //do wycofania
              sides = 3;
              radians = math.pi / 6;
              var angle = (math.pi * 2) / sides; //kąt

              Offset center =
                  Offset(10 + (numerRamki - 1) * 20 + 10, start + 7);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'to extraction': //do wirowania
              double radiusEx = 4;
              sides = 6;
              radians = 0;
              var angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

              Offset center =
                  Offset(10 + (numerRamki - 1) * 20 + 10, start + 6);
              Offset startPoint = Offset(
                  radiusEx * math.cos(radians), radiusEx * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radiusEx * math.cos(radians + angle * i) + center.dx;
                double y = radiusEx * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'to insulate': //ramka dobra do zaizolowania na niej matki
              sides = 4;
              radians = math.pi / 4;
              //var angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 6, start + 9),
                  Offset(10 + (numerRamki - 1) * 20 + 14, start + 9),
                  linePaint); // - (kreska pozioma) dla poszczególnych ramek

              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 6, start + 3),
                  Offset(10 + (numerRamki - 1) * 20 + 6, start + 10),
                  linePaint); // | (kreska pionowa lewa)
              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 14, start + 3),
                  Offset(10 + (numerRamki - 1) * 20 + 14, start + 10),
                  linePaint); // | (kreska pionowa prawa)
              break;
            case 'ramka pracy': //ramka pracy
              var angle = (math.pi * 2) / 4; //kąt (4 - kwadrat)
              radians = math.pi / 4;

              Offset center =
                  Offset(10 + (numerRamki - 1) * 20 + 10, start + 6);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'trzeba usunąć': //do wycofania
              sides = 3;
              radians = math.pi / 6;
              var angle = (math.pi * 2) / sides; //kąt

              Offset center =
                  Offset(10 + (numerRamki - 1) * 20 + 10, start + 7);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'trzeba wirować': //do wirowania
              double radiusEx = 4;
              sides = 6;
              radians = 0;
              var angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

              Offset center =
                  Offset(10 + (numerRamki - 1) * 20 + 10, start + 6);
              Offset startPoint = Offset(
                  radiusEx * math.cos(radians), radiusEx * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radiusEx * math.cos(radians + angle * i) + center.dx;
                double y = radiusEx * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'można izolować': //ramka dobra do zaizolowania na niej matki
              sides = 4;
              radians = math.pi / 4;
              //var angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 6, start + 9),
                  Offset(10 + (numerRamki - 1) * 20 + 14, start + 9),
                  linePaint); // - (kreska pozioma) dla poszczególnych ramek

              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 6, start + 3),
                  Offset(10 + (numerRamki - 1) * 20 + 6, start + 10),
                  linePaint); // | (kreska pionowa lewa)
              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 14, start + 3),
                  Offset(10 + (numerRamki - 1) * 20 + 14, start + 10),
                  linePaint); // | (kreska pionowa prawa)
              break;
          }
          break;
        case 14: //is Done
          //print('case 14');
          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 4, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek

          canvas.drawLine(
              Offset(10 + (numerRamki - 1) * 20 + 10, start + 13),
              Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          switch (ramki[i].wartosc) {
            case 'moved left': //przesunieto w lewo
              sides = 3;
              radians = math.pi; //w lewo
              var angle = (math.pi * 2) / 3; //kąt (3- trójkąt)

              Offset center = Offset(10 + (numerRamki - 1) * 20 + 10 - 2,
                  start + (75 * ramki[i].rozmiar) + 10 + 12);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'moved right': //przesunięto w prawo
              sides = 3;
              radians = 0; //w prawo
              var angle = (math.pi * 2) / sides; //kąt (3- trójkąt)

              Offset center = Offset(10 + (numerRamki - 1) * 20 + 10 + 2,
                  start + (75 * ramki[i].rozmiar) + 10 + 12);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'inserted': //wstawiono
              sides = 3;
              radians = math.pi / 6; //w górę
              var angle = (math.pi * 2) / sides; //kąt (3- trójkąt)

              Offset center = Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 10 + 13);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'deleted': //wycofano, usunieto
              sides = 3;
              radians = math.pi / 2; //w dół
              var angle = (math.pi * 2) / sides; //kąt (3- trójkąt)

              Offset center = Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 10 + 11);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'insulated': //zaizolowano - załoono izolator
              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 1,
                      start + (75 * ramki[i].rozmiar) + 20),
                  Offset(10 + (numerRamki - 1) * 20 + 19,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // - (kreska pozioma) dla poszczególnych ramek

              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 1, start + 9),
                  Offset(10 + (numerRamki - 1) * 20 + 1,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // | (kreska pionowa lewa)
              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 19, start + 9),
                  Offset(10 + (numerRamki - 1) * 20 + 19,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // | (kreska pionowa prawa)
              break;
            case 'izolacja': //zaizolowano - załoono izolator
              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 1,
                      start + (75 * ramki[i].rozmiar) + 20),
                  Offset(10 + (numerRamki - 1) * 20 + 19,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // - (kreska pozioma) dla poszczególnych ramek

              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 1, start + 9),
                  Offset(10 + (numerRamki - 1) * 20 + 1,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // | (kreska pionowa lewa)
              canvas.drawLine(
                  Offset(10 + (numerRamki - 1) * 20 + 19, start + 9),
                  Offset(10 + (numerRamki - 1) * 20 + 19,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // | (kreska pionowa prawa)
              break;
            case 'usuń ramka': //wycofano, usunieto
              sides = 3;
              radians = math.pi / 2; //w dół
              var angle = (math.pi * 2) / sides; //kąt (3- trójkąt)

              Offset center = Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 10 + 11);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'wstaw ramka': //wstawiono
              sides = 3;
              radians = math.pi / 6; //w górę
              var angle = (math.pi * 2) / sides; //kąt (3- trójkąt)

              Offset center = Offset(10 + (numerRamki - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 10 + 13);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'przesuń w prawo': //przesunięto w prawo
              sides = 3;
              radians = 0; //w prawo
              var angle = (math.pi * 2) / sides; //kąt (3- trójkąt)

              Offset center = Offset(10 + (numerRamki - 1) * 20 + 10 + 2,
                  start + (75 * ramki[i].rozmiar) + 10 + 12);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
            case 'przesuń w lewo': //przesunieto w lewo
              sides = 3;
              radians = math.pi; //w lewo
              var angle = (math.pi * 2) / 3; //kąt (3- trójkąt)

              Offset center = Offset(10 + (numerRamki - 1) * 20 + 10 - 2,
                  start + (75 * ramki[i].rozmiar) + 10 + 12);
              Offset startPoint = Offset(
                  radius * math.cos(radians), radius * math.sin(radians));

              path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

              for (int i = 1; i <= sides; i++) {
                double x = radius * math.cos(radians + angle * i) + center.dx;
                double y = radius * math.sin(radians + angle * i) + center.dy;
                path.lineTo(x, y);
              }
              path.close();
              canvas.drawPath(path, paintStroke);
              break;
          }
          break;
      }
      //print(startyZasobow);
      //print(ramki[i].wartosc);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    //throw UnimplementedError();
    return true;
  }
}
 //usunąć zeby aktywować cały skrypt !!!!!!!!!!!!!!!!!!!!!!!!!!!
