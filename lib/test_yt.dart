import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  print('Initializing...');
  final yt = YoutubeExplode();
  print('Searching...');
  try {
    final searchResults = await yt.search.search('test karaoke');
    print('Found: \${searchResults.length}');
    for (var video in searchResults.take(3)) {
      print('- \${video.title}');
    }
  } catch (e, stack) {
    print('Error: \$e');
    print(stack);
  } finally {
    yt.close();
  }
}
