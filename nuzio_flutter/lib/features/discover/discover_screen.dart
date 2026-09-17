import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/article_model.dart';
import '../../core/api_client.dart';

class DiscoverScreen extends StatefulWidget {
  final Function(ArticleModel) onPlayArticle;

  const DiscoverScreen({super.key, required this.onPlayArticle});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;

  List<ArticleModel> _articles = [];
  bool _loading = false;
  String? _error;
  String _activeSearchQuery = '';

  int _selectedFilter = 0;
  final List<String> _filters = [
    'All',
    'AI & Tech',
    'Markets',
    'Startups',
    'Science',
    'Global'
  ];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFeed({String category = 'all'}) async {
    setState(() {
      _loading = true;
      _error = null;
      _activeSearchQuery = '';
    });
    try {
      final res = await _api.get(
        '/news/feed',
        queryParams: {'category': category, 'limit': 25},
      );
      final List raw = res.data['articles'] ?? [];
      if (mounted) {
        setState(() {
          _articles = raw.map((a) => ArticleModel.fromJson(a)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load news. Check server connection.';
          _loading = false;
        });
      }
    }
  }

  /// Live Search API call directly to backend `/api/news/search?q=query`
  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      _loadFeed(
        category: _selectedFilter == 0 ? 'all' : _filters[_selectedFilter],
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _activeSearchQuery = cleanQuery;
    });

    try {
      final res = await _api.get(
        '/news/search',
        queryParams: {'q': cleanQuery, 'limit': 30},
      );
      final List raw = res.data['articles'] ?? [];
      if (mounted) {
        setState(() {
          _articles = raw.map((a) => ArticleModel.fromJson(a)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Search failed: $e';
          _loading = false;
        });
      }
    }
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(text);
    });
  }

  Future<void> _toggleSave(ArticleModel article) async {
    try {
      final res = await _api.post('/news/save/${article.id}');
      final saved = res.data['saved'] == true;
      setState(() {
        article.isSaved = saved;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved ? 'Article saved to your library' : 'Article removed',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: AppTheme.surface,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header matching Image 5 Screen 1
        _buildTopHeader(),

        // Search Bar with actual API trigger
        _buildSearchBar(),

        const SizedBox(height: 12),

        // Filter chips
        _buildFilterChips(),

        const SizedBox(height: 12),

        // Active search status bar
        if (_activeSearchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Search results for "$_activeSearchQuery"',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    _performSearch('');
                  },
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // News List
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : _error != null
                  ? _buildErrorView()
                  : _articles.isEmpty
                      ? _buildEmptyView()
                      : RefreshIndicator(
                          onRefresh: () => _activeSearchQuery.isEmpty
                              ? _loadFeed(
                                  category: _selectedFilter == 0
                                      ? 'all'
                                      : _filters[_selectedFilter],
                                )
                              : _performSearch(_activeSearchQuery),
                          color: AppTheme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _articles.length + 1,
                            itemBuilder: (ctx, idx) {
                              if (idx == _articles.length) {
                                return const SizedBox(height: 80);
                              }
                              return _buildArticleCard(_articles[idx], idx);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
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
                icon: const Icon(Icons.notifications_none,
                    color: AppTheme.textSecondary, size: 22),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Discover',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppTheme.textPrimary,
            ),
          ).animate().fadeIn(duration: 300.ms),
          Text(
            'Inshorts-style — swipe the world.',
            style:
                GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          onSubmitted: _performSearch,
          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search stories, sources, topics...',
            hintStyle:
                GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
            prefixIcon: IconButton(
              icon: const Icon(Icons.search_rounded,
                  color: AppTheme.textSecondary, size: 20),
              onPressed: () => _performSearch(_searchCtrl.text),
            ),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textMuted, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _performSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final selected = _selectedFilter == i && _activeSearchQuery.isEmpty;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = i;
                _searchCtrl.clear();
              });
              if (i == 0) {
                _loadFeed();
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
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.cardBorder,
                ),
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

  Widget _buildArticleCard(ArticleModel article, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges: Category + Source
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  article.categoryLabel.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      article.source,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_outward_rounded,
                        size: 10, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Title
          Text(
            article.title,
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          // Summary
          Text(
            article.summary,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Bottom read time + save + Play button
          Row(
            children: [
              Text(
                '${article.readMin} MIN READ',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  article.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: article.isSaved
                      ? AppTheme.primary
                      : AppTheme.textMuted,
                  size: 20,
                ),
                onPressed: () => _toggleSave(article),
              ),
              const SizedBox(width: 6),
              // Play button (green circle with play icon)
              GestureDetector(
                onTap: () => widget.onPlayArticle(article),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.black, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            _activeSearchQuery.isNotEmpty
                ? 'No stories found for "$_activeSearchQuery"'
                : 'No stories available.',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppTheme.textSecondary),
          ),
          if (_activeSearchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _searchCtrl.clear();
                _loadFeed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceLight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Clear Search',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 40, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadFeed(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
