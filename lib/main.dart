import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hi_bees/models/harvest.dart';
import 'package:hi_bees/screens/harvest_edit_screen.dart';
import 'package:provider/provider.dart'; //zarejestrowanie dostawcy
import 'package:flutter_localizations/flutter_localizations.dart';
//import 'package:in_app_purchase/in_app_purchase.dart'; //subskrypcja
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart'; //do formatowania daty - dzień tygodnia
import './screens/frames_screen.dart';
import './screens/hives_screen.dart';
import './screens/apiarys_screen.dart';
import './screens/voice_screen.dart'; //blokowanie działania Picovoce  - usunięto: picovoice_flutter: ^3.0.1
import './screens/infos_screen.dart';
import './screens/frames_detail_screen.dart';
//import './screens/subscription_screen.dart';
import './screens/settings_screen.dart';
import './screens/import_screen.dart';
import './screens/about_screen.dart';
import './screens/activation_screen.dart';
import './screens/frame_edit_screen.dart';
import './screens/frame_move_screen.dart';
import './screens/frame_edit_screen2.dart';
import './screens/harvest_screen.dart';
import './screens/parametr_screen.dart';
import './screens/apiarys_weather_edit_screen.dart';
import './screens/infos_edit_screen.dart';
import './screens/parametr_edit_screen.dart';
import './screens/parametry_ula_screen.dart';
import './screens/sale_screen.dart';
import './screens/sale_edit_screen.dart';
import './screens/purchase_screen.dart';
import './screens/purchase_edit_screen.dart';
import './screens/note_screen.dart';
import './screens/note_edit_screen.dart';
import './screens/queens_screen.dart';
import './screens/queen_edit_screen.dart';
import './screens/queen_history_screen.dart';
import './screens/add_hive_screen.dart';
import './screens/add_queen_screen.dart';
import './screens/apiary_weather_5days.dart';
import './screens/raport_screen.dart';
import './screens/raport_color_screen.dart';
import './screens/raport2_screen.dart';
import './screens/calculator_screen.dart';
import './screens/syrup_calculator_screen.dart';
import './screens/syrup21_calculator_screen.dart';
import './screens/syrup11_calculator_screen.dart';
import './screens/cake_calculator_screen.dart';
import './screens/summary_screen.dart';
import './screens/nfc_settings_screen.dart';

//import './screens/languages_screen.dart';

import './models/apiarys.dart';
import './models/frames.dart'; //zaimportowanie klasy dostawcy
import './models/hives.dart';
import './models/note.dart';
import 'models/queen.dart';
import './models/sale.dart';
import './models/purchase.dart';
import './models/infos.dart';
import './models/memory.dart';
import './models/dodatki1.dart';
import './models/dodatki2.dart';
import './models/weathers.dart';

//import 'screens/languages.dart';
//import 'all_translations.dart';

void main() async {
  HttpOverrides.global =
      MyHttpOverrides(); //obejście certyfikatu na stronie www
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting;
  // Initializes the translation module
//    await allTranslations.init();
  // then start the application
  
  return runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
  @override
  void initState() {
    super.initState();
  }

  // główna konstrukcja aplikacji
  @override
  Widget build(BuildContext context) {
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Frames(), //dla Frames
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Hives(), //dla Hives
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Apiarys(), //dla Hives
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Infos(), //dla Hives
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Memory(), //dla Hives
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Dodatki1(), //dla Hives
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Dodatki2(), //dla Hives
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Harvests(), //dla Hives
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Weathers(), //dla Hives
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Sales(), //dla Hives
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Purchases(), //dla Hives
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Notes(), //dla Hives
        ),
        ChangeNotifierProvider.value(
          //zarejestrowanie dostawcy danych (bez kontekstu)
          value: Queens(), //dla Hives
        ),
        
      ],
      child: MaterialApp(
         localizationsDelegates: [
          AppLocalizations.delegate,
           GlobalMaterialLocalizations.delegate,
           GlobalWidgetsLocalizations.delegate,
           GlobalCupertinoLocalizations.delegate,
           //AppLocalizations.localizationsDelegates,
            
         ],
         //locale: Locale('pl','PL'),
         supportedLocales: [
           const Locale('en', 'US'),
           const Locale('pl', 'PL'),
         ],

         //zeby domyślnie ustawić "en" jesli wybrano inny jezyk niz polski
         localeListResolutionCallback: (allLocales, supportedLocales) {
          final locale = allLocales?.first.languageCode;
          if (locale == 'pl') {
            return const Locale('pl', 'PL');
          }
          // The default locale
          return const Locale('en', 'US');
        },

        ///title: 'Hi Bees',
        theme: ThemeData(
          //definiowanie danych decydujących o wyglądzie (kolory, style, czcionki)
          //appBarTheme: AppBarTheme(color: Color.fromRGBO(55, 125, 255, 1),),
          scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
          dialogBackgroundColor: const Color(0xFFFFFFFF),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0, // ⬅️ KLUCZOWE przy przewijaniu!
            surfaceTintColor: Colors.transparent, // ⬅️ zapobiega efektowi "szarości"
            shadowColor: Colors.transparent,
            foregroundColor: Colors.black,
          ),
          
          listTileTheme: ListTileThemeData(
            tileColor: Color.fromARGB(255, 255, 255, 255), // Ustawienie koloru tła dla elementów listy
          ),
          primaryColor: Color.fromARGB(255, 255, 183, 75), //kolor podstawowy
          //primaryColorLight: const Color.fromRGBO(255, 118, 122, 1),
          //primaryColorDark: const Color.fromRGBO(160, 0, 38, 1), //kolor wyrózniający
          canvasColor: Color.fromARGB(255, 255, 255, 255), //kolor płótna 255, 254, 229, 1
          //fontFamily: 'Raleway', //domyślna czcionka
          // textTheme: ThemeData.light().textTheme.copyWith(
          //       //domyślny motyw tektu
          //       headline1: const TextStyle(
          //         color: Color.fromRGBO(20, 51, 51, 1),
          //       ),
          //       headline2: const TextStyle(
          //         color: Color.fromRGBO(20, 51, 51, 1),
          //       ),
          //       headline6: const TextStyle(
          //         fontSize: 20,
          //         fontFamily: 'RobotoCondensed',
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange
          ), //po nowemu akcentColor
          // colorScheme: ColorScheme.fromSwatch().copyWith(
          //     secondary: Color.fromRGBO(0, 0, 0, 1)), //po nowemu akcentColor
        ),

        //home: CategoriesScreen(), //MyHomePage(), //ekran startowy apki
        initialRoute:
            '/', //default is '/'  - dodatkowe określenie domyśnej trasy (inicjującej aplikację)
        routes: {
          //tabela tras (kurs 161)
          //rejestrowanie trasy/drogi do poszczególnych ekranów
          '/': (ctx) => ApiarysScreen(), //zastępuje home: (kurs 162)
          FramesScreen.routeName: (ctx) => FramesScreen(),
          HivesScreen.routeName: (ctx) => HivesScreen(),
          VoiceScreen.routeName: (ctx) => VoiceScreen(), //blokowanie działania Picovoce
          InfoScreen.routeName: (ctx) => InfoScreen(),
          // SubsScreen.routeName: (ctx) => SubsScreen(), //blokowanie subskrypcji bo błedy kompilacji androida
          FramesDetailScreen.routeName: (ctx) => FramesDetailScreen(),
          SettingsScreen.routeName: (ctx) => SettingsScreen(),
          ImportScreen.routeName: (ctx) => ImportScreen(),
          AboutScreen.routeName: (ctx) => AboutScreen(),
          ActivationScreen.routeName: (ctx) => ActivationScreen(),
          FrameEditScreen.routeName: (ctx) => FrameEditScreen(),
          FrameMoveScreen.routeName: (ctx) => FrameMoveScreen(),
          FrameEditScreen2.routeName: (ctx) => FrameEditScreen2(),
          HarvestScreen.routeName:(ctx) => HarvestScreen(),
          HarvestEditScreen.routeName: (ctx) => HarvestEditScreen(),
          ParametrScreen.routeName: (ctx) => ParametrScreen(),
          WeatherEditScreen.routeName: (ctx) => WeatherEditScreen(),
          InfosEditScreen.routeName: (ctx) => InfosEditScreen(),
          ParametrEditScreen.routeName: (ctx) => ParametrEditScreen(),
          ParametryUlaScreen.routeName: (ctx) => ParametryUlaScreen(),
          SaleScreen.routeName: (ctx) => SaleScreen(),
          SaleEditScreen.routeName: (ctx) => SaleEditScreen(),
          PurchaseScreen.routeName: (ctx) => PurchaseScreen(),
          PurchaseEditScreen.routeName: (ctx) => PurchaseEditScreen(),
          NoteScreen.routeName: (ctx) => NoteScreen(),
          NoteEditScreen.routeName: (ctx) => NoteEditScreen(),
          QueenScreen.routeName: (ctx) => QueenScreen(),
          QueenEditScreen.routeName: (ctx) => QueenEditScreen(),
          QueenHistoryScreen.routeName: (ctx) => QueenHistoryScreen(),
          AddHiveScreen.routeName: (ctx) => AddHiveScreen(),
          AddQueenScreen.routeName: (ctx) => AddQueenScreen(),
          Weather5DaysScreen.routeName: (ctx) => Weather5DaysScreen(),
          RaportScreen.routeName: (ctx) => RaportScreen(),
          RaportColorScreen.routeName: (ctx) => RaportColorScreen(),
          Raport2Screen.routeName: (ctx) => Raport2Screen(),
          CalculatorScreen.routeName: (ctx) => CalculatorScreen(),
          SyrupCalculatorScreen.routeName: (ctx) => SyrupCalculatorScreen(),
          Syrup21CalculatorScreen.routeName: (ctx) => Syrup21CalculatorScreen(),
          Syrup11CalculatorScreen.routeName: (ctx) => Syrup11CalculatorScreen(),
          CakeCalculatorScreen.routeName: (ctx) => CakeCalculatorScreen(),
          SummaryScreen.routeName: (ctx) => SummaryScreen(),
          NfcSettingsScreen.routeName: (ctx) => NfcSettingsScreen(),
         // LanguagesScreen.routeName: (ctx) => LanguagesScreen(),
          //FiltersScreen.routeName: (ctx) => FiltersScreen(_filters, _setFilters),
        },
        //onGenerateRoute:  - (kure 168) - jezeli brak zdefiniowanej trasy, wyświetla argumenty, dynamiczne trasy
        onUnknownRoute: (settings) {
          //trasa awaryjna jezeli zawiodą wszystkie inne
          return MaterialPageRoute(
            builder: (ctx) => ApiarysScreen(),
          );
        },
      ),
    );
  }
}

//obejście certyfikatu na stronie www
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

