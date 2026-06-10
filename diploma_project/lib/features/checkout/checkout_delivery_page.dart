import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/medi_theme.dart';
import 'checkout_selection.dart';

class CheckoutDeliveryPage extends StatelessWidget {
  const CheckoutDeliveryPage({super.key, required this.selection});

  final CheckoutSelection selection;

  static const _pageBg = Color(0xFFF5F5F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Жеткізу әдісі',
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
                  Text(
                    'Тапсырыс 1 (${selection.sellerName})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                    child: Center(
                      child: _CheckoutProductThumb(
                        imageUrl: selection.imageUrl,
                        name: selection.medicineName,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Жеткізу',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selection.deliverySubtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.3,
                                    color: MediColors.textMuted.withValues(alpha: 0.95),
                                  ),
                                ),
                              ],
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
                  onPressed: () => context.push('/checkout/payment', extra: selection),
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

class _CheckoutProductThumb extends StatelessWidget {
  const _CheckoutProductThumb({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    const h = 120.0;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: h,
          child: _mediImage(imageUrl!, BoxFit.contain, _Placeholder(name: name, height: h)),
        ),
      );
    }
    return _Placeholder(name: name, height: h);
  }
}

Widget _mediImage(String url, BoxFit fit, Widget placeholder) {
  if (url.startsWith('assets/')) {
    return Image.asset(url, fit: fit, errorBuilder: (_, __, ___) => placeholder);
  }
  return Image.network(url, fit: fit, errorBuilder: (_, __, ___) => placeholder);
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.name, required this.height});

  final String name;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: MediColors.textMuted.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
