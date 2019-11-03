import 'dart:async';

typedef LazyFactory<T> = T Function();
typedef AsyncLazyFactory<T> = Future<T> Function();

/// Lazy initialization of `<T>` .
///
/// [factory] will be invoked upon first access to [value]. Subsequent access to
/// [value] will return cached values;
class Lazy<T> {
  final LazyFactory<T> factory;

  T _value;

  Lazy(this.factory);

  T get value {
    if (_value == null) _value = factory();
    return _value;
  }

  /// Resets value cache, upon next [value] access, [factory] will re-run.
  void reset() => _value = null;
}

/// Lazy initialization ot `<T>` with async factory.
///
/// See [Lazy]
class AsyncLazy<T> {
  final AsyncLazyFactory<T> factory;

  T _value;

  AsyncLazy(this.factory);

  FutureOr<T> get value async {
    if (_value == null) _value = await factory();
    return _value;
  }

  /// Resets value cache, upon next [value] access, [factory] will re-run.
  void reset() => _value = null;
}
