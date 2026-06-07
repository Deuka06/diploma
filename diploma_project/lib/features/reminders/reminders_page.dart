import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/medi_theme.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<Map<String, dynamic>> _reminders = [];
  bool _loading = true;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await NotificationService().init();
    await _loadReminders();
    await _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final pending = await NotificationService().getPendingNotifications();
    setState(() {
      _notificationsEnabled = pending.isNotEmpty;
    });
  }

  Future<void> _loadReminders() async {
    final auth = context.read<AuthController>();
    setState(() => _loading = true);
    try {
      final res = await auth.client.dio.get<List<dynamic>>('/reminders');
      setState(() {
        _reminders = (res.data ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } on DioException {
      setState(() => _loading = false);
    }
  }

  Future<void> _enableNotifications() async {
    final granted = await NotificationService().requestPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Параметрлерде хабарландыруларға рұқсат беріңіз')),
        );
      }
      return;
    }

    for (final reminder in _reminders) {
      if (reminder['is_active'] == true) {
        final timeStr = reminder['reminder_time'] as String? ?? '09:00:00';
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 9;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

        await NotificationService().scheduleReminder(
          reminderId: reminder['id'] as int,
          medicineName: reminder['medicine_name'] as String? ?? 'Дәрі',
          dosage: reminder['dosage'] as String?,
          hour: hour,
          minute: minute,
        );
      }
    }

    setState(() => _notificationsEnabled = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Хабарландырулар қосылды')),
      );
    }
  }

  Future<void> _disableNotifications() async {
    await NotificationService().cancelAllNotifications();
    setState(() => _notificationsEnabled = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Хабарландырулар өшірілді')),
      );
    }
  }

  Future<void> _toggleReminder(Map<String, dynamic> reminder, bool active) async {
    final auth = context.read<AuthController>();
    try {
      await auth.client.dio.patch<Map<String, dynamic>>(
        '/reminders/${reminder['id']}',
        data: {'is_active': active},
      );

      if (active && _notificationsEnabled) {
        final timeStr = reminder['reminder_time'] as String? ?? '09:00:00';
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 9;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

        await NotificationService().scheduleReminder(
          reminderId: reminder['id'] as int,
          medicineName: reminder['medicine_name'] as String? ?? 'Дәрі',
          dosage: reminder['dosage'] as String?,
          hour: hour,
          minute: minute,
        );
      } else {
        await NotificationService().cancelNotification(reminder['id'] as int);
      }

      await _loadReminders();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Қате')),
        );
      }
    }
  }

  Future<void> _deleteReminder(int id) async {
    final auth = context.read<AuthController>();
    try {
      await auth.client.dio.delete('/reminders/$id');
      await NotificationService().cancelNotification(id);
      await _loadReminders();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Қате')),
        );
      }
    }
  }

  Future<void> _showAddReminderDialog() async {
    final medicineCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Жаңа еске салу'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: medicineCtrl,
                decoration: const InputDecoration(
                  labelText: 'Дәрі атауы',
                  hintText: 'Мысалы: Парацетамол',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Дозасы',
                  hintText: 'Мысалы: 1 таблетка',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Уақыт'),
                trailing: TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                  child: Text(
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Болдырмау'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Қосу'),
            ),
          ],
        ),
      ),
    );

    if (result == true && medicineCtrl.text.trim().isNotEmpty && mounted) {
      final auth = context.read<AuthController>();
      try {
        final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
        await auth.client.dio.post<Map<String, dynamic>>(
          '/reminders',
          data: {
            'medicine_name': medicineCtrl.text.trim(),
            'dosage': dosageCtrl.text.trim(),
            'reminder_time': timeStr,
            'is_active': true,
          },
        );
        await _loadReminders();

        if (_notificationsEnabled) {
          await _enableNotifications();
        }
      } on DioException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Қате')),
          );
        }
      }
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '09:00';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Еске салулар'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _notificationsEnabled ? _disableNotifications : _enableNotifications,
            icon: Icon(
              _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off_outlined,
              color: _notificationsEnabled ? MediColors.accentPurple : Colors.grey,
            ),
            tooltip: _notificationsEnabled ? 'Хабарландыруларды өшіру' : 'Хабарландыруларды қосу',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MediColors.accentPurple))
          : _reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Еске салулар жоқ',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Дәрі қабылдау туралы еске салу қосыңыз',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReminders,
                  color: MediColors.accentPurple,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      final isActive = reminder['is_active'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? MediColors.accentPurple.withValues(alpha: 0.1)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.alarm,
                              color: isActive ? MediColors.accentPurple : Colors.grey,
                            ),
                          ),
                          title: Text(
                            reminder['medicine_name'] as String? ?? 'Дәрі',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.black : Colors.grey,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (reminder['dosage'] != null && (reminder['dosage'] as String).isNotEmpty)
                                Text(
                                  reminder['dosage'] as String,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              Text(
                                _formatTime(reminder['reminder_time'] as String?),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? MediColors.accentPurple : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: isActive,
                                onChanged: (val) => _toggleReminder(reminder, val),
                                activeTrackColor: MediColors.accentPurple.withValues(alpha: 0.5),
                                thumbColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return MediColors.accentPurple;
                                  }
                                  return Colors.grey;
                                }),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteReminder(reminder['id'] as int),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        backgroundColor: MediColors.accentPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
