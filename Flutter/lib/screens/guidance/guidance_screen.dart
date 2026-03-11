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
      'color': Color(0xFF3B82F6),
    },
    {
      'id': 'loan',
      'label': 'Loans & Finance',
      'icon': Icons.account_balance_rounded,
      'subtitle': 'Home, personal, car loans',
      'color': Color(0xFF10B981),
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
      'color': Color(0xFFEC4899),
    },
    {
      'id': 'education',
      'label': 'Education',
      'icon': Icons.school_rounded,
      'subtitle': 'Admissions, scholarships',
      'color': Color(0xFF8B5CF6),
    },
    {
      'id': 'insurance',
      'label': 'Insurance',
      'icon': Icons.shield_rounded,
      'subtitle': 'Health, life, property',
      'color': Color(0xFFF59E0B),
    },
    {
      'id': 'digital',
      'label': 'Digital Agreements',
      'icon': Icons.devices_rounded,
      'subtitle': 'T&C, Privacy, EULA',
      'color': Color(0xFF06B6D4),
    },
    {
      'id': 'personal',
      'label': 'Personal Legal',
      'icon': Icons.person_rounded,
      'subtitle': 'Wills, POA, affidavits',
      'color': Color(0xFFEF4444),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Guide',
                    style: AppTextStyles.goldTitle.copyWith(fontSize: 22),
                  ),
                  Text(
                    'What do you need today?',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.12),
              AppColors.cardBg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}
