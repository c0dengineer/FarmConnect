import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  String _role = Roles.customer;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepoProvider).signUp(
            name: _name.text,
            email: _email.text,
            password: _pass.text,
            phone: _phone.text,
            role: _role,
          );
    } catch (e) {
      if (mounted) showMsg(context, AuthRepo.friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _roleCard(String role, IconData icon, String title, String sub) {
    final on = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: on ? AppColors.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? AppColors.primary : AppColors.border, width: on ? 1.6 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: on ? AppColors.primary : AppColors.muted),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/login'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Create account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Join the farm-to-door marketplace.', style: TextStyle(color: AppColors.muted, fontSize: 15)),
              const SizedBox(height: 22),
              Row(children: [
                _roleCard(Roles.customer, Icons.shopping_basket_outlined, 'Customer', 'Buy fresh produce'),
                const SizedBox(width: 12),
                _roleCard(Roles.farmer, Icons.agriculture_outlined, 'Farmer', 'Sell your harvest'),
              ]),
              const SizedBox(height: 20),
              AppField(controller: _name, label: 'Full name', prefixIcon: Icons.person_outline_rounded, validator: requiredValidator),
              const SizedBox(height: 14),
              AppField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 14),
              AppField(
                controller: _phone,
                label: 'Phone number',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null,
              ),
              const SizedBox(height: 14),
              AppField(
                controller: _pass,
                label: 'Password',
                obscure: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Create account', loading: _loading, onPressed: _submit),
            ]),
          ),
        ),
      ),
    );
  }
}
