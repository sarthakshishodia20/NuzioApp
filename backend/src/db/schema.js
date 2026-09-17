const db = require('../config/db');

function initSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      google_id TEXT,
      language TEXT DEFAULT 'en',
      profession TEXT DEFAULT '',
      niches TEXT DEFAULT '[]',
      brief_time TEXT DEFAULT '07:00',
      narrator_voice TEXT DEFAULT 'Aria',
      brief_length INTEGER DEFAULT 5,
      created_at TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS articles (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      summary TEXT NOT NULL,
      source TEXT NOT NULL,
      category TEXT NOT NULL,
      url TEXT NOT NULL,
      read_min INTEGER DEFAULT 3,
      published_at TEXT DEFAULT (datetime('now')),
      created_at TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS saved_articles (
      user_id TEXT NOT NULL,
      article_id TEXT NOT NULL,
      saved_at TEXT DEFAULT (datetime('now')),
      PRIMARY KEY (user_id, article_id),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_articles_category ON articles(category);
    CREATE INDEX IF NOT EXISTS idx_articles_published ON articles(published_at DESC);
  `);

  console.log('✅ Database schema initialized');
}

module.exports = { initSchema };
