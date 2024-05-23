library cobytu.globals;

//bool isInit = false; //true jezeli była modyfikowana baza - 'ramka'
int pasiekaID = 1; //aktualnie wybrana pasieka - numer pasieki
int ulID = 1; //aktualnie wybrany ul  - numer ula
int iloscRamek = 10; //ilość ramek w korpusie ula
String dataInspekcji = ''; //data inspekcji dla wybranego elementu listy info
int ileRamek = 0; //ile ramek w "edit inspection" - szczegóły inspekcji
String aktualnaKategoriaInfo = 'inspection'; //aktualnie wybrana kategoria Info
String rokStatystyk = DateTime.now().toString().substring(0, 4); //rok wybrany w Info do ststystyk\
double aktualTemp = 0.0; //aktualna temperatura
String stopnie = '\u2103'; //nazwa jednostki temperatury

String kod = ''; //kod do pobrania klucza picovoice z bazy www
String key = ''; //kaccessKey picovoice
String keyMemory =
    ''; //kaccessKey picovoice - gdyby wycofanie sie z aktywacji i powrót do tego co było
String deviceId = ''; //Id telefonu - identyfikator apki/uzytkownika
String wersja = ''; //wersja apki
String jezyk = ''; //język obsługiwany przez aplikację
//String memJezyk = 'system'; //język z systemu "system" lub z ustawień w aplikacji 
String ikonaUla = 'green'; //
String ikonaPasieki = 'green'; //

String dataWpisu = DateTime.now().toString().substring(0, 10);
int nowyNrKorpusu = 1;
int nowyNrRamki = 1;
int nowyNrRamkiPo = 1;
int zakresRamek = 0; //0-jedna, 1-wiele
int nrRamkiOd = 1;
int nrRamkiDo = 5;
int korpus = 2;
int rozmiarRamki = 2;
int stronaRamki = 2;
int numeryWieluRamek = 1; //0- xx/0 , 1- xx/xx, 2- 0/xx  (przy dodawaniu/edycji wielu ramek)

//z/do tabeli Memory
//String id = '';
//String email = '';
//String dev = '';

//String dod = '';
//String ddo = '';



//String memoryLokE = '31'; //id wybranej restauracji
//String memoryLokC = '1'; //id miasta
//String language; //język
