import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';
import 'src/data/app_database.dart';
import 'src/services/notification_service.dart';
import 'src/state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  final database = AppDatabase();
  await database.open();
  final notifications = NotificationService();
  await notifications.initialize();
  final controller = AppController(database, notifications);
  await controller.initialize();
  runApp(AssetlyApp(controller: controller));
}
