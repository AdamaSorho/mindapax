Mindapax Mobile

Run
- flutter run
- Optional: pass API base URL with --dart-define=API_URL=https://api.example.com/api/v1
- Optional: pass web app URL with --dart-define=WEB_APP_URL=https://app.example.com

Sessions & Zoom Join
- The Sessions screen fetches upcoming and past sessions from /sessions/by-user.
- Joining a VIDEO session can use two methods (select in Settings):
  - Zoom app (default): launches the native Zoom client via deep link.
  - In-app (WebView): opens WebView to WEB_APP_URL/member/zoom-call with signature params; a Preflight Check verifies camera/mic via getUserMedia before opening the meeting.
- Backend must expose POST /sessions/{id}/join-video that returns: { apiKey, meetingNumber, signature, password }.

iOS Notes
- To allow opening the Zoom app, add LSApplicationQueriesSchemes in ios/Runner/Info.plist:
  <key>LSApplicationQueriesSchemes</key>
  <array>
    <string>zoomus</string>
  </array>
 - Also ensure NSCameraUsageDescription and NSMicrophoneUsageDescription are present (already added).

Dependencies
- url_launcher is used to open the Zoom app or browser.
- webview_flutter is used for in-app Zoom via the Web SDK.
- permission_handler requests camera/microphone permissions at runtime.

Android Notes
- Manifest requests INTERNET, CAMERA, and RECORD_AUDIO (already added).
- On Android 12+, users may need to grant mic/camera at runtime; the app prompts before joining.
