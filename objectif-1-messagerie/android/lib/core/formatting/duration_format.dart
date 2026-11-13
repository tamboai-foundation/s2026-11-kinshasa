/// Durations the Wouanda way: « 4:05 », then « 1:02:09 » beyond an hour.
///
/// Countdowns, waiting times, calls and voice notes share this one clock
/// format; a negative duration reads as « 0:00 ».
String formatClock(Duration value) {
  final duration = value.isNegative ? Duration.zero : value;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  if (duration.inHours > 0) {
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '${duration.inHours}:$minutes:$seconds';
  }
  return '${duration.inMinutes}:$seconds';
}
