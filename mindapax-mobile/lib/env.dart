// Simple environment configuration for API base URL.
// Override at build time with: --dart-define=API_URL=https://api.example.com/api/v1
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8080/api/v1',
);

