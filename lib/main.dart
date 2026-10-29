import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmconnect/all.dart';
import 'package:farmconnect/app/router.dart';
import 'package:farmconnect/firebase_options.dart';
import 'package:farmconnect/features/common/startup_error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirebaseBootstrapApp());
}

class FirebaseBootstrapApp extends StatefulWidget {
  const FirebaseBootstrapApp({super.key});

  @override
  State<FirebaseBootstrapApp> createState() => _FirebaseBootstrapAppState();
}

class _FirebaseBootstrapAppState extends State<FirebaseBootstrapApp> {
  late final Future<void> _firebaseReady = _initializeFirebase();

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 20));
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _firebaseReady,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return StartupErrorApp(error: snapshot.error!);
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const StartupLoadingApp();
          }
          return const ProviderScope(child: FarmConnectApp());
        },
      );
}

class StartupLoadingApp extends StatelessWidget {
  const StartupLoadingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connecting to FarmConnect...',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 28),
                const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      );
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: StartupErrorScreen(error: error),
      );
}

class FarmConnectApp extends ConsumerWidget {
  const FarmConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentUserProvider, (_, next) {
      final u = next.valueOrNull;
      if (u == null) return;
      unawaited(NotificationService.init(u));
      unawaited(LocationService.requestPermission());
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: NotificationService.messengerKey,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
