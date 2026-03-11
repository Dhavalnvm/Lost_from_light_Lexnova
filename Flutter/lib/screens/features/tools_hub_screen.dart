import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'contract_comparison_screen.dart';
import 'version_diff_screen.dart';
import 'clause_rewrite_screen.dart';
import 'smart_checklist_screen.dart';
import '../group_discussion/group_discussion_screen.dart';  // ← Group Discussion

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Legal Tools', style: AppTextStyles.displayTitle),
                    const SizedBox(height: 4),
                    Text(
                      'Advanced AI-powered contract analysis',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UPLOAD A DOCUMENT FIRST, THEN USE THESE TOOLS',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Feature A: Contract Safety Comparison ───────────────────
                  _ToolCard(
                    delay: 0,
                    icon: Icons.compare_arrows_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0F2A1A), Color(0xFF081A0F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    accentColor: AppColors.safeGreen,
                    title: 'Contract Safety\nComparison',
                    subtitle:
                        'Upload 2 contracts — see which one protects you better, clause by clause.',
                    tags: ['Side-by-side', 'Safety score', 'Color diff'],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ContractComparisonScreen())),
                  ),
                  const SizedBox(height: 14),

                  // ── Feature B: Clause Rewriting ─────────────────────────────
                  _ToolCard(
                    delay: 80,
                    icon: Icons.auto_fix_high_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1A1008), Color(0xFF0D0804)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    accentColor: AppColors.gold,
                    title: 'Clause Rewriting\nSuggestions',
                    subtitle:
                        'Get safer rewrites for every risky clause with negotiation tips.',
                    tags: ['Safer rewrites', 'Negotiation tips', '3 tones'],
                    badge: 'From Analyzer',
                    onTap: () => _showDocIdPrompt(context, 'rewrite'),
                  ),
                  const SizedBox(height: 14),

                  // ── Feature C: Smart Checklist ──────────────────────────────
                  _ToolCard(
                    delay: 160,
                    icon: Icons.checklist_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0A0F2A), Color(0xFF060815)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    accentColor: AppColors.infoBlue,
                    title: 'Smart Document\nChecklist',
                    subtitle:
                        'See exactly what clauses are present, missing, or problematic.',
                    tags: ['Present / Missing', 'Action steps', 'Auto-detect type'],
                    badge: 'From Analyzer',
                    onTap: () => _showDocIdPrompt(context, 'checklist'),
                  ),
                  const SizedBox(height: 14),

                  // ── Feature D: Version Diff ─────────────────────────────────
                  _ToolCard(
                    delay: 240,
                    icon: Icons.difference_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1A0A1A), Color(0xFF0D060D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    accentColor: const Color(0xFFB06BF5),
                    title: 'Contract Version\nDiff',
                    subtitle:
                        "Compare v1 and v2 of the same contract to see what changed — and if it's worse.",
                    tags: ['What changed', 'Favorable / Not', 'Rights removed'],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const VersionDiffScreen())),
                  ),
                  const SizedBox(height: 14),

                  // ── Feature E: Group Discussion ─────────────────────────────
                  _ToolCard(
                    delay: 320,
                    icon: Icons.groups_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1A100A), Color(0xFF0F0804)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    accentColor: AppColors.gold,
                    title: 'Group\nDiscussion',
                    subtitle:
                        'Review a document together in real-time. Share a 6-char room code with your partner and ask Lex questions as a group.',
                    tags: ['Real-time', 'Ask Lex', 'Room codes'],
                    badge: 'From Analyzer',
                    onTap: () => _showDocIdPrompt(context, 'group_discussion'),
                  ),
                  const SizedBox(height: 24),

                  // ── Tip card ─────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.goldGlow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.goldDark.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          color: AppColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tip: Use the Analyzer tab to upload documents first, then come back here for advanced tools.',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4),
                        ),
                      ),
                    ]),
                  ).animate().fadeIn(delay: 480.ms),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocIdPrompt(BuildContext context, String tool) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tool == 'group_discussion'
                  ? 'Start Group Discussion'
                  : 'Enter Document ID',
              style: GoogleFonts.cormorantGaramond(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              tool == 'group_discussion'
                  ? 'Enter the Document ID from the Analyzer tab to start or join a group discussion.'
                  : 'Copy the Document ID from the Analyzer tab after uploading.',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. 3f7a-...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.fingerprint_rounded,
                    color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12)),
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    _navigateToTool(context, tool, ctrl.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('Open',
                      style: GoogleFonts.dmSans(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTool(BuildContext context, String tool, String docId) {
    switch (tool) {
      case 'rewrite':
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => ClauseRewriteScreen(documentId: docId)));
        break;
      case 'checklist':
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => SmartChecklistScreen(documentId: docId)));
        break;
      case 'group_discussion':
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => GroupDiscussionLobby(
                  documentId: docId,
                  // Filename not known from here — user sees it in the lobby
                  documentName: docId,
                )));
        break;
    }
  }
}

// ─── Tool Card ─────────────────────────────────────────────────────────────────

class _ToolCard extends StatelessWidget {
  final int delay;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final String title, subtitle;
  final List<String> tags;
  final String? badge;
  final VoidCallback onTap;

  const _ToolCard({
    required this.delay,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.tags,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder)),
                  child: Text(badge!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: accentColor.withOpacity(0.6), size: 14),
            ]),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.cormorantGaramond(
                    color: accentColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: accentColor.withOpacity(0.2)),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                color: accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ).animate()
          .fadeIn(delay: Duration(milliseconds: delay))
          .slideY(begin: 0.1),
    );
  }
}