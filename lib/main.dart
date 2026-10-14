import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmconnect/all.dart';
import 'package:farmconnect/app/router.dart';
import 'package:farmconnect/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: FarmConnectApp()));
}

class FarmConnectApp extends ConsumerWidget {
  const FarmConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Register for push notifications as soon as a user is signed in.
    ref.listen(currentUserProvider, (_, next) {
      final u = next.valueOrNull;
      if (u != null) NotificationService.init(u);
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
