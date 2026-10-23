enum TimerPhase { idle, running, paused, finished }

class SessionState {
  const SessionState({
    this.phase = TimerPhase.idle,
    this.plannedSeconds = 0,
    this.elapsedSeconds = 0,
  });
  final TimerPhase phase;
  final int plannedSeconds;
  final int elapsedSeconds;
  int get remainingSeconds =>
      (plannedSeconds - elapsedSeconds).clamp(0, plannedSeconds);
  SessionState copyWith({
    TimerPhase? phase,
    int? plannedSeconds,
    int? elapsedSeconds,
  }) => SessionState(
    phase: phase ?? this.phase,
    plannedSeconds: plannedSeconds ?? this.plannedSeconds,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
  );
}

class SessionController {
  SessionState _state = const SessionState();
  SessionState get state => _state;
  void start(int seconds) {
    if (seconds <= 0) throw ArgumentError('Duration must be positive.');
    if (_state.phase == TimerPhase.running ||
        _state.phase == TimerPhase.paused) {
      throw StateError('A session is already active.');
    }
    _state = SessionState(phase: TimerPhase.running, plannedSeconds: seconds);
  }

  void tick([int seconds = 1]) {
    if (_state.phase != TimerPhase.running || seconds <= 0) return;
    _state = _state.copyWith(
      elapsedSeconds: (_state.elapsedSeconds + seconds).clamp(
        0,
        _state.plannedSeconds,
      ),
    );
  }

  void pause() {
    if (_state.phase != TimerPhase.running) {
      throw StateError('Only a running session can be paused.');
    }
    _state = _state.copyWith(phase: TimerPhase.paused);
  }

  void resume() {
    if (_state.phase != TimerPhase.paused) {
      throw StateError('Only a paused session can be resumed.');
    }
    _state = _state.copyWith(phase: TimerPhase.running);
  }

  int finish() {
    if (_state.phase != TimerPhase.running &&
        _state.phase != TimerPhase.paused) {
      throw StateError('The session cannot be finished twice.');
    }
    _state = _state.copyWith(phase: TimerPhase.finished);
    return _state.elapsedSeconds;
  }

  void reset() => _state = const SessionState();
}
