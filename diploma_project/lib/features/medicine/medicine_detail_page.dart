import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';
import 'sellers_page.dart';

class MedicineDetailPage extends StatefulWidget {
  const MedicineDetailPage({super.key, required this.id});

  final String id;

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  Map<String, dynamic>? _m;
  Map<String, dynamic>? _safety;
  bool _loading = true;

  static const _pageBg = Color(0xFFF5F5F7);
  static const _subtitlePurple = Color(0xFF7B68EE);
  static const _bodyGray = Color(0xFF4F4F4F);
  static const _divider = Color(0xFFE0E0E0);
  static const _warningRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthController>();
    setState(() => _loading = true);
    try {
      final d = await auth.client.dio.get<Map<String, dynamic>>('/medicines/${widget.id}');
      Map<String, dynamic>? s;
      try {
        final path = auth.isLoggedIn
            ? '/medicines/${widget.id}/safety'
            : '/medicines/${widget.id}/safety/public';
        final sr = await auth.client.dio.get<Map<String, dynamic>>(path);
        s = sr.data;
      } catch (_) {}
      setState(() {
        _m = d.data;
        _safety = s;
        _loading = false;
      });
    } on DioException {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _pageBg,
        body: const Center(child: CircularProgressIndicator(color: MediColors.accentPurple)),
      );
    }
    if (_m == null) {
      return Scaffold(
        backgroundColor: _pageBg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackRow(onBack: () => context.pop()),
              const Expanded(child: Center(child: Text('Не найдено'))),
            ],
          ),
        ),
      );
    }

    final m = _m!;
    final name = m['name'] as String? ?? '';
    final indication = m['indication_label'] as String?;
    final imageUrl = m['image_url'] as String?;
    final dosage = (m['dosage'] as String?)?.trim() ?? '';
    final instructions = (m['instructions'] as String?)?.trim() ?? '';
    final restrictions = (m['restrictions'] as String?)?.trim() ?? '';
    final description = (m['description'] as String?)?.trim() ?? '';

    final rec = _safety?['is_recommended'] == true;
    final showSafety = _safety != null;

    return Scaffold(
      backgroundColor: _pageBg,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverSafeArea(
                  bottom: false,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _BackRow(onBack: () => context.pop()),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            color: Color(0xFF000000),
                          ),
                        ),
                        if (indication != null && indication.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            indication,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _subtitlePurple,
                              height: 1.25,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _ProductImageCard(imageUrl: imageUrl),
                        const SizedBox(height: 20),
                        if (showSafety) ...[
                          Text(
                            rec ? 'Рекомендуется к применению' : 'Не рекомендуется к применению',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: rec ? MediColors.success : _warningRed,
                              height: 1.3,
                            ),
                          ),
                          if (_safety!['warning_message'] != null &&
                              (_safety!['warning_message'] as String).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _safety!['warning_message'] as String,
                              style: const TextStyle(fontSize: 14, color: _bodyGray, height: 1.35),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          title: dosage.isNotEmpty ? 'Приём: $dosage' : 'Приём: по назначению врача',
                          subtitle: instructions.isNotEmpty
                              ? instructions
                              : 'Следуйте инструкции и рекомендациям специалиста.',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, thickness: 1, color: _divider),
                        ),
                        _DetailRow(
                          icon: Icons.water_drop_outlined,
                          title: 'Нужно принимать с водой',
                          subtitle: restrictions.isNotEmpty
                              ? restrictions
                              : 'Запивайте водой; не сочетайте с газировкой и алкоголем без совета врача.',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, thickness: 1, color: _divider),
                        ),
                        _DetailRow(
                          icon: Icons.medication_liquid_outlined,
                          title: 'Описание',
                          subtitle: description.isNotEmpty
                              ? description
                              : 'Подробное описание уточняйте в официальной инструкции к препарату.',
                          subtitleIsBody: true,
                        ),
                        if (_safety != null && (_safety!['alternatives'] as List?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 28),
                          const Text(
                            'Безопасные аналоги',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: MediColors.accentPurple,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 118,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: (_safety!['alternatives'] as List).length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (c, i) {
                                final a = (_safety!['alternatives'] as List)[i] as Map<String, dynamic>;
                                return GestureDetector(
                                  onTap: () => context.pushReplacement('/medicine/${a['id']}'),
                                  child: Container(
                                    width: 132,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: MediColors.success.withValues(alpha: 0.45)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.medication_rounded,
                                            size: 28, color: MediColors.accentPurple.withValues(alpha: 0.7)),
                                        const Spacer(),
                                        Text(
                                          a['name'] as String? ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                        Text(
                                          '${a['price']} ₸',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: MediColors.textMuted.withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () => showSellersBottomSheet(
                        context,
                        widget.id,
                        medicineName: name,
                        imageUrl: imageUrl,
                        onOfferSelected: (sel) => context.push('/checkout/delivery', extra: sel),
                      ),
                  style: FilledButton.styleFrom(
                    backgroundColor: MediColors.accentPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  child: const Text('Купить'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF000000)),
      label: const Text(
        'Назад',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF000000),
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        alignment: Alignment.centerLeft,
        foregroundColor: Colors.black,
      ),
    );
  }
}

class _ProductImageCard extends StatelessWidget {
  const _ProductImageCard({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280, maxHeight: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 1.15,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? _mediImage(imageUrl!, BoxFit.contain, _placeholder())
              : _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Icon(
      Icons.medication_rounded,
      size: 88,
      color: MediColors.accentPurple.withValues(alpha: 0.35),
    );
  }
}

Widget _mediImage(String url, BoxFit fit, Widget placeholder) {
  if (url.startsWith('assets/')) {
    return Image.asset(url, fit: fit, errorBuilder: (_, __, ___) => placeholder);
  }
  return Image.network(url, fit: fit, errorBuilder: (_, __, ___) => placeholder);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleIsBody = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool subtitleIsBody;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26, color: const Color(0xFF000000)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: subtitleIsBody ? 16 : 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF000000),
                  height: 1.25,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: subtitleIsBody ? 8 : 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: subtitleIsBody ? 14 : 14,
                    fontWeight: FontWeight.w400,
                    color: subtitleIsBody ? _MedicineDetailPageState._bodyGray : const Color(0xFF333333),
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
