import 'package:flutter/material.dart';

import 'core/services/notification_service.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  _scheduleTestNotification();

  runApp(const MediRoot());
}

void _scheduleTestNotification() async {
  await NotificationService().scheduleDelayedNotification(
    id: 9999,
    title: 'Пора принимать таблетки!',
    body: 'Не забудьте принять лекарство по расписанию',
    delay: const Duration(seconds: 50),
  );
}
