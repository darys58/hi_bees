import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:heymaya/l10n/app_localizations.dart';
import '../helpers/subskrypcja.dart';
import '../models/memory.dart';
import 'voice_vosk_screen.dart';

//Ekran subskrypcji sterowania głosem (08.10.2026, etap 4 planu pliki/plan_subskrypcja_glos.md).
//Otwierany z przycisku "Sterowanie głosem" po końcu okresu (argument {'zGlosu': true} - po zakupie
//od razu przechodzi do sterowania) i z Ustawień → Sterowanie głosem → Subskrypcja.
//Treść wymagana przez sklepy: cena za rok w walucie sklepu, informacja o automatycznym odnawianiu
//i anulowaniu, "Przywróć zakupy", linki do warunków korzystania i polityki prywatności.
class VoiceSubscriptionScreen extends StatefulWidget {
  static const routeName = '/voice-subscription';

  const VoiceSubscriptionScreen({super.key});

  @override
  State<VoiceSubscriptionScreen> createState() => _VoiceSubscriptionScreenState();
}

class _VoiceSubscriptionScreenState extends State<VoiceSubscriptionScreen> {
  //Linki wymagane przez sklepy. TODO przed włączeniem zakupów: strony na heymaya.eu (etap 1 planu).
  //Pusty regulamin = na iOS standardowa licencja Apple (EULA), na Androidzie link ukryty;
  //pusta polityka prywatności = link ukryty (Apple jej WYMAGA przy subskrypcji - uzupełnić).
  static const String _regulamin = '';
  static const String _polityka = '';
  static const String _eulaApple = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  bool _wczytywanie = true;
  bool _zajete = false; //trwa zakup / przywracanie - przyciski nieaktywne
  bool _gotowe = false; //SDK uruchomione
  Package? _pakiet;
  bool _zGlosu = false;
  bool _pierwszy = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_pierwszy) return;
    _pierwszy = false;
    final arg = ModalRoute.of(context)?.settings.arguments;
    _zGlosu = arg is Map && arg['zGlosu'] == true;
    Subskrypcja.zmiana.addListener(_odswiez);
    _wczytaj();
  }

  @override
  void dispose() {
    Subskrypcja.zmiana.removeListener(_odswiez);
    super.dispose();
  }

  void _odswiez() {
    if (mounted) setState(() {});
  }

  String get _beId {
    final m = Provider.of<Memory>(context, listen: false).items;
    return m.isNotEmpty ? m[0].id : '';
  }

  String get _ddo {
    final m = Provider.of<Memory>(context, listen: false).items;
    return m.isNotEmpty ? m[0].ddo : '';
  }

  Future<void> _wczytaj() async {
    _gotowe = await Subskrypcja.init(_beId);
    if (_gotowe) _pakiet = await Subskrypcja.pakiet();
    if (mounted) setState(() => _wczytywanie = false);
  }

  String _data(AppLocalizations l, String data) => Subskrypcja.naEkran(data, l.subLifetime);

  void _komunikat(String tekst) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tekst), duration: const Duration(seconds: 4)));
  }

  //po zakupie / przywróceniu: nowa data z serwera do providera Memory (belka "O aplikacji",
  //bramka przycisku głosu), a gdy przyszliśmy z przycisku głosu - od razu do sterowania
  Future<void> _poZakupie(AppLocalizations l) async {
    await Provider.of<Memory>(context, listen: false).fetchAndSetMemory2();
    if (!mounted) return;
    _komunikat(l.subThanks(_data(l, Subskrypcja.dataDo(_ddo))));
    if (_zGlosu) Navigator.of(context).pushReplacementNamed(VoiceVoskScreen.routeName);
  }

  Future<void> _kup(AppLocalizations l) async {
    final Package? p = _pakiet;
    if (p == null || _zajete) return;
    setState(() => _zajete = true);
    final String wynik = await Subskrypcja.kup(p);
    if (!mounted) return;
    setState(() => _zajete = false);
    switch (wynik) {
      case 'ok':
        await _poZakupie(l);
        break;
      case 'oczekuje':
        _komunikat(l.subPending);
        break;
      case 'anulowane':
        break; //użytkownik sam zamknął okno sklepu - bez komunikatu
      default:
        _komunikat(l.subStoreError);
    }
  }

  Future<void> _przywroc(AppLocalizations l) async {
    if (_zajete) return;
    setState(() => _zajete = true);
    final String wynik = await Subskrypcja.przywroc();
    if (!mounted) return;
    setState(() => _zajete = false);
    if (wynik == 'ok') {
      await _poZakupie(l);
    } else {
      _komunikat(wynik == 'brak' ? l.subRestoreNone : l.subStoreError);
    }
  }

  Future<void> _otworz(String adres) async {
    try {
      await launchUrl(Uri.parse(adres), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final String ddo = _ddo;
    final bool dostepny = Subskrypcja.glosDostepny(ddo);
    final String dataDo = _data(l, Subskrypcja.dataDo(ddo));
    final String regulamin = _regulamin.isNotEmpty ? _regulamin : (Platform.isIOS ? _eulaApple : '');

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: Text(l.subTitle, style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[300], height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          //stan dostępu
          Card(
            child: ListTile(
              leading: Icon(dostepny ? Icons.check_circle_outline : Icons.info_outline,
                  color: dostepny ? Colors.green : Colors.orange),
              title: Text(dostepny ? l.subscryptionTo + dataDo : l.subEnded(dataDo)),
              subtitle: Subskrypcja.problemZPlatnoscia
                  ? Text(l.subBillingProblem)
                  : (Subskrypcja.nieOdnowiSie ? Text(l.subWillNotRenew) : null),
            ),
          ),
          const SizedBox(height: 12),
          Text(l.subDescription, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 20),

          if (_wczytywanie)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (!Subskrypcja.zakupyDostepne)
            Text(l.subUnavailable, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15))
          else if (_pakiet == null)
            Text(l.subStoreError, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15))
          else ...[
            //cena w walucie sklepu (zależy od kraju konta w sklepie, nie od języka aplikacji)
            Text(l.subPricePerYear(_pakiet!.storeProduct.priceString),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _zajete ? null : () => _kup(l),
                child: _zajete
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.subBuy, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            Text(l.subAutoRenew, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],

          if (_gotowe) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _zajete ? null : () => _przywroc(l),
              child: Text(l.subRestore),
            ),
            if (Subskrypcja.aktywnaWSklepie)
              TextButton(
                onPressed: () => Subskrypcja.zarzadzaj(),
                child: Text(l.subManage),
              ),
          ],

          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              if (regulamin.isNotEmpty)
                TextButton(onPressed: () => _otworz(regulamin), child: Text(l.subTerms)),
              if (_polityka.isNotEmpty)
                TextButton(onPressed: () => _otworz(_polityka), child: Text(l.subPrivacy)),
            ],
          ),
        ],
      ),
    );
  }
}
