import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/stats/daily_stats_controller.dart';
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
    if (days <= 0) return 'Жалғасуда';
    return '$days күн';
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthController>().userName ?? '';
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
                      GestureDetector(
                        onTap: () => context.go('/t/profile'),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: MediColors.accentPurple.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.person_rounded,
                            size: 26,
                            color: MediColors.accentPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName.isNotEmpty ? 'Сәлем, $userName!' : 'Сәлем!',
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
            label: 'Сіздің рецептіңіз',
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
            isRecipes ? 'Сіздің дәрілеріңіз' : 'Сіздің прогресіңіз',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: MediColors.greetingPurple,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            isRecipes ? 'Дәрігер тағайындаған' : 'Осы аптада',
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
                'Белсенді ем-дом жоқ.\nШолу бөліміне қосыңыз.',
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

    final stats = context.watch<DailyStatsController>();

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
                            : 'Белсенді жоқ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Апталық есебіңіз',
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
                    value: _formatNum(stats.calories),
                    label: 'Ккал / ${_formatNum(DailyStatsController.caloriesTarget)}',
                    progress: stats.calories / DailyStatsController.caloriesTarget,
                    onTap: () => _showCaloriesSheet(context, stats),
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
                          value: '${stats.water}',
                          label: 'Стақан / ${DailyStatsController.waterTarget}',
                          progress: stats.water / DailyStatsController.waterTarget,
                          onTap: () => _showWaterSheet(context, stats),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _SmallStatCard(
                          color: const Color(0xFFFF9A9A),
                          icon: Icons.directions_walk_rounded,
                          value: _formatNum(stats.steps),
                          label: 'Қадам / ${_formatNum(DailyStatsController.stepsTarget)}',
                          progress: stats.steps / DailyStatsController.stepsTarget,
                          onTap: () => _showStepsSheet(context, stats),
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

String _formatNum(int n) {
  if (n >= 1000) {
    final s = n.toString();
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
  return '$n';
}

void _showWaterSheet(BuildContext context, DailyStatsController stats) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _WaterSheet(stats: stats),
  );
}

void _showCaloriesSheet(BuildContext context, DailyStatsController stats) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: stats,
      child: const _CaloriesSheet(),
    ),
  );
}

void _showStepsSheet(BuildContext context, DailyStatsController stats) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: stats,
      child: const _StepsSheet(),
    ),
  );
}

class _WaterSheet extends StatelessWidget {
  const _WaterSheet({required this.stats});
  final DailyStatsController stats;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: stats,
      child: Consumer<DailyStatsController>(
        builder: (context, s, _) {
          final pct = (s.water / DailyStatsController.waterTarget).clamp(0.0, 1.0);
          return _BottomSheetShell(
            title: 'Су',
            subtitle: 'Мақсат: күніне ${DailyStatsController.waterTarget} стақан (≈ 2 л)',
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  '${s.water} / ${DailyStatsController.waterTarget}',
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF5BA4E5)),
                ),
                const Text('стақан', style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93))),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE8EFF8),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF5BA4E5)),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CircleBtn(
                      icon: Icons.remove,
                      color: const Color(0xFF5BA4E5),
                      onTap: s.removeWater,
                    ),
                    const SizedBox(width: 32),
                    const Icon(Icons.water_drop_rounded, size: 40, color: Color(0xFF5BA4E5)),
                    const SizedBox(width: 32),
                    _CircleBtn(
                      icon: Icons.add,
                      color: const Color(0xFF5BA4E5),
                      onTap: s.addWater,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('1 стақан = 250 мл', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CaloriesSheet extends StatefulWidget {
  const _CaloriesSheet();

  @override
  State<_CaloriesSheet> createState() => _CaloriesSheetState();
}

class _CaloriesSheetState extends State<_CaloriesSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add(DailyStatsController stats) {
    final val = int.tryParse(_ctrl.text.trim());
    if (val == null || val <= 0) return;
    stats.addCalories(val);
    _ctrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyStatsController>(
      builder: (context, stats, _) {
        final pct = (stats.calories / DailyStatsController.caloriesTarget).clamp(0.0, 1.0);
        return _BottomSheetShell(
          title: 'Калория',
          subtitle: 'Мақсат: күніне ${DailyStatsController.caloriesTarget} ккал',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${stats.calories} / ${DailyStatsController.caloriesTarget}',
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFFFF9F6B)),
                ),
              ),
              const Center(child: Text('ккал', style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93)))),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF2EDE8),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9F6B)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Тамақ мезгілін қосу', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Ккал енгізіңіз',
                        filled: true,
                        fillColor: const Color(0xFFF2F2F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _add(stats),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9F6B),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Қосу', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: stats.resetCalories,
                child: const Text('Күнді нөлдеу', style: TextStyle(color: Color(0xFFFF3B30))),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepsSheet extends StatefulWidget {
  const _StepsSheet();

  @override
  State<_StepsSheet> createState() => _StepsSheetState();
}

class _StepsSheetState extends State<_StepsSheet> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final stats = context.read<DailyStatsController>();
    if (stats.steps > 0 && !stats.pedometerActive) {
      _ctrl.text = '${stats.steps}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save(DailyStatsController stats) {
    final val = int.tryParse(_ctrl.text.trim());
    if (val == null) return;
    stats.setSteps(val);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyStatsController>(
      builder: (context, stats, _) {
        final pct = (stats.steps / DailyStatsController.stepsTarget).clamp(0.0, 1.0);
        return _BottomSheetShell(
          title: 'Қадамдар',
          subtitle: 'Мақсат: күніне ${_formatNum(DailyStatsController.stepsTarget)} қадам',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _formatNum(stats.steps),
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFFFF9A9A)),
                ),
              ),
              const Center(child: Text('қадам', style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93)))),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF5EAEA),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9A9A)),
                ),
              ),
              const SizedBox(height: 20),
              // Статус педометра
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: stats.pedometerActive
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      stats.pedometerActive
                          ? Icons.directions_walk_rounded
                          : Icons.phonelink_off_rounded,
                      color: stats.pedometerActive
                          ? const Color(0xFF43A047)
                          : const Color(0xFF8E8E93),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stats.pedometerActive
                            ? 'Қадамсан белсенді — қадамдар автоматты есептеледі'
                            : 'Қадамсан қолжетімсіз — қадамды қолмен енгізіңіз',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: stats.pedometerActive
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!stats.pedometerActive) ...[
                const SizedBox(height: 16),
                const Text('Қадам санын енгізіңіз',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'Мысалы: 5000',
                          filled: true,
                          fillColor: const Color(0xFFF2F2F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => _save(stats),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9A9A),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Сақтау',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BottomSheetShell extends StatelessWidget {
  const _BottomSheetShell({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: color, size: 28),
        ),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
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
    this.progress = 0,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String value;
  final String label;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ),
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
    this.progress = 0,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String value;
  final String label;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      fontSize: 10)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
