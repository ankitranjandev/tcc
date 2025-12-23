class Election {
  final int id;
  final String title;
  final String question;
  final double votingCharge;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final DateTime createdAt;
  final int totalVotes;
  final double totalRevenue;
  final List<ElectionOption> options;
  final UserVote? userVote;

  Election({
    required this.id,
    required this.title,
    required this.question,
    required this.votingCharge,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    required this.totalVotes,
    required this.totalRevenue,
    required this.options,
    this.userVote,
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
      createdAt: DateTime.parse(json['created_at'] as String),
      totalVotes: json['total_votes'] as int,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      options: (json['options'] as List)
          .map((e) => ElectionOption.fromJson(e))
          .toList(),
      userVote: json['user_vote'] != null
          ? UserVote.fromJson(json['user_vote'])
          : null,
    );
  }

  bool get hasVoted => userVote != null;
  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended';
  bool get isPaused => status == 'paused';

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endTime)) {
      return Duration.zero;
    }
    return endTime.difference(now);
  }

  String get timeRemainingText {
    final remaining = timeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h remaining';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m remaining';
    } else {
      return 'Ending soon';
    }
  }

  ElectionOption? get winningOption {
    if (options.isEmpty) return null;
    return options.reduce((a, b) => a.voteCount > b.voteCount ? a : b);
  }
}

class ElectionOption {
  final int id;
  final int electionId;
  final String optionText;
  final int voteCount;
  final DateTime createdAt;

  ElectionOption({
    required this.id,
    required this.electionId,
    required this.optionText,
    required this.voteCount,
    required this.createdAt,
  });

  factory ElectionOption.fromJson(Map<String, dynamic> json) {
    return ElectionOption(
      id: json['id'] as int,
      electionId: json['election_id'] as int,
      optionText: json['option_text'] as String,
      voteCount: json['vote_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0;
    return (voteCount / totalVotes) * 100;
  }
}

class UserVote {
  final int optionId;
  final DateTime votedAt;
  final double? voteCharge;

  UserVote({
    required this.optionId,
    required this.votedAt,
    this.voteCharge,
  });

  factory UserVote.fromJson(Map<String, dynamic> json) {
    return UserVote(
      optionId: json['option_id'] as int,
      votedAt: DateTime.parse(json['voted_at'] as String),
      voteCharge: json['vote_charge'] != null
          ? (json['vote_charge'] as num).toDouble()
          : null,
    );
  }
}

class CastVoteRequest {
  final int electionId;
  final int optionId;

  CastVoteRequest({
    required this.electionId,
    required this.optionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'election_id': electionId,
      'option_id': optionId,
    };
  }
}
