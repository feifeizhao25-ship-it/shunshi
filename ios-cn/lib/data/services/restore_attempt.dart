import 'dart:async';

/// Bound UI waiting without cancelling receipt verification or granting access.
class RestoreAttempt<T> {
  RestoreAttempt({
    required this.isSuccess,
    required this.pendingResult,
    required this.failedResult,
    this.timeout = const Duration(seconds: 30),
  });
  final bool Function(T) isSuccess;
  final T pendingResult, failedResult;
  final Duration timeout;
  Completer<T>? _active;
  Timer? _timer;
  int _generation = 0;
  int? get activeId => _active == null ? null : _generation;

  Future<T> run(Future<void> Function() launch) {
    if (_active != null) return _active!.future;
    final id = ++_generation;
    final completion = _active = Completer<T>();
    _timer = Timer(timeout, () => _finish(id, pendingResult));
    unawaited(
      Future<void>.sync(launch).then(
        (_) {},
        onError: (Object error, StackTrace stack) {
          _finish(id, failedResult);
        },
      ),
    );
    return completion.future;
  }

  void report(int? id, T result) {
    // One invalid/expired receipt must not hide a later valid receipt.
    if (id != null && isSuccess(result)) _finish(id, result);
  }

  void _finish(int id, T result) {
    if (id != _generation || _active == null) return;
    final completion = _active!;
    _active = null;
    _timer?.cancel();
    _timer = null;
    completion.complete(result);
  }

  void cancel() {
    if (_active != null) _finish(_generation, pendingResult);
  }
}
