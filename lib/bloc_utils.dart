import 'dart:async';

import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:floor_it/subscription_registry.dart';
import 'package:rxdart/rxdart.dart';

typedef StateMatcherCallback<T> = bool Function(T state);
typedef OnEnterCallback<State> = void Function(State state);
typedef EqualityCheckCallback<T> = bool Function(dynamic state);
typedef CurryStateCheck = bool Function();

/// Waits for next transition
///
/// Comparison and checking happens if
/// - bloc emits a new state
/// - the new state is not equal to previous state
///
/// You can use `bloc.isInByType<T>()` or `bloc.isInByValue(val)` to check if a Bloc
/// is in any given state by type or value;
///
/// Returns `true` if [nextStateMatcher] returns `true` for the newly emitted state,
/// `false` otherwise.
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

void onEnterRunOnce<T>(Bloc<dynamic, T> bloc, OnEnterCallback<T> callback, [EqualityCheckCallback<T> equalCallback]) {
  equalCallback ??= (v) => _equalsByType<T>(v);
  bool blocIsClosed = false;
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

Future<T> waitForNext<T>(Bloc bloc, [bool throwFailure = false, EqualityCheckCallback<T> equalCallback]) {
  equalCallback ??= (v) => _equalsByType<T>(v);
  final currentState = bloc.state;
  return bloc.firstWhere((st) {
    if (st == currentState) {
      return false;
    }
    // FIXME
//    if (throwFailure && st is FailureState) {
//      throw st.failure;
//    }
//    if (throwFailure && st is Failure) {
//      throw st;
//    }
    return equalCallback(st);
  }, orElse: () {}).then<T>((st) => st);
}

extension SubscriptionStateFilterHelpers on SubscriptionRegistry {
  void onBlocEnterByType<T>(Bloc bloc, OnEnterCallback<T> callback) {
    addDisposableSubscription(bloc.onEnterByType(callback));
  }
}

class DelegatingBloc<Event, State> extends DelegatingStream<State> implements Bloc<Event, State> {
  final Bloc<Event, State> _bloc;

  DelegatingBloc(this._bloc) : super(_bloc);

  @override
  State get initialState => _bloc.initialState;

  @override
  Stream<State> mapEventToState(Event event) => _bloc.mapEventToState(event);

  @override
  void onError(Object error, StackTrace stacktrace) => _bloc.onError(error, stacktrace);

  @override
  void onEvent(Event event) => _bloc.onEvent(event);

  @override
  void onTransition(Transition<Event, State> transition) => _bloc.onTransition(transition);

  @override
  State get state => _bloc.state;

  @override
  Stream<Transition<Event, State>> transformTransitions(Stream<Transition<Event, State>> transitions) =>
      _bloc.transformTransitions(transitions);

  @override
  Stream<Transition<Event, State>> transformEvents(Stream<Event> events, transitionFn) =>
      _bloc.transformEvents(events, transitionFn);

  // sink interfaces

  @override
  void add(Event event) => _bloc.add(event);

  @override
  Future<void> close() => _bloc.close();
}

abstract class BlocUtilsBase<E, S> implements Bloc<E, S> {
  StreamSubscription onEnterByType<T extends S>(OnEnterCallback<T> callback);

  StreamSubscription onEnterByValue<T extends S>(OnEnterCallback<T> callback, T value);

  bool isInByType<T extends S>();

  bool isInByValue(S value);

  /// Waits of next event of type <T> and returns it
  ///
  /// If [throwFailure] is `true`, the Failure emitted while waiting for event of type T
  /// will be thrown. This way, [FailureState] can be handled in a catch block.
  Future<T> untilNextByType<T extends S>({bool throwFailure = false});

  CurryStateCheck curryIsInByType<T extends S>();

  /// see [expectNextTransition]
  Future<bool> checkNextTransition(StateMatcherCallback<S> nextStateMatcher);

  /// see [addAndExpectTransition]
  Future<bool> addAndCheckNextTransition(E event, StateMatcherCallback<S> nextStateMatcher);
}

class BlocWithUtils<E, US> extends DelegatingBloc<E, US> implements BlocUtilsBase<E, US> {
  BlocWithUtils(Bloc<E, US> bloc) : super(bloc);

  @override
  StreamSubscription onEnterByType<MT extends US>(OnEnterCallback<MT> callback) {
    return onEnterRun(this, callback);
  }

  @override
  StreamSubscription onEnterByValue<MT extends US>(OnEnterCallback<MT> callback, MT value) {
    return onEnterRun(this, callback, (st) => st == value);
  }

  @override
  bool isInByType<MT extends US>() {
    return state.runtimeType == MT;
  }

  @override
  bool isInByValue(US value) {
    return state == value;
  }

  /// Waits of next event of type <T> and returns it
  ///
  /// If [throwFailure] is `true`, the Failure emitted while waiting for event of type T
  /// will be thrown. This way, [FailureState] can be handled in a catch block.
  @override
  Future<MT> untilNextByType<MT extends US>({bool throwFailure = false}) {
    return waitForNext<MT>(this, throwFailure);
  }

  @override
  CurryStateCheck curryIsInByType<MT extends US>() {
    return () => isInByType<MT>();
  }

  /// see [expectNextTransition]
  @override
  Future<bool> checkNextTransition(StateMatcherCallback<US> nextStateMatcher) {
    return expectNextTransition(this, nextStateMatcher);
  }

  /// see [addAndExpectTransition]
  @override
  Future<bool> addAndCheckNextTransition(E event, StateMatcherCallback<US> nextStateMatcher) {
    return addAndExpectTransition(this, event, nextStateMatcher);
  }
}

BlocUtilsBase<E, S> _getOrBoxInUtils<E, S>(Bloc<E, S> bloc) {
  if (bloc is BlocUtilsBase<E, S>) {
    return bloc;
  }
  return BlocWithUtils(bloc);
}

extension BlocUtilProxies<E, PState> on Bloc<E, PState> {
  StreamSubscription onEnterByType<ExT extends PState>(OnEnterCallback<ExT> callback) =>
      _getOrBoxInUtils<E, PState>(this).onEnterByType<ExT>(callback);

  StreamSubscription onEnterByValue<ExT extends PState>(OnEnterCallback<ExT> callback, ExT value) =>
      _getOrBoxInUtils<E, PState>(this).onEnterByValue<ExT>(callback, value);

  bool isInByType<ExT extends PState>() => _getOrBoxInUtils<E, PState>(this).isInByType<ExT>();

  bool isInByValue(PState value) => _getOrBoxInUtils<E, PState>(this).isInByValue(value);

  /// Waits of next event of type <ExT> and returns it
  ///
  /// If [throwFailure] is `true`, the Failure emitted while waiting for event of type T
  /// will be thrown. This way, [FailureState] can be handled in a catch block.
  Future<ExT> untilNextByType<ExT extends PState>({bool throwFailure = false}) =>
      _getOrBoxInUtils<E, PState>(this).untilNextByType<ExT>(throwFailure: throwFailure);

  CurryStateCheck curryIsInByType<ExT extends PState>() => _getOrBoxInUtils<E, PState>(this).curryIsInByType<ExT>();

  /// see [expectNextTransition]
  Future<bool> checkNextTransition(StateMatcherCallback<PState> nextStateMatcher) =>
      _getOrBoxInUtils<E, PState>(this).checkNextTransition(nextStateMatcher);

  /// see [addAndExpectTransition]
  Future<bool> addAndCheckNextTransition(E event, StateMatcherCallback<PState> nextStateMatcher) {
    return _getOrBoxInUtils<E, PState>(this).addAndCheckNextTransition(event, nextStateMatcher);
  }
}
