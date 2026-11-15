/// Represents either a successful operation or a typed application failure.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => switch (this) {
    Success<T> success => success.data,
    Failure<T> _ => null,
  };

  AppError? get error => switch (this) {
    Success<T> _ => null,
    Failure<T> failure => failure.error,
  };

  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T> success => Result.success(transform(success.data)),
    Failure<T> failure => Result.failure(failure.error),
  };

  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) => switch (this) {
    Success<T> value => success(value.data),
    Failure<T> value => failure(value.error),
  };

  static Result<T> success<T>(T data) => Success(data);
  static Result<T> failure<T>(AppError error) => Failure(error);
}

class Success<T> extends Result<T> {
  const Success(this.data);

  @override
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.error);

  @override
  final AppError error;
}

/// A user-safe error shared by service, repository and presentation layers.
class AppError {
  const AppError({
    required this.code,
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
  });

  final String code;
  final String message;
  final String? userMessage;
  final Object? originalError;
  final StackTrace? stackTrace;

  static const networkError = AppError(
    code: 'NETWORK_ERROR',
    message: 'Network request failed',
    userMessage: 'Connexion impossible. Vérifiez votre connexion internet.',
  );
  static const unauthorized = AppError(
    code: 'UNAUTHORIZED',
    message: 'Authentication required',
    userMessage: 'Veuillez vous connecter pour continuer.',
  );
  static const notFound = AppError(
    code: 'NOT_FOUND',
    message: 'Resource not found',
    userMessage: 'La ressource demandée est introuvable.',
  );
  static const serverError = AppError(
    code: 'SERVER_ERROR',
    message: 'Internal server error',
    userMessage: 'Une erreur serveur est survenue. Réessayez plus tard.',
  );
  static const timeout = AppError(
    code: 'TIMEOUT',
    message: 'Request timeout',
    userMessage: 'La requête a pris trop de temps. Réessayez.',
  );
  static const insufficientFunds = AppError(
    code: 'INSUFFICIENT_FUNDS',
    message: 'Insufficient wallet balance',
    userMessage: 'Solde insuffisant. Rechargez votre wallet.',
  );
  static const offlineAction = AppError(
    code: 'OFFLINE_ACTION',
    message: 'Action requires connectivity',
    userMessage: 'Cette action nécessite une connexion internet.',
  );

  factory AppError.unknown(Object error, [StackTrace? stackTrace]) => AppError(
    code: 'UNKNOWN',
    message: error.toString(),
    userMessage: 'Une erreur inattendue est survenue.',
    originalError: error,
    stackTrace: stackTrace,
  );

  @override
  String toString() => 'AppError($code: $message)';
}

/// Base repository behavior that does not depend on Flutter or a UI framework.
abstract class BaseRepository {
  Future<Result<T>> safeCall<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } on FormatException catch (error, stackTrace) {
      return Result.failure(
        AppError(
          code: 'FORMAT_ERROR',
          message: error.message,
          userMessage: 'Données invalides reçues.',
          originalError: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return Result.failure(AppError.unknown(error, stackTrace));
    }
  }
}
