/*

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;
import '../screens/apiarys_screen.dart';
import '../helpers/db_helper.dart';


class LanguagesScreen extends StatefulWidget {
  static const routeName = '/languages'; 

  @override
  _LanguagesScreenState createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  

  @override
  Widget build(BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);
    String jezykSmartfona = myLocale.toString(); 
    
    String jezykApki;
    
    switch(globals.memJezyk) {
      case 'system':  jezykApki = 'Systemowy'; break; 
      case 'pl_PL':  jezykApki = 'Polski'; break; 
      case 'en_US':  jezykApki = 'English'; break; 
      // case 'cs':  jezykApki = 'Čeština'; break; 
      // case 'de':  jezykApki = 'Deutsch'; break; 
      // case 'es':  jezykApki = 'Español'; break; 
      // case 'fr':  jezykApki = 'Français'; break; 
      // case 'ru':  jezykApki = 'Pусский'; break; 
      // case 'sv':  jezykApki = 'Svenska'; break; 
      // case 'ja':  jezykApki = '日本語'; break; 
      // case 'zh':  jezykApki = '中文'; break; 
      default: jezykApki = 'system'; break; 
      
    } 


print('----------------jezykSmartfona = $jezykSmartfona');
print('----------------jezykApki = $jezykApki');
   // final String buttonText = language == 'pl' ? '=> English' : '=> Polski';
    List<String> lang = ['Systemowy','Polski','English']; //,'Čeština','Deutsch','Español','Français','Pусский','Svenska','日本語', '中文'];
    List<String> lang2 = ['Taki jak w smartfonie','polski','angielski'];//,allTranslations.text('L_CS'),allTranslations.text('L_DE'),allTranslations.text('L_ES'),allTranslations.text('L_FR'),allTranslations.text('L_RU'),allTranslations.text('L_SV'),allTranslations.text('L_JA'),allTranslations.text('L_ZH')];
    //var ile = lang.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.cHooseLanguage,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
        backgroundColor: Color.fromARGB(255, 255, 255, 255)
      ),     
      body: 
        SingleChildScrollView(
          child: Column( 
           // mainAxisSize:MainAxisSize.min, 
            //crossAxisAlignment: CrossAxisAlignment.start, 
            //padding: EdgeInsets.all(8.0),
            children: <Widget>[
              RadioListTile(
                activeColor: Colors.black,
                groupValue: jezykApki,
                title: Text(lang[0]),
                subtitle: Text(lang2[0]),
                //secondary: Image.asset('assets/images/PL.png'),
                value: lang[0],
                onChanged: (val) {
                  setState(() {
                    jezykApki = val!;
                    globals.memJezyk = 'system';
                    print('------------ val system - jezykApki = $jezykApki');
                    DBHelper.updateJezyk(globals.deviceId, 'system').then((_) {
                      Navigator.of(context).pushNamedAndRemoveUntil(ApiarysScreen.routeName,ModalRoute.withName(ApiarysScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
                    });
                  });
                },
              ),
              RadioListTile(
                activeColor: Colors.black,
                groupValue: jezykApki,
                title: Text(lang[1]),
                subtitle: Text(lang2[1]),
                secondary: Image.asset('assets/image/PL.png'),
                value: lang[1],
                onChanged: (val) {
                  setState(() {
                    jezykApki = val!;
                    globals.memJezyk = 'pl_PL';
                    print('val polski - jezykApki = ${jezykApki}');
                    DBHelper.updateJezyk(globals.deviceId, 'pl_PL').then((_) {
                      Navigator.of(context).pushNamedAndRemoveUntil(ApiarysScreen.routeName,ModalRoute.withName(ApiarysScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
                    });
                  });
                },
                // onChanged: (val) async{
                //   await val == 'Polski' ? 'pl' : 'en';
                  // await allTranslations.setNewLanguage(val == 'Polski' ? 'pl' : 'en');
                  // setState(() {
                  //   jezykApki = val;
                  //   print('val pl - jezykApki = $jezykApki');
                  //   _setPrefers('reload', 'true');  //konieczne załadowanie danych z serwera 
                  //    Navigator.of(context).pushNamedAndRemoveUntil(MealsScreen.routeName,ModalRoute.withName(MealsScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
        
                  // });
                //},
              ),
              RadioListTile(
                activeColor: Colors.black,
                groupValue: jezykApki,
                title: Text(lang[2]),
                subtitle: Text(lang2[2]),
                secondary: Image.asset('assets/image/EN.png'),
                value: lang[2],
                onChanged: (val) {
                  setState(() {
                    jezykApki = val!;
                    globals.memJezyk = 'en_US';
                    print('val angielski - jezykApki = $jezykApki');
                    DBHelper.updateJezyk(globals.deviceId, 'en_US').then((_) {
                      Navigator.of(context).pushNamedAndRemoveUntil(ApiarysScreen.routeName,ModalRoute.withName(ApiarysScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
                    });
                  });
                },
                //onChanged: (val) {
                  // await allTranslations.setNewLanguage(val == 'English' ? 'en' : 'pl');
                  //  setState(() {
                  //    jezykApki = val!;
                  //   print('val en - _currentValue = $_currentValue');
                  //   _setPrefers('reload', 'true');  //konieczne załadowanie danych z serwera 
                  //    Navigator.of(context).pushNamedAndRemoveUntil(MealsScreen.routeName,ModalRoute.withName(MealsScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
        
                  //  });
                // },
              ),
    /*          RadioListTile(
                activeColor: Colors.black,
                groupValue: _currentValue,
                title: Text(lang[2]),
                subtitle: Text(lang2[2]),
                secondary: Image.asset('assets/images/CS.png'),
                value: lang[2],
                onChanged: (val) async{
                  await allTranslations.setNewLanguage(val == 'Čeština' ? 'cs' : 'en');
                  setState(() {
                    _currentValue = val;
                    print('val _currentValue = $_currentValue');
                    _setPrefers('reload', 'true');  //konieczne załadowanie danych z serwera 
                     Navigator.of(context).pushNamedAndRemoveUntil(MealsScreen.routeName,ModalRoute.withName(MealsScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
        
                  });
                },
              ),
              RadioListTile(
                activeColor: Colors.black,
                groupValue: _currentValue,
                title: Text(lang[3]),
                subtitle: Text(lang2[3]),
                secondary: Image.asset('assets/images/DE.png'),
                value: lang[3],
                onChanged: (val) async{
                  await allTranslations.setNewLanguage(val == 'Deutsch' ? 'de' : 'en');
                  setState(() {
                    _currentValue = val;
                    print('val  _currentValue = $_currentValue');
                    _setPrefers('reload', 'true');  //konieczne załadowanie danych z serwera 
                     Navigator.of(context).pushNamedAndRemoveUntil(MealsScreen.routeName,ModalRoute.withName(MealsScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
        
                  });
                },
              ),
              RadioListTile(
                activeColor: Colors.black,
                groupValue: _currentValue,
                title: Text(lang[4]),
                subtitle: Text(lang2[4]),
                secondary: Image.asset('assets/images/ES.png'),
                value: lang[4],
                onChanged: (val) async{
                  await allTranslations.setNewLanguage(val == 'Español' ? 'es' : 'en');
                  setState(() {
                    _currentValue = val;
                    print('val _currentValue = $_currentValue');
                    _setPrefers('reload', 'true');  //konieczne załadowanie danych z serwera 
                     Navigator.of(context).pushNamedAndRemoveUntil(MealsScreen.routeName,ModalRoute.withName(MealsScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
        
                  });
                },
              ),
              RadioListTile(
                activeColor: Colors.black,
                groupValue: _currentValue,
                title: Text(lang[5]),
                subtitle: Text(lang2[5]),
                secondary: Image.asset('assets/images/FR.png'),
                value: lang[5],
                onChanged: (val) async{
                  await allTranslations.setNewLanguage(val == 'Français' ? 'fr' : 'en');
                  setState(() {
                    _currentValue = val;
                    print('val en - _currentValue = $_currentValue');
                    _setPrefers('reload', 'true');  //konieczne załadowanie danych z serwera 
                     Navigator.of(context).pushNamedAndRemoveUntil(MealsScreen.routeName,ModalRoute.withName(MealsScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
        
                  });
                },
              ),
              RadioListTile(
                activeColor: Colors.black,
                groupValue: _currentValue,
                title: Text(lang[6]),
                subtitle: Text(lang2[6]),
                secondary: Image.asset('assets/images/RU.png'),
                value: lang[6],
                onChanged: (val) async{
                  await allTranslations.setNewLanguage(val == 'Pусский' ? 'ru' : 'en');
                  setState(() {
                    _currentValue = val;
                    print('val en - _currentValue = $_currentValue');
                    _setPrefers('reload', 'true');  //konieczne załadowanie danych z serwera 
                     Navigator.of(context).pushNamedAndRemoveUntil(MealsScreen.routeName,ModalRoute.withName(MealsScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
        
                  });
                },
              ),
              RadioListTile(
                activeColor: Colors.black,
                groupValue: _currentValue,
                title: Text(lang[7]),
                subtitle: Text(lang2[7]),
                secondary: Image.asset('assets/images/SV.png'),
                value: lang[7],
                onChanged: (val) async{
                  await allTranslations.setNewLanguage(val == 'Svenska' ? 'sv' : 'en');
                  setState(() {
                    _currentValue = val;
                    print('val en - _currentValue = $_currentValue');
                    _setPrefers('reload', 'true');  //konieczne załadowanie danych z serwera 
                     Navigator.of(context).pushNamedAndRemoveUntil(MealsScreen.routeName,ModalRoute.withName(MealsScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
        
                  });
                },
              ),
              RadioListTile(
                activeColor: Colors.black,
                groupValue: _currentValue,
                title: Text(lang[8]),
                subtitle: Text(lang2[8]),
                secondary: Image.asset('assets/images/JA.png'),
                value: lang[8],
                onChanged: (val) async{
                  await allTranslations.setNewLanguage(val == '日本語' ? 'ja' : 'en');
                  setState(() {
                    _currentValue = val;
                    print('val en - _currentValue = $_currentValue');
                    _setPrefers('reload', 'true');  //konieczne załadowanie danych z serwera 
                     Navigator.of(context).pushNamedAndRemoveUntil(MealsScreen.routeName,ModalRoute.withName(MealsScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
        
                  });
                },
              ),
              RadioListTile(
                activeColor: Colors.black,
                groupValue: _currentValue,
                title: Text(lang[9]),
                subtitle: Text(lang2[9]),
                secondary: Image.asset('assets/images/ZH.png'),
                value: lang[9],
                onChanged: (val) async{
                  await allTranslations.setNewLanguage(val == '中文' ? 'zh' : 'en');
                  setState(() {
                    _currentValue = val;
                    print('val en - _currentValue = $_currentValue');
                    _setPrefers('reload', 'true');  //konieczne załadowanie danych z serwera 
                     Navigator.of(context).pushNamedAndRemoveUntil(MealsScreen.routeName,ModalRoute.withName(MealsScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
        
                  });
                },
              ),
*/
          ],
          //scrollDirection: Axis.vertical,
        ),
            ),
      );
    
  }
}
*/
/* RaisedButton(
    child: Text(buttonText),
    onPressed: () async {
      await allTranslations.setNewLanguage(language == 'pl' ? 'en' : 'pl');
      setState((){
        Navigator.of(context).pushNamedAndRemoveUntil(MealsScreen.routeName,ModalRoute.withName(MealsScreen.routeName));  //przejście z usunięciem wszystkich wczesniejszych tras i ekranów
                      
      });
    },
  ),
*/