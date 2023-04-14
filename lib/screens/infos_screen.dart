import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../globals.dart' as globals;
import '../models/info.dart';
import '../models/infos.dart';
import '../widgets/info_item.dart';
import '../screens/frames_screen.dart';

class InfoScreen extends StatefulWidget {
  static const routeName = '/screen-infos';

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  bool _isInit = true;
  String wybranaKategoria = 'inspection';
  List<Color> colory = [
    const Color.fromARGB(255, 252, 193, 104),
    const Color.fromARGB(255, 255, 114, 104),
    const Color.fromARGB(255, 104, 187, 254),
    const Color.fromARGB(255, 83, 215, 88),
    const Color.fromARGB(255, 203, 174, 85),
    const Color.fromARGB(255, 253, 182, 76),
    const Color.fromARGB(255, 255, 86, 74),
    const Color.fromARGB(255, 71, 170, 251),
    Color.fromARGB(255, 61, 214, 66),
    Color.fromARGB(255, 210, 170, 49),
  ];


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
    
    int kolor = globals.pasiekaID;
    while (kolor > 10) {
      kolor = kolor - 10;
    }
    
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
        iconTheme: IconThemeData(
          color: Color.fromARGB(255, 0, 0, 0)),
        title: Text('Hive $hiveNr', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
        backgroundColor: Color.fromARGB(255, 255, 255, 255), 
        // title: Text('Hive $hiveNr'),
        // backgroundColor: Color.fromARGB(255, 233, 140, 0),
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(10),
            height: 60,
            child: 
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: <Widget>[
                
             SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                children: [
                 CircleAvatar(
                  maxRadius: 30,
                  backgroundColor:  colory[kolor - 1],
                  child: IconButton(
                    //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    color: Colors.black,
                    icon: Image.asset('assets/image/hi_bees.png'),
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
                 const SizedBox(
                  width: 5,
                ), 
                CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: colory[kolor  - 1],
                  child: IconButton(
                    //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    color: Colors.black,
                    icon: Image.asset('assets/image/korpus.png'),
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
                 const SizedBox(
                  width: 5,
                ), 
                CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: colory[kolor  - 1],
                  child: IconButton(
                    //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    color: Colors.black,
                    icon: Image.asset('assets/image/pszczola1.png'),
                    //icon: Icon(Icons.female_rounded),
                    onPressed: () {
                      setState(() {
                        wybranaKategoria = 'colony';
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    ),
                  ),
                ),
                 const SizedBox(
                  width: 5,
                ), 
                CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: colory[kolor - 1],
                  child: IconButton(
                    //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    color: Colors.black,
                    icon: Image.asset('assets/image/matka1.png'),
                    //icon: Icon(Icons.female_rounded),
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
                 const SizedBox(
                  width: 5,
                ), 
                CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: colory[kolor  - 1],
                  child: IconButton(
                    //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    color: Colors.black,
                    icon: Image.asset('assets/image/invert.png'),
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
                 const SizedBox(
                  width: 5,
                ), 
                CircleAvatar(
                  maxRadius: 30,
                  backgroundColor: colory[kolor  - 1],
                  child: IconButton(
                    //backgroundColor: Color.fromARGB(255, 252, 193, 104),
                    color: Colors.black,
                    icon: Image.asset('assets/image/apivarol1.png'),
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
                    // ElevatedButton(
                    //   onPressed: () => print("Button pressed!"),
                    //   child: Text(button),
                    // ),
                ],
              ),
            ),   
                            
                
          ),
             
             
             
             
               
           //   ]
           // ),

//lista z info o ostatniej inpekcji - bez mozliwosci skasowania
       //   );
          wybranaKategoria == 'inspection'
            ? Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 4),
              child: ListTile( //zeby nie mozna było skasować ptzejścia do inspekcji
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      FramesScreen.routeName,
                      arguments: globals.ulID,
                    );
                  },
                  leading: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Image.asset('assets/image/hi_bees.png'),//done_outline_rounted //face //female_rounded
                      ),
                  title: Text('INSPECTION',
                      style: const TextStyle(fontSize: 14, color: Colors.black)),
                  //subtitle: Text(
                   // 'last inspection',
                      //'${infos[0].parametr}  ${infos[0].wartosc} ${infos[0].miara}',
                   //  style:
                   //       const TextStyle(fontSize: 18, color: Colors.black)),
                  trailing: const Icon(Icons.arrow_forward_ios)),
            )
            : SizedBox(height: 1),
 //lista z info         
          infos.length>0
          ? Expanded(
              child: ListView.builder(
                itemCount: infos.length,
                itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                  value: infos[i],
                  child: InfoItem(),
                ),
              ),
            )
        : Center(
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(50),
                  child: const Text(
                    'There is no information in this category yet.',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
