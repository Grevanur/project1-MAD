/// Display helpers. Durations are stored in seconds and shown in minutes.
String formatClock(int totalSeconds) {
  final safe = totalSeconds < 0 ? 0 : totalSeconds;
  final minutes = safe ~/ 60;
  final seconds = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String formatMinutes(num seconds) {
  if (seconds > 0 && seconds < 60) return '${seconds.round()} sec';
  final minutes = seconds / 60;
  if (minutes == minutes.roundToDouble()) return '${minutes.round()} min';
  return '${minutes.toStringAsFixed(1)} min';
}

String spokenClock(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes minutes $seconds seconds remaining';
}

String formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final suffix = local.hour < 12 ? 'AM' : 'PM';
  return '${local.month}/${local.day}/${local.year} '
      '$hour:${local.minute.toString().padLeft(2, '0')} $suffix';
}

String formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.month}/${local.day}/${local.year}';
}
