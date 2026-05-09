import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final query = 'ruk ja';
  final url = Uri.parse('https://www.smule.com/search?q=${Uri.encodeComponent(query)}&type=recording');
  final _userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  
  try {
    final response = await http.get(url, headers: {'User-Agent': _userAgent});
    print('Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final body = response.body;
      File('smule_body.html').writeAsStringSync(body);
      
      final recordingRegex = RegExp(r'<a[^>]*href="(/recording/[^/]+/[^"]+)"[^>]*title="([^"]+)"');
      final matches = recordingRegex.allMatches(body);
      print('Matches using standard regex: ${matches.length}');
      
      // Let's try to find ANY recording links
      final altRegex = RegExp(r'href="(/recording/[^/]+/[^"]+)"');
      final altMatches = altRegex.allMatches(body);
      print('Matches for just /recording/ hrefs: ${altMatches.length}');
      
      // Let's try to extract from window.Data
      final dataRegex = RegExp(r'window\.Data\s*=\s*(\{.*?\});\s*</script>');
      final dataMatch = dataRegex.firstMatch(body);
      if (dataMatch != null) {
        print('Found window.Data!');
        final jsonStr = dataMatch.group(1);
        File('smule_data.json').writeAsStringSync(jsonStr!);
      } else {
        print('window.Data not found.');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
