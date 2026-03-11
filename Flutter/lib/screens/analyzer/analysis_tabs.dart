import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common/common_widgets.dart';

class AnalysisTabs extends StatefulWidget {
  final DocumentSummary? summary;
  final RiskAnalysis? riskAnalysis;
  final ClauseFairness? clauseFairness;
  final SafetyScore? safetyScore;

  const AnalysisTabs({
    super.key,
    this.summary,
    this.riskAnalysis,
    this.clauseFairness,
    this.safetyScore,
  });

  @override
  State<AnalysisTabs> createState() => _AnalysisTabsState();
}

class _AnalysisTabsState extends State<AnalysisTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.background,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.dmSans(
                fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'Summary'),
              Tab(text: 'Risks'),
              Tab(text: 'Fairness'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _SummaryTab(summary: widget.summary),
              _RisksTab(riskAnalysis: widget.riskAnalysis),
              _FairnessTab(clauseFairness: widget.clauseFairness),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Summary Tab ──────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final DocumentSummary? summary;
  const _SummaryTab({this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main summary
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(label: 'AI Summary'),
                const SizedBox(height: 12),
                Text(
                  summary!.summary,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.7),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Obligations & Rights
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.task_alt_rounded,
                              color: AppColors.warningAmber, size: 16),
                          const SizedBox(width: 6),
                          Text('Obligations',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 1,
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...summary!.keyObligations.take(4).map((o) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(top: 6, right: 8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.warningAmber,
                                  ),
                                ),
                                Expanded(
                                  child: Text(o,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontSize: 12, height: 1.5)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined,
                              color: AppColors.safeGreen, size: 16),
                          const SizedBox(width: 6),
                          Text('Rights',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 1,
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...summary!.keyRights.take(4).map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(top: 6, right: 8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.safeGreen,
                                  ),
                                ),
                                Expanded(
                                  child: Text(r,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontSize: 12, height: 1.5)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Key clauses
          if (summary!.importantClauses.isNotEmpty) ...[
            const SectionHeader(label: 'Detected Clauses'),
            const SizedBox(height: 10),
            ...summary!.importantClauses.take(6).map((clause) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.goldGlow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.article_outlined,
                              color: AppColors.gold, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(clause.clauseType,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                clause.extractedText,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ─── Risks Tab ────────────────────────────────────────────────────────────────

class _RisksTab extends StatelessWidget {
  final RiskAnalysis? riskAnalysis;
  const _RisksTab({this.riskAnalysis});

  @override
  Widget build(BuildContext context) {
    if (riskAnalysis == null) return const Center(child: CircularProgressIndicator());

    final r = riskAnalysis!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk summary card
          GlassCard(
            borderColor: _riskColor(r.riskLevel).withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ScoreRing(
                        score: r.riskScore, size: 80, label: 'RISK'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Risk Level',
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            r.riskLevel,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _riskColor(r.riskLevel),
                            ),
                          ),
                          Text(
                            '${r.detectedRedFlags.length} red flags found',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (r.riskSummary.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const GoldDivider(),
                  const SizedBox(height: 14),
                  Text(r.riskSummary,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (r.detectedRedFlags.isEmpty)
            const EmptyState(
              icon: Icons.verified_rounded,
              title: 'No Red Flags Found',
              subtitle: 'This document appears to have no major risky clauses',
            )
          else ...[
            const SectionHeader(label: 'Red Flags'),
            const SizedBox(height: 10),
            ...r.detectedRedFlags.map((flag) => _RedFlagCard(flag: flag)),
          ],
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Color _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return AppColors.dangerRed;
      case 'medium':
        return AppColors.warningAmber;
      default:
        return AppColors.safeGreen;
    }
  }
}

class _RedFlagCard extends StatefulWidget {
  final RedFlag flag;
  const _RedFlagCard({required this.flag});

  @override
  State<_RedFlagCard> createState() => _RedFlagCardState();
}

class _RedFlagCardState extends State<_RedFlagCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.flag.severity == 'high'
        ? AppColors.dangerRed
        : widget.flag.severity == 'medium'
            ? AppColors.warningAmber
            : AppColors.safeGreen;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.08), AppColors.cardBg],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_rounded, color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.flag.flagType,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: color),
                    ),
                  ),
                  RiskBadge(severity: widget.flag.severity),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.flag.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
              ),
              if (_expanded && widget.flag.extractedText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.cardBorder, width: 1),
                  ),
                  child: Text(
                    '"${widget.flag.extractedText}"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Fairness Tab ─────────────────────────────────────────────────────────────

class _FairnessTab extends StatelessWidget {
  final ClauseFairness? clauseFairness;
  const _FairnessTab({this.clauseFairness});

  @override
  Widget build(BuildContext context) {
    if (clauseFairness == null) return const Center(child: CircularProgressIndicator());

    final f = clauseFairness!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall fairness banner
          GlassCard(
            borderColor: AppColors.gold.withOpacity(0.3),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                  ),
                  child: const Icon(Icons.balance_rounded,
                      color: AppColors.background, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overall Fairness',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        f.overallFairness,
                        style: AppTextStyles.goldTitle.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (f.clausesAnalyzed.isEmpty)
            const EmptyState(
              icon: Icons.balance_rounded,
              title: 'No Clauses Compared',
              subtitle: 'No specific clauses matched standard benchmarks',
            )
          else ...[
            const SectionHeader(
                label: 'Clause Comparison',
                subtitle: 'Compared against industry standards'),
            const SizedBox(height: 10),
            ...f.clausesAnalyzed.map((c) => _FairnessCard(clause: c)),
          ],
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _FairnessCard extends StatelessWidget {
  final ClauseFairnessItem clause;
  const _FairnessCard({required this.clause});

  Color get _fairnessColor {
    final r = clause.fairnessRating.toLowerCase();
    if (r.contains('very unfair')) return AppColors.dangerRed;
    if (r.contains('unfair')) return AppColors.warningAmber;
    if (r.contains('fair')) return AppColors.safeGreen;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderColor: _fairnessColor.withOpacity(0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(clause.clauseType,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _fairnessColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _fairnessColor.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    clause.fairnessRating,
                    style: TextStyle(
                      color: _fairnessColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CompareBox(
                    label: 'Contract Says',
                    value: clause.contractValue,
                    color: _fairnessColor,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.compare_arrows_rounded,
                    color: AppColors.textMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompareBox(
                    label: 'Typical Standard',
                    value: clause.typicalStandard,
                    color: AppColors.safeGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.gold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clause.aiInsight,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompareBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
