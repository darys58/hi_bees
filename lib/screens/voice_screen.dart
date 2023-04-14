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

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hi_bees/helpers/db_helper.dart';
import 'package:provider/provider.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:wakelock/wakelock.dart';
//import 'package:audioplayers/audioplayers.dart';

import 'package:rhino_flutter/rhino.dart';
import 'package:picovoice_flutter/picovoice_manager.dart';
import 'package:picovoice_flutter/picovoice_error.dart';
import 'package:intl/intl.dart';
import '../globals.dart' as globals;
import '../models/frame.dart';
import '../models/frames.dart';
import '../models/hives.dart';
import '../models/apiarys.dart';
//import '../models/info.dart';
import '../models/infos.dart';
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
  PicovoiceManager? _picovoiceManager;
  var now = new DateTime.now();
  var formatter = new DateFormat('yyyy-MM-dd');
  var formatterHm = new DateFormat('H:mm');
  String formattedDate = '';
  String ustawianaData = '';
  String formatedTime = '';
  List<Frames> frame = [];
  String ikona = '';
  String opis = '';
  int ileUli = 0;
  String miejsce = '0';
  String zapis = '0'; //co i ile zostanie zapisane w bazie
  bool openDialog = false; //czy otwarte jest jakieś okno pomocy
  //AudioPlayer player = AudioPlayer();

  bool readyApiary = false; //ustalony numer pasieki
  bool readyAllHives = false; //polecenia dla wszy
  bool readyHive = false; //ustalony numer ula
  bool readyBody = false; //ustalony numer korpusu
  bool readyHalfBody = false; //ustalony numer półkorpusu
  bool readyFrame = false; //ustalony numer ramki
  bool readyStory = false; //gotowość do zapisu w bazie poszczególnych produktów
  bool readyInfo = false; //gotowość do zapisu info

  //intents
  String intention = '';

  //slots
  String helpMe = 'close help'; //wywołanie pomocy
  String apiaryState = 'close'; //stan pasieki
  int nrXXOfApiary = 0; //numer pasieki
  int nrXXOfApairyTemp = 0;
  String allHivesState = 'close';
  String hiveState = 'close';
  int nrXXOfHive = 0;
  int nrXXOfHiveTemp =
      0; //tymczasowy numer ula potrzebny przy resecie bo inna kolejność pól w slocie
  String bodyState = 'close';
  int nrXOfBody = 0;
  int nrXOfBodyTemp = 0;
  String halfBodyState = 'close';
  int nrXOfHalfBody = 0;
  int nrXOfHalfBodyTemp = 0;
  String frameState = 'close';
  int nrXXOfFrame = 0;
  int nrXXOfFrameTemp = 0;
  String siteOfFrame = 'both'; //whole, left, right
  String sizeOfFrame = 'big'; //small   2-duza, 1-mała
  String site = 'left'; //left, right  - dla moved
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

  int _korpusNr = 0;
  int _typ = 0; //2-korpus, 1-półkorpus
  int _rozmiar = 0; //2-big, 1-small
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

  @override
  void initState() {
    super.initState();
    setState(() {
      isButtonDisabled = true;
      rhinoText = "";
      Wakelock.enable(); //blokada wyłaczania ekranu
    });

    initPicovoice();
  }

  @override
  void didChangeDependencies() {
    print('voice_screen: wejscie do Dependencies ms 1');

    print('voice_screen: _isInit = $_isInit');
    if (_isInit) {
      formattedDate = formatter.format(now);
      Provider.of<Frames>(context, listen: false).fetchAndSetFrames().then((_) {
        print('voice_screen: pobrano wszystkie ramki z bazy lokalnej do voice');
      });
    }
    // Provider.of<Hives>(context, listen: false)
    //       .fetchAndSetHives(globals.pasiekaID)
    //       .then((_) {
    //     //wszystkie ule z tabeli ule z bazy lokalnej
    //   });
    _isInit = false;
    //Provider.of<Rests>(context, listen: false).fetchAndSetRests(); //dostawca restauracji
    super.didChangeDependencies();
  }

  //inicjacja środowiska i zasobow -----------
  Future<void> initPicovoice() async {
    platform = Platform.isAndroid
        ? "android"
        : Platform.isIOS
            ? "ios"
            : throw PicovoiceRuntimeException(
                "This app supports iOS and Android only.");
    String keywordPath = "assets/keyword_files/$platform/hi-bees_$platform.ppn";
    String contextPath = "assets/contexts/$platform/apiary_$platform.rhn";
    //tworzenie instancji Managera przy pomocy słowa kluczowego i przekazanie mu plików kontekstu (Rhino)
    //wakeWordCallback i inferenceCallback - funkcje do wykonania po wykryciu wywołania i po wnioskowaniu
    _picovoiceManager = PicovoiceManager.create(accessKey, keywordPath,
        wakeWordCallback, contextPath, inferenceCallback,
        processErrorCallback: errorCallback);
    setState(() {
      isButtonDisabled = false;
    });
  }

  //zdekodowano słowo wybudzenia - wybudzono słowem - czekanie na polecenie
  void wakeWordCallback() {
    //print('111 oczekiwanie na intencje');
    setState(() {
      wakeWordDetected = true;
      rhinoText =
          "\"Hi Bees!\" detected!\nListening for intent...\n\nWant help - say \"Help me!\""; //po słowie wybudzenia
    });
    //wciśnięcieSTART
    platform == 'android'
        ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_PROP_BEEP2)
        : FlutterBeep.playSysSound(iOSSoundIDs.BeginRecording);
  }

//funkcja wywołania zwrotnego przyjmuje parametr RhinoInterface z parametrami: isUnderstood - czy Rhino zrozumiał na podstawie kontekstu, intent - nazwa intencji jeśli zrozumiał, slots - klucz i wartość wnioskowania
  void inferenceCallback(RhinoInference inference) {
    //print('111-3 wywołanie zwrotne czy zrozumiał i co zrozumiał');
    setState(() {
      rhinoText = prettyPrintInference(inference);
      wakeWordDetected = false;
    });

    //print('zmienn apiaryState = $apiaryState');

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (isProcessing) {
        if (wakeWordDetected) {
          //print('111-3 delayed - jest wybudzenie');
          rhinoText =
              "\"Hi Bees!\" detected!\nListening for intent...\n\nWant help - say \"Help me!\"";
          //FlutterBeep.playSysSound(iOSSoundIDs.BeginRecording);
          //FlutterBeep.playSysSound(iOSSoundIDs.Headset_StartCall);
        } else {
          //print('111-3 delayed - nie ma wybudzenia');
          setState(() {
            rhinoText =
                "Listening for \"Hi Bees!\""; //po zakończeniu wnioskowania  
          });
          //rhinoText += "\"Hi Bees\"";
            platform == 'android'
                ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_PROP_PROMPT)
                : FlutterBeep.playSysSound(iOSSoundIDs.ConnectedToPower);
        }
      } else {
       // print('111-3 delayed - nieaktywny isProcesing, ');
        setState(() {
          rhinoText = "";
        });
      }
    });
  }

  void errorCallback(PicovoiceException error) {
    if (error.message != null) {
      //print('111-4 errorCallback ');
      setState(() {
        isError = true;
        errorMessage = error.message!;
        isProcessing = false;
      });
    }
  }

  String prettyPrintInference(RhinoInference inference) {
    String printText = ""; //ogólny
    String printText1 = ""; //dla części State

    if (inference.isUnderstood!) {
      //printText += "I uderstood :)\n";
    } else {
      printText += "I not uderstood :(";
      beep('error');
    }

    //printText += " - ${inference.isUnderstood}\n\n";
    // "{\n    \"isUnderstood\" : \"${inference.isUnderstood}\",\n";
    if (inference.isUnderstood!) {
      //printText += "  intent: ${inference.intent}\n\n";
      //printText += "    \"intent\" : \"${inference.intent}\",\n";
      switch (inference.intent) {
        case 'setApiary':
          printText += " Apiary";
          intention = 'setApiary';
          break;
        case 'setHive':
          printText += " Hive";
          intention = 'setHive';
          break;
        case 'setAllHives':
          printText += " All Hives";
          intention = 'setAllHives';
          break;
        case 'setBody':
          printText += " Body";
          intention = 'setBody';
          break;
        case 'setHalfBody':
          printText += " Half Body";
          intention = 'setHalfBody';
          break;
        case 'setFrame':
          printText += " Frame";
          intention = 'setFrame';
          break;
        case 'setStore':
          printText += " Store:";
          intention = 'setStore';
          break;
        case 'setEquipment':
          printText += " Equipment:";
          intention = 'setEquipment';
          break;
        case 'feeding':
          printText += " Feeding:";
          intention = 'feeding';
          break;
        case 'treatment':
          printText += " Treatment:";
          intention = 'treatment';
          break;
        case 'setQueen':
          printText += " Queen:";
          intention = 'setQueen';
          break;
        case 'setColony':
          printText += " Colony:";
          intention = 'setColony';
          break;
        case 'setHelp':
          printText += " Help me:";
          intention = 'setHelp';
          break;
        case 'setDate':
          printText += " Date:";
          intention = 'setDate';
          break;
      }

      if (inference.slots!.isNotEmpty) {
        //printText += '    "slots" : {\n';
        Map<String, String> slots = inference.slots!;
        for (String key in slots.keys) {
          // printText += "   $key: ${slots[key]},\n";
          //  printText += "        \"$key\" : \"${slots[key]}\",\n";
          switch (key) {
            case 'helpMe':
              helpMe = '${slots[key]}';
              switch (helpMe) {
                case 'help':
                  if (openDialog) Navigator.pop(context); //zamknij okno
                  printText1 = ' ${slots[key]}';
                  _dialogBuilderHelp(context);
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
                case 'date':
                  if (openDialog) Navigator.pop(context); //zamknij okno
                  printText1 = ' ${slots[key]}';
                  _dialogBuilderDate(context);
                  openDialog = true;
                  beep('open');
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
              break;
            case 'apiaryState':
              apiaryState = '${slots[key]}';
              if (apiaryState == 'close') {
                beep('close');
                printText1 += " ${slots[key]}";
                readyApiary = false;
                nrXXOfApiary = 0;
                nrXXOfApairyTemp = 0;
                readyHive = false;
                nrXXOfHive = 0;
                bodyState = 'close';
                readyBody = false;
                readyInfo = false;
                resetBody();
                resetFrame();
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
                hiveState = 'close';
                readyAllHives = false;
                allHivesState = 'close';
                nrXXOfHive = 0;
                bodyState = 'close';
                readyBody = false;
                readyInfo = false;
                resetBody();
                resetFrame();
              }
              break;
            case 'nrXXOfApiary':
              nrXXOfApiary = int.parse('${slots[key]}');
              if (apiaryState == 'open' || apiaryState == 'set') {
                printText1 += " ${slots[key]}";
                nrXXOfApairyTemp = nrXXOfApiary;
                readyApiary =
                    true; // ustawienie Apairy - kolejność wnioskowania poprawna
                beep('open');
                //zerowanie danych Hive, Body i Frame
                readyHive = false;
                hiveState = 'close';
                readyAllHives = false;
                allHivesState = 'close';
                nrXXOfHive = 0;
                bodyState = 'close';
                readyBody = false;
                readyInfo = false;
                resetBody();
                resetFrame();
              } else {
                //przypadek kiedy najpierw będzie numer a pózniej status pasieki (a teraz jest close)
                printText1 += " ${slots[key]}";
                nrXXOfApairyTemp = nrXXOfApiary;
                nrXXOfApiary = 0;
                readyApiary = false;
                readyHive = false;
                nrXXOfHive = 0;
                bodyState = 'close';
                readyBody = false;
                readyInfo = false;
                resetBody();
                resetFrame();
              }
              break;
            case 'allHivesState':
              allHivesState = '${slots[key]}';
              if (allHivesState == 'close') {
                beep('close');
                printText1 += "\n All Hives are";
                printText1 += " ${slots[key]}";
                readyAllHives = false;
                readyHive = false;
                hiveState = 'close';
                nrXXOfHive = 0;
                bodyState = 'close';
                readyBody = false;
                readyInfo = false;
                resetBody();
                resetFrame();
                //Navigator.pop(context);
              } else {
                if (readyApiary == true) {
                  printText1 += "\n All Hives are";
                  printText1 += " ${slots[key]}";
                  readyAllHives = true;
                  beep('open');
                  readyHive = false;
                  hiveState = 'close';
                  nrXXOfHive = 0;
                  bodyState = 'close';
                  readyBody = false;
                  resetBody();
                  resetFrame();
                  resetInfo();
                  // _dialogBuilderHelp(context);
                }
              }
              break;

            case 'hiveState':
              hiveState = '${slots[key]}';
              if (hiveState == 'close') {
                beep('close');
                printText1 += " ${slots[key]}";
                readyHive = false;
                nrXXOfHive = 0;
                nrXXOfHiveTemp = 0;
                bodyState = 'close';
                readyBody = false;
                readyInfo = false;
                resetBody();
                resetFrame();
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
                  allHivesState = 'close';
                  beep('open');
                  if (readyApiary == false && nrXXOfApiary == 0) {
                    readyApiary = true;
                    nrXXOfApiary = 1;
                  } //bo tylko jedna (lub pierwsza) pasieka
                }
              }
              break;
            case 'nrXXOfHive':
              nrXXOfHive = int.parse('${slots[key]}');
              if ((hiveState == 'open' || hiveState == 'set') &&
                  (readyApiary == true ||
                      (readyApiary == false && nrXXOfApiary == 0))) {
                //numer Hive jezeli otwarto Apiary
                printText1 += " ${slots[key]}";
                if (readyApiary == false && nrXXOfApiary == 0) {
                  readyApiary = true;
                  nrXXOfApiary = 1;
                }
                readyHive = true;
                readyAllHives = false;
                allHivesState = 'close';
                beep('open');
                nrXXOfHiveTemp = nrXXOfHive;
                bodyState = 'close';
                readyBody = false;
                readyInfo = false;
                resetBody();
                resetFrame();
              } else {
                printText1 += " ${slots[key]}";
                nrXXOfHiveTemp = nrXXOfHive;
                nrXXOfHive = 0;
                bodyState = 'close';
                readyHive = false;
                readyBody = false;
                readyInfo = false;
                resetBody();
                resetFrame();
              }
              break;
            case 'bodyState':
              bodyState = '${slots[key]}';
              if (bodyState == 'close') {
                printText1 += " ${slots[key]}";
                readyBody = false;
                beep('close');
                halfBodyState = 'close';
                readyFrame = false;
                nrXOfBodyTemp = 0;
                resetBody();
                resetFrame();
              } else {
                if (readyApiary == true && readyHive == true) {
                  //otwieranie Body jezeli otwarto Apiary i Hive
                  printText1 += " ${slots[key]}";
                  if (nrXOfBodyTemp != 0) {
                    nrXOfBody = nrXOfBodyTemp;
                    sizeOfFrame = 'big';
                  }
                  // if (nrXOfHalfBodyTemp != 0) {
                  //   nrXOfHalfBody = nrXOfHalfBodyTemp;
                  //   sizeOfFrame = 'small';
                  // }
                  readyAllHives = false;
                  allHivesState = 'close';
                  halfBodyState = 'close';
                  readyHalfBody = false;
                  nrXOfBodyTemp = 0;
                  nrXOfHalfBodyTemp = 0;
                  readyBody = true;
                  beep('open');
                  readyFrame = false;
                  resetFrame();
                }
              }
              break;
            case 'nrXOfBody':
              nrXOfBody = int.parse('${slots[key]}');
              if ((bodyState == 'open' || bodyState == 'set') &&
                  (readyApiary == true && readyHive == true)) {
                printText1 += " ${slots[key]}";
                readyBody = true;
                beep('open');
                nrXOfBodyTemp = nrXOfBody;
                nrXOfHalfBody = 0;
                nrXOfHalfBodyTemp = 0;
                readyHalfBody = false;
                readyAllHives = false;
                allHivesState = 'close';
                readyFrame = false;
                nrXXOfFrame = 0;
                sizeOfFrame = 'big'; //bo korpus
                resetFrame();
              } else {
                printText1 += " ${slots[key]}";
                nrXOfBodyTemp = nrXOfBody;
                nrXOfBody = 0;
                nrXOfHalfBody = 0;
                nrXXOfFrame = 0;
                readyBody = false;
                //beep('close');
                readyFrame = false;
                resetFrame();
              }
              break;
            case 'halfBodyState':
              halfBodyState = '${slots[key]}';
              if (halfBodyState == 'close') {
                printText1 += " ${slots[key]}";
                readyHalfBody = false;
                beep('close');
                readyFrame = false;
                nrXOfHalfBodyTemp = 0;
                resetBody();
                resetFrame();
              } else {
                if (readyApiary == true && readyHive == true) {
                  //otwieranie Body jezeli otwarto Apiary i Hive
                  printText1 += " ${slots[key]}";
                  if (nrXOfHalfBodyTemp != 0) {
                    nrXOfHalfBody = nrXOfHalfBodyTemp;
                    sizeOfFrame = 'small';
                  }
                  readyAllHives = false;
                  allHivesState = 'close';
                  nrXOfHalfBodyTemp = 0;
                  readyHalfBody = true;
                  readyBody = false;
                  bodyState = 'close';
                  nrXOfBody = 0;
                  beep('open');
                  readyFrame = false;
                  resetFrame();
                }
              }
              break;
            case 'nrXOfHalfBody':
              nrXOfHalfBody = int.parse('${slots[key]}');
              if ((halfBodyState == 'open' || halfBodyState == 'set') &&
                  (readyApiary == true && readyHive == true)) {
                printText1 += " half ${slots[key]}";
                readyHalfBody = true;
                readyBody = false;
                bodyState = 'close';
                nrXOfBody = 0;
                beep('open');
                //nrXOfHalfBodyTemp = nrXOfHalfBody;
                //nrXOfHalfBody = 0;
                nrXOfHalfBodyTemp = 0;
                nrXXOfFrame = 0;
                sizeOfFrame = 'small'; //bo półkorpus
                readyAllHives = false;
                allHivesState = 'close';
                resetFrame();
              } else {
                printText1 += " half ${slots[key]}";
                nrXOfHalfBodyTemp = nrXOfHalfBody;
                nrXOfHalfBody = 0;
                readyBody = false;
                nrXOfBody = 0;
                nrXXOfFrame = 0;
                readyFrame = false;
                resetFrame();
              }
              break;
            case 'frameState':
              frameState = '${slots[key]}';
              if (frameState == 'close') {
                beep('close');
                printText1 += " ${slots[key]}";
                readyFrame = false;
                nrXXOfFrame = 0;
                nrXXOfFrameTemp;
                resetFrame();
              } else {
                if (readyApiary == true &&
                    readyHive == true &&
                    (readyBody == true || readyHalfBody == true)) {
                  printText1 += " ${slots[key]}";
                  nrXXOfFrame = nrXXOfFrameTemp;
                  nrXXOfFrameTemp = 0;
                  readyFrame = true;
                  beep('open');
                  resetFrame();
                }
              }
              break;
            case 'nrXXOfFrame':
              nrXXOfFrame = int.parse('${slots[key]}');
              if ((frameState == 'open' || frameState == 'set') &&
                  (readyApiary == true &&
                      readyHive == true &&
                      (readyBody == true || readyHalfBody == true))) {
                printText1 += " ${slots[key]}";
                readyFrame = true;
                nrXXOfFrameTemp = nrXXOfFrame;
                resetFrame(); //kasowanie zmiennych przechowujących biezace zasoby ramki (bo nowa ramka)
              } else {
                if (readyApiary == true &&
                    readyHive == true &&
                    readyBody == true) {
                  printText1 += " ${slots[key]}";
                  nrXXOfFrameTemp = nrXXOfFrame;
                  nrXXOfFrame = 0;
                  readyFrame = false;
                  resetFrame();
                }
              }
              break;
            case 'siteOfFrame':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                beep('open');
                printText1 += "\n Site of frame =";
                printText1 += " ${slots[key]}";
                siteOfFrame = '${slots[key]}';
                resetInfo();
                readyInfo = false;
              }
              break;
            case 'sizeOfFrame': //OfFrame
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                beep('open');
                printText1 += "\n Size of frame =";
                printText1 += " ${slots[key]}";
                sizeOfFrame = '${slots[key]}';
                resetInfo();
                readyInfo = false;
              }
              break;
            case 'drone':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Drone =";
                printText1 += " ${slots[key]}";
                drone = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Drone = ${slots[key]}';
                zapisDoBazy(1, '${slots[key]}'); //
              }
              break;
            case 'brood':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Brood covered =";
                printText1 += " ${slots[key]}";
                brood = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Brood covered = ${slots[key]}';
                zapisDoBazy(2, '${slots[key]}'); //
              }
              break;
            case 'larvae':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Larvae =";
                printText1 += " ${slots[key]}";
                larvae = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Larvae = ${slots[key]}';
                zapisDoBazy(3, '${slots[key]}'); //
              }
              break;
            case 'eggs':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Eggs =";
                printText1 += " ${slots[key]}";
                eggs = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Eggs = ${slots[key]}';
                zapisDoBazy(4, '${slots[key]}'); //
              }
              break;
            case 'pollen':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Pollen =";
                printText1 += " ${slots[key]}";
                pollen = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Pollen = ${slots[key]}';
                zapisDoBazy(5, '${slots[key]}');
              }
              break;
            case 'honeySealed':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Honey sealed =";
                printText1 += " ${slots[key]}";
                honeySeald = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Honey sealed = ${slots[key]}';
                zapisDoBazy(6, '${slots[key]}'); //2-honeySeald
              }
              break;
            case 'honey':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Honey =";
                printText1 += " ${slots[key]}";
                honey = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Honey = ${slots[key]}';
                zapisDoBazy(7, '${slots[key]}'); //1-honey
              }
              break;
            case 'waxComb':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Wax comb =";
                printText1 += " ${slots[key]}";
                waxComb = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Wax comb = ${slots[key]}';
                zapisDoBazy(8, '${slots[key]}'); //
              }
              break;
            case 'wax':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Wax fundation =";
                printText1 += " ${slots[key]}";
                wax = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Wax fundation = ${slots[key]}';
                zapisDoBazy(9, '${slots[key]}'); //
              }
              break;
            case 'queen':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Queen =";
                printText1 += " ${slots[key]}";
                queen = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Queen = ${slots[key]}';
                zapisDoBazy(10, '${slots[key]}'); //
              }
              break;
            case 'queenCells':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Queen cells =";
                printText1 += " ${slots[key]}";
                queenCells = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Queen cells = ${slots[key]}';
                zapisDoBazy(11, '${slots[key]}'); //
              }
              break;
            case 'delQCells':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n Delete queen cels =";
                printText1 += " ${slots[key]}";
                delQCells = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'Delete queen cels = ${slots[key]}';
                zapisDoBazy(12, '${slots[key]}'); //
              }
              break;
            case 'toDo':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n to Do =";
                printText1 += " ${slots[key]}";
                toDo = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'to Do = ${slots[key]}';
                zapisDoBazy(13, '${slots[key]}'); //
              }
              break;
            case 'isDone':
              if (readyApiary == true &&
                  readyHive == true &&
                  (readyBody == true || readyHalfBody == true) &&
                  readyFrame == true) {
                printText1 += "\n is Done =";
                printText1 += " ${slots[key]}";
                isDone = '${slots[key]}';
                readyStory = true;
                resetInfo();
                readyInfo = false;
                zapis = 'is Done = ${slots[key]}';
                zapisDoBazy(14, '${slots[key]}'); //
              }
              break;
            case 'syrup1to1I': //syrop 1 do 1 część całkowita w litrach
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Syrup 1:1 =";
                printText1 += "  ${slots[key]} l";
                syrup1to1I = '${slots[key]}';
                zapis = 'Syrup 1:1 = $syrup1to1I.$syrup1to1D l';
                readyInfo = true;
                zapisInfoDoBazy(
                    'feeding', 'syrup 1:1', '$syrup1to1I.$syrup1to1D', 'l'); //
              }
              break;
            case 'syrup1to1D': //syrop 1 do 1 część dziesiętna
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Syrup 1:1 =";
                printText1 += "  0.${slots[key]} l";
                syrup1to1D = '${slots[key]}';
                zapis = 'Syrup 1:1 = $syrup1to1I.$syrup1to1D l';
                readyInfo = true;
                zapisInfoDoBazy(
                    'feeding', 'syrup 1:1', '$syrup1to1I.$syrup1to1D', 'l'); //
              }
              break;
            case 'syrup3to2I': //syrop 3 do 2 część całkowita w litrach
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Syrup 3:2 =";
                printText1 += "  ${slots[key]} l";
                syrup3to2I = '${slots[key]}';
                zapis = 'Syrup 3:2 = $syrup3to2I.$syrup3to2D l';
                readyInfo = true;
                zapisInfoDoBazy(
                    'feeding', 'syrup 3:2', '$syrup3to2I.$syrup3to2D', 'l'); //
              }
              break;
            case 'syrup3to2D': //syrop 3 do 2 część dziesiętna
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Syrup 3:2 =";
                printText1 += "  0.${slots[key]} l";
                syrup3to2D = '${slots[key]}';
                zapis = 'Syrup 3:2 = $syrup3to2I.$syrup3to2D l';
                readyInfo = true;
                zapisInfoDoBazy(
                    'feeding', 'syrup 3:2', '$syrup3to2I.$syrup3to2D', 'l'); //
              }
              break;
            case 'candyI': //candy część całkowita w litrach
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Candy =";
                printText1 += "  ${slots[key]} kg";
                candyI = '${slots[key]}';
                zapis = 'Candy = $candyI.$candyD kg';
                readyInfo = true;
                zapisInfoDoBazy('feeding', 'candy', '$candyI.$candyD', 'kg'); //
              }
              break;
            case 'candyD': //candy część dziesiętna
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Candy =";
                printText1 += "  ${slots[key]} kg";
                candyD = '${slots[key]}';
                zapis = 'Candy = $candyI.$candyD kg';
                readyInfo = true;
                zapisInfoDoBazy('feeding', 'candy', '$candyI.$candyD', 'kg'); //
              }
              break;
            case 'invertI': //invert część całkowita w litrach
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Invert =";
                printText1 += "  ${slots[key]}";
                invertI = '${slots[key]}';
                zapis = 'Invert = $invertI.$invertD l';
                readyInfo = true;
                zapisInfoDoBazy(
                    'feeding', 'invert', '$invertI.$invertD', 'l'); //
              }
              break;
            case 'invertD': //invert część dziesiętna
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Invert =";
                printText1 += "  ${slots[key]}";
                invertD = '${slots[key]}';
                zapis = 'Invert = $invertI.$invertD l';
                readyInfo = true;
                zapisInfoDoBazy(
                    'feeding', 'invert', '$invertI.$invertD', 'l'); //
              }
              break;
            case 'removedFood': //usunięto pokarm
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Removed food =";
                printText1 += "  ${slots[key]}";
                removedFood = '${slots[key]}';
                zapis = 'Removed food = ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy('feeding', 'removed food', removedFood, ''); //
              }
              break;
            case 'leftFood': //pozostał (niezjedzony) pokarm
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Left food =";
                printText1 += "  ${slots[key]}";
                leftFood = '${slots[key]}';
                zapis = 'Left food = ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy('feeding', 'left food', leftFood, ''); //
              }
              break;
            case 'apivarol': //
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Apiwarol =";
                printText1 += "  ${slots[key]} dose";
                zapis = 'Apiwarol = ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy(
                    'treatment', 'apivarol', '${slots[key]}', 'dose'); //
              }
              break;
            case 'biovar': //
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Biowar =";
                printText1 += "  ${slots[key]} belts";
                zapis = 'Biowar = ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy(
                    'treatment', 'biovar', '${slots[key]}', 'belts'); //
              }
              break;
            case 'varroa': //
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Varroa =";
                printText1 += "  ${slots[key]} mites";
                zapis = 'Varroa = ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy(
                    'treatment', 'varroa', '${slots[key]}', 'mites'); //
              }
              break;
            case 'varroaH': //
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Varroa =";
                printText1 += "  ${slots[key]}00 mites";
                zapis = 'Varroa = ${slots[key]}00 mites';
                readyInfo = true;
                zapisInfoDoBazy(
                    'treatment', 'varroa', '${slots[key]}00', 'mites'); //
              }
              break;
            case 'queenState': //
              if (readyApiary == true && readyHive == true) {
                printText1 += "\n Queen =";
                printText1 += "  ${slots[key]}";
                zapis = 'Queen - ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy('queen', 'queen -', '${slots[key]}', ''); //
              }
              break;
            case 'queenStart': //
              if (readyApiary == true && readyHive == true) {
                printText1 += "\n Queen =";
                printText1 += "  ${slots[key]}";
                zapis = 'Queen is ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy('queen', 'queen is', '${slots[key]}', ''); //
              }
              break;
            case 'queenMark': //
              if (readyApiary == true && readyHive == true) {
                printText1 += "\n Queen =";
                printText1 += "  ${slots[key]}";
                zapis = 'Queen is ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy('queen', ' queen is', '${slots[key]}', ''); //
              }
              break;
            case 'queenQuality': //
              if (readyApiary == true && readyHive == true) {
                printText1 += "\n Queen =";
                printText1 += "  ${slots[key]}";
                zapis = 'Queen is ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy('queen', 'queen is ', '${slots[key]}', ''); //
              }
              break;
            case 'queenBorn': //
              if (readyApiary == true && readyHive == true) {
                printText1 += "\n Queen was born in 20";
                printText1 += "${slots[key]}";
                zapis = 'Queen was born in 20 ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy(
                    'queen', 'queen was born', 'in 20${slots[key]}', ''); //
              }
              break;
            case 'numberOfFrame':
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Number of frame =";
                printText1 += " ${slots[key]}";
                globals.iloscRamek = '${slots[key]}';
                zapis = 'Number of frame = ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy(
                    'equipment', 'number of frame = ', '${slots[key]}', ''); //
              }
              break;
            case 'excluder': //krata odgrodowa
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Exculuder =";
                printText1 += " on ${slots[key]} body";
                zapis = 'Exculuder on ${slots[key]} body';
                readyInfo = true;
                zapisInfoDoBazy('equipment', 'excluder', 'on body number',
                    '${slots[key]}'); //
              }
              break;
            case 'excluderDel': //krata odgrodowa
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Exculuder =";
                printText1 += " ${slots[key]}";
                zapis = 'Exculuder ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy(
                    'equipment', 'excluder -', '${slots[key]}', ''); //remove
              }
              break;
            case 'bottomBoard': //dennica
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Bottom board =";
                printText1 += " ${slots[key]}";
                zapis = 'Bottom board is ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy(
                    'equipment', 'bottom board is', '${slots[key]}', '');
              }
              break;
            case 'polenTrap': //poławiacz pyłku
              if (readyApiary == true &&
                  (readyHive == true || readyAllHives == true)) {
                printText1 += "\n Pollen trap =";
                printText1 += " ${slots[key]}";
                zapis = 'Pollen trap is ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy(
                    'equipment', 'pollen trap is', '${slots[key]}', '');
              }
              break;
            case 'colonyForce': //poławiacz pyłku
              if (readyApiary == true && readyHive == true) {
                printText1 += "\n Colony =";
                printText1 += " ${slots[key]}";
                zapis = 'Colony is ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy('colony', ' colony is', '${slots[key]}', '');
              }
              break;
            case 'colonyState': //poławiacz pyłku
              if (readyApiary == true && readyHive == true) {
                printText1 += "\n Colony =";
                printText1 += " ${slots[key]}";
                zapis = 'Colony is ${slots[key]}';
                readyInfo = true;
                zapisInfoDoBazy('colony', 'colony is', '${slots[key]}', '');
              }
              break;

            case 'dateDay':
              printText1 += "\n Day =";
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
              printText1 += "\n Month =";
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
              printText1 += "\n Year =";
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
              printText1 += "\n Date";
              printText1 += " ${slots[key]}";
              ustawianaData = '';
              formattedDate = formatter.format(now);
              beep('open');
              break;
          }
        }
        //printText += '    }\n';
      } else {
        //jezeli nie zdekodowano slotu czyli parametrów intencji
        printText = 'Error';
        beep('error');
      }
      printText1 == '' //jezeli nie ma slotu bo niewłaściwa kolejność komend
          ? {
              printText = 'Wrong command',
              beep('error'),
            }
          : printText += printText1;
    }
    //printText += '}';
    print('wynik = $printText');

    print('intention = $intention');
    print('readyApiary = $readyApiary');
    print('readyAllHives = $readyAllHives');
    print('readyHive = $readyHive');
    print('readyBody = $readyBody');
    print('readyHalfBody = $readyHalfBody');
    print('readyFrame = $readyFrame');
    print('---');
    print('apiaryState = $apiaryState');
    print('nrXXOfApiary = $nrXXOfApiary');
    print('allHivesState = $allHivesState');
    print('hiveState = $hiveState');
    print('nrXXOfHive = $nrXXOfHive');
    print('bodyState = $bodyState');
    print('nrXOfBody = $nrXOfBody');
    print('halfBodyState = $halfBodyState');
    print('nrXOfHalfBody = $nrXOfHalfBody');
    print('frameState = $frameState');
    print('nrXXOfFrame = $nrXXOfFrame');
    print('siteOfFrame = $siteOfFrame');
    print('sizeOfFrame = $sizeOfFrame');
    print('honey = $honey');
    print('honeySeald = $honeySeald');
    print('pollen = $pollen');
    print('brood = $brood');
    print('larvae = $larvae');
    print('eggs = $eggs');
    print('wax = $wax');
    print('waxComb = $waxComb');
    print('queen = $queen');
    print('queenCells = $queenCells');
    print('delQCells = $delQCells');
    print('drone = $drone');
    print('toDo = $toDo');
    print('isDone = $isDone');
    print('syrup1to1I = $syrup1to1I');
    print('syrup1to1D = $syrup1to1D');

    return printText;
  }

  zapisDoBazy(int zas, wart) {
    if (ustawianaData != '')
      formattedDate = ustawianaData;
    else
      formattedDate = formatter.format(now);

    if (nrXOfBody != 0) {
      _korpusNr = nrXOfBody;
      _typ = 2;
    } else {
      _korpusNr = nrXOfHalfBody;
      _typ = 1;
    }

    if (sizeOfFrame == 'big') {
      _rozmiar = 2;
    } else if (sizeOfFrame == 'small') {
      _rozmiar = 1;
    }

    //data.       pasiekaNr.    ulNr.     korpusNr.   ramkaNr.   strona.  zasob

    //String id = '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$nrXOfBody.$nrXXOfFrame.$_strona.$zas';
    if (nrXXOfApiary != 0 &&
        nrXXOfHive != 0 &&
        _korpusNr != 0 &&
        nrXXOfFrame != 0) {
      if (siteOfFrame == 'left') {
        Frames.insertFrame(
            '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$nrXXOfFrame.1.$zas',
            formattedDate,
            nrXXOfApiary,
            nrXXOfHive,
            _korpusNr,
            _typ,
            nrXXOfFrame,
            _rozmiar,
            1, //lewa
            zas,
            wart);
      } else if (siteOfFrame == 'right') {
        Frames.insertFrame(
            '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$nrXXOfFrame.2.$zas',
            formattedDate,
            nrXXOfApiary,
            nrXXOfHive,
            _korpusNr,
            _typ,
            nrXXOfFrame,
            _rozmiar,
            2, //prawa
            zas,
            wart);
      } else {
        //bo both lub whole
        Frames.insertFrame(
            '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$nrXXOfFrame.1.$zas',
            formattedDate,
            nrXXOfApiary,
            nrXXOfHive,
            _korpusNr,
            _typ,
            nrXXOfFrame,
            _rozmiar,
            1, //lewa
            zas,
            wart);
        Frames.insertFrame(
            '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$_korpusNr.$nrXXOfFrame.2.$zas',
            formattedDate,
            nrXXOfApiary,
            nrXXOfHive,
            _korpusNr,
            _typ,
            nrXXOfFrame,
            _rozmiar,
            2, //prawa
            zas,
            wart);
      }

      ikona = 'green';
      if (toDo != '') {
        ikona = 'yellow';
      }
      // if (isDone == 'insulated') {
      //   ikona = 'red';
      // }

      zapisInfoDoBazy('inspection', 'inspection', ikona, '');
    } else {
      beep('error');
    }
  }

  //info(id TEXT PRIMARY KEY, pasiekaNr INTEGER, ileUli INTEGER, data TEXT, kategoria TEXT, parametr TEXT, wartosc TEXT, miara TEXT, uwagi TEXT)');
  zapisInfoDoBazy(String kat, String param, String wart, String miar) {
    if (ustawianaData != '')
      formattedDate = ustawianaData;
    else
      formattedDate = formatter.format(now);

    formatedTime = formatterHm.format(now);
    //print('czas $formatedTime');

    if (readyAllHives) {
      //wpis dla wszystkich uli w pasiece
      //pobranie do Hives_items z tabeli ule - ule z pasieki do której ma być wpis
      Provider.of<Hives>(context, listen: false)
          .fetchAndSetHives(
        nrXXOfApiary,
      )
          .then((_) {
        final hivesData = Provider.of<Hives>(context, listen: false);
        final hives = hivesData.items;
        print('ilość uli do wpisania info = ${hives.length}');
        for (var i = 0; i < hives.length; i++) {
          print('wpis nr $i');
          Infos.insertInfo(
              '$formattedDate.$nrXXOfApiary.${hives[i].ulNr}.$kat.$param', //id
              formattedDate, //data
              nrXXOfApiary, //pasiekaNr
              hives[i].ulNr, //ulNr
              kat, //karegoria
              param, //parametr
              wart, //wartosc
              miar, //miara
              formatedTime);
        }
        platform == 'android'
            ? FlutterBeep.playSysSound(
                AndroidSoundIDs.TONE_CDMA_NETWORK_BUSY_ONE_SHOT)
            : FlutterBeep.playSysSound(iOSSoundIDs.JBL_NoMatch);
      });
    } else {
      //wpis dla jednego ula

      if (ikona == '') ikona = 'green';

      Infos.insertInfo(
          '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$kat.$param', //id
          formattedDate, //data
          nrXXOfApiary, //pasiekaNr
          nrXXOfHive, //ulNr
          kat, //karegoria
          param, //parametr
          wart, //wartosc
          miar, //miara
          formatedTime); //uwagi - czas
      print('voice_screen: zapis Info do bazy');

      Hives.insertHive(
        '$nrXXOfApiary.$nrXXOfHive',
        nrXXOfApiary, //pasieka nr
        nrXXOfHive, //ul nr
        formattedDate, //przeglad
        ikona, //ikona
        globals.iloscRamek, //opis - ilość ramek w korpusie
      ).then((_) {
        //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
        Provider.of<Hives>(context, listen: false)
            .fetchAndSetHives(
          nrXXOfApiary,
        )
            .then((_) {
          final hivesData = Provider.of<Hives>(context, listen: false);
          final hives = hivesData.items;
          ileUli = hives.length;
          print('voice_screen - ilość uli =');
          // print(hives.length);
          // print(ileUli);
          DBHelper.updateIleUli(nrXXOfApiary, ileUli); //
        });
      });

      //zapis do tabeli "pasieki"
      Apiarys.insertApiary(
        '$nrXXOfApiary',
        nrXXOfApiary, //pasieka nr
        ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
        formattedDate, //przeglad
        ikona, //ikona
        '??', //opis
      ).then((_) {
        Provider.of<Apiarys>(context, listen: false)
            .fetchAndSetApiarys()
            .then((_) {
          print(
              'voice_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy');
        });
      });

      platform == 'android'
          ? FlutterBeep.playSysSound(
              AndroidSoundIDs.TONE_CDMA_NETWORK_BUSY_ONE_SHOT)
          : FlutterBeep.playSysSound(iOSSoundIDs.JBL_NoMatch);
      print('voice_screen: zapis Frame do bazy');
    }
  }

  resetBody() {
    print('kasowanie body');
    nrXOfBody = 0;
    nrXOfBodyTemp = 0;
    nrXOfHalfBody = 0;
    nrXOfHalfBodyTemp = 0;
    frameState = 'close';
    readyFrame = false;
    nrXXOfFrame = 0;
  }

  resetFrame() {
    print('kasowanie frame');
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
  }

  //uruchomienie przycisku START
  Future<void> _startProcessing() async {
    if (isProcessing) {
      return;
    }

    setState(() {
      isButtonDisabled = true;
    });

    try {
      if (_picovoiceManager == null) {
        throw PicovoiceInvalidStateException(
            "_picovoiceManager not initialized.");
      }
      await _picovoiceManager!.start();
      setState(() {
        isProcessing = true;
        rhinoText = "Listening for \"Hi Bees!\""; //po naciśnięciu START
        //rhinoText += "\"Hi Bees!\"";
        isButtonDisabled = false;
      });
    } on PicovoiceInvalidArgumentException {
      errorCallback(PicovoiceInvalidArgumentException(
          "No functionality - the application is inactive."));
      //   "${ex.message}\nEnsure your accessKey '$accessKey' is a valid access key."));
    } on PicovoiceActivationException {
      errorCallback(PicovoiceActivationException(
          "AccessKey activation error.\nInternet connection needed."));
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

    //wciśnięcieSTART
    platform == 'android'
        ? FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ONE_MIN_BEEP)
        : FlutterBeep.playSysSound(iOSSoundIDs.JBL_Begin);
  }

  Future<void> _stopProcessing() async {
    if (!isProcessing) {
      return;
    }

    setState(() {
      isButtonDisabled = true;
    });

    if (_picovoiceManager == null) {
      throw PicovoiceInvalidStateException(
          "_picovoiceManager not initialized.");
    }
    await _picovoiceManager!.stop();
    setState(() {
      isProcessing = false;
      rhinoText = "";
      isButtonDisabled = false;
    });
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
                    TextSpan(
                      text: ('\nInspection - say e.g.:'),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),

                    TextSpan(text: '\n\nOpen'),
                    TextSpan(
                        text: ' apiary',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' number',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\nOpen'),
                    TextSpan(
                        text: ' all hives',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '.\n\nOpen'),
                    TextSpan(
                        text: ' hive',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' number',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 5', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\nOpen'),
                    TextSpan(
                        text: ' body/half body',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' number',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\nSet'),
                    TextSpan(
                        text: ' big/small ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' frame',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' number',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 9', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' on the left/right/both.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text:
                            'When the apiary, hive, body and frame are open say e.g.:\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),
                    TextSpan(
                        text: 'Set ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' drone',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 10%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' on the left/right.\n\nSet ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' brood',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 20%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' on the left/right.\n\nSet ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' larvae/eggs/pollen/honey/seald/wax/comb',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 35%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' on the left/right.\n\nSet ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' on the left/right.\n\nSet ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' queen cells',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' on the left/right.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: 'Delete'),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' queen cells'),
                    TextSpan(
                        text: ' on the left/right.\n\nSet ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' left/right'),
                    TextSpan(
                        text: '  site',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: '.\n\nSet',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text:
                            ' work frame/to extraction/to delete/to insulate.'),
                    TextSpan(
                        text: ' - to do\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),
                    TextSpan(
                        text: 'Set',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text:
                            ' deleted/inserted/insulated/moved left/moved right.'),
                    TextSpan(
                        text: ' - is done\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),
                    //  Equipment
                    TextSpan(
                        text: 'Equipment - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text:
                            '(when at least the apiary and hive are open)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Set',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: '  number of frame',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' in body'),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 10', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\nSet',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: '  excluder',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' on body number'),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\nDelete excluder.\n\n'),
                    TextSpan(
                        text: 'Bottom board',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            ' is disinfected/ok/dirty/for cleaning/cleared/cleaned/clean/to remove/to delete.'),
                    TextSpan(
                        text: '\n\nPollen trap',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            ' is on/off/open/close/activated/eliminated.\n\n'),
//queen
                    TextSpan(
                        text: '\nQueen - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text:
                            '(when at least the apiary and hive are open)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' was born in'),
                    TextSpan(text: ' 23', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            ' is virgine/artificially inseminated/naturally mated.\n\n'),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' is freed/in a cage/in the insulator.\n\n'),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' is marked/unmarked.\n\n'),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            ' is very good/good/poor/weak/canceled/to exchange.\n\n'),
//colony
                    TextSpan(
                        text: 'Colony - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text:
                            '(when at least the apiary and hive are open)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Colony',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text:
                            ' dead/flight/swarming mood/in a cluster/gentle/aggressive.\n\n'),
                    TextSpan(
                        text: 'Colony',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' very weak/weak/strong/very strong.\n\n'),

//feeding
                    TextSpan(
                        text: 'Feeding - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text:
                            '(when at least the apiary and hive are open)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Set',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' syrup one to one',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' point',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 5',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(text: ' liters.\n\n'),
                    TextSpan(
                        text: 'Set',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' syrup three to two',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' point',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 5',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(text: ' liters.\n\n'),
                    TextSpan(
                        text: 'Set bee',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' candy',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' point',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 0',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(text: ' kilo.\n\n'),
                    TextSpan(
                        text: 'Set',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' invert',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' point',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 7',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(text: ' liters.\n\n'),
                    TextSpan(
                        text: 'Left food',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 30%', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: 'Remove food',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 30%', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
//treatment
                    TextSpan(
                        text: 'Treatment - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text:
                            '(when at least the apiary and hive are open)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Apivarol/chemistry',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1st', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' dose/portion/part.\n\n'),
                    TextSpan(text: 'Apivarol/chemistry'),
                    TextSpan(text: ' dose/portion/part number'),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: 'Biovar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' belts.\n\n'),
                    TextSpan(text: 'Biovar remove'),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' belts.\n\n'),
                    TextSpan(
                        text: 'Varroa',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 18', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' mites.\n\n'),
                    TextSpan(
                        text: 'Varroa',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' hundred mites.\n\n'),
//date
                    TextSpan(
                        text: 'Date - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    // TextSpan(
                    //     text:
                    //         '(when at least the apiary is open)\n\n',
                    //     style: TextStyle(
                    //         fontSize: 14,
                    //         fontStyle: FontStyle.italic,
                    //         color: Colors.blue)),
                    TextSpan(
                        text: '\nDay',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 15', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: 'Month',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: 'Year',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 22', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(text: 'Set'),
                    TextSpan(
                        text: ' current',
                        style: TextStyle(fontWeight: FontWeight.bold)),

                    TextSpan(text: ' date.\n\n'),
//help me
                    TextSpan(
                        text: 'Help - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: '(for precise help)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Inspection',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Equipment',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Colony',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Feeding',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Treatment',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Date',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Close help',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' me.',
                        style: TextStyle(fontStyle: FontStyle.italic)),

//Legenda
                    TextSpan(
                        text: '\n\nLegend:\n',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold)),
                    TextSpan(text: 'Normal or'),
                    TextSpan(
                        text: ' bold',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' - required text.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Italic',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' - optional text.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(text: 'Text1/text2'),
                    TextSpan(
                        text: ' - selectable text.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' - sample value.\n',
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
              child: const Text('Disable'),
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
                      text: ('\nInspection - say e.g.:'),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    TextSpan(text: '\n\nOpen'),
                    TextSpan(
                        text: ' apiary',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' number',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\nOpen'),
                    TextSpan(
                        text: ' all hives',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '.\n\nOpen'),
                    TextSpan(
                        text: ' hive',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' number',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 5', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\nOpen'),
                    TextSpan(
                        text: ' body/half body',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' number',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\nSet'),
                    TextSpan(
                        text: ' big/small ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' frame',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' number',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 9', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' on the left/right/both.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text:
                            'When the apiary, hive, body and frame are open say e.g.:\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),
                    TextSpan(
                        text: 'Set ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' drone',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 10%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' on the left/right.\n\nSet ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' brood',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 20%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' on the left/right.\n\nSet ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' larvae/eggs/pollen/honey/seald/wax/comb',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 35%', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' on the left/right.\n\nSet ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' on the left/right.\n\nSet ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' queen cells',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' on the left/right.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: 'Delete'),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' queen cells'),
                    TextSpan(
                        text: ' on the left/right.\n\nSet ',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' left/right'),
                    TextSpan(
                        text: '  site',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: '.\n\nSet',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text:
                            ' work frame/to extraction/to delete/to insulate.'),
                    TextSpan(
                        text: ' - to do\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),
                    TextSpan(
                        text: 'Set',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text:
                            ' deleted/inserted/insulated/moved left/moved right.'),
                    TextSpan(
                        text: ' - is done\n\n',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.blue)),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Disable'),
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
                        text: '\nEquipment - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text:
                            '(when at least the apiary and hive are open)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Set',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: '  number of frame',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' in body'),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 10', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: '.\n\nSet',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: '  excluder',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' on body number'),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\nDelete excluder.\n\n'),
                    TextSpan(
                        text: 'Bottom board',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            ' is disinfected/ok/dirty/for cleaning/cleared/cleaned/clean/to remove/to delete.'),
                    TextSpan(
                        text: '\n\nPollen trap',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            ' is on/off/open/close/activated/eliminated.\n\n'),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Disable'),
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
                        text: '\nQueen - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text:
                            '(when at least the apiary and hive are open)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' was born in'),
                    TextSpan(text: ' 23', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            ' is virgine/artificially inseminated/naturally mated.\n\n'),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' is freed/in a cage/in the insulator.\n\n'),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' is marked/unmarked.\n\n'),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            ' is very good/good/poor/weak/canceled/to exchange.\n\n'),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Disable'),
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
                        text: '\nColony - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text:
                            '(when at least the apiary and hive are open)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Colony',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text:
                            ' dead/flight/swarming mood/in a cluster/gentle/aggressive.\n\n'),
                    TextSpan(
                        text: 'Colony',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' very weak/weak/strong/very strong.\n\n'),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Disable'),
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
                        text: '\nFeeding - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text:
                            '(when at least the apiary and hive are open)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Set',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' syrup one to one',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' point',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 5',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(text: ' liters.\n\n'),
                    TextSpan(
                        text: 'Set',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' syrup three to two',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' point',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 5',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(text: ' liters.\n\n'),
                    TextSpan(
                        text: 'Set bee',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' candy',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' point',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 0',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(text: ' kilo.\n\n'),
                    TextSpan(
                        text: 'Set',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' invert',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' point',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' 7',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.red)),
                    TextSpan(text: ' liters.\n\n'),
                    TextSpan(
                        text: 'Left food',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 30%', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: 'Remove food',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 30%', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Disable'),
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
                        text: '\nTreatment - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text:
                            '(when at least the apiary and hive are open)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Apivarol/chemistry',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 1st', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' dose/portion/part.\n\n'),
                    TextSpan(text: 'Apivarol/chemistry'),
                    TextSpan(text: ' dose/portion/part number'),
                    TextSpan(text: ' 1', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: 'Biovar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' belts.\n\n'),
                    TextSpan(text: 'Biovar remove'),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' belts.\n\n'),
                    TextSpan(
                        text: 'Varroa',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 18', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' mites.\n\n'),
                    TextSpan(
                        text: 'Varroa',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(text: ' hundred mites.'),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Disable'),
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
                        text: '\nHelp - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    TextSpan(
                        text: '(for precise help)\n\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Inspection',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Equipment',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Queen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Colony',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Feeding',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Treatment',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Date',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' help me.\n\n',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: 'Close help',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' me.',
                        style: TextStyle(fontStyle: FontStyle.italic)),

                    TextSpan(
                        text: '\n\nLegend:\n',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold)),
                    TextSpan(text: 'Normal or'),
                    TextSpan(
                        text: ' bold',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' - required text.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(
                        text: 'Italic',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(
                        text: ' - optional text.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(text: 'Text1/text2'),
                    TextSpan(
                        text: ' - selectable text.\n',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue)),
                    TextSpan(text: ' 2', style: TextStyle(color: Colors.red)),
                    TextSpan(
                        text: ' - sample value.\n',
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
              child: const Text('Disable'),
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
                        text: '\nDate - say e.g.:\n',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    // TextSpan(
                    //     text:
                    //         '(when at least the apiary is open)\n\n',
                    //     style: TextStyle(
                    //         fontSize: 14,
                    //         fontStyle: FontStyle.italic,
                    //         color: Colors.blue)),
                    TextSpan(
                        text: '\nDay',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 15', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: 'Month',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 3', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(
                        text: 'Year',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: ' is',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ' 22', style: TextStyle(color: Colors.red)),
                    TextSpan(text: '.\n\n'),
                    TextSpan(text: 'Set'),
                    TextSpan(
                        text: ' current',
                        style: TextStyle(fontWeight: FontWeight.bold)),

                    TextSpan(text: ' date.'),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Disable'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Future<void> _dialogBuilderLast(BuildContext context) {
  //   return showDialog<void>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         contentPadding: EdgeInsets.only(left: 15, right: 15),
  //         //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
  //         content: Container(
  //           child: SingleChildScrollView(
  //             child:

  //           //rysunek ula z ostatniego przeglądu

  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Disable'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
        backgroundColor: Color.fromARGB(255, 233, 140, 0),
        //shape: CircleBorder(),
        textStyle: const TextStyle(color: Colors.white));

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

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            'Voice Control',
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
              Wakelock.disable(), //usunięcie blokowania wygaszania ekranu
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
                        child: Text(isProcessing ? "Stop" : "Start",
                            style: const TextStyle(
                                fontSize: 14)), // fontWeight: FontWeight.bold
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
          alignment: Alignment.center,
          //color: Color.fromARGB(255, 236, 222, 202),
          margin: EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (readyApiary)
                    Expanded(
                      child: Container(
                        color: Color.fromARGB(255, 252, 193, 104),
                        padding:
                            const EdgeInsets.all(6.00), //wokół części tekstowej
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            nrXXOfApiary != 0
                                ? Text(
                                    'Apiary nr $nrXXOfApiary   ($formattedDate)',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  )
                                : Text(
                                    'Apiary nr $nrXXOfApiary - invalid apiary number',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 255, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  ),
                            //if (nrXXOfApiary == 0)  beep('error'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              if (readyAllHives) const SizedBox(height: 5),
              if (readyAllHives)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        color: Color.fromARGB(255, 252, 193, 104),
                        padding:
                            const EdgeInsets.all(6.00), //wokół części tekstowej
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            allHivesState != 'close'
                                ? Text(
                                    'All the hives are open',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  )
                                : Text(
                                    'All hives are close',
                                    style: const TextStyle(
                                      fontSize: 15,
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
                  ],
                ),
              if (readyHive) const SizedBox(height: 5),
              if (readyHive)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        color: Color.fromARGB(255, 252, 193, 104),
                        padding:
                            const EdgeInsets.all(6.00), //wokół części tekstowej
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            nrXXOfHive != 0
                                ? Text(
                                    'Hive nr $nrXXOfHive',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  )
                                : Text(
                                    'Hive nr $nrXXOfHive - invalid hive number',
                                    style: const TextStyle(
                                      fontSize: 15,
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
                  ],
                ),
              if (readyBody) const SizedBox(height: 5),
              if (readyBody)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        color: Color.fromARGB(255, 252, 193, 104),
                        padding:
                            const EdgeInsets.all(6.00), //wokół części tekstowej
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            nrXOfBody != 0
                                ? Text(
                                    'Body nr $nrXOfBody',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  )
                                : Text(
                                    'Body nr $nrXOfBody - invalid body number',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 255, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (readyHalfBody) const SizedBox(height: 5),
              if (readyHalfBody)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        color: Color.fromARGB(255, 252, 193, 104),
                        padding:
                            const EdgeInsets.all(6.00), //wokół części tekstowej
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            nrXOfHalfBody != 0
                                ? Text(
                                    'Half body nr $nrXOfHalfBody',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  )
                                : Text(
                                    'Half body nr $nrXOfHalfBody - invalid body number',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 255, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (readyFrame) const SizedBox(height: 5),
              if (readyFrame)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        color: Color.fromARGB(255, 252, 193, 104),
                        padding:
                            const EdgeInsets.all(6.00), //wokół części tekstowej
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            nrXXOfFrame != 0
                                ? Text(
                                    'Frame nr $nrXXOfFrame',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  )
                                : Text(
                                    'Frame nr $nrXXOfFrame - invalid frame number',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 255, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  ),
                            if (nrXXOfFrame != 0)
                              Text(
                                '$sizeOfFrame frame on $siteOfFrame site',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: false, //zawijanie tekstu
                                overflow: TextOverflow.fade, //skracanie tekstu
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (readyStory && !readyInfo) const SizedBox(height: 5),
              if (readyStory && !readyInfo)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        color: Color.fromARGB(255, 252, 193, 104),
                        padding:
                            const EdgeInsets.all(6.00), //wokół części tekstowej
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            //jezeli numery pasieki, ula, korpusu i ramki rózne od 0
                            nrXXOfApiary != 0 &&
                                    nrXXOfHive != 0 &&
                                    _korpusNr != 0 &&
                                    nrXXOfFrame != 0
                                ? Text(
                                    'Save:',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  )
                                : Text(
                                    'No save - invalid frame number',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 255, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (readyStory && !readyInfo)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        alignment: Alignment.topCenter,
                        height: 50,
                        color: Color.fromARGB(255, 252, 193, 104),
                        padding:
                            const EdgeInsets.all(6.00), //wokół części tekstowej
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              zapis,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.bold,
                              ),
                              softWrap: false, //zawijanie tekstu
                              overflow: TextOverflow.fade, //skracanie tekstu
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (readyInfo) const SizedBox(height: 5),
              if (readyInfo)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        color: Color.fromARGB(255, 252, 193, 104),
                        padding:
                            const EdgeInsets.all(6.00), //wokół części tekstowej
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            //jezeli numery pasieki, ula, korpusu i ramki rózne od 0
                            nrXXOfApiary != 0 &&
                                    (nrXXOfHive != 0 || readyAllHives)
                                ? Text(
                                    'Save info:',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  )
                                : Text(
                                    'No save - invalid have number',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 255, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: false, //zawijanie tekstu
                                    overflow:
                                        TextOverflow.fade, //skracanie tekstu
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (readyInfo)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        alignment: Alignment.topCenter,
                        height: 50,
                        color: Color.fromARGB(255, 252, 193, 104),
                        padding:
                            const EdgeInsets.all(6.00), //wokół części tekstowej
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              zapis,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.bold,
                              ),
                              softWrap: false, //zawijanie tekstu
                              overflow: TextOverflow.fade, //skracanie tekstu
                            )
                          ],
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
            margin: EdgeInsets.all(15),
            padding: EdgeInsets.all(10),
            child: Text(
              rhinoText,
              style:
                  TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
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

/*
  @override
  bool shouldRepaint(CustomPainter old) {
    //throw UnimplementedError();
    return true;
  }
}
*/
