import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';

const _fcmNotificationChannelId = 'fcm_messages';
const _fcmNotificationChannelName = 'Pesan Firebase';
const _fcmNotificationChannelDescription =
    'Notifikasi pesan Firebase Cloud Messaging';

const _fcmNotificationChannel = AndroidNotificationChannel(
  _fcmNotificationChannelId,
  _fcmNotificationChannelName,
  description: _fcmNotificationChannelDescription,
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('FCM background message: ${message.messageId}');
  await FirebaseMessagingService.showNotificationInBackground(message);
}

class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<RemoteMessage> _receivedMessages =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<Object> _errors = StreamController<Object>.broadcast();
  final List<RemoteMessage> _recentMessages = [];
  bool _initialized = false;
  String? _initializationError;

  FirebaseMessaging get _client => FirebaseMessaging.instance;

  Stream<RemoteMessage> get receivedMessages => _receivedMessages.stream;

  Stream<Object> get errors => _errors.stream;

  List<RemoteMessage> get recentMessages => List.unmodifiable(_recentMessages);

  String? get initializationError => _initializationError;

  Future<void> initializeForegroundNotifications() async {
    if (_initialized) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await _localNotifications.initialize(
            const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            ),
          );
          await _createNotificationChannel(_localNotifications);
        } catch (error, stackTrace) {
          _initializationError = 'Gagal menyiapkan notifikasi Android: $error';
          debugPrint('$_initializationError\n$stackTrace');
          _errors.add(error);
        }
      }
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
          'FCM foreground message received: '
          'id=${message.messageId}, data=${message.data}',
        );
        _recordMessage(message);
        if (defaultTargetPlatform == TargetPlatform.android) {
          unawaited(_showNotification(message));
        }
      }, onError: _errors.add);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('FCM notification opened: ${message.messageId}');
        _recordMessage(message);
      }, onError: _errors.add);
      _initialized = true;
    } catch (error, stackTrace) {
      _initializationError = 'Gagal menyiapkan notifikasi: $error';
      debugPrint('$_initializationError\n$stackTrace');
      _errors.add(error);
    }
  }

  void recordOpenedMessage(RemoteMessage message) {
    _recordMessage(message);
  }

  void _recordMessage(RemoteMessage message) {
    _recentMessages.insert(0, message);
    if (_recentMessages.length > 50) {
      _recentMessages.removeLast();
    }
    _receivedMessages.add(message);
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'];
    final body =
        message.notification?.body ??
        message.data['body'] ??
        (message.data.isEmpty
            ? 'Pesan baru diterima.'
            : message.data.toString());

    try {
      await _localNotifications.show(
        (message.messageId?.hashCode ?? DateTime.now().microsecondsSinceEpoch) &
            0x7fffffff,
        title ?? 'Pesan Firebase',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _fcmNotificationChannelId,
            _fcmNotificationChannelName,
            channelDescription: _fcmNotificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.messageId,
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal menampilkan notifikasi FCM: $error\n$stackTrace');
      _errors.add(error);
    }
  }

  static Future<void> showNotificationInBackground(
    RemoteMessage message,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    debugPrint('FCM background message: ${message.messageId}');
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _createNotificationChannel(notifications);

    final title = message.notification?.title ?? message.data['title'];
    final body =
        message.notification?.body ??
        message.data['body'] ??
        (message.data.isEmpty
            ? 'Pesan baru diterima.'
            : message.data.toString());
    await notifications.show(
      (message.messageId?.hashCode ?? DateTime.now().microsecondsSinceEpoch) &
          0x7fffffff,
      title ?? 'Pesan Firebase',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _fcmNotificationChannelId,
          _fcmNotificationChannelName,
          channelDescription: _fcmNotificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.messageId,
    );
  }

  static Future<void> _createNotificationChannel(
    FlutterLocalNotificationsPlugin notifications,
  ) async {
    final androidNotifications = notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(
      _fcmNotificationChannel,
    );
  }

  Future<NotificationSettings> getNotificationSettings() {
    return _client.getNotificationSettings();
  }

  Future<NotificationSettings> requestPermission() {
    return _client.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<String> register() async {
    final registrationId = _client.onRegistered.first.timeout(
      const Duration(seconds: 30),
    );
    await _client.register();
    return registrationId;
  }

  Stream<String> get onRegistered => _client.onRegistered;

  Future<RemoteMessage?> getInitialMessage() {
    return _client.getInitialMessage();
  }
}
