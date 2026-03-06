import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/db_helper.dart';
import '../globals.dart' as globals;
import '../screens/infos_screen.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Globalny klucz navigatora - ustawiany z main.dart
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Klucze SharedPreferences
  static const String keyEnabled = 'notif_enabled';
  static const String keyHour = 'notif_hour';
  static const String keyMinute = 'notif_minute';
  static const String keyNotesEnabled = 'notif_notes_enabled';
  static const String keyNotesAdvanceDays = 'notif_notes_advance_days';
  static const String keyInspectionEnabled = 'notif_inspection_enabled';
  static const String keyInspectionDays = 'notif_inspection_days';
  static const String keyFeedingEnabled = 'notif_feeding_enabled';
  static const String keyFeedingDays = 'notif_feeding_days';
  static const String keyTreatmentEnabled = 'notif_treatment_enabled';
  static const String keyTreatmentDays = 'notif_treatment_days';
  static const String keyCancelledIds = 'notif_cancelled_ids';

  /// Obsługa kliknięcia w powiadomienie
  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    // payload format: "pasiekaNr|ulNr|kategoria"
    final parts = payload.split('|');
    if (parts.length < 3) return;

    final pasiekaNr = int.tryParse(parts[0]);
    final ulNr = int.tryParse(parts[1]);
    final kategoria = parts[2];

    if (pasiekaNr == null || ulNr == null) return;

    // Ustaw globalne zmienne
    globals.pasiekaID = pasiekaNr;
    globals.ulID = ulNr;
    globals.aktualnaKategoriaInfo = kategoria;

    // Nawiguj do ekranu info z przekazaniem numeru ula
    navigatorKey.currentState?.pushNamed(
      InfoScreen.routeName,
      arguments: ulNr,
    );
  }

  static Future<void> initialize() async {
    // Inicjalizacja stref czasowych
    tzdata.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback - użyj UTC jeśli nie da się pobrać strefy
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Konfiguracja Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Konfiguracja iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permission na Androidzie 13+
    _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Anuluje wszystkie i planuje od nowa
  static Future<void> scheduleAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(keyEnabled) ?? true;

    // Czyść stare/nieaktywne powiadomienia z bazy
    await DBHelper.cleanupPowiadomienia();

    // Czyść listę ręcznie anulowanych (bo planujemy wszystko od nowa)
    await prefs.remove(keyCancelledIds);

    await _plugin.cancelAll();

    if (!enabled) return;

    // Planuj 4 typy powiadomień
    if (prefs.getBool(keyNotesEnabled) ?? true) {
      await _scheduleNoteReminders(prefs);
    }
    if (prefs.getBool(keyInspectionEnabled) ?? false) {
      await _scheduleInfoReminders(prefs, 'inspection');
    }
    if (prefs.getBool(keyFeedingEnabled) ?? false) {
      await _scheduleInfoReminders(prefs, 'feeding');
    }
    if (prefs.getBool(keyTreatmentEnabled) ?? false) {
      await _scheduleInfoReminders(prefs, 'treatment');
    }

    // Planuj indywidualne powiadomienia z tabeli powiadomienia
    await _scheduleIndividualReminders();
  }

  /// Planuje przypomnienia z notatek
  static Future<void> _scheduleNoteReminders(SharedPreferences prefs) async {
    final hour = prefs.getInt(keyHour) ?? 8;
    final minute = prefs.getInt(keyMinute) ?? 0;
    final advanceDays = prefs.getInt(keyNotesAdvanceDays) ?? 0;

    final notes = await DBHelper.getActiveNotesWithTaskDate();

    for (final note in notes) {
      final noteId = note['id'] as int;
      final title = note['tytul'] as String? ?? '';
      final dateStr = note['pole1'] as String? ?? '';

      if (dateStr.isEmpty) continue;

      try {
        final taskDate = DateTime.parse(dateStr);
        final notifDate = taskDate.subtract(Duration(days: advanceDays));

        final scheduledDate = tz.TZDateTime(
          tz.local,
          notifDate.year,
          notifDate.month,
          notifDate.day,
          hour,
          minute,
        );

        // Planuj tylko jeśli data jest w przyszłości
        if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
          await _scheduleNotification(
            id: 100000 + noteId,
            title: 'Hey Maya',
            body: title,
            scheduledDate: scheduledDate,
          );
        }
      } catch (_) {
        // Pomiń notatki z nieprawidłową datą
      }
    }
  }

  /// Planuje przypomnienia o przeglądach/dokarmianiu/leczeniu
  static Future<void> _scheduleInfoReminders(
      SharedPreferences prefs, String kategoria) async {
    final hour = prefs.getInt(keyHour) ?? 8;
    final minute = prefs.getInt(keyMinute) ?? 0;

    int days;
    int idBase;
    String bodyPrefix;
    switch (kategoria) {
      case 'inspection':
        days = prefs.getInt(keyInspectionDays) ?? 7;
        idBase = 200000;
        bodyPrefix = _getCategoryPrefix('inspection');
        break;
      case 'feeding':
        days = prefs.getInt(keyFeedingDays) ?? 7;
        idBase = 300000;
        bodyPrefix = _getCategoryPrefix('feeding');
        break;
      case 'treatment':
        days = prefs.getInt(keyTreatmentDays) ?? 5;
        idBase = 400000;
        bodyPrefix = _getCategoryPrefix('treatment');
        break;
      default:
        return;
    }

    final infos = await DBHelper.getLatestInfoPerHive(kategoria);

    for (final info in infos) {
      final pasiekaNr = info['pasiekaNr'] as int;
      final ulNr = info['ulNr'] as int;
      final lastDateStr = info['lastDate'] as String? ?? '';

      if (lastDateStr.isEmpty) continue;

      try {
        final lastDate = DateTime.parse(lastDateStr);
        final nextDate = lastDate.add(Duration(days: days));

        final scheduledDate = tz.TZDateTime(
          tz.local,
          nextDate.year,
          nextDate.month,
          nextDate.day,
          hour,
          minute,
        );

        if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
          final notifId = idBase + (pasiekaNr * 1000 + ulNr);

          await _scheduleNotification(
            id: notifId,
            title: 'Hey Maya',
            body: '$bodyPrefix $pasiekaNr / $ulNr',
            scheduledDate: scheduledDate,
            payload: '$pasiekaNr|$ulNr|$kategoria',
          );
        }
      } catch (_) {
        // Pomiń wpisy z nieprawidłową datą
      }
    }
  }

  /// Planuje pojedyncze powiadomienie
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'hi_bees_reminders',
      'Reminders',
      channelDescription: 'Hey Maya notification reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: payload,
    );
  }

  /// Planuje indywidualne powiadomienia z tabeli powiadomienia
  static Future<void> _scheduleIndividualReminders() async {
    final powiadomienia = await DBHelper.getActivePowiadomienia();

    for (final p in powiadomienia) {
      final id = p['id'] as int;
      final pasiekaNr = p['pasiekaNr'] as int;
      final ulNr = p['ulNr'] as int;
      final kategoria = p['kategoria'] as String? ?? '';
      final parametr = p['parametr'] as String? ?? '';
      final godzina = p['godzina'] as int? ?? 8;
      final minuta = p['minuta'] as int? ?? 0;
      final dataNotifStr = p['dataNotif'] as String? ?? '';

      if (dataNotifStr.isEmpty) continue;

      try {
        final notifDate = DateTime.parse(dataNotifStr);
        final scheduledDate = tz.TZDateTime(
          tz.local,
          notifDate.year,
          notifDate.month,
          notifDate.day,
          godzina,
          minuta,
        );

        if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
          final bodyPrefix = _getCategoryPrefix(kategoria);
          await _scheduleNotification(
            id: 500000 + id,
            title: 'Hey Maya',
            body: '$bodyPrefix $pasiekaNr / $ulNr $parametr',
            scheduledDate: scheduledDate,
            payload: '$pasiekaNr|$ulNr|$kategoria',
          );
        }
      } catch (_) {
        // Pomiń wpisy z nieprawidłową datą
      }
    }
  }

  /// Zwraca prefix powiadomienia dla danej kategorii
  static String _getCategoryPrefix(String kategoria) {
    final lang = globals.jezyk.substring(0, 2); // pl, en, de, fr, es, pt, it
    const map = {
      'inspection': {'pl': '🔍 przegląd', 'en': '🔍 inspection', 'de': '🔍 Durchsicht', 'fr': '🔍 inspection', 'es': '🔍 inspección', 'pt': '🔍 inspeção', 'it': '🔍 ispezione'},
      'feeding':    {'pl': '🍶 dokarmianie', 'en': '🍶 feeding', 'de': '🍶 Fütterung', 'fr': '🍶 nourrissement', 'es': '🍶 alimentación', 'pt': '🍶 alimentação', 'it': '🍶 nutrizione'},
      'treatment':  {'pl': '💉 leczenie', 'en': '💉 treatment', 'de': '💉 Behandlung', 'fr': '💉 traitement', 'es': '💉 tratamiento', 'pt': '💉 tratamento', 'it': '💉 trattamento'},
    };
    return map[kategoria]?[lang] ?? map[kategoria]?['en'] ?? '';
  }

  /// Planuje pojedyncze indywidualne powiadomienie (wywoływane po zapisie info)
  static Future<void> scheduleIndividualNotification({
    required int id,
    required int pasiekaNr,
    required int ulNr,
    required String kategoria,
    required String parametr,
    required int godzina,
    required int minuta,
    required String dataNotif,
  }) async {
    try {
      final notifDate = DateTime.parse(dataNotif);
      final scheduledDate = tz.TZDateTime(
        tz.local,
        notifDate.year,
        notifDate.month,
        notifDate.day,
        godzina,
        minuta,
      );

      if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
        final bodyPrefix = _getCategoryPrefix(kategoria);
        await _scheduleNotification(
          id: 500000 + id,
          title: 'Hey Maya',
          body: '$bodyPrefix $pasiekaNr / $ulNr $parametr',
          scheduledDate: scheduledDate,
          payload: '$pasiekaNr|$ulNr|$kategoria',
        );
      }
    } catch (_) {
      // Pomiń błędy
    }
  }

  /// Planuje powiadomienie z podanym tytułem, treścią i datą (publiczne API)
  static Future<void> scheduleSimpleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );

    if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      await _scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
      );
    }
  }

  /// Anuluje pojedyncze powiadomienie po ID (bez zapamiętywania w cancelled)
  static Future<void> cancelNotificationById(int notifId) async {
    await _plugin.cancel(notifId);
  }

  /// Anuluje wszystkie powiadomienia
  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// Anuluje pojedyncze powiadomienie po ID systemowym
  /// i zapamiętuje je jako anulowane, żeby nie pojawiło się ponownie na liście
  static Future<void> cancelNotification(int notifId) async {
    await _plugin.cancel(notifId);
    final prefs = await SharedPreferences.getInstance();
    final cancelled = prefs.getStringList(keyCancelledIds) ?? [];
    cancelled.add(notifId.toString());
    await prefs.setStringList(keyCancelledIds, cancelled);
  }

  /// Zwraca listę oczekujących powiadomień z datami obliczonymi z bazy danych.
  /// Każdy element: {'date': DateTime, 'body': String, 'type': String, 'notifId': int, 'dbId': int?}
  static Future<List<Map<String, dynamic>>> getPendingNotificationsList() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(keyEnabled) ?? true;
    final list = <Map<String, dynamic>>[];

    if (!enabled) return list;

    final hour = prefs.getInt(keyHour) ?? 8;
    final minute = prefs.getInt(keyMinute) ?? 0;
    final now = DateTime.now();
    final cancelledIds = (prefs.getStringList(keyCancelledIds) ?? []).toSet();

    // 1. Notatki
    if (prefs.getBool(keyNotesEnabled) ?? true) {
      final advanceDays = prefs.getInt(keyNotesAdvanceDays) ?? 0;
      final notes = await DBHelper.getActiveNotesWithTaskDate();
      for (final note in notes) {
        final noteId = note['id'] as int;
        final title = note['tytul'] as String? ?? '';
        final dateStr = note['pole1'] as String? ?? '';
        if (dateStr.isEmpty) continue;
        try {
          final taskDate = DateTime.parse(dateStr);
          final notifDate = taskDate.subtract(Duration(days: advanceDays));
          final scheduled = DateTime(notifDate.year, notifDate.month, notifDate.day, hour, minute);
          if (scheduled.isAfter(now)) {
            list.add({'date': scheduled, 'body': title, 'type': 'note', 'notifId': 100000 + noteId});
          }
        } catch (_) {}
      }
    }

    // 2. Przeglądy, dokarmianie, leczenie
    for (final kategoria in ['inspection', 'feeding', 'treatment']) {
      bool catEnabled;
      int days;
      int idBase;
      switch (kategoria) {
        case 'inspection':
          catEnabled = prefs.getBool(keyInspectionEnabled) ?? false;
          days = prefs.getInt(keyInspectionDays) ?? 7;
          idBase = 200000;
          break;
        case 'feeding':
          catEnabled = prefs.getBool(keyFeedingEnabled) ?? false;
          days = prefs.getInt(keyFeedingDays) ?? 7;
          idBase = 300000;
          break;
        case 'treatment':
          catEnabled = prefs.getBool(keyTreatmentEnabled) ?? false;
          days = prefs.getInt(keyTreatmentDays) ?? 5;
          idBase = 400000;
          break;
        default:
          catEnabled = false;
          days = 7;
          idBase = 0;
      }
      if (!catEnabled) continue;

      final bodyPrefix = _getCategoryPrefix(kategoria);
      final infos = await DBHelper.getLatestInfoPerHive(kategoria);
      for (final info in infos) {
        final pasiekaNr = info['pasiekaNr'] as int;
        final ulNr = info['ulNr'] as int;
        final lastDateStr = info['lastDate'] as String? ?? '';
        if (lastDateStr.isEmpty) continue;
        try {
          final lastDate = DateTime.parse(lastDateStr);
          final nextDate = lastDate.add(Duration(days: days));
          final scheduled = DateTime(nextDate.year, nextDate.month, nextDate.day, hour, minute);
          if (scheduled.isAfter(now)) {
            final notifId = idBase + (pasiekaNr * 1000 + ulNr);
            list.add({'date': scheduled, 'body': '$bodyPrefix $pasiekaNr / $ulNr', 'type': kategoria, 'notifId': notifId});
          }
        } catch (_) {}
      }
    }

    // 3. Indywidualne powiadomienia z tabeli powiadomienia
    final powiadomienia = await DBHelper.getActivePowiadomienia();
    for (final p in powiadomienia) {
      final id = p['id'] as int;
      final pasiekaNr = p['pasiekaNr'] as int;
      final ulNr = p['ulNr'] as int;
      final kategoria = p['kategoria'] as String? ?? '';
      final parametr = p['parametr'] as String? ?? '';
      final godzina = p['godzina'] as int? ?? 8;
      final minuta = p['minuta'] as int? ?? 0;
      final dataNotifStr = p['dataNotif'] as String? ?? '';
      if (dataNotifStr.isEmpty) continue;
      try {
        final notifDate = DateTime.parse(dataNotifStr);
        final scheduled = DateTime(notifDate.year, notifDate.month, notifDate.day, godzina, minuta);
        if (scheduled.isAfter(now)) {
          final bodyPrefix = _getCategoryPrefix(kategoria);
          list.add({'date': scheduled, 'body': '$bodyPrefix $pasiekaNr / $ulNr $parametr', 'type': 'individual', 'notifId': 500000 + id, 'dbId': id});
        }
      } catch (_) {}
    }

    // Usuń ręcznie anulowane powiadomienia
    list.removeWhere((item) => cancelledIds.contains((item['notifId'] as int).toString()));

    // Sortuj po dacie
    list.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return list;
  }
}
