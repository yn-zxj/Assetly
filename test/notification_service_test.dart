import 'package:assetly/src/data/models.dart';
import 'package:assetly/src/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

Medicine medicine({
  double remainingQuantity = 12,
  String dosageInstructions = '每日 2 次，每次 1 片',
  String unit = '片',
}) => Medicine(
  id: 'medicine-1',
  itemId: 'item-1',
  name: '测试药品',
  remainingQuantity: remainingQuantity,
  dosageInstructions: dosageInstructions,
  unit: unit,
);

void main() {
  group('medicationNotificationBody', () {
    test('展示当前库存和用药说明', () {
      expect(
        medicationNotificationBody(medicine()),
        '每日 2 次，每次 1 片 · 当前库存 12 片',
      );
    });

    test('小数库存不会被四舍五入', () {
      expect(
        medicationNotificationBody(medicine(remainingQuantity: 1.5)),
        contains('当前库存 1.5 片'),
      );
    });

    test('无用药说明时不会出现多余分隔符', () {
      expect(
        medicationNotificationBody(medicine(dosageInstructions: '  ')),
        '当前库存 12 片',
      );
    });
  });
}
