
import 'dart:convert'; //obsługa json'a

//import 'package:hi_bees/screens/apiarys_weather_edit_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../globals.dart' as globals;
import '../helpers/db_helper.dart';
import '../models/apiarys.dart';
import '../models/frame.dart';
import '../models/frames.dart';
import '../models/hive.dart';
import '../models/hives.dart';
import '../models/info.dart';
import '../models/infos.dart';
import '../models/weather.dart';
import '../models/weathers.dart';
import '../screens/apiary_weather_5Days.dart';
import '../screens/apiarys_weather_edit_screen.dart';
import '../widgets/hives_item.dart';
import '../screens/raport_screen.dart';
import '../screens/raport2_screen.dart';

class HivesScreen extends StatefulWidget {
  static const routeName = '/screen-hives';

  @override
  State<HivesScreen> createState() => _HivesScreenState();
}

class _HivesScreenState extends State<HivesScreen> {
  bool _isInit = true;
  String numerPasieki = '';
  //String pobranie = '';
  double temp = 0.0;
  String icon = ''; //tymczasowo...
  String units = 'metric';
  String stopnie = '\u2103';
  var now = new DateTime.now();
  var formatterPogoda = new DateFormat('yyyy-MM-dd HH:mm');
  List<Weather>? pogoda;
  //zmienne do aktualizacji belki
  List<Hive> hives = []; //lista wszystkich uli w wybranej pasiece
  List<Frame> _daty = []; //unikalne daty z tabeli "ramki" (z zasobami na ramkach)
  List<Info> _datyInfo = []; //unikalne daty z tabeli "info" (dla kategorii i parametru)
  List<Info> _datyInfoDL = []; //unikalne daty z tabeli "info" (dla kategorii feeding i treatment)
  String dataPrzegladu = '2024-01-01'; //DateTime.now().toString().substring(0, 10);
  String ikona = 'green'; //pobierana z aktualnego ula
  int korpusNr = 0;
  int ileRamek = 10;
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
  String kategoria = '0';
  String parametr = '0';
  String wartosc = '0';
  String miara = '0';
  String matka1 = '';
  String matka2 = '';
  String matka3 = '';
  String matka4 = '';
  String matka5 = '';
  

  @override
  void didChangeDependencies() {
    //print('hives_screen - didChangeDependencies');

    //_isInit = globals.isInit;
    //print('hives_screen - _isInit = $_isInit');
    if (_isInit) {
      //pobranie danych o pogodzie dla pasieki
      //  Provider.of<Weathers>(context, listen: false)
      //   .fetchAndSetWeathers();
      //.then((_) {});
      
      //pobranie danych wszystkich uli z tabeli "ule" z bazy lokalnej (dane do belki, dokarmiania, leczenia i o matce)
      Provider.of<Hives>(context, listen: false)
          .fetchAndSetHives(globals.pasiekaID)
          .then((_) async{ //async zeby móc wywołac  await OdswiezBelki(i) 
        final hivesDataAll = Provider.of<Hives>(context, listen: false);
        final hivesAll = hivesDataAll.items; 
        //ODŚWIEZANIE ZASOBW I MATEK
        if(globals.odswiezBelkiUli == true){ //odswiezanie belek po imporcie danych (zmienna ustawiana w import_screen) lub ręcznie z ikony odświezania
          List<int> items = []; 
          for (var i = 0; i < hivesAll.length; i++) { 
            items.add(hivesAll[i].ulNr); //utworzenie listy numerów wszystkich uli - dla pętli for asynchronicznej
          }

          for (var item in items) {
            await OdswiezBelkiMatka(item); //tworzenie w belkach info o matkach
            await OdswiezBelki(item); //tworzenie belek zasobów dla kazdego ula
          }
          globals.odswiezBelkiUli = false;
        }
        
        //ODŚWIEZANIE DOKARMIANIA LUB LECZENIA
        if(globals.odswiezBelkiUliDL == true){ //tylko ręcznie z ikony odświezania
          List<int> items = []; 
          for (var i = 0; i < hivesAll.length; i++) { 
            items.add(hivesAll[i].ulNr); //utworzenie listy numerów wszystkich uli - dla pętli for asynchronicznej
          }

          for (var item in items) {
            await OdswiezBelkiDL(item); //tworzenie w belkach info o dokarmianiu lub leczeniu
            
          }
          globals.odswiezBelkiUliDL = false;
        }


        // setState(() {
        //   // _isLoading = false; //zatrzymanie wskaznika ładowania dań
        // });
      });
    }
    //  Provider.of<Weathers>(context, listen: false)
    //   .fetchAndSetWeathers();
    _isInit = false;

    super.didChangeDependencies();
  }


  //odświezanie belek (dokarmianie lub leczenie)
  OdswiezBelkiDL(int numerUla){
    //pobranie wszystkich info dla wybranego ula
    Provider.of<Infos>(context, listen: false)
      .fetchAndSetInfosForHive(globals.pasiekaID, numerUla)
      .then((_) { 
      final infosUla = Provider.of<Infos>(context, listen: false);   
      final hivesInfo = infosUla.items; //przypisanie tutaj bo inaczej nie działa tworzenie list: np List<Info> infosIleRamek = hivesInfo.where a nie List<Info> infosIleRamek = infosUla.items.where

      //DOKARMIANIE  lub LECZENIE //lista dat info ula zeby uzyskac datę ostatniego wpisu o dokarmianiu lub leczeniu
      getDatyInfoDL(globals.pasiekaID, numerUla).then((_) async {
        final tempDataDL = _datyInfoDL[0].data; //data oststniego wpisu dokarmiania lub leczenia
        //print(' OdswiezBelkiDL _____________ ile dat  = ${_datyInfoDL.length}');
        if(_datyInfoDL.isNotEmpty){ //jezeli są jakieś wpisy o dokarmianiu lub leczeniu (feeding  treatment)
        //final tempDataDL = _datyInfoDL[0].data; //data oststniego wpisu dokarmiania lub leczenia
          //pobranie info dla ula i dla daty ostatniego wpisu o dokarmianiu lub leczeniu
          List<Info> infosDL = hivesInfo.where((inf) {
              return  inf.data == tempDataDL && (inf.kategoria == 'feeding' || inf.kategoria == 'treatment') ; 
            }).toList();
            kategoria =  infosDL[0].kategoria;
            parametr = infosDL[0].parametr;
            wartosc = infosDL[0].wartosc;
            miara = infosDL[0].miara;
            //print('!!!!!!!!!!!!!!!!! do belki  = $kategoria $parametr $wartosc $wartosc'); 
            //ZAPIS DANYCH O ULU              
            Hives.insertHive(
              '${globals.pasiekaID}.${numerUla}',
              globals.pasiekaID, //pasieka nr
              numerUla, //ul nr
              infosDL[0].data, //przeglad ???????
              ikona, //kolor ikony ula
              ileRamek, //ilość ramek w korpusie pobrana z wpisów w "info"
              0, //framesZas[0].korpusNr,
              0, //trut,
              0, //czerw,
              0, //larwy,
              0, //jaja,
              0, //pierzga,
              0, //miod,
              0, //dojrzaly,
              0, //weza,
              0, //susz,
              0, //matka,
              0, //mateczniki,
              0, //usunmat,
              '0', //todo,
              kategoria, 
              parametr ,
              wartosc,
              miara,
              '0', //matka1,
              '0', //matka2,
              '0', //matka3,
              '0', //matka4,
              '0', //matka5,
              '0', //zapas h1
              '0', //h2
              '0', //h3
              0, //aktualne zasoby
            ).then((_) {
              //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
              Provider.of<Hives>(context, listen: false).fetchAndSetHives(globals.pasiekaID)
              .then((_) {
                final hivesData = Provider.of<Hives>(context, listen: false);
                final hives1 = hivesData.items;
                int ileUli = hives1.length;
                //print('edit_screen - ilość uli =');
                // print(hives.length);
                // print(ileUli);

                //DBHelper.updateIleUli(nrXXOfApiary, ileUli); //
                //print('insertApiary');
                //zapis do tabeli "pasieki"
                Apiarys.insertApiary(
                  '${globals.pasiekaID}',
                  globals.pasiekaID, //pasieka nr
                  ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
                  infosDL[0].data, //przeglad /????????
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
        } else {
            kategoria =  '0';
            parametr = '0';
            wartosc = '0';
            miara = '0';
            //print('!!!!!!!!!!!!!!!!! do belki  = $kategoria $parametr $wartosc $wartosc'); 
            //ZAPIS DANYCH O ULU              
            Hives.insertHive(
              '${globals.pasiekaID}.${numerUla}',
              globals.pasiekaID, //pasieka nr
              numerUla, //ul nr
              tempDataDL, //przeglad tempDataDL ??????
              ikona, //kolor ikony ula
              ileRamek, //ilość ramek w korpusie pobrana z wpisów w "info"
              0, //framesZas[0].korpusNr,
              0, //trut,
              0, //czerw,
              0, //larwy,
              0, //jaja,
              0, //pierzga,
              0, //miod,
              0, //dojrzaly,
              0, //weza,
              0, //susz,
              0, //matka,
              0, //mateczniki,
              0, //usunmat,
              '0', //todo,
              kategoria, 
              parametr ,
              wartosc,
              miara,
              '0', //matka1,
              '0', //matka2,
              '0', //matka3,
              '0', //matka4,
              '0', //matka5,
              '0', //zapas h1
              '0', //h2
              '0', //h3
              0, //aktualne zasoby
            ).then((_) {
              //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
              Provider.of<Hives>(context, listen: false).fetchAndSetHives(globals.pasiekaID)
              .then((_) {
                final hivesData = Provider.of<Hives>(context, listen: false);
                final hives1 = hivesData.items;
                int ileUli = hives1.length;
                //print('edit_screen - ilość uli =');
                // print(hives.length);
                // print(ileUli);

                //DBHelper.updateIleUli(nrXXOfApiary, ileUli); //
                //print('insertApiary');
                //zapis do tabeli "pasieki"
                Apiarys.insertApiary(
                  '${globals.pasiekaID}',
                  globals.pasiekaID, //pasieka nr
                  ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
                  tempDataDL, //przeglad tempDataDL ???????
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
        }
      });
    });
  }
  
  //odświezanie belek (info o matkach)
  OdswiezBelkiMatka(int numerUla){
    //INFO DLA ULA
    //pobranie wszystkich info dla wybranego ula
    Provider.of<Infos>(context, listen: false)
      .fetchAndSetInfosForHive(globals.pasiekaID, numerUla)
      .then((_) { 
      final infosUla = Provider.of<Infos>(context, listen: false);  
      final hivesInfo = infosUla.items; //przypisanie tutaj bo inaczej nie działa tworzenie list: np List<Info> infosIleRamek = hivesInfo.where a nie List<Info> infosIleRamek = infosUla.items.where

     //ILOŚĆ RAMEK   //lista dat info ula zeby uzyskac datę ostatniego wpisu ilości ramek w wybranym ulu
      getDatyInfo(globals.pasiekaID, numerUla,'equipment',AppLocalizations.of(context)!.numberOfFrame + " = ").then((_) async {
        if(_datyInfo.isNotEmpty){ //jezeli są jakieś wpisy o ilości ramek 
          final tempDataIleRamek = _datyInfo[0].data; //data oststniego wpisu ile ramek
          //pobranie info dla ula i dla daty ostatniego wpisu o ilosci ramek 
          List<Info> infosIleRamek = hivesInfo.where((inf) {
              return  inf.data == tempDataIleRamek && inf.kategoria == 'equipment' &&  inf.parametr == AppLocalizations.of(context)!.numberOfFrame + " = "; 
            }).toList();        
            ileRamek = int.parse(infosIleRamek[0].wartosc); 
        } else {ileRamek = 10;} //domyślna ilość ramek jezeli nie ma odpowiedniego wpisu w info dla ula
        
        //MATKA1 - queenQuality (dobra, OK)
        getDatyInfo(globals.pasiekaID, numerUla,'queen',AppLocalizations.of(context)!.queen + '  ' + AppLocalizations.of(context)!.isIs).then((_) async {
          if(_datyInfo.isNotEmpty){ //jezeli są jakieś wpisy o matce1
          final tempDataMatka1 = _datyInfo[0].data; //data ostatniego wpisu matka1
            //pobranie info dla ula i dla daty ostatniego wpisu o matce1
            List<Info> infosMatka1 = hivesInfo.where((m1) {
                return  m1.data == tempDataMatka1 && m1.kategoria == 'queen' &&  m1.parametr == AppLocalizations.of(context)!.queen + '  ' + AppLocalizations.of(context)!.isIs; 
              }).toList();
              if (infosMatka1[0].wartosc == 'mała' || infosMatka1[0].wartosc == 'słaba' || infosMatka1[0].wartosc == 'zła' || infosMatka1[0].wartosc == 'stara' ||
                infosMatka1[0].wartosc == 'small' || infosMatka1[0].wartosc == 'to exchange' || infosMatka1[0].wartosc == 'canceled' || infosMatka1[0].wartosc == 'weak' ) {
              matka1 = 'zła';
              if (ikona == 'red') { //bo był brak matki
                ikona = 'orange';
                //globals.ikonaPasieki = 'orange';
              }
              if (matka2 == 'brak') matka2 = '';
            } else {
              matka1 = 'ok';
              if (ikona == 'red') {  //bo był brak matki               
                ikona = 'orange';
                //globals.ikonaPasieki = 'orange';
              }
              if (matka2 == 'brak') matka2 = '';
            }
              //print('matka1 = ${infosMatka1[0].wartosc}'); 
          } else {matka1 = '';}
        DBHelper.updateUleMatka1('${globals.pasiekaID}.$numerUla',matka1);

          //MATKA2 - queenMark (ma znak, brak)
          getDatyInfo(globals.pasiekaID, numerUla,'queen'," " + AppLocalizations.of(context)!.queen).then((_) async {
            if(_datyInfo.isNotEmpty){ //jezeli są jakieś wpisy o matce2
            final tempDataMatka2 = _datyInfo[0].data; //data ostatniego wpisu matka2
              //pobranie info dla ula i dla daty ostatniego wpisu o matce2
              List<Info> infosMatka2 = hivesInfo.where((m2) {
                  return  m2.data == tempDataMatka2 && m2.kategoria == 'queen' &&  m2.parametr == " " + AppLocalizations.of(context)!.queen; 
                }).toList();
                switch (infosMatka2[0].wartosc) {
                  case 'nie ma znak': matka2 = 'niez'; //nieznaczona
                    break;
                  case 'unmarked': matka2 = 'niez'; //nieznaczona
                    break;
                  case 'ma biały znak': matka2 = 'biał ' + infosMatka2[0].miara; //kolor + numer matki
                    break;
                  case 'marker white': matka2 = 'biał ' + infosMatka2[0].miara; //kolor + numer matki
                    break;
                  case 'ma żółty znak': matka2 = 'żółt ' + infosMatka2[0].miara; //kolor + numer matki
                    break;
                  case 'marked yellow': matka2 = 'żółt ' + infosMatka2[0].miara; //kolor + numer matki
                    break;
                  case 'ma czerwony znak': matka2 = 'czer ' + infosMatka2[0].miara; //kolor + numer matki
                    break;
                  case 'marked red': matka2 = 'czer ' + infosMatka2[0].miara; //kolor + numer matki
                    break;
                  case 'ma zielony znak': matka2 = 'ziel ' + infosMatka2[0].miara; //kolor + numer matki
                    break;
                  case 'marked green': matka2 = 'ziel ' + infosMatka2[0].miara; //kolor + numer matki
                    break;
                  case 'ma niebieski znak': matka2 = 'nieb ' + infosMatka2[0].miara; //kolor + numer matki
                    break;
                  case 'marked blue': matka2 = 'nieb ' + infosMatka2[0].miara; //kolor + numer matki
                    break;
                  case 'nie ma': matka2 = 'brak'; matka1 = ''; matka3 = ''; matka4 = '';matka5 = '';
                    ikona = 'red';
                    //globals.ikonaPasieki = 'red';
                    break;
                  case 'gone': matka2 = 'brak'; matka1 = ''; matka3 = ''; matka4 = '';matka5 = '';
                    ikona = 'red';
                    //globals.ikonaPasieki = 'red';
                    break;
                  case 'brak': matka2 = 'brak'; matka1 = ''; matka3 = ''; matka4 = ''; matka5 = '';
                    ikona = 'red';
                    //globals.ikonaPasieki = 'red';
                    break;
                  case 'missing': matka2 = 'brak'; matka1 = ''; matka3 = ''; matka4 = '';matka5 = '';
                    ikona = 'red';
                    //globals.ikonaPasieki = 'red';
                    break;
                }
                //print('matka2 = ${infosMatka2[0].wartosc}'); 
            } else {matka2 = '';}
             DBHelper.updateUleMatka2('${globals.pasiekaID}.$numerUla',matka2);

            //MATKA3 - queenState (dziewica, naturalna)
            getDatyInfo(globals.pasiekaID, numerUla,'queen',AppLocalizations.of(context)!.queen + " -").then((_) async {
              if(_datyInfo.isNotEmpty){ //jezeli są jakieś wpisy o matce3
              final tempDataMatka3 = _datyInfo[0].data; //data ostatniego wpisu matka3
                //pobranie info dla ula i dla daty ostatniego wpisu o matce3
                List<Info> infosMatka3 = hivesInfo.where((m3) {
                    return  m3.data == tempDataMatka3 && m3.kategoria == 'queen' &&  m3.parametr == AppLocalizations.of(context)!.queen + " -"; 
                  }).toList();
                  if (infosMatka3[0].wartosc == 'dziewica' || infosMatka3[0].wartosc == 'virgin') {
                      matka3 = 'nieunasienniona';
                      if (ikona == 'red') { //bo był brak matki
                        ikona = 'orange';
                        //globals.ikonaPasieki = 'orange';
                      }
                      if (matka2 == 'brak') matka2 = '';
                    } else {
                      matka3 = 'unasienniona';
                      if (ikona != 'yellow') { //jezeli nie toDo
                        ikona = 'green';
                        //globals.ikonaPasieki = 'green'; 
                      }
                      if (matka2 == 'brak') matka2 = '';
                    }
                  //print('matka3 = ${infosMatka3[0].wartosc}'); 
              } else {matka3 = '';}
            DBHelper.updateUleMatka3('${globals.pasiekaID}.$numerUla',matka3);
              
              //MATKA4 - queenStart (wolna, w klatce)
              getDatyInfo(globals.pasiekaID, numerUla,'queen',AppLocalizations.of(context)!.queenIs).then((_) async {
                if(_datyInfo.isNotEmpty){ //jezeli są jakieś wpisy o matce4
                final tempDataMatka4 = _datyInfo[0].data; //data ostatniego wpisu matka4
                  //pobranie info dla ula i dla daty ostatniego wpisu o matce4
                  List<Info> infosMatka4 = hivesInfo.where((m4) {
                      return  m4.data == tempDataMatka4 && m4.kategoria == 'queen' &&  m4.parametr == AppLocalizations.of(context)!.queenIs; 
                    }).toList();
                    if (infosMatka4[0].wartosc == 'wolna' || infosMatka4[0].wartosc == 'freed'){
                      matka4 = 'wolna';
                      if (ikona == 'red') {//bo był brak matki
                        ikona = 'orange';
                        //globals.ikonaPasieki = 'orange';
                      }
                      if (matka2 == 'brak') matka2 = '';
                    } else{
                      matka4 = 'ograniczona';
                      if (ikona == 'red') {  //bo był brak matki
                        ikona = 'orange';
                        //globals.ikonaPasieki = 'orange';
                      }
                      if (matka2 == 'brak') matka2 = '';
                    }
                    //print('matka4 = ${infosMatka4[0].wartosc}'); 
                } else {matka4 = '';}
                DBHelper.updateUleMatka4('${globals.pasiekaID}.$numerUla',matka4);
                      
                //MATKA5 - queenBorn
                getDatyInfo(globals.pasiekaID, numerUla,'queen',AppLocalizations.of(context)!.queenWasBornIn).then((_) async {
                  if(_datyInfo.isNotEmpty){ //jezeli są jakieś wpisy o matce5
                  final tempDataMatka5 = _datyInfo[0].data; //data oststniego wpisu matka5
                    //pobranie info dla ula i dla daty ostatniego wpisu o matce5
                    List<Info> infosMatka5 = hivesInfo.where((m5) {
                        return  m5.data == tempDataMatka5 && m5.kategoria == 'queen' &&  m5.parametr == AppLocalizations.of(context)!.queenWasBornIn; 
                      }).toList();
                      matka5 = infosMatka5[0].wartosc;
                  } else {matka5 = '';}
                DBHelper.updateUleMatka5('${globals.pasiekaID}.$numerUla',matka5);
    
                  //AKTUALIZACJA DANYCH O PASIECE
                  //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
                  Provider.of<Hives>(context, listen: false).fetchAndSetHives(globals.pasiekaID)
                  .then((_) {
                    final hivesData = Provider.of<Hives>(context, listen: false);
                    final hives1 = hivesData.items;
                    int ileUli = hives1.length;
                    //print('edit_screen - ilość uli =');
                    // print(hives.length);
                    // print(ileUli);

                    //DBHelper.updateIleUli(nrXXOfApiary, ileUli); //
                    //print('insertApiary');
                    //zapis do tabeli "pasieki"
                    Apiarys.insertApiary(
                      '${globals.pasiekaID}',
                      globals.pasiekaID, //pasieka nr
                      ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
                      dataPrzegladu, //przeglad
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
                }); //daty matka1
              }); //daty matka2
            }); //daty matka3
          }); //daty matka4
        }); //daty matka5
      }); //daty ile ramek   
    });
  }
  
  //odświezanie belek (zasoby) - funkcja asynchroniczna po kolei dla kazdego ula
  Future<void> OdswiezBelki(int numerUla)async {
    //ZASOBY NA RAMKACH
    //lista dat przeglądów ula zeby uzyskac datę ostatniego przeglądu wybranego ula
    getDaty(globals.pasiekaID, numerUla).then((_) async {
      final tempData = _daty[0].data; //zapamietanie lokalne pierwszej daty bo przy pracy w pętli dla wielu uli tablica _daty jest nadpisywana przez nastepny ul
      if((DateTime.parse(tempData)).compareTo(DateTime.parse(dataPrzegladu)) > 0){
        dataPrzegladu = tempData; //dla wyświetlania ilości dni od przeglądu dla całej pasieki
      }
      Provider.of<Frames>(context, listen: false) //pobranie wszystkich ramek/zasobów z wybranego ula
          .fetchAndSetFramesForHive(globals.pasiekaID, numerUla)
          .then((_) { 
        final framesUla = Provider.of<Frames>(context, listen: false);
        //dotyczących wszystkich zasobów w ulu (dla daty ostatniego przeglądu oraz tylko dla ramek Po i wybranego korpusu)
        final framesZas = framesUla.items.where((fr) {
            return  fr.data == tempData && fr.ramkaNrPo != 0 && fr.korpusNr == 1; 
          }).toList();

            //   print('ZAWARTOŚĆ LISTY TYPU FRAME ula $numerUla');
            // if(numerUla == 4)
            // for (var frame in framesZas) {
            //     print('Data: ${frame.data}, ramkaNrPo: ${frame.ramkaNrPo}, korpusNr: ${frame.korpusNr}');
            //   }
        
        //zeby nie stracić danych zebranych podczas przeglądu w widoku zbiorczym uli (belka)
        final hiveData = Provider.of<Hives>(context, listen: false);
        final hive = hiveData.items.where((element) {
          //to wczytanie danych edytowanego ula
          return element.id.contains('${globals.pasiekaID}.$numerUla');
        }).toList();
        ikona = hive[0].ikona; 
        ileRamek = hive[0].ramek;
        korpusNr = hive[0].korpusNr; 

        kategoria = hive[0].kategoria;
        parametr = hive[0].parametr;
        wartosc = hive[0].wartosc;
        miara = hive[0].miara;
        matka1 = hive[0].matka1;
        matka2 = hive[0].matka2;
        matka3 = hive[0].matka3;
        matka4 = hive[0].matka4;
        matka5 = hive[0].matka5;

        //zerowanie zasobów
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
              //dla kazdego zasobu na ramkaNrPo - sumowanie wszystkich wartości zasobów
              for (var j = 0; j < framesZas.length; j++) {
                  //print('j = $j; zasob = ${framesZas[j].zasob }, data = ${framesZas[j].data}');
                switch (framesZas[j].zasob) {//id kolejnego zasobu
                  case 1:           
                    if(j == 0) trut = 0; //zerowanie zasobu bo będzie aktualizowany
                    trut = trut + int.parse(framesZas[j].wartosc.replaceAll(RegExp('%'), '')); //dodanie z uprzednim usunięciem znaku %
                    break;
                  case 2:
                    if(j == 0) czerw = 0; //zerowanie zasobu bo będzie aktualizowany
                    czerw = czerw + int.parse(framesZas[j].wartosc.replaceAll(RegExp('%'), ''));
                    break;
                  case 3:
                    if(j == 0) larwy = 0; //zerowanie zasobu bo będzie aktualizowany
                    larwy = larwy + int.parse(framesZas[j].wartosc.replaceAll(RegExp('%'), '')); 
                    break;
                  case 4:
                    if(j == 0) jaja = 0; //zerowanie zasobu bo będzie aktualizowany
                    jaja = jaja + int.parse(framesZas[j].wartosc.replaceAll(RegExp('%'), '')); 
                    break;
                  case 5:
                    if(j == 0) pierzga = 0; //zerowanie zasobu bo będzie aktualizowany
                    pierzga = pierzga + int.parse(framesZas[j].wartosc.replaceAll(RegExp('%'), '')); 
                    break;
                  case 6:
                    if(j == 0) miod = 0; //zerowanie zasobu bo będzie aktualizowany
                    miod = miod + int.parse(framesZas[j].wartosc.replaceAll(RegExp('%'), '')); 
                    break;
                  case 7:
                    if(j == 0) dojrzaly = 0; //zerowanie zasobu bo będzie aktualizowany
                    dojrzaly = dojrzaly + int.parse(framesZas[j].wartosc.replaceAll(RegExp('%'), '')); 
                    break;
                  case 8:
                    if(j == 0) weza = 0; //zerowanie zasobu bo będzie aktualizowany
                    weza = weza + int.parse(framesZas[j].wartosc.replaceAll(RegExp('%'), '')); 
                    break;
                  case 9:
                    if(j == 0) susz = 0; //zerowanie zasobu bo będzie aktualizowany
                    susz = susz + int.parse(framesZas[j].wartosc.replaceAll(RegExp('%'), '')); 
                    break;
                  case 10:
                      matka = int.parse(framesZas[j].wartosc); 
                    break;
                  case 11:
                    if(j == 0) mateczniki = 0; //zerowanie zasobu bo będzie aktualizowany
                    mateczniki = mateczniki + int.parse(framesZas[j].wartosc); 
                    break;
                  case 12:
                    if(j == 0) usunmat = 0; //zerowanie zasobu bo będzie aktualizowany
                    usunmat = usunmat + int.parse(framesZas[j].wartosc); 
                    break;
                  case 13:
                    todo = framesZas[j].wartosc;
                    break;
                }
              }
//IKONA DLA ULA
              // ikona ula zółta jezeli zasobem była czynność do zrobienia
              //o ile nie była czerwona lub pomarańczowa, bo problemy z matką są wazniejsze
              if ((todo != '' && todo != '0') && (ikona != 'red' || ikona != 'orange')) {
                ikona = 'yellow';
              }else if ((todo == '' || todo == '0') && (ikona =='yellow'))ikona ='green';                
                          
//ZAPIS DANYCH O ULU              
                Hives.insertHive(
                  '${globals.pasiekaID}.${numerUla}',
                  globals.pasiekaID, //pasieka nr
                  numerUla, //ul nr
                  framesZas[0].data, //przeglad
                  ikona, //kolor ikony ula
                  ileRamek, //ilość ramek w korpusie pobrana z wpisów w "info"
                  framesZas[0].korpusNr,
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
                  Provider.of<Hives>(context, listen: false).fetchAndSetHives(globals.pasiekaID)
                  .then((_) {
                    final hivesData = Provider.of<Hives>(context, listen: false);
                    final hives1 = hivesData.items;
                    int ileUli = hives1.length;
                    //print('edit_screen - ilość uli =');
                    // print(hives.length);
                    // print(ileUli);

                    //DBHelper.updateIleUli(nrXXOfApiary, ileUli); //
                    //print('insertApiary');
                    //zapis do tabeli "pasieki"
                    Apiarys.insertApiary(
                      '${globals.pasiekaID}',
                      globals.pasiekaID, //pasieka nr
                      ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
                      framesZas[0].data, //przeglad
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
        
      }); // od zasoby ramek   
    }); //od getDaty
  }// OdswiezBelki


   //pobranie listy info z unikalnymi datami dla wybranego ula, pasieki dla kategorii feeding i treatment z bazy lokalnej
  Future<List<Info>> getDatyInfoDL(pasieka, ul) async {
    final dataList = await DBHelper.getDateInfoDL(pasieka, ul); //numer wybranego ula
    //print('getDatyInfoDL: pasieka=$pasieka ul=$ul');
    _datyInfoDL = dataList
        .map(
          (item) => Info(
            id: '0',//data bo jak id to problem !!!
            data: item['data'],
            pasiekaNr: 0,
            ulNr: 0,
            kategoria: '0', //karmienie, leczenie, 
            parametr: '0', //
            wartosc: '0',
            miara: '0',
            pogoda: '0',
            temp: '0',
            czas: '0',
            uwagi: '0',
            arch: 0,
          ),
        )
        .toList();
    //print('daty = $_daty');
    return _datyInfoDL;
  }

  //pobranie listy info z unikalnymi datami dla wybranego ula, pasieki, kategorii i parametru z bazy lokalnej
  Future<List<Info>> getDatyInfo(pasieka, ul, kategoria, parametr) async {
    final dataList = await DBHelper.getDateInfo(pasieka, ul, kategoria, parametr); //numer wybranego ula
    //('getDatyInfo: pasieka=$pasieka ul=$ul katagoria=$kategoria parametr=$parametr');
    _datyInfo = dataList
        .map(
          (item) => Info(
            id: '0',//data bo jak id to problem !!!
            data: item['data'],
            pasiekaNr: 0,
            ulNr: 0,
            kategoria: '0', // matka, wyposazenie
            parametr: '0', //
            wartosc: '0',
            miara: '0',
            pogoda: '0',
            temp: '0',
            czas: '0',
            uwagi: '0',
            arch: 0,
          ),
        )
        .toList();
    //print('daty = $_daty');
    return _datyInfo;
  }

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

  //pobranie pogody z www dla miasta i aktualizacja wpisu w bazie
  Future<bool>? getCurrentWeather(String nrPasieki, String location) async {
    var endpoint = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=$location&appid=3943495c9983f5f94616a38aa17fcb4d&units=$units"); //https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=-2.15&appid={API key}")
    var response = await http.get(endpoint);
    var body = jsonDecode(response.body);
    // print('dane o pogodzie z miasta -----------------------');
    // print(body);
    temp = body["main"]["temp"];
    icon = body["weather"][0]["icon"];
    
    //print('$temp, $icon');
    String teraz = formatterPogoda.format(now);
    // print('ikona przed zapisem w miasto');
    // print(icon);
    DBHelper.updatePogoda(nrPasieki, teraz, temp, icon).then((_) {
      OdswiezPogode(numerPasieki);
    });
    return true;
  }

  //pobranie pogody z www dla koordynatów i aktualizacja wpisu w bazie
  Future<bool>? getCurrentWeatherCoord(
      String nrPasieki, String lati, String longi) async {
    var endpoint = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$lati&lon=$longi&appid=3943495c9983f5f94616a38aa17fcb4d&units=$units"); //https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=-2.15&appid={API key}")
    var response = await http.get(endpoint);
    var body = jsonDecode(response.body);
    // print('dane o pogodzie z koordynatów -----------------------');
    // print(body);
    temp = body["main"]["temp"];
    icon = body["weather"][0]["icon"];
    //print('$temp, $icon');
    String teraz = formatterPogoda.format(now);
    // print('ikona przed zapisem w koo');
    // print(icon);
    DBHelper.updatePogoda(nrPasieki, teraz, temp, icon).then((_) {
      OdswiezPogode(numerPasieki);
    }); //
    return true;
  }

  OdswiezPogode(String nrPasieki) {
    //pobranie danych o pogodzie dla pasieki
    Provider.of<Weathers>(context, listen: false)
        .fetchAndSetWeathers()
        .then((_) {
      final pogodaData = Provider.of<Weathers>(context, listen: false);
      pogoda = pogodaData.items.where((ap) {
        return ap.id.contains(numerPasieki.toString());
        //'numerPasieki'; // jest ==  a było contains ale dla typu String
      }).toList();
      // setState(() {
      temp = double.parse(pogoda![0].temp);
      icon = pogoda![0].icon;
      globals.aktualTemp = temp;
      globals.stopnie = stopnie;
      //print('setState icon - z bazy po OdswiezPogode');
      //print('aktualna temperatura pobrana z bazy = $temp');
      //  });
    });
  }

  // ręczne odswiezenie belek - wybór ?
    void _showAlertOdswiez() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.ostatnieInformacje + ':'),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, //minimalna wysokośc okna dialogowego
          children: <Widget>[          
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.odswiezBelkiUli = true;
                Navigator.of(context).pushNamed(
                    HivesScreen.routeName,
                    arguments: {'numerPasieki': globals.pasiekaID },
                  );
              }, child: Text((AppLocalizations.of(context)!.oZasobachMatkach),style: TextStyle(fontSize: 18))
              ), 
        
              TextButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                globals.odswiezBelkiUliDL = true;
                Navigator.of(context).pushNamed(
                    HivesScreen.routeName,
                    arguments: {'numerPasieki': globals.pasiekaID },
                  );
              }, child: Text((AppLocalizations.of(context)!.oDL),style: TextStyle(fontSize: 18))
              ),

              SizedBox(height: 20,),
              Text(AppLocalizations.of(context)!.rAports + ':', style: TextStyle(fontSize: 22)),
              SizedBox(height: 10,),

              TextButton(onPressed: (){
                Navigator.of(context).pop();
               // Navigator.of(context).pop();
                //globals.odswiezBelkiUliDL = true;
                Navigator.of(context).pushNamed(
                    RaportScreen.routeName,
                    arguments: {'numerPasieki': globals.pasiekaID },
                  );
              }, child: Text((AppLocalizations.of(context)!.hArvestReports),style: TextStyle(fontSize: 18))
              ),  

              TextButton(onPressed: (){
                Navigator.of(context).pop();
               // Navigator.of(context).pop();
                //globals.odswiezBelkiUliDL = true;
                Navigator.of(context).pushNamed(
                    Raport2Screen.routeName,
                    arguments: {'numerPasieki': globals.pasiekaID },
                  );
              }, child: Text((AppLocalizations.of(context)!.tReatmentReports),style: TextStyle(fontSize: 18))
              ),    
 
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }
    

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    final numerPasieki = routeArgs['numerPasieki'];
    //  final startBoxTitle = routeArgs['title'];
    //  final startBoxColor = routeArgs['color'];

    final hivesData = Provider.of<Hives>(context);
     
    //  // final hivesData = Provider.of<Hives>(context, listen: false);
    // //pobranie danych o nieaktualnych ulach do zmiennej
    // final hivesToAktual = hivesData.items.where((hi) {
    //     return hi.aktual != 0 ; //tylko ule nieaktualne
    //   }).toList();
    //   print('hives_screen - ilość uli nieaktualnych = ${hivesToAktual.length}');
    // //aktualizacja nieaktualnych uli
    
    // print('AKTUALIZACJA ULI !!!!!!!!!!!!!');
    // for (var i = 0; i < hivesToAktual.length; i++) {
    
    
    // }
    
    //pobranie danych o wszystkich ulach do zmiennej
    hives = hivesData.items; //showFavs ? productsData.favoriteItems :
    // print('hives_screen - ilość uli =');
    // print(hives.length);
    
    //ustawienie ikony dla pasieki na podstawie ikon ulowych
    globals.ikonaPasieki = 'green';
    for (var i = 0; i < hives.length; i++) {
      switch (hives[i].ikona){
        case 'red': globals.ikonaPasieki = 'red';
        break;
        case 'orange': if(globals.ikonaPasieki == 'yellow' || globals.ikonaPasieki == 'green') globals.ikonaPasieki = 'orange';
        break;
        case 'yellow': if(globals.ikonaPasieki == 'green') globals.ikonaPasieki = 'yellow';
        break;
      }
    }
    
    //aktualizacja ikony pasieki
    DBHelper.updateIkonaPasieki(int.parse(numerPasieki.toString()), globals.ikonaPasieki ); 
    //aktualizacja pasieki  - pobranie danych z bazy
    Provider.of<Apiarys>(context, listen: false).fetchAndSetApiarys();


    final pogodaData = Provider.of<Weathers>(context, listen: false);
    pogoda = pogodaData.items.where((ap) {
      return ap.id.contains(numerPasieki.toString());
      //'numerPasieki'; // jest ==  a było contains ale dla typu String
    }).toList();
    if (pogoda!.length == 0) {
      //jezeli nie ma danych dla wybranej pasieki - wpisz Konin (było: nie rób nic)
       Weathers.insertWeather(
        globals.pasiekaID.toString(),
        'Konin',
        '',
        '',
        '0000-00-00 00:00', //pobranie
        '', //temp
        '', // weatherId,
        '', //icon
        1,
        'pl',
        '',
      );
      //print('brak danych o lokalizacji pasieki więc wpisujemy Konin');
    } else {
      //print('dane o pogodzie pobrane z bazy lolalnej!!!!!!!!!!!!!!!!');
      //pobranie danych z bazy lokalnej na wypadek gdyby nie było internetu lub dane byłyby świeze
      pogoda![0].temp != '' ? temp = double.parse(pogoda![0].temp) : temp = 500; //500 - fikcyjna temp zeby jej nie wyswietlać
      pogoda![0].icon != '' ? icon = pogoda![0].icon : icon = '';
      globals.aktualTemp = temp;
      // print(
      //     '=================${pogoda![0].id},${pogoda![0].miasto},${pogoda![0].pobranie},${pogoda![0].temp},${pogoda![0].icon},${pogoda![0].miasto},');

      //jezeli są jakieś dane dla pasieki
      switch (pogoda![0].units) {
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
      globals.stopnie = stopnie;
      var now = DateTime.now();
      // print('data now =');
      // print('=$now=');
      // print('data pobrana z bazy = ');
      // print('=${pogoda![0].pobranie}=');
      final data = DateTime.parse(pogoda![0].pobranie);
      final difference = now.difference(data);
      // print('difference');
      // print(difference.inMinutes);
      //jezeli powyzej 30 minut od ostatniego pobrania pogody
      if (difference.inMinutes > 15) {
        //print('wejście do ifa difference');
        //to aktualizacja z www
        _isInternet().then(
          (inter) {
            if (inter) {
              // print('$inter - jest internet');
             // print('pobranie danych o pogodzie');
              if (pogoda![0].latitude != '' && pogoda![0].longitude != '') {
                getCurrentWeatherCoord(numerPasieki.toString(),
                    pogoda![0].latitude, pogoda![0].longitude);
              } else if (pogoda![0].miasto != '') {
                getCurrentWeather(numerPasieki.toString(), pogoda![0].miasto);
              }
              // print('ikona po pobraniu');
              // print(icon);
            } else {
              // print('braaaaaak internetu');
               //komunikat na dole ekranu 
              final czasOdPoprzedniegoKomunikatu = now.difference(globals.nieaktualnaPogoda);
              if(czasOdPoprzedniegoKomunikatu.inMinutes > 15){//zeby wyświetlał sie z tego miejsca nie częściej niz co 15 minut
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.pogodaNieaktualna),
                  ),
                );
                globals.nieaktualnaPogoda = DateTime.now(); //czas wyświetlenia komunikatu 
              }
              //dane o pogodzie nie będą aktualizowane a pobrane z bazy
              // setState(() {
              //   temp = double.parse(pogoda![0].temp);
              //   icon = pogoda![0].icon;
              //print('setState icon - z bazy bo nie ma internetu - else1');
              // });
            }
          },
        );
      } else {
        //to pobranie z bazy lokalnej
        // setState(() {
        //   temp = double.parse(pogoda![0].temp);
        //   icon = pogoda![0].icon;
       // print('setState icon - z bazy bo świeze dane - else2');
        // });
        //print('ikona w else2');
        //print(icon);
      }
      //print('${pogoda[0].id}, ${pogoda[0].miasto}, ${pogoda[0].latitude}');
    }
    // print('ikona przed Scaffold');
    // print(icon);

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            AppLocalizations.of(context)!.aPiary + " $numerPasieki",
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          //   title: Text('Apiary $numerPasieki'),
          //   backgroundColor: Color.fromARGB(255, 233, 140, 0),
          actions: <Widget>[
            if (icon != '')
              IconButton(
                icon: Image.network(
                  //     //obrazek pogody pobierany z neta
                  'https://openweathermap.org/img/wn/$icon.png', //adres internetowy
                  height: 50, //wysokość obrazka
                  //     //width: 140,
                  fit: BoxFit.cover, //dopasowanie do pojemnika
                ),
                onPressed: () => Navigator.of(context).pushNamed(Weather5DaysScreen.routeName),
              ),
            if(temp != 500) //bo była np zmiana lokalizacji
            Center(
                child: Text('${temp.toStringAsFixed(0)}$stopnie',
                    style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)))),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => Navigator.of(context)
                  .pushNamed(WeatherEditScreen.routeName, arguments: {
                'idPasieki': globals.pasiekaID,
              }),
            ),
            //odświezanie
            IconButton(
            icon: Icon(Icons.remove_red_eye, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () => 
               //print('${globals.pasiekaID}, $hiveNr')
                _showAlertOdswiez(),
               
          ), 
          ],
        ),
        body: hives.length == 0
            ? Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 50),
                      child: Text(
                        AppLocalizations.of(context)!.thereAreNoHives,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            :
            //kafelki
            // GridView.builder(
            //   padding: const EdgeInsets.all(10.0),
            //   itemCount: hives.length,
            //   itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
            //     value: hives[i],
            //     child: HivesItem(),
            //   ),
            //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //     crossAxisCount: 3,
            //     childAspectRatio: 6/ 8,
            //     crossAxisSpacing: 10,
            //     mainAxisSpacing: 10,
            //   ),
            // ),

            //lista
            Column(children: <Widget>[
                // Image.network(
                //   //     //obrazek pogody pobierany z neta
                //   'https://openweathermap.org/img/wn/$icon.png', //adres internetowy
                //   height: 50, //wysokość obrazka
                //   //     //width: 140,
                //   fit: BoxFit.cover, //dopasowanie do pojemnika
                // ),
                Expanded(
                  child: ListView.builder(
                    itemCount: hives.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: hives[i],
                      child: HivesItem(),
                    ),
                  ),
                )
              ]));
  }
}
