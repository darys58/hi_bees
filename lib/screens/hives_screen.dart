import 'package:flutter/material.dart';
import 'apiarys_screen.dart';
import '../models/apiarys.dart';
import '../widgets/apiarys_item.dart';

import 'package:provider/provider.dart';
import '../globals.dart' as globals;
import '../models/hives.dart';
import '../widgets/hives_item.dart';

class HivesScreen extends StatefulWidget {
  static const routeName = '/screen-hives';

  @override
  State<HivesScreen> createState() => _HivesScreenState();
}

class _HivesScreenState extends State<HivesScreen> {
  bool _isInit = true;
  String numerPasieki = '';
  @override
  void didChangeDependencies() {
    print('hives_screen - didChangeDependencies');

    //_isInit = globals.isInit;
    print('hives_screen - _isInit = $_isInit');
    if (_isInit) {
      //DBHelper.deleteBase().then((_) {

      // getApiarys().then((_) {
      //pobranie pasiek z bazy
      //wybranaPasieka =
      //  _pasieki[0].pasiekaNr; //najwcześniejsza data pobrana z bazy
      Provider.of<Hives>(context, listen: false)
          .fetchAndSetHives(globals.pasiekaID)
          .then((_) {
        //wszystkie ule z tabeli ule z bazy lokalnej

        // setState(() {
        //   // _isLoading = false; //zatrzymanie wskaznika ładowania dań
        // });
      }); //dostawca 
      // setState(() {
      //   // _isLoading = false; //zatrzymanie wskaznika ładowania dań
      //     });
      //  });
    }
    _isInit = false;
    // globals.isInit = false;
    super.didChangeDependencies();
  }

  

  @override
  Widget build(BuildContext context) {
    final routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    final numerPasieki = routeArgs['numerPasieki'];
    //  final startBoxTitle = routeArgs['title'];
    //  final startBoxColor = routeArgs['color'];

    final hivesData = Provider.of<Hives>(context);
    final hives = hivesData.items; //showFavs ? productsData.favoriteItems :
    print('hives_screen - ilość uli =');
    print(hives.length);
    for (var i = 0; i < hives.length; i++) {
      print(
          '${hives[i].id},${hives[i].pasiekaNr},${hives[i].ulNr},${hives[i].przeglad},${hives[i].ikona},${hives[i].opis}');
      print('*****');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Apiary $numerPasieki'),
        backgroundColor: Color.fromARGB(255, 233, 140, 0),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: hives.length,
        itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
          value: hives[i],
          child: HivesItem(),
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 6/ 8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
      ),
    );
  }
}
