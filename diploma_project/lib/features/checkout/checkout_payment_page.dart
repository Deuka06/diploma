import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/medi_theme.dart';
import 'checkout_selection.dart';

class CheckoutPaymentPage extends StatelessWidget {
  const CheckoutPaymentPage({super.key, required this.selection});

  final CheckoutSelection selection;

  static const _pageBg = Color(0xFFF5F5F7);

  /// Демо-баланс карты по макету (без бэкенда).
  static const _demoCardBalance = '4500 тг';

  @override
  Widget build(BuildContext context) {
    final p = selection.priceLabel;
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Төлем',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                    child: Column(
                      children: [
                        _PriceRow(label: 'Тауар', value: p, boldValue: false),
                        const Divider(height: 24),
                        _PriceRow(label: 'Сатып алу сомасы', value: p, boldValue: false),
                        const Divider(height: 24),
                        _PriceRow(label: 'Төленетін сома', value: p, boldValue: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Төлем әдісі',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: MediColors.accentPurple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.credit_card_rounded,
                            size: 28,
                            color: MediColors.text.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Банк картасы',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF000000),
                              ),
                            ),
                          ),
                          Text(
                            _demoCardBalance,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: MediColors.textMuted.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Төлем (MVP): тапсырыс рәсімделді')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: MediColors.accentPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  child: const Text('Төлемге өту'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    required this.boldValue,
  });

  final String label;
  final String value;
  final bool boldValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: boldValue ? FontWeight.w800 : FontWeight.w500,
            color: const Color(0xFF000000),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: boldValue ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF000000),
          ),
        ),
      ],
    );
  }
}
