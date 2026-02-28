import 'dart:convert';
import 'package:http/http.dart' as http;
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

    final inboxItemsJson = inboxItems
        .map(
          (i) => {
            'id': i['id'] ?? '',
            'type': i['tipo'] ?? '',
            'content': i['contenido'] ?? '',
            'title': i['titulo'] ?? '',
            'raw_data': i['raw_data'] ?? '',
          },
        )
        .toList();

    final systemPrompt = """
You are an AI assistant that organizes an inbox of digital content into boards.
You will receive a list of existing user boards and a list of unorganized inbox items.
Your task is to analyze ALL inbox items together and suggest one action for EACH item.

Actions can be:
- "use_existing": move the item to an existing board.
- "create_new": suggest creating a new board that would fit this item (and potentially other similar items in the inbox).

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

    final userContent = jsonEncode({
      "user_boards": userBoardsJson,
      "inbox_items": inboxItemsJson,
    });

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
          {"role": "user", "content": userContent},
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
}
