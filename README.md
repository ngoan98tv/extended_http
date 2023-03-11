# Easy API with authorization and caching

![Test](https://github.com/ngoan98tv/extended_http/workflows/Test/badge.svg)
![DryRun](https://github.com/ngoan98tv/extended_http/workflows/Pub%20Dry%20Run/badge.svg)
![Publish](https://github.com/ngoan98tv/extended_http/workflows/Publish/badge.svg)
![PubVersion](https://img.shields.io/pub/v/extended_http)
![Issues](https://img.shields.io/github/issues/ngoan98tv/extended_http)

A Flutter HTTP package supports authorization and caching

## Features

- Handle unauthorized requests by define `onUnauthorized` method
- Specify when to retry the requests via `shouldRetry` & `onError` method
- Cache API response (for GET requests)
- Set request headers (such as: authorization token,...)
- Set request baseURL (Ex: `http://yourhost.com/api`)
- Set request timeout

All methods from `BaseClient` is inherited, including `get`, `post`, `put`, `patch` and more. See at [BaseClient APIs](https://pub.dev/documentation/http/latest/http/BaseClient-class.html).

## TODO

- Support multiple API domains, alternative domains.
- Support auto authentication with access and refresh token.
- Support different caching options to specific paths.

## Dependencies

[http](https://pub.dev/packages/http)

[hive](https://pub.dev/packages/hive)

## Feel free to [leave an issue](https://github.com/ngoan98tv/extended_http/issues) if you need help or see something wrong in this package
