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
/*
  void toggleFavoriteStatus(String id) {
    //przełącznik polubienia dania
    if (fav == '0') {
      fav = '1';
      wyslijFav(id,
          fav); //wysłanie na serwer jezeli jest połączenie z kontem uzytkownika
      Meals.updateFavorite(id, fav); //update w bazie lokalnej
    } else {
      fav = '0';
      wyslijFav(id, fav);
      Meals.updateFavorite(id, fav); //update w bazie lokalnej
    }
    notifyListeners(); //wysłanie powiadomienia aby wszyscy słuchacze wiedzieli ze trzeba wywołać powiadamiacze nasłuchujące bo nastąpoiła zmiana w Meal (zmiana w obiekcie), podobnie jak zmiana stanu
  }
*/
  //wysyłanie polubienie dania jezeli jest połączenie z kontem na cobytu.com
/*  Future<void> wyslijFav(String id, String fav) async {
    final http.Response response = await http.post(
      'https://cobytu.com/cbt_f_fav.php',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "idDania": id,
        "fav": fav,
        "deviceId": globals.deviceId,
      }),
    );
    print('******** fav *******');
    print(id + fav + globals.deviceId);
    print(response.body);
 */

  /*  if (response.statusCode >= 200 &&
        response.statusCode <= 400 &&
        json != null) {
      Map<String, dynamic> odpPost = json.decode(response.body);
      if (odpPost['success'] != 'ok') {
        if (kod != 'test_deviceId') {
          //jezeli nie był to test połączenia (tylko próba połączenia)
          _showAlert(context, allTranslations.text('L_KOMUNIKAT'),
              allTranslations.text('L_POLACZENIE_ERROR'));
        } else {
          print('brak połączenie tej apki z kontem na cobytu.com');
        }
      } else {
        //jezeli odpowiedz "ok"
        if (kod == 'test_deviceId') {
          _uzLogin = odpPost['uz_login']; //jest połączenie i zostanie wybrana część mówiąca o połaczeniu        
        } 
        else if (kod == 'rozlacz') {
          //jezeli było to rozłaczenie
          _showAlertOK(context, allTranslations.text('L_KOMUNIKAT'),
              allTranslations.text('L_ROZLOCZENIE_OK') + odpPost['uz_login']);
        }
        else {
          //jezeli nie był to test połączenia ani rozłaczenie (tylko połączenie i to udane)
          _showAlertOK(context, allTranslations.text('L_KOMUNIKAT'),
              allTranslations.text('L_POLACZENIE_OK') + odpPost['uz_login']);
        }
        //Navigator.of(context).pushNamed(OrderScreen.routeName);
      }
    } else {
      throw Exception('Failed to create OdpPost. z połączenia konta z apką');
    }
*/
  //}

/*  void changeStolik(String id, String ile) {
    stolik = ile;
    Meals.updateKoszyk(id, ile);  
    notifyListeners(); 
  }
*/
}
