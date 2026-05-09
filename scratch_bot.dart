import 'dart:io';
void main() {
  final html = File('smule_bot.html').readAsStringSync();
  print('Length: ${html.length}');
  print('Has window.Data: ${html.contains('window.Data =')}');
  final r = RegExp(r'<a[^>]*href="(/recording/[^/]+/[^"]+)"[^>]*title="([^"]+)"');
  print('Matches: ${r.allMatches(html).length}');
}
