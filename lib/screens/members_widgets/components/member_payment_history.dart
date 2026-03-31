import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/dashboard_theme.dart';

/// Utility class for member payment history UI components
class MemberPaymentHistory {
  // === PAYMENT HISTORY LIST ===

  /// Builds a scrollable list of all member payment transactions
  static List<Widget> buildPaymentHistory(Map<String, dynamic> member) {
    final history = member['history'] ?? [];

    // Return empty state if no payments exist
    if (history.isEmpty) {
      return [
        const Text('No payment history available.',
            style: TextStyle(color: Colors.black54))
      ];
    }

    return [
      const SizedBox(height: 8),
      // Payment list container with subtle styling
      Container(
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: ListView.separated(
          shrinkWrap: true, // Prevent list from expanding infinitely
          physics:
              const NeverScrollableScrollPhysics(), // Disable scrolling for nested list
          itemCount: history.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.grey),
          itemBuilder: (context, index) {
            final payment = history[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // Payment type icon with colored background
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: DashboardTheme.accentColor.withOpacity(0.1),
                child: Icon(_getPaymentIcon(payment['type']),
                    color: DashboardTheme.accentColor, size: 20),
              ),
              title: Text(payment['type'] ?? 'Payment',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(payment['date'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              // Amount and paid status on the right
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Payment amount in green to indicate positive flow
                  Text(
                    '₱${(payment['amount'] as num).toDouble().toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 2),
                  // Status badge to clearly show payment is complete
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text('PAID',
                        style: TextStyle(
                            fontSize: 8,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }

  // === ICON SELECTION ===

  /// Maps payment types to appropriate icons for visual clarity
  static IconData _getPaymentIcon(String? paymentType) {
    switch (paymentType) {
      case 'Contribution Paid':
        return Icons.account_balance_wallet; // Regular contribution
      case 'Deficit Penalty Paid':
        return Icons.warning_rounded; // Penalty payment
      case 'Late Join Interest Paid':
        return Icons.access_time; // Late payment interest
      default:
        return Icons.payment; // Generic payment
    }
  }

  // === END OF ICON SELECTION ===

  // === FINANCIAL SUMMARY ===

  /// Builds summary cards showing key member financial metrics
  static List<Widget> buildSummaryCards(Map<String, dynamic> member) {
    // Extract financial values with null safety
    final contribution = (member['contribution'] as num).toDouble();
    final expectedReturn = (member['expectedReturn'] as num).toDouble();
    final deficitInterest = (member['deficitInterest'] ?? 0.0).toDouble();
    final lateJoinInterest = (member['lateJoinInterest'] ?? 0.0).toDouble();

    // Calculate derived values
    final totalInterest = deficitInterest + lateJoinInterest;
    var remaining = expectedReturn - contribution;
    if (remaining < 0) remaining = 0; // Prevent negative remaining

    return [
      // Row 1: Expected return and total contribution
      Row(children: [
        Expanded(
            child: _buildSummaryCard(
                'Expected Return',
                '₱${expectedReturn.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.blue)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSummaryCard(
                'Total Contribution',
                '₱${contribution.toStringAsFixed(2)}',
                Icons.payments,
                Colors.green)),
      ]),
      const SizedBox(height: 12),
      // Row 2: Remaining balance and total interest with dynamic colors
      Row(children: [
        Expanded(
            child: _buildSummaryCard(
                'Remaining Balance',
                '₱${remaining.toStringAsFixed(2)}',
                Icons.money_off,
                remaining > 0 ? Colors.orange : Colors.grey)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSummaryCard(
                'Total Interest',
                '₱${totalInterest.toStringAsFixed(2)}',
                Icons.percent,
                totalInterest > 0 ? Colors.red : Colors.grey)),
      ]),
    ];
  }

  /// Creates a styled summary card with icon, title, and value
  static Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Subtle background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          // Scale down value if it's too long
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color))),
        ],
      ),
    );
  }

  // === END OF FINANCIAL SUMMARY ===

  // === PENALTY MANAGEMENT ===

  /// Builds a penalty row with status indicator and payment option
  static Widget buildPenaltyRow({
    required String title,
    required dynamic amount,
    required BuildContext context,
    required StateSetter setState,
    required Map<String, dynamic> member,
    required Function(Map<String, dynamic>)? onUpdate,
    required String fieldType,
  }) {
    final amountValue = (amount as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      // Color coding: red for unpaid, green for paid
      decoration: BoxDecoration(
        color: amountValue > 0.01 ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: amountValue > 0.01
                ? Colors.red.shade200
                : Colors.green.shade200),
      ),
      child: Row(
        children: [
          // Penalty info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status icon and title
                Row(
                  children: [
                    Icon(
                        amountValue > 0.01
                            ? Icons.warning_rounded
                            : Icons.check_circle,
                        size: 16,
                        color: amountValue > 0.01
                            ? Colors.red.shade900
                            : Colors.green.shade900),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: amountValue > 0.01
                                    ? Colors.red.shade900
                                    : Colors.green.shade900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 4),
                // Penalty amount
                Text('₱${amountValue.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 16,
                        color: amountValue > 0.01
                            ? Colors.red.shade800
                            : Colors.green.shade800,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action section: pay button or checkmark
          if (amountValue > 0.01)
            // Show pay button for unpaid penalties
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0),
                onPressed: () => _showPaymentDialog(
                    context: context,
                    title: title,
                    amount: amountValue,
                    member: member,
                    setState: setState,
                    onUpdate: onUpdate,
                    fieldType: fieldType),
                child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Pay Now', style: TextStyle(fontSize: 12))),
              ),
            )
          else
            // Show checkmark for paid penalties
            const Expanded(
                child: Icon(Icons.check_circle, color: Colors.green, size: 24)),
        ],
      ),
    );
  }

  /// Shows confirmation dialog and processes penalty payment
  static void _showPaymentDialog({
    required BuildContext context,
    required String title,
    required double amount,
    required Map<String, dynamic> member,
    required StateSetter setState,
    required Function(Map<String, dynamic>)? onUpdate,
    required String fieldType,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay $title'),
        content: Text(
            'Confirm payment of ₱${amount.toStringAsFixed(2)}? This will clear this outstanding amount.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          // Process payment on confirmation
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              setState(() {
                // Record payment in history
                final history = member['history'] ?? [];
                history.add({
                  'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  'type': title,
                  'amount': amount,
                });
                member['history'] = history;

                // Clear the specific penalty field
                if (fieldType == 'deficitInterest') {
                  member['deficitInterest'] = 0.0;
                } else if (fieldType == 'lateJoinInterest') {
                  member['lateJoinInterest'] = 0.0;
                }

                // Recalculate total interest
                member['totalInterest'] = (member['deficitInterest'] ?? 0.0) +
                    (member['lateJoinInterest'] ?? 0.0);

                // Update member status based on payment completion
                final contribution = (member['contribution'] as num).toDouble();
                final expectedReturn =
                    (member['expectedReturn'] as num).toDouble();
                final totalInterest = member['totalInterest'] ?? 0.0;

                if (totalInterest <= 0.01) {
                  // No penalties left - check if fully paid
                  member['status'] = contribution >= (expectedReturn - 0.01)
                      ? 'Completed'
                      : 'With Balance';
                } else {
                  member['status'] = 'With Penalty'; // Still has penalties
                }
              });

              // Notify parent of changes
              if (onUpdate != null) onUpdate(member);

              // Show success feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        '₱${amount.toStringAsFixed(2)} paid successfully for $title!')),
              );
            },
            child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // === END OF PENALTY MANAGEMENT ===
}
