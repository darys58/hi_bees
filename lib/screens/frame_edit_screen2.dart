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

class FrameEditScreen2 extends StatefulWidget {
  static const routeName = '/frame_edit2';

  @override
  State<FrameEditScreen2> createState() => _FrameEditScreen2State();
}

class _FrameEditScreen2State extends State<FrameEditScreen2> {
  final _formKey1 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');
  var formatterHm = new DateFormat('H:mm');
  int? nowyNrPasieki;
  int? nowyNrUla;
  int? nowyNrKorpusu;
  int? nowyNrRamki;//przed  przeglądem
  int? nowyNrRamkiPo; //po przeglądzie
  int rozmiarRamki = 2;//1-mała, 2-duza
  int stronaRamki = 0; //0-obie, 1-lewa, 2-prawa
  //bool lewa = false;
  //bool prawa = false;
  int korpus = 2;//1-półkorpus, 2-korpus
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
  TextEditingController dateController = TextEditingController();
  bool isChecked = false; //czy zakres ramek
  bool zakresRamek = false; //"false" - ramki przed i po przeglądzie; "true" - zakres ramek od do
  int nrRamkiOd = 0;
  int nrRamkiDo = 0;

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

  @override
  void didChangeDependencies() {
    final routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    final idRamki = routeArgs['idRamki']; //pobiera z frames_detail_item.dart
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
      nowyNrRamkiPo = ramka[0].ramkaNrPo;
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
      dateController.text = globals.dataWpisu; //DateTime.now().toString().substring(0, 10);
      // nowyRok = DateFormat('yyyy').format(DateTime.now());
      // nowyMiesiac = DateFormat('MM').format(DateTime.now());
      // nowyDzien = DateFormat('dd').format(DateTime.now());
      nowyNrPasieki = int.parse('$idPasieki');
      nowyNrUla = int.parse('$idUla');
      nowyNrKorpusu = globals.nowyNrKorpusu; //zapamiętany ostatni wybór
      nowyNrRamki = globals.nowyNrRamki;
      nowyNrRamkiPo = globals.nowyNrRamkiPo;
      korpus = globals.korpus;
      rozmiarRamki = globals.rozmiarRamki;
      stronaRamki = globals.stronaRamki;
      nowyZasob = int.parse('$idZasobu');
      //tempZasob = nowyZasob;
      nowaWartosc = '1';
      tempNowaWartosc = nowaWartosc;
      tryb = 'dodaj';
      tytulEkranu = AppLocalizations.of(context)!.addFrame;
      if (nowyZasob == 13)
        nowaWartosc = AppLocalizations.of(context)!.workFrame;
      if (nowyZasob == 14) nowaWartosc = AppLocalizations.of(context)!.deleted;
    }

    super.didChangeDependencies();
  }

  //zapis zasobu do tabeli "ramki"
  zapisDoBazy(int zas, wart, String zrobic) {
    String formattedDate = dateController.text; //nowyRok + '-' + nowyMiesiac + '-' + nowyDzien;

    if (zas < 10) wart = nowaWartosc + '%'; //????????
 
    //======= Zapis zasobu do tabeli  "ramka" ========
    //jezeli zakres ramek
    if(zakresRamek){
      for (var i = nrRamkiOd; i <= nrRamkiDo; i++) {
        if (stronaRamki == 1) { //dla lewej strony
            // print(
            //     'zapis do bazy id = $formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.1.$zas');
            // print('numer ramki = $i');
            // print('nowa wartość = $wart');
            // print(
            //     'dane do zapisu = $formattedDate, $nowyNrPasieki,$nowyNrUla,$nowyNrKorpusu,$korpus,$nowyNrRamki,$nowyNrRamkiPo,$rozmiarRamki,1,$zas,$wart,0');
          Frames.insertFrame(
            '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$i.$i.1.$zas',
            formattedDate,
            nowyNrPasieki!,
            nowyNrUla!,
            nowyNrKorpusu!,
            korpus,
            i,
            i,
            rozmiarRamki,
            1, //lewa
            zas,
            wart,
            0); //arch
        }else if (stronaRamki == 2) { //dla prawej strony
          Frames.insertFrame(
            '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$i.$i.2.$zas',
            formattedDate,
            nowyNrPasieki!,
            nowyNrUla!,
            nowyNrKorpusu!,
            korpus,
            i,
            i,
            rozmiarRamki,
            2, //prawa
            zas,
            wart,
            0); //arch
        }else { //dla obu stron ramki
          Frames.insertFrame(
            '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$i.$i.1.$zas',
            formattedDate,
            nowyNrPasieki!,
            nowyNrUla!,
            nowyNrKorpusu!,
            korpus,
            i,
            i,
            rozmiarRamki,
            1, //lewa
            zas,
            wart,
            0);
          Frames.insertFrame(
            '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$i.$i.2.$zas',
            formattedDate,
            nowyNrPasieki!,
            nowyNrUla!,
            nowyNrKorpusu!,
            korpus,
            i,
            i,
            rozmiarRamki,
            2, //lewa
            zas,
            wart,
            0);
        }
      }
      //jezeli jedna ramka
    }else{
      if (stronaRamki == 1) { //dla lewej strony
          // print(
          //     'zapis do bazy id = $formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.1.$zas');
          // print('nowa wartość = $wart');
          // print(
          //     'dane do zapisu = $formattedDate, $nowyNrPasieki,$nowyNrUla,$nowyNrKorpusu,$korpus,$nowyNrRamki,$nowyNrRamkiPo,$rozmiarRamki,1,$zas,$wart,0');
        Frames.insertFrame(
          '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.1.$zas',
          formattedDate,
          nowyNrPasieki!,
          nowyNrUla!,
          nowyNrKorpusu!,
          korpus,
          nowyNrRamki!,
          nowyNrRamkiPo!,
          rozmiarRamki,
          1, //lewa
          zas,
          wart,
          0); //arch
      } else if (stronaRamki == 2) { //dla prawej strony
        Frames.insertFrame(
          '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.2.$zas',
          formattedDate,
          nowyNrPasieki!,
          nowyNrUla!,
          nowyNrKorpusu!,
          korpus,
          nowyNrRamki!,
          nowyNrRamkiPo!,
          rozmiarRamki,
          2, //prawa
          zas,
          wart,
          0); //arch
      } else { //dla obu stron ramki
        Frames.insertFrame(
          '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.1.$zas',
          formattedDate,
          nowyNrPasieki!,
          nowyNrUla!,
          nowyNrKorpusu!,
          korpus,
          nowyNrRamki!,
          nowyNrRamkiPo!,
          rozmiarRamki,
          1, //lewa
          zas,
          wart,
          0);
        Frames.insertFrame(
          '$formattedDate.$nowyNrPasieki.$nowyNrUla.$nowyNrKorpusu.$nowyNrRamki.$nowyNrRamkiPo.2.$zas',
          formattedDate,
          nowyNrPasieki!,
          nowyNrUla!,
          nowyNrKorpusu!,
          korpus,
          nowyNrRamki!,
          nowyNrRamkiPo!,
          rozmiarRamki,
          2, //lewa
          zas,
          wart,
          0);
      }

    }
    
    //========= Modyfikacja belki =========
    //zeby nie stracić danych zebranych podczas przeglądu w widoku zbiorczym uli (belka)
    final hiveData = Provider.of<Hives>(context, listen: false);
    hive = hiveData.items.where((element) {
      //to wczytanie danych edytowanego ula
      return element.id.contains('$nowyNrPasieki.$nowyNrUla');
    }).toList();
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

    print('nowyNrPasieki = $nowyNrPasieki, nowyNrUla = $nowyNrUla, id wpisu w "ule" = ${hive[0].id}, data wybranego przeglądu = $formattedDate, data ostatniego przeglądu =  ${hive[0].przeglad}');
    print('nowyZasob = $nowyZasob, korpusNr = $korpusNr, nowyNrKorpusu = $nowyNrKorpusu');
    
    //===== Jezeli data dodawanego lub modyfikowanego przegladu jest nowsza lub taka sama jak data ostatniego przegladu
    //===== to modyfikacja belki bo jest zmiana zasobu
    if((DateTime.parse(formattedDate)).compareTo(DateTime.parse(hive[0].przeglad)) >= 0){
      
      if (formattedDate == hive[0].przeglad) {//data wprowadzanych zmian i data belki takie same to edycja/modyfikacja
        print('edycja istniejącego przeglądu bo takie same daty');
        //więc nic nie rób chyba ze
        //było skasowanie przeglądu z aktualnie ustawioną datą lub zmieniono numer korpusu więc dodawanie nowego przeglądu
        if (korpusNr == 0 || korpusNr != nowyNrKorpusu){ 
          print('miała być edycja istniejącego przeglądu ale jednak jest nowy przegląd bo inny numer korpusa !!!!!!!');
          korpusNr = nowyNrKorpusu!;
          ikona = 'green'; //"zerowanie" zasobów bo nowy przegląd
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
      }else if((DateTime.parse(formattedDate)).compareTo(DateTime.parse(hive[0].przeglad)) > 0) { //dodanie aktualnego nowego przeglądu bo data nowsza niz ta z przeglądu ($nowyNrPasieki.$nowyNrUla' == hive[0].id && )
        print('dodanie nowego przeglądu - zerowanie belki');
        korpusNr = nowyNrKorpusu!;
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
      
      
      // print('-------------------------ikona przed  = $ikona');
      //print('$todo != '' && ($ikona != red || $ikona != orange)'); 
      // ikona ula zółta jezeli zasobem była czynność do zrobienia
      //o ile nie była czerwona lub pomarańczowa, bo problemy z matką są wazniejsze
      if ((todo != '' && todo != '0') && (ikona != 'red' || ikona != 'orange')) {
        ikona = 'yellow';
      }else if ((todo == '' || todo == '0') && (ikona =='yellow'))ikona ='green';   
    // print('ikona po  = $ikona');
      
      
      
      //aktualizacja zasobów ula na belce po jego modyfikacji na ramce lub ramkach
      Provider.of<Frames>(context, listen: false)
        .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
        .then((_) { //pobranie wszystkich ramek/zasobów z wybranego ula
        //pobranie wszyskich wpisów z tabeli "ramki" dla danego ula
        final framesUla = Provider.of<Frames>(context, listen: false);
        //dotyczących aktualnie zmodyfikowanego zasobu w ulu (i dla wybranej daty oraz tylko dla ramek Po i wybranego korpusu)
        List<Frame> framesZas = framesUla.items.where((fr) {
            return fr.zasob == zas && fr.data == dateController.text && fr.ramkaNrPo != 0 && fr.korpusNr == nowyNrKorpusu; 
          }).toList();
          //dla kazdego zapisu dotyczącego tego zasobu na ramkaNrPo - sumowanie wszystkich wartości zasobów
          
          print('******** framesZas.length ${framesZas.length}');
          print('zas $zas,korpusNr $korpusNr, nowyNrKorpusu $nowyNrKorpusu,globals.dataWpisu ${globals.dataWpisu}, ');
          
          print('fr.zasob == {framesZas[0].zasob }&& fr.data == {framesZas[0].data} && data wpisu = ${globals.dataWpisu}');
          
          //print('przed for ======= ramka ${framesZas[0].ramkaNrPo}, zas ${framesZas[0].zasob} == ${framesZas[0].wartosc}');
          
          for (var i = 0; i < framesZas.length; i++) {
            print('$i ======= ramka ${framesZas[i].ramkaNrPo}, zas ${framesZas[i].zasob} == ${framesZas[i].wartosc}');
            switch (zas) {//id zasobu
              case 1:           
                if(i == 0) trut = 0; //zerowanie zasobu bo będzie aktualizowany
                trut = trut + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); //dodanie z uprzednim usunięciem znaku %
                break;
              case 2:
                if(i == 0) czerw = 0; //zerowanie zasobu bo będzie aktualizowany
                czerw = czerw + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), ''));
                print('wartość czerwiu $czerw');
                break;
              case 3:
                if(i == 0) larwy = 0; //zerowanie zasobu bo będzie aktualizowany
                larwy = larwy + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 4:
                if(i == 0) jaja = 0; //zerowanie zasobu bo będzie aktualizowany
                jaja = jaja + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 5:
                if(i == 0) pierzga = 0; //zerowanie zasobu bo będzie aktualizowany
                pierzga = pierzga + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 6:
                if(i == 0) miod = 0; //zerowanie zasobu bo będzie aktualizowany
                miod = miod + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 7:
                if(i == 0) dojrzaly = 0; //zerowanie zasobu bo będzie aktualizowany
                dojrzaly = dojrzaly + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 8:
                if(i == 0) weza = 0; //zerowanie zasobu bo będzie aktualizowany
                weza = weza + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 9:
                if(i == 0) susz = 0; //zerowanie zasobu bo będzie aktualizowany
                susz = susz + int.parse(framesZas[i].wartosc.replaceAll(RegExp('%'), '')); 
                break;
              case 10:
                  matka = int.parse(nowaWartosc); 
                break;
              case 11:
                if(i == 0) mateczniki = 0; //zerowanie zasobu bo będzie aktualizowany
                mateczniki = mateczniki + int.parse(nowaWartosc); 
                break;
              case 12:
                if(i == 0) usunmat = 0; //zerowanie zasobu bo będzie aktualizowany
                usunmat = usunmat + int.parse(nowaWartosc); 
                break;
              case 13:
                todo = nowaWartosc;
                break;
            }
          } //for
          print('po for==================== korpusNr = $korpusNr');
      
      
        // });
        print('po aktualizacji zasobów czerw ==================== $czerw');
        print('wartość czerwiu przed zapisem do hive = $czerw');
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
          '0', //zerowanie parametrów info bo zapis zasobów do belki
          '0',
          '0',
          '0',
          matka1,
          matka2,
          matka3,
          matka4,
          matka5,
          '0', //zapas h1
          '0', //h2
          '0', //h3
          0, //aktualne zasoby
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
          0 //arch
        ).then((_) {
          Provider.of<Infos>(context, listen: false)
              .fetchAndSetInfosForHive(nowyNrPasieki,nowyNrUla)
              .then((_) {
            // print(
            //     'edit_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy');
          });
        });
      }); //od pobrania ramek z zasobami do aktualizacji 
    }   

    // //edycja = grey - znaczy ze była edycja przeglądu
    // zapisInfoDoBazy('inspection', AppLocalizations.of(context)!.inspection,
    //     AppLocalizations.of(context)!.edited, zrobic);
  }

  //zapisanie informacji o przegladzie - aktualizacja po kazdym zapisaniu zasobu ramki do bazy
  // zapisInfoDoBazy(String kat, String param, String wart, String zrobic) {
  //   String formattedDate = dateController.text; //nowyRok + '-' + nowyMiesiac + '-' + nowyDzien;

  //   //print('update info w bazie id = $formattedDate.$nowyNrPasieki.$nowyNrUla.$kat.$param = $wart');
  //   DBHelper.updateInfoWartosc('$formattedDate.$nowyNrPasieki.$nowyNrUla.$kat.$param', wart);

    // //zeby nie stracić danych zebranych podczas przeglądu w widoku zbiorczym uli
    // final hiveData = Provider.of<Hives>(context, listen: false);
    // hive = hiveData.items.where((element) {
    //   //to wczytanie danych edytowanego ula
    //   return element.id.contains('$nowyNrPasieki.$nowyNrUla');
    // }).toList();
    // ikona = hive[0].ikona; 
    // ramek = hive[0].ramek;
    // korpusNr = hive[0].korpusNr; 
    // trut = hive[0].trut;
    // czerw = hive[0].czerw;
    // larwy = hive[0].larwy;
    // jaja = hive[0].jaja;
    // pierzga = hive[0].pierzga;
    // miod = hive[0].miod;
    // dojrzaly = hive[0].dojrzaly;
    // weza = hive[0].weza;
    // susz = hive[0].susz;
    // matka = hive[0].matka;
    // mateczniki = hive[0].mateczniki;
    // usunmat = hive[0].usunmat;
    // todo = hive[0].todo;
    // matka1 = hive[0].matka1;
    // matka2 = hive[0].matka2;
    // matka3 = hive[0].matka3;
    // matka4 = hive[0].matka4;
    // matka5 = hive[0].matka5;

    // print(
    //     'nowyNrPasieki = $nowyNrPasieki, nowyNrUla = $nowyNrUla, id hive = ${hive[0].id}, formattedDate = $formattedDate, date hive =  ${hive[0].przeglad}');
    // print('nowyZasob = $nowyZasob');
    // //to jezeli edytowano przegląd ula z datą taką jak ostatni przegląd ula to modyfikacja danych
    // if ('$nowyNrPasieki.$nowyNrUla' == hive[0].id && formattedDate == hive[0].przeglad) {
    //   if (korpusNr == 0){ //było skasowanie przeglądu z aktualnie ustawioną datą więc dodawanie nowego przeglądu
    //     ikona = 'green'; //"zerowanie" ikony bo nowy przegląd
    //     korpusNr = nowyNrKorpusu!;
    //     zrobic = 'dodaj';
    //   }else{ // edycja przeglądu
    //     korpusNr = hive[0].korpusNr; //niepotrzebnie bo to wynika z warunku ifa
    //     zrobic = 'zmiana'; //ewentualna zmiana z "dodaj" bo dotyczy istniejącego przeglądu
    //   }
    //   print('edycja istniejącego przeglądu');
    // }else if('$nowyNrPasieki.$nowyNrUla' == hive[0].id && (DateTime.parse(formattedDate)).compareTo(DateTime.parse(hive[0].przeglad)) > 0) { //dodanie aktualnego nowego przeglądu 
    //   korpusNr = nowyNrKorpusu!;
    //   zrobic = 'dodaj'; //ewentualna zmiana z "zmiana" bo dotyczy nowego przeglądu bo zmieniono datę edytowanego przeglądu 
    //   print('dodanie nowego przeglądu - zerowanie belki');
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
    //   todo = '';
    //   ikona = 'green'; //"zerowanie" ikony bo nowy przegląd
    // }
      // switch (nowyZasob) {
      //   case 1:
      //     if (zrobic == 'zmiana') {
      //       trut = hive[0].trut - int.parse(tempNowaWartosc);
      //       trut = trut + int.parse(nowaWartosc);
      //     } else
      //       trut = trut + int.parse(nowaWartosc);
      //     break;
      //   case 2:
      //     if (zrobic == 'zmiana') {
      //       czerw = hive[0].czerw - int.parse(tempNowaWartosc);
      //       czerw = czerw + int.parse(nowaWartosc);
      //     } else
      //       czerw = czerw + int.parse(nowaWartosc);
      //     break;
      //   case 3:
      //     if (zrobic == 'zmiana') {
      //       larwy = hive[0].larwy - int.parse(tempNowaWartosc);
      //       larwy = larwy + int.parse(nowaWartosc);
      //     } else
      //       larwy = larwy + int.parse(nowaWartosc); 
      //     break;
      //   case 4:
      //     if (zrobic == 'zmiana') {
      //       jaja = hive[0].jaja - int.parse(tempNowaWartosc);
      //       jaja = jaja + int.parse(nowaWartosc);
      //     } else
      //       jaja = jaja + int.parse(nowaWartosc); 
      //     break;
      //   case 5:
      //     if (zrobic == 'zmiana') {
      //       pierzga = hive[0].pierzga - int.parse(tempNowaWartosc);
      //       pierzga = pierzga + int.parse(nowaWartosc);
      //     } else
      //       pierzga = pierzga + int.parse(nowaWartosc); 
      //     break;
      //   case 6:
      //     if (zrobic == 'zmiana') {
      //       miod = hive[0].miod - int.parse(tempNowaWartosc);
      //       miod = miod + int.parse(nowaWartosc);
      //     } else
      //       miod = miod + int.parse(nowaWartosc); 
      //     break;
      //   case 7:
      //     if (zrobic == 'zmiana') {
      //       dojrzaly = hive[0].dojrzaly - int.parse(tempNowaWartosc);
      //       dojrzaly = dojrzaly + int.parse(nowaWartosc);
      //     } else
      //       dojrzaly = dojrzaly + int.parse(nowaWartosc); 
      //     break;
      //   case 8:
      //     if (zrobic == 'zmiana') {
      //       weza = hive[0].weza - int.parse(tempNowaWartosc);
      //       weza = weza + int.parse(nowaWartosc);
      //     } else
      //       weza = weza + int.parse(nowaWartosc); 
      //     break;
      //   case 9:
      //     if (zrobic == 'zmiana') {
      //       susz = hive[0].susz - int.parse(tempNowaWartosc);
      //       susz = susz + int.parse(nowaWartosc);
      //     } else
      //       susz = susz + int.parse(nowaWartosc); 
      //     break;
      //   case 10:
      //       matka = int.parse(nowaWartosc); 
      //     break;
      //   case 11:
      //     if (zrobic == 'zmiana') {
      //       mateczniki = hive[0].mateczniki - int.parse(tempNowaWartosc);
      //       mateczniki = mateczniki + int.parse(nowaWartosc);
      //     } else
      //       mateczniki = mateczniki + int.parse(nowaWartosc); 
      //     break;
      //   case 12:
      //     if (zrobic == 'zmiana') {
      //       usunmat = hive[0].usunmat - int.parse(tempNowaWartosc);
      //       usunmat = usunmat + int.parse(nowaWartosc);
      //     } else
      //       usunmat = usunmat + int.parse(nowaWartosc); 
      //     break;
      //   case 13:
      //     todo = nowaWartosc;
      //     break;
      // }
    // print('-------------------------ikona1  = $ikona');
    // print('$todo != '' && ($ikona != red || $ikona != orange)');
      
    //   // ikona ula zółta jezeli zasobem była czynność do zrobienia
    //   //o ile nie była czerwona lub pomarańczowa, bo problemy z matką są wazniejsze
    //   if ((todo != '' && todo != '0') && (ikona != 'red' || ikona != 'orange')) {
    //     ikona = 'yellow';
    //   }else if ((todo == '' || todo == '0') && (ikona =='yellow'))ikona ='green';
      
      
    //   // if ((todo != ''  && todo != '0') && (globals.ikonaPasieki != 'red' || globals.ikonaPasieki != 'orange')) {
    //   //   globals.ikonaPasieki = 'yellow';
    //   // }
    // print('ikona2  = $ikona');
    
    // //print('korpus`nr = $korpusNr');
    // // print('trut = $trut, czerw = $czerw');
    // // print('insertHive');
    // Hives.insertHive(
    //   '$nowyNrPasieki.$nowyNrUla',
    //   nowyNrPasieki!, //pasieka nr
    //   nowyNrUla!, //ul nr
    //   formattedDate, //przeglad
    //   ikona, //ikona
    //   ramek, //ramek - ilość ramek w korpusie
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
    //   kat,
    //   param,
    //   wart,
    //   '',
    //   matka1,
    //   matka2,
    //   matka3,
    //   matka4,
    //   matka5,
    // ).then((_) {
    //   //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
    //   Provider.of<Hives>(context, listen: false).fetchAndSetHives(nowyNrPasieki)
    //   .then((_) {
    //     final hivesData = Provider.of<Hives>(context, listen: false);
    //     final hives = hivesData.items;
    //     int ileUli = hives.length;
    //     //print('edit_screen - ilość uli =');
    //     // print(hives.length);
    //     // print(ileUli);

    //     //DBHelper.updateIleUli(nrXXOfApiary, ileUli); //
    //     print('insertApiary');
    //     //zapis do tabeli "pasieki"
    //     Apiarys.insertApiary(
    //       '$nowyNrPasieki',
    //       nowyNrPasieki!, //pasieka nr
    //       ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
    //       formattedDate, //przeglad
    //       globals.ikonaPasieki, //ikona
    //       '??', //opis
    //     ).then((_) {
    //       Provider.of<Apiarys>(context, listen: false)
    //           .fetchAndSetApiarys()
    //           .then((_) {
    //         // print(
    //         //     'edit_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy');
    //       });
    //     });
    //   });
    // });

    // Infos.insertInfo(
    //   '$formattedDate.$nowyNrPasieki.$nowyNrUla.inspection.${AppLocalizations.of(context)!.inspection}', //id
    //   formattedDate, //data
    //   nowyNrPasieki!, //pasiekaNr
    //   nowyNrUla!, //ulNr
    //   'inspection', //karegoria
    //   AppLocalizations.of(context)!.inspection, //parametr
    //   ikona, //wartosc
    //   '', //miara
    //   '',//icon, //ikona pogody
    //   '', //'${temp.toStringAsFixed(0)}$stopnie', //temperatura zaokrąglona do 1 stopnia
    //   formatterHm.format(DateTime.now()), //formatedTime, //czas
    //   '', //uwagi
    //   0
    // ).then((_) {
    //   Provider.of<Infos>(context, listen: false)
    //       .fetchAndSetInfosForHive(nowyNrPasieki,nowyNrUla)
    //       .then((_) {
    //     // print(
    //     //     'edit_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy');
    //   });
    // });

    //print('edit_screen: zapis Frame do bazy');
 // }

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
//data - pasieka - ul
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  //SizedBox(width: 10),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                        controller: dateController, //editing controller of this TextField
                                        decoration: InputDecoration(//icon: Icon(Icons.calendar_today), //icon of text field
                                            labelText: AppLocalizations.of(context)!.noteDate),
                                        readOnly: true, // when true user cannot edit text
                                        onTap: () async {
                                          DateTime? pickedDate =
                                              await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.parse(dateController.text),
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime(2101));
                                          if (pickedDate != null) {
                                            String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);

                                            setState(() {
                                              dateController.text = formattedDate;
                                              globals.dataWpisu = formattedDate;
                                            });
                                          } else {
                                            print("Date is not selected");
                                          }
                                        }),
                                  ),
 //pasieka                               
                                  SizedBox(width: 10),
                                  SizedBox(
                                    width: 55,
                                    child: TextFormField(
                                        readOnly: true,
                                        initialValue: nowyNrPasieki.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          labelText:(AppLocalizations.of(context)!.apiary),
                                          labelStyle:TextStyle(color: Colors.black),
                                          hintText:(AppLocalizations.of(context)!.number),
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(context)!.apiaryNr);
                                          }
                                          nowyNrPasieki = int.parse(value);
                                          return null;
                                        }),
                                  ),
 //ul                                
                                  SizedBox(width: 10),
                                  SizedBox(
                                    width: 55,
                                    child: TextFormField(
                                        readOnly: true,
                                        initialValue: nowyNrUla.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          labelText:(AppLocalizations.of(context)!.hive),
                                          labelStyle:TextStyle(color: Colors.black),
                                          hintText:(AppLocalizations.of(context)!.number),
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(context)!.hiveNr);
                                          }
                                          nowyNrUla = int.parse(value);
                                          return null;
                                        }),
                                  ),
                                  SizedBox(width: 10),
  //korpus                                
                                  SizedBox(
                                    width: 55,
                                    child: TextFormField(
                                        initialValue: nowyNrKorpusu.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          labelText:(AppLocalizations.of(context)!.body),
                                          labelStyle:TextStyle(color: Colors.black),
                                          hintText:(AppLocalizations.of(context)!.number),
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(context)!.bodyNr);
                                          }
                                          nowyNrKorpusu = int.parse(value);
                                          globals.nowyNrKorpusu = int.parse(value);
                                          return null;
                                        }),
                                  ),                             
                                
                                
                                ],
                              ),

// ramka
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                //mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  
                                 // SizedBox(width: 10),
//ramka przed                                 
                                zakresRamek == false  
                                  ? SizedBox(
                                      width: 60,
                                      child: TextFormField(
                                          initialValue: nowyNrRamki.toString(),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: InputDecoration(
                                            labelText:(AppLocalizations.of(context)!.frame),
                                            labelStyle:TextStyle(color: Colors.black),
                                            hintText:(AppLocalizations.of(context)!.number),
                                          ),
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return (AppLocalizations.of(context)!.frameNr);
                                            }
                                            nowyNrRamki = int.parse(value);
                                            globals.nowyNrRamki = int.parse(value);                          
                                            return null;
                                          }),
                                    )
                                  : SizedBox(
                                      width: 60,
                                      child: TextFormField(
                                          initialValue: nrRamkiOd.toString(),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: InputDecoration(
                                            labelText:(AppLocalizations.of(context)!.from),
                                            labelStyle:TextStyle(color: Colors.black),
                                            hintText:(AppLocalizations.of(context)!.number),
                                          ),
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return (AppLocalizations.of(context)!.from);
                                            }
                                            nrRamkiOd = int.parse(value);
                                            //globals.nowyNrRamki = int.parse(value);
                                            return null;
                                          }),
                                    ),
                                
                                SizedBox(width: 10),
//ramka po                                 
                                zakresRamek == false  
                                ? SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                        initialValue: nowyNrRamkiPo.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          labelText:(AppLocalizations.of(context)!.frameAfter),
                                          labelStyle:TextStyle(color: Colors.black),
                                          hintText:(AppLocalizations.of(context)!.number),
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(context)!.frameNr);
                                          }
                                          nowyNrRamkiPo = int.parse(value);
                                          globals.nowyNrRamkiPo = int.parse(value);
                                          return null;
                                        }),
                                  )
                                  : SizedBox(
                                      width: 60,
                                      child: TextFormField(
                                          initialValue: nrRamkiDo.toString(),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: InputDecoration(
                                            labelText:(AppLocalizations.of(context)!.to),
                                            labelStyle:TextStyle(color: Colors.black),
                                            hintText:(AppLocalizations.of(context)!.number),
                                          ),
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return (AppLocalizations.of(context)!.theStoreIs);
                                            }
                                            nrRamkiDo = int.parse(value);
                                            //globals.nowyNrRamki = int.parse(value);
                                            return null;
                                          }),
                                    ),
  //zakres ramek                                  
                                  if(tryb == 'dodaj')
                                    Checkbox(
                                      checkColor: Colors.white,
                                      activeColor: Color.fromARGB(255, 0, 0, 0),
                                      //fillColor: MaterialStateProperty.Color(0xFF42A5F5),
                                      value: isChecked,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          isChecked = value!;
                                          zakresRamek = value;
                                        });
                                      },
                                    ),                              
                                    // SizedBox(
                                    //   width: 0,
                                    // ),
                                  if(tryb == 'dodaj')  
                                    Text(AppLocalizations.of(context)!.frameRange),
                                  
                                
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  globals.korpus = korpus;
                                                });
                                              }),
                                          label: Text(AppLocalizations.of(context)!.halfBody)),
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
                                                  globals.rozmiarRamki = rozmiarRamki;
                                                });
                                              }),
                                          label: Text(AppLocalizations.of(context)!.small +
                                                  ' ' + AppLocalizations.of(context)!.frame)),
       
                                    ],
                                  ),

//korpus
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  globals.korpus = korpus;
                                                });
                                              }),
                                          label: Text(AppLocalizations.of(context)!.body)),
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
                                                  globals.rozmiarRamki = rozmiarRamki;
                                                });
                                              }),
                                          label: Text(AppLocalizations.of(context)!.big +
                                                  ' ' + AppLocalizations.of(context)!.frame)),
   
                                    ],
                                  ),
                                ],
                              ),
  //lewa prawa obie 

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  // Column(
                                  //   mainAxisAlignment: MainAxisAlignment.start,
                                  //   crossAxisAlignment: CrossAxisAlignment.start,
                                  //   children: [
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
                                                  globals.stronaRamki = stronaRamki;
                                                });
                                              }),
                                          label: Text(AppLocalizations.of(context)!.left)),
//obie
                                    if(tryb == 'dodaj')  
                                      TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              stronaRamki = 0;
                                            });
                                          },
                                          icon: Radio(
                                              value: 0,
                                              groupValue: stronaRamki,
                                              onChanged: (value) {
                                                setState(() {
                                                  stronaRamki = value!;
                                                  globals.stronaRamki = stronaRamki;
                                                });
                                              }),
                                          label: Text(AppLocalizations.of(context)!.both)),
    
    
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
                                                  globals.stronaRamki = stronaRamki;
                                                });
                                              }),
                                          label: Text(AppLocalizations.of(context)!.right )),
                                    //]
                                  //)
                                ]
                              ),








//zasób 1-12
                              if (nowyZasob! < 13)
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      DropdownButton(
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                        value: nowyZasob, //ramka[0].zasob, //ustawiona, widoczna wartość
                                        items: [
                                       
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.queen),
                                              value: 10),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.waxFundation),
                                              value: 8),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.waxComb),
                                              value: 9),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.honeySealed),
                                              value: 7),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.recentHoney),
                                              value: 6),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.pollen),
                                              value: 5),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.eggs),
                                              value: 4),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.larvae),
                                              value: 3),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.broodCovered),
                                              value: 2),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.drone),
                                              value: 1),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.queenCells),
                                              value: 11),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.deleteQueenCells),
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
                                            nowyZasob = newValue; // ustawienie nowej wybranej nazwy dodatku
                                            nowaWartosc = '1'; //bo jak zmiana z jakiegoś zasobu na matkę to zostaje stara wartośc zasobu i wywala się DropdownButton od nowaWartosc
                                             //print('nowy zasób = $nowyZasob');
                                             //print('nowa wartość w  = $nowaWartosc');
                                          });
                                        }, //onChangeDropdownItemWar1,
                                      ),

//ilość

                                    SizedBox(width: 10),
//jezeli matka                                    
                                    if (nowyZasob! == 10)
                                    
                                       DropdownButton(
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                        value: nowaWartosc, //ustawiona, widoczna wartość
                                        items: [                             
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.black),
                                              value: '1'),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.yellow),
                                              value: '2'),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.red),
                                              value: '3'),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.green),
                                              value: '4'),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.blue),
                                              value: '5'),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.white),
                                              value: '6'),      
                                        ], //lista elementów do wyboru
                                        onChanged: (newValue) {
                                          //wybrana nowa wartość - nazwa dodatku
                                          setState(() {
                                            nowaWartosc = newValue.toString(); // ustawienie nowej wybranej nazwy dodatku                              
                                             //print('nowa wartość w switchu = $nowaWartosc');
                                          });
                                        }, //onChangeDropdownItemWar1,
                                      ),
//oprocz matki
                                    if (nowyZasob! != 10)
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                            initialValue: nowaWartosc,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            decoration: InputDecoration(
                                              labelText:(AppLocalizations.of(context)!.quantity),
                                              labelStyle: TextStyle(color: Colors.black),
                                              hintText: (AppLocalizations.of(context)!.enter + ' ' + AppLocalizations.of(context)!.quantity),
                                            ),
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return (AppLocalizations.of(context)!.enter + ' ' + AppLocalizations.of(context)!.quantity);
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
                                          child: Text('%',
                                            style: TextStyle(
                                              //fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                            softWrap: true, //zawijanie tekstu
                                            overflow: TextOverflow.fade,
                                          ),
                                        ),
   //szt.                                   
                                      if (nowyZasob! > 10 && nowyZasob! < 13)
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
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      DropdownButton(
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.black54,
                                        ),
                                        value: nowaWartosc, //ramka[0].zasob, //ustawiona, widoczna wartość
                                        items: [
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.workFrame),
                                              value: AppLocalizations.of(context)!.workFrame),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.toExtraction),
                                              value: AppLocalizations.of(context)!.toExtraction),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.toDelete),
                                              value: AppLocalizations.of(context)!.toDelete),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.toInsulate),
                                              value: AppLocalizations.of(context)!.toInsulate),
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
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      DropdownButton(
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.black54,
                                        ),
                                        value: nowaWartosc, //ramka[0].zasob, //ustawiona, widoczna wartość
                                        items: [
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.deleted),
                                              value: AppLocalizations.of(context)!.deleted),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.inserted),
                                              value: AppLocalizations.of(context)!.inserted),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.insulated),
                                              value: AppLocalizations.of(context)!.insulated),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.movedLeft),
                                              value: AppLocalizations.of(context)!.movedLeft),
                                          DropdownMenuItem(
                                              child: Text(AppLocalizations.of(context)!.movedRight),
                                              value: AppLocalizations.of(context)!.movedRight),
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
                                    zapisDoBazy(nowyZasob!, nowaWartosc, 'zmiana');                                   
                                    Provider.of<Frames>(context, listen: false)
                                      .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                                      .then((_) {

                                      if(nowyNrRamki != 0){//zeby mogło  być kilka ramek nowych wstawianych do ula
                                        //dla wszystkich zasobów dla ramki z numerem "nowyNrRamki" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
                                        final framesData1 = Provider.of<Frames>(context, listen: false);
                                          //wszystkie zasoby tej ramki (i z wybranej daty dla ula)
                                        List<Frame> frames = framesData1.items.where((fr) {
                                          return fr.ramkaNr == nowyNrRamki && fr.data == globals.dataWpisu; //return fr.data.contains('2024-04-04');
                                        }).toList();
                                          //dla kazdego zasobu modyfikacja ramkaNrPo
                                        for (var i = 0; i < frames.length; i++) {
                                          //print('ramka: ${frames[i].ramkaNr} zasób: ${frames[i].zasob}');
                                          DBHelper.updateRamkaNrPo(frames[i].id, nowyNrRamkiPo!);
                                        }
                                      } 
                                      Provider.of<Frames>(context, listen: false)
                                        .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                                        .then((_) {
                                        Navigator.of(context).pop();
                                      });
                                    });                                   
                                  });
                                };
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
                                    .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                                    .then((_) {
                                      
                                      if(nowyNrRamki != 0){//zeby mogło być kilka ramek nowych wstawianych do ula
                                        //dla wszystkich zasobów dla ramki z numerem "nowyNrRamki" (innym niz 0) nalezy ustawić taką samą wartość "ramkaPo" zeby cała ramka z zasobami zmieniła pozycję jeśli ustawiono taką zmianę
                                        final framesData1 = Provider.of<Frames>(context, listen: false);
                                        //zasoby tej ramki (z wybranej daty dla ula)
                                        List<Frame> frames = framesData1.items.where((fr) {
                                          return fr.ramkaNr == nowyNrRamki && fr.data == globals.dataWpisu; //return fr.data.contains('2024-04-04');
                                        }).toList();
                                        //dla kazdego zasobu modyfikacja ramkaNrPo
                                        for (var i = 0; i < frames.length; i++) {
                                          //print('ramka: ${frames[i].ramkaNr} zasób: ${frames[i].zasob}');
                                          DBHelper.updateRamkaNrPo(frames[i].id, nowyNrRamkiPo!);
                                        }
                                      }
                                      Provider.of<Frames>(context, listen: false)
                                        .fetchAndSetFramesForHive(globals.pasiekaID, globals.ulID)
                                        .then((_) {
                                        Navigator.of(context).pop();
                                      });
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
