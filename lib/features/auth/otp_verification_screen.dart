import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/primary_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  int _seconds = 45;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() async {
    while (_seconds > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _seconds--);
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const BackBar(title: 'Verify', italic: 'It’s You'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.mark_email_read_rounded,
                      color: AppColors.navyDeep, size: 56),
                  const SizedBox(height: 14),
                  Text('Enter the 6-digit code',
                      style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 6),
                  Text('We sent it to your email.',
                      style: AppTextStyles.italicAccent(
                          size: 13, color: AppColors.grey)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 46,
                        height: 56,
                        child: TextField(
                          controller: _ctrls[i],
                          focusNode: _focus[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: AppTextStyles.fraunces(
                              size: 22,
                              weight: FontWeight.w900,
                              color: AppColors.navyDeep),
                          decoration: const InputDecoration(counterText: ''),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) {
                              _focus[i + 1].requestFocus();
                            }
                            if (v.isEmpty && i > 0) {
                              _focus[i - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: _seconds > 0
                        ? Text('RESEND IN ${_seconds}S',
                            style: AppTextStyles.mono(
                              size: 9,
                              letterSpacing: 0.2,
                              color: AppColors.grey,
                            ))
                        : TextButton(
                            onPressed: () => setState(() {
                              _seconds = 45;
                              _tick();
                            }),
                            child: const Text('RESEND CODE'),
                          ),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Verify',
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
