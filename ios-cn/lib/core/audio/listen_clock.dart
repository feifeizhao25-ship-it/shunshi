/// Counts how long audio actually played, for the daily audio-minutes quota.
///
/// The player's position says where in the track you are, not how long you listened (a seek moves it for free),
/// so playback time is measured separately: [setPlaying] when the player starts/stops, [takeSeconds] when a report
/// is sent. Left-over milliseconds are kept for the next report; [giveBack] restores seconds from a failed report.
class ListenClock {
  ListenClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  DateTime? _since;
  int _ms = 0;

  bool get isPlaying => _since != null;

  void setPlaying(bool playing) {
    if (playing && _since == null) {
      _since = _now();
    } else if (!playing && _since != null) {
      _ms += _now().difference(_since!).inMilliseconds;
      _since = null;
    }
  }

  /// Whole seconds listened since the last call.
  int takeSeconds() {
    if (_since != null) {
      final t = _now();
      _ms += t.difference(_since!).inMilliseconds;
      _since = t;
    }
    final s = _ms ~/ 1000;
    _ms -= s * 1000;
    return s;
  }

  void giveBack(int seconds) => _ms += seconds * 1000;
}
