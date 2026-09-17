const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

// Niche key → article category mapping
const NICHE_TO_CATEGORY = {
  'AI & Technology': 'ai_technology',
  'Financial Markets': 'financial_markets',
  'Indian Business': 'indian_business',
  'Global Politics': 'global_politics',
  'Startups': 'startups',
  'Science': 'science',
  'Geopolitics': 'global_politics',
  'Health & Medicine': 'health_medicine',
  'Climate & Energy': 'climate_energy',
  'Sports': 'sports',
  'Culture & Arts': 'culture_arts',
  'Legal & Policy': 'global_politics',
};

/**
 * GET /api/news/feed?category=all&limit=20&offset=0
 * Returns personalised news feed based on user niches.
 */
router.get('/feed', auth, (req, res) => {
  const { category = 'all', limit = 20, offset = 0 } = req.query;

  const user = db.prepare('SELECT niches FROM users WHERE id = ?').get(req.user.id);
  const userNiches = JSON.parse(user?.niches || '[]');

  let articles;

  if (category !== 'all') {
    // Filter by specific category
    const dbCategory = NICHE_TO_CATEGORY[category] || category;
    articles = db.prepare(`
      SELECT a.*, 
        CASE WHEN s.article_id IS NOT NULL THEN 1 ELSE 0 END as is_saved
      FROM articles a
      LEFT JOIN saved_articles s ON s.article_id = a.id AND s.user_id = ?
      WHERE a.category = ?
      ORDER BY a.published_at DESC
      LIMIT ? OFFSET ?
    `).all(req.user.id, dbCategory, parseInt(limit), parseInt(offset));
  } else if (userNiches.length > 0) {
    // Get articles matching user niches
    const cats = userNiches.map(n => NICHE_TO_CATEGORY[n] || n).filter(Boolean);
    const placeholders = cats.map(() => '?').join(',');
    articles = db.prepare(`
      SELECT a.*, 
        CASE WHEN s.article_id IS NOT NULL THEN 1 ELSE 0 END as is_saved
      FROM articles a
      LEFT JOIN saved_articles s ON s.article_id = a.id AND s.user_id = ?
      WHERE a.category IN (${placeholders})
      ORDER BY a.published_at DESC
      LIMIT ? OFFSET ?
    `).all(req.user.id, ...cats, parseInt(limit), parseInt(offset));
  } else {
    // No preferences yet — return all recent
    articles = db.prepare(`
      SELECT a.*, 
        CASE WHEN s.article_id IS NOT NULL THEN 1 ELSE 0 END as is_saved
      FROM articles a
      LEFT JOIN saved_articles s ON s.article_id = a.id AND s.user_id = ?
      ORDER BY a.published_at DESC
      LIMIT ? OFFSET ?
    `).all(req.user.id, parseInt(limit), parseInt(offset));
  }

  res.json({ articles, total: articles.length });
});

/**
 * GET /api/news/brief/today
 * Returns today's morning brief — top articles based on user niches.
 * Limits to `brief_length` articles (5 min = 5 articles, etc.)
 */
router.get('/brief/today', auth, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
  if (!user) return res.status(404).json({ error: 'User not found' });

  const userNiches = JSON.parse(user.niches || '[]');
  const briefLength = user.brief_length || 5;

  let articles;
  if (userNiches.length > 0) {
    const cats = userNiches.map(n => NICHE_TO_CATEGORY[n] || n).filter(Boolean);
    const placeholders = cats.map(() => '?').join(',');
    // Pick 1-2 articles per category to diversify the brief
    articles = db.prepare(`
      SELECT a.*,
        CASE WHEN s.article_id IS NOT NULL THEN 1 ELSE 0 END as is_saved
      FROM articles a
      LEFT JOIN saved_articles s ON s.article_id = a.id AND s.user_id = ?
      WHERE a.category IN (${placeholders})
      ORDER BY a.published_at DESC
      LIMIT ?
    `).all(user.id, ...cats, briefLength);
  } else {
    articles = db.prepare(`
      SELECT a.*,
        CASE WHEN s.article_id IS NOT NULL THEN 1 ELSE 0 END as is_saved
      FROM articles a
      LEFT JOIN saved_articles s ON s.article_id = a.id AND s.user_id = ?
      ORDER BY a.published_at DESC
      LIMIT ?
    `).all(user.id, briefLength);
  }

  const totalReadMin = articles.reduce((sum, a) => sum + (a.read_min || 3), 0);

  res.json({
    date: new Date().toISOString().split('T')[0],
    user_name: user.name.split(' ')[0],
    narrator_voice: user.narrator_voice,
    brief_time: user.brief_time,
    total_stories: articles.length,
    total_read_min: totalReadMin,
    niches_covered: [...new Set(articles.map(a => a.category))],
    articles,
  });
});

/**
 * POST /api/news/save/:id
 * Toggle save/unsave an article
 */
router.post('/save/:id', auth, (req, res) => {
  const { id } = req.params;

  const existing = db.prepare(
    'SELECT * FROM saved_articles WHERE user_id = ? AND article_id = ?'
  ).get(req.user.id, id);

  if (existing) {
    db.prepare('DELETE FROM saved_articles WHERE user_id = ? AND article_id = ?').run(req.user.id, id);
    res.json({ saved: false, message: 'Article unsaved' });
  } else {
    db.prepare('INSERT INTO saved_articles (user_id, article_id) VALUES (?, ?)').run(req.user.id, id);
    res.json({ saved: true, message: 'Article saved' });
  }
});

/**
 * GET /api/news/saved
 * List all saved articles for the user
 */
router.get('/saved', auth, (req, res) => {
  const articles = db.prepare(`
    SELECT a.*, 1 as is_saved
    FROM articles a
    JOIN saved_articles s ON s.article_id = a.id
    WHERE s.user_id = ?
    ORDER BY s.saved_at DESC
  `).all(req.user.id);

  res.json({ articles, total: articles.length });
});

/**
 * GET /api/news/search?q=query&limit=20
 * Full-text search across title, summary, source, category
 */
router.get('/search', auth, (req, res) => {
  const { q = '', limit = 20 } = req.query;
  if (!q.trim()) return res.json({ articles: [], total: 0, query: q });

  const term = `%${q.trim()}%`;
  const articles = db.prepare(`
    SELECT a.*,
      CASE WHEN s.article_id IS NOT NULL THEN 1 ELSE 0 END as is_saved
    FROM articles a
    LEFT JOIN saved_articles s ON s.article_id = a.id AND s.user_id = ?
    WHERE a.title LIKE ? OR a.summary LIKE ? OR a.source LIKE ? OR a.category LIKE ?
    ORDER BY a.published_at DESC
    LIMIT ?
  `).all(req.user.id, term, term, term, term, parseInt(limit));

  res.json({ articles, total: articles.length, query: q });
});

module.exports = router;
