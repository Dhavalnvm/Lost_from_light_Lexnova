import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'analyzer/document_analyzer_screen.dart';
import 'guidance/guidance_screen.dart';
import 'chatbot/chatbot_screen.dart';
import 'features/tools_hub_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DocumentAnalyzerScreen(),
    GuidanceScreen(),
    ChatbotScreen(),
    ToolsHubScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.description_outlined, activeIcon: Icons.description_rounded,
                  label: 'Analyzer', isActive: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
              _NavItem(icon: Icons.folder_outlined, activeIcon: Icons.folder_rounded,
                  label: 'Guidance', isActive: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
              _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded,
                  label: 'AI Lawyer', isActive: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
              _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded,
                  label: 'Tools', isActive: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
              _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
                  label: 'Profile', isActive: _currentIndex == 4, onTap: () => setState(() => _currentIndex = 4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label,
    required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.goldGlow : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isActive ? Border.all(color: AppColors.goldDark.withOpacity(0.5), width: 1) : null,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(isActive ? activeIcon : icon,
            color: isActive ? AppColors.gold : AppColors.textMuted, size: 21),
        const SizedBox(height: 3),
        Text(label, style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.gold : AppColors.textMuted)),
      ]),
    ),
  );
}