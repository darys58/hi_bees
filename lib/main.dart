import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; //zarejestrowanie dostawcy
//import 'package:flutter_localizations/flutter_localizations.dart';
//import 'package:in_app_purchase/in_app_purchase.dart'; //subskrypcja

import './screens/frames_screen.dart';
import './screens/hives_screen.dart';
import './screens/apiarys_screen.dart';
import './screens/voice_screen.dart';
import './screens/infos_screen.dart';
import './screens/frames_detail_screen.dart';
import './screens/subscription_screen.dart';
import './models/apiarys.dart';
import './models/frames.dart'; //zaimportowanie klasy dostawcy
import './models/hives.dart';
import './models/infos.dart';
import './models/memory.dart';

//import 'screens/languages.dart';
//import 'all_translations.dart';

void main() async {
  HttpOverrides.global =
      MyHttpOverrides(); //obejście certyfikatu na stronie www
  WidgetsFlutterBinding.ensureInitialized();
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
      ],
      child: MaterialApp(
        ///title: 'Hi Bees',
        theme: ThemeData(
          //definiowanie danych decydujących o wyglądzie (kolory, style, czcionki)
          //appBarTheme: AppBarTheme(color: Color.fromRGBO(55, 125, 255, 1),),
          primaryColor: Color.fromARGB(255, 233, 140, 0), //kolor podstawowy
          primaryColorLight: const Color.fromRGBO(255, 118, 122, 1),
          primaryColorDark:
              const Color.fromRGBO(160, 0, 38, 1), //kolor wyrózniający
          canvasColor: const Color.fromRGBO(
              255, 255, 255, 1), //kolor płótna 255, 254, 229, 1
          fontFamily: 'Raleway', //domyślna czcionka
          textTheme: ThemeData.light().textTheme.copyWith(
                //domyślny motyw tektu
                headline1: const TextStyle(
                  color: Color.fromRGBO(20, 51, 51, 1),
                ),
                headline2: const TextStyle(
                  color: Color.fromRGBO(20, 51, 51, 1),
                ),
                headline6: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'RobotoCondensed',
                  fontWeight: FontWeight.bold,
                ),
              ),
          colorScheme: ColorScheme.fromSwatch().copyWith(
              secondary: Color.fromRGBO(0, 0, 0, 1)), //po nowemu akcentColor
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
          VoiceScreen.routeName: (ctx) => VoiceScreen(),
          InfoScreen.routeName: (ctx) => InfoScreen(),
          SubsScreen.routeName: (ctx) => SubsScreen(),
          FramesDetailScreen.routeName: (ctx) => FramesDetailScreen(),
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
