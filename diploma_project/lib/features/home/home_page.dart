import 'package:flutter/material.dart';

import '../../core/theme/medi_theme.dart';

/// Главная: рецепты / прогресс по макету MEDI.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        onPressed: () {},
                        icon: Icon(Icons.notifications_none_rounded, color: MediColors.greetingPurple, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      const SizedBox(width: 4),
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFFFFC107),
                        child: Text('🐕', style: TextStyle(fontSize: 22)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Привет, Медет!',
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
                builder: (context, _) {
                  return _HomeHeaderChips(
                    index: _tab.index,
                    onChanged: (i) => _tab.animateTo(i),
                  );
                },
              ),
            ),
            AnimatedBuilder(
              animation: _tab,
              builder: (context, _) {
                return _HomeSectionHeader(index: _tab.index);
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _RecipesTab(),
                  _ProgressTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Вкладки шапки: активная — лавандовая капсула с иконкой и текстом; неактивная — только иконка.
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
  const _HomeActiveTabPill({
    required this.onTap,
    required this.icon,
    required this.label,
  });

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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}

/// Заголовок и подзаголовок блока под вкладками (меняются вместе с табом).
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
            isRecipes ? 'Твои лекарство' : 'Твой прогресс',
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

/// Иконка флакона с «+» как в дизайне (кольцо вокруг «+» под цвет фона капсулы).
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
                border: Border.all(color: ringColor ?? MediColors.tabActiveLavender, width: 1.5),
              ),
              child: const Icon(Icons.add, size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipesTab extends StatelessWidget {
  const _RecipesTab();

  static const _cards = [
    _MedCardData('Витамин С', '22 дня', '19:00 – 20:00', Color(0xFFFFB3B8)),
    _MedCardData('Витамин С', '10 дней', '19:00 – 20:00', Color(0xFFFFF0B8)),
    _MedCardData('Витамин С', '3 дня', '19:00 – 20:00', Color(0xFFB8ECF0)),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        ..._cards.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MedicationCard(data: c),
            )),
      ],
    );
  }
}

class _MedCardData {
  const _MedCardData(this.title, this.duration, this.time, this.color);
  final String title;
  final String duration;
  final String time;
  final Color color;
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.data});

  final _MedCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.45),
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
                  data.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.duration,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.time,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 88,
            alignment: Alignment.center,
            child: Icon(Icons.medication_liquid_rounded, size: 56, color: Colors.white.withOpacity(0.95)),
          ),
        ],
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: MediColors.accentPurple,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: MediColors.accentPurple.withOpacity(0.35),
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
                    const Text(
                      'Лечения Грипп',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ваш еженедельный отчет',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
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
                      value: 0.65,
                      strokeWidth: 7,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        '65%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
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
          BoxShadow(color: color.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
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
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
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
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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
