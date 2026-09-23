import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows local (on-device) notifications, e.g. when it becomes the
/// player's turn in a friend match.
///
/// This is intentionally *not* a push-notification (FCM) integration:
/// delivering a notification while the app process isn't running would
/// require a server-side trigger (a Cloud Function watching Firestore)
/// plus FCM/APNs project configuration, which needs to be set up and
/// confirmed in the Firebase console by the project owner. What's
/// implemented here covers the case where the app is open (foreground or
/// backgrounded but still running) and a Firestore listener observes the
/// match turning to the player's turn.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> showYourTurnNotification({required String matchId}) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'multiplayer_turn_channel',
      '対戦相手の手番通知',
      channelDescription: 'フレンド対戦であなたの番になったときの通知',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      matchId.hashCode,
      'あなたの番です',
      'フレンド対戦で相手が指しました。盤面を確認しましょう。',
      details,
      payload: matchId,
    );
  }
}
