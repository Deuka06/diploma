import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/medi_theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Бастайық',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: MediColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Жаңа мүмкіндіктерді ашу үшін тіркеліңіз',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MediColors.textMuted),
              ),
              const SizedBox(height: 32),
              Image.asset(
                'assets/4.png',
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.push('/register'),
                child: const Text('Электрондық поштамен жалғастыру'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Аккаунтыңыз бар ма? '),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Кіру'),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
