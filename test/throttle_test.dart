import 'dart:async';

import 'package:floor_it/throttle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('function equality', () {
    final cb = () {};
    final a = cb;
    final b = cb;
    expect(a == b, isTrue);
  });

  test('should assert when computation is null', () {
    expect(() {
      throttle(computation: null);
    }, throwsAssertionError);
  });
  test('should invoke computation immediately when timeout is zero', () {
    bool invoked = false;
    throttle(computation: () {
      invoked = true;
    });
    expect(invoked, isTrue);
  });
  test('should not invoke computation within timeout', () {
    int callCount = 0;
    final cb = () {
      callCount++;
    };
    for (int i = 0; i < 5; i++) {
      throttle(
        computation: cb,
        timeout: Duration(hours: 1),
      );
    }
    expect(callCount, 1);
  });
  test('should invoke computation if computation is different', () {
    int callCount = 0;
    for (int i = 0; i < 5; i++) {
      throttle(
        computation: () {
          callCount++;
        },
        timeout: Duration(hours: 1),
      );
    }
    expect(callCount, 5);
  });
  test('should not invoke computation within timeout when trackComputation is false', () {
    int callCount = 0;
    for (int i = 0; i < 5; i++) {
      throttle(
        computation: () {
          callCount++;
        },
        timeout: Duration(hours: 1),
        trackComputation: false);
    }
    expect(callCount, 1);
  });
  test('should consider Zone when deciding to invoke', () {
    int callCount = 0;
    final cb = () {
      callCount++;
    };
    for (int i = 0; i < 5; i++) {
      Zone.current.fork().runGuarded(() {
        throttle(computation: cb, timeout: Duration(hours: 1));
      });
    }
    expect(callCount, 5);
  });
}
