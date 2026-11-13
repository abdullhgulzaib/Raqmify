import 'app_failure.dart';

/// Sealed Result type for explicit, type-safe error handling (S5).
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        Failure() => null,
      };

  AppFailure? get failureOrNull => switch (this) {
        Success() => null,
        Failure(failure: final f) => f,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      Success(data: final d) => success(d),
      Failure(failure: final f) => failure(f),
    };
  }
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);

  factory Failure.fromMessage(String message, {int? statusCode}) =>
      Failure(AppFailure(message: message, statusCode: statusCode));

  factory Failure.fromException(dynamic error) =>
      Failure(AppFailure.fromException(error));
}
