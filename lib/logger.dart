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

  void log(String message, {String? debugId}) {
    debugPrint("\x1B[33m$namespace[$debugId] $message\x1B[0m");
  }

  void logWithJson(String message, {dynamic json, String? debugId}) {
    debugPrint("\x1B[33m$namespace[$debugId] $message");
    if (json != null) {
      final str = jsonString(json).splitMapJoin(
        '\n',
        onMatch: (m) => "${m[0]}\x1B[33m$namespace[$debugId]    ",
        onNonMatch: (s) => s,
      );
      debugPrint("\x1B[33m$namespace[$debugId]    $str");
    }
  }
}
