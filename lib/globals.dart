library cobytu.globals;
String? status = 'xxx';
//bool isInit = false; //true jezeli była modyfikowana baza - 'ramka'
int pasiekaID = 1; //aktualnie wybrana pasieka - numer pasieki
int ulID = 1; //aktualnie wybrany ul  - numer ula
int iloscRamek = 10; //ilość ramek w korpusie ula
String typUla = 'WIELKOPOLSKI'; //typ aktualnie wybranego ula
String dataInspekcji = ''; //data inspekcji dla wybranego elementu listy info
String ikonaInspekcji = ''; //ikona inspekcji dla wybranego elementu listy info
int ileRamek = 0; //ile ramek w "edit inspection" - szczegóły inspekcji
String aktualnaKategoriaInfo = 'inspection'; //aktualnie wybrana kategoria Info
String dataAktualnegoPrzegladu = ''; //zeby nie nadpisywać info o przeglądzie by nie usuwać godziny rozpoczęcia przegladu i notatki
String rokStatystyk = DateTime.now().toString().substring(0, 4); //rok wybrany w Info do ststystyk\
String rokMatek = '20'; //rok wybrany w ZARZADZANIE MATKAMI
double aktualTemp = 0.0; //aktualna temperatura
String stopnie = '\u2103'; //nazwa jednostki temperatury

String kod = ''; //kod do pobrania klucza picovoice z bazy www
String key = ''; //kaccessKey picovoice
String keyMemory = ''; //kaccessKey picovoice - gdyby wycofanie sie z aktywacji i powrót do tego co było
String deviceId = ''; //Id telefonu - identyfikator apki/uzytkownika
String wersja = ''; //wersja apki
String jezyk = ''; //język obsługiwany przez aplikację
//String memJezyk = 'system'; //język z systemu "system" lub z ustawień w aplikacji 
String ikonaUla = 'green'; //
String ikonaPasieki = 'green'; //
String widokMatek = 'activ'; //lista matek w ZARZADZANIE MATKAMI (all, activ, living, lost) 

var nieaktualnaPogoda = DateTime(2024,6,1,0,0,0); //czas kiedy wyświetlił się ostatni komunikat o braku aktualnej pogody
String dataWpisu = DateTime.now().toString().substring(0, 10);
String dataPrzeniesRamke = DateTime.now().toString().substring(0, 10); //data przeglądu do którego przenoszona jest ramka
int nrUlaPrzeniesZ = 1; //numer ula z którego przenoszona jest ramka
int nrKorpusuPrzeniesZ = 1; //numer korpusu z którego przenoszona jest ramka
int nrRamkiPrzeniesZ = 1; //numer ramki z którego przenoszona jest ramka
int nrUlaPrzeniesDo = 1; //numer ula do którego przenoszona jest ramka
int nrKorpusuPrzeniesDo = 1; //numer korpusu do którego przenoszona jest ramka
int nrRamkiPrzeniesDo = 1; //numer ramki do którego przenoszona jest ramka
int nowyNrUla = 1;
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
double lupaRamek = 1.0; //powiększanie widoku ula

bool odswiezBelkiUli = false;//czy odswiezyć belki po imporcie danych lub ręcznie ikoną odswiezania
bool odswiezBelkiUliDL = false;//czy odswiezyć ręcznie ikoną odswiezania
bool odswiezBelkiUliZ = false;//czy odswiezyć ręcznie ikoną odswiezania

String wykresZbiory = 'miod'; //wyświetlany wykres "miod" lub "pylek"

String nfcMode = 'summary'; //tryb NFC: 'off' - wyłączony, 'info' - otwieraj informacje, 'summary' - otwieraj podsumowanie

int raportNrStrony = 1; //numer strony dla wykresu raportu zbiorów lub leczenia
int raportIleUliNaStronie = 20; //ilość uli na stronie w raporcie zbiorów lub leczenia (od 1 do 20)
String rokRaportow = 'wszystkie'; //DateTime.now().toString().substring(0, 4); //rok wybrany w Info do raportów

//z/do tabeli Memory
//String id = '';
//String email = '';
//String dev = '';

//String dod = '';
//String ddo = '';



//String memoryLokE = '31'; //id wybranej restauracji
//String memoryLokC = '1'; //id miasta
//String language; //język
