import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local game reminders and social notifications.
class GameNotificationService {
  GameNotificationService._();

  static final GameNotificationService instance = GameNotificationService._();
  static const _middayId = 4012;
  static const _eveningId = 4019;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;

    if (await _requestNotificationPermission()) {
      await _scheduleDailyInvites();
    }
  }

  Future<bool> _requestNotificationPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidPermission = await android?.requestNotificationsPermission();
    if (androidPermission == false) return false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosPermission = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return iosPermission != false;
  }

  Future<void> notifyFriendRequest(String username) => _notifyNow(
    id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
    title: 'Yeni arkadaşlık isteği',
    body: '$username seninle arkadaş olmak istiyor.',
  );

  Future<void> notifyGameInvite(String roomName, String inviter) => _notifyNow(
    id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
    title: 'Oyun daveti',
    body: '$inviter seni “$roomName” odasına çağırıyor.',
  );

  Future<void> _notifyNow({required int id, required String title, required String body}) async {
    await initialize();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('social_game_events', 'Oyun ve arkadaş bildirimleri',
          channelDescription: 'Oyun davetleri ve arkadaşlık istekleri',
          importance: Importance.high, priority: Priority.high, playSound: true),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _scheduleDailyInvites() async {
    await _scheduleInvite(
      id: _middayId,
      hour: 12,
      minute: 30,
      title: 'Alevler seni bekliyor! 🔥',
      body: 'Kısa bir mola ver, arenaya dön ve yeni bir maç başlat.',
    );
    await _scheduleInvite(
      id: _eveningId,
      hour: 19,
      minute: 30,
      title: 'Akşam maçı zamanı! 🚒',
      body: 'Ekibini topla, arenada yerini al. Bir maç daha oynayalım!',
    );
  }

  Future<void> _scheduleInvite({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var nextTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!nextTime.isAfter(now)) {
      nextTime = nextTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: nextTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_game_invites',
          'Günlük oyun davetleri',
          channelDescription: 'Oyuna dönmen için günlük hatırlatmalar',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
