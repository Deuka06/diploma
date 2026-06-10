import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _err;

  static const _pageBg = Color(0xFFF5F5F7);

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
      final res = await auth.client.dio.get<List<dynamic>>('/orders');
      setState(() {
        _orders = res.data ?? [];
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _err = e.message ?? 'Жүктеу қатесі';
        _loading = false;
      });
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Күтуде';
      case 'confirmed':
        return 'Расталды';
      case 'processing':
        return 'Дайындалуда';
      case 'shipped':
        return 'Жолда';
      case 'delivered':
        return 'Жеткізілді';
      case 'cancelled':
        return 'Болдырылмады';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return MediColors.success;
      case 'cancelled':
        return MediColors.danger;
      default:
        return MediColors.accentPurple;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd.MM.yyyy, HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Сатып алу тарихы',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF000000)),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MediColors.accentPurple))
          : _err != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_err!, textAlign: TextAlign.center),
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'Әзірге тапсырыстар жоқ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF000000)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: MediColors.accentPurple,
                      onRefresh: _load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (c, i) {
                          final o = _orders[i] as Map<String, dynamic>;
                          final items = (o['items'] as List<dynamic>? ?? []);
                          final status = o['status'] as String? ?? '';
                          final total = (o['total_amount'] as num?)?.toDouble() ?? 0;
                          final createdAt = o['created_at'] as String? ?? '';
                          return Container(
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
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Тапсырыс №${o['id']}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF000000)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor(status)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(createdAt),
                                  style: TextStyle(fontSize: 12, color: MediColors.textMuted.withValues(alpha: 0.9)),
                                ),
                                const SizedBox(height: 12),
                                ...items.map((it) {
                                  final m = it as Map<String, dynamic>;
                                  final name = m['medicine_name'] as String? ?? '';
                                  final qty = m['quantity'] as int? ?? 1;
                                  final tp = (m['total_price'] as num?)?.toDouble() ?? 0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$name ×$qty',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
                                          ),
                                        ),
                                        Text(
                                          '${tp.toStringAsFixed(0)} тг',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF000000)),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Барлығы',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF000000)),
                                    ),
                                    Text(
                                      '${total.toStringAsFixed(0)} тг',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF000000)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
