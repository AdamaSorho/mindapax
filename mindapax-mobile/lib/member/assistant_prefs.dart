import 'package:shared_preferences/shared_preferences.dart';

class AssistantPrefs {
  static const _kUseContext = 'assistant_use_context';
  static const _kIncludeProgress = 'assistant_include_progress';
  static const _kSuggestGoals = 'assistant_suggest_goals';

  static Future<bool> getUseContext() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kUseContext) ?? true;
  }

  static Future<void> setUseContext(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kUseContext, v);
  }

  static Future<bool> getIncludeProgress() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kIncludeProgress) ?? true;
  }

  static Future<void> setIncludeProgress(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kIncludeProgress, v);
  }

  static Future<bool> getSuggestGoals() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kSuggestGoals) ?? true;
  }

  static Future<void> setSuggestGoals(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSuggestGoals, v);
  }
}

