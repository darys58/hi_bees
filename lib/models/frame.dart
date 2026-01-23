import 'package:flutter/foundation.dart'; //zeby mozna było ustawić ze argumenty są wymagane (dekorator @required)
//import 'package:http/http.dart' as http;


class Frame with ChangeNotifier {
  //dzięki ChangeNotifier dania mogą powiadamiać słuchaczy o zmianach np.polubienia dania
  final String id; //
  final String data; //data wpisu
  final int pasiekaNr; //
  final int ulNr; //
  final int korpusNr; // kolejność samych korpusów i półkorpusów od dołu
  final int typ; //2-korpus, 1-półkorpus
  final int ramkaNr; //
  final int ramkaNrPo; //numer ramki po przeglądzie
  final int rozmiar; //2-duza, 1-mała
  final int strona; // 1-lewa, 2-prawa
  final int zasob; //1-trut,2-czerw,3-larwy,4-jaja,5-pierzga,6-miód,7-zasklep,8-susz,9-węza,10-matka,
  final String wartosc; //ilość lub wartość zasobu        11-mateczniki,12-delMat,13-przeznaczenie,14-akcja
  final int arch; //0-niezarchiwizowane, 1-przesłane do chmury, 2-zaimportowane z chmury

  Frame({
    required this.id,
    required this.data,
    required this.pasiekaNr,
    required this.ulNr,
    required this.korpusNr,
    required this.typ,
    required this.ramkaNr,
    required this.ramkaNrPo,
    required this.rozmiar,
    required this.strona,
    required this.zasob,
    required this.wartosc,
    required this.arch,
  });

}
