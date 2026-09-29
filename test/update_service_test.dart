import 'dart:convert';
import 'dart:ffi';

import 'package:assetly/src/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('UpdateService.isNewerVersion', () {
    test('正确比较语义化版本', () {
      expect(UpdateService.isNewerVersion('v1.3.4', '1.3.3'), isTrue);
      expect(UpdateService.isNewerVersion('1.4.0', '1.3.9'), isTrue);
      expect(UpdateService.isNewerVersion('2.0.0', '1.99.99'), isTrue);
      expect(UpdateService.isNewerVersion('1.3.3', '1.3.3'), isFalse);
      expect(UpdateService.isNewerVersion('1.3.2', '1.3.3'), isFalse);
    });

    test('正式版高于相同版本的预发布版', () {
      expect(UpdateService.isNewerVersion('1.3.4', '1.3.4-beta.1'), isTrue);
      expect(UpdateService.isNewerVersion('1.3.4-beta.2', '1.3.4'), isFalse);
    });
  });

  test('正确识别 Android APK 架构名称', () {
    expect(UpdateService.currentAndroidAbi(Abi.androidArm64), 'arm64-v8a');
    expect(UpdateService.currentAndroidAbi(Abi.androidArm), 'armeabi-v7a');
    expect(UpdateService.currentAndroidAbi(Abi.androidX64), 'x86_64');
    expect(UpdateService.currentAndroidAbi(Abi.macosArm64), isNull);
  });

  test('解析 GitHub Release 并优先选择当前设备架构 APK', () async {
    final client = MockClient((request) async {
      expect(request.headers['accept'], 'application/vnd.github+json');
      expect(request.headers['x-github-api-version'], '2026-03-10');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'tag_name': 'v1.4.0',
            'html_url': 'https://github.com/yn-zxj/Assetly/releases/tag/v1.4.0',
            'body': '更新说明',
            'published_at': '2026-09-29T08:00:00Z',
            'assets': [
              {
                'name': 'Assetly-v1.4.0-android-arm64-v8a.apk',
                'browser_download_url': 'https://example.com/arm64.apk',
              },
              {
                'name': 'Assetly-v1.4.0-android-universal.apk',
                'browser_download_url': 'https://example.com/universal.apk',
              },
            ],
          }),
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final release = await UpdateService(
      client: client,
      androidAbiProvider: () => 'arm64-v8a',
    ).getLatestRelease();

    expect(release.version, '1.4.0');
    expect(release.downloadUrl, 'https://example.com/arm64.apk');
    expect(release.downloadVariant, 'ARM64 专用安装包');
    expect(release.notes, '更新说明');
  });

  test('当前架构没有专用包时回退到通用 APK', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'tag_name': 'v1.4.0',
          'html_url': 'https://example.com/release',
          'assets': [
            {
              'name': 'Assetly-v1.4.0-android-universal.apk',
              'browser_download_url': 'https://example.com/universal.apk',
            },
          ],
        }),
        200,
      ),
    );

    final release = await UpdateService(
      client: client,
      androidAbiProvider: () => 'x86_64',
    ).getLatestRelease();

    expect(release.downloadUrl, 'https://example.com/universal.apk');
    expect(release.downloadVariant, '通用安装包');
  });
}
