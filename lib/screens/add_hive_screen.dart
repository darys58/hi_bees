import 'package:flutter/material.dart';
//import 'package:hi_bees/globals.dart';
import 'package:hi_bees/models/infos.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../globals.dart' as globals;
import 'package:intl/intl.dart';
import '../models/apiarys.dart';
import '../models/hives.dart';
//import '../models/dodatki2.dart';
import '../models/harvest.dart';
import 'package:flutter/services.dart';

class AddHiveScreen extends StatefulWidget {
  static const routeName = '/add_hive';

  @override
  State<AddHiveScreen> createState() => _AddHiveScreenState();
}

class _AddHiveScreenState extends State<AddHiveScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');
  var formatterHm = new DateFormat('H:mm');
  
  int nowyNrPasieki = 1;
  int nowyNrUla = 1;
  int ileUli = 0; //ilość uli w pasiece
  int iloscUli = 1; //ilość uli do dodania
  //double? nowyIlosc;
  String ileRamek = '10';
  String typUla = 'WIELKOPOLSKI';//wielkopolski, dadant itp
  String rodzajUla = ''; //ul, odkład, mini
  String tagNFC = '';
  String nowyUwagi = '';
  bool edycja = false;
  String tytulEkranu = '';
  List<Harvest> zbior = [];
  TextEditingController dateController = TextEditingController();
  DateTime? _selectedDate = DateTime.now(); // domyślnie dziś ; //wybrana data

  @override
  void didChangeDependencies() {

      edycja = false;
      dateController.text = DateTime.now().toString().substring(0, 10);     
      tytulEkranu = AppLocalizations.of(context)!.aDdHive;
      rodzajUla = AppLocalizations.of(context)!.hIve;

    super.didChangeDependencies();
  }

  //kalendarz wyboru daty 
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate , // domyślnie dziś
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate); // np. 2025-11-01
      });
    }
  }

 //tworzenie wielu uli - kolejność wywoływania funkcji osiągana przez awaitowanie
  Future<void>  dodajUle(int numerUlaDoDodania) async{   
    await Infos.insertInfo(
      '${dateController.text}.$nowyNrPasieki.$numerUlaDoDodania.equipment.' + AppLocalizations.of(context)!.numberOfFrame + " = ",
      dateController.text,
      nowyNrPasieki,
      numerUlaDoDodania,
      'equipment',
      AppLocalizations.of(context)!.numberOfFrame + " = ",
      ileRamek,
      typUla, //miara - tu typ ula
      rodzajUla, //pogoda - tu rodzaj ula
      '', //temp
      formatterHm.format(DateTime.now()), //czas
      nowyUwagi,
      0, //info[0].arch,
    );

    await Hives.insertHive(
      '$nowyNrPasieki.$numerUlaDoDodania',
      nowyNrPasieki, //pasieka nr
      numerUlaDoDodania, //ul nr
      dateController.text, //przeglad
      'green', //ikona
      int.parse(ileRamek), //opis - ilość ramek w korpusie
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      rodzajUla,//h1 - rodzaj ula
      typUla, //h2 - typ ula
      tagNFC, //h3 - jeszcze nie przypisany
      0, //aktualny bo dopiero utworzony
    );
  }



  @override
  Widget build(BuildContext context) {

    // final ButtonStyle dataButtonStyle = OutlinedButton.styleFrom(
    //   backgroundColor: Theme.of(context).primaryColor, //Color.fromARGB(255, 233, 140, 0),
    //   shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    //   side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
    //   fixedSize: Size(150.0, 35.0),
    //   textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    // );

    // //uzyskanie dostępu do danych w tabeli Dodatki2 - typy własne uli
    // final dod2Data = Provider.of<Dodatki2>(context);
    // final dod2 = dod2Data.items;

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(
            tytulEkranu,
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
                padding: const EdgeInsets.all(20.0),
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
                              SizedBox(height: 10,),
                              Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: TextFormField(
                                  controller: dateController,
                                  readOnly: true, // blokuje ręczne wpisywanie
                                  decoration: InputDecoration(                        
                                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                    focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                    labelText: AppLocalizations.of(context)!.dAteAcquisition,
                                    labelStyle: TextStyle(color: Colors.black),
                                    hintText: AppLocalizations.of(context)!.sElectDate,
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  onTap: () => _selectDate(context),
                                ),
                                      ),
 
  
                             
//numer pasieki
                              SizedBox(
                                height: 15,
                              ),
                              TextFormField(
                                initialValue: nowyNrPasieki.toString(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                  labelText: (AppLocalizations.of(context)!.apiaryNr),
                                  labelStyle: TextStyle(color: Colors.black),
                                  // hintText:
                                  //     (AppLocalizations.of(context)!
                                  //         .vAlue),
                                ),
                                validator: (value) {
                                  // if (value!.isEmpty) {
                                  //   return ('uwagi');
                                  // }
                                  nowyNrPasieki = int.parse(value!);
                                  return null;
                                }
                              ),

//numer ula
                              SizedBox(
                                height: 15,
                              ),
                              TextFormField(
                                initialValue: nowyNrUla.toString(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                  labelText: (AppLocalizations.of(context)!.hIveNr),
                                  labelStyle: TextStyle(color: Colors.black),
                                  // hintText:
                                  //     (AppLocalizations.of(context)!
                                  //         .vAlue),
                                ),
                                validator: (value) {
                                  // if (value!.isEmpty) {
                                  //   return ('uwagi');
                                  // }
                                  nowyNrUla = int.parse(value!);
                                  return null;
                                }
                              ),

//ilość uli do dodania
                              SizedBox(
                                height: 15,
                              ),
                              TextFormField(
                                initialValue: '1',
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                  labelText: (AppLocalizations.of(context)!.nUmberHives),
                                  labelStyle: TextStyle(color: Colors.black),
                                  // hintText:
                                  //     (AppLocalizations.of(context)!
                                  //         .vAlue),
                                ),
                                validator: (value) {
                                  // if (value!.isEmpty) {
                                  //   return ('uwagi');
                                  // }
                                  iloscUli = int.parse(value!);
                                  return null;
                                }
                              ),                              

//rodzaj ula: ul, odkład, mini
                      SizedBox(
                        height: 10,
                      ),              
                      Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                          width: 80,
                          child: Text(AppLocalizations.of(context)!.kIndHive + ':',
                            style: TextStyle(
                              //fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                            softWrap: true, //zawijanie tekstu
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 200,
                              margin: EdgeInsets.only(top: 0, bottom: 0),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: rodzajUla,  
                                items: [
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.hIve),
                                                  value: AppLocalizations.of(context)!.hIve),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.nUc),
                                                  value: AppLocalizations.of(context)!.nUc),
                                  DropdownMenuItem(child: Text('Mini'),
                                                  value: 'Mini'),                                                                                                        
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    rodzajUla = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),


//typ ula              
                        
                       Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                          width: 80,
                          child: Text(AppLocalizations.of(context)!.hIveType + ':',
                            style: TextStyle(
                              //fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                            softWrap: true, //zawijanie tekstu
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 220,
                              margin: EdgeInsets.only(top: 0, bottom: 0),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: typUla,  
                                items: [
                                  DropdownMenuItem(child: Text('WIELKOPOLSKI'),
                                                  value: 'WIELKOPOLSKI'),
                                  DropdownMenuItem(child: Text('DADANT'),
                                                  value: 'DADANT'),
                                  DropdownMenuItem(child: Text('OSTROWSKIEJ'),
                                                  value: 'OSTROWSKIEJ'), 
                                  DropdownMenuItem(child: Text('WARSZAWSKI ZWYKŁY'),
                                                  value: 'WARSZAWSKI ZWYKŁY'),
                                  DropdownMenuItem(child: Text('WARSZAWSKI POSZERZANY'),
                                                  value: 'WARSZAWSKI POSZERZANY'),
                                  DropdownMenuItem(child: Text('APIPOL'),
                                                  value: 'APIPOL'),
                                  DropdownMenuItem(child: Text('LANGSTROTH'),
                                                  value: 'LANGSTROTH'),
                                  DropdownMenuItem(child: Text('ZANDER'),
                                                  value: 'ZANDER'),
                                  DropdownMenuItem(child: Text('GERSTUNG'),
                                                  value: 'GERSTUNG'),
                                  DropdownMenuItem(child: Text('APIMAYE'),
                                                  value: 'APIMAYE'),
                                  DropdownMenuItem(child: Text('DEUTSCH NORMAL'),
                                                  value: 'DEUTSCH NORMAL'),
                                  DropdownMenuItem(child: Text('NORMALMASS'),
                                                  value: 'NORMALMASS'),
                                  DropdownMenuItem(child: Text('FRANKENBEUTE'),
                                                  value: 'FRANKENBEUTE'),
                                  DropdownMenuItem(child: Text('NATIONAL'),
                                                  value: 'NATIONAL'),
                                  DropdownMenuItem(child: Text('WBC'),
                                                  value: 'WBC'),
                                  DropdownMenuItem(child: Text('WIELKOPOLSKI GÓRSKI'),
                                                  value: 'WIELKOPOLSKI GÓRSKI'),
                                  DropdownMenuItem(child: Text('TYP A'), //własna nazwa ula TYP A
                                                  value: 'TYP A'), 
                                  DropdownMenuItem(child: Text('TYP B'),
                                                  value: 'TYP B'),
                                  DropdownMenuItem(child: Text('TYP C'),
                                                  value: 'TYP C'),
                                  DropdownMenuItem(child: Text('TYP D'),
                                                  value: 'TYP D'),
                                  DropdownMenuItem(child: Text('MINI PLUS'),
                                                  value: 'MINI PLUS'),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.wEeddingHive),
                                                  value: AppLocalizations.of(context)!.wEeddingHive), 
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.oTHER),
                                                  value: AppLocalizations.of(context)!.oTHER),                                                                                                        
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    typUla = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),



//ile ramek
                              SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                initialValue: ileRamek,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                                  labelText: (AppLocalizations.of(context)!.nUmberOfFrameInBody),
                                  labelStyle: TextStyle(color: Colors.black),
                                  // hintText:
                                  //     (AppLocalizations.of(context)!
                                  //         .vAlue),
                                ),
                                validator: (value) {
                                  // if (value!.isEmpty) {
                                  //   return ('uwagi');
                                  // }
                                  ileRamek = value!;
                                  return null;
                                }
                              ),


//uwagi
                              SizedBox(
                                height: 15,
                              ),
                              // Row(
                              //     mainAxisAlignment: MainAxisAlignment.start,
                              //     crossAxisAlignment: CrossAxisAlignment.end,
                              //     children: <Widget>[
                                    // SizedBox(
                                    //   width: 270,
                                    //   child: 
                                      TextFormField(
                                          minLines: 1,
                                          maxLines: 5,
                                          initialValue: nowyUwagi,
                                          keyboardType: TextInputType.text,
                                          decoration: InputDecoration(
                                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                                            labelText:
                                                (AppLocalizations.of(context)!
                                                    .cOmments),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            // hintText:
                                            //     (AppLocalizations.of(context)!
                                            //         .comments),
                                          ),
                                          validator: (value) {
                                            // if (value!.isEmpty) {
                                            //   return ('uwagi');
                                            // }
                                            nowyUwagi = value!;
                                            return null;
                                          }),
                                    //),
                                 // ]),
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
                            MaterialButton(
                              height: 50,
                              shape: const StadiumBorder(
                                side: const BorderSide(color: Color.fromARGB(255, 162, 103, 0)),),                    
                              onPressed: () async {
                                if (_formKey1.currentState!.validate()) {
                                   
                                   List<int> items = []; 
                                    for (var i = nowyNrUla; i < nowyNrUla + iloscUli; i++) { 
                                      items.add(i); //utworzenie listy numerów wszystkich uli do dodania - dla pętli for asynchronicznej
                                    }

                                    for (var item in items) {
                                      await dodajUle(item); //tworzenie uli
                                      print('tworze ul nr = $item');
                                    }

                              
                                  //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
                                  await Provider.of<Hives>(context, listen: false).fetchAndSetHives(nowyNrPasieki,)
                                    .then((_) {
                                      final hivesData = Provider.of<Hives>(context,listen: false);
                                      final hives = hivesData.items;
                                      int ileUli = hives.length;
                                      //print('ile uli w pasiece = $ileUli');
               
                                      //zapis do tabeli "pasieki"
                                      Apiarys.insertApiary(
                                        '${nowyNrPasieki}',
                                        nowyNrPasieki, //pasieka nr
                                        ileUli, //ileUli + iloscUli, //ile uli + 
                                        dateController.text, //przeglad
                                        'green', //ikona
                                        '??', //opis
                                      ).then((_) {
                                        Provider.of<Apiarys>(context,listen: false).fetchAndSetApiarys()
                                        .then((_) {
                                          Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(nowyNrPasieki, nowyNrUla)
                                            .then((_) {
                                              Navigator.of(context).pop();
                                          });
                                        });
                                      });
                                    });
                                }      
                              },
                              child: Text('   ' +
                                  (AppLocalizations.of(context)!.saveZ) +
                                  '   '), //Modyfikuj
                              color: Theme.of(context).primaryColor,
                              textColor: Colors.black,
                              disabledColor: Colors.grey,
                              disabledTextColor: Colors.white,
                              
                            ),
                          ]),
                    ]))));
  }
}
