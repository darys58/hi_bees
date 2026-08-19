# Sterowanie głosem

Tekst przygotowany jako kolejny punkt przewodnika na www.heymaya.eu (wersja polska).
Konwencja jak w pozostałych rozdziałach: forma bezosobowa, nazwy ekranów i przycisków
w cudzysłowach, bez zrzutów ekranu.

---

Sterowanie głosem pozwala prowadzić przegląd bez odkładania ramki i bez zdejmowania
rękawic - telefon leży obok ula, a zapisy powstają z tego, co pszczelarz mówi na głos.
Funkcja uruchamiana jest przyciskiem "STEROWANIE GŁOSEM" na stronie startowej aplikacji
i dostępna jest w polskiej wersji językowej. Rozpoznawanie mowy odbywa się w całości na
telefonie, bez połączenia z internetem - nagrania i wypowiedzi nie są nigdzie wysyłane.

Aplikacja rozpoznaje wyłącznie polecenia z listy opisanej niżej, a nie dowolną mowę.
Wyjątkiem jest dyktowanie notatki, kiedy zapisywane jest wszystko, co zostanie
powiedziane.

## Rozpoczęcie i zakończenie rozmowy

Po wejściu na ekran aplikacja czuwa, czyli nasłuchuje, ale rozpoznaje tylko kilka fraz
otwierających. Dzięki temu rozmowa prowadzona przy ulu nie spowoduje żadnego zapisu.

1. "Hej Maja start" (albo "zaczynamy", "startujemy") - otwiera nasłuch poleceń.
2. "Hej Maja stop" (albo "koniec", "kończymy") - kończy nasłuch i wraca do czuwania.

Przyjęcie każdego polecenia potwierdzane jest krótkim sygnałem dźwiękowym. Jeżeli
wypowiedź nie została rozpoznana, Maja mówi o tym wprost. Przerwanie pracy telefonu -
rozmowa przychodząca, przejście aplikacji w tło albo zajęcie mikrofonu przez inny
program - zawsze kończy się powrotem do czuwania, nigdy cichym zawieszeniem nasłuchu.

## Budowa polecenia

Zapis powstaje w dwóch krokach. Najpierw wskazywane jest miejsce, którego dotyczą
kolejne polecenia, a potem podawane są dane. Raz ustawione miejsce obowiązuje aż do
zmiany, więc kolejnych zasobów na tej samej ramce nie trzeba już nigdzie przypisywać.
Aktualnie ustawiona pasieka, ul, korpus i ramka pokazywane są przez cały czas na
ekranie, razem z ostatnio wykonanym zapisem.

- "otwórz pasiekę numer 1"
- "otwórz ul numer 5"
- "otwórz korpus numer 2", "otwórz półkorpus numer 2"
- "otwórz duża ramka numer 6 z lewej strony" (albo "z prawej", "z obu")
- "wstaw dużą ramkę numer 4", "usuń ramkę", "ustaw ramkę od 1 do 9"

Ten sam wpis można wykonać od razu dla wielu uli: "otwórz wszystkie ule" obejmuje całą
pasiekę, a "ustaw ule od 1 do 5" zawęża zapis do podanego zakresu.

## Co można zapisać głosem

- **Przegląd ramki** - "czerw trut 10 procent z lewej", "larwy 35 procent z prawej",
  a tak samo jajka, pierzga, miód, pokarm, nakrop, dojrzały, węza i susz. Można też
  podać matkę wraz z kolorem znaku ("czerwona matka z lewej"), mateczniki ("2 mateczniki
  z prawej") oraz to, co zostało do zrobienia albo już zrobione ("trzeba wirować",
  "izolacja", "przesuń w lewo").
- **Wyposażenie** - "ilość ramek w korpusie jest 10", "krata na korpusie numer 1",
  "usuń kratę", "podłoga jest brudna", "załącz zbieracz pyłku".
- **Matka** - "matka jest z roku 23", "matka jest dziewicza", "matka jest zamknięta",
  "matka ma biały znak numer 55", "matka jest do wymiany".
- **Rodzina** - "rodzina jest łagodna", "rodzina jest bardzo silna", "rodzina zawiązała
  kłąb", "martwe pszczoły 250 mililitrów".
- **Dokarmianie** - "syrop jeden do jednego 1 przecinek 5 litr", "ciasto 1 przecinek 0
  kilo", "zostało 30 procent pokarmu".
- **Leczenie** - "chemia 1 dawka", "wstaw paski 3 sztuki", "kwas 40 mililitrów",
  "roztocza 218 sztuk".
- **Zbiory** - "zbiór miodu 10 razy duża ramka", "zbiór pyłku 825 mililitrów".
- **Data wpisu** - zapisy trafiają na dzień dzisiejszy, ale datę można cofnąć: "ustaw
  inny dzień 15", "ustaw inny miesiąc 3", "ustaw inny rok 22", a "ustaw aktualną datę"
  przywraca dzień bieżący.

Wartości ułamkowe wymawiane są ze słowem "przecinek" ("1 przecinek 5 litr").

## Notatki dyktowane

Poza poleceniami można podyktować zwykły tekst, a aplikacja zapisze go w takiej postaci,
w jakiej został wypowiedziany. Notatka ma dwa miejsca docelowe:

- "zanotuj" (albo "zapisz notatkę", "Hej Maja notatka do przeglądu") - treść trafia do
  uwag dzisiejszego przeglądu wybranego ula,
- "Hej Maja notatka do Notesu" - powstaje osobny wpis w Notesie.

Dyktowanie kończy się słowami "Hej Maja". Jeżeli w ustawieniach włączone jest
"Nagrywanie notatek", razem z tekstem zachowywane jest nagranie dźwiękowe, które można
odsłuchać przy notatce - przydaje się wtedy, gdy zapis wyszedł przekręcony. Nagrania
zostają na telefonie, nie są wysyłane do chmury i kasują się po 7 dniach albo razem
z notatką.

## Cofanie zapisu

Pomyłkę można odwołać poleceniem "Hej Maja cofnij ostatni zapis" (albo "cofnij ostatni
wpis"). Cofnąć da się do pięciu ostatnich zapisujących poleceń, także tych wydanych dla
wszystkich uli w pasiece. Polecenia, które niczego nie zapisują - ustawienie pasieki,
ula czy ramki - nie zajmują miejsca w tej historii.

## Pomoc w trakcie pracy

Pełny spis poleceń otwiera ikona "?" na ekranie sterowania głosem. To samo okno
przywołuje polecenie "pomóż mi", a po dodaniu słowa kierunkowego pokazywana jest tylko
wybrana część spisu - "przegląd pomóż mi", "matka pomóż mi", "dokarmianie pomóż mi",
"leczenie pomóż mi", "zbiory pomóż mi", "notatki pomóż mi". Okno zamyka polecenie
"zamknij pomoc". W spisie tekst pogrubiony oznacza słowa wymagane, pochylony - takie,
które można pominąć, ukośnik oddziela wyrazy do wyboru, a czerwony kolor to przykładowa
wartość.

## Ustawienia

Zachowanie funkcji zmienia się na ekranie "Sterowanie głosem", dostępnym z "Ustawień"
w części "Parametryzacja":

- "Podgląd korpusu w trakcie poleceń" - zamiast podpowiedzi z listą poleceń ekran
  pokazuje rysunek korpusu aktualizowany po każdym zapisie, w układzie poziomym;
- "Nagrywanie notatek" - opisane wyżej nagrania dyktowanych notatek;
- suwaki głośności - osobno dla wypowiedzi Mai i dla sygnałów potwierdzenia.

## Wskazówki

1. Mówić spokojnie i całymi frazami - polecenie rozpoznawane jest jako całość, więc
   dłuższa przerwa w środku zdania potrafi je rozerwać na dwie części.
2. Odczekać na sygnał potwierdzenia, zanim wypowiadane jest kolejne polecenie.
3. Przed pierwszym przeglądem warto przejrzeć spis poleceń pod ikoną "?" - Maja rozumie
   podane w nim sformułowania, a nie ich dowolne odpowiedniki.
4. Ekran nie gaśnie w trakcie pracy, dlatego przy dłuższym przeglądzie dobrze jest mieć
   naładowany telefon.
