class User {
  final String id;
  final String name;
  final String occupation;
  final String language;
  final String phone;

  User({
    required this.id,
    required this.name,
    required this.occupation,
    required this.language,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      occupation: json['occupation'] as String,
      language: json['language'] as String,
      phone: json['phone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'occupation': occupation,
      'language': language,
      'phone': phone,
    };
  }
}

