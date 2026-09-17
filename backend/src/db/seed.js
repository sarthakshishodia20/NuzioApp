const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');
const { initSchema } = require('./schema');

const MOCK_ARTICLES = [
  // AI & Technology
  {
    title: "Anthropic ships Claude 4.5 with 2M-token memory and native tools.",
    summary: "Anthropic's new memory layer lets Claude hold entire codebases in mind while it works. The new model also supports native tool calling, bringing it closer to autonomous agent use cases. Enterprise customers get access first, with a wider rollout expected next quarter.",
    source: "The Verge",
    category: "ai_technology",
    url: "https://theverge.com",
    read_min: 3,
  },
  {
    title: "Google DeepMind releases Gemini 2.0 with real-time reasoning capabilities.",
    summary: "Gemini 2.0 introduces a new reasoning engine that can handle multi-step problems in real time. The model is integrated into Google Search, Workspace, and Android. Developers can access it via the Gemini API starting today.",
    source: "TechCrunch",
    category: "ai_technology",
    url: "https://techcrunch.com",
    read_min: 4,
  },
  {
    title: "OpenAI o3 model sets new benchmark in mathematical reasoning.",
    summary: "OpenAI o3 outperforms human experts on the MATH benchmark with 96.7% accuracy. The model uses chain-of-thought reasoning and is designed for scientific and engineering applications. Pricing is $15 per million tokens.",
    source: "MIT Tech Review",
    category: "ai_technology",
    url: "https://technologyreview.com",
    read_min: 5,
  },
  {
    title: "Meta launches Llama 4 with multimodal capabilities and 10x speed improvement.",
    summary: "Meta's open-source Llama 4 now supports images, audio, and video natively. The model runs 10x faster than its predecessor on the same hardware. It is free to use for commercial purposes under Meta's updated license.",
    source: "Bloomberg",
    category: "ai_technology",
    url: "https://bloomberg.com",
    read_min: 3,
  },
  {
    title: "GitHub Copilot adds agent mode — autonomously fixes bugs end-to-end.",
    summary: "GitHub's new agent mode allows Copilot to plan, write, test, and commit code changes autonomously. It integrates with CI/CD pipelines and can resolve GitHub Issues directly. Available to all Copilot Enterprise users.",
    source: "GitHub Blog",
    category: "ai_technology",
    url: "https://github.blog",
    read_min: 3,
  },
  // Financial Markets
  {
    title: "Fed minutes hint at a September policy shift amid cooling inflation.",
    summary: "Officials flagged growing confidence that inflation is cooling toward target. Markets now price a 78% chance of a rate cut in September. The 10-year Treasury yield fell 8 basis points on the news.",
    source: "Bloomberg",
    category: "financial_markets",
    url: "https://bloomberg.com",
    read_min: 2,
  },
  {
    title: "Nifty 50 crosses 25,000 for the first time on strong FII inflows.",
    summary: "Foreign institutional investors pumped 8,200 crore rupees into Indian equities in a single session, pushing Nifty to a historic high. IT and banking stocks led the rally. Analysts see room for another 5% upside by year-end.",
    source: "Economic Times",
    category: "financial_markets",
    url: "https://economictimes.com",
    read_min: 3,
  },
  {
    title: "Bitcoin surpasses $100k as spot ETF inflows accelerate.",
    summary: "Bitcoin crossed the $100,000 mark for the first time as spot ETFs recorded $2.1B in weekly inflows. BlackRock IBIT is now the fastest-growing ETF in history. Analysts warn of volatility ahead of the next halving.",
    source: "CoinDesk",
    category: "financial_markets",
    url: "https://coindesk.com",
    read_min: 4,
  },
  // Indian Business
  {
    title: "Reliance Jio launches JioAI Cloud — targets 50M SMEs with affordable compute.",
    summary: "Jio's new cloud platform offers GPU compute at 2 rupees per hour, a fraction of AWS pricing. It integrates with JioPhone and offers Hindi-first AI tools. The launch is seen as a direct challenge to AWS and Azure in India.",
    source: "Mint",
    category: "indian_business",
    url: "https://livemint.com",
    read_min: 3,
  },
  {
    title: "Zepto raises $350M Series F, valued at $5B after rapid 10-minute delivery expansion.",
    summary: "Zepto's latest round brings its valuation to $5B, just 18 months after its Series E. The company now operates in 25 cities and is profitable in 14 of them. It plans to expand to Tier-2 cities before its expected 2025 IPO.",
    source: "The Ken",
    category: "indian_business",
    url: "https://the-ken.com",
    read_min: 4,
  },
  {
    title: "Tata Motors EV division posts first quarterly profit of 1,200 crore rupees.",
    summary: "Tata Motors EV business turned profitable for the first time, driven by Nexon EV and Punch EV sales. The company holds 60% of the Indian EV market. Management guided for 40% volume growth in FY26.",
    source: "Business Standard",
    category: "indian_business",
    url: "https://business-standard.com",
    read_min: 3,
  },
  // Startups
  {
    title: "Y Combinator W25 batch reveals 40% AI-native companies — highest ever.",
    summary: "YC's Winter 2025 batch has 40% companies building core AI products, up from 25% in W24. Notable startups include an AI radiologist, an autonomous legal firm, and a B2B voice AI for Indian SMEs.",
    source: "TechCrunch",
    category: "startups",
    url: "https://techcrunch.com",
    read_min: 4,
  },
  {
    title: "Sarvam AI raises $41M to build India foundational LLM in 22 languages.",
    summary: "Bengaluru-based Sarvam AI has raised $41M to build a large language model trained on Indian languages. The model supports 22 languages including Hindi, Tamil, Telugu, and Kannada. It is being deployed in government services across 3 states.",
    source: "YourStory",
    category: "startups",
    url: "https://yourstory.com",
    read_min: 3,
  },
  {
    title: "Meesho clocks 7,600 crore rupees revenue, eyes profitability before Diwali IPO.",
    summary: "Meesho's revenue grew 33% YoY as it doubled down on Tier-3 and Tier-4 markets. The company reduced losses by 80% and is targeting EBITDA breakeven. An IPO filing before the festive season is expected.",
    source: "The Ken",
    category: "startups",
    url: "https://the-ken.com",
    read_min: 4,
  },
  // Science
  {
    title: "ISRO Gaganyaan test flight a success — crew capsule recovered from Bay of Bengal.",
    summary: "ISRO's uncrewed Gaganyaan test was flawless, with the crew module splashing down precisely in the Bay of Bengal. This paves the way for India's first crewed space mission in 2026. PM Modi called it a historic moment for Indian science.",
    source: "NDTV",
    category: "science",
    url: "https://ndtv.com",
    read_min: 4,
  },
  {
    title: "Scientists achieve room-temperature superconductivity for the first time.",
    summary: "A team at MIT has demonstrated superconductivity at 25 degrees Celsius using a novel hydrogen-rich compound under moderate pressure. The breakthrough could transform power grids, MRI machines, and quantum computers. Peer review is ongoing.",
    source: "Nature",
    category: "science",
    url: "https://nature.com",
    read_min: 5,
  },
  // Global Politics
  {
    title: "India and EU sign landmark trade deal — 70% tariff reduction on goods.",
    summary: "After 9 years of negotiations, India and the EU have finalised a free trade agreement covering 70% tariff cuts on goods and services. The deal is expected to boost bilateral trade from $120B to $200B by 2030. Indian exporters in textiles, pharma, and IT stand to gain most.",
    source: "Reuters",
    category: "global_politics",
    url: "https://reuters.com",
    read_min: 4,
  },
  {
    title: "G20 summit agrees on global AI governance framework for the first time.",
    summary: "G20 leaders adopted a non-binding framework for AI governance, covering safety standards, transparency, and cross-border data flows. India played a key role as co-chair. Critics argue the framework lacks enforcement mechanisms.",
    source: "The Guardian",
    category: "global_politics",
    url: "https://theguardian.com",
    read_min: 3,
  },
  // Health & Medicine
  {
    title: "AI model detects pancreatic cancer 3 years before symptoms with 94% accuracy.",
    summary: "Researchers at Harvard Medical School trained a model on 6 million patient records to detect early-stage pancreatic cancer. The model is 3x more accurate than current biomarker tests. Clinical trials are planned for 2025.",
    source: "NEJM",
    category: "health_medicine",
    url: "https://nejm.org",
    read_min: 4,
  },
  {
    title: "WHO approves first mRNA malaria vaccine — could save 500,000 lives annually.",
    summary: "The WHO has granted emergency use approval to an mRNA-based malaria vaccine developed by BioNTech and the Wellcome Trust. Trials showed 85% efficacy, far surpassing existing vaccines. Rollout begins in sub-Saharan Africa in 2025.",
    source: "Lancet",
    category: "health_medicine",
    url: "https://thelancet.com",
    read_min: 5,
  },
  // Climate & Energy
  {
    title: "India achieves 200GW renewable energy milestone — 3 years ahead of schedule.",
    summary: "India hit its 200GW renewable energy target in 2024, three years ahead of the 2027 deadline. Solar accounts for 130GW of the total. The government has now set a new target of 500GW by 2030.",
    source: "Times of India",
    category: "climate_energy",
    url: "https://timesofindia.com",
    read_min: 3,
  },
  {
    title: "Tesla Megapack powers entire Mumbai suburb for 6 hours during grid outage.",
    summary: "A Tesla Megapack battery installation in Navi Mumbai kept 40,000 homes powered for 6 hours during a grid failure. It is the largest battery storage deployment in South Asia. MSEDCL plans to expand the project to 5 more locations.",
    source: "Hindustan Times",
    category: "climate_energy",
    url: "https://hindustantimes.com",
    read_min: 3,
  },
  // Sports
  {
    title: "Virat Kohli becomes highest run-scorer in Test cricket, surpasses Sachin record.",
    summary: "Kohli scored 79 in the second innings against England, taking him past Sachin Tendulkar's all-time Test record of 15,921 runs. The crowd at Lord's gave him a standing ovation. He becomes only the second Indian to score 100 international centuries.",
    source: "ESPNcricinfo",
    category: "sports",
    url: "https://espncricinfo.com",
    read_min: 3,
  },
  {
    title: "Neeraj Chopra defends Olympic gold with world record 93.7m throw in Paris.",
    summary: "Neeraj Chopra threw 93.7m in his fifth attempt to win Olympic gold and set a new world record in Paris 2024. The throw eclipsed Jan Zelezny's 1996 record of 93.4m. India celebrates its most golden Olympic performance ever.",
    source: "Sportstar",
    category: "sports",
    url: "https://sportstar.thehindu.com",
    read_min: 4,
  },
  // Culture & Arts
  {
    title: "All We Imagine as Light wins Palme d Or — first Indian film in Cannes history.",
    summary: "Director Payal Kapadia's debut feature about two nurses in Mumbai won the Palme d'Or at Cannes, making history as the first Indian film to win cinema's highest honour. The film will release in India on August 9.",
    source: "The Hindu",
    category: "culture_arts",
    url: "https://thehindu.com",
    read_min: 3,
  },
];

function seed() {
  initSchema();

  const insertArticle = db.prepare(`
    INSERT OR IGNORE INTO articles (id, title, summary, source, category, url, read_min, published_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const seedMany = db.transaction(() => {
    for (const article of MOCK_ARTICLES) {
      const hoursAgo = Math.floor(Math.random() * 36);
      const publishedAt = new Date(Date.now() - hoursAgo * 60 * 60 * 1000).toISOString();
      insertArticle.run(uuidv4(), article.title, article.summary, article.source, article.category, article.url, article.read_min, publishedAt);
    }
  });

  seedMany();
  console.log(`Seeded ${MOCK_ARTICLES.length} articles successfully`);
}

seed();
