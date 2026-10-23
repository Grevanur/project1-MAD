import 'package:adaptive_focus_studio/application/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionController c;
  setUp(() => c = SessionController());
  test('starts', () {
    c.start(60);
    expect(c.state.phase, TimerPhase.running);
  });
  test(
    'rejects invalid duration',
    () => expect(() => c.start(0), throwsArgumentError),
  );
  test('ticks only while running', () {
    c.start(60);
    c.tick(5);
    c.pause();
    c.tick(5);
    expect(c.state.elapsedSeconds, 5);
  });
  test('pauses and resumes', () {
    c.start(60);
    c.pause();
    c.resume();
    expect(c.state.phase, TimerPhase.running);
  });
  test('prevents duplicate finish', () {
    c.start(60);
    c.tick(10);
    expect(c.finish(), 10);
    expect(c.finish, throwsStateError);
  });
  test('resets', () {
    c.start(60);
    c.reset();
    expect(c.state.phase, TimerPhase.idle);
  });
}
