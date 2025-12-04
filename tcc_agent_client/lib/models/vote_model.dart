class VoteModel {
  final String id;
  final String electionId;
  final String userId;
  final String optionId;
  final double charge;
  final DateTime votedAt;
  final String status;

  VoteModel({
    required this.id,
    required this.electionId,
    required this.userId,
    required this.optionId,
    required this.charge,
    required this.votedAt,
    required this.status,
  });

  factory VoteModel.fromJson(Map<String, dynamic> json) {
    return VoteModel(
      id: json['id'] ?? '',
      electionId: json['election_id'] ?? '',
      userId: json['user_id'] ?? '',
      optionId: json['option_id'] ?? '',
      charge: (json['charge'] ?? 0).toDouble(),
      votedAt: DateTime.parse(json['voted_at']),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'election_id': electionId,
      'user_id': userId,
      'option_id': optionId,
      'charge': charge,
      'voted_at': votedAt.toIso8601String(),
      'status': status,
    };
  }
}

class PollOption {
  final String id;
  final String electionId;
  final String label;
  final String? description;
  final int voteCount;

  PollOption({
    required this.id,
    required this.electionId,
    required this.label,
    this.description,
    this.voteCount = 0,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] ?? '',
      electionId: json['election_id'] ?? '',
      label: json['label'] ?? '',
      description: json['description'],
      voteCount: json['vote_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'election_id': electionId,
      'label': label,
      'description': description,
      'vote_count': voteCount,
    };
  }
}

class ElectionModel {
  final String id;
  final String title;
  final String question;
  final List<PollOption> options;
  final double votingCharge;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'open', 'closed', 'upcoming'
  final int totalVotes;
  final double? totalRevenue;
  final String? userVote; // Option ID if user has voted
  final bool hasVoted;

  ElectionModel({
    required this.id,
    required this.title,
    required this.question,
    required this.options,
    required this.votingCharge,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.totalVotes = 0,
    this.totalRevenue,
    this.userVote,
    this.hasVoted = false,
  });

  bool get isOpen => status == 'open' && DateTime.now().isBefore(endDate);
  bool get isClosed => status == 'closed' || DateTime.now().isAfter(endDate);
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  Duration get timeRemaining => endDate.difference(DateTime.now());

  factory ElectionModel.fromJson(Map<String, dynamic> json) {
    return ElectionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      question: json['question'] ?? '',
      options: (json['options'] as List?)
              ?.map((e) => PollOption.fromJson(e))
              .toList() ??
          [],
      votingCharge: (json['voting_charge'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'] ?? 'open',
      totalVotes: json['total_votes'] ?? 0,
      totalRevenue: json['total_revenue']?.toDouble(),
      userVote: json['user_vote'],
      hasVoted: json['has_voted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'question': question,
      'options': options.map((e) => e.toJson()).toList(),
      'voting_charge': votingCharge,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'total_votes': totalVotes,
      'total_revenue': totalRevenue,
      'user_vote': userVote,
      'has_voted': hasVoted,
    };
  }

  ElectionModel copyWith({
    String? id,
    String? title,
    String? question,
    List<PollOption>? options,
    double? votingCharge,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? totalVotes,
    double? totalRevenue,
    String? userVote,
    bool? hasVoted,
  }) {
    return ElectionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      question: question ?? this.question,
      options: options ?? this.options,
      votingCharge: votingCharge ?? this.votingCharge,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      totalVotes: totalVotes ?? this.totalVotes,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      userVote: userVote ?? this.userVote,
      hasVoted: hasVoted ?? this.hasVoted,
    );
  }
}
