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

  HttpConfig({
    this.baseURL = '',
    this.headers = const {},
    this.timeout = const Duration(seconds: 10),
    this.cachePolicy = CachePolicy.NetworkFirst,
    this.logURL = true,
    this.logRequestHeader = false,
    this.logRespondHeader = false,
    this.logRespondBody = false,
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

  HttpOptionalConfig({
    this.baseURL,
    this.headers,
    this.timeout,
    this.cachePolicy,
    this.logURL,
    this.logRequestHeader,
    this.logRespondHeader,
    this.logRespondBody,
  });
}
