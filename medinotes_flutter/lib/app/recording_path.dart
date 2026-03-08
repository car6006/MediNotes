import 'recording_path_stub.dart'
    if (dart.library.io) 'recording_path_native.dart';

Future<String> createRecordingPath() {
  return createPlatformRecordingPath();
}
