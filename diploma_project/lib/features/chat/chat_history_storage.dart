import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Локальное сохранение истории чата между перезапусками приложения.
class ChatHistoryStorage {
  ChatHistoryStorage._();

  static const _key = 'medi_chat_messages_v1';

  static Future<List<Map<String, dynamic>>> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_key);
      if (s == null || s.isEmpty) return [];
      final decoded = jsonDecode(s);
      if (decoded is! List) return [];
      final out = <Map<String, dynamic>>[];
      for (final e in decoded) {
        if (e is Map) {
          out.add(Map<String, dynamic>.from(e));
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Map<String, dynamic>> rows) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(rows));
    } catch (_) {
      // не блокируем отправку сообщений из‑за сбоя записи
    }
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
