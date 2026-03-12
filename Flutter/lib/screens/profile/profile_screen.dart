import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  UserProfile?              _profile;
  List<DocumentHistoryItem> _docs    = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Single source of truth — check AuthService
    if (!AuthService().isLoggedIn) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (mounted) setState(() { _loading = true; _error = null; });

    try {
      final results = await Future.wait([
        ApiService().getMe(),
        ApiService().getMyDocuments(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as UserProfile;
          _docs    = results[1] as List<DocumentHistoryItem>;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      // 401 means the token expired server-side — log out and redirect
      if (e.statusCode == 401) {
        await AuthService().logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false);
        }
        return;
      }
      if (mounted) {
        setState(() {
          _error   = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error   = e.toString().replaceAll(RegExp(r'ApiException\(\d+\): '), '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService().isLoggedIn) return _NotLoggedIn();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.gold))
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.dangerRed, size: 48),
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(
                      color: AppColors.dangerRed, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient:     AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Retry',
                      style: GoogleFonts.dmSans(
                          color:      Colors.black,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        )
            : RefreshIndicator(
          onRefresh: _load,
          color:     AppColors.gold,
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildStats()),
            if (_docs.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text('DOCUMENT HISTORY',
                      style: AppTextStyles.sectionTitle),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _DocHistoryCard(doc: _docs[i])
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 50 * i)),
                    childCount: _docs.length,
                  ),
                ),
              ),
            ],
            if (_docs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(children: [
                      const Icon(Icons.folder_open_rounded,
                          color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text('No documents yet',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textMuted,
                              fontSize: 16)),
                      const SizedBox(height: 6),
                      const Text(
                          'Upload a document in the Analyzer tab',
                          style: TextStyle(
                              color:    AppColors.textMuted,
                              fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_profile == null) return const SizedBox.shrink();
    return Container(
      margin:  const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:     AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
              gradient: AppColors.goldGradient, shape: BoxShape.circle),
          child: Center(
            child: Text(
              _profile!.name.isNotEmpty
                  ? _profile!.name[0].toUpperCase() : 'U',
              style: GoogleFonts.cormorantGaramond(
                  color: Colors.black, fontSize: 26, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_profile!.name,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(_profile!.email,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
          tooltip: 'Sign out',
        ),
      ]),
    ).animate().fadeIn();
  }

  Widget _buildStats() {
    if (_profile == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        Expanded(child: _StatCard(
            label: 'Documents Analyzed',
            value: '${_docs.length}',
            icon:  Icons.description_rounded,
            color: AppColors.gold)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
            label: 'Member Since',
            value: _profile!.createdAt.isNotEmpty
                ? _profile!.createdAt.substring(0, 10) : 'Today',
            icon:  Icons.calendar_today_rounded,
            color: AppColors.infoBlue)),
      ]),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color  color;
  const _StatCard(
      {required this.label, required this.value,
        required this.icon,  required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 10),
      Text(value,
          style: GoogleFonts.cormorantGaramond(
              color: color, fontSize: 22, fontWeight: FontWeight.w700)),
      Text(label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
    ]),
  );
}

class _DocHistoryCard extends StatelessWidget {
  final DocumentHistoryItem doc;
  const _DocHistoryCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final safetyScore = doc.analysis['safety_score'] as int?;
    final riskLevel   = doc.analysis['risk_level']   as String?;
    final color = riskLevel == 'High'   ? AppColors.dangerRed
        : riskLevel == 'Medium' ? AppColors.warningAmber
        :                         AppColors.safeGreen;

    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.description_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc.filename,
                style: GoogleFonts.dmSans(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
                doc.uploadedAt.isNotEmpty
                    ? doc.uploadedAt.substring(0, 10) : '',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ]),
        ),
        if (safetyScore != null) ...[
          const SizedBox(width: 10),
          Column(children: [
            Text('$safetyScore',
                style: GoogleFonts.cormorantGaramond(
                    color:      color,
                    fontSize:   20,
                    fontWeight: FontWeight.w700)),
            const Text('/ 100',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ]),
        ],
      ]),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: AppColors.goldGlow, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline_rounded,
                color: AppColors.gold, size: 40),
          ),
          const SizedBox(height: 24),
          Text('Your Profile', style: AppTextStyles.goldTitle),
          const SizedBox(height: 8),
          const Text(
              'Sign in to track your documents\nand access your analysis history',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient:     AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(14)),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor:     Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: Text('Sign In',
                    style: GoogleFonts.dmSans(
                        color:      Colors.black,
                        fontSize:   16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}