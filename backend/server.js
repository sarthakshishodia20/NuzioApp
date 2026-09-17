require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { initSchema } = require('./src/db/schema');
const { fetchAndStoreNews } = require('./src/services/newsService');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({ origin: '*' }));
app.use(express.json());

// Initialize DB schema
initSchema();

// Routes
app.use('/api/auth', require('./src/routes/auth'));
app.use('/api/user', require('./src/routes/user'));
app.use('/api/news', require('./src/routes/news'));

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok', service: 'Nuzio API', time: new Date().toISOString() }));

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`\n🚀 Nuzio API running on http://localhost:${PORT}`);
  console.log(`📋 Endpoints:`);
  console.log(`   POST /api/auth/login`);
  console.log(`   GET  /api/auth/me`);
  console.log(`   PUT  /api/user/preferences`);
  console.log(`   GET  /api/news/feed`);
  console.log(`   GET  /api/news/search?q=query`);
  console.log(`   GET  /api/news/brief/today`);
  console.log(`   POST /api/news/save/:id`);
  console.log(`   GET  /api/news/saved\n`);

  // Optionally fetch live news on startup
  fetchAndStoreNews().catch(console.error);
});
