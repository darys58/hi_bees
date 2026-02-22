import 'package:flutter/material.dart';
//import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
//import 'package:connectivity_plus/connectivity_plus.dart'; //czy jest Internet
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;
import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
import '../helpers/notification_helper.dart';
import '../models/apiarys.dart';
// import '../models/frame.dart';
import '../models/hives.dart';
import 'package:flutter/services.dart';
// import '../models/infos.dart';
// import '../screens/activation_screen.dart';
// import '../models/frames.dart';
import '../models/queen.dart';
// import 'frames_detail_screen.dart';
import '../models/info.dart';
import '../models/infos.dart';
import '../models/dodatki2.dart';

class InfosEditScreen extends StatefulWidget {
  static const routeName = '/infos_edit';

  @override
  State<InfosEditScreen> createState() => _InfosEditScreenState();
}

class _InfosEditScreenState extends State<InfosEditScreen> {
  final _formKey1 = GlobalKey<FormState>();
  //final _formKey2 = GlobalKey<FormState>();
  //var now = new DateTime.now();
  //var formatterY = new DateFormat('yyyy-MM-dd');
  var formatterHm = new DateFormat('H:mm');
  bool _isInit = true;
  int nowaPasieka = 0;
  int nowyUl = 0;
  String nowaKategoria = '0';
  String nowyParametr = '0';
  String nowyWartosc = '0';
  String typUla = 'WIELKOPOLSKI'; //wielkopolski, dadant itp
  String rodzajUla = ''; //ul, odkład, mini
  int matkaID = 0; //numer id matki - index z tabeli "matka"
  String dmRamki = ''; //ilośc dm2 w ramce - zalezna od typu ula i wielkosci ramki
  String? nowyMiara;
  String? nowyUwagi;
  String? nowyTemp;
  String? nowyCzas;
  bool edycja = false;
  String tytulEkranu = '';
  List<Info> info = [];
  TextEditingController dateController = TextEditingController();
  //int _nowaIloscRamek = 0; //zmieniana nowym wpisem
  List<bool> _selectedZakresUli = <bool>[true, false]; //tylko ten | wszystkie

  // Zmienne stanu dla sekcji "Przypomnij"
  bool _przypomnienieEnabled = false;
  int _przypomnienieDni = 5;
  int _przypomnienieGodzina = 8;
  int _przypomnienieMinuta = 0;



  @override
  void didChangeDependencies() {
  if (_isInit) {
    final routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, Object>;
    final idInfo = routeArgs['idInfo'];
    final kategoria = routeArgs['kategoria'];
    final parametr = routeArgs['parametr'];
    final wartosc = routeArgs['wartosc'];
    final idPasieki = routeArgs['idPasieki'];
    final idUla = routeArgs['idUla'];
    //final temp = routeArgs['temp']; //ślepy argument bo jest błąd jak jest nowy wpis

    //print('idInfo= $idInfo||');
    // print('wartosc= $wartosc||');
     // print('ikona ula= ${globals.ikonaUla}||');
    //print('dataWpisu= ${globals.dataWpisu}||');
    //print('dataInspekcji= ${globals.dataInspekcji}||');
    
    //uzyskanie dostępu do danych w tabeli Dodatki2 - typy własne uli
    final dod2Data = Provider.of<Dodatki2>(context);
    final dod2 = dod2Data.items;

    
    //jezeli edycja istniejącego wpisu to wczytanie danych zbioru
    if (idInfo != '') {
      edycja = true;
      final infoData = Provider.of<Infos>(context, listen: false);
      info = infoData.items.where((element) { 
        return element.id.toString() == ('$idInfo');
      }).toList();
      
      dateController.text = info[0].data;
      nowaPasieka = info[0].pasiekaNr;
      nowyUl = info[0].ulNr;
      nowaKategoria = info[0].kategoria;
      nowyParametr = info[0].parametr;
      nowyWartosc = info[0].wartosc;
      nowyMiara = info[0].miara;
      if(nowyParametr == AppLocalizations.of(context)!.numberOfFrame + " = ") {
        typUla = info[0].miara; //dla iloscRamek =
        globals.typUla = typUla;
        rodzajUla = info[0].pogoda; //dane tylko dla iloscRamek =
      }
      if(nowaKategoria == 'queen' && info[0].pogoda != '') matkaID = int.parse(info[0].pogoda);
      else{
          //pobranie matek dla tego ula bo edytowane info nie ma jeszcze ID matki
          final queensData = Provider.of<Queens>(context);
          List<Queen> queens = queensData.items.where((qu) {
            return qu.pasieka == globals.pasiekaID && qu.ul == globals.ulID ;
          }).toList();
          if(queens.isNotEmpty) matkaID = queens[0].id;//jest matka podłączona do ula
          else matkaID = 0; //nie ma matki połaczonej z ulem
      }
      nowyTemp = info[0].temp;
      nowyCzas = info[0].czas;
      nowyUwagi = info[0].uwagi;
      tytulEkranu = AppLocalizations.of(context)!.editingInfo;
      // Załadowanie danych powiadomienia indywidualnego (jeśli istnieje)
      if (nowaKategoria == 'feeding' || nowaKategoria == 'treatment') {
        DBHelper.getPowiadomienieByInfoId(info[0].id).then((data) {
          if (data.isNotEmpty && mounted) {
            setState(() {
              _przypomnienieEnabled = (data[0]['aktywne'] as int) == 1;
              _przypomnienieDni = data[0]['dni'] as int? ?? 5;
              _przypomnienieGodzina = data[0]['godzina'] as int? ?? 8;
              _przypomnienieMinuta = data[0]['minuta'] as int? ?? 0;
            });
          }
        });
      }
    }else { //a jezeli dodanie nowego info
      edycja = false;
      dateController.text = globals.dataWpisu; //ostatnio wybrana data      DateTime.now().toString().substring(0, 10);
      nowaPasieka = int.parse(idPasieki.toString());
      nowyUl = int.parse(idUla.toString());
      nowaKategoria = kategoria.toString();
      nowyParametr = parametr.toString();
      nowyWartosc = wartosc.toString();
      
      if(nowyParametr == AppLocalizations.of(context)!.numberOfFrame + " = ") {//pole "miara" = typ ula
        nowyMiara = typUla;//wartość domyślna typUla
        rodzajUla = AppLocalizations.of(context)!.hIve; //wartość domyślna rodzajUla //pole "pogoda" = rodzaj ula    
      } else nowyMiara = '';
      
      
      if (nowyParametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.small +  " " + AppLocalizations.of(context)!.frame +  " x" ){      
                      //nowyParametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.big +  " " + AppLocalizations.of(context)!.frame +  " x" 
          switch (globals.typUla) {
            case 'WIELKOPOLSKI': dmRamki = '35175'; //dm2, węza: 335x105 (mała ramka: 360x130)
              break;
            case 'DADANT': dmRamki = '49680';       //dm2, węza: 414x120 (mała ramka: 435x145)
              break;
            case 'OSTROWSKIEJ': dmRamki = '68675';  //dm2, węza: 335x205 (ramka: 360x230)
              break;
            case 'WARSZAWSKI ZWYKŁY': dmRamki = '28600';  //dm2, węza: 220x130 (mała ramka: 240x160)
              break;
            case 'WARSZAWSKI POSZERZANY': dmRamki = '35175';  //dm2, węza: 335x105 (mała ramka: 360x130)
              break;
            case 'APIPOL': dmRamki = '37260';  //dm2, węza: 414x90 (ramka: 435x115)
              break;
            case 'LANGSTROTH': dmRamki = '37260';  //dm2, węza: 414x90 (mała ramka: 435x115)
              break;
            case 'ZANDER': dmRamki = '74100';  //dm2, węza: 390x190 (ramka: 420x220)
              break;
            case 'GERSTUNG': dmRamki = '39100';  //dm2, węza: 230x170 (mała ramka: 260x200)
              break;
            case 'APIMAYE': dmRamki = '37260';  //dm2, węza: 414x90 (mała ramka: 435x115)
              break;
            case 'DEUTSCH NORMAL': dmRamki = '49680'; //dm2, węza: 414x120 (mała ramka: 435x145)
              break;
            case 'NORMALMASS': dmRamki = '84000';  //dm2, węza: 400x210 (ramka: 435x240)
              break;
            case 'FRANKENBEUTE': dmRamki = '50600';  //dm2, węza: 440x115 (mała ramka: 470x145)
              break;
            case 'NATIONAL': dmRamki = '88150';  //dm2, węza: 430x205 (ramka: 460x235)
              break;
            case 'WBC': dmRamki = '37260';  //dm2, węza: 414x90 (mała ramka: 435x115)
              break;
            case 'WIELKOPOLSKI GÓRSKI': dmRamki = '51925';  //dm2, węza: 335x155 (ramka: 360x180)
              break;
            case 'TYP A': dmRamki = dod2[0].z;  //dm2, ramka mała własna TYP A
              break;
            case 'TYP B': dmRamki = dod2[1].z;  //dm2, ramka mała własna TYP B
              break;
            case 'TYP C': dmRamki = dod2[2].z;  //dm2, ramka mała własna TYP C
              break;
            case 'TYP D': dmRamki = dod2[3].z;  //dm2, ramka mała własna TYP D
              break;
            default: dmRamki = '0';// dla typów innych niz powyzsze
          }          
      }else if (nowyParametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.big +  " " + AppLocalizations.of(context)!.frame +  " x"  ){                   
          //print('globals.typUla = ${globals.typUla}');
          switch (globals.typUla) {
            case 'WIELKOPOLSKI': dmRamki = '78725'; //dm2, węza: 335x235 (duza ramka: 360x260)
              break;
            case 'DADANT': dmRamki = '109710'; //dm2, węza: 414x265 (duza ramka: 435x300)
              break;
            case 'OSTROWSKIEJ': dmRamki = '68675';  //dm2, węza: 335x205 (ramka: 360x230)
              break;
            case 'WARSZAWSKI ZWYKŁY': dmRamki = '88000';  //dm2, węza: 220x400 (duza ramka: 240x435)
              break;
            case 'WARSZAWSKI POSZERZANY': dmRamki = '112000';  //dm2, węza: 280x400 (duza ramka: 300x435)
              break;
            case 'APIPOL': dmRamki = '37260';  //dm2, węza: 414x90 (ramka: 435x115)
              break;
            case 'LANGSTROTH': dmRamki = '84870';  //dm2, węza: 414x205 (duza ramka: 435x230)
              break;
            case 'ZANDER': dmRamki = '74100';  //dm2, węza: 390x190 (ramka: 420x220)
              break;
            case 'GERSTUNG': dmRamki = '64400';  //dm2, węza: 280x230 (duza ramka: 410x260)
              break;
            case 'APIMAYE': dmRamki = '86820';  //dm2, węza: 424x205 (duza ramka: 448x232)
              break;
            case 'DEUTSCH NORMAL': dmRamki = '109710'; //dm2, węza: 414x265 (duza ramka: 435x300)
              break;
            case 'NORMALMASS': dmRamki = '84000';  //dm2, węza: 400x210 (ramka: 435x240)
              break;
            case 'FRANKENBEUTE': dmRamki = '118800';  //dm2, węza: 440x270 (duza ramka: 470x300)
              break;
            case 'NATIONAL': dmRamki = '88150';  //dm2, węza: 430x205 (ramka: 460x235)
              break;
            case 'WBC': dmRamki = '84870';  //dm2, węza: 414x205 (duza ramka: 435x230)
              break;
            case 'WIELKOPOLSKI GÓRSKI': dmRamki = '51925';  //dm2, węza: 335x155 (ramka: 360x180)
              break;
            case 'TYP A': dmRamki = dod2[0].u;  //dm2, ramka duza własna TYP A
              break;
            case 'TYP B': dmRamki = dod2[1].u;  //dm2, ramka duza własna TYP B
              break;
            case 'TYP C': dmRamki = dod2[2].u;  //dm2, ramka duza własna TYP C
              break;
            case 'TYP D': dmRamki = dod2[3].u;  //dm2, ramka duza własna TYP D
              break;
            default: dmRamki = '0';// dla typów innych niz powyzsze
          }          
      }
//print('nowyMiara = $nowyMiara');
      nowyUwagi = '';
      tytulEkranu = AppLocalizations.of(context)!.addInfo;
      if(nowaKategoria == 'queen') {
        //pobranie matek dla tego ula
          final queensData = Provider.of<Queens>(context);
          List<Queen> queens = queensData.items.where((qu) {
            return qu.pasieka == globals.pasiekaID && qu.ul == globals.ulID ;
          }).toList();
          matkaID = queens[0].id;  
      }
      if(nowyWartosc == AppLocalizations.of(context)!.onBodyNumber) nowyMiara = '1';//wartość domyslna korpusu dla kraty odgrodowej przy dodawaniu wpisu
      if(nowyParametr == " " + AppLocalizations.of(context)!.excluder + " -") nowyMiara = '0';//wartość domyslna dla usunietej kraty odgrodowej, musi być 0 bo jest zameniana na int w frames_screen
      if(nowyParametr == AppLocalizations.of(context)!.honey + " = ") nowyMiara = 'kg'; //wartość domyslna dla miodu w kg
      if(nowyParametr == AppLocalizations.of(context)!.beePollen + " = ") nowyMiara = 'ml'; //wartość domyslna dla pyłku w ml
      if(nowyParametr ==  " " + AppLocalizations.of(context)!.beePollen + " =  ") nowyMiara = 'l'; //wartość domyslna dla pyłku w l
      if(nowyParametr == AppLocalizations.of(context)!.deadBees) nowyMiara = 'ml';//wartość domyslna dla osypu pszczół
      if(nowyParametr ==  AppLocalizations.of(context)!.syrup + " 1:1") nowyMiara = 'l'; //wartość domyslna dla syrop 1:1
      if(nowyParametr ==  AppLocalizations.of(context)!.syrup + " 3:2") nowyMiara = 'l'; //wartość domyslna dla syrop 3:2
      if(nowyParametr ==  AppLocalizations.of(context)!.invert) nowyMiara = 'l'; //wartość domyslna dla syrop - invert
      if(nowyParametr ==  AppLocalizations.of(context)!.candy) nowyMiara = 'kg'; //wartość domyslna dla ciasta
      if(nowyParametr ==  'apivarol') nowyMiara = AppLocalizations.of(context)!.dose; //wartość domyslna dla apivarol
      if(nowyParametr ==  'biovar') nowyMiara = AppLocalizations.of(context)!.belts; //wartość domyslna dla biovar
      if(nowyParametr == AppLocalizations.of(context)!.acid) nowyMiara = 'ml'; //wartość domyslna dla kwasu w ml
      if(nowyParametr == " " + AppLocalizations.of(context)!.acid) nowyMiara = 'g'; //wartość domyslna dla kwasu w g
      if(nowyParametr ==  'varroa') nowyMiara = AppLocalizations.of(context)!.mites; //wartość domyslna dla varroa
     
      //zeby wpis(notatka) z przeglądu dotyczył tylko wybranego przegladu i nie zmieniał czasu
      if(nowyParametr == AppLocalizations.of(context)!.inspection){
        // to pobranie wszystkich info dla ula
        final infoData = Provider.of<Infos>(context, listen: false);
        //pobranie info o tym przeglądzie bo powinien być (czyli zgadza się data, nr ula, kategoria i parametr)
        info = infoData.items.where((element) { 
          return element.data == globals.dataInspekcji && element.ulNr == idUla && element.kategoria == 'inspection' && element.parametr == '${AppLocalizations.of(context)!.inspection}'; //data, nr ula, kategoria i parametr
        }).toList();
        dateController.text = info[0].data;
        nowaPasieka = info[0].pasiekaNr;
        nowyUl = info[0].ulNr;
        nowaKategoria = info[0].kategoria;
        nowyParametr = info[0].parametr;
        nowyWartosc = info[0].wartosc;
        nowyMiara = info[0].miara;
        nowyTemp = info[0].temp;
        nowyCzas = info[0].czas;
        nowyUwagi = info[0].uwagi;
        tytulEkranu = AppLocalizations.of(context)!.editingInfo;
        edycja = true; //to jest to defacto edycja notatki
      }
    }
    // print('idInfo === $idInfo|');
    // print('id === ${info[0].id}|');
    // print('nowyParametr === $nowyParametr');
    } //od if (_isInit) {
    _isInit = false;
    super.didChangeDependencies();
  }

  //dialog z wyborem liczby dni (0-30) - wzorowany na raport_screen
  void _showDaysPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.remindAfterDays, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 230,
              width: 300,
              child: ListWheelScrollView(
                itemExtent: 70,
                physics: FixedExtentScrollPhysics(),
                perspective: 0.009,
                controller: FixedExtentScrollController(initialItem: _przypomnienieDni),
                children: [
                  for (var i = 0; i <= 30; i++)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _przypomnienieDni = i;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        '$i',
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle dataButtonStyle = OutlinedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor, //Color.fromARGB(255, 233, 140, 0),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(170.0, 35.0),
      textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    );
     final ButtonStyle dataButtonStyleNote = OutlinedButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 211, 211, 211),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(170.0, 35.0),
      textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    );
    // final ButtonStyle buttonStyle = OutlinedButton.styleFrom(
    //   padding: const EdgeInsets.all(2.0),
    //   backgroundColor: Theme.of(context).primaryColor, //Color.fromARGB(255, 233, 140, 0),
    //   shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    //   side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
    //   fixedSize: Size(66.0, 35.0),
    //   //textStyle: const TextStyle(color: Color.fromARGB(255, 162, 103, 0),)
    // );
     final ButtonStyle buttonSumaZasobow = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(2.0),
      backgroundColor: Color.fromARGB(255, 211, 211, 211),
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      side:BorderSide(color: Color.fromARGB(255, 162, 103, 0),width: 1,),
      fixedSize: Size(85.0, 35.0),
      textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),)
    );

    // //uzyskanie dostępu do danych w tabeli Dodatki2 - typy własne uli
    // final dod22Data = Provider.of<Dodatki2>(context);
    // final dod22 = dod22Data.items;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          tytulEkranu,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0,right: 20.0, bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Form(
                key: _formKey1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if(nowaKategoria == 'inspection')
                          Text(
                              AppLocalizations.of(context)!.oUlu,
                              style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                        if(nowaKategoria == 'equipment')
                          Text(
                              AppLocalizations.of(context)!.oWyposazeniu,
                              style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                        if(nowaKategoria == 'colony')
                          Text(
                              AppLocalizations.of(context)!.oRodzinie,
                              style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                        if(nowaKategoria == 'queen')
                          Text(
                              AppLocalizations.of(context)!.oMatce + ' ID' + matkaID.toString(),
                              style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                        if(nowaKategoria == 'harvest')
                          Text(
                              AppLocalizations.of(context)!.oZbiorach,
                              style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                        if(nowaKategoria == 'feeding')
                          Text(
                              AppLocalizations.of(context)!.oDokarmianiu,
                              style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                        if(nowaKategoria == 'treatment')
                          Text(
                              AppLocalizations.of(context)!.oLeczeniu,
                              style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
                            ),   
                
                        
                                          
                    ]),
                    SizedBox(height: 20.0,),
  //** */ data                
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
 //data przeglądu  
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.noteDate),
                            //czy info dotyczy przegladu czyli edycji notatki
                            nowyParametr == AppLocalizations.of(context)!.inspection
                            ? OutlinedButton(
                                style: dataButtonStyleNote,
                                onPressed: null,
                                child: Text(dateController.text,
                                  style: const TextStyle(
                                    //fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 0, 0,0))),
                              )
                            
                            : OutlinedButton(
                              style: dataButtonStyle,
                              onPressed: () async {
                                DateTime? pickedDate =
                                  await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.parse(dateController.text),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                    builder:(context , child){
                                      return Theme( data: Theme.of(context).copyWith(  // override MaterialApp ThemeData
                                        colorScheme: ColorScheme.light(
                                          primary: Color.fromARGB(255, 236, 167, 63),//header and selced day background color
                                          onPrimary: Colors.white, // titles and 
                                          onSurface: Colors.black, // Month days , years 
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.black, // ok , cancel    buttons
                                          ),
                                        ),
                                      ),  child: child!   );  // pass child to this child
                                    }
                                  );
                                if (pickedDate != null) {
                                  String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                                  setState(() {
                                    dateController.text = formattedDate;
                                    globals.dataWpisu = formattedDate;
                                  });
                                } else {print("Date is not selected");}
                              },

                                child: Text(dateController.text ,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontSize: 15),),   
                            ),
                        ]),  
                        SizedBox(width: 10),
//ten ul czy wszystkie - dla dodawaia dokarmiania lub leczenia
                        if(edycja == false && (nowaKategoria == 'feeding' || nowaKategoria == 'treatment')) //jezeli dodawanie dokarmiania lub leczenia
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(AppLocalizations.of(context)!.hIveNr),
                              ToggleButtons(
                                direction: Axis.horizontal, 
                                onPressed: (int index) {
                                  setState(() {
                                    // Dotknięty przycisk ma wartość „prawda”, a pozostałe – „fałsz”.
                                    for (int i = 0; i < _selectedZakresUli.length; i++) {
                                      _selectedZakresUli[i] = i == index;
                                    }
                                    // Przy wyborze “wszystkie ule” wyłącz przypomnienie
                                    if (_selectedZakresUli[1] == true) {
                                      _przypomnienieEnabled = false;
                                    }
                                  });
                                },
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                                borderColor: Color.fromARGB(255, 162, 103, 0),
                                selectedBorderColor: Color.fromARGB(255, 162, 103, 0), //obramowanie wybranego przycisku
                                selectedColor: Color.fromARGB(255, 0, 0, 0), //napis wybranego
                                fillColor: Theme.of(context).primaryColor, //tło wybranego
                                color: Color.fromARGB(255, 78, 78, 78), //napis niewybranego
                                constraints: const BoxConstraints(
                                  minHeight: 38.0,
                                  minWidth: 60.0,
                                ),
                                isSelected: _selectedZakresUli,
                                children: [ //napisy na przełącznikach
                                  Text(nowyUl.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text(' ' + AppLocalizations.of(context)!.all + '  ', textAlign: TextAlign.center),
                                ],  //lewa, obie, prawa
                              ),
                            ],
                          ),
//dla edycji i dodawania bez dokarmiania i leczenia                              
                          if(edycja == true || (edycja == false && (nowaKategoria != 'feeding' && nowaKategoria != 'treatment'))) //jezeli nie jest to dodawanie dokarmiania lub leczenia
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(AppLocalizations.of(context)!.hIveNr),
                                OutlinedButton(
                                    style: buttonSumaZasobow,
                                    onPressed: null,
                                    child: Text(nowyUl.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color.fromARGB(255, 0, 0,0))),
                            )]) ,  
                        
                          
                    ]),

                    SizedBox(
                      height: 20,
                    ),
//******************************************** */
// dodatkowe pola dla wyposazenia - ilość ramek: typ i rodzaj ula
//********************************************* */

//rodzaj ula: ul, odkład, mini              
                  if (nowaKategoria == 'equipment')    
                    if (nowyParametr ==  AppLocalizations.of(context)!.numberOfFrame + " = ")
                      Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                          width: 80,
                          child: Text(AppLocalizations.of(context)!.kIndHive + ':',
                            style: TextStyle(
                              //fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                            softWrap: true, //zawijanie tekstu
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 200,
                              margin: EdgeInsets.only(top: 0, bottom: 0),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: rodzajUla,  
                                items: [
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.hIve),
                                                  value: AppLocalizations.of(context)!.hIve),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.nUc),
                                                  value: AppLocalizations.of(context)!.nUc),
                                  DropdownMenuItem(child: Text('Mini'),
                                                  value: 'Mini'),                                                                                                        
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    rodzajUla = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),


//typ ula              
                  if (nowaKategoria == 'equipment')    
                    if (nowyParametr ==  AppLocalizations.of(context)!.numberOfFrame + " = ")
                      Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                          width: 80,
                          child: Text(AppLocalizations.of(context)!.hIveType + ':',
                            style: TextStyle(
                              //fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                            softWrap: true, //zawijanie tekstu
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 200,
                              margin: EdgeInsets.only(top: 0, bottom: 0),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: typUla,  
                                items: [
                                  DropdownMenuItem(child: Text('WIELKOPOLSKI'),
                                                  value: 'WIELKOPOLSKI'),
                                  DropdownMenuItem(child: Text('DADANT'),
                                                  value: 'DADANT'),
                                  DropdownMenuItem(child: Text('OSTROWSKIEJ'),
                                                  value: 'OSTROWSKIEJ'),
                                  DropdownMenuItem(child: Text('WARSZAWSKI ZWYKŁY'),
                                                  value: 'WARSZAWSKI ZWYKŁY'),
                                  DropdownMenuItem(child: Text('WARSZAWSKI POSZERZANY'),
                                                  value: 'WARSZAWSKI POSZERZANY'),
                                  DropdownMenuItem(child: Text('APIPOL'),
                                                  value: 'APIPOL'),
                                  DropdownMenuItem(child: Text('LANGSTROTH'),
                                                  value: 'LANGSTROTH'),
                                  DropdownMenuItem(child: Text('ZANDER'),
                                                  value: 'ZANDER'),
                                  DropdownMenuItem(child: Text('GERSTUNG'),
                                                  value: 'GERSTUNG'),
                                  DropdownMenuItem(child: Text('APIMAYE'),
                                                  value: 'APIMAYE'),
                                  DropdownMenuItem(child: Text('DEUTSCH NORMAL'),
                                                  value: 'DEUTSCH NORMAL'),
                                  DropdownMenuItem(child: Text('NORMALMASS'),
                                                  value: 'NORMALMASS'),
                                  DropdownMenuItem(child: Text('FRANKENBEUTE'),
                                                  value: 'FRANKENBEUTE'),
                                  DropdownMenuItem(child: Text('NATIONAL'),
                                                  value: 'NATIONAL'),
                                  DropdownMenuItem(child: Text('WBC'),
                                                  value: 'WBC'),
                                  DropdownMenuItem(child: Text('WIELKOPOLSKI GÓRSKI'),
                                                  value: 'WIELKOPOLSKI GÓRSKI'),
                                  DropdownMenuItem(child: Text('TYP A'), //własna nazwa ula TYP A
                                                  value: 'TYP A'), 
                                  DropdownMenuItem(child: Text('TYP B'),
                                                  value: 'TYP B'),
                                  DropdownMenuItem(child: Text('TYP C'),
                                                  value: 'TYP C'),
                                  DropdownMenuItem(child: Text('TYP D'),
                                                  value: 'TYP D'),
                                  DropdownMenuItem(child: Text('MINI PLUS'),
                                                  value: 'MINI PLUS'),                                  
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.wEeddingHive),
                                                  value: AppLocalizations.of(context)!.wEeddingHive), 
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    typUla = newValue!.toString(); 
                                    nowyMiara = typUla;
                                    globals.typUla = typUla;
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),
                  
                  if (nowaKategoria == 'equipment')    
                    if (nowyParametr ==  AppLocalizations.of(context)!.numberOfFrame + " = ")
                      SizedBox(height: 10),


//********************************************* */
                    //** */ parametr (Cecha:)
 //******************************************** */                      
      // dla parametrów które nie są w tym miejscu modyfikowane np. przez (ml), (kg), (sztuki) itp. dodatkowe opisy                   
                    if (nowyParametr !=  AppLocalizations.of(context)!.honey + " = " &&  //oprócz miód w kg
                        nowyParametr !=  AppLocalizations.of(context)!.beePollen + " = " &&  //oprócz pyłek w ml
                        nowyParametr !=  " " + AppLocalizations.of(context)!.beePollen + " =  " &&//oprócz pyłek w l
                        nowyParametr !=  AppLocalizations.of(context)!.deadBees &&
                        nowyParametr !=  AppLocalizations.of(context)!.syrup + " 1:1" && //oprócz dokarmianie syrop 1:1 w l
                        nowyParametr !=  AppLocalizations.of(context)!.syrup + " 3:2" && //oprócz dokarmianie syrop 3:2 w l
                        nowyParametr !=  AppLocalizations.of(context)!.invert && //oprócz dokarmianie invert w l
                        nowyParametr !=  AppLocalizations.of(context)!.candy && //oprócz dokarmianie ciasto w kg
                        nowyParametr !=  AppLocalizations.of(context)!.removedFood && //oprócz dokarmianie usunieto pokarm
                        nowyParametr !=  AppLocalizations.of(context)!.leftFood && //oprócz dokarmianie pozostało pokarm
                        nowyParametr !=  'apivarol' &&
                        nowyParametr !=  'biovar' &&
                        nowyParametr !=  AppLocalizations.of(context)!.acid &&
                        nowyParametr !=  " " + AppLocalizations.of(context)!.acid &&
                        nowyParametr !=  'varroa') 
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':', // Cecha:
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 300,
                          //   child: 
    //cecha - nazwa cechy - wyśrodkowana                      
                            Text( nowyParametr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                          // ),
                        ]
                      ),

    
    //parametr dla miód w kg              
                    if (nowyParametr ==  AppLocalizations.of(context)!.honey + " = ")
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                         // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( AppLocalizations.of(context)!.honey + " (kg) = ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                        //  ),
                        ]
                      ),
    
    //parametr dla pyłek w l               
                    if (nowyParametr ==  " " + AppLocalizations.of(context)!.beePollen + " =  ")
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                            // width: 200,
                            // child:
                             Text( AppLocalizations.of(context)!.beePollen + " (l) = ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                         // ),
                        ]
                      ),
//parametr dla pyłek w ml               
                    if (nowyParametr ==  AppLocalizations.of(context)!.beePollen + " = ")
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( AppLocalizations.of(context)!.beePollen + " (ml) = ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                         // ),
                        ]
                      ),
 //parametr dla osypu pszczół w ml               
                    if (nowyParametr ==  AppLocalizations.of(context)!.deadBees)
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( AppLocalizations.of(context)!.deadBees + " (ml) = ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                        //  ),
                        ]
                      ),
//parametr dla dokarmianie - syrop 1:1 w l               
                    if (nowyParametr ==  AppLocalizations.of(context)!.syrup + " 1:1")
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( AppLocalizations.of(context)!.syrup + " 1:1" + " (l) = ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                          // ),
                        ]
                      ),                      
//parametr dla dokarmianie - syrop 3:2 w l               
                    if (nowyParametr ==  AppLocalizations.of(context)!.syrup + " 3:2")
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( AppLocalizations.of(context)!.syrup + " 3:2" + " (l) = ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                        //  ),
                        ]
                      ),  
//parametr dla dokarmianie - syrop - invert w l               
                    if (nowyParametr ==  AppLocalizations.of(context)!.invert)
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child:
                             Text( AppLocalizations.of(context)!.invert + " (l) = ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                         // ),
                        ]
                      ),  
//parametr dla dokarmianie - ciasto w kg              
                    if (nowyParametr ==  AppLocalizations.of(context)!.candy)
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( AppLocalizations.of(context)!.candy + " (kg) = ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                        //  ),
                        ]
                      ),  
//parametr dla dokarmianie - usunięto ciasto w %              
                    if (nowyParametr ==  AppLocalizations.of(context)!.removedFood)
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( AppLocalizations.of(context)!.removedFood + " (%)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                         // ),
                        ]
                      ),
//parametr dla dokarmianie - pozostało ciasto w %              
                    if (nowyParametr ==  AppLocalizations.of(context)!.leftFood)
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( AppLocalizations.of(context)!.leftFood + " (%)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                         // ),
                        ]
                      ),
//parametr dla leczenie - apivarol             
                    if (nowyParametr == 'apivarol')
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( "apivarol (" + AppLocalizations.of(context)!.dose + ")",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                         // ),
                        ]
                      ),
//parametr dla leczenie - biovar            
                    if (nowyParametr == 'biovar')
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( "biovar (" + AppLocalizations.of(context)!.belts + ")",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                        //  ),
                        ]
                      ),
//parametr dla leczenie - biovar            
                    if (nowyParametr == 'varroa')
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child:
                             Text( "varroa (" + AppLocalizations.of(context)!.mites+ ")",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                        //  ),
                        ]
                      ),
//parametr dla leczenie - kwas          
                    if (nowyParametr == AppLocalizations.of(context)!.acid)
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( AppLocalizations.of(context)!.acid + " (ml)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                        //  ),
                        ]
                      ),
//parametr dla leczenie - kwas w g         
                    if (nowyParametr == " " + AppLocalizations.of(context)!.acid)
                      Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(
                          //   width: 65,
                          //   child: Text(AppLocalizations.of(context)!.pArametr + ':',
                          //     style: TextStyle(
                          //       //fontWeight: FontWeight.bold,
                          //       fontSize: 15,
                          //       color: Colors.black,
                          //     ),
                          //     softWrap: true, //zawijanie tekstu
                          //     overflow: TextOverflow.fade,
                          //   ),
                          // ),
                          // SizedBox(width: 20),
                          // SizedBox(
                          //   width: 200,
                          //   child: 
                            Text( AppLocalizations.of(context)!.acid + " (g)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                         // ),
                        ]
                      ),




                   SizedBox(height: 20), //przed wartością
 //*********************************************************** */                  
                   //** */ Wartość - lista wyboru
//************************************************************ */
//dla matka1 Quality
                    if (nowaKategoria == 'queen')    
                      if (nowyParametr == AppLocalizations.of(context)!.queen + '  ' + AppLocalizations.of(context)!.isIs) //Quality
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        //     SizedBox(
                        //   width: 65,
                        //   child: Text(AppLocalizations.of(context)!.vAlue + ':',
                        //     style: TextStyle(
                        //       //fontWeight: FontWeight.bold,
                        //       fontSize: 15,
                        //       color: Colors.black,
                        //     ),
                        //     softWrap: true, //zawijanie tekstu
                        //     overflow: TextOverflow.fade,
                        //   ),
                        // ),
                        // SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 200,
                              margin: EdgeInsets.only(bottom: 15),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: nowyWartosc,  
                                items: [
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.veryGood),
                                                  value:AppLocalizations.of(context)!.veryGood),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.good),
                                                  value:AppLocalizations.of(context)!.good),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.big),
                                                  value:AppLocalizations.of(context)!.big),
                                  DropdownMenuItem(child: Text('ok'),value: 'ok'),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.canceled),
                                                  value:AppLocalizations.of(context)!.canceled),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.small),
                                                  value:AppLocalizations.of(context)!.small),                                             
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.weak),
                                                  value:AppLocalizations.of(context)!.weak),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.exchange),
                                                  value:AppLocalizations.of(context)!.exchange),                                       
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    nowyWartosc = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),
 //dla matka2 znak + numer                   
                    if (nowaKategoria == 'queen')    
                      if (nowyParametr ==  " " + AppLocalizations.of(context)!.queen) //Mark + number
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        //     SizedBox(
                        //   width: 65,
                        //   child: Text(AppLocalizations.of(context)!.vAlue + ':',
                        //     style: TextStyle(
                        //       //fontWeight: FontWeight.bold,
                        //       fontSize: 15,
                        //       color: Colors.black,
                        //     ),
                        //     softWrap: true, //zawijanie tekstu
                        //     overflow: TextOverflow.fade,
                        //   ),
                        // ),
                        // SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 200,
                              margin: EdgeInsets.only(top: 15, bottom: 15),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: nowyWartosc,  
                                items: [
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.unmarked1),
                                                  value:AppLocalizations.of(context)!.unmarked),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedWhite),
                                                  value:AppLocalizations.of(context)!.markedWhite),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedYellow),
                                                  value:AppLocalizations.of(context)!.markedYellow),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedRed),
                                                  value:AppLocalizations.of(context)!.markedRed),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedGreen),
                                                  value:AppLocalizations.of(context)!.markedGreen),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedBlue),
                                                  value:AppLocalizations.of(context)!.markedBlue),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.markedOther),
                                                  value:AppLocalizations.of(context)!.markedOther),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.missing1),
                                                  value:AppLocalizations.of(context)!.missing),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.gone1),
                                                  value:AppLocalizations.of(context)!.gone),                                                                        
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    nowyWartosc = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),
//dla matka3 State - unasienniona?                  
                    if (nowaKategoria == 'queen')    
                      if (nowyParametr ==  AppLocalizations.of(context)!.queen + " -") //State
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        //     SizedBox(
                        //   width: 65,
                        //   child: Text(AppLocalizations.of(context)!.vAlue + ':',
                        //     style: TextStyle(
                        //       //fontWeight: FontWeight.bold,
                        //       fontSize: 15,
                        //       color: Colors.black,
                        //     ),
                        //     softWrap: true, //zawijanie tekstu
                        //     overflow: TextOverflow.fade,
                        //   ),
                        // ),
                        // SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 200,
                              margin: EdgeInsets.only(top: 15, bottom: 15),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: nowyWartosc,  
                                items: [
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.virgine1),
                                                  value:AppLocalizations.of(context)!.virgine),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.naturallyMated1),
                                                  value:AppLocalizations.of(context)!.naturallyMated),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.artificiallyInseminated1),
                                                  value:AppLocalizations.of(context)!.artificiallyInseminated),                                                                        
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.droneLaying),
                                                  value:AppLocalizations.of(context)!.droneLaying),                                                                         
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    nowyWartosc = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),                  
//dla matka4 Start - ograniczona?                  
                    if (nowaKategoria == 'queen')    
                      if (nowyParametr ==  AppLocalizations.of(context)!.queenIs) //Start
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        //     SizedBox(
                        //   width: 65,
                        //   child: Text(AppLocalizations.of(context)!.vAlue + ':',
                        //     style: TextStyle(
                        //       //fontWeight: FontWeight.bold,
                        //       fontSize: 15,
                        //       color: Colors.black,
                        //     ),
                        //     softWrap: true, //zawijanie tekstu
                        //     overflow: TextOverflow.fade,
                        //   ),
                        // ),
                        // SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 200,
                              margin: EdgeInsets.only(top: 15, bottom: 15),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: nowyWartosc,  
                                items: [
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.freed),
                                                  value:AppLocalizations.of(context)!.freed),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.inCage),
                                                  value:AppLocalizations.of(context)!.inCage),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.inInsulator),
                                                  value:AppLocalizations.of(context)!.inInsulator),                                                                        
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.isolated),
                                                  value:AppLocalizations.of(context)!.isolated),                                                                        
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    nowyWartosc = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),  
//dla matka5 Born roczmnik matki  - edycja standardowa pola "wartość" tylko bez pola "miara"

//dla colonyState - stan rodziny?                  
                    if (nowaKategoria == 'colony')    
                      if (nowyParametr ==  AppLocalizations.of(context)!.colony + " " + AppLocalizations.of(context)!.isIs) //colonyState
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        //     SizedBox(
                        //   width: 65,
                        //   child: Text(AppLocalizations.of(context)!.vAlue + ':',
                        //     style: TextStyle(
                        //       //fontWeight: FontWeight.bold,
                        //       fontSize: 15,
                        //       color: Colors.black,
                        //     ),
                        //     softWrap: true, //zawijanie tekstu
                        //     overflow: TextOverflow.fade,
                        //   ),
                        // ),
                        // SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 250,
                              margin: EdgeInsets.only(top: 15, bottom: 15),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: nowyWartosc,  
                                items: [
                                   DropdownMenuItem(child: Text(AppLocalizations.of(context)!.aggressive1),
                                                  value:AppLocalizations.of(context)!.aggressive),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.gentle),
                                                  value:AppLocalizations.of(context)!.gentle),
                                  DropdownMenuItem(child: Text('ok'),
                                                  value:'ok'),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.swarmingMood),
                                                  value:AppLocalizations.of(context)!.swarmingMood),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.inCluster),
                                                  value:AppLocalizations.of(context)!.inCluster),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.droneBees),
                                                  value:AppLocalizations.of(context)!.droneBees),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.dead),
                                                  value:AppLocalizations.of(context)!.dead),                                                                        
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    nowyWartosc = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ), 

//dla colonyForce - siła rodziny?                  
                    if (nowaKategoria == 'colony')    
                      if (nowyParametr ==  " " + AppLocalizations.of(context)!.colony + " " + AppLocalizations.of(context)!.isIs) //colonyForce
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        //     SizedBox(
                        //   width: 65,
                        //   child: Text(AppLocalizations.of(context)!.vAlue + ':',
                        //     style: TextStyle(
                        //       //fontWeight: FontWeight.bold,
                        //       fontSize: 15,
                        //       color: Colors.black,
                        //     ),
                        //     softWrap: true, //zawijanie tekstu
                        //     overflow: TextOverflow.fade,
                        //   ),
                        // ),
                        // SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 200,
                              margin: EdgeInsets.only(top: 15, bottom: 15),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: nowyWartosc,  
                                items: [
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.veryStrong),
                                                  value:AppLocalizations.of(context)!.veryStrong),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.strong),
                                                  value:AppLocalizations.of(context)!.strong),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.normal1),
                                                  value:AppLocalizations.of(context)!.normal),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.weak),
                                                  value:AppLocalizations.of(context)!.weak),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.veryWeak),
                                                  value:AppLocalizations.of(context)!.veryWeak),                                                                                                       
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    nowyWartosc = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),                     
 //dla colony deadBees - osyp pszczół - edycja standardowa pola "wartość"  
                    
//dla wyposazenia - ilość ramek - edycja standardowa pola "wartość" , bez pola "miara"                  

//dla wyposazenia - krata na korpus nr - 
                    if (nowaKategoria == 'equipment')    
                      if (nowyParametr ==  AppLocalizations.of(context)!.excluder)
                       Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          SizedBox(
                            width: 65,
                            // child: Text(AppLocalizations.of(context)!.pArametr + ':',
                            //   style: TextStyle(
                            //     //fontWeight: FontWeight.bold,
                            //     fontSize: 15,
                            //     color: Colors.black,
                            //   ),
                            //   softWrap: true, //zawijanie tekstu
                            //   overflow: TextOverflow.fade,
                            // ),
                          ),
                          SizedBox(width: 20),
                          SizedBox(
                            width: 200,
                            child: Text( AppLocalizations.of(context)!.onBodyNumber, //na korpusie numer
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ]
                      ),
//dla wyposazenia - krata odgrodowa - brak. nowyWartosc jest pusta a nowyMiara = 0
                    if (nowaKategoria == 'equipment')    
                      if (nowyParametr ==  " " + AppLocalizations.of(context)!.excluder + " -")
                       Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          SizedBox(
                            width: 65,
                            // child: Text(AppLocalizations.of(context)!.pArametr + ':',
                            //   style: TextStyle(
                            //     //fontWeight: FontWeight.bold,
                            //     fontSize: 15,
                            //     color: Colors.black,
                            //   ),
                            //   softWrap: true, //zawijanie tekstu
                            //   overflow: TextOverflow.fade,
                            // ),
                          ),
                          SizedBox(width: 20),
                          SizedBox(
                            width: 200,
                            child: Text( " " + AppLocalizations.of(context)!.lack, //brak
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              softWrap: true, //zawijanie tekstu
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ]
                      ),
//dla wyposazenie  - dennica               
                    if (nowaKategoria == 'equipment')    
                      if (nowyParametr ==  AppLocalizations.of(context)!.bottomBoard +  " " + AppLocalizations.of(context)!.isIs) //dennica
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        //     SizedBox(
                        //   width: 65,
                        //   child: Text(AppLocalizations.of(context)!.vAlue + ':',
                        //     style: TextStyle(
                        //       //fontWeight: FontWeight.bold,
                        //       fontSize: 15,
                        //       color: Colors.black,
                        //     ),
                        //     softWrap: true, //zawijanie tekstu
                        //     overflow: TextOverflow.fade,
                        //   ),
                        // ),
                        // SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 200,
                              margin: EdgeInsets.only(top: 15, bottom: 15),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: nowyWartosc,  
                                items: [
                                 DropdownMenuItem(child: Text(AppLocalizations.of(context)!.dirty),
                                                  value: AppLocalizations.of(context)!.dirty),
                                  DropdownMenuItem(child: Text('ok'),
                                                  value: 'ok'),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.clean),
                                                  value: AppLocalizations.of(context)!.clean),                                                                        
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    nowyWartosc = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ), 
//dla wyposazenie  - poławiacz pyłku               
                    if (nowaKategoria == 'equipment')    
                      if (nowyParametr ==  AppLocalizations.of(context)!.beePollenTrap + " " + AppLocalizations.of(context)!.isIs) //poławiacz
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        //     SizedBox(
                        //   width: 65,
                        //   child: Text(AppLocalizations.of(context)!.vAlue + ':',
                        //     style: TextStyle(
                        //       //fontWeight: FontWeight.bold,
                        //       fontSize: 15,
                        //       color: Colors.black,
                        //     ),
                        //     softWrap: true, //zawijanie tekstu
                        //     overflow: TextOverflow.fade,
                        //   ),
                        // ),
                        // SizedBox(width: 20),
                            Container(
                              height: 50,
                              width: 200,
                              margin: EdgeInsets.only(top: 15, bottom: 15),
                              child: DropdownButton(
                                isExpanded: true,
                                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0),),
                                value: nowyWartosc,  
                                items: [
                                                                                                                                              
                                  // DropdownMenuItem(child: Text(AppLocalizations.of(context)!.open),
                                  //                 value: AppLocalizations.of(context)!.open),
                                  // DropdownMenuItem(child: Text(AppLocalizations.of(context)!.close),
                                  //                 value: AppLocalizations.of(context)!.close),
                                  // DropdownMenuItem(child: Text(AppLocalizations.of(context)!.set),
                                  //                 value: AppLocalizations.of(context)!.set),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.zalacz1),
                                                  value: AppLocalizations.of(context)!.zalacz),
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.off1),
                                                  value: AppLocalizations.of(context)!.off),
                                  // DropdownMenuItem(child: Text(AppLocalizations.of(context)!.delete),
                                  //                 value: AppLocalizations.of(context)!.delete), 
                                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.remove1),
                                                  value: AppLocalizations.of(context)!.remove),                                                                       
                                
                                ], //lista elementów do wyboru
                                onChanged: (newValue) {
                                  setState(() {
                                    nowyWartosc = newValue!.toString(); 
                                  });
                                }, //onChangeDropdownItem
                              ),
                            )
                          ]
                        ),
                  

//dla dokarmianie usunieto pokarm, pozostało pokarm
                  if(nowyParametr ==  AppLocalizations.of(context)!.removedFood || //usunieto pokarm
                      nowyParametr ==  AppLocalizations.of(context)!.leftFood ) //pozostało pokarm
                    TextFormField(
                      initialValue: nowyWartosc,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                        labelText: (AppLocalizations.of(context)!.vAlue),
                        labelStyle: TextStyle(color: Colors.black),
                        // hintText:
                        //     (AppLocalizations.of(context)!
                        //         .vAlue),
                      ),
                      validator: (value) {
                        // if (value!.isEmpty) {
                        //   return ('uwagi');
                        // }
                        value = value!.replaceAll('%', '');
                        nowyWartosc = value + '%';
                        return null;
                      }
                    ),




//************************************************************************************* */                 
                    //** */ wartość w zwykłym polu edycyjnym poza wyjatkami w ifie
//************************************************************************************* */                  
                  // 
                  //nowyParametr !=  AppLocalizations.of(context)!.leftFood) //pozostało pokarm

//z klawiatura numeryczną bez przecinka                                      
                  if(nowyParametr == AppLocalizations.of(context)!.numberOfFrame + " = " || //ilość ramek 
                     // nowyParametr == 'tag NFC' ||
                      nowyParametr == 'apivarol' ||  //dawka 
                      nowyParametr == 'biovar' ||
                      nowyParametr == AppLocalizations.of(context)!.acid ||  //kwas w ml
                      nowyParametr == " " + AppLocalizations.of(context)!.acid || //kwas w g
                      nowyParametr == 'varroa' || //ilość roztoczy
                      nowyParametr == AppLocalizations.of(context)!.queenWasBornIn ||  //rocznik matki
                      nowyParametr == AppLocalizations.of(context)!.deadBees || //osyp pszczół
                      //nowyParametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.small +  " " + AppLocalizations.of(context)!.frame +  " x"  ||     
                      //nowyParametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.big +  " " + AppLocalizations.of(context)!.frame +  " x" ||
                      nowyParametr == AppLocalizations.of(context)!.beePollen + " = "  || //pyłek w ml
                      nowyParametr == AppLocalizations.of(context)!.beePollen +  "  = " + AppLocalizations.of(context)!.miarka + " x" //pyłem w miarce
                    )
                    TextFormField(
                      initialValue: nowyWartosc,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                        labelText: (AppLocalizations.of(context)!.vAlue),
                        labelStyle: TextStyle(color: Colors.black),
                        // hintText:
                        //     (AppLocalizations.of(context)!
                        //         .vAlue),
                      ),
                      validator: (value) {
                        // if (value!.isEmpty) {
                        //   return ('uwagi');
                        // }
                        nowyWartosc = value!;
                        return null;
                      }
                    ), 
                   
//z klawiaturą numeryczna z przecinkiem                   
                   
                  if(nowyParametr == AppLocalizations.of(context)!.syrup + " 1:1" ||
                      nowyParametr == AppLocalizations.of(context)!.syrup + " 3:2" ||
                      nowyParametr == AppLocalizations.of(context)!.candy ||
                      nowyParametr == AppLocalizations.of(context)!.invert ||
                      nowyParametr == " " + AppLocalizations.of(context)!.beePollen + " =  " || //pyłek w litravh
                      nowyParametr == AppLocalizations.of(context)!.honey + " = " || //w kg
                      nowyParametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.small +  " " + AppLocalizations.of(context)!.frame +  " x"  ||     
                      nowyParametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.big +  " " + AppLocalizations.of(context)!.frame +  " x" 
                     
                   )
                    TextFormField(
                      initialValue: nowyWartosc,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                        labelText: (AppLocalizations.of(context)!.vAlue),
                        labelStyle: TextStyle(color: Colors.black),
                        // hintText:
                        //     (AppLocalizations.of(context)!
                        //         .vAlue),
                      ),
                      validator: (value) {
                        // if (value!.isEmpty) {
                        //   return ('uwagi');
                        // }
                        nowyWartosc = value!.replaceAll(',', '.');
                        return null;
                      }
                    ),
                        
//********************************************** */                    
                    //** */ miara
//********************************************** */
                  // if (nowyParametr != AppLocalizations.of(context)!.queen + '  ' + AppLocalizations.of(context)!.isIs &&  //Quality
                  //     nowyParametr != AppLocalizations.of(context)!.queen + " -" && //State
                  //     nowyParametr != AppLocalizations.of(context)!.queenIs && // Start
                  //     nowyParametr != AppLocalizations.of(context)!.queenWasBornIn && //Born
                  //     nowyParametr != AppLocalizations.of(context)!.colony + " " + AppLocalizations.of(context)!.isIs && //colonyState
                  //     nowyParametr != " " + AppLocalizations.of(context)!.colony + " " + AppLocalizations.of(context)!.isIs && //colonyForce
                  //     nowyParametr != AppLocalizations.of(context)!.numberOfFrame + " = " && //ilość ramek
                  //     nowyParametr != " " + AppLocalizations.of(context)!.excluder + " -" &&//excluder - brak
                  //     nowyParametr != AppLocalizations.of(context)!.bottomBoard +  " " + AppLocalizations.of(context)!.isIs && //dennica
                  //     nowyParametr != AppLocalizations.of(context)!.beePollenTrap + " " + AppLocalizations.of(context)!.isIs && //poławiacz pyłku
                  //     nowyParametr != AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" &&
                  //     nowyParametr != AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" &&
                  //     nowyParametr != AppLocalizations.of(context)!.beePollen + " = " && //pyłek w ml
                  //     nowyParametr != " " + AppLocalizations.of(context)!.beePollen + " =  " && //pyłek w l
                  //     nowyParametr !=  AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x" && //pyłek x miarka
                  //     nowyParametr !=  AppLocalizations.of(context)!.syrup + " 1:1" && //syrop 1:1 w l
                  //     nowyParametr !=  AppLocalizations.of(context)!.syrup + " 3:2" && //syrop 3:2 w l
                  //     nowyParametr !=  AppLocalizations.of(context)!.invert && //invert w l
                  //     nowyParametr !=  AppLocalizations.of(context)!.candy &&
                  //     nowyParametr !=  AppLocalizations.of(context)!.removedFood &&
                  //     nowyParametr !=  AppLocalizations.of(context)!.leftFood)
                   

  //jezeli jest to:                 
                  if (nowyParametr ==  AppLocalizations.of(context)!.excluder || //numer korpusu na którym jest krata odgrodowa
                      nowyParametr ==  " " + AppLocalizations.of(context)!.queen)  //numer opalitka  
                    SizedBox(height: 10),
                              // Row(
                              //     mainAxisAlignment: MainAxisAlignment.start,
                              //     crossAxisAlignment: CrossAxisAlignment.end,
                              //     children: <Widget>[
                              //       SizedBox(
                              //         width: 270,
                              //         child:
                  // if (nowyParametr != AppLocalizations.of(context)!.queen + '  ' + AppLocalizations.of(context)!.isIs && //Quality
                  //     nowyParametr != AppLocalizations.of(context)!.queen + " -" && //State) 
                  //     nowyParametr != AppLocalizations.of(context)!.queenIs && // Start 
                  //     nowyParametr != AppLocalizations.of(context)!.queenWasBornIn && //Bortn
                  //     nowyParametr != AppLocalizations.of(context)!.colony + " " + AppLocalizations.of(context)!.isIs && //colonyState
                  //     nowyParametr != " " + AppLocalizations.of(context)!.colony + " " + AppLocalizations.of(context)!.isIs && //colonyForce          
                  //     nowyParametr != AppLocalizations.of(context)!.numberOfFrame + " = " && //ilość ramek
                  //     nowyParametr != " " + AppLocalizations.of(context)!.excluder + " -" &&//excluder - brak
                  //     nowyParametr != AppLocalizations.of(context)!.bottomBoard +  " " + AppLocalizations.of(context)!.isIs && //dennica
                  //     nowyParametr != AppLocalizations.of(context)!.beePollenTrap + " " + AppLocalizations.of(context)!.isIs&& //poławiacz pyłku
                  //     nowyParametr != AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.small + " " + AppLocalizations.of(context)!.frame + " x" &&
                  //     nowyParametr != AppLocalizations.of(context)!.honey + " = " + AppLocalizations.of(context)!.big + " " + AppLocalizations.of(context)!.frame + " x" &&
                  //     nowyParametr != AppLocalizations.of(context)!.beePollen + " = " && //pyłek w ml
                  //     nowyParametr != " " + AppLocalizations.of(context)!.beePollen + " =  " && //pyłek w l
                  //     nowyParametr !=  AppLocalizations.of(context)!.beePollen + "  = " + AppLocalizations.of(context)!.miarka + " x" && //pyłek x miarka
                  //     nowyParametr !=  AppLocalizations.of(context)!.syrup + " 1:1" && //syrop 1:1 w l
                  //     nowyParametr !=  AppLocalizations.of(context)!.syrup + " 3:2" && //syrop 3:2 w l
                  //     nowyParametr !=  AppLocalizations.of(context)!.invert && //invert w l
                  //     nowyParametr !=  AppLocalizations.of(context)!.candy&&
                  //     nowyParametr !=  AppLocalizations.of(context)!.removedFood &&
                  //     nowyParametr !=  AppLocalizations.of(context)!.leftFood)

//to dla:
                  if (nowyParametr ==  AppLocalizations.of(context)!.excluder)  //numer korpusu na którym jest krata odgrodowa
                    TextFormField(
                      initialValue: nowyMiara,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                        labelText:(AppLocalizations.of(context)!.nUmber), //Numer zamiast Miara
                        labelStyle: TextStyle(color: Colors.black),
                          // hintText:
                          //     (AppLocalizations.of(context)!
                          //         .mEasure),
                        ),
                      validator: (value) {
                        // if (value!.isEmpty) {
                        //   return ('uwagi');
                        // }
                        nowyMiara = value;
                        return null;
                      }
                    ),
    //to dla:                
                    if (nowyParametr ==  " " + AppLocalizations.of(context)!.queen) //numer opalitka
                    TextFormField(
                      initialValue: nowyMiara,
                      keyboardType: TextInputType.name,
                      //inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                        labelText:(AppLocalizations.of(context)!.nUmber), //Numer zamiast Miara
                        labelStyle: TextStyle(color: Colors.black),
                          // hintText:
                          //     (AppLocalizations.of(context)!
                          //         .mEasure),
                        ),
                      validator: (value) {
                        // if (value!.isEmpty) {
                        //   return ('uwagi');
                        // }
                        nowyMiara = value;
                        return null;
                      }
                    ),
                              //   ),
                              // ]),
//*********************************************** */                   
                    //** */ uwagi
//*********************************************** */
                    SizedBox(height: 10),
                              // Row(
                              //     mainAxisAlignment: MainAxisAlignment.start,
                              //     crossAxisAlignment: CrossAxisAlignment.end,
                              //     children: <Widget>[
                              //       SizedBox(
                              //         width: 270,
                              //         child:
                    TextFormField(
                      minLines: 1,
                      maxLines: 5,
                      initialValue: nowyUwagi,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(enabledBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide:BorderSide(color: Colors.blue)),
                        labelText: (AppLocalizations.of(context)!.nOte),
                        labelStyle: TextStyle(color: Colors.black),
                          // hintText:
                          //     (AppLocalizations.of(context)!
                          //         .comments),
                        ),
                      validator: (value) {
                        // if (value!.isEmpty) {
                        //   return ('uwagi');
                        // }
                        nowyUwagi = value;
                        return null;
                      }
                    ),
                              //   ),
                              // ]),
                  ]
                ),
              ),
//*********************************************** */
              //** */ sekcja "Przypomnij" - tylko dla feeding i treatment
//*********************************************** */
              if (nowaKategoria == 'feeding' || nowaKategoria == 'treatment')
                Column(
                  children: [
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.remind,
                          style: TextStyle(fontSize: 16, color: _selectedZakresUli[1] == true ? Colors.grey : Colors.black),
                        ),
                        Switch(
                          value: _przypomnienieEnabled,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: _selectedZakresUli[1] == true
                              ? null // zablokowany przy "wszystkie ule"
                              : (bool value) {
                                  setState(() {
                                    _przypomnienieEnabled = value;
                                  });
                                },
                        ),
                      ],
                    ),
                    if (_przypomnienieEnabled)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.forr,  //za
                              style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 0, 0, 0)),
                            ),                         
                            
                            // Przycisk z liczbą dni
                            Column(
                              children: [
                                //Text(AppLocalizations.of(context)!.remindAfterDays, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                // SizedBox(height: 4),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                    side: BorderSide(color: Color.fromARGB(255, 162, 103, 0), width: 1),
                                    fixedSize: Size(120.0, 40.0),
                                  ),
                                  onPressed: () {
                                    _showDaysPickerDialog();
                                  },
                                  child: Text(
                                    '$_przypomnienieDni ${_przypomnienieDni == 1 ? AppLocalizations.of(context)!.day : AppLocalizations.of(context)!.days}',
                                    style: TextStyle(color: Colors.black, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            
                            Text(
                              AppLocalizations.of(context)!.at,  // o
                              style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 0, 0, 0)),
                            ), 
                            
                            // Przycisk z godziną
                            Column(
                              children: [
                               // Text(AppLocalizations.of(context)!.remindAtTime, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                               // SizedBox(height: 4),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                    side: BorderSide(color: Color.fromARGB(255, 162, 103, 0), width: 1),
                                    fixedSize: Size(120.0, 40.0),
                                  ),
                                  onPressed: () async {
                                    final TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(hour: _przypomnienieGodzina, minute: _przypomnienieMinuta),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _przypomnienieGodzina = picked.hour;
                                        _przypomnienieMinuta = picked.minute;
                                      });
                                    }
                                  },
                                  child: Text(
                                    '${_przypomnienieGodzina.toString().padLeft(2, '0')}:${_przypomnienieMinuta.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: Colors.black, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              SizedBox(height: 30),
//*********************************************** */
              //** */przycisk "Zapisz"
//*********************************************** */
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  
    //** */ zmień
                  MaterialButton(
                    height: 50,
                    shape: const StadiumBorder(
                      side: const BorderSide(color: Color.fromARGB(255, 162, 103, 0)),
                      ),                
                    onPressed: () {
                      if (_formKey1.currentState!.validate()) {
                        if(nowyParametr != '') //było: jezeli wartość nie jest pusta, jest: jezeli parametr...
                          if (edycja) {
                            //print('edycja info - rodzaj ula = $rodzajUla');
                            // Usunięcie starego powiadomienia indywidualnego
                            DBHelper.deletePowiadomienieByInfoId(info[0].id);
                            DBHelper.deleteInfo(info[0].id).then((_) {
                              final nowyInfoId = '${dateController.text}.$nowaPasieka.$nowyUl.$nowaKategoria.$nowyParametr';
                              Infos.insertInfo(
                                nowyInfoId,
                                dateController.text,
                                nowaPasieka,
                                nowyUl,
                                nowaKategoria,
                                nowyParametr,
                                nowyWartosc,
                                nowyMiara!, //ewentualny typ ula ustawiony wczesniej

                                //pole pogoda moze mieć wartość "matkaID", "rodzaj ula", "dmRamki" lub nic
                                nowaKategoria == 'queen'
                                  ? matkaID.toString()
                                  : nowyParametr == AppLocalizations.of(context)!.numberOfFrame + " = "
                                    ? rodzajUla //rodzajUla, //tylko dla ilość ramek =
                                    : nowyParametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.small +  " " + AppLocalizations.of(context)!.frame +  " x"
                                      || nowyParametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.big +  " " + AppLocalizations.of(context)!.frame +  " x"
                                        ? dmRamki //ilość dm2 ramki zalezna od typu ula  i wielkosci ramki
                                        : '',
                                info[0].temp,
                                info[0].czas,
                                nowyUwagi!,
                                0, //info[0].arch,
                              ).then((_) {
                                // Zapis nowego powiadomienia indywidualnego (edycja)
                                if (_przypomnienieEnabled && (nowaKategoria == 'feeding' || nowaKategoria == 'treatment')) {
                                  final dataInfo = DateTime.parse(dateController.text);
                                  final dataNotif = dataInfo.add(Duration(days: _przypomnienieDni));
                                  final dataNotifStr = dataNotif.toString().substring(0, 10);
                                  DBHelper.insertPowiadomienie({
                                    'infoId': nowyInfoId,
                                    'pasiekaNr': nowaPasieka,
                                    'ulNr': nowyUl,
                                    'kategoria': nowaKategoria,
                                    'parametr': nowyParametr,
                                    'dni': _przypomnienieDni,
                                    'godzina': _przypomnienieGodzina,
                                    'minuta': _przypomnienieMinuta,
                                    'dataInfo': dateController.text,
                                    'dataNotif': dataNotifStr,
                                    'aktywne': 1,
                                  }).then((insertedId) {
                                    NotificationHelper.scheduleIndividualNotification(
                                      id: insertedId,
                                      pasiekaNr: nowaPasieka,
                                      ulNr: nowyUl,
                                      kategoria: nowaKategoria,
                                      parametr: nowyParametr,
                                      godzina: _przypomnienieGodzina,
                                      minuta: _przypomnienieMinuta,
                                      dataNotif: dataNotifStr,
                                    );
                                  });
                                }
                                Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(nowaPasieka, nowyUl)
                                .then((_) {
                                  Navigator.of(context).pop();
                                });
                              });
                            });
                          }else{
                            if(_selectedZakresUli[0] == true){ //dodawanie info tylko dla tego ula
                              //print('dodawanie info - rodzaj ula = $rodzajUla');
                              //print('usunieto pokarm - nowaWartość = $nowyWartosc')                              
                              Infos.insertInfo(
                                '${dateController.text}.$nowaPasieka.$nowyUl.$nowaKategoria.$nowyParametr',
                                dateController.text,
                                nowaPasieka,
                                nowyUl,
                                nowaKategoria,
                                nowyParametr,
                                nowyWartosc,
                                //dodawanie miodobrania: nowyMiara = ile dm2 ma ramka ula (zalezne od typu ula i wielkości ramki)
                                nowyMiara!,
                                //info[0].pogoda,
                                //pole pogoda moze mieć wartość "matkaID", "rodzaj ula" lub nic
                                nowaKategoria == 'queen' 
                                  ? matkaID.toString() 
                                  : nowyParametr == AppLocalizations.of(context)!.numberOfFrame + " = " 
                                    ? rodzajUla //rodzajUla,//tylko dla ilość ramek = 
                                    : nowyParametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.small +  " " + AppLocalizations.of(context)!.frame +  " x"      
                                      || nowyParametr == AppLocalizations.of(context)!.honey +  " = " + AppLocalizations.of(context)!.big +  " " + AppLocalizations.of(context)!.frame +  " x" 
                                        ? dmRamki //ilość dm2 ramki zalezna od typu ula i wielkosci ramki
                                        : '',
                                '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}',//info[0].temp,
                                formatterHm.format(DateTime.now()),
                                nowyUwagi!,
                                0, //info[0].arch,
                              ).then((_) {
                                //jezeli LIKWIDACJA ULA to dodaj info o likwidacji ula do wszystkich kategorii ula
                                if(nowyParametr == AppLocalizations.of(context)!.hiveLiquidation ) {
                                  //print('zapisywanie w kategoriach!!!!!!!!!!!!!!');
                                  Infos.insertInfo(
                                    '${dateController.text}.$nowaPasieka.$nowyUl.equipment.$nowyParametr',
                                    dateController.text,
                                    nowaPasieka,
                                    nowyUl,
                                    'equipment',
                                    nowyParametr,
                                    '', //nowyWartosc,
                                    '', //nowyMiara!
                                    '',
                                    '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}',//info[0].temp,
                                    formatterHm.format(DateTime.now()),
                                    nowyUwagi!,
                                    0, //info[0].arch,
                                  ).then((_) {
                                    Infos.insertInfo(
                                      '${dateController.text}.$nowaPasieka.$nowyUl.colony.$nowyParametr',
                                      dateController.text,
                                      nowaPasieka,
                                      nowyUl,
                                      'colony',
                                      nowyParametr,
                                      '', //nowyWartosc,
                                      '', //nowyMiara!
                                      '',
                                      '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}',//info[0].temp,
                                      formatterHm.format(DateTime.now()),
                                      nowyUwagi!,
                                      0, //info[0].arch,
                                    ).then((_) {
                                      //pobranie ID matki przypisanej do tego ula
                                      DBHelper.getQueenID(nowaPasieka, nowyUl).then((data) {
                                      int? matkaIdUla;
                                      if (data.isNotEmpty) {
                                        matkaIdUla = data[0]['id'] as int;
                                      }

                                      Infos.insertInfo(
                                        '${dateController.text}.$nowaPasieka.$nowyUl.queen.$nowyParametr',
                                        dateController.text,
                                        nowaPasieka,
                                        nowyUl,
                                        'queen',
                                        nowyParametr,
                                        '', //nowyWartosc,
                                        '', //nowyMiara!
                                        '${matkaIdUla ?? ''}', //ID matki a jak nie ma to ''
                                        '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}',//info[0].temp,
                                        formatterHm.format(DateTime.now()),
                                        nowyUwagi!,
                                        0, //info[0].arch,
                                      ).then((_) {
                                        Infos.insertInfo(
                                          '${dateController.text}.$nowaPasieka.$nowyUl.harvest.$nowyParametr',
                                          dateController.text,
                                          nowaPasieka,
                                          nowyUl,
                                          'harvest',
                                          nowyParametr,
                                          '', //nowyWartosc,
                                          '', //nowyMiara!
                                          '',
                                          '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}',//info[0].temp,
                                          formatterHm.format(DateTime.now()),
                                          nowyUwagi!,
                                          0, //info[0].arch,
                                        ).then((_) {
                                          Infos.insertInfo(
                                            '${dateController.text}.$nowaPasieka.$nowyUl.feeding.$nowyParametr',
                                            dateController.text,
                                            nowaPasieka,
                                            nowyUl,
                                            'feeding',
                                            nowyParametr,
                                            '', //nowyWartosc,
                                            '', //nowyMiara!
                                            '',
                                            '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}',//info[0].temp,
                                            formatterHm.format(DateTime.now()),
                                            nowyUwagi!,
                                            0, //info[0].arch,
                                          ).then((_) {
                                            Infos.insertInfo(
                                              '${dateController.text}.$nowaPasieka.$nowyUl.treatment.$nowyParametr',
                                              dateController.text,
                                              nowaPasieka,
                                              nowyUl,
                                              'treatment',
                                              nowyParametr,
                                              '',//nowyWartosc,
                                              '', //nowyMiara!
                                              '',
                                              '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}',//info[0].temp,
                                              formatterHm.format(DateTime.now()),
                                              nowyUwagi!,
                                              0, //info[0].arch,
                                            ).then((_) {
                                              Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(nowaPasieka, nowyUl)
                                                .then((_) {
                                                Navigator.of(context).pop();
                                              });
                                            });
                                          });
                                        });
                                      });
                                      }); // getQueenID
                                    });
                                  });
                                }else{
                                  // Zapis powiadomienia indywidualnego (dodawanie, tylko ten ul)
                                  if (_przypomnienieEnabled && (nowaKategoria == 'feeding' || nowaKategoria == 'treatment')) {
                                    final nowyInfoId = '${dateController.text}.$nowaPasieka.$nowyUl.$nowaKategoria.$nowyParametr';
                                    final dataInfo = DateTime.parse(dateController.text);
                                    final dataNotif = dataInfo.add(Duration(days: _przypomnienieDni));
                                    final dataNotifStr = dataNotif.toString().substring(0, 10);
                                    DBHelper.insertPowiadomienie({
                                      'infoId': nowyInfoId,
                                      'pasiekaNr': nowaPasieka,
                                      'ulNr': nowyUl,
                                      'kategoria': nowaKategoria,
                                      'parametr': nowyParametr,
                                      'dni': _przypomnienieDni,
                                      'godzina': _przypomnienieGodzina,
                                      'minuta': _przypomnienieMinuta,
                                      'dataInfo': dateController.text,
                                      'dataNotif': dataNotifStr,
                                      'aktywne': 1,
                                    }).then((insertedId) {
                                      NotificationHelper.scheduleIndividualNotification(
                                        id: insertedId,
                                        pasiekaNr: nowaPasieka,
                                        ulNr: nowyUl,
                                        kategoria: nowaKategoria,
                                        parametr: nowyParametr,
                                        godzina: _przypomnienieGodzina,
                                        minuta: _przypomnienieMinuta,
                                        dataNotif: dataNotifStr,
                                      );
                                    });
                                  }
                                  Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(nowaPasieka, nowyUl)
                                    .then((_) {
                                    Navigator.of(context).pop();
                                  });
                                };
                              });
                            }else{ //dodawanie tego samego info dla wszystkich uli
                              //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
                              Provider.of<Hives>(context, listen: false).fetchAndSetHives(nowaPasieka,)
                                .then((_) {
                                  final hivesDataDL = Provider.of<Hives>(context,listen: false);
                                  final hivesDL = hivesDataDL.items;
                                  for (var i = 0; i < hivesDL.length; i++) {
                                    Infos.insertInfo(
                                      '${dateController.text}.$nowaPasieka.${hivesDL[i].ulNr}.$nowaKategoria.$nowyParametr',
                                      dateController.text,
                                      nowaPasieka,
                                      hivesDL[i].ulNr,
                                      nowaKategoria,
                                      nowyParametr,
                                      nowyWartosc,
                                      nowyMiara!,
                                      '',//info[0].pogoda,
                                      '${globals.aktualTemp.toStringAsFixed(0)}${globals.stopnie}',//info[0].temp,
                                      formatterHm.format(DateTime.now()),
                                      nowyUwagi!,
                                      0, //info[0].arch,
                                    );
                                  };
                                  Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(nowaPasieka, nowyUl)
                                  .then((_) {
                                  globals.odswiezBelkiUliDL = true; //odświezenie belek uli
                                  Navigator.of(context).pop();
                                });
                                });
                            }
                          }

                        //przeplanowanie powiadomień po zapisie info
                        if (nowaKategoria == 'feeding' || nowaKategoria == 'treatment' || nowaKategoria == 'inspection') {
                          NotificationHelper.scheduleAllNotifications();
                        }

                        //jezeli wpis  dotyczy leczenia lub dokarmiania lub matki lub wyposazenia lub przeglądu (bo likwidacja ula i zmiana ikony na czarną)
                        if (nowaKategoria == 'feeding' || nowaKategoria == 'treatment' || nowaKategoria == 'queen' || nowaKategoria == 'equipment'  || nowaKategoria == 'inspection') {
                          //zeby nie stracić danych zebranych podczas przeglądu w widoku zbiorczym uli (belki)
                          final hiveData = Provider.of<Hives>(context,listen: false);
                          final hive = hiveData.items.where((element) {
                            //to wczytanie danych edytowanego ula
                            return element.id == ('$nowaPasieka.$nowyUl');
                          }).toList();
                          //print('zeby nie stracic info przed - rodzaj ula = $rodzajUla');
                          String ikona = hive[0].ikona;
                          int ramek = hive[0].ramek;
                          int korpusNr = hive[0].korpusNr; //obecna belka pozostaje
                          int trut = hive[0].trut;
                          int czerw = hive[0].czerw;
                          int larwy = hive[0].larwy;
                          int jaja = hive[0].jaja;
                          int pierzga = hive[0].pierzga;
                          int miod = hive[0].miod;
                          int dojrzaly = hive[0].dojrzaly;
                          int weza = hive[0].weza;
                          int susz = hive[0].susz;
                          int matka = hive[0].matka;
                          int mateczniki = hive[0].mateczniki;
                          int usunmat = hive[0].usunmat;
                          String todo = hive[0].todo;
                          String kat = hive[0].kategoria;
                          String param = hive[0].parametr;
                          String wart = hive[0].wartosc;
                          String miara = hive[0].miara;
                          String matka1 = hive[0].matka1;
                          String matka2 = hive[0].matka2;
                          String matka3 = hive[0].matka3;
                          String matka4 = hive[0].matka4;
                          String matka5 = hive[0].matka5;
                          if(nowyParametr != AppLocalizations.of(context)!.numberOfFrame + " = " && hive[0].h1 != '') rodzajUla = hive[0].h1; //nie zachowuj starego rodzaju ula jezeli jest jakiś nowy rodzaj 
                          if(nowyParametr != AppLocalizations.of(context)!.numberOfFrame + " = " && hive[0].h2 != '') typUla = hive[0].h2; //nie zachowuj starego typu ula jezeli jest jakiś nowy typ 
                          String tagNFC = hive[0].h3;
                          //print('zeby nie stracic info po - rodzaj ula = $rodzajUla'); 
                          //jezeli wpis  dotyczy leczenia lub dokarmiania
                          if (nowaKategoria == 'feeding' || nowaKategoria == 'treatment'){                        
                            //to jezeli edytowano info ula z datą taką jak ostatnie (lub pózniejszą) info ula to modyfikacja danych
                            //bo zmiana dla leczenia i pokarmu
                            if ('$nowaPasieka.$nowyUl' == hive[0].id &&
                                (dateController.text == hive[0].przeglad || (DateTime.parse(dateController.text)).compareTo(DateTime.parse(hive[0].przeglad)) > 0)) {
                              korpusNr = 0;
                              kat = nowaKategoria;
                              param = nowyParametr;
                              wart = nowyWartosc;
                              miara = nowyMiara!;
                            }
                          }
                          //jezeli info jest o matce to zmiana parametrów matki w belce
                          if (nowaKategoria == 'queen') {                                          
                          
  //** */ Quality - matka1
                            if (nowyParametr == AppLocalizations.of(context)!.queen + '  ' + AppLocalizations.of(context)!.isIs) 
                              if (nowyWartosc == 'mała' || nowyWartosc == 'słaba' || nowyWartosc == 'zła' || nowyWartosc == 'stara' ||
                                  nowyWartosc == 'small' || nowyWartosc == 'to exchange' || nowyWartosc == 'canceled' || nowyWartosc == 'weak' ) {
                                matka1 = 'zła';
                                ikona = 'orange';                              
                                if (matka2 == 'brak') matka2 = '';
                              } else {
                                matka1 = 'ok';
                                if (ikona == 'red' || ikona == 'orange') {  //bo był brak matki               
                                  ikona = 'green';
                                }
                                if (matka2 == 'brak') matka2 = '';
                              }
 //** */ Mark + Number matka2
                            if (nowyParametr == " " + AppLocalizations.of(context)!.queen)
                              switch (nowyWartosc) {
                                case 'nie ma znak': matka2 = 'niez'; ikona = 'green';//nieznaczona
                                  break;
                                case 'unmarked': matka2 = 'niez'; ikona = 'green';//nieznaczona
                                  break;
                                case 'ma inny znak': matka2 = 'inny ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'marked other': matka2 = 'inny ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'ma biały znak': matka2 = 'biał ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'marked white': matka2 = 'biał ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'ma żółty znak': matka2 = 'żółt ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'marked yellow': matka2 = 'żółt ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'ma czerwony znak': matka2 = 'czer ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'marked red': matka2 = 'czer ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'ma zielony znak': matka2 = 'ziel ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'marked green': matka2 = 'ziel ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'ma niebieski znak': matka2 = 'nieb ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'marked blue': matka2 = 'nieb ' + nowyMiara!; ikona = 'green';//kolor + numer matki
                                  break;
                                case 'nie ma': matka2 = 'brak'; matka1 = ''; matka3 = ''; matka4 = '';matka5 = '';
                                  ikona = 'red';
                                  break;
                                case 'gone': matka2 = 'brak'; matka1 = ''; matka3 = ''; matka4 = '';matka5 = '';
                                  ikona = 'red';
                                  break;
                                case 'brak': matka2 = 'brak'; matka1 = ''; matka3 = ''; matka4 = ''; matka5 = '';
                                  ikona = 'red';
                                  break;
                                case 'missing': matka2 = 'brak'; matka1 = ''; matka3 = ''; matka4 = '';matka5 = '';
                                  ikona = 'red';
                                  break;
                              }
//** */ State matka3 - czy unasienniona?
                            if (nowyParametr == AppLocalizations.of(context)!.queen + " -") //State
                              if (nowyWartosc == 'dziewica' || nowyWartosc == 'virgine') {
                                matka3 = 'nieunasienniona';
                                if (ikona == 'red') { //bo był brak matki
                                  ikona = 'orange';
                                }
                                if (matka2 == 'brak') matka2 = ''; //usuwanie informacji o unasiennieniu
                              } else if (nowyWartosc == 'trutówka' || nowyWartosc == 'drone laying') {
                                matka3 = 'trutowa';
                                ikona = 'orange';
                                if (matka2 == 'brak') matka2 = ''; //usuwanie informacji o unasiennieniu
                              } else {
                                matka3 = 'unasienniona';
                                if (ikona != 'yellow') { //jezeli nie toDo
                                  ikona = 'green'; 
                                }
                                if (matka2 == 'brak') matka2 = '';
                              }
                                                                                   
    //** */ Start matka4  - czy ograniczona?
                            if (nowyParametr == AppLocalizations.of(context)!.queenIs) //Start
                              if (nowyWartosc == 'wolna' || nowyWartosc == 'freed'){
                                matka4 = 'wolna';
                                if (ikona == 'red') {//bo był brak matki
                                  ikona = 'orange';
                                }
                                if (matka2 == 'brak') matka2 = '';
                              } else{
                                matka4 = 'ograniczona';
                                if (ikona == 'red') {  //bo był brak matki
                                  ikona = 'orange';
                                }
                                if (matka2 == 'brak') matka2 = '';
                              }
     //** */ Born matka5  - rocznik
                            if (nowyParametr == AppLocalizations.of(context)!.queenWasBornIn){ //Born
                              matka5 = nowyWartosc;
                              if (ikona == 'red') { //bo był brak matki
                                ikona = 'orange';
                              }
                              if (matka2 == 'brak') matka2 = '';
                            }
                          }

                          if (nowaKategoria == 'equipment') {
                            if(nowyParametr == AppLocalizations.of(context)!.numberOfFrame + " = "){
                              ramek = int.parse(nowyWartosc);
                              globals.iloscRamek = ramek; //nie wiem czy potrzeba ???
                               if (ikona == 'black') { //bo była likwidacja ula
                                ikona = 'green';
                              }
                            }
                           }
                          //jezeli LIKWIDACJA ULA to zmień ikonę na czarną
                          if (nowaKategoria == 'inspection' && nowyParametr == AppLocalizations.of(context)!.hiveLiquidation ) {
                            ikona = 'black';
                          }
                          //print('nowaKategoria = $nowaKategoria, nowyParametr = $nowyParametr, ikona = $ikona');
                          //print('zapis do hive - rodzaj ula = $rodzajUla');          
                          Hives.insertHive(
                            '$nowaPasieka.$nowyUl',
                            nowaPasieka, //pasieka nr
                            nowyUl, //ul nr
                            dateController.text, //przeglad
                            ikona, //ikona
                            ramek, //opis - ilość ramek w korpusie
                            korpusNr,
                            trut,
                            czerw,
                            larwy,
                            jaja,
                            pierzga,
                            miod,
                            dojrzaly,
                            weza,
                            susz,
                            matka,
                            mateczniki,
                            usunmat,
                            todo,
                            kat,
                            param,
                            wart,
                            miara,
                            matka1,
                            matka2,
                            matka3,
                            matka4,
                            matka5,
                            rodzajUla, //h1 - rodzaj ula
                            typUla, //h2 - typ ula
                            tagNFC, //h3
                            0,// aktualne bo aktualizowane na biezaco
                          ).then((_) {
                            //pobranie do Hives_items z tabeli ule - ule z pasieki do której był wpis
                            Provider.of<Hives>(context, listen: false).fetchAndSetHives(nowaPasieka,)
                              .then((_) {
                                final hivesData = Provider.of<Hives>(context,listen: false);
                                final hives = hivesData.items;
                                int ileUli = hives.length;

                                //ustawienie ikony dla pasieki
                                globals.ikonaPasieki = 'green';
                                for (var i = 0; i < hives.length; i++) {
                                  //print('i=$i');
                                  //print( 'hives[i].ikona = ${hives[i].ikona}');
                                  switch (hives[i].ikona){
                                    case 'red': globals.ikonaPasieki = 'red';
                                    break;
                                    case 'orange': if(globals.ikonaPasieki == 'yellow' || globals.ikonaPasieki == 'green') globals.ikonaPasieki = 'orange';
                                    break;
                                    case 'yellow': if(globals.ikonaPasieki == 'green') globals.ikonaPasieki = 'yellow';
                                    break;
                                  }
                                  //print('============== globals.ikonaPasieki ===== ${globals.ikonaPasieki}');
                                  // print(
                                  //     '${hives[i].id},${hives[i].pasiekaNr},${hives[i].ulNr},${hives[i].przeglad},${hives[i].ikona},${hives[i].ramek}');
                                  // print('*****');
                                }
                                
                                
                                
                                //zapis do tabeli "pasieki"
                                Apiarys.insertApiary(
                                  '${nowaPasieka}',
                                  nowaPasieka, //pasieka nr
                                  ileUli, //ile uli - obliczone przy wstawianiu/zapisywaniu info o ulach insertHive
                                  dateController.text, //przeglad
                                  globals.ikonaPasieki, //ikona
                                  '??', //opis
                                ).then((_) {
                                  Provider.of<Apiarys>(context,listen: false).fetchAndSetApiarys()
                                    .then((_) {
                                            // print(
                                            //     'edit_screen: aktualizacja Apiarys_items z tabeli "pasieki" z bazy');
                                  });
                                });
                              });
                          });
                        }//jezeli wpis  dotyczy leczenia lub dokarmiania lub matki

                            // Provider.of<Infos>(context, listen: false).fetchAndSetInfosForHive(nowaPasieka, nowyUl)
                            //   .then((_) {
                            //   Navigator.of(context).pop();
                            // });
                         // }); //deleteInfo
                        //}//if edycja
                      };//if validate
                    },//onPressed
                    child: Text('   ' + (AppLocalizations.of(context)!.saveZ) +'   '), //Zapisz
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.black,
                    disabledColor: Colors.grey,
                    disabledTextColor: Colors.white,
                  ),
                ]
              ),
            ]))));
  }
}
