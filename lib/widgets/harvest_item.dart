import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import '../models/infos.dart';
// import '../models/hives.dart';
// import '../models/apiarys.dart';
// import '../models/info.dart';
import '../helpers/db_helper.dart';
import '../screens/harvest_edit_screen.dart';
import '../globals.dart' as globals;
//import '../models/frames.dart';
import '../models/harvest.dart';
//import '../models/hives.dart';
import '../models/hive.dart';
//import '../models/infos.dart';

class HarvestItem extends StatefulWidget {
  @override
  State<HarvestItem> createState() => _HarvestItemState();
}

class _HarvestItemState extends State<HarvestItem> {
  //final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //int rozmiarRamki = 0;
  String nowaData = '0';
  String nowuNrPasieki = '0';
  List<Hive> hive = [];
  String? nazwaZbioru;
  String? miara;

   String zmienDate(String data) {
    String rok = data.substring(0, 4);
    String miesiac = data.substring(5, 7);
    String dzien = data.substring(8);
    return '$dzien.$miesiac.$rok';
  }

  @override
  Widget build(BuildContext context) {
    final zbior = Provider.of<Harvest>(context, listen: false);

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
    switch (zbior.zasobId) {
      case 1:
        nazwaZbioru = AppLocalizations.of(context)!.honey;
        break;
      case 2:
        nazwaZbioru = AppLocalizations.of(context)!.beePollen;
        break;
      case 3:
        nazwaZbioru = AppLocalizations.of(context)!.perga;
        break;
      case 4:
        nazwaZbioru = AppLocalizations.of(context)!.wax;
        break;
      case 5:
        nazwaZbioru = 'propolis';
        break;
    }

    switch (zbior.miara) {
      case 1:
        miara = 'l';
        break;
      case 2:
        miara = 'kg';
        break;
    }

    return Dismissible(
      //usuwalny element listy
      key: ValueKey(zbior.id),
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
                  
                    DBHelper.deleteZbiory(zbior.id).then((_) {
                      //print('3... kasowanie elementu zbioru');

                      Navigator.of(context)
                          .pop(true); //skasowanie elementu listy
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(
                      //     content: Text("The item has been deleted"),
                      //   ),
                      // );
                      Provider.of<Harvests>(context, listen: false)
                          .fetchAndSetZbiory()
                          .then((_) {
                        //print('4... aktualizacja zbiorow w harvest_item');
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
                  HarvestEditScreen.routeName,
                  arguments: {'idZbioru': zbior.id},
                );
              },
              leading: CircleAvatar(
                backgroundColor: Colors.white,
                child: //Image.asset('assets/image/hi_bees.png'),
                    Text('${zbior.pasiekaNr}',
                        style: const TextStyle(fontSize: 18)),
              ),
              title: globals.jezyk == 'pl_PL'
                 ? Text("${zmienDate(zbior.data)}", style: const TextStyle(fontSize: 14))
                 : Text(zbior.data, style: const TextStyle(fontSize: 14)),
              subtitle: RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                    globals.jezyk == 'pl_PL'
                    ? TextSpan(
                        text: ('$nazwaZbioru' +
                          ' ${zbior.ilosc.toString().replaceAll('.', ',')}' +
                          ' $miara'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0)),
                      )
                    : TextSpan(
                        text: ('$nazwaZbioru' +
                          ' ${zbior.ilosc}' +
                          ' $miara'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                    TextSpan(
                      text: '\n${zbior.uwagi}',
                      style: TextStyle(
                          fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
                    )
                  ])),

              trailing: const Icon(Icons.edit),
              isThreeLine: true,
              //trailing: const Icon(Icons.arrow_forward_ios)
            )),
      ),
    );
  }
}
