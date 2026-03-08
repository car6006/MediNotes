import 'offline_transcriber_base.dart';
import 'offline_transcriber_stub.dart'
    if (dart.library.io) 'offline_transcriber_native.dart';

export 'offline_transcriber_base.dart';

OfflineTranscriber createOfflineTranscriber() {
  return createPlatformOfflineTranscriber();
}
