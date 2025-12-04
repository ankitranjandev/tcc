/// Poll Model
/// Represents a poll/voting in the system
class PollModel {
  final String pollId;
  final String title;
  final String description;
  final double voteCharge;
  final List<PollOption> options;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // DRAFT, ACTIVE, ENDED
  final int totalVotes;
  final double totalRevenue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  PollModel({
    required this.pollId,
    required this.title,
    required this.description,
    required this.voteCharge,
    required this.options,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalVotes,
    required this.totalRevenue,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      pollId: json['poll_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      voteCharge: (json['vote_charge'] as num).toDouble(),
      options: (json['options'] as List<dynamic>)
          .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['status'] as String,
      totalVotes: json['total_votes'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poll_id': pollId,
      'title': title,
      'description': description,
      'vote_charge': voteCharge,
      'options': options.map((e) => e.toJson()).toList(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'total_votes': totalVotes,
      'total_revenue': totalRevenue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  /// Check if poll is active
  bool get isActive => status == 'ACTIVE';

  /// Check if poll is ended
  bool get isEnded => status == 'ENDED';

  /// Check if poll is draft
  bool get isDraft => status == 'DRAFT';

  /// Check if poll is currently running (active and within date range)
  bool get isRunning {
    if (!isActive) return false;
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

/// Poll Option Model
class PollOption {
  final String optionId;
  final String optionText;
  final int votes;
  final double revenue;

  PollOption({
    required this.optionId,
    required this.optionText,
    required this.votes,
    required this.revenue,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      optionId: json['option_id'] as String? ?? json['id'] as String? ?? '',
      optionText: json['option_text'] as String? ?? json['text'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'option_id': optionId,
      'option_text': optionText,
      'votes': votes,
      'revenue': revenue,
    };
  }

  /// Calculate percentage of total votes
  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0.0;
    return (votes / totalVotes) * 100;
  }
}

/// Vote Model
/// Represents a user's vote on a poll
class VoteModel {
  final String voteId;
  final String pollId;
  final String userId;
  final String userName;
  final String selectedOption;
  final double amountPaid;
  final DateTime votedAt;

  VoteModel({
    required this.voteId,
    required this.pollId,
    required this.userId,
    required this.userName,
    required this.selectedOption,
    required this.amountPaid,
    required this.votedAt,
  });

  factory VoteModel.fromJson(Map<String, dynamic> json) {
    return VoteModel(
      voteId: json['vote_id'] as String,
      pollId: json['poll_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Unknown',
      selectedOption: json['selected_option'] as String,
      amountPaid: (json['amount_paid'] as num).toDouble(),
      votedAt: DateTime.parse(json['voted_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vote_id': voteId,
      'poll_id': pollId,
      'user_id': userId,
      'user_name': userName,
      'selected_option': selectedOption,
      'amount_paid': amountPaid,
      'voted_at': votedAt.toIso8601String(),
    };
  }
}

/// Poll Revenue Model
/// Represents revenue analytics per option
class PollRevenueModel {
  final String pollId;
  final String pollTitle;
  final List<OptionRevenue> optionRevenues;
  final double totalRevenue;
  final int totalVotes;

  PollRevenueModel({
    required this.pollId,
    required this.pollTitle,
    required this.optionRevenues,
    required this.totalRevenue,
    required this.totalVotes,
  });

  factory PollRevenueModel.fromJson(Map<String, dynamic> json) {
    return PollRevenueModel(
      pollId: json['poll_id'] as String,
      pollTitle: json['poll_title'] as String,
      optionRevenues: (json['option_revenues'] as List<dynamic>)
          .map((e) => OptionRevenue.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalVotes: json['total_votes'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poll_id': pollId,
      'poll_title': pollTitle,
      'option_revenues': optionRevenues.map((e) => e.toJson()).toList(),
      'total_revenue': totalRevenue,
      'total_votes': totalVotes,
    };
  }
}

/// Option Revenue Model
class OptionRevenue {
  final String optionText;
  final int votes;
  final double revenue;
  final double percentage;

  OptionRevenue({
    required this.optionText,
    required this.votes,
    required this.revenue,
    required this.percentage,
  });

  factory OptionRevenue.fromJson(Map<String, dynamic> json) {
    return OptionRevenue(
      optionText: json['option_text'] as String,
      votes: json['votes'] as int,
      revenue: (json['revenue'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'option_text': optionText,
      'votes': votes,
      'revenue': revenue,
      'percentage': percentage,
    };
  }
}
