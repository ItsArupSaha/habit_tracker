class Quote {
  final String id;
  final String text;
  final String author;
  final bool isFavorite;
  
  const Quote({
    required this.id,
    required this.text,
    required this.author,
    this.isFavorite = false,
  });
  
  // Create from API response
  factory Quote.fromApi(Map<String, dynamic> data) {
    return Quote(
      id: data['_id'] ?? data['id'] ?? '',
      text: data['content'] ?? data['text'] ?? data['quote'] ?? '',
      author: data['author'] ?? 'Unknown',
    );
  }
  
  // Create a copy with updated values
  Quote copyWith({
    String? id,
    String? text,
    String? author,
    bool? isFavorite,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
  
  @override
  String toString() {
    return 'Quote(id: $id, text: $text, author: $author, isFavorite: $isFavorite)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Quote && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
