# Changelog

## [0.3.5] - Feb 15, 2023

- Fix log error when response body is null

## [0.3.4] - Oct 25, 2022

Improve logging with color and added new log options

- logURL
- logRequestHeaders
- logRespondHeaders
- logRespondBody

## [0.2.4] - Oct 25, 2022

Expose `onError` method so you can define your own logic there

## [0.1.4] - Oct 21, 2022

Expose `shouldRetry` method so you can define your own logic there

## [0.0.4] - Oct 21, 2022

Improve config headers to add new values instead of replace all.

From now, when calling `config(headers: {new-headers})`

- matched headers will be overwritten
- while others headers will be kept

## [0.0.3] - Oct 5, 2022

Remove import dart:io

## [0.0.2] - Oct 5, 2022

Update package description

## [0.0.1] - Oct 5, 2022

Splitted from [remote_data_provider](https://pub.dev/packages/remote_data_provider)

Support API response caching and custom authorization headers
