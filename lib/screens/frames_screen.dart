import 'dart:async';
//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hi_bees/models/hive.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:wakelock/wakelock.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import 'package:rhino_flutter/rhino.dart';
//import 'package:picovoice_flutter/picovoice_manager.dart';
//import 'package:picovoice_flutter/picovoice_error.dart';
import 'package:intl/intl.dart';
import '../globals.dart' as globals;
import '../helpers/db_helper.dart';
import '../models/frames.dart';
import '../models/frame.dart';
import '../models/hives.dart';
import '../models/infos.dart';
import '../models/info.dart';
import '../screens/frames_detail_screen.dart';

class FramesScreen extends StatefulWidget {
  static const routeName = '/screen-frames'; //nazwa trasy do tego ekranu

  @override
  _FramesScreenState createState() => _FramesScreenState();
}

class _FramesScreenState extends State<FramesScreen> {
  // final String accessKey =
  //    'xPj3ezZa5Y9gQj+v6xQ5YvESy7eLtUcC3NPRFj8E5yDt5MvQWj3b1w=='; // AccessKey obtained from Picovoice Console (https://console.picovoice.ai/)
  bool _isInit = true;
  //bool isError = false;
  // String errorMessage = "";

  // bool isButtonDisabled = false; //czy klawisz nieaktywny?
  // bool isProcessing =
  //    false; //czy uruchomiono proces rozpoznawania mowy przyciskiem START
  // bool wakeWordDetected = false;
  //String rhinoText = "";
  // PicovoiceManager? _picovoiceManager;
  var now = new DateTime.now();
  var formatter = new DateFormat('yyyy-MM-dd');
  List<Frames> frame =
      []; //wszystkie ramki z wybranego ula dla wszystkich dat przeglądów
  List<Frame> _daty = []; //unikalne daty
  String wybranaData = '';
  List<Frame> _korpusy = []; //unikalne korpusy

  bool readyApiary = false; //ustalony numer pasieki
  bool readyHive = false; //ustalony numer ula
  bool readyBody = false; //ustalony numer korpusu
  bool readyFrame = false; //ustalony numer ramki

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
  int nrXXFrame = 0;
  int nrXXFrameTemp = 0;
  String siteOfFrame = 'both'; //whole, cała
  //store
  int honey = 0;
  int honeySeald = 0;
  int pollen = 0;
  int brood = 0;
  int larvae = 0;
  int eggs = 0;
  int wax = 0;
  int earwax = 0;
  int queen = 0;
  int queenCells = 0;
  int delQCells = 0;
  int drone = 0;
  String porpouseOfFrame = '';
  String actionOnFrame = '';
  @override
  void initState() {
    super.initState();
    Wakelock.enable(); //blokada wyłaczania ekranu
  }

  @override
  void didChangeDependencies() {
    print('frames_screen - didChangeDependencies');
    print('frames_screen - _isInit = $_isInit');

    apiaryState = AppLocalizations.of(context)!.close;
    hiveState = AppLocalizations.of(context)!.close;
    bodyState = AppLocalizations.of(context)!.close;
    frameState = AppLocalizations.of(context)!.close;
    siteOfFrame = AppLocalizations.of(context)!.both;

    if (_isInit) {
      getDaty(globals.pasiekaID, globals.ulID).then((_) {
        //pobranie dat z bazy
        //print('data inspekcji ${globals.dataInspekcji}');
        if (globals.dataInspekcji != '') {
          wybranaData = globals.dataInspekcji; //data z elementu listy info
          globals.dataInspekcji = '';
        } else {
          if (_daty.isNotEmpty) {
            //print('wybrana = $wybranaData');
            wybranaData = _daty[0].data;
          } //najwcześniejsza data pobrana z bazy
        }

        getKorpusy(globals.pasiekaID, globals.ulID, wybranaData).then((_) {
          //ilość rekordów oznacza ilość korpusów i informacje o ich typach(1-półkorpus, 2-korpus)
          //print('ilość korpusów w wybranym ulu = ${_korpusy.length}');

          Provider.of<Frames>(context, listen: false)
              .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
              .then((_) {
            //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
            Provider.of<Infos>(context, listen: false)
                .fetchAndSetInfosForHive(globals.pasiekaID, globals.ulID)
                .then((_) {
              //wszystkie informacje dla wybranego pasieki i ula
            });

            setState(() {
              // _isLoading = false; //zatrzymanie wskaznika ładowania dań
            });
          });
        });

        setState(() {
          // _isLoading = false; //zatrzymanie wskaznika ładowania dań
        });
      });
    }
    _isInit = false;
    //Provider.of<Rests>(context, listen: false).fetchAndSetRests(); //dostawca restauracji
    super.didChangeDependencies();
  }

  //pobranie listy ramek z unikalnymi datami dla wybranego ula i pasieki z bazy lokalnej
  Future<List<Frame>> getDaty(pasieka, ul) async {
    final dataList = await DBHelper.getDate(pasieka, ul); //numer wybranego ula
    print('getDaty: pasieka $pasieka ul $ul');
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
            rozmiar: 0,
            strona: 0,
            zasob: 0,
            wartosc: '0',
            arch: 0,
          ),
        )
        .toList();
    print('daty = $_daty');
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

  Future<void> _dialogBuilderHelp(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: Column(children: <Widget>[
                //for (var i = 0; i < frames.length; i++) {}
                //Text(frames[0].data),
                Container(
                  //szare body
                  //alignment: Alignment.center,
                  color: Color.fromARGB(173, 173, 173, 173),
                  // ignore: sort_child_properties_last
                  child: CustomPaint(
                    painter: MyHiveHelp(),
                    size: Size(200, 365),
                  ),
                  margin: EdgeInsets.all(20),
                  //padding: EdgeInsets.all(10),
                ),
              ]),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.disable),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogBuilderHelpPl(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 15, right: 15),
          //title: const Text('Inspection - say e.g.:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),),
          content: Container(
            child: SingleChildScrollView(
              child: Column(children: <Widget>[
                //for (var i = 0; i < frames.length; i++) {}
                //Text(frames[0].data),
                Container(
                  //szare body
                  //alignment: Alignment.center,
                  color: Color.fromARGB(173, 173, 173, 173),
                  // ignore: sort_child_properties_last
                  child: CustomPaint(
                    painter: MyHiveHelpPl(),
                    size: Size(200, 365),
                  ),
                  margin: EdgeInsets.all(15),
                  //padding: EdgeInsets.all(10),
                ),
              ]),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.disable),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String zmienDate(String data) {
    String rok = data.substring(0, 4);
    String miesiac = data.substring(5, 7);
    String dzien = data.substring(8);
    return '$dzien.$miesiac.$rok';
  }

  @override
  Widget build(BuildContext context) {
    //przekazanie hiveNr z hives_item za pomocą navigatora
    final hiveNr = ModalRoute.of(context)!.settings.arguments as int;
    //pobranie wszystkich ramek dla ula
    final framesData = Provider.of<Frames>(context);
    //ramki z wybranej daty dla ula
    List<Frame> frames = framesData.items.where((fr) {
      return fr.data.contains(wybranaData);
    }).toList();

    // print(
    //     'frames_screen - ilość stron ramek w pasiece ${globals.pasiekaID} ulu ${globals.ulID}');
    // print(frames.length);

    //var frame = Provider.of<Frames>(context);
    // print(' frames_screen  - dane z bazy::::::::::::::::::::');
    // for (var i = 0; i < frames.length; i++) {
    //   print(
    //       '${frames[i].id},${frames[i].data},${frames[i].pasiekaNr},${frames[i].ulNr},${frames[i].korpusNr},${frames[i].typ},${frames[i].ramkaNr},${frames[i].rozmiar}');
    //   print('${frames[i].strona},${frames[i].zasob},${frames[i].wartosc}');
    //   print('-----');
    // }
    final infosData = Provider.of<Infos>(context);
    List<Info> infos = infosData.items.where((inf) {
      return inf.data.contains(wybranaData);
    }).toList();

    // for (var i = 0; i < infos.length; i++) {
    //   print(
    //       '${infos[i].id},${infos[i].data},${infos[i].pasiekaNr},${infos[i].ulNr},${infos[i].kategoria},${infos[i].parametr},${infos[i].wartosc},${infos[i].miara}');
    //   print('=======');
    // }

    //obliczane wielkości płótna dla wszystkich korpusów w ulu
    double widthCanvas = 0; //szerokość płótna
    double highCanvas = 0; //wysokość płótna
    for (var i = 0; i < _korpusy.length; i++) {
      highCanvas +=
          _korpusy[i].typ * 75 + 30; //wysokość półkorpusa + 2 po 15 na padding
      // print('wysokość = $highCanvas');
    }
    final hivesData = Provider.of<Hives>(context);
    //final hives = hivesData.items;
    List<Hive> hive = hivesData.items.where((hv) {
      return hv.ulNr == hiveNr; // jest ==  a było contain ale dla typu String
    }).toList();

    globals.iloscRamek =
        hive[0].ramek; //ilość ramek w korpusie zapamiętana w bazie
    widthCanvas = hive[0].ramek * 20 +
        20; //opis zawiera ilość ramek, po 20px na ramkę i 2 x 10px na padding
    //print('hive= ${hive[0].opis}');

    // print('szerokość = $widthCanvas');

    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        title: Text(
          AppLocalizations.of(context)!.inspectionHive + " $hiveNr",
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        // title: Text('Inspection hive $hiveNr'),
        // backgroundColor: Color.fromARGB(255, 233, 140, 0),
        //automaticallyImplyLeading: false, //usuwanie cofania
        //przycisk cofania bo go nie było
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () => {
                  Wakelock.disable(), //usunięcie blokowania wygaszania ekranu
                  Navigator.of(context).pop(),
                }),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help_center, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () => globals.jezyk == 'pl_PL'
                ? _dialogBuilderHelpPl(context)
                : _dialogBuilderHelp(context),
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => Navigator.of(context)
                .pushNamed(FramesDetailScreen.routeName, arguments: {
              'ul': globals.ulID,
              'data': wybranaData,
            }),
          )
        ],
      ),
      body: frames.length == 0
          ? Center(
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(top: 50),
                    child: Text(
                      AppLocalizations.of(context)!.noInspectionYet,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
//daty przeglądów
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.0, vertical: 1.0),
                      height: 46, //MediaQuery.of(context).size.height * 0.35,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _daty.length,
                          itemBuilder: (context, index) {
                            return Container(
                              //width: MediaQuery.of(context).size.width * 0.6,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    wybranaData = _daty[index]
                                        .data; //dla filtrowania po dacie
                                    getKorpusy(globals.pasiekaID, globals.ulID,
                                            wybranaData)
                                        .then((_) {});
                                  });
                                },
                                child: wybranaData == _daty[index].data
                                    ? Card(
                                        color: Colors.white,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.0, vertical: 1.0),
                                          child: Center(
                                              child: 
                                              globals.jezyk == 'pl_PL'
                                               ? Text(
                                                  '${zmienDate(_daty[index].data)}', 
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 17.0),
                                                )
                                              : Text(
                                                  _daty[index].data,
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 17.0),
                                                  )),
                                        ),
                                      )
                                    : Card(
                                        color: Colors.white,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.0, vertical: 1.0),
                                          child: Center(
                                              child: 
                                              globals.jezyk == 'pl_PL'
                                               ? Text(
                                                  '${zmienDate(_daty[index].data)}',
                                                    style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 17.0),
                                                  )
                                                : Text(
                                                  _daty[index].data,
                                                    style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 17.0),
                                                  )),
                                        ),
                                      ),
                              ),
                            );
                          }),
                    ),
//rysunki uli
                    SingleChildScrollView(
                        child: Column(children: <Widget>[
                      //for (var i = 0; i < frames.length; i++) {}
                      //Text(frames[0].data),
                      Container(
                        //szare body
                        //alignment: Alignment.center,
                        color: Color.fromARGB(173, 173, 173, 173),
                        // ignore: sort_child_properties_last
                        child: CustomPaint(
                          painter: MyHive(
                              ramki: frames,
                              korpusy: _korpusy,
                              width: widthCanvas,
                              high: highCanvas,
                              informacje: infos),
                          size: Size(widthCanvas, highCanvas),
                        ),
                        margin: EdgeInsets.all(20),
                        //padding: EdgeInsets.all(10),
                      ),
                    ])),
                  ],
                ),
              ),
            ),
    ));
  }

/*
  Widget footer = Container(
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.only(bottom: 20),
          child: const Text(
            "Made in Vancouver, Canada by Picovoice",
            style: TextStyle(color: Color(0xff666666)),
          ));
*/

}

//data, pasiekaNr,  ulNr,  korpusNr,  typ,  ramkaNr,  rozmiar,   strona,  zasob,  wartosc

class MyHive extends CustomPainter {
  List<Frame> ramki;
  List<Frame> korpusy;
  double width;
  double high;
  List<Info> informacje;

  MyHive({
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

    //krata odgrodowa - jeśli załozona w wybranej dacie
    String excluder = '0';
    //print('informacje.length = ${informacje.length}');//wszstkie info z wybranej daty
    for (var i = 0; i < informacje.length; i++) {
      //print('i = $i');
      //print('excluder1 = $excluder');
      //print('informacje[i].wartosc1 = ${informacje[i].wartosc} ');
      if ((informacje[i].parametr == 'excluder') ||
          (informacje[i].parametr == 'excluder -') ||
          (informacje[i].parametr == 'krata odgrodowa') ||
          (informacje[i].parametr == 'krata odgrodowa -')) {
        excluder = informacje[i]
            .miara; //zamiana pola wartosc z miara zeby poprawnie wyświetlać na listTail
        //print('excluder2 = $excluder');
        //print('informacje[i].wartosc2 = ${informacje[i].wartosc} ');
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

    //utworzenie mapy startyZasobow = key:korpusNr.ramkaNr.ramkaNr, value: start kolejnego zasobu
    for (var i = 0; i < ramki.length; i++) {
      double startMaxZasobu = ramki[i].rozmiar * 75; //wielkość ramki
      startyZasobow[
              '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] =
          startMaxZasobu; //modyfikowane dla kolejnych zasobów
      startyMaxZasobow[
              '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] =
          startMaxZasobu; //nie są modyfikowane, odniesienie dla pozycji matek, mateczników
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
    for (var i = 0; i < ramki.length; i++) {
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
          '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']!;

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
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek
          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                dronePaint); //zasob 1 - drone // dla strony lewej i prawej

            //print('${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}');
            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 2:
          //print('case 2');
          //print('start dla ramki ${ramki[i].ramkaNr} = $start');
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek
          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                broodPaint); //zasob 2 - brook // dla strony lewej i prawej

            //print('${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}');
            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 3:
          //print('case 3');
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek
          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                larvaePaint); //zasob 3 - larvae // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }

          break;
        case 4:
          //print('case 4');
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek
          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                eggPaint); //zasob 4 - egg // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 5:
          //print('case 5');
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                pollenPaint); //zasob 5 - pollen // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 6:
          //print('case 6');
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                honeyPaint); //zasob 6 - miód // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 7:
          //print('case 7');
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                sealedPaint); //zasob 7 - zasklep // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 8:
          //print('case 9');
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                waxPaint); //zasob 9 - węza // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 9:
          //print('case 8');
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          //kontrola czy zasób nie przekracza łącznie 100%
          startNastZas =
              startZasobu - ((ramki[i].rozmiar * 75) * wartoscInt) / 100;
          if (startNastZas >=
              startyMaxZasobow[
                      '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                  ramki[i].rozmiar * 75) {
            canvas.drawLine(
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start + 15 + startZasobu),
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
                        (ramki[i].strona * 8) -
                        2,
                    start +
                        15 +
                        startZasobu -
                        ((ramki[i].rozmiar * 75) * wartoscInt) / 100),
                combPaint); //zasob 8 - susz // dla strony lewej i prawej

            //modyfikacja startuZasobu w mapie startyZasobow dla danego zasobu, ramki i korpusu
            startyZasobow[
                    '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}'] =
                (startyZasobow[
                        '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! -
                    (((ramki[i].rozmiar * 75) * wartoscInt) / 100));
          }
          break;
        case 10:
          //print('case 10');
          //canvas.drawCircle(Offset(100, 100), 3, matka);
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          switch (ramki[i].wartosc) {
            case '1':
              canvas.drawCircle(
                  Offset(
                      10 +
                          (ramki[i].ramkaNr - 1) * 20 +
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
                          (ramki[i].ramkaNr - 1) * 20 +
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
                          (ramki[i].ramkaNr - 1) * 20 +
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
                          (ramki[i].ramkaNr - 1) * 20 +
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
                          (ramki[i].ramkaNr - 1) * 20 +
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
                          (ramki[i].ramkaNr - 1) * 20 +
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
                          (ramki[i].ramkaNr - 1) * 20 +
                          (ramki[i].strona * 12) -
                          8,
                      start + 20),
                  3,
                  matkaBlack);
          }
          // for (var a = 0; a < int.parse(ramki[i].wartosc); a++) {
          //   canvas.drawCircle(
          //       Offset(
          //           10 +
          //               (ramki[i].ramkaNr - 1) * 20 +
          //               (ramki[i].strona * 12) -
          //               8,
          //           start + 20),
          //       3,
          //       matka);
          // }
          break;
        case 11:
          //print('case 11');
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek

          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          double temp = startyMaxZasobow[
                  '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! +
              5;
          for (var a = 0; a < int.parse(ramki[i].wartosc); a++) {
            canvas.drawCircle(
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
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
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek

          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          double temp = startyMaxZasobow[
                  '${ramki[i].korpusNr}.${ramki[i].ramkaNr}.${ramki[i].strona}']! +
              5;
          for (var a = 0; a < int.parse(ramki[i].wartosc); a++) {
            canvas.drawCircle(
                Offset(
                    10 +
                        (ramki[i].ramkaNr - 1) * 20 +
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
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek

          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          switch (ramki[i].wartosc) {
            case 'work frame': //ramka pracy
              var angle = (math.pi * 2) / 4; //kąt (4 - kwadrat)
              radians = math.pi / 4;

              Offset center =
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 6);
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
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 7);
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
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 6);
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
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 6, start + 9),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 14, start + 9),
                  linePaint); // - (kreska pozioma) dla poszczególnych ramek

              canvas.drawLine(
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 6, start + 3),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 6, start + 10),
                  linePaint); // | (kreska pionowa lewa)
              canvas.drawLine(
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 14, start + 3),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 14, start + 10),
                  linePaint); // | (kreska pionowa prawa)
              break;
            case 'ramka pracy': //ramka pracy
              var angle = (math.pi * 2) / 4; //kąt (4 - kwadrat)
              radians = math.pi / 4;

              Offset center =
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 6);
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
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 7);
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
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 6);
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
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 6, start + 9),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 14, start + 9),
                  linePaint); // - (kreska pozioma) dla poszczególnych ramek

              canvas.drawLine(
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 6, start + 3),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 6, start + 10),
                  linePaint); // | (kreska pionowa lewa)
              canvas.drawLine(
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 14, start + 3),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 14, start + 10),
                  linePaint); // | (kreska pionowa prawa)
              break;
          }
          break;
        case 14: //is Done
          //print('case 14');
          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 4, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 16, start + 13),
              linePaint); // - (kreska pozioma) dla poszczególnych ramek

          canvas.drawLine(
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10, start + 13),
              Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
                  start + (75 * ramki[i].rozmiar) + 15),
              linePaint); // | (kreska pionowa) dla poszczególnych ramek

          switch (ramki[i].wartosc) {
            case 'moved left': //przesunieto w lewo
              sides = 3;
              radians = math.pi; //w lewo
              var angle = (math.pi * 2) / 3; //kąt (3- trójkąt)

              Offset center = Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10 - 2,
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

              Offset center = Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10 + 2,
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

              Offset center = Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
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

              Offset center = Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
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
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 1,
                      start + (75 * ramki[i].rozmiar) + 20),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 19,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // - (kreska pozioma) dla poszczególnych ramek

              canvas.drawLine(
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 1, start + 9),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 1,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // | (kreska pionowa lewa)
              canvas.drawLine(
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 19, start + 9),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 19,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // | (kreska pionowa prawa)
              break;
            case 'izolacja': //zaizolowano - załoono izolator
              canvas.drawLine(
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 1,
                      start + (75 * ramki[i].rozmiar) + 20),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 19,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // - (kreska pozioma) dla poszczególnych ramek

              canvas.drawLine(
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 1, start + 9),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 1,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // | (kreska pionowa lewa)
              canvas.drawLine(
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 19, start + 9),
                  Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 19,
                      start + (75 * ramki[i].rozmiar) + 20),
                  linePaint); // | (kreska pionowa prawa)
              break;
            case 'usuń ramka': //wycofano, usunieto
              sides = 3;
              radians = math.pi / 2; //w dół
              var angle = (math.pi * 2) / sides; //kąt (3- trójkąt)

              Offset center = Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
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

              Offset center = Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10,
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

              Offset center = Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10 + 2,
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

              Offset center = Offset(10 + (ramki[i].ramkaNr - 1) * 20 + 10 - 2,
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

class MyHiveHelp extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()..strokeWidth = 1; //linia ramki
    Paint lineExcluder = Paint()..strokeWidth = 3; //linia ramki
    // Paint obrysPaint = Paint()
    //   ..strokeWidth = 1
    //   ..color = Color.fromARGB(255, 122, 122, 122); //obrys
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
    Paint matka = Paint()
      ..color = Color.fromARGB(255, 59, 59, 59)
      ..style = PaintingStyle.fill; //matka
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
//ramka pracy
    var angle = (math.pi * 2) / 4; //kąt (4 - kwadrat)
    radians = math.pi / 4;

    Offset center = Offset(10, 20);
    Offset startPoint =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center.dx;
      double y = radius * math.sin(radians + angle * i) + center.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    var opisSpan = TextSpan(
      text: '- work frame',
      style: textStyle,
    );
    var textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 10));
//to delete
    sides = 3;
    radians = math.pi / 6;
    angle = (math.pi * 2) / sides; //kąt

    Offset center1 = Offset(10, 35);
    Offset startPoint1 =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint1.dx + center1.dx, startPoint1.dy + center1.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center1.dx;
      double y = radius * math.sin(radians + angle * i) + center1.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- to delete',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 25));
//to extraction
    double radiusEx = 4;
    sides = 6;
    radians = 0;
    angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

    Offset center2 = Offset(10, 50);
    Offset startPoint2 =
        Offset(radiusEx * math.cos(radians), radiusEx * math.sin(radians));

    path.moveTo(startPoint2.dx + center2.dx, startPoint2.dy + center2.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radiusEx * math.cos(radians + angle * i) + center2.dx;
      double y = radiusEx * math.sin(radians + angle * i) + center2.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- to extraction',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 40));
//to insutate
    sides = 4;
    radians = math.pi / 4;
    angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

    canvas.drawLine(
        Offset(7, 68), Offset(13, 68), linePaint); // - (kreska pozioma)

    canvas.drawLine(
        Offset(7, 62), Offset(7, 68), linePaint); // | (kreska pionowa lewa)
    canvas.drawLine(Offset(13, 62), Offset(13, 68), linePaint);
    opisSpan = TextSpan(
      text: '- to insulate',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 55));
//queen
    canvas.drawCircle(Offset(10, 80), 3, matka);
    opisSpan = TextSpan(
      text: '- queen',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 70));
//comb
    canvas.drawLine(Offset(10, 105), Offset(10, 115), combPaint);
    opisSpan = TextSpan(
      text: '- wax comb',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 100));
//wax
    canvas.drawLine(Offset(10, 90), Offset(10, 100), waxPaint);
    opisSpan = TextSpan(
      text: '- wax foundation',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 85));
//sealed
    canvas.drawLine(Offset(10, 135), Offset(10, 145), sealedPaint);
    opisSpan = TextSpan(
      text: '- honey sealed',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 130));
//honey
    canvas.drawLine(Offset(10, 120), Offset(10, 130), honeyPaint);
    opisSpan = TextSpan(
      text: '- honey/food',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 115));

//pollen
    canvas.drawLine(Offset(10, 150), Offset(10, 160), pollenPaint);
    opisSpan = TextSpan(
      text: '- pollen',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 145));
//eggs
    canvas.drawLine(Offset(10, 165), Offset(10, 175), eggPaint);
    opisSpan = TextSpan(
      text: '- eggs',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 160));
//larvae
    canvas.drawLine(Offset(10, 180), Offset(10, 190), larvaePaint);
    opisSpan = TextSpan(
      text: '- larvae',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 175));
//brood
    canvas.drawLine(Offset(10, 195), Offset(10, 205), broodPaint);
    opisSpan = TextSpan(
      text: '- covered brood',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 190));
//drone
    canvas.drawLine(Offset(10, 210), Offset(10, 220), dronePaint);
    opisSpan = TextSpan(
      text: '- drone',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 205));
//inserted
    sides = 3;
    radians = math.pi / 6;
    angle = (math.pi * 2) / sides; //kąt

    Offset center3 = Offset(10, 232);
    Offset startPoint3 =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint3.dx + center3.dx, startPoint3.dy + center3.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center3.dx;
      double y = radius * math.sin(radians + angle * i) + center3.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- inserted',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 220));
//deleted
    sides = 3;
    radians = math.pi / 2;
    angle = (math.pi * 2) / sides; //kąt

    Offset center4 = Offset(10, 243);
    Offset startPoint4 =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint4.dx + center4.dx, startPoint4.dy + center4.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center4.dx;
      double y = radius * math.sin(radians + angle * i) + center4.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- deleted',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 235));
//moved left
    sides = 3;
    radians = math.pi; //w lewo
    angle = (math.pi * 2) / 3; //kąt (3- trójkąt)

    Offset center5 = Offset(12, 259);
    Offset startPoint5 =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint5.dx + center5.dx, startPoint5.dy + center5.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center5.dx;
      double y = radius * math.sin(radians + angle * i) + center5.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- moved left',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 250));
//moved right
    sides = 3;
    radians = 0; //w lewo
    angle = (math.pi * 2) / 3; //kąt (3- trójkąt)

    Offset center6 = Offset(10, 274);
    Offset startPoint6 =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint6.dx + center6.dx, startPoint6.dy + center6.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center6.dx;
      double y = radius * math.sin(radians + angle * i) + center6.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- moved right',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 265));
//insulated
    canvas.drawLine(
        Offset(4, 293), Offset(16, 293), linePaint); // - (kreska pozioma)
    canvas.drawLine(
        Offset(4, 285), Offset(4, 293), linePaint); // | (kreska pionowa lewa)
    canvas.drawLine(Offset(16, 285), Offset(16, 293), linePaint);
    opisSpan = TextSpan(
      text: '- insulated',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 280));
//queen cell
    canvas.drawCircle(Offset(10, 305), 3, matecznik);
    opisSpan = TextSpan(
      text: '- queen cell',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 295));
//delete queen cell
    canvas.drawCircle(Offset(10, 320), 3, delMat);
    opisSpan = TextSpan(
      text: '- delete queen cell',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 310));
//iexcluder
    canvas.drawLine(
        Offset(4, 335), Offset(16, 335), lineExcluder); // - (kreska pozioma)
    opisSpan = TextSpan(
      text: '- excluder',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 325));
//nr body
    opisSpan = TextSpan(
      text: '1 - body number',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(6, 340));
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    //throw UnimplementedError();
    return true;
  }
}

class MyHiveHelpPl extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()..strokeWidth = 1; //linia ramki
    Paint lineExcluder = Paint()..strokeWidth = 3; //linia ramki
    // Paint obrysPaint = Paint()
    //   ..strokeWidth = 1
    //   ..color = Color.fromARGB(255, 122, 122, 122); //obrys
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
    Paint matka = Paint()
      ..color = Color.fromARGB(255, 59, 59, 59)
      ..style = PaintingStyle.fill; //matka
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
//ramka pracy
    var angle = (math.pi * 2) / 4; //kąt (4 - kwadrat)
    radians = math.pi / 4;

    Offset center = Offset(10, 20);
    Offset startPoint =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center.dx;
      double y = radius * math.sin(radians + angle * i) + center.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    var opisSpan = TextSpan(
      text: '- ramka pracy',
      style: textStyle,
    );
    var textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 10));
//to delete
    sides = 3;
    radians = math.pi / 6;
    angle = (math.pi * 2) / sides; //kąt

    Offset center1 = Offset(10, 35);
    Offset startPoint1 =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint1.dx + center1.dx, startPoint1.dy + center1.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center1.dx;
      double y = radius * math.sin(radians + angle * i) + center1.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- trzeba usunąć',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 25));
//to extraction
    double radiusEx = 4;
    sides = 6;
    radians = 0;
    angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

    Offset center2 = Offset(10, 50);
    Offset startPoint2 =
        Offset(radiusEx * math.cos(radians), radiusEx * math.sin(radians));

    path.moveTo(startPoint2.dx + center2.dx, startPoint2.dy + center2.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radiusEx * math.cos(radians + angle * i) + center2.dx;
      double y = radiusEx * math.sin(radians + angle * i) + center2.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- trzeba wirować',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 40));
//to insutate
    sides = 4;
    radians = math.pi / 4;
    angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

    canvas.drawLine(
        Offset(7, 68), Offset(13, 68), linePaint); // - (kreska pozioma)

    canvas.drawLine(
        Offset(7, 62), Offset(7, 68), linePaint); // | (kreska pionowa lewa)
    canvas.drawLine(Offset(13, 62), Offset(13, 68), linePaint);
    opisSpan = TextSpan(
      text: '- można izolować',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 55));
//queen
    canvas.drawCircle(Offset(10, 80), 3, matka);
    opisSpan = TextSpan(
      text: '- matka',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 70));
//comb
    canvas.drawLine(Offset(10, 105), Offset(10, 115), combPaint);
    opisSpan = TextSpan(
      text: '- susz',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 100));
//wax
    canvas.drawLine(Offset(10, 90), Offset(10, 100), waxPaint);
    opisSpan = TextSpan(
      text: '- węza',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 85));

//sealed
    canvas.drawLine(Offset(10, 135), Offset(10, 145), sealedPaint);
    opisSpan = TextSpan(
      text: '- miód dojrzały',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 130));
//honey
    canvas.drawLine(Offset(10, 120), Offset(10, 130), honeyPaint);
    opisSpan = TextSpan(
      text: '- miód/pokarm (nakrop)',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 115));

//pollen
    canvas.drawLine(Offset(10, 150), Offset(10, 160), pollenPaint);
    opisSpan = TextSpan(
      text: '- pierzga',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 145));
//eggs
    canvas.drawLine(Offset(10, 165), Offset(10, 175), eggPaint);
    opisSpan = TextSpan(
      text: '- jajka',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 160));
//larvae
    canvas.drawLine(Offset(10, 180), Offset(10, 190), larvaePaint);
    opisSpan = TextSpan(
      text: '- larwy',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 175));
//brood
    canvas.drawLine(Offset(10, 195), Offset(10, 205), broodPaint);
    opisSpan = TextSpan(
      text: '- czerw kryty',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 190));
//drone
    canvas.drawLine(Offset(10, 210), Offset(10, 220), dronePaint);
    opisSpan = TextSpan(
      text: '- czerw trutowy',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 205));
//inserted
    sides = 3;
    radians = math.pi / 6;
    angle = (math.pi * 2) / sides; //kąt

    Offset center3 = Offset(10, 232);
    Offset startPoint3 =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint3.dx + center3.dx, startPoint3.dy + center3.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center3.dx;
      double y = radius * math.sin(radians + angle * i) + center3.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- wstawiono ramkę',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 220));
//deleted
    sides = 3;
    radians = math.pi / 2;
    angle = (math.pi * 2) / sides; //kąt

    Offset center4 = Offset(10, 243);
    Offset startPoint4 =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint4.dx + center4.dx, startPoint4.dy + center4.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center4.dx;
      double y = radius * math.sin(radians + angle * i) + center4.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- usunięto ramkę',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 235));
//moved left
    sides = 3;
    radians = math.pi; //w lewo
    angle = (math.pi * 2) / 3; //kąt (3- trójkąt)

    Offset center5 = Offset(12, 259);
    Offset startPoint5 =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint5.dx + center5.dx, startPoint5.dy + center5.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center5.dx;
      double y = radius * math.sin(radians + angle * i) + center5.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- przesunięto w lewo',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 250));
//moved right
    sides = 3;
    radians = 0; //w lewo
    angle = (math.pi * 2) / 3; //kąt (3- trójkąt)

    Offset center6 = Offset(10, 274);
    Offset startPoint6 =
        Offset(radius * math.cos(radians), radius * math.sin(radians));

    path.moveTo(startPoint6.dx + center6.dx, startPoint6.dy + center6.dy);

    for (int i = 1; i <= sides; i++) {
      double x = radius * math.cos(radians + angle * i) + center6.dx;
      double y = radius * math.sin(radians + angle * i) + center6.dy;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paintStroke);
    opisSpan = TextSpan(
      text: '- przesunięto w prawo',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 265));
//insulated
    canvas.drawLine(
        Offset(4, 293), Offset(16, 293), linePaint); // - (kreska pozioma)
    canvas.drawLine(
        Offset(4, 285), Offset(4, 293), linePaint); // | (kreska pionowa lewa)
    canvas.drawLine(Offset(16, 285), Offset(16, 293), linePaint);
    opisSpan = TextSpan(
      text: '- zaizolowano',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 280));
//queen cell
    canvas.drawCircle(Offset(10, 305), 3, matecznik);
    opisSpan = TextSpan(
      text: '- matecznik',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 295));
//delete queen cell
    canvas.drawCircle(Offset(10, 320), 3, delMat);
    opisSpan = TextSpan(
      text: '- usunięty matecznik',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 310));
//iexcluder
    canvas.drawLine(
        Offset(4, 335), Offset(16, 335), lineExcluder); // - (kreska pozioma)
    opisSpan = TextSpan(
      text: '- krata odgrodowa',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(20, 325));
//nr body
    opisSpan = TextSpan(
      text: '1 - numer korpusu',
      style: textStyle,
    );
    textOpis = TextPainter(
      text: opisSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textOpis.layout(
      minWidth: 0,
      maxWidth: 200,
    );
    textOpis.paint(canvas, Offset(6, 340));
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    //throw UnimplementedError();
    return true;
  }
}
