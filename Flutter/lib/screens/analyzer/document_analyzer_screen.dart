import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common/common_widgets.dart';
import 'analysis_tabs.dart';
import 'document_chat_sheet.dart';

class DocumentAnalyzerScreen extends StatefulWidget {
  const DocumentAnalyzerScreen({super.key});

  @override
  State<DocumentAnalyzerScreen> createState() => _DocumentAnalyzerScreenState();
}

class _DocumentAnalyzerScreenState extends State<DocumentAnalyzerScreen> {
  final _api = ApiService();

  File? _selectedFile;
  UploadResponse? _uploadResponse;
  SafetyScore? _safetyScore;
  RiskAnalysis? _riskAnalysis;
  ClauseFairness? _clauseFairness;
  DocumentSummary? _summary;

  bool _isUploading = false;
  bool _isAnalyzing = false;
  String _analysisMode = 'student';
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _uploadResponse = null;
        _safetyScore = null;
        _riskAnalysis = null;
        _clauseFairness = null;
        _summary = null;
        _error = null;
      });
    }
  }

  Future<void> _analyzeDocument() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      // Step 1: Upload
      final upload = await _api.uploadDocument(_selectedFile!);
      setState(() {
        _uploadResponse = upload;
        _isUploading = false;
        _isAnalyzing = true;
      });

      // Step 2: Run all analyses in parallel
      final results = await Future.wait([
        _api.getSafetyScore(upload.documentId),
        _api.getRiskAnalysis(upload.documentId),
        _api.getClauseFairness(upload.documentId),
        _api.getDocumentSummary(upload.documentId, _analysisMode),
      ]);

      setState(() {
        _safetyScore = results[0] as SafetyScore;
        _riskAnalysis = results[1] as RiskAnalysis;
        _clauseFairness = results[2] as ClauseFairness;
        _summary = results[3] as DocumentSummary;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isAnalyzing = false;
        _error = e.toString().replaceAll('ApiException', '').trim();
      });
    }
  }

  void _openChat() {
    if (_uploadResponse == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DocumentChatSheet(
        documentId: _uploadResponse!.documentId,
        filename: _uploadResponse!.filename,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _buildUploadSection(),
                if (_error != null) _buildError(),
                if (_isUploading || _isAnalyzing) _buildLoadingState(),
                if (_safetyScore != null) ...[
                  const SizedBox(height: 24),
                  _buildSafetyHero(),
                  const SizedBox(height: 24),
                  AnalysisTabs(
                    summary: _summary,
                    riskAnalysis: _riskAnalysis,
                    clauseFairness: _clauseFairness,
                    safetyScore: _safetyScore,
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _safetyScore != null
          ? FloatingActionButton.extended(
              onPressed: _openChat,
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.background,
              icon: const Icon(Icons.chat_bubble_rounded, size: 20),
              label: Text(
                'Chat with Doc',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
              elevation: 8,
            ).animate().slideY(begin: 2, end: 0, delay: 300.ms, duration: 500.ms)
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Analyzer',
              style: AppTextStyles.goldTitle.copyWith(fontSize: 22),
            ),
            Text(
              'Upload · Analyze · Understand',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode selector
        Row(
          children: ['beginner', 'student', 'professional'].map((mode) {
            final isSelected = _analysisMode == mode;
            return GestureDetector(
              onTap: () => setState(() => _analysisMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldGlow : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  mode[0].toUpperCase() + mode.substring(1),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.gold : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Upload zone
        GestureDetector(
          onTap: _isUploading || _isAnalyzing ? null : _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: _selectedFile != null
                  ? const LinearGradient(
                      colors: [Color(0xFF1A1F0E), Color(0xFF121810)],
                    )
                  : AppColors.cardGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedFile != null
                    ? AppColors.safeGreen.withOpacity(0.5)
                    : AppColors.cardBorder,
                width: 1.5,
              ),
            ),
            child: _selectedFile == null
                ? Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldGlow,
                          border: Border.all(color: AppColors.goldDark, width: 1),
                        ),
                        child: const Icon(
                          Icons.upload_file_rounded,
                          color: AppColors.gold,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Drop your document here',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PDF • DOCX • Images (OCR)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.goldDark, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Browse Files',
                          style: GoogleFonts.dmSans(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.safeGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check_circle_rounded,
                            color: AppColors.safeGreen, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.path.split('/').last.split('\\').last,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Ready to analyze  ·  Tap to change',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        if (_selectedFile != null && _safetyScore == null && !_isUploading && !_isAnalyzing) ...[
          const SizedBox(height: 16),
          GoldButton(
            label: 'Analyze Document',
            icon: Icons.auto_awesome_rounded,
            onTap: _analyzeDocument,
            width: double.infinity,
          ),
        ],
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.background, size: 36),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1500.ms, color: AppColors.goldLight),
          const SizedBox(height: 20),
          Text(
            _isUploading ? 'Uploading document...' : 'AI is analyzing...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _isUploading
                ? 'Extracting text and generating embeddings'
                : 'Detecting risks, comparing clauses, calculating score',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const ShimmerBox(height: 80),
          const SizedBox(height: 10),
          const ShimmerBox(height: 60),
          const SizedBox(height: 10),
          const ShimmerBox(height: 60),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSafetyHero() {
    final score = _safetyScore!;
    Color bgColor;
    String verdict;

    if (score.safetyScore >= 70) {
      bgColor = AppColors.safeGreen;
      verdict = 'Generally Safe to Sign';
    } else if (score.safetyScore >= 40) {
      bgColor = AppColors.warningAmber;
      verdict = 'Review Before Signing';
    } else {
      bgColor = AppColors.dangerRed;
      verdict = 'Risky — Consult a Lawyer';
    }

    return GlassCard(
      borderColor: bgColor.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            children: [
              ScoreRing(
                score: score.safetyScore,
                size: 100,
                label: 'SAFETY',
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contract Safety Score',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      verdict,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: bgColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: bgColor.withOpacity(0.4), width: 1),
                      ),
                      child: Text(
                        '${score.riskLevel} Risk',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: bgColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (score.recommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            const GoldDivider(),
            const SizedBox(height: 16),
            ...score.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          rec,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GlassCard(
        borderColor: AppColors.dangerRed.withOpacity(0.4),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.dangerRed, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error ?? 'Something went wrong',
                style: const TextStyle(color: AppColors.dangerRed, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().shake();
  }
}
