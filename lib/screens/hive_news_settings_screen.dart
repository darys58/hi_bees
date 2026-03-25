import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;
import '../helpers/db_helper.dart';

class HiveNewsSettingsScreen extends StatefulWidget {
  static const routeName = '/hive-news-settings';

  @override
  State<HiveNewsSettingsScreen> createState() => _HiveNewsSettingsScreenState();
}

class _HiveNewsSettingsScreenState extends State<HiveNewsSettingsScreen> {
  late List<bool> _flags;

  @override
  void initState() {
    super.initState();
    final v = globals.summaryVisibility.padRight(7, '1');
    _flags = List.generate(7, (i) => v[i] == '1');
  }

  void _save() {
    final s = _flags.map((f) => f ? '1' : '0').join();
    globals.summaryVisibility = s;
    if (globals.deviceId.isNotEmpty) {
      DBHelper.updateMem1(globals.deviceId, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    // Kolejność wyświetlania jak w summary_screen:
    // Przegląd ramek, Zdjęcia, Rodzina, Matka, Zbiory, Dokarmianie, Leczenie
    // flagIndex = indeks bitu w summaryVisibility
    final categories = [
      {'label': l.frameReview, 'icon': Icons.grid_view, 'flagIndex': 0},
      {'label': l.photos, 'icon': Icons.photo_library, 'flagIndex': 6},
      {'label': l.cOlony, 'icon': Icons.groups, 'flagIndex': 1},
      {'label': l.qUeen, 'icon': Icons.circle, 'flagIndex': 2},
      {'label': l.hArvests, 'icon': Icons.inventory_2, 'flagIndex': 3},
      {'label': l.fEeding, 'icon': Icons.water_drop, 'flagIndex': 4},
      {'label': l.tReatment, 'icon': Icons.medical_services, 'flagIndex': 5},
    ];

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: Text(
          l.hiveNews,
          style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          return Card(
            child: ListTile(
              leading: Icon(categories[i]['icon'] as IconData),
              title: Text(categories[i]['label'] as String),
              trailing: Switch.adaptive(
                value: _flags[categories[i]['flagIndex'] as int],
                onChanged: (value) {
                  setState(() {
                    _flags[categories[i]['flagIndex'] as int] = value;
                  });
                  _save();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
