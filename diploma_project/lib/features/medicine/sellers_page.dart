import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';
import '../checkout/checkout_selection.dart';

/// Модальное окно «Продавцы» поверх карточки препарата (макет: bottom sheet с ручкой).
Future<void> showSellersBottomSheet(
  BuildContext context,
  String medicineId, {
  required String medicineName,
  String? imageUrl,
  required void Function(CheckoutSelection selection) onOfferSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) {
      final h = MediaQuery.sizeOf(ctx).height;
      return SizedBox(
        height: h * 0.92,
        child: _SellersOffersPanel(
          medicineId: medicineId,
          medicineName: medicineName,
          imageUrl: imageUrl,
          onOfferSelected: onOfferSelected,
        ),
      );
    },
  );
}

class _SellersOffersPanel extends StatefulWidget {
  const _SellersOffersPanel({
    required this.medicineId,
    required this.medicineName,
    this.imageUrl,
    required this.onOfferSelected,
  });

  final String medicineId;
  final String medicineName;
  final String? imageUrl;
  final void Function(CheckoutSelection selection) onOfferSelected;

  @override
  State<_SellersOffersPanel> createState() => _SellersOffersPanelState();
}

class _SellersOffersPanelState extends State<_SellersOffersPanel> {
  List<dynamic> _rows = [];
  bool _loading = true;
  String? _err;
  /// null — все; иначе query tag для API: express | today
  String? _filterTag;

  static const _divider = Color(0xFFE8E8ED);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthController>();
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final res = await auth.client.dio.get<List<dynamic>>(
        '/medicines/${widget.medicineId}/offers',
        queryParameters: {
          if (_filterTag != null) 'tag': _filterTag,
        },
      );
      setState(() {
        _rows = res.data ?? [];
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _err = e.message ?? 'Жүктеу қатесі';
        _loading = false;
      });
    }
  }

  void _setFilter(String? tag) {
    setState(() => _filterTag = _filterTag == tag ? null : tag);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Сатушылар',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Жеткізу',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        color: const Color(0xFF3A3A3C),
                      ),
                    ),
                    const SizedBox(width: 18),
                    _FilterChipPill(
                      label: 'Express, 3 сағатта',
                      selected: _filterTag == 'express',
                      onTap: () => _setFilter('express'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipPill(
                      label: 'Бүгін',
                      selected: _filterTag == 'today',
                      onTap: () => _setFilter('today'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: MediColors.accentPurple))
              : _err != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_err!)))
                  : _rows.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _filterTag != null
                                      ? 'Таңдалған сүзгі бойынша сатушылар жоқ.'
                                      : 'Бұл препарат бойынша ұсыныстар әзірше жоқ.\nІске қосыңыз: PYTHONPATH=. python scripts/seed_medicines.py',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: MediColors.textMuted.withValues(alpha: 0.9),
                                    height: 1.4,
                                    fontSize: 15,
                                  ),
                                ),
                                if (_filterTag != null) ...[
                                  const SizedBox(height: 20),
                                  FilledButton(
                                    onPressed: () {
                                      setState(() => _filterTag = null);
                                      _load();
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: MediColors.accentPurple,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: const Text('Барлығын көрсету'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          itemCount: _rows.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: _divider),
                          itemBuilder: (c, i) {
                            final o = _rows[i] as Map<String, dynamic>;
                            final s = o['seller'] as Map<String, dynamic>;
                            final name = s['name'] as String? ?? '';
                            final rating = (s['rating'] as num?)?.toDouble() ?? 0;
                            final reviews = (s['review_count'] as num?)?.toInt() ?? 0;
                            final price = (o['price'] as num?)?.toDouble() ?? 0;
                            final delivery = o['delivery_text'] as String? ?? '';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: _SellerRow(
                                name: name,
                                rating: rating,
                                reviewCount: reviews,
                                price: price,
                                deliveryText: delivery,
                                onSelect: () {
                                  final sel = CheckoutSelection(
                                    medicineId: widget.medicineId,
                                    medicineName: widget.medicineName,
                                    imageUrl: widget.imageUrl,
                                    sellerName: name,
                                    price: price,
                                    deliveryText: delivery,
                                  );
                                  Navigator.of(context).pop();
                                  widget.onOfferSelected(sel);
                                },
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _borderIdle = Color(0xFFDCDCE0);
  static const _borderSelected = Color(0xFFAEAEB2);
  static const _chipText = Color(0xFF3C3C3C);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF2F2F7) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _borderSelected : _borderIdle,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: _chipText,
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerRow extends StatelessWidget {
  const _SellerRow({
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.deliveryText,
    required this.onSelect,
  });

  final String name;
  final double rating;
  final int reviewCount;
  final double price;
  final String deliveryText;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor().clamp(0, 5);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF000000),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ...List.generate(5, (i) {
                    final filled = i < fullStars;
                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: filled ? MediColors.accentPurple : const Color(0xFFE0E0E0),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$reviewCount пікір',
                      style: TextStyle(
                        fontSize: 13,
                        color: MediColors.textMuted.withValues(alpha: 0.95),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${price.toStringAsFixed(0)} тг',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF000000),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      size: 18,
                      color: MediColors.text.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deliveryText,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: MediColors.text.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: FilledButton(
            onPressed: onSelect,
            style: FilledButton.styleFrom(
              backgroundColor: MediColors.accentPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            child: const Text('Таңдау'),
          ),
        ),
      ],
    );
  }
}
