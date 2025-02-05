//
// Copyright 2021 Picovoice Inc.
//
// You may not use this file except in compliance with the license. A copy of the license is located in the "LICENSE"
// file accompanying this source.
//
// Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
  //usunąć zeby aktywować cały skrypt !!!!!!!!!!!!!!!!!!!!!!!!!!!
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
//import 'package:hi_bees/helpers/db_helper.dart';
import 'package:provider/provider.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rhino_flutter/rhino.dart';
import 'package:picovoice_flutter/picovoice_error.dart';
import 'package:picovoice_flutter/picovoice_manager.dart';
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
import '../models/weather.dart';
import '../models/weathers.dart';
import '../models/dodatki1.dart';
//void main() {
//  runApp(MyApp());
//}

class VoiceScreen extends StatefulWidget {
  static const routeName = '/screen-voice'; //nazwa trasy do tego ekranu

  const VoiceScreen({super.key});

  @override
  _VoiceScreenState createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final String accessKey = globals.key;
  // 'xPj3ezZa5Y9gQj+v6xQ5YvESy7eLtUcC3NPRFj8E5yDt5MvQWj3b1w=='; // AccessKey obtained from Picovoice Console (https://console.picovoice.ai/)

  //final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isInit = true;
  bool isError = false;
  String errorMessage = "";
  String platform = '';
  bool isButtonDisabled = false; //czy klawisz nieaktywny?
  bool isProcessing =
      false; //czy uruchomiono proces rozpoznawania mowy przyciskiem START
  bool wakeWordDetected = false;
  String rhinoText = "";
  String? contextInfo;
  PicovoiceManager? _picovoiceManager;
  double heightScreen = 601;
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
  bool openDialog = false; //czy otwarte jest jakieś okno pomocy
  double hightSave =
      100; //wysokość wiersza "Save" - zapis zasobu lub info do bazy
  double marginRow = 10; //marginesy dla wierszy 'ul,korpus,ramka' i...
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
      '1'; //1-czarna,2-zółta,3-czerwona,4-zielona,5-niebieska,6-biała
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

  //zmienne pogodowe
  String pobranie = '';
  double temp = 0.0;
  String icon = '';
  String units = 'metric';
  String stopnie = '\u2103';

  int zwloka = 1500;

  @override
  void initState() {
    super.initState();
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
    // nrXXOfHive = 666;
    // nrXOfBody = 1;
    // nrXXOdFrame = 0;
    // nrXXDoFrame = 0;
    // nrXXOfFrame = 10;
    // nrXXOfFramePo = 10;


    initPicovoice();
  }

  @override
  void didChangeDependencies() {

    if (_isInit) {
      formattedDate = formatter.format(now);

      final dod1Data = Provider.of<Dodatki1>(context);
      final dod1 = dod1Data.items;
      zwloka = int.parse(dod1[0].h);
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

  //inicjacja środowiska i zasobow -----------
  // Future<void> initPicovoice() async {
  //   platform = Platform.isAndroid
  //       ? "android"
  //       : Platform.isIOS
  //           ? "ios"
  //           : throw PicovoiceRuntimeException(
  //               "This app supports iOS and Android only.");
  //   String keywordPath =
  //       "assets/keyword_files/$platform/Hi-Maya_${platform}_${globals.jezyk}.ppn";
  //   String contextPath =
  //       "assets/contexts/$platform/apiary_${platform}_${globals.jezyk}.rhn";
  //   print('1 initPicovoice ....................');
  //   print(keywordPath);
  //   print(contextPath);
  //   String rhinoModelPath = "assets/rhino/rhino_params_${globals.jezyk}.pv";
  //   String porcupineModelPath =
  //       "assets/porcupine/porcupine_params_${globals.jezyk}.pv";
  //   //tworzenie instancji Managera przy pomocy słowa kluczowego i przekazanie mu plików kontekstu (Rhino)
  //   //wakeWordCallback i inferenceCallback - funkcje do wykonania po wykryciu wywołania i po wnioskowaniu
  //   _picovoiceManager = PicovoiceManager.create(
  //       accessKey,
  //       keywordPath,
  //       wakeWordCallback,
  //       contextPath,
  //       inferenceCallback,
  //       porcupineModelPath,
  //       rhinoModelPath,
  //       processErrorCallback:
  //           errorCallback); // //porcupineModelPath,rhinoModelPath,
  //   setState(() {
  //     isButtonDisabled = false;
  //   });
  // }

  Future<void> initPicovoice() async {

    String platform = Platform.isAndroid
        ? "android"
        : Platform.isIOS
            ? "ios"
            : throw PicovoiceRuntimeException(
                "This demo supports iOS and Android only.");

    String wakeWordPath =
        "assets/keyword_files/$platform/Hi-Maya_${platform}_${globals.jezyk}.ppn";
    // "assets/keywords/$platform/${wakeWordName}_$platform.ppn";
    String contextPath =
        "assets/contexts/$platform/apiary_${platform}_${globals.jezyk}.rhn";
    //"assets/contexts/$platform/${contextName}_$platform.rhn";
    String? porcupineModelPath =
        "assets/porcupine/porcupine_params_${globals.jezyk}.pv";
    //language != "en" ? "assets/models/porcupine_params_$language.pv" : null;
    String? rhinoModelPath = "assets/rhino/rhino_params_${globals.jezyk}.pv";
    //language != "en" ? "assets/models/rhino_params_$language.pv" : null;

    try {
      _picovoiceManager = await PicovoiceManager.create(accessKey, wakeWordPath,
          wakeWordCallback, contextPath, inferenceCallback,
          porcupineModelPath: porcupineModelPath,
          rhinoModelPath: rhinoModelPath,
          processErrorCallback: errorCallback);
      setState(() {
        isButtonDisabled = false;
        contextInfo = _picovoiceManager!.contextInfo;
      });
    } on PicovoiceActivationException {
      errorCallback(
          PicovoiceActivationException("AccessKey activation error."));
    } on PicovoiceActivationLimitException {
      errorCallback(PicovoiceActivationLimitException(
          "AccessKey reached its device limit."));
    } on PicovoiceActivationRefusedException {
      errorCallback(PicovoiceActivationRefusedException("AccessKey refused."));
    } on PicovoiceActivationThrottledException {
      errorCallback(PicovoiceActivationThrottledException(
          "AccessKey has been throttled."));
    } on PicovoiceException catch (ex) {
      errorCallback(ex);
    }
  }

  //zdekodowano słowo wybudzenia - wybudzono słowem - czekanie na polecenie
  void wakeWordCallback() {
    //print('2 wakeWordCallback - słowo wybudzania zdekodowani i jest oczekiwanie na intencje ...................');

    if (this.mounted)//{
      setState(() {
        //print('wywołanie setState w wakeWordCallback  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        //czyJesWidget = false;
        wakeWordDetected = true;
        rhinoText = AppLocalizations.of(context)!.hiBeesDetected;
        //"\"Hi Bees!\" detected!\nListening for intent...\n\nWant help - say \"Help me!\""; //po słowie wybudzenia
        platform == 'android'
          ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_PROP_BEEP2)
          : FlutterBeep.playSysSound(iOSSoundIDs.BeginRecording);//hiBeesDetected
      });
   
      //  platform == 'android'
      //   ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_PROP_BEEP2)
      //   : FlutterBeep.playSysSound(iOSSoundIDs.BeginRecording);
      //print('beep - BeginRecording - sygnał ze jest wybudzenie');
 //   } else beep('error');
  }

//funkcja wywołania zwrotnego przyjmuje parametr RhinoInterface z parametrami: isUnderstood - czy Rhino zrozumiał na podstawie kontekstu, intent - nazwa intencji jeśli zrozumiał, slots - klucz i wartość wnioskowania
  void inferenceCallback(RhinoInference inference) {
    //print('3 inferenceCallback wywołanie zwrotne czy zrozumiał i co zrozumiał............');
    //print(' !!!!!!!!!! wyołanie setState w inferenceCallback  - tu sie wywala bo nie ma widgetu "build"');
    if (this.mounted)
    setState(() {
      //print('3 11111 wywołanie setState w inferenceCallback - wywołanie funkcji obsługi polecenia głosowego  - tworzenie tekstów');
      rhinoText = prettyPrintInference(inference);
      wakeWordDetected = false;
    });

    //print('!!!!!!!!!!! zakończenie tworzenia tekstów i wpisów do bazy ?????? !!!!!!!!!!!!1');
    //print(' funkcja delayed zwłoka ======== $zwloka' opóznienie zeby wykonały sie wszystkie operacje );
    Future.delayed(Duration(milliseconds: zwloka), () {
      if (isProcessing) {
        if (wakeWordDetected) {
          //print('3 2222222 isProcessing delayed - jest wybudzenie - usłyszano hej Maja');
          rhinoText = AppLocalizations.of(context)!.hiBeesDetected;
          platform == 'android'
            ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_PROP_BEEP2)
            : FlutterBeep.playSysSound(iOSSoundIDs.BeginRecording);//hiBeesDetected
          //FlutterBeep.playSysSound(iOSSoundIDs.BeginRecording);
          //FlutterBeep.playSysSound(iOSSoundIDs.Headset_StartCall);
        } else {
          // print('3 3333333  isProcessing delayed - nie ma wybudzenia - czekanie na hej Maja');
          // print(' tu tez sie wywala bo chce wywołać setState');
          if (this.mounted)
          setState(() {
            rhinoText = AppLocalizations.of(context)!.listeningForHiBees;
            // "Listening for \"Hi Bees!\""; //po zakończeniu wnioskowania
            //if (Platform.isAndroid) test = 'delayed';//!!!!!!!!!!!!!!!!!!!!!!!!!!
            platform == 'android'
              ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_PROP_PROMPT)
              : FlutterBeep.playSysSound(iOSSoundIDs.JBL_Begin);
          });
          //rhinoText += "\"Hi Bees\"";
          //wykonanie polecenia - realizacja intencji i powrót do oczekiwania na wybudzenie
          // platform == 'android'
          //     ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_PROP_PROMPT)
          //     : FlutterBeep.playSysSound(iOSSoundIDs.JBL_Begin);
          //: FlutterBeep.playSysSound(iOSSoundIDs.ConnectedToPower); //nie działa na iPhone
          // print('beep - ConnectedToPower - wykonanie polecenia - realizacja intencji i powrót do oczekiwania na wybudzenie');
          // print('3  444444444  na końcu inferenceCallback ??????????????? czyJesWidget = $czyJesWidget');
        }
      } else {
        //debugPrint('333-3 isProcessing delayed - nieaktywny isProcesing, ');       
        if (this.mounted)
        setState(() {
          rhinoText = "";
        });
      }
    });
  }

  void errorCallback(PicovoiceException error) {
    if (error.message != null) {
      print('4 errorCallback ..............................');

      setState(() {
        isError = true;
        errorMessage = error.message!;
        isProcessing = false;
        //if (Platform.isAndroid) test = 'errorCallback';//!!!!!!!!!!!!!!!!!!!!!!!!!!
      });
    }
  }

  String prettyPrintInference(RhinoInference inference) {
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
        print('setMoveBody');
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
                print('nrTempHalfBody');
                  nrTempHalfBody = int.parse('${slots[key]}');
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
                print('nrTempFrame');
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
              else {nrTempBody = nrTempHalfBody; typ = 1;}
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
                    if(frames[i].zasob != 14) //jezeli jest rózne od "isDone" czyli prawdopodobnie jest = "usuń ramka"
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
                        frames[i].wartosc,
                        0);
                    else //więc jezeli jest "usuń ramka" to zamień na "wstaw ramka"
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
                        _dialogBuilderHelp(context);
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
                        _dialogBuilderHelp(context);
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
                      case 'lokacja':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderLocation(context);
                        beep('open');
                        openDialog = true;
                        break;
                      case 'przegląd':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderInspection(context);
                        beep('open');
                        openDialog = true;
                        break;
                      case 'wyposażenie':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderEquipment(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'pokarm':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderFeeding(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'leczenie':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderTreatement(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'matka':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderQueen(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'rodzina':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderColony(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'zbiór':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderHarvest(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'data':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderDate(context);
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
                        _dialogBuilderLocation(context);
                        beep('open');
                        openDialog = true;
                        break;
                      case 'inspection':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderInspection(context);
                        beep('open');
                        openDialog = true;
                        break;
                      case 'equipment':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderEquipment(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'feeding':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderFeeding(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'treatment':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderTreatement(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'queen':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderQueen(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'colony':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderColony(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'harvest':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderHarvest(context);
                        openDialog = true;
                        beep('open');
                        break;
                      case 'date':
                        if (openDialog) Navigator.pop(context); //zamknij okno
                        printText1 = ' ${slots[key]}';
                        _dialogBuilderDate(context);
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
                    resetSumowania();
                    resetBody();
                    resetStory();
                    //Navigator.pop(context);
                  } else {
                    if (readyApiary == true) {
                      printText1 += AppLocalizations.of(context)!.allHivesAre;
                      printText1 += " ${slots[key]}";
                      readyAllHives = true;
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
                      // _dialogBuilderHelp(context);
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
        return ap.id.contains(numerPasieki.toString());
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
          return element.id.contains('$nrXXOfApiary.$nrXXOfHive');
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
      '0',
      '0',
      '0',
      1, //nieaktualne - zmiana zasobu
    ).then((_) {
      //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
      Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrXXOfApiary)
      .then((_) {
        final hivesData = Provider.of<Hives>(context, listen: false);
        final hives = hivesData.items;
        ileUli = hives.length;
        //print('voice_screen - ilość uli = $ileUli');
        // print(hives.length);
        // print(ileUli);

        //DBHelper.updateIleUli(nrXXOfApiary, ileUli); //

        //zapis do tabeli "pasieki"
        Apiarys.insertApiary(
          '$nrXXOfApiary',
          nrXXOfApiary, //pasieka nr
          ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
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
    Infos.insertInfo(
        '$formattedDate.$nrXXOfApiary.$nrXXOfHive.inspection.${AppLocalizations.of(context)!.inspection}', //id
        formattedDate, //data
        nrXXOfApiary, //pasiekaNr
        nrXXOfHive, //ulNr
        'inspection', //karegoria
        AppLocalizations.of(context)!.inspection, //parametr
        globals.ikonaUla, //wartosc
        '', //miara
        icon, //ikona pogody
        '${temp.toStringAsFixed(0)}$stopnie', //temperatura zaokrąglona do 1 stopnia
        formatedTime, //czas
        '', //uwagi
        0); //niezarchiwizowane

    platform == 'android'
        ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ONE_MIN_BEEP)
        : FlutterBeep.playSysSound(iOSSoundIDs.JBL_NoMatch);
    //print('beep - JBL_NoMatch - insertInfo - zapis info do bazy');
  
  }

  
  /** ZAPIS INFO DO BAZY */

  //info(id TEXT PRIMARY KEY, pasiekaNr INTEGER, ileUli INTEGER, data TEXT, kategoria TEXT, parametr TEXT, wartosc TEXT, miara TEXT, uwagi TEXT)');
  zapisInfoDoBazy(String kat, String param, String wart, String miar) {
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
        final hives = hivesData.items;
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
              miar, //miara
              icon, //ikona pogody
              '${temp.toStringAsFixed(0)}$stopnie', //temperatura zaokrąglona do 1 stopnia
              formatedTime, //czas
              '', //uwagi
              0); //niezarchiwizowane
          //print('kategoria');
          //print(kat);
          //jezeli dokarmianie lub leczenie to zmiana danych do wyświetlania belki w widoku uli
          if (kat == 'feeding' || kat == 'treatment') {

            //zeby nie stracić danych zebranych podczas przeglądu w widoku zbiorczym uli
            Provider.of<Hives>(context, listen: false).fetchAndSetHives(nrXXOfApiary)
            .then((_) {
              final hiveData = Provider.of<Hives>(context, listen: false);
              hive = hiveData.items.where((element) {
                //to wczytanie danych ula
                return element.id.contains('$nrXXOfApiary.${hives[i].ulNr}');
              }).toList();

              if (hive.isNotEmpty) {
                //pobranie danych o ulu
                ikona = hive[0].ikona;
                ramek = hive[0].ramek;
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
              }
            });
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
              '0',
              '0',
              '0',
              0,
            );
          }
        }
      });
      platform == 'android'
          ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ONE_MIN_BEEP)
          : FlutterBeep.playSysSound(iOSSoundIDs.JBL_NoMatch);
      //print('beep - JBL_NoMatch - zapis ula do bazy');
     
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
      Infos.insertInfo(
          '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$kat.$param', //id
          formattedDate, //data
          nrXXOfApiary, //pasiekaNr
          nrXXOfHive, //ulNr
          kat, //karegoria
          param, //parametr
          wart, //wartosc
          miar, //miara
          icon, //ikona pogody
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
            return element.id.contains('$nrXXOfApiary.$nrXXOfHive');
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
            if (wart == 'mała' || wart == 'słaba' || wart == 'zła' || wart == 'stara' ||
                wart == 'small' || wart == 'to exchange' || wart == 'canceled' || wart == 'weak' ) {
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
            if (wart == 'dziewica' || wart == 'virgin') {
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
          '0',
          '0',
          '0',
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

            //DBHelper.updateIleUli(nrXXOfApiary, ileUli); //

            //zapis do tabeli "pasieki"
            Apiarys.insertApiary(
              '$nrXXOfApiary',
              nrXXOfApiary, //pasieka nr
              ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
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
      platform == 'android'
          ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ONE_MIN_BEEP)
          : FlutterBeep.playSysSound(iOSSoundIDs.JBL_NoMatch);
         // print('beep - voice_screen: zapis Info do bazy');
      
      }else{
        platform == 'android'
          ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ONE_MIN_BEEP)
          : FlutterBeep.playSysSound(iOSSoundIDs.JBL_NoMatch);
          // print('beep - voice_screen: zapis Info do bazy');
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

  //uruchomienie przycisku START
  Future<void> _startProcessing() async {
    if (isProcessing) {
      return;
    }

    setState(() {
      isButtonDisabled = true;
    });

    if (_picovoiceManager == null) {
      throw PicovoiceInvalidStateException(
          "_picovoiceManager not initialized.");
    }

    try {
      await _picovoiceManager!.start();
      setState(() {
        isProcessing = true;
        rhinoText = AppLocalizations.of(context)!
            .listeningForHiBees; //"Listening for '$wakeWordName'...";
        isButtonDisabled = false;
      });
    } on PicovoiceException catch (ex) {
      errorCallback(ex);
    }

    //wciśnięcie START
    platform == 'android'
        ? FlutterBeep.playSysSound(
            AndroidSoundIDs.TONE_PROP_BEEP2) // było TONE_CDMA_ONE_MIN_BEEP
        : FlutterBeep.playSysSound(iOSSoundIDs.JBL_Begin);
    print('beep - JBL_Begin - start');
  }

  Future<void> _stopProcessing() async {
    print('7  _stopProcessing...........................');
    if (!isProcessing) {
      return;
    }
   // if (this.mounted) {
      setState(() {
        isButtonDisabled = true;
      });
   // }

    if (_picovoiceManager == null) {
      throw PicovoiceInvalidStateException(
          "_picovoiceManager not initialized.");
    }
    await _picovoiceManager!.stop();
    if (this.mounted) {
    setState(() {
      isProcessing = false;
      rhinoText = "";
      isButtonDisabled = false;
    });
    }
    //beep('close');
  }

  beep(m) {
    switch (m) {
      case 'close':
        platform == 'android'
            ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_PROP_ACK)
            : FlutterBeep.playSysSound(iOSSoundIDs.CameraShutter);
        break;
      case 'open':
        platform == 'android'
            ? FlutterBeep.playSysSound(
                AndroidSoundIDs.TONE_CDMA_KEYPAD_VOLUME_KEY_LITE)
            : FlutterBeep.playSysSound(iOSSoundIDs.EndRecording);
        //print('beep - EndRecording - "open"');
        break;
      case 'error':
        platform == 'android'
            ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_PROP_NACK)
            : FlutterBeep.playSysSound(iOSSoundIDs.VCCallUpgrade);
        break;
    }
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
//Lokacja zasobu
                    TextSpan(
                      text: ("\n" +
                          AppLocalizations.of(context)!.resourceLocationSay),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),

                    TextSpan(text: '\n\n' + AppLocalizations.of(context)!.oPen),
                    TextSpan(
                        text: " " + AppLocalizations.of(context)!.apiary,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\n' + AppLocalizations.of(context)!.oPen),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.allHives,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: '.\n\n' + AppLocalizations.of(context)!.oPen),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.hive,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 5', style: TextStyle(color: Colors.red)),
     //korpus numer               
                    TextSpan(
                        text: '.\n\n' + AppLocalizations.of(context)!.oPen),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.body +
                            '/' +
                            AppLocalizations.of(context)!.halfBody,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
        //ramka numer
                    TextSpan(
                        text: '.\n\n' + AppLocalizations.of(context)!.oPen),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.big +
                            '/' +
                            AppLocalizations.of(context)!.small,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.frame,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 6', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRightBoth +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
         //ramka po przeglądzie
                    TextSpan(
                        text: AppLocalizations.of(context)!.fRame,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 2 ', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.framesAfter,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 5', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\n'),
        //przenieś
                    TextSpan(
                        text: AppLocalizations.of(context)!.mOve),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.hive + ' ' + AppLocalizations.of(context)!.number  + ' 4 ',
                        style: TextStyle(fontStyle: FontStyle.italic)),

                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.body +
                            '/' +
                            AppLocalizations.of(context)!.halfBody,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                     TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.frame,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 10', style: TextStyle(color: Colors.red)),
                   
         //wstaw ramka           
                    TextSpan(
                        text: '\n\n' + AppLocalizations.of(context)!.iNsert),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.big +
                            '/' +
                            AppLocalizations.of(context)!.small,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.frame,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 4', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\n'),
         //ustaw ramka od do                              
                    TextSpan(
                        text: AppLocalizations.of(context)!.sEt,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.frame +
                            ' ' +
                            AppLocalizations.of(context)!.from,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.to,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 9', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n'),
//Przegląd
                    TextSpan(
                      text: ('\n' +
                          AppLocalizations.of(context)!.inspectionSay +
                          '\n'),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    TextSpan(
                        text: AppLocalizations.of(context)!.whenTheApiary +
                            '\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.bRood,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.trut,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 10%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),

                    globals.jezyk == 'pl_PL'
                        ? TextSpan(
                            text: AppLocalizations.of(context)!.bRood,
                            style: TextStyle(fontStyle: FontStyle.italic))
                        : TextSpan(
                            text: AppLocalizations.of(context)!.covered,
                            style: TextStyle(fontStyle: FontStyle.italic)),
                    globals.jezyk == 'pl_PL'
                        ? TextSpan(
                            text: ' ' + AppLocalizations.of(context)!.covered,
                            style: TextStyle(fontWeight: FontWeight.bold))
                        : TextSpan(
                            text: ' ' + AppLocalizations.of(context)!.bRood,
                            style: TextStyle(fontWeight: FontWeight.bold)),

                    TextSpan(text: ' 20%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                            .larvaeEggsPollenHoneySealdWaxComb,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 35%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.queenColors + ' ',
                        style: TextStyle(fontWeight: FontWeight.bold)),

                    TextSpan(
                        text: AppLocalizations.of(context)!.queen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: '2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.queenCells,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: AppLocalizations.of(context)!.dElete),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.queenCells),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n' +
                            AppLocalizations.of(context)!.sEt +
                            ' ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.leftRight),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.site,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .workFrameToExtraction +
                            '.',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            ' - ' + AppLocalizations.of(context)!.tOdo + '\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),

                    TextSpan(
                        text:
                            AppLocalizations.of(context)!.deletedInserted + '.',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' - ' +
                            AppLocalizations.of(context)!.iSdone +
                            '\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),
//  Equipment
                    TextSpan(
                        text: AppLocalizations.of(context)!.equipmentSay + '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.sEt,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text:
                            '  ' + AppLocalizations.of(context)!.numberOfFrame,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' ' + AppLocalizations.of(context)!.inBody),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.isIs,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 10', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.eXclud,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.onBodyNumber),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\n' +
                            AppLocalizations.of(context)!.dElete +
                            ' ' +
                            AppLocalizations.of(context)!.exclud +
                            '.\n\n',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.bOttomBoard,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.isDisinfectedOkDirty +
                            '.'),
                    globals.jezyk == 'pl_PL'
                        ? TextSpan(
                            text:
                                '\n\nZałącz/włacz/wyłacz/otwórz/zamknij/ustaw')
                        : TextSpan(
                            text: '\n\nBee pollen trap',
                            style: TextStyle(fontWeight: FontWeight.bold)),

                    globals.jezyk == 'pl_PL'
                        ? TextSpan(
                            text: ' poławiacz pyłku.\n\n',
                            style: TextStyle(fontWeight: FontWeight.bold))
                        : TextSpan(
                            text:
                                ' is on/off/open/close/activated/eliminated.\n\n'),
//queen
                    TextSpan(
                        text: AppLocalizations.of(context)!.queenSay + '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.wasBornIn),
                    TextSpan(text: ' 23', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.isVirgine +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.isFreed +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.isMarked),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 55.\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.isVeryGoodCanceled +
                            '.\n\n'),
//colony
                    TextSpan(
                        text: AppLocalizations.of(context)!.colonySay + '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.cOlony,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.isIs,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.deadFlight +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.cOlony,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.isIs,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.veryWeakStrong +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.dEadBees,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 250', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.milliliter +
                            '.\n\n'),

//feeding
                    TextSpan(
                        text: AppLocalizations.of(context)!.feedingSay + '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),

                    TextSpan(
                        text: AppLocalizations.of(context)!.syrupOneToOne,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.point,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 5',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.liters +
                            '.\n\n'),

                    TextSpan(
                        text: AppLocalizations.of(context)!.syrupThreeToTwo,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.point,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 5',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.liters +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.bee,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.cAndy,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.point,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 0',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(text: ' kilo.\n\n'),

                    TextSpan(
                        text: AppLocalizations.of(context)!.invert,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.point,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 7',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.liters +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.lEftFood,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 30%', style: TextStyle(color: Colors.red)),
                    globals.jezyk == 'pl_PL'
                        ? TextSpan(text: ' pokarmu.\n\n')
                        : TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.rEmoveFood,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 30%', style: TextStyle(color: Colors.red)),
                    globals.jezyk == 'pl_PL'
                        ? TextSpan(text: ' pokarmu.\n\n')
                        : TextSpan(text: '.\n\n'),
//treatment
                    TextSpan(
                        text: AppLocalizations.of(context)!.treatmentSay + '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),

                    if (globals.jezyk == 'en_US')
                      TextSpan(
                          text: AppLocalizations.of(context)!.apivarolChemistry,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    if (globals.jezyk == 'en_US')
                      TextSpan(
                          text: ' ' + AppLocalizations.of(context)!.first,
                          style: TextStyle(color: Colors.red)),
                    if (globals.jezyk == 'en_US')
                      TextSpan(
                          text: ' ' +
                              AppLocalizations.of(context)!.dosePortionPart +
                              '.\n\n'),

                    TextSpan(
                        text: AppLocalizations.of(context)!.apivarolChemistry,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.dosePortionPart +
                            ' ' +
                            AppLocalizations.of(context)!.number),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),

                    // TextSpan(
                    //     text: 'Biovar',
                    //     style: TextStyle(fontWeight: FontWeight.bold)),
                    // TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    // TextSpan(
                    //     text: ' ' +
                    //         AppLocalizations.of(context)!.belts +
                    //         '.\n\n'),
                    TextSpan(
                        text: 'Biovar ' + AppLocalizations.of(context)!.rem,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.belts +
                            '.\n\n'),

                    TextSpan(
                        text: AppLocalizations.of(context)!.aCid,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 40', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.milliliter +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.vArroa,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 218', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.mites +
                            '.\n\n'),

                    // TextSpan(
                    //     text: AppLocalizations.of(context)!.vArroa,
                    //     style: TextStyle(fontWeight: FontWeight.bold)),
                    // TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    // if (globals.jezyk == 'en_US')
                    //   TextSpan(text: ' hundred mites.\n\n'),
                    // if (globals.jezyk == 'pl_PL')
                    //   TextSpan(text: ' razy sto sztuk.\n\n'),
//zbiory
                    TextSpan(
                        text: AppLocalizations.of(context)!.harvestSay + '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.honeyHarvest,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 10 ', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.razy,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.small +
                            "/" +
                            AppLocalizations.of(context)!.big +
                            " " +
                            AppLocalizations.of(context)!.frame),
                    TextSpan(text: '.\n\n'),

                    TextSpan(
                        text: AppLocalizations.of(context)!.beePollenHarvest,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 2 ', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.razy,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' ' + AppLocalizations.of(context)!.miarka),
                    TextSpan(text: '.\n\n'),

                    TextSpan(
                        text: AppLocalizations.of(context)!.beePollenHarvest,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' 825 ', style: TextStyle(color: Colors.red)),
                    // TextSpan(
                    //     text: AppLocalizations.of(context)!.razy,
                    //     style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: AppLocalizations.of(context)!.milliliter),
                    TextSpan(text: '.\n\n'),

                    TextSpan(
                        text: AppLocalizations.of(context)!.beePollenHarvest,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 0', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.point,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 15',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.liters +
                            '.\n\n'),
                    // if (globals.jezyk == 'pl_PL')
                    //   TextSpan(
                    //       text: 'Zbiór pierzga',
                    //       style: TextStyle(fontWeight: FontWeight.bold)),
                    // if (globals.jezyk == 'pl_PL')
                    //   TextSpan(
                    //       text: ' 3 ', style: TextStyle(color: Colors.red)),
                    // if (globals.jezyk == 'pl_PL')
                    //   TextSpan(
                    //       text: AppLocalizations.of(context)!.razy,
                    //       style: TextStyle(fontStyle: FontStyle.italic)),
                    // if (globals.jezyk == 'pl_PL')
                    //   TextSpan(text: ' miarka/porcja.\n\n'),

//date
                    TextSpan(
                        text: AppLocalizations.of(context)!.dateSay + '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: '\n' + AppLocalizations.of(context)!.setOther),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.day,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 15', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(text: AppLocalizations.of(context)!.setOther),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.month,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(text: AppLocalizations.of(context)!.setOther),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.year,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 22', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(text: AppLocalizations.of(context)!.sEt),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.current,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.datee +
                            '.\n\n'),
//help me
                    TextSpan(
                        text: AppLocalizations.of(context)!.helpSay + '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: '(' +
                            AppLocalizations.of(context)!.forPreciseHelp +
                            ')\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.lOcation,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            ' .\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.iNspection,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            ' .\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.eQuipment,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.cOlony,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.fEeding,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),

                    TextSpan(
                        text: AppLocalizations.of(context)!.tReatment,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.hArvest,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.dAte,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.closeHelp,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.hIve,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.hIve + ' ' + AppLocalizations.of(context)!.before,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),                    
                    TextSpan(
                        text: AppLocalizations.of(context)!.hIve + ' ' + AppLocalizations.of(context)!.after,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.hIve +
                            ' ' +
                            AppLocalizations.of(context)!.earlier,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.hIve +
                            ' ' +
                            AppLocalizations.of(context)!.later,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.helpMe + '.'),

//Legenda
                    TextSpan(
                        text: '\n\n' +
                            AppLocalizations.of(context)!.legend +
                            ':\n',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold)),
                    TextSpan(text: AppLocalizations.of(context)!.normalOr),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.bold,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' - ' +
                            AppLocalizations.of(context)!.requiredText +
                            '.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.italic,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' - ' +
                            AppLocalizations.of(context)!.optionalText +
                            '.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(text: AppLocalizations.of(context)!.text1Text2),
                    TextSpan(
                        text: ' - ' +
                            AppLocalizations.of(context)!.selectableText +
                            '.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' - ' +
                            AppLocalizations.of(context)!.sampleValue +
                            '.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
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
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilderLocation(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: ('\n' +
                          AppLocalizations.of(context)!.resourceLocationSay),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    TextSpan(text: '\n\n' + AppLocalizations.of(context)!.oPen),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.apiary,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\n' + AppLocalizations.of(context)!.oPen),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.allHives,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: '.\n\n' + AppLocalizations.of(context)!.oPen),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.hive,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 5', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\n' + AppLocalizations.of(context)!.oPen),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.body +
                            '/' +
                            AppLocalizations.of(context)!.halfBody,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\n' + AppLocalizations.of(context)!.oPen),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.big +
                            '/' +
                            AppLocalizations.of(context)!.small,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.frame,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 6', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRightBoth +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    
          //ramka po przeglądzie
                    TextSpan(
                        text: AppLocalizations.of(context)!.fRame,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 2 ', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.framesAfter,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 5', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\n'),

          //przenieś
                    TextSpan(
                        text: AppLocalizations.of(context)!.mOve),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.hive + ' ' + AppLocalizations.of(context)!.number  + ' 4 ',
                        style: TextStyle(fontStyle: FontStyle.italic)),

                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.body +
                            '/' +
                            AppLocalizations.of(context)!.halfBody,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                     TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.frame,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 10', style: TextStyle(color: Colors.red)),          
                
             //wstaw ramka          
                    TextSpan(
                        text: '\n\n' + AppLocalizations.of(context)!.iNsert),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.big +
                            '/' +
                            AppLocalizations.of(context)!.small,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.frame,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 4', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\n'),
                    
                    TextSpan(
                        text: AppLocalizations.of(context)!.sEt,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.frame +
                            ' ' +
                            AppLocalizations.of(context)!.from,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.to,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 9', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
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
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilderInspection(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: ('\n' +
                          AppLocalizations.of(context)!.inspectionSay +
                          '\n'),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    TextSpan(
                        text: AppLocalizations.of(context)!.whenTheApiary +
                            '\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.bRood,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.trut,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 10%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    globals.jezyk == 'pl_PL'
                        ? TextSpan(
                            text: AppLocalizations.of(context)!.bRood,
                            style: TextStyle(fontStyle: FontStyle.italic))
                        : TextSpan(
                            text: AppLocalizations.of(context)!.covered,
                            style: TextStyle(fontStyle: FontStyle.italic)),
                    globals.jezyk == 'pl_PL'
                        ? TextSpan(
                            text: ' ' + AppLocalizations.of(context)!.covered,
                            style: TextStyle(fontWeight: FontWeight.bold))
                        : TextSpan(
                            text: ' ' + AppLocalizations.of(context)!.bRood,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 20%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                            .larvaeEggsPollenHoneySealdWaxComb,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 35%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.queenColors + ' ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.queen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: '2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.queenCells,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: AppLocalizations.of(context)!.dElete),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.queenCells),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.leftRight +
                            '.\n\n' +
                            AppLocalizations.of(context)!.sEt +
                            ' ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.leftRight),
                    TextSpan(
                        text: '  ' + AppLocalizations.of(context)!.site,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .workFrameToExtraction +
                            '.',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            ' - ' + AppLocalizations.of(context)!.tOdo + '\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),
                    TextSpan(
                        text:
                            AppLocalizations.of(context)!.deletedInserted + '.',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' - ' +
                            AppLocalizations.of(context)!.iSdone +
                            '\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),
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
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilderEquipment(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
                    //  Equipment
                    TextSpan(
                        text: '\n' +
                            AppLocalizations.of(context)!.equipmentSay +
                            '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.sEt,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text:
                            '  ' + AppLocalizations.of(context)!.numberOfFrame,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' ' + AppLocalizations.of(context)!.inBody),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.isIs,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 10', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: '  ' + AppLocalizations.of(context)!.eXclud,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.onBodyNumber),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\n' +
                            AppLocalizations.of(context)!.dElete +
                            ' ' +
                            AppLocalizations.of(context)!.exclud +
                            '.\n\n',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.bOttomBoard,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.isDisinfectedOkDirty +
                            '.'),

                    globals.jezyk == 'pl_PL'
                        ? TextSpan(
                            text:
                                '\n\nZałącz/włącz/wyłącz/otwórz/zamknij/ustaw')
                        : TextSpan(
                            text: '\n\nBee pollen trap',
                            style: TextStyle(fontWeight: FontWeight.bold)),

                    globals.jezyk == 'pl_PL'
                        ? TextSpan(
                            text: ' poławiacz pyłku.\n\n',
                            style: TextStyle(fontWeight: FontWeight.bold))
                        : TextSpan(
                            text:
                                ' is on/off/open/close/activated/eliminated.\n\n'),
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
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilderQueen(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
//queen
                    TextSpan(
                        text: '\n' +
                            AppLocalizations.of(context)!.queenSay +
                            '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.wasBornIn),
                    TextSpan(text: ' 23', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.isVirgine +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.isFreed +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.isMarked),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.number,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 55.\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.isVeryGoodCanceled +
                            '.\n\n'),
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
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilderColony(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
//colony
                    TextSpan(
                        text: '\n' +
                            AppLocalizations.of(context)!.colonySay +
                            '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.cOlony,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.isIs,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.deadFlight +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.cOlony,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.isIs,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.veryWeakStrong +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.dEadBees,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 250', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.milliliter +
                            '.\n\n'),
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
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilderFeeding(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
//feeding
                    TextSpan(
                        text: '\n' +
                            AppLocalizations.of(context)!.feedingSay +
                            '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),

                    TextSpan(
                        text: AppLocalizations.of(context)!.syrupOneToOne,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.point,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 5',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.liters +
                            '.\n\n'),

                    TextSpan(
                        text: AppLocalizations.of(context)!.syrupThreeToTwo,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.point,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 5',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.liters +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.bee,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.cAndy,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.point,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 0',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(text: ' kilo.\n\n'),

                    TextSpan(
                        text: AppLocalizations.of(context)!.invert,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.point,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 7',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.liters +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.lEftFood,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 30%', style: TextStyle(color: Colors.red)),
                    globals.jezyk == 'pl_PL'
                        ? TextSpan(text: ' pokarmu.\n\n')
                        : TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.rEmoveFood,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 30%', style: TextStyle(color: Colors.red)),
                    globals.jezyk == 'pl_PL'
                        ? TextSpan(text: ' pokarmu.\n\n')
                        : TextSpan(text: '.\n\n'),
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
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilderTreatement(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
//treatment
                    TextSpan(
                        text: '\n' +
                            AppLocalizations.of(context)!.treatmentSay +
                            '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    if (globals.jezyk == 'en_US')
                      TextSpan(
                          text: AppLocalizations.of(context)!.apivarolChemistry,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    if (globals.jezyk == 'en_US')
                      TextSpan(
                          text: ' ' + AppLocalizations.of(context)!.first,
                          style: TextStyle(color: Colors.red)),
                    if (globals.jezyk == 'en_US')
                      TextSpan(
                          text: ' ' +
                              AppLocalizations.of(context)!.dosePortionPart +
                              '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.apivarolChemistry,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.dosePortionPart +
                            ' ' +
                            AppLocalizations.of(context)!.number),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    // TextSpan(
                    //     text: 'Biovar',
                    //     style: TextStyle(fontWeight: FontWeight.bold)),
                    // TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    // TextSpan(
                    //     text: ' ' +
                    //         AppLocalizations.of(context)!.belts +
                    //         '.\n\n'),
                    TextSpan(
                        text: 'Biovar ' + AppLocalizations.of(context)!.rem,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.belts +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.aCid,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 40', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.milliliter +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.vArroa,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 218', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.mites +
                            '.\n\n'),
                    // TextSpan(
                    //     text: AppLocalizations.of(context)!.vArroa,
                    //     style: TextStyle(fontWeight: FontWeight.bold)),
                    // TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    // if (globals.jezyk == 'en_US')
                    //   TextSpan(text: ' hundred mites.\n\n'),
                    // if (globals.jezyk == 'pl_PL')
                    //   TextSpan(text: ' razy sto sztuk.\n\n'),
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
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilderHarvest(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
//zbiory
                    TextSpan(
                        text: '\n' +
                            AppLocalizations.of(context)!.harvestSay +
                            '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.honeyHarvest,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 10 ', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.razy,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.small +
                            "/" +
                            AppLocalizations.of(context)!.big +
                            " " +
                            AppLocalizations.of(context)!.frame),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.beePollenHarvest,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 2 ', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.razy,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' ' + AppLocalizations.of(context)!.miarka),
                    TextSpan(text: '.\n\n'),

                    TextSpan(
                        text: AppLocalizations.of(context)!.beePollenHarvest,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 0', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.point,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 15',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.liters +
                            '.\n\n'),
                    // if (globals.jezyk == 'pl_PL')
                    //   TextSpan(
                    //       text: 'Zbiór pierzga',
                    //       style: TextStyle(fontWeight: FontWeight.bold)),
                    // if (globals.jezyk == 'pl_PL')
                    //   TextSpan(
                    //       text: ' 3 ', style: TextStyle(color: Colors.red)),
                    // if (globals.jezyk == 'pl_PL')
                    //   TextSpan(
                    //       text: AppLocalizations.of(context)!.razy,
                    //       style: TextStyle(fontStyle: FontStyle.italic)),
                    // if (globals.jezyk == 'pl_PL')
                    //   TextSpan(text: ' miarka/porcja.\n\n'),
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
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilderHelp(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
//help me
                    TextSpan(
                        text:
                            '\n' + AppLocalizations.of(context)!.helpSay + '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: '(' +
                            AppLocalizations.of(context)!.forPreciseHelp +
                            ')\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.lOcation,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            ' .\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.iNspection,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.eQuipment,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.qUeen,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.cOlony,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.fEeding,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.tReatment,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.hArvest,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.dAte,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.closeHelp,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                                .whenAtLeastApiaryAndHive +
                            '\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.hIve,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.hIve + ' ' + AppLocalizations.of(context)!.before,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),                    
                    TextSpan(
                        text: AppLocalizations.of(context)!.hIve + ' ' + AppLocalizations.of(context)!.after,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.hIve +
                            ' ' +
                            AppLocalizations.of(context)!.earlier,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.helpMe +
                            '.\n\n'),
                    TextSpan(
                        text: AppLocalizations.of(context)!.hIve +
                            ' ' +
                            AppLocalizations.of(context)!.later,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.helpMe + '.'),

                    TextSpan(
                        text: '\n\n' +
                            AppLocalizations.of(context)!.legend +
                            ':\n',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold)),
                    TextSpan(text: AppLocalizations.of(context)!.normalOr),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.bold,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' - ' +
                            AppLocalizations.of(context)!.requiredText +
                            '.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: AppLocalizations.of(context)!.italic,
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' - ' +
                            AppLocalizations.of(context)!.optionalText +
                            '.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(text: AppLocalizations.of(context)!.text1Text2),
                    TextSpan(
                        text: ' - ' +
                            AppLocalizations.of(context)!.selectableText +
                            '.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' - ' +
                            AppLocalizations.of(context)!.sampleValue +
                            '.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
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
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilderDate(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
//date
                    TextSpan(
                        text:
                            '\n' + AppLocalizations.of(context)!.dateSay + '\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: '\n' + AppLocalizations.of(context)!.setOther),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.day,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 15', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(text: AppLocalizations.of(context)!.setOther),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.month,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(text: AppLocalizations.of(context)!.setOther),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.year,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 22', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(text: AppLocalizations.of(context)!.sEt),
                    TextSpan(
                        text: ' ' + AppLocalizations.of(context)!.current,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' ' +
                            AppLocalizations.of(context)!.datee +
                            '.\n\n'),
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
              },
            ),
          ],
        );
      },
    );
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
        return fr.data.contains(wybranaData) && fr.ramkaNrPo > 0; //tylko ramki "Po" 
      }).toList();
    else
      frames = framesData.items.where((fr) {
        return fr.data.contains(wybranaData) && fr.ramkaNr > 0; //tylko ramki "Po" 
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
      return inf.data.contains(wybranaData);
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

    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        //backgroundColor: const Color.fromRGBO(55, 125, 255, 1),
        backgroundColor:
            Theme.of(context).primaryColor, //Color.fromARGB(255, 233, 140, 0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)));

//dla mniejszych ekranów zmiana wysokośći wiersza  'Save' - zapis zasobu do bazy
//sony Z3 592px, mały ios 568px
    heightScreen = MediaQuery.of(context).size.height;
    // print('wysokość ekranu');
    // print(heightScreen);
    if (heightScreen < 600 && heightScreen > 590) {
      hightSave = 60;
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
          return element.id.contains('$nrXXOfApiary.$nrXXOfHive');
        }).toList();
            // print('voice hive (${hive[0].matka1} != '' || ${hive[0].matka2} != '' || ${hive[0].matka3} != '' || ${hive[0].matka4} != '' || ${hive[0].matka5} != '' )');
            // print(
            //       ' voice hive ${hive[0].ulNr}: t${hive[0].trut}, c${hive[0].czerw}, l${hive[0].larwy}, j${hive[0].jaja}, p${hive[0].pierzga}, m${hive[0].miod}, d${hive[0].dojrzaly},w${hive[0].weza}, s${hive[0].susz}, m${hive[0].matka}, mt${hive[0].mateczniki}, dm${hive[0].usunmat} , td${hive[0].todo} m1${hive[0].matka1} m2${hive[0].matka2} m3${hive[0].matka3} m4${hive[0].matka4} m5${hive[0].matka5}');
      //print('widget "build" uruchomiony - mozna działać !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      //czyJesWidget = true;   
      }); 
    }

    return MaterialApp(
      home: Scaffold(
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
            IconButton(
              icon:
                  Icon(Icons.help_center, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () => _dialogBuilder(context),
            )
          ],
        ),
        body: Column(
          children: [
            buildAnswerArea(context),
            //buildStartButton(context),
            buildRhinoTextArea(context),
            buildErrorMessage(context),
            //footer,
            const SizedBox(
              height: 50,
            ),
          ],
        ),

        //=== stopka
        bottomSheet: Container(
          //margin:  EdgeInsets.only(bottom:15),
          height: 100,
          color: Colors.white,
          //width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const SizedBox(
                    width: 9,
                  ),
                  SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: buttonStyle,
                        onPressed: (isButtonDisabled || isError)
                            ? null
                            : isProcessing
                                ? _stopProcessing
                                : _startProcessing,
                        child: Text(isProcessing ? "STOP" : "START",
                            style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 0, 0,
                                    0))), // fontWeight: FontWeight.bold
                      )),
                  const SizedBox(
                    width: 15,
                  ), //interpolacja ciągu znaków
                ],
              )
            ],
          ),
        ),
      ),
    );
   
  }

  
  
  buildAnswerArea(BuildContext context) {
    
    return Expanded(
      flex: 4,
      child: Container(
          color: Color.fromARGB(255, 255, 255, 255),
          alignment: Alignment.center,
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
            
//wiersz pasieka
              heightScreen < 590
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (readyApiary)
                          Expanded(
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.only(
                                  top: 5, left: 20, right: 20),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (readyApiary)
                          Expanded(
                            child: Container(
                              height: 45,
                              padding: const EdgeInsets.only(
                                  top: 5, left: 20, right: 20),
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
                                  AppLocalizations.of(context)!
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

//wiersz z ul, korpus ramka
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
//ul numer
                if (readyHive)
                  heightScreen < 590
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
                      : Container(
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
                  heightScreen < 590
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
                      : Container(
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
                  heightScreen < 590
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
                      : Container(
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
                  heightScreen < 590
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
                      : Container(
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
                  heightScreen < 590
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
                      : Container(
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
              ]),

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
                        if(hive.isNotEmpty && hive[0].matka1 == 'ok')
                        Icon(Icons.thumb_up_outlined,color: Color.fromARGB(255, 15, 200, 8),) 
                        else if(hive[0].matka1 == 'zła') Icon(Icons.thumb_down_outlined,color: Color.fromARGB(255, 255, 0, 0),), 
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
                  heightScreen < 590
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                //width: 100,
                                height: 40,
                                padding: const EdgeInsets.only(
                                    top: 5, bottom: 5, left: 20, right: 20),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      //color: Colors.black,
                                      width: 3.0,
                                      style: BorderStyle.solid),
                                  borderRadius: BorderRadius.circular(20),
                                  //color: Colors.yellowAccent,
                                ),
                                //color: Colors.blue,
                                child: Column(
                                  children: [
                                    Text(
                                      "$sizeOfFrame " +
                                          AppLocalizations.of(context)!
                                              .frameOn +
                                          " $siteOfFrame " +
                                          AppLocalizations.of(context)!.site,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                //width: 100,
                                height: 45,
                                padding: const EdgeInsets.only(
                                    top: 5, bottom: 5, left: 20, right: 20),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      //color: Colors.black,
                                      width: 3.0,
                                      style: BorderStyle.solid),
                                  borderRadius: BorderRadius.circular(20),
                                  //color: Colors.yellowAccent,
                                ),
                                //color: Colors.blue,
                                child: Column(
                                  children: [
                                    Text(
                                      "$sizeOfFrame " +
                                          AppLocalizations.of(context)!
                                              .frameOn +
                                          " $siteOfFrame " +
                                          AppLocalizations.of(context)!.site,
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ],
                        ),

//zapis zasobu
              if (readyStory && !readyInfo)
                heightScreen < 590
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              //width: 100,
                              height: 60,
                              margin: EdgeInsets.only(top: marginRow),
                              padding:
                                  EdgeInsets.only(top: 7, left: 20, right: 20),
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
                                          style: TextStyle(
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
                      )
                    : Row(
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
                                          style: TextStyle(
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
                heightScreen < 590
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              //width: 100,
                              height: 75,
                              margin: EdgeInsets.only(top: marginRow),
                              padding:
                                  EdgeInsets.only(top: 7, left: 20, right: 20),
                              child: Column(
                                children: [
                                  Text(AppLocalizations.of(context)!.save +
                                      " info:"),
                                  nrXXOfApiary != 0 &&
                                          (nrXXOfHive != 0 || readyAllHives)
                                      ? Text(
                                          zapis,
                                          style: TextStyle(
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
                    : Row(
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
                                          style: TextStyle(
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
          )),
    );
  }

  buildRhinoTextArea(BuildContext context) {
    return Expanded(
        flex: 2,
        child: Container(
            alignment: Alignment.center,
            color: Color.fromARGB(255, 255, 255, 255),
            //margin: EdgeInsets.all(15),
            padding: EdgeInsets.all(15),
            child: heightScreen < 600
                ? Text(rhinoText,
                    style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0), fontSize: 15))
                : Text(
                    rhinoText,
                    style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0), fontSize: 18),
                  )));
  }

  buildErrorMessage(BuildContext context) {
    return Expanded(
        flex: isError ? 4 : 0,
        child: Container(
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
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  )));
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
