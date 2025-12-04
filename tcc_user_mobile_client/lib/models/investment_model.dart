class InvestmentModel {
  final String id;
  final String name;
  final String category;
  final double amount;
  final double roi;
  final int period; // in months
  final double expectedReturn;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  InvestmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.roi,
    required this.period,
    required this.expectedReturn,
    required this.startDate,
    required this.endDate,
    this.status = 'ACTIVE',
  });

  int get daysLeft => endDate.difference(DateTime.now()).inDays;
  double get progress => DateTime.now().difference(startDate).inDays /
                          endDate.difference(startDate).inDays;
}

class InvestmentProduct {
  final String id;
  final String name;
  final String unit;
  final double price;
  final double roi;
  final int minPeriod;
  final String description;
  final String category;

  InvestmentProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.roi,
    required this.minPeriod,
    required this.description,
    required this.category,
  });
}
