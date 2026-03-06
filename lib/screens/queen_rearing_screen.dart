import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/notification_helper.dart';

class QueenRearingScreen extends StatefulWidget {
  static const routeName = '/queen-rearing';

  @override
  State<QueenRearingScreen> createState() => _QueenRearingScreenState();
}

class _QueenRearingScreenState extends State<QueenRearingScreen> {
  DateTime _graftingDate = DateTime.now();
  TimeOfDay _notifTime = TimeOfDay(hour: 8, minute: 0);
  bool _notificationsScheduled = false;

  // ID bazowe dla powiadomień wychowu matek: 600000+
  static const int _notifIdBase = 600000;

  // Etapy wychowu matek: dzień od przeszczepu
  static const List<int> _stageDays = [0, 1, 5, 7, 9, 10, 11, 18, 25];

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('queen_rearing_date');
    final savedHour = prefs.getInt('queen_rearing_hour');
    final savedMinute = prefs.getInt('queen_rearing_minute');
    final savedScheduled = prefs.getBool('queen_rearing_scheduled') ?? false;

    setState(() {
      if (savedDate != null) {
        _graftingDate = DateTime.tryParse(savedDate) ?? DateTime.now();
      }
      _notifTime = TimeOfDay(
        hour: savedHour ?? 8,
        minute: savedMinute ?? 0,
      );
      _notificationsScheduled = savedScheduled;
    });
  }

  Future<void> _saveState({required bool scheduled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'queen_rearing_date', _graftingDate.toIso8601String());
    await prefs.setInt('queen_rearing_hour', _notifTime.hour);
    await prefs.setInt('queen_rearing_minute', _notifTime.minute);
    await prefs.setBool('queen_rearing_scheduled', scheduled);
  }

  List<String> _stageKeys() {
    return [
      'qrGrafting',
      'qrCheckAcceptance',
      'qrCellsSealed',
      'qrHistolysis',
      'qrCellIsolation',
      'qrTransferToNucs',
      'qrQueenEmergence',
      'qrMatingFlights',
      'qrCheckLaying',
    ];
  }

  String _stageLabel(AppLocalizations loc, int index) {
    switch (index) {
      case 0:
        return loc.qrGrafting;
      case 1:
        return loc.qrCheckAcceptance;
      case 2:
        return loc.qrCellsSealed;
      case 3:
        return loc.qrHistolysis;
      case 4:
        return loc.qrCellIsolation;
      case 5:
        return loc.qrTransferToNucs;
      case 6:
        return loc.qrQueenEmergence;
      case 7:
        return loc.qrMatingFlights;
      case 8:
        return loc.qrCheckLaying;
      default:
        return '';
    }
  }

  IconData _stageIcon(int index) {
    switch (index) {
      case 0:
        return Icons.start;
      case 1:
        return Icons.check_circle_outline;
      case 2:
        return Icons.lock;
      case 3:
        return Icons.transform;
      case 4:
        return Icons.grid_view;
      case 5:
        return Icons.move_down;
      case 6:
        return Icons.child_care;
      case 7:
        return Icons.flight_takeoff;
      case 8:
        return Icons.egg_alt;
      default:
        return Icons.circle;
    }
  }

  Color _stageColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.brown;
      case 3:
        return Colors.red;
      case 4:
        return Colors.indigo;
      case 5:
        return Colors.purple;
      case 6:
        return Colors.pink;
      case 7:
        return Colors.teal;
      case 8:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  DateTime _stageDate(int stageIndex) {
    return _graftingDate.add(Duration(days: _stageDays[stageIndex]));
  }

  bool _isDatePast(DateTime date) {
    final now = DateTime.now();
    final stageDateTime = DateTime(
        date.year, date.month, date.day, _notifTime.hour, _notifTime.minute);
    return stageDateTime.isBefore(now);
  }

  Future<void> _pickGraftingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _graftingDate,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _graftingDate = picked;
        _notificationsScheduled = false;
      });
    }
  }

  Future<void> _pickNotifTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifTime,
    );
    if (picked != null) {
      setState(() {
        _notifTime = picked;
        _notificationsScheduled = false;
      });
    }
  }

  Future<void> _scheduleNotifications() async {
    // Anuluj wcześniejsze powiadomienia wychowu matek
    for (int i = 0; i < _stageDays.length; i++) {
      await NotificationHelper.cancelNotificationById(_notifIdBase + i);
    }

    final loc = AppLocalizations.of(context)!;
    int scheduledCount = 0;

    for (int i = 0; i < _stageDays.length; i++) {
      final date = _stageDate(i);
      final dateTime = DateTime(
          date.year, date.month, date.day, _notifTime.hour, _notifTime.minute);

      if (dateTime.isAfter(DateTime.now())) {
        await NotificationHelper.scheduleSimpleNotification(
          id: _notifIdBase + i,
          title: 'Hey Maya - ${loc.queenRearingCalendar}',
          body:
              '${loc.qrDay} ${_stageDays[i]}: ${_stageLabel(loc, i)}',
          dateTime: dateTime,
        );
        scheduledCount++;
      }
    }

    await _saveState(scheduled: true);
    setState(() {
      _notificationsScheduled = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.qrNotificationsScheduled} ($scheduledCount)'),
        ),
      );
    }
  }

  Future<void> _cancelNotifications() async {
    for (int i = 0; i < _stageDays.length; i++) {
      await NotificationHelper.cancelNotificationById(_notifIdBase + i);
    }

    await _saveState(scheduled: false);
    setState(() {
      _notificationsScheduled = false;
    });

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

  String _dayOfWeek(AppLocalizations loc, DateTime date) {
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
      case 'pl':
        days = plDays;
        break;
      case 'de':
        days = deDays;
        break;
      case 'fr':
        days = frDays;
        break;
      case 'es':
        days = esDays;
        break;
      case 'it':
        days = itDays;
        break;
      case 'pt':
        days = ptDays;
        break;
      default:
        days = enDays;
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
          loc.queenRearingCalendar,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Wybór daty przeszczepu i godziny powiadomień
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
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatDate(_graftingDate)),
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
                        '${_notifTime.hour.toString().padLeft(2, '0')}:${_notifTime.minute.toString().padLeft(2, '0')}',
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
                final dayName = _dayOfWeek(loc, date);

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
                            backgroundColor: isPast
                                ? Colors.grey[400]
                                : _stageColor(index),
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
                        padding:
                            EdgeInsets.only(left: 8, bottom: 8, top: index == 0 ? 0 : 4),
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
                                          color: isPast
                                              ? Colors.grey[600]
                                              : null,
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
                                        : _stageColor(index).withValues(alpha: 0.15),
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
                if (_notificationsScheduled)
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
                if (_notificationsScheduled) SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scheduleNotifications,
                    icon: Icon(Icons.notifications_active),
                    label: Text(_notificationsScheduled
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
