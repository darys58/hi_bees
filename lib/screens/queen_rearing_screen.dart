import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/notification_helper.dart';

/// Model jednego kalendarza wychowu matek
class QueenRearingCalendar {
  String name;
  DateTime graftingDate;
  int notifHour;
  int notifMinute;
  bool notificationsScheduled;
  int slot; // unikalny slot do obliczania ID powiadomień

  QueenRearingCalendar({
    required this.name,
    required this.graftingDate,
    this.notifHour = 8,
    this.notifMinute = 0,
    this.notificationsScheduled = false,
    required this.slot,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'graftingDate': graftingDate.toIso8601String(),
        'notifHour': notifHour,
        'notifMinute': notifMinute,
        'notificationsScheduled': notificationsScheduled,
        'slot': slot,
      };

  factory QueenRearingCalendar.fromJson(Map<String, dynamic> json) {
    return QueenRearingCalendar(
      name: json['name'] ?? '',
      graftingDate:
          DateTime.tryParse(json['graftingDate'] ?? '') ?? DateTime.now(),
      notifHour: json['notifHour'] ?? 8,
      notifMinute: json['notifMinute'] ?? 0,
      notificationsScheduled: json['notificationsScheduled'] ?? false,
      slot: json['slot'] ?? 0,
    );
  }
}

// ============================================================
// Ekran listy kalendarzy wychowu matek
// ============================================================
class QueenRearingScreen extends StatefulWidget {
  static const routeName = '/queen-rearing';

  @override
  State<QueenRearingScreen> createState() => _QueenRearingScreenState();
}

class _QueenRearingScreenState extends State<QueenRearingScreen> {
  static const String _prefsKey = 'queen_rearing_calendars';
  static const int _notifIdBase = 600000;
  static const int _stagesPerCalendar = 10; // 9 etapów + zapas
  static const List<int> _stageDays = [0, 1, 5, 7, 9, 10, 11, 18, 25];

  List<QueenRearingCalendar> _calendars = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);

    if (json != null) {
      final list = jsonDecode(json) as List;
      _calendars =
          list.map((e) => QueenRearingCalendar.fromJson(e)).toList();
    } else {
      // Migracja ze starego formatu (pojedynczy kalendarz)
      await _migrateOldFormat(prefs);
    }

    setState(() => _loaded = true);
  }

  Future<void> _migrateOldFormat(SharedPreferences prefs) async {
    final savedDate = prefs.getString('queen_rearing_date');
    if (savedDate != null) {
      final cal = QueenRearingCalendar(
        name: '#1',
        graftingDate: DateTime.tryParse(savedDate) ?? DateTime.now(),
        notifHour: prefs.getInt('queen_rearing_hour') ?? 8,
        notifMinute: prefs.getInt('queen_rearing_minute') ?? 0,
        notificationsScheduled:
            prefs.getBool('queen_rearing_scheduled') ?? false,
        slot: 0,
      );
      _calendars = [cal];
      await _saveCalendars();
      // Usuń stare klucze
      await prefs.remove('queen_rearing_date');
      await prefs.remove('queen_rearing_hour');
      await prefs.remove('queen_rearing_minute');
      await prefs.remove('queen_rearing_scheduled');
    }
  }

  Future<void> _saveCalendars() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_calendars.map((c) => c.toJson()).toList());
    await prefs.setString(_prefsKey, json);
  }

  int _nextSlot() {
    if (_calendars.isEmpty) return 0;
    return _calendars.map((c) => c.slot).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _addCalendar() async {
    final loc = AppLocalizations.of(context)!;
    final nameController = TextEditingController(
      text: '#${_calendars.length + 1}',
    );

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.qrNewCalendar),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: loc.qrCalendarName,
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: Text('OK'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final cal = QueenRearingCalendar(
        name: name,
        graftingDate: DateTime.now(),
        slot: _nextSlot(),
      );
      setState(() => _calendars.add(cal));
      await _saveCalendars();
      if (mounted) {
        _openCalendarDetail(_calendars.length - 1);
      }
    }
  }

  Future<void> _deleteCalendar(int index) async {
    final loc = AppLocalizations.of(context)!;
    final cal = _calendars[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.qrDeleteCalendar),
        content: Text('${cal.name} (${_formatDate(cal.graftingDate)})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.dElete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Anuluj powiadomienia tego kalendarza
      for (int i = 0; i < _stageDays.length; i++) {
        await NotificationHelper.cancelNotificationById(
            _notifIdBase + cal.slot * _stagesPerCalendar + i);
      }
      setState(() => _calendars.removeAt(index));
      await _saveCalendars();
    }
  }

  void _openCalendarDetail(int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QueenRearingDetailScreen(
          calendar: _calendars[index],
          onSave: (updated) {
            setState(() => _calendars[index] = updated);
            _saveCalendars();
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Ile etapów jeszcze przed nami
  int _remainingStages(QueenRearingCalendar cal) {
    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < _stageDays.length; i++) {
      final date = cal.graftingDate.add(Duration(days: _stageDays[i]));
      final dt = DateTime(
          date.year, date.month, date.day, cal.notifHour, cal.notifMinute);
      if (dt.isAfter(now)) count++;
    }
    return count;
  }

  bool _isCompleted(QueenRearingCalendar cal) {
    return _remainingStages(cal) == 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          loc.queenRearingCalendar,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addCalendar,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: Colors.grey[300], height: 1.0),
        ),
      ),
      body: !_loaded
          ? Center(child: CircularProgressIndicator())
          : _calendars.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month,
                            size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          loc.qrNoCalendars,
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _calendars.length,
                  itemBuilder: (ctx, index) {
                    final cal = _calendars[index];
                    final completed = _isCompleted(cal);
                    final remaining = _remainingStages(cal);
                    final lastDate = cal.graftingDate
                        .add(Duration(days: _stageDays.last));

                    return Dismissible(
                      key: ValueKey(cal.slot),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        await _deleteCalendar(index);
                        return false; // usuwamy ręcznie w _deleteCalendar
                      },
                      child: Card(
                        color: completed ? Colors.grey[100] : null,
                        elevation: completed ? 0 : 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                completed ? Colors.grey[400] : Colors.amber[700],
                            child: Icon(
                              completed ? Icons.check : Icons.calendar_month,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            cal.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: completed ? Colors.grey[600] : null,
                            ),
                          ),
                          subtitle: Text(
                            '${_formatDate(cal.graftingDate)} → ${_formatDate(lastDate)}'
                            '${cal.notificationsScheduled ? '  🔔' : ''}'
                            '${completed ? '' : '  ($remaining/${_stageDays.length})'}',
                            style: TextStyle(
                              color: completed ? Colors.grey[500] : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Colors.grey[400]),
                            onPressed: () => _deleteCalendar(index),
                          ),
                          onTap: () => _openCalendarDetail(index),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ============================================================
// Ekran szczegółów kalendarza (timeline)
// ============================================================
class _QueenRearingDetailScreen extends StatefulWidget {
  final QueenRearingCalendar calendar;
  final ValueChanged<QueenRearingCalendar> onSave;

  const _QueenRearingDetailScreen({
    required this.calendar,
    required this.onSave,
  });

  @override
  State<_QueenRearingDetailScreen> createState() =>
      _QueenRearingDetailScreenState();
}

class _QueenRearingDetailScreenState extends State<_QueenRearingDetailScreen> {
  static const int _notifIdBase = 600000;
  static const int _stagesPerCalendar = 10;
  static const List<int> _stageDays = [0, 1, 5, 7, 9, 10, 11, 18, 25];

  late QueenRearingCalendar _cal;

  @override
  void initState() {
    super.initState();
    _cal = widget.calendar;
  }

  int _notifId(int stageIndex) =>
      _notifIdBase + _cal.slot * _stagesPerCalendar + stageIndex;

  String _stageLabel(AppLocalizations loc, int index) {
    switch (index) {
      case 0: return loc.qrGrafting;
      case 1: return loc.qrCheckAcceptance;
      case 2: return loc.qrCellsSealed;
      case 3: return loc.qrHistolysis;
      case 4: return loc.qrCellIsolation;
      case 5: return loc.qrTransferToNucs;
      case 6: return loc.qrQueenEmergence;
      case 7: return loc.qrMatingFlights;
      case 8: return loc.qrCheckLaying;
      default: return '';
    }
  }

  IconData _stageIcon(int index) {
    switch (index) {
      case 0: return Icons.start;
      case 1: return Icons.check_circle_outline;
      case 2: return Icons.lock;
      case 3: return Icons.transform;
      case 4: return Icons.grid_view;
      case 5: return Icons.move_down;
      case 6: return Icons.child_care;
      case 7: return Icons.flight_takeoff;
      case 8: return Icons.egg_alt;
      default: return Icons.circle;
    }
  }

  Color _stageColor(int index) {
    switch (index) {
      case 0: return Colors.blue;
      case 1: return Colors.orange;
      case 2: return Colors.brown;
      case 3: return Colors.red;
      case 4: return Colors.indigo;
      case 5: return Colors.purple;
      case 6: return Colors.pink;
      case 7: return Colors.teal;
      case 8: return Colors.green;
      default: return Colors.grey;
    }
  }

  DateTime _stageDate(int stageIndex) {
    return _cal.graftingDate.add(Duration(days: _stageDays[stageIndex]));
  }

  bool _isDatePast(DateTime date) {
    final now = DateTime.now();
    final stageDateTime = DateTime(
        date.year, date.month, date.day, _cal.notifHour, _cal.notifMinute);
    return stageDateTime.isBefore(now);
  }

  Future<void> _pickGraftingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _cal.graftingDate,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _cal.graftingDate = picked;
        _cal.notificationsScheduled = false;
      });
      widget.onSave(_cal);
    }
  }

  Future<void> _pickNotifTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _cal.notifHour, minute: _cal.notifMinute),
    );
    if (picked != null) {
      setState(() {
        _cal.notifHour = picked.hour;
        _cal.notifMinute = picked.minute;
        _cal.notificationsScheduled = false;
      });
      widget.onSave(_cal);
    }
  }

  Future<void> _scheduleNotifications() async {
    // Anuluj wcześniejsze
    for (int i = 0; i < _stageDays.length; i++) {
      await NotificationHelper.cancelNotificationById(_notifId(i));
    }

    final loc = AppLocalizations.of(context)!;
    int scheduledCount = 0;

    for (int i = 0; i < _stageDays.length; i++) {
      final date = _stageDate(i);
      final dateTime = DateTime(
          date.year, date.month, date.day, _cal.notifHour, _cal.notifMinute);

      if (dateTime.isAfter(DateTime.now())) {
        await NotificationHelper.scheduleSimpleNotification(
          id: _notifId(i),
          title: 'Hey Maya - ${loc.queenRearingCalendar} (${_cal.name})',
          body: '${loc.qrDay} ${_stageDays[i]}: ${_stageLabel(loc, i)}',
          dateTime: dateTime,
        );
        scheduledCount++;
      }
    }

    setState(() => _cal.notificationsScheduled = true);
    widget.onSave(_cal);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${loc.qrNotificationsScheduled} ($scheduledCount)'),
        ),
      );
    }
  }

  Future<void> _cancelNotifications() async {
    for (int i = 0; i < _stageDays.length; i++) {
      await NotificationHelper.cancelNotificationById(_notifId(i));
    }

    setState(() => _cal.notificationsScheduled = false);
    widget.onSave(_cal);

    if (mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.qrNotificationsCancelled)),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _dayOfWeek(DateTime date) {
    const plDays = ['pon', 'wt', 'śr', 'czw', 'pt', 'sob', 'ndz'];
    const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const deDays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    const frDays = ['lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'];
    const esDays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const itDays = ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];
    const ptDays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

    final locale = Localizations.localeOf(context).languageCode;
    List<String> days;
    switch (locale) {
      case 'pl': days = plDays; break;
      case 'de': days = deDays; break;
      case 'fr': days = frDays; break;
      case 'es': days = esDays; break;
      case 'it': days = itDays; break;
      case 'pt': days = ptDays; break;
      default: days = enDays;
    }
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          _cal.name,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: Colors.grey[300], height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Wybór daty przekładania i godziny powiadomień
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickGraftingDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.qrGraftingDate,
                        labelStyle: TextStyle(fontSize: 13),
                        floatingLabelStyle: TextStyle(fontSize: 14),
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatDate(_cal.graftingDate)),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _pickNotifTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.qrNotifTime,
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${_cal.notifHour.toString().padLeft(2, '0')}:${_cal.notifMinute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista etapów
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _stageDays.length,
              itemBuilder: (ctx, index) {
                final date = _stageDate(index);
                final isPast = _isDatePast(date);
                final dayName = _dayOfWeek(date);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline linia
                    SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          Container(
                            width: 2,
                            height: index == 0 ? 0 : 20,
                            color: Colors.grey[300],
                          ),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                isPast ? Colors.grey[400] : _stageColor(index),
                            child: Icon(
                              isPast ? Icons.check : _stageIcon(index),
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          if (index < _stageDays.length - 1)
                            Container(
                              width: 2,
                              height: 30,
                              color: Colors.grey[300],
                            ),
                        ],
                      ),
                    ),
                    // Treść etapu
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 8, bottom: 8, top: index == 0 ? 0 : 4),
                        child: Card(
                          color: isPast ? Colors.grey[100] : null,
                          elevation: isPast ? 0 : 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _stageLabel(loc, index),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color:
                                              isPast ? Colors.grey[600] : null,
                                          decoration: isPast
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '$dayName, ${_formatDate(date)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isPast
                                              ? Colors.grey[500]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPast
                                        ? Colors.grey[300]
                                        : _stageColor(index)
                                            .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${loc.qrDay} ${_stageDays[index]}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isPast
                                          ? Colors.grey[600]
                                          : _stageColor(index),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Przyciski
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_cal.notificationsScheduled)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancelNotifications,
                      icon: Icon(Icons.notifications_off),
                      label: Text(loc.qrCancelNotifications),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                if (_cal.notificationsScheduled) SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scheduleNotifications,
                    icon: Icon(Icons.notifications_active),
                    label: Text(_cal.notificationsScheduled
                        ? loc.qrReschedule
                        : loc.qrScheduleNotifications),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
