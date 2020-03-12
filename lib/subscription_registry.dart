import 'dart:async';

import 'package:flutter/widgets.dart';

/// Keeps track of stream subscriptions that are to be handled together in a Widget
mixin SubscriptionRegistry<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription> _subscriptions = [];

  void addDisposableSubscription(StreamSubscription sub) {
    _subscriptions.add(sub);
  }

  void pauseSubscriptions() {
    for (final sub in _subscriptions) {
      sub.pause();
    }
  }

  void resumeSubscriptions() {
    for (final sub in _subscriptions) {
      sub.resume();
    }
  }

  /// Disposes all subscriptions registered
  void disposeSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
