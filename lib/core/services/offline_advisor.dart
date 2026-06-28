/// Offline AI advisor — answers common business questions using the user's
/// real data (scores, revenue, loan eligibility) when both Ollama and Gemini
/// are unreachable. No internet required.
library offline_advisor;

class OfflineAdvisor {
  OfflineAdvisor._();
  static final OfflineAdvisor instance = OfflineAdvisor._();

  /// Returns a personalised answer if the question matches a known intent,
  /// or null if the question is too complex for offline mode.
  String? answer(String question, Map<String, dynamic> ctx) {
    final q = question.toLowerCase().trim();

    // ── Extract context values ──────────────────────────────────────────────
    final name        = (ctx['ownerName']       as String?) ?? '';
    final bName       = (ctx['businessName']    as String?) ?? 'your business';
    final healthScore = ((ctx['healthScore']    as double?) ?? 0).round();
    final loanScore   = ((ctx['loanScore']      as double?) ?? 0).round();
    final confScore   = ((ctx['confidenceScore'] as double?) ?? 0).round();
    final revenue     = ((ctx['totalRevenue']   as double?) ?? 0);
    final expenses    = ((ctx['totalExpenses']  as double?) ?? 0);
    final netProfit   = ((ctx['netProfit']      as double?) ?? 0);
    final txCount     = (ctx['txCount']         as int?) ?? 0;
    final greeting    = name.isNotEmpty ? '$name ji' : 'Aap';

    // ── Intent matching ─────────────────────────────────────────────────────
    if (_matches(q, ['loan', 'lend', 'borrow', 'credit', 'mudra', 'limit',
                      'udhaar', 'karj', 'qarz', '1 cr', '1cr', 'crore',
                      'lakh', 'amount', 'eligible'])) {
      return _loanAnswer(greeting, loanScore, healthScore);
    }

    if (_matches(q, ['health score', 'business score', 'my score', 'score',
                      'rating', 'rank', 'kitna score', 'mera score'])) {
      return _scoreAnswer(greeting, bName, healthScore, loanScore, confScore);
    }

    if (_matches(q, ['revenue', 'income', 'sales', 'earning', 'profit',
                      'loss', 'expense', 'kharcha', 'kamai', 'munafa',
                      'financial', 'money', 'rupee', 'rs '])) {
      return _financialAnswer(greeting, bName, revenue, expenses, netProfit, txCount);
    }

    if (_matches(q, ['improve', 'increase score', 'better', 'grow', 'tips',
                      'advice', 'suggest', 'kya karu', 'kya karun',
                      'how to', 'next step', 'action'])) {
      return _improvementAnswer(greeting, healthScore, loanScore, confScore, txCount, netProfit);
    }

    if (_matches(q, ['scheme', 'government', 'sarkari', 'pm', 'svani',
                      'svanidhi', 'pmmy', 'standup', 'yojana', 'subsidy'])) {
      return _schemesAnswer(greeting, loanScore);
    }

    if (_matches(q, ['confidence', 'trust', 'document', 'aadhaar', 'pan',
                      'kyc', 'verified', 'profile'])) {
      return _confidenceAnswer(greeting, confScore);
    }

    if (_matches(q, ['who am i', 'my business', 'overview', 'summary',
                      'mera business', 'tell me about', 'about me'])) {
      return _overviewAnswer(greeting, bName, healthScore, loanScore, confScore,
          revenue, netProfit, txCount);
    }

    return null; // No match — caller shows "AI unavailable"
  }

  // ── Intent handlers ───────────────────────────────────────────────────────

  String _loanAnswer(String greeting, int loanScore, int healthScore) {
    String range, advice;
    if (loanScore >= 75) {
      range  = '₹2 Lakh – ₹10 Lakh (CGTMSE / Mudra Tarun)';
      advice = 'Aapka profile strong hai! Aaj hi apply kar sakte hain.';
    } else if (loanScore >= 55) {
      range  = '₹50,000 – ₹2 Lakh (Mudra Kishore)';
      advice = 'Thoda aur transactions record karo — score badhega.';
    } else if (loanScore >= 35) {
      range  = '₹10,000 – ₹50,000 (Mudra Shishu / PM SVANidhi)';
      advice = '3 mahine positive cash flow maintain karo pehle.';
    } else {
      return '$greeting, abhi loan eligibility kam hai.\n\n'
          '📊 **Loan Readiness: $loanScore/100**\n\n'
          '**Improve karne ke liye:**\n'
          '- Roz transactions record karo (15–20 per month)\n'
          '- Expenses kam karo — profit mein aao\n'
          '- Aadhaar + PAN verify karo Documents section mein\n\n'
          '_Score 35+ hone par Mudra Shishu loan eligible ho jaoge._';
    }
    return '$greeting, aapke loan details:\n\n'
        '📊 **Loan Readiness Score: $loanScore/100**\n\n'
        '💰 **Eligible Amount:** $range\n\n'
        '💡 $advice\n\n'
        '_Yeh score aapke actual business data par based hai._';
  }

  String _scoreAnswer(String greeting, String bName, int health, int loan, int conf) {
    final healthLabel = health >= 75 ? '🟢 Strong' : health >= 50 ? '🟡 Moderate' : '🔴 Weak';
    final loanLabel   = loan   >= 70 ? '🟢 High'   : loan   >= 45 ? '🟡 Medium'   : '🔴 Low';
    final confLabel   = conf   >= 70 ? '🟢 Verified': conf   >= 40 ? '🟡 Partial'  : '🔴 Low';
    return '$greeting, $bName ke scores:\n\n'
        '🏥 **Business Health:** $health/100 — $healthLabel\n'
        '💳 **Loan Readiness:** $loan/100 — $loanLabel\n'
        '🛡️ **Confidence Score:** $conf/100 — $confLabel\n\n'
        '${_quickScoreTip(health, loan, conf)}';
  }

  String _financialAnswer(String greeting, String bName,
      double rev, double exp, double profit, int txCount) {
    final profitIcon = profit >= 0 ? '🟢' : '🔴';
    final profitText = profit >= 0 ? 'Profit' : 'Loss';
    final margin     = rev > 0
        ? '${((profit / rev) * 100).toStringAsFixed(1)}%'
        : 'N/A';
    return '$greeting, $bName ki financials:\n\n'
        '💰 **Revenue:** ₹${_fmt(rev)}\n'
        '💸 **Expenses:** ₹${_fmt(exp)}\n'
        '$profitIcon **Net $profitText:** ₹${_fmt(profit.abs())} ($margin margin)\n'
        '📝 **Transactions:** $txCount recorded\n\n'
        '${profit < 0
            ? "⚠️ Expenses revenue se zyada hain. Costs reduce karo loan eligibility ke liye."
            : "✅ Business profitable hai — loan ke liye achha sign!"}';
  }

  String _improvementAnswer(String greeting, int health, int loan, int conf,
      int txCount, double profit) {
    final tips = <String>[];
    if (conf < 60)    tips.add('✅ Aadhaar + PAN verify karo Documents section mein');
    if (txCount < 15) tips.add('📝 Roz transactions record karo (target: 15–20/month)');
    if (profit < 0)   tips.add('📉 Expenses kam karo — pehle profitable bano');
    if (loan < 50)    tips.add('⏳ 3 mahine positive cash flow maintain karo');
    if (health < 60)  tips.add('🔄 Business data update karo regularly');

    if (tips.isEmpty) {
      return '$greeting, aapka profile already strong hai! 🎉\n\n'
          'Health: $health | Loan: $loan | Confidence: $conf\n\n'
          'Mudra Kishore ya CGTMSE loan ke liye apply kar sakte hain ab.';
    }
    return '$greeting, score improve karne ke liye:\n\n${tips.join("\n")}\n\n'
        '_Inhe follow karo — score 2–4 hafton mein badhega._';
  }

  String _schemesAnswer(String greeting, int loanScore) {
    if (loanScore >= 75) {
      return '$greeting, aap in schemes ke eligible hain:\n\n'
          '🏦 **CGTMSE** — ₹2L–₹10L, no collateral\n'
          '🏦 **Mudra Tarun** — ₹5L–₹10L @ ~10%\n'
          '🏦 **Stand-Up India** — ₹10L–₹1Cr\n\n'
          '_Nearest bank branch ya udyamimitra.in par apply karo._';
    } else if (loanScore >= 40) {
      return '$greeting, aap in schemes ke eligible hain:\n\n'
          '🏦 **Mudra Kishore** — ₹50K–₹2L @ ~12%\n'
          '🏦 **Mudra Shishu** — ₹10K–₹50K @ ~10%\n\n'
          '_Score 70+ karo Mudra Tarun ke liye._';
    }
    return '$greeting, abhi sirf yeh scheme eligible hai:\n\n'
        '🏦 **PM SVANidhi** — ₹10,000 (street vendors)\n'
        '🏦 **Mudra Shishu** — ₹10K–₹50K\n\n'
        '_Score badhao zyada options ke liye._';
  }

  String _confidenceAnswer(String greeting, int conf) {
    final label = conf >= 70 ? 'High ✅' : conf >= 40 ? 'Medium ⚠️' : 'Low ❌';
    final tip   = conf < 60
        ? 'Aadhaar + PAN verify karo Documents section mein — score instantly badhega.'
        : conf < 80
            ? 'Business registration documents upload karo confidence badhane ke liye.'
            : 'Aapka profile fully verified hai!';
    return '$greeting, Confidence Score: **$conf/100 — $label**\n\n💡 $tip';
  }

  String _overviewAnswer(String greeting, String bName, int health, int loan,
      int conf, double rev, double profit, int tx) {
    return '$greeting, yeh hai $bName ka overview:\n\n'
        '🏥 Health: $health/100  |  💳 Loan: $loan/100  |  🛡️ Confidence: $conf/100\n\n'
        '💰 Revenue: ₹${_fmt(rev)}  |  ${profit >= 0 ? "✅" : "⚠️"} '
        '${profit >= 0 ? "Profit" : "Loss"}: ₹${_fmt(profit.abs())}\n'
        '📝 Transactions: $tx recorded\n\n'
        '${_quickScoreTip(health, loan, conf)}';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _quickScoreTip(int health, int loan, int conf) {
    if (health >= 70 && loan >= 55) return '🎯 Strong profile! Mudra loan ke liye apply kar sakte hain.';
    if (conf < 50)   return '💡 Tip: Aadhaar + PAN verify karo — sabse fast score boost.';
    if (loan < 40)   return '💡 Tip: Transactions badhao aur profit mein aao.';
    return '💡 Consistent transactions se score automatically badhega.';
  }

  bool _matches(String question, List<String> keywords) =>
      keywords.any((k) => question.contains(k));

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)     return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
