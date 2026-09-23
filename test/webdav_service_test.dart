import 'package:assetly/src/services/webdav_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildWebDavUri', () {
    test('正确拼接服务器和中文远程路径', () {
      final uri = buildWebDavUri(
        'https://dav.jianguoyun.com/dav/',
        '/我的坚果云/assetly/assetly-backup.json',
      );

      expect(uri.host, 'dav.jianguoyun.com');
      expect(
        Uri.decodeComponent(uri.path),
        '/dav/我的坚果云/assetly/assetly-backup.json',
      );
    });

    test('识别缺少 com 的坚果云地址', () {
      expect(
        () => buildWebDavUri(
          'https://dav.jianguoyun./dav/',
          '/assetly-backup.json',
        ),
        throwsA(
          predicate(
            (error) => '$error'.contains('https://dav.jianguoyun.com/dav/'),
          ),
        ),
      );
    });
  });

  test('将 TLS 握手异常转换为可读提示', () {
    expect(
      friendlyWebDavError(Exception('HandshakeConnection terminated')),
      contains('TLS 安全连接失败'),
    );
  });
}
