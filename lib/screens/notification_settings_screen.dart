import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../helpers/notification_helper.dart';
import '../helpers/db_helper.dart';

class NotificationSettingsScreen extends StatefulWidget {
  static const routeName = '/notification-settings';

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _enabled = true;
  int _hour = 8;
  int _minute = 0;
  bool _notesEnabled = true;
  int _notesAdvanceDays = 0;
  bool _inspectionEnabled = false;
  int _inspectionDays = 7;
  bool _feedingEnabled = false;
  int _feedingDays = 7;
  bool _treatmentEnabled = false;
  int _treatmentDays = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool(NotificationHelper.keyEnabled) ?? true;
      _hour = prefs.getInt(NotificationHelper.keyHour) ?? 8;
      _minute = prefs.getInt(NotificationHelper.keyMinute) ?? 0;
      _notesEnabled =
          prefs.getBool(NotificationHelper.keyNotesEnabled) ?? true;
      _notesAdvanceDays =
          prefs.getInt(NotificationHelper.keyNotesAdvanceDays) ?? 0;
      _inspectionEnabled =
          prefs.getBool(NotificationHelper.keyInspectionEnabled) ?? false;
      _inspectionDays =
          prefs.getInt(NotificationHelper.keyInspectionDays) ?? 7;
      _feedingEnabled =
          prefs.getBool(NotificationHelper.keyFeedingEnabled) ?? false;
      _feedingDays = prefs.getInt(NotificationHelper.keyFeedingDays) ?? 7;
      _treatmentEnabled =
          prefs.getBool(NotificationHelper.keyTreatmentEnabled) ?? false;
      _treatmentDays =
          prefs.getInt(NotificationHelper.keyTreatmentDays) ?? 5;
    });
  }

  Future<void> _saveAndReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationHelper.keyEnabled, _enabled);
    await prefs.setInt(NotificationHelper.keyHour, _hour);
    await prefs.setInt(NotificationHelper.keyMinute, _minute);
    await prefs.setBool(NotificationHelper.keyNotesEnabled, _notesEnabled);
    await prefs.setInt(
        NotificationHelper.keyNotesAdvanceDays, _notesAdvanceDays);
    await prefs.setBool(
        NotificationHelper.keyInspectionEnabled, _inspectionEnabled);
    await prefs.setInt(NotificationHelper.keyInspectionDays, _inspectionDays);
    await prefs.setBool(NotificationHelper.keyFeedingEnabled, _feedingEnabled);
    await prefs.setInt(NotificationHelper.keyFeedingDays, _feedingDays);
    await prefs.setBool(
        NotificationHelper.keyTreatmentEnabled, _treatmentEnabled);
    await prefs.setInt(NotificationHelper.keyTreatmentDays, _treatmentDays);

    await NotificationHelper.scheduleAllNotifications();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
      _saveAndReschedule();
    }
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _showDaysPickerDialog({
    required int currentValue,
    required int maxDays,
    required ValueChanged<int> onChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.remindAfterDays, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 230,
              width: 300,
              child: ListWheelScrollView(
                itemExtent: 70,
                physics: FixedExtentScrollPhysics(),
                perspective: 0.009,
                controller: FixedExtentScrollController(initialItem: currentValue),
                children: [
                  for (var i = 0; i <= maxDays; i++)
                    InkWell(
                      onTap: () {
                        onChanged(i);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        '$i',
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
        elevation: 24.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
      barrierDismissible: false,
    );
  }

  String _daysLabel(int value) {
    if (value == 1) return AppLocalizations.of(context)!.day;
    return AppLocalizations.of(context)!.days;
  }

  Widget _buildDaysSelector({
    required int value,
    required int maxDays,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 3),
          Text(
            AppLocalizations.of(context)!.on,  //na
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          SizedBox(width: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              side: BorderSide(color: Color.fromARGB(255, 162, 103, 0), width: 1),
            ),
            onPressed: () {
              _showDaysPickerDialog(
                currentValue: value,
                maxDays: maxDays,
                onChanged: onChanged,
              );
            },
            child: Text(
              '$value ${_daysLabel(value)}',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
          SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.aheadSchedule,  //przed terminem
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelector2({
    required int value,
    required int maxDays,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 3),
          Text(
            AppLocalizations.of(context)!.forr,  //za
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          SizedBox(width: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              side: BorderSide(color: Color.fromARGB(255, 162, 103, 0), width: 1),
            ),
            onPressed: () {
              _showDaysPickerDialog(
                currentValue: value,
                maxDays: maxDays,
                onChanged: onChanged,
              );
            },
            child: Text(
              '$value ${_daysLabel(value)}',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
          SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.sinceLastOne,  //od ostatniego
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          AppLocalizations.of(context)!.notificationSettings,
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
      body: ListView(
        children: [
          // Master toggle
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.notificationsEnabled),
            value: _enabled,
            onChanged: (v) {
              setState(() => _enabled = v);
              _saveAndReschedule();
            },
          ),
          Divider(height: 1),

          if (_enabled) ...[
            // --- Godzina powiadomienia ---
            ListTile(
              leading: Icon(Icons.access_time),
              title: Text(AppLocalizations.of(context)!.notificationTime),
              trailing: Text(
                '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: _pickTime,
            ),
            Divider(height: 1),

            // --- Notatki ---
      //      _buildSectionHeader(AppLocalizations.of(context)!.nOtes),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.notifNotesDesc),
              value: _notesEnabled, // on/off
              onChanged: (v) {
                setState(() => _notesEnabled = v);
                _saveAndReschedule();
              },
            ),
            if (_notesEnabled)
              _buildDaysSelector(
                value: _notesAdvanceDays,
                maxDays: 30,
                onChanged: (v) {
                  setState(() => _notesAdvanceDays = v);
                  _saveAndReschedule();
                },
              ),
            SizedBox(height: 10),
            Divider(height: 1),

            // --- Przeglądy ---
         //   _buildSectionHeader(AppLocalizations.of(context)!.inspection),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.notifInspectionDesc),
              value: _inspectionEnabled,
              onChanged: (v) {
                setState(() => _inspectionEnabled = v);
                _saveAndReschedule();
              },
            ),
            if (_inspectionEnabled)
              _buildDaysSelector2(
                value: _inspectionDays,
                maxDays: 30,
                onChanged: (v) {
                  setState(() => _inspectionDays = v);
                  _saveAndReschedule();
                },
              ),
            SizedBox(height: 10),
            Divider(height: 1),

            // --- Dokarmianie ---
          //  _buildSectionHeader(AppLocalizations.of(context)!.feeding),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.notifFeedingDesc),
              value: _feedingEnabled,
              onChanged: (v) {
                setState(() => _feedingEnabled = v);
                _saveAndReschedule();
              },
            ),
            if (_feedingEnabled)
              _buildDaysSelector2(
                value: _feedingDays,
                maxDays: 30,
                onChanged: (v) {
                  setState(() => _feedingDays = v);
                  _saveAndReschedule();
                },
              ),
            SizedBox(height: 10),
            Divider(height: 1),

            // --- Leczenie ---
         //   _buildSectionHeader(AppLocalizations.of(context)!.treatment),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.notifTreatmentDesc),
              value: _treatmentEnabled,
              onChanged: (v) {
                setState(() => _treatmentEnabled = v);
                _saveAndReschedule();
              },
            ),
            if (_treatmentEnabled)
              _buildDaysSelector2(
                value: _treatmentDays,
                maxDays: 30,
                onChanged: (v) {
                  setState(() => _treatmentDays = v);
                  _saveAndReschedule();
                },
              ),
            SizedBox(height: 10),
            Divider(height: 1),

            // Przycisk: Pokaż zaplanowane powiadomienia
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                icon: Icon(Icons.list_alt, color: Colors.black87),
                label: Text(
                  AppLocalizations.of(context)!.pendingNotifications,
                  style: TextStyle(color: Colors.black87, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  side: BorderSide(color: Color.fromARGB(255, 162, 103, 0), width: 1),
                  minimumSize: Size(double.infinity, 44),
                ),
                onPressed: _showPendingNotifications,
              ),
            ),
            SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Future<void> _showPendingNotifications() async {
    var list = await NotificationHelper.getPendingNotificationsList();
    if (!mounted) return;

    final loc = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd.MM.yyyy  HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${loc.pendingNotifications} (${list.length})',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Divider(height: 1),
                    Expanded(
                      child: list.isEmpty
                          ? Center(
                              child: Text(
                                loc.noPendingNotifications,
                                style: TextStyle(color: Colors.grey[600], fontSize: 15),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: list.length,
                              separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16),
                              itemBuilder: (ctx, i) {
                                final item = list[i];
                                final date = item['date'] as DateTime;
                                final body = item['body'] as String;
                                final type = item['type'] as String;
                                final notifId = item['notifId'] as int;
                                final dbId = item['dbId'] as int?;

                                IconData icon;
                                switch (type) {
                                  case 'note':
                                    icon = Icons.note_alt_outlined;
                                    break;
                                  case 'inspection':
                                    icon = Icons.search;
                                    break;
                                  case 'feeding':
                                    icon = Icons.local_drink;
                                    break;
                                  case 'treatment':
                                    icon = Icons.medical_services_outlined;
                                    break;
                                  default:
                                    icon = Icons.notifications_outlined;
                                }

                                return ListTile(
                                  leading: Icon(icon, color: Color.fromARGB(255, 162, 103, 0)),
                                  title: Text(body, style: TextStyle(fontSize: 14)),
                                  subtitle: Text(
                                    dateFormat.format(date),
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.cancel_outlined, color: Colors.red[400], size: 22),
                                    tooltip: loc.cancelNotification,
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: ctx,
                                        builder: (dCtx) => AlertDialog(
                                          title: Text(loc.cancelNotification),
                                          content: Text(loc.cancelNotificationConfirm),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(dCtx).pop(false),
                                              child: Text(loc.cancel),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(dCtx).pop(true),
                                              child: Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm != true) return;

                                      // Anuluj w systemie
                                      await NotificationHelper.cancelNotification(notifId);

                                      // Jeśli indywidualne - usuń z bazy
                                      if (dbId != null) {
                                        await DBHelper.deletePowiadomienie(dbId);
                                      }

                                      // Usuń element z lokalnej listy
                                      setModalState(() {
                                        list.removeAt(i);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
