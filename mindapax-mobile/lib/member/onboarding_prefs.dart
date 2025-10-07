import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPrefs {
  static const _kCompleted = 'onboarding_completed_v1';

  static Future<bool> isCompleted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kCompleted) ?? false;
  }

  static Future<void> setCompleted(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kCompleted, v);
  }
}

