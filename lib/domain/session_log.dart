enum SessionStatus { finished, reset }

class SessionLog {
  const SessionLog({
    this.id,
    required this.presetId,
    required this.startedAt,
    required this.completedSeconds,
    required this.moodTagSnapshot,
    required this.status,
    required this.source,
    this.note = '',
  });
  final int? id;
  final int presetId;
  final DateTime startedAt;
  final int completedSeconds;
  final String moodTagSnapshot;
  final SessionStatus status;
  final String source;
  final String note;
  Map<String, Object?> toMap() => {
    'id': id,
    'preset_id': presetId,
    'started_at': startedAt.toUtc().toIso8601String(),
    'completed_seconds': completedSeconds,
    'mood_tag_snapshot': moodTagSnapshot,
    'status': status.name,
    'source': source,
    'note': note.trim(),
  };
  factory SessionLog.fromMap(Map<String, Object?> map) => SessionLog(
    id: map['id'] as int?,
    presetId: map['preset_id'] as int,
    startedAt: DateTime.parse(map['started_at'] as String),
    completedSeconds: map['completed_seconds'] as int,
    moodTagSnapshot: map['mood_tag_snapshot'] as String,
    status: SessionStatus.values.byName(map['status'] as String),
    source: map['source'] as String,
    note: map['note'] as String? ?? '',
  );
}
