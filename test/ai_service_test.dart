import 'package:assetly/src/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = AiService();

  test('AI medicine result is routed to the medicine cabinet', () {
    final result = service.parseRecognition('''
      ```json
      {
        "record_type": "medicine",
        "name": "布洛芬缓释胶囊",
        "description": "饭后服用",
        "barcode": "690000000001",
        "category": "药品保健",
        "expiry": "2028-05-01",
        "manufacturer": "示例药业",
        "medicine_type": "internal",
        "remaining_quantity": 12,
        "unit": "粒"
      }
      ```
    ''');

    expect(result.isMedicine, isTrue);
    expect(result.name, '布洛芬缓释胶囊');
    expect(result.remainingQuantity, 12);
    expect(result.unit, '粒');
    expect(result.barcode, '690000000001');
  });

  test('AI item result stays in the ordinary item library', () {
    final result = service.parseRecognition(
      '识别结果：{"record_type":"item","name":"保温杯",'
      '"category":"生活日用","unit":"个"}',
    );

    expect(result.isMedicine, isFalse);
    expect(result.name, '保温杯');
  });

  test('Chinese medicine type and medicine category are accepted', () {
    final result = service.parseRecognition(
      '{"record_type":"药品","name":"碘伏",'
      '"category":"药品保健","medicine_type":"external"}',
    );

    expect(result.isMedicine, isTrue);
    expect(result.medicineType, 'external');
  });
}
