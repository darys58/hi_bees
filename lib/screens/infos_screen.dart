import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../globals.dart' as globals;
import '../models/info.dart';
import '../models/infos.dart';
import '../widgets/info_item.dart';

class InfoScreen extends StatefulWidget {
  static const routeName = '/screen-infos';

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  bool _isInit = true;
  String wybranaKategoria = 'inspection';

  @override
  void didChangeDependencies() {
    print('frames_screen - didChangeDependencies');

    print('frames_screen - _isInit = $_isInit');

    if (_isInit) {
      Provider.of<Infos>(context, listen: false)
          .fetchAndSetInfosForHive(globals.pasiekaID, globals.ulID)
          .then((_) {
        //wszystkie informacje dla wybranego pasieki i ula
      });
    }
    _isInit = false;
    //Provider.of<Rests>(context, listen: false).fetchAndSetRests(); //dostawca restauracji
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    //przekazanie hiveNr z hives_item za pomocą navigatora
    final hiveNr = ModalRoute.of(context)!.settings.arguments as int;

    final infosData = Provider.of<Infos>(context);
    List<Info> infos = infosData.items.where((inf) {
      return inf.kategoria.contains(wybranaKategoria);
    }).toList();

    for (var i = 0; i < infos.length; i++) {
      print(
          '${infos[i].id},${infos[i].data},${infos[i].pasiekaNr},${infos[i].ulNr},${infos[i].kategoria},${infos[i].parametr},${infos[i].wartosc},${infos[i].miara},${infos[i].uwagi}');
      print('=======');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hive $hiveNr'),
        backgroundColor: Color.fromARGB(255, 233, 140, 0),
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(10),
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: Color.fromARGB(255, 252, 193, 104),
                  child: IconButton(
                    //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    color: Colors.black,
                    icon: Icon(Icons.check),
                    onPressed: () {
                      setState(() {
                        wybranaKategoria = 'inspection';
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    ),
                  ),
                ),
                CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: Color.fromARGB(255, 252, 193, 104),
                  child: IconButton(
                    //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    color: Colors.black,
                    icon: Icon(Icons.inventory_2_rounded),
                    onPressed: () {
                      setState(() {
                        wybranaKategoria = 'equipment';
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    ),
                  ),
                ),
                CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: Color.fromARGB(255, 252, 193, 104),
                  child: IconButton(
                    //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    color: Colors.black,
                    icon: Icon(Icons.female_rounded),
                    onPressed: () {
                      setState(() {
                        wybranaKategoria = 'queen';
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    ),
                  ),
                ),
                CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: Color.fromARGB(255, 252, 193, 104),
                  child: IconButton(
                    //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    color: Colors.black,
                    icon: Icon(Icons.local_restaurant),
                    onPressed: () {
                      setState(() {
                        wybranaKategoria = 'feeding';
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    ),
                  ),
                ),
                CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: Color.fromARGB(255, 252, 193, 104),
                  child: IconButton(
                    //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    color: Colors.black,
                    icon: Icon(Icons.pest_control_rounded),
                    onPressed: () {
                      setState(() {
                        wybranaKategoria = 'treatment';
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    ),
                  ),
                ),
              ],
            ),

            // child: GestureDetector(
            //   onTap: () {
            //     setState(() {
            //       // wybranaData =
            //       //     _daty[index].data; //dla filtrowania po dacie
            //       // getKorpusy(globals.pasiekaID, globals.ulID,
            //       //         wybranaData)
            //       //     .then((_) {});
            //     });
            //   },
            //   child: Card(
            //     color: Colors.white,
            //     child: Container(
            //       padding: EdgeInsets.symmetric(
            //           horizontal: 10.0, vertical: 1.0),
            //       child: Center(
            //           child: Icon(
            //                   Icons.local_restaurant,
            //                   color: Colors.black,
            //                 )

            //         //   Text(
            //         // _daty[index].data, //nazwa
            //         // style: const TextStyle(
            //         //     color: Colors.black, fontSize: 17.0),
            //         // )
            //       ),
            //     ),
            //   )
            // ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: infos.length,
              itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                value: infos[i],
                child: InfoItem(),
              ),
            ),
          )
        ],
      ),
    );
  }
}
