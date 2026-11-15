/// Cooperative cancellation for device-login polling.
class AuthCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// Sleeps [total] in one-second slices so [cancel] is honoured quickly.
Future<void> sleepCancellable(
  Duration total,
  Future<void> Function(Duration) delay,
  AuthCancelToken? cancel,
) async {
  var left = total;
  const slice = Duration(seconds: 1);
  while (left > Duration.zero) {
    if (cancel?.isCancelled ?? false) return;
    final step = left > slice ? slice : left;
    await delay(step);
    left -= step;
  }
}
