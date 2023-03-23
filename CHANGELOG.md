# Changelog

## [1.1.8] - Mar 23, 2023

- Add option `sendDebugId` to specify whether send the `debugId` to server or not.
- When set `CachePolicy.networkFirst`, only return cached response when the request failed due to server error (`statusCode >= 500`)

## [1.1.6] - Mar 20, 2023

- Clear auth data by calling `setAuthData(null)`

## [1.1.5] - Mar 17, 2023

- Improve `ensureInitialized()`

## [1.1.4] - Mar 17, 2023

- Add `ensureInitialized()`, await it before access `authData`

## [1.1.3] - Mar 17, 2023

- Fix missing package
- Set default `debugId`

## [1.1.2] - Mar 17, 2023

- Support upload file, example
  
  ```dart
  final file = createFileFromBytes(
    'file',
    bytes: bytes,
    filename: filename,
    mimeType: MimeType('image', 'jpg'),
  );
  final uri = createURI('/api/upload');
  sendFile(uri, [file]);
  ```

## [1.0.2] - Mar 15, 2023

- Update package description

## [1.0.1] - Mar 15, 2023

- Support custom config on each path, example
  
  ```dart
  createURI(
      '/api/posts',
      overrideConfig: HttpOptionalConfig(
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      ),
    )
  ```

## [1.0.0] - Mar 15, 2023

- New `CachePolicy` with 3 options:
  - `NetworkFirst` Fetch data from network, if failed, fetch from cache.
  - `CacheFirst` Fetch data from cache, if not existed, fetch from network.
  - `NoCache` Only fetch data from network. Never store data in cache.

- Support multiple instances for multiple API domains, example:
  - `ExtendedHttp()` => get/set for default instance
  - `ExtendedHttp("domain1")` => get/set for instance of domain1
  - `ExtendedHttp("domain2")` => get/set for instance of domain2

- Add `debugId` to easy filter out relevant logs when debugging, example

    ```dart
    ExtendedHttp().createURI(
      '/api',
      debugId: '123',
    )
    ```

- Add `authData` for easy saving user credential, it can be used to store token or current user data.
  - Setter: `setAuthData(Map<String, dynamic> data)`
  - Getter: `authData`
  - Method of `onUnauthorized` now also have `authData` as parameter.

- Add getter `headers` to get current headers and setter `setHeaders`

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
