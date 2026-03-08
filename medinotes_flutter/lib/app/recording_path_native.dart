import 'package:path_provider/path_provider.dart';

Future<String> createPlatformRecordingPath() async {
  final directory = await getTemporaryDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${directory.path}/medinotes_$timestamp.m4a';
}
