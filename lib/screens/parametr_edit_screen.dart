import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../globals.dart' as globals;
//import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
import '../models/dodatki1.dart';
import 'package:flutter/services.dart';

class ParametrEditScreen extends StatefulWidget {
  static const routeName = '/parametr_edit';

  @override
  State<ParametrEditScreen> createState() => _ParametrEditScreenState();
}

class _ParametrEditScreenState extends State<ParametrEditScreen> {
  final _formKey1 = GlobalKey<FormState>();

  String? pole;
  String? wartosc;
 

  @override
  void didChangeDependencies() {
    final routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    pole = routeArgs['pole'].toString();
    wartosc = routeArgs['wartosc'].toString();
    print('pole= $pole');
    print('wartosc= $wartosc');
    
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
 
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(
            AppLocalizations.of(context)!.paramEdition,
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
                              if(pole == 'e') //waga miodu na małej ramce
                                Container(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  // mainAxisAlignment: MainAxisAlignment.start,
                                  //crossAxisAlignment: CrossAxisAlignment.end,
                                  child: 
                                    Text(AppLocalizations.of(context)!.honeyOnSmallFrame,
                                        style: TextStyle(
                                            //fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                            softWrap: true, //zawijanie tekstu
                                            overflow: TextOverflow.fade,
                                            ),
                                  ),
                                if(pole == 'f') //waga miodu na duzej ramce
                                Container(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  // mainAxisAlignment: MainAxisAlignment.start,
                                  //crossAxisAlignment: CrossAxisAlignment.end,
                                  child: 
                                    Text(AppLocalizations.of(context)!.honeyOnBigFrame,
                                        style: TextStyle(
                                            //fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                            softWrap: true, //zawijanie tekstu
                                            overflow: TextOverflow.fade,
                                            ),
                                  ),
                                if(pole == 'g') //pojmność pyłku
                                Container(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  // mainAxisAlignment: MainAxisAlignment.start,
                                  //crossAxisAlignment: CrossAxisAlignment.end,
                                  child: 
                                    Text(AppLocalizations.of(context)!.beePollenPortion,
                                        style: TextStyle(
                                            //fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                            softWrap: true, //zawijanie tekstu
                                            overflow: TextOverflow.fade,
                                            ),
                                  ),

// parametr
                              SizedBox(height: 30),
                              Row(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    // SizedBox(
                                    //   width: 100,
                                    //   child: Text(
                                    //     AppLocalizations.of(context)!.vAlue + ':',
                                    //     style: TextStyle(
                                    //       //fontWeight: FontWeight.bold,
                                    //       fontSize: 15,
                                    //       color: Colors.black,
                                    //     ),
                                    //     softWrap: true, //zawijanie tekstu
                                    //     overflow: TextOverflow.fade,
                                    //   ),
                                    // ),
                                    
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        initialValue: wartosc,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                                          labelText: AppLocalizations.of(context)!.vAlue,
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
                                            wartosc = value;
                                            return null;
                                        }),
                                    ),
                                    SizedBox(width: 20),
                                    SizedBox(
                                      width: 30,
                                      child: 
                                        pole == 'g'
                                        ? Text('ml',
                                            style: TextStyle(
                                              //fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                            softWrap: true, //zawijanie tekstu
                                            overflow: TextOverflow.fade,
                                          )
                                        : Text('g',
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
                              shape: const StadiumBorder(),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                  // print(
                                  //     '$idPasieki,$miasto,$latitude,$longitude,$units,$lang');
                                  DBHelper.updateDodatki1('$pole', '$wartosc').then((_) {

                                    Provider.of<Dodatki1>(context, listen: false)
                                      .fetchAndSetDodatki1()
                                      .then((_) {
                                      Navigator.of(context).pop();
                                    });
                                  });

                                }
                                ;
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!.saveZ) +
                                  '   '), //Modyfikuj
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.white,
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
