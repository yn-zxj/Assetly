import 'package:assetly/src/data/models.dart';
import 'package:assetly/src/app.dart';
import 'package:assetly/src/data/app_database.dart';
import 'package:assetly/src/services/notification_service.dart';
import 'package:assetly/src/state/app_controller.dart';
import 'package:assetly/src/theme/assetly_theme.dart';
import 'package:assetly/src/ui/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  test('cost per day uses the full service period', () {
    final item = AssetItem(
      id: '1',
      name: 'Test asset',
      purchaseDate: DateTime.now()
          .subtract(const Duration(days: 9))
          .toIso8601String(),
      purchasePrice: 100,
    );
    expect(item.daysInService, 10);
    expect(item.dailyCost, closeTo(10, .01));
  });

  testWidgets('five primary screens fit a phone viewport', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    final controller = AppController(AppDatabase(), NotificationService());
    controller.items = [
      AssetItem(
        id: '1',
        name: 'MacBook Pro 16"',
        categoryName: '数码家电',
        locationPath: '主卧 > 升降工作台',
        purchaseDate: '2025-06-30',
        purchasePrice: 24999,
        barcode: '195949102431',
        icon: '💻',
      ),
      AssetItem(
        id: '2',
        name: '本月新增物品',
        categoryName: '生活日用',
        locationPath: '主卧',
        purchaseDate:
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-01',
        purchasePrice: 100,
        icon: '📦',
      ),
    ];
    controller.medicines = const [
      Medicine(
        id: 'm1',
        itemId: 'mi1',
        name: '布洛芬缓释胶囊',
        expiryDate: '2027-11-20',
        dosageInstructions: '饭后温水服用 1 粒',
        remainingQuantity: 14,
        isTaking: true,
        timeSlots: '08:00',
        locationPath: '客厅 > 家庭常备药箱',
      ),
    ];
    controller.categories = const [
      Category(id: 'c1', name: '数码家电', icon: '💻', color: '#18181B'),
    ];
    controller.locations = const [
      StorageLocation(id: 'l1', name: '主卧', fullPath: '主卧'),
    ];
    controller.loading = false;

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: AssetlyTheme.light(const Color(0xFF10B981)),
          home: const AppShell(),
        ),
      ),
    );
    expect(find.text('Assetly.'), findsOneWidget);
    expect(find.textContaining('星期'), findsOneWidget);
    expect(find.text('本月新增资产金额'), findsOneWidget);
    expect(find.text('¥ 100.00'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('提醒'));
    await tester.pumpAndSettle();
    expect(find.text('提醒与预警'), findsOneWidget);
    expect(find.text('目前没有提醒'), findsOneWidget);
    expect(tester.getSize(find.byType(BottomSheet)).width, 390);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text('点击查看完整统计'), findsNothing);
    await tester.tap(find.text('本月新增资产金额'));
    await tester.pumpAndSettle();
    expect(find.text('完整数据统计'), findsNothing);
    await tester.tap(find.text('近 6 个月'));
    await tester.pumpAndSettle();
    expect(find.text('完整数据统计'), findsOneWidget);
    expect(find.text('全部月份'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    for (final label in ['物品', '药箱', '空间', '设置']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '$label screen overflowed',
      );
      if (label == '物品') {
        await tester.tap(find.byTooltip('添加物品'));
        await tester.pumpAndSettle();
        expect(find.text('添加新物品'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
        await tester.tap(find.text('MacBook Pro 16"'));
        await tester.pumpAndSettle();
        expect(find.byIcon(LucideIcons.moreHorizontal), findsNothing);
        expect(find.text('删除资产'), findsOneWidget);
        await tester.tap(find.text('编辑资产'));
        await tester.pumpAndSettle();
        expect(find.text('编辑资产属性'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
      }
      if (label == '药箱') {
        expect(find.byIcon(LucideIcons.moreVertical), findsNothing);
        await tester.tap(find.text('布洛芬缓释胶囊').first);
        await tester.pumpAndSettle();
        expect(find.text('药品完整详情'), findsOneWidget);
        expect(find.text('编辑药品'), findsOneWidget);
        expect(find.text('删除药品'), findsOneWidget);
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('添加药品'));
        await tester.pumpAndSettle();
        expect(find.text('添加药品'), findsWidgets);
        expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
      }
      if (label == '空间') {
        expect(find.byTooltip('添加空间'), findsOneWidget);
        await tester.tap(find.byTooltip('添加空间'));
        await tester.pumpAndSettle();
        expect(find.text('添加收纳空间'), findsOneWidget);
        expect(find.text('空间图标'), findsOneWidget);
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('管理主卧'));
        await tester.pumpAndSettle();
        expect(find.text('修改空间'), findsOneWidget);
        expect(find.text('添加子空间'), findsOneWidget);
        expect(find.text('删除空间'), findsOneWidget);
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
      }
    }
  });
}
