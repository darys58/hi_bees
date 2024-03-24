library cobytu.globals;

//bool isInit = false; //true jezeli była modyfikowana baza - 'ramka'
int pasiekaID = 1; //aktualnie wybrana pasieka - numer pasieki
int ulID = 1; //aktualnie wybrany ul  - numer ula
int iloscRamek = 10; //ilość ramek w korpusie ula
String dataInspekcji = ''; //data inspekcji dla wybranego elementu listy info
int ileRamek = 0; //ile ramek w "edit inspection" - szczegóły inspekcji
String aktualnaKategoriaInfo = 'inspection'; //aktualnie wybrana kategoria Info
String rokStatystyk = DateTime.now().toString().substring(0, 4); //rok wybrany w Info do ststystyk

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

//z/do tabeli Memory
//String id = '';
//String email = '';
//String dev = '';

//String dod = '';
//String ddo = '';



//String memoryLokE = '31'; //id wybranej restauracji
//String memoryLokC = '1'; //id miasta
//String language; //język
