enum ChatRole { user, assistant }

class ChatMessageModel {
  final String id;
  final String content;
  final ChatRole role;
  final DateTime timestamp;
  final bool isTyping;

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isTyping = false,
  });

  ChatMessageModel copyWith({
    String? id,
    String? content,
    ChatRole? role,
    DateTime? timestamp,
    bool? isTyping,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;

  Map<String, String> toApiMessage() => {
    'role': role == ChatRole.user ? 'user' : 'assistant',
    'content': content,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'role': role.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String,
        content: json['content'] as String,
        role: ChatRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => ChatRole.user,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
