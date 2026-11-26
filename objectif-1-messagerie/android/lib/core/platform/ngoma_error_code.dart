/// Cross-module error codes of the bridge protocol
/// (docs/protocol/PROTOCOLE_NGOMA.md §3.2). Module codes stay prefixed in
/// their own contract (`GO_…`, `DRIVER_…`).
abstract final class NgomaErrorCode {
  static const authRequired = 'AUTH_REQUIRED';
  static const forbidden = 'FORBIDDEN';
  static const notFound = 'NOT_FOUND';
  static const validationFailed = 'VALIDATION_FAILED';
  static const offline = 'OFFLINE';
  static const serverError = 'SERVER_ERROR';
}
