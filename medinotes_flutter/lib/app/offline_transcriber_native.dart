import 'dart:io';

import 'package:whisper_ggml/whisper_ggml.dart';

import 'offline_transcriber_base.dart';

OfflineTranscriber createPlatformOfflineTranscriber() {
  return NativeWhisperOfflineTranscriber();
}

class NativeWhisperOfflineTranscriber implements OfflineTranscriber {
  NativeWhisperOfflineTranscriber();

  final WhisperController _controller = WhisperController();
  final WhisperModel _model = WhisperModel.base;
  bool _isReady = false;

  @override
  bool get isSupported => true;

  @override
  String get engineLabel => 'Whisper GGML offline (${_model.modelName})';

  @override
  Future<void> ensureReady() async {
    if (_isReady) {
      return;
    }

    final modelPath = await _controller.getPath(_model);
    final modelFile = File(modelPath);

    if (!modelFile.existsSync()) {
      await _controller.downloadModel(_model);
    }

    await _controller.initModel(_model);
    _isReady = true;
  }

  @override
  Future<String> transcribeAudio(
    String audioPath, {
    String language = 'en',
  }) async {
    await ensureReady();

    final result = await _controller.transcribe(
      model: _model,
      audioPath: audioPath,
      lang: language,
    );

    return result?.transcription.text.trim() ?? '';
  }
}
