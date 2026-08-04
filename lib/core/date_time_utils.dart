/// Merges a calendar [date] (e.g. from [showDatePicker]) with the current
/// clock time so multiple events on the same day keep chronological order.
DateTime dateWithCurrentTime(DateTime date) {
  final now = DateTime.now();
  return DateTime(
    date.year,
    date.month,
    date.day,
    now.hour,
    now.minute,
    now.second,
    now.millisecond,
    now.microsecond,
  );
}
