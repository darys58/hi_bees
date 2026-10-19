#!/usr/bin/env python3
# Generator maili mailing_2027: mail_pl.html, mail_en.html, mail_de.html z jednego szablonu.
# Teksty poprawiać TUTAJ i uruchamiać: python3 generuj_maile.py  (pliki HTML są nadpisywane).
#
# Charakter maila: WIADOMOŚĆ O USŁUDZE (regulamin, rozdz. 4 ust. 5), nie informacja handlowa –
# obecne konta nie mają zgody na newsletter (art. 398 PKE). Dlatego: najpierw zmiana warunków
# (koniec okresu bezpłatnego, subskrypcja), potem rzeczowa lista zmian w aplikacji, zawiadomienie
# o nowym Regulaminie (min. 14 dni przed wejściem w życie – rozdz. 10) i stopka bez „wypisz”.
#
# Logo w nagłówku: cid:logo – plik logo.png obok, dołączany w cbt_hi_mailing.php (AddEmbeddedImage);
# w podglądzie HTML w przeglądarce logo się nie wyświetla, w mailu testowym tak.
#
# DATA_REGULAMINU – data wejścia w życie nowego Regulaminu; wysyłka co najmniej 14 dni wcześniej.
import os

DATA_REGULAMINU = {'pl': '1 grudnia 2026 r.', 'en': '1 December 2026', 'de': '1. Dezember 2026'}

T = {
'pl': dict(
  temat='Hey Maya: zmiany w usłudze od 1 grudnia 2026',
  tytul='Hey Maya – zmiany w usłudze',
  preheader='Koniec okresu bezpłatnego sterowania głosem i pracy zespołowej, subskrypcja od 2027 roku, zmiany w aplikacji i nowa wersja Regulaminu.',
  haslo='Notatnik dla pszczelarzy',
  powitanie='Dzień dobry!',
  wstep=['Piszemy, ponieważ od 1 stycznia 2027 r. zmieniają się warunki korzystania z Hey Maya. Poniżej znajdziesz, co się zmienia, a także przegląd zmian w aplikacji z ostatnich miesięcy i informację o nowej wersji Regulaminu.'],
  sub_tytul='Od 1 stycznia 2027 r. – subskrypcja',
  sub_1='Do 31 grudnia 2026 r. sterowanie głosem i praca zespołowa są <strong>bezpłatne dla wszystkich</strong>. Od 1 stycznia 2027 r. obie funkcje będą dostępne w ramach jednej, rocznej subskrypcji:',
  cena='99,99 zł', okres='/ rok', cena_uwaga='',
  sub_2='<strong>Wszystkie pozostałe funkcje zostają bezpłatne</strong> – przeglądy ramek, zarządzanie matkami, leczenie, zbiory, raporty, notatki, kopia w chmurze i cała reszta.',
  sub_3='Subskrypcję można kupić w aplikacji: <strong>O aplikacji → Subskrypcja</strong>. Płatność obsługuje App Store lub Google Play, a subskrypcja działa na wszystkich telefonach z tym samym kontem Hey Maya – także po przejściu z iPhone\'a na Androida i odwrotnie. Można ją anulować w każdej chwili w ustawieniach sklepu.',
  sub_4='Okres bezpłatny nie zmienia się automatycznie w płatną subskrypcję – o zakupie decydujesz sam. Rok subskrypcji liczy się od dnia zakupu.',
  zm_tytul='Zmiany w aplikacji',
  zm_wstep='W ostatnich wersjach aplikacji doszły m.in.:',
  zmiany=[
    ('🔳', 'Kody QR na ulach', 'Wydruk naklejek z kodami dla wybranych uli. Zeskanowanie kodu aparatem – albo polecenie głosowe „czytaj kod” – otwiera pasiekę i ul, tak samo jak tag NFC.'),
    ('👥', 'Praca zespołowa', 'Zapraszanie pomocników do swojej bazy z prawami odczytu lub zapisu w wybranych pasiekach i zakresach danych. Każdy pracuje na swoim telefonie, dane trafiają do jednej bazy.'),
    ('🐝', 'Stan rodziny', 'Nowe cechy rodziny (m.in. „chora”, „strutowiała”), ikonki stanu i siły rodziny w statystyce ula, kolor ikony belki ula według najpoważniejszego problemu.'),
    ('🎙️', 'Sterowanie głosem', 'Zdjęcia poleceniem „zrób zdjęcie”, notatka do ostatniego zapisu („zanotuj”), cofanie poleceniem „cofnij ostatni zapis”, otwieranie ula tagiem NFC.'),
    ('🍯', 'Zbiory i raporty', 'Podsumowanie zbiorów osobno dla każdej pasieki, raport osypu varroa, eksport danych do CSV z ośmiu ekranów, liczba nowych ramek z węzą wstawionych do ula od początku sezonu.'),
    ('☁️', 'Kopia w chmurze', 'Ochrona tokenem urządzenia, automatyczna synchronizacja konta, usunięte wpisy znikają też z chmury i z innych telefonów, a import nie nadpisuje niewysłanych zmian.'),
  ],
  aktualizuj='Zmiany są w najnowszej wersji aplikacji, dostępnej w sklepach:',
  reg_tytul='Nowa wersja Regulaminu i Polityki prywatności',
  reg_tekst='Od <strong>{data}</strong> obowiązuje nowa wersja Regulaminu i Polityki prywatności. Dopisaliśmy, jakie wiadomości e-mail wysyłamy: wiadomości o usłudze (takie jak ta) oraz – tylko za odrębną zgodą – informacje o nowościach. Jeśli nie akceptujesz zmian, możesz usunąć konto w aplikacji (O aplikacji → Usuń konto).',
  reg_linki=[('Regulamin', 'https://heymaya.eu/index.php/regulamin/'), ('Polityka prywatności', 'https://heymaya.eu/index.php/polityka-prywatnosci/')],
  pytania='Pytania? Odpisz na tego maila albo napisz na maya@heymaya.eu.',
  pozdrowienie='Pozdrawiamy,',
  podpis='Zespół Hey Maya',
  strona='https://heymaya.eu/',
  stopka='Wysyłamy tę wiadomość, ponieważ zmieniają się warunki usługi Hey Maya, z której korzystasz (wiadomość o usłudze).',
),
'en': dict(
  temat='Hey Maya: service changes from 1 December 2026',
  tytul='Hey Maya – service changes',
  preheader='End of the free period for voice control and teamwork, the subscription from 2027, changes in the app and new Terms.',
  haslo='A notebook for beekeepers',
  powitanie='Hello!',
  wstep=['We are writing because the terms of using Hey Maya change on 1 January 2027. Below you will find what changes, an overview of changes in the app from recent months and information about the new version of the Terms.'],
  sub_tytul='From 1 January 2027 – subscription',
  sub_1='Until 31 December 2026, voice control and teamwork are <strong>free for everyone</strong>. From 1 January 2027 both features will be available with one annual subscription:',
  cena='€29.99', okres='/ year', cena_uwaga='In Poland 99.99 zł; outside the euro area the store shows the price in your local currency.',
  sub_2='<strong>All other features stay free</strong> – frame inspections, queen management, treatment, harvests, reports, notes, cloud backup and everything else.',
  sub_3='The subscription can be bought in the app: <strong>About app → Subscription</strong>. Payment is handled by the App Store or Google Play, and the subscription works on all phones with the same Hey Maya account – also when you switch from iPhone to Android or the other way round. It can be cancelled at any time in the store settings.',
  sub_4='The free period does not turn into a paid subscription automatically – buying it is your decision. The subscription year starts on the day of purchase.',
  zm_tytul='Changes in the app',
  zm_wstep='Recent versions of the app have added, among other things:',
  zmiany=[
    ('🔳', 'QR codes on hives', 'Printing code stickers for selected hives. Scanning a code with the camera – or the voice command “read code” – opens the apiary and hive, just like an NFC tag.'),
    ('👥', 'Teamwork', 'Inviting helpers to your database with read or write rights in selected apiaries and data scopes. Everyone works on their own phone, the data goes into one database.'),
    ('🐝', 'Colony state', 'New colony traits (including “sick” and “drone laying”), icons for colony state and strength in the hive statistics, hive bar icon colour by the most serious problem.'),
    ('🎙️', 'Voice control', 'Photos with “take photo”, a note for the last entry, undo with “undo last save”, opening a hive with an NFC tag.'),
    ('🍯', 'Harvests and reports', 'Harvest summary for each apiary separately, varroa mite drop report, CSV export from eight screens, number of new frames with foundation added to the hive since the start of the season.'),
    ('☁️', 'Cloud backup', 'Protection with a device token, automatic account sync, deleted entries also disappear from the cloud and other phones, and import does not overwrite unsent changes.'),
  ],
  aktualizuj='The changes are in the latest version of the app, available in the stores:',
  reg_tytul='New version of the Terms and Privacy Policy',
  reg_tekst='From <strong>{data}</strong> a new version of the Terms and Privacy Policy applies. We have added which e-mails we send: service messages (like this one) and – only with separate consent – news about the app. If you do not accept the changes, you can delete your account in the app (About app → Delete account).',
  reg_linki=[('Terms', 'https://heymaya.eu/index.php/en/regulations/'), ('Privacy Policy', 'https://heymaya.eu/index.php/en/privacy-policy/')],
  pytania='Questions? Reply to this email or write to maya@heymaya.eu.',
  pozdrowienie='Best regards,',
  podpis='The Hey Maya Team',
  strona='https://heymaya.eu/index.php/en/english/',
  stopka='We are sending this message because the terms of the Hey Maya service you use are changing (service message).',
),
'de': dict(
  temat='Hey Maya: Änderungen des Dienstes ab 1. Dezember 2026',
  tytul='Hey Maya – Änderungen des Dienstes',
  preheader='Ende der kostenlosen Phase für Teamarbeit und Sprachsteuerung, Abonnement ab 2027, Änderungen in der App und neue Nutzungsbedingungen.',
  haslo='Das Notizbuch für Imker',
  powitanie='Guten Tag!',
  wstep=['Wir schreiben Ihnen, weil sich am 1. Januar 2027 die Bedingungen für die Nutzung von Hey Maya ändern. Unten finden Sie, was sich ändert, einen Überblick über die Änderungen in der App der letzten Monate und eine Information zur neuen Fassung der Nutzungsbedingungen.'],
  sub_tytul='Ab 1. Januar 2027 – Abonnement',
  sub_1='Bis zum 31. Dezember 2026 sind Teamarbeit und Sprachsteuerung <strong>für alle kostenlos</strong>. Ab dem 1. Januar 2027 sind beide Funktionen mit einem gemeinsamen Jahresabonnement verfügbar:',
  cena='29,99 €', okres='/ Jahr', cena_uwaga='Außerhalb des Euroraums zeigt der Store den Preis in Ihrer Landeswährung.',
  sub_2='<strong>Alle anderen Funktionen bleiben kostenlos</strong> – Wabendurchsichten, Königinnenverwaltung, Behandlung, Ernten, Berichte, Notizen, Cloud-Sicherung und alles andere.',
  sub_3='Das Abonnement kann in der App gekauft werden: <strong>Über die App → Abonnement</strong>. Die Zahlung läuft über den App Store oder Google Play, und das Abonnement gilt auf allen Handys mit demselben Hey-Maya-Konto – auch beim Wechsel vom iPhone zu Android und umgekehrt. Es kann jederzeit in den Store-Einstellungen gekündigt werden.',
  sub_4='Die kostenlose Phase geht nicht automatisch in ein kostenpflichtiges Abonnement über – über den Kauf entscheiden Sie selbst. Das Abonnementjahr beginnt am Tag des Kaufs. Die Sprachsteuerung funktioniert derzeit auf Englisch und Polnisch (App-Sprache Englisch oder Polnisch).',
  zm_tytul='Änderungen in der App',
  zm_wstep='In den letzten Versionen der App ist unter anderem hinzugekommen:',
  zmiany=[
    ('🔳', 'QR-Codes an den Beuten', 'Druck von Aufklebern mit Codes für ausgewählte Beuten. Das Scannen eines Codes mit der Kamera öffnet den Bienenstand und die Beute – genauso wie ein NFC-Tag.'),
    ('👥', 'Teamarbeit', 'Helfer in die eigene Datenbank einladen, mit Lese- oder Schreibrechten in ausgewählten Bienenständen und Datenbereichen. Jeder arbeitet auf seinem eigenen Handy, die Daten landen in einer Datenbank.'),
    ('🐝', 'Volkszustand', 'Neue Merkmale des Volkes (u. a. „krank“, „drohnenbrütig“), Symbole für Zustand und Stärke in der Beutenstatistik, Farbe des Symbols in der Beutenleiste nach dem ernstesten Problem.'),
    ('🍯', 'Ernten und Berichte', 'Erntezusammenfassung für jeden Bienenstand einzeln, Varroa-Milbenfall-Bericht, CSV-Export aus acht Bildschirmen, Anzahl neuer Rähmchen mit Mittelwand, die seit Saisonbeginn in die Beute gegeben wurden.'),
    ('☁️', 'Cloud-Sicherung', 'Schutz mit einem Gerätetoken, automatische Kontosynchronisierung, gelöschte Einträge verschwinden auch aus der Cloud und von anderen Handys, und der Import überschreibt keine nicht gesendeten Änderungen.'),
  ],
  aktualizuj='Die Änderungen sind in der neuesten Version der App enthalten, erhältlich in den Stores:',
  reg_tytul='Neue Fassung der Nutzungsbedingungen und der Datenschutzerklärung',
  reg_tekst='Ab dem <strong>{data}</strong> gilt eine neue Fassung der Nutzungsbedingungen und der Datenschutzerklärung. Wir haben ergänzt, welche E-Mails wir senden: Nachrichten zum Dienst (wie diese) und – nur mit gesonderter Einwilligung – Neuigkeiten über die App. Wenn Sie mit den Änderungen nicht einverstanden sind, können Sie Ihr Konto in der App löschen (Über die App → Konto löschen).',
  reg_linki=[('Nutzungsbedingungen (Englisch)', 'https://heymaya.eu/index.php/en/regulations/'), ('Datenschutzerklärung (Englisch)', 'https://heymaya.eu/index.php/en/privacy-policy/')],
  pytania='Fragen? Antworten Sie auf diese E-Mail oder schreiben Sie an maya@heymaya.eu.',
  pozdrowienie='Mit freundlichen Grüßen',
  podpis='Ihr Hey-Maya-Team',
  strona='https://heymaya.eu/index.php/de/deutsch/',
  stopka='Wir senden Ihnen diese Nachricht, weil sich die Bedingungen des von Ihnen genutzten Dienstes Hey Maya ändern (Nachricht zum Dienst).',
),
}

F = 'font-family:Arial, Helvetica, sans-serif;'

def zmiana(ikona, tytul, opis, pierwsza):
    b = '' if pierwsza else ' border-top:1px solid #f1e6d2;'
    return f'''          <tr>
            <td width="48" valign="top" style="padding:10px 0; font-size:24px; line-height:28px;{b}">{ikona}</td>
            <td valign="top" style="padding:10px 0; {F} color:#333333;{b}">
              <div style="font-size:16px; line-height:22px; font-weight:bold; color:#3b2a10;">{tytul}</div>
              <div style="font-size:14px; line-height:21px; margin-top:2px;">{opis}</div>
            </td>
          </tr>
'''

def przycisk(napis, url):
    return f'''            <td class="przycisk-sklep" align="center" style="padding:0 6px;">
              <a href="{url}" target="_blank" style="display:inline-block; background-color:#3b2a10; color:#ffffff; {F} font-size:15px; font-weight:bold; text-decoration:none; padding:12px 22px; border-radius:30px;">{napis}</a>
            </td>
'''

def mail(jez, t):
    wstep = ''.join(f'        <p style="margin:0 0 14px 0; font-size:16px; line-height:25px;">{p}</p>\n' for p in t['wstep'])
    zmiany = ''.join(zmiana(*z, i == 0) for i, z in enumerate(t['zmiany']))
    uwaga = (f'<p style="margin:-6px 0 12px 0; font-size:13px; line-height:19px; color:#777777;">{t["cena_uwaga"]}</p>\n' if t['cena_uwaga'] else '')
    linki = ' &nbsp;·&nbsp; '.join(f'<a href="{u}" target="_blank" style="color:#c47a00; font-weight:bold;">{n}</a>' for n, u in t['reg_linki'])
    return f'''<!DOCTYPE html>
<html lang="{jez}" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="x-apple-disable-message-reformatting">
<meta name="color-scheme" content="light">
<meta name="supported-color-schemes" content="light">
<title>{t['tytul']}</title>
<!-- WYGENEROWANE przez generuj_maile.py – nie poprawiać ręcznie. Temat: {t['temat']} -->
<style>
  @media only screen and (max-width: 620px) {{
    .kontener {{ width: 100% !important; }}
    .odstep {{ padding-left: 20px !important; padding-right: 20px !important; }}
    .przycisk-sklep {{ display: block !important; width: 100% !important; padding-bottom: 10px !important; }}
  }}
</style>
</head>
<body style="margin:0; padding:0; background-color:#f6efe2;">

<div style="display:none; max-height:0; overflow:hidden; font-size:1px; line-height:1px; color:#f6efe2;">{t['preheader']}</div>

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#f6efe2;">
<tr>
<td align="center" style="padding:24px 10px;">

  <table role="presentation" class="kontener" width="600" cellpadding="0" cellspacing="0" border="0" style="width:600px; max-width:600px; background-color:#ffffff; border-radius:14px; overflow:hidden;">

    <!-- NAGŁÓWEK -->
    <tr>
      <td align="center" style="background-color:#e9af2d; padding:20px 30px 22px 30px;">
        <img src="cid:logo" width="180" height="180" alt="Hey Maya" style="display:block; width:180px; height:180px; border:0; outline:none; text-decoration:none; {F} font-size:28px; font-weight:bold; color:#3b2a10;">
        <div style="{F} font-size:15px; line-height:21px; color:#3b2a10; margin-top:6px;">{t['haslo']}</div>
      </td>
    </tr>

    <!-- WSTĘP -->
    <tr>
      <td class="odstep" style="padding:30px 40px 4px 40px; {F} color:#333333;">
        <h1 style="margin:0 0 14px 0; font-size:22px; line-height:28px; color:#3b2a10;">{t['powitanie']}</h1>
{wstep}      </td>
    </tr>

    <!-- SUBSKRYPCJA -->
    <tr>
      <td class="odstep" style="padding:8px 40px 8px 40px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#fff6e5; border:2px solid #f5a623; border-radius:12px;">
          <tr>
            <td style="padding:22px 26px; {F} color:#333333;">
              <h2 style="margin:0 0 12px 0; font-size:20px; line-height:26px; color:#3b2a10;">{t['sub_tytul']}</h2>
              <p style="margin:0 0 12px 0; font-size:15px; line-height:23px;">{t['sub_1']}</p>
              <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:4px 0 14px 0;">
                <tr>
                  <td style="background-color:#ffffff; border-radius:10px; padding:10px 18px; {F}">
                    <span style="font-size:26px; line-height:30px; font-weight:bold; color:#c47a00;">{t['cena']}</span>
                    <span style="font-size:15px; line-height:20px; color:#555555;">&nbsp;{t['okres']}</span>
                  </td>
                </tr>
              </table>
              {uwaga}<p style="margin:0 0 12px 0; font-size:15px; line-height:23px;">{t['sub_2']}</p>
              <p style="margin:0 0 12px 0; font-size:15px; line-height:23px;">{t['sub_3']}</p>
              <p style="margin:0; font-size:15px; line-height:23px;">{t['sub_4']}</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>

    <!-- ZMIANY W APLIKACJI -->
    <tr>
      <td class="odstep" style="padding:24px 40px 0 40px; {F} color:#333333;">
        <h2 style="margin:0 0 6px 0; font-size:19px; line-height:25px; color:#c47a00;">{t['zm_tytul']}</h2>
        <p style="margin:0; font-size:15px; line-height:23px;">{t['zm_wstep']}</p>
      </td>
    </tr>
    <tr>
      <td class="odstep" style="padding:6px 40px 0 40px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
{zmiany}        </table>
      </td>
    </tr>

    <!-- AKTUALIZACJA -->
    <tr>
      <td class="odstep" align="center" style="padding:18px 40px 6px 40px; {F} color:#333333;">
        <p style="margin:0 0 14px 0; font-size:15px; line-height:23px;">{t['aktualizuj']}</p>
        <table role="presentation" cellpadding="0" cellspacing="0" border="0">
          <tr>
{przycisk('App Store', 'https://apps.apple.com/app/id6447341365')}{przycisk('Google Play', 'https://play.google.com/store/apps/details?id=eu.darys.heymaya')}          </tr>
        </table>
      </td>
    </tr>

    <!-- REGULAMIN -->
    <tr>
      <td class="odstep" style="padding:24px 40px 0 40px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#f7f7f7; border-radius:10px;">
          <tr>
            <td style="padding:18px 22px; {F} color:#333333;">
              <div style="font-size:16px; line-height:22px; font-weight:bold; color:#3b2a10;">{t['reg_tytul']}</div>
              <p style="margin:8px 0 10px 0; font-size:14px; line-height:21px;">{t['reg_tekst'].format(data=DATA_REGULAMINU[jez])}</p>
              <p style="margin:0; font-size:14px; line-height:21px;">{linki}</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>

    <!-- ZAKOŃCZENIE -->
    <tr>
      <td class="odstep" style="padding:24px 40px 30px 40px; {F} color:#333333;">
        <p style="margin:0 0 14px 0; font-size:15px; line-height:23px;">{t['pytania']}</p>
        <p style="margin:0; font-size:15px; line-height:23px;">{t['pozdrowienie']}<br>
          <span style="color:#777777;">{t['podpis']}</span></p>
      </td>
    </tr>

    <!-- STOPKA -->
    <tr>
      <td align="center" style="background-color:#3b2a10; padding:20px 30px; {F} color:#e8d9bd; font-size:13px; line-height:20px;">
        <a href="{t['strona']}" target="_blank" style="color:#f5a623; text-decoration:none; font-weight:bold;">heymaya.eu</a>
        &nbsp;·&nbsp;
        <a href="mailto:maya@heymaya.eu" style="color:#f5a623; text-decoration:none;">maya@heymaya.eu</a>
        <div style="margin-top:10px; color:#bfae8e; font-size:12px; line-height:18px;">{t['stopka']}</div>
      </td>
    </tr>

  </table>

</td>
</tr>
</table>

</body>
</html>
'''

if __name__ == '__main__':
    kat = os.path.dirname(os.path.abspath(__file__))
    for jez, t in T.items():
        with open(os.path.join(kat, f'mail_{jez}.html'), 'w', encoding='utf-8') as f:
            f.write(mail(jez, t))
        print(f'mail_{jez}.html  temat: {t["temat"]}')
