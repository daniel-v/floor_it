import 'dart:async';

/// Simplification of `package:dartz#Either` to reduce boilerplate and create
/// a prettier API keeping the power of it's most used features.
abstract class Result<Failure, Success> {
  Success get _successValue;

  Failure get _failureValue;

  bool get isSuccess;

  ResultSuccess<Failure, Success> get asSuccess =>
    isSuccess ? this : throw StateError('ResultFailre cannot be accessed as success');

  ResultFailure<Failure, Success> get asFailure =>
    !isSuccess ? this : throw StateError('ResultFailre cannot be accessed as success');

  FutureOr<T> fold<T>(T onFailure(Failure f), T onSuccess(Success s)) {
    return isSuccess ? onSuccess(_successValue) : onFailure(_failureValue);
  }

  dynamic get value;
}

class ResultSuccess<F, S> extends Result<F, S> {
  @override
  final S _successValue;

  ResultSuccess(this._successValue);

  @override
  bool get isSuccess => true;

  @override
  S get value => _successValue;

  @override
  F get _failureValue => null;

  @override
  int get hashCode => (0 + _successValue.hashCode) ^ 17;

  @override
  bool operator ==(other) {
    return identical(this, other) || other is ResultSuccess && _successValue == other._successValue;
  }
}

class ResultFailure<F, S> extends Result<F, S> {
  @override
  final F _failureValue;

  ResultFailure(this._failureValue);

  @override
  bool get isSuccess => false;

  @override
  F get value => _failureValue;

  @override
  S get _successValue => null;

  @override
  int get hashCode => (0 + _failureValue.hashCode) ^ 17;

  @override
  bool operator ==(other) {
    return identical(this, other) || other is ResultFailure && _failureValue == other._failureValue;
  }
}
