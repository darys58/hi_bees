import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:intl/intl.dart';
//import '../screens/product_detail_screen.dart';
//import '../screens/frames_screen.dart';
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
    //obliczenie ile dni od odtatniego przeglądu
    final przeglad = DateTime.parse(hive.przeglad);
    //final date2 = DateTime.now();
    final difference = daysBetween(przeglad, now);

    return InkWell(
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
                            'Hive ${hive.ulNr}',
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
                              '$difference days',
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
                              '$difference day',
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
  }
}

/*
     
   */
/*

Container(
        padding: const EdgeInsets.all(15),
        child: Text(
          hive.title,
          style: Theme.of(context).textTheme.headline6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.7),
              color,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
      ),


    ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GridTile(
        child: GestureDetector(
          onTap: () {
             Navigator.of(context).pushNamed(
               ProductDetailScreen.routeName,
               arguments: product.id,
             );
          },
          
           child: Image.network(
             product.imageUrl,
             fit: BoxFit.cover,
          ),
        ),
        //  footer: GridTileBar(
        //    backgroundColor: Colors.black87,
        //    leading: Consumer<Product>(
        //      builder: (ctx, product, _) => IconButton(
        //            icon: Icon(
        //              product.isFavorite ? Icons.favorite : Icons.favorite_border,
        //            ),
        //            color: Theme.of(context).accentColor,
        //            onPressed: () {
        //              product.toggleFavoriteStatus();
        //            },
        //          ),
        //    ),
        //    title: Text(
        //      product.title,
        //      textAlign: TextAlign.center,
        //    ),
        //   //  trailing: IconButton(
        //   //    icon: const Icon(
        //   //      Icons.shopping_cart,
        //   //    ),
        //   //    onPressed: () {
        //   //      cart.addItem(product.id, product.price, product.title);
        //   //    },
        //   //    color: Theme.of(context).accentColor,
        //   //  ),
        //  ),
      ),
    );
 */

// }
//}
