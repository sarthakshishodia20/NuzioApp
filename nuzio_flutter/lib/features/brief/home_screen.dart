import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/article_model.dart';
import '../auth/auth_provider.dart';
import '../discover/discover_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/api_client.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  List<ArticleModel> _articles = [];
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;
  bool _isPlaying = false;
  int _selectedTab = 0; // 0 = Player/Brief, 1 = Discover, 2 = Settings
  double _playbackSpeed = 1.0;

  // Filter chips in player
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'AI & Tech', 'Markets', 'Startups', 'Science'];

  late AnimationController _waveController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 180),
    );

    _loadBrief();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadBrief() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/news/brief/today');
      final List rawArticles = res.data['articles'] ?? [];
      if (mounted) {
        setState(() {
          _articles = rawArticles.map((a) => ArticleModel.fromJson(a)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load your brief. Make sure the backend is running.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadFeed({String category = 'all'}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/news/feed', queryParams: {'category': category});
      final List rawArticles = res.data['articles'] ?? [];
      if (mounted) {
        setState(() {
          _articles = rawArticles.map((a) => ArticleModel.fromJson(a)).toList();
          _currentIndex = 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load feed.';
          _loading = false;
        });
      }
    }
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _waveController.repeat();
      _progressController.forward();
    } else {
      _waveController.stop();
      _progressController.stop();
    }
  }

  void _next() {
    if (_articles.isEmpty) return;
    if (_currentIndex < _articles.length - 1) {
      setState(() => _currentIndex++);
      _progressController.reset();
      if (_isPlaying) _progressController.forward();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _progressController.reset();
      if (_isPlaying) _progressController.forward();
    }
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.25;
      } else if (_playbackSpeed == 1.25) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
  }

  Future<void> _toggleSave(ArticleModel article) async {
    try {
      final res = await _api.post('/news/save/${article.id}');
      setState(() => article.isSaved = res.data['saved'] == true);
    } catch (_) {}
  }

  /// Called when user clicks "Play" on an article in Discover or Saved list
  void _playSpecificArticle(ArticleModel article) {
    setState(() {
      final existingIndex = _articles.indexWhere((a) => a.id == article.id);
      if (existingIndex != -1) {
        _currentIndex = existingIndex;
      } else {
        _articles.insert(0, article);
        _currentIndex = 0;
      }
      _selectedTab = 0; // switch to Player
      _isPlaying = true;
    });
    _progressController.reset();
    _progressController.forward();
    _waveController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Active Tab Content
            Positioned.fill(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  // Tab 0: Brief Player Screen
                  _buildPlayerTab(),
                  // Tab 1: Discover Screen with Search API
                  DiscoverScreen(onPlayArticle: _playSpecificArticle),
                  // Tab 2: Settings Screen with Saved & Billing
                  SettingsScreen(onPlayArticle: _playSpecificArticle),
                ],
              ),
            ),

            // Floating bottom navigation bar matching Figma
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTab() {
    final user = context.watch<AuthProvider>().user;

    return Column(
      children: [
        _buildTopBar(user?.name ?? 'Aarav'),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _error != null
                  ? _buildError()
                  : _articles.isEmpty
                      ? _buildEmpty()
                      : _buildBriefPlayerContent(),
        ),
      ],
    );
  }

  Widget _buildTopBar(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Row(
            children: List.generate(5, (i) {
              final h = [8.0, 14.0, 20.0, 14.0, 8.0];
              return Container(
                width: 3,
                height: h[i],
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            'Nuzio',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 3),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'AI',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 22),
            onPressed: () {
              setState(() => _selectedTab = 1); // Switch to Discover with search
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppTheme.textSecondary, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBriefPlayerContent() {
    final article = _articles[_currentIndex];
    final user = context.read<AuthProvider>().user;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Category chips
          _buildFilterChips(),
          const SizedBox(height: 16),

          // Date + Morning Brief Header matching Image 4 Screen 3
          Text(
            '${_dayOfWeek()}  •  MORNING BRIEF',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Good morning, ${user?.firstName ?? 'Aarav'} —\n${_articles.length} things.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'Audio live',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• Voice: ${user?.narratorVoice ?? 'Aria'}',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${_articles.length} stories',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Core Player Card matching Image 4 Screen 3
          _buildPlayerCard(article),

          const SizedBox(height: 18),

          // Mini Now narrating subtitle banner
          if (_isPlaying)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF131A1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic_none_rounded, color: AppTheme.secondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Now narrating — ${article.title}',
                      style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pause, color: Colors.black, size: 14),
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2500.ms, color: AppTheme.secondary.withValues(alpha: 0.15)),

          // Story list title
          Text(
            'STORIES IN THIS BRIEF',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Story list items
          ..._articles.asMap().entries.map((e) => _buildStoryListItem(e.key, e.value)),

          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final selected = _selectedFilter == i;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = i;
                _currentIndex = 0;
              });
              if (i == 0) {
                _loadBrief();
              } else {
                _loadFeed(category: _filters[i]);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? AppTheme.primary : AppTheme.cardBorder),
              ),
              child: Center(
                child: Text(
                  _filters[i],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard(ArticleModel article) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(article.id),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Now playing badge + counter
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'NOW PLAYING • ${article.categoryLabel.toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentIndex + 1} / ${_articles.length}',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Headline in Editorial Serif style
            Text(
              article.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 8),

            // Source + Read Time + Save Button
            Row(
              children: [
                Text(
                  article.source.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${article.readMin} MIN',
                  style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.textMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  '• SOURCE ↗',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _toggleSave(article),
                  child: Row(
                    children: [
                      Icon(
                        article.isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: article.isSaved ? AppTheme.primary : AppTheme.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.isSaved ? 'SAVED' : 'SAVE',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: article.isSaved ? AppTheme.primary : AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Summary
            Text(
              article.summary,
              style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 18),

            // Waveform visualizer
            _AnimatedWaveform(controller: _waveController, isPlaying: _isPlaying),

            const SizedBox(height: 8),

            // Progress time labels
            AnimatedBuilder(
              animation: _progressController,
              builder: (_, __) {
                final total = article.readMin * 60;
                final elapsed = (_progressController.value * total).round();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(elapsed),
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    Text(
                      '-${_formatTime(total - elapsed)}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),

            // Playback controls matching Figma
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prev,
                  icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.textSecondary, size: 28),
                ),
                GestureDetector(
                  onTap: _togglePlay,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.5),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _next,
                  icon: const Icon(Icons.skip_next_rounded, color: AppTheme.textSecondary, size: 28),
                ),
                GestureDetector(
                  onTap: _cycleSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_playbackSpeed == 1.0 ? '1' : _playbackSpeed}x',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryListItem(int index, ArticleModel article) {
    final isActive = index == _currentIndex;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        _progressController.reset();
        if (_isPlaying) _progressController.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : AppTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          article.categoryLabel.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        article.source,
                        style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    article.title,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isActive && _isPlaying)
              _MiniWaveform(controller: _waveController)
            else
              const Icon(Icons.play_arrow_rounded, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Discover
          _NavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: 'DISCOVER',
            selected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),

          // Center Quick Play / Player Toggle
          GestureDetector(
            onTap: () {
              if (_selectedTab != 0) {
                setState(() => _selectedTab = 0);
              } else {
                _togglePlay();
              }
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                _selectedTab == 0 && _isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          // Settings
          _NavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'SETTINGS',
            selected: _selectedTab == 2,
            onTap: () => setState(() => _selectedTab = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadBrief, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text('No stories found.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
    );
  }

  String _dayOfWeek() {
    final days = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];
    return '${days[DateTime.now().weekday % 7]}  ${DateTime.now().day} ${_monthName()}';
  }

  String _monthName() {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[DateTime.now().month - 1];
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// Waveform visualizer
class _AnimatedWaveform extends StatelessWidget {
  final AnimationController controller;
  final bool isPlaying;

  const _AnimatedWaveform({required this.controller, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(28, (i) {
              double h;
              if (isPlaying) {
                final phase = (i / 28) * 2 * math.pi;
                h = 6 + 26 * ((math.sin(controller.value * 2 * math.pi + phase) + 1) / 2);
              } else {
                h = 4 + (i % 4) * 3.0;
              }
              return AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 3.5,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppTheme.primary.withValues(alpha: 0.6 + 0.4 * (h / 32))
                      : AppTheme.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _MiniWaveform extends StatelessWidget {
  final AnimationController controller;
  const _MiniWaveform({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Row(
        children: List.generate(4, (i) {
          final phase = i * math.pi / 2;
          final h = 6.0 + 10 * ((math.sin(controller.value * 2 * math.pi + phase) + 1) / 2);
          return Container(
            width: 2.5,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? AppTheme.secondary : AppTheme.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.secondary : AppTheme.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: selected ? 18 : 0,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
