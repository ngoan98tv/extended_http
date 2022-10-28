import 'dart:convert';

import 'package:flutter/foundation.dart';

class Logger {
  final _encoder = JsonEncoder.withIndent('  ');
  final String namespace;

  Logger(this.namespace);

  String jsonString(Object json) {
    dynamic value = json;
    if (json is String) {
      value = jsonDecode(json);
    }
    return _encoder.convert(value);
  }

  void log(String message) {
    debugPrint("\x1B[33m$namespace: $message\x1B[0m");
  }

  void logWithJson(String message, {dynamic json}) {
    debugPrint("\x1B[33m$namespace: $message");
    final str = jsonString(json).splitMapJoin(
      '\n',
      onMatch: (m) => "${m[0]}\x1B[33m    ",
      onNonMatch: (s) => s,
    );
    debugPrint("\x1B[33m    $str");
  }
}
