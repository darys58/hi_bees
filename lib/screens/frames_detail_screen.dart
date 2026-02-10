import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/frames.dart';
import '../models/frame.dart';
import '../widgets/frames_detail_item.dart';
import '../screens/frame_edit_screen.dart';
import '../screens/frame_move_screen.dart';
//import '../screens/frame_edit_screen2.dart';
import '../globals.dart' as globals;

class FramesDetailScreen extends StatefulWidget {
  const FramesDetailScreen({super.key});
  static const routeName = '/screen-frames_detail'; //nazwa trasy do tego ekranu
  @override
  State<FramesDetailScreen> createState() => _FramesDetailScreenState();
}

class _FramesDetailScreenState extends State<FramesDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    final numerUla = routeArgs['ul'];
    final wybranaData = routeArgs['data'];
    //  final startBoxColor = routeArgs['color'];

  void _showAlert(BuildContext context, int pasieka, int ul) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectEntryType),
        content: Column(
          //zeby tekst był wyśrodkowany w poziomie
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[


            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  FrameEditScreen.routeName,
                  arguments: {'idPasieki': pasieka, 'idUla':ul, 'idZasobu': 2},
                );
            }, child: Text((AppLocalizations.of(context)!.resourceOnFrame),style: TextStyle(fontSize: 18))
            ),  
            
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  FrameEditScreen.routeName,
                  arguments: {'idPasieki': pasieka, 'idUla':ul, 'idZasobu': 13},
                );
            }, child: Text((AppLocalizations.of(context)!.toDO),style: TextStyle(fontSize: 18)),
            ),
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  FrameEditScreen.routeName,
                  arguments: {'idPasieki': pasieka, 'idUla':ul, 'idZasobu': 14},
                );
            }, child: Text((AppLocalizations.of(context)!.itWasDone),
            style: TextStyle(fontSize: 18)),
            ),
            TextButton(onPressed: (){
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                  FrameMoveScreen.routeName,
                  arguments: {'idPasieki': pasieka, 'idUla':ul, 'idZasobu': 2, 'idKorpusu': globals.nowyNrKorpusu, 'idRamki': globals.nowyNrRamki, 'idData': wybranaData},
                );
            }, child: Text((AppLocalizations.of(context)!.mOvingFrame),
            style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      barrierDismissible:
          false, //zeby zaciemnione tło było zablokowane na kliknięcia
    );
  }
    
    //pobranie wszystkich ramek dla ula
    final framesData = Provider.of<Frames>(context);
    //ramki z wybranej daty dla ula
    List<Frame> frames = framesData.items.where((fr) {
     // globals.ileRamek = frames.length;
    //print('ileRamek w czasie pobierania ilości=${globals.ileRamek}');
      return fr.data == ('$wybranaData');
    }).toList();

    globals.ileRamek = frames.length;
    //print('frames_detail - ileRamek=${globals.ileRamek}');

    
    
    
    
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            AppLocalizations.of(context)!.editInspectionHive + " $numerUla",
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          // title: Text('Edit inspection hive $numerUla'),
          // backgroundColor: Color.fromARGB(255, 233, 140, 0),
          actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () => 
                _showAlert(context, frames[0].pasiekaNr, frames[0].ulNr)
               
          ),
          // IconButton(
          //   icon: Icon(Icons.edit),
          //   onPressed: () => Navigator.of(context)
          //       .pushNamed(FramesDetailScreen.routeName, arguments: {
          //     'ul': globals.ulID,
          //     'data': wybranaData,
          //   }),
          // )
        ],
        ),
        body: frames.length == 0
            ? Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 50),
                      child: Text(
                        AppLocalizations.of(context)!.noDetailsYet,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: frames.length,
                    itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                      value: frames[i],
                      child: FramesDetailItem(),
                    ),
                  ),
                )
              ]));
  }
}
