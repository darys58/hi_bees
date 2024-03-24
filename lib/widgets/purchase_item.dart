import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import '../models/infos.dart';
// import '../models/hives.dart';
// import '../models/apiarys.dart';
// import '../models/info.dart';
import '../helpers/db_helper.dart';
import '../screens/purchase_edit_screen.dart';
import '../globals.dart' as globals;
//import '../globals.dart' as globals;
//import '../models/frames.dart';
import '../models/purchase.dart';
//import '../models/hives.dart';
//import '../models/hive.dart';
//import '../models/infos.dart';

class PurchaseItem extends StatefulWidget {
  @override
  State<PurchaseItem> createState() => _PurchaseItemState();
}

class _PurchaseItemState extends State<PurchaseItem> {
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
    final zakup = Provider.of<Purchase>(context, listen: false);

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
    switch (zakup.kategoriaId) {
      case 1:
        nazwaKategorii = AppLocalizations.of(context)!.lack;
        break;
      case 2:
        nazwaKategorii = AppLocalizations.of(context)!.packaging;
        break;
      case 3:
        nazwaKategorii = AppLocalizations.of(context)!.equipment;
        break;
      case 4:
        nazwaKategorii = AppLocalizations.of(context)!.bees;
        break;
      case 5:
        nazwaKategorii = AppLocalizations.of(context)!.queens;
        break;
      case 6:
        nazwaKategorii = AppLocalizations.of(context)!.waxFundation;
        break;
      case 7:
        nazwaKategorii = AppLocalizations.of(context)!.food;
        break;
      case 8:
        nazwaKategorii = AppLocalizations.of(context)!.medicines;
        break;
    }

    switch (zakup.miara) {
      case 1:
        miara = AppLocalizations.of(context)!.pcs;
        break;
      case 2:
        miara = 'l';
        break;
      case 3:
        miara = 'kg';
        break;
    }

    switch (zakup.waluta) {
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
      key: ValueKey(zakup.id),
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
                    DBHelper.deleteZakupy(zakup.id).then((_) {
                      print('3... kasowanie elementu zakupu');

                      Navigator.of(context)
                          .pop(true); //skasowanie elementu listy
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(
                      //     content: Text("The item has been deleted"),
                      //   ),
                      // );
                      Provider.of<Purchases>(context, listen: false)
                          .fetchAndSetZakupy()
                          .then((_) {
                        print('4... aktualizacja zakupow w sale_item');
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
                  PurchaseEditScreen.routeName,
                  arguments: {'idZakupy': zakup.id},
                );
              },
              // leading: CircleAvatar(
              //   backgroundColor: Colors.white,
              //   child: //Image.asset('assets/image/hi_bees.png'),
              //       Text('${zakup.pasiekaNr}',
              //           style: const TextStyle(fontSize: 18)),
              // ),
              
               leading: globals.jezyk == 'pl_PL'
                ? Text('${zakup.data.substring(8)}.${zakup.data.substring(5, 7)}',
                         style: const TextStyle(fontSize: 16))
                : Text('${zakup.data.substring(5, 7)}-${zakup.data.substring(8)}',
                         style: const TextStyle(fontSize: 16)),
 //wiersz ilość, miara, cena wartość, waluta             
              title: RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                    // TextSpan(
                    //   text: ('${zakup.data}'),
                    //   style: TextStyle(
                    //       fontSize: 14,
                    //       //fontWeight: FontWeight.bold,
                    //       color: Color.fromARGB(255, 0, 0, 0)),
                    // ),
                    globals.jezyk == 'pl_PL'
                      ? TextSpan(
                          text: '${zakup.ilosc.toInt()} ${miara} x ${zakup.cena.toStringAsFixed(2).replaceAll('.', ',')} = ',
                          style: TextStyle(
                            //fontWeight: FontWeight.bold,
                              fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
                        )
                      : TextSpan(
                          text: '${zakup.ilosc.toInt()} ${miara} x ${zakup.cena.toStringAsFixed(2)} = ',
                          style: TextStyle(
                           // fontWeight: FontWeight.bold,
                              fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                    globals.jezyk == 'pl_PL'
                      ? TextSpan(
                          text: '${zakup.wartosc.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                              fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
                        )
                      : TextSpan(
                          text: '${zakup.wartosc.toStringAsFixed(2)}',
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
              // title: Text("${zakup.data}   ${zakup.ilosc.toInt()} x ${zakup.cena.toStringAsFixed(2)} ${waluta} ",
              //     style: const TextStyle(fontSize: 16)),
   //nazwa           
              subtitle: RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                    // TextSpan(
                    //   text: ('${nazwaKategorii}'),
                    //   style: TextStyle(
                    //       fontSize: 16,
                    //       fontWeight: FontWeight.bold,
                    //       color: Color.fromARGB(255, 0, 0, 0)),
                    // ),
  //nazwa                  
                    TextSpan(
                      text: ('${zakup.nazwa}'),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0)),
                    ),
  //uwagi
                    TextSpan(
                      text: '\n${zakup.uwagi}',
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
