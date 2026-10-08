import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../globals.dart' as globals;
import 'db_helper.dart';

//Płatne sterowanie głosem - roczna subskrypcja ze sklepu (App Store / Google Play) przez RevenueCat,
//08.10.2026 (etap 4 planu pliki/plan_subskrypcja_glos.md).
//
//Dostęp do głosu (plan pkt 2.2): data `memory.ddo` (okres bezpłatny ALBO - od 08.10.2026 - późniejsza
//z okresu bezpłatnego i opłaconej subskrypcji, bo serwer tak liczy be_do przy synchronizacji konta)
//LUB aktywne uprawnienie "voice" w SDK RevenueCat (działa od razu po zakupie i offline - SDK trzyma
//stan w pamięci telefonu).
//
//Konto w RevenueCat = 'hb_<be_id>' - tak samo jak na serwerze (lib/subskrypcja.php). Dzięki temu
//zakup przechodzi na nowy telefon i między iPhonem a Androidem z tym samym kontem Hey Maya.
//Po zakupie / przywróceniu aplikacja prosi serwer (cbt_hi_subskrypcja.php, z tokenem) o sprawdzenie
//subskrypcji w RevenueCat - serwer zapisuje ją u siebie (praca zespołowa) i odsyła nowe be_do.
class Subskrypcja {
  //Klucze PUBLICZNE SDK RevenueCat (Project settings → API keys: aplikacja iOS "appl_...",
  //aplikacja Android "goog_..."). Są publiczne z założenia - mogą być w repozytorium (klucz TAJNY
  //"sk_..." jest tylko na serwerze, w lib/konf.php). PUSTE = zakupy jeszcze niedostępne:
  //ekran subskrypcji pokazuje komunikat, a głos działa jak dotąd do daty ddo.
  static const String _kluczIos = '';
  static const String _kluczAndroid = '';

  //identyfikator uprawnienia (entitlement) w RevenueCat - ten sam co HB_RC_UPRAWNIENIE na serwerze
  static const String uprawnienie = 'voice';
  static const String _adresSerwera = 'https://darys.pl/cbt_hi_subskrypcja.php';

  static bool _skonfigurowane = false;
  static String _konto = ''; //be_id, na które zalogowane jest SDK
  static CustomerInfo? _info; //ostatni stan konta z SDK
  //ekrany (subskrypcja, ustawienia głosu) odświeżają się, gdy SDK zgłosi zmianę
  static final ValueNotifier<int> zmiana = ValueNotifier<int>(0);

  static String get _klucz =>
      Platform.isIOS ? _kluczIos : (Platform.isAndroid ? _kluczAndroid : '');

  //czy w tej wersji aplikacji da się w ogóle kupić subskrypcję (są klucze RevenueCat)
  static bool get zakupyDostepne => _klucz.isNotEmpty;

  //Uruchomienie SDK dla konta [beId] (memory.id). Bezpieczne do wielokrotnego wołania:
  //przy starcie aplikacji i przy otwarciu ekranu subskrypcji (np. zaraz po aktywacji).
  //false = brak kluczy / konta / błąd - zakupy niedostępne, aplikacja działa dalej.
  static Future<bool> init(String beId) async {
    if (_klucz.isEmpty || !RegExp(r'^[0-9]{1,10}$').hasMatch(beId)) return false;
    try {
      if (!_skonfigurowane) {
        final konfiguracja = PurchasesConfiguration(_klucz)..appUserID = 'hb_$beId';
        await Purchases.configure(konfiguracja);
        _skonfigurowane = true;
        _konto = beId;
        Purchases.addCustomerInfoUpdateListener(_odczytaj);
        _odczytaj(await Purchases.getCustomerInfo());
      } else if (_konto != beId) {
        //inne konto Hey Maya na tym telefonie (ponowna aktywacja innym e-mailem)
        final wynik = await Purchases.logIn('hb_$beId');
        _konto = beId;
        _odczytaj(wynik.customerInfo);
      }
      return true;
    } catch (e) {
      debugPrint('Subskrypcja.init: $e');
      return _skonfigurowane;
    }
  }

  static void _odczytaj(CustomerInfo info) {
    _info = info;
    zmiana.value++;
  }

  static EntitlementInfo? get _upr => _info?.entitlements.active[uprawnienie];

  //koniec opłaconej subskrypcji wg SDK; null = brak subskrypcji albo zakup bezterminowy
  static DateTime? get _sklepDo {
    final String? d = _upr?.expirationDate;
    return d == null ? null : DateTime.tryParse(d)?.toLocal();
  }

  //aktywna opłacona subskrypcja wg SDK (stan zapamiętany w telefonie - także bez internetu)
  static bool get aktywnaWSklepie {
    final e = _upr;
    if (e == null) return false;
    if (e.expirationDate == null) return true; //bezterminowo
    final DateTime? d = _sklepDo;
    return d != null && d.isAfter(DateTime.now());
  }

  //subskrypcja nie odnowi się (anulowana w sklepie) - dostęp do końca opłaconego okresu
  static bool get nieOdnowiSie => aktywnaWSklepie && _upr?.willRenew == false;
  //sklep zgłasza kłopot z płatnością (karta wygasła itp.)
  static bool get problemZPlatnoscia => aktywnaWSklepie && _upr?.billingIssueDetectedAt != null;

  //Czy sterowanie głosem jest dostępne (plan pkt 2.2). Klucz (`bez_klucza`) i język sprawdza
  //przycisk na ekranie startowym - tu tylko termin. [ddo] - memory.ddo, 'RRRR-MM-DD', dzień włącznie.
  static bool glosDostepny(String ddo) {
    if (aktywnaWSklepie) return true;
    final DateTime? d = DateTime.tryParse(ddo);
    if (d == null) return true; //nieczytelna data (nie powinno się zdarzyć) - nie blokujemy głosu
    final DateTime teraz = DateTime.now();
    return !DateTime(teraz.year, teraz.month, teraz.day).isAfter(DateTime(d.year, d.month, d.day));
  }

  //data "sterowanie głosem do" do wyświetlenia, 'RRRR-MM-DD': późniejsza z ddo i końca subskrypcji
  //wg SDK (zaraz po zakupie serwer może jeszcze nie znać subskrypcji); bezterminowo = '9999-12-31'
  static String dataDo(String ddo) {
    String sklep = '';
    if (aktywnaWSklepie) {
      final DateTime? d = _sklepDo;
      sklep = d == null
          ? '9999-12-31'
          : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    final String bezplatnie = ddo.length >= 10 ? ddo.substring(0, 10) : ddo;
    return sklep.compareTo(bezplatnie) > 0 ? sklep : bezplatnie;
  }

  //'RRRR-MM-DD' -> dd.mm.rrrr (albo rrrr-mm-dd przy en_US), jak w "O aplikacji";
  //'9999-...' (zakup bezterminowy) -> [bezterminowo]
  static String naEkran(String data, String bezterminowo) {
    if (data.startsWith('9999')) return bezterminowo;
    final DateTime? d = DateTime.tryParse(data);
    if (d == null) return data;
    final String rok = d.year.toString().padLeft(4, '0');
    final String miesiac = d.month.toString().padLeft(2, '0');
    final String dzien = d.day.toString().padLeft(2, '0');
    return globals.isEuropeanFormat() ? '$dzien.$miesiac.$rok' : '$rok-$miesiac-$dzien';
  }

  //roczny pakiet z bieżącej oferty (offering) RevenueCat - cena w walucie sklepu; null = brak / błąd
  static Future<Package?> pakiet() async {
    if (!_skonfigurowane) return null;
    try {
      final Offering? oferta = (await Purchases.getOfferings()).current;
      if (oferta == null) return null;
      return oferta.annual ??
          (oferta.availablePackages.isNotEmpty ? oferta.availablePackages.first : null);
    } catch (e) {
      debugPrint('Subskrypcja.pakiet: $e');
      return null;
    }
  }

  //zakup; wynik: 'ok', 'anulowane', 'oczekuje' (płatność czeka na potwierdzenie sklepu), 'blad'
  static Future<String> kup(Package pakiet) async {
    try {
      final wynik = await Purchases.purchase(PurchaseParams.package(pakiet));
      _odczytaj(wynik.customerInfo);
      await potwierdzNaSerwerze();
      return aktywnaWSklepie ? 'ok' : 'oczekuje';
    } on PlatformException catch (e) {
      final kod = PurchasesErrorHelper.getErrorCode(e);
      if (kod == PurchasesErrorCode.purchaseCancelledError) return 'anulowane';
      if (kod == PurchasesErrorCode.paymentPendingError) return 'oczekuje';
      debugPrint('Subskrypcja.kup: $kod ${e.message}');
      return 'blad';
    } catch (e) {
      debugPrint('Subskrypcja.kup: $e');
      return 'blad';
    }
  }

  //przywrócenie zakupów (nowy telefon, ponowna instalacja); wynik: 'ok', 'brak', 'blad'
  static Future<String> przywroc() async {
    try {
      _odczytaj(await Purchases.restorePurchases());
      await potwierdzNaSerwerze();
      return aktywnaWSklepie ? 'ok' : 'brak';
    } catch (e) {
      debugPrint('Subskrypcja.przywroc: $e');
      return 'blad';
    }
  }

  //Prośba do serwera o sprawdzenie subskrypcji w RevenueCat (serwer nie przyjmuje dat od aplikacji).
  //Zapisuje nowe be_do w memory.ddo; zwraca je albo null (brak tokenu / sieci / bez zmian).
  //Wołający odświeża provider Memory.
  static Future<String?> potwierdzNaSerwerze() async {
    if (globals.token.isEmpty || _konto.isEmpty) return null;
    try {
      final r = await http
          .post(Uri.parse(_adresSerwera),
              headers: {'Content-Type': 'application/json; charset=UTF-8'},
              body: jsonEncode({'token': globals.token}))
          .timeout(const Duration(seconds: 20));
      final odp = json.decode(r.body);
      if (odp is! Map) return null;
      //przy "error - revenuecat" serwer też podaje be_do (ostatni zapisany stan) - też poprawne
      final String beDo = (odp['be_do'] ?? '').toString();
      if (DateTime.tryParse(beDo) == null) return null;
      await DBHelper.updateKonto(_konto, {'do': beDo});
      return beDo;
    } catch (e) {
      debugPrint('Subskrypcja.potwierdzNaSerwerze: $e');
      return null;
    }
  }

  //strona zarządzania subskrypcją w sklepie (anulowanie, zmiana płatności)
  static Future<bool> zarzadzaj() async {
    final String adres = _info?.managementURL ??
        (Platform.isIOS
            ? 'https://apps.apple.com/account/subscriptions'
            : 'https://play.google.com/store/account/subscriptions');
    try {
      return await launchUrl(Uri.parse(adres), mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
