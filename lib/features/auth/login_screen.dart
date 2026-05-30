import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../../data/backend_sync.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (_user.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username and password')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.login(_user.text.trim(), _pass.text);
      await BackendSync.instance.refreshAll();
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              _label('USERNAME OR EMAIL'),
              const SizedBox(height: 6),
              TextField(
                controller: _user,
                decoration: const InputDecoration(hintText: 'superadmin'),
                style:
                    AppTextStyles.fraunces(size: 14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              _label('PASSWORD'),
              const SizedBox(height: 6),
              TextField(
                controller: _pass,
                obscureText: _obscure,
                onSubmitted: (_) => _go(),
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
