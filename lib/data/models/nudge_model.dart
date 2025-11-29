class Nudge {
  final String id;
  final String title;
  final String reason;
  final String impact;
  final String riskLevel; // 'low', 'medium', 'high'
  final String type;

  Nudge({
    required this.id,
    required this.title,
    required this.reason,
    required this.impact,
    required this.riskLevel,
    required this.type,
  });

  factory Nudge.fromJson(Map<String, dynamic> json) {
    return Nudge(
      id: json['id'] as String,
      title: json['title'] as String,
      reason: json['reason'] as String,
      impact: json['impact'] as String,
      riskLevel: json['riskLevel'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'reason': reason,
      'impact': impact,
      'riskLevel': riskLevel,
      'type': type,
    };
  }
}

