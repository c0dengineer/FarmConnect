import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:farmconnect/core/services/notification_service.dart';
import 'package:farmconnect/models/app_user.dart';

class AuthRepo {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String uid) => _db.collection('users').doc(uid);

  Stream<AppUser?> userStream(String uid) =>
      _ref(uid).snapshots().map((d) => d.exists ? AppUser.fromDoc(d) : null);

  Stream<List<AppUser>> watchAllUsers() => _db
      .collection('users')
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromDoc).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    await cred.user!.updateDisplayName(name);
    final user = AppUser(
      uid: cred.user!.uid,
      role: role,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      createdAt: DateTime.now(),
    );
    await _ref(user.uid).set(user.toMap());
  }

  /// Finishes a Firebase Auth account whose Firestore profile was not created.
  Future<void> completeMissingProfile({required String name, required String phone, required String role}) async {
    final authUser = _auth.currentUser;
    if (authUser == null) throw StateError('Sign in again before completing your profile.');
    if (role != Roles.customer && role != Roles.farmer) throw ArgumentError.value(role, 'role');
    final profileRef = _ref(authUser.uid);
    final profile = AppUser(
      uid: authUser.uid,
      role: role,
      name: name.trim(),
      email: (authUser.email ?? '').trim(),
      phone: phone.trim(),
      photoUrl: authUser.photoURL,
      createdAt: DateTime.now(),
    );
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(profileRef);
      if (!existing.exists) transaction.set(profileRef, profile.toMap());
    });
  }

  Future<void> signOut() async {
    NotificationService.reset();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> updateProfile(String uid, {required String name, required String phone}) =>
      _ref(uid).update({'name': name.trim(), 'phone': phone.trim()});

  Future<void> saveAddresses(String uid, List<Address> list) =>
      _ref(uid).update({'addresses': list.map((a) => a.toMap()).toList()});

  Future<void> toggleFavorite(String uid, String productId, bool add) => _ref(uid).update({
        'favoriteProductIds': add ? FieldValue.arrayUnion([productId]) : FieldValue.arrayRemove([productId]),
      });

  Future<void> toggleFollow(String uid, String farmerUid, bool follow) async {
    await _ref(uid).update({
      'followedFarmIds': follow ? FieldValue.arrayUnion([farmerUid]) : FieldValue.arrayRemove([farmerUid]),
    });
    try {
      final fm = FirebaseMessaging.instance;
      follow ? await fm.subscribeToTopic('farm_$farmerUid') : await fm.unsubscribeFromTopic('farm_$farmerUid');
    } catch (_) {}
  }

  Future<void> setBlocked(String uid, bool blocked) => _ref(uid).update({'isBlocked': blocked});

  static String friendly(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
      }
      return e.message ?? 'Authentication failed.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
