import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'package:file_picker/file_picker.dart';

class ContractComparisonScreen extends StatefulWidget {
  const ContractComparisonScreen({super.key});
  @override
  State<ContractComparisonScreen> createState() => _ContractComparisonScreenState();
}

class _ContractComparisonScreenState extends State<ContractComparisonScreen> {
  File? _fileA;
  File? _fileB;
  String? _docIdA;
  String? _docIdB;
  String? _nameA;
  String? _nameB;
  bool _uploadingA = false;
  bool _uploadingB = false;
  bool _comparing = false;
  ContractComparison? _result;
  String? _error;

  Future<void> _pickAndUpload(bool isA) async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf', 'docx', 'doc']);
    if (result == null) return;
    final file = File(result.files.single.path!);
    final name = result.files.single.name;
    setState(() { isA ? _uploadingA = true : _uploadingB = true; });
    try {
      final response = await ApiService().uploadDocument(file);
      setState(() {
        if (isA) { _fileA = file; _docIdA = response.documentId; _nameA = name; }
        else      { _fileB = file; _docIdB = response.documentId; _nameB = name; }
      });
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      setState(() { isA ? _uploadingA = false : _uploadingB = false; });
    }
  }

  Future<void> _compare() async {
    if (_docIdA == null || _docIdB == null) return;
    setState(() { _comparing = true; _error = null; _result = null; });
    try {
      final result = await ApiService().compareContracts(_docIdA!, _docIdB!);
      setState(() => _result = result);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _comparing = false);
    }
  }

  void _showError(String msg) => setState(() => _error = msg.replaceAll(RegExp(r'ApiException\(\d+\): '), ''));

  Color _outcomeColor(String outcome) {
    switch (outcome) {
      case 'better': return AppColors.safeGreen;
      case 'worse':  return AppColors.dangerRed;
      default:       return AppColors.warningAmber;
    }
  }

  IconData _outcomeIcon(String outcome) {
    switch (outcome) {
      case 'better': return Icons.arrow_upward_rounded;
      case 'worse':  return Icons.arrow_downward_rounded;
      default:       return Icons.remove_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Contract Comparison', style: AppTextStyles.goldTitle.copyWith(fontSize: 20)),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Upload cards row
            Row(children: [
              Expanded(child: _UploadCard(
                label: 'Contract A',
                filename: _nameA,
                uploading: _uploadingA,
                uploaded: _docIdA != null,
                onTap: () => _pickAndUpload(true),
              )),
              const SizedBox(width: 12),
              Expanded(child: _UploadCard(
                label: 'Contract B',
                filename: _nameB,
                uploading: _uploadingB,
                uploaded: _docIdB != null,
                onTap: () => _pickAndUpload(false),
              )),
            ]).animate().fadeIn(),
            const SizedBox(height: 20),
            // Compare button
            if (_docIdA != null && _docIdB != null) ...[
              SizedBox(
                width: double.infinity, height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _comparing ? null : _compare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _comparing
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                        : const Icon(Icons.compare_arrows_rounded, color: Colors.black),
                    label: Text(_comparing ? 'Analysing...' : 'Compare Contracts',
                        style: GoogleFonts.dmSans(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 20),
            ],
            if (_error != null)
              _ErrorCard(message: _error!),
            if (_result != null) ...[
              _VerdictCard(result: _result!),
              const SizedBox(height: 16),
              _ScoresRow(result: _result!),
              const SizedBox(height: 16),
              if (_result!.keyDifferences.isNotEmpty) ...[
                _SectionHeader('Key Differences'),
                const SizedBox(height: 8),
                ..._result!.keyDifferences.map((d) => _KeyDifferenceChip(text: d)),
                const SizedBox(height: 16),
              ],
              _SectionHeader('Clause-by-Clause Breakdown'),
              const SizedBox(height: 8),
              ..._result!.clauseComparisons.asMap().entries.map((entry) =>
                _ClauseCompCard(
                  clause: entry.value,
                  outcomeColor: _outcomeColor(entry.value.outcome),
                  outcomeIcon: _outcomeIcon(entry.value.outcome),
                  nameA: _result!.filenameA,
                  nameB: _result!.filenameB,
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * entry.key)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String label;
  final String? filename;
  final bool uploading, uploaded;
  final VoidCallback onTap;

  const _UploadCard({required this.label, this.filename, required this.uploading, required this.uploaded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: uploaded ? AppColors.gold : AppColors.cardBorder, width: uploaded ? 1.5 : 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          uploading
              ? const CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)
              : Icon(uploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                  color: uploaded ? AppColors.gold : AppColors.textMuted, size: 32),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.dmSans(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13)),
          if (filename != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(filename!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ),
          ],
          if (!uploaded && !uploading)
            const Text('Tap to upload', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  final ContractComparison result;
  const _VerdictCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final winnerName = result.winner == 'A' ? result.filenameA
        : result.winner == 'B' ? result.filenameB : 'Both are equal';
    final winnerColor = result.winner == 'A' ? AppColors.safeGreen
        : result.winner == 'B' ? AppColors.infoBlue : AppColors.warningAmber;

    return Container(
      decoration: BoxDecoration(
        gradient: result.winner == 'A' ? AppColors.safeGradient : AppColors.dangerGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: winnerColor.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.verified_rounded, color: winnerColor, size: 20),
          const SizedBox(width: 8),
          Text('VERDICT', style: AppTextStyles.sectionTitle.copyWith(color: winnerColor)),
        ]),
        const SizedBox(height: 12),
        if (result.winner != 'tie')
          RichText(text: TextSpan(children: [
            TextSpan(text: winnerName, style: GoogleFonts.cormorantGaramond(
                color: winnerColor, fontSize: 18, fontWeight: FontWeight.w700)),
            TextSpan(text: ' is ${result.percentageDifference}% safer',
                style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ])),
        const SizedBox(height: 8),
        Text(result.verdict, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
      ]),
    );
  }
}

class _ScoresRow extends StatelessWidget {
  final ContractComparison result;
  const _ScoresRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _ScoreCard(label: result.filenameA, score: result.contractASafetyScore,
          isWinner: result.winner == 'A', color: AppColors.safeGreen)),
      const SizedBox(width: 12),
      Expanded(child: _ScoreCard(label: result.filenameB, score: result.contractBSafetyScore,
          isWinner: result.winner == 'B', color: AppColors.infoBlue)),
    ]);
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final int score;
  final bool isWinner;
  final Color color;
  const _ScoreCard({required this.label, required this.score, required this.isWinner, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isWinner ? color.withOpacity(0.5) : AppColors.cardBorder,
            width: isWinner ? 1.5 : 1),
      ),
      child: Column(children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Text('$score', style: GoogleFonts.cormorantGaramond(
            color: color, fontSize: 36, fontWeight: FontWeight.w700)),
        Text('/ 100', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        if (isWinner) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text('SAFER', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(title.toUpperCase(), style: AppTextStyles.sectionTitle);
}

class _KeyDifferenceChip extends StatelessWidget {
  final String text;
  const _KeyDifferenceChip({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.goldGlow,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.goldDark.withOpacity(0.4)),
    ),
    child: Row(children: [
      const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
    ]),
  );
}

class _ClauseCompCard extends StatelessWidget {
  final ClauseComparison clause;
  final Color outcomeColor;
  final IconData outcomeIcon;
  final String nameA, nameB;

  const _ClauseCompCard({required this.clause, required this.outcomeColor,
    required this.outcomeIcon, required this.nameA, required this.nameB});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: outcomeColor.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(bottom: BorderSide(color: outcomeColor.withOpacity(0.2))),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: outcomeColor.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(outcomeIcon, color: outcomeColor, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(clause.clauseType, style: GoogleFonts.dmSans(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
            _SeverityBadge(severity: clause.severity),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _ContractBox(label: 'A', text: clause.contractAText,
                  highlight: clause.winner == 'A')),
              const SizedBox(width: 8),
              Expanded(child: _ContractBox(label: 'B', text: clause.contractBText,
                  highlight: clause.winner == 'B')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.gold, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(clause.reason, style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.4))),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _ContractBox extends StatelessWidget {
  final String label, text;
  final bool highlight;
  const _ContractBox({required this.label, required this.text, required this.highlight});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: highlight ? AppColors.safeGreen.withOpacity(0.06) : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: highlight ? AppColors.safeGreen.withOpacity(0.3) : AppColors.cardBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Contract $label', style: TextStyle(
          color: highlight ? AppColors.safeGreen : AppColors.textMuted,
          fontSize: 10, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
          maxLines: 4, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = severity == 'high' ? AppColors.dangerRed
        : severity == 'medium' ? AppColors.warningAmber : AppColors.safeGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(severity.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.dangerRed.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.dangerRed.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.dangerRed),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: const TextStyle(color: AppColors.dangerRed))),
    ]),
  );
}