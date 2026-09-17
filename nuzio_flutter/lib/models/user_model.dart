class UserModel {
  final String id;
  final String name;
  final String email;
  final String language;
  final String profession;
  final List<String> niches;
  final String briefTime;
  final String narratorVoice;
  final int briefLength;
  final bool onboardingDone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.language = 'en',
    this.profession = '',
    this.niches = const [],
    this.briefTime = '07:00',
    this.narratorVoice = 'Aria',
    this.briefLength = 5,
    this.onboardingDone = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      language: json['language'] ?? 'en',
      profession: json['profession'] ?? '',
      niches: List<String>.from(json['niches'] ?? []),
      briefTime: json['brief_time'] ?? '07:00',
      narratorVoice: json['narrator_voice'] ?? 'Aria',
      briefLength: json['brief_length'] ?? 5,
      onboardingDone: json['onboarding_done'] == true,
    );
  }

  String get firstName => name.split(' ').first;
}
