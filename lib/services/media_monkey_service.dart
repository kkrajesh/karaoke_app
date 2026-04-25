import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'media_monkey_service_stub.dart' if (dart.library.io) 'media_monkey_service_io.dart';

class MediaMonkeyService extends MediaMonkeyServiceImpl {}

final mediaMonkeyServiceProvider = Provider<MediaMonkeyService>((ref) {
  return MediaMonkeyService();
});
