import 'dart:async';

import 'package:flutter/material.dart';

typedef StreamObserverErrorHandler = Widget Function(Object error);
typedef StreamObserverSuccessHandler<T> = Widget Function(BuildContext context, T data);
typedef StreamObserverWaitHandler = Widget Function(ConnectionState connectionState);
typedef StreamObserverTransformer<T> = Stream<T> Function(Stream<T> stream);

Stream<T> distinctTransformer<T>(Stream<T> stream) {
  return stream.distinct((a, b) => a == b);
}

abstract class StreamObserver<T> implements Widget {
  factory StreamObserver(
      {Key key,
      @required Stream<T> stream,
      @required StreamObserverSuccessHandler<T> onSuccess,
      StreamObserverErrorHandler onError,
      StreamObserverWaitHandler onWaiting}) {
    return _StreamObserver<T>(
      stream: stream,
      onSuccess: onSuccess,
      onError: onError,
      onWaiting: onWaiting,
    );
  }

  factory StreamObserver.custom(
      {Key key,
      @required Stream<T> stream,
      @required StreamObserverTransformer<T> transformer,
      @required StreamObserverSuccessHandler<T> onSuccess,
      StreamObserverErrorHandler onError,
      StreamObserverWaitHandler onWaiting}) {
    return StreamObserver<T>(
      stream: transformer(stream),
      onSuccess: onSuccess,
      onError: onError,
      onWaiting: onWaiting,
    );
  }

  factory StreamObserver.distinct(
      {Key key,
      @required Stream<T> stream,
      @required StreamObserverSuccessHandler<T> onSuccess,
      StreamObserverErrorHandler onError,
      StreamObserverWaitHandler onWaiting}) {
    return StreamObserver.custom(
      stream: stream,
      transformer: distinctTransformer,
      onSuccess: onSuccess,
      onError: onError,
      onWaiting: onWaiting,
    );
  }
}

class _StreamObserver<T> extends StatelessWidget implements StreamObserver<T> {
  final Stream<T> stream;
  final StreamObserverErrorHandler onError;
  final StreamObserverSuccessHandler<T> onSuccess;
  final StreamObserverWaitHandler onWaiting;

  _StreamObserver({Key key, @required this.stream, @required this.onSuccess, this.onError, this.onWaiting})
      : assert(stream != null),
        assert(onSuccess != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (ctx, snapshot) {
        if (snapshot.hasError) return _handleError(snapshot.error);
        if (snapshot.hasData) return onSuccess(ctx, snapshot.data);
        return _handleWaiting(snapshot.connectionState);
      },
    );
  }

  Widget _handleError(Object error) {
    if (onError != null) return onError(error);
    return Container();
  }

  Widget _handleWaiting(ConnectionState connectionState) {
    if (onWaiting != null) return onWaiting(connectionState);
    return Container();
  }
}
