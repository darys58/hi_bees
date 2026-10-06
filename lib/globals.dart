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
//500 = temperatura NIEZNANA (pogoda jeszcze niepobrana) - ta sama wartość, której hives_screen
//używa do ukrycia temperatury na pasku. Do 06.10.2026 start od 0.0: wpisy zrobione przed pobraniem
//pogody (np. nowy użytkownik, pierwsze wejście do pasieki) dostawały "0°C".
const double tempNieznana = 500;
double aktualTemp = tempNieznana; //aktualna temperatura

//temperatura do zapisu we wpisie: pusto, gdy nieznana (zamiast fałszywego "0°C" albo "500°C")
String tempNaWpis(double t, String jednostka) =>
    t == tempNieznana ? '' : '${t.toStringAsFixed(0)}$jednostka';
String stopnie = '\u2103'; //nazwa jednostki temperatury

//Klucz aktywacyjny apki. Historycznie był to accessKey Picovoice; po przejściu
//na Vosk (03.08.2026) silnik głosowy go NIE potrzebuje, ale klucz został jako
//bramka licencyjna - pusty key ('bez_klucza') = brak sterowania głosem.
String kod = ''; //kod do pobrania klucza aktywacyjnego z bazy www

//PREFIKS TABEL KONTA W CHMURZE (np. "0001", od konta nr 10000 "A000") - etap 1b pkt 2, 06.10.2026.
//Podaje go serwer: be_prefiks w odpowiedzi cbt_hi_kod_v2.php (aktywacja i synchronizacja konta
//przy starcie / po powrocie z tła). Trzymany tylko w pamięci - tabela memory nie ma wolnej kolumny.
//Zanim przyjdzie odpowiedź (start bez sieci, stary serwer) - 4 pierwsze znaki kodu, jak dotąd;
//dziś to ta sama wartość, bo serwer też liczy prefiks z 4 pierwszych znaków kodu konta.
//Jedno miejsce na zmianę, gdy kod przestanie zaczynać się od prefiksu (token, etap 1b pkt 3).
String prefiksSerwera = '';

//TOKEN URZĄDZENIA (etap 1b pkt 3, 06.10.2026) - 64 znaki z serwera, jeden na instalację aplikacji.
//Zapisany w memory.token; idzie w każdym żądaniu do chmury zamiast samego kodu.
//'' = jeszcze nie pobrany (pobiera go cicha synchronizacja konta kodem przy starcie).
String token = '';
String prefiksTabel(String kodKonta) {
  if (prefiksSerwera.isNotEmpty) return prefiksSerwera;
  final k = kodKonta.trim();
  return k.length >= 4 ? k.substring(0, 4).toUpperCase() : k; //krótszy kod: dotąd RangeError
}

//be_prefiks z odpowiedzi serwera - przyjmowany tylko w poprawnym formacie (4 znaki [0-9A-Z])
void ustawPrefiksSerwera(dynamic bePrefiks) {
  final p = (bePrefiks ?? '').toString();
  if (RegExp(r'^[0-9A-Z]{4}$').hasMatch(p)) prefiksSerwera = p;
}
String key = ''; //klucz aktywacyjny
String keyMemory = ''; //klucz aktywacyjny - gdyby wycofanie sie z aktywacji i powrót do tego co było
String deviceId = ''; //Id telefonu - identyfikator apki/uzytkownika
String wersja = ''; //wersja apki
String jezyk = ''; //język obsługiwany przez aplikację
String memJezyk = 'system'; //język z systemu "system" lub z ustawień w aplikacji

/// Europejski format: DD.MM.RRRR, przecinek dziesiętny - wszystkie języki oprócz angielskiego
bool isEuropeanFormat() => jezyk != 'en_US';

/// Zwraca kod waluty na podstawie języka
int walutaDlaJezyka() {
  switch (jezyk) {
    case 'pl_PL': return 1; // PLN
    case 'en_US': return 2; // USD
    default: return 3; // EUR (de, fr, es, pt, it)
  }
}

/// Strona www.heymaya.eu w języku apki (adresy z hreflang strony, sprawdzone 27.09.2026).
/// Nieobsługiwany język -> wersja angielska.
String adresStronyHeyMaya() {
  switch (jezyk.length >= 2 ? jezyk.substring(0, 2) : jezyk) {
    case 'pl': return 'https://heymaya.eu/';
    case 'de': return 'https://heymaya.eu/index.php/de/deutsch/';
    case 'fr': return 'https://heymaya.eu/index.php/fr/francais/';
    case 'es': return 'https://heymaya.eu/index.php/es/espanol/';
    case 'pt': return 'https://heymaya.eu/index.php/pt/';
    case 'it': return 'https://heymaya.eu/index.php/it/italia/';
    default: return 'https://heymaya.eu/index.php/en/english/';
  }
}

/// Przewodnik (ikona "?" na ekranie startowym) w języku apki.
String adresPrzewodnikaHeyMaya() {
  switch (jezyk.length >= 2 ? jezyk.substring(0, 2) : jezyk) {
    case 'pl': return 'https://heymaya.eu/index.php/przewodnik/';
    case 'de': return 'https://heymaya.eu/index.php/de/wegweiser/';
    case 'fr': return 'https://heymaya.eu/index.php/fr/guide-2/';
    case 'es': return 'https://heymaya.eu/index.php/es/guia/';
    case 'pt': return 'https://heymaya.eu/index.php/pt/guia-2/';
    case 'it': return 'https://heymaya.eu/index.php/it/guida/';
    default: return 'https://heymaya.eu/index.php/en/guide/';
  }
}

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
int nrPasiekiPrzeniesDo = 1; //numer pasieki do której przenoszona jest ramka
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
String belkiDLKategoria = ''; //co ma trafić na belkę przy odświezaniu DL: '' - dokarmianie lub leczenie, 'feeding' - tylko dokarmianie, 'treatment' - tylko leczenie
bool odswiezBelkiUliZ = false;//czy odswiezyć ręcznie ikoną odswiezania

String wykresZbiory = 'miod'; //wyświetlany wykres "miod" lub "pylek"

String nfcMode = 'summary'; //tryb NFC: 'off' - wyłączony, 'info' - otwieraj informacje, 'summary' - otwieraj podsumowanie

bool showZakupySprzedaz = true; //pokazuj/ukrywaj przyciski Zakupy i Sprzedaż na stronie startowej

int raportNrStrony = 1; //numer strony dla wykresu raportu zbiorów lub leczenia
int raportIleUliNaStronie = 20; //ilość uli na stronie w raporcie zbiorów lub leczenia (od 1 do 20)
String rokRaportow = 'wszystkie'; //DateTime.now().toString().substring(0, 4); //rok wybrany w Info do raportów

//Sterowanie głosem: podgląd korpusu na żywo (poziomo) zamiast podpowiedzi komend
//(pionowo). Domyślnie WŁĄCZONY od 06.08.2026 - przy ulu liczy się to, co dzieje
//się z plastrem po komendzie, a podpowiedzi są potrzebne tylko na początku.
//Ustawienie sesyjne: po restarcie apki wraca na true. Wyłącznik w Parametryzacji.
bool voice2LivePodglad = true;
bool voice2LiveLandscape = false; //wymuszenie układu poziomego dla live podglądu korpusu (niezależnie od orientacji urządzenia)

//Diagnostyka sterowania głosem: pokazuje na ekranie SUROWY tekst z Vosk wraz
//z pewnością rozpoznania. Domyślnie WYŁĄCZONA i tak ma zostać na produkcji -
//gramatyka celowo zawiera aliasy fonetyczne („pierzcha" = pierzga, „węża" =
//węza, „miodu branie" = miodobranie, „na grób" = nakrop), bo tylko takie formy
//istnieją w słowniku modelu. Pszczelarz wziąłby je za błąd aplikacji.
//Od 06.08.2026 PRZEŁĄCZNIK W PARAMETRYZACJI JEST ZAKOMENTOWANY (sekcja
//"Sterowanie głosem" w parametr_screen). Żeby włączyć diagnostykę, trzeba
//odkomentować tamtą kartę - cały mechanizm czytający tę flagę zostaje w kodzie.
//Ustawienie sesyjne (jak voice2LivePodglad) - po restarcie apki wraca na false.
bool voiceDiagnostyka = false;

//Nagrywanie dyktowanych notatek: obok tekstu zapisujemy ścieżkę dźwiękową (WAV
//16 kHz mono, ~32 kB/s) i przypinamy ją do notatki. Po to, żeby dało się
//sprawdzić, co pszczelarz naprawdę powiedział, gdy transkrypcja z Vosk wyszła
//przekręcona. Nagrania zostają NA TELEFONIE (do chmury nie idą) i znikają po
//RecordingHelper.dniPrzechowywania dniach albo razem z notatką.
//Domyślnie WŁĄCZONE - wyłącznik jest w Parametryzacji, dla oszczędzania miejsca.
bool nagrywajNotatki = true;

// Aktualności ula - widoczność kategorii (0=ukryta, 1=widoczna)
// Pozycje: 0-ramki, 1-rodzina, 2-matka, 3-zbiory, 4-dokarmianie, 5-leczenie, 6-zdjęcia
String summaryVisibility = '1111111'; // domyślnie wszystko widoczne
bool get showSummaryFrames => summaryVisibility.length > 0 && summaryVisibility[0] == '1';
bool get showSummaryColony => summaryVisibility.length > 1 && summaryVisibility[1] == '1';
bool get showSummaryQueen => summaryVisibility.length > 2 && summaryVisibility[2] == '1';
bool get showSummaryHarvest => summaryVisibility.length > 3 && summaryVisibility[3] == '1';
bool get showSummaryFeeding => summaryVisibility.length > 4 && summaryVisibility[4] == '1';
bool get showSummaryTreatment => summaryVisibility.length > 5 && summaryVisibility[5] == '1';
bool get showSummaryPhotos => summaryVisibility.length > 6 && summaryVisibility[6] == '1';

//z/do tabeli Memory
//String id = '';
//String email = '';
//String dev = '';

//String dod = '';
//String ddo = '';



//String memoryLokE = '31'; //id wybranej restauracji
//String memoryLokC = '1'; //id miasta
//String language; //język
