class Goal {
  final String id;
  final String title;
  final double target;
  final double current;
  final String type; // 'vault' or other

  Goal({
    required this.id,
    required this.title,
    required this.target,
    required this.current,
    required this.type,
  });

  double get progress => target > 0 ? current / target : 0.0;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      target: (json['target'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'target': target,
      'current': current,
      'type': type,
    };
  }
}

