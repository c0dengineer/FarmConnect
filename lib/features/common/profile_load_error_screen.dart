import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmconnect/all.dart';

/// Recovery path for authenticated accounts with a missing or unreadable profile.
class ProfileLoadErrorScreen extends ConsumerStatefulWidget {
  const ProfileLoadErrorScreen({super.key});

  @override
  ConsumerState<ProfileLoadErrorScreen> createState() => _ProfileLoadErrorScreenState();
}

class _ProfileLoadErrorScreenState extends ConsumerState<ProfileLoadErrorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _role = Roles.customer;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepoProvider).completeMissingProfile(
            name: _name.text,
            phone: _phone.text,
            role: _role,
          );
      ref.invalidate(currentUserProvider);
    } catch (error) {
      if (mounted) showMsg(context, 'Could not create your profile: ${AuthRepo.friendly(error)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProvider);
    final error = profile.error;
    final missing = !profile.isLoading && error == null && profile.valueOrNull == null;
    final authUser = ref.watch(authStateProvider).valueOrNull;
    if (_name.text.isEmpty && authUser != null) {
      _name.text = authUser.displayName ?? authUser.email?.split('@').first ?? '';
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off_outlined, size: 52, color: AppColors.accent),
                const SizedBox(height: 16),
                Text(missing ? 'Finish setting up your account' : 'Could not load your account', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(
                  missing
                      ? 'You are signed in, but this Firebase project has no FarmConnect profile for this account. This can happen after switching projects. Complete your profile below to continue.'
                      : 'Sign-in succeeded, but FarmConnect could not read your Firestore profile. Check your connection, Firestore setup, and deployed security rules, then retry.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                if (missing) ...[
                  const SizedBox(height: 20),
                  Form(key: _formKey, child: Column(children: [
                    AppField(controller: _name, label: 'Your name', validator: requiredValidator),
                    const SizedBox(height: 12),
                    AppField(controller: _phone, label: 'Phone (optional)', keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: const InputDecoration(labelText: 'I am joining as'),
                      items: const [DropdownMenuItem(value: Roles.customer, child: Text('Customer')), DropdownMenuItem(value: Roles.farmer, child: Text('Farmer'))],
                      onChanged: _saving ? null : (value) { if (value != null) setState(() => _role = value); },
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(label: 'Complete profile', loading: _saving, icon: Icons.check_rounded, onPressed: _completeProfile),
                  ])),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(title: const Text('Technical details'), children: [SelectableText(error.toString(), style: const TextStyle(fontSize: 12, color: AppColors.muted))]),
                ],
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ref.invalidate(currentUserProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry loading profile'),
                ),
                TextButton.icon(
                  onPressed: () => ref.read(authRepoProvider).signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out and return to login'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
