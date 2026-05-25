import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/enums.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _agreed = false;
  UserRole _role = UserRole.fan;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const BackBar(title: 'Create', italic: 'Account'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              children: [
                Text('Join the home of veteran cricket.',
                    style: AppTextStyles.italicAccent(
                        size: 13, color: AppColors.grey)),
                const SizedBox(height: 20),
                _label('FULL NAME'),
                const SizedBox(height: 6),
                TextField(
                  controller: _name,
                  decoration:
                      const InputDecoration(hintText: 'e.g. Imran Sidhu'),
                  style:
                      AppTextStyles.fraunces(size: 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                _label('EMAIL'),
                const SizedBox(height: 6),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(hintText: 'you@example.com'),
                  style:
                      AppTextStyles.fraunces(size: 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                _label('PHONE (OPTIONAL)'),
                const SizedBox(height: 6),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(hintText: '+92 300 1234567'),
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
                    hintText: 'Min 8 characters',
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
                const SizedBox(height: 20),
                _label('I AM A...'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final r in [
                      UserRole.fan,
                      UserRole.player,
                      UserRole.captain,
                      UserRole.scorer,
                      UserRole.organizer,
                    ])
                      _rolePill(r),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      activeColor: AppColors.navyDeep,
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.fraunces(
                              size: 12, weight: FontWeight.w400),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                                text: 'Terms',
                                style: AppTextStyles.fraunces(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: AppColors.navyDeep)),
                            const TextSpan(text: ' and '),
                            TextSpan(
                                text: 'Privacy Policy',
                                style: AppTextStyles.fraunces(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: AppColors.navyDeep)),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Continue',
                  onPressed: () => context.push('/verify-otp'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String s) => Text(s,
      style: AppTextStyles.mono(
          size: 9, color: AppColors.grey, letterSpacing: 0.2));

  Widget _rolePill(UserRole r) {
    final selected = _role == r;
    final label = switch (r) {
      UserRole.fan => 'Fan',
      UserRole.player => 'Player',
      UserRole.captain => 'Captain',
      UserRole.scorer => 'Scorer',
      UserRole.organizer => 'Organizer',
      UserRole.admin => 'Admin',
    };
    return GestureDetector(
      onTap: () => setState(() => _role = r),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navyDeep : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? AppColors.navyDeep : AppColors.line),
        ),
        child: Text(label.toUpperCase(),
            style: AppTextStyles.mono(
              size: 9,
              color: selected ? AppColors.cream : AppColors.ink,
              letterSpacing: 0.15,
              weight: FontWeight.w700,
            )),
      ),
    );
  }
}
