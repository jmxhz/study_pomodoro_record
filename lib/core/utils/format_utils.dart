import 'package:intl/intl.dart';

class FormatUtils {
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _dateTimeMinuteFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthFormat = DateFormat('yyyy年M月');
  static final DateFormat _yearFormat = DateFormat('yyyy年');

  static String formatDateTime(DateTime value) => _dateTimeFormat.format(value);

  static String formatDateTimeMinute(DateTime value) => _dateTimeMinuteFormat.format(value);

  static String formatDate(DateTime value) => _dateFormat.format(value);

  static String formatMonth(DateTime value) => _monthFormat.format(value);

  static String formatYear(DateTime value) => _yearFormat.format(value);
}
