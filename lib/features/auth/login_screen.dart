import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _go() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AppLogo(size: 96)),
              const SizedBox(height: 32),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: 'Welcome ',
                      style: AppTextStyles.fraunces(
                          size: 30,
                          weight: FontWeight.w900,
                          color: AppColors.navyDeep)),
                  TextSpan(
                      text: 'back',
                      style: AppTextStyles.italicAccent(
                          size: 30, color: AppColors.goldDeep)),
                ]),
              ),
              const SizedBox(height: 8),
              Text('Sign in to score, manage, and follow live cricket.',
                  style: AppTextStyles.italicAccent(
                      size: 13, color: AppColors.grey)),
              const SizedBox(height: 26),
              _label('EMAIL OR PHONE'),
              const SizedBox(height: 6),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'you@example.com'),
                style:
                    AppTextStyles.fraunces(size: 14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              _label('PASSWORD'),
              const SizedBox(height: 6),
              TextField(
                controller: _pass,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                  ),
                ),
                style:
                    AppTextStyles.fraunces(size: 14, weight: FontWeight.w600),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text('FORGOT PASSWORD?'),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                  label: 'Sign In', loading: _loading, onPressed: _go),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('NEW HERE?',
                      style: AppTextStyles.mono(
                          size: 9, letterSpacing: 0.2, color: AppColors.grey)),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('CREATE ACCOUNT'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String s) => Text(s,
      style: AppTextStyles.mono(
          size: 9, color: AppColors.grey, letterSpacing: 0.2));
}
