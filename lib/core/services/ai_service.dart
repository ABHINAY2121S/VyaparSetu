import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../shared/models/scheme_model.dart';
import 'offline_advisor.dart';

/// Which backend is currently active.
enum AiBackend { ollama, gemini, none }

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  // ── OLLAMA CONFIGURATION ─────────────────────────────────────────────────
  static const String _ollamaBaseUrl  = 'http://127.0.0.1:11434';
  static const String _ollamaModel    = 'llama3.2:3b';

  // ── GEMINI CLOUD FALLBACK ────────────────────────────────────────────────
  // Paste your Google AI Studio key here.
  // Get one free at: https://aistudio.google.com/app/apikey
  static const String _geminiApiKey   = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String _geminiModel    = 'gemini-1.5-flash';

  // ────────────────────────────────────────────────────────────────────────
  AiBackend _activeBackend = AiBackend.none;
  AiBackend get activeBackend => _activeBackend;

  bool get isConfigured => true;

  void setApiKey(String key) {} // legacy no-op
  void resetChat() {}

  // ── Health check: is Ollama reachable? ──────────────────────────────────
  Future<bool> _isOllamaReachable() async {
    try {
      final res = await http
          .get(Uri.parse('$_ollamaBaseUrl/api/tags'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Rich system prompt ───────────────────────────────────────────────────
  String buildSystemPrompt(Map<String, dynamic> context) {
    final bName      = (context['businessName'] as String?) ?? 'this business';
    final bType      = (context['businessType'] as String?) ?? 'small business';
    final city       = (context['city']         as String?) ?? '';
    final ownerName  = (context['ownerName']    as String?) ?? '';
    final healthScore  = ((context['healthScore']      as double?) ?? 0).round();
    final loanScore    = ((context['loanScore']        as double?) ?? 0).round();
    final confScore    = ((context['confidenceScore']  as double?) ?? 0).round();
    final revenue      = ((context['totalRevenue']     as double?) ?? 0).round();
    final expenses     = ((context['totalExpenses']    as double?) ?? 0).round();
    final netProfit    = ((context['netProfit']        as double?) ?? 0).round();
    final txCount      = (context['txCount'] as int?) ?? 0;

    final healthLabel  = healthScore >= 75 ? 'Strong' : healthScore >= 50 ? 'Moderate' : 'Weak';
    final loanLabel    = loanScore   >= 70 ? 'High'   : loanScore   >= 45 ? 'Medium'   : 'Low';
    final profitLabel  = netProfit > 0 ? 'profitable' : 'running at a loss';
    final profitMargin = revenue > 0
        ? '${((netProfit / revenue) * 100).toStringAsFixed(1)}%'
        : 'N/A';

    String loanRange;
    if (loanScore >= 75) {
      loanRange = 'Rs 2 Lakh – Rs 10 Lakh (CGTMSE / Mudra Tarun)';
    } else if (loanScore >= 55) {
      loanRange = 'Rs 50,000 – Rs 2 Lakh (Mudra Kishore)';
    } else if (loanScore >= 35) {
      loanRange = 'Rs 10,000 – Rs 50,000 (Mudra Shishu / SVANidhi)';
    } else {
      loanRange = 'Not yet eligible – needs score improvement first';
    }

    final actionPlan = StringBuffer();
    if (confScore  < 60)  actionPlan.writeln('  - Verify Aadhaar + PAN in Documents section');
    if (txCount    < 10)  actionPlan.writeln('  - Record more daily transactions (15-20/month)');
    if (netProfit  < 0)   actionPlan.writeln('  - Expenses exceed revenue – reduce costs first');
    if (loanScore  < 50)  actionPlan.writeln('  - Maintain positive cash flow for 3 months');
    if (healthScore >= 70 && loanScore >= 55) {
      actionPlan.writeln('  - Great profile! Consider applying for Mudra Kishore loan now');
    }

    final eligibleSchemes = StringBuffer();
    for (final s in SchemeModel.allSchemes) {
      eligibleSchemes.writeln('  - ${s.name}: ${s.loanRange} @ ${s.interestRate}');
    }

    return '''
YOU ARE VyaparSetu AI. You ALREADY HAVE the user's complete business data below. DO NOT say you lack data.

OWNER: ${ownerName.isNotEmpty ? ownerName : "Not set"}
BUSINESS: ${bName.isNotEmpty ? bName : "Not set"} (${bType.isNotEmpty ? bType : "small business"}) in ${city.isNotEmpty ? city : "India"}

SCORES (out of 100):
- Business Health: $healthScore ($healthLabel)
- Loan Readiness:  $loanScore ($loanLabel)
- Confidence Score: $confScore

FINANCES:
- Revenue: Rs $revenue  |  Expenses: Rs $expenses  |  Profit: Rs $netProfit ($profitLabel, $profitMargin margin)
- Transactions recorded: $txCount

LOAN ELIGIBILITY:
$loanRange

ACTION PLAN:
${actionPlan.isEmpty ? "Profile is strong – explore loan options" : actionPlan.toString()}
GOVERNMENT SCHEMES AVAILABLE:
$eligibleSchemes
RULES (FOLLOW STRICTLY):
- NEVER ask "please provide your name/details" — you ALREADY have all data above.
- NEVER say you lack data or need more information. Use what is given.
- If scores are 0, the user is new — tell them their scores and what to do to improve.
- Always give a direct, specific answer using the numbers above.
- Reply in the SAME language as the user (Hindi/Marathi/English/mixed Hinglish).
- Be like a trusted CA advisor: warm, direct, concise (3-8 lines max).
- For loan questions: always state the loan range from LOAN ELIGIBILITY above.
- Never invent interest rates or loan amounts beyond what is listed above.
''';
  }

  // ── Main entry: try Ollama → fallback to Gemini ──────────────────────────
  Stream<String> sendMessageStream(
    String userMessage,
    List<Map<String, String>> conversationHistory,
    Map<String, dynamic> businessContext,
  ) async* {
    final ollamaUp = await _isOllamaReachable();

    if (ollamaUp) {
      _activeBackend = AiBackend.ollama;
      debugPrint('[AiService] Using Ollama backend');
      yield* _streamFromOllama(userMessage, conversationHistory, businessContext);
    } else {
      _activeBackend = AiBackend.gemini;
      debugPrint('[AiService] Ollama offline – falling back to Gemini');
      yield* _streamFromGemini(userMessage, conversationHistory, businessContext);
    }
  }

  // ── Ollama streaming ─────────────────────────────────────────────────────
  Stream<String> _streamFromOllama(
    String userMessage,
    List<Map<String, String>> conversationHistory,
    Map<String, dynamic> businessContext,
  ) async* {
    final client = http.Client();
    try {
      // qwen3.5:4b supports the system role properly.
      final systemPrompt = buildSystemPrompt(businessContext);

      // /no_think must be in the LAST user message for thinking models (not system prompt)
      final userWithNoThink = '$userMessage /no_think';

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        ...conversationHistory,
        {'role': 'user', 'content': userWithNoThink},
      ];

      final request = http.Request('POST', Uri.parse('$_ollamaBaseUrl/api/chat'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': _ollamaModel,
        'messages': messages,
        'stream': true,
        'options': {'temperature': 0.1, 'num_predict': 500},
      });

      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        debugPrint('[AiService] Ollama HTTP ${response.statusCode}: $body');
        yield* _streamFromGemini(userMessage, conversationHistory, businessContext);
        return;
      }

      // Stream response, skipping <think>...</think> blocks that qwen3 emits.
      bool gotAnyText  = false;
      bool inThinkBlock = false;
      final thinkBuf  = StringBuffer();

      await for (final chunk in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(const Duration(seconds: 90), onTimeout: (sink) {
        if (!gotAnyText) {
          sink.addError(TimeoutException('Ollama model did not respond in time'));
        } else {
          sink.close();
        }
      })) {
        if (chunk.isNotEmpty) {
          try {
            final data = jsonDecode(chunk);
            final text = data['message']?['content'] as String?;
            if (text != null && text.isNotEmpty) {
              // Accumulate to detect/strip <think> blocks across chunk boundaries
              thinkBuf.write(text);
              final buf = thinkBuf.toString();

              // Enter think block
              if (!inThinkBlock && buf.contains('<think>')) {
                inThinkBlock = true;
                // Yield anything before the <think> tag
                final before = buf.substring(0, buf.indexOf('<think>'));
                if (before.isNotEmpty) { gotAnyText = true; yield before; }
                thinkBuf.clear();
                thinkBuf.write(buf.substring(buf.indexOf('<think>')));
              }

              // Exit think block
              if (inThinkBlock && thinkBuf.toString().contains('</think>')) {
                final after = thinkBuf.toString();
                final end   = after.indexOf('</think>') + '</think>'.length;
                inThinkBlock = false;
                thinkBuf.clear();
                final remaining = after.substring(end);
                if (remaining.isNotEmpty) { gotAnyText = true; yield remaining; }
              } else if (!inThinkBlock && thinkBuf.isNotEmpty) {
                // Normal text — flush buffer
                final out = thinkBuf.toString();
                thinkBuf.clear();
                if (out.isNotEmpty) { gotAnyText = true; yield out; }
              }
            }
            if (data['done'] == true) break;
          } catch (_) {}
        }
      }
    } on TimeoutException {
      debugPrint('[AiService] Ollama timeout – switching to Gemini');
      _activeBackend = AiBackend.gemini;
      yield* _streamFromGemini(userMessage, conversationHistory, businessContext);
    } catch (e) {
      debugPrint('[AiService] Ollama error: $e – switching to Gemini');
      _activeBackend = AiBackend.gemini;
      yield* _streamFromGemini(userMessage, conversationHistory, businessContext);
    } finally {
      client.close();
    }
  }

  // ── Gemini streaming (cloud fallback) ────────────────────────────────────
  Stream<String> _streamFromGemini(
    String userMessage,
    List<Map<String, String>> conversationHistory,
    Map<String, dynamic> businessContext,
  ) async* {
    try {
      final systemPrompt = buildSystemPrompt(businessContext);

      final model = GenerativeModel(
        model: _geminiModel,
        apiKey: _geminiApiKey,
        systemInstruction: Content.system(systemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 400,
        ),
      );

      // Build history for Gemini format
      final history = conversationHistory.map((m) {
        final role = m['role'] == 'user' ? 'user' : 'model';
        return Content(role, [TextPart(m['content'] ?? '')]);
      }).toList();

      final chat = model.startChat(history: history);

      final stream = chat.sendMessageStream(Content.text(userMessage));

      await for (final response in stream) {
        final text = response.text;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    } catch (e) {
      debugPrint('[AiService] Gemini error: $e');
      _activeBackend = AiBackend.none;
      yield _bothOfflineMessage(businessContext, userMessage);
    }
  }

  // ── Smart offline fallback ────────────────────────────────────────────────
  String _bothOfflineMessage(Map<String, dynamic> ctx, [String userMessage = '']) {
    // Try to answer using pattern-matched offline Q&A first
    if (userMessage.isNotEmpty) {
      final offlineAnswer = OfflineAdvisor.instance.answer(userMessage, ctx);
      if (offlineAnswer != null) return offlineAnswer;
    }

    // Fallback: generic unavailable message
    final ownerName = (ctx['ownerName'] as String?)?.trim() ?? '';
    final greeting  = ownerName.isNotEmpty ? '$ownerName ji' : 'Friend';
    return '⚠️ **AI temporarily unavailable.**\n\n'
        '$greeting, local aur cloud AI dono abhi unreachable hain.\n\n'
        '**Common questions jo abhi bhi answer kar sakta hoon:**\n'
        '- "Can I get a loan?" → apna score bataunga\n'
        '- "My business score?" → health/loan/confidence score\n'
        '- "My revenue?" → financial summary\n'
        '- "How to improve?" → actionable tips\n'
        '- "Government schemes?" → eligible yojanas\n\n'
        '_In mein se kuch poocho — bina internet ke bhi jawab milega!_';
  }


  Future<bool> isOllamaAvailable() => _isOllamaReachable();
}
