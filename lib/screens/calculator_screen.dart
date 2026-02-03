import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../screens/syrup_calculator_screen.dart';
import '../screens/syrup21_calculator_screen.dart';
import '../screens/syrup11_calculator_screen.dart';
import '../screens/cake_calculator_screen.dart';

class CalculatorScreen extends StatelessWidget {
  static const routeName = '/calculator';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          AppLocalizations.of(context)!.calculator,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: ListView(
        children: <Widget>[
          // Syrop cukrowy 3:2
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(SyrupCalculatorScreen.routeName);
            },
            child: Card(
              child: ListTile(
                leading: Icon(Icons.water_drop),
                title: Text(AppLocalizations.of(context)!.sugarSyrup32),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
          ),
          // Syrop cukrowy 2:1
          GestureDetector(
            onTap: () {
              Navigator.of(context)
                  .pushNamed(Syrup21CalculatorScreen.routeName);
            },
            child: Card(
              child: ListTile(
                leading: Icon(Icons.water_drop),
                title: Text(AppLocalizations.of(context)!.sugarSyrup21),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
          ),
          // Syrop cukrowy 1:1
          GestureDetector(
            onTap: () {
              Navigator.of(context)
                  .pushNamed(Syrup11CalculatorScreen.routeName);
            },
            child: Card(
              child: ListTile(
                leading: Icon(Icons.water_drop),
                title: Text(AppLocalizations.of(context)!.sugarSyrup11),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
          ),
          // Ciasto miodowo-cukrowe
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(CakeCalculatorScreen.routeName);
            },
            child: Card(
              child: ListTile(
                leading: Icon(Icons.cake),
                title: Text(AppLocalizations.of(context)!.honeySugarCake),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
