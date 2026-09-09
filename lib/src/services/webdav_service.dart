import 'dart:convert';

import 'package:http/http.dart' as http;

class WebDavService {
  Map<String, String> _headers(String username, String password) => {
    'Authorization':
        'Basic ${base64Encode(utf8.encode('$username:$password'))}',
  };
  Uri _uri(String server, String path) => Uri.parse(
    '${server.replaceAll(RegExp(r'/+$'), '')}/${path.replaceAll(RegExp(r'^/+'), '')}',
  );

  Future<void> test(
    String server,
    String username,
    String password,
    String path,
  ) async {
    if (server.trim().isEmpty) throw Exception('请填写服务器地址');
    if (username.trim().isEmpty) throw Exception('请填写用户名');
    if (password.isEmpty) throw Exception('请填写密码');
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
      throw Exception('WebDAV 连接失败：HTTP ${response.statusCode}');
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
