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

import 'package:rhino_flutter/rhino.dart';
import 'package:picovoice_flutter/picovoice_manager.dart';
import 'package:picovoice_flutter/picovoice_error.dart';
import 'package:intl/intl.dart';
import '../globals.dart' as globals;
import '../models/frame.dart';
import '../models/frames.dart';
import '../models/hives.dart';
import '../models/apiarys.dart';
import '../models/info.dart';
import '../models/infos.dart';
//void main() {
//  runApp(MyApp());
//}

class VoiceScreen extends StatefulWidget {
  static const routeName = '/screen-voice'; //nazwa trasy do tego ekranu

  @override
  _VoiceScreenState createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final String accessKey =
      'xPj3ezZa5Y9gQj+v6xQ5YvESy7eLtUcC3NPRFj8E5yDt5MvQWj3b1w=='; // AccessKey obtained from Picovoice Console (https://console.picovoice.ai/)

  //final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isInit = true;
  bool isError = false;
  String errorMessage = "";

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
  String formatedTime = '';
  List<Frames> frame = [];
  String ikona = '';
  String opis = '';
  int ileUli = 0;

  bool readyApiary = false; //ustalony numer pasieki
  bool readyHive = false; //ustalony numer ula
  bool readyBody = false; //ustalony numer korpusu
  bool readyFrame = false; //ustalony numer ramki
  bool readyStory = false; //gotowość do zapisu w bazie poszczególnych produktów

  //intents
  String intention = '';

  //slots
  String apiaryState = 'close'; //stan pasieki
  int nrXXOfApiary = 0; //numer pasieki
  int nrXXOfApairyTemp = 0;
  String hiveState = 'close';
  int nrXXOfHive = 0;
  int nrXXOfHiveTemp =
      0; //tymczasowy numer ula potrzebny przy resecie bo inna kolejność pól w slocie
  String bodyState = 'close';
  int nrXOfBody = 0;
  int nrXOfBodyTemp = 0;
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
  int _strona = 0;

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
    });

    initPicovoice();
  }

  @override
  void didChangeDependencies() {
    print('voice_screen: wejscie do Dependencies ms 1');

    print('voice_screen: _isInit = $_isInit');
    if (_isInit) {
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
    String platform = Platform.isAndroid
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
    setState(() {
      wakeWordDetected = true;
      rhinoText =
          "\"Hi Bees!\" detected!\nListening for intent..."; //po słowie wybudzenia
      FlutterBeep.playSysSound(iOSSoundIDs.BeginRecording);
    });
  }

//funkcja wywołania zwrotnego przyjmuje parametr RhinoInterface z parametrami: isUnderstood - czy Rhino zrozumiał na podstawie kontekstu, intent - nazwa intencji jeśli zrozumiał, slots - klucz i wartość wnioskowania
  void inferenceCallback(RhinoInference inference) {
    setState(() {
      rhinoText = prettyPrintInference(inference);
      wakeWordDetected = false;
    });

    //print('zmienn apiaryState = $apiaryState');

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (isProcessing) {
        if (wakeWordDetected) {
          rhinoText = "\"Hi Bees!\" detected!\nListening for intent...";
          //FlutterBeep.playSysSound(iOSSoundIDs.BeginRecording);
          //FlutterBeep.playSysSound(iOSSoundIDs.Headset_StartCall);
        } else {
          setState(() {
            rhinoText =
                "Listening for \"Hi Bees!\""; //po zakończeniu wnioskowania
            //rhinoText += "\"Hi Bees\"";
            FlutterBeep.playSysSound(iOSSoundIDs.ConnectedToPower);
          });
        }
      } else {
        setState(() {
          rhinoText = "";
        });
      }
    });
  }

  void errorCallback(PicovoiceException error) {
    if (error.message != null) {
      setState(() {
        isError = true;
        errorMessage = error.message!;
        isProcessing = false;
      });
    }
  }

  String prettyPrintInference(RhinoInference inference) {
    String printText = "";
    if (inference.isUnderstood!) {
      //printText += "I uderstood :)\n";
    } else {
      printText += "I not uderstood :(";
      FlutterBeep.playSysSound(iOSSoundIDs.Headset_TransitionEnd);
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
        case 'setBody':
          printText += " Body";
          intention = 'setBody';
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
      }
      if (inference.slots!.isNotEmpty) {
        //printText += '    "slots" : {\n';
        Map<String, String> slots = inference.slots!;
        for (String key in slots.keys) {
          // printText += "   $key: ${slots[key]},\n";
          //  printText += "        \"$key\" : \"${slots[key]}\",\n";
          switch (key) {
            case 'apiaryState':
              apiaryState = '${slots[key]}';
              if (apiaryState == 'close') {
                FlutterBeep.playSysSound(iOSSoundIDs.CameraShutter);
                printText += " ${slots[key]}";
                readyApiary = false;
                nrXXOfApiary = 0;
                nrXXOfApairyTemp = 0;
                readyHive = false;
                nrXXOfHive = 0;
                bodyState = 'close';
                readyBody = false;
                resetBody();
                resetFrame();
                resetInfo();
              } else {
                // przypadek dla odwrotnej kolejności wnioskowania lub/i przy ustawianiu Apiary
                printText += " ${slots[key]}";
                readyApiary = true; //ustawienie Apairy
                FlutterBeep.playSysSound(iOSSoundIDs.EndRecording);
                nrXXOfApiary =
                    nrXXOfApairyTemp; // ustawienie numeru Apairy z temp
                nrXXOfApairyTemp = 0;
                //zerowanie Hive, Body i Frame
                readyHive = false;
                hiveState = 'close';
                nrXXOfHive = 0;
                bodyState = 'close';
                readyBody = false;
                resetBody();
                resetFrame();
              }
              break;
            case 'nrXXOfApiary':
              nrXXOfApiary = int.parse('${slots[key]}');
              if (apiaryState == 'open' || apiaryState == 'set') {
                printText += " ${slots[key]}";
                nrXXOfApairyTemp = nrXXOfApiary;
                readyApiary =
                    true; // ustawienie Apairy - kolejność wnioskowania poprawna
                FlutterBeep.playSysSound(iOSSoundIDs.EndRecording);
                //zerowanie danych Hive, Body i Frame
                readyHive = false;
                hiveState = 'close';
                nrXXOfHive = 0;
                bodyState = 'close';
                readyBody = false;
                resetBody();
                resetFrame();
              } else {
                //przypadek kiedy najpierw będzie numer a pózniej status pasieki (a teraz jest close)
                printText += " ${slots[key]}";
                nrXXOfApairyTemp = nrXXOfApiary;
                nrXXOfApiary = 0;
                readyApiary = false;
                readyHive = false;
                nrXXOfHive = 0;
                bodyState = 'close';
                readyBody = false;
                resetBody();
                resetFrame();
              }
              break;
            case 'hiveState':
              hiveState = '${slots[key]}';
              if (hiveState == 'close') {
                FlutterBeep.playSysSound(iOSSoundIDs.CameraShutter);
                printText += " ${slots[key]}";
                readyHive = false;
                nrXXOfHive = 0;
                nrXXOfHiveTemp = 0;
                bodyState = 'close';
                readyBody = false;
                resetBody();
                resetFrame();
              } else {
                if (readyApiary == true ||
                    (readyApiary == false && nrXXOfApiary == 0)) {
                  //otwieranie Hive jezeli otwarto Apiary lub jest tylko jedna (lub pierwsza) pasieka
                  printText += " ${slots[key]}";
                  nrXXOfHive =
                      nrXXOfHiveTemp; //bo inna kolejnośc wartości w slocie (patrz wydruk)- zmienić kolejność case???
                  nrXXOfHiveTemp = 0;
                  readyHive = true;
                  FlutterBeep.playSysSound(iOSSoundIDs.EndRecording);
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
                printText += " ${slots[key]}";
                if (readyApiary == false && nrXXOfApiary == 0) {
                  readyApiary = true;
                  FlutterBeep.playSysSound(iOSSoundIDs.EndRecording);
                  nrXXOfApiary = 1;
                }
                readyHive = true;
                FlutterBeep.playSysSound(iOSSoundIDs.EndRecording);
                nrXXOfHiveTemp = nrXXOfHive;
                bodyState = 'close';
                readyBody = false;
                resetBody();
                resetFrame();
              } else {
                printText += " ${slots[key]}";
                nrXXOfHiveTemp = nrXXOfHive;
                nrXXOfHive = 0;
                bodyState = 'close';
                readyBody = false;
                resetBody();
                resetFrame();
              }
              break;
            case 'bodyState':
              bodyState = '${slots[key]}';
              if (bodyState == 'close') {
                FlutterBeep.playSysSound(iOSSoundIDs.CameraShutter);
                printText += " ${slots[key]}";
                readyBody = false;
                readyFrame = false;
                nrXOfBodyTemp = 0;
                resetBody();
                resetFrame();
              } else {
                if (readyApiary == true && readyHive == true) {
                  //otwieranie Body jezeli otwarto Apiary i Hive
                  printText += " ${slots[key]}";
                  if (nrXOfBodyTemp != 0) {
                    nrXOfBody = nrXOfBodyTemp;
                    sizeOfFrame = 'big';
                  }
                  if (nrXOfHalfBodyTemp != 0) {
                    nrXOfHalfBody = nrXOfHalfBodyTemp;
                    sizeOfFrame = 'small';
                  }
                  nrXOfBodyTemp = 0;
                  nrXOfHalfBodyTemp = 0;
                  readyBody = true;
                  FlutterBeep.playSysSound(iOSSoundIDs.EndRecording);
                  readyFrame = false;
                  resetFrame();
                }
              }
              break;
            case 'nrXOfBody':
              nrXOfBody = int.parse('${slots[key]}');
              if ((bodyState == 'open' || bodyState == 'set') &&
                  (readyApiary == true && readyHive == true)) {
                printText += " ${slots[key]}";
                readyBody = true;
                FlutterBeep.playSysSound(iOSSoundIDs.EndRecording);
                nrXOfBodyTemp = nrXOfBody;
                nrXOfHalfBody = 0;
                nrXOfHalfBodyTemp = 0;
                readyFrame = false;
                nrXXOfFrame = 0;
                sizeOfFrame = 'big'; //bo korpus
                resetFrame();
              } else {
                printText += " ${slots[key]}";
                nrXOfBodyTemp = nrXOfBody;
                nrXOfBody = 0;
                nrXOfHalfBody = 0;
                nrXXOfFrame = 0;
                readyBody = false;
                readyFrame = false;
                resetFrame();
              }
              break;
            case 'nrXOfHalfBody':
              nrXOfHalfBody = int.parse('${slots[key]}');
              if ((bodyState == 'open' || bodyState == 'set') &&
                  (readyApiary == true && readyHive == true)) {
                printText += " half ${slots[key]}";
                readyBody = true;
                FlutterBeep.playSysSound(iOSSoundIDs.EndRecording);
                nrXOfHalfBodyTemp = nrXOfHalfBody;
                nrXOfBody = 0;
                nrXOfBodyTemp = 0;
                nrXXOfFrame = 0;
                sizeOfFrame = 'small'; //bo półkorpus
                resetFrame();
              } else {
                printText += " half ${slots[key]}";
                nrXOfHalfBodyTemp = nrXOfHalfBody;
                nrXOfHalfBody = 0;
                nrXOfBody = 0;
                nrXXOfFrame = 0;
                readyFrame = false;
                resetFrame();
              }
              break;
            case 'frameState':
              frameState = '${slots[key]}';
              if (frameState == 'close') {
                FlutterBeep.playSysSound(iOSSoundIDs.CameraShutter);
                printText += " ${slots[key]}";
                readyFrame = false;
                nrXXOfFrame = 0;
                nrXXOfFrameTemp;
                resetFrame();
              } else {
                if (readyApiary == true &&
                    readyHive == true &&
                    readyBody == true) {
                  printText += " ${slots[key]}";
                  nrXXOfFrame = nrXXOfFrameTemp;
                  nrXXOfFrameTemp = 0;
                  readyFrame = true;
                  FlutterBeep.playSysSound(iOSSoundIDs.EndRecording);
                  resetFrame();
                }
              }
              break;
            case 'nrXXOfFrame':
              nrXXOfFrame = int.parse('${slots[key]}');
              if ((frameState == 'open' || frameState == 'set') &&
                  (readyApiary == true &&
                      readyHive == true &&
                      readyBody == true)) {
                printText += " ${slots[key]}";
                readyFrame = true;
                nrXXOfFrameTemp = nrXXOfFrame;
                resetFrame(); //kasowanie zmiennych przechowujących biezace zasoby ramki (bo nowa ramka)
              } else {
                if (readyApiary == true &&
                    readyHive == true &&
                    readyBody == true) {
                  printText += " ${slots[key]}";
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
                  readyBody == true &&
                  readyFrame == true) {
                FlutterBeep.playSysSound(iOSSoundIDs.EndRecording);
                printText += "\n Site of frame =";
                printText += " ${slots[key]}";
                siteOfFrame = '${slots[key]}';
              }
              break;
            case 'sizeOFframe': //OfFrame
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Size of frame =";
                printText += " ${slots[key]}";
                sizeOfFrame = '${slots[key]}';
              }
              break;
            case 'drone':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Drone =";
                printText += " ${slots[key]}";
                drone = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(1, '${slots[key]}'); //
              }
              break;
            case 'brood':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Brood covered =";
                printText += " ${slots[key]}";
                brood = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(2, '${slots[key]}'); //
              }
              break;
            case 'larvae':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Larvae =";
                printText += " ${slots[key]}";
                larvae = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(3, '${slots[key]}'); //
              }
              break;
            case 'eggs':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Eggs =";
                printText += " ${slots[key]}";
                eggs = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(4, '${slots[key]}'); //
              }
              break;
            case 'pollen':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Pollen =";
                printText += " ${slots[key]}";
                pollen = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(5, '${slots[key]}'); //
              }
              break;
            case 'honeySealed':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Honey sealed =";
                printText += " ${slots[key]}";
                honeySeald = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(6, '${slots[key]}'); //2-honeySeald
              }
              break;
            case 'honey':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Honey =";
                printText += " ${slots[key]}";
                honey = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(7, '${slots[key]}'); //1-honey
              }
              break;
            case 'waxComb':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Wax comb =";
                printText += " ${slots[key]}";
                waxComb = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(8, '${slots[key]}'); //
              }
              break;
            case 'wax':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Wax fundation=";
                printText += " ${slots[key]}";
                wax = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(9, '${slots[key]}'); //
              }
              break;
            case 'queen':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Queen =";
                printText += " ${slots[key]}";
                queen = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(10, '${slots[key]}'); //
              }
              break;
            case 'queenCells':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Queen cells =";
                printText += " ${slots[key]}";
                queenCells = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(11, '${slots[key]}'); //
              }
              break;
            case 'delQCells':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n Delete queen cels =";
                printText += " ${slots[key]}";
                delQCells = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(12, '${slots[key]}'); //
              }
              break;
            case 'toDo':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n to Do =";
                printText += " ${slots[key]}";
                toDo = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(13, '${slots[key]}'); //
              }
              break;
            case 'isDone':
              if (readyApiary == true &&
                  readyHive == true &&
                  readyBody == true &&
                  readyFrame == true) {
                printText += "\n is Done =";
                printText += " ${slots[key]}";
                isDone = '${slots[key]}';
                readyStory = true;
                zapisDoBazy(14, '${slots[key]}'); //
              }
              break;
            case 'excluder': //krata odgrodowa
              if (readyApiary == true && readyHive == true) {
                printText += "\n Exculuder =";
                printText += " on ${slots[key]} body";
                //setEquipment = '${slots[key]}';
                //readyStory = true;
                zapisInfoDoBazy('equipment', 'excluder', 'on body number',
                    '${slots[key]}'); //
              }
              break;
            case 'excluderDel': //krata odgrodowa
              if (readyApiary == true && readyHive == true) {
                printText += "\n Exculuder =";
                printText += " ${slots[key]}";
                //setEquipment = '${slots[key]}';
                //readyStory = true;
                zapisInfoDoBazy(
                    'equipment', 'excluder -', '${slots[key]}', '0'); //remove
              }
              break;
            case 'syrup1to1I': //syrop 1 do 1 część całkowita w litrach
              if (readyApiary == true && readyHive == true) {
                printText += "\n Syrup 1:1 =";
                printText += "  ${slots[key]}";
                syrup1to1I = '${slots[key]}';
                //readyStory = true;
                zapisInfoDoBazy(
                    'feeding', 'syrup 1:1', '$syrup1to1I.$syrup1to1D', 'l'); //
              }
              break;
            case 'syrup1to1D': //syrop 1 do 1 część dziesiętna
              if (readyApiary == true && readyHive == true) {
                printText += "\n Syrup 1:1 =";
                printText += "  ${slots[key]}";
                syrup1to1D = '${slots[key]}';
                //readyStory = true;
                zapisInfoDoBazy(
                    'feeding', 'syrup 1:1', '$syrup1to1I.$syrup1to1D', 'l'); //
              }
              break;
            case 'syrup3to2I': //syrop 3 do 2 część całkowita w litrach
              if (readyApiary == true && readyHive == true) {
                printText += "\n Syrup 3:2 =";
                printText += "  ${slots[key]}";
                syrup3to2I = '${slots[key]}';
                //readyStory = true;
                zapisInfoDoBazy(
                    'feeding', 'syrup 3:2', '$syrup3to2I.$syrup3to2D', 'l'); //
              }
              break;
            case 'syrup3to2D': //syrop 3 do 2 część dziesiętna
              if (readyApiary == true && readyHive == true) {
                printText += "\n Syrup 3:2 =";
                printText += "  ${slots[key]}";
                syrup3to2D = '${slots[key]}';
                //readyStory = true;
                zapisInfoDoBazy(
                    'feeding', 'syrup 3:2', '$syrup3to2I.$syrup3to2D', 'l'); //
              }
              break;
            case 'candyI': //candy część całkowita w litrach
              if (readyApiary == true && readyHive == true) {
                printText += "\n Candy =";
                printText += "  ${slots[key]}";
                candyI = '${slots[key]}';
                //readyStory = true;
                zapisInfoDoBazy('feeding', 'candy', '$candyI.$candyD', 'kg'); //
              }
              break;
            case 'candyD': //candy część dziesiętna
              if (readyApiary == true && readyHive == true) {
                printText += "\n Candy =";
                printText += "  ${slots[key]}";
                candyD = '${slots[key]}';
                //readyStory = true;
                zapisInfoDoBazy('feeding', 'candy', '$candyI.$candyD', 'kg'); //
              }
              break;
            case 'invertI': //invert część całkowita w litrach
              if (readyApiary == true && readyHive == true) {
                printText += "\n Invert =";
                printText += "  ${slots[key]}";
                invertI = '${slots[key]}';
                //readyStory = true;
                zapisInfoDoBazy(
                    'feeding', 'invert', '$invertI.$invertD', 'l'); //
              }
              break;
            case 'invertD': //invert część dziesiętna
              if (readyApiary == true && readyHive == true) {
                printText += "\n Invert =";
                printText += "  ${slots[key]}";
                invertD = '${slots[key]}';
                //readyStory = true;
                zapisInfoDoBazy(
                    'feeding', 'invert', '$invertI.$invertD', 'l'); //
              }
              break;
            case 'removedFood': //usunięto pokarm
              if (readyApiary == true && readyHive == true) {
                printText += "\n Removed food =";
                printText += "  ${slots[key]}";
                removedFood = '${slots[key]}';
                zapisInfoDoBazy('feeding', 'removed food', removedFood, ''); //
              }
              break;
            case 'leftFood': //pozostał (niezjedzony) pokarm
              if (readyApiary == true && readyHive == true) {
                printText += "\n Left food =";
                printText += "  ${slots[key]}";
                leftFood = '${slots[key]}';
                zapisInfoDoBazy('feeding', 'left food', leftFood, ''); //
              }
              break;
            case 'apivarol': //
              if (readyApiary == true && readyHive == true) {
                printText += "\n Apiwarol =";
                printText += "  ${slots[key]}";
                //leftFood = '${slots[key]}';
                zapisInfoDoBazy(
                    'treatment', 'apivarol', '${slots[key]}', 'dose'); //
              }
              break;
            case 'biovar': //
              if (readyApiary == true && readyHive == true) {
                printText += "\n Biowar =";
                printText += "  ${slots[key]}";
                //leftFood = '${slots[key]}';
                zapisInfoDoBazy(
                    'treatment', 'biovar', '${slots[key]}', 'belts'); //
              }
              break;
            case 'varroa': //
              if (readyApiary == true && readyHive == true) {
                printText += "\n Varroa =";
                printText += "  ${slots[key]}";
                //leftFood = '${slots[key]}';
                zapisInfoDoBazy(
                    'treatment', 'varroa', '${slots[key]}', 'mites'); //
              }
              break;
            case 'varroaH': //
              if (readyApiary == true && readyHive == true) {
                printText += "\n Varroa =";
                printText += "  ${slots[key]}00";
                //leftFood = '${slots[key]}';
                zapisInfoDoBazy(
                    'treatment', 'varroa', '${slots[key]}00', 'mites'); //
              }
              break;
            case 'queenState': //
              if (readyApiary == true && readyHive == true) {
                printText += "\n Queen =";
                printText += "  ${slots[key]}";
                //leftFood = '${slots[key]}';
                zapisInfoDoBazy('queen', 'queen -', '${slots[key]}', ''); //
              }
              break;
            case 'queenStart': //
              if (readyApiary == true && readyHive == true) {
                printText += "\n Queen =";
                printText += "  ${slots[key]}";
                //leftFood = '${slots[key]}';
                zapisInfoDoBazy('queen', 'queen is', '${slots[key]}', ''); //
              }
              break;
            case 'queenMark': //
              if (readyApiary == true && readyHive == true) {
                printText += "\n Queen =";
                printText += "  ${slots[key]}";
                //leftFood = '${slots[key]}';
                zapisInfoDoBazy('queen', ' queen is', '${slots[key]}', ''); //
              }
              break;
            case 'queenQuality': //
              if (readyApiary == true && readyHive == true) {
                printText += "\n Queen =";
                printText += "  ${slots[key]}";
                //leftFood = '${slots[key]}';
                zapisInfoDoBazy('queen', 'queen is ', '${slots[key]}', ''); //
              }
              break;
            case 'queenBorn': //
              if (readyApiary == true && readyHive == true) {
                printText += "\n Queen was born in 20";
                printText += "${slots[key]}";
                zapisInfoDoBazy('queen', 'queen was born', 'in 20${slots[key]}', ''); //
              }
              break;
            case 'numberOfFrame':
              if (readyApiary == true && readyHive == true) {
                printText += "\n Number of frame =";
                printText += " ${slots[key]}";
                globals.iloscRamek = '${slots[key]}';
                zapisInfoDoBazy(
                    'equipment', 'number of frame = ', '${slots[key]}', ''); //
              }
              break;
          }
        }
        //printText += '    }\n';
      }
    }
    //printText += '}';
    print('wynik = $printText');

    print('intention = $intention');
    print('readyApiary = $readyApiary');
    print('readyHive = $readyHive');
    print('readyBody = $readyBody');
    print('readyFrame = $readyFrame');
    print('---');
    print('apiaryState = $apiaryState');
    print('nrXXOfApiary = $nrXXOfApiary');
    print('hiveState = $hiveState');
    print('nrXXOfHive = $nrXXOfHive');
    print('bodyState = $bodyState');
    print('nrXOfBody = $nrXOfBody');
    print('nrXOfHalfBody = $nrXOfHalfBody');
    print('frameState = $frameState');
    print('nrXXOfFrame = $nrXXOfFrame');
    print('siteOfFrame = $siteOfFrame');
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
  }

  //info(id TEXT PRIMARY KEY, pasiekaNr INTEGER, ileUli INTEGER, data TEXT, kategoria TEXT, parametr TEXT, wartosc TEXT, miara TEXT, uwagi TEXT)');
  zapisInfoDoBazy(String kat, String param, String wart, String miar) {
    formattedDate = formatter.format(now);
    formatedTime = formatterHm.format(now);
    if (ikona == '') ikona = 'green';

    print('czas $formatedTime');

    Infos.insertInfo(
        '$formattedDate.$nrXXOfApiary.$nrXXOfHive.$kat.$param', //id
        formattedDate, //data
        nrXXOfApiary, //pasiekaNr
        nrXXOfHive, //ulNr
        kat, //karegoria
        param, //parametr
        wart, //wartosc
        miar, //miara
        formatedTime); //uwagi
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
    FlutterBeep.playSysSound(iOSSoundIDs.SMSSent1); //beep
    print('voice_screen: zapis Frame do bazy');
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
    } on PicovoiceInvalidArgumentException catch (ex) {
      errorCallback(PicovoiceInvalidArgumentException(
          "${ex.message}\nEnsure your accessKey '$accessKey' is a valid access key."));
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
    FlutterBeep.playSysSound(iOSSoundIDs.ConnectedToPower); //iOSSoundIDs.ConnectedToPower
    //FlutterBeep.playSysSound();
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
  }

  Color picoBlue = Color.fromRGBO(55, 125, 255, 1);
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
    final framesData = Provider.of<Frames>(context);
    List<Frame> frames = framesData.items.toList();

    print('voice_screen: początek budowy ekranu - dane z bazy:::::');
    for (var i = 0; i < frames.length; i++) {
      print('${frames[i].id}');
      print(
          '${frames[i].data},${frames[i].pasiekaNr},${frames[i].ulNr},${frames[i].korpusNr},${frames[i].typ},${frames[i].ramkaNr},${frames[i].rozmiar}');
      print('${frames[i].strona},${frames[i].zasob},${frames[i].wartosc}');
      print('-----');
    }

//var frame = Provider.of<Frames>(context, listen: false).fetchAndSetFrames().then((_) {
    //    print('wczytanie danych');
    // });
    //    frame = frameData.items.where((fr) {
    //      return fr.pasiekaId.contains('1');
    //   }).toList();

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 233, 140, 0),
          title: Text('Voice Control'),
          //automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Color.fromARGB(255, 255, 255, 255)),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
                            style: const TextStyle(fontSize: 14)), // fontWeight: FontWeight.bold
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
          color: Color.fromARGB(255, 236, 222, 202),
          margin: EdgeInsets.all(20),
          child: Column(
            children: [
              if (readyApiary)
                Row(
                  children: [
                    Text('Apiary nr $nrXXOfApiary'),
                  ],
                ),
              if (readyHive)
                Row(
                  children: [
                    Text('Hives nr $nrXXOfHive'),
                  ],
                ),
              if (readyBody && (nrXOfBody != 0))
                Row(
                  children: [Text('Body nr $nrXOfBody'), Container()],
                ),
              if (readyBody && (nrXOfHalfBody != 0))
                Row(
                  children: [
                    Text('Half body nr $nrXOfHalfBody'),
                  ],
                ),
              if (readyFrame)
                Row(
                  children: [
                    Text('Frame nr $nrXXOfFrame on $siteOfFrame site'),
                  ],
                ),
              if (readyApiary &&
                  readyHive &&
                  readyBody &&
                  readyFrame &&
                  readyStory)
                Row(
                  children: [
                    Text('Story -> zapis do bazy'),
                  ],
                )
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
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(10),
            child: Text(
              rhinoText,
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
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
