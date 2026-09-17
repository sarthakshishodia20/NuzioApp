class ArticleModel {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String category;
  final String url;
  final int readMin;
  final String publishedAt;
  bool isSaved;

  ArticleModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.category,
    required this.url,
    required this.readMin,
    required this.publishedAt,
    this.isSaved = false,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      source: json['source'] ?? '',
      category: json['category'] ?? '',
      url: json['url'] ?? '',
      readMin: json['read_min'] ?? 3,
      publishedAt: json['published_at'] ?? '',
      isSaved: (json['is_saved'] == 1 || json['is_saved'] == true),
    );
  }

  String get categoryLabel {
    const labels = {
      'ai_technology': 'AI & Tech',
      'financial_markets': 'Markets',
      'indian_business': 'Indian Biz',
      'startups': 'Startups',
      'science': 'Science',
      'global_politics': 'Global',
      'health_medicine': 'Health',
      'climate_energy': 'Climate',
      'sports': 'Sports',
      'culture_arts': 'Culture',
    };
    return labels[category] ?? category;
  }
}
