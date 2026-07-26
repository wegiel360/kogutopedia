import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime date) => _dateFormat.format(date);

  static String formatTime(DateTime date) => _timeFormat.format(date);

  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  static String formatIsoDate(DateTime date) => _isoFormat.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'przed chwilą';
    if (diff.inHours < 1) return '${diff.inMinutes} min temu';
    if (diff.inDays < 1) return '${diff.inHours} h temu';
    if (diff.inDays < 7) return '${diff.inDays} dni temu';
    return formatDate(date);
  }

  static String dateKey(DateTime date) => formatIsoDate(date);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
