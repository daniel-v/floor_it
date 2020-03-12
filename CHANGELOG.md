## Next

* `SubscriptionRegistry` aids in tracking/handling stream subscriptions
  in widgets and offers methods to do operations on them in a single 
  call.
* BLoC extension utility functions to help detecting state transitions 
  and react to them (note: these signatures might not match that of 
  the code)  
  * `Bloc.checkNextTransition() ↦ bool` - checks if next state Bloc 
    enters is of expected type/value
  * `Bloc.addAndCheckNextTransition() ↦ bool` - trigger state change
    and check if next transition is of expected type/value
  * `Bloc.onEnterByType<T>() -> StreamSubscription` - run callback
    when Bloc enters specified state by type
  * `Bloc.onEnterByValue<T>() -> StreamSubscription` - run callback
    when Bloc enters specified state by value
  * `Bloc.isInByType<T>() -> bool` - checks if Bloc is in a state
    with Type of T
  * `Bloc.isInByValue() -> bool` - checks if Bloc is in a state with
    the state having defined value
  * `Bloc.untilNextByType<T>() -> T` - returns/waits until Bloc enters
    a state with type T
  * `Bloc.curryIsInByType<T>() -> Function` - returns a Function that 
    can be evaluated any number of times to check if a Bloc is in a
    state of type T
  * `SubsciprtionRegistry.onBlocEnterByType<T>() -> void` - triggers
    callback when Bloc enters state of type T. It also adds the stream
    subscription to `SubscriptionRegistry` so that is can be disposed/
    paused/resumed easily. 

## [0.3.0] - 2019-12-05

* add `Lazy` and `AsyncLazy` object for lazy initialization of value
* `Result.fold` now accepts generic parameter
* add `throttle` function
* add `FilteredConsumer`
* add `getCurrentRoute` helper function to quickly retrieve current route

## [0.2.0] - 2019-11-03

* Add `Result` object, which is a simplified interface for 
`package:dartz#Either.dart`. Useful tool to work with `package:bloc`.

## [0.1.0] - 2019-06-14

* Add `StreamObserver`
