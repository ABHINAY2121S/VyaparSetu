import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../shared/models/scheme_model.dart';

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  // ── OLLAMA CONFIGURATION ──────────────────────────────────────────────────
  // Your laptop's local IP on the Wi-Fi network
  static const String _ollamaBaseUrl = 'http://192.168.1.2:11434';

  // qwen3.5:4b follows instructions well. think:false disables slow reasoning mode.
  static const String _ollamaModelName = 'qwen3.5:4b';
  // ─────────────────────────────────────────────────────────────────────────

  String _baseUrl = _ollamaBaseUrl;

  void setApiKey(String key) {
    if (key.isNotEmpty && key.startsWith('http')) {
      _baseUrl = key;
    }
  }

  bool get isConfigured => true;

  void resetChat() {}

  // ── Rich system prompt with real user context ─────────────────────────────
  String buildSystemPrompt(Map<String, dynamic> context) {
    final bName = (context['businessName'] as String?) ?? 'this business';
    final bType = (context['businessType'] as String?) ?? 'small business';
    final city = (context['city'] as String?) ?? '';
    final ownerName = (context['ownerName'] as String?) ?? '';
    final healthScore = ((context['healthScore'] as double?) ?? 0).round();
    final loanScore = ((context['loanScore'] as double?) ?? 0).round();
    final confScore = ((context['confidenceScore'] as double?) ?? 0).round();
    final revenue = ((context['totalRevenue'] as double?) ?? 0).round();
    final expenses = ((context['totalExpenses'] as double?) ?? 0).round();
    final netProfit = ((context['netProfit'] as double?) ?? 0).round();
    final txCount = (context['txCount'] as int?) ?? 0;

    final healthLabel = healthScore >= 75 ? 'Strong' : healthScore >= 50 ? 'Moderate' : 'Weak';
    final loanLabel = loanScore >= 70 ? 'High' : loanScore >= 45 ? 'Medium' : 'Low';
    final profitLabel = netProfit > 0 ? 'profitable' : 'running at a loss';
    final profitMargin = revenue > 0
        ? '${((netProfit / revenue) * 100).toStringAsFixed(1)}%'
        : 'N/A';

    String loanRange;
    if (loanScore >= 75) {
      loanRange = 'Rs 2 Lakh - Rs 10 Lakh (CGTMSE / Mudra Tarun)';
    } else if (loanScore >= 55) {
      loanRange = 'Rs 50,000 - Rs 2 Lakh (Mudra Kishore)';
    } else if (loanScore >= 35) {
      loanRange = 'Rs 10,000 - Rs 50,000 (Mudra Shishu / SVANidhi)';
    } else {
      loanRange = 'Not yet eligible - needs score improvement first';
    }

    final actionPlan = StringBuffer();
    if (confScore < 60) {
      actionPlan.writeln('  - Verify Aadhaar + PAN in Documents section');
    }
    if (txCount < 10) {
      actionPlan.writeln('  - Record more daily transactions (15-20/month)');
    }
    if (netProfit < 0) {
      actionPlan.writeln('  - Expenses exceed revenue - reduce costs first');
    }
    if (loanScore < 50) {
      actionPlan.writeln('  - Maintain positive cash flow for 3 months');
    }
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
- Loan Readiness: $loanScore ($loanLabel)
- Confidence Score: $confScore

FINANCES:
- Revenue: Rs $revenue  |  Expenses: Rs $expenses  |  Profit: Rs $netProfit ($profitLabel, $profitMargin margin)
- Transactions recorded: $txCount

LOAN ELIGIBILITY (based on the scores above):
$loanRange

ACTION PLAN:
${actionPlan.isEmpty ? "Profile is strong - explore loan options" : actionPlan.toString()}

GOVERNMENT SCHEMES AVAILABLE:
$eligibleSchemes
RULES:
- Always answer using the data above. NEVER say you lack data.
- Reply in the SAME language as the user (Hindi/Marathi/English/mixed).
- Be like a trusted CA advisor: warm, direct, concise (3-8 lines).
- For Rs 1 crore question: explain the score gap clearly and what they need to improve.
- For non-finance questions (other business ideas, general knowledge): answer helpfully.
- Never invent interest rates or loan amounts beyond what is listed above.
''';
  }

  // ── Streaming chat with proper timeout ───────────────────────────────────
  Stream<String> sendMessageStream(
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

      final request = http.Request('POST', Uri.parse('$_baseUrl/api/chat'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': _ollamaModelName,
        'messages': messages,
        'stream': true,
        'think': false,
        'options': {'temperature': 0.7, 'num_predict': 400},
      });

      // 30s to establish connection
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        yield _offlineMessage(businessContext);
        return;
      }

      bool gotAnyText = false;

      // 60s watchdog on EACH chunk — prevents infinite hang
      await for (final chunk in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(
        const Duration(seconds: 60),
        onTimeout: (sink) {
          if (!gotAnyText) {
            sink.addError(TimeoutException('Ollama model did not respond'));
          } else {
            sink.close();
          }
        },
      )) {
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
      debugPrint('Ollama: timeout');
      yield '\n\n**[Timeout]** The model took too long. Try again or ask a shorter question.';
    } catch (e) {
      debugPrint('Ollama error: $e');
      yield _offlineMessage(businessContext);
    } finally {
      client.close();
    }
  }

  // ── Offline notice ────────────────────────────────────────────────────────
  String _offlineMessage(Map<String, dynamic> ctx) {
    final ownerName = (ctx['ownerName'] as String?)?.trim() ?? '';
    final greeting = ownerName.isNotEmpty ? '$ownerName ji' : 'Friend';
    return '[!] **Ollama AI is not reachable right now.**\n\n'
        '$greeting, please make sure:\n'
        '1. Laptop and phone are on the same Wi-Fi\n'
        '2. Run `ollama serve` on your laptop terminal\n'
        '3. Run `ollama run gemma:2b` to pre-load the model\n'
        '4. Laptop IP is $_baseUrl\n\n'
        'Once connected, I can answer ANY question!';
  }

  Future<bool> isOllamaAvailable() async => false;
}
