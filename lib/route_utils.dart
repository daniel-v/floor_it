import 'package:flutter/widgets.dart';

@optionalTypeArgs
T getCurrentRoute<T extends Route>(NavigatorState navigator) {
  T currentRoute;
  navigator.popUntil((route) {
    currentRoute = route;
    return true;
  });
  return currentRoute;
}
