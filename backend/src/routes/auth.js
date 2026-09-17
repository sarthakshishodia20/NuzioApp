const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');

/**
 * POST /api/auth/login
 * Email-based JWT login — no password required for assessment.
 * Accepts { name, email } → creates or finds user → returns JWT.
 */
router.post('/login', (req, res) => {
  const { name, email } = req.body;
  if (!email) return res.status(400).json({ error: 'email is required' });

  const safeName = name && name.trim() ? name.trim() : email.split('@')[0];

  let user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  if (!user) {
    const id = uuidv4();
    db.prepare(`
      INSERT INTO users (id, name, email)
      VALUES (?, ?, ?)
    `).run(id, safeName, email);
    user = db.prepare('SELECT * FROM users WHERE id = ?').get(id);
  }

  const token = jwt.sign(
    { id: user.id, email: user.email, name: user.name },
    process.env.JWT_SECRET,
    { expiresIn: '30d' }
  );

  const niches = JSON.parse(user.niches || '[]');
  res.json({
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      language: user.language,
      profession: user.profession,
      niches,
      brief_time: user.brief_time,
      narrator_voice: user.narrator_voice,
      brief_length: user.brief_length,
      onboarding_done: !!(user.profession && niches.length > 0),
    },
  });
});

/**
 * GET /api/auth/me
 */
router.get('/me', require('../middleware/auth'), (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
  if (!user) return res.status(404).json({ error: 'User not found' });
  const niches = JSON.parse(user.niches || '[]');
  res.json({
    id: user.id,
    name: user.name,
    email: user.email,
    language: user.language,
    profession: user.profession,
    niches,
    brief_time: user.brief_time,
    narrator_voice: user.narrator_voice,
    brief_length: user.brief_length,
    onboarding_done: !!(user.profession && niches.length > 0),
  });
});

module.exports = router;
