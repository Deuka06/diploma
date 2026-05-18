import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  bool _saving = false;

  static const _fieldFill = Color(0xFFF2F2F7);
  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9A56), Color(0xFFFF6B9D)],
  );

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthController>().userProfile;
    if (profile != null) {
      _firstNameCtrl.text = (profile['first_name'] as String?)?.trim() ?? '';
      _lastNameCtrl.text = (profile['last_name'] as String?)?.trim() ?? '';
      if (_firstNameCtrl.text.isEmpty && _lastNameCtrl.text.isEmpty) {
        final full = (profile['full_name'] as String?)?.trim() ?? '';
        final parts = full.split(' ');
        if (parts.isNotEmpty) _firstNameCtrl.text = parts.first;
        if (parts.length > 1) _lastNameCtrl.text = parts.sublist(1).join(' ');
      }
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    if (firstName.isEmpty) return;
    setState(() => _saving = true);
    final auth = context.read<AuthController>();
    final err = await auth.patchProfile({
      'first_name': firstName,
      'last_name': lastName,
      'full_name': '$firstName $lastName'.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const avatarR = 50.0;
    final email = context.read<AuthController>().userProfile?['email'] as String? ?? '';
    final avatarUrl =
        'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(email)}&size=256';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          SizedBox(
            height: top + 140,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(decoration: const BoxDecoration(gradient: _gradient)),
                ),
                Positioned(
                  top: top + 12,
                  left: 4,
                  child: BackButton(
                    color: Colors.white,
                    onPressed: () => context.pop(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: avatarR,
                          backgroundColor: const Color(0xFFFFD54F),
                          child: ClipOval(
                            child: Image.network(
                              avatarUrl,
                              width: avatarR * 2,
                              height: avatarR * 2,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/6.png',
                                  width: avatarR * 2,
                                  height: avatarR * 2,
                                  fit: BoxFit.cover,
                                ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Изменить профиль',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Имя', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF6B6B6B))),
                  const SizedBox(height: 8),
                  _Field(controller: _firstNameCtrl, hint: 'Введите имя', fillColor: _fieldFill),
                  const SizedBox(height: 16),
                  const Text('Фамилия', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF6B6B6B))),
                  const SizedBox(height: 8),
                  _Field(controller: _lastNameCtrl, hint: 'Введите фамилию', fillColor: _fieldFill),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: MediColors.accentPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Сохранить'),
                    ),
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

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint, required this.fillColor});

  final TextEditingController controller;
  final String hint;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: MediColors.textMuted.withValues(alpha: 0.85), fontSize: 16),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
