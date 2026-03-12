import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'contract_comparison_screen.dart';
import 'version_diff_screen.dart';
import 'clause_rewrite_screen.dart';
import 'smart_checklist_screen.dart';
import '../group_discussion/group_discussion_screen.dart';
import '../../services/auth_service.dart';


// Top-level helper — avoids class-scope import resolution issues
void _navigateToGroupRoom(BuildContext context, String roomCode) {
  final auth = AuthService();
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => GroupDiscussionScreen(
      roomCode:     roomCode,
      documentId:   '',
      documentName: 'Group Discussion',
      userId:       auth.currentUser?.userId ?? '',
      displayName:  auth.currentUser?.name ?? 'User',
    ),
  ));
}

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0), // light warm background
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Legal Tools', style: AppTextStyles.displayTitle),
                const SizedBox(height: 4),
                Text('Advanced AI-powered contract analysis',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('UPLOAD A DOCUMENT FIRST, THEN USE THESE TOOLS',
                    style: AppTextStyles.sectionTitle),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Feature A — Contract Safety Comparison (green tint)
                _ToolCard(
                  delay:       0,
                  icon:        Icons.compare_arrows_rounded,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFEBF8F0), Color(0xFFD6F0E2)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  accentColor: const Color(0xFF1A7A45),
                  borderColor: const Color(0xFFB2DFC5),
                  title:       'Contract Safety\nComparison',
                  subtitle:    'Upload 2 contracts — see which one protects you better, clause by clause.',
                  tags:        ['Side-by-side', 'Safety score', 'Color diff'],
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ContractComparisonScreen())),
                ),
                const SizedBox(height: 14),
                // Feature B — Clause Rewriting (amber/gold tint)
                _ToolCard(
                  delay:       80,
                  icon:        Icons.auto_fix_high_rounded,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFEF9EC), Color(0xFFFCEFC7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  accentColor: const Color(0xFF92640A),
                  borderColor: const Color(0xFFF0D88A),
                  title:       'Clause Rewriting\nSuggestions',
                  subtitle:    'Get safer rewrites for every risky clause with negotiation tips.',
                  tags:        ['Safer rewrites', 'Negotiation tips', '3 tones'],
                  badge:       'From Analyzer',
                  onTap: () => _showDocIdPrompt(context, 'rewrite'),
                ),
                const SizedBox(height: 14),
                // Feature C — Smart Checklist (blue tint)
                _ToolCard(
                  delay:       160,
                  icon:        Icons.checklist_rounded,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFEDF4FE), Color(0xFFD6E8FD)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  accentColor: const Color(0xFF1A56A8),
                  borderColor: const Color(0xFFB3CFEE),
                  title:       'Smart Document\nChecklist',
                  subtitle:    'See exactly what clauses are present, missing, or problematic.',
                  tags:        ['Present / Missing', 'Action steps', 'Auto-detect type'],
                  badge:       'From Analyzer',
                  onTap: () => _showDocIdPrompt(context, 'checklist'),
                ),
                const SizedBox(height: 14),
                // Feature D — Version Diff (purple tint)
                _ToolCard(
                  delay:       240,
                  icon:        Icons.difference_rounded,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFF4EDFE), Color(0xFFEAD9FD)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  accentColor: const Color(0xFF6B2FA0),
                  borderColor: const Color(0xFFD3B4F5),
                  title:       'Contract Version\nDiff',
                  subtitle:    "Compare v1 and v2 of the same contract to see what changed — and if it's worse.",
                  tags:        ['What changed', 'Favorable / Not', 'Rights removed'],
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const VersionDiffScreen())),
                ),
                const SizedBox(height: 14),
                // Feature E — Group Discussion (sky tint)
                _ToolCard(
                  delay:       320,
                  icon:        Icons.groups_rounded,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFEBF7FD), Color(0xFFCFECFA)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  accentColor: const Color(0xFF0369A1),
                  borderColor: const Color(0xFFADD9EF),
                  title:       'Group Discussion\nRoom',
                  subtitle:    'Join a shared room to discuss a contract with others in real-time — or ask Lex for AI analysis.',
                  tags:        ['Live chat', 'Ask Lex AI', 'Shareable code'],
                  onTap: () => _showGroupCodePrompt(context),
                ),
                const SizedBox(height: 24),
                // Tip card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFFEF9EC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF0D88A).withOpacity(0.7)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: Color(0xFF92640A), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Use the Analyzer tab to upload documents first, then come back here for advanced tools.',
                        style: GoogleFonts.dmSans(
                            color: const Color(0xFF92640A), fontSize: 12, height: 1.4),
                      ),
                    ),
                  ]),
                ).animate().fadeIn(delay: 400.ms),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Doc ID prompt (rewrite / checklist) ───────────────────────────────────

  void _showDocIdPrompt(BuildContext context, String tool) {
    showModalBottomSheet(
      context:            context,
      backgroundColor:    Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _DocIdSheet(tool: tool),
    );
  }

  // ── Group Discussion room-code prompt ─────────────────────────────────────

  void _showGroupCodePrompt(BuildContext context) {
    final ctrl = TextEditingController();
    const accent = Color(0xFF0369A1);

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          bool isJoining = false;

          void join(String code) {
            final trimmed = code.trim().toUpperCase();
            if (trimmed.length != 6) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:  Text('Please enter a valid 6-character room code'),
                behavior: SnackBarBehavior.floating,
              ));
              return;
            }
            setState(() => isJoining = true);
            Navigator.pop(ctx);
            _navigateToGroupRoom(context, trimmed);
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2)),
                  )),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.groups_rounded, color: accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Join Group Discussion',
                          style: GoogleFonts.cormorantGaramond(
                              color: accent, fontSize: 20, fontWeight: FontWeight.w700)),
                      const Text('Enter the 6-character room code',
                          style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                    ]),
                  ]),
                  const SizedBox(height: 24),
                  TextField(
                    controller:         ctrl,
                    autofocus:          true,
                    maxLength:          6,
                    textCapitalization: TextCapitalization.characters,
                    textAlign:          TextAlign.center,
                    style: GoogleFonts.dmSans(
                        color: const Color(0xFF1A1A1A), fontSize: 28,
                        fontWeight: FontWeight.w700, letterSpacing: 10),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText:    '· · · · · ·',
                      hintStyle:   GoogleFonts.dmSans(
                          color: const Color(0xFFBBBBBB), fontSize: 24, letterSpacing: 8),
                      filled:    true,
                      fillColor: const Color(0xFFF5F8FC),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: accent, width: 1.5)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: accent.withOpacity(0.35), width: 1.5)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: accent, width: 2)),
                    ),
                    onChanged:   (v) { if (v.length == 6) join(v); },
                    onSubmitted: (v) => join(v),
                  ),
                  const SizedBox(height: 8),
                  Center(child: Text(
                    'The room code is shared by whoever created the discussion.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    textAlign: TextAlign.center,
                  )),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: isJoining ? null : () => join(ctrl.text),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor:     Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        child: isJoining
                            ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : Text('Join Room',
                            style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                      ),
                    ),
                  ),
                ]),
          );
        },
      ),
    );
  }
}

// ── Doc ID sheet (rewrite / checklist) ────────────────────────────────────────

class _DocIdSheet extends StatefulWidget {
  final String tool;
  const _DocIdSheet({required this.tool});

  @override
  State<_DocIdSheet> createState() => _DocIdSheetState();
}

class _DocIdSheetState extends State<_DocIdSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final docId = _ctrl.text.trim();
    if (docId.isEmpty) return;
    Navigator.pop(context);
    if (widget.tool == 'rewrite') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ClauseRewriteScreen(documentId: docId)));
    } else if (widget.tool == 'checklist') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => SmartChecklistScreen(documentId: docId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Enter Document ID',
                style: GoogleFonts.cormorantGaramond(
                    color: const Color(0xFF92640A), fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Copy the Document ID from the Analyzer tab after uploading.',
                style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller:      _ctrl,
              autofocus:       true,
              style:           const TextStyle(color: Color(0xFF1A1A1A)),
              textInputAction: TextInputAction.done,
              onSubmitted:     (_) => _submit(),
              decoration: const InputDecoration(
                hintText:   'e.g. 3f7a-...',
                hintStyle:  TextStyle(color: Color(0xFFAAAAAA)),
                prefixIcon: Icon(Icons.fingerprint_rounded, color: Color(0xFF999999)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5C842), Color(0xFFE6A817)],
                    ),
                    borderRadius: BorderRadius.circular(12)),
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor:     Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('Open',
                      style: GoogleFonts.dmSans(
                          color:      Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize:   15)),
                ),
              ),
            ),
          ]),
    );
  }
}


// ── Tool Card ─────────────────────────────────────────────────────────────────

class _ToolCard extends StatelessWidget {
  final int            delay;
  final IconData       icon;
  final LinearGradient gradient;
  final Color          accentColor;
  final Color          borderColor;
  final String         title, subtitle;
  final List<String>   tags;
  final String?        badge;
  final VoidCallback   onTap;

  const _ToolCard({
    required this.delay,       required this.icon,
    required this.gradient,    required this.accentColor,
    required this.borderColor,
    required this.title,       required this.subtitle,
    required this.tags,        this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient:     gradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color:       borderColor.withOpacity(0.35),
              blurRadius:  10,
              offset:      const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color:        accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const Spacer(),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor)),
                child: Text(badge!,
                    style: TextStyle(
                        color: accentColor.withOpacity(0.8), fontSize: 11)),
              ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                color: accentColor.withOpacity(0.5), size: 14),
          ]),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.cormorantGaramond(
                  color: accentColor, fontSize: 22,
                  fontWeight: FontWeight.w700, height: 1.2)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  color: accentColor.withOpacity(0.7), fontSize: 13, height: 1.5)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withOpacity(0.2)),
              ),
              child: Text(t,
                  style: TextStyle(
                      color:      accentColor,
                      fontSize:   11,
                      fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ]),
      ).animate()
          .fadeIn(delay: Duration(milliseconds: delay))
          .slideY(begin: 0.1),
    );
  }
}