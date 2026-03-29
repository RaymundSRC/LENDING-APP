import 'package:flutter/material.dart';
import '../../../theme/dashboard_theme.dart';

class LoanPaymentHistory {
  static List<Widget> buildPaymentHistory(Map<String, dynamic> loan) {
    List history = loan['paymentHistory'] ?? [];

    if (history.isEmpty) {
      return [
        const Text(
          'No payment history available.',
          style: TextStyle(color: Colors.black54),
        )
      ];
    }

    return [
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.grey),
          itemBuilder: (context, index) {
            final payment = history[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: DashboardTheme.accentColor.withOpacity(0.1),
                child: const Icon(
                  Icons.payment,
                  color: DashboardTheme.accentColor,
                  size: 20,
                ),
              ),
              title: Text(
                payment['label'] ?? 'Payment',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment['date'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (payment['interestPortion'] != null &&
                      payment['principalPortion'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              'Interest: ₱${payment['interestPortion'].toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              'Principal: ₱${payment['principalPortion'].toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade800,
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
                    '₱${(payment['amount'] as num).toDouble().toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      'PAID',
                      style: TextStyle(
                          fontSize: 8,
                          color: Colors.green.shade800,
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

  static List<Widget> buildSummaryCards(Map<String, dynamic> loan) {
    double totalPaid = (loan['totalPaid'] as num?)?.toDouble() ?? 0.0;
    double originalAmount = (loan['amount'] as num).toDouble();
    double remainingPrincipal = (loan['remainingPrincipal'] as num).toDouble();
    double remainingInterest = (loan['remainingInterest'] as num).toDouble();

    return [
      Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Original Amount',
              '₱${originalAmount.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Total Paid',
              '₱${totalPaid.toStringAsFixed(2)}',
              Icons.payments,
              Colors.green,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Remaining Principal',
              '₱${remainingPrincipal.toStringAsFixed(2)}',
              Icons.money_off,
              remainingPrincipal > 0 ? Colors.orange : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Remaining Interest',
              '₱${remainingInterest.toStringAsFixed(2)}',
              Icons.percent,
              remainingInterest > 0 ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    ];
  }

  static Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
