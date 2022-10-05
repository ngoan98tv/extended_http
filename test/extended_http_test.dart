import 'package:extended_http/extended_http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('config base url and create uri', () async {
    ExtendedHttp().config(
      baseURL: 'http://pub.dev',
    );

    final uri = ExtendedHttp().createURI('/api');

    expect(uri.toString(), "http://pub.dev/api");
  });
}
