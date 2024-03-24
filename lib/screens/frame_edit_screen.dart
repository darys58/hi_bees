import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;
import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
import '../models/apiarys.dart';
import '../models/frame.dart';
import '../models/hives.dart';
import '../models/infos.dart';
//import '../screens/activation_screen.dart';
import '../models/frames.dart';
import '../models/hive.dart';
import 'package:flutter/services.dart';
//import 'frames_detail_screen.dart';

class FrameEditScreen extends StatefulWidget {
  static const routeName = '/frame_edit';

  @override
  State<FrameEditScreen> createState() => _FrameEditScreenState();
}

class _FrameEditScreenState extends State<FrameEditScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');
  var formatterHm = new DateFormat('H:mm');
  // String nowyRok = '0';
  // String nowyMiesiac = '0';
  // String nowyDzien = '0';
  int? nowyNrPasieki;
  int? nowyNrUla;
  int? nowyNrKorpusu;
  int? nowyNrRamki;
  int rozmiarRamki = 2;
  int stronaRamki = 0;
  //bool lewa = false;
  //bool prawa = false;
  int korpus = 2;
  int? nowyZasob;
  //int? tempZasob;
  String nowaWartosc = '0';
  String tempNowaWartosc = '0';
  // String noweToDo = '0';
  // String noweIsDone = '0';
  List<Frame> ramka = [];
  List<Hive> hive = [];
  String tryb = '';
  String tytulEkranu = '';
  String ikona = 'green';
  TextEditingController dateController = TextEditingController();

  @override
  void didChangeDependencies() {
    final routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    final idRamki = routeArgs['idRamki'];
    final idPasieki = routeArgs['idPasieki'];
    final idUla = routeArgs['idUla'];
    final idZasobu = routeArgs['idZasobu'];
    //print('ramka = $idRamki, pasieka = $idPasieki , ul = $idUla');

    if (idRamki != null) {
      //jezeli edycja istniejącego wpisu
      final frameData = Provider.of<Frames>(context, listen: false);
      ramka = frameData.items.where((element) {
        //to wczytanie danych ramki
        return element.id.contains('$idRamki');
      }).toList();
      dateController.text = ramka[0].data;
      // nowyRok = ramka[0].data.substring(0, 4);
      // nowyMiesiac = ramka[0].data.substring(5, 7);
      // nowyDzien = ramka[0].data.substring(8);
      nowyNrPasieki = ramka[0].pasiekaNr;
      nowyNrUla = ramka[0].ulNr;
      nowyNrKorpusu = ramka[0].korpusNr;
      nowyNrRamki = ramka[0].ramkaNr;

      korpus = ramka[0].typ;
      rozmiarRamki = ramka[0].rozmiar;
      nowyZasob = ramka[0].zasob;
      //tempZasob = nowyZasob;
      nowaWartosc = ramka[0].wartosc.replaceAll(RegExp('%'), '');
      tempNowaWartosc = nowaWartosc;
      stronaRamki = ramka[0].strona; //1-lewa, 2-prawa
      tryb = 'edycja';
      tytulEkranu = AppLocalizations.of(context)!.editingFrame;
    } else {
      //jezeli dodanie nowego wpisu (tylko dla aktualnie wybranej pasieki i ula)
      dateController.text = DateTime.now().toString().substring(0, 10);
      // nowyRok = DateFormat('yyyy').format(DateTime.now());
      // nowyMiesiac = DateFormat('MM').format(DateTime.now());
      // nowyDzien = DateFormat('dd').format(DateTime.now());
      nowyNrPasieki = int.parse('$idPasieki');
      nowyNrUla = int.parse('$idUla');
      nowyNrKorpusu = 1;
      nowyNrRamki = 1;
      korpus = 2;
      rozmiarRamki = 2;
      stronaRamki = 2;
      nowyZasob = int.parse('$idZasobu');
      //tempZasob = nowyZasob;
      nowaWartosc = '0';
      tempNowaWartosc = nowaWartosc;
      tryb = 'dodaj';
      tytulEkranu = AppLocalizations.of(context)!.addFrame;
      if (nowyZasob == 13)
        nowaWartosc = AppLocalizations.of(context)!.workFrame;
      if (nowyZasob == 14) nowaWartosc = AppLocalizations.of(context)!.deleted;
    }

    super.didChangeDependencies();
  }

  // // void _showAlertAnuluj(BuildContext context, String nazwa, String text) {
  // Future<bool> _isInternet() async {
  //   var connectivityResult = await (Connectivity().checkConnectivity());
  //   if (connectivityResult == ConnectivityResult.mobile) {
  //     print("Connected to Mobile Network");
  //     return true;
  //   } else if (connectivityResult == ConnectivityResult.wifi) {
  //     print("Connected to WiFi");
  //     return true;
  //   } else {
  //     print("Unable to connect. Please Check Internet Connection");
  //     return false;
  //   }
  // }

  zapisDoBazy(int zas, wart, String coZrobic) {
    String formattedDate =
        dateController.text; //nowyRok + '-' + nowyMiesiac + '-' + nowyDzien;

    if (zas < 10) wart = nowaWartosc + '%';

    //data.       pasiekaNr.    ulNr.     korpusNr.   ramkaNr.   strona.  zasob

    if (stronaRamki == 1) {
      // print(
      //     'zapis do bazy id = $formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.1.$zas');
      // print('nowa wartość = $wart');
      // print(
      //     'dane do zapisu = $formattedDate, $nowyNrPasieki,$nowyNrUla,$nowyNrKorpusu,$korpus,$nowyNrRamki,$rozmiarRamki,1,$zas,$wart,0');

      Frames.insertFrame(
          '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.1.$zas',
          formattedDate,
          nowyNrPasieki!,
          nowyNrUla!,
          nowyNrKorpusu!,
          korpus,
          nowyNrRamki!,
          rozmiarRamki,
          1, //lewa
          zas,
          wart,
          0); //arch
    }
    if (stronaRamki == 2) {
      // print(
      //     'zapis do bazy  id = $formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.2.$zas');
      // print('nowa wartość = $wart');
      Frames.insertFrame(
          '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.2.$zas',
          formattedDate,
          nowyNrPasieki!,
          nowyNrUla!,
          nowyNrKorpusu!,
          korpus,
          nowyNrRamki!,
          rozmiarRamki,
          2, //prawa
          zas,
          wart,
          0); //arch
    }
    //jezeli ikona była czerwona to nie zmieniamy
    // if (zas == 13 && globals.ikonaUla != 'red') {
    //   globals.ikonaUla = 'yellow';
    // }
    // if (zas == 13 && globals.ikonaPasieki != 'red') {
    //   globals.ikonaPasieki = 'yellow';
    // }

    //edycja = grey - znaczy ze była edycja przeglądu
    zapisInfoDoBazy('inspection', AppLocalizations.of(context)!.inspection,
        AppLocalizations.of(context)!.edited, coZrobic);
  }

  //info(id TEXT PRIMARY KEY, pasiekaNr INTEGER, ileUli INTEGER, data TEXT, kategoria TEXT, parametr TEXT, wartosc TEXT, miara TEXT, uwagi TEXT)');
  zapisInfoDoBazy(String kat, String param, String wart, String zrobic) {
    String formattedDate = dateController.text;
    //nowyRok + '-' + nowyMiesiac + '-' + nowyDzien;

    // if (wart == 'brak' || wart == 'nie ma' || wart == 'missing') {
    //   globals.ikonaUla = 'red';
    //   globals.ikonaPasieki = 'red';
    // }

    print(
        'update info w bazie id = $formattedDate.$nowyNrPasieki.$nowyNrUla.$kat.$param = $wart');
    DBHelper.updateInfoWartosc(
        '$formattedDate.$nowyNrPasieki.$nowyNrUla.$kat.$param', wart);
    // Infos.insertInfo(
    //     '$formattedDate.$nowyNrPasieki.$nowyNrUla.$kat.$param', //id
    //     formattedDate, //data
    //     nowyNrPasieki!, //pasiekaNr
    //     nowyNrUla!, //ulNr
    //     kat, //karegoria
    //     param, //parametr
    //     wart, //wartosc
    //     '', //miara
    //     '', //pogoda
    //     '', //temp
    //     '--:--', //czas
    //     '', //uwagi
    //     0); //niezarchiwizowane

    //nie mozna zapisać danych jezeli nie istnieje numer pasieki lub ula poniewaz
    //dalsza część kodu się wywala - bo brak danych dla: return element.id.contains('$nowyNrPasieki.$nowyNrUla');

    //zeby nie stracić danych zebranych podczas przeglądu w widoku zbiorczym uli
    final hiveData = Provider.of<Hives>(context, listen: false);
    hive = hiveData.items.where((element) {
      //to wczytanie danych edytowanego ula
      return element.id.contains('$nowyNrPasieki.$nowyNrUla');
    }).toList();
    String ikona = hive[0].ikona; 
    int ramek = hive[0].ramek;
    int korpusNr = hive[0].korpusNr; 
    int trut = hive[0].trut;
    int czerw = hive[0].czerw;
    int larwy = hive[0].larwy;
    int jaja = hive[0].jaja;
    int pierzga = hive[0].pierzga;
    int miod = hive[0].miod;
    int dojrzaly = hive[0].dojrzaly;
    int weza = hive[0].weza;
    int susz = hive[0].susz;
    int matka = hive[0].matka;
    int mateczniki = hive[0].mateczniki;
    int usunmat = hive[0].usunmat;
    String todo = hive[0].todo;
    String matka1 = hive[0].matka1;
    String matka2 = hive[0].matka2;
    String matka3 = hive[0].matka3;
    String matka4 = hive[0].matka4;
    String matka5 = hive[0].matka5;

    print(
        'nowyNrPasieki = $nowyNrPasieki, nowyNrUla = $nowyNrUla, id hive = ${hive[0].id}, formattedDate = $formattedDate, date hive =  ${hive[0].przeglad}');
    print('nowyZasob = $nowyZasob');
    //to jezeli edytowano przegląd ula z datą taką jak ostatni przegląd ula to modyfikacja danych
    if ('$nowyNrPasieki.$nowyNrUla' == hive[0].id && formattedDate == hive[0].przeglad) {
      if (korpusNr == 0){ //było skasowanie przeglądu z aktualnie ustawioną datą więc dodawanie nowego przeglądu
        ikona = 'green'; //"zerowanie" ikony bo nowy przegląd
        korpusNr = nowyNrKorpusu!;
        zrobic = 'dodaj';
      }else{ // edycja przeglądu
        korpusNr = hive[0].korpusNr; //niepotrzebnie bo to wynika z warunku ifa
        zrobic = 'zmiana'; //ewentualna zmiana z "dodaj" bo dotyczy istniejącego przeglądu
      }
      print('edycja istniejącego przeglądu');
    }else if('$nowyNrPasieki.$nowyNrUla' == hive[0].id && (DateTime.parse(formattedDate)).compareTo(DateTime.parse(hive[0].przeglad)) > 0) { //dodanie aktualnego nowego przeglądu 
      korpusNr = nowyNrKorpusu!;
      zrobic = 'dodaj'; //ewentualna zmiana z "zmiana" bo dotyczy nowego przeglądu bo zmieniono datę edytowanego przeglądu 
      print('dodanie nowego przeglądu - zerowanie belki');
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
      ikona = 'green'; //"zerowanie" ikony bo nowy przegląd
    }
      switch (nowyZasob) {
        case 1:
          if (zrobic == 'zmiana') {
            trut = hive[0].trut - int.parse(tempNowaWartosc);
            trut = trut + int.parse(nowaWartosc);
          } else
            trut = trut + int.parse(nowaWartosc);
          break;
        case 2:
          if (zrobic == 'zmiana') {
            czerw = hive[0].czerw - int.parse(tempNowaWartosc);
            czerw = czerw + int.parse(nowaWartosc);
          } else
            czerw = czerw + int.parse(nowaWartosc);
          break;
        case 3:
          if (zrobic == 'zmiana') {
            larwy = hive[0].larwy - int.parse(tempNowaWartosc);
            larwy = larwy + int.parse(nowaWartosc);
          } else
            larwy = larwy + int.parse(nowaWartosc); 
          break;
        case 4:
          if (zrobic == 'zmiana') {
            jaja = hive[0].jaja - int.parse(tempNowaWartosc);
            jaja = jaja + int.parse(nowaWartosc);
          } else
            jaja = jaja + int.parse(nowaWartosc); 
          break;
        case 5:
          if (zrobic == 'zmiana') {
            pierzga = hive[0].pierzga - int.parse(tempNowaWartosc);
            pierzga = pierzga + int.parse(nowaWartosc);
          } else
            pierzga = pierzga + int.parse(nowaWartosc); 
          break;
        case 6:
          if (zrobic == 'zmiana') {
            miod = hive[0].miod - int.parse(tempNowaWartosc);
            miod = miod + int.parse(nowaWartosc);
          } else
            miod = miod + int.parse(nowaWartosc); 
          break;
        case 7:
          if (zrobic == 'zmiana') {
            dojrzaly = hive[0].dojrzaly - int.parse(tempNowaWartosc);
            dojrzaly = dojrzaly + int.parse(nowaWartosc);
          } else
            dojrzaly = dojrzaly + int.parse(nowaWartosc); 
          break;
        case 8:
          if (zrobic == 'zmiana') {
            weza = hive[0].weza - int.parse(tempNowaWartosc);
            weza = weza + int.parse(nowaWartosc);
          } else
            weza = weza + int.parse(nowaWartosc); 
          break;
        case 9:
          if (zrobic == 'zmiana') {
            susz = hive[0].susz - int.parse(tempNowaWartosc);
            susz = susz + int.parse(nowaWartosc);
          } else
            susz = susz + int.parse(nowaWartosc); 
          break;
        case 10:
            matka = int.parse(nowaWartosc); 
          break;
        case 11:
          if (zrobic == 'zmiana') {
            mateczniki = hive[0].mateczniki - int.parse(tempNowaWartosc);
            mateczniki = mateczniki + int.parse(nowaWartosc);
          } else
            mateczniki = mateczniki + int.parse(nowaWartosc); 
          break;
        case 12:
          if (zrobic == 'zmiana') {
            usunmat = hive[0].usunmat - int.parse(tempNowaWartosc);
            usunmat = usunmat + int.parse(nowaWartosc);
          } else
            usunmat = usunmat + int.parse(nowaWartosc); 
          break;
        case 13:
          todo = nowaWartosc;
          break;
      }
    print('-------------------------ikona1  = $ikona');
    print('$todo != '' && ($ikona != red || $ikona != orange)');
      
      // ikona ula zółta jezeli zasobem była czynność do zrobienia
      //o ile nie była czerwona lub pomarańczowa, bo problemy z matką są wazniejsze
      if ((todo != '' && todo != '0') && (ikona != 'red' || ikona != 'orange')) {
        ikona = 'yellow';
      }else if ((todo == '' || todo == '0') && (ikona =='yellow'))ikona ='green';
      
      
      // if ((todo != ''  && todo != '0') && (globals.ikonaPasieki != 'red' || globals.ikonaPasieki != 'orange')) {
      //   globals.ikonaPasieki = 'yellow';
      // }
    print('ikona2  = $ikona');
    
    //print('korpus`nr = $korpusNr');
    // print('trut = $trut, czerw = $czerw');
    // print('insertHive');
    Hives.insertHive(
      '$nowyNrPasieki.$nowyNrUla',
      nowyNrPasieki!, //pasieka nr
      nowyNrUla!, //ul nr
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
      '',
      matka1,
      matka2,
      matka3,
      matka4,
      matka5,
    ).then((_) {
      //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
      Provider.of<Hives>(context, listen: false).fetchAndSetHives(nowyNrPasieki)
      .then((_) {
        final hivesData = Provider.of<Hives>(context, listen: false);
        final hives = hivesData.items;
        int ileUli = hives.length;
        //print('edit_screen - ilość uli =');
        // print(hives.length);
        // print(ileUli);

        //DBHelper.updateIleUli(nrXXOfApiary, ileUli); //
        print('insertApiary');
        //zapis do tabeli "pasieki"
        Apiarys.insertApiary(
          '$nowyNrPasieki',
          nowyNrPasieki!, //pasieka nr
          ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
          formattedDate, //przeglad
          globals.ikonaPasieki, //ikona
          '??', //opis
        ).then((_) {
          Provider.of<Apiarys>(context, listen: false)
              .fetchAndSetApiarys()
              .then((_) {
            // print(
            //     'edit_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy');
          });
        });
      });
    });

    Infos.insertInfo(
      '$formattedDate.$nowyNrPasieki.$nowyNrUla.inspection.${AppLocalizations.of(context)!.inspection}', //id
      formattedDate, //data
      nowyNrPasieki!, //pasiekaNr
      nowyNrUla!, //ulNr
      'inspection', //karegoria
      AppLocalizations.of(context)!.inspection, //parametr
      ikona, //wartosc
      '', //miara
      '',//icon, //ikona pogody
      '', //'${temp.toStringAsFixed(0)}$stopnie', //temperatura zaokrąglona do 1 stopnia
      formatterHm.format(DateTime.now()), //formatedTime, //czas
      '', //uwagi
      0
    ).then((_) {
      Provider.of<Infos>(context, listen: false)
          .fetchAndSetInfosForHive(nowyNrPasieki,nowyNrUla)
          .then((_) {
        // print(
        //     'edit_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy');
      });
    });

    //print('edit_screen: zapis Frame do bazy');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(
            tytulEkranu,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
        ),
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Form(
                        key: _formKey1,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
//data

                              Row(
                                children: [
                                  SizedBox(width: 20),
                                  SizedBox(
                                    width: 280,
                                    child: TextField(
                                        controller:
                                            dateController, //editing controller of this TextField
                                        decoration: InputDecoration(
                                            icon: Icon(Icons
                                                .calendar_today), //icon of text field
                                            labelText:
                                                AppLocalizations.of(context)!
                                                    .noteDate),
                                        readOnly:
                                            true, // when true user cannot edit text
                                        onTap: () async {
                                          DateTime? pickedDate =
                                              await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.parse(
                                                      dateController.text),
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime(2101));
                                          if (pickedDate != null) {
                                            String formattedDate =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(pickedDate);

                                            setState(() {
                                              dateController.text =
                                                  formattedDate;
                                            });
                                          } else {
                                            print("Date is not selected");
                                          }
                                        }),
                                  ),
                                ],
                              ),

// pasieka - ul - korpus
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                //mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                        readOnly: true,
                                        initialValue: nowyNrPasieki.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          labelText:
                                              (AppLocalizations.of(context)!
                                                  .apiary),
                                          labelStyle:
                                              TextStyle(color: Colors.black),
                                          hintText:
                                              (AppLocalizations.of(context)!
                                                  .number),
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(
                                                    context)!
                                                .apiaryNr);
                                          }
                                          nowyNrPasieki = int.parse(value);
                                          return null;
                                        }),
                                  ),
                                  SizedBox(width: 15),
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                        readOnly: true,
                                        initialValue: nowyNrUla.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          labelText:
                                              (AppLocalizations.of(context)!
                                                  .hive),
                                          labelStyle:
                                              TextStyle(color: Colors.black),
                                          hintText:
                                              (AppLocalizations.of(context)!
                                                  .number),
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(
                                                    context)!
                                                .hiveNr);
                                          }
                                          nowyNrUla = int.parse(value);
                                          return null;
                                        }),
                                  ),
                                  SizedBox(width: 15),
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                        initialValue: nowyNrKorpusu.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          labelText:
                                              (AppLocalizations.of(context)!
                                                  .body),
                                          labelStyle:
                                              TextStyle(color: Colors.black),
                                          hintText:
                                              (AppLocalizations.of(context)!
                                                  .number),
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(
                                                    context)!
                                                .bodyNr);
                                          }
                                          nowyNrKorpusu = int.parse(value);
                                          return null;
                                        }),
                                  ),
                                  SizedBox(width: 15),
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                        initialValue: nowyNrRamki.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          labelText:
                                              (AppLocalizations.of(context)!
                                                  .frame),
                                          labelStyle:
                                              TextStyle(color: Colors.black),
                                          hintText:
                                              (AppLocalizations.of(context)!
                                                  .number),
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(
                                                    context)!
                                                .frameNr);
                                          }
                                          nowyNrRamki = int.parse(value);
                                          return null;
                                        }),
                                  ),
                                ],
                              ),

                              //korpus / półkorpus

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
//półkorpus
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              korpus = 1;
                                            });
                                          },
                                          icon: Radio(
                                              value: 1,
                                              groupValue: korpus,
                                              onChanged: (value) {
                                                setState(() {
                                                  korpus = value!;
                                                });
                                              }),
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .halfBody)),
                                      //mała ramka
                                      TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              rozmiarRamki = 1;
                                            });
                                          },
                                          icon: Radio(
                                              value: 1,
                                              groupValue: rozmiarRamki,
                                              onChanged: (value) {
                                                setState(() {
                                                  rozmiarRamki = value!;
                                                });
                                              }),
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                      .small +
                                                  ' ' +
                                                  AppLocalizations.of(context)!
                                                      .frame)),
                                      //lewa
                                      TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              stronaRamki = 1;
                                            });
                                          },
                                          icon: Radio(
                                              value: 1,
                                              groupValue: stronaRamki,
                                              onChanged: (value) {
                                                setState(() {
                                                  stronaRamki = value!;
                                                });
                                              }),
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                      .left +
                                                  ' ' +
                                                  AppLocalizations.of(context)!
                                                      .site)),
                                    ],
                                  ),

//korpus
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              korpus = 2;
                                            });
                                          },
                                          icon: Radio(
                                              value: 2,
                                              groupValue: korpus,
                                              onChanged: (value) {
                                                setState(() {
                                                  korpus = value!;
                                                });
                                              }),
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .body)),
//duza ramka
                                      TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              rozmiarRamki = 2;
                                            });
                                          },
                                          icon: Radio(
                                              value: 2,
                                              groupValue: rozmiarRamki,
                                              onChanged: (value) {
                                                setState(() {
                                                  rozmiarRamki = value!;
                                                });
                                              }),
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                      .big +
                                                  ' ' +
                                                  AppLocalizations.of(context)!
                                                      .frame)),
                                      //prawa
                                      TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              stronaRamki = 2;
                                            });
                                          },
                                          icon: Radio(
                                              value: 2,
                                              groupValue: stronaRamki,
                                              onChanged: (value) {
                                                setState(() {
                                                  stronaRamki = value!;
                                                });
                                              }),
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                      .right +
                                                  ' ' +
                                                  AppLocalizations.of(context)!
                                                      .site)),
                                    ],
                                  ),
                                ],
                              ),
                              

//zasób 1-12
                              if (nowyZasob! < 13)
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      DropdownButton(
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.black54,
                                        ),
                                        value:
                                            nowyZasob, //ramka[0].zasob, //ustawiona, widoczna wartość
                                        items: [
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .drone),
                                              value: 1),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .broodCovered),
                                              value: 2),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .larvae),
                                              value: 3),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .eggs),
                                              value: 4),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .pollen),
                                              value: 5),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .honey),
                                              value: 6),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .honeySealed),
                                              value: 7),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .waxFundation),
                                              value: 8),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .waxComb),
                                              value: 9),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .queen),
                                              value: 10),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .queenCells),
                                              value: 11),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .deleteQueenCells),
                                              value: 12),
                                          // DropdownMenuItem(
                                          //     child: Text(
                                          //         AppLocalizations.of(context)!
                                          //             .toDo),
                                          //     value: 13),
                                          // DropdownMenuItem(
                                          //     child: Text(
                                          //         AppLocalizations.of(context)!
                                          //             .isDone),
                                          //     value: 14),
                                        ], //lista elementów do wyboru
                                        onChanged: (newValue) {
                                          //wybrana nowa wartość - nazwa dodatku
                                          setState(() {
                                            nowyZasob =
                                                newValue!; // ustawienie nowej wybranej nazwy dodatku
                                            // print('nowy zasób = $nowyZasob');
                                          });
                                        }, //onChangeDropdownItemWar1,
                                      ),

//ilość

                                      SizedBox(
                                        width: 10,
                                      ),

                                      //if (nowyZasob < 13)
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                            initialValue: nowaWartosc,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            decoration: InputDecoration(
                                              labelText:
                                                  (AppLocalizations.of(context)!
                                                      .quantity),
                                              labelStyle: TextStyle(
                                                  color: Colors.black),
                                              hintText: (AppLocalizations.of(
                                                          context)!
                                                      .enter +
                                                  ' ' +
                                                  AppLocalizations.of(context)!
                                                      .quantity),
                                            ),
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return (AppLocalizations.of(
                                                            context)!
                                                        .enter +
                                                    ' ' +
                                                    AppLocalizations.of(
                                                            context)!
                                                        .quantity);
                                              }
                                              //print('nowaWartosc = $nowaWartosc');
                                              nowaWartosc = value;
                                              return null;
                                            }),
                                      ),
                                      //znak %
                                      if (nowyZasob! < 10)
                                        SizedBox(
                                          width: 30,
                                          child: Text(
                                            '%',
                                            style: TextStyle(
                                              //fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                            softWrap: true, //zawijanie tekstu
                                            overflow: TextOverflow.fade,
                                          ),
                                        ),
                                      if (nowyZasob! > 9 && nowyZasob! < 13)
                                        SizedBox(
                                          width: 30,
                                          child: Text(
                                            AppLocalizations.of(context)!.pcs,
                                            style: TextStyle(
                                              //fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                            softWrap: true, //zawijanie tekstu
                                            overflow: TextOverflow.fade,
                                          ),
                                        ),
                                    ]),
//toDo
                              if (nowyZasob == 13)
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      DropdownButton(
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.black54,
                                        ),
                                        value:
                                            nowaWartosc, //ramka[0].zasob, //ustawiona, widoczna wartość
                                        items: [
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .workFrame),
                                              value:
                                                  AppLocalizations.of(context)!
                                                      .workFrame),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .toExtraction),
                                              value:
                                                  AppLocalizations.of(context)!
                                                      .toExtraction),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .toDelete),
                                              value:
                                                  AppLocalizations.of(context)!
                                                      .toDelete),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .toInsulate),
                                              value:
                                                  AppLocalizations.of(context)!
                                                      .toInsulate),
                                        ], //lista elementów do wyboru
                                        onChanged: (newValue) {
                                          setState(() {
                                            nowaWartosc = newValue
                                                .toString(); // ustawienie nowej wwrtośi
                                            //print('nowy zasób = $nowyZasob');
                                          });
                                        }, //onChangeDropdownItemWar1,
                                      ),
                                    ]),
//isDone
                              if (nowyZasob == 14)
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      DropdownButton(
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.black54,
                                        ),
                                        value:
                                            nowaWartosc, //ramka[0].zasob, //ustawiona, widoczna wartość
                                        items: [
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .deleted),
                                              value:
                                                  AppLocalizations.of(context)!
                                                      .deleted),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .inserted),
                                              value:
                                                  AppLocalizations.of(context)!
                                                      .inserted),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .insulated),
                                              value:
                                                  AppLocalizations.of(context)!
                                                      .insulated),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .movedLeft),
                                              value:
                                                  AppLocalizations.of(context)!
                                                      .movedLeft),
                                          DropdownMenuItem(
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .movedRight),
                                              value:
                                                  AppLocalizations.of(context)!
                                                      .movedRight),
                                        ], //lista elementów do wyboru
                                        onChanged: (newValue) {
                                          setState(() {
                                            nowaWartosc = newValue
                                                .toString(); // ustawienie nowej wwrtośi
                                            //print('nowy zasób = $nowyZasob');
                                          });
                                        }, //onChangeDropdownItemWar1,
                                      ),
                                    ]),
                            ]),
                      ),
                      SizedBox(
                        height: 30,
                      ),

//przyciski
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
//zmień
                          if(tryb == 'edycja')
                            MaterialButton(
                              shape: const StadiumBorder(),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                  DBHelper.deleteFrame(ramka[0].id).then((_) {
                                    // //poniewaz usunięcie wartości to trzeba usunąć ją tez z belki
                                    // final hiveData = Provider.of<Hives>(context,
                                    //     listen: false);
                                    // hive = hiveData.items.where((element) {
                                    //   return element.id.contains(
                                    //       '$nowyNrPasieki.$nowyNrUla');
                                    // }).toList();
                                    // int korpusNr = hive[0].korpusNr;
                                    // int trut = hive[0].trut;
                                    // int czerw = hive[0].czerw;
                                    // int larwy = hive[0].larwy;
                                    // int jaja = hive[0].jaja;
                                    // int pierzga = hive[0].pierzga;
                                    // int miod = hive[0].miod;
                                    // int dojrzaly = hive[0].dojrzaly;
                                    // int weza = hive[0].weza;
                                    // int susz = hive[0].susz;
                                    // int matka = hive[0].matka;
                                    // int mateczniki = hive[0].mateczniki;
                                    // int usunmat = hive[0].usunmat;
                                    // String todo = hive[0].todo;

                                    // // jezeli usuwano wartosc z przeglądu ula z datą taką jak ostatni przegląd ula to modyfikacja danych
                                    // if (nowyRok +
                                    //             '-' +
                                    //             nowyMiesiac +
                                    //             '-' +
                                    //             nowyDzien ==
                                    //         hive[0].przeglad &&
                                    //     nowyNrKorpusu == hive[0].korpusNr) {
                                    //   switch (nowyZasob) {
                                    //     case 1:
                                    //       trut = trut - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 2:
                                    //       czerw = czerw - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 3:
                                    //       larwy = larwy - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 4:
                                    //       jaja = jaja - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 5:
                                    //       pierzga = pierzga - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 6:
                                    //       miod = miod - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 7:
                                    //       dojrzaly = dojrzaly - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 8:
                                    //       weza = weza - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 9:
                                    //       susz = susz - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 10:
                                    //       matka = matka - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 11:
                                    //       mateczniki = mateczniki - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 12:
                                    //       usunmat = usunmat - int.parse(tempNowaWartosc);
                                    //       break;
                                    //     case 13:
                                    //       todo = '0';
                                    //       break;
                                    //   }
                                    // }

                                    // Hives.insertHive(
                                    //   '$nowyNrPasieki.$nowyNrUla}',
                                    //   hive[0].pasiekaNr, //pasieka nr
                                    //   hive[0].ulNr, //ul nr
                                    //   hive[0].przeglad, //przeglad
                                    //   hive[0].ikona, //ikona
                                    //   hive[0].ramek, //opis - ilość ramek w korpusie
                                    //   korpusNr,
                                    //   trut,
                                    //   czerw,
                                    //   larwy,
                                    //   jaja,
                                    //   pierzga,
                                    //   miod,
                                    //   dojrzaly,
                                    //   weza,
                                    //   susz,
                                    //   matka,
                                    //   mateczniki,
                                    //   usunmat,
                                    //   todo,
                                    //   '0',
                                    //   '0',
                                    //   '0',
                                    //   '0',
                                    // ).then((_) {
                                    //   //pobranie do Hives_items z tabeli ule
                                    //   Provider.of<Hives>(context, listen: false)
                                    //       .fetchAndSetHives(
                                    //     hive[0].pasiekaNr,
                                    //   );
                                    //   //zerowanie wartosci początkowej
                                    //   tempNowaWartosc = '0';
                                    zapisDoBazy(
                                        nowyZasob!, nowaWartosc, 'zmiana');
                                    Provider.of<Frames>(context, listen: false)
                                        .fetchAndSetFramesForHive(
                                            globals.pasiekaID, globals.ulID)
                                        .then((_) {
                                      Navigator.of(context).pop();
                                    });
                                    // });
                                  });
                                }
                                ;
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!.replace) +
                                  '   '), //Modyfikuj
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.white,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),

//zapisz
                            MaterialButton(
                              shape: const StadiumBorder(),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                  zapisDoBazy(nowyZasob!, nowaWartosc, 'dodaj');
                                  Provider.of<Frames>(context, listen: false)
                                      .fetchAndSetFramesForHive(
                                          globals.pasiekaID, globals.ulID)
                                      .then((_) {
                                    Navigator.of(context).pop();
                                  });
                                }
                                ;
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!.saveZ) +
                                  '   '), //Zapisz
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.white,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),
                          ]),
                    ]))));
  }
}
