import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'firebase_service.dart';

@pragma('vm:entry-point')
Future<void> backgroundMessage(RemoteMessage message) async {
  await FirebaseService.initialize();
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final local = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? tokenSubscription;
  StreamSubscription<RemoteMessage>? foreground, opened;
  void Function(String)? navigate;
  Future<void> register() async {
    if (FirebaseService.useEmulators) return;
    await unregisterListeners();
    await local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (_) => navigate?.call('/notifications'),
    );
    await local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'jbb_training',
            'Training updates',
            importance: Importance.high,
          ),
        );
    final permission = await FirebaseMessaging.instance.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.denied) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await saveToken(token);
    tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) {
      saveToken(token).catchError((Object e) {});
    });
    foreground = FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n != null) {
        local
            .show(
              id: (message.messageId ?? n.title ?? '').hashCode & 0x7fffffff,
              title: n.title,
              body: n.body,
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'jbb_training',
                  'Training updates',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
            )
            .catchError((Object e) {});
}
    });
    opened = FirebaseMessaging.onMessageOpenedApp.listen(
      (_) => navigate?.call('/notifications'),
    );
    if (await FirebaseMessaging.instance.getInitialMessage() != null) {
      navigate?.call('/notifications');
}
  }

  Future<void> saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final box = Hive.box('jbb_device');
    final deviceId = box.get('deviceId') ?? const Uuid().v4();
    await box.put('deviceId', deviceId);
    await FirebaseFirestore.instance.doc('users/$uid/devices/$deviceId').set({
      'token': token,
      'platform': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unregisterListeners() async {
    await tokenSubscription?.cancel();
    await foreground?.cancel();
    await opened?.cancel();
  }

  Future<void> unregister() async {
    await unregisterListeners();
    if (FirebaseService.useEmulators) return;
    final uid = FirebaseAuth.instance.currentUser?.uid,
        deviceId = Hive.box('jbb_device').get('deviceId');
    if (uid != null && deviceId != null) {
      await FirebaseFirestore.instance
          .doc('users/$uid/devices/$deviceId')
          .delete();
}
    await FirebaseMessaging.instance.deleteToken();
  }
}
