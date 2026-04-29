import 'dart:convert';
import 'dart:io' as dart_io;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_state_provider.dart';
import '../services/media_monkey_service.dart';
import '../models/song.dart';
import 'youtube_service.dart';

class LocalServerService {
  final Ref ref;
  var _server;
  String? _ipAddress;

  LocalServerService(this.ref);

  String? get ipAddress => _ipAddress;
  bool get isRunning => _server != null;

  Future<void> startServer() async {
    if (_server != null) return; // Already running
    
    try {
      if (const bool.fromEnvironment('dart.library.html')) {
        _ipAddress = 'localhost (Web)';
      } else {
        final info = NetworkInfo();
        _ipAddress = await info.getWifiIP();
      }
    } catch (e) {
      _ipAddress = 'localhost';
      print('Could not find local IP: $e');
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

    // PUT /queue/<id>/approve
    app.put('/queue/<id>/approve', (Request request, String id) async {
      String? assignedSinger;
      try {
        final payload = await request.readAsString();
        if (payload.isNotEmpty) {
          final data = jsonDecode(payload);
          assignedSinger = data['assignedSinger'];
        }
      } catch (e) {
        // ignore JSON parse errors if body is empty
      }
      ref.read(sessionStateProvider.notifier).approveRequest(id, assignedSinger: assignedSinger);
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
      final state = ref.read(sessionStateProvider);
      final formattedReactions = state.reactions.map((r) => {
        ...r,
        'timestamp': r['timestamp'] is DateTime 
            ? (r['timestamp'] as DateTime).toIso8601String() 
            : r['timestamp'],
      }).toList();
      
      final responseBody = {
        'reactions': formattedReactions,
        'emojiCounts': state.emojiCounts,
      };
      return Response.ok(jsonEncode(responseBody), headers: {'Content-Type': 'application/json'});
    });

    // POST /reactions
    app.post('/reactions', (Request request) async {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      
      ref.read(sessionStateProvider.notifier).sendReaction(
        data['user'] ?? 'audience',
        data['value'] ?? '',
        isEmoji: data['isEmoji'] ?? true,
      );
      
      return Response.ok('{"status":"ok"}', headers: {'Content-Type': 'application/json'});
    });

    // GET /display-state
    app.get('/display-state', (Request request) {
      final state = ref.read(sessionStateProvider);
      final responseBody = {
        'announcement': state.announcement,
        'countdownEndTime': state.countdownEndTime,
      };
      return Response.ok(jsonEncode(responseBody), headers: {'Content-Type': 'application/json'});
    });

    // POST /display-state/announcement
    app.post('/display-state/announcement', (Request request) async {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      ref.read(sessionStateProvider.notifier).pushAnnouncement(data['announcement']);
      return Response.ok('{"status":"ok"}', headers: {'Content-Type': 'application/json'});
    });

    // POST /display-state/countdown
    app.post('/display-state/countdown', (Request request) async {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      
      final endTimeMs = data['countdownEndTime'] as int?;
      // Note: We're setting the end time directly via state rather than pushCountdown which calculates it
      ref.read(sessionStateProvider.notifier).state = ref.read(sessionStateProvider.notifier).state.copyWith(
        countdownEndTime: endTimeMs,
        clearCountdown: endTimeMs == null,
      );
      return Response.ok('{"status":"ok"}', headers: {'Content-Type': 'application/json'});
    });

    app.get('/local-media', (Request request) {
      final path = request.url.queryParameters['path'];
      if (path == null) return Response.notFound('No path provided');
      final file = dart_io.File(path);
      if (!file.existsSync()) return Response.notFound('File not found');
      
      final range = request.headers['range'];
      if (range != null && range.startsWith('bytes=')) {
        final parts = range.substring(6).split('-');
        final start = int.parse(parts[0]);
        final end = parts.length > 1 && parts[1].isNotEmpty ? int.parse(parts[1]) : file.lengthSync() - 1;
        final length = end - start + 1;
        
        return Response(206, body: file.openRead(start, end + 1), headers: {
          'Content-Type': 'video/mp4',
          'Accept-Ranges': 'bytes',
          'Content-Length': length.toString(),
          'Content-Range': 'bytes $start-$end/${file.lengthSync()}',
        });
      }

      return Response.ok(file.openRead(), headers: {
        'Content-Type': 'video/mp4',
        'Accept-Ranges': 'bytes',
        'Content-Length': file.lengthSync().toString(),
      });
    });

    app.get('/local-search', (Request request) async {
      final query = request.url.queryParameters['q'];
      if (query == null) {
        return Response.badRequest(body: 'Missing query parameter "q"');
      }
      
      final mmService = ref.read(mediaMonkeyServiceProvider);
      final results = await mmService.searchSongs(query);
      
      final jsonList = results.map((song) => song.toMap()).toList();
      return Response.ok(jsonEncode(jsonList), headers: {'Content-Type': 'application/json'});
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

    // Mount API and conditionally add Static Handler if web build exists
    var cascade = Cascade().add(app.call);
    
    if (dart_io.Directory('build/web').existsSync()) {
      final staticHandler = createStaticHandler('build/web', defaultDocument: 'index.html');
      cascade = cascade.add(staticHandler);
    } else {
      print('Warning: build/web directory not found. Web clients will not be served.');
    }

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsMiddleware)
        .addHandler(cascade.handler);

    _server = await io.serve(handler, '0.0.0.0', 8080);
    print('Serving at http://${_ipAddress}:8080');
  }

  Future<void> stopServer() async {
    if (_server != null) {
      await _server.close(force: true);
      _server = null;
    }
  }
}

final localServerProvider = Provider<LocalServerService>((ref) {
  return LocalServerService(ref);
});
