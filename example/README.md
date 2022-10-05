## Extended HTTP - fetch data from your API with caching and authorization options

All methods from `BaseClient` is inherited, including `get`, `post`, `put`, `patch` and more. See at [BaseClient APIs](https://pub.dev/documentation/http/latest/http/BaseClient-class.html)

```dart

// Call config at the App init to apply for all following requests, skip to use default config.

ExtendedHttp().config(
  String? baseURL,
  Duration? timeout,
  bool? disableCache,
  Duration? cacheAge,
  Map<String, String>? headers,
);

ExtendedHttp().onUnauthorized = () async {
  // Fetch token
  ExtendedHttp().config(
    headers: // new headers,
  );
};

// Usage: Example Post APIs
class Post {
  static Future<List<Post>> getAll({
    int page = 1,
    int limit = 10,
    String search = '',
  }) async {
    final uri = ExtendedHttp().createURI('/posts', params: {
      "_page": "$page",
      "_limit": "$limit",
      "q": search,
    });
    final res = await ExtendedHttp().get(uri);
    final dataList = jsonDecode(res.body) as List<dynamic>;
    return dataList.map((e) => Post.fromJson(e)).toList();
  }

  static Future<Post> getDetail(int id) async {
    final uri = ExtendedHttp().createURI('/posts/$id');
    final res = await ExtendedHttp().get(uri);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Post.fromJson(data);
  }

  static Future<Post> create(Post newPost) async {
    final uri = ExtendedHttp().createURI('/posts');
    final res = await ExtendedHttp().post(
      uri,
      body: newPost.toJson(),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Post.fromJson(data);
  }

  static Future<Post> update(Post post) async {
    final uri = ExtendedHttp().createURI('/posts/${post.id}');
    final res = await ExtendedHttp().put(
      uri,
      body: post.toJson()..remove('id'),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Post.fromJson(data);
  }

  static Future<Post> delete(int id) async {
    final uri = ExtendedHttp().createURI('/posts/$id');
    final res = await ExtendedHttp().delete(uri);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Post.fromJson(data);
  }
}
```
