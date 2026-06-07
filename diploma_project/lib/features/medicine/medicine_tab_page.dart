import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';

class MedicineTabPage extends StatefulWidget {
  const MedicineTabPage({super.key});

  @override
  State<MedicineTabPage> createState() => _MedicineTabPageState();
}

class _MedicineTabPageState extends State<MedicineTabPage> {
  List<dynamic> _items = [];
  List<dynamic> _cats = [];
  bool _loading = true;
  String? _err;
  final _q = TextEditingController();

  static const _pageBg = Color(0xFFF5F5F7);
  static const _searchBg = Color(0xFFEBEBF0);
  static const _bannerPink = Color(0xFFFF6B9D);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthController>();
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final dio = auth.client.dio;
      final cats = await dio.get<List<dynamic>>('/medicines/categories');
      final med = await dio.get<List<dynamic>>(
        '/medicines',
        queryParameters: {
          if (_q.text.trim().isNotEmpty) 'q': _q.text.trim(),
        },
      );
      setState(() {
        _cats = cats.data ?? [];
        _items = med.data ?? [];
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _err = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: RefreshIndicator(
        color: MediColors.accentPurple,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Давайте найдем лекарство',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: MediColors.accentPurple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SearchPill(
                        controller: _q,
                        onSubmit: _load,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Категорий',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: MediColors.accentPurple,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 124,
                child: _loading && _cats.isEmpty
                    ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: _cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (c, i) {
                          final m = _cats[i] as Map<String, dynamic>;
                          final id = m['id'] as String;
                          final label = m['label'] as String;
                          return _CategoryCard(
                            id: id,
                            label: label,
                            onTap: () => context.push('/category/$id'),
                          );
                        },
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _CovidBanner(
                  onLearnMore: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Материалы о профилактике — в разделе помощи')),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Лекарство для вас',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: MediColors.accentPurple,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            if (_err != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(_err!, style: const TextStyle(color: MediColors.danger)),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: _loading && _items.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: MediColors.accentPurple))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: _items.length.clamp(0, 24),
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (c, i) {
                          final m = _items[i] as Map<String, dynamic>;
                          return _ProductCard(
                            id: m['id'] as String? ?? '',
                            name: m['name'] as String? ?? '',
                            imageUrl: m['image_url'] as String?,
                            onTap: () => context.push('/medicine/${m['id']}'),
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

class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.controller,
    required this.onSubmit,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _MedicineTabPageState._searchBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: const InputDecorationTheme(
              filled: false,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          child: TextField(
            controller: controller,
            onSubmitted: (_) => onSubmit(),
            onChanged: (_) => onChanged(),
            cursorColor: MediColors.greetingPurple,
            style: const TextStyle(fontSize: 16, color: MediColors.text),
            decoration: InputDecoration(
              hintText: 'Искать',
              hintStyle: TextStyle(
                color: MediColors.textMuted.withValues(alpha: 0.85),
                fontSize: 16,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              suffixIcon: Icon(
                Icons.search_rounded,
                color: MediColors.greetingPurple.withValues(alpha: 0.75),
                size: 26,
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 48),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.id,
    required this.label,
    required this.onTap,
  });

  final String id;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color accent;
    late Widget glyph;
    switch (id) {
      case 'heart':
        bg = const Color(0xFFFFEBEE);
        accent = const Color(0xFFE53935);
        glyph = Icon(Icons.favorite_rounded, size: 40, color: accent);
        break;
      case 'teeth':
        bg = const Color(0xFFE3F2FD);
        accent = const Color(0xFF1E88E5);
        glyph = Icon(Icons.medication_rounded, size: 40, color: accent);
        break;
      case 'painkillers':
        bg = const Color(0xFFFFF3E0);
        accent = const Color(0xFFFF9800);
        glyph = Icon(Icons.healing_rounded, size: 40, color: accent);
        break;
      case 'vitamins':
        bg = const Color(0xFFE8F5E9);
        accent = const Color(0xFF4CAF50);
        glyph = Icon(Icons.local_pharmacy_rounded, size: 40, color: accent);
        break;
      case 'antibiotics':
        bg = const Color(0xFFE3F2FD);
        accent = const Color(0xFF2196F3);
        glyph = Icon(Icons.vaccines_rounded, size: 40, color: accent);
        break;
      case 'head':
      default:
        bg = const Color(0xFFF3E5F5);
        accent = MediColors.greetingPurple;
        glyph = Icon(Icons.psychology_rounded, size: 40, color: accent);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            glyph,
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: accent,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CovidBanner extends StatelessWidget {
  const _CovidBanner({required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 168,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Container(
              width: double.infinity,
              color: MediColors.accentPurple,
            ),
            Positioned(
              right: -24,
              bottom: -8,
              child: Icon(
                Icons.medical_services_rounded,
                size: 140,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              left: -30,
              top: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 80,
              top: 20,
              child: Transform.rotate(
                angle: 0.5,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 120, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Как защитить свою жизнь от COVID-19',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: _MedicineTabPageState._bannerPink,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: onLearnMore,
                      borderRadius: BorderRadius.circular(24),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        child: Text(
                          'Узнать больше',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 8,
              child: Icon(
                Icons.vaccines_rounded,
                size: 88,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  static const _localImages = {
    'paracetamol-500': 'assets/парацетамол.png',
    'ibuprofen-400': 'assets/ибупрофин.webp',
    'vitamin-d3': 'assets/д3.jpg',
    'omeprazole-20': 'assets/омепразол.png',
    'amoxicillin-500': 'assets/med1.png',
    'loratadine-10': 'assets/med2.png',
  };

  @override
  Widget build(BuildContext context) {
    final title = name.isNotEmpty ? name : 'Лекарство';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 138,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFF4),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: ColoredBox(
                color: Colors.white,
                child: _buildImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.2,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final localPath = _localImages[id];
    if (localPath != null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          localPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _productPlaceholder(),
        ),
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _mediImage(imageUrl!, BoxFit.contain, _productPlaceholder());
    }
    return _productPlaceholder();
  }

  Widget _productPlaceholder() {
    return Center(
      child: Icon(
        Icons.medication_rounded,
        size: 52,
        color: MediColors.accentPurple.withValues(alpha: 0.45),
      ),
    );
  }
}

Widget _mediImage(String url, BoxFit fit, Widget placeholder) {
  if (url.startsWith('assets/')) {
    return Image.asset(url, fit: fit, errorBuilder: (_, __, ___) => placeholder);
  }
  return Image.network(url, fit: fit, errorBuilder: (_, __, ___) => placeholder);
}
