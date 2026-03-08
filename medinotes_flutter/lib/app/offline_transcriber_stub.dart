import 'offline_transcriber_base.dart';

OfflineTranscriber createPlatformOfflineTranscriber() {
  return const UnsupportedOfflineTranscriber();
}

class UnsupportedOfflineTranscriber implements OfflineTranscriber {
  const UnsupportedOfflineTranscriber();

  @override
  bool get isSupported => false;

  @override
  String get engineLabel => 'Whisper offline not available on web builds yet';

  @override
  Future<void> ensureReady() async {}

  @override
  Future<String> transcribeAudio(
    String audioPath, {
    String language = 'en',
  }) async {
    throw UnsupportedError(engineLabel);
  }
}
