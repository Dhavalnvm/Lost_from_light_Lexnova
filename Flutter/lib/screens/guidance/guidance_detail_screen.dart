import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common/common_widgets.dart';

class GuidanceDetailScreen extends StatefulWidget {
  final String category;
  final String label;

  const GuidanceDetailScreen({
    super.key,
    required this.category,
    required this.label,
  });

  @override
  State<GuidanceDetailScreen> createState() => _GuidanceDetailScreenState();
}

class _GuidanceDetailScreenState extends State<GuidanceDetailScreen> {
  final _api = ApiService();
  GuidanceResponse? _guidance;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGuidance();
  }

  Future<void> _loadGuidance() async {
    try {
      final data = await _api.getRequiredDocuments(widget.category);
      setState(() {
        _guidance = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(widget.label,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Failed to Load',
                subtitle: _error!,
              ),
            )
          else if (_guidance != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Overview
                  GlassCard(
                    borderColor: AppColors.gold.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overview',
                            style: AppTextStyles.sectionTitle),
                        const SizedBox(height: 10),
                        Text(
                          _guidance!.overview,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.7),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 20),

                  Text(
                    'REQUIRED DOCUMENTS',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 12),

                  ..._guidance!.requiredDocuments.asMap().entries.map(
                        (e) => _DocumentCard(
                          doc: e.value,
                          index: e.key,
                        ),
                      ),

                  if (_guidance!.generalTips.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    GlassCard(
                      borderColor: AppColors.infoBlue.withOpacity(0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tips_and_updates_rounded,
                                  color: AppColors.infoBlue, size: 18),
                              const SizedBox(width: 8),
                              Text('PRO TIPS',
                                  style: AppTextStyles.sectionTitle),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._guidance!.generalTips.map((tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.arrow_right_rounded,
                                        color: AppColors.infoBlue, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tip,
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
                      ),
                    ).animate(delay: 300.ms).fadeIn(),
                  ],
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatefulWidget {
  final RequiredDocumentItem doc;
  final int index;

  const _DocumentCard({required this.doc, required this.index});

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  bool _showSteps = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        color: AppColors.background,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.doc.documentName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.doc.validity != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.goldGlow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.doc.validity!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),
            Text(
              widget.doc.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.doc.whereToObtain,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),

            if (widget.doc.notes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.warningAmber.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.warningAmber, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.doc.notes!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (widget.doc.steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              const GoldDivider(),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _showSteps = !_showSteps),
                child: Row(
                  children: [
                    const Icon(Icons.route_rounded,
                        color: AppColors.gold, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _showSteps ? 'Hide Steps' : 'How to Get It',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showSteps
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ],
                ),
              ),
              if (_showSteps) ...[
                const SizedBox(height: 12),
                ...widget.doc.steps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.goldGlow,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.goldDark, width: 1),
                            ),
                            child: Center(
                              child: Text(
                                '${step.stepNumber}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(step.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(step.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 12, height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}
