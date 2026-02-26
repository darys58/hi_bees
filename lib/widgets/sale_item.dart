import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import '../models/infos.dart';
// import '../models/hives.dart';
// import '../models/apiarys.dart';
// import '../models/info.dart';
import '../helpers/db_helper.dart';
import '../screens/sale_edit_screen.dart';
import '../globals.dart' as globals;
//import '../globals.dart' as globals;
//import '../models/frames.dart';
import '../models/sale.dart';
//import '../models/hives.dart';
//import '../models/hive.dart';
//import '../models/infos.dart';

class SaleItem extends StatefulWidget {
  @override
  State<SaleItem> createState() => _SaleItemState();
}

class _SaleItemState extends State<SaleItem> {
  //final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //int rozmiarRamki = 0;
  String nowaData = '0';
  //String nowuNrPasieki = '0';
  //List<Hive> hive = [];
  String? nazwaKategorii;
  String? miara;
  String? waluta;

  @override
  Widget build(BuildContext context) {
    final sprzedaz = Provider.of<Sale>(context, listen: false);

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
    switch (sprzedaz.kategoriaId) {
      case 1:
        nazwaKategorii = AppLocalizations.of(context)!.honey;
        break;
      case 2:
        nazwaKategorii = AppLocalizations.of(context)!.beePollen;
        break;
      case 3:
        nazwaKategorii = AppLocalizations.of(context)!.perga;
        break;
      case 4:
        nazwaKategorii = AppLocalizations.of(context)!.wax;
        break;
      case 5:
        nazwaKategorii = 'propolis';
        break;
    }

    switch (sprzedaz.miara) {
      case 1:
        miara = '';
        break;
      case 2:
        miara = '900 ml';
        break;
      case 3:
        miara = '720 ml';
        break;
      case 4:
        miara = '500 ml';
        break;
      case 5:
        miara = '350 ml';
        break;
      case 6:
        miara = '315 ml';
        break;
      case 7:
        miara = '200 ml';
        break;
      case 8:
        miara = '100 ml';
        break;
      case 9:
        miara = '50 ml';
        break;
      case 10:
        miara = '30 ml';
        break;
      case 21:
        miara = '1000 g';
        break;
      case 22:
        miara = '500 g';
        break;
      case 23:
        miara = '250 g';
        break;
      case 24:
        miara = '100 g';
        break;
      case 25:
        miara = '50 g';
        break;
    }

    switch (sprzedaz.waluta) {
      case 1:
        waluta = 'PLN';
        break;
      case 2:
        waluta = 'EUR';
        break;
      case 3:
        waluta = 'USD';
        break;
    }

    return Dismissible(
      //usuwalny element listy
      key: ValueKey(sprzedaz.id),
      background: Container(
        color: Colors.red,
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.delete,
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
              title: Text(AppLocalizations.of(context)!.removeThisItem),
              content: Text(AppLocalizations.of(context)!.deletePermanently),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => {
                    DBHelper.deleteSprzedaz(sprzedaz.id).then((_) {
                      //print('3... kasowanie elementu sprzedazu');

                      Navigator.of(context)
                          .pop(true); //skasowanie elementu listy
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(
                      //     content: Text("The item has been deleted"),
                      //   ),
                      // );
                      Provider.of<Sales>(context, listen: false)
                          .fetchAndSetSprzedaz()
                          .then((_) {
                       // print('4... aktualizacja sprzedazow w sale_item');
                      });
                    }),
                  },
                  child: Text(AppLocalizations.of(context)!.yesDelete),
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
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
        child: Padding(
            padding: const EdgeInsets.all(1),
            child: ListTile(
              onTap: () {
                //_showAlert(context, 'Edycja', '${frame.id}');
                // globals.dataInspekcji = frame.data;
                Navigator.of(context).pushNamed(
                  SaleEditScreen.routeName,
                  arguments: {'idSprzedazy': sprzedaz.id},
                );
              },
              // leading: CircleAvatar(
              //   backgroundColor: Colors.white,
              //   child: //Image.asset('assets/image/hi_bees.png'),
              //       Text('${sprzedaz.pasiekaNr}',
              //           style: const TextStyle(fontSize: 18)),
              // ),
              
               leading: globals.isEuropeanFormat()
                ? Text('${sprzedaz.data.substring(8)}.${sprzedaz.data.substring(5, 7)}',
                         style: const TextStyle(fontSize: 16))
                : Text('${sprzedaz.data.substring(5, 7)}-${sprzedaz.data.substring(8)}',
                         style: const TextStyle(fontSize: 16)),
              
              title: RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                    // TextSpan(
                    //   text: ('${sprzedaz.data}'),
                    //   style: TextStyle(
                    //       fontSize: 14,
                    //       //fontWeight: FontWeight.bold,
                    //       color: Color.fromARGB(255, 0, 0, 0)),
                    // ),
                    globals.isEuropeanFormat()
                      ? TextSpan(
                          text: '${sprzedaz.ilosc.toInt()} x ${sprzedaz.cena.toStringAsFixed(2).replaceAll('.', ',')} = ',
                          style: TextStyle(
                            //fontWeight: FontWeight.bold,
                              fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
                        )
                      : TextSpan(
                          text: '${sprzedaz.ilosc.toInt()} x ${sprzedaz.cena.toStringAsFixed(2)} = ',
                          style: TextStyle(
                           // fontWeight: FontWeight.bold,
                              fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                    globals.isEuropeanFormat()
                      ? TextSpan(
                          text: '${sprzedaz.wartosc.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                              fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
                        )
                      : TextSpan(
                          text: '${sprzedaz.wartosc.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                              fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                     TextSpan(
                      text: ' ${waluta} ',
                      style: TextStyle(
                        //fontWeight: FontWeight.bold,
                          fontSize: 12, color: Color.fromARGB(255, 0, 0, 0)),
                    )
                  ])),
              // title: Text("${sprzedaz.data}   ${sprzedaz.ilosc.toInt()} x ${sprzedaz.cena.toStringAsFixed(2)} ${waluta} ",
              //     style: const TextStyle(fontSize: 16)),
              subtitle: RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                    TextSpan(
                      text: ('${nazwaKategorii}'),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    TextSpan(
                      text: (' ${miara} ${sprzedaz.nazwa}'),
                      style: TextStyle(
                          fontSize: 16,
                          //fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    TextSpan(
                      text: '\n${sprzedaz.uwagi}',
                      style: TextStyle(
                          fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
                    )
                  ])),

              trailing: const Icon(Icons.edit),
              //isThreeLine: true,
              //trailing: const Icon(Icons.arrow_forward_ios)
            )),
      ),
    );
  }
}
