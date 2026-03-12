import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class SmartChecklistScreen extends StatefulWidget {
  final String documentId;
  final String? initialDocType;
  const SmartChecklistScreen({super.key, required this.documentId, this.initialDocType});

  @override
  State<SmartChecklistScreen> createState() => _SmartChecklistScreenState();
}

class _SmartChecklistScreenState extends State<SmartChecklistScreen> {
  SmartChecklist? _result;
  bool _loading = true;
  String? _error;
  String _selectedDocType = '';

  final List<Map<String, String>> _docTypes = [
    {'value': '', 'label': 'Auto-detect'},
    {'value': 'rental', 'label': 'Rental'},
    {'value': 'employment', 'label': 'Employment'},
    {'value': 'loan', 'label': 'Loan'},
    {'value': 'business', 'label': 'Business'},
    {'value': 'nda', 'label': 'NDA'},
    {'value': 'general', 'label': 'General'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDocType = widget.initialDocType ?? '';
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService().getSmartChecklist(widget.documentId, docType: _selectedDocType);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll(RegExp(r'ApiException\(\d+\): '), ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present': return AppColors.safeGreen;
      case 'warning': return AppColors.warningAmber;
      default:        return AppColors.dangerRed;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'present': return Icons.check_circle_rounded;
      case 'warning': return Icons.warning_amber_rounded;
      default:        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Smart Checklist',
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
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _docTypes.map((t) {
                  final isSelected = _selectedDocType == t['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDocType = t['value']!);
                      _load();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.gold.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.cardBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(t['label']!,
                          style: GoogleFonts.plusJakartaSans(
                              color: isSelected ? AppColors.gold : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircularProgressIndicator(color: AppColors.gold),
              const SizedBox(height: 16),
              Text('Generating checklist...',
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
            ]))
                : _error != null
                ? Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: GoogleFonts.plusJakartaSans(color: AppColors.dangerRed))))
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_result == null) return const SizedBox.shrink();
    final present = _result!.items.where((i) => i.status == 'present').length;
    final warning = _result!.items.where((i) => i.status == 'warning').length;
    final missing = _result!.items.where((i) => i.status == 'missing').length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,4))],
          ),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 52,
                lineWidth: 7,
                percent: _result!.checklistScore / 100,
                center: Text('${_result!.checklistScore}%',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w700)),
                progressColor: AppColors.gold,
                backgroundColor: AppColors.cardBorder,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_result!.documentType.toUpperCase(), style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                Text(_result!.summary, style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                const SizedBox(height: 8),
                Row(children: [
                  _StatusBadge(count: present, label: 'Present', color: AppColors.safeGreen),
                  const SizedBox(width: 6),
                  _StatusBadge(count: warning, label: 'Warn', color: AppColors.warningAmber),
                  const SizedBox(width: 6),
                  _StatusBadge(count: missing, label: 'Missing', color: AppColors.dangerRed),
                ]),
              ])),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 24),

        ...['missing', 'warning', 'present'].expand((status) {
          final items = _result!.items.where((i) => i.status == status).toList();
          if (items.isEmpty) return <Widget>[];
          return [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 3, height: 16,
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status == 'missing' ? 'MISSING CLAUSES'
                      : status == 'warning' ? 'WARNINGS' : 'PRESENT',
                  style: AppTextStyles.sectionTitle.copyWith(color: _statusColor(status)),
                ),
              ]),
            ),
            ...items.asMap().entries.map((entry) => _ChecklistItemCard(
              item: entry.value,
              statusColor: _statusColor(entry.value.status),
              statusIcon: _statusIcon(entry.value.status),
            ).animate().fadeIn(delay: Duration(milliseconds: 40 * entry.key))),
            const SizedBox(height: 16),
          ];
        }),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatusBadge({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text('$count $label', style: GoogleFonts.plusJakartaSans(
        color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _ChecklistItemCard extends StatefulWidget {
  final ChecklistItem item;
  final Color statusColor;
  final IconData statusIcon;
  const _ChecklistItemCard({required this.item, required this.statusColor, required this.statusIcon});

  @override
  State<_ChecklistItemCard> createState() => _ChecklistItemCardState();
}

class _ChecklistItemCardState extends State<_ChecklistItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.statusColor.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0,2))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(widget.statusIcon, color: widget.statusColor, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.item.item, style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted, size: 20),
            ]),
          ),
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 1, color: AppColors.cardBorder, margin: const EdgeInsets.only(bottom: 12)),
                Text(widget.item.explanation, style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                if (widget.item.action != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.gold, size: 12),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.item.action!, style: GoogleFonts.plusJakartaSans(
                          color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w500))),
                    ]),
                  ),
                ],
              ]),
            ),
        ]),
      ),
    );
  }
}