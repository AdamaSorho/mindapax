import 'package:flutter/foundation.dart';

class RoleOverride {
  static List<String>? _roles;

  static List<String>? get roles => _roles;

  static void setRoles(List<String>? roles) {
    if (!kDebugMode) return; // Only effective in debug mode
    _roles = roles;
  }

  static bool get isActive => _roles != null && _roles!.isNotEmpty;
}

