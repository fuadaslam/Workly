import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains('.withOpacity(')) {
      final regex = RegExp(r'\.withOpacity\((.*?)\)');
      String newContent = content.replaceAllMapped(regex, (match) {
        return '.withValues(alpha: ${match.group(1)})';
      });
      if (content != newContent) {
        file.writeAsStringSync(newContent);
        print('Updated ${file.path}');
      }
    }
  }
}
