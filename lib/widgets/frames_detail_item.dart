import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../models/infos.dart';
// import '../models/hives.dart';
// import '../models/apiarys.dart';
// import '../models/info.dart';
import '../helpers/db_helper.dart';
//import '../screens/frames_screen.dart';
import '../globals.dart' as globals;
import '../models/frames.dart';
import '../models/frame.dart';

class FramesDetailItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final frame = Provider.of<Frame>(context, listen: false);

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
    String korpus = '';
    if (frame.typ == 1)
      korpus = 'half body';
    else if (frame.typ == 2) korpus = 'body';
    String rozmiar = '';
    if (frame.rozmiar == 1)
      rozmiar = 'small';
    else if (frame.rozmiar == 2) rozmiar = 'big';
    String strona = '';
    if (frame.strona == 1)
      strona = 'left';
    else if (frame.strona == 2) strona = 'right';
    String zasob = '';
    switch (frame.zasob) {
      case 1:
        zasob = 'drone';
        break;
      case 2:
        zasob = 'brood';
        break;
      case 3:
        zasob = 'larvae';
        break;
      case 4:
        zasob = 'eggs';
        break;
      case 5:
        zasob = 'pollen';
        break;
      case 6:
        zasob = 'honey seald';
        break;
      case 7:
        zasob = 'honey';
        break;
      case 8:
        zasob = 'wax comb';
        break;
      case 9:
        zasob = 'wax';
        break;
      case 10:
        zasob = 'queen';
        break;
      case 11:
        zasob = 'queen cells';
        break;
      case 12:
        zasob = 'delete queen cells';
        break;
      case 13:
        zasob = 'frame ';
        break;
      case 14:
        zasob = 'frame ';
        break;
    }
//1-trut,2-czerw,3-larwy,4-jaja,5-pierzga,6-zasklep,7-miód,8-susz,9-węza,10-matka,
    //ilość lub wartość zasobu        11-mateczniki,12-delMat,13-przeznaczenie,14-akcja
    return Dismissible(
      //usuwalny element listy
      key: ValueKey(frame.id),
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
              title: Text('Are you sure to remove this item?'),
              content: Text('It will delete item permanently.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => {
                    if (globals.ileRamek > 1) {                    
                      DBHelper.deleteFrame(frame.id).then((_) {
                        print('3... kasowanie elementu inspekcji');
                        Navigator.of(context)
                          .pop(true); //skasowanie elementu listy
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(
                        //     content: Text("The item has been deleted"),
                        //   ),
                        // );
                        Provider.of<Frames>(context, listen: false)
                            .fetchAndSetFramesForHive(
                                globals.pasiekaID, globals.ulID)
                            .then((_) {
                          print('4... aktualizacja ramek w frames.item');
                        });
                      }),
                    } else {
                      print('ileRamek=${globals.ileRamek}'),
                      print('5... nie mozna usunąć oststniego elementu'),
                      Navigator.of(context).pop(false),
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('You can\'t delete last item!'),
                            content: Text(
                                'You can delete whole ispection in screen witch information about all inspections.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text('Cancel'),
                              ),
                            ]
                          );
                        },
                      ),
                    }
                  },
                  child: Text('Yes Delete'),
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
              // onTap: () {
              //   globals.dataInspekcji = frame.data;
              // Navigator.of(context).pushNamed(
              //  FramesScreen.routeName,
              //  arguments: info.ulNr,
              //  );
              // },
               leading: CircleAvatar(
                 backgroundColor: Colors.white,
                 child: //Image.asset('assets/image/hi_bees.png'),
                 Text('${frame.korpusNr}.${frame.ramkaNr}',style: const TextStyle(fontSize: 18)),
               ),
              title: Text(
                  '$korpus ${frame.korpusNr}, $rozmiar frame ${frame.ramkaNr} $strona',
                  style: const TextStyle(fontSize: 16)),
              subtitle: Text('$zasob ${frame.wartosc}',
                  style: const TextStyle(fontSize: 16, color: Colors.black)),
              //trailing: const Icon(Icons.arrow_forward_ios)
            )),
      ),
    );
  }
}
