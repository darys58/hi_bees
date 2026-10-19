import 'package:flutter/material.dart';
import 'package:heymaya/l10n/app_localizations.dart';

import '../helpers/newsletter.dart';

//Ustawienia: przełącznik zgody na informacje o nowościach e-mailem (18.10.2026).
//Najpierw ostatni znany stan z telefonu, potem stan z serwera. Zmiana idzie od razu na serwer;
//bez sieci przełącznik wraca do poprzedniej pozycji i pokazuje komunikat.
class NewsletterTile extends StatefulWidget {
  const NewsletterTile({super.key});

  @override
  State<NewsletterTile> createState() => _NewsletterTileState();
}

class _NewsletterTileState extends State<NewsletterTile> {
  bool _zgoda = false;
  bool _zapisuje = false;

  @override
  void initState() {
    super.initState();
    _wczytaj();
  }

  Future<void> _wczytaj() async {
    final lokalnie = await Newsletter.zapamietanyStan();
    if (mounted) setState(() => _zgoda = lokalnie);
    final zSerwera = await Newsletter.pobierz();
    if (zSerwera != null && mounted && !_zapisuje) setState(() => _zgoda = zSerwera);
  }

  Future<void> _zmien(bool nowa) async {
    final poprzednia = _zgoda;
    setState(() {
      _zgoda = nowa;
      _zapisuje = true;
    });
    final ok = await Newsletter.zapisz(nowa, 'ustawienia');
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _zapisuje = false;
      if (!ok) _zgoda = poprzednia;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(!ok
          ? loc.newsletterError
          : (nowa ? loc.newsletterOn : loc.newsletterOff)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: SwitchListTile(
        secondary: Icon(Icons.mark_email_unread_outlined),
        title: Text(loc.newsletterTitle),
        subtitle: Text(loc.newsletterSubtitle),
        value: _zgoda,
        onChanged: _zapisuje ? null : _zmien,
      ),
    );
  }
}
