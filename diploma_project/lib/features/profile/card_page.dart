import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/medi_theme.dart';

class CardPage extends StatefulWidget {
  const CardPage({super.key});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  final _numberCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  static const _fieldFill = Color(0xFFF2F2F7);
  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9A56), Color(0xFFFF6B9D)],
  );

  @override
  void dispose() {
    _numberCtrl.dispose();
    _cvcCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Карта сақталды')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          Container(
            height: top + 64,
            decoration: const BoxDecoration(gradient: _gradient),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: BackButton(color: Colors.white, onPressed: () => context.pop()),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Карта қосу',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Карта нөмірін енгізіңіз',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF6B6B6B))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _numberCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberFormatter(),
                    ],
                    decoration: _dec('4400 4300 3000 22 33', _fieldFill),
                  ),
                  const SizedBox(height: 16),
                  const Text('CVC енгізіңіз',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF6B6B6B))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cvcCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: _dec('333', _fieldFill),
                  ),
                  const SizedBox(height: 16),
                  const Text('Мерзімін енгізіңіз',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF6B6B6B))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dateCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _DateFormatter(),
                    ],
                    decoration: _dec('04/22', _fieldFill),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: MediColors.accentPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      child: const Text('Сақтау'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint, Color fill) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: MediColors.textMuted.withValues(alpha: 0.85), fontSize: 16),
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      );
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) {
    final digits = val.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return val.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) {
    final digits = val.text;
    if (digits.length <= 2) return val;
    final str = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return val.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
