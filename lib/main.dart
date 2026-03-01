import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hi_bees/models/harvest.dart';
import 'package:hi_bees/screens/harvest_edit_screen.dart';
import 'package:provider/provider.dart'; //zarejestrowanie dostawcy
import 'package:flutter_localizations/flutter_localizations.dart';
//import 'package:in_app_purchase/in_app_purchase.dart'; //subskrypcja
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart'; //do formatowania daty - dzień tygodnia
import './globals.dart' as globals;
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
import './screens/apiarys_map_screen.dart';
import './screens/apiarys_all_map_screen.dart';
import './screens/notification_settings_screen.dart';
import './screens/move_hive_screen.dart';
import './helpers/notification_helper.dart';

//import './screens/languages_screen.dart';

import './models/apiarys.dart';
import './models/frames.dart'; //zaimportowanie klasy dostawcy
import './models/hives.dart';
import './models/note.dart';
import 'models/queen.dart';
import './models/sale.dart';
import './models/purchase.dart';
import './models/infos.dart';
import './models/photo.dart';
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

  // Inicjalizacja powiadomień lokalnych - z zabezpieczeniem przed zawieszeniem
  try {
    await NotificationHelper.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        // Timeout - aplikacja startuje bez powiadomień
      },
    );
  } catch (_) {
    // Błąd inicjalizacji powiadomień - aplikacja startuje normalnie
  }

  // then start the application
  return runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // Notifier do zmiany języka z poziomu ustawień
  static final ValueNotifier<Locale?> localeOverride = ValueNotifier<Locale?>(null);

  /// Mapowanie kodu języka na Locale
  static const Map<String, Locale> supportedLocaleMap = {
    'system': Locale('en', 'US'), // placeholder - nadpisywany przez system
    'pl': Locale('pl', 'PL'),
    'en': Locale('en', 'US'),
    'de': Locale('de', 'DE'),
    'fr': Locale('fr', 'FR'),
    'es': Locale('es', 'ES'),
    'pt': Locale('pt', 'PT'),
    'it': Locale('it', 'IT'),
  };

  /// Ustawia locale nadpisujące język systemowy
  static void setLocale(String langCode) {
    if (langCode == 'system') {
      globals.memJezyk = 'system';
      localeOverride.value = null; // null = użyj języka systemowego
      // globals.jezyk zaktualizuje się po rebuild w localeListResolutionCallback
    } else {
      globals.memJezyk = langCode;
      final locale = supportedLocaleMap[langCode];
      localeOverride.value = locale;
      if (locale != null) {
        globals.jezyk = locale.toString(); // natychmiastowa aktualizacja
      }
    }
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Instancje providerów tworzone raz - nie są tracone przy rebuild (np. zmiana języka)
  final _frames = Frames();
  final _hives = Hives();
  final _apiarys = Apiarys();
  final _infos = Infos();
  final _memory = Memory();
  final _dodatki1 = Dodatki1();
  final _dodatki2 = Dodatki2();
  final _harvests = Harvests();
  final _weathers = Weathers();
  final _sales = Sales();
  final _purchases = Purchases();
  final _notes = Notes();
  final _queens = Queens();
  final _photos = Photos();

  @override
  void initState() {
    super.initState();
    MyApp.localeOverride.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    MyApp.localeOverride.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  // główna konstrukcja aplikacji
  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: _frames,
        ),
        ChangeNotifierProvider.value(
          value: _hives,
        ),
        ChangeNotifierProvider.value(
          value: _apiarys,
        ),
        ChangeNotifierProvider.value(
          value: _infos,
        ),
        ChangeNotifierProvider.value(
          value: _memory,
        ),
        ChangeNotifierProvider.value(
          value: _dodatki1,
        ),
        ChangeNotifierProvider.value(
          value: _dodatki2,
        ),
        ChangeNotifierProvider.value(
          value: _harvests,
        ),
        ChangeNotifierProvider.value(
          value: _weathers,
        ),
        ChangeNotifierProvider.value(
          value: _sales,
        ),
        ChangeNotifierProvider.value(
          value: _purchases,
        ),
        ChangeNotifierProvider.value(
          value: _notes,
        ),
        ChangeNotifierProvider.value(
          value: _queens,
        ),
        ChangeNotifierProvider.value(
          value: _photos,
        ),

      ],
      child: MaterialApp(
         navigatorKey: NotificationHelper.navigatorKey,
         localizationsDelegates: [
          AppLocalizations.delegate,
           GlobalMaterialLocalizations.delegate,
           GlobalWidgetsLocalizations.delegate,
           GlobalCupertinoLocalizations.delegate,
           //AppLocalizations.localizationsDelegates,
            
         ],
         locale: MyApp.localeOverride.value, // null = język systemowy, Locale = nadpisany
         supportedLocales: [
           const Locale('en', 'US'),
           const Locale('pl', 'PL'),
           const Locale('de', 'DE'),
           const Locale('fr', 'FR'),
           const Locale('es', 'ES'),
           const Locale('pt', 'PT'),
           const Locale('it', 'IT'),
         ],

         //zeby domyślnie ustawić "en" jesli wybrano inny jezyk niz polski
         localeListResolutionCallback: (allLocales, supportedLocales) {
          final locale = allLocales?.first.languageCode;
          if (locale == 'pl') return const Locale('pl', 'PL');
          if (locale == 'de') return const Locale('de', 'DE');
          if (locale == 'fr') return const Locale('fr', 'FR');
          if (locale == 'es') return const Locale('es', 'ES');
          if (locale == 'pt') return const Locale('pt', 'PT');
          if (locale == 'it') return const Locale('it', 'IT');
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
          ApiaryMapScreen.routeName: (ctx) => ApiaryMapScreen(),
          ApiarysAllMapScreen.routeName: (ctx) => ApiarysAllMapScreen(),
          NotificationSettingsScreen.routeName: (ctx) => NotificationSettingsScreen(),
          MoveHiveScreen.routeName: (ctx) => MoveHiveScreen(),
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

