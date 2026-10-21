import 'dart:async';

import 'package:flutter/material.dart';
import 'package:farmconnect/app/theme.dart';

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key, required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final isMissingConfig = error is UnsupportedError;
    final isTimeout = error is TimeoutException;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 54, color: AppColors.accent),
                  const SizedBox(height: 18),
                  const Text('FarmConnect could not start',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                    isMissingConfig
                        ? 'Firebase is not configured for this platform. From the project folder, run:'
                        : isTimeout
                            ? 'Firebase did not respond within 20 seconds. Check your connection and project configuration, then reload FarmConnect.'
                            : 'Firebase initialization failed. Check your Firebase configuration and restart the app.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  if (isMissingConfig) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border.withValues(alpha: .5)),
                      ),
                      child: const SelectableText(
                        'dart pub global run flutterfire_cli:flutterfire configure',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Select your Firebase project and include Web.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                  const SizedBox(height: 18),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Technical details'),
                    children: [
                      SelectableText(error.toString(),
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
