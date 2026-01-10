import 'package:flutter/material.dart';
import 'transactions_screen.dart';

// History screen is just a wrapper around TransactionsScreen with updated styling
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  final GlobalKey<TransactionsScreenState> _transactionsKey = GlobalKey();

  /// Public method to refresh transactions when entering the History tab
  void refreshTransactions() {
    _transactionsKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return TransactionsScreen(key: _transactionsKey);
  }
}
