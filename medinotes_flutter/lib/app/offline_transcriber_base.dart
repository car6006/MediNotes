abstract class OfflineTranscriber {
  bool get isSupported;
  String get engineLabel;

  Future<void> ensureReady();

  Future<String> transcribeAudio(String audioPath, {String language = 'en'});
}
