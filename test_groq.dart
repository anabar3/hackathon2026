import 'dart:io';
import 'lib/services/groq_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final groq = GroqService();
  print("Groq service loaded");
}
