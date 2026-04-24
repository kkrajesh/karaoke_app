import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_state_provider.dart';
import '../models/song.dart';
import 'youtube_service.dart';

class LocalServerService {
  final Ref ref;
  var _server;
  String? _ipAddress;

  LocalServerService(this.ref);

  String? get ipAddress => _ipAddress;

  Future<void> startServer() async {
    try {
      if (const bool.fromEnvironment('dart.library.html')) {
        _ipAddress = 'localhost (Web)';
      } else {
        final info = NetworkInfo();
        _ipAddress = await info.getWifiIP();
      }
    } catch (e) {
      _ipAddress = 'localhost';
      print('Could not find local IP: \$e');
    }

    if (_ipAddress == null) {
      _ipAddress = 'localhost';
    }

    final app = Router();

    // GET /queue
    app.get('/queue', (Request request) {
      final queue = ref.read(sessionStateProvider).queue;
      final queueList = queue.map((s) => s.toMap()).toList();
      return Response.ok(jsonEncode(queueList), headers: {'Content-Type': 'application/json'});
    });

    // POST /queue
    app.post('/queue', (Request request) async {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      final song = Song.fromMap(data, DateTime.now().millisecondsSinceEpoch.toString());
      
      ref.read(sessionStateProvider.notifier).addToQueue(song);
      return Response.ok('{"status":"ok"}', headers: {'Content-Type': 'application/json'});
    });

    // GET /now-playing
    app.get('/now-playing', (Request request) {
      final nowPlaying = ref.read(sessionStateProvider).nowPlaying;
      if (nowPlaying == null) {
        return Response.ok('{}', headers: {'Content-Type': 'application/json'});
      }
      return Response.ok(jsonEncode(nowPlaying.toMap()), headers: {'Content-Type': 'application/json'});
    });

    // POST /play-next
    app.post('/play-next', (Request request) {
      ref.read(sessionStateProvider.notifier).playNext();
      return Response.ok('{"status":"ok"}', headers: {'Content-Type': 'application/json'});
    });

    // DELETE /queue/<id>
    app.delete('/queue/<id>', (Request request, String id) {
      ref.read(sessionStateProvider.notifier).removeFromQueue(id);
      return Response.ok('{"status":"ok"}', headers: {'Content-Type': 'application/json'});
    });

    // GET /search?q=xyz
    app.get('/search', (Request request) async {
      final query = request.url.queryParameters['q'];
      if (query == null || query.isEmpty) {
        return Response.badRequest(body: 'Missing query parameter "q"');
      }

      try {
        final ytService = ref.read(youtubeServiceProvider);
        final results = await ytService.searchSongs(query);
        final resultList = results.map((s) => s.toMap()).toList();
        return Response.ok(jsonEncode(resultList), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Search failed: $e');
      }
    });

    // GET /reactions
    app.get('/reactions', (Request request) {
      final reactions = ref.read(sessionStateProvider).reactions;
      // Convert timestamps to ISO string if needed, or assume they serialize
      final formattedReactions = reactions.map((r) => {
        ...r,
        'timestamp': r['timestamp'] is DateTime 
            ? (r['timestamp'] as DateTime).toIso8601String() 
            : r['timestamp'],
      }).toList();
      return Response.ok(jsonEncode(formattedReactions), headers: {'Content-Type': 'application/json'});
    });

    // POST /reactions
    app.post('/reactions', (Request request) async {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      
      ref.read(sessionStateProvider.notifier).sendReaction(
        data['emoji'] ?? '',
        data['userId'] ?? 'audience',
      );
      
      return Response.ok('{"status":"ok"}', headers: {'Content-Type': 'application/json'});
    });

    // Simple CORS middleware
    Handler corsMiddleware(Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type',
          });
        }
        final response = await innerHandler(request);
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
        });
      };
    }

    // Serve Flutter Web App
    final staticHandler = createStaticHandler('build/web', defaultDocument: 'index.html');

    // Mount API and Static Handler
    final cascade = Cascade()
        .add(app.call)
        .add(staticHandler);

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsMiddleware)
        .addHandler(cascade.handler);

    _server = await io.serve(handler, '0.0.0.0', 8080);
    print('Serving at http://\${_ipAddress}:8080');
  }

  Future<void> stopServer() async {
    if (_server != null) {
      await _server.close(force: true);
    }
  }
}

final localServerProvider = Provider<LocalServerService>((ref) {
  return LocalServerService(ref);
});
