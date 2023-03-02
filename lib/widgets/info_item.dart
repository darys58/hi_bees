import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/infos.dart';
import '../models/info.dart';
import '../screens/frames_screen.dart';

class InfoItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final info = Provider.of<Info>(context, listen: false);
    List<Color> color = [
      const Color.fromARGB(255, 252, 193, 104),
      const Color.fromARGB(255, 255, 114, 104),
      const Color.fromARGB(255, 104, 187, 254),
      const Color.fromARGB(255, 99, 255, 104),
      const Color.fromARGB(255, 255, 217, 104),
      const Color.fromARGB(255, 253, 182, 76),
      const Color.fromARGB(255, 255, 86, 74),
      const Color.fromARGB(255, 71, 170, 251),
      const Color.fromARGB(255, 70, 255, 76),
      const Color.fromARGB(255, 255, 209, 73),
    ];


    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 4,
      ),
      child: Padding(
          padding: const EdgeInsets.all(1),
          child: info.kategoria == 'inspection' //przeglądy
              ? ListTile(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      FramesScreen.routeName,
                      arguments: info.ulNr,
                    );
                  },
                  leading:  CircleAvatar(
                      backgroundColor: color[info.pasiekaNr - 1],
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                      ) //done_outline_rounted //face //female_rounded
                      ),
                  title: Text('${info.data}  ${info.uwagi}',
                      style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                      '${info.parametr}  ${info.wartosc} ${info.miara}',
                      style:
                          const TextStyle(fontSize: 18, color: Colors.black)),
                  trailing: const Icon(Icons.arrow_forward_ios))
              : ListTile(
                  leading: CircleAvatar(
                      backgroundColor: color[info.pasiekaNr - 1],
                      child: info.kategoria == 'feeding'
                          ? const Icon(
                              Icons.local_restaurant,
                              color: Colors.black,
                            )
                          : info.kategoria == 'treatment'
                              ? const Icon(
                                  Icons.pest_control_rounded,
                                  color: Colors.black,
                                ) //pest_control_rounded) //vaccines_rounded
                              : info.kategoria == 'equipment'
                                  ? const Icon(
                                      Icons.inventory_2_rounded,
                                      color: Colors.black,
                                    ) //construction_rounded)//verified_user_rounded) //info_rounded) //visability_rounded //check
                                  : info.kategoria ==
                                          'queen' //done_outline_rounted //face //female_rounded
                                      ? const Icon(
                                          Icons.female_rounded,
                                          color: Colors.black,
                                        ) //done_outline_rounted //face //female_rounded
                                      : const Icon(
                                          Icons.info_rounded,
                                          color: Colors.black,
                                        )),
                  title: Text('${info.data}  ${info.uwagi}',
                      style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                      '${info.parametr} ${info.wartosc} ${info.miara}',
                      style:
                          const TextStyle(fontSize: 18, color: Colors.black)),
                )),
    );
  }
}
