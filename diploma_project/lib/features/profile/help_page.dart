import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  List<dynamic> _faqs = [];
  bool _loading = true;
  int? _open;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthController>();
    setState(() => _loading = true);
    try {
      final res = await auth.client.dio.get<List<dynamic>>('/faqs');
      setState(() {
        _faqs = res.data ?? [];
        _loading = false;
      });
    } on DioException {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Помощь'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _faqs.length,
              itemBuilder: (c, i) {
                final f = _faqs[i] as Map<String, dynamic>;
                final open = _open == i;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: InkWell(
                    onTap: () => setState(() => _open = open ? null : i),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  f['question'] as String? ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Icon(open ? Icons.expand_less : Icons.expand_more),
                            ],
                          ),
                          if (open) ...[
                            const SizedBox(height: 8),
                            Text(
                              f['answer'] as String? ?? '',
                              style: const TextStyle(color: MediColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
