import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/chat_message_model.dart';
import '../providers/ai_advisor_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  late AnimationController _dotController;
  late AnimationController _pulseController;

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  // Text that was in the field BEFORE the current listening session started.
  // Partial results replace the tail; only final results get committed.
  String _committedText = '';

  final _suggestedPrompts = [
    '🏦 Mudra loan के लिए eligible हूँ क्या?',
    '📊 Score कैसे improve करूं?',
    '🏛️ Best government scheme कौनसी है?',
    '💰 Safe EMI कितनी होनी चाहिए?',
    '📈 Business grow कैसे करूं?',
    '📋 Loan के लिए कौन से documents चाहिए?',
  ];

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _initSpeech();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dash = context.read<DashboardProvider>();
      context.read<AiAdvisorProvider>().init(
        context: {
          'businessName': dash.business?.businessName ?? '',
          'businessType': dash.business?.businessType ?? '',
          'ownerName': dash.user?.name ?? '',
          'city': dash.business?.city ?? '',
          'healthScore': dash.businessHealthScore,
          'loanScore': dash.loanReadinessScore,
          'confidenceScore': dash.confidenceScore,
          'totalRevenue': dash.totalRevenue,
          'totalExpenses': dash.totalExpenses,
          'netProfit': dash.netProfit,
          'txCount': dash.transactions.length,
        },
      );
      context.read<AiAdvisorProvider>().addListener(_scrollToBottom);
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (_) => _stopListening(),
      onStatus: (status) {
        // Restart when the engine stops between phrases so listening is
        // truly continuous — only if the user hasn't tapped Stop.
        if (status == 'done' && _isListening) {
          _restartListening();
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _restartListening() {
    if (!_isListening || !_speechAvailable) return;
    _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        if (words.isEmpty) return;

        // Replace partial: base committed text + current recognition
        final newText = _committedText.isEmpty ? words : '$_committedText $words';
        _messageController.text = newText;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: newText.length),
        );

        // When the engine gives a final result, commit it so the NEXT
        // partial starts appending after this sentence.
        if (result.finalResult) {
          _committedText = newText;
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        localeId: 'hi_IN',
        cancelOnError: false,
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone not available on this device'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    // Snapshot whatever is already typed — new speech appends after it
    _committedText = _messageController.text.trim();
    setState(() => _isListening = true);
    _restartListening();
  }

  void _stopListening() {
    _speech.stop();
    // Commit whatever the field has now
    _committedText = _messageController.text.trim();
    if (mounted) setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _dotController.dispose();
    _pulseController.dispose();
    _speech.stop();
    try {
      context.read<AiAdvisorProvider>().removeListener(_scrollToBottom);
    } catch (_) {}
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (_scrollController.hasClients &&
            _scrollController.position.hasContentDimensions) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        }
      } catch (_) {}
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    // Stop listening before sending
    if (_isListening) _stopListening();
    _messageController.clear();
    await context.read<AiAdvisorProvider>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiAdvisorProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(provider),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: provider.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPaddingH,
                      AppDimensions.paddingLG,
                      AppDimensions.screenPaddingH,
                      AppDimensions.paddingLG,
                    ),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(provider.messages[index]);
                    },
                  ),
          ),

          // Listening indicator bar
          if (_isListening) _buildListeningBar(),

          // Suggested prompts (only when chat is fresh)
          if (provider.messages.length <= 1) _buildSuggestedPrompts(provider),

          // Input bar
          _buildInputRow(provider),
        ],
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  AppBar _buildAppBar(AiAdvisorProvider provider) {
    return AppBar(
      backgroundColor: AppColors.background,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Advisor',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ollama AI • Active',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Clear chat',
          onPressed: () => provider.clearChat(),
        ),
      ],
    );
  }

  // ── Listening bar ─────────────────────────────────────────────────────────
  Widget _buildListeningBar() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.error.withValues(
          alpha: 0.05 + 0.05 * _pulseController.value,
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(
                  alpha: 0.6 + 0.4 * _pulseController.value,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '🎤 Listening… Tap Stop when done',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text('VyaparSetu AI',
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Your personal financial advisor',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ── Message Bubble ────────────────────────────────────────────────────────
  Widget _buildMessageBubble(ChatMessageModel msg) {
    if (msg.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: AnimatedBuilder(
            animation: _dotController,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _animatedDot(i)),
            ),
          ),
        ),
      );
    }

    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.primaryGradient : null,
                color: isUser ? null : AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
                boxShadow: isUser ? AppColors.primaryShadow : null,
              ),
              child: isUser
                  ? Text(
                      msg.content,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.5),
                    )
                  : _buildRichText(msg.content),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: msg.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Icon(Icons.copy_rounded,
                        size: 12, color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  AppFormatters.formatTime(msg.timestamp),
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppColors.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Simple bold-text renderer (**text**) ──────────────────────────────────
  Widget _buildRichText(String content) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;

    for (final match in regex.allMatches(content)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: content.substring(last, match.start),
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textPrimary, height: 1.55),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.55),
      ));
      last = match.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(
        text: content.substring(last),
        style: GoogleFonts.inter(
            fontSize: 14, color: AppColors.textPrimary, height: 1.55),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  // ── Animated dot ─────────────────────────────────────────────────────────
  Widget _animatedDot(int index) {
    final delay = index * 0.2;
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _dotController,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeInOut),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(right: index < 2 ? 4 : 0),
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, -4 * animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.4 + 0.6 * animation.value),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // ── Suggested prompts ─────────────────────────────────────────────────────
  Widget _buildSuggestedPrompts(AiAdvisorProvider provider) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH),
        child: Row(
          children: _suggestedPrompts.map((prompt) {
            return GestureDetector(
              onTap: () => provider.sendSuggestedPrompt(prompt),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  prompt,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Input row ─────────────────────────────────────────────────────────────
  Widget _buildInputRow(AiAdvisorProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.screenPaddingH,
        right: AppDimensions.screenPaddingH,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border:
            const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Mic button ────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? AppColors.error.withValues(
                            alpha: 0.85 + 0.15 * _pulseController.value)
                        : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isListening
                          ? AppColors.error
                          : AppColors.border,
                      width: _isListening ? 2 : 1,
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: AppColors.error.withValues(
                                  alpha: 0.3 + 0.2 * _pulseController.value),
                              blurRadius: 8 + 4 * _pulseController.value,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: _isListening ? Colors.white : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Text field ────────────────────────────────────────────────
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => provider.isLoading ? null : _send(),
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _isListening
                      ? 'बोलते रहें… (Speak now…)'
                      : 'अपने business के बारे में कुछ भी पूछें…',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Send button ───────────────────────────────────────────────
            GestureDetector(
              onTap: provider.isLoading ? null : _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient:
                      provider.isLoading ? null : AppColors.primaryGradient,
                  color: provider.isLoading ? AppColors.border : null,
                  shape: BoxShape.circle,
                  boxShadow: provider.isLoading ? null : AppColors.primaryShadow,
                ),
                child: provider.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
