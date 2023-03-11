import 'dart:async';
import 'dart:convert';
import 'package:extended_http/logger.dart';
import 'package:extended_http/store.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

/// Extend from `BaseClient`, adding caching and timeout features.
class ExtendedHttp extends BaseClient {
  final Client _client;
  final Logger _logger = Logger("ExtendedHttp");
  final Store _store = Store();

  Map<String, String> _headers = {};
  Duration _timeout = const Duration(seconds: 5);
  Duration _cacheAge = const Duration(seconds: 60);
  String _baseURL = '';

  bool _disableCache = false;
  bool _logURL = true;
  bool _logRequestHeaders = false;
  bool _logRespondHeaders = false;
  bool _logRespondBody = false;

  static final _instance = ExtendedHttp._internal(
    RetryClient(
      Client(),
      when: _shouldRetry,
      whenError: _shouldRetryError,
      onRetry: _beforeRetry,
    ),
  );

  factory ExtendedHttp() {
    return _instance;
  }

  ExtendedHttp._internal(this._client);

  static bool _shouldRetryError(Object error, StackTrace stack) {
    if (error is TimeoutException) {
      return true;
    }
    if (_instance.onError != null) {
      return _instance.onError!(error, stack);
    }
    return false;
  }

  static bool _shouldRetry(BaseResponse res) {
    if (res.statusCode == 503) {
      return true;
    }
    if (_instance.shouldRetry != null) {
      return _instance.shouldRetry!(res);
    }
    return false;
  }

  static Future<void> _beforeRetry(
    BaseRequest req,
    BaseResponse? res,
    int retryCount,
  ) async {
    _instance._log("Retry ($retryCount) ${req.method} ${req.url}");
    _instance._log("Headers ${req.headers}");
    if (res?.statusCode == 401 && _instance.onUnauthorized != null) {
      await _instance.onUnauthorized!();
      req.headers.addAll(_instance._headers);
    }
  }

  /// YOU MUST DEFINE `shouldRetry` FUNCTION TO MAKE THIS WORK
  ///
  /// Add `return response.statusCode == 401` into `shouldRetry` to trigger this
  ///
  /// Here we can get token and update headers to authorize the request
  ///
  /// The request will automatically retry after this
  Future<void> Function()? onUnauthorized;

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
  /// `timeout` - Request timeout, default `5 seconds`.
  ///
  /// `disableCache` - default `false`.
  ///
  /// `cacheAge` - cache time to live, default `60 seconds`.
  ///
  /// `headers` - Custom request headers, default `{}`.
  void config({
    String? baseURL,
    Duration? timeout,
    bool? disableCache,
    Duration? cacheAge,
    Map<String, String>? headers,
    bool? logURL,
    bool? logRequestHeaders,
    bool? logRespondHeaders,
    bool? logRespondBody,
  }) {
    _timeout = timeout ?? _timeout;
    _baseURL = baseURL ?? _baseURL;
    _cacheAge = cacheAge ?? _cacheAge;
    _disableCache = disableCache ?? _disableCache;
    _headers.addAll(headers ?? {});
    _logURL = logURL ?? _logURL;
    _logRequestHeaders = logRequestHeaders ?? _logRequestHeaders;
    _logRespondHeaders = logRespondHeaders ?? _logRespondHeaders;
    _logRespondBody = logRespondBody ?? _logRespondBody;
  }

  /// Create an URI with baseURL prefix
  ///
  /// The result with be `baseURL` + `path` + `params`
  Uri createURI(String path, {Map<String, String>? params}) {
    final u = Uri.parse(_baseURL + path);
    return Uri(
      scheme: u.scheme,
      host: u.host,
      port: u.port,
      path: u.path,
      queryParameters: params,
    );
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    request.headers.addAll(_headers);

    if (_logURL) {
      _log("${request.method} ${request.url}");
    }
    if (_logRequestHeaders) {
      _log("Request headers", json: request.headers);
    }

    if (!_disableCache && request.method == 'GET') {
      _log("Read from cache");
      final cachedResponse = _responseFromCache(request.url);
      if (cachedResponse != null) {
        _log("Return cached response");
        return cachedResponse;
      }
      _log("Cache empty. Send request.");
    }

    final response = await _client.send(request).timeout(_timeout);
    final bodyString = await response.stream.bytesToString();

    if (_logRespondHeaders) {
      _log("Response (${response.statusCode}) headers", json: response.headers);
    }
    if (_logRespondBody) {
      _log(
        "${request.method} (${response.statusCode}) ${request.url}",
        json: bodyString,
      );
    }

    if (!_disableCache && response.statusCode == 200) {
      _log("Write to cache");
      await _cacheResponse(request.url, bodyString, response.headers);
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

    _store.putBody(
      cacheKey,
      bodyString,
    );

    final validTo = DateTime.now().add(_cacheAge).toIso8601String();
    headers['cache-valid-to'] = validTo;

    final headerString = jsonEncode(headers);

    _store.putHeader(
      cacheKey,
      headerString,
    );
  }

  StreamedResponse? _responseFromCache(
    Uri uri, {
    bool ignoreValidDate = false,
  }) {
    final cacheKey = uri.toString();
    final bodyString = _store.getBody(cacheKey);
    final headerString = _store.getHeader(cacheKey);

    if (bodyString == null || bodyString.isEmpty) {
      return null;
    }

    final headerMap = jsonDecode(headerString ?? "{}") as Map<String, dynamic>;
    final headers = headerMap.map((key, value) => MapEntry(key, "$value"));

    if (!ignoreValidDate) {
      if (headers['cache-valid-to'] == null) {
        return null;
      }

      final validDate = DateTime.parse(headers['cache-valid-to']!);

      if (validDate.isBefore(DateTime.now())) {
        return null;
      }
    }

    if (_logRespondHeaders) {
      _log("Cached (203) $cacheKey headers", json: headers);
    }
    if (_logRespondBody) {
      _log("Cached (203) $cacheKey body", json: bodyString);
    }

    return StreamedResponse(
      Stream.value(utf8.encode(bodyString)),
      203,
      headers: headers,
      reasonPhrase: "Cached Response",
    );
  }

  void _log(String message, {dynamic json}) {
    if (json != null) {
      _logger.logWithJson(message, json: json);
    } else {
      _logger.log(message);
    }
  }
}
