import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common/common_widgets.dart';
import 'guidance_detail_screen.dart';

class GuidanceScreen extends StatelessWidget {
  const GuidanceScreen({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {
      'id': 'housing',
      'label': 'Housing & Property',
      'icon': Icons.home_rounded,
      'subtitle': 'Rent, buy, lease property',
      'color': Color(0xFF2563EB),
    },
    {
      'id': 'loan',
      'label': 'Loans & Finance',
      'icon': Icons.account_balance_rounded,
      'subtitle': 'Home, personal, car loans',
      'color': Color(0xFF059669),
    },
    {
      'id': 'employment',
      'label': 'Employment',
      'icon': Icons.work_rounded,
      'subtitle': 'Jobs, NDAs, contracts',
      'color': AppColors.gold,
    },
    {
      'id': 'business',
      'label': 'Business',
      'icon': Icons.business_center_rounded,
      'subtitle': 'GST, partnerships, vendors',
      'color': Color(0xFFDB2777),
    },
    {
      'id': 'education',
      'label': 'Education',
      'icon': Icons.school_rounded,
      'subtitle': 'Admissions, scholarships',
      'color': Color(0xFF7C3AED),
    },
    {
      'id': 'insurance',
      'label': 'Insurance',
      'icon': Icons.shield_rounded,
      'subtitle': 'Health, life, property',
      'color': Color(0xFFD97706),
    },
    {
      'id': 'digital',
      'label': 'Digital Agreements',
      'icon': Icons.devices_rounded,
      'subtitle': 'T&C, Privacy, EULA',
      'color': Color(0xFF0891B2),
    },
    {
      'id': 'personal',
      'label': 'Personal Legal',
      'icon': Icons.person_rounded,
      'subtitle': 'Wills, POA, affidavits',
      'color': Color(0xFFDC2626),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.cardBorder),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              background: Container(color: AppColors.surface),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Guide',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'What do you need today?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                  final cat = _categories[i];
                  return _CategoryCard(
                    id: cat['id'],
                    label: cat['label'],
                    icon: cat['icon'],
                    subtitle: cat['subtitle'],
                    color: cat['color'],
                    delay: i * 60,
                  );
                },
                childCount: _categories.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final String subtitle;
  final Color color;
  final int delay;

  const _CategoryCard({
    required this.id,
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuidanceDetailScreen(category: id, label: label),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.15, end: 0);
  }
}