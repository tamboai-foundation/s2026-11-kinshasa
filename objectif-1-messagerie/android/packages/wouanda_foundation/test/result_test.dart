import 'package:test/test.dart';
import 'package:wouanda_foundation/wouanda_foundation.dart';

void main() {
  test('maps a successful result without a Flutter dependency', () {
    final result = Result.success(2).map((value) => value * 3);

    expect(result.data, 6);
    expect(result.error, isNull);
    expect(result.isSuccess, isTrue);
  });

  test('preserves a typed failure', () {
    const error = AppError(code: 'OFFLINE', message: 'offline');
    final result = Result.failure<int>(error);

    expect(result.data, isNull);
    expect(result.error, same(error));
    expect(result.isFailure, isTrue);
  });
}
