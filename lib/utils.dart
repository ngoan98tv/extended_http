import 'package:http_parser/http_parser.dart';

enum CachePolicy {
  /// Fetch data from network, if failed, fetch from cache.
  NetworkFirst,

  /// Fetch data from cache, if not existed, fetch from network.
  CacheFirst,

  /// Only fetch data from network. Never store data in cache.
  NoCache,

  /// Follow instructions from `Cache-Control` headers
  ControlHeader
}

class HttpConfig {
  String baseURL;
  Duration timeout;
  CachePolicy cachePolicy;
  Map<String, String> headers;

  bool logURL;
  bool logRequestHeader;
  bool logRespondHeader;
  bool logRespondBody;
  bool sendDebugId;

  HttpConfig({
    this.baseURL = '',
    this.headers = const {},
    this.timeout = const Duration(seconds: 10),
    this.cachePolicy = CachePolicy.NetworkFirst,
    this.logURL = true,
    this.logRequestHeader = false,
    this.logRespondHeader = false,
    this.logRespondBody = false,
    this.sendDebugId = false,
  }) {
    headers = {};
  }

  void add(HttpOptionalConfig other) {
    headers.addAll(other.headers ?? {});
    baseURL = other.baseURL ?? baseURL;
    timeout = other.timeout ?? timeout;
    cachePolicy = other.cachePolicy ?? cachePolicy;
    logURL = other.logURL ?? logURL;
    logRequestHeader = other.logRequestHeader ?? logRequestHeader;
    logRespondHeader = other.logRespondHeader ?? logRespondHeader;
    logRespondBody = other.logRespondBody ?? logRespondBody;
    sendDebugId = other.sendDebugId ?? sendDebugId;
  }

  HttpConfig clone() {
    return HttpConfig(
      headers: headers,
      baseURL: baseURL,
      timeout: timeout,
      cachePolicy: cachePolicy,
      logURL: logURL,
      logRequestHeader: logRequestHeader,
      logRespondHeader: logRespondHeader,
      logRespondBody: logRespondBody,
      sendDebugId: sendDebugId,
    );
  }
}

class HttpOptionalConfig {
  String? baseURL;
  Duration? timeout;
  CachePolicy? cachePolicy;
  Map<String, String>? headers;

  bool? logURL;
  bool? logRequestHeader;
  bool? logRespondHeader;
  bool? logRespondBody;
  bool? sendDebugId;

  HttpOptionalConfig({
    this.baseURL,
    this.headers,
    this.timeout,
    this.cachePolicy,
    this.logURL,
    this.logRequestHeader,
    this.logRespondHeader,
    this.logRespondBody,
    this.sendDebugId,
  });
}

class MimeType extends MediaType {
  MimeType(super.type, super.subtype, [super.parameters]);

  /// Create MimeType from string of `type/subtype;parameter=value`
  factory MimeType.fromString(String value) {
    var separatorIndex = value.indexOf('/');
    var type = value.substring(0, separatorIndex);
    var subtype = value.substring(separatorIndex + 1);
    var hasParam = subtype.indexOf(';');
    Map<String, String>? parameters;
    if (hasParam > 0) {
      var param = subtype.substring(hasParam + 1).trim().split('=');
      subtype = subtype.substring(0, hasParam);
      parameters = {
        param[0]: param[1],
      };
    }
    return MimeType(type, subtype, parameters);
  }
}
