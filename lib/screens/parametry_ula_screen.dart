import 'package:flutter/material.dart';
import 'package:hi_bees/helpers/db_helper.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../globals.dart' as globals;
//import 'package:intl/intl.dart';
//import '../helpers/db_helper.dart';
import '../models/dodatki2.dart';
import 'package:flutter/services.dart';

class ParametryUlaScreen extends StatefulWidget {
  static const routeName = '/parametry_ula';

  @override
  State<ParametryUlaScreen> createState() => _ParametryUlaScreenState();
}

class _ParametryUlaScreenState extends State<ParametryUlaScreen> {
  final _formKey1 = GlobalKey<FormState>();

  String typ = 'TYP A';
  String indexX = '0';
  String nazwaTypu = 'Wielkopolski A'; 
  String szerokosc_dr = '0';
  String wysokosc_dr = '0';
  String szerokosc_mr = '0';
  String wysokosc_mr = '0';

  @override
  void didChangeDependencies() {
    final routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    typ = routeArgs['typ'].toString();
    indexX = (routeArgs['indexX']).toString(); //dod2[indexX] dla listy dod2 [0] - id=1, [1] - id=2 itd
    //print('pole= $pole');
   // print('wartosc= $wartosc');
    print('indexX didChange... = $indexX');
    super.didChangeDependencies();
  }



  @override
  Widget build(BuildContext context) {
    
    final dod2Data = Provider.of<Dodatki2>(context);
    final dod2 = dod2Data.items.where((dod) {
      return dod.id == (int.parse(indexX)+1).toString();
    }).toList();
    
    
    print('indexX build = $indexX');
    
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(
            AppLocalizations.of(context)!.hiveTypeEdit + ': ' + typ,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300], // kolor linii
            height: 1.0,
          ),
        ),
        ),
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.only(
                    top: 20, left: 20, right: 20, bottom: 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Form(
                        key: _formKey1,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
   //parametry typ ula
                                Container(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  // mainAxisAlignment: MainAxisAlignment.start,
                                  //crossAxisAlignment: CrossAxisAlignment.end,
                                  child: 
                                    Text(AppLocalizations.of(context)!.pArametersDetermine,
                                        style: TextStyle(
                                            //fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                            softWrap: true, //zawijanie tekstu
                                            overflow: TextOverflow.fade,
                                            ),
                                  ),
                                
  //nazwa własna typu ula
                              SizedBox(
                                height: 30,
                              ),
                              TextFormField(
                                initialValue: dod2[0].n,
                                keyboardType: TextInputType.text,
                                //inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                  labelText: (AppLocalizations.of(context)!.oWnTypeName),
                                  labelStyle: TextStyle(color: Colors.black),
                                  // hintText:
                                  //     (AppLocalizations.of(context)!
                                  //         .vAlue),
                                ),
                                validator: (value) {
                                  // if (value!.isEmpty) {
                                  //   return ('uwagi');
                                  // }
                                  nazwaTypu = value!;
                                  return null;
                                }
                              ),
//Wymiary duzej ramki
                            SizedBox(height: 30),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                   Text(AppLocalizations.of(context)!.dImensionsBigFrame + ':',
                                      style: TextStyle(
                                          //fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                          softWrap: true, //zawijanie tekstu
                                          overflow: TextOverflow.fade,
                                          ),
                                  ]),

//szerokość duzej ramki
                              SizedBox(height: 30),
                              Row(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                   
                                    
                                    SizedBox(
                                      width: 140,
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        initialValue: dod2[0].s,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                                          labelText: AppLocalizations.of(context)!.wIdth + ' (mm)',
                                          labelStyle: TextStyle(color: Colors.black),
                                          //hintText: AppLocalizations.of(context)!.vAlue,
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(
                                                        context)!
                                                    .enter +
                                                ' ' +
                                                AppLocalizations.of(
                                                          context)!
                                                      .value);
                                            }
                                            szerokosc_dr = value;
                                            return null;
                                        }),
                                    ),
// wysokość duzej ramki
                                     SizedBox(
                                      width: 140,
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        initialValue: dod2[0].t,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                                          labelText: AppLocalizations.of(context)!.hEight + ' (mm)',
                                          labelStyle: TextStyle(color: Colors.black),
                                          //hintText: AppLocalizations.of(context)!.vAlue,
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(
                                                        context)!
                                                    .enter +
                                                ' ' +
                                                AppLocalizations.of(
                                                          context)!
                                                      .value);
                                            }
                                            wysokosc_dr = value;
                                            return null;
                                        }),
                                    ),
    
                                  ]),
//Wymiary małej ramki
                            SizedBox(height: 30),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                   Text(AppLocalizations.of(context)!.dImensionsSmallFrame + ':',
                                      style: TextStyle(
                                          //fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                          softWrap: true, //zawijanie tekstu
                                          overflow: TextOverflow.fade,
                                          ),
                                  ]),

//szerokość duzej ramki
                              SizedBox(height: 30),
                              Row(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                   
                                    
                                    SizedBox(
                                      width: 140,
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        initialValue: dod2[0].v,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                                          labelText: AppLocalizations.of(context)!.wIdth + ' (mm)',
                                          labelStyle: TextStyle(color: Colors.black),
                                          //hintText: AppLocalizations.of(context)!.vAlue,
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(
                                                        context)!
                                                    .enter +
                                                ' ' +
                                                AppLocalizations.of(
                                                          context)!
                                                      .value);
                                            }
                                            szerokosc_mr = value;
                                            return null;
                                        }),
                                    ),
// wysokość duzej ramki
                                     SizedBox(
                                      width: 140,
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        initialValue: dod2[0].w,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                                          labelText: AppLocalizations.of(context)!.hEight + ' (mm)',
                                          labelStyle: TextStyle(color: Colors.black),
                                          //hintText: AppLocalizations.of(context)!.vAlue,
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return (AppLocalizations.of(
                                                        context)!
                                                    .enter +
                                                ' ' +
                                                AppLocalizations.of(
                                                          context)!
                                                      .value);
                                            }
                                            wysokosc_mr = value;
                                            return null;
                                        }),
                                    ),
    
                                  ]),
                           
                      SizedBox(
                        height: 30,
                      ),

//przyciski
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            //zmień
                            MaterialButton(
                              height: 50,
                              shape: const StadiumBorder(
                                side: const BorderSide(color: Color.fromARGB(255, 162, 103, 0)),
                                ),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                  DBHelper.updateDodatki2(
                                    (int.parse(indexX)+1).toString(), //np: dla TYP A: indexX = 0 wiec id rekordu = 1 
                                    typ, //'TYP A', 
                                    nazwaTypu, //'Wielkopolski A', 
                                    szerokosc_dr, //335', 
                                    wysokosc_dr, //'235', 
                                    (int.parse(szerokosc_dr) * int.parse(wysokosc_dr)).toString(), //'78725', 
                                    szerokosc_mr, //'335', 
                                    wysokosc_mr, //'105', 
                                    (int.parse(szerokosc_mr) * int.parse(wysokosc_mr)).toString(), //'35175'
                                    ).then((_) {

                                      Provider.of<Dodatki2>(context, listen: false)
                                        .fetchAndSetDodatki2()
                                        .then((_) {
                                        Navigator.of(context).pop();
                                      });
                                    });

                                };
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!.saveZ) +
                                  '   '), //Modyfikuj
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.black,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                            ),
                          ]
                          ),
                    ])
                    )]
                    )
                    )
                    )
    );
  }
}
