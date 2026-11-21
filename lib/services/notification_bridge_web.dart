import 'dart:js_interop';

@JS('Notification.permission')
external JSString? get _permission;

@JS('Notification.requestPermission')
external JSPromise<JSString> _requestPermission();

@JS('Notification')
extension type _WebNotification._(JSObject _) implements JSObject {
  external factory _WebNotification(String title, [_NotificationOptions? options]);
}

@JS()
@anonymous
extension type _NotificationOptions._(JSObject _) implements JSObject {
  external factory _NotificationOptions({
    String? body,
    String? icon,
    String? badge,
  });
}

Future<bool> requestPlatformNotificationPermission() async {
  try {
    final current = _permission?.toDart;
    if (current == 'granted') return true;
    if (current == 'denied') return false;
    final result = (await _requestPermission().toDart).toDart;
    return result == 'granted';
  } catch (_) {
    return false;
  }
}

Future<void> showPlatformNotification({
  required String title,
  required String body,
}) async {
  try {
    final current = _permission?.toDart;
    if (current != 'granted') {
      final granted = await requestPlatformNotificationPermission();
      if (!granted) return;
    }
    _WebNotification(
      title,
      _NotificationOptions(
        body: body,
        icon: 'favicon.png',
        badge: 'favicon.png',
      ),
    );
  } catch (_) {
    // Si el navegador bloquea la notificación nativa, el banner in-app igual se muestra.
  }
}
