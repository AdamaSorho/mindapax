import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../env.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class ZoomWebViewPage extends StatefulWidget {
  final String meetingNumber;
  final String signature;
  final String? password;
  final String userName;
  final String? userEmail;
  final String? sdkKey;

  const ZoomWebViewPage({
    super.key,
    required this.meetingNumber,
    required this.signature,
    required this.userName,
    this.password,
    this.userEmail,
    this.sdkKey,
  });

  @override
  State<ZoomWebViewPage> createState() => _ZoomWebViewPageState();
}

class _ZoomWebViewPageState extends State<ZoomWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  late final Uri _meetingUri;
  bool _preflightDone = false;
  bool _joining = false;
  late final String _preflightBaseUrl;

  @override
  void initState() {
    super.initState();
    final normalized = _normalizeBaseUrl(webAppBaseUrl);
    final base = _ensureHttpsIfNotLocal(normalized);
    _preflightBaseUrl = base.startsWith('http') ? base : 'https://mindapax.com';
    final params = {
      if (widget.sdkKey != null && widget.sdkKey!.isNotEmpty)
        'sdkKey': widget.sdkKey!,
      'meetingNumber': widget.meetingNumber,
      'signature': widget.signature,
      if (widget.password != null && widget.password!.isNotEmpty)
        'passWord': widget.password!,
      'userName': widget.userName,
      if (widget.userEmail != null && widget.userEmail!.isNotEmpty)
        'userEmail': widget.userEmail!,
    };
    _meetingUri = Uri.parse(base).replace(
      path: '/member/zoom-call',
      queryParameters: params,
    );

    late final WebViewController controller;
    if (Platform.isAndroid) {
      final creationParams = AndroidWebViewControllerCreationParams();
      controller = WebViewController.fromPlatformCreationParams(creationParams)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (url) {
            if (kDebugMode) debugPrint('[WebView] onPageFinished: ${(url)}');
            setState(() {
              _loading = false;
              if (_preflightDone) _joining = false;
            });
          },
        ))
        ..addJavaScriptChannel('MPX', onMessageReceived: (message) async {
          if (kDebugMode) {
            debugPrint('[WebView] JS channel message: ${message.message}');
          }
          if (message.message == 'continue') {
            setState(() {
              _loading = true;
              _preflightDone = true;
              _joining = true;
            });
            _controller.loadRequest(_meetingUri);
          } else if (message.message == 'requestPermissions') {
            final ok = await _requestNativePermissions();
            if (ok && mounted) {
              // Reload preflight; it will auto-continue if OK
              await _loadPreflight();
            }
          }
        })
        ..loadHtmlString(_preflightHtml(), baseUrl: _preflightBaseUrl);
      final androidCtrl = controller.platform as AndroidWebViewController;
      AndroidWebViewController.enableDebugging(true);
      androidCtrl.setMediaPlaybackRequiresUserGesture(false);
      // Grant camera/mic permission requests from WebView (getUserMedia)
      androidCtrl.setOnPlatformPermissionRequest((request) {
        try {
          if (kDebugMode) {
            debugPrint(
                '[WebView][Android] Permission request received, granting.');
          }
          // Prefer granting requested resources when API provides them
          // ignore: invalid_use_of_visible_for_testing_member
          // ignore: invalid_use_of_protected_member
          // Some versions expose `resources`; if unavailable, fall back to plain grant.
          // @ts-ignore (Dart) - handled by try/catch
          // request.grant(request.resources);
          // Safer generic grant:
          request.grant();
        } catch (_) {
          try {
            if (kDebugMode) {
              debugPrint('[WebView][Android] Fallback grant with resources.');
            }
            // Attempt grant with resources if available
            // dynamic call to avoid type errors across versions
            // ignore: avoid_dynamic_calls
            // ignore: unnecessary_cast
            // ignore: invalid_use_of_visible_for_testing_member
            (request as dynamic).grant((request as dynamic).resources);
          } catch (_) {}
        }
      });
    } else if (Platform.isIOS) {
      final creationParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
      controller = WebViewController.fromPlatformCreationParams(creationParams)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (url) {
            if (kDebugMode) debugPrint('[WebView] onPageFinished: ${(url)}');
            setState(() {
              _loading = false;
              if (_preflightDone) _joining = false;
            });
          },
        ))
        ..addJavaScriptChannel('MPX', onMessageReceived: (message) async {
          if (kDebugMode) {
            debugPrint('[WebView] JS channel message: ${message.message}');
          }
          if (message.message == 'continue') {
            setState(() {
              _loading = true;
              _preflightDone = true;
              _joining = true;
            });
            _controller.loadRequest(_meetingUri);
          } else if (message.message == 'requestPermissions') {
            final ok = await _requestNativePermissions();
            if (ok && mounted) {
              await _loadPreflight();
            }
          }
        })
        ..loadHtmlString(_preflightHtml(), baseUrl: _preflightBaseUrl);
    } else {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (url) {
            if (kDebugMode) debugPrint('[WebView] onPageFinished: ${(url)}');
            setState(() {
              _loading = false;
              if (_preflightDone) _joining = false;
            });
          },
        ))
        ..addJavaScriptChannel('MPX', onMessageReceived: (message) async {
          if (kDebugMode) {
            debugPrint('[WebView] JS channel message: ${message.message}');
          }
          if (message.message == 'continue') {
            setState(() {
              _loading = true;
              _preflightDone = true;
              _joining = true;
            });
            _controller.loadRequest(_meetingUri);
          } else if (message.message == 'requestPermissions') {
            final ok = await _requestNativePermissions();
            if (ok && mounted) {
              await _loadPreflight();
            }
          }
        })
        ..loadHtmlString(_preflightHtml(), baseUrl: _preflightBaseUrl);
    }

    _controller = controller;
  }

  Future<bool> _requestNativePermissions() async {
    try {
      final statuses =
          await [Permission.camera, Permission.microphone].request();
      final cam = statuses[Permission.camera];
      final mic = statuses[Permission.microphone];
      final granted = (cam?.isGranted ?? false) && (mic?.isGranted ?? false);
      if (!granted &&
          ((cam?.isPermanentlyDenied ?? false) ||
              (mic?.isPermanentlyDenied ?? false))) {
        if (!mounted) return false;
        final open = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions needed'),
            content: const Text(
                'Please enable Camera and Microphone permissions in Settings to join video sessions.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Open Settings')),
            ],
          ),
        );
        if (open == true) {
          await openAppSettings();
        }
      }
      return granted;
    } catch (_) {
      return false;
    }
  }

  String _normalizeBaseUrl(String value) {
    final cleaned = value.replaceAll(RegExp(r'/+$'), '');
    try {
      final u = Uri.parse(cleaned);
      if (u.host == 'localhost' && Platform.isAndroid) {
        return cleaned.replaceFirst('localhost', '10.0.2.2');
      }
      return cleaned;
    } catch (_) {
      return cleaned;
    }
  }

  String _ensureHttpsIfNotLocal(String value) {
    try {
      final u = Uri.parse(value);
      final isLocal = u.host == 'localhost' ||
          u.host == '10.0.2.2' ||
          u.host == '127.0.0.1';
      if (!isLocal && u.scheme == 'http') {
        return value.replaceFirst('http://', 'https://');
      }
      return value;
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_preflightDone ? 'Zoom Session' : 'Preflight Check'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _loading = true);
              await _controller.reload();
            },
          )
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          // Animated joining overlay
          IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              opacity: _joining ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Joining…',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPreflight() async {
    await _controller.loadHtmlString(_preflightHtml(),
        baseUrl: _preflightBaseUrl);
  }

  String _preflightHtml() {
    const html = r'''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Preflight</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; padding: 16px; }
    .ok { color: #16a34a; }
    .err { color: #dc2626; }
    .card { border: 1px solid #e5e7eb; border-radius: 8px; padding: 12px; }
    .row { margin: 8px 0; }
    button { background: #2563eb; color: white; border: none; border-radius: 6px; padding: 10px 14px; font-size: 16px; }
    button:disabled { background: #9ca3af; }
  </style>
  <script>
    let camOk = false;
    let micOk = false;
    async function test() {
      const camEl = document.getElementById('cam');
      const micEl = document.getElementById('mic');
      const btn = document.getElementById('go');
      const perm = document.getElementById('perm');
      try {
        const s = await navigator.mediaDevices.getUserMedia({video:true,audio:true});
        camOk = true; micOk = true;
        s.getTracks().forEach(t => t.stop());
      } catch(e) {
        try {
          const v = await navigator.mediaDevices.getUserMedia({video:true});
          camOk = true; v.getTracks().forEach(t => t.stop());
        } catch(_){}
        try {
          const a = await navigator.mediaDevices.getUserMedia({audio:true});
          micOk = true; a.getTracks().forEach(t => t.stop());
        } catch(_){}
      }
      camEl.textContent = camOk ? 'Camera access OK' : 'Camera access failed';
      camEl.className = camOk ? 'ok' : 'err';
      micEl.textContent = micOk ? 'Microphone access OK' : 'Microphone access failed';
      micEl.className = micOk ? 'ok' : 'err';
      btn.disabled = !(camOk && micOk);
      perm.style.display = (camOk && micOk) ? 'none' : 'inline-block';
      if (camOk && micOk) {
        // Auto-continue shortly after successful preflight
        setTimeout(go, 300);
      }
    }
    function go() {
      if (window.MPX && MPX.postMessage) {
        MPX.postMessage('continue');
      }
    }
    function requestPermissions() {
      if (window.MPX && MPX.postMessage) {
        MPX.postMessage('requestPermissions');
      }
    }
    window.addEventListener('load', test);
  </script>
</head>
<body>
  <h2>Preflight Check</h2>
  <div class="card">
    <div id="cam" class="row">Checking camera...</div>
    <div id="mic" class="row">Checking microphone...</div>
  </div>
  <p style="margin-top:12px;color:#6b7280">Grant camera and microphone if prompted.</p>
  <div style="display:flex; gap:8px; margin-top:8px; align-items:center;">
    <button id="go" onclick="go()" disabled>Continue to Meeting</button>
    <button id="perm" onclick="requestPermissions()" style="display:none;background:#374151;">Grant Permissions in App</button>
  </div>
</body>
</html>
''';
    return html;
  }
}
