import 'package:shared_preferences/shared_preferences.dart';

class IntroPrefs {
  static const _kIntroSeen = 'intro_slides_seen';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIntroSeen) ?? false;
  }

  static Future<void> setCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIntroSeen, value);
  }

  static Future<void> reset() => setCompleted(false);
}
