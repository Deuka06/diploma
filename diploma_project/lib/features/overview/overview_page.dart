import 'dart:math' as math;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  List<Map<String, dynamic>> _treatments = [];
  bool _loading = true;

  static const _gradients = [
    [Color(0xFF8B6CFF), Color(0xFF5B3FD4)],
    [Color(0xFFFF8A7A), Color(0xFFFF5E6B)],
    [Color(0xFF6BC4FF), Color(0xFF3A9FE8)],
    [Color(0xFF6BFF9F), Color(0xFF3AB85A)],
    [Color(0xFFFFBE6B), Color(0xFFFF8E3A)],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

  LinearGradient _gradient(int colorIndex) {
    final colors = _gradients[colorIndex.clamp(0, _gradients.length - 1)];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  void _openCheckInSheet(Map<String, dynamic> treatment) {
    final id = treatment['id'] as int;
    final currentProgress = (treatment['progress'] as num?)?.toDouble() ?? 0.0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      builder: (ctx) => _DailyCheckInSheet(
        treatmentName: treatment['disease_name'] as String? ?? '',
        currentProgress: currentProgress,
        onSubmit: (delta) async {
          Navigator.of(ctx).pop();
          await _patchProgress(id, currentProgress, delta);
        },
      ),
    );
  }

  Future<void> _patchProgress(int id, double current, double delta) async {
    final auth = context.read<AuthController>();
    final newProgress = (current + delta).clamp(0.0, 1.0);
    try {
      await auth.client.dio.patch<void>(
        '/treatments/$id/progress',
        data: {'progress': newProgress},
      );
      await _load();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Ошибка обновления')),
        );
      }
    }
  }

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (ctx) => _AddTreatmentSheet(
        onSubmit: (diseaseName, medicineName, durationDays) async {
          Navigator.of(ctx).pop();
          await _createTreatment(diseaseName, medicineName, durationDays);
        },
      ),
    );
  }

  Future<void> _createTreatment(
      String diseaseName, String? medicineName, int durationDays) async {
    final auth = context.read<AuthController>();
    final now = DateTime.now();
    final end = now.add(Duration(days: durationDays > 0 ? durationDays : 7));
    try {
      await auth.client.dio.post<void>(
        '/treatments',
        data: {
          'disease_name': diseaseName,
          if (medicineName != null && medicineName.isNotEmpty)
            'medicine_name': medicineName,
          'start_date': now.toIso8601String().split('T').first,
          'end_date': end.toIso8601String().split('T').first,
          'color_index': _treatments.length % _gradients.length,
        },
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Лечение добавлено')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Ошибка')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: MediColors.accentPurple,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: RefreshIndicator(
          color: MediColors.accentPurple,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Ваш прогресс за последний месяц',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: MediColors.accentPurple)),
                )
              else if (_treatments.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 60, 20, 0),
                  child: Center(
                    child: Text(
                      'Нет записей о лечении.\nНажмите + чтобы добавить.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MediColors.textMuted, fontSize: 15),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: _treatments.map((t) {
                      final colorIdx = (t['color_index'] as int?) ?? 0;
                      final progress =
                          (t['progress'] as num?)?.toDouble() ?? 0.0;
                      final startDate = _formatDate(t['start_date'] as String?);
                      final endDate = _formatDate(t['end_date'] as String?);
                      final isCompleted = t['is_completed'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _OverviewProgressCard(
                          title: t['disease_name'] as String? ?? '',
                          subtext: isCompleted
                              ? 'Вы успешно завершили'
                              : 'Нажмите для отчёта',
                          dates: 'Начало $startDate - Конец $endDate',
                          progress: progress,
                          ringStroke: isCompleted ? 8 : 5,
                          trackAlpha: isCompleted ? 0.45 : 0.28,
                          gradient: _gradient(colorIdx),
                          onTap: isCompleted ? null : () => _openCheckInSheet(t),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardWavePainter extends CustomPainter {
  _CardWavePainter({required this.waveColor});

  final Color waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (var row = 0; row < 9; row++) {
      final baseY = size.height * 0.08 + row * (size.height * 0.11);
      final path = Path();
      path.moveTo(0, baseY);
      const waveLen = 26.0;
      for (var x = 0.0; x <= size.width + waveLen; x += waveLen) {
        path.quadraticBezierTo(
          x + waveLen * 0.5,
          baseY + (row.isEven ? 5 : -5),
          x + waveLen,
          baseY,
        );
      }
      canvas.drawPath(path, paint);
    }

    final soft = Paint()
      ..color = waveColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;
    for (var row = 0; row < 6; row++) {
      final baseY = size.height * 0.22 + row * 18.0;
      final path = Path();
      path.moveTo(size.width * 0.4, baseY);
      for (var x = size.width * 0.4; x < size.width + 24; x += 24) {
        path.quadraticBezierTo(
          x + 12,
          baseY + 4 * math.sin(x * 0.12 + row),
          x + 24,
          baseY,
        );
      }
      canvas.drawPath(path, soft);
    }
  }

  @override
  bool shouldRepaint(covariant _CardWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}

class _OverviewProgressCard extends StatelessWidget {
  const _OverviewProgressCard({
    required this.title,
    required this.subtext,
    required this.dates,
    required this.progress,
    required this.gradient,
    required this.ringStroke,
    required this.trackAlpha,
    this.onTap,
  });

  final String title;
  final String subtext;
  final String dates;
  final double progress;
  final Gradient gradient;
  final double ringStroke;
  final double trackAlpha;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: gradient),
              child: CustomPaint(
                painter: _CardWavePainter(
                    waveColor: Colors.white.withValues(alpha: 0.14)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtext,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dates,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: ringStroke,
                          backgroundColor:
                              Colors.white.withValues(alpha: trackAlpha),
                          color: Colors.white,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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
    ));
  }
}

class _DailyCheckInSheet extends StatefulWidget {
  const _DailyCheckInSheet({
    required this.treatmentName,
    required this.currentProgress,
    required this.onSubmit,
  });

  final String treatmentName;
  final double currentProgress;
  final void Function(double delta) onSubmit;

  @override
  State<_DailyCheckInSheet> createState() => _DailyCheckInSheetState();
}

class _DailyCheckInSheetState extends State<_DailyCheckInSheet> {
  bool _tookMedicine = false;
  bool _feelingGood = false;
  bool _worsening = false;

  double get _delta {
    if (_worsening) return -0.15;
    double d = 0;
    if (_tookMedicine) d += 0.08;
    if (_feelingGood) d += 0.07;
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                widget.treatmentName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Ежедневный отчёт',
                style: TextStyle(fontSize: 14, color: MediColors.textMuted),
              ),
              const SizedBox(height: 20),
              _CheckItem(
                icon: Icons.medication_rounded,
                label: 'Принял(а) лекарства',
                color: MediColors.accentPurple,
                value: _tookMedicine,
                onChanged: (v) => setState(() {
                  _tookMedicine = v;
                  if (v) _worsening = false;
                }),
              ),
              const SizedBox(height: 10),
              _CheckItem(
                icon: Icons.sentiment_satisfied_rounded,
                label: 'Чувствую себя хорошо',
                color: const Color(0xFF3AB85A),
                value: _feelingGood,
                onChanged: (v) => setState(() {
                  _feelingGood = v;
                  if (v) _worsening = false;
                }),
              ),
              const SizedBox(height: 10),
              _CheckItem(
                icon: Icons.sentiment_very_dissatisfied_rounded,
                label: 'Ухудшение самочувствия',
                color: const Color(0xFFFF5E6B),
                value: _worsening,
                onChanged: (v) => setState(() {
                  _worsening = v;
                  if (v) {
                    _tookMedicine = false;
                    _feelingGood = false;
                  }
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: (_tookMedicine || _feelingGood || _worsening)
                      ? () => widget.onSubmit(_delta)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: MediColors.accentPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.1) : const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? color : const Color(0xFFE8E8ED),
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: value ? color : MediColors.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: value ? color : MediColors.text,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? color : const Color(0xFFD1D1D6),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTreatmentSheet extends StatefulWidget {
  const _AddTreatmentSheet({required this.onSubmit});

  final void Function(String diseaseName, String? medicineName, int durationDays)
      onSubmit;

  @override
  State<_AddTreatmentSheet> createState() => _AddTreatmentSheetState();
}

class _AddTreatmentSheetState extends State<_AddTreatmentSheet> {
  final _disease = TextEditingController();
  final _medicine = TextEditingController();
  final _period = TextEditingController();

  static const _fieldFill = Color(0xFFE8EAF6);

  @override
  void dispose() {
    _disease.dispose();
    _medicine.dispose();
    _period.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final h = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(color: Colors.black.withValues(alpha: 0.32)),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: bottomInset),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1D1D6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const Text(
                          'Добавить',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF000000)),
                        ),
                        const SizedBox(height: 20),
                        _SheetField(
                            controller: _disease,
                            hint: 'Название болезни',
                            fillColor: _fieldFill),
                        const SizedBox(height: 12),
                        _SheetField(
                            controller: _period,
                            hint: 'На какой срок (дней)',
                            fillColor: _fieldFill,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        _SheetField(
                            controller: _medicine,
                            hint: 'Лекарство (необязательно)',
                            fillColor: _fieldFill),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: () {
                              final disease = _disease.text.trim();
                              if (disease.isEmpty) return;
                              final days =
                                  int.tryParse(_period.text.trim()) ?? 7;
                              widget.onSubmit(
                                disease,
                                _medicine.text.trim().isNotEmpty
                                    ? _medicine.text.trim()
                                    : null,
                                days,
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: MediColors.accentPurple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              textStyle: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            child: const Text('Добавить'),
                          ),
                        ),
                      ],
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

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.hint,
    required this.fillColor,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final Color fillColor;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: MediColors.textMuted.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
