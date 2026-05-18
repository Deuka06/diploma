import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  /// Фон контента по макету (#F8F9FB).
  static const _pageBg = Color(0xFFF8F9FB);
  static const _fallbackName = 'Махамбетхан Медет';
  static const _fallbackEmail = 'medet.makhambetkhan@jihc.kz';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      setState(() {
        _user = null;
        _loading = false;
      });
      return;
    }
    try {
      final res = await auth.client.dio.get<Map<String, dynamic>>('/users/me');
      setState(() {
        _user = res.data;
        _loading = false;
      });
    } on DioException {
      setState(() {
        _user = null;
        _loading = false;
      });
    }
  }

  String get _displayName {
    final u = _user;
    if (u == null) return _fallbackName;
    final full = (u['full_name'] as String?)?.trim();
    if (full != null && full.isNotEmpty) return full;
    final f = (u['first_name'] as String?)?.trim() ?? '';
    final l = (u['last_name'] as String?)?.trim() ?? '';
    final combined = '$f $l'.trim();
    if (combined.isNotEmpty) return combined;
    return _fallbackName;
  }

  String get _email {
    final u = _user;
    if (u == null) return _fallbackEmail;
    final e = u['email'] as String?;
    if (e != null && e.isNotEmpty) return e;
    return _fallbackEmail;
  }

  String get _avatarSeed => _email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MediColors.accentPurple))
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _ProfileHeaderBlock(
                    name: _displayName,
                    email: _email,
                    avatarSeed: _avatarSeed,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      children: [
                        _ParcelsHighlightTile(onTap: () {}),
                        const SizedBox(height: 14),
                        _ProfileMenuCard(
                          children: [
                            _ProfileMenuRow(
                              icon: Icons.edit_outlined,
                              label: 'Изменить профиль',
                              onTap: () async {
                                await context.push('/edit-profile');
                                if (context.mounted) _load();
                              },
                            ),
                            _ProfileMenuRow(
                              icon: Icons.credit_card_outlined,
                              label: 'Карта',
                              onTap: () => context.push('/card'),
                            ),
                            _ProfileMenuRow(
                              icon: Icons.edit_note_outlined,
                              label: 'Пройти проверку',
                              onTap: () => context.push('/onboarding'),
                            ),
                            _ProfileMenuRow(
                              icon: Icons.help_outline_rounded,
                              label: 'Помощь',
                              onTap: () => context.push('/help'),
                            ),
                            _ProfileMenuRow(
                              icon: Icons.logout,
                              label: 'Выйти',
                              danger: true,
                              showDividerAbove: true,
                              onTap: () async {
                                await context.read<AuthController>().logout();
                                if (context.mounted) context.go('/welcome');
                              },
                            ),
                          ],
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

class _ProfileHeaderBlock extends StatelessWidget {
  const _ProfileHeaderBlock({
    required this.name,
    required this.email,
    required this.avatarSeed,
  });

  final String name;
  final String email;
  final String avatarSeed;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9A56), Color(0xFFFF6B9D)],
  );

  static const _outlinePink = Color(0xFFFFB3C8);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const avatarR = 56.0;
    const overlap = 52.0;
    final avatarUrl =
        'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(avatarSeed)}&size=256';

    /// Нижняя граница градиента; аватар «висит» вниз на [overlap].
    final gradientH = top + 132.0;

    return SizedBox(
      height: gradientH + 198,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: gradientH,
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: _gradient),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -20,
                    top: 8,
                    child: IgnorePointer(
                      child: Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _outlinePink.withValues(alpha: 0.85), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -56,
                    top: 56,
                    child: IgnorePointer(
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _outlinePink.withValues(alpha: 0.7), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: gradientH - overlap,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
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
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Material(
                        color: const Color(0xFFFFB3C8),
                        shape: const CircleBorder(),
                        elevation: 2,
                        shadowColor: Colors.black26,
                        child: InkWell(
                          onTap: () {},
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                        child: Text(
                          email,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Лавандовая плитка по макету.
class _ParcelsHighlightTile extends StatelessWidget {
  const _ParcelsHighlightTile({required this.onTap});

  final VoidCallback onTap;

  static const _lavender = Color(0xFFF0E8FF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _lavender,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.inventory_2_outlined, color: MediColors.accentPurple, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Посылки и история покупок',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.showDividerAbove = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool showDividerAbove;

  @override
  Widget build(BuildContext context) {
    final color = danger ? MediColors.danger : const Color(0xFF000000);
    final iconColor = danger ? MediColors.danger : const Color(0xFF000000);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDividerAbove)
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, size: 24, color: iconColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
