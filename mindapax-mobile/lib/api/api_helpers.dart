import 'dart:io' show Platform;

String normalizeBaseUrl(String value) {
  final cleaned = value.replaceAll(RegExp(r'/+$'), '');
  try {
    final uri = Uri.parse(cleaned);
    if (uri.host == 'localhost' && Platform.isAndroid) {
      return cleaned.replaceFirst('localhost', '10.0.2.2');
    }
    return cleaned;
  } catch (_) {
    return cleaned;
  }
}
