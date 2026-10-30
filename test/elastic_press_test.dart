import 'package:assetly/src/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('按住一会儿再松手仍然算一次点击', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElasticPress(
              maxGrowth: 7,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(width: 88, height: 56, child: Text('目标')),
              ),
            ),
          ),
        ),
      ),
    );

    // A real finger rests well past the first frame; the swell must not
    // rebuild the tree under it or the tap is dropped.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('目标')),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 124));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
