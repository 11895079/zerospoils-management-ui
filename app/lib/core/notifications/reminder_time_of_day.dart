/// Maps a DateTime to a time of day category.
/// Returns "morning", "afternoon", or "evening".
String timeOfDayFor(DateTime dateTime) {
  final hour = dateTime.hour;

  if (hour >= 5 && hour < 12) {
    return 'morning';
  } else if (hour >= 12 && hour < 18) {
    return 'afternoon';
  } else {
    return 'evening';
  }
}
