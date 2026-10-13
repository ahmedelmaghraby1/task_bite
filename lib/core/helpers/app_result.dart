/// A small, dependency-free result type used to surface failures from
/// repositories and services without relying on exceptions for control flow.
sealed class AppResult<T> {
  const AppResult();

  bool get isSuccess => this is AppSuccess<T>;
  bool get isFailure => this is AppFailure<T>;

  T? get valueOrNull => switch (this) {
    AppSuccess<T> success => success.value,
    AppFailure<T>() => null,
  };

  AppFailure<T>? get failureOrNull => switch (this) {
    AppSuccess<T>() => null,
    AppFailure<T> failure => failure,
  };
}

class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);
  final T value;
}

class AppFailure<T> extends AppResult<T> {
  const AppFailure(this.message, {this.cause});
  final String message;

  /// The underlying exception, when one is available. It is never rendered
  /// directly to users but kept for debugging and logging.
  final Object? cause;
}
