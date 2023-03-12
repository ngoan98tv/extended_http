import 'package:extended_http/extended_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'fake_path_provider.dart';

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  test('create uri without parameters', () async {
    ExtendedHttp().config(
      baseURL: 'http://pub.dev',
    );

    final uri = ExtendedHttp().createURI('/api');

    expect(uri.toString(), "http://pub.dev/api");
  });

  test('create uri with parameters', () async {
    ExtendedHttp().config(
      baseURL: 'http://pub.dev',
    );

    final uri = ExtendedHttp().createURI(
      '/api',
      params: {
        'value': '123',
      },
    );

    expect(uri.toString(), "http://pub.dev/api?value=123");
  });

  test('create uri with debugId', () async {
    ExtendedHttp().config(
      baseURL: 'http://pub.dev',
    );

    final uri = ExtendedHttp().createURI(
      '/api',
      debugId: '123',
    );

    expect(uri.toString(), "http://pub.dev/api?debugId=123");
  });
}
