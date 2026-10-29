import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:farmconnect/core/services/location_service.dart';
import 'package:farmconnect/models/app_user.dart';

class NotificationService {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static String? _initializedFor;
  static StreamSubscription<RemoteMessage>? _sub;
  static StreamSubscription<String>? _tokenSub;
  static final Set<String> _subscribedTopics = {};

  /// Saves the FCM token, subscribes to followed farm topics and shows foreground messages.
  static Future<void> init(AppUser user) async {
    try {
      final fm = FirebaseMessaging.instance;
      if (_initializedFor != user.uid) {
        for (final topic in _subscribedTopics.toList()) {
          await fm.unsubscribeFromTopic(topic);
        }
        await _sub?.cancel();
        await _tokenSub?.cancel();
        _subscribedTopics.clear();
        _initializedFor = user.uid;
        await fm.requestPermission();
        await LocationService.requestPermission();
        _sub = FirebaseMessaging.onMessage.listen((m) {
          final n = m.notification;
          if (n == null) return;
          final title = n.title;
          final body = n.body;
          messengerKey.currentState?.showSnackBar(
            SnackBar(
                content: Text([title, body].whereType<String>().join('\n'))),
          );
        });
        _tokenSub =
            fm.onTokenRefresh.listen((token) => _saveToken(user.uid, token));
      }

      final desiredTopics =
          user.followedFarmIds.map((id) => 'farm_$id').toSet();
      for (final topic
          in _subscribedTopics.difference(desiredTopics).toList()) {
        await fm.unsubscribeFromTopic(topic);
        _subscribedTopics.remove(topic);
      }
      for (final topic in desiredTopics.difference(_subscribedTopics)) {
        await fm.subscribeToTopic(topic);
        _subscribedTopics.add(topic);
      }

      final token = await fm.getToken();
      if (token != null) await _saveToken(user.uid, token);
    } catch (_) {
      // Notifications are optional; never block the app.
    }
  }

  static Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});
    } catch (_) {
      // Token persistence is best-effort; in-app alerts remain available.
    }
  }

  static void reset() {
    final fm = FirebaseMessaging.instance;
    for (final topic in _subscribedTopics) {
      fm.unsubscribeFromTopic(topic).catchError((_) {});
    }
    _subscribedTopics.clear();
    _initializedFor = null;
    _sub?.cancel();
    _tokenSub?.cancel();
    _sub = null;
    _tokenSub = null;
  }
}
