import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AiRecognizedItem {
  const AiRecognizedItem({
    required this.name,
    this.isMedicine = false,
    this.description = '',
    this.barcode = '',
    this.category = '生活日用',
    this.expiry = '',
    this.manufacturer = '',
    this.medicineType = 'internal',
    this.unit = '片',
    this.remainingQuantity = 1,
  });
  final bool isMedicine;
  final String name, description, barcode, category, expiry, manufacturer;
  final String medicineType, unit;
  final double remainingQuantity;
}

class AiService {
  final secure = const FlutterSecureStorage();

  Future<XFile?> pickCompressedImage() => ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 768,
    maxHeight: 768,
    imageQuality: 80,
  );

  Future<String> testConnection({
    required String endpoint,
    required String apiKey,
    required String model,
  }) async {
    if (endpoint.trim().isEmpty) throw Exception('请填写 API Endpoint');
    if (model.trim().isEmpty) throw Exception('请填写模型名称');
    if (apiKey.trim().isEmpty) throw Exception('请填写 API Key');
    final response = await http
        .post(
          _chatUri(endpoint),
          headers: {
            'Authorization': 'Bearer ${apiKey.trim()}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'model': model.trim(),
            'messages': [
              {'role': 'user', 'content': '请只回复 OK'},
            ],
            'max_tokens': 8,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_httpError('连接失败', response));
    }
    final content = _responseContent(response.body);
    return content.isEmpty ? '连接成功，模型已响应' : '连接成功：$content';
  }

  Future<AiRecognizedItem> recognize(
    XFile file, {
    required String endpoint,
    required String model,
  }) async {
    final key = await secure.read(key: 'ai_vision_api_key') ?? '';
    if (key.isEmpty) throw Exception('请先在设置中填写视觉模型 API Key');
    final bytes = await File(file.path).readAsBytes();
    final response = await http
        .post(
          _chatUri(endpoint),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'model': model.trim(),
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'text',
                    'text':
                        '识别图片中的家庭物品或药品。首先判断它应进入普通物品库还是家庭药箱。只返回一个 JSON 对象，不要使用 Markdown，字段为：record_type（只能是 item 或 medicine）、name、description、barcode、category、expiry、manufacturer、medicine_type、remaining_quantity、unit。药品、外用药、医疗制剂和保健药品使用 medicine；其他物品使用 item。category 从 数码家电、生活日用、服饰鞋包、家具家居、药品保健 中选择。medicine_type 从 internal、external、emergency、injection、inhaled、ophthalmic 中选择。expiry 使用 yyyy-MM-dd，无法识别的字段返回空字符串。',
                  },
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:image/jpeg;base64,${base64Encode(bytes)}',
                    },
                  },
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_httpError('AI 请求失败', response));
    }
    final content = _responseContent(response.body);
    return parseRecognition(content);
  }

  AiRecognizedItem parseRecognition(String rawContent) {
    var content = rawContent;
    content = content
        .replaceAll(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();
    if (content.isEmpty) {
      throw Exception('AI 返回内容为空，请检查模型是否支持图片输入');
    }
    final objectStart = content.indexOf('{');
    final objectEnd = content.lastIndexOf('}');
    if (objectStart >= 0 && objectEnd > objectStart) {
      content = content.substring(objectStart, objectEnd + 1);
    }
    late final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      data = decoded;
    } catch (_) {
      throw Exception('AI 返回的识别结果格式不正确，请重试或更换视觉模型');
    }
    final category = '${data['category'] ?? '生活日用'}';
    final recordType = '${data['record_type'] ?? data['item_type'] ?? ''}'
        .trim()
        .toLowerCase();
    final medicineType = '${data['medicine_type'] ?? 'internal'}';
    const medicineTypes = {
      'internal',
      'external',
      'emergency',
      'injection',
      'inhaled',
      'ophthalmic',
    };
    const medicineUnits = {'片', '粒', '袋', '支', '瓶', '盒', '毫升'};
    final rawUnit = '${data['unit'] ?? '片'}'.trim();
    final isMedicine =
        recordType == 'medicine' ||
        recordType == 'drug' ||
        recordType == '药品' ||
        category.contains('药');
    return AiRecognizedItem(
      name: '${data['name'] ?? (isMedicine ? '未命名药品' : '未命名物品')}',
      isMedicine: isMedicine,
      description: '${data['description'] ?? ''}',
      barcode: '${data['barcode'] ?? ''}',
      category: category,
      expiry: '${data['expiry'] ?? ''}',
      manufacturer: '${data['manufacturer'] ?? ''}',
      medicineType: medicineTypes.contains(medicineType)
          ? medicineType
          : 'internal',
      remainingQuantity: _asDouble(data['remaining_quantity'], fallback: 1),
      unit: medicineUnits.contains(rawUnit) ? rawUnit : '片',
    );
  }

  double _asDouble(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }

  Uri _chatUri(String endpoint) {
    final value = endpoint.trim().replaceAll(RegExp(r'/+$'), '');
    final normalized = value.endsWith('/chat/completions')
        ? value
        : '$value/chat/completions';
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw Exception('API Endpoint 格式不正确');
    }
    return uri;
  }

  String _responseContent(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return '${decoded['choices']?[0]?['message']?['content'] ?? ''}'.trim();
    } catch (_) {
      return '';
    }
  }

  String _httpError(String prefix, http.Response response) {
    var detail = '';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final error = decoded['error'];
      if (error is Map) detail = '${error['message'] ?? ''}'.trim();
    } catch (_) {
      detail = response.body.trim();
    }
    if (detail.length > 180) detail = '${detail.substring(0, 180)}…';
    return '$prefix：HTTP ${response.statusCode}${detail.isEmpty ? '' : ' · $detail'}';
  }
}
