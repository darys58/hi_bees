import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/frames.dart';
import '../models/frame.dart';
import '../widgets/frames_detail_item.dart';
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

    //pobranie wszystkich ramek dla ula
    final framesData = Provider.of<Frames>(context);
    //ramki z wybranej daty dla ula
    List<Frame> frames = framesData.items.where((fr) {
     // globals.ileRamek = frames.length;
    print('ileRamek w czasie pobierania ilości=${globals.ileRamek}');
      return fr.data.contains('$wybranaData');
    }).toList();

    globals.ileRamek = frames.length;
    print('ileRamek=${globals.ileRamek}');

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
          title: Text(
            'Edit inspection hive $numerUla',
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          // title: Text('Edit inspection hive $numerUla'),
          // backgroundColor: Color.fromARGB(255, 233, 140, 0),
        ),
        body: frames.length == 0
            ? Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 50),
                      child: const Text(
                        'There are no details yet.',
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
