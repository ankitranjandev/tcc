// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

/// CSV Export Utility for Web
class CsvExport {
  /// Export data to CSV file
  static void exportToCSV({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    // Create CSV content
    final csvContent = StringBuffer();

    // Add headers
    csvContent.writeln(headers.map((h) => _escapeCsvField(h)).join(','));

    // Add rows
    for (final row in rows) {
      csvContent.writeln(row.map((cell) => _escapeCsvField(cell)).join(','));
    }

    // Create blob and download
    final bytes = utf8.encode(csvContent.toString());
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = '$filename.csv';
    html.document.body?.children.add(anchor);

    // Trigger download
    anchor.click();

    // Cleanup
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  /// Escape CSV field (handle commas, quotes, newlines)
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Export users to CSV
  static void exportUsers(List<dynamic> users) {
    final headers = [
      'User ID',
      'First Name',
      'Last Name',
      'Email',
      'Phone',
      'KYC Status',
      'Account Status',
      'Wallet Balance',
      'Registration Date',
    ];

    final rows = users.map((user) {
      return <String>[
        user.id.toString(),
        user.firstName.toString(),
        user.lastName.toString(),
        user.email.toString(),
        user.phone?.toString() ?? 'N/A',
        user.kycStatus.displayName,
        user.status.displayName,
        user.walletBalance.toString(),
        user.createdAt.toString(),
      ];
    }).toList();

    exportToCSV(
      filename: 'users_export_${DateTime.now().millisecondsSinceEpoch}',
      headers: headers,
      rows: rows,
    );
  }

  /// Export agents to CSV
  static void exportAgents(List<dynamic> agents) {
    final headers = [
      'Agent ID',
      'First Name',
      'Last Name',
      'Business Name',
      'Registration Number',
      'Email',
      'Phone',
      'Location',
      'Verification Status',
      'Account Status',
      'Commission Rate',
      'Total Earned',
      'Total Transactions',
      'Wallet Balance',
      'Available',
      'Registration Date',
    ];

    final rows = agents.map((agent) {
      return <String>[
        agent.id.toString(),
        agent.firstName.toString(),
        agent.lastName.toString(),
        agent.businessName.toString(),
        agent.businessRegistrationNumber.toString(),
        agent.email.toString(),
        agent.phone.toString(),
        agent.location.toString(),
        agent.verificationStatus.displayName,
        agent.status.displayName,
        '${agent.commissionRate}%',
        agent.totalCommissionEarned.toString(),
        agent.totalTransactions.toString(),
        agent.walletBalance.toString(),
        agent.isAvailable ? 'Yes' : 'No',
        agent.createdAt.toString(),
      ];
    }).toList();

    exportToCSV(
      filename: 'agents_export_${DateTime.now().millisecondsSinceEpoch}',
      headers: headers,
      rows: rows,
    );
  }

  /// Export transactions to CSV
  static void exportTransactions(List<dynamic> transactions) {
    final headers = [
      'Transaction ID',
      'User ID',
      'User Name',
      'Agent ID',
      'Type',
      'Amount',
      'Fee',
      'Total',
      'Status',
      'Description',
      'Date',
    ];

    final rows = transactions.map((txn) {
      return <String>[
        txn.id.toString(),
        txn.userId.toString(),
        txn.userName?.toString() ?? 'N/A',
        txn.agentId?.toString() ?? 'N/A',
        txn.type.displayName,
        txn.amount.toString(),
        txn.fee.toString(),
        txn.total.toString(),
        txn.status.displayName,
        txn.description?.toString() ?? 'N/A',
        txn.createdAt.toString(),
      ];
    }).toList();

    exportToCSV(
      filename: 'transactions_export_${DateTime.now().millisecondsSinceEpoch}',
      headers: headers,
      rows: rows,
    );
  }

  /// Export investments to CSV
  static void exportInvestments(List<Map<String, dynamic>> investments) {
    final headers = [
      'Investment ID',
      'User',
      'Category',
      'Sub-Category',
      'Amount Invested',
      'Tenure (months)',
      'Expected Return %',
      'Expected Return Amount',
      'Progress %',
      'Start Date',
      'Maturity Date',
      'Status',
    ];

    final rows = investments.map((inv) {
      return [
        inv['id'].toString(),
        inv['userName'].toString(),
        inv['category'].toString(),
        inv['subCategory'].toString(),
        inv['amountInvested'].toString(),
        inv['tenure'].toString(),
        inv['expectedReturn'].toString(),
        inv['expectedReturnAmount'].toString(),
        inv['progress'].toString(),
        inv['startDate'].toString(),
        inv['maturityDate'].toString(),
        inv['status'].toString(),
      ];
    }).toList();

    exportToCSV(
      filename: 'investments_export_${DateTime.now().millisecondsSinceEpoch}',
      headers: headers,
      rows: rows,
    );
  }

  /// Export polls to CSV
  static void exportPolls(List<Map<String, dynamic>> polls) {
    final headers = [
      'Poll ID',
      'Title',
      'Question',
      'Type',
      'Options',
      'Total Votes',
      'Total Revenue',
      'Start Date',
      'End Date',
      'Status',
    ];

    final rows = polls.map((poll) {
      final options = (poll['options'] as List).map((o) => o['option']).join('; ');
      return [
        poll['id'].toString(),
        poll['title'].toString(),
        poll['question'].toString(),
        poll['type'].toString(),
        options,
        poll['totalVotes'].toString(),
        poll['totalRevenue'].toString(),
        poll['startDate'].toString(),
        poll['endDate'].toString(),
        poll['status'].toString(),
      ];
    }).toList();

    exportToCSV(
      filename: 'polls_export_${DateTime.now().millisecondsSinceEpoch}',
      headers: headers,
      rows: rows,
    );
  }
}
