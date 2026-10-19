# Mailing 2027 – instalacja i uruchamianie

Wiadomość o usłudze (koniec okresu bezpłatnego, subskrypcja od 2027, zmiany w aplikacji, nowy Regulamin).

Dwie części:
- `generuj_maile.py` – generator treści, uruchamiany **lokalnie**,
- `cbt_hi_mailing.php` – wysyłka, działa **na serwerze**.

## 1. Przygotowanie treści (lokalnie)

1. W `generuj_maile.py` wpisz datę wejścia w życie nowego Regulaminu (linia 13), np.:
   ```python
   DATA_REGULAMINU = {'pl': '1 grudnia 2026 r.', 'en': '1 December 2026', 'de': '1. Dezember 2026'}
   ```
   Mail trzeba wysłać **co najmniej 14 dni przed tą datą**. Dopóki zostaje `[[DATA]]`, serwer zablokuje wysyłkę.
2. Wygeneruj pliki HTML:
   ```bash
   cd pliki/mailing_2027
   python3 generuj_maile.py
   ```
   Skrypt nadpisze `mail_pl.html`, `mail_en.html` i `mail_de.html`. Teksty poprawiasz zawsze w `.py`, nigdy w plikach HTML.
   Logo w nagłówku to `logo.png` (kopia `pliki/logo_HeyMaya_e9af2d_www.png`), dołączane do maila jako załącznik osadzony. W podglądzie pliku HTML w przeglądarce go nie widać, w mailu testowym tak.
3. Temat maila ustawiasz **w dwóch miejscach**: `temat` w `generuj_maile.py` (tylko komentarz w HTML) i `$tematy` w `cbt_hi_mailing.php` (ten faktycznie wysyłany).

## 2. Konfiguracja skryptu PHP (lokalnie, przed wgraniem)

W `cbt_hi_mailing.php` uzupełnij:
```php
define('HB_MAILING_KLUCZ', 'tu-losowy-ciag');   // np. wynik: openssl rand -hex 16
define('HB_MAILING_TEST', 'twoj@adres.pl');     // adres do maili testowych
```
⚠️ Tych wartości **nie commituj**, bo repozytorium jest publiczne. Wpisz je tylko w kopii, którą wgrywasz na serwer.

## 3. Instalacja na serwerze

Ułóż pliki na serwerze **darys.pl** (nie heymaya.eu!), w katalogu głównym, tym samym, w którym leży `cbt_hi_kod_v2.php`:
```
cbt_hi_mailing.php
mailing_2027/
    mail_pl.html
    mail_en.html
    mail_de.html
    logo.png         ← logo w nagłówku, dołączane do maila (cid:logo)
    .htaccess        ← ukryty plik, łatwo go pominąć przy wgrywaniu!
```
- `.htaccess` blokuje dostęp do katalogu z przeglądarki, bo będzie tam lista wysłanych adresów.
- Katalog `mailing_2027/` musi mieć **prawo zapisu** dla PHP. Skrypt tworzy w nim `wyslane.txt` i `.blokada`.
- Hasło SMTP skrypt bierze z `lib/konf.php` (`SMTP_PASS`), tak jak `lib/poczta.php`, więc nic więcej nie trzeba ustawiać.
- Opcjonalnie: w `mailing_2027/wypisani.txt` możesz wpisać adresy, które mają być pominięte, po jednym w wierszu.

## 4. Uruchamianie (w przeglądarce)

W adresach poniżej zamiast `KLUCZ` wpisz wartość `HB_MAILING_KLUCZ`.

**a) Podgląd.** Nic nie wysyła, pokazuje liczbę odbiorców w każdym języku:
```
https://darys.pl/cbt_hi_mailing.php?klucz=KLUCZ&tryb=podglad
```
Jeśli zobaczysz komunikat „UWAGA: niewpisana data”, wróć do kroku 1.

**b) Test.** Wysyła trzy wersje (PL, EN, DE) na adres `HB_MAILING_TEST`:
```
https://darys.pl/cbt_hi_mailing.php?klucz=KLUCZ&tryb=test
```
Sprawdź, jak maile wyglądają w poczcie, także na telefonie, i czy nie wpadają do spamu.

**c) Wysyłka porcjami:**
```
https://darys.pl/cbt_hi_mailing.php?klucz=KLUCZ&tryb=wyslij&ile=40
```
- Odświeżaj stronę po zakończeniu każdej porcji, aż zobaczysz **„Zostało: 0”**.
- Między mailami są 2 sekundy przerwy, więc porcja 40 maili trwa około 1,5 minuty. Maksymalna porcja to 100.
- Wysłane adresy trafiają do `wyslane.txt`, więc ponowne uruchomienie nie wyśle nikomu drugiego maila.
- Zamknięcie karty nie przerywa porcji w połowie. Uruchomienie w drugim oknie jest zablokowane.
- Po trzech błędach z rzędu skrypt sam przerywa wysyłkę. Wtedy sprawdź SMTP.

## 5. Po wysyłce

- **Usuń `cbt_hi_mailing.php` z serwera** albo wyczyść w nim `HB_MAILING_KLUCZ`.
- Plik `mailing_2027/wyslane.txt` możesz pobrać na pamiątkę, a potem usunąć cały katalog.

## Kiedy wysłać

- Dopiero gdy wersja nowsza niż 1.13.6 jest już w sklepach, bo mail opisuje nowe funkcje.
- Co najmniej 14 dni przed datą nowego Regulaminu (`DATA_REGULAMINU`).
- Regulamin (4.5–4.6) i Polityka prywatności (PL/EN) z dopisanymi wiadomościami e-mail muszą być już opublikowane na heymaya.eu.
