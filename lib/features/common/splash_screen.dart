import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmconnect/all.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key, this.blocked = false});
  final bool blocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: Icon(blocked ? Icons.block_rounded : Icons.eco_rounded, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(blocked ? 'Account suspended' : AppConstants.appName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(blocked ? 'Your account has been blocked. Please contact support.' : 'Fresh from the farm',
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 28),
            if (!blocked) const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            const SizedBox(height: 20),
            if (blocked)
              PrimaryButton(label: 'Sign out', outlined: true, expand: false, onPressed: () => ref.read(authRepoProvider).signOut())
            else
              TextButton(onPressed: () => ref.read(authRepoProvider).signOut(), child: const Text('Taking too long? Sign out')),
          ]),
        ),
      ),
    );
  }
}
