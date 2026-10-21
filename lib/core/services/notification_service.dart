import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:farmconnect/models/app_user.dart';

class NotificationService {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static String? _initializedFor;
  static StreamSubscription<RemoteMessage>? _sub;

  /// Saves the FCM token, subscribes to followed farm topics and shows foreground messages.
  static Future<void> init(AppUser user) async {
    if (_initializedFor == user.uid) return;
    _initializedFor = user.uid;
    try {
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      final token = await fm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': token});
      }
      for (final f in user.followedFarmIds) {
        await fm.subscribeToTopic('farm_$f');
      }
      await _sub?.cancel();
      _sub = FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n == null) return;
        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text([n.title, n.body].whereType<String>().join('\n'))),
        );
      });
    } catch (_) {
      // Notifications are optional; never block the app.
    }
  }

  static void reset() {
    _initializedFor = null;
    _sub?.cancel();
    _sub = null;
  }
}
