# Nuzio AI — Personalised Audio News App

> **News on go.** Personalised audio news for Indian professionals — curated every morning.

A full-stack personalized audio news platform with an **Express + Node.js REST API** backend and a **Flutter dark-mode UI** matching the Nuzio AI aesthetic.

---

## 🚀 Live Backend Deployment

- **Live Public URL**: [https://nuzio-api-sarthak.loca.lt](https://nuzio-api-sarthak.loca.lt)
- **API Base**: `https://nuzio-api-sarthak.loca.lt/api`
- **1-Click Render Deploy**: Ready with `render.yaml` and `Dockerfile`

---

## 📱 Features & Screens

1. **Splash Screen**:
   - Animated soundwave logo with glowing purple effects
   - Brand taglines: *"News on go"*, *"YOUR AUDIO BRIEF, EVERY MORNING"*
   - Live state indicator: *"CURATING YOUR BRIEF..."*

2. **Language Selection**:
   - English (🇬🇧) and Hindi (🇮🇳) briefing delivery choices
   - Hyperlocal location toggle switch

3. **JWT Authentication (Email Login/Signup)**:
   - Clean email-based login returning JWT token (30-day expiry)
   - Auto session restore via SharedPreferences

4. **Personalized Onboarding (3 Steps)**:
   - **Step 1 - Profession Picker**: Finance, Legal, Technology, Healthcare, Consulting, Marketing, Government, Real Estate, Founder, Education
   - **Step 2 - Niches Selector**: Up to 7 niches (AI & Technology, Financial Markets, Indian Business, Global Politics, Startups, Science, etc.)
   - **Step 3 - Voice & Delivery Time**: Aria (British), Kai (American), Meera (Indian) with audio duration (5, 10, 15 min) and morning delivery schedule

5. **Audio News Brief Player**:
   - Real-time 28-bar animated audio waveform visualizer
   - Play/Pause, Next story, Previous story, and Speed controls (1x, 1.25x, 1.5x, 2x)
   - "Now narrating" live subtitle banner with mini controls
   - Category filters & story queue navigation

6. **Discover Feed with Live Search API**:
   - Dedicated search bar executing real-time full-text search queries via `/api/news/search?q=...`
   - Inshorts-style cards with category tags, source link, read time, and bookmarking
   - Direct Play button on each card to immediately launch audio player

7. **Settings & Profile**:
   - User profile with interactive name/profession editor
   - Saved stories library viewer with playback trigger
   - Appearance toggle: Dark mode & Light mode
   - Commute offline mode, auto-advance, and push notification toggles

8. **Plan & Billing (Subscription UI)**:
   - **Free Plan**: ₹0/mo — 5 article summaries daily, push notifications
   - **Pro Plan (Launch Offer)**: ₹79/mo — Unlimited custom briefings, premium AI voices, multi-language support
   - **Pro Annual Plan**: ₹1,499/yr (35% discount)

---

## 🛠️ Architecture & Tech Stack

```
assessment/
├── backend/                  # Node.js + Express + SQLite
│   ├── src/
│   │   ├── config/           # Database configuration
│   │   ├── db/               # Schema & seeded articles
│   │   ├── middleware/       # JWT authentication middleware
│   │   ├── routes/           # auth, news, user
│   │   └── services/         # NewsAPI integration service
│   ├── Dockerfile            # Container deployment
│   ├── server.js             # Entrypoint
│   └── package.json
├── nuzio_flutter/            # Flutter Dark Mode Application
│   ├── lib/
│   │   ├── core/             # Theme, constants, ApiClient with interceptors
│   │   ├── features/
│   │   │   ├── auth/         # Login & JWT AuthProvider
│   │   │   ├── brief/        # Home Audio Player Screen
│   │   │   ├── discover/     # Inshorts-style feed with live search
│   │   │   ├── onboarding/   # Language, Profession, Niches, Voice & Time
│   │   │   ├── settings/     # Profile, Saved Stories, Plan & Billing
│   │   │   └── splash/       # Animated Splash screen
│   │   └── models/           # UserModel, ArticleModel
│   └── pubspec.yaml
└── render.yaml               # Render Cloud deployment blueprint
```

---

## 🔌 API Endpoints

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/api/auth/login` | Login/Register with email & name → JWT | No |
| `GET` | `/api/auth/me` | Fetch authenticated user profile | Yes (Bearer token) |
| `PUT` | `/api/user/preferences` | Update profession, niches, voice, time | Yes |
| `GET` | `/api/user/preferences` | Retrieve user preferences | Yes |
| `GET` | `/api/news/feed` | Personalized feed filtered by niches/category | Yes |
| `GET` | `/api/news/search?q=:query` | Live full-text search across all stories | Yes |
| `GET` | `/api/news/brief/today` | Morning brief queue (5-6 stories) | Yes |
| `POST` | `/api/news/save/:id` | Toggle save/bookmark story | Yes |
| `GET` | `/api/news/saved` | Fetch user's saved stories | Yes |

---

## 📦 How to Run Locally

### Backend
```bash
cd backend
npm install
node server.js
```
Runs on `http://localhost:3000`.

### Flutter App
```bash
cd nuzio_flutter
flutter pub get
flutter run
```

To build APK:
```bash
flutter build apk
```
The resulting APK will be saved at: `nuzio_flutter/build/app/outputs/flutter-apk/app-release.apk`.
