import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/medi_theme.dart';
import 'chat_history_storage.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
    required this.at,
  });

  final bool isUser;
  final String text;
  final DateTime at;
}

/// Чат с ИИ: вёрстка по макету MEDI, отправка на POST /chat/message.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scroll = ScrollController();
  final _textCtrl = TextEditingController();
  final _timeFmt = DateFormat('HH:mm');
  final List<_ChatMessage> _messages = [];
  bool _sending = false;

  static _ChatMessage _welcome() {
    return _ChatMessage(
      isUser: false,
      text:
          'Сәлеметсіз бе! Мен MEDI қолданбасының ЖИ негізіндегі көмекшісімін. Қолданба немесе денсаулық туралы жалпы сұрақтар қойыңыз — бұл дәрігердің орнын баспайды.',
      at: DateTime.now(),
    );
  }

  @override
  void initState() {
    super.initState();
    // Не блокируем UI ожиданием SharedPreferences (на iOS иногда долго / редко зависает канал).
    _messages.add(_welcome());
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreHistory());
  }

  Future<void> _restoreHistory() async {
    try {
      final rows = await ChatHistoryStorage.load()
          .timeout(const Duration(seconds: 5), onTimeout: () => <Map<String, dynamic>>[]);
      if (!mounted) return;
      if (rows.isEmpty) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(_rowsToMessages(rows));
        if (_messages.isEmpty) {
          _messages.add(_welcome());
        }
      });
    } catch (e, st) {
      assert(() {
        debugPrint('ChatHistoryStorage.load: $e\n$st');
        return true;
      }());
    }
  }

  List<_ChatMessage> _rowsToMessages(List<Map<String, dynamic>> rows) {
    final out = <_ChatMessage>[];
    for (final r in rows) {
      try {
        final at = DateTime.tryParse(r['at'] as String? ?? '');
        out.add(
          _ChatMessage(
            isUser: r['isUser'] == true || r['isUser'] == 1,
            text: (r['text'] as String?) ?? '',
            at: at ?? DateTime.now(),
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  /// Реплики до текущего сообщения пользователя (для контекста модели на сервере).
  List<Map<String, String>> _historyForApiBeforeLastUser() {
    if (_messages.length < 2) return [];
    final out = <Map<String, String>>[];
    for (var i = 0; i < _messages.length - 1; i++) {
      final m = _messages[i];
      out.add({
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      });
    }
    return out;
  }

  void _persistMessages() {
    final rows = _messages
        .map(
          (m) => {
            'isUser': m.isUser,
            'text': m.text,
            'at': m.at.toIso8601String(),
          },
        )
        .toList();
    unawaited(ChatHistoryStorage.save(rows));
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Тарихты тазалау?'),
        content: const Text('Барлық хабарламалар қайтарымсыз жойылады.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Болдырмау'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Тазалау'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ChatHistoryStorage.clear();
    setState(() {
      _messages
        ..clear()
        ..add(_welcome());
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final raw = _textCtrl.text.trim();
    if (raw.isEmpty || _sending) return;

    final auth = context.read<AuthController>();
    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(isUser: true, text: raw, at: DateTime.now()));
      _textCtrl.clear();
    });
    _scrollToEnd();

    final history = _historyForApiBeforeLastUser();

    try {
      final res = await auth.client.dio.post<Map<String, dynamic>>(
        '/chat/message',
        data: {
          'message': raw,
          'history': history
              .map((e) => {'role': e['role'], 'content': e['content']})
              .toList(),
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      final reply = res.data?['reply'] as String? ?? '';
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: reply.isEmpty ? 'Бос жауап' : reply, at: DateTime.now()));
      });
      _persistMessages();
      _scrollToEnd();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = dioErrorMessage(e) ?? 'Желі қатесі';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: 'Жауап алу мүмкін болмады. Қайталап көріңіз.', at: DateTime.now()));
      });
      _persistMessages();
      _scrollToEnd();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Чат',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: MediColors.chatBubbleText,
                        ),
                  ),
                  IconButton(
                    onPressed: _clearHistory,
                    tooltip: 'Тарихты тазалау',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: MediColors.chatTimestamp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return _ChatBubbleRow(message: m, timeFmt: _timeFmt);
              },
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Тіркемелер кейінірек қосылады')),
                      ),
                      icon: Icon(Icons.attach_file_rounded, color: MediColors.greetingPurple.withValues(alpha: 0.9)),
                    ),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F8),
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
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            child: TextField(
                              controller: _textCtrl,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              cursorColor: MediColors.greetingPurple,
                              style: const TextStyle(
                                fontSize: 16,
                                color: MediColors.text,
                                height: 1.25,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Жазыңыз...',
                                hintStyle: TextStyle(
                                  color: MediColors.chatTimestamp,
                                  fontSize: 16,
                                ),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.fromLTRB(18, 12, 4, 12),
                                suffixIcon: Icon(
                                  Icons.nightlight_round,
                                  size: 22,
                                  color: MediColors.greetingPurple.withValues(alpha: 0.45),
                                ),
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: MediColors.bottomNavPill,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: _sending ? null : _send,
                        borderRadius: BorderRadius.circular(24),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubbleRow extends StatelessWidget {
  const _ChatBubbleRow({required this.message, required this.timeFmt});

  final _ChatMessage message;
  final DateFormat timeFmt;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr = timeFmt.format(message.at);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isUser ? MediColors.chatUserBubble : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 5),
                bottomRight: Radius.circular(isUser ? 5 : 18),
              ),
              border: isUser ? null : Border.all(color: MediColors.chatAiBorder, width: 1),
              boxShadow: isUser
                  ? null
                  : [
                      BoxShadow(
                        color: MediColors.chatAiBorder.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: MediColors.chatBubbleText,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: MediColors.chatTimestamp,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.done_all_rounded,
                              size: 16,
                              color: MediColors.greetingPurple.withValues(alpha: 0.75),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
