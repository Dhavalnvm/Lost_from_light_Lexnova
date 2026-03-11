import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'contract_comparison_screen.dart';
import 'version_diff_screen.dart';
import 'clause_rewrite_screen.dart';
import 'smart_checklist_screen.dart';
import '../group_discussion/group_discussion_screen.dart';

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
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                      ),
                      child: Text(
                        '📎  Upload a document first, then use these tools',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  _ToolCard(
                    delay: 0,
                    icon: Icons.compare_arrows_rounded,
                    accentColor: AppColors.safeGreen,
                    title: 'Contract Safety Comparison',
                    subtitle: 'Upload 2 contracts — see which one protects you better, clause by clause.',
                    tags: ['Side-by-side', 'Safety score', 'Color diff'],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ContractComparisonScreen())),
                  ),
                  const SizedBox(height: 12),

                  _ToolCard(
                    delay: 80,
                    icon: Icons.auto_fix_high_rounded,
                    accentColor: AppColors.gold,
                    title: 'Clause Rewriting Suggestions',
                    subtitle: 'Get safer rewrites for every risky clause with negotiation tips.',
                    tags: ['Safer rewrites', 'Negotiation tips', '3 tones'],
                    badge: 'From Analyzer',
                    onTap: () => _showDocIdPrompt(context, 'rewrite'),
                  ),
                  const SizedBox(height: 12),

                  _ToolCard(
                    delay: 160,
                    icon: Icons.checklist_rounded,
                    accentColor: AppColors.infoBlue,
                    title: 'Smart Document Checklist',
                    subtitle: 'See exactly what clauses are present, missing, or problematic.',
                    tags: ['Present / Missing', 'Action steps', 'Auto-detect type'],
                    badge: 'From Analyzer',
                    onTap: () => _showDocIdPrompt(context, 'checklist'),
                  ),
                  const SizedBox(height: 12),

                  _ToolCard(
                    delay: 240,
                    icon: Icons.difference_rounded,
                    accentColor: const Color(0xFF7C3AED),
                    title: 'Contract Version Diff',
                    subtitle: "Compare v1 and v2 of the same contract to see what changed — and if it's worse.",
                    tags: ['What changed', 'Favorable / Not', 'Rights removed'],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const VersionDiffScreen())),
                  ),
                  const SizedBox(height: 12),

                  _ToolCard(
                    delay: 320,
                    icon: Icons.groups_rounded,
                    accentColor: const Color(0xFFDB2777),
                    title: 'Group Discussion',
                    subtitle: 'Review a document together in real-time. Share a 6-char room code with your partner.',
                    tags: ['Real-time', 'Ask Lex', 'Room codes'],
                    badge: 'From Analyzer',
                    onTap: () => _showDocIdPrompt(context, 'group_discussion'),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gold.withOpacity(0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.gold, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tip: Use the Analyzer tab to upload documents first, then come back here for advanced tools.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Text(
              tool == 'group_discussion' ? 'Start Group Discussion' : 'Enter Document ID',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tool == 'group_discussion'
                  ? 'Enter the Document ID from the Analyzer tab to start or join a group discussion.'
                  : 'Copy the Document ID from the Analyzer tab after uploading.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. 3f7a-...',
                prefixIcon: Icon(Icons.fingerprint_rounded, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    _navigateToTool(context, tool, ctrl.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Open',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
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
              documentName: docId,
            )));
        break;
    }
  }
}

class _ToolCard extends StatelessWidget {
  final int delay;
  final IconData icon;
  final Color accentColor;
  final String title, subtitle;
  final List<String> tags;
  final String? badge;
  final VoidCallback onTap;

  const _ToolCard({
    required this.delay,
    required this.icon,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(badge!,
                      style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary, fontSize: 11)),
                ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: accentColor.withOpacity(0.5), size: 14),
            ]),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withOpacity(0.18)),
                ),
                child: Text(t,
                    style: GoogleFonts.plusJakartaSans(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: delay))
          .slideY(begin: 0.08),
    );
  }
}