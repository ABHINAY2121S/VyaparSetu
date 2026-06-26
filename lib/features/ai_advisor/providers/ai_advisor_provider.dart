import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/chat_message_model.dart';

class AiAdvisorProvider extends ChangeNotifier {
  final AiService _aiService = AiService.instance;
  final StorageService _storage = StorageService.instance;
  final _uuid = const Uuid();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  Map<String, dynamic> _businessContext = {};

  // Streaming state
  String _streamingMsgId = '';

  // Ollama is always ready — no API key needed
  bool get isApiKeySet => true;

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get hasMessages => _messages.isNotEmpty;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init({required Map<String, dynamic> context}) async {
    _businessContext = context;
    _messages = _storage.getChatHistory();

    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }

    notifyListeners();
  }

  void reset() {
    _messages = [];
    _isLoading = false;
    _businessContext = {};
    _streamingMsgId = '';
    notifyListeners();
  }

  // ── Welcome message ───────────────────────────────────────────────────────
  void _addWelcomeMessage() {
    final businessName =
        (_businessContext['businessName'] as String?)?.isNotEmpty == true
            ? _businessContext['businessName'] as String
            : 'your business';
    final healthScore =
        (_businessContext['healthScore'] as double?)?.round() ?? 0;

    _messages.add(ChatMessageModel(
      id: _uuid.v4(),
      content:
          'नमस्ते! 🙏 I\'m **VyaparSetu AI**, your personal financial advisor.\n\n'
          'Your Business Health Score is **$healthScore/100** for **$businessName**.\n\n'
          '**I can help you with:**\n'
          '- 🏦 Loan eligibility & best government schemes\n'
          '- 📊 Improving your business scores\n'
          '- 💰 EMI calculations & financial planning\n'
          '- 📈 Growth strategies for your business\n\n'
          '✅ **Ollama AI is active** — ask me anything in Hindi, Marathi, or English! 🎤 Use the mic button to speak.',
      role: ChatRole.assistant,
      timestamp: DateTime.now(),
    ));
  }

  // ── Send message (streaming) ──────────────────────────────────────────────
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _isLoading) return;

    _messages.add(ChatMessageModel(
      id: _uuid.v4(),
      content: content.trim(),
      role: ChatRole.user,
      timestamp: DateTime.now(),
    ));

    _streamingMsgId = _uuid.v4();
    _messages.add(ChatMessageModel(
      id: _streamingMsgId,
      content: '',
      role: ChatRole.assistant,
      timestamp: DateTime.now(),
      isTyping: true,
    ));

    _isLoading = true;
    notifyListeners();

    final history = _messages
        .where((m) => m.id != _streamingMsgId && !m.isTyping)
        .take(20)
        .map((m) => m.toApiMessage())
        .toList();

    final buffer = StringBuffer();
    try {
      await for (final chunk in _aiService.sendMessageStream(
        content.trim(),
        history,
        _businessContext,
      )) {
        buffer.write(chunk);
        final idx = _messages.indexWhere((m) => m.id == _streamingMsgId);
        if (idx != -1) {
          _messages[idx] = ChatMessageModel(
            id: _streamingMsgId,
            content: buffer.toString(),
            role: ChatRole.assistant,
            timestamp: _messages[idx].timestamp,
            isTyping: false,
          );
          notifyListeners();
        }
      }
    } catch (_) {
      final idx = _messages.indexWhere((m) => m.id == _streamingMsgId);
      if (idx != -1) {
        _messages[idx] = ChatMessageModel(
          id: _streamingMsgId,
          content: 'Sorry, something went wrong. Please try again. 🙏',
          role: ChatRole.assistant,
          timestamp: _messages[idx].timestamp,
          isTyping: false,
        );
      }
    }

    _isLoading = false;
    _streamingMsgId = '';
    notifyListeners();
    await _storage.saveChatHistory(_messages);
  }

  Future<void> sendSuggestedPrompt(String prompt) => sendMessage(prompt);

  void clearChat() {
    _messages.clear();
    _aiService.resetChat();
    _addWelcomeMessage();
    _storage.saveChatHistory(_messages);
    notifyListeners();
  }

  void updateContext(Map<String, dynamic> context) {
    _businessContext = context;
  }
}
