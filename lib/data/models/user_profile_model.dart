class UserProfile {
  final int? id;
  final String name;
  final String phoneNumber;
  final String preferredLanguage;
  final String occupationCategory;
  final String incomeRange;
  final Map<String, bool> monthlyObligations;
  final DateTime createdAt;

  UserProfile({
    this.id,
    required this.name,
    required this.phoneNumber,
    required this.preferredLanguage,
    required this.occupationCategory,
    required this.incomeRange,
    required this.monthlyObligations,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'preferred_language': preferredLanguage,
      'occupation_category': occupationCategory,
      'income_range': incomeRange,
      'monthly_obligations': _obligationsToJson(monthlyObligations),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      phoneNumber: map['phone_number'] as String,
      preferredLanguage: map['preferred_language'] as String,
      occupationCategory: map['occupation_category'] as String,
      incomeRange: map['income_range'] as String,
      monthlyObligations: _obligationsFromJson(map['monthly_obligations'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static String _obligationsToJson(Map<String, bool> obligations) {
    return obligations.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
  }

  static Map<String, bool> _obligationsFromJson(String json) {
    final Map<String, bool> obligations = {};
    if (json.isNotEmpty) {
      final pairs = json.split(',');
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          obligations[parts[0]] = parts[1] == 'true';
        }
      }
    }
    return obligations;
  }
}

