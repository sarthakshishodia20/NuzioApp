const axios = require('axios');
const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

const NEWSAPI_KEY = process.env.NEWS_API_KEY;
const NEWSAPI_BASE = 'https://newsapi.org/v2';

const CATEGORY_MAP = {
  technology: 'ai_technology',
  business: 'financial_markets',
  science: 'science',
  health: 'health_medicine',
  sports: 'sports',
  entertainment: 'culture_arts',
};

/**
 * Fetch articles from NewsAPI and upsert into the DB.
 * Falls back silently if no API key is configured.
 */
async function fetchAndStoreNews() {
  if (!NEWSAPI_KEY || NEWSAPI_KEY === 'your_newsapi_key_here') {
    console.log('ℹ️  NewsAPI key not set — using seeded mock articles only');
    return;
  }

  console.log('📰 Fetching live news from NewsAPI...');
  const categories = Object.keys(CATEGORY_MAP);

  for (const cat of categories) {
    try {
      const response = await axios.get(`${NEWSAPI_BASE}/top-headlines`, {
        params: {
          country: 'in',
          category: cat,
          pageSize: 10,
          apiKey: NEWSAPI_KEY,
        },
      });

      const articles = response.data.articles || [];
      const insert = db.prepare(`
        INSERT OR IGNORE INTO articles (id, title, summary, source, category, url, read_min, published_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `);

      const insertMany = db.transaction((items) => {
        for (const article of items) {
          if (!article.title || !article.description) continue;
          const readMin = Math.max(1, Math.ceil((article.content || '').split(' ').length / 200));
          insert.run(
            uuidv4(),
            article.title.replace(/\[.*?\]/g, '').trim(),
            article.description || article.content || '',
            article.source?.name || 'Unknown',
            CATEGORY_MAP[cat],
            article.url || '',
            readMin || 3,
            article.publishedAt || new Date().toISOString()
          );
        }
      });

      insertMany(articles);
      console.log(`  ✅ ${cat}: stored ${articles.length} articles`);
    } catch (err) {
      console.error(`  ❌ Failed to fetch ${cat}:`, err.message);
    }
  }
}

module.exports = { fetchAndStoreNews };
