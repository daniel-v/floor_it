import 'package:floor_it/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should equal by value', () {
    final r1 = ResultSuccess(5);
    final r2 = ResultSuccess(5);
    final r3 = ResultSuccess(6);
    final r4 = ResultSuccess(null);
    expect(r1 == r2, isTrue);
    expect(r1 == r3, isFalse);
    expect(r1 == r4, isFalse);
  });
  test('should equal by type', () {
    final Result<String, int> r1 = ResultSuccess(5);
    final Result<String, int> r2 = ResultSuccess(5);
    final Result<String, int> r3 = ResultFailure('Ooops');
    final Result<String, int> r4 = ResultSuccess(null);
    expect(r1 == r2, isTrue);
    expect(r1 == r3, isFalse);
    expect(r1 == r4, isFalse);
  });
  test('should return isSuccess properly', () {
    final Result r1 = ResultSuccess(5);
    final Result r2 = ResultFailure('Ooops');
    expect(r1.isSuccess, isTrue);
    expect(r2.isSuccess, isFalse);
  });
  test('should throw on invalid cast', () {
    final Result r1 = ResultSuccess(5);
    final Result r2 = ResultFailure(5);
    expect(() {
      r1.asFailure;
    }, throwsStateError);
    expect(() {
      r2.asSuccess;
    }, throwsStateError);
  });
  test('should return result on successful cast', () {
    final Result r1 = ResultSuccess(5);
    final Result r2 = ResultFailure('oops');
    expect(r1.asSuccess, ResultSuccess(5));
    expect(r2.asFailure, ResultFailure('oops'));
  });
}
