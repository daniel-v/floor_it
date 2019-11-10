import 'dart:async';

import 'package:floor_it/throttle.dart';

main() {
  int tickCount = 0;
  final cb = () {
    print('Printed at most once every second');
  };
  Timer.periodic(Duration(milliseconds: 50), (timer) {
    throttle(computation: cb, timeout: Duration(seconds: 1));
    if ((tickCount++) >= 80) timer.cancel();
  });
}
