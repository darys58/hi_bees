import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
// import '../models/infos.dart';
// import '../models/hives.dart';
import '../models/apiarys.dart';
// import '../models/info.dart';
import '../helpers/db_helper.dart';
import '../screens/queen_edit_screen.dart';
//import '../screens/infos_screen.dart';
import '../globals.dart' as globals;
//import '../models/frames.dart';
import '../models/queen.dart';
import '../models/hives.dart';
import '../models/hive.dart';
import '../models/infos.dart';

class QueenItem extends StatefulWidget {
  @override
  State<QueenItem> createState() => _QueenItemState();
}

class _QueenItemState extends State<QueenItem> {
  //final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //int rozmiarRamki = 0;
  var formatterHm = new DateFormat('H:mm');
  String nowaData = '0';
  String nowuNrPasieki = '0';
  List<Hive> hive = [];
  String? nazwaZbioru;
  String? miara;
  TextEditingController dateController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    final matki = Provider.of<Queen>(context, listen: false);
    dateController.text = globals.dataWpisu; //ostatnio wybrana data 
    // List<Color> color = [
    //   const Color.fromARGB(255, 252, 193, 104),
    //   const Color.fromARGB(255, 255, 114, 104),
    //   const Color.fromARGB(255, 104, 187, 254),
    //   const Color.fromARGB(255, 83, 215, 88),
    //   const Color.fromARGB(255, 203, 174, 85),
    //   const Color.fromARGB(255, 253, 182, 76),
    //   const Color.fromARGB(255, 255, 86, 74),
    //   const Color.fromARGB(255, 71, 170, 251),
    //   Color.fromARGB(255, 61, 214, 66),
    //   Color.fromARGB(255, 210, 170, 49),
    // ];
    // switch (notatki.status) {
    //   case 1:
    //     nazwaZbioru = AppLocalizations.of(context)!.honey;
    //     break;
    //   case 2:
    //     nazwaZbioru = AppLocalizations.of(context)!.beePollen;
    //     break;
    //   case 3:
    //     nazwaZbioru = AppLocalizations.of(context)!.perga;
    //     break;
    //   case 4:
    //     nazwaZbioru = AppLocalizations.of(context)!.wax;
    //     break;
    //   case 5:
    //     nazwaZbioru = 'propolis';
    //     break;
    // }

    // switch (notatki.priorytet) {
    //   case 1:
    //     miara = 'l';
    //     break;
    //   case 2:
    //     miara = 'kg';
    //     break;
    // }

    return  Dismissible(
      ///usuwalny element listy
      key: ValueKey(matki.id),
      background: Container(
        color: Colors.blue,
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if(matki.dataStraty == '' && matki.ul != 0)
                Icon(
                  Icons.highlight_off,
                  color: Colors.white,
                  size: 40,
                ),
              SizedBox(width:20),
              Icon(
                Icons.edit,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (DismissDirection direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.wHatDoYouWant),
              content: matki.dataStraty == '' && matki.ul != 0
                        ? Text(AppLocalizations.of(context)!.dIsconnectOrEdit)
                        : Text(AppLocalizations.of(context)!.eDitQueen),
              
              actions: [
                //Edytuj
                TextButton(
                  onPressed: () => {Navigator.of(context).pop(false),
                    Navigator.of(context).pushNamed(
                      QueenEditScreen.routeName,
                      arguments: {'idQueen': matki.id},
                    ),
                  },
                  child: Text(AppLocalizations.of(context)!.eDit), //Edytuj matkę
                ),
                //Anuluj
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context)!.cancel), // Anuluj
                ),
                
                //Odłacz matkę - jezeli matka zyje
                if(matki.dataStraty == '' && matki.ul != 0)
                  TextButton(
                    onPressed: () => {
                      DBHelper.updateQueen(matki.id, 'pasieka', 0).then((_) {
                        DBHelper.updateQueen(matki.id, 'ul', 0).then((_) {
                          DBHelper.updateQueen(matki.id, 'arch', 0);
                          
                          //DBHelper.upgradeQueen(matki.id).then((_) {
                          //print('3... usuwanie matki z ula - pasieka=0, ul=0');

                          Navigator.of(context).pop(true); //skasowanie elementu listy
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   const SnackBar(
                          //     content: Text("The item has been deleted"),
                          //   ),
                          // );
                          Provider.of<Queens>(context, listen: false)
                              .fetchAndSetQueens()
                              .then((_) {
                                Navigator.of(context).pop(false);
                            //print('4... aktualizacja zbiorow w note_item');
                          });
                       
                        });
                      }),
                    },
                    child: Text(AppLocalizations.of(context)!.dIsconnectQueen), //Odłacz matkę
                  ),

              ],
            );
          },
        );
      },
      child: Card(
         shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
        color:  Colors.white,
        margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 4,
        ),
        child: Padding(
            padding: const EdgeInsets.all(1),
            child: ListTile(
              tileColor: matki.dataStraty != ''  
                ? const Color.fromARGB(255, 244, 208, 208) //matka stracona
                : matki.ul == globals.ulID && matki.pasieka == globals.pasiekaID && globals.ulID != 0 && matki.dataStraty.isEmpty
                  ? const Color.fromARGB(255, 205, 250, 207) //matka w biezącym ulu
                  : matki.ul > 0 && matki.dataStraty.isEmpty
                    ? Colors.grey[200] //matka w innym ulu
                    : Colors.white, 
              onTap: () {
                //_showAlert(context, 'Edycja', '${frame.id}');
                // globals.dataInspekcji = frame.data;
                // Navigator.of(context).pushNamed(
                //   QueenEditScreen.routeName,
                //   arguments: {'idQueen': matki.id},
                // );
                //jezeli matka jest stracona to nie mozna jej dołączyć do ula
                //musi nie mieć dataStraty i nie być podłaczona do innego ula
                if(matki.dataStraty == '' && matki.ul == 0 && globals.ulID != 0){
                  DBHelper.updateQueen(matki.id, 'pasieka', globals.pasiekaID);
                  DBHelper.updateQueen(matki.id, 'ul', globals.ulID);
                  DBHelper.updateQueen(matki.id, 'arch', 0);
                  Infos.insertInfo(
                    '${dateController.text}.${globals.pasiekaID}.${globals.ulID}.queen. ' + AppLocalizations.of(context)!.queen,
                    dateController.text,
                    globals.pasiekaID,
                    globals.ulID,
                    'queen',
                    " " + AppLocalizations.of(context)!.queen, //oznaczenie matki
                    matki.znak,
                    matki.napis,
                    matki.id.toString(), //pogoda - tu matkaID
                    '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}',
                    formatterHm.format(DateTime.now()),
                    matki.uwagi,
                    0, //info[0].arch,
                  ).then((_) {
                    String matka2 = '';
                    if(matki.znak != '' && matki.znak != '0') 
                      if(matki.znak == AppLocalizations.of(context)!.unmarked){
                        matka2 = 'niez ';
                      } else if(matki.znak == AppLocalizations.of(context)!.markedWhite){
                        matka2 = 'biał ' + matki.napis; //znak + napis na opalitku
                      }else if(matki.znak == AppLocalizations.of(context)!.markedYellow){
                        matka2 = 'żółt ' + matki.napis; 
                      }else if(matki.znak == AppLocalizations.of(context)!.markedRed){
                        matka2 = 'czer ' + matki.napis; 
                      }else if(matki.znak == AppLocalizations.of(context)!.markedGreen){
                        matka2 = 'ziel ' + matki.napis; 
                      }else if(matki.znak == AppLocalizations.of(context)!.markedBlue){
                        matka2 = 'nieb ' + matki.napis; 
                      }else if(matki.znak == AppLocalizations.of(context)!.markedOther){
                        matka2 = 'inny ' + matki.napis; 
                      } 
                    DBHelper.updateUleMatka2('${globals.pasiekaID}.${globals.ulID}', matka2).then((_) { //ul.id, ul.matka2
                      DBHelper.updateUle('${globals.pasiekaID}.${globals.ulID}', 'ikona', 'green').then((_) {
                        //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
                        Provider.of<Hives>(context, listen: false).fetchAndSetHives(globals.pasiekaID)
                          .then((_) {
                            final hivesData = Provider.of<Hives>(context,listen: false);
                            final hives = hivesData.items;
                            int ileUli = hives.length;

                        //ustawienie ikony dla pasieki
                            globals.ikonaPasieki = 'green';
                            for (var i = 0; i < hives.length; i++) {
                              //print('i=$i');
                              //print( 'hives[i].ikona = ${hives[i].ikona}');
                              switch (hives[i].ikona){
                                case 'red': globals.ikonaPasieki = 'red';
                                break;
                                case 'orange': if(globals.ikonaPasieki == 'yellow' || globals.ikonaPasieki == 'green') globals.ikonaPasieki = 'orange';
                                break;
                                case 'yellow': if(globals.ikonaPasieki == 'green') globals.ikonaPasieki = 'yellow';
                                break;
                              }
                                  //print('============== globals.ikonaPasieki ===== ${globals.ikonaPasieki}');
                                  // print(
                                  //     '${hives[i].id},${hives[i].pasiekaNr},${hives[i].ulNr},${hives[i].przeglad},${hives[i].ikona},${hives[i].ramek}');
                                  // print('*****');
                            }
                                                 
                            //zapis do tabeli "pasieki"
                            Apiarys.insertApiary(
                              '${globals.pasiekaID}',
                              globals.pasiekaID, //pasieka nr
                              ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
                              dateController.text, //przeglad
                              globals.ikonaPasieki, //ikona
                              '??', //opis
                            ).then((_) {
                              Provider.of<Apiarys>(context,listen: false).fetchAndSetApiarys()
                                .then((_) {

                                  Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(globals.pasiekaID, globals.ulID)
                                    .then((_) {
                                      Provider.of<Queens>(context, listen: false).fetchAndSetQueens()
                                        .then((_) {
                                          Navigator.of(context).pop();
                                        }); 
                                    
                                    });
                                            // print(
                                            //     'edit_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy');
                                  });
                                });
                              });
                            });
                          });                              
                  });
              };
              //Navigator.of(context).pop();
              // Navigator.of(context).pushNamed(
              //     InfoScreen.routeName,
              //     arguments: matki.ul,
              //     //arguments: {'idQueen': matki.id},
              //   );
              },
              leading: Container(
                height:70,
                //alignment: Alignment.center,
                child: 
                  Text('ID\n${matki.id}',
                    style: const TextStyle(color: Colors.black, fontSize: 18)),
                
               ),
              // globals.jezyk == 'pl_PL'
              //   ?  Text("${matki.data.substring(8)}.${matki.data.substring(5, 7)}  ${matki.rasa}", 
              //     style: const TextStyle(fontSize: 16))
              //   : Text("${matki.data.substring(5, 7)}-${matki.data.substring(8)}  ${matki.rasa}", 
              //     style: const TextStyle(fontSize: 16)),
            
              title: RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                    TextSpan(
                      text: ('${matki.linia} '),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                    TextSpan(
                      text: ('${matki.rasa}'),
                      style: TextStyle(
                          fontSize: 14,
                          //fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                    
                    ])),
              subtitle: Column(
                children: [
                  Row(
                    children: [
//znak?       
                      if(matki.znak != '' && matki.znak != '0') 
                        if(matki.znak == AppLocalizations.of(context)!.unmarked)
                          Icon(Icons.circle, size: 20.0, color: Color.fromARGB(255, 61, 61, 61),)
                        else if(matki.znak == AppLocalizations.of(context)!.markedWhite)
                          Icon(Icons.check_circle_outline_outlined, size: 20.0, color: Color.fromARGB(255, 0, 0, 0),)
                        else if(matki.znak == AppLocalizations.of(context)!.markedYellow)
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 215, 208, 0),)
                        else if(matki.znak == AppLocalizations.of(context)!.markedRed)
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 255, 0, 0),)
                        else if(matki.znak == AppLocalizations.of(context)!.markedGreen) 
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 15, 200, 8),)
                        else if(matki.znak == AppLocalizations.of(context)!.markedBlue) 
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 0, 102, 255),)
                        else if(matki.znak == AppLocalizations.of(context)!.markedOther) 
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 158, 166, 172),),


//numer opalitka                      
  
                        if(matki.napis != '' && matki.napis != '0') 
                          Text(
                          ' ${matki.napis}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color.fromARGB(255, 69, 69, 69),
                          )),
                        // if(hive.matka2 != '' && hive.matka2 != '0')
                        //   SizedBox(width: 5),
//pasieka                  
                        if(matki.pasieka != 0) 
                          RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              TextSpan(
                                text: (' ' + AppLocalizations.of(context)!.aPiary + ': '), 
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
//numer pasieki czarny - matka zyje                             
                              matki.dataStraty == ''
                                ? TextSpan(
                                  text: ('${matki.pasieka}'),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  )
//numer pasieki siwy - strata matki
                                : TextSpan(
                                    text: ('${matki.pasieka}'),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey),
                                    ),
                              ])),
                          // Text('  ' + AppLocalizations.of(context)!.aPiary +
                          // ': ${matki.pasieka},',
                          // style: const TextStyle(
                          //  // fontWeight: FontWeight.bold,
                          //   fontSize: 13,
                          //   color: Color.fromARGB(255, 69, 69, 69),
                          // )),
                        if(matki.pasieka == 0) 
                          Text('  ' + AppLocalizations.of(context)!.aPiary +
                          ': ' + AppLocalizations.of(context)!.lack,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 69, 69, 69),
                          )),
   //ul                 
                        if(matki.ul != 0) 
                          RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                              TextSpan(
                                text: (' ' + AppLocalizations.of(context)!.hIve + ': '), 
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
 //numer ula czarny = matka zyje                             
                              matki.dataStraty == ''
                                ? TextSpan(
                                    text: ('${matki.ul}'),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 0, 0, 0)),
                                    )
//numer ula szary - strata matki                                   
                                    : TextSpan(
                                      text: ('${matki.ul}'),
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey),
                                      ),
                              
                              ])),
                        //   Text('  ' + AppLocalizations.of(context)!.hIve +
                        //   ': ${matki.ul},',
                        //   style: const TextStyle(
                        //    // fontWeight: FontWeight.bold,
                        //     fontSize: 13,
                        //     color: Color.fromARGB(255, 69, 69, 69),
                        //   )),
                        if(matki.ul == 0) 
                          Text('  ' + AppLocalizations.of(context)!.hIve +
                          ': ' + AppLocalizations.of(context)!.lack,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 69, 69, 69),
                          )),
                   ],
                  ),
                    
                  Row(children: [
//zrodlo                  
                    if(matki.zrodlo != '' && matki.zrodlo  != '0')
                      Text('${matki.zrodlo}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color.fromARGB(255, 0, 0, 0),
                      )),
//rok pozyskania                  

                    if(matki.data != '' && matki.data  != '0')
                      Text(' ${matki.data }',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color.fromARGB(255, 0, 0, 0),
                      )),  
                      
                    ]),

//strata matki                   
                  if(matki.dataStraty != '' && matki.dataStraty  != '0')
                    Row(children: [              
                      Text(AppLocalizations.of(context)!.lOst,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color.fromARGB(255, 0, 0, 0),
                      )),
//data straty                                     
                      Text(' ${matki.dataStraty }',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color.fromARGB(255, 0, 0, 0),
                      )),
                        
                      
                    ]),
 //uwagi         
                if(matki.uwagi != '' && matki.uwagi  != '0')      
                     Row(children: [    
                          Expanded(
                            child: Text('${matki.uwagi }',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 0, 0, 0),
                          )),
                          ),                   
                    ])]),
              
              // RichText(
              //     text: TextSpan(
              //         style: TextStyle(color: Colors.black),
              //         children: [
              //       TextSpan(
              //         text: ('${matki.linia}'),
              //         style: TextStyle(
              //             fontSize: 16,
              //             //fontWeight: FontWeight.bold,
              //             color: Color.fromARGB(255, 0, 0, 0)),
              //       ),
              //       TextSpan(
              //         text: '\n${matki.uwagi}',
              //         style: TextStyle(
              //             fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
              //       )
              //     ])),

              trailing:  
                Column(
                  children: [
                    matki.ul == 0 && globals.ulID != 0 //jezeli jest się w jakimś ulu a nie w Apiary
                      ? Icon(Icons.touch_app, size: 50, color: Colors.green,)
                      : Icon(Icons.swipe_left, size: 45, color: Colors.blue,),
                    // SizedBox(height: 5,),
                    // matki.ul != 0
                    //   ? Icon(Icons.swipe_left, size: 32,)
                    //   : Icon(Icons.swipe_left, size: 19,)
                  ]
                ),
              isThreeLine: true,
              //trailing: const Icon(Icons.arrow_forward_ios)
            )),
      ),
    );
  }
}
