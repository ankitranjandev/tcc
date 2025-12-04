import 'package:flutter/material.dart';
import 'transactions_screen.dart';

// History screen is just a wrapper around TransactionsScreen with updated styling
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionsScreen();
  }
}
