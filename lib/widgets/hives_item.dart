import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../screens/product_detail_screen.dart';
//import '../screens/frames_screen.dart';
import 'dart:math' as math;
//import 'dart:ui' as ui;
//import '../models/frames.dart';
import '../screens/infos_screen.dart';
import '../globals.dart' as globals;
import '../models/hive.dart';
//import '../models/info.dart';

class HivesItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //nadawcą danych jest ChangeNotifierProvider w hives_screen.dart
    final hive = Provider.of<Hive>(context, listen: false);
    int kolor = hive.pasiekaNr;
    while (kolor > 10) {
      kolor = kolor - 10;
    }
    //print( '${hive.ulNr}: korp=${hive.korpusNr} - t${hive.trut}, c${hive.czerw}, l${hive.larwy}, j${hive.jaja}, p${hive.pierzga}, m${hive.miod}, d${hive.dojrzaly},w${hive.weza}, s${hive.susz}, m${hive.matka}, mt${hive.mateczniki}, dm${hive.usunmat} , td${hive.todo} m1${hive.matka1} m2${hive.matka2} m3${hive.matka3} m4${hive.matka4} m5${hive.matka5}');
    
    //final cart = Provider.of<Cart>(context, listen: false); //dostęp do cart.addItem(
    //var color = Colors.orange;
    var now = new DateTime.now();
    //var formatter = new DateFormat('yyyy-MM-dd');
    //String formattedDate = '';

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

    //obliczanie róznicy miedzy dwoma datami
    int daysBetween(DateTime from, DateTime to) {
      from = DateTime(from.year, from.month, from.day);
      to = DateTime(to.year, to.month, to.day);
      return (to.difference(from).inHours / 24).round();
    }

    //obliczenie ile dni od ostatniego przeglądu
    final przeglad = DateTime.parse(hive.przeglad);
    //final date2 = DateTime.now();
    final difference = daysBetween(przeglad, now);
   

    //sony Z3 592px, mały ios 568px
    double heightScreen = MediaQuery.of(context).size.height;
    // print('wysokość ekranu');
    // print(heightScreen);
    double belka = 150;
    if (heightScreen < 600 && heightScreen > 590) {
      belka = 120; //zmniejszenie długości belki ze 150 pixeli do 120
    }
    if (heightScreen < 590) {
      belka = 90; //zmniejszenie długości belki  do 90
    }

    // //wszystkie ramki z wszystkich dat dla wybranej pasieki i ula z bazy lokalnej
    // Provider.of<Frames>(context, listen: false)
    //           .fetchAndSetFrames()
    //           .then((_) {

    // });

    // //hive.przeglad, hive.pasiekaNr, hive.ulNr

    // final framesData = Provider.of<Frames>(context);
    // //ramki z wybranej daty dla ula
    // List<Frame> frames = framesData.items.where((fr) {
    //   return fr.data.contains(wybranaData);
    // }).toList();

    return Container(
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
              // onTap: () {
              //   globals.dataInspekcji = frame.data;
              // Navigator.of(context).pushNamed(
              //  FramesScreen.routeName,
              //  arguments: info.ulNr,
              //  );
              // },
              onTap: () {
                globals.ulID = hive.ulNr;
                //globals.ikonaUla = 'green';
                Navigator.of(context).pushNamed(
                  InfoScreen.routeName,
                  arguments: hive.ulNr,
                );
              },
              leading: CircleAvatar(
                maxRadius: 30,
                backgroundColor: colory[kolor - 1],
                child: //Image.asset('assets/image/hi_bees.png'),
                    Text('${hive.ulNr}',
                        style:
                            const TextStyle(fontSize: 22, color: Colors.black)),
              ),
//Ul 1 / 15 dni  
              title: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      AppLocalizations.of(context)!.hIve + ' ${hive.ulNr}',
                      style: const TextStyle(
                        // fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      softWrap: true, //zawijanie tekstu
                      maxLines: 2, //ilość wierszy opisu
                      overflow: TextOverflow.ellipsis, //skracanie tekstu
                    ),
                    Text(' / '),
                    difference > 365
                      ? Text(
                          '? ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          '$difference ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                    
                    difference != 1
                        ? Text(
                            AppLocalizations.of(context)!.days,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 69, 69, 69),
                            ),
                            softWrap: true, //zawijanie tekstu
                            maxLines: 2, //ilość wierszy opisu
                            overflow: TextOverflow.ellipsis, //skracanie tekstu
                          )
                        : Text(
                            AppLocalizations.of(context)!.day,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color.fromARGB(255, 69, 69, 69),
                            ),
                            softWrap: true, //zawijanie tekstu
                            maxLines: 2, //ilość wierszy opisu
                            overflow: TextOverflow.ellipsis, //skracanie tekstu
                          ),
                  ]),

              // title: Text(
              //   AppLocalizations.of(context)!.hIve + ' ${hive.ulNr}',
              //   style: const TextStyle(
              //     fontSize: 18,
              //     color: Colors.black,
              //   ),
              //   softWrap: true, //zawijanie tekstu
              //   maxLines: 2, //ilość wierszy opisu
              //   overflow: TextOverflow.ellipsis, //skracanie tekstu
              // ),

              // Text('$difference dni',
              //     style: const TextStyle(fontSize: 16)),
//belka
              subtitle: Column(
                children: [
                  Row(
                    children: [
                      if (hive.korpusNr > 0) Text('${hive.korpusNr}'),

                      if (hive.korpusNr > 0)
                        Container(
                          //szare body
                          //alignment: Alignment.center,
                          color: Color.fromARGB(172, 223, 223, 223),
                          // ignore: sort_child_properties_last
                          child: CustomPaint(
                            painter: MyHiveRow(ul: hive),
                            size: Size(belka, 13),
                          ),
                          margin: EdgeInsets.all(2),
                          //padding: EdgeInsets.all(10),
                        ),
                      if (hive.korpusNr > 0)
                        Container(
                          //szare body
                          //alignment: Alignment.center,
                          color: Color.fromARGB(172, 255, 255, 255),
                          // ignore: sort_child_properties_last
                          child: CustomPaint(
                            painter: MyHiveQueen(ul: hive),
                            size: Size(13, 13),
                          ),
                          margin: EdgeInsets.all(2),
                          //padding: EdgeInsets.all(10),
                        ),
                      if (hive.korpusNr > 0)
                        Container(
                          //szare body
                          //alignment: Alignment.center,
                          color: Color.fromARGB(172, 255, 255, 255),
                          // ignore: sort_child_properties_last
                          child: CustomPaint(
                            painter: MyHiveToDo(ul: hive),
                            size: Size(13, 13),
                          ),
                          margin: EdgeInsets.all(2),
                          //padding: EdgeInsets.all(10),
                        ),

//tekst info - ikona leczenia lub pokarmu
                      if (hive.korpusNr == 0)
                        hive.kategoria == 'feeding'
                            ? Image.asset('assets/image/invert.png',
                                width: 20, height: 20, fit: BoxFit.fill)
                            : hive.kategoria == 'treatment'
                                ? Image.asset('assets/image/apivarol1.png',
                                    width: 20, height: 20, fit: BoxFit.fill)
                                : Text(''),
                        
                      if (hive.korpusNr == 0 && (hive.kategoria == 'feeding' || hive.kategoria == 'treatment')) 
                        SizedBox(width: 5),
                      
  //info o leczeniu lub pokarmie                
                      if (hive.korpusNr == 0 &&
                          (hive.kategoria == 'feeding' ||
                              hive.kategoria == 'treatment'))
                        Text(
                          '${hive.parametr} ${hive.wartosc} ${hive.miara}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color.fromARGB(255, 69, 69, 69),
                          ),
                          softWrap: true, //zawijanie tekstu
                          maxLines: 2, //ilość wierszy opisu
                          overflow: TextOverflow.ellipsis, //skracanie tekstu),
                        ),

//info o matce jezeli nie ma belki             
                      if (hive.korpusNr == 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))
//czy jest ograniczona
                        if(hive.matka4 == 'wolna')
                          Image.asset('assets/image/matka1.png',
                             width: 27, height: 16, fit: BoxFit.fill)
                        else if (hive.matka4 == 'ograniczona')
                          Image.asset('assets/image/matka11.png',
                             width: 25, height: 15, fit: BoxFit.fill),
                      if (hive.korpusNr == 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))  
                        if(hive.matka4 != '' && hive.matka4 != '0')
                          SizedBox(width: 8),
//ok?
                      if (hive.korpusNr == 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))
                        if(hive.matka1 == 'ok')               
                          Icon(Icons.thumb_up_outlined, size: 20.0, color: Color.fromARGB(255, 15, 200, 8),) 
                        else if(hive.matka1 == 'zła') Icon(Icons.thumb_down_outlined, size: 20.0, color: Color.fromARGB(255, 255, 1, 1),), 
                      if (hive.korpusNr == 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))  
                        if(hive.matka1 != '' && hive.matka1 != '0')
                          SizedBox(width: 5),
//unasienniona?                    
                      if (hive.korpusNr == 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))  
                        if(hive.matka3 == 'unasienniona')                   
                          Icon(Icons.egg, size: 20.0, color: Color.fromARGB(255, 15, 200, 8),)
                        else if(hive.matka3 == 'nieunasienniona') Icon(Icons.egg_outlined, size: 20.0, color: Color.fromARGB(255, 255, 0, 0),), 
                      if (hive.korpusNr == 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment' && (hive.matka3 == 'unasienniona' || hive.matka3 == 'nieunasienniona')))  
                        if(hive.matka3 != '' && hive.matka3 != '0')
                          SizedBox(width: 5),
//znak? numer?     
                      if (hive.korpusNr == 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))  
                        if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'niez')
                          Icon(Icons.circle, size: 20.0, color: Color.fromARGB(255, 61, 61, 61),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'brak')
                          Icon(Icons.dangerous_outlined, size: 20.0, color: Color.fromARGB(255, 255, 0, 0))
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'inny')
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 158, 166, 172),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'biał')
                          Icon(Icons.check_circle_outline_outlined, size: 20.0, color: Color.fromARGB(255, 0, 0, 0),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'żółt')
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 215, 208, 0),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'czer')
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 255, 0, 0),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'ziel')
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 15, 200, 8),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'nieb')
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 0, 102, 255),),
//numer opalitka                      
                      if (hive.korpusNr == 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))   
                        if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(4) != '')
                          Text(
                          '${hive.matka2.substring(4)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 69, 69, 69),
                          )),
                        // if(hive.matka2 != '' && hive.matka2 != '0')
                        //   SizedBox(width: 5),
//rok urodzenia                   
                      if (hive.korpusNr == 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))   
                        if(hive.matka5 != '' && hive.matka5 != '0')
                          Text(
                          '  \'${hive.matka5.substring(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 0, 0, 0),
                          )),
                       
                       
                        // Text(
                        //   '${hive.matka1}, ${hive.matka2} \n${hive.matka3}, ${hive.matka4}, ${hive.matka5}',
                        //   style: const TextStyle(
                        //     fontSize: 15,
                        //     color: Color.fromARGB(255, 69, 69, 69),
                        //   ),
                        //   softWrap: true, //zawijanie tekstu
                        //   maxLines: 5, //ilość wierszy opisu
                        //   overflow: TextOverflow.ellipsis, //skracanie tekstu),
                        // ),
                    ],
                  ),
                  
//drugi wiersz z matką jezeli jest belka                 
                  Row(
                    
                    children: [
                      if (hive.korpusNr > 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))
//czy jest ograniczona
                        if(hive.matka4 == 'wolna')
                          Image.asset('assets/image/matka1.png',
                             width: 27, height: 16, fit: BoxFit.fill)
                        else if (hive.matka4 == 'ograniczona')
                          Image.asset('assets/image/matka11.png',
                             width: 25, height: 15, fit: BoxFit.fill),
                      if (hive.korpusNr > 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))  
                        if(hive.matka4 != '' && hive.matka4 != '0')
                          SizedBox(width: 8),
//ok?
                      if (hive.korpusNr > 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))
                        if(hive.matka1 == 'ok')               
                          Icon(Icons.thumb_up_outlined, size: 20.0, color: Color.fromARGB(255, 15, 200, 8),) 
                        else if(hive.matka1 == 'zła') Icon(Icons.thumb_down_outlined, size: 20.0, color: Color.fromARGB(255, 255, 0, 0),), 
                      if (hive.korpusNr > 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))  
                        if(hive.matka1 != '' && hive.matka1 != '0')
                          SizedBox(width: 5),
//unasienniona?                    
                      if (hive.korpusNr > 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))  
                        if(hive.matka3 == 'unasienniona')                   
                          Icon(Icons.egg, size: 20.0, color: Color.fromARGB(255, 15, 200, 8),)
                        else if(hive.matka3 == 'nieunasienniona') Icon(Icons.egg_outlined, size: 20.0, color: Color.fromARGB(255, 255, 0, 0),), 
                      if (hive.korpusNr > 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment' && hive.matka3 == 'unasienniona'))  
                        if(hive.matka3 != '' && hive.matka3 != '0')
                          SizedBox(width: 5),
//znak? numer?     
                      if (hive.korpusNr > 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))  
                        if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'niez')
                          Icon(Icons.circle, size: 20.0, color: Color.fromARGB(255, 61, 61, 61),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'brak')
                          Icon(Icons.dangerous_outlined, size: 20.0, color: Color.fromARGB(255, 255, 0, 0))
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'inny')
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 158, 166, 172),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'biał')
                          Icon(Icons.check_circle_outline_outlined, size: 20.0, color: Color.fromARGB(255, 0, 0, 0),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'żółt')
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 215, 208, 0),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'czer')
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 255, 0, 0),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'ziel')
                          Icon(Icons.check_circle_rounded, size: 20.0, color: Color.fromARGB(255, 15, 200, 8),)
                        else if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(0, 4) == 'nieb')
                          Icon(Icons.check_circle_rounded, size: 20.0,color: Color.fromARGB(255, 0, 102, 255),),
                      if (hive.korpusNr > 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))   
                        if(hive.matka2 != '' && hive.matka2 != '0') if(hive.matka2.substring(4) != '')
                          Text(
                          '${hive.matka2.substring(4)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 69, 69, 69),
                          )),
                        // if(hive.matka2 != '' && hive.matka2 != '0')
                        //   SizedBox(width: 5),
//rok urodzenia                   
                      if (hive.korpusNr > 0 &&
                          (hive.kategoria != 'feeding' &&
                              hive.kategoria != 'treatment'))   
                        if(hive.matka5 != '' && hive.matka5 != '0')
                          Text(
                          '  \'${hive.matka5.substring(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 0, 0, 0),
                          )),
                       
                    ]
                  )
                
                ],
              ),
              //isThreeLine: true,

//ikona zielona, zółta, czerwona
              trailing: hive.ikona == 'green'
                  ? const Icon(
                      Icons.hive,
                      color: Color.fromARGB(255, 0, 255, 0),
                    )
                  : hive.ikona == 'yellow'
                      ? const Icon(
                          Icons.hive,
                          color: Color.fromARGB(255, 233, 229, 1),
                        )
                      : hive.ikona == 'orange'
                          ? const Icon(
                              Icons.hive,
                              color: Color.fromARGB(255, 233, 132, 1),
                            )
                          : const Icon(
                              Icons.hive,
                              color: Color.fromARGB(255, 255, 0, 0),
                            ),
            )),
      ),
    );
  }
}

class MyHiveToDo extends CustomPainter {
  Hive ul;

  MyHiveToDo({
    required this.ul,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()..strokeWidth = 1; //linia ramki
    //Paint lineExcluder = Paint()..strokeWidth = 3; //linia ramki
    // Paint obrysPaint = Paint()
    //   ..strokeWidth = 1
    //   ..color = Color.fromARGB(255, 122, 122, 122); //obrys

    Paint paintStroke = Paint()
      ..color = Color.fromARGB(255, 0, 0, 0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke //fill
      ..strokeCap = StrokeCap.round;
    // Paint paintStroke = Paint()
    //   ..color = Color.fromARGB(255, 0, 0, 0)
    //   ..strokeWidth = 1
    //   ..style = PaintingStyle.fill //stroke
    //   ..strokeCap = StrokeCap.round;

    //wielokąty
    double sides = 3;
    double radius = 5;
    double radians = 0; //kąt - początek rysowania
    //3.14 - trójkąt w lewo, //1,57(/2) - w dół //(/6) - w górę, 0 - w prawo
    //double wDol = math.pi/2; //1,57 - trójkąt w dół
    var path = Path();

    //ramka pracy
    if (ul.todo == 'ramka pracy' || ul.todo == 'work frame') {
      var angle = (math.pi * 2) / 4; //kąt (4 - kwadrat)
      radians = math.pi / 4;

      Offset center = Offset(2, 7);
      Offset startPoint =
          Offset(radius * math.cos(radians), radius * math.sin(radians));

      path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

      for (int i = 1; i <= sides; i++) {
        double x = radius * math.cos(radians + angle * i) + center.dx;
        double y = radius * math.sin(radians + angle * i) + center.dy;
        path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, paintStroke);
    }

    //to insutate
    if (ul.todo == 'można izolować' || ul.todo == 'to insulate') {
      sides = 4;
      radians = math.pi / 4;
      //var angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

      canvas.drawLine(
          Offset(1, 8), Offset(7, 8), linePaint); // - (kreska pozioma)

      canvas.drawLine(
          Offset(1, 2), Offset(1, 8), linePaint); // | (kreska pionowa lewa)
      canvas.drawLine(Offset(7, 2), Offset(7, 8), linePaint);
    }

    //to delete
    if (ul.todo == 'trzeba usunąć' || ul.todo == 'to delete') {
      sides = 3;
      radians = math.pi / 6;
      var angle = (math.pi * 2) / sides; //kąt

      Offset center1 = Offset(5, 7);
      Offset startPoint1 =
          Offset(radius * math.cos(radians), radius * math.sin(radians));

      path.moveTo(startPoint1.dx + center1.dx, startPoint1.dy + center1.dy);

      for (int i = 1; i <= sides; i++) {
        double x = radius * math.cos(radians + angle * i) + center1.dx;
        double y = radius * math.sin(radians + angle * i) + center1.dy;
        path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, paintStroke);
    }

    //to extraction
    if (ul.todo == 'trzeba wirować' || ul.todo == 'to extraction') {
      double radiusEx = 4;
      sides = 6;
      radians = 0;
      var angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

      Offset center2 = Offset(5, 6);
      Offset startPoint2 =
          Offset(radiusEx * math.cos(radians), radiusEx * math.sin(radians));

      path.moveTo(startPoint2.dx + center2.dx, startPoint2.dy + center2.dy);

      for (int i = 1; i <= sides; i++) {
        double x = radiusEx * math.cos(radians + angle * i) + center2.dx;
        double y = radiusEx * math.sin(radians + angle * i) + center2.dy;
        path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, paintStroke);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    //throw UnimplementedError();
    return true;
  }
}

class MyHiveQueen extends CustomPainter {
  Hive ul;

  MyHiveQueen({
    required this.ul,
  });

  @override
  void paint(Canvas canvas, Size size) {
    //Paint linePaint = Paint()..strokeWidth = 1; //linia ramki
    //Paint lineExcluder = Paint()..strokeWidth = 3; //linia ramki

    Paint matka = Paint()
      ..color = Color.fromARGB(255, 59, 59, 59)
      ..style = PaintingStyle.fill; //matka
    Paint matecznik = Paint()
      ..color = Color.fromARGB(255, 255, 17, 0)
      ..style = PaintingStyle.fill
      ..strokeWidth = 1; //matecznik
    Paint delMat = Paint()
      ..color = Color.fromARGB(255, 153, 125, 125)
      ..style = PaintingStyle.fill //stroke
      ..strokeWidth = 1; //mateczniki usuniete

    if (ul.matka > 0) {
      canvas.drawCircle(Offset(3, 3), 3, matka);
    }
    if (ul.mateczniki > 0) {
      canvas.drawCircle(Offset(3, 10), 3, matecznik);
    }
    if (ul.usunmat > 0) {
      canvas.drawCircle(Offset(10, 10), 3, delMat);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    //throw UnimplementedError();
    return true;
  }
}

class MyHiveRow extends CustomPainter {
  Hive ul;

  MyHiveRow({
    required this.ul,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()..strokeWidth = 1; //linia ramki
    //Paint lineExcluder = Paint()..strokeWidth = 3; //linia ramki
    // Paint obrysPaint = Paint()
    //   ..strokeWidth = 1
    //   ..color = Color.fromARGB(255, 122, 122, 122); //obrys
    Paint honeyPaint = Paint()
      ..strokeWidth = 11
      ..color = Color.fromARGB(255, 222, 156,
          1); //(1) honey / miód, nakrop 255, 252, 193, 104//,255, 206, 144, 1
    Paint sealedPaint = Paint()
      ..strokeWidth = 11
      ..color =
          Color.fromARGB(255, 131, 92, 0); //(2) sealed / zasklep, miód poszyty
    Paint pollenPaint = Paint()
      ..strokeWidth = 11
      ..color = Color.fromARGB(255, 0, 197, 0); //(3) pollen / pierzga
    Paint broodPaint = Paint()
      ..strokeWidth = 11
      ..color = Color.fromARGB(255, 255, 17, 0); //(4) brook / czerw
    Paint larvaePaint = Paint()
      ..strokeWidth = 11
      ..color = Color.fromARGB(255, 253, 195, 192); //(5) larvae / larwy
    Paint eggPaint = Paint()
      ..strokeWidth = 11
      ..color = Color.fromARGB(255, 255, 255, 255); //(6) eggs / jaja
    Paint dronePaint = Paint()
      ..strokeWidth = 11
      ..color = Color.fromARGB(255, 114, 0, 0); //(7) drone / trut
    Paint waxPaint = Paint()
      ..strokeWidth = 5
      ..color = Color.fromARGB(255, 255, 255, 0); //(8) wax / węza
    Paint combPaint = Paint()
      ..strokeWidth = 11
      ..color = Color.fromARGB(
          255, 255, 255, 0); //(9) comb, wax comb / susz, woszczyna
    // Paint matka = Paint()
    //   ..color = Color.fromARGB(255, 59, 59, 59)
    //   ..style = PaintingStyle.fill; //matka
    // Paint matecznik = Paint()
    //   ..color = Color.fromARGB(255, 255, 17, 0)
    //   ..style = PaintingStyle.fill
    //   ..strokeWidth = 1; //matecznik
    // Paint delMat = Paint()
    //   ..color = Color.fromARGB(255, 153, 125, 125)
    //   ..style = PaintingStyle.fill //stroke
    //   ..strokeWidth = 1; //mateczniki usuniete

    // Paint paintStroke = Paint()
    //   ..color = Color.fromARGB(255, 0, 0, 0)
    //   ..strokeWidth = 1
    //   ..style = PaintingStyle.stroke //fill
    //   ..strokeCap = StrokeCap.round;
    // Paint paintStroke = Paint()
    //   ..color = Color.fromARGB(255, 0, 0, 0)
    //   ..strokeWidth = 1
    //   ..style = PaintingStyle.fill //stroke
    //   ..strokeCap = StrokeCap.round;

    //wielokąty
    // double sides = 3;
    // double radius = 5;
    // double radians = 0; //kąt - początek rysowania
    //3.14 - trójkąt w lewo, //1,57(/2) - w dół //(/6) - w górę, 0 - w prawo
    //double wDol = math.pi/2; //1,57 - trójkąt w dół
    // var path = Path();

    //text
    // final textStyle = TextStyle(
    //   color: Colors.black,
    //   fontSize: 15,
    // );
    double mnoznik = size.width / 100; //1.5 dla 150 długości belki, 1 dla 100

    canvas.drawLine(Offset(0, 1), Offset(size.width, 1), linePaint);
    canvas.drawLine(Offset(0, 13), Offset(size.width, 13), linePaint);
    double start = 0.0;
    double stop = 0.0;
    if (ul.trut > 0) {
      stop = (ul.trut / (ul.ramek * 2)) * mnoznik;
     // print('$start - $stop');
      canvas.drawLine(Offset(start, 7), Offset(stop, 7), dronePaint);
    }
    if (ul.czerw > 0) {
      start = stop;
      stop = start + (ul.czerw / (ul.ramek * 2)) * mnoznik;
      //print('$start - $stop');
      canvas.drawLine(Offset(start, 7), Offset(stop, 7), broodPaint);
    }
    if (ul.larwy > 0) {
      start = stop;
      stop = start + (ul.larwy / (ul.ramek * 2)) * mnoznik;
     // print('$start - $stop');
      canvas.drawLine(Offset(start, 7), Offset(stop, 7), larvaePaint);
    }
    if (ul.jaja > 0) {
      start = stop;
      stop = start + (ul.jaja / (ul.ramek * 2)) * mnoznik;
     // print('$start - $stop');
      canvas.drawLine(Offset(start, 7), Offset(stop, 7), eggPaint);
    }
    if (ul.pierzga > 0) {
      start = stop;
      stop = start + (ul.pierzga / (ul.ramek * 2)) * mnoznik;
     // print('$start - $stop pierzga = ${ul.pierzga} ');
      canvas.drawLine(Offset(start, 7), Offset(stop, 7), pollenPaint);
    }
    if (ul.miod > 0) {
      start = stop;
      stop = start + (ul.miod / (ul.ramek * 2)) * mnoznik;
     // print('$start - $stop miod = ${ul.miod} ');
      canvas.drawLine(Offset(start, 7), Offset(stop, 7), honeyPaint);
    }
    if (ul.dojrzaly > 0) {
      start = stop;
      stop = start + (ul.dojrzaly / (ul.ramek * 2)) * mnoznik;
    //  print('$start - $stop');
      canvas.drawLine(Offset(start, 7), Offset(stop, 7), sealedPaint);
    }
    if (ul.weza > 0) {
      start = stop;
      stop = start + (ul.weza / (ul.ramek * 2)) * mnoznik;
    //  print('$start - $stop');
      canvas.drawLine(Offset(start, 7), Offset(stop, 7), waxPaint);
    }
    if (ul.susz > 0) {
      start = stop;
      stop = start + (ul.susz / (ul.ramek * 2)) * mnoznik;
    //  print('$start - $stop');
      canvas.drawLine(Offset(start, 7), Offset(stop, 7), combPaint);
    }
  }

// //ramka pracy
//     var angle = (math.pi * 2) / 4; //kąt (4 - kwadrat)
//     radians = math.pi / 4;

//     Offset center = Offset(10, 20);
//     Offset startPoint =
//         Offset(radius * math.cos(radians), radius * math.sin(radians));

//     path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

//     for (int i = 1; i <= sides; i++) {
//       double x = radius * math.cos(radians + angle * i) + center.dx;
//       double y = radius * math.sin(radians + angle * i) + center.dy;
//       path.lineTo(x, y);
//     }
//     path.close();
//     canvas.drawPath(path, paintStroke);
//     var opisSpan = TextSpan(
//       text: '- work frame',
//       style: textStyle,
//     );
//     var textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 10));
// //to delete
//     sides = 3;
//     radians = math.pi / 6;
//     angle = (math.pi * 2) / sides; //kąt

//     Offset center1 = Offset(10, 35);
//     Offset startPoint1 =
//         Offset(radius * math.cos(radians), radius * math.sin(radians));

//     path.moveTo(startPoint1.dx + center1.dx, startPoint1.dy + center1.dy);

//     for (int i = 1; i <= sides; i++) {
//       double x = radius * math.cos(radians + angle * i) + center1.dx;
//       double y = radius * math.sin(radians + angle * i) + center1.dy;
//       path.lineTo(x, y);
//     }
//     path.close();
//     canvas.drawPath(path, paintStroke);
//     opisSpan = TextSpan(
//       text: '- to delete',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 25));
// //to extraction
//     double radiusEx = 4;
//     sides = 6;
//     radians = 0;
//     angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

//     Offset center2 = Offset(10, 50);
//     Offset startPoint2 =
//         Offset(radiusEx * math.cos(radians), radiusEx * math.sin(radians));

//     path.moveTo(startPoint2.dx + center2.dx, startPoint2.dy + center2.dy);

//     for (int i = 1; i <= sides; i++) {
//       double x = radiusEx * math.cos(radians + angle * i) + center2.dx;
//       double y = radiusEx * math.sin(radians + angle * i) + center2.dy;
//       path.lineTo(x, y);
//     }
//     path.close();
//     canvas.drawPath(path, paintStroke);
//     opisSpan = TextSpan(
//       text: '- to extraction',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 40));
// //to insutate
//     sides = 4;
//     radians = math.pi / 4;
//     angle = (math.pi * 2) / sides; //kąt (6 - sześciobok)

//     canvas.drawLine(
//         Offset(7, 68), Offset(13, 68), linePaint); // - (kreska pozioma)

//     canvas.drawLine(
//         Offset(7, 62), Offset(7, 68), linePaint); // | (kreska pionowa lewa)
//     canvas.drawLine(Offset(13, 62), Offset(13, 68), linePaint);
//     opisSpan = TextSpan(
//       text: '- to insulate',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 55));
// //queen
//     canvas.drawCircle(Offset(10, 80), 3, matka);
//     opisSpan = TextSpan(
//       text: '- queen',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 70));
// //wax
//     canvas.drawLine(Offset(10, 90), Offset(10, 100), waxPaint);
//     opisSpan = TextSpan(
//       text: '- wax foundation',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 85));
// //comb
//     canvas.drawLine(Offset(10, 105), Offset(10, 115), combPaint);
//     opisSpan = TextSpan(
//       text: '- wax comb',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 100));
// //honey
//     canvas.drawLine(Offset(10, 120), Offset(10, 130), honeyPaint);
//     opisSpan = TextSpan(
//       text: '- honey',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 115));
//     //sealed
//     canvas.drawLine(Offset(10, 135), Offset(10, 145), sealedPaint);
//     opisSpan = TextSpan(
//       text: '- honey sealed',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 130));
// //pollen
//     canvas.drawLine(Offset(10, 150), Offset(10, 160), pollenPaint);
//     opisSpan = TextSpan(
//       text: '- pollen',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 145));
// //eggs
//     canvas.drawLine(Offset(10, 165), Offset(10, 175), eggPaint);
//     opisSpan = TextSpan(
//       text: '- eggs',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 160));
// //larvae
//     canvas.drawLine(Offset(10, 180), Offset(10, 190), larvaePaint);
//     opisSpan = TextSpan(
//       text: '- larvae',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 175));
// //brood
//     canvas.drawLine(Offset(10, 195), Offset(10, 205), broodPaint);
//     opisSpan = TextSpan(
//       text: '- covered brood',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 190));
// //drone
//     canvas.drawLine(Offset(10, 210), Offset(10, 220), dronePaint);
//     opisSpan = TextSpan(
//       text: '- drone',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 205));
// //inserted
//     sides = 3;
//     radians = math.pi / 6;
//     angle = (math.pi * 2) / sides; //kąt

//     Offset center3 = Offset(10, 232);
//     Offset startPoint3 =
//         Offset(radius * math.cos(radians), radius * math.sin(radians));

//     path.moveTo(startPoint3.dx + center3.dx, startPoint3.dy + center3.dy);

//     for (int i = 1; i <= sides; i++) {
//       double x = radius * math.cos(radians + angle * i) + center3.dx;
//       double y = radius * math.sin(radians + angle * i) + center3.dy;
//       path.lineTo(x, y);
//     }
//     path.close();
//     canvas.drawPath(path, paintStroke);
//     opisSpan = TextSpan(
//       text: '- inserted',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 220));
// //deleted
//     sides = 3;
//     radians = math.pi / 2;
//     angle = (math.pi * 2) / sides; //kąt

//     Offset center4 = Offset(10, 243);
//     Offset startPoint4 =
//         Offset(radius * math.cos(radians), radius * math.sin(radians));

//     path.moveTo(startPoint4.dx + center4.dx, startPoint4.dy + center4.dy);

//     for (int i = 1; i <= sides; i++) {
//       double x = radius * math.cos(radians + angle * i) + center4.dx;
//       double y = radius * math.sin(radians + angle * i) + center4.dy;
//       path.lineTo(x, y);
//     }
//     path.close();
//     canvas.drawPath(path, paintStroke);
//     opisSpan = TextSpan(
//       text: '- deleted',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 235));
// //moved left
//     sides = 3;
//     radians = math.pi; //w lewo
//     angle = (math.pi * 2) / 3; //kąt (3- trójkąt)

//     Offset center5 = Offset(12, 259);
//     Offset startPoint5 =
//         Offset(radius * math.cos(radians), radius * math.sin(radians));

//     path.moveTo(startPoint5.dx + center5.dx, startPoint5.dy + center5.dy);

//     for (int i = 1; i <= sides; i++) {
//       double x = radius * math.cos(radians + angle * i) + center5.dx;
//       double y = radius * math.sin(radians + angle * i) + center5.dy;
//       path.lineTo(x, y);
//     }
//     path.close();
//     canvas.drawPath(path, paintStroke);
//     opisSpan = TextSpan(
//       text: '- moved left',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 250));
// //moved right
//     sides = 3;
//     radians = 0; //w lewo
//     angle = (math.pi * 2) / 3; //kąt (3- trójkąt)

//     Offset center6 = Offset(10, 274);
//     Offset startPoint6 =
//         Offset(radius * math.cos(radians), radius * math.sin(radians));

//     path.moveTo(startPoint6.dx + center6.dx, startPoint6.dy + center6.dy);

//     for (int i = 1; i <= sides; i++) {
//       double x = radius * math.cos(radians + angle * i) + center6.dx;
//       double y = radius * math.sin(radians + angle * i) + center6.dy;
//       path.lineTo(x, y);
//     }
//     path.close();
//     canvas.drawPath(path, paintStroke);
//     opisSpan = TextSpan(
//       text: '- moved right',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 265));
// //insulated
//     canvas.drawLine(
//         Offset(4, 293), Offset(16, 293), linePaint); // - (kreska pozioma)
//     canvas.drawLine(
//         Offset(4, 285), Offset(4, 293), linePaint); // | (kreska pionowa lewa)
//     canvas.drawLine(Offset(16, 285), Offset(16, 293), linePaint);
//     opisSpan = TextSpan(
//       text: '- insulated',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 280));
// //queen cell
//     canvas.drawCircle(Offset(10, 305), 3, matecznik);
//     opisSpan = TextSpan(
//       text: '- queen cell',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 295));
// //delete queen cell
//     canvas.drawCircle(Offset(10, 320), 3, delMat);
//     opisSpan = TextSpan(
//       text: '- delete queen cell',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 310));
// //iexcluder
//     canvas.drawLine(
//         Offset(4, 335), Offset(16, 335), lineExcluder); // - (kreska pozioma)
//     opisSpan = TextSpan(
//       text: '- excluder',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(20, 325));
// //nr body
//     opisSpan = TextSpan(
//       text: '1 - body number',
//       style: textStyle,
//     );
//     textOpis = TextPainter(
//       text: opisSpan,
//       textDirection: ui.TextDirection.ltr,
//     );
//     textOpis.layout(
//       minWidth: 0,
//       maxWidth: 200,
//     );
//     textOpis.paint(canvas, Offset(6, 340));
//   }

  @override
  bool shouldRepaint(CustomPainter old) {
    //throw UnimplementedError();
    return true;
  }
}
/*
    //dla kafelków
    InkWell(
      onTap: () {
        globals.ulID = hive.ulNr;
        Navigator.of(context).pushNamed(
          InfoScreen.routeName,
          arguments: hive.ulNr,
        );
      },
      splashColor: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        color: colory[kolor -
            1], //zeby byl taki sam kolor ula jak pasieki
        shape: RoundedRectangleBorder(
          //kształt karty
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 4, //cień za kartą
        margin: const EdgeInsets.all(8), //margines wokół karty
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                //całą zawatość kolmny stanowi wiersz
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      //zeby zrobić margines wokół części tekstowej
                      padding: const EdgeInsets.all(
                          6.00), //margines wokół części tekstowej
                      child: Column(
                        //ustawienie elementów jeden pod drugim - tytuł i opis
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
//nazwa ula
                            AppLocalizations.of(context)!.hive + " ${hive.ulNr}",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.bold,
                            ),
                            softWrap: false, //zawijanie tekstu
                            overflow: TextOverflow.fade, //skracanie tekstu
                          ),
                          Container(
//pojemnik na datę ostatniego przeglądu
                            padding: const EdgeInsets.only(top: 2),
                            height: 18,
                            child: 
 //ilość dni od ostatniego przegladu                           
                            difference != 1
                            ? Text(
                              "$difference " + AppLocalizations.of(context)!.days,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color.fromARGB(255, 69, 69, 69),
                              ),
                              softWrap: true, //zawijanie tekstu
                              maxLines: 2, //ilość wierszy opisu
                              overflow:
                                  TextOverflow.ellipsis, //skracanie tekstu
                            )
                            :Text(
                              "$difference " + AppLocalizations.of(context)!.day,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color.fromARGB(255, 69, 69, 69),
                              ),
                              softWrap: true, //zawijanie tekstu
                              maxLines: 2, //ilość wierszy opisu
                              overflow:
                                  TextOverflow.ellipsis, //skracanie tekstu
                            ),
                          ),
                          Padding(
                            //odstępy dla wiersza z ikonami
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
//rząd z ikonami
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceAround, //główna oś wyrównywania
                              children: <Widget>[
                                //elementy rzędu które sa widzetami
                                Row(
                                  children: <Widget>[
                                    // Icon( //jezeli np. kelner bo typ = 6
                                    //     Icons.thumb_up_off_alt,
                                    //     color: Color.fromARGB(255, 0, 253, 76),
                                    //   ),
                                    const SizedBox(
                                      width: 0,
                                    ),
//ikona zielona, zółta, czerwona
                                    hive.ikona == 'green'
                                        ? const Icon(
                                            Icons.hive,
                                            color:
                                                Color.fromARGB(255, 0, 255, 0),
                                          )
                                        : hive.ikona == 'yellow'
                                            ? const Icon(
                                                Icons.hive,
                                                color: Color.fromARGB(
                                                    255, 255, 251, 0),
                                              )
                                            : const Icon(
                                                Icons.hive,
                                                color: Color.fromARGB(
                                                    255, 255, 0, 0),
                                              ),
                                    const SizedBox(
                                      width: 0,
                                    ), //odległość 
                                    // Icon( //jezeli np. kelner bo typ = 6
                                    //     Icons.thumb_down_off_alt,
                                    //     color: Color.fromARGB(255, 253, 3, 3),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        
        
        
        ),
      ),
    );
  */
