/// Why an authentication step failed.
enum AuthErrorKind {
  notConfigured,
  noAccount,
  noJava,
  noProfile,
  needsRelogin,
  network,
  denied,
  expired,
  cancelled,
  xbox,
  failed,
}

/// A user-facing authentication error (the [message] can be shown as is).
class AuthException implements Exception {
  const AuthException(this.kind, this.message);

  const AuthException.network([
    this.message = 'Cannot reach the server. Check your internet connection and try again.',
  ]) : kind = AuthErrorKind.network;

  const AuthException.cancelled()
      : kind = AuthErrorKind.cancelled,
        message = 'Sign-in cancelled.';

  const AuthException.needsRelogin([
    this.message = 'This account must sign in again. Open Accounts and choose "Sign in again".',
  ]) : kind = AuthErrorKind.needsRelogin;

  final AuthErrorKind kind;
  final String message;

  @override
  String toString() => message;
}
