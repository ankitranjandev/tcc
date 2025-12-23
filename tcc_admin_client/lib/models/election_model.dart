class Election {
  final int id;
  final String title;
  final String question;
  final double votingCharge;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? endedAt;
  final int totalVotes;
  final double totalRevenue;
  final List<ElectionOption>? options;

  Election({
    required this.id,
    required this.title,
    required this.question,
    required this.votingCharge,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.endedAt,
    required this.totalVotes,
    required this.totalRevenue,
    this.options,
  });

  factory Election.fromJson(Map<String, dynamic> json) {
    return Election(
      id: json['id'] as int,
      title: json['title'] as String,
      question: json['question'] as String,
      votingCharge: (json['voting_charge'] as num).toDouble(),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: json['status'] as String,
      createdBy: json['created_by'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
      totalVotes: json['total_votes'] as int,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      options: json['options'] != null
          ? (json['options'] as List).map((e) => ElectionOption.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'question': question,
      'voting_charge': votingCharge,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'total_votes': totalVotes,
      'total_revenue': totalRevenue,
      'options': options?.map((e) => e.toJson()).toList(),
    };
  }

  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended';
  bool get isPaused => status == 'paused';
  bool get hasVotes => totalVotes > 0;
}

class ElectionOption {
  final int id;
  final int electionId;
  final String optionText;
  final int voteCount;
  final DateTime createdAt;
  final double? percentage;

  ElectionOption({
    required this.id,
    required this.electionId,
    required this.optionText,
    required this.voteCount,
    required this.createdAt,
    this.percentage,
  });

  factory ElectionOption.fromJson(Map<String, dynamic> json) {
    return ElectionOption(
      id: json['id'] as int,
      electionId: json['election_id'] as int,
      optionText: json['option_text'] as String,
      voteCount: json['vote_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      percentage: json['percentage'] != null ? (json['percentage'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'election_id': electionId,
      'option_text': optionText,
      'vote_count': voteCount,
      'created_at': createdAt.toIso8601String(),
      if (percentage != null) 'percentage': percentage,
    };
  }
}

class ElectionVoter {
  final int userId;
  final String firstName;
  final String lastName;
  final int optionId;
  final String optionText;
  final DateTime votedAt;
  final double voteCharge;

  ElectionVoter({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.optionId,
    required this.optionText,
    required this.votedAt,
    required this.voteCharge,
  });

  factory ElectionVoter.fromJson(Map<String, dynamic> json) {
    return ElectionVoter(
      userId: json['user_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      optionId: json['option_id'] as int,
      optionText: json['option_text'] as String,
      votedAt: DateTime.parse(json['voted_at'] as String),
      voteCharge: (json['vote_charge'] as num).toDouble(),
    );
  }

  String get fullName => '$firstName $lastName';
}

class ElectionStats {
  final Election election;
  final List<ElectionOption> options;
  final List<ElectionVoter> voters;

  ElectionStats({
    required this.election,
    required this.options,
    required this.voters,
  });

  factory ElectionStats.fromJson(Map<String, dynamic> json) {
    return ElectionStats(
      election: Election.fromJson(json),
      options: (json['options'] as List).map((e) => ElectionOption.fromJson(e)).toList(),
      voters: (json['voters'] as List).map((e) => ElectionVoter.fromJson(e)).toList(),
    );
  }
}

class CreateElectionRequest {
  final String title;
  final String question;
  final List<String> options;
  final double votingCharge;
  final DateTime endTime;

  CreateElectionRequest({
    required this.title,
    required this.question,
    required this.options,
    required this.votingCharge,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'question': question,
      'options': options,
      'voting_charge': votingCharge,
      'end_time': endTime.toIso8601String(),
    };
  }
}

class UpdateElectionRequest {
  final String? title;
  final String? question;
  final List<String>? options;
  final double? votingCharge;
  final DateTime? endTime;

  UpdateElectionRequest({
    this.title,
    this.question,
    this.options,
    this.votingCharge,
    this.endTime,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (question != null) map['question'] = question;
    if (options != null) map['options'] = options;
    if (votingCharge != null) map['voting_charge'] = votingCharge;
    if (endTime != null) map['end_time'] = endTime!.toIso8601String();
    return map;
  }
}
