import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import 'voice_time_screen.dart';

class NichesScreen extends StatefulWidget {
  const NichesScreen({super.key});

  @override
  State<NichesScreen> createState() => _NichesScreenState();
}

class _NichesScreenState extends State<NichesScreen> {
  final Set<String> _selected = {};

  static const _niches = [
    ('🤖', 'AI & Technology'),
    ('📈', 'Financial Markets'),
    ('🇮🇳', 'Indian Business'),
    ('🌍', 'Global Politics'),
    ('🚀', 'Startups'),
    ('🔬', 'Science'),
    ('🗺️', 'Geopolitics'),
    ('💊', 'Health & Medicine'),
    ('🌿', 'Climate & Energy'),
    ('⚽', 'Sports'),
    ('🎭', 'Culture & Arts'),
    ('⚖️', 'Legal & Policy'),
  ];

  void _toggle(String niche) {
    setState(() {
      if (_selected.contains(niche)) {
        _selected.remove(niche);
      } else if (_selected.length < 7) {
        _selected.add(niche);
      }
    });
  }

  Future<void> _continue() async {
    await context.read<AuthProvider>().savePreferences({
      'niches': _selected.toList(),
    });
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const VoiceTimeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildTopBar(context),
                  const SizedBox(height: 12),
                  const _ProgressBar(step: 1, total: 3),
                  const SizedBox(height: 28),
                  Text('STEP 2 OF 3', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Text('What moves', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary))
                      .animate().fadeIn(duration: 400.ms),
                  Text('your world?', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primary, fontStyle: FontStyle.italic))
                      .animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Pick up to 7 niches.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.secondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text('${_selected.length}/7', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.secondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _niches.asMap().entries.map((e) {
                    final idx = e.key;
                    final (emoji, label) = e.value;
                    final isSelected = _selected.contains(label);
                    return _NicheChip(
                      emoji: emoji,
                      label: label,
                      selected: isSelected,
                      onTap: () => _toggle(label),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 200 + idx * 35))
                        .scale(begin: const Offset(0.85, 0.85));
                  }).toList(),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected.isEmpty ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected.isNotEmpty ? AppTheme.primary : AppTheme.surfaceLight,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Continue →',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _selected.isNotEmpty ? Colors.white : AppTheme.textMuted),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Row(children: List.generate(5, (i) {
          final h = [8.0, 14.0, 20.0, 14.0, 8.0];
          return Container(width: 2.5, height: h[i], margin: const EdgeInsets.symmetric(horizontal: 1.2),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2)));
        })),
        const SizedBox(width: 8),
        Text('Nuzio', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        Container(margin: const EdgeInsets.only(left: 3), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3)),
            child: Text('AI', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primary))),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const VoiceTimeScreen())),
          child: Text('SKIP →', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
        ),
      ],
    );
  }
}

class _NicheChip extends StatelessWidget {
  final String emoji, label;
  final bool selected;
  final VoidCallback onTap;

  const _NicheChip({required this.emoji, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.cardBorder, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? AppTheme.textPrimary : AppTheme.textSecondary)),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, size: 13, color: AppTheme.secondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step, total;
  const _ProgressBar({required this.step, required this.total});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) => Expanded(
        child: Container(
          height: 3, margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(color: i <= step ? AppTheme.secondary : AppTheme.surfaceLight, borderRadius: BorderRadius.circular(2)),
        ),
      )),
    );
  }
}
