// Simple environment configuration for API base URL.
// Override at build time with: --dart-define=API_URL=https://api.example.com/api/v1
import 'package:flutter/foundation.dart';

const bool _isReleaseMode = kReleaseMode;

const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: _isReleaseMode
      ? 'http://vps-a6468c72.vps.ovh.net:8080/api/v1'
      : 'http://localhost:8080/api/v1',
);

// Base URL of the web app hosting the Zoom Web SDK route.
// Override with: --dart-define=WEB_APP_URL=https://app.example.com
const String webAppBaseUrl = String.fromEnvironment(
  'WEB_APP_URL',
  defaultValue: _isReleaseMode
      ? 'http://mindapax.com.s3-website-us-east-1.amazonaws.com'
      : 'http://localhost:4200',
);
