import 'package:shared_preferences/shared_preferences.dart';

enum SessionJoinMethod { zoomApp, webView }

class SettingsPrefs {
  static const _kJoinMethod = 'session_join_method';

  static Future<SessionJoinMethod> getJoinMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kJoinMethod);
    switch (value) {
      case 'webView':
        return SessionJoinMethod.webView;
      case 'zoomApp':
      default:
        return SessionJoinMethod.zoomApp; // default to Zoom app
    }
  }

  static Future<void> setJoinMethod(SessionJoinMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    final value = method == SessionJoinMethod.webView ? 'webView' : 'zoomApp';
    await prefs.setString(_kJoinMethod, value);
  }
}

