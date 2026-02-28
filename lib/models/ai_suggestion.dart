class AiSuggestionResponse {
  final List<ItemSuggestion> suggestions;

  AiSuggestionResponse({required this.suggestions});

  factory AiSuggestionResponse.fromJson(Map<String, dynamic> json) {
    if (json['suggestions'] != null) {
      var list = json['suggestions'] as List;
      List<ItemSuggestion> suggestionsList = list
          .map((i) => ItemSuggestion.fromJson(i))
          .toList();
      return AiSuggestionResponse(suggestions: suggestionsList);
    } else {
      return AiSuggestionResponse(suggestions: []);
    }
  }
}

class ItemSuggestion {
  final String itemId;
  final String action; // 'create_new', 'use_existing', or 'none'
  final String? boardId;
  final NewBoardSuggestion? newBoardSuggestion;
  final String reasoning;

  ItemSuggestion({
    required this.itemId,
    required this.action,
    this.boardId,
    this.newBoardSuggestion,
    required this.reasoning,
  });

  factory ItemSuggestion.fromJson(Map<String, dynamic> json) {
    return ItemSuggestion(
      itemId: json['item_id'] ?? '',
      action: json['action'] ?? 'none',
      boardId: json['board_id'],
      newBoardSuggestion: json['new_board_suggestion'] != null
          ? NewBoardSuggestion.fromJson(json['new_board_suggestion'])
          : null,
      reasoning: json['reasoning'] ?? '',
    );
  }
}

class NewBoardSuggestion {
  final String name;
  final String description;

  NewBoardSuggestion({required this.name, required this.description});

  factory NewBoardSuggestion.fromJson(Map<String, dynamic> json) {
    return NewBoardSuggestion(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
