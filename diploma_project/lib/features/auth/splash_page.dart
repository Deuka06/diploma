import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go());
  }

  Future<void> _go() async {
    final auth = context.read<AuthController>();
    while (!auth.isReady) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    if (auth.isLoggedIn) {
      await auth.refreshUserProfile();
      if (!mounted) return;
      context.go(auth.needsOnboarding ? '/onboarding' : '/t/home');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_pharmacy, size: 72, color: MediColors.primary),
            const SizedBox(height: 16),
            Text(
              'MEDI',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
