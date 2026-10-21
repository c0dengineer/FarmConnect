import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false, _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepoProvider).signIn(_email.text, _pass.text);
    } catch (e) {
      if (mounted) showMsg(context, AuthRepo.friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) return showMsg(context, 'Enter your email first.');
    try {
      await ref.read(authRepoProvider).resetPassword(_email.text);
      if (mounted) showMsg(context, 'Password reset link sent to your email.');
    } catch (e) {
      if (mounted) showMsg(context, AuthRepo.friendly(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.eco_rounded, size: 32, color: AppColors.primary),
                ),
                const SizedBox(height: 22),
                const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Sign in to buy or sell fresh produce.', style: TextStyle(color: AppColors.muted, fontSize: 15)),
                const SizedBox(height: 28),
                AppField(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 14),
                AppField(
                  controller: _pass,
                  label: 'Password',
                  obscure: _hide,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _forgot, child: const Text('Forgot password?'))),
                const SizedBox(height: 8),
                PrimaryButton(label: 'Sign in', loading: _loading, onPressed: _submit),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('New to FarmConnect?', style: TextStyle(color: AppColors.muted)),
                  TextButton(onPressed: () => context.go('/signup'), child: const Text('Create account')),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
