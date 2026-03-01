import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ai_suggestion.dart';
import '../models/models.dart';

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
            'ai_summary': b['ai_summary'] ?? '',
          },
        )
        .toList();

    final systemPrompt = """
You are an AI assistant that organizes an inbox of digital content into boards.
You will receive a list of existing user boards and a list of unorganized inbox items.
Your task is to analyze ALL inbox items together and classify EACH item.

CRITICAL INSTRUCTION ON INBOX RELATIONSHIPS:
Before classifying individual items, look at ALL the items in the inbox as a whole. Identify common themes or topics among them. 
Items do NOT need to match exactly to be grouped; if they share a sufficient underlying semantic relationship or broad common theme (e.g. a guitar and a drumset both go to a "Music" board; a recipe and a restaurant review both go to a "Food" board), you MUST treat them as a group and place them together into the SAME board. 
If they are to be grouped into a newly created board, you MUST choose "create_new" for ALL of those related items, and the suggested board name MUST match EXACTLY across all of them. Do not create separate distinct boards for items that share enough in common.

IMPORTANT CLASSIFICATION RULES (STRICTLY ENFORCED):
1. MEANINGFUL CONTENT ONLY: The board category MUST be derived from the semantic content of the item. For example, an image of a violin belongs in "Music" or "Instruments", NEVER in "Images".
2. NO FORMAT BOARDS: UNDER NO CIRCUMSTANCES should you create a board related to file formats, types, or general media categories. DO NOT produce categories like "Images", "Pictures", "Photos", "Videos", "Documents", "Files", or "Links".
3. NO VAGUE BOARDS: DO NOT use miscellaneous or vague categories like "Miscellaneous", "Random", "Others".
4. NAMING AND SPECIFICITY: When creating a new board, its name MUST be short (1 or 2 words max). It should be broad enough to hold similar items, but not overly specific (e.g., use "Travel" instead of "Trip to Paris 2024").
5. USE BOARD AI SUMMARIES: When considering existing boards, pay close attention to each board's "ai_summary". This summary represents the actual contents currently stored in that board. If an item matches the semantic context described in a board's ai_summary, prioritize moving the item to that existing board.

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
      "reasoning": "short explanation of why you grouped this item here, referencing its relationship to other inbox items or an existing board's ai_summary if applicable. Do not include the item id in the reasoning, use the name instead."
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
          "Item ID: ${i['id']}\nTitle: ${i['titulo'] ?? ''}\n$extraContent\n";

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

  Future<String> summarizeItem(Map<String, dynamic> item) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'pon_tu_api_key_aqui') {
      throw Exception('GROQ_API_KEY is not properly set in .env');
    }

    final tipo = item['tipo'] ?? '';
    final isImage = tipo == 'imagen';
    final isLink = tipo == 'link';
    final isAudio = tipo == 'audio';
    final isArchivo = tipo == 'archivo';
    final contentVal = item['contenido'] ?? '';
    final rawData = item['metadatos'] ?? item['raw_data'] ?? {};

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

    final itemContext = "Title: ${item['titulo'] ?? ''}\n$extraContent\n";
    final systemPrompt =
        "You are an AI assistant that provides an insightful summary of the content of an item. Provide ONLY the summary text.";

    final List<Map<String, dynamic>> userContentArray = [
      {"type": "text", "text": "Please summarize this item:\n"},
    ];

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

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "meta-llama/llama-4-scout-17b-16e-instruct",
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userContentArray},
        ],
        "temperature": 0.3,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? '';
    } else {
      throw Exception(
        'Failed to summarize item: ${response.statusCode} \n ${response.body}',
      );
    }
  }

  Future<String> summarizeBoard(
    Map<String, dynamic> board,
    List<Map<String, dynamic>> items,
  ) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'pon_tu_api_key_aqui') {
      throw Exception('GROQ_API_KEY is not properly set in .env');
    }

    final systemPrompt =
        "You are an AI assistant that writes insightful summaries for boards containing multiple items. You will receive the board's title, description, and the summaries of all the items inside the board. Create an insightful, holistic text summary of the board's entire contents. The summary should quickly help the user to understand the content of the board. You can include bullet points if it helps to make the summary more insightful. Provide ONLY the summary text.";

    String itemsText = "";
    for (var i in items) {
      final title = i['titulo'] ?? 'Untitled';
      final summary = i['ai_summary'] ?? 'No summary available';
      itemsText += "- Item: $title\n  Summary: $summary\n\n";
    }

    final userContent =
        "Board Title: ${board['titulo'] ?? ''}\nBoard Description: ${board['descripcion'] ?? ''}\n\nItems in Board:\n$itemsText";

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "meta-llama/llama-4-scout-17b-16e-instruct",
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userContent},
        ],
        "temperature": 0.3,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? '';
    } else {
      throw Exception(
        'Failed to summarize board: ${response.statusCode} \n ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> compareBoards({
    required List<Board> myBoards,
    required List<Board> otherBoards,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'pon_tu_api_key_aqui') {
      throw Exception('GROQ_API_KEY is not properly set in .env');
    }

    if (otherBoards.isEmpty) {
      return {'insightful_summary': null, 'ranked_board_ids': <String>[]};
    }

    final systemPrompt = """
You are an AI assistant that analyzes the interests of two users to find commonalities and differences based on their digital boards.
You will receive a list of "My Boards" and "Other User's Boards". Each board has a title, description, and an AI summary of its contents.

Your task is to:
1. Compare the contents of the boards to understand both users' interests.
2. Generate an "insightful_summary" (1-3 sentences) directly addressing the first user (e.g., "You both seem to love..." or "While you focus on X, they are more into Y, but you both share an interest in Z.") analyzing how their interests overlap or differ.
3. Rank the "Other User's Boards" in order of how similar they are to "My Boards".
4. Return a JSON object with two fields:
   - "insightful_summary": The generated summary text.
   - "ranked_board_ids": A list of board IDs from the "Other User's Boards", ordered from most similar to least similar.

Focus deeply on the semantic meaning of the board contents, not just keyword matching.

Output STRICTLY in the following JSON schema:
{
  "insightful_summary": "string",
  "ranked_board_ids": ["string", "string"]
}
""";

    String formatBoards(List<Board> boards) {
      return boards
          .map((b) {
            return "- Board ID: ${b.id}\n  Title: ${b.name}\n  Description: ${b.description ?? 'None'}\n  AI Summary: ${b.aiSummary ?? 'None'}\n";
          })
          .join('\n');
    }

    final userContent =
        """
My Boards:
${formatBoards(myBoards)}

Other User's Boards:
${formatBoards(otherBoards)}
""";

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
      final decoded = jsonDecode(content);
      return {
        'insightful_summary': decoded['insightful_summary'] as String?,
        'ranked_board_ids': List<String>.from(
          decoded['ranked_board_ids'] ?? [],
        ),
      };
    } else {
      throw Exception(
        'Failed to compare boards: ${response.statusCode} \n ${response.body}',
      );
    }
  }
}
