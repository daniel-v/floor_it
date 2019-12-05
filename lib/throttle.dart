import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:meta/meta.dart';

ThrottleCleanupStrategy _throttleCleanupStrategy = ThrottleCleanupStrategy.callCount();

ThrottleCleanupStrategy get throttleCleanupStrategy => _throttleCleanupStrategy;

set throttleCleanupStrategy(ThrottleCleanupStrategy strategy) {
  assert(strategy != null);
  _throttleCleanupStrategy = strategy;
}

typedef ThrottleCallback = void Function();

final _timers = <_ComparableFrame, int>{};

class _ComparableFrame with EquatableMixin {
  final Frame frame;
  final Zone zone;
  final ThrottleCallback computation;

  _ComparableFrame(this.frame, this.zone, this.computation);

  @override
  List<Object> get props => [frame.uri, frame.member, frame.line, frame.column, zone, computation];
}

abstract class ThrottleCleanupStrategy {
  factory ThrottleCleanupStrategy.callCount() {
    return _CleanupByCallCount();
  }

  void tick();
}

class _CleanupByCallCount implements ThrottleCleanupStrategy {
  int _callCount = 0;

  @override
  void tick() {
    ++_callCount;
    if (_callCount % _cleanupByCallCount == 0) {
      _timers.removeWhere((_, nextCalltime) => nextCalltime < DateTime.now().millisecondsSinceEpoch);
    }
  }

  static const _cleanupByCallCount = 1000;
}

/// Throttles execution of [computation] to run once every [timeout]
///
/// **Execution criteria:**
///
/// Upon first invocation, computation is ran immediately.
/// After first invocation, until [timeout] is not over, computation will
/// not be executed and it won't be scheduled to be executed. In that
/// regard, it differs from `Future.delayed()`
///
/// If [timeout] equals `Duration.zero`, [computation] is executed immediately.
///
/// **How computation is tracked:**
///
/// Computations are tracked by callsite (where you call `throttle` from),
/// Zone and function reference by default. If any is different, computation
/// will be executed by execution criteria.
///
/// You can turn off function reference tracking by setting [trackComputation]
/// to `false`, in which can only the call site and zone will be considered.
/// Setting [trackComputation] to `false` is useful if [computation] is a closure
/// instead of a method/existing function.
///
///
/// **Common use case:**
///
/// You want to execute [computation] in response to events that happen very
/// frequently eg. scroll position change or dragging an object.
///
/// **Cleanup:**
///
/// To make sure that memory can be cleaned up, throttle periodically calls
/// appropriate cleanup declared by [ThrottleCleanupStrategy].
///
/// {@tool sample}
///
/// Following example prints to console at most every second. Throttle is
/// invoked every 50 milliseconds but printing is throttled to a second
///
/// ```dart
/// int tickCount = 0;
/// final cb = () {
///   print('Printed at most once every second');
/// };
/// Timer.periodic(Duration(milliseconds: 50), (timer) {
/// throttle(computation: cb, timeout: Duration(seconds: 1));
/// if ((tickCount++) >= 80) timer.cancel();
/// });
/// ```
/// {@end-tool}
///
/// **See also:**
///
///  * `test/throttle_test.dart` on usage
///  * `example/throttle_example.dart`
void throttle(
    {Duration timeout = Duration.zero, @required ThrottleCallback computation, bool trackComputation = true}) {
  assert(computation != null);
  if (timeout == Duration.zero) {
    computation();
  }
  final callFrame = Trace.current(1).frames.first;
  final frame = _ComparableFrame(callFrame, Zone.current, trackComputation ? computation : null);
  if (!_timers.containsKey(frame)) {
    final nextCall = DateTime.now().add(timeout);
    _timers[frame] = nextCall.millisecondsSinceEpoch;
    computation();
  } else if (_timers[frame] < DateTime.now().millisecondsSinceEpoch) {
    final nextCall = DateTime.now().add(timeout);
    _timers[frame] = nextCall.millisecondsSinceEpoch;
    computation();
  }
  _throttleCleanupStrategy.tick();
}
