/// Every invalidation is significant, even when the bridge repeats its topic.
/// Riverpod compares stream values: exposing the raw topic can suppress refresh.
/// This sequence is presentation invalidation only, never business state.
Stream<int> wouandaBridgeRevisions(Stream<Object?> signals) async* {
  var revision = 0;
  await for (final _ in signals) {
    yield ++revision;
  }
}
