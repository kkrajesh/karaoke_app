import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/library_song.dart';
import '../providers/app_state_provider.dart';

class SmuleService {
  static const String _userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  final String? clientIp;

  SmuleService({this.clientIp});

  Future<List<LibrarySong>> searchPerformances(String query, {bool isProxy = false}) async {
    if (kIsWeb && !isProxy) {
      try {
        final ip = clientIp ?? '127.0.0.1';
        final url = Uri.parse('http://$ip:8080/smule-search?q=${Uri.encodeComponent(query)}');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          return data.map((json) => LibrarySong.fromMap(json)).toList();
        }
      } catch (e) {
        print('Smule Web Proxy Error: $e');
      }
      return [];
    }

    try {
      final url = Uri.parse('https://www.smule.com/search?q=${Uri.encodeComponent(query)}&type=recording');
      final response = await http.get(url, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final body = response.body;
        final results = <LibrarySong>[];
        final recordingRegex = RegExp(
          r'<a[^>]*href="(/recording/[^/]+/[^"]+)"[^>]*title="([^"]+)"',
        );
        
        final matches = recordingRegex.allMatches(body);
        final seenUrls = <String>{};
        
        for (final m in matches) {
          final smulePath = m.group(1);
          final fullTitle = m.group(2)?.replaceAll('&amp;', '&').replaceAll('&#39;', "'") ?? 'Unknown Song';
          if (smulePath == null || seenUrls.contains(smulePath)) continue;
          
          seenUrls.add(smulePath);
          
          final parts = fullTitle.split(' - ');
          final artist = parts.length > 1 ? parts.first : 'Smule User';
          final title = parts.length > 1 ? parts.sublist(1).join(' - ') : fullTitle;

          results.add(LibrarySong(
            id: 'smule_$smulePath',
            title: title.trim(),
            artist: artist.trim(),
            source: 'smule',
            videoId: 'https://www.smule.com$smulePath',
            hasPreview: true,
          ));
        }
        
        return results;
      }
      return [];
    } catch (e) {
      print('Error searching Smule: $e');
      return [];
    }
  }

  Future<String?> getMediaUrl(String smuleUrl, {bool isProxy = false}) async {
    if (kIsWeb && !isProxy) {
      try {
        final ip = clientIp ?? '127.0.0.1';
        final url = Uri.parse('http://$ip:8080/smule-media?url=${Uri.encodeComponent(smuleUrl)}');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['url'];
        }
      } catch (e) {
        print('Smule Media Web Proxy Error: $e');
      }
      return null;
    }

    try {
      final response = await http.get(Uri.parse(smuleUrl), headers: {'User-Agent': _userAgent});
      if (response.statusCode == 200) {
        final regex = RegExp(r'<meta\s+name="twitter:player:stream"\s+content="([^"]+)"');
        final match = regex.firstMatch(response.body);
        if (match != null) {
          return match.group(1)?.replaceAll('&amp;', '&');
        }
      }
      return null;
    } catch (e) {
      print('Error extracting Smule media URL: $e');
      return null;
    }
  }
}

final smuleServiceProvider = Provider<SmuleService>((ref) {
  final ip = ref.watch(clientHostIpProvider);
  return SmuleService(clientIp: ip);
});
