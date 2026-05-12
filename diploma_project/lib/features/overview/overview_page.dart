import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/medi_theme.dart';

/// Обзор прогресса лечения по макету: шапка, карточки с градиентом, FAB «+», sheet «Добавить».
class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (ctx) => _AddTreatmentSheet(onClose: () => Navigator.of(ctx).pop()),
    );
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Привет, Медет!',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: MediColors.greetingPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ваш прогресс за последний месяц',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.notifications_rounded,
                      color: MediColors.accentPurple,
                      size: 26,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  const SizedBox(width: 2),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFFFC107),
                      child: Text('🐕', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _OverviewProgressCard(
                    title: 'Лечения Грипп',
                    subtext: 'Ваш еженедельный отчет',
                    dates: 'Начало 22.03 - Конец 29.03',
                    progress: 0.65,
                    ringStroke: 5,
                    trackAlpha: 0.28,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8B6CFF), Color(0xFF5B3FD4)],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _OverviewProgressCard(
                    title: 'Лечения Насморк',
                    subtext: 'Вы успешно завершили',
                    dates: 'Начало 11.02 - Конец 18.02',
                    progress: 1.0,
                    ringStroke: 8,
                    trackAlpha: 0.45,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF8A7A), Color(0xFFFF5E6B)],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _OverviewProgressCard(
                    title: 'Лечения Головная боль',
                    subtext: 'Вы успешно завершили',
                    dates: 'Начало 15.01 - Конец 23.01',
                    progress: 1.0,
                    ringStroke: 8,
                    trackAlpha: 0.45,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6BC4FF), Color(0xFF3A9FE8)],
                    ),
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

/// Волны на фоне карточки (макет).
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
  });

  final String title;
  final String subtext;
  final String dates;
  final double progress;
  final Gradient gradient;
  final double ringStroke;
  final double trackAlpha;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
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
                  waveColor: Colors.white.withValues(alpha: 0.14),
                ),
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
                          backgroundColor: Colors.white.withValues(alpha: trackAlpha),
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
    );
  }
}

class _AddTreatmentSheet extends StatefulWidget {
  const _AddTreatmentSheet({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_AddTreatmentSheet> createState() => _AddTreatmentSheetState();
}

class _AddTreatmentSheetState extends State<_AddTreatmentSheet> {
  final _disease = TextEditingController();
  final _period = TextEditingController();
  final _medicine = TextEditingController();

  static const _fieldFill = Color(0xFFE8EAF6);

  @override
  void dispose() {
    _disease.dispose();
    _period.dispose();
    _medicine.dispose();
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
              onTap: widget.onClose,
              behavior: HitTestBehavior.opaque,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.32),
                  ),
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
                            color: Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SheetField(
                          controller: _disease,
                          hint: 'Название болезни',
                          fillColor: _fieldFill,
                        ),
                        const SizedBox(height: 12),
                        _SheetField(
                          controller: _period,
                          hint: 'На какой срок',
                          fillColor: _fieldFill,
                        ),
                        const SizedBox(height: 12),
                        _SheetField(
                          controller: _medicine,
                          hint: 'Лекарство',
                          fillColor: _fieldFill,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: () {
                              final messenger = ScaffoldMessenger.of(context);
                              widget.onClose();
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Лечение добавлено (MVP)')),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: MediColors.accentPurple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
  });

  final TextEditingController controller;
  final String hint;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
