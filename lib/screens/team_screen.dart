import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../globals.dart' as globals;
import '../helpers/baza_zespolu.dart';
import '../models/apiarys.dart';
import '../models/frames.dart';
import '../models/harvest.dart';
import '../models/hives.dart';
import '../models/infos.dart';
import '../models/note.dart';
import '../models/photo.dart';
import '../models/purchase.dart';
import '../models/queen.dart';
import '../models/recording.dart';
import '../models/sale.dart';

//PRACA ZESPOŁOWA (etap 2, 07.10.2026) - sekcja w Zarządzaniu danymi.
//Właściciel (z abonamentem): zaprasza pracowników e-mailem, nadaje pasieki i prawa odczyt/zapis
//do 8 części bazy, zmienia je i odwołuje. Pracownik: przyjmuje / odrzuca zaproszenia, przełącza się
//między własną bazą a bazami właścicieli (osobne pliki SQLite), rezygnuje.
//Serwer: cbt_hi_zespol.php (tylko z tokenem urządzenia) - on pilnuje praw; ten ekran tylko je pokazuje.
//Specyfikacja: pliki/plan_praca_zespolowa.md.
class TeamScreen extends StatefulWidget {
  static const routeName = '/screen-team';
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  static const String _adres = 'https://darys.pl/cbt_hi_zespol.php';
  //8 części bazy - klucze jak na serwerze (HB_TABELE)
  static const List<String> _czesci = [
    'notatki', 'zbiory', 'zakupy', 'sprzedaz', 'matki', 'ramka', 'info', 'zdjecia'
  ];

  bool _laduje = true;
  String _blad = '';
  Map<String, dynamic>? _lista;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wczytaj());
  }

  String _nazwaCzesci(AppLocalizations l, String c) {
    switch (c) {
      case 'notatki': return l.nOtes;
      case 'zbiory': return l.hArvests;
      case 'zakupy': return l.pUrchase;
      case 'sprzedaz': return l.sAle;
      case 'matki': return l.qUeens;
      case 'ramka': return l.fRames;
      case 'info': return l.iNfos;
      case 'zdjecia': return l.pHotos;
    }
    return c;
  }

  //zapytanie do serwera zespołu; null = brak połączenia / zła odpowiedź
  Future<Map<String, dynamic>?> _zapytaj(Map<String, dynamic> dane) async {
    if (globals.token.isEmpty) return {'success': 'error - brak tokenu'};
    try {
      final r = await http
          .post(Uri.parse(_adres),
              headers: {'Content-Type': 'application/json; charset=UTF-8'},
              body: jsonEncode({'token': globals.token, ...dane}))
          .timeout(const Duration(seconds: 15));
      final o = json.decode(r.body);
      return o is Map<String, dynamic> ? o : null;
    } catch (_) {
      return null;
    }
  }

  String _komunikat(AppLocalizations l, dynamic s) {
    switch ('$s') {
      case 'error - brak tokenu':
      case 'error - token':
        return l.teamNoToken;
      case 'error - nie ma konta': return l.teamErrNoAccount;
      case 'error - limit pracownikow': return l.teamErrLimit;
      case 'error - wlasne konto': return l.teamErrOwnAccount;
      case 'error - juz pracownik': return l.teamErrAlready;
      case 'error - brak praw': return l.teamErrNoRights;
      case 'error - brak abonamentu': return l.teamNeedsSubscription;
    }
    return l.teamError('$s');
  }

  Future<void> _wczytaj() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _laduje = true);
    final o = await _zapytaj({'akcja': 'lista'});
    if (!mounted) return;
    setState(() {
      _laduje = false;
      if (o == null) {
        _blad = l.teamNoConnection;
      } else if (o['success'] != 'ok') {
        _blad = _komunikat(l, o['success']);
      } else {
        _lista = o;
        _blad = '';
      }
    });
  }

  //akcja na serwerze + komunikat błędu + odświeżenie listy; true = ok
  Future<bool> _akcja(Map<String, dynamic> dane) async {
    final l = AppLocalizations.of(context)!;
    final o = await _zapytaj(dane);
    if (!mounted) return false;
    if (o == null || o['success'] != 'ok') {
      _info(o == null ? l.teamNoConnection : _komunikat(l, o['success']));
      return false;
    }
    await _wczytaj();
    return true;
  }

  void _info(String tekst) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tekst)));
  }

  Future<bool> _potwierdz(String tytul, String tresc) async {
    final l = AppLocalizations.of(context)!;
    final wynik = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tytul),
        content: tresc.isEmpty ? null : Text(tresc),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK')),
        ],
      ),
    );
    return wynik == true;
  }

  String _opisPasiek(AppLocalizations l, dynamic pasieki) {
    final p = '${pasieki ?? '*'}';
    if (p == '*' || p.isEmpty) return l.teamAllApiaries;
    return l.teamApiaries(p.replaceAll(',', ', '));
  }

  String _opisPraw(AppLocalizations l, dynamic prawa) {
    if (prawa is! Map) return l.teamNone;
    final czesci = <String>[];
    for (final c in _czesci) {
      final p = prawa[c];
      if (p is! Map) continue;
      final rodzaje = <String>[
        if ('${p['odczyt']}' == '1') l.teamRead,
        if ('${p['zapis']}' == '1') l.teamWrite,
      ];
      if (rodzaje.isNotEmpty) czesci.add('${_nazwaCzesci(l, c)} (${rodzaje.join(', ')})');
    }
    return czesci.isEmpty ? l.teamNone : czesci.join('\n'); //każda część w osobnej linii
  }

  //---------- przełączanie baz ----------

  Future<void> _przelacz(String prefiks, String email, int stanowisko) async {
    final l = AppLocalizations.of(context)!;
    if (!await _potwierdz(l.teamSwitchConfirm, prefiks.isEmpty ? '' : l.teamSwitchInfo)) return;
    await przelaczBaze(prefiks, email, stanowisko);
    if (!mounted) return;
    await _odswiezDostawcow();
    if (!mounted) return;
    //ekran startowy od nowa - wczyta pasieki, notatki, ustawienia i konto z nowego pliku bazy
    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
  }

  //dane w pamięci aplikacji z nowego pliku bazy - część ekranów czyta providery bez ponownego pobrania
  Future<void> _odswiezDostawcow() async {
    final c = context;
    try {
      await Provider.of<Apiarys>(c, listen: false).fetchAndSetApiarys();
      await Provider.of<Hives>(c, listen: false).fetchAndSetHivesAll();
      await Provider.of<Queens>(c, listen: false).fetchAndSetQueens();
      await Provider.of<Notes>(c, listen: false).fetchAndSetNotatki();
      await Provider.of<Harvests>(c, listen: false).fetchAndSetZbiory();
      await Provider.of<Purchases>(c, listen: false).fetchAndSetZakupy();
      await Provider.of<Sales>(c, listen: false).fetchAndSetSprzedaz();
      await Provider.of<Photos>(c, listen: false).fetchAndSetPhotos();
      await Provider.of<Recordings>(c, listen: false).fetchAndSetRecordings();
      await Provider.of<Frames>(c, listen: false).fetchAndSetFrames();
      await Provider.of<Infos>(c, listen: false).fetchAndSetInfos();
    } catch (e) {
      debugPrint('TeamScreen._odswiezDostawcow: $e');
    }
  }

  //---------- formularz praw (zaproszenie / zmiana) ----------

  Future<void> _formularz({Map<String, dynamic>? pracownik}) async {
    final l = AppLocalizations.of(context)!;
    final bool nowy = pracownik == null;
    final Map<String, dynamic> pr = pracownik ?? const <String, dynamic>{};
    final emailCtrl = TextEditingController();
    String pasieki = nowy ? '*' : '${pr['pasieki'] ?? '*'}';
    bool wszystkie = pasieki == '*';
    final Set<int> wybrane = wszystkie
        ? <int>{}
        : pasieki.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e > 0).toSet();
    final Map<String, Map<String, bool>> prawa = {
      for (final c in _czesci)
        c: {
          'odczyt': !nowy && '${pr['prawa']?[c]?['odczyt']}' == '1',
          'zapis': !nowy && '${pr['prawa']?[c]?['zapis']}' == '1',
        }
    };
    final moje = Provider.of<Apiarys>(context, listen: false).items.map((a) => a.pasiekaNr).toSet().toList()..sort();

    final zapisz = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ustaw) => AlertDialog(
          title: Text(nowy ? l.teamInvite : '${l.teamEditWorker}: ${pr['email']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nowy) ...[
                  //opis nad polem (zawija się w wąskim oknie), pole wyróżnione ramką i ikoną
                  Text(l.teamEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  tileColor: Colors.transparent, //motyw daje ListTile białe tło - tu ma być tło okna
                  title: Text(l.teamAllApiaries),
                  value: wszystkie,
                  onChanged: (v) => ustaw(() => wszystkie = v ?? true),
                ),
                if (!wszystkie)
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final nr in moje)
                        FilterChip(
                          label: Text('$nr'),
                          selected: wybrane.contains(nr),
                          onSelected: (v) => ustaw(() => v ? wybrane.add(nr) : wybrane.remove(nr)),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(children: [
                  const Expanded(child: SizedBox()),
                  SizedBox(width: 64, child: Text(l.teamRead, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                  SizedBox(width: 64, child: Text(l.teamWrite, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                ]),
                for (final c in _czesci)
                  Row(children: [
                    Expanded(child: Text(_nazwaCzesci(l, c))),
                    SizedBox(
                        width: 64,
                        child: Checkbox(
                            value: prawa[c]!['odczyt'],
                            onChanged: (v) => ustaw(() => prawa[c]!['odczyt'] = v ?? false))),
                    SizedBox(
                        width: 64,
                        child: Checkbox(
                            value: prawa[c]!['zapis'],
                            onChanged: (v) => ustaw(() => prawa[c]!['zapis'] = v ?? false))),
                  ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l.cancel)),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l.teamSave)),
          ],
        ),
      ),
    );
    if (zapisz != true || !mounted) return;
    if (!wszystkie && wybrane.isEmpty) wszystkie = true; //nic nie zaznaczone = wszystkie
    final dane = <String, dynamic>{
      'akcja': nowy ? 'zapros' : 'zmien',
      'pasieki': wszystkie ? '*' : (wybrane.toList()..sort()).join(','),
      'prawa': {
        for (final c in _czesci)
          c: {'odczyt': prawa[c]!['odczyt']! ? 1 : 0, 'zapis': prawa[c]!['zapis']! ? 1 : 0}
      },
      if (nowy) 'email': emailCtrl.text.trim(),
      if (!nowy) 'pracownik_id': pr['pracownik_id'],
    };
    if (await _akcja(dane) && nowy && mounted) _info(l.teamInvitationSent);
  }

  //---------- widok ----------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final List bazy = (_lista?['jako_pracownik'] as List?) ?? [];
    final List pracownicy = (_lista?['jako_wlasciciel'] as List?) ?? [];
    final bool abonament = _lista?['abonament'] == true;
    final aktywneBazy = bazy.where((b) => b['status'] == 'aktywny').toList();
    final zaproszenia = bazy.where((b) => b['status'] == 'zaproszony').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.teamWork, style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
      ),
      body: _laduje
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black)))
          : RefreshIndicator(
              onRefresh: _wczytaj,
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  if (_blad.isNotEmpty)
                    Card(child: ListTile(leading: const Icon(Icons.error_outline), title: Text(_blad), onTap: _wczytaj)),

                  //bazy, na których pracuję
                  _naglowek(l.teamBases),
                  Card(
                    child: ListTile(
                      leading: Icon(globals.aktywnaBaza.isEmpty ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                      title: Text(l.teamMyBase),
                      subtitle: globals.aktywnaBaza.isEmpty ? Text(l.teamCurrent) : null,
                      onTap: globals.aktywnaBaza.isEmpty ? null : () => _przelacz('', '', 0),
                    ),
                  ),
                  for (final b in aktywneBazy)
                    Card(
                      child: ListTile(
                        leading: Icon(globals.aktywnaBaza == b['prefiks'] ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                        title: Text('${b['email']}'),
                        subtitle: Text([
                          if (globals.aktywnaBaza == b['prefiks']) l.teamCurrent,
                          _opisPasiek(l, b['pasieki']),
                          _opisPraw(l, b['prawa']),
                          if (b['odczyt_mozliwy'] == false) l.teamReadBlocked
                          else if (b['zapis_mozliwy'] == false) l.teamWriteBlocked,
                        ].join('\n')),
                        isThreeLine: true,
                        onTap: globals.aktywnaBaza == b['prefiks']
                            ? null
                            : () => _przelacz('${b['prefiks']}', '${b['email']}', int.tryParse('${b['stanowisko']}') ?? 0),
                        trailing: IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: l.teamLeave,
                          onPressed: () async {
                            if (!await _potwierdz(l.teamLeaveConfirm, '${b['email']}')) return;
                            final ok = await _akcja({'akcja': 'odejdz', 'wlasciciel_id': b['wlasciciel_id']});
                            //rezygnacja z bazy, na której właśnie pracuję - powrót do własnej
                            if (ok && globals.aktywnaBaza == b['prefiks']) {
                              await przelaczBaze('', '', 0);
                              if (!mounted) return;
                              await _odswiezDostawcow();
                              if (!mounted) return;
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                            }
                          },
                        ),
                      ),
                    ),

                  //zaproszenia do mnie
                  if (zaproszenia.isNotEmpty) _naglowek(l.teamInvitations),
                  for (final z in zaproszenia)
                    Card(
                      child: ListTile(
                        title: Text('${z['email']}'),
                        subtitle: Text([
                          l.teamValidUntil('${z['wazne_do'] ?? ''}'),
                          _opisPasiek(l, z['pasieki']),
                          _opisPraw(l, z['prawa']),
                        ].join('\n')),
                        isThreeLine: true,
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            tooltip: l.teamAccept,
                            onPressed: () => _akcja({'akcja': 'przyjmij', 'wlasciciel_id': z['wlasciciel_id']}),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: l.teamReject,
                            onPressed: () => _akcja({'akcja': 'odrzuc', 'wlasciciel_id': z['wlasciciel_id']}),
                          ),
                        ]),
                      ),
                    ),

                  //moi pracownicy (tylko z własnej bazy - właściciel nadaje prawa do SWOJEJ bazy)
                  _naglowek(l.teamMyWorkers),
                  if (globals.aktywnaBaza.isNotEmpty)
                    Padding(padding: const EdgeInsets.all(8), child: Text(l.teamOnlyFromOwnBase))
                  else ...[
                    for (final p in pracownicy)
                      Card(
                        child: ListTile(
                          title: Text('${p['email']}'),
                          subtitle: Text([
                            p['status'] == 'aktywny'
                                ? l.teamStatusActive
                                : p['status'] == 'wygasle'
                                    ? l.teamStatusExpired
                                    : '${l.teamStatusInvited}, ${l.teamValidUntil('${p['wazne_do'] ?? ''}')}',
                            _opisPasiek(l, p['pasieki']),
                            _opisPraw(l, p['prawa']),
                          ].join('\n')),
                          isThreeLine: true,
                          onTap: abonament ? () => _formularz(pracownik: Map<String, dynamic>.from(p)) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove),
                            tooltip: l.teamRevoke,
                            onPressed: () async {
                              if (!await _potwierdz(l.teamRevokeConfirm, '${p['email']}')) return;
                              await _akcja({'akcja': 'odwolaj', 'pracownik_id': p['pracownik_id']});
                            },
                          ),
                        ),
                      ),
                    if (pracownicy.isEmpty && _blad.isEmpty)
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(l.teamNone)),
                    const SizedBox(height: 8),
                    if (abonament)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _formularz(),
                          icon: const Icon(Icons.person_add),
                          label: Text(l.teamInvite),
                        ),
                      )
                    else if (_blad.isEmpty)
                      Padding(padding: const EdgeInsets.all(8), child: Text(l.teamNeedsSubscription)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _naglowek(String tekst) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
        child: Text(tekst, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
}
