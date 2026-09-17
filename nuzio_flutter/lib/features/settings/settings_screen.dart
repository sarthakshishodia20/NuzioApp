import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/article_model.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../onboarding/profession_screen.dart';
import 'plan_billing_screen.dart';
import '../../core/api_client.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ArticleModel)? onPlayArticle;

  const SettingsScreen({super.key, this.onPlayArticle});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiClient _api = ApiClient();
  bool _isDark = true;
  bool _offlineMode = false;
  bool _autoAdvance = true;
  bool _pushNotifications = true;
  int _savedCount = 0;
  List<ArticleModel> _savedArticles = [];

  @override
  void initState() {
    super.initState();
    _loadSavedArticles();
  }

  Future<void> _loadSavedArticles() async {
    try {
      final res = await _api.get('/news/saved');
      final List raw = res.data['articles'] ?? [];
      if (mounted) {
        setState(() {
          _savedArticles = raw.map((a) => ArticleModel.fromJson(a)).toList();
          _savedCount = _savedArticles.length;
        });
      }
    } catch (_) {}
  }

  void _showSavedStoriesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Saved Stories',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_savedCount',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _savedArticles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bookmark_border, size: 48, color: AppTheme.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  'No saved stories yet',
                                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bookmark stories in Discover or Player to read later.',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: _savedArticles.length,
                            itemBuilder: (_, i) {
                              final art = _savedArticles[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            art.title,
                                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text('${art.source} • ${art.readMin} min', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_fill, color: AppTheme.secondary, size: 30),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        widget.onPlayArticle?.call(art);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editProfile() {
    final user = context.read<AuthProvider>().user;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final profCtrl = TextEditingController(text: user?.profession ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Profile', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 18),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: GoogleFonts.inter(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: profCtrl,
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Profession',
                  labelStyle: GoogleFonts.inter(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().savePreferences({
                      'name': nameCtrl.text.trim(),
                      'profession': profCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          _buildTopBar(),

          const SizedBox(height: 12),
          Text(
            'Settings',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppTheme.textPrimary,
            ),
          ).animate().fadeIn(duration: 300.ms),
          Text(
            'Tune your morning.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 20),

          // User Profile Card matching Image 5 Screen 2
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Aarav Sharma',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${user?.profession.isNotEmpty == true ? user!.profession : 'Technology'} • Mumbai, India',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _editProfile,
                  child: Text(
                    'Edit ›',
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 14),

          // Action Card 1: Saved stories
          _buildActionTile(
            icon: Icons.bookmark_added_rounded,
            iconBg: const Color(0xFF381A1A),
            iconColor: const Color(0xFFFF6B6B),
            title: 'Saved stories',
            subtitle: '$_savedCount saved',
            trailing: '›',
            onTap: _showSavedStoriesSheet,
          ),

          const SizedBox(height: 10),

          // Action Card 2: Plan & billing
          _buildActionTile(
            icon: Icons.credit_card_rounded,
            iconBg: const Color(0xFF382E14),
            iconColor: const Color(0xFFFFC107),
            title: 'Plan & billing',
            subtitle: 'Free — upgrade for unlimited',
            trailing: 'Free ›',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlanBillingScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          // APPEARANCE SECTION
          Text(
            'APPEARANCE',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),

          // Dark / Light Toggle Pills
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isDark = true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isDark ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🌙 ', style: TextStyle(fontSize: 14)),
                          Text(
                            'Dark',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isDark ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isDark = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: !_isDark ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('☀️ ', style: TextStyle(fontSize: 14)),
                          Text(
                            'Light',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: !_isDark ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Settings Toggles Container
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              children: [
                _buildSwitchRow(
                  icon: Icons.download_for_offline_outlined,
                  title: 'Offline mode',
                  subtitle: 'Download briefs for the commute',
                  value: _offlineMode,
                  onChanged: (v) => setState(() => _offlineMode = v),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder, indent: 56),
                _buildSwitchRow(
                  icon: Icons.skip_next_rounded,
                  title: 'Auto-advance',
                  subtitle: 'Play the next story automatically',
                  value: _autoAdvance,
                  onChanged: (v) => setState(() => _autoAdvance = v),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder, indent: 56),
                _buildSwitchRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Push notifications',
                  subtitle: 'Brief drops & breaking news',
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // PREFERENCES & ACCOUNT
          Text(
            'PREFERENCES & ACCOUNT',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 22),
                  title: Text('Update Profession & Niches', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionScreen()));
                  },
                ),
                const Divider(height: 1, color: AppTheme.cardBorder, indent: 56),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                  title: Text('Log Out', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Row(
            children: List.generate(5, (i) {
              final h = [8.0, 14.0, 20.0, 14.0, 8.0];
              return Container(
                width: 3,
                height: h[i],
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2)),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text('Nuzio', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          Container(
            margin: const EdgeInsets.only(left: 3),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3)),
            child: Text('AI', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primary)),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppTheme.textSecondary, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Text(trailing, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.secondary,
            activeThumbColor: Colors.black,
            inactiveTrackColor: AppTheme.surfaceLight,
            inactiveThumbColor: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }
}
