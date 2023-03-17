import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class Store {
  String? _domain;
  Box<String>? _domainKeys;
  Box<String>? _httpToken;
  Box<String>? _httpCacheBody;
  Box<String>? _httpCacheHeader;

  bool _isInitialized = false;

  static final _instance = Store._internal();

  factory Store(String domain) {
    if (_instance._httpCacheBody?.isOpen != true ||
        _instance._httpCacheHeader?.isOpen != true) {
      _instance._init(domain);
    }
    return _instance;
  }

  Store._internal();

  Future<void> _init(String domain) async {
    _domain = domain;
    await Hive.initFlutter();
    _domainKeys = await Hive.openBox<String>('domainKeys');

    String? key = _domainKeys?.get(_domain);

    if (key == null) {
      key = base64UrlEncode(Hive.generateSecureKey());
      _domainKeys?.put(_domain, key);
    }

    _httpToken = await Hive.openBox<String>(
      'httpToken',
      encryptionCipher: HiveAesCipher(base64Url.decode(key)),
    );

    _httpCacheBody = await Hive.openBox<String>('httpCacheBody');
    _httpCacheHeader = await Hive.openBox<String>('httpCacheHeader');

    _isInitialized = true;
  }

  Future<void> ensureInitialized() async {
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return !_isInitialized;
    });
  }

  void putToken(String key, String value) {
    if (_httpToken == null) {
      throw Exception("httpToken is not initialized");
    }
    _httpToken?.put(key, value);
  }

  void putBody(String key, String value) {
    if (_httpCacheBody == null) {
      throw Exception("_httpCacheBody is not initialized");
    }
    _httpCacheBody?.put(key, value);
  }

  void putHeader(String key, String value) {
    if (_httpCacheHeader == null) {
      throw Exception("_httpCacheHeader is not initialized");
    }
    _httpCacheHeader?.put(key, value);
  }

  String? getToken(String key) {
    if (_httpToken == null) {
      throw Exception("httpToken is not initialized");
    }
    return _httpToken?.get(key);
  }

  String? getBody(String key) {
    if (_httpCacheBody == null) {
      throw Exception("_httpCacheBody is not initialized");
    }
    return _httpCacheBody?.get(key);
  }

  String? getHeader(String key) {
    if (_httpCacheHeader == null) {
      throw Exception("_httpCacheHeader is not initialized");
    }
    return _httpCacheHeader?.get(key);
  }
}
