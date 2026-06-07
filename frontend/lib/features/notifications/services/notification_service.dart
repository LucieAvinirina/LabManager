import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
 
// ─── Handler arrière-plan (doit être top-level) ────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Notification arrière-plan : ${message.notification?.title}');
}
 
class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
 
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
 
  // Canal Android
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'labmanager_channel',
    'LabManager Notifications',
    description: 'Notifications réservations et incidents',
    importance: Importance.high,
    playSound: true,
  );
 
  // ─── Initialisation ───────────────────────────────────────
  Future<void> initialize() async {
    try {
      // 1. Handler arrière-plan
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);
 
      // 2. Demander permission
      final settings = await _messaging.requestPermission(
        alert:       true,
        badge:       true,
        sound:       true,
        provisional: false,
      );
      debugPrint(
          '🔔 Permission : ${settings.authorizationStatus}');
 
      if (settings.authorizationStatus ==
          AuthorizationStatus.denied) {
        debugPrint('❌ Notifications refusées par l\'utilisateur');
        return;
      }
 
      // 3. Notifications locales
      await _initLocalNotifications();
 
      // 4. Écouter notifications app ouverte
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
 
      // 5. Écouter clics notifications
      FirebaseMessaging.onMessageOpenedApp
          .listen(_onNotificationTap);
 
      // 6. Notification qui a ouvert l'app depuis terminée
      final initialMessage =
          await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _onNotificationTap(initialMessage);
      }
 
      debugPrint('✅ NotificationService prêt');
    } catch (e) {
      debugPrint('❌ Erreur init NotificationService : $e');
    }
  }
 
  // ─── Initialiser notifications locales ───────────────────
  Future<void> _initLocalNotifications() async {
    const android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
 
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Clic notification locale : ${details.payload}');
      },
    );
 
    // Créer le canal Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
 
  // ─── Sauvegarder le token FCM après connexion ────────────
  Future<void> saveFcmToken() async {
    try {
      final isLoggedIn = await SecureStorage.isLoggedIn();
      if (!isLoggedIn) return;
 
      final token = await _messaging.getToken();
      if (token == null) return;
 
      debugPrint('📱 FCM Token : ${token.substring(0, 20)}...');
 
      await ApiClient.put(
        AppEndpoints.fcmToken,
        data: {'fcm_token': token},
      );
      debugPrint('✅ FCM token enregistré');
 
      // Écouter les rafraîchissements de token
      _messaging.onTokenRefresh.listen((newToken) async {
        final logged = await SecureStorage.isLoggedIn();
        if (!logged) return;
        await ApiClient.put(
          AppEndpoints.fcmToken,
          data: {'fcm_token': newToken},
        );
        debugPrint('✅ FCM token rafraîchi');
      });
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde FCM token : $e');
    }
  }
 
  // ─── Notification reçue app OUVERTE ──────────────────────
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;
 
    debugPrint('🔔 Notification reçue : ${notif.title}');
 
    await _localNotifications.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority:   Priority.high,
          icon:       '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }
 
  // ─── Clic sur notification ────────────────────────────────
  void _onNotificationTap(RemoteMessage message) {
    final type = message.data['type'] ?? '';
    debugPrint('🔔 Notification cliquée, type : $type');
    // Navigation gérée dans main.dart via GlobalKey<NavigatorState>
  }
}