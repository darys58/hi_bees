import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../globals.dart' as globals;

import '../models/apiarys.dart';
import '../widgets/apiarys_item.dart';
import '../screens/voice_screen.dart';
import '../models/frames.dart';
import '../models/frame.dart';
import '../helpers/db_helper.dart';
import '../screens/hives_screen.dart';

//ekran startowy
class ApiarysScreen extends StatefulWidget {
  const ApiarysScreen({super.key});
  static const routeName = '/screen-apiarys'; //nazwa trasy do tego ekranu
  @override
  State<ApiarysScreen> createState() => _ApiarysScreenState();
}

class _ApiarysScreenState extends State<ApiarysScreen> {
  bool _isInit = true;

  

  @override
  void didChangeDependencies() {
    print('apiarys_screen - didChangeDependencies');

    //_isInit = globals.isInit;
    print('apiarys_screen - _isInit = $_isInit');
    if (_isInit) {
    //DBHelper.deleteBase().then((_) {

     // getApiarys().then((_) {
        //pobranie pasiek z bazy
           // _pasieki[0].pasiekaNr; //najwcześniejsza data pobrana z bazy
        Provider.of<Apiarys>(context, listen: false)
            .fetchAndSetApiarys()
            .then((_) {
          //wszystkie pasieki z tabeli pasieki z bazy lokalnej

          // setState(() {
          //   // _isLoading = false; //zatrzymanie wskaznika ładowania dań
          // });
        }); //dostawca restauracji
        // setState(() {
        //   // _isLoading = false; //zatrzymanie wskaznika ładowania dań
    //     });
    //});
    }
    _isInit = false;
    // globals.isInit = false;
    super.didChangeDependencies();
  }

  //pobranie listy ramek z unikalnymi pasiekaNr z bazy lokalnej
  // Future<List<Frame>> getApiarys() async {
  //   final dataList = await DBHelper.getApiary();
  //   _pasieki = dataList
  //       .map(
  //         (item) => Frame(
  //           id: item['pasiekaNr'], //pasiekaNr bo jak id to problem !!!
  //           data: item['pasiekaNr'],
  //           pasiekaNr: item['pasiekaNr'],
  //           ulNr: item['pasiekaNr'],
  //           korpusNr: item['pasiekaNr'],
  //           typ: item['pasiekaNr'],
  //           ramkaNr: item['pasiekaNr'],
  //           rozmiar: item['pasiekaNr'],
  //           strona: item['pasiekaNr'],
  //           zasob: item['pasiekaNr'],
  //           wartosc: item['pasiekaNr'],
  //         ),
  //       )
  //       .toList();
  //   return _pasieki;
  // }

  // void selectApiary(BuildContext ctx) {
  //   Navigator.of(ctx).pushNamed(HivesScreen.routeName,arguments: {'id': _pasieki[0].pasiekaNr,'title': pasiekaNazwa[0], 'color':color[0] },);
  //    //(MaterialPageRoute(builder: (_){return FramesScreen();},),);
  //}

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        backgroundColor:Color.fromARGB(255, 233, 140, 0),
        //shape: CircleBorder(),
        textStyle: const TextStyle(color: Colors.white));

    final apiarysData = Provider.of<Apiarys>(context);
    final apiarys =  apiarysData.items; //showFavs ? productsData.favoriteItems :
    //getApiarys().then((_) {
      print('start_screen - drugie pobranie liczby pasiek');
      print(apiarys.length);
   // });
    for (var i = 0; i < apiarys.length; i++) {
      print(
          '${apiarys[i].id},${apiarys[i].pasiekaNr},${apiarys[i].ileUli},${apiarys[i].przeglad},${apiarys[i].ikona},${apiarys[i].opis}');
      print('^^^^^');
    }
  
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hi Bees'),
        backgroundColor: Color.fromARGB(255, 233, 140, 0),
      ),
      
      body: apiarys.length == 0
      ? Center( 
          child:Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(top: 50),
                child: const Text(
                  'There are no apiaries yet',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                  ),
                ),
              ),          
            ],
          ),
        ) 
      
      : GridView.builder(
        padding: const EdgeInsets.all(25.0),
        itemCount: apiarys.length,
        itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
          value: apiarys[i],
          child: ApiarysItem(
              ),
        ),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 7 / 6,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        // children: [
          // _pasieki.length != 0
          //     ? InkWell(
          //         //onTap: () => selectApiary(_pasieki[0].pasiekaNr,pasiekaNazwa[0],color[0]),
          //         onTap: () => Navigator.of(context).pushNamed(
          //           HivesScreen.routeName,
          //           arguments: {
          //             'id': _pasieki[0].pasiekaNr,
          //             'title': pasiekaNazwa[0],
          //             'color': color[0]
          //           },
          //         ),
          //         splashColor: Theme.of(context).primaryColor,
          //         borderRadius: BorderRadius.circular(15),
          //         child: Container(
          //           padding: const EdgeInsets.all(15),
          //           child: Text(
          //             pasiekaNazwa[0],
          //             style: Theme.of(context).textTheme.headline6,
          //           ),
          //           decoration: BoxDecoration(
          //             boxShadow: [
          //               BoxShadow(
          //                 color: Color.fromARGB(255, 115, 115, 115)
          //                     .withOpacity(0.5),
          //                 spreadRadius: 1,
          //                 blurRadius: 4,
          //                 offset: Offset(1, 3), // changes position of shadow
          //               ),
          //             ],
          //             gradient: LinearGradient(
          //               colors: [
          //                 color[0].withOpacity(0.7),
          //                 color[0],
          //               ],
          //               begin: Alignment.topLeft,
          //               end: Alignment.bottomRight,
          //             ),
          //             borderRadius: BorderRadius.circular(15),
          //           ),
          //         ),
          //       )
          //     : Text(''),
         
    //    ],

        // children: APIARY_DUMMY
        //     .map(
        //       (apiaryData) => StartItem(
        //         apiaryData.id,
        //         apiaryData.title,
        //         apiaryData.color,
        //       ),
        //     )
        //     .toList(),
      ),
      //=== stopka
      bottomSheet: Container(
        //margin:  EdgeInsets.only(bottom:15),
        height: 100,
        color: Colors.white,
        //width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                const SizedBox(
                  width: 9,
                ),
                SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      style: buttonStyle,
                      onPressed: () {
                        _isInit = true;
                        Navigator.of(context).pushNamed(
                          VoiceScreen.routeName,
                        );
                      },
                      child:
                          Text("VOICE CONTROL", style: TextStyle(fontSize: 14)),
                    )),
                const SizedBox(
                  width: 15,
                ), //interpolacja ciągu znaków
              ],
            )
          ],
        ),
      ),
    );
  }
}
