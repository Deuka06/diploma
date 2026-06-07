import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';

/// 6 шагов после регистрации по макету: пол, возраст, вес, рост, аллергии, поздравление.
class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final _page = PageController();
  int _step = 0;
  static const _stepCount = 6;

  String _gender = 'male';
  int _age = 21;
  double _weightKg = 75;
  bool _weightLb = false;
  double _heightCm = 170;
  bool _heightFt = false;
  final Set<String> _allergies = {};
  bool _saving = false;

  static const _subtitle =
      'Это информация нужна чтобы улучшить применение приложения';

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _skipLater() async {
    setState(() => _saving = true);
    final auth = context.read<AuthController>();
    final err = await auth.patchProfile({'onboarding_completed': true});
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    context.go('/t/home');
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final auth = context.read<AuthController>();
    final err = await auth.patchProfile({
      'gender': _gender,
      'age': _age,
      'weight_kg': _weightKg,
      'height_cm': _heightCm,
      'allergy_types': _allergies.isEmpty ? <String>[] : _allergies.toList(),
      'onboarding_completed': true,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    context.go('/t/home');
  }

  void _continue() {
    if (_step < 4) {
      _page.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else if (_step == 4) {
      _page.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top + 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(_stepCount, (i) {
                final active = i <= _step;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < _stepCount - 1 ? 6 : 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 4,
                      decoration: BoxDecoration(
                        color: active ? MediColors.accentPurple : const Color(0xFFE8E8ED),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _GenderStep(
                  subtitle: _subtitle,
                  selected: _gender,
                  onSelect: (g) => setState(() => _gender = g),
                ),
                _AgeStep(subtitle: _subtitle, age: _age, onAge: (a) => setState(() => _age = a)),
                _WeightStep(
                  subtitle: _subtitle,
                  kg: _weightKg,
                  lbMode: _weightLb,
                  onKg: (v) => setState(() => _weightKg = v),
                  onToggleLb: (v) => setState(() => _weightLb = v),
                ),
                _HeightStep(
                  subtitle: _subtitle,
                  cm: _heightCm,
                  ftMode: _heightFt,
                  onCm: (v) => setState(() => _heightCm = v),
                  onToggleFt: (v) => setState(() => _heightFt = v),
                ),
                _AllergyStep(
                  subtitle: _subtitle,
                  selected: _allergies,
                  onToggle: (id) => setState(() {
                    if (_allergies.contains(id)) {
                      _allergies.remove(id);
                    } else {
                      _allergies.add(id);
                    }
                  }),
                ),
                const _CongratsStep(),
              ],
            ),
          ),
          _OnboardingFooter(
            bottomInset: bottom,
            step: _step,
            saving: _saving,
            onSkip: _skipLater,
            onContinue: _step < 5 ? _continue : null,
            onFinish: _step == 5 ? _finish : null,
          ),
        ],
      ),
    );
  }
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.bottomInset,
    required this.step,
    required this.saving,
    required this.onSkip,
    required this.onContinue,
    required this.onFinish,
  });

  final double bottomInset;
  final int step;
  final bool saving;
  final VoidCallback onSkip;
  final VoidCallback? onContinue;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final isLast = step == 5;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottomInset),
      color: MediColors.accentPurple,
      child: Row(
        children: [
          Expanded(
            child: isLast
                ? Text(
                    'Поздравляем',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  )
                : TextButton(
                    onPressed: saving ? null : onSkip,
                    child: Text(
                      'Сделать потом',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : (isLast ? onFinish : onContinue),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: MediColors.accentPurple,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MediColors.accentPurple),
                  )
                : Text(isLast ? 'Закончить' : 'Продолжить'),
          ),
        ],
      ),
    );
  }
}

class _GenderStep extends StatelessWidget {
  const _GenderStep({
    required this.subtitle,
    required this.selected,
    required this.onSelect,
  });

  final String subtitle;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Какой ваш пол?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: MediColors.accentPurple,
            ),
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: TextStyle(fontSize: 14, height: 1.4, color: MediColors.textMuted)),
          const SizedBox(height: 28),
          _GenderCard(
            label: 'Мужчина',
            icon: Icons.male_rounded,
            selected: selected == 'male',
            onTap: () => onSelect('male'),
            selectedStyle: true,
          ),
          const SizedBox(height: 12),
          _GenderCard(
            label: 'Женщина',
            icon: Icons.female_rounded,
            selected: selected == 'female',
            onTap: () => onSelect('female'),
            selectedStyle: false,
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.selectedStyle,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool selectedStyle;

  @override
  Widget build(BuildContext context) {
    final purple = selected && selectedStyle;
    final lavender = selected && !selectedStyle;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            color: purple
                ? MediColors.accentPurple
                : lavender
                    ? MediColors.tabActiveLavender
                    : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: lavender ? MediColors.accentPurple.withValues(alpha: 0.35) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 36,
                color: purple ? Colors.white : MediColors.accentPurple,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: purple ? Colors.white : MediColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeStep extends StatefulWidget {
  const _AgeStep({
    required this.subtitle,
    required this.age,
    required this.onAge,
  });

  final String subtitle;
  final int age;
  final ValueChanged<int> onAge;

  @override
  State<_AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<_AgeStep> {
  static final List<int> kAges = List.generate(90, (i) => i + 10);
  late final FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    final i = kAges.indexOf(widget.age);
    _ctrl = FixedExtentScrollController(initialItem: i >= 0 ? i : 11);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сколько вам лет?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: MediColors.accentPurple,
            ),
          ),
          const SizedBox(height: 10),
          Text(widget.subtitle, style: TextStyle(fontSize: 14, height: 1.4, color: MediColors.textMuted)),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(color: MediColors.accentPurple.withValues(alpha: 0.55), width: 2),
                      ),
                    ),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: _ctrl,
                  itemExtent: 48,
                  perspective: 0.003,
                  diameterRatio: 1.4,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) => widget.onAge(kAges[i]),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: kAges.length,
                    builder: (context, index) {
                      final a = kAges[index];
                      final sel = a == widget.age;
                      return Center(
                        child: Text(
                          '$a',
                          style: TextStyle(
                            fontSize: sel ? 28 : 22,
                            fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                            color: sel ? MediColors.text : MediColors.textMuted,
                          ),
                        ),
                      );
                    },
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

class _WeightStep extends StatelessWidget {
  const _WeightStep({
    required this.subtitle,
    required this.kg,
    required this.lbMode,
    required this.onKg,
    required this.onToggleLb,
  });

  final String subtitle;
  final double kg;
  final bool lbMode;
  final ValueChanged<double> onKg;
  final ValueChanged<bool> onToggleLb;

  @override
  Widget build(BuildContext context) {
    final display = lbMode ? (kg / 0.45359237) : kg;
    final label = lbMode ? '${display.round()} lb' : '${kg.round()} kg';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Какой ваш вес?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: MediColors.accentPurple,
            ),
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: TextStyle(fontSize: 14, height: 1.4, color: MediColors.textMuted)),
          const SizedBox(height: 20),
          _UnitToggle(
            left: 'KG',
            right: 'LB',
            leftSelected: !lbMode,
            onLeft: () => onToggleLb(false),
            onRight: () => onToggleLb(true),
          ),
          const Spacer(),
          Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Color(0xFF2D2D2D)),
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MediColors.accentPurple,
              inactiveTrackColor: const Color(0xFFE8E8ED),
              thumbColor: MediColors.accentPurple,
              overlayColor: MediColors.accentPurple.withValues(alpha: 0.15),
              trackHeight: 6,
            ),
            child: Slider(
              value: display.clamp(30.0, lbMode ? 330.0 : 150.0),
              min: lbMode ? 66 : 30,
              max: lbMode ? 330 : 150,
              divisions: lbMode ? 132 : 120,
              onChanged: (v) {
                if (lbMode) {
                  onKg(v * 0.45359237);
                } else {
                  onKg(v);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HeightStep extends StatelessWidget {
  const _HeightStep({
    required this.subtitle,
    required this.cm,
    required this.ftMode,
    required this.onCm,
    required this.onToggleFt,
  });

  final String subtitle;
  final double cm;
  final bool ftMode;
  final ValueChanged<double> onCm;
  final ValueChanged<bool> onToggleFt;

  @override
  Widget build(BuildContext context) {
    final totalIn = cm / 2.54;
    final ft = totalIn ~/ 12;
    final inch = (totalIn - ft * 12).round().clamp(0, 11);
    final label = ftMode ? "$ft'$inch\"" : '${cm.round()} cm';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Какой ваш рост?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: MediColors.accentPurple,
            ),
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: TextStyle(fontSize: 14, height: 1.4, color: MediColors.textMuted)),
          const SizedBox(height: 20),
          _UnitToggle(
            left: 'CM',
            right: 'FT',
            leftSelected: !ftMode,
            onLeft: () => onToggleFt(false),
            onRight: () => onToggleFt(true),
          ),
          const Spacer(),
          Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Color(0xFF2D2D2D)),
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MediColors.accentPurple,
              inactiveTrackColor: const Color(0xFFE8E8ED),
              thumbColor: MediColors.accentPurple,
              trackHeight: 6,
            ),
            child: Slider(
              value: cm.clamp(120, 220),
              min: 120,
              max: 220,
              divisions: 100,
              onChanged: onCm,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({
    required this.left,
    required this.right,
    required this.leftSelected,
    required this.onLeft,
    required this.onRight,
  });

  final String left;
  final String right;
  final bool leftSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: leftSelected ? MediColors.accentPurple : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onLeft,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      left,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: leftSelected ? Colors.white : MediColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: !leftSelected ? MediColors.accentPurple : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onRight,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      right,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: !leftSelected ? Colors.white : MediColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergyTileData {
  const _AllergyTileData(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

class _AllergyStep extends StatelessWidget {
  const _AllergyStep({
    required this.subtitle,
    required this.selected,
    required this.onToggle,
  });

  final String subtitle;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  static const _tiles = [
    _AllergyTileData('food', 'Пищевая аллергия', Icons.water_drop_outlined),
    _AllergyTileData('rhinitis', 'Аллергический ринит', Icons.air_rounded),
    _AllergyTileData('dermatitis', 'Аллергический дерматит', Icons.spa_outlined),
    _AllergyTileData('insect', 'Аллергия на насекомых', Icons.bug_report_outlined),
    _AllergyTileData('drug', 'Лекарственная аллергия', Icons.medication_outlined),
    _AllergyTileData('animal', 'Аллергия на животных', Icons.pets_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'У вас есть аллергия?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: MediColors.accentPurple,
            ),
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: TextStyle(fontSize: 14, height: 1.4, color: MediColors.textMuted)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: _tiles.map((t) {
                final sel = selected.contains(t.id);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onToggle(t.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: sel ? MediColors.tabActiveLavender : const Color(0xFFF7F7F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel ? MediColors.accentPurple : const Color(0xFFE8E8ED),
                          width: sel ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(t.icon, size: 32, color: sel ? MediColors.accentPurple : MediColors.text),
                          const SizedBox(height: 8),
                          Text(
                            t.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: sel ? MediColors.accentPurple : MediColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CongratsStep extends StatelessWidget {
  const _CongratsStep();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        children: [
          Text(
            'Поздравляю',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: MediColors.accentPurple,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Вы только что закончили настройку',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.4, color: MediColors.textMuted),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/1.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
