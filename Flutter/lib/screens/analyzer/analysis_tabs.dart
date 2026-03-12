import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common/common_widgets.dart';

class AnalysisTabs extends StatefulWidget {
  final DocumentSummary?  summary;
  final RiskAnalysis?     riskAnalysis;
  final ClauseFairness?   clauseFairness;
  final SafetyScore?      safetyScore;

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

  /// Called whenever the parent passes updated props down.
  /// This is what was MISSING — without this, late-arriving SSE data
  /// (summary, risk) would never trigger a visual update in the tab content.
  @override
  void didUpdateWidget(AnalysisTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    final summaryArrived  = oldWidget.summary       == null && widget.summary       != null;
    final riskArrived     = oldWidget.riskAnalysis  == null && widget.riskAnalysis  != null;
    final fairnessArrived = oldWidget.clauseFairness == null && widget.clauseFairness != null;

    if (summaryArrived || riskArrived || fairnessArrived) {
      // Auto-switch to summary tab when it finally arrives and the user
      // is still on the loading placeholder
      if (summaryArrived && _tabController.index == 0) {
        // Already on summary tab — setState alone is enough to re-render
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: TabBar(
            controller:           _tabController,
            indicator: BoxDecoration(
              gradient:     AppColors.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize:        TabBarIndicatorSize.tab,
            dividerColor:         Colors.transparent,
            labelColor:           AppColors.background,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.dmSans(
                fontWeight: FontWeight.w500, fontSize: 13),
            tabs: [
              // Show a subtle loading dot on tabs that are still pending
              _buildTab('Summary',  widget.summary       == null),
              _buildTab('Risks',    widget.riskAnalysis  == null),
              _buildTab('Fairness', widget.clauseFairness == null),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _SummaryTab(summary:        widget.summary),
              _RisksTab(riskAnalysis:     widget.riskAnalysis),
              _FairnessTab(clauseFairness: widget.clauseFairness),
            ],
          ),
        ),
      ],
    );
  }

  /// Tab label with a small amber dot when that section is still loading
  Widget _buildTab(String label, bool isLoading) {
    return Tab(
      child: Row(
        mainAxisSize:     MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (isLoading) ...[
            const SizedBox(width: 6),
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warningAmber,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 600.ms),
          ],
        ],
      ),
    );
  }
}

// ─── Summary Tab ──────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final DocumentSummary? summary;
  const _SummaryTab({this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
            const SizedBox(height: 16),
            Text('Generating summary...',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Text('This may take a moment',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      );
    }

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
                      Row(children: [
                        const Icon(Icons.task_alt_rounded,
                            color: AppColors.warningAmber, size: 16),
                        const SizedBox(width: 6),
                        Text('Obligations',
                            style: GoogleFonts.dmSans(
                                fontSize:   12,
                                fontWeight: FontWeight.w600,
                                color:      AppColors.textMuted,
                                letterSpacing: 1)),
                      ]),
                      const SizedBox(height: 10),
                      ...summary!.keyObligations.take(4).map((o) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 5, height: 5,
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.warningAmber),
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
                      Row(children: [
                        const Icon(Icons.shield_outlined,
                            color: AppColors.safeGreen, size: 16),
                        const SizedBox(width: 6),
                        Text('Rights',
                            style: GoogleFonts.dmSans(
                                fontSize:   12,
                                fontWeight: FontWeight.w600,
                                color:      AppColors.textMuted,
                                letterSpacing: 1)),
                      ]),
                      const SizedBox(height: 10),
                      ...summary!.keyRights.take(4).map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 5, height: 5,
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.safeGreen),
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
                        color:        AppColors.goldGlow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.article_outlined,
                          color: AppColors.gold, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clause.clauseType,
                              style: GoogleFonts.dmSans(
                                  color:      AppColors.gold,
                                  fontWeight: FontWeight.w600,
                                  fontSize:   12)),
                          const SizedBox(height: 4),
                          Text(clause.extractedText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 12, height: 1.5)),
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
    if (riskAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
            const SizedBox(height: 16),
            Text('Analyzing risks...',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    final flags = riskAnalysis!.detectedRedFlags;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(label: 'Risk Summary'),
              const SizedBox(height: 10),
              Text(riskAnalysis!.riskSummary,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.6)),
            ]),
          ),
          const SizedBox(height: 16),
          if (flags.isEmpty)
            GlassCard(
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.safeGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('No significant red flags detected.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ]),
            )
          else ...[
            const SectionHeader(label: 'Red Flags'),
            const SizedBox(height: 10),
            ...flags.map((flag) {
              final color = flag.severity == 'high'
                  ? AppColors.dangerRed
                  : flag.severity == 'medium'
                  ? AppColors.warningAmber
                  : AppColors.infoBlue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderColor: color.withOpacity(0.3),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:        color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(flag.severity.toUpperCase(),
                                style: TextStyle(
                                    color:      color,
                                    fontSize:   10,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(flag.flagType,
                                style: GoogleFonts.dmSans(
                                    color:      AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize:   13)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(flag.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.5)),
                        if (flag.extractedText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:        AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: color.withOpacity(0.2)),
                            ),
                            child: Text(
                              '"${flag.extractedText}"',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ]),
                ),
              );
            }),
          ],
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ─── Fairness Tab ─────────────────────────────────────────────────────────────

class _FairnessTab extends StatelessWidget {
  final ClauseFairness? clauseFairness;
  const _FairnessTab({this.clauseFairness});

  @override
  Widget build(BuildContext context) {
    if (clauseFairness == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
            const SizedBox(height: 16),
            Text('Checking clause fairness...',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    final clauses = clauseFairness!.clausesAnalyzed;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Row(children: [
              const Icon(Icons.balance_rounded,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overall Fairness',
                          style: GoogleFonts.dmSans(
                              color:      AppColors.textMuted,
                              fontSize:   11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(clauseFairness!.overallFairness,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.gold)),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (clauses.isNotEmpty) ...[
            const SectionHeader(label: 'Clause Analysis'),
            const SizedBox(height: 10),
            ...clauses.map((clause) {
              final rating = clause.fairnessRating.toLowerCase();
              final color  = rating.contains('unfair')
                  ? AppColors.dangerRed
                  : rating.contains('fair')
                  ? AppColors.safeGreen
                  : AppColors.warningAmber;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderColor: color.withOpacity(0.25),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(clause.clauseType,
                                style: GoogleFonts.dmSans(
                                    color:      AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize:   13)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:        color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(clause.fairnessRating,
                                style: TextStyle(
                                    color:      color,
                                    fontSize:   10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(clause.aiInsight,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.5)),
                        if (clause.contractValue.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _FairnessRow(
                              label: 'In this contract',
                              value: clause.contractValue,
                              color: color),
                          const SizedBox(height: 4),
                          _FairnessRow(
                              label: 'Typical standard',
                              value: clause.typicalStandard,
                              color: AppColors.safeGreen),
                        ],
                      ]),
                ),
              );
            }),
          ],
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _FairnessRow extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _FairnessRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color:        AppColors.surface,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: ',
          style: TextStyle(
              color:      color,
              fontSize:   11,
              fontWeight: FontWeight.w600)),
      Expanded(
        child: Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 11, height: 1.4)),
      ),
    ]),
  );
}