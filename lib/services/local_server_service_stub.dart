import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalServerService {
  final Ref ref;
  String? _ipAddress;

  LocalServerService(this.ref);

  String? get ipAddress => _ipAddress;
  bool get isRunning => false;

  Future<void> startServer() async {
    // Stub: No server on web
  }

  Future<void> stopServer() async {
    // Stub
  }
}

final localServerProvider = Provider<LocalServerService>((ref) {
  return LocalServerService(ref);
});
