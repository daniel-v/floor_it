import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'subscription_registry.dart';

typedef StateMatcherCallback<T> = bool Function(T state);

/// Waits for next transition
///
/// Returns `true` if [nextStateMatcher] returns `true`, `false` otherwise.
Future<bool> expectNextTransition<Event, State>(
    Bloc<Event, State> bloc, StateMatcherCallback<State> nextStateMatcher) async {
  // wait for the next transition
  final currentState = bloc.state;
  return bloc.firstWhere((st) => currentState != st).then((ev) {
    return nextStateMatcher(ev);
  });
}

/// Add an event to [bloc] and wait for the next transition to occur.
///
/// Returns `true` if [nextStateMatcher] returns `true`, `false` otherwise.
Future<bool> addAndExpectTransition<Event, State>(
    Bloc<Event, State> bloc, Event ev, StateMatcherCallback<State> nextStateMatcher) async {
  final expect = expectNextTransition(bloc, nextStateMatcher);
  bloc.add(ev);
  return expect;
}

extension TransitionHelpers<E, S> on Bloc<E, S> {
  /// see [expectNextTransition]
  Future<bool> checkNextTransition(StateMatcherCallback<S> nextStateMatcher) {
    return expectNextTransition(this, nextStateMatcher);
  }

  /// see [addAndExpectTransition]
  Future<bool> addAndCheckNextTransition(E event, StateMatcherCallback<S> nextStateMatcher) {
    return addAndExpectTransition(this, event, nextStateMatcher);
  }
}

typedef OnEnterCallback<State> = void Function(State state);
typedef EqualityCheckCallback<T> = bool Function(dynamic state);
typedef CurryStateCheck = bool Function();

bool _equalsByType<T>(state) {
  return state.runtimeType == T;
}

/// Invokes [callback] when [bloc] emits an event that matches to [equalCallback]
///
/// By default, [equalCallback] checks event by it's type
StreamSubscription onEnterRun<T>(Bloc bloc, OnEnterCallback<T> callback, [EqualityCheckCallback<T> equalCallback]) {
  equalCallback ??= (v) => _equalsByType<T>(v);
  StreamSubscription sub;
  sub = bloc.where((st) {
    return equalCallback(st);
  }).listen(
    (ev) {
      callback(ev);
    },
    onDone: () {
      sub.cancel();
    },
  );
  return sub;
}

void onEnterRunOnce<T>(Bloc bloc, OnEnterCallback<T> callback, [EqualityCheckCallback<T> equalCallback]) {
  equalCallback ??= (v) => _equalsByType<T>(v);
  var blocIsClosed = false;
  bloc.doOnDone(() {
    blocIsClosed = true;
  });
  bloc.firstWhere((st) {
    return equalCallback(st);
  }).then((ev) {
    if (!blocIsClosed) {
      callback(ev);
    }
  });
}

Future<T> waitForNext<T>(Bloc bloc, [EqualityCheckCallback<T> equalCallback]) {
  equalCallback ??= (v) => _equalsByType<T>(v);
  return bloc.firstWhere((st) {
    return equalCallback(st);
  }, orElse: () {}).then<T>((st) => st);
}

extension StateFilterHelpers<E, S> on Bloc<E, S> {
  StreamSubscription onEnterByType<T extends S>(OnEnterCallback<T> callback) {
    return onEnterRun(this, callback);
  }

  StreamSubscription onEnterByValue<T extends S>(OnEnterCallback<T> callback, T value) {
    return onEnterRun(this, callback, (st) => st == value);
  }

  bool isInByType<T extends S>() {
    return state.runtimeType == T;
  }

  bool isInByValue(S value) {
    return state == value;
  }

  Future<T> untilNextByType<T extends S>() {
    return waitForNext<T>(this);
  }

  CurryStateCheck curryIsInByType<T extends S>() {
    return () => isInByType<T>();
  }
}

extension SubscriptionStateFilterHelpers on SubscriptionRegistry {
  void onBlocEnterByType<T>(Bloc bloc, OnEnterCallback<T> callback) {
    addDisposableSubscription(bloc.onEnterByType(callback));
  }
}
