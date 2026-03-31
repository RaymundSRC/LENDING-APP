import 'package:flutter/material.dart';
import '../../../theme/dashboard_theme.dart';

/// Utility class for loan payment history UI components
class LoanPaymentHistory {
  /// Builds a scrollable list of all loan payment transactions
  static List<Widget> buildPaymentHistory(Map<String, dynamic> loan) {
    List history =
        loan['paymentHistory'] ?? []; // Get payment history or empty list

    // Return empty state if no payments exist
    if (history.isEmpty) {
      return [
        const Text(
          'No payment history available.', // Empty state message
          style: TextStyle(color: Colors.black54),
        )
      ];
    }

    return [
      const SizedBox(height: 8), // Top spacing
      Container(
        decoration: BoxDecoration(
            color: Colors.grey.shade50, // Background color
            borderRadius: BorderRadius.circular(12), // Rounded corners
            border: Border.all(color: Colors.grey.shade200)), // Subtle border
        child: ListView.separated(
          shrinkWrap: true, // Prevent list from expanding infinitely
          physics:
              const NeverScrollableScrollPhysics(), // Disable scrolling for nested list
          itemCount: history.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.grey), // Separator line
          itemBuilder: (context, index) {
            final payment = history[index]; // Get current payment
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8), // Internal padding
              leading: CircleAvatar(
                radius: 20, // Icon size
                backgroundColor: DashboardTheme.accentColor
                    .withOpacity(0.1), // Subtle background
                child: const Icon(
                  Icons.payment, // Payment icon
                  color: DashboardTheme.accentColor, // Theme color
                  size: 20, // Icon size
                ),
              ),
              title: Text(
                payment['label'] ?? 'Payment', // Payment label or default
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment['date'] ?? '', // Payment date
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600, // Subtle text color
                    ),
                  ),
                  // Show payment breakdown if both portions exist
                  if (payment['interestPortion'] != null &&
                      payment['principalPortion'] != null)
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 4), // Top spacing for breakdown
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2), // Internal padding
                            decoration: BoxDecoration(
                                color: Colors.orange
                                    .shade100, // Orange background for interest
                                borderRadius: BorderRadius.circular(
                                    4)), // Rounded corners
                            child: Text(
                              'Interest: ₱${payment['interestPortion'].toStringAsFixed(2)}', // Interest amount
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors
                                      .orange.shade800, // Dark orange text
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 6), // Spacing between tags
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2), // Internal padding
                            decoration: BoxDecoration(
                                color: Colors.green
                                    .shade100, // Green background for principal
                                borderRadius: BorderRadius.circular(
                                    4)), // Rounded corners
                            child: Text(
                              'Principal: ₱${payment['principalPortion'].toStringAsFixed(2)}', // Principal amount
                              style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      Colors.green.shade800, // Dark green text
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₱${(payment['amount'] as num).toDouble().toStringAsFixed(2)}', // Total payment amount
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green), // Green for paid amount
                  ),
                  const SizedBox(height: 2), // Small spacing
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2), // Badge padding
                    decoration: BoxDecoration(
                        color: Colors.green.shade100, // Green badge background
                        borderRadius:
                            BorderRadius.circular(4)), // Rounded corners
                    child: Text(
                      'PAID', // Payment status
                      style: TextStyle(
                          fontSize: 8,
                          color: Colors.green.shade800, // Dark green text
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }

  /// Builds summary cards showing loan financial overview
  static List<Widget> buildSummaryCards(Map<String, dynamic> loan) {
    double totalPaid = (loan['totalPaid'] as num?)?.toDouble() ??
        0.0; // Total amount paid so far
    double originalAmount =
        (loan['amount'] as num).toDouble(); // Original loan amount
    double remainingPrincipal = (loan['remainingPrincipal'] as num)
        .toDouble(); // Remaining principal balance
    double remainingInterest = (loan['remainingInterest'] as num)
        .toDouble(); // Remaining interest balance

    return [
      // First row: Original amount and total paid
      Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Original Amount', // Card title
              '₱${originalAmount.toStringAsFixed(2)}', // Formatted amount
              Icons.account_balance_wallet, // Wallet icon
              Colors.blue, // Blue color for original amount
            ),
          ),
          const SizedBox(width: 12), // Spacing between cards
          Expanded(
            child: _buildSummaryCard(
              'Total Paid', // Card title
              '₱${totalPaid.toStringAsFixed(2)}', // Formatted amount
              Icons.payments, // Payment icon
              Colors.green, // Green color for paid amount
            ),
          ),
        ],
      ),
      const SizedBox(height: 12), // Spacing between rows
      // Second row: Remaining principal and interest
      Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Remaining Principal', // Card title
              '₱${remainingPrincipal.toStringAsFixed(2)}', // Formatted amount
              Icons.money_off, // Money off icon
              remainingPrincipal > 0
                  ? Colors.orange
                  : Colors.grey, // Orange if remaining, grey if zero
            ),
          ),
          const SizedBox(width: 12), // Spacing between cards
          Expanded(
            child: _buildSummaryCard(
              'Remaining Interest', // Card title
              '₱${remainingInterest.toStringAsFixed(2)}', // Formatted amount
              Icons.percent, // Percent icon
              remainingInterest > 0
                  ? Colors.red
                  : Colors.grey, // Red if remaining, grey if zero
            ),
          ),
        ],
      ),
    ];
  }

  /// Builds a summary card with icon, title, and value
  static Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16), // Internal padding
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), // Subtle background color
          borderRadius: BorderRadius.circular(12), // Rounded corners
          border: Border.all(color: color.withOpacity(0.2))), // Subtle border
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20), // Card icon
          const SizedBox(height: 8), // Spacing after icon
          Text(
            title, // Card title
            style: const TextStyle(
                color: Colors.black54, // Subtle text color
                fontSize: 11,
                fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // Prevent text overflow
          ),
          const SizedBox(height: 4), // Spacing before value
          FittedBox(
            fit: BoxFit.scaleDown, // Scale down if needed
            alignment: Alignment.centerLeft,
            child: Text(
              value, // Card value
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color), // Bold colored text
            ),
          ),
        ],
      ),
    );
  }
}
