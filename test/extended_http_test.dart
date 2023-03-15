import 'package:extended_http/extended_http.dart';
import 'package:extended_http/utils.dart';
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

  test('create uri for multiple domains', () async {
    ExtendedHttp('domain1').config(
      baseURL: 'http://domain1.com',
    );

    ExtendedHttp('domain2').config(
      baseURL: 'http://domain2.com',
    );

    final uri1 = ExtendedHttp('domain1').createURI('/api/users');
    final uri2 = ExtendedHttp('domain2').createURI('/api/posts');

    expect(uri1.toString(), "http://domain1.com/api/users");
    expect(uri2.toString(), "http://domain2.com/api/posts");
  });

  test('create custom config for a specified path', () async {
    final http = ExtendedHttp();

    http.config(
      baseURL: 'http://domain.com',
      headers: {
        "Content-Type": "application/json",
      },
    );

    final uri1 = http.createURI('/api/users');
    final uri2 = http.createURI(
      '/api/posts',
      overrideConfig: HttpOptionalConfig(
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      ),
    );
    final uri3 = http.createURI('/api/profile');

    expect(uri1.toString(), "http://domain.com/api/users");
    expect(uri2.toString(), "http://domain.com/api/posts");
    expect(uri3.toString(), "http://domain.com/api/profile");

    expect(
      http.headers,
      containsPair("Content-Type", "application/json"),
    );
    expect(
      http.getConfig(uri1).headers,
      containsPair("Content-Type", "application/json"),
    );
    expect(
      http.getConfig(uri2).headers,
      containsPair("Content-Type", "application/x-www-form-urlencoded"),
    );
    expect(
      http.getConfig(uri3).headers,
      containsPair("Content-Type", "application/json"),
    );
  });

  test('check if instances are singleton', () async {
    final instance1 = ExtendedHttp('domain1');
    final instance2 = ExtendedHttp('domain2');

    expect(instance1, isNot(same(instance2)));
    expect(instance1, same(ExtendedHttp('domain1')));
    expect(instance2, same(ExtendedHttp('domain2')));
  });
}
