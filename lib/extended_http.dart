import 'dart:async';
import 'dart:convert';
import 'package:extended_http/logger.dart';
import 'package:extended_http/store.dart';
import 'package:extended_http/utils.dart';
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
  void config({
    String? baseURL,
    Duration? timeout,
    CachePolicy? cachePolicy,
    Map<String, String>? headers,
    bool? logURL,
    bool? logRequestHeaders,
    bool? logRespondHeaders,
    bool? logRespondBody,
  }) {
    _config.timeout = timeout ?? _config.timeout;
    _config.baseURL = baseURL ?? _config.baseURL;
    _config.cachePolicy = cachePolicy ?? _config.cachePolicy;
    _config.headers.addAll(headers ?? {});
    _config.logURL = logURL ?? _config.logURL;
    _config.logRequestHeader = logRequestHeaders ?? _config.logRequestHeader;
    _config.logRespondHeader = logRespondHeaders ?? _config.logRespondHeader;
    _config.logRespondBody = logRespondBody ?? _config.logRespondBody;
  }

  /// Create an URI with baseURL prefix
  ///
  /// The result with be `baseURL` + `path` + `params`
  ///
  /// A `debugId` can be added to easy filter out relevant logs
  Uri createURI(
    String path, {
    String? debugId,
    Map<String, String>? params,
  }) {
    final u = Uri.parse(_config.baseURL + path);
    Map<String, String> queryParameters = {};
    if (debugId != null) {
      queryParameters.addAll({"debugId": debugId});
    }
    if (params != null) {
      queryParameters.addAll(params);
    }
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
  void saveAuthData(Map<String, dynamic> data) async {
    _store.putToken('auth', jsonEncode(data));
  }

  /// Get saved auth data if existed.
  Map<String, dynamic>? getAuthData() {
    Map<String, dynamic>? authData;
    final jsonData = _store.getToken('auth');
    if (jsonData != null) {
      authData = jsonDecode(jsonData) as Map<String, dynamic>;
    }
    return authData;
  }

  late Store _store;
  final String _domain;
  final Client _client;
  final Logger _logger = Logger("ExtendedHttp");
  final HttpConfig _config = HttpConfig();

  bool get _disableCache => _config.cachePolicy == CachePolicy.NoCache;
  bool get _cacheFirst => _config.cachePolicy == CachePolicy.CacheFirst;
  bool get _networkFirst => _config.cachePolicy == CachePolicy.NetworkFirst;

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
      _instanceMap[domain]!.init();
    }
    return _instanceMap[domain]!;
  }

  ExtendedHttp._internal(this._domain, this._client);

  void init() {
    _store = Store(_domain);
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
    _instanceMap[domain]!._log("Retry ($retryCount) ${req.method} ${req.url}");
    _instanceMap[domain]!._log("Headers ${req.headers}");
    if (res?.statusCode == 401 &&
        _instanceMap[domain]!.onUnauthorized != null) {
      final authData = _instanceMap[domain]!.getAuthData();
      await _instanceMap[domain]!.onUnauthorized!(authData);
      req.headers.addAll(_instanceMap[domain]!._config.headers);
    }
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final debugId = request.url.queryParameters['debugId'];

    request.headers.addAll(_config.headers);

    if (_config.logURL) {
      _log("${request.method} ${request.url}", debugId: debugId);
    }
    if (_config.logRequestHeader) {
      _log("Request headers", json: request.headers, debugId: debugId);
    }

    if (request.method == 'GET' && _cacheFirst) {
      _log("Read from cache", debugId: debugId);
      final cachedResponse = _responseFromCache(request.url);
      if (cachedResponse != null) {
        _log("Return cached response", debugId: debugId);
        return cachedResponse;
      }
      _log("Cache empty. Send request.", debugId: debugId);
    }

    final response = await _client.send(request).timeout(_config.timeout);
    final bodyString = await response.stream.bytesToString();

    if (_config.logRespondHeader) {
      _log(
        "Response (${response.statusCode}) headers",
        json: response.headers,
        debugId: debugId,
      );
    }

    if (_config.logRespondBody) {
      _log(
        "${request.method} (${response.statusCode}) ${request.url}",
        json: bodyString,
        debugId: debugId,
      );
    }

    if (request.method == 'GET' && !_disableCache) {
      if (response.statusCode == 200) {
        _log("Write to cache", debugId: debugId);
        await _cacheResponse(request.url, bodyString, response.headers);
      } else {
        if (_networkFirst) {
          final cachedResponse = _responseFromCache(request.url);
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

  StreamedResponse? _responseFromCache(Uri uri) {
    final cacheKey = uri.toString();
    final bodyString = _store.getBody(cacheKey);
    final headerString = _store.getHeader(cacheKey);

    if (bodyString == null || bodyString.isEmpty) {
      return null;
    }

    final headerMap = jsonDecode(headerString ?? "{}") as Map<String, dynamic>;
    final headers = headerMap.map((key, value) => MapEntry(key, "$value"));

    if (_config.logRespondHeader) {
      _log("Cached (200) $cacheKey headers", json: headers);
    }

    if (_config.logRespondBody) {
      _log("Cached (200) $cacheKey body", json: bodyString);
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
