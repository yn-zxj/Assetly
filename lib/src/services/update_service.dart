import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:http/http.dart' as http;

class AppRelease {
  const AppRelease({
    required this.tagName,
    required this.version,
    required this.releaseUrl,
    required this.notes,
    required this.publishedAt,
    this.downloadUrl,
    this.downloadVariant,
  });

  final String tagName;
  final String version;
  final String releaseUrl;
  final String notes;
  final DateTime? publishedAt;
  final String? downloadUrl;
  final String? downloadVariant;
}

class UpdateService {
  UpdateService({http.Client? client, String? Function()? androidAbiProvider})
    : _client = client ?? http.Client(),
      _androidAbiProvider = androidAbiProvider ?? currentAndroidAbi;

  static const latestReleaseApi =
      'https://api.github.com/repos/yn-zxj/Assetly/releases/latest';
  final http.Client _client;
  final String? Function() _androidAbiProvider;

  Future<AppRelease> getLatestRelease() async {
    late final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse(latestReleaseApi),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2026-03-10',
              'User-Agent': 'Assetly-Update-Checker',
            },
          )
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw Exception('检查更新超时，请稍后重试');
    } catch (_) {
      throw Exception('无法连接 GitHub，请检查网络后重试');
    }

    if (response.statusCode == 404) {
      throw Exception('暂未找到可用的 GitHub Release');
    }
    if (response.statusCode == 403 || response.statusCode == 429) {
      throw Exception('GitHub 请求过于频繁，请稍后再试');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('检查更新失败：HTTP ${response.statusCode}');
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final tagName = '${json['tag_name'] ?? ''}'.trim();
    final releaseUrl = '${json['html_url'] ?? ''}'.trim();
    if (tagName.isEmpty || releaseUrl.isEmpty) {
      throw Exception('GitHub Release 数据不完整');
    }

    final assets = (json['assets'] as List? ?? const [])
        .whereType<Map>()
        .map((asset) => Map<String, dynamic>.from(asset))
        .toList();
    final deviceAbi = _androidAbiProvider();
    final apk = _selectApk(assets, deviceAbi);
    final downloadUrl = '${apk?['browser_download_url'] ?? ''}'.trim();
    final downloadVariant = _variantForAsset('${apk?['name'] ?? ''}');

    return AppRelease(
      tagName: tagName,
      version: normalizeVersion(tagName),
      releaseUrl: releaseUrl,
      downloadUrl: downloadUrl.isEmpty ? null : downloadUrl,
      downloadVariant: downloadVariant,
      notes: '${json['body'] ?? ''}'.trim(),
      publishedAt: DateTime.tryParse('${json['published_at'] ?? ''}'),
    );
  }

  static String normalizeVersion(String value) =>
      value.trim().replaceFirst(RegExp(r'^[vV]'), '').split('+').first;

  static String? currentAndroidAbi([Abi? abi]) {
    return switch (abi ?? Abi.current()) {
      Abi.androidArm64 => 'arm64-v8a',
      Abi.androidArm => 'armeabi-v7a',
      Abi.androidX64 => 'x86_64',
      _ => null,
    };
  }

  static Map<String, dynamic>? _selectApk(
    List<Map<String, dynamic>> assets,
    String? deviceAbi,
  ) {
    Map<String, dynamic>? find(String suffix) {
      for (final asset in assets) {
        if ('${asset['name']}'.toLowerCase().endsWith(suffix)) return asset;
      }
      return null;
    }

    if (deviceAbi != null) {
      final matched = find('android-$deviceAbi.apk');
      if (matched != null) return matched;
    }
    return find('android-universal.apk') ?? find('.apk');
  }

  static String? _variantForAsset(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('android-arm64-v8a.apk')) return 'ARM64 专用安装包';
    if (lower.endsWith('android-armeabi-v7a.apk')) return '32 位 ARM 专用安装包';
    if (lower.endsWith('android-x86_64.apk')) return 'x86_64 专用安装包';
    if (lower.endsWith('android-universal.apk')) return '通用安装包';
    return name.isEmpty ? null : 'Android 安装包';
  }

  static bool isNewerVersion(String latest, String current) {
    final latestVersion = _parseVersion(latest);
    final currentVersion = _parseVersion(current);
    if (latestVersion == null || currentVersion == null) return false;
    for (var index = 0; index < 3; index++) {
      if (latestVersion.numbers[index] != currentVersion.numbers[index]) {
        return latestVersion.numbers[index] > currentVersion.numbers[index];
      }
    }
    if (latestVersion.preRelease == currentVersion.preRelease) return false;
    if (currentVersion.preRelease != null && latestVersion.preRelease == null) {
      return true;
    }
    return false;
  }

  static ({List<int> numbers, String? preRelease})? _parseVersion(
    String value,
  ) {
    final match = RegExp(
      r'^[vV]?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+.*)?$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    return (
      numbers: [
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      ],
      preRelease: match.group(4),
    );
  }
}
