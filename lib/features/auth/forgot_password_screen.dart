import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    context.push('/verify-otp');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const BackBar(title: 'Reset', italic: 'Password'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_reset_rounded,
                      size: 56, color: AppColors.navy),
                  const SizedBox(height: 18),
                  Text('Forgot your password?',
                      style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your account email and we will send a 6-digit OTP to verify it is you.',
                    style: AppTextStyles.fraunces(
                        size: 13,
                        weight: FontWeight.w400,
                        color: AppColors.grey),
                  ),
                  const SizedBox(height: 22),
                  Text('EMAIL',
                      style: AppTextStyles.mono(
                          size: 9, color: AppColors.grey, letterSpacing: 0.2)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _email,
                    decoration:
                        const InputDecoration(hintText: 'you@example.com'),
                    style: AppTextStyles.fraunces(
                        size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                      label: 'Send OTP', loading: _loading, onPressed: _send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
