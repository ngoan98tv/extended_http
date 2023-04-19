import 'dart:async';
import 'dart:convert';
import 'package:extended_http/logger.dart';
import 'package:extended_http/store.dart';
import 'package:extended_http/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

/// Extend from `BaseClient`, adding caching and timeout features.
class ExtendedHttp extends BaseClient {
  /// YOU MUST DEFINE `shouldRetry` FUNCTION TO MAKE THIS WORK
  ///
  /// Add `return response.statusCode == 401` into `shouldRetry` to trigger this,
  /// Remember to exclude auth paths such as: `/login`, `/refresh-token`
  ///
  /// Here we can get token and update headers to re-authorize the requests
  ///
  /// The request will automatically retry after this
  Future<void> Function(Map<String, dynamic>? authData)? onUnauthorized;

  /// Called when a request failed to check if it should be retried or not
  ///
  /// Default only 503 requests are retried
  bool Function(BaseResponse response)? shouldRetry;

  /// Called when an error occurred to check if it should be retried or not
  ///
  /// Default only TimeoutException requests are retried
  bool Function(Object error, StackTrace stack)? onError;

  /// Override default config
  ///
  /// `baseURL` - API host path, such as `http://yourapi.com/v1`, default: ''
  ///
  /// `timeout` - Request timeout, default `10 seconds`.
  ///
  /// `cachePolicy` - Specify how cache should be processed, see more on `CachePolicy`, default `NetworkFirst`
  ///
  /// `headers` - Custom request headers, default `{}`.
  ///
  /// `sendDebugId` - Specify whether include `debugId` in request params or not, default `false`
  void config({
    String? baseURL,
    Duration? timeout,
    CachePolicy? cachePolicy,
    Map<String, String>? headers,
    bool? logURL,
    bool? logRequestHeader,
    bool? logRespondHeader,
    bool? logRespondBody,
    bool? sendDebugId,
    bool? enableAuthLock,
  }) {
    _config.add(
      HttpOptionalConfig(
        baseURL: baseURL,
        timeout: timeout,
        cachePolicy: cachePolicy,
        headers: headers,
        logURL: logURL,
        logRequestHeader: logRequestHeader,
        logRespondHeader: logRespondHeader,
        logRespondBody: logRespondBody,
        sendDebugId: sendDebugId,
        enableAuthLock: enableAuthLock,
      ),
    );
  }

  /// Create an URI with baseURL prefix
  ///
  /// The result with be `baseURL` + `path` + `params`
  ///
  /// `debugId` can be added to easy filter out relevant logs
  ///
  /// `overrideConfig` used to override global configs
  Uri createURI(
    String path, {
    String? debugId,
    Map<String, String>? params,
    HttpOptionalConfig? overrideConfig,
  }) {
    _counter++;
    final u = Uri.parse(_config.baseURL + path);
    Map<String, String> queryParameters = {};
    if (params != null) {
      queryParameters.addAll(params);
    }
    if (overrideConfig != null) {
      _configMap.addAll({u.path: overrideConfig});
    }
    if ((_config.sendDebugId && overrideConfig?.sendDebugId == null) ||
        (overrideConfig?.sendDebugId == true)) {
      queryParameters.addAll({"debugId": debugId ?? "$_counter"});
    }
    _debugIdMap.addAll({u.path: debugId ?? "$_counter"});
    return Uri(
      scheme: u.scheme,
      host: u.host,
      port: u.port,
      path: u.path,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  /// Save auth data (access token, refresh token,...) for use later
  /// in `onUnauthorized` method, it can also be accessed using `getAuthData()`
  void setAuthData(Map<String, dynamic>? data) {
    if (data == null) {
      _store.removeToken('auth');
      return;
    }
    _store.putToken('auth', jsonEncode(data));
  }

  /// Get saved auth data if existed.
  Map<String, dynamic>? get authData {
    Map<String, dynamic>? authData;
    final jsonData = _store.getToken('auth');
    if (jsonData != null) {
      authData = jsonDecode(jsonData) as Map<String, dynamic>;
    }
    return authData;
  }

  /// Override global headers setting
  void setHeaders(Map<String, String>? headers) {
    _config.headers.addAll(headers ?? {});
  }

  /// Get current global headers
  Map<String, String> get headers => _config.headers;

  Future<MultipartFile> createFileFromPath(
    String fieldName, {
    required String path,
    required String filename,
    required MimeType mimeType,
  }) {
    return MultipartFile.fromPath(
      fieldName,
      path,
      filename: filename,
      contentType: mimeType,
    );
  }

  MultipartFile createFileFromBytes(
    String fieldName, {
    required List<int> bytes,
    required String filename,
    required MimeType mimeType,
  }) {
    return MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: filename,
      contentType: mimeType,
    );
  }

  Future<StreamedResponse> sendFile(
    Uri uri,
    List<MultipartFile> files, {
    String method = "POST",
    Map<String, String>? fields,
  }) async {
    final request = MultipartRequest(method, uri)
      ..files.addAll(files)
      ..fields.addAll(fields ?? {});

    return send(request);
  }

  Future<Map<String, dynamic>?> sendJsonRequest(
    HttpMethod method,
    String path, {
    Object? body,
    Map<String, String>? headers,
    Encoding? encoding,
    String? debugId,
    Map<String, String>? params,
    HttpOptionalConfig? overrideConfig,
  }) async {
    final uri = createURI(
      path,
      debugId: debugId,
      params: params,
      overrideConfig: overrideConfig,
    );

    final request = Request(method.name, uri);

    if (headers != null) request.headers.addAll(headers);
    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is List || body is Map) {
        request.body = await compute((data) => jsonEncode(data), body);
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }

    final res = await Response.fromStream(await send(request));

    if (res.body.isEmpty) {
      return null;
    }

    return compute((data) => jsonDecode(data), res.body);
  }

  static int _counter = 0;

  String? _locker;

  late Store _store;
  final String _domain;
  final Client _client;
  final Logger _logger = Logger("ExHttp");
  final HttpConfig _config = HttpConfig();

  /// Specified config for different API paths
  final Map<String, HttpOptionalConfig> _configMap = {};

  // Store debug id list
  final Map<String, String> _debugIdMap = {};

  static final Map<String, ExtendedHttp> _instanceMap = {};

  factory ExtendedHttp([String domain = 'default']) {
    if (!_instanceMap.containsKey(domain)) {
      _instanceMap[domain] = ExtendedHttp._internal(
        domain,
        RetryClient(
          Client(),
          when: (BaseResponse res) => _shouldRetry(domain, res),
          whenError: (Object error, StackTrace stack) =>
              _shouldRetryError(domain, error, stack),
          onRetry: (BaseRequest req, BaseResponse? res, int retryCount) =>
              _beforeRetry(domain, req, res, retryCount),
        ),
      );
      _instanceMap[domain]!._init();
    }
    return _instanceMap[domain]!;
  }

  factory ExtendedHttp.from(Client client, [String domain = 'default']) {
    if (!_instanceMap.containsKey(domain)) {
      _instanceMap[domain] = ExtendedHttp._internal(
        domain,
        RetryClient(
          client,
          when: (BaseResponse res) => _shouldRetry(domain, res),
          whenError: (Object error, StackTrace stack) =>
              _shouldRetryError(domain, error, stack),
          onRetry: (BaseRequest req, BaseResponse? res, int retryCount) =>
              _beforeRetry(domain, req, res, retryCount),
        ),
      );
      _instanceMap[domain]!._init();
    }
    return _instanceMap[domain]!;
  }

  ExtendedHttp._internal(this._domain, this._client);

  void _init() {
    _store = Store(_domain);
  }

  Future<void> ensureInitialized() async {
    await _store.ensureInitialized();
  }

  HttpConfig getConfig([Uri? uri]) {
    if (uri != null && _configMap.containsKey(uri.path)) {
      return _config.clone()..add(_configMap[uri.path]!);
    }
    return _config;
  }

  static bool _shouldRetryError(String domain, Object error, StackTrace stack) {
    if (error is TimeoutException) {
      return true;
    }
    return _instanceMap[domain]!.onError?.call(error, stack) ?? false;
  }

  static bool _shouldRetry(String domain, BaseResponse res) {
    if (res.statusCode == 503) {
      return true;
    }
    return _instanceMap[domain]!.shouldRetry?.call(res) ?? false;
  }

  static Future<void> _beforeRetry(
    String domain,
    BaseRequest req,
    BaseResponse? res,
    int retryCount,
  ) async {
    final instance = _instanceMap[domain]!;
    final debugId = instance._debugIdMap[req.url.path];

    instance._log(
      "Retry ($retryCount) ${req.method} ${req.url}",
      debugId: debugId,
    );
    instance._log("Headers ${req.headers}", debugId: debugId);

    if (res?.statusCode == 401 && instance.onUnauthorized != null) {
      if (instance._locker != null && instance._locker != debugId) {
        instance._log("[Paused] ${req.method} ${req.url}", debugId: debugId);
        await Future.doWhile(() async {
          await Future.delayed(const Duration(seconds: 1));
          return instance._locker != null;
        });
      } else {
        final authData = instance.authData ?? {};
        if (instance._config.enableAuthLock) {
          instance._locker = "r$debugId";
          authData.addAll({'locker': "r$debugId"});
        }
        await instance.onUnauthorized!(authData);
        instance._locker = null;
      }
      final config = instance.getConfig(req.url);
      req.headers.addAll(config.headers);
    }
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final debugId = _debugIdMap[request.url.path];

    if (_locker != null && _locker != debugId) {
      _log("[Paused] ${request.method} ${request.url}", debugId: debugId);
      await Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        return _locker != null;
      });
    }

    final config = getConfig(request.url);
    final disableCache = config.cachePolicy == CachePolicy.NoCache;
    final cacheFirst = config.cachePolicy == CachePolicy.CacheFirst;
    final networkFirst = config.cachePolicy == CachePolicy.NetworkFirst;

    request.headers.addAll(config.headers);

    if (config.logURL) {
      _log("${request.method} ${request.url}", debugId: debugId);
    }
    if (config.logRequestHeader) {
      _log("Request headers", json: request.headers, debugId: debugId);
    }

    if (request.method == 'GET' && cacheFirst) {
      _log("Read from cache", debugId: debugId);
      final cachedResponse = _responseFromCache(request.url, debugId);
      if (cachedResponse != null) {
        _log("Return cached response", debugId: debugId);
        return cachedResponse;
      }
      _log("Cache empty. Send request.", debugId: debugId);
    }

    final response = await _client.send(request).timeout(config.timeout);
    final bodyString = await response.stream.bytesToString();

    if (config.logRespondHeader) {
      _log(
        "Response (${response.statusCode}) headers",
        json: response.headers,
        debugId: debugId,
      );
    }

    if (config.logRespondBody) {
      _log(
        "${request.method} (${response.statusCode}) ${request.url}",
        json: bodyString,
        debugId: debugId,
      );
    }

    if (request.method == 'GET' && !disableCache) {
      if (response.statusCode == 200) {
        _log("Write to cache", debugId: debugId);
        await _cacheResponse(request.url, bodyString, response.headers);
      } else {
        if (networkFirst && response.statusCode >= 500) {
          final cachedResponse = _responseFromCache(request.url, debugId);
          if (cachedResponse != null) {
            _log("Return cached response", debugId: debugId);
            return cachedResponse;
          }
        }
      }
    }

    return StreamedResponse(
      Stream.value(utf8.encode(bodyString)),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      contentLength: response.contentLength,
      request: response.request,
    );
  }

  Future<void> _cacheResponse(
    Uri uri,
    String bodyString,
    Map<String, String> headers,
  ) async {
    final cacheKey = uri.toString();
    final headerString = jsonEncode(headers);

    _store.putBody(
      cacheKey,
      bodyString,
    );

    _store.putHeader(
      cacheKey,
      headerString,
    );
  }

  StreamedResponse? _responseFromCache(Uri uri, String? debugId) {
    final cacheKey = uri.toString();
    final bodyString = _store.getBody(cacheKey);
    final headerString = _store.getHeader(cacheKey);
    final config = getConfig(uri);

    if (bodyString == null || bodyString.isEmpty) {
      return null;
    }

    final headerMap = jsonDecode(headerString ?? "{}") as Map<String, dynamic>;
    final headers = headerMap.map((key, value) => MapEntry(key, "$value"));

    if (config.logRespondHeader) {
      _log(
        "Cached (200) $cacheKey headers",
        json: headers,
        debugId: debugId,
      );
    }

    if (config.logRespondBody) {
      _log(
        "Cached (200) $cacheKey body",
        json: bodyString,
        debugId: debugId,
      );
    }

    return StreamedResponse(
      Stream.value(utf8.encode(bodyString)),
      200,
      headers: headers,
      reasonPhrase: "Cached Response",
    );
  }

  void _log(String message, {dynamic json, String? debugId}) {
    if (json != null) {
      _logger.logWithJson(message, json: json, debugId: debugId);
    } else {
      _logger.log(message, debugId: debugId);
    }
  }
}
