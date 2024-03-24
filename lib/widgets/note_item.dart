import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import '../models/infos.dart';
// import '../models/hives.dart';
// import '../models/apiarys.dart';
// import '../models/info.dart';
import '../helpers/db_helper.dart';
import '../screens/note_edit_screen.dart';
import '../globals.dart' as globals;
//import '../models/frames.dart';
import '../models/note.dart';
//import '../models/hives.dart';
import '../models/hive.dart';
//import '../models/infos.dart';

class NoteItem extends StatefulWidget {
  @override
  State<NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends State<NoteItem> {
  //final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //int rozmiarRamki = 0;
  String nowaData = '0';
  String nowuNrPasieki = '0';
  List<Hive> hive = [];
  String? nazwaZbioru;
  String? miara;

  @override
  Widget build(BuildContext context) {
    final notatki = Provider.of<Note>(context, listen: false);

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
    switch (notatki.status) {
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

    // switch (notatki.priorytet) {
    //   case 1:
    //     miara = 'l';
    //     break;
    //   case 2:
    //     miara = 'kg';
    //     break;
    // }

    return Dismissible(
      //usuwalny element listy
      key: ValueKey(notatki.id),
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
                    DBHelper.deleteNotatki(notatki.id).then((_) {
                      print('3... kasowanie elementu notatki');

                      Navigator.of(context)
                          .pop(true); //skasowanie elementu listy
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(
                      //     content: Text("The item has been deleted"),
                      //   ),
                      // );
                      Provider.of<Notes>(context, listen: false)
                          .fetchAndSetNotatki()
                          .then((_) {
                        print('4... aktualizacja zbiorow w note_item');
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
        
        color: 
          notatki.priorytet == 'true'
           ? Colors.yellow
           : Colors.white,
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
                  NoteEditScreen.routeName,
                  arguments: {'idNotatki': notatki.id},
                );
              },
              leading: 
                //notatki.priorytet == 'true'
                // ? CircleAvatar(
                //   maxRadius: 30,
                //   backgroundColor: Colors.yellow,
                //   child: //Image.asset('assets/image/hi_bees.png'),
                      
                //     notatki.pasiekaNr > 0
                //       ? Text('${notatki.pasiekaNr}/${notatki.ulNr}',
                //           style: const TextStyle(color: Colors.black, fontSize: 18))
                //       :null,
                //   )
                //notatki.pasiekaNr > 0
                 // ? CircleAvatar(
                      //maxRadius: 30,
                      //backgroundColor: Color.fromARGB(255, 252, 252, 252),
                      //child: //Image.asset('assets/image/hi_bees.png'),
                          
                        notatki.pasiekaNr > 0
                          ? Text('${notatki.pasiekaNr}/${notatki.ulNr}',
                              style: const TextStyle(color: Colors.black, fontSize: 18))
                          :null,
                    //  )
                 // : null,
              title: globals.jezyk == 'pl_PL'
                ?  Text("${notatki.data.substring(8)}.${notatki.data.substring(5, 7)}  ${notatki.tytul}", 
                  style: const TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold))
                : Text("${notatki.data.substring(5, 7)}-${notatki.data.substring(8)}  ${notatki.tytul}", 
                  style: const TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold)),
              subtitle: RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                    TextSpan(
                      text: ('${notatki.notatka}'),
                      style: TextStyle(
                          fontSize: 16,
                          //fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    TextSpan(
                      text: '\n${notatki.uwagi}',
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
