//import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
//import 'package:in_app_purchase/in_app_purchase.dart'; //subskrypcja
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hi_bees/screens/add_hive_screen.dart';
import 'package:hi_bees/screens/add_queen_screen.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert'; //obsługa json'a
//import 'dart:io';
import '../helpers/db_helper.dart';
import '../models/dodatki1.dart';
import '../models/dodatki2.dart';
import '../models/apiarys.dart';
import '../models/frames.dart';
import '../models/note.dart';
import '../models/memory.dart';
import '../models/weather.dart';
import '../models/infos.dart';
import '../widgets/apiarys_item.dart';
import '../widgets/note_priorytet_item.dart';
import '../screens/voice_screen.dart';
//import '../screens/subscription_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/harvest_screen.dart';
import '../screens/sale_screen.dart';
import '../screens/purchase_screen.dart';
import '../screens/note_screen.dart';
import '../screens/queens_screen.dart';
import '../models/weathers.dart';
import '../models/queen.dart';
import '../helpers/nfc_helper.dart';
//import '../models/apiarys.dart';

//ekran startowy
class ApiarysScreen extends StatefulWidget {
  const ApiarysScreen({super.key});
  static const routeName = '/screen-apiarys'; //nazwa trasy do tego ekranu
  @override
  State<ApiarysScreen> createState() => _ApiarysScreenState();
}

class _ApiarysScreenState extends State<ApiarysScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  final _formKey2 = GlobalKey<FormState>();
//final wersja = ['1','0','0','2','22.05.2020','nic']; //major, minor - wersja(zmiana w bazie), kolejna wersja bo wymaga tego iOS, numer wydania
  //1.0.1.1 30.03.2023 - start
  //1.0.1.4 13.04.2023 - subskrypcja przetestowana w sandboxie w AppStoreConnect 79,99 zł
  //1.1.0.5 01.06.2023 - wersja PL (picovoice_flutter 2.2.0), backup w chmurze, import, zmiana w bazie, nowa grafika w voice control
  //1.2.0.6 23.06.2023 - zmiana w bazie - dane z ostatniego przeglądu widoczne na liście uli, edycja wpisów z przeglądów, android ok
  //1.2.1.7 30.06.2023 - drobne błędy w wersji na iOSa, poprawki dla androida dotyczące dźwieków i plików picovoice
  //1.2.2.8 13.07.2023 - versja picovoice_flutter 2.2.1, zapis i edycja zbiorów, poprawki wyświtlania belki uli
  //1.2.3.9 11.08.2023 - zmiany w bazie - tabele sprzedaz, zakupy, zadania; statystyki w info; poprawki w rhuno
  //1.2.4.10 11.08.2023 - zmiana w imporcie i eksporcie danych info - dodano pogoda, temp i czas
  //1.2.5.11 12.08.2023 - poprawka z czasem delayed w pico, usunięcie if(mounted) w pico
  //1.2.5.15 23.08.2023 - próba z picovoice_flutter: ^2.2.2 - nadal błąd dla Androida
  //1.2.6.16 25.08.2023 - poprawka wyświetlania np. dokarmiania dla wszystkich uli (w belce ula), poprawki w ekranie parametryzacji i o aplikacji
  //1.2.7.18 07.09.2023 - picovoice_flutter: ^2.2.3, Android działa, zablokowanie edycji numeru pasieki i ula w frame_edit_screen
  //1.2.8.19 22.09.2023 - dodano sprzedaz, rhino aktualne dla pl i en
  //1.2.9.20 24.10.2023 - dodano zakupy i notatki
  //1.2.10.21 30.10.2023 - poprawki, wybór dat z kalendarza, komunikaty przy przesyłaniu danych
  //1.2.11.22 03.11.2023 - poprawianie wyglądu, obliczanie zbiorów miodu dla parametryzacji
  //1.2.12.23 12.11.2023 - link do Przewodnika, poprawki wyglądu
  //1.3.0.24 28.11.2023 - picovoice_flutter: 3.0.1, zbiór pyłek w ml, zlikwidowano wszystkie konta na Picovoice !!!
  //1.3.1.25 24.01.2024 - ręczne dodawanie uli (pasiek), przegladów i informacji, uporzadkowanie parametrów wpisów
  //1.3.2.26 27.01.2024 - instalowanie nowej aplikacji bez klucza picovoice, klawiatury numeryczne z lub bez przecinków i kropek, poprawki komunikatów na ekranie powitalnym
  //1.3.3.27 27.01.2024 - bez zmian - play.google - zmiana adresu strony www privacy-polisy
  //1.3.4.28 29.01.2024 - ustawianie roku do statystyk, zmniejszenie ikon matki pod belkami
  //1.3.5.29 11.02.2024 - prognoza pogody na 5 dni, automatyczne uzyskanie kodu aktywacyjnego
  //1.3.5.30 11.02.2024 - wersja dla AppStore - bo było dwa razy wysyłane dlatego (30), uwaga zmienić SDK na 17
  //1.3.6.31 12.02.2024 - wersja z testem dla App Store - kod aktywacyjny 00043210
  //1.4.0.32 15.02.2024 - dodano 3 pola w tabeli memory (na zapas), ustawianie domyślnego języka na "en" (zmiany w main i Info.plist) jezeli jest nieobsługiwany język
  //1.5.0.33 04.04.2024 - dodano pole w tabeli "ramka" ramkaNrPo, mozliwość pokazywania zasobów ramki przed i po przeglądzie, brak odpowiednich poprawek w voice_screen
  //1.5.1.34 05.04.2024 - poprawka bo nie mozna było aktywować apki - w tym pliku brakowało ramkaNrPo
  //1.5.2.36 06.04.2024 - dodawane zasobów ramek z pozycji widoku ramek w ulu, mozliwość dodawania kilku nowych ramek (z "ramkaNr" == 0) czyli dodanie do id ramek "ramkaNrPo", pamietanie daty w info_edit_screen
  //1.6.0.37 28.04.2024 - numery ramek w widoku ula, nowy interfejs dodawania i edycji zasobów na ramkach, dodatkowe pola w tabeli "ule" (niewykorzystane jeszcze)
  //1.6.1.38 02.05.2024 - poprawki działania nowego interfejsu dodawania zasobów na ramkach (przeglądy)
  //1.6.2.39 17.05.2024 - rozbudowa dodawania/edycji zasobów dla wielu ramek jednoczesnie - numery wielu ramek przed i po, zasób na ramce "tylko ten" lub "wszystkie"
  //1.6.3.40 20.05.2024 - mozliwość eksportu wybranych danych, poprawka wygladu edycji notatek, zakupów, zbiorów i sprzedazy, problem z podpisaniem a play.googlecom
  //1.6.4.41 25.05.2024 - wersja na nowy XCode 15 (i nowy MacBook) poprawki - kolor tła elementów ListTail, padding w dataButton, sumaZasob itp.
  //1.6.5.42 01.06.2024 - poprawki - dodanie isInit do skryptów edycyjnych, formatowanie pola data
  //1.6.6.43 14.06.2024 - zmiana na iosDeviceInfo.name i androidDeviceInfo.device bo Id telefonów nie są niezmienne, zmiana nazwy tabel www - XXXX_ramka itd., ograniczenie komunikatów o braku internetu
  //1.6.7.44 27.09.2024 - zapamietanie daty info w globals, pierwszy widok ramek - po przeglądzie, odświezanie belek: zasoby i matki (po imporcie danych i recznie) oraz dokarmianie lub leczenie, dodawanie info dla wszystkich uli przy dokarmianiu i leczeniu
  //1.6.9.47 02.10.2024 - ununięto Picovoice bo błąd w XCode: obecny kod binarny w bibliotekach porcupino i rhuino, usunieto subskrypcję bo błedy przy kompilacji androida
  //1.6.10.48 14.10.2024 - dodano statystyki zbioru miodu, pyłku i varrozy, poprawa statystyki dokarmiania ciastem, chyba poprawa wyświetlania szczegółów ramek przy zmianie daty przegladu
  //1.6.11.49 27.10.2024 - dodano raporty zbiorów i raporty leczenia,
  //zminana MacBook Pro
  //1.6.12.50 02.11.2024 - dodano "frame_edit_screen2" - ekran dodawania zasobów na ramkach w wersji dla obu stron ramki naraz i automatycznego zwiększania numeru ramki
  //1.7.0.51 11.11.2024 - zaktualizowano wszystkie pakiety (biblioteki) - apka nie działa z picovoice_flutter: ^3.0.3 !!!
  //1.7.0.51 06.12.2024 - Picovoice naprawił rhino_flutter 3.0.4 i działa juz picovoice_flutter: ^3.0.3, pliki .rhn v.3_0_0, model: ang1, pol1, poprawki w wersji angielskiej (PlayGoogle)
  //aktualizacja Fluttera - nie działa wersja na Androida
  //1.7.1.52 05.01.2025 - usunięcie błędnego działania vioce_screen, modyfikacja voice_screen: wstaw/usuń ramka, numer ramki przed i po przeglądzie np. przed 3/8 po, isDone dla zakresu ramek - wstaw/usuń wiele ramek (AppStore tylko bo android nie działa po flutter upgrade)
  //1.8.0.53 17.01.2025 - zmiana nazwy i ikony apki na "Hey Maya", nowy ekran powitalny, poprawki i nowe słowa w modelu Rhiuno, statystyki do 2030 roku, literowe oznaczenia matek,
  //1.8.1.54 25.01.2025 - poprawka niedziałajacej funkcji _isInternet() po zmianie biblioteki connectivity_plus
  //1.8.2.55 15.02.2025 - zmiana adresu strony ze skryptami rejestrowania uzytkowników i eksportu/importu danych z hibees.pl na darys.pl  
  //1.8.3.56 18.02.2025 - poprzednia wersja nie chciała się uruchomić na AppStore więc wysłałem powtórnir bez zmian
  //1.8.4.57 26.03.2025 - dodano inne zaznaczenie matki (srebrne)(trzeba dodać w modelu na picovoice.ai !!!!!), rok urodzenia matki wyswietla się w info niezaleznie od roku statystyk
  //1.8.5.58 06.04.2025 - usunięty błąd w statystykach przy braku wartości parametru (pole wartość puste), blokowanie wygaszania ekranów wszystkich oprócz startowego, oś pozioma raportów zbiorczych pokazuje numer ula a nie kolejny numer słupka
  //1.8.6.59 04.05.2025 - oznaczanie np: > 2025 < w oknie wyboru roku statystyk, zmiana daty ( na dateController.text) przy edycji ramkaPo dla wszystkich zasobów na ramce, w ekranie "Zbiory Pomóz mi" dodanie pyłku w ml, w voice_screen ustawianie ramkaPo=0 dla zasobów ramki przenoszonej do innego korpusa lub ula, matka2=='brak' -> czerwone tło, przy przenoszeniu ramki zerowanie numeru korpusa - komentarz KOM1,
  //1.8.7.60 11.05.2025 - przenoszenie ramek ręczne, błąd w statystykach zbiorów miodu z duzych ramek, likwidacja ula, poprawki tła appBar i dodanie kreski oddzielającej od body
  //1.8.8.61 25.05.2025 - poprawka w przenoszeniu ramek - niezalezne daty przeglądów Z i Do, notatki w przegladach ramek, powiększanie widoku ramek ula
  //1.8.8.62 26.05.2025 - zmiana w Xcode - mozliwość działania na iPad
  //1.8.9.63 01.06.2025 - zapisywanie info o przeglądzie do bazy tylko raz zeby zachować godzinę rozpoczecia przeglądu, zapisywanie notatki tylko w trybie edycji i bez mozliwośi zmiany daty zeby nie nadpisywać notatki
  //1.8.10.64 17.06.2025 - poprawka pobierania temperatury z bazy po restarcie apki, dodano info o ostatnich zbiorach miodu a widoku wszystkich uli 
  //1.8.11.65 01.07.2025 - poprawka informacji o zbiorach w widoku Pasieka (wszystkie ule)
  //1.8.12.66 28.10.2025 - dodanie zbiorów miodu w kg, stronicowanie raportów przy duzej ilości uli
  //1.8.13.67 03.11.2025 - zmiana współczynnika przeliczania zbiorów pierzgi litry/kilogramy (harvest_screen), dodano typ i rodzaj ula w wyposazeniu, poprawa wyswietlania ikon w "info",dodano obramowanie wszystkich przycisków "zapisz"
  //1.9.0.68 11.16.2025 - dodano zarzadzanie matkami - nowa baza matki, likwidacja błędów pojawiających sie kiedy brak danych o przeglądach ramek, poprawa stylistyczna nazw niektórych info
  //1.9.1.69 30.11.2025 - usunięty bład w raportach warrozy i błąd w voice_screen: "zamknij pomoc" wychodził z voice,
  //1.9.2.70 19.12.2025 - app_pl, app_en, queen_scerrn - widoki, queen.dart - kolory, add_hive_screen - ilość uli, globals,
  //1.9.3.71 06.01.2026 - app_en i app_pl - "ramek",raport_screen i raport2_screen - rok w tytule, globals - rokMatki, info_edit_screen - dodano ID matki w tytule, queen_screen - dodatkowy rok "Wsztstkie", info_screen - w rodzina i matka ostatnie infa z wszystkich lat a nie z roku do statystyk, w Notes Zbiory Zakupy Sprzedaz - tylko lata z danymi
  //1.9.4.72 31.01.2026 - zwiekszenie kafla pasieki i inne dostosowania do systemowego skalowania czcionki, ilość ramek miodu w zbiorach - zmiana z int na liczby dziesiętne, zbiór miodu zalezy od powierzchni ramki w dm2, obsługa tagów NFC
  //1.9.5.74 01.02.2025 - bład przy wyświetlaniu w hive_screen danych o matkach bez belki zasobów,
  //1.9.5.75 03.02.2026 - raport_color_screen -> litry miodu w legendzie zbiorów (1l=1.45kg), legenda miodobrań w kolumnie, przycisk PDF przy wykresach zbiorów miodu i pyłku

  final wersja = '1.9.5.74'; //wersja aplikacji na iOS
  final dataWersji = '2026-02-01';
  final now = DateTime.now();
  int aktywnosc = 0;
  List<Weather>? pogoda;
  String stopnie = '\u2103';  

  @override
  void didChangeDependencies() {
    //print('apiarys_screen - didChangeDependencies');

    //print('apiarys_screen - _isInit = $_isInit');
    if (_isInit) {
      setState(() {
        _isLoading = true; //uruchomienie wskaznika ładowania danych
      });
//DBHelper.deleteBase().then((_) {
      _getId().then((_) {
        //pobranie Id telefonu i zapisanie w globals.deviceId - do identyfikacji uzytkownika apki
        //pobranie z bazy lokalnej Memory dla tego smartfona (lub "test" dla sklepów)
        //print('globals.deviceId = ${globals.deviceId}');
        Provider.of<Memory>(context, listen: false)
            .fetchAndSetMemory(globals.deviceId)
            .then((_) {
          //memory(id TEXT PRIMARY KEY, email TEXT, dev TEXT, wer TEXT, kod TEXT, key TEXT,dod TEXT, ddo TEXT, memjezyk TEXT, mem1 Text, mem2 TEXT)');
          //uzyskanie dostępu do danych
          final memData = Provider.of<Memory>(context, listen: false);
          final mem = memData.items;
          //if (mem.isNotEmpty){
            //print('------------- jest memory: ');
            //print('${mem[0].id}, ${mem[0].email},${mem[0].dev},${mem[0].wer},${mem[0].kod},${mem[0].key},${mem[0].dod},${mem[0].ddo},${mem[0].memjezyk},${mem[0].mem1},${mem[0].mem2},');
         // }else{
            //print('---------------- memory jest puste!!!!!');};
          //print('**************** globals.memJezyk przed pobraniem z bazy = /${globals.memJezyk}/ ');
          // if (mem.isNotEmpty && mem[0].memjezyk != '') globals.memJezyk = mem[0].memjezyk;
          // else globals.memJezyk = 'system';
          // print('**************** memjezyk po pobraniu z bazy = /${mem[0].memjezyk}/ ');
          // print('**************** globals.memJezyk = /${globals.memJezyk}/ ');
          //odczytanie ustawień języka (pl_PL, en_US)
          Locale myLocale = Localizations.localeOf(context);
          String jezykSmartfona = myLocale.toString(); //zapamiętanie aktualnego języka
          //  print('================pobranie jezyka smartona = ${jezykSmartfona}');
          // print('================globals.jezyk przed switchem = ${globals.jezyk}');
          //if (globals.memJezyk == 'system')
          switch (jezykSmartfona) {
            case 'pl_PL':
              globals.jezyk = 'pl_PL';
              break;
            case 'en_US':
              globals.jezyk = 'en_US';
              break;
            default:
              globals.jezyk = 'en_US'; //i to nie działa nie wiadomo czemu !!!
              break;
          }
          // else globals.jezyk = mem[0].memjezyk;

          //  print('================globals.jezyk po switchu = ${globals.jezyk}');
          globals.wersja = wersja;

          //uaktualnienie wersji apki na serwerze www po np. aktualizacji apki
          //print('mem.wer = ${mem[0].wer}');
          //print('mem.kod = ${mem[0].kod}');
          if (mem.isNotEmpty && mem[0].wer != wersja) wyslijKod(mem[0].kod);

          //jezeli jest wpis w bazie dla tego deviceId lub "test" - (wpis moze być ale accessKey niekoniecznie!!!)
          if (mem.isNotEmpty &&
              mem[0].dod != 'bez aktywacji' &&
              mem[0].dod != '') {
            //jezeli jest taki deviceID i data "od" ma normalny format
            globals.key = mem[0].key; //pobranie klucza
            globals.keyMemory =  mem[0].key; //potrzebne gdyby była rezygnacja z aktywacji
            globals.kod = mem[0].kod; //kod do aktywacji, kod tworzy nazwę tabeli do archiwizacji
//print('jest wpis w bazie dla tego deviceID lub "test" ');
            //sprawdzenie daty do której apka jest aktywna
            final data = DateTime.parse(mem[0].ddo);
            aktywnosc = daysBetween(now, data); //ile dni wazności apki
            // if (aktywnosc < 30 && aktywnosc >= 0) {
            //   _showAlert(
            //       context,
            //       AppLocalizations.of(context)!.alert,
            //       AppLocalizations.of(context)!.subscriptionEndsIn +
            //           " $aktywnosc " +
            //           AppLocalizations.of(context)!.days);
            //   //pobranie wszystkich pasiek z tabeli pasieki z bazy lokalnej
            //   Provider.of<Apiarys>(context, listen: false)
            //       .fetchAndSetApiarys()
            //       .then((_) {
            //         //print('------------------- wczytanie pasiek Apiarys????? podczas inicjacji');
            //     setState(() {
            //       _isLoading = false; //zatrzymanie wskaznika ładowania dań
            //     });
            //   });
            // } else if (aktywnosc <= -1) {
            //   //*** Wygasła subskrypcja
            //   //wymuszenie trybu "bez aktywacji"
            //   //print('333333333333 aktywnosc < -1');

            //   DBHelper.updateActivate(globals.deviceId, 'bez aktywacji')
            //       .then((_) {
            //     // print(
            //     //     'w bez i \'\' aktywność < -1 globals.key = ${globals.key}');
            //     // print('w bez i \'\' aktywność < -1 memory.dod: ${mem[0].dod}');
            //     //pobranie wszystkich pasiek z tabeli pasieki z bazy lokalnej
            //     Provider.of<Apiarys>(context, listen: false)
            //         .fetchAndSetApiarys()
            //         .then((_) {
            //       setState(() {
            //         _isLoading = false; //zatrzymanie wskaznika ładowania dań
            //       });
            //     });
            //   });
            // } else {
              //*** Jest aktywna subskrypcja
              //print('44444444444 aktywnoscok');
              //pobranie wszystkich pasiek z tabeli pasieki z bazy lokalnej
              Provider.of<Apiarys>(context, listen: false)
                  .fetchAndSetApiarys()
                  .then((_) {
                setState(() {
                  _isLoading = false; //zatrzymanie wskaznika ładowania
                });
              });
              //print('Apka aktywna');
    //        }

            //jezeli uzytkownik wybrał "bez aktywacji" ma dostęp ale bez "voice control"
          } else if (mem.isNotEmpty && mem[0].dod == 'bez aktywacji') {
            globals.key = mem[0].dod;
            //print('w bez aktywności globals.key = ${globals.key}');
            //print('w bez aktywności memory.dod: ${mem[0].dod}');
            //pobranie wszystkich pasiek z tabeli pasieki z bazy lokalnej
            Provider.of<Apiarys>(context, listen: false)
                .fetchAndSetApiarys()
                .then((_) {
              setState(() {
                _isLoading = false; //zatrzymanie wskaznika ładowania
              });
            });
            final data = DateTime.parse(mem[0].ddo);
            aktywnosc = daysBetween(now, data); //ile dni wazności apki
            //print('aktywnisc = $data - $now = $aktywnosc ');

            // _showAlert(
            //     context,
            //     AppLocalizations.of(context)!.alert,
            //     AppLocalizations.of(context)!.subscriptionEndsIn +
            //         " $aktywnosc " +
            //         AppLocalizations.of(context)!.days);
          } else {
            //jezeli uzytkownik chce aktywować bo wybrał "Aktywuj"
            if (mem.isNotEmpty)
              globals.key = mem[0].dod; //???
            else {
              //dla testu AppStore
              //globals.key = '';
              Provider.of<Memory>(context, listen: false)
                  .fetchAndSetMemory('test')
                  .then((_) {
                //uzyskanie dostępu do danych
                final memData = Provider.of<Memory>(context, listen: false);
                final mem = memData.items;
                if (mem.isNotEmpty && mem[0].dev == 'test') {
                  globals.key = 'bez_klucza';
                } else
                  globals.key = '';
              });
            }
            //jezeli nie ma accessKey
            //print('nie ma assessKey');
            //print('w else globals.key = ${globals.key}');
            //print('w else memory.dod: ${mem[0].dod}');
          }
 //DBHelper.deleteTable('dodatki2');
          //DODATKI2 - ustawienia w aplikacji:
          Provider.of<Dodatki2>(context, listen: false)
              .fetchAndSetDodatki2()
              .then((_) {
            //uzyskanie dostępu do danych z tabeli dodatki1
            final dod2Data = Provider.of<Dodatki2>(context, listen: false);
            final dod2 = dod2Data.items;
            //inicjacja tabeli dodatki2 jezeli jej nie było
            //tabela Dodatki1: index,m,n,s,t,u,v,w,z,
                            //  id; //id:1 
                            //   m; //TYP A
                            //   n; //własna nazwa ula
                            //   s; //szerokość wewnętrzna ramka duza
                            //   t; //wysokość wewnętrzna ramka duza
                            //   u; //powierzchnia wnętrza duzej ramki w mm2 (plastra)
                            //   v; //szerokość wewnętrzna ramka mała
                            //   w; //wysokość wewnętrzna ramka mała
                            //   z; //powierzchnia wnętrza małej ramki w mm2 (plastra)
            
            //jezeli nie ma tabeli dodatki2
            if (dod2.length == 0) {
              Dodatki2.insertDodatki2('1', 'TYP A', 'Wielkopolski A', '335', '235', '78725', '335', '105', '35175');
              Dodatki2.insertDodatki2('2', 'TYP B', 'Wielkopolski B', '335', '235', '78725', '335', '105', '35175');
              Dodatki2.insertDodatki2('3', 'TYP C', 'Wielkopolski C', '335', '235', '78725', '335', '105', '35175');
              Dodatki2.insertDodatki2('4', 'TYP D', 'Wielkopolski D', '335', '235', '78725', '335', '105', '35175');
            }
          });

          //DODATKI1 - ustawienia w aplikacji:
          //a - 'true'/'false' - uatawienie przełącznika automatycznego eksportu danych
          Provider.of<Dodatki1>(context, listen: false)
              .fetchAndSetDodatki1()
              .then((_) {
            //uzyskanie dostępu do danych z tabeli dodatki1
            final dod1Data = Provider.of<Dodatki1>(context, listen: false);
            final dod1 = dod1Data.items;
            //inicjacja tabeli dodatki1m jezeli jej nie było
            //tabela Dodatki1: index,a,b,c,d,e,f,g,h
                              //id-1
                              //a-auto wysyłka danych z bazy do chmury,
                              //b-średnia waga miodu na 1dm2 plastra, 
                              //c-nic, 
                              //d-nic, 
                              //e-waga miodu na duzej ramce, 
                              //f-waga miodu na małej ramce, 
                              //g-miarka do pyłku, 
                              //h-ile uli na stronie raportów
            
            //jezeli nie ma tabeli dodatki1
            // DBHelper.deleteTable('dodatki1');
            if (dod1.length == 0) {
              //jezeli nie ma tabeli dodatki1
              Dodatki1.insertDodatki1('1', 'true', '250', '0', '0', '900', '1900', '100', '20');
              } else {
              //jezeli jest tabela dodatki1
              globals.raportIleUliNaStronie = int.parse(dod1[0].h);
              if (dod1[0].a == 'true') {
                //ustawienie przłącznika eksportu danych - automatyczne wysłanie danych przy uruchamianiu apki
                //BACKUP BAZY LOKALNEJ
                //czy jest wpis w bazie memory dla tego deviceId? kod potrzebny do nazwy tabeli backupu
                if (mem.isNotEmpty && mem[0].kod != '') {
                  //BACKUP tabeli ramka - tylko wpisy z arch=0
                  Provider.of<Frames>(context, listen: false)
                      .fetchAndSetFramesToArch()
                      .then((_) {
                    final framesAllData =
                        Provider.of<Frames>(context, listen: false);
                    final ramki = framesAllData.items;
                    //print('ilość wpisów w tabeli ramka');
                    //print(ramki.length);
                    //print(globals.kod);
                    //final jsonData = jsonEncode(<String, String>{'aaa':'101', 'bbb':'1', 'ccc':'1'});
                    //'{"ramki":[{"id": "aaa","pasieka":"1", "ul":"1"},{"id":"bbb", "pasieka":"1","ul":"2"}],"total":2}';

                    if (ramki.length > 0) {
                      String jsonData = '{"ramka":[';
                      int i = 0;
                      while (ramki.length > i) {
                        jsonData += '{"id": "${ramki[i].id}",';
                        jsonData += '"data": "${ramki[i].data}",';
                        jsonData += '"pasiekaNr": ${ramki[i].pasiekaNr},';
                        jsonData += '"ulNr": ${ramki[i].ulNr},';
                        jsonData += '"korpusNr": ${ramki[i].korpusNr},';
                        jsonData += '"typ": ${ramki[i].typ},';
                        jsonData += '"ramkaNr": ${ramki[i].ramkaNr},';
                        jsonData += '"ramkaNrPo": ${ramki[i].ramkaNrPo},';
                        jsonData += '"rozmiar": ${ramki[i].rozmiar},';
                        jsonData += '"strona": ${ramki[i].strona},';
                        jsonData += '"zasob": ${ramki[i].zasob},';
                        jsonData += '"wartosc": "${ramki[i].wartosc}",';
                        jsonData += '"arch": ${ramki[i].arch}}';
                        i++;
                        if (ramki.length > i) jsonData += ',';
                      }
                      jsonData +=
                          '],"total":${ramki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_ramka"}'; //pierwsze cztery cyfry kodu XXXX_ramka

                      //print(jsonData);
                      _isInternet().then(
                        (inter) {
                          if (inter) {
                            // print('$inter - jest internet');
                            wyslijBackupRamka(jsonData); //jsonData
                          } else {
                            // print('braaaaaak internetu');
                            //   _showAlertOK(
                            //       context,
                            //       AppLocalizations.of(context)!.alert,
                            //       AppLocalizations.of(context)!.noInternet);
                          }
                        },
                      );
                    } //jeśli sa ramki do archiwizacji
                  }); //od pobrania ramek

                  //BACKUP tabeli info - tylko wpisy z arch=0
                  Provider.of<Infos>(context, listen: false)
                      .fetchAndSetInfosToArch()
                      .then((_) {
                    final infoArchData =
                        Provider.of<Infos>(context, listen: false);
                    final info = infoArchData.items;
                    //print('ilość wpisów w tabeli info');
                    //print(info.length);
                    //print(globals.kod);
                    //final jsonData = jsonEncode(<String, String>{'aaa':'101', 'bbb':'1', 'ccc':'1'});
                    //'{"ramki":[{"id": "aaa","pasieka":"1", "ul":"1"},{"id":"bbb", "pasieka":"1","ul":"2"}],"total":2}';

                    if (info.length > 0) {
                      String jsonData = '{"info":[';
                      int i = 0;
                      while (info.length > i) {
                        jsonData += '{"id": "${info[i].id}",';
                        jsonData += '"data": "${info[i].data}",';
                        jsonData += '"pasiekaNr": ${info[i].pasiekaNr},';
                        jsonData += '"ulNr": ${info[i].ulNr},';
                        jsonData += '"kategoria": "${info[i].kategoria}",';
                        jsonData += '"parametr": "${info[i].parametr}",';
                        jsonData += '"wartosc": "${info[i].wartosc}",';
                        jsonData += '"miara": "${info[i].miara}",';
                        jsonData += '"pogoda": "${info[i].pogoda}",';
                        jsonData += '"temp": "${info[i].temp}",';
                        jsonData += '"czas": "${info[i].czas}",';
                        jsonData += '"uwagi": "${info[i].uwagi}",';
                        jsonData += '"arch": ${info[i].arch}}';
                        i++;
                        if (info.length > i) jsonData += ',';
                      }
                      jsonData +=
                          '],"total":${info.length}, "tabela":"${mem[0].kod.substring(0, 4)}_info"}'; //pierwsze cztery cyfry kodu XXXX_ramka

                      //print(jsonData);
                      _isInternet().then(
                        (inter) {
                          if (inter) {
                            wyslijBackupInfo(jsonData); //jsonData
                          } else {
                            //print('braaaaaak internetu');
                            //komunikat na dole ekranu
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    AppLocalizations.of(context)!.unablaToSend),
                              ),
                            );
                            // _showAlertOK(
                            //     context,
                            //     AppLocalizations.of(context)!.alert,
                            //     AppLocalizations.of(context)!.noInternet);
                          }
                        },
                      );
                    } //jeśli sa ramki do archiwizacji
                  });

                   //BACKUP tabeli matki - tylko wpisy z arch=0
                  Provider.of<Queens>(context, listen: false)
                      .fetchAndSetQueensToArch()
                      .then((_) {
                    final matkiArchData =
                        Provider.of<Queens>(context, listen: false);
                    final matki = matkiArchData.items;
                    //print('ilość wpisów w tabeli info');
                    //print(info.length);
                    //print(globals.kod);
                    //final jsonData = jsonEncode(<String, String>{'aaa':'101', 'bbb':'1', 'ccc':'1'});
                    //'{"ramki":[{"id": "aaa","pasieka":"1", "ul":"1"},{"id":"bbb", "pasieka":"1","ul":"2"}],"total":2}';

                    if (matki.length > 0) {
                      String jsonData = '{"matki":[';
                      int i = 0;
                      while (matki.length > i) {
                        jsonData += '{"id": "${matki[i].id}",';
                        jsonData += '"data": "${matki[i].data}",';
                        jsonData += '"zrodlo": "${matki[i].zrodlo}",';
                        jsonData += '"rasa": "${matki[i].rasa}",';
                        jsonData += '"linia": "${matki[i].linia}",';
                        jsonData += '"znak": "${matki[i].znak}",';
                        jsonData += '"napis": "${matki[i].napis}",';
                        jsonData += '"uwagi": "${matki[i].uwagi}",';
                        jsonData += '"pasieka": ${matki[i].pasieka},';
                        jsonData += '"ul": ${matki[i].ul},';
                        jsonData += '"dataStraty": "${matki[i].dataStraty}",';
                        jsonData += '"a": "${matki[i].a}",';
                        jsonData += '"b": "${matki[i].b}",';
                        jsonData += '"c": "${matki[i].c}",';
                        jsonData += '"arch": ${matki[i].arch}}';
                        i++;
                        if (matki.length > i) jsonData += ',';
                      }
                      jsonData +=
                          '],"total":${matki.length}, "tabela":"${mem[0].kod.substring(0, 4)}_matki"}'; //pierwsze cztery cyfry kodu XXXX_ramka

                      //print(jsonData);
                      _isInternet().then(
                        (inter) {
                          if (inter) {
                            wyslijBackupMatki(jsonData); //jsonData
                          } else {
                            //print('braaaaaak internetu');
                            //komunikat na dole ekranu
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    AppLocalizations.of(context)!.unablaToSend),
                              ),
                            );
                            // _showAlertOK(
                            //     context,
                            //     AppLocalizations.of(context)!.alert,
                            //     AppLocalizations.of(context)!.noInternet);
                          }
                        },
                      );
                    } //jeśli sa ramki do archiwizacji
                  });

                  

                } //id ifa - czy jest kod?
              } //ustawienie przłącznika eksportu danych
            } //od jezeli jest tabela dodatki1 i a==true
          });

          //pobranie notatek
          Provider.of<Notes>(context, listen: false).fetchAndSetNotatki();

          //pobranie danych o pogodzie dla pasieki
          Provider.of<Weathers>(context, listen: false)
              .fetchAndSetWeathers().then((_) {
                 final pogodaData = Provider.of<Weathers>(context, listen: false);
                  pogoda = pogodaData.items.where((ap) {
                    return ap.id == (globals.pasiekaID.toString());
                  }).toList();
                  // setState(() {
                  //jezeli są jakieś dane dla pasieki
                  if (pogoda != null && pogoda!.isNotEmpty) {
                    //print('apiarys_screen: temp pierwsza pobrana z bazy= ${pogoda![0].temp}');
                    if((pogoda![0].temp).isNotEmpty) globals.aktualTemp = double.parse(pogoda![0].temp);
                    switch (pogoda![0].units) {
                      case 1:
                        //units = 'metric';
                        stopnie = "\u2103";
                        break;
                      case 2:
                        //units = 'standard';
                        stopnie = "\u212A";
                        break;
                      case 3:
                       // units = 'imperial';
                        stopnie = "\u2109";
                        break;
                      default:
                        //units = 'metric';
                        stopnie = "\u2103";
                    }
                    globals.stopnie = stopnie;
                  } else {
                    //print('Brak danych pogodowych dla pasieki');
                    stopnie = "\u2103"; // Default to Celsius
                    globals.stopnie = stopnie;
                  }
                
              });

          setState(() {
            _isLoading = false; //zatrzymanie wskaznika ładowania danych
          });
//   }); //kasowanie bazy
        }); //od pobrania danych z tabeli memory
      });
    }

    _isInit = false;
    // globals.isInit = false;
    super.didChangeDependencies();
  }

  //sprawdzenie czy jest internet
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

  //obliczanie róznicy miedzy dwoma datami
  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  //pobieranie Id telefonu  - do identyfikacji apki jako uzytkownika
  Future<void> _getId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      globals.deviceId = 'ios_' + iosDeviceInfo.name;
      //.identifierForVendor!; // + '_' + iosDeviceInfo.model; // +'_' + wersja[0] + wersja[1] + wersja[2] + wersja[3]; // + '_' + iosDeviceInfo.model
      //return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      globals.deviceId = 'and_' + androidDeviceInfo.device; //androidId!; // + '_' + androidDeviceInfo.model;
      //wersja[0] + wersja[1] + wersja[2] + wersja[3]; //androidDeviceInfo.model
      //return androidDeviceInfo.androidId; // unique ID on Android
    }
  }

  //wysyłanie backupu ramka
  Future<void> wyslijBackupRamka(String jsonData1) async {
    //String jsonData1
    //print("z funkcji wysyłania");
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v6.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela ramka w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Frames>(context, listen: false)
            .fetchAndSetFramesToArch()
            .then((_) {
          //dla tabeli RAMKI
          final framesAllData = Provider.of<Frames>(context, listen: false);
          final ramki = framesAllData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli ramka');
          //print(ramki.length);
          int i = 0;
          while (ramki.length > i) {
            DBHelper.updateRamkaArch(ramki[i].id); //zapis arch = 1
            i++;
          }
          //komunikat na dole ekranu
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.inspectionDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
       // print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu info
  Future<void> wyslijBackupInfo(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v6.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela ramka w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Infos>(context, listen: false)
            .fetchAndSetInfosToArch()
            .then((_) {
          //dla tabeli RAMKI
          final infoArchData = Provider.of<Infos>(context, listen: false);
          final info = infoArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli info');
          //print(info.length);
          int i = 0;
          while (info.length > i) {
            DBHelper.updateInfoArch(info[i].id); //zapis arch = 1
            i++;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.infoDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //wysyłanie backupu matki
  Future<void> wyslijBackupMatki(String jsonData1) async {
    //String jsonData1
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_backup_v6.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData1, //tabela info w postaci jsona
    );
    //print("response.body:");
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'ok') {
        // _showAlertOK(context, AppLocalizations.of(context)!.success,
        //    AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej
        Provider.of<Queens>(context, listen: false)
            .fetchAndSetQueensToArch()
            .then((_) {
          //dla tabeli Matki
          final matkiArchData = Provider.of<Queens>(context, listen: false);
          final matki = matkiArchData.items;
          //print('ilość potrzebnych wpisów arch = 1 w tabeli matki');
          //print(matki.length);
          int i = 0;
          while (matki.length > i) {
            DBHelper.updateMatkiArch(matki[i].id); //zapis arch = 1
            i++;
          }

//Navigator.pop(context); //wyjscie z wskaźnika wysyłki
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.queenDataSend),
            ),
          );
        });
      } else {
        // _showAlertOK(context, AppLocalizations.of(context)!.alert,
        //    AppLocalizations.of(context)!.errorWhileActivating);
        //print('niepowodzenie - $odpPost["success"]');
      }
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }


  //wysyłanie kodu
  Future<void> wyslijKod(String kod) async {
    final http.Response response = await http.post(
      Uri.parse('https://darys.pl/cbt_hi_kod.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "kod_mobile": kod,
        "deviceId": globals.deviceId,
        "wersja": wersja,
        "jezyk": globals.jezyk,
      }),
    );
    //print('$kod ${globals.deviceId} $wersja ${globals.jezyk}');
    //print(response.body);
    if (response.statusCode >= 200 && response.statusCode <= 400) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] == 'email') {
        _showAlertOK(context, AppLocalizations.of(context)!.alert,
            AppLocalizations.of(context)!.activationCodeWillBeSent);
        // print('wysłano e-mail');
      } else if (odpPost['success'] == 'brak_email') {
        _showAlertOK(context, AppLocalizations.of(context)!.alert,
            AppLocalizations.of(context)!.sendAgain);
        // print('wysłano e-mail ale nie zapisał się');
      } else if (odpPost['success'] == 'ok') {
        _showAlertOK(context, AppLocalizations.of(context)!.success,
            AppLocalizations.of(context)!.willBeActiveUntil + odpPost['be_do']);
        //zapis do bazy lokalnej z bazy www
        DBHelper.deleteTable('memory').then((_) {
          //kasowanie tabeli bo będzie nowy wpis
          Memory.insertMemory(
            odpPost['be_id'], //id
            odpPost['be_email'],
            //ponizej wstawone wartosci deviceId i wersja a apki, bo www nie zdązy ich zapisać i nie ma ich po pobraniu
            //globals.deviceId, //
            odpPost['be_dev'], //deviceId
            //wersja, //
            odpPost['be_wersja'], //wersja apki
            odpPost['be_kod'], //kod
            odpPost['be_key'], //accessKey
            odpPost['be_od'], //data od
            odpPost['be_do'], // do data
            '', //globals.memJezyk, //memjezyk - język ustawiony w Ustawienia/Język apki
            '', //zapas
            '', //zapas
          );
        });
      } else {
        _showAlertOK(context, AppLocalizations.of(context)!.alert,
            AppLocalizations.of(context)!.errorWhileActivating);
        // print('brak danych dla tej apki');
      }

      //Navigator.of(context).pushNamed(OrderScreen.routeName);
      //}
    } else {
      throw Exception('Failed to create OdpPost.');
    }
  }

  //okno dialogowe - Aktywuj lub Anuluj
  void _showAlert(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              DBHelper.updateActivate(globals.deviceId, '').then((_) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    ApiarysScreen.routeName,
                    ModalRoute.withName(ApiarysScreen
                        .routeName)); //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
              }); //'' do memory "od" - kasowanie
            },
            child: Text(AppLocalizations.of(context)!.activate),
          ),
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

  //dodawanie ula lub matki
  void _showAlertAdd(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        //title: Text(AppLocalizations.of(context)!.selectEntryType),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
//dodawanie ula      
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(AddHiveScreen.routeName);               
            }, child: Text((AppLocalizations.of(context)!.aDdHive),style: TextStyle(fontSize: 18)) //zasoby
            ), 
          
          
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(AddQueenScreen.routeName);  
            }, child: Text((AppLocalizations.of(context)!.aDdQueen),style: TextStyle(fontSize: 18)) //zasoby +
            ), 

            TextButton(onPressed: (){
              Navigator.of(context).pop();
               Navigator.of(context).pushNamed(
                  QueenScreen.routeName, 
                    arguments: {'idInfo': '',
                              'kategoria': 'queen', 
                              'parametr': AppLocalizations.of(context)!.queenIs, //Start
                              'wartosc': AppLocalizations.of(context)!.freed, //wartość domyślna
                              'idPasieki': 0, 
                              'idUla':0,}, //przy wejściu z Apiary do ZARZADZANIA MATKAMI numer ula jest zerowany
                  );
            }, child: Text((AppLocalizations.of(context)!.aDdingQueen),style: TextStyle(fontSize: 18)) //zasoby +
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

  void _showAlertOK(BuildContext context, String nazwa, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nazwa),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              //_setPrefers('reload',
              //    'true'); //dane nieaktualne - trzeba przeładować dane z serwera
              Navigator.of(context).pushNamedAndRemoveUntil(
                  ApiarysScreen.routeName,
                  ModalRoute.withName(ApiarysScreen
                      .routeName)); //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
            },
            child: Text('OK'),
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

  //wywoływanie przeglądarki stron www
  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      side: BorderSide(color: Colors.grey),
        backgroundColor:Theme.of(context).primaryColor, //Color.fromARGB(255, 233, 140, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)));

    final apiarysData = Provider.of<Apiarys>(context);
    final apiarys = apiarysData.items; //showFavs ? productsData.favoriteItems :
    //getApiarys().then((_) {
    //print('start_screen - pobranie liczby pasiek z widzetu głównego');
    // print(apiarys.length);
    // });
    // print('obliczenia!!!!!!!!!!!!!!!!!!!');
    // int dziel = (9 / 2).toInt();
    // int mod = 9 % 2;

    // print(dziel);
    // print(mod);

    // for (var i = 0; i < apiarys.length; i++) {
    //   print(
    //       '${apiarys[i].id},${apiarys[i].pasiekaNr},${apiarys[i].ileUli},${apiarys[i].przeglad},${apiarys[i].ikona},${apiarys[i].opis}');
    //   print('^^^^^');
    // }
    final memData1 = Provider.of<Memory>(context, listen: false);
    final mem1 = memData1.items;

    //pobranie wszystkich notatek
    final notatkiData = Provider.of<Notes>(context);
    List<Note> notatki = notatkiData.items.where((no) {
      return no.priorytet.contains('true');
    }).toList();
    //odwrotne sortowanie
    final notatkiOdwrotnie = notatki.reversed.toList();

    //print('widzet główny - globals.key = ${globals.key}');

    // Locale myLocale = Localizations.localeOf(context);
    //print(myLocale);

    List<String> gridItems = [
      'Notes',
      AppLocalizations.of(context)!.hArvests,
      AppLocalizations.of(context)!.pUrchase,
      AppLocalizations.of(context)!.sAle,
    ];

    //double heightScreen = MediaQuery.of(context).size.height;
    // print('wysokość ekranu');
    // print(heightScreen);

    final Uri toLaunchPl = Uri(
        scheme: 'https', host: 'www.heymaya.eu', path: '/index.php/przewodnik');
    final Uri toLaunchEn =
        Uri(scheme: 'https', host: 'www.heymaya.eu', path: '/index.php/guide');

// print('globals.deviceId = ${globals.deviceId}');
// print('globals.key = ${globals.key}');
 //print('temperatura = ${globals.aktualTemp}');

    return Scaffold(
      //localizationsDelegates: AppLocalizations.localizationsDelegates,
      //  supportedLocales: AppLocalizations.supportedLocales,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        title: const Text(
          'Hey Maya',
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        backgroundColor: Color.fromARGB(
            255, 255, 255, 255), //Color.fromARGB(255, 233, 140, 0),
        actions: <Widget>[
//dodawanie ula (z pasieką) 
          if(globals.key != '')
            IconButton(
              icon: Icon(Icons.add, color: Color.fromARGB(255, 0, 0, 0)),
              onPressed: () =>
                apiarys.length == 0 
                  ? Navigator.of(context).pushNamed(AddHiveScreen.routeName)
                  : _showAlertAdd(context),
            ),
//pomoc w przeglądarce
          IconButton(
            icon: Icon(Icons.help_rounded, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () => globals.jezyk == 'pl_PL'
                ? _isInternet().then((inter) {
                    if (inter) {
                      _launchInBrowser(toLaunchPl);
                      //'https://www.cobytu.com/index.php?d=polityka&mobile=1');
                      // Navigator.of(context).pushNamed(LanguagesScreen.routeName);
                    } else {
                      print('braaaaaak internetu');
                      _showAlertOK(context, AppLocalizations.of(context)!.alert,
                          AppLocalizations.of(context)!.noInternet);
                    }
                  })
                //   },
                // child: Card(
                //   child: ListTile(
                //     leading: Icon(Icons.security),
                //     title: Text(allTranslations.text('L_POLITYKA')),
                //     trailing: Icon(Icons.chevron_right),
                //   ),
                // ),
                // ),

                : _isInternet().then((inter) {
                    if (inter) { //inter != null && 
                      _launchInBrowser(toLaunchEn);
                    } else {
                      print('braaaaaak internetu');
                      _showAlertOK(context, AppLocalizations.of(context)!.alert,
                          AppLocalizations.of(context)!.noInternet);
                    }
                  }),
          ),
//ustawienia
          if(globals.key != '') 
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Navigator.of(context)
                  .pushNamed(SettingsScreen.routeName), //arguments: {
              //   'ul': globals.ulID,
              //   'data': wybranaData,
              // }),
            )
        ],
         bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300], // kolor linii
            height: 1.0,
          ),
        ),
      ),

      body: _isLoading //jezeli dane są ładowane
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.black)), //kółko ładowania danych
            )
          : globals.key == '' //jezeli nie ma accessKey to trzeba wysłać kod
              ? Center(
                  child: Column(children: <Widget>[
                    Container(
                        padding: const EdgeInsets.all(20),
                        child: mem1.isEmpty
                            ? Text(
                                (AppLocalizations.of(context)!.enterYourActivationCode),
                                style: TextStyle(
                                  fontSize: 15,
                                  //color: Colors.grey,
                                ),
                              )
                            : Text(
                                (AppLocalizations.of(context)!.enterYourActivationCode), //jezeli jest tylko bezpłatnie
                                // (AppLocalizations.of(context)!
                                //     .activationCodeAfterPaying), //jezeli będzie wersja płatna
                                style: TextStyle(
                                  fontSize: 15,
                                  //color: Colors.grey,
                                ),
                              )),
//wprowadzenie kodu lub e-maila
                    Form(
                      key: _formKey2,
                      child: Container(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        child: TextFormField(
                            //initialValue: globals.numer,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: (AppLocalizations.of(context)!.codeOrEmail),
                              labelStyle: TextStyle(color: Colors.black),
                              //hintText: allTranslations
                              //.text('L_WPISZ_KOD_POLACZ'),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return (AppLocalizations.of(context)!.enterCodeOrEmail);
                              }
                              globals.kod = value;
                              return null;
                            }),
                      ),
                    ),
      //Przyciski
                    Container(
                      height: 90,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          //Aktywuj
                          MaterialButton(
                            height: 50,
                            shape: const StadiumBorder(
                              side: const BorderSide(color: Color.fromARGB(255, 162, 103, 0)),
                              ),
                            onPressed: () {
                              if (_formKey2.currentState!.validate()) {
                                //jezeli formularz wypełniony poprawnie
                                _isInternet().then(
                                  (inter) {
                                    if (inter) {
                                      wyslijKod(globals.kod);
                                    } else {
                                      print('braaaaaak internetu');
                                      _showAlertOK(
                                          context,
                                          AppLocalizations.of(context)!.alert,
                                          AppLocalizations.of(context)!
                                              .noInternet);
                                    }
                                  },
                                );
                              }
                              ;
                              //Navigator.of(context).pushNamed(OrderScreen.routeName);
                            },
                            child: Text('   ' +
                                (AppLocalizations.of(context)!.activate) +
                                '   '), //AKTYWUJ===========================
                            color: Theme.of(context).primaryColor,
                            textColor: Colors.black,
                            disabledColor: Colors.grey,
                            disabledTextColor: Colors.white,
                          ),
                          SizedBox(width: 10),
        //Bez aktywacji
                          if (mem1.isNotEmpty)
                            MaterialButton(
                              height: 50,
                              shape: const StadiumBorder(),
                              onPressed: () {
                                DBHelper.updateActivate(globals.deviceId,
                                    'bez aktywacji'); //"bez aktywacji" do memory "od"
                                Navigator.of(context)
                                    .pushNamed(ApiarysScreen.routeName);
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!.noActivation) +
                                  '   '), //BEZ AKTYWACJI =========================
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.white,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),
                        ],
                      ),
                    ),

                    //Subskrypcja wyłaczona ze wzgledu na politykę Picovoice
                    // //Subskrybuj
                    // if (aktywnosc < 30 && aktywnosc >= 0 && Platform.isIOS)
                    //   Container(
                    //     height: 90,
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: <Widget>[
                    //         MaterialButton(
                    //           shape: const StadiumBorder(),
                    //           onPressed: () {
                    //             Navigator.of(context)
                    //                 .pushNamed(SubsScreen.routeName);
                    //           },
                    //           child: Text('   ' +
                    //               (AppLocalizations.of(context)!.subscription) +
                    //               '   '), //SUBSKRYBUJ ========================
                    //           color: Theme.of(context).primaryColor,
                    //           textColor: Colors.white,
                    //           disabledColor: Colors.grey,
                    //           disabledTextColor: Colors.white,
                    //         ),
                    //       ],
                    //     ),
                    //   ),

//Powrót bez zmian
                    if (aktywnosc < 30 &&
                        aktywnosc >= 0 &&
                        globals.keyMemory != '')
                      Container(
                        height: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            MaterialButton(
                              height: 50,
                              shape: const StadiumBorder(),
                              onPressed: () {
                                DBHelper.updateActivate(globals.deviceId,'${globals.keyMemory}'); //powtórne zapisanie key
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    ApiarysScreen.routeName,
                                    ModalRoute.withName(ApiarysScreen.routeName)); //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!
                                      .powrotBezZmian) +
                                  '   '), //Bez zmian========================
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.white,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                  ]),
                )

//jezeli jest accessKey
              : apiarys.length == 0
                  ? SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.only(
                                top: 30, left: 20, right: 20),
                            child: RichText(
                              text: TextSpan(
                                  style: TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: (AppLocalizations.of(context)!
                                          .noApiaries), //brak pasiek
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text: (AppLocalizations.of(context)!
                                          .introA),
                                      style: TextStyle(
                                          fontSize: 16,
                                          //fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),
                                    // TextSpan(
                                    //   text:(AppLocalizations.of(context)!.introB),
                                    //   style: TextStyle(
                                    //       fontSize: 16,
                                    //       //fontWeight: FontWeight.bold,
                                    //       color: Color.fromARGB(255, 0, 0, 0)),
                                    // ),
                                    // TextSpan(
                                    //   text: (AppLocalizations.of(context)!.introC),
                                    //   style: TextStyle(
                                    //       fontSize: 16,
                                    //       //fontWeight: FontWeight.bold,
                                    //       color: Color.fromARGB(255, 0, 0, 0)),
                                    // ),
                                  ]),
                            ),

                            // Text(
                            //   AppLocalizations.of(context)!.noApiaries,
                            //   style: TextStyle(
                            //     fontSize: 20,
                            //     color: Colors.grey,
                            //   ),
                            // ),
                          ),
                          const SizedBox(
                            height: 100,
                          ),
                        ],
                      ),
                    )
//jezeli są pasieki
                  : SingleChildScrollView(
                      child: Column(children: <Widget>[
//przyciski Zbiory, Zakupy, Sprzedaz, Notes
                      Container(
                          height:
                              ((MediaQuery.of(context).size.width + 30) / 5) *
                                  2, //połowa szerokości
                          child: Column(children: [
                            Expanded(
                              child: GridView.count(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(15.0),
                                //shrinkWrap: true,
                                crossAxisCount: 2, //ilość kolumn
                                childAspectRatio:
                                    (5 / 2), //proporcje boków kafli
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 10,
                                children: gridItems
                                    .map((data) => InkWell(
                                        onTap: () {
                                          if (data == 'Notes')
                                            Navigator.of(context).pushNamed(
                                                NoteScreen.routeName);

                                          if (data ==
                                              AppLocalizations.of(context)!
                                                  .hArvests)
                                            Navigator.of(context).pushNamed(
                                                HarvestScreen.routeName);

                                          if (data ==
                                              AppLocalizations.of(context)!
                                                  .sAle)
                                            Navigator.of(context).pushNamed(
                                                SaleScreen.routeName);

                                          if (data ==
                                              AppLocalizations.of(context)!
                                                  .pUrchase)
                                            Navigator.of(context).pushNamed(
                                                PurchaseScreen.routeName);

                                          //getGridViewSelectedItem(context, data);
                                        },
                                        splashColor:
                                            Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(15),
                                        child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey,
                                                width: 1, //      
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Color.fromARGB(255, 119, 87, 87)
                                                      .withValues(alpha:0.5),
                                                  spreadRadius: 1,
                                                  blurRadius: 4,
                                                  offset: const Offset(1,
                                                      3), // changes position of shadow
                                                ),
                                              ],
                                              gradient: LinearGradient(
                                                colors: [
                                                  Theme.of(context)
                                                      .primaryColor
                                                      .withValues(alpha:0.7),
                                                  Theme.of(context)
                                                      .primaryColor,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              //color: Theme.of(context).primaryColor,
                                              // borderRadius: BorderRadius.only(
                                              //   topLeft: Radius.circular(20),
                                              //   topRight: Radius.circular(20),
                                              //   bottomLeft: Radius.circular(20),
                                              //   bottomRight: Radius.circular(20),
                                              // ),
                                            ),
                                            //margin:EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                                            //color: Theme.of(context).primaryColor,
                                            child: Center(
                                                child: Text(data,
                                                    style: TextStyle(
                                                        //fontWeight: FontWeight.bold,
                                                        fontSize: 20,
                                                        color: Color.fromARGB(
                                                            255, 0, 0, 0)),
                                                    textAlign:
                                                        TextAlign.center)))))
                                    .toList(),
                              ),
                            ),
                          ])),

//pasieki
                      Container(
                          //height: 170 * ((apiarys.length ~/ 2) + (apiarys.length % 2)),//1  dla 1 i 2 pasiek, 2 dla 3 i 4 pasiek, itd
                          height: 160,
                          child: GridView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(
                                left: 15, right: 15, top: 20, bottom: 15),
                            itemCount: apiarys.length,
                            itemBuilder: (ctx, i) =>
                                ChangeNotifierProvider.value(
                              value: apiarys[i],
                              child: ApiarysItem(),
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              mainAxisExtent: 180, //długośc kafelka
                              maxCrossAxisExtent: 200,
                              childAspectRatio: 7 / 5,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                            ),
                          )),

                      //wiadomosci priorytetowe
                      //SizedBox(height: 10),

          // Container(
          //   child: Text(
          //       'Status: ${globals.status}',
          //       style: const TextStyle(fontSize: 16),
          //     ),
          // ),

//wiadomosci priorytetowe
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        // height: MediaQuery.of(context).size.height - (350 + (MediaQuery.of(context).size.width/2)),//150,
                        height: 135 * notatkiOdwrotnie.length.toDouble(),
                        child: ListView.builder(
                          physics:
                              NeverScrollableScrollPhysics(), //zeby sie nie przewijał
                          itemCount: notatkiOdwrotnie.length,
                          itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                            value: notatkiOdwrotnie[i],
                            child: NotePriorytetItem(),
                          ),
                        ),
                      ),
                      SizedBox(height: 100),
                    ])),
      //=== stopka
      bottomSheet: globals.key == ''// || globals.key == "bez_klucza"
          ? null
          : Container(
              //margin:  EdgeInsets.only(bottom:15),
              height: 100,
              color: Colors.white,
              //width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      // ElevatedButton(
                      //   child: Text('English'),
                      //   onPressed: () => _changeLanguage(Locale('en')),
                      // ),
                      // ElevatedButton(
                      //   child: Text('Polski'),
                      //   onPressed: () => _changeLanguage(Locale('pl')),
                      // ),
                      const SizedBox(
                        width: 9,
                      ),
                      if(globals.key != '' && globals.key != "bez_klucza")//jezeli jest accessKey lub testowanie
                        SizedBox(
                          width: 220,
                          height: 50,
                          child: ElevatedButton(
                            style: buttonStyle,
                            onPressed: () {
                              globals.key != '' && globals.key != "bez_klucza"//jezeli jest accessKey lub testowanie
                                  ? null
                                  : {
                                      //_isInit = true,
                                      Navigator.of(context).pushNamed(
                                        VoiceScreen.routeName,
                                      ),
                                    };
                            },
                            child: Text(
                                AppLocalizations.of(context)!.voiceControl,
                                style: TextStyle(
                                    height: 1.0,
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 0, 0, 0))),
                          )),
                      const SizedBox(
                        width: 10,
                      ),
    // Przycisk NFC
                      SizedBox(
                          width: 100,
                          height: 50,
                          child: ElevatedButton(
                            style: buttonStyle,
                            onPressed: () {
                              // globals.key == '' || globals.key == "bez_klucza"
                              //     ? null
                              //     : 
                                  NfcHelper.handleNfcScan(context);
                            },
                            child: Text(
                                AppLocalizations.of(context)!.nfcButton,
                                style: TextStyle(
                                    height: 1.0,
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 0, 0, 0))),
                          )),
                      const SizedBox(
                        width: 9,
                      ), //interpolacja ciągu znaków
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
