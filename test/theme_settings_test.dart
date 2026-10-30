import 'package:assetly/src/app.dart';
import 'package:assetly/src/data/app_database.dart';
import 'package:assetly/src/services/notification_service.dart';
import 'package:assetly/src/state/app_controller.dart';
import 'package:assetly/src/theme/assetly_theme.dart';
import 'package:assetly/src/ui/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Db extends AppDatabase {
  @override
  Future<String?> getSetting(String key) async => null;
}

void main() {
  testWidgets('theme page rows respond', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    final controller = AppController(_Db(), NotificationService());
    controller.loading = false;
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: AssetlyTheme.light(const Color(0xFF10B981)),
          home: AppShell(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('主题与外观'));
    await tester.pumpAndSettle();
    expect(find.text('深色'), findsOneWidget);
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    expect(controller.themeMode, ThemeMode.dark);
    expect(find.text('主题与外观'), findsOneWidget);
  });
}
