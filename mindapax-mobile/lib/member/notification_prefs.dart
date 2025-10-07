import 'package:shared_preferences/shared_preferences.dart';

class NotificationPrefs {
  static const _kPushEnabled = 'notif_push_enabled';
  static const _kGoalReminders = 'notif_goal_reminders';
  static const _kSessionReminders = 'notif_session_reminders';
  static const _kMessageAlerts = 'notif_message_alerts';
  static const _kQuietEnabled = 'notif_quiet_enabled';
  static const _kQuietStart = 'notif_quiet_start'; // HH:MM (24h)
  static const _kQuietEnd = 'notif_quiet_end'; // HH:MM (24h)

  static Future<bool> getPushEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kPushEnabled) ?? true;
  }

  static Future<void> setPushEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPushEnabled, v);
  }

  static Future<bool> getGoalReminders() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kGoalReminders) ?? true;
  }

  static Future<void> setGoalReminders(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kGoalReminders, v);
  }

  static Future<bool> getSessionReminders() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kSessionReminders) ?? true;
  }

  static Future<void> setSessionReminders(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSessionReminders, v);
  }

  static Future<bool> getMessageAlerts() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kMessageAlerts) ?? true;
  }

  static Future<void> setMessageAlerts(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMessageAlerts, v);
  }

  static Future<bool> getQuietEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kQuietEnabled) ?? false;
  }

  static Future<void> setQuietEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kQuietEnabled, v);
  }

  static Future<String> getQuietStart() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kQuietStart) ?? '22:00';
  }

  static Future<void> setQuietStart(String hhmm) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kQuietStart, hhmm);
  }

  static Future<String> getQuietEnd() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kQuietEnd) ?? '07:00';
  }

  static Future<void> setQuietEnd(String hhmm) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kQuietEnd, hhmm);
  }
}

