const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

/**
 * PUT /api/user/preferences
 * Save onboarding preferences: profession, niches, language, brief_time, narrator_voice, brief_length
 */
router.put('/preferences', auth, (req, res) => {
  const { language, profession, niches, brief_time, narrator_voice, brief_length } = req.body;

  const fields = [];
  const values = [];

  if (language !== undefined) { fields.push('language = ?'); values.push(language); }
  if (profession !== undefined) { fields.push('profession = ?'); values.push(profession); }
  if (niches !== undefined) { fields.push('niches = ?'); values.push(JSON.stringify(niches)); }
  if (brief_time !== undefined) { fields.push('brief_time = ?'); values.push(brief_time); }
  if (narrator_voice !== undefined) { fields.push('narrator_voice = ?'); values.push(narrator_voice); }
  if (brief_length !== undefined) { fields.push('brief_length = ?'); values.push(brief_length); }

  if (fields.length === 0) {
    return res.status(400).json({ error: 'No fields to update' });
  }

  values.push(req.user.id);
  db.prepare(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`).run(...values);

  const updated = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
  res.json({
    id: updated.id,
    name: updated.name,
    email: updated.email,
    language: updated.language,
    profession: updated.profession,
    niches: JSON.parse(updated.niches || '[]'),
    brief_time: updated.brief_time,
    narrator_voice: updated.narrator_voice,
    brief_length: updated.brief_length,
  });
});

/**
 * GET /api/user/preferences
 * Get current user preferences
 */
router.get('/preferences', auth, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
  if (!user) return res.status(404).json({ error: 'User not found' });

  res.json({
    language: user.language,
    profession: user.profession,
    niches: JSON.parse(user.niches || '[]'),
    brief_time: user.brief_time,
    narrator_voice: user.narrator_voice,
    brief_length: user.brief_length,
  });
});

module.exports = router;
