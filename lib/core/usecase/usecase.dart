import '../errors/failures.dart';

// Note: Using standard Flutter Either-like structure. If we didn't add dartz,
// we can implement a simple custom Either class, or use a Result pattern, or import dartz.
// Wait! Let's check if we added dartz to pubspec.yaml. We did not add dartz.
// Let's create a beautiful custom Result or Either class so we don't need additional heavy libraries, 
// or we can use a custom result wrapper: `Future<Result<T>>` where Result is a sealed class.
// Sealed classes are standard, beautiful, and native in Dart 3! Excellent modern choice.

sealed class Result<S, E> {
  const Result();
}

class Success<S, E> extends Result<S, E> {
  final S value;
  const Success(this.value);
}

class FailureResult<S, E> extends Result<S, E> {
  final E error;
  const FailureResult(this.error);
}

abstract class UseCase<T, Params> {
  Future<Result<T, Failure>> call(Params params);
}

class NoParams {}
