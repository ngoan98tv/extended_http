import 'package:hive_flutter/hive_flutter.dart';

class Store {
  Box<String>? _httpCacheBody;
  Box<String>? _httpCacheHeader;

  static final _instance = Store._internal();

  factory Store() {
    if (_instance._httpCacheBody?.isOpen != true ||
        _instance._httpCacheHeader?.isOpen != true) {
      _instance._init();
    }
    return _instance;
  }

  Store._internal();

  Future<void> _init() async {
    await Hive.initFlutter();
    _httpCacheBody = await Hive.openBox<String>('httpCacheBody');
    _httpCacheHeader = await Hive.openBox<String>('httpCacheHeader');
  }

  void putBody(String key, String value) {
    _httpCacheBody?.put(key, value);
  }

  void putHeader(String key, String value) {
    _httpCacheHeader?.put(key, value);
  }

  String? getBody(String key) {
    return _httpCacheBody?.get(key);
  }

  String? getHeader(String key) {
    return _httpCacheHeader?.get(key);
  }
}
