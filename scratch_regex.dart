import 'dart:io';
void main() {
  final html = File('smule_curl.html').readAsStringSync();
  final r = RegExp(r'<a[^>]*href="(/recording/[^/]+/[^"]+)"[^>]*title="([^"]+)"');
  final matches = r.allMatches(html);
  print('Matches: ${matches.length}');
  
  if (matches.isEmpty) {
    // try finding any recording link
    final alt = RegExp(r'href="(/recording/[^/]+/[^"]+)"');
    print('Alt matches: ${alt.allMatches(html).length}');
  } else {
    for (var m in matches.take(3)) {
      print('${m.group(1)} -> ${m.group(2)}');
    }
  }
}
