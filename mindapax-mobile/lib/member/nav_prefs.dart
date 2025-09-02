import 'package:shared_preferences/shared_preferences.dart';

class NavPrefs {
  static const _kLastMemberRoute = 'last_member_route';
  static const String defaultRoute = '/member/dashboard';

  static Future<void> saveLastRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastMemberRoute, route);
  }

  static Future<String> getLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastMemberRoute) ?? defaultRoute;
  }
}

