import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../shared/models/scheme_model.dart';

/// Which backend is currently active.
enum AiBackend { ollama, gemini, none }

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  // ── OLLAMA CONFIGURATION ─────────────────────────────────────────────────
  static const String _ollamaBaseUrl  = 'http://192.168.1.2:11434';
  static const String _ollamaModel    = 'qwen3.5:4b';

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
RULES:
- Always answer using the data above. NEVER say you lack data.
- Reply in the SAME language as the user (Hindi/Marathi/English/mixed).
- Be like a trusted CA advisor: warm, direct, concise (3-8 lines).
- For Rs 1 crore question: explain the score gap clearly.
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
      final systemPrompt = buildSystemPrompt(businessContext);
      final messages = [
        {'role': 'system', 'content': systemPrompt},
        ...conversationHistory,
        {'role': 'user', 'content': userMessage},
      ];

      final request = http.Request('POST', Uri.parse('$_ollamaBaseUrl/api/chat'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': _ollamaModel,
        'messages': messages,
        'stream': true,
        'think': false,
        'options': {'temperature': 0.7, 'num_predict': 400},
      });

      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        yield* _streamFromGemini(userMessage, conversationHistory, businessContext);
        return;
      }

      bool gotAnyText = false;
      await for (final chunk in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(const Duration(seconds: 60), onTimeout: (sink) {
        if (!gotAnyText) {
          sink.addError(TimeoutException('Ollama model did not respond'));
        } else {
          sink.close();
        }
      })) {
        if (chunk.isNotEmpty) {
          try {
            final data = jsonDecode(chunk);
            final text = data['message']?['content'] as String?;
            if (text != null && text.isNotEmpty) {
              gotAnyText = true;
              yield text;
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
      yield _bothOfflineMessage(businessContext);
    }
  }

  // ── Fully-offline fallback message ───────────────────────────────────────
  String _bothOfflineMessage(Map<String, dynamic> ctx) {
    final ownerName = (ctx['ownerName'] as String?)?.trim() ?? '';
    final greeting = ownerName.isNotEmpty ? '$ownerName ji' : 'Friend';
    return '⚠️ **AI temporarily unavailable.**\n\n'
        '$greeting, both the local AI and cloud AI are unreachable right now.\n\n'
        '**Try:**\n'
        '- Check your internet connection\n'
        '- For local AI: run `ollama serve` on your laptop (same Wi-Fi)\n'
        '- Try again in a moment\n\n'
        '_Your business data is safe and I\'ll be back shortly!_';
  }

  Future<bool> isOllamaAvailable() => _isOllamaReachable();
}
