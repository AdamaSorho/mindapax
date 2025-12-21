class NavPrefs {
  static const String defaultRoute = '/member/dashboard';

  static Future<void> saveLastRoute(String route) async {}

  static Future<String> getLastRoute() async {
    return defaultRoute;
  }
}
