import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class ClauseRewriteScreen extends StatefulWidget {
  final String documentId;
  const ClauseRewriteScreen({super.key, required this.documentId});

  @override
  State<ClauseRewriteScreen> createState() => _ClauseRewriteScreenState();
}

class _ClauseRewriteScreenState extends State<ClauseRewriteScreen> {
  RewriteResult? _result;
  bool _loading = true;
  String? _error;
  String _tone = 'standard';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService().getClauseRewrites(widget.documentId, tone: _tone);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll(RegExp(r'ApiException\(\d+\): '), ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'high':   return AppColors.dangerRed;
      case 'medium': return AppColors.warningAmber;
      default:       return AppColors.safeGreen;
    }
  }

  Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'hard':     return AppColors.dangerRed;
      case 'moderate': return AppColors.warningAmber;
      default:         return AppColors.safeGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Clause Rewrites', style: AppTextStyles.goldTitle.copyWith(fontSize: 20)),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          // Tone selector
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NEGOTIATION TONE', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              Row(children: [
                _ToneChip(label: '💼 Standard', value: 'standard', selected: _tone == 'standard',
                    onTap: () { setState(() => _tone = 'standard'); _load(); }),
                const SizedBox(width: 8),
                _ToneChip(label: '💪 Firm', value: 'firm', selected: _tone == 'firm',
                    onTap: () { setState(() => _tone = 'firm'); _load(); }),
                const SizedBox(width: 8),
                _ToneChip(label: '🤝 Polite', value: 'polite', selected: _tone == 'polite',
                    onTap: () { setState(() => _tone = 'polite'); _load(); }),
              ]),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircularProgressIndicator(color: AppColors.gold),
                    SizedBox(height: 16),
                    Text('Generating rewrites...', style: TextStyle(color: AppColors.textSecondary)),
                    SizedBox(height: 6),
                    Text('This may take a moment', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ]))
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24),
                        child: Text(_error!, style: const TextStyle(color: AppColors.dangerRed))))
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_result == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _difficultyColor(_result!.rewriteDifficulty).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_result!.rewriteDifficulty} to negotiate',
                    style: TextStyle(color: _difficultyColor(_result!.rewriteDifficulty),
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text('${_result!.totalRiskyClauses} risky clauses',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ]),
            const SizedBox(height: 10),
            Text(_result!.overallAssessment, style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          ]),
        ).animate().fadeIn(),

        if (_result!.suggestions.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(children: [
              const Icon(Icons.verified_rounded, color: AppColors.safeGreen, size: 48),
              const SizedBox(height: 12),
              Text('No risky clauses detected', style: GoogleFonts.cormorantGaramond(
                  color: AppColors.safeGreen, fontSize: 20, fontWeight: FontWeight.w600)),
            ]),
          ))
        else
          ..._result!.suggestions.asMap().entries.map((entry) =>
            _RewriteCard(suggestion: entry.value, riskColor: _riskColor(entry.value.riskLevel))
                .animate().fadeIn(delay: Duration(milliseconds: 80 * entry.key))),
      ],
    );
  }
}

class _ToneChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _ToneChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.goldGlow : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.gold : AppColors.cardBorder, width: selected ? 1.5 : 1),
      ),
      child: Text(label, style: GoogleFonts.dmSans(
          color: selected ? AppColors.gold : AppColors.textSecondary,
          fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
    ),
  );
}

class _RewriteCard extends StatefulWidget {
  final RewriteSuggestion suggestion;
  final Color riskColor;
  const _RewriteCard({required this.suggestion, required this.riskColor});

  @override
  State<_RewriteCard> createState() => _RewriteCardState();
}

class _RewriteCardState extends State<_RewriteCard> {
  bool _showRewrite = false;

  void _copyRewrite() {
    Clipboard.setData(ClipboardData(text: widget.suggestion.suggestedRewrite));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rewrite copied to clipboard'), backgroundColor: AppColors.safeGreen));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.riskColor.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Clause header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.riskColor.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: widget.riskColor.withOpacity(0.15))),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: widget.riskColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.warning_amber_rounded, color: widget.riskColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(s.clauseType, style: GoogleFonts.dmSans(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.riskColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(s.riskLevel.toUpperCase(), style: TextStyle(
                  color: widget.riskColor, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Original
            _Label('ORIGINAL CLAUSE'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.dangerRed.withOpacity(0.15)),
              ),
              child: Text(s.originalText, style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
            ),
            const SizedBox(height: 12),
            // Why risky
            _Label('WHY IT\'S RISKY'),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, color: widget.riskColor, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(s.riskReason, style: TextStyle(
                  color: widget.riskColor.withOpacity(0.9), fontSize: 13, height: 1.4))),
            ]),
            const SizedBox(height: 12),
            // Toggle rewrite
            GestureDetector(
              onTap: () => setState(() => _showRewrite = !_showRewrite),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: _showRewrite ? AppColors.safeGradient : null,
                  color: _showRewrite ? null : AppColors.safeGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.safeGreen.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.auto_fix_high_rounded, color: AppColors.safeGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(_showRewrite ? 'Hide safer rewrite' : 'View safer rewrite →',
                      style: const TextStyle(color: AppColors.safeGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
            ),
            if (_showRewrite) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.safeGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.safeGreen.withOpacity(0.25)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Expanded(child: Text('SUGGESTED REWRITE',
                        style: TextStyle(color: AppColors.safeGreen, fontSize: 10, fontWeight: FontWeight.w700))),
                    GestureDetector(
                      onTap: _copyRewrite,
                      child: const Icon(Icons.copy_rounded, color: AppColors.safeGreen, size: 16),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(s.suggestedRewrite, style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
                ]),
              ),
              const SizedBox(height: 10),
              // Negotiation tip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('💬 HOW TO NEGOTIATE',
                      style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(s.negotiationTip, style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                ]),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.infoBlue.withOpacity(0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('🛡️ IF THEY REFUSE',
                      style: TextStyle(color: AppColors.infoBlue, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(s.whatToDoIfRefused, style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.sectionTitle);
}