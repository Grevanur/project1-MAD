class FocusPreset {
  const FocusPreset({
    this.id,
    required this.label,
    required this.moodTag,
    required this.plannedSeconds,
  });
  final int? id;
  final String label;
  final String moodTag;
  final int plannedSeconds;
  Map<String, Object?> toMap() => {
    'id': id,
    'label': label.trim(),
    'mood_tag': moodTag.trim(),
    'planned_seconds': plannedSeconds,
  };
  factory FocusPreset.fromMap(Map<String, Object?> map) => FocusPreset(
    id: map['id'] as int?,
    label: map['label'] as String,
    moodTag: map['mood_tag'] as String,
    plannedSeconds: map['planned_seconds'] as int,
  );
  static String? validateLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Enter a preset label.';
    if (trimmed.length > 60) return 'Use 60 characters or fewer.';
    return null;
  }

  static String? validateDuration(int seconds) {
    if (seconds <= 0) return 'Duration must be greater than zero.';
    if (seconds > 4 * 60 * 60) return 'Duration cannot exceed four hours.';
    return null;
  }
}
