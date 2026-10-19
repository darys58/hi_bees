<?php
//cbt_hi_mailing.php - jednorazowa wysyłka WIADOMOŚCI O USŁUDZE (koniec okresu bezpłatnego, subskrypcja od 2027,
//zmiany w aplikacji, nowy Regulamin) do kont z tabeli bees. Treści generuje mailing_2027/generuj_maile.py
//NOWY PLIK (Claude), 18.10.2026. Wgrać do katalogu głównego (obok cbt_hi_kod_v2.php), a obok niego
//katalog mailing_2027/ z plikami mail_pl.html, mail_en.html, mail_de.html, logo.png i .htaccess.
//
//Użycie (w przeglądarce, KLUCZ = wartość HB_MAILING_KLUCZ niżej):
//  cbt_hi_mailing.php?klucz=KLUCZ&tryb=podglad        - liczby odbiorców wg języka, nic nie wysyła
//  cbt_hi_mailing.php?klucz=KLUCZ&tryb=test           - trzy wersje (PL, EN, DE) na adres HB_MAILING_TEST
//  cbt_hi_mailing.php?klucz=KLUCZ&tryb=wyslij&ile=40  - kolejna porcja; powtarzać, aż "zostało: 0"
//
//Wysłane adresy trafiają do mailing_2027/wyslane.txt - ponowne uruchomienie NIE wysyła drugi raz.
//Pominięci: mailing_2027/wypisani.txt, jeden adres w wierszu (np. ktoś wprost poprosił o brak maili).
//Hasło SMTP z lib/konf.php ($GLOBALS['SMTP_PASS']), jak w lib/poczta.php.
//Po zakończeniu wysyłki USUNĄĆ ten plik z serwera (albo wyczyścić HB_MAILING_KLUCZ).

define('HB_MAILING_KLUCZ', '');            //losowy ciąg (np. openssl rand -hex 16); PUSTY = skrypt nie działa
define('HB_MAILING_TEST', '');             //Twój adres do testu; NIE wpisywać w repozytorium (jest publiczne)
define('HB_MAILING_JEZYK_PUSTY', 'pl');    //wersja dla kont bez zapisanego be_jezyk (stare konta)
define('HB_MAILING_PAUZA', 2);             //sekundy między mailami - żeby SMTP nie uznał wysyłki za spam
define('HB_MAILING_KATALOG', __DIR__.'/mailing_2027');

$tematy = array(
	'pl' => 'Hey Maya: zmiany w usłudze od 1 grudnia 2026',
	'en' => 'Hey Maya: service changes from 1 December 2026',
	'de' => 'Hey Maya: Änderungen des Dienstes ab 1. Dezember 2026',
);

header('Content-Type: text/plain; charset=utf-8');
error_reporting(E_ALL ^ E_NOTICE);

$klucz = isset($_GET['klucz']) ? (string)$_GET['klucz'] : '';
if (HB_MAILING_KLUCZ === '' || !hash_equals(HB_MAILING_KLUCZ, $klucz)) {
	http_response_code(403);
	exit("brak dostępu\n");
}

include "lib/konf.php";
include "lib/connect.php";
require_once __DIR__.'/phpmailer/class.phpmailer.php';

//jedna wysyłka naraz (np. podwójne kliknięcie)
if (!is_dir(HB_MAILING_KATALOG)) exit("brak katalogu ".HB_MAILING_KATALOG."\n");
$blokada = @fopen(HB_MAILING_KATALOG.'/.blokada', 'c');
if (!$blokada) exit("brak prawa zapisu w katalogu ".HB_MAILING_KATALOG." (ustaw np. 755 lub 775)\n");
if (!flock($blokada, LOCK_EX | LOCK_NB)) exit("wysyłka już trwa w innym oknie\n");

//logo w nagłówku (cid:logo w treści)
if (!is_file(HB_MAILING_KATALOG.'/logo.png')) exit("brak pliku ".HB_MAILING_KATALOG."/logo.png\n");

//treści maili
$tresci = array();
$niegotowe = array();
foreach ($tematy as $jez => $temat) {
	$plik = HB_MAILING_KATALOG.'/mail_'.$jez.'.html';
	if (!is_file($plik)) exit("brak pliku $plik\n");
	$tresci[$jez] = file_get_contents($plik);
	//niewpisana data wejścia w życie Regulaminu ([[DATA]] w generuj_maile.py) - nie wysyłamy
	if (strpos($tresci[$jez], '[[') !== false) $niegotowe[] = 'mail_'.$jez.'.html';
}

function hbMailingJezyk($beJezyk) {
	$j = strtolower(substr(trim((string)$beJezyk), 0, 2));
	if ($j === '') return HB_MAILING_JEZYK_PUSTY;
	if ($j === 'pl' || $j === 'de') return $j;
	return 'en'; //en, fr, es, pt, it i inne
}

//wersja tekstowa (AltBody) - programy bez HTML i filtry antyspamowe
function hbMailingTekst($html) {
	$t = preg_replace('#<!--.*?-->#s', '', $html);
	$t = preg_replace('#<(style|title)\b.*?</\1>#si', '', $t);
	$t = preg_replace('#<div style="display:none.*?</div>#si', '', $t); //preheader
	$t = preg_replace('#<a [^>]*href="([^"]+)"[^>]*>(.*?)</a>#si', '$2 ($1)', $t);
	$t = preg_replace('#<(br|/p|/h1|/h2|/div|/tr)\b[^>]*>#i', "\n", $t);
	$t = html_entity_decode(strip_tags($t), ENT_QUOTES, 'UTF-8');
	$t = preg_replace("#[ \t]+#", ' ', $t);
	$t = preg_replace("#\n\s*\n\s*#", "\n\n", $t);
	return trim(str_replace("\xC2\xA0", ' ', $t));
}

function hbMailingWyslij($odbiorca, $temat, $html) {
	if (empty($GLOBALS['SMTP_PASS'])) return 'brak SMTP_PASS w lib/konf.php';
	$mail = new PHPMailer;
	$mail->isSMTP();
	$mail->Host = 'smtp.zenbox.pl';
	$mail->SMTPAuth = true;
	$mail->Username = 'maya@heymaya.eu';
	$mail->Password = $GLOBALS['SMTP_PASS'];
	$mail->Port = 587;
	$mail->CharSet = "UTF-8";
	$mail->From = 'maya@heymaya.eu';
	$mail->FromName = 'Hey Maya';
	$mail->addReplyTo('maya@heymaya.eu', 'Hey Maya');
	$mail->addAddress($odbiorca, '');
	$mail->isHTML(true);
	$mail->Subject = $temat;
	$mail->AddEmbeddedImage(HB_MAILING_KATALOG.'/logo.png', 'logo', 'logo.png', 'base64', 'image/png');
	$mail->Body = $html;
	$mail->AltBody = hbMailingTekst($html);
	if ($mail->Send()) return '';
	return $mail->ErrorInfo;
}

function hbMailingLista($plik) {
	$wynik = array();
	if (!is_file($plik)) return $wynik;
	foreach (file($plik, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $w) {
		$w = strtolower(trim($w));
		if ($w !== '') $wynik[$w] = true;
	}
	return $wynik;
}

$tryb = isset($_GET['tryb']) ? $_GET['tryb'] : 'podglad';

//--- test: trzy wersje na adres testowy, bez zapisu do wyslane.txt ---
if ($tryb === 'test') {
	if (!filter_var(HB_MAILING_TEST, FILTER_VALIDATE_EMAIL)) exit("wpisz poprawny adres w HB_MAILING_TEST\n");
	foreach ($tematy as $jez => $temat) {
		$blad = hbMailingWyslij(HB_MAILING_TEST, '[TEST '.strtoupper($jez).'] '.$temat, $tresci[$jez]);
		echo strtoupper($jez).': '.($blad === '' ? 'wysłany' : 'BŁĄD - '.$blad)."\n";
	}
	exit;
}

//--- odbiorcy z bazy: unikalne adresy, język z najnowszego konta o tym adresie ---
$conn = connect();
select_db($conn, $GLOBALS['DBNAME']);
mysqli_set_charset($conn, 'utf8');

$odbiorcy = array(); //adres => język
$zle = 0;
$res = mysqli_query($conn, "SELECT be_email, be_jezyk FROM bees ORDER BY be_id");
if (!$res) { error_log('cbt_hi_mailing: '.mysqli_error($conn)); exit("błąd zapytania do bazy\n"); }
while ($w = mysqli_fetch_assoc($res)) {
	$adres = strtolower(trim((string)$w['be_email']));
	if (!filter_var($adres, FILTER_VALIDATE_EMAIL)) { $zle++; continue; }
	$odbiorcy[$adres] = hbMailingJezyk($w['be_jezyk']);
}

$wyslane = hbMailingLista(HB_MAILING_KATALOG.'/wyslane.txt');
$wypisani = hbMailingLista(HB_MAILING_KATALOG.'/wypisani.txt');

$doWyslania = array();
$wgJezyka = array('pl' => 0, 'en' => 0, 'de' => 0);
foreach ($odbiorcy as $adres => $jez) {
	$wgJezyka[$jez]++;
	if (!isset($wyslane[$adres]) && !isset($wypisani[$adres])) $doWyslania[$adres] = $jez;
}

if ($tryb === 'podglad') {
	echo "Konta z poprawnym adresem: ".count($odbiorcy)."  (PL ".$wgJezyka['pl'].", EN ".$wgJezyka['en'].", DE ".$wgJezyka['de'].")\n";
	echo "Pominięte - błędny lub pusty adres: $zle\n";
	echo "Już wysłane: ".count($wyslane).", wypisani: ".count($wypisani)."\n";
	$ile = array('pl' => 0, 'en' => 0, 'de' => 0);
	foreach ($doWyslania as $jez) $ile[$jez]++;
	echo "Zostało do wysłania: ".count($doWyslania)."  (PL ".$ile['pl'].", EN ".$ile['en'].", DE ".$ile['de'].")\n";
	echo "Konta bez be_jezyk dostaną wersję: ".strtoupper(HB_MAILING_JEZYK_PUSTY)."\n";
	if ($niegotowe) echo "UWAGA: niewpisana data [[...]] w: ".implode(', ', $niegotowe)." - wysyłka zablokowana\n";
	exit;
}

if ($tryb !== 'wyslij') exit("nieznany tryb\n");
if ($niegotowe) exit("niewpisana data [[...]] w: ".implode(', ', $niegotowe)." - uzupełnij DATA_REGULAMINU w generuj_maile.py\n");

//--- wysyłka porcji ---
$ile = isset($_GET['ile']) ? max(1, min(100, (int)$_GET['ile'])) : 40;
set_time_limit(60 + $ile * (HB_MAILING_PAUZA + 10));
ignore_user_abort(true); //zamknięcie karty nie przerywa porcji w połowie

$dziennik = fopen(HB_MAILING_KATALOG.'/wyslane.txt', 'a');
$ok = 0; $bledy = 0;
foreach (array_slice($doWyslania, 0, $ile, true) as $adres => $jez) {
	$blad = hbMailingWyslij($adres, $tematy[$jez], $tresci[$jez]);
	if ($blad === '') {
		fwrite($dziennik, $adres."\n");
		fflush($dziennik);
		$ok++;
	} else {
		$bledy++;
		error_log('cbt_hi_mailing do '.$adres.': '.$blad);
		echo "BŁĄD ($jez) $adres: $blad\n";
		if ($bledy >= 3 && $ok === 0) { echo "trzy błędy z rzędu - przerywam (sprawdź SMTP)\n"; break; }
	}
	sleep(HB_MAILING_PAUZA);
}
fclose($dziennik);

echo "Wysłane w tej porcji: $ok, błędy: $bledy\n";
echo "Zostało: ".max(0, count($doWyslania) - $ok)."\n";
