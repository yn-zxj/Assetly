import 'package:assetly/src/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('提示信息显示在页面顶端并自动消失', (tester) async {
    tester.view.padding = const FakeViewPadding(top: 30);
    addTearDown(() => tester.view.resetPadding());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showTopNotice(context, '操作完成'),
                  child: const Text('显示提示'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示提示'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final positioned = tester.widget<Positioned>(
      find.byKey(const ValueKey('top-notice')),
    );
    final logicalSafeTop =
        tester.view.padding.top / tester.view.devicePixelRatio;
    expect(positioned.top, logicalSafeTop + 80);
    expect(find.text('操作完成'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('操作完成'), findsNothing);
  });
}
