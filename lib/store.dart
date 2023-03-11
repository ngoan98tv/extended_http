import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class Store {
  String? _domain;
  Box<String>? _domainKeys;
  Box<String>? _httpToken;
  Box<String>? _httpCacheBody;
  Box<String>? _httpCacheHeader;

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
  }

  void putToken(String key, String value) {
    _httpToken?.put(key, value);
  }

  void putBody(String key, String value) {
    _httpCacheBody?.put(key, value);
  }

  void putHeader(String key, String value) {
    _httpCacheHeader?.put(key, value);
  }

  String? getToken(String key) {
    return _httpToken?.get(key);
  }

  String? getBody(String key) {
    return _httpCacheBody?.get(key);
  }

  String? getHeader(String key) {
    return _httpCacheHeader?.get(key);
  }
}
