import 'dart:convert';

import 'package:http/http.dart' as http;

Uri buildWebDavUri(String server, String path) {
  final value = server.trim();
  if (value.isEmpty) throw Exception('请填写服务器地址');
  final base = Uri.tryParse(value);
  if (base == null ||
      !base.hasAuthority ||
      base.host.isEmpty ||
      (base.scheme != 'https' && base.scheme != 'http')) {
    throw Exception('服务器地址无效，请填写完整的 http:// 或 https:// 地址');
  }
  final host = base.host.toLowerCase();
  if (host == 'dav.jianguoyun.' || host == 'dav.jianguoyun') {
    throw Exception('坚果云地址不完整，应为 https://dav.jianguoyun.com/dav/');
  }
  return Uri.parse(
    '${value.replaceAll(RegExp(r'/+$'), '')}/${path.trim().replaceAll(RegExp(r'^/+'), '')}',
  );
}

String friendlyWebDavError(Object error) {
  final message = '$error';
  if (message.contains('HandshakeException') ||
      message.contains('HandshakeConnection')) {
    return 'TLS 安全连接失败，请检查服务器域名和 HTTPS 证书';
  }
  if (message.contains('Failed host lookup') ||
      message.contains('No address associated')) {
    return '无法解析服务器地址，请检查域名和网络';
  }
  if (message.contains('TimeoutException')) {
    return '连接超时，请检查网络或服务器地址';
  }
  return message.replaceFirst('Exception: ', '');
}

class WebDavService {
  Map<String, String> _headers(String username, String password) => {
    'Authorization':
        'Basic ${base64Encode(utf8.encode('$username:$password'))}',
  };
  Uri _uri(String server, String path) => buildWebDavUri(server, path);

  Future<void> test(
    String server,
    String username,
    String password,
    String path,
  ) async {
    if (username.trim().isEmpty) throw Exception('请填写用户名');
    if (password.isEmpty) throw Exception('请填写密码');
    buildWebDavUri(server, path);
    try {
      var response = await _propfind(server, username, password, path);
      if (response.statusCode == 404) {
        final segments = path.split('/')..removeWhere((part) => part.isEmpty);
        if (segments.isNotEmpty) segments.removeLast();
        response = await _propfind(
          server,
          username,
          password,
          segments.isEmpty ? '/' : '/${segments.join('/')}/',
        );
      }
      if (response.statusCode != 200 && response.statusCode != 207) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('WebDAV 连接失败：${friendlyWebDavError(error)}');
    }
  }

  Future<http.StreamedResponse> _propfind(
    String server,
    String username,
    String password,
    String path,
  ) async {
    final request = http.Request('PROPFIND', _uri(server, path));
    request.headers.addAll({..._headers(username, password), 'Depth': '0'});
    return request.send().timeout(const Duration(seconds: 12));
  }

  Future<void> upload(
    String server,
    String username,
    String password,
    String path,
    String content,
  ) async {
    final response = await http
        .put(
          _uri(server, path),
          headers: {
            ..._headers(username, password),
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(content),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('上传失败：HTTP ${response.statusCode}');
    }
  }

  Future<String> download(
    String server,
    String username,
    String password,
    String path,
  ) async {
    final response = await http
        .get(_uri(server, path), headers: _headers(username, password))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('下载失败：HTTP ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes);
  }
}
