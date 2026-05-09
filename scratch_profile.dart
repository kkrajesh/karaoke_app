import 'dart:io';
void main() {
  final html = File('smule_profile.html').readAsStringSync();
  print('Length: ${html.length}');
  print('Has window.Data: ${html.contains('window.Data =')}');
}
