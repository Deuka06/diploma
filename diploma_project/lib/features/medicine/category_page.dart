import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';

/// Страница каталога по категории — макет: заголовок, подзаголовок, сетка 3×N.
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _err;

  static const _subtitlePurple = Color(0xFF9381FF);

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
        '/medicines',
        queryParameters: {'category': widget.categoryId},
      );
      setState(() {
        _items = res.data ?? [];
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _err = e.message ?? 'Жүктеу қатесі';
        _loading = false;
      });
    }
  }

  String get _pageTitle {
    switch (widget.categoryId) {
      case 'teeth':
        return 'Тіс дәрісі';
      case 'heart':
        return 'Жүрек дәрісі';
      case 'head':
        return 'Бас дәрісі';
      default:
        return 'Дәрілер';
    }
  }

  String get _categorySubtitle {
    switch (widget.categoryId) {
      case 'teeth':
        return 'Тіс санаты';
      case 'heart':
        return 'Жүрек санаты';
      case 'head':
        return 'Бас санаты';
      default:
        return 'Санат';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: TextButton.icon(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: MediColors.text.withValues(alpha: 0.85),
                ),
                label: Text(
                  'Артқа',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MediColors.text.withValues(alpha: 0.85),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: MediColors.text,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pageTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _categorySubtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _subtitlePurple,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: MediColors.accentPurple),
                    )
                  : _err != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(_err!, textAlign: TextAlign.center),
                          ),
                        )
                      : RefreshIndicator(
                          color: MediColors.accentPurple,
                          onRefresh: _load,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.66,
                            ),
                            itemCount: _items.length,
                            itemBuilder: (c, i) {
                              final m = _items[i] as Map<String, dynamic>;
                              final id = m['id'] as String? ?? '';
                              final name = m['name'] as String? ?? '';
                              final imageUrl = m['image_url'] as String?;
                              return _MedicineGridCard(
                                name: name,
                                imageUrl: imageUrl,
                                onTap: () => context.push('/medicine/$id'),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineGridCard extends StatelessWidget {
  const _MedicineGridCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Дәрі',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF000000),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Icon(
      Icons.medication_rounded,
      size: 40,
      color: MediColors.accentPurple.withValues(alpha: 0.4),
    );
  }
}
