import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  List<Map<String, dynamic>> _treatments = [];
  bool _loading = true;

  static const _cardColors = [
    Color(0xFFFFB3B8),
    Color(0xFFFFF0B8),
    Color(0xFFB8ECF0),
    Color(0xFFB8F0C0),
    Color(0xFFE8B8F0),
  ];

  @override
  void initState() {
    super.initState();
    _loadTreatments();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadTreatments() async {
    final auth = context.read<AuthController>();
    setState(() => _loading = true);
    try {
      final res = await auth.client.dio.get<List<dynamic>>('/treatments');
      setState(() {
        _treatments = (res.data ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } on DioException {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _activeTreatments =>
      _treatments.where((t) => t['is_completed'] == false).toList();

  List<Map<String, dynamic>> get _allTreatments => _treatments;

  Color _cardColor(int colorIndex) =>
      _cardColors[colorIndex.clamp(0, _cardColors.length - 1)];

  String _formatDays(int days) {
    if (days <= 0) return 'Продолжается';
    if (days % 100 >= 11 && days % 100 <= 19) return '$days дней';
    switch (days % 10) {
      case 1:
        return '$days день';
      case 2:
      case 3:
      case 4:
        return '$days дня';
      default:
        return '$days дней';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthController>().userName ?? 'Медет';
    return Scaffold(
      backgroundColor: MediColors.homeBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => context.push('/reminders'),
                        icon: Icon(Icons.notifications_none_rounded,
                            color: MediColors.greetingPurple, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      const SizedBox(width: 4),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: MediColors.accentPurple.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.person_rounded,
                          size: 26,
                          color: MediColors.accentPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Привет, $userName!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: MediColors.greetingPurple,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          height: 1.15,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: AnimatedBuilder(
                animation: _tab,
                builder: (context, _) => _HomeHeaderChips(
                  index: _tab.index,
                  onChanged: (i) => _tab.animateTo(i),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _tab,
              builder: (context, _) => _HomeSectionHeader(index: _tab.index),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _RecipesTab(
                    treatments: _activeTreatments,
                    loading: _loading,
                    cardColor: _cardColor,
                    formatDays: _formatDays,
                    onRefresh: _loadTreatments,
                  ),
                  _ProgressTab(
                    treatments: _allTreatments,
                    loading: _loading,
                    cardColor: _cardColor,
                    formatDays: _formatDays,
                    onRefresh: _loadTreatments,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeaderChips extends StatelessWidget {
  const _HomeHeaderChips({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _purple = MediColors.greetingPurple;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (index == 0)
          _HomeActiveTabPill(
            onTap: () => onChanged(0),
            icon: _PrescriptionIcon(color: _purple, ringColor: MediColors.tabActiveLavender),
            label: 'Ваш рецепт',
          )
        else
          _HomeIconOnlyTab(
            onTap: () => onChanged(0),
            child: Icon(Icons.medication_liquid_rounded, color: _purple, size: 28),
          ),
        const SizedBox(width: 12),
        if (index == 1)
          _HomeActiveTabPill(
            onTap: () => onChanged(1),
            icon: Icon(Icons.schedule_rounded, color: _purple, size: 26),
            label: 'Прогресс',
          )
        else
          _HomeIconOnlyTab(
            onTap: () => onChanged(1),
            child: Icon(Icons.schedule_rounded, color: _purple, size: 28),
          ),
      ],
    );
  }
}

class _HomeActiveTabPill extends StatelessWidget {
  const _HomeActiveTabPill({required this.onTap, required this.icon, required this.label});

  final VoidCallback onTap;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: MediColors.tabActiveLavender,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: MediColors.greetingPurple,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeIconOnlyTab extends StatelessWidget {
  const _HomeIconOnlyTab({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final isRecipes = index == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRecipes ? 'Твои лекарства' : 'Твой прогресс',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: MediColors.greetingPurple,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            isRecipes ? 'Написаны вашим Доктором' : 'В этой неделе',
            style: const TextStyle(
              color: MediColors.headerSubtitle,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionIcon extends StatelessWidget {
  const _PrescriptionIcon({required this.color, this.ringColor});

  final Color color;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(Icons.medication_liquid_rounded, color: color, size: 24),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                    color: ringColor ?? MediColors.tabActiveLavender, width: 1.5),
              ),
              child: const Icon(Icons.add, size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Вкладка "Рецепты" — активные лечения
class _RecipesTab extends StatelessWidget {
  const _RecipesTab({
    required this.treatments,
    required this.loading,
    required this.cardColor,
    required this.formatDays,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> treatments;
  final bool loading;
  final Color Function(int) cardColor;
  final String Function(int) formatDays;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: MediColors.accentPurple));
    }
    if (treatments.isEmpty) {
      return RefreshIndicator(
        color: MediColors.accentPurple,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: const [
            SizedBox(height: 60),
            Center(
              child: Text(
                'Нет активных лечений.\nДобавьте в разделе Обзор.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MediColors.textMuted, fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: MediColors.accentPurple,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: treatments.map((t) {
          final colorIdx = (t['color_index'] as int?) ?? 0;
          final medicineName =
              (t['medicine_name'] as String?)?.isNotEmpty == true
                  ? t['medicine_name'] as String
                  : t['disease_name'] as String;
          final durationDays = (t['duration_days'] as int?) ?? 0;
          final intakeTime = t['intake_time'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _MedicationCard(
              title: medicineName,
              duration: formatDays(durationDays),
              time: intakeTime,
              color: cardColor(colorIdx),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Вкладка "Прогресс" — мини-карточки + статистика
class _ProgressTab extends StatelessWidget {
  const _ProgressTab({
    required this.treatments,
    required this.loading,
    required this.cardColor,
    required this.formatDays,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> treatments;
  final bool loading;
  final Color Function(int) cardColor;
  final String Function(int) formatDays;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: MediColors.accentPurple));
    }

    final active = treatments.where((t) => t['is_completed'] == false).toList();
    final progressVal = active.isEmpty
        ? 0.0
        : active
                .map((t) => (t['progress'] as num).toDouble())
                .reduce((a, b) => a + b) /
            active.length;

    return RefreshIndicator(
      color: MediColors.accentPurple,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: MediColors.accentPurple,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: MediColors.accentPurple.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active.isNotEmpty
                            ? active.first['disease_name'] as String
                            : 'Нет активных',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ваш еженедельный отчет',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progressVal,
                        strokeWidth: 7,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Text(
                          '${(progressVal * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: _BigStatCard(
                    color: const Color(0xFFFF9F6B),
                    icon: Icons.local_fire_department_rounded,
                    value: '2,000',
                    label: 'Калл',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 10,
                  child: Column(
                    children: [
                      Expanded(
                        child: _SmallStatCard(
                          color: const Color(0xFF5BA4E5),
                          icon: Icons.water_drop_rounded,
                          value: '50',
                          label: 'Стакан воды',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _SmallStatCard(
                          color: const Color(0xFFFF9A9A),
                          icon: Icons.directions_walk_rounded,
                          value: '10,000',
                          label: 'Шаги',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.title,
    required this.duration,
    required this.time,
    required this.color,
  });

  final String title;
  final String duration;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Color(0xFF2D2D2D)),
                ),
                const SizedBox(height: 6),
                Text(
                  duration,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black.withValues(alpha: 0.55)),
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black.withValues(alpha: 0.55)),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 72,
            height: 88,
            alignment: Alignment.center,
            child: Icon(Icons.medication_liquid_rounded,
                size: 56, color: Colors.white.withValues(alpha: 0.95)),
          ),
        ],
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  const _BigStatCard({
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20)),
                Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
