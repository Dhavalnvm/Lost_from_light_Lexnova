import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'package:file_picker/file_picker.dart';

class VersionDiffScreen extends StatefulWidget {
  const VersionDiffScreen({super.key});
  @override
  State<VersionDiffScreen> createState() => _VersionDiffScreenState();
}

class _VersionDiffScreenState extends State<VersionDiffScreen> {
  String? _docIdV1, _docIdV2, _nameV1, _nameV2;
  bool _uploadingV1 = false, _uploadingV2 = false;
  bool _comparing = false;
  VersionDiff? _result;
  String? _error;

  Future<void> _pickAndUpload(bool isV1) async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf', 'docx', 'doc']);
    if (result == null) return;
    final file = File(result.files.single.path!);
    final name = result.files.single.name;
    setState(() { isV1 ? _uploadingV1 = true : _uploadingV2 = true; });
    try {
      final response = await ApiService().uploadDocument(file);
      setState(() {
        if (isV1) { _docIdV1 = response.documentId; _nameV1 = name; }
        else      { _docIdV2 = response.documentId; _nameV2 = name; }
      });
    } catch (e) {
      setState(() => _error = 'Upload failed: $e');
    } finally {
      setState(() { isV1 ? _uploadingV1 = false : _uploadingV2 = false; });
    }
  }

  Future<void> _compare() async {
    if (_docIdV1 == null || _docIdV2 == null) return;
    setState(() { _comparing = true; _error = null; _result = null; });
    try {
      final result = await ApiService().getVersionDiff(_docIdV1!, _docIdV2!);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll(RegExp(r'ApiException\(\d+\): '), ''));
    } finally {
      setState(() => _comparing = false);
    }
  }

  Color _verdictColor(String verdict) {
    if (verdict.contains('better')) return AppColors.safeGreen;
    if (verdict.contains('worse')) return AppColors.dangerRed;
    return AppColors.warningAmber;
  }

  String _verdictLabel(String verdict) {
    switch (verdict) {
      case 'significantly_better': return '🎉 Significantly Better for You';
      case 'slightly_better':      return '✅ Slightly Better for You';
      case 'neutral':              return '➡️ No Significant Change';
      case 'slightly_worse':       return '⚠️ Slightly Worse for You';
      case 'significantly_worse':  return '🚨 Significantly Worse for You';
      default:                     return verdict;
    }
  }

  Color _favColor(String fav) {
    switch (fav) {
      case 'more_favorable': return AppColors.safeGreen;
      case 'less_favorable': return AppColors.dangerRed;
      default:               return AppColors.warningAmber;
    }
  }

  IconData _changeIcon(String type) {
    switch (type) {
      case 'added':   return Icons.add_circle_outline_rounded;
      case 'removed': return Icons.remove_circle_outline_rounded;
      default:        return Icons.edit_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Version Diff',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.cardBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: _UploadVersionCard(
                label: 'Version 1 (Old)',
                filename: _nameV1,
                uploading: _uploadingV1,
                uploaded: _docIdV1 != null,
                onTap: () => _pickAndUpload(true),
                color: AppColors.infoBlue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _UploadVersionCard(
                label: 'Version 2 (New)',
                filename: _nameV2,
                uploading: _uploadingV2,
                uploaded: _docIdV2 != null,
                onTap: () => _pickAndUpload(false),
                color: AppColors.gold,
              )),
            ]).animate().fadeIn(),
            const SizedBox(height: 20),
            if (_docIdV1 != null && _docIdV2 != null) ...[
              SizedBox(
                width: double.infinity, height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(14)),
                  child: ElevatedButton.icon(
                    onPressed: _comparing ? null : _compare,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    icon: _comparing
                        ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Icon(Icons.difference_rounded, color: Colors.white),
                    label: Text(_comparing ? 'Comparing versions...' : 'Find Changes',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 20),
            ],
            if (_error != null) _ErrorCard(message: _error!),
            if (_result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _verdictColor(_result!.overallVerdict).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _verdictColor(_result!.overallVerdict).withOpacity(0.25)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_verdictLabel(_result!.overallVerdict),
                      style: GoogleFonts.plusJakartaSans(
                          color: _verdictColor(_result!.overallVerdict),
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_result!.summary,
                      style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary, height: 1.5, fontSize: 13)),
                  const SizedBox(height: 14),
                  Row(children: [
                    _StatBadge(count: _result!.favorableChanges, label: 'Favorable', color: AppColors.safeGreen),
                    const SizedBox(width: 8),
                    _StatBadge(count: _result!.unfavorableChanges, label: 'Unfavorable', color: AppColors.dangerRed),
                  ]),
                ]),
              ).animate().fadeIn(),
              const SizedBox(height: 16),
              if (_result!.newRestrictionsAdded.isNotEmpty) ...[
                _AlertSection(
                  title: '🚫 New Restrictions in Version 2',
                  items: _result!.newRestrictionsAdded,
                  color: AppColors.dangerRed,
                ),
                const SizedBox(height: 12),
              ],
              if (_result!.rightsRemoved.isNotEmpty) ...[
                _AlertSection(
                  title: '❌ Rights Removed in Version 2',
                  items: _result!.rightsRemoved,
                  color: AppColors.warningAmber,
                ),
                const SizedBox(height: 16),
              ],
              Text('ALL CHANGES', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 10),
              ..._result!.changes.asMap().entries.map((entry) =>
                  _ChangeCard(
                    change: entry.value,
                    favColor: _favColor(entry.value.favorability),
                    changeIcon: _changeIcon(entry.value.changeType),
                  ).animate().fadeIn(delay: Duration(milliseconds: 60 * entry.key)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadVersionCard extends StatelessWidget {
  final String label;
  final String? filename;
  final bool uploading, uploaded;
  final VoidCallback onTap;
  final Color color;

  const _UploadVersionCard({required this.label, this.filename,
    required this.uploading, required this.uploaded, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: uploading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: uploaded ? color : AppColors.cardBorder,
            width: uploaded ? 2 : 1),
        boxShadow: uploaded ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)] : null,
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        uploading
            ? CircularProgressIndicator(color: color, strokeWidth: 2)
            : Icon(uploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
            color: uploaded ? color : AppColors.textMuted, size: 30),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.plusJakartaSans(
            color: color, fontWeight: FontWeight.w600, fontSize: 12),
            textAlign: TextAlign.center),
        if (filename != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(filename!, style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
        ],
        if (!uploaded && !uploading)
          Text('Tap to upload', style: GoogleFonts.plusJakartaSans(
              color: AppColors.textMuted, fontSize: 11)),
      ]),
    ),
  );
}

class _ChangeCard extends StatefulWidget {
  final ContractChange change;
  final Color favColor;
  final IconData changeIcon;
  const _ChangeCard({required this.change, required this.favColor, required this.changeIcon});
  @override
  State<_ChangeCard> createState() => _ChangeCardState();
}

class _ChangeCardState extends State<_ChangeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.change;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.favColor.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0,2))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.favColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.changeIcon, color: widget.favColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.clauseType, style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(c.plainExplanation, style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded ? null : TextOverflow.ellipsis),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _ImpactBadge(impact: c.impact),
                const SizedBox(height: 4),
                Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted, size: 18),
              ]),
            ]),
          ),
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _VersionBox(label: 'V1', text: c.v1Text, color: AppColors.infoBlue)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 8),
                Expanded(child: _VersionBox(label: 'V2', text: c.v2Text, color: widget.favColor)),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _VersionBox extends StatelessWidget {
  final String label, text;
  final Color color;
  const _VersionBox({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.plusJakartaSans(
          color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(text, style: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary, fontSize: 12, height: 1.3),
          maxLines: 5, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _ImpactBadge extends StatelessWidget {
  final String impact;
  const _ImpactBadge({required this.impact});

  @override
  Widget build(BuildContext context) {
    final color = impact == 'high' ? AppColors.dangerRed
        : impact == 'medium' ? AppColors.warningAmber : AppColors.safeGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(impact.toUpperCase(), style: GoogleFonts.plusJakartaSans(
          color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

class _AlertSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  const _AlertSection({required this.title, required this.items, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.plusJakartaSans(
          color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 8),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(Icons.circle, color: color, size: 6),
          const SizedBox(width: 8),
          Expanded(child: Text(item, style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondary, fontSize: 13))),
        ]),
      )),
    ]),
  );
}

class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatBadge({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text('$count $label', style: GoogleFonts.plusJakartaSans(
        color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.dangerRed.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.dangerRed.withOpacity(0.25)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.dangerRed),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: GoogleFonts.plusJakartaSans(color: AppColors.dangerRed))),
    ]),
  );
}