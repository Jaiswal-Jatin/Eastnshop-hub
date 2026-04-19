import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../Utils/ApiService.dart';
import '../Utils/LogUtils.dart';
import '../Utils/SharedPrefUtils.dart';
import '../Utils/TokenManager.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  LogUtils.info('Background FCM message: ${message.messageId}', tag: 'FCM');
}

class FcmService {
  static const String _fcmTokenKey = 'fcm_token';
  static const String _lastSyncedFcmTokenKey = 'fcm_token_last_synced';
  static const String _defaultChannelId = 'eastnshop_hub_general';
  static const String _defaultChannelName = 'General Notifications';
  static const String _defaultChannelDescription =
      'General app notifications from Eastnshop Hub';

  static bool _isInitialized = false;
  static bool _isLocalNotificationsInitialized = false;
  static bool _areMessageListenersAttached = false;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initializes Firebase + FCM flow once when app starts.
  ///
  /// Steps:
  /// 1) Initialize Firebase safely
  /// 2) Ask notification permission from user
  /// 3) Read and persist device FCM token
  /// 4) Register token to backend endpoint
  /// 5) Keep backend in sync when token refreshes
  static Future<void> initializeOnAppOpen() async {
    if (_isInitialized) return;

    try {
      print('[FCM_CHECK] initializeOnAppOpen() started');
      await SharedPrefUtils.init();
      await Firebase.initializeApp();

      final messaging = FirebaseMessaging.instance;

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _initializeLocalNotifications();

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print(
        '[FCM_CHECK] permission status: ${settings.authorizationStatus.name}',
      );

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final isAllowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!isAllowed) {
        LogUtils.warning('Notification permission denied by user', tag: 'FCM');
        print('[FCM_CHECK] permission denied, skipping token registration');
        _isInitialized = true;
        return;
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        final preview = token.length > 16
            ? '${token.substring(0, 16)}...'
            : token;
        print('[FCM_CHECK] token fetched: $preview');
        print('[FCM_CHECK] token generated: YES');
        print('[FCM_CHECK] full token: $token');
        await _saveTokenLocally(token);
        await _registerTokenIfNeeded(token);
      } else {
        print('[FCM_CHECK] token generated: NO');
        print('[FCM_CHECK] token fetch returned empty/null');
      }

      _attachMessageListeners();

      // Keep token in sync when Firebase rotates it.
      messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty) return;
        final preview = newToken.length > 16
            ? '${newToken.substring(0, 16)}...'
            : newToken;
        print('[FCM_CHECK] onTokenRefresh received: $preview');
        print('[FCM_CHECK] onTokenRefresh full token: $newToken');
        await _saveTokenLocally(newToken);
        await _registerTokenIfNeeded(newToken, force: true);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        LogUtils.info(
          'App opened from terminated notification: ${initialMessage.messageId}',
          tag: 'FCM',
        );
      }

      _isInitialized = true;
      LogUtils.info('FCM initialized successfully', tag: 'FCM');
    } catch (error, stackTrace) {
      // Do not crash app startup when Firebase is not configured yet.
      print('[FCM_CHECK] initialize failed: $error');
      LogUtils.error(
        'FCM initialization failed',
        tag: 'FCM',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    if (_isLocalNotificationsInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _defaultChannelId,
            _defaultChannelName,
            description: _defaultChannelDescription,
            importance: Importance.high,
          ),
        );
      }

      _isLocalNotificationsInitialized = true;
    } on MissingPluginException catch (error, stackTrace) {
      LogUtils.warning(
        'Local notifications plugin not registered yet. Perform full app restart after adding plugin.',
        tag: 'FCM',
      );
      LogUtils.error(
        'Local notifications initialize failed',
        tag: 'FCM',
        error: error,
        stackTrace: stackTrace,
      );
      _isLocalNotificationsInitialized = false;
    }
  }

  static void _attachMessageListeners() {
    if (_areMessageListenersAttached) return;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      LogUtils.info('Foreground FCM message: ${message.messageId}', tag: 'FCM');
      await _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      LogUtils.info(
        'User opened app via notification: ${message.messageId}',
        tag: 'FCM',
      );
    });

    _areMessageListenersAttached = true;
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!_isLocalNotificationsInitialized) {
      await _initializeLocalNotifications();
    }

    final notification = message.notification;
    final title =
        notification?.title ??
        (message.data['title']?.toString().trim() ?? 'Notification');
    final body =
        notification?.body ??
        (message.data['body']?.toString().trim() ??
            message.data['message']?.toString().trim() ??
            'You have a new update');

    final payload = message.data.isEmpty ? null : jsonEncode(message.data);

    if (!_isLocalNotificationsInitialized) {
      _showInAppFallback(title, body);
      return;
    }

    try {
      await _localNotifications.show(
        Random().nextInt(1 << 31),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _defaultChannelId,
            _defaultChannelName,
            channelDescription: _defaultChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } on MissingPluginException {
      _showInAppFallback(title, body);
    } catch (_) {
      _showInAppFallback(title, body);
    }
  }

  static void _showInAppFallback(String title, String body) {
    print('[FCM_CHECK] in-app fallback shown. title: $title, body: $body');

    if (Get.context == null) {
      return;
    }

    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  /// Re-attempt backend registration, useful right after login.
  static Future<void> syncTokenWithBackend() async {
    try {
      print('[FCM_CHECK] syncTokenWithBackend() called');
      await SharedPrefUtils.init();
      final token = SharedPrefUtils.getString(_fcmTokenKey);
      if (token == null || token.isEmpty) {
        print('[FCM_CHECK] no stored token found for backend sync');
        return;
      }
      await _registerTokenIfNeeded(token, force: true);
    } catch (error, stackTrace) {
      print('[FCM_CHECK] syncTokenWithBackend failed: $error');
      LogUtils.error(
        'Failed to sync FCM token with backend',
        tag: 'FCM',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _saveTokenLocally(String token) async {
    await SharedPrefUtils.setString(_fcmTokenKey, token);
    print('[FCM_CHECK] token saved in SharedPreferences ($_fcmTokenKey)');
    LogUtils.debug('FCM token saved locally', tag: 'FCM');
  }

  static Future<void> _registerTokenIfNeeded(
    String token, {
    bool force = false,
  }) async {
    final lastSynced = SharedPrefUtils.getString(_lastSyncedFcmTokenKey);

    if (!force && lastSynced == token) {
      LogUtils.debug('FCM token already synced, skipping API call', tag: 'FCM');
      print('[FCM_CHECK] token already synced, API call skipped');
      return;
    }

    final deviceType = _resolveDeviceType();
    final isAuthenticated = await TokenManager.isAuthenticated();

    if (!isAuthenticated) {
      print(
        '[FCM_CHECK] user not authenticated yet, postponing /api/fcm/register',
      );
      LogUtils.debug(
        'Skipping FCM register until user login is available',
        tag: 'FCM',
      );
      return;
    }

    final response = await ApiService.post(
      '/api/fcm/register',
      body: {'fcm_token': token, 'device_type': deviceType},
      includeAuth: true,
    );

    print(
      '[FCM_CHECK] POST /api/fcm/register => ${response.statusCode}, body: ${response.body}',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await SharedPrefUtils.setString(_lastSyncedFcmTokenKey, token);
      final message = _readMessage(response.body);
      print(
        '[FCM_CHECK] register success message: ${message.isEmpty ? 'FCM token registered successfully' : message}',
      );
      LogUtils.info(
        message.isEmpty ? 'FCM token registered successfully' : message,
        tag: 'FCM',
      );
      return;
    }

    print('[FCM_CHECK] register failed with status ${response.statusCode}');
    LogUtils.warning(
      'FCM register failed: ${response.statusCode} ${response.body}',
      tag: 'FCM',
    );
  }

  static String _resolveDeviceType() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  static String _readMessage(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        return (parsed['message'] ?? '').toString();
      }
      return '';
    } catch (_) {
      return '';
    }
  }
}
