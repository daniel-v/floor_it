import 'dart:async';

import 'package:floor_it/throttle.dart';

/// This example shows how to create a debounce like
/// behaviour with throttle.
Future<void> debounceLikeExample() {
  final completer = Completer();
  int tickCount = 0;
  final cb = () {
    print('Printed at most once every second');
  };
  Timer.periodic(Duration(milliseconds: 50), (timer) {
    throttle(computation: cb, timeout: Duration(seconds: 1));
    if ((tickCount++) >= 80) {
      timer.cancel();
      completer.complete();
    }
  });
  return completer.future;
}

/// This example shows how to avoid accessing stale data.
///
/// Combining `throttle` and `Future.delayed` are useful when you
/// want to defer the computation just before when next throttle
/// call would be accepted.
///
/// On a timeline it looks like so:
///
/// By default, computation is executed immediately, next time it is
/// executed when timeout expired:
///
/// ```
/// |----|----|----
/// ```
///
/// By contrast, using it with `Future.delayed`, computation is executed
/// like so:
///
/// ```
/// ----|----|----|
/// ```
void ensureNoStaleData() {
  final timeout = Duration(seconds: 5);
  print('Expecting a single DateTime in 5 seconds. Should print ~${DateTime.now().add(timeout)}');
  for (int i = 0; i < 10; ++i) {
    throttle(
      timeout: timeout,
      computation: () {
        Future.delayed(timeout, () {
          print('${DateTime.now()}');
        });
      },
      trackComputation: false,
    );
  }
}

main() async {
  print('------ Debounce like ------ ');
  await debounceLikeExample();
  print('------ No stale data ------ ');
  ensureNoStaleData();
}
