import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ai_suggestion.dart';

class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<AiSuggestionResponse> analyzeInbox(
    List<Map<String, dynamic>> boards,
    List<Map<String, dynamic>> inboxItems,
  ) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'pon_tu_api_key_aqui') {
      throw Exception('GROQ_API_KEY is not properly set in .env');
    }

    final userBoardsJson = boards
        .map(
          (b) => {
            'id': b['id'] ?? '',
            'name': b['titulo'] ?? '',
            'description': b['descripcion'] ?? '',
          },
        )
        .toList();

    final systemPrompt = """
You are an AI assistant that organizes an inbox of digital content into boards.
You will receive a list of existing user boards and a list of unorganized inbox items.
Your task is to analyze ALL inbox items together and suggest one action for EACH item.

IMPORTANT CLASSIFICATION RULES:
1. DO NOT classify items based on their file type or format (e.g., do not create generic boards like "Images", "Videos", "Documents", or "Links").
2. Instead, analyze the actual CONTENT, topic, or meaning of the item and group them semantically (e.g., "Travel Plans", "Work Project", "Recipes").

Actions can be:
- "use_existing": move the item to an existing board.
- "create_new": suggest creating a new board that would fit this item's topic (and potentially other similar items in the inbox).

Output STRICTLY in the following JSON schema:
{
  "suggestions": [
    {
      "item_id": "string",
      "action": "create_new" or "use_existing",
      "board_id": "string or null",
      "new_board_suggestion": {
         "name": "string",
         "description": "string"
      } or null,
      "reasoning": "short explanation"
    }
  ]
}
""";

    // Reconstruct the message content as a vision-compatible array
    final List<Map<String, dynamic>> userContentArray = [
      {
        "type": "text",
        "text":
            "User Boards:\n${jsonEncode(userBoardsJson)}\n\nInbox Items to analyze:\n",
      },
    ];

    for (var i in inboxItems) {
      final tipo = i['tipo'] ?? '';
      final isImage = tipo == 'imagen';
      final isLink = tipo == 'link';
      final isAudio = tipo == 'audio';
      final isArchivo = tipo == 'archivo';
      final contentVal = i['contenido'] ?? '';
      final rawData = i['metadatos'] ?? i['raw_data'] ?? {};

      String extraContent = "";
      if (isLink && rawData is Map && rawData.containsKey('scraped_text')) {
        extraContent = "Scraped Link Content:\n${rawData['scraped_text']}";
      } else if (isAudio &&
          rawData is Map &&
          rawData.containsKey('transcription')) {
        extraContent = "Audio Transcription:\n${rawData['transcription']}";
      } else if (isArchivo &&
          rawData is Map &&
          rawData.containsKey('extracted_text')) {
        extraContent = "Document Content:\n${rawData['extracted_text']}";
      }

      final itemContext =
          "Item ID: ${i['id']}\nType: $tipo\nTitle: ${i['titulo'] ?? ''}\n$extraContent\n";

      if (isImage && contentVal.toString().isNotEmpty) {
        userContentArray.add({
          "type": "text",
          "text": itemContext + "Image content:\n",
        });
        userContentArray.add({
          "type": "image_url",
          "image_url": {"url": contentVal},
        });
      } else {
        userContentArray.add({
          "type": "text",
          "text": itemContext + "Content: $contentVal\n",
        });
      }
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "meta-llama/llama-4-scout-17b-16e-instruct",
        "response_format": {"type": "json_object"},
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userContentArray},
        ],
        "temperature": 0.3,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return AiSuggestionResponse.fromJson(jsonDecode(content));
    } else {
      throw Exception(
        'Failed to get suggestions from Groq: ${response.statusCode} \n ${response.body}',
      );
    }
  }

  Future<String> transcribeAudio(List<int> bytes, String fileName) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'pon_tu_api_key_aqui') {
      throw Exception('GROQ_API_KEY is not properly set in .env');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
    );

    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['model'] = 'whisper-large-v3';
    request.fields['temperature'] = '0';
    request.fields['response_format'] = 'verbose_json';

    final ext = fileName.split('.').last.toLowerCase();
    String mimeType = 'audio/mpeg'; // default
    if (ext == 'ogg')
      mimeType = 'audio/ogg';
    else if (ext == 'wav')
      mimeType = 'audio/wav';
    else if (ext == 'm4a')
      mimeType = 'audio/mp4';
    else if (ext == 'mp4')
      mimeType = 'video/mp4';
    else if (ext == 'webm')
      mimeType = 'audio/webm';

    final mimeParts = mimeType.split('/');

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType(mimeParts[0], mimeParts[1]),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['text'] ?? '';
    } else {
      throw Exception(
        'Failed to transcribe audio: ${response.statusCode} \n ${response.body}',
      );
    }
  }

  Future<String?> fetchLinkContent(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Use a simple regex to extract title and body content
        // since we might not have the html package dependency fully working or we want a lightweight solution
        final htmlContent = response.body;

        String title = '';
        final titleMatch = RegExp(
          r'<title>(.*?)<\/title>',
          caseSensitive: false,
        ).firstMatch(htmlContent);
        if (titleMatch != null) {
          title = titleMatch.group(1) ?? '';
        }

        String body = '';
        final bodyMatch = RegExp(
          r'<body[^>]*>([\s\S]*?)<\/body>',
          caseSensitive: false,
        ).firstMatch(htmlContent);
        if (bodyMatch != null) {
          // Remove script and style tags
          body = bodyMatch.group(1) ?? '';
          body = body.replaceAll(
            RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
            ' ',
          );
          body = body.replaceAll(
            RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false),
            ' ',
          );
          // Remove HTML tags
          body = body.replaceAll(RegExp(r'<[^>]*>'), ' ');
          // Collapse whitespace
          body = body.replaceAll(RegExp(r'\s+'), ' ').trim();

          // Truncate to avoid massive payloads
          if (body.length > 5000) {
            body = body.substring(0, 5000) + '...';
          }
        }

        return 'Title: $title\nContent: $body';
      }
    } catch (e) {
      print('Error fetching link content: $e');
    }
    return null;
  }
}
