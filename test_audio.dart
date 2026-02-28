import 'dart:io';

void main() async {
  final ext = 'ogg';
  String mimeType = 'audio/mpeg'; // default
  if (ext == 'ogg') mimeType = 'audio/ogg';
  print(mimeType);
}
