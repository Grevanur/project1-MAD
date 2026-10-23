import 'package:adaptive_focus_studio/domain/focus_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rejects blank label',
    () => expect(FocusPreset.validateLabel('  '), isNotNull),
  );
  test(
    'accepts valid label',
    () => expect(FocusPreset.validateLabel('Algorithms'), isNull),
  );
  test(
    'rejects zero duration',
    () => expect(FocusPreset.validateDuration(0), isNotNull),
  );
  test('maps fields', () {
    const p = FocusPreset(
      id: 7,
      label: ' Read ',
      moodTag: 'calm',
      plannedSeconds: 1200,
    );
    expect(FocusPreset.fromMap(p.toMap()).label, 'Read');
  });
}
