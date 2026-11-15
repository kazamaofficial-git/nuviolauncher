/// Human readable byte size, e.g. `12.4 MB`.
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var i = 0;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i++;
  }
  return '${value.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
}

/// `YYYY-MM-DD` in local time.
String formatDate(DateTime d) {
  final l = d.toLocal();
  final m = l.month.toString().padLeft(2, '0');
  final day = l.day.toString().padLeft(2, '0');
  return '${l.year}-$m-$day';
}

/// `YYYY-MM-DD HH:mm` in local time.
String formatDateTime(DateTime d) {
  final l = d.toLocal();
  final h = l.hour.toString().padLeft(2, '0');
  final min = l.minute.toString().padLeft(2, '0');
  return '${formatDate(l)} $h:$min';
}

/// RAM label such as `4 GB` or `1.5 GB`.
String formatRam(int mb) {
  final gb = mb / 1024;
  return gb == gb.roundToDouble() ? '${gb.toInt()} GB' : '${gb.toStringAsFixed(1)} GB';
}
