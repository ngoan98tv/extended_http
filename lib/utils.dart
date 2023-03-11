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
  });
}
