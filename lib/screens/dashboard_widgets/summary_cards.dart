import 'package:flutter/material.dart';
import '../../theme/dashboard_theme.dart';

class SummaryCards extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> loans;
  const SummaryCards({super.key, required this.members, required this.loans});

  @override
  Widget build(BuildContext context) {
    double baseCapital = members.fold(0.0,
        (sum, item) => sum + ((item['contribution'] ?? 0.0) as num).toDouble());
    double totalLoans = loans.fold(
        0.0, (sum, item) => sum + ((item['amount'] ?? 0.0) as num).toDouble());

    double targetFund = members.fold(
        0.0,
        (sum, item) =>
            sum + ((item['expectedReturn'] ?? 0.0) as num).toDouble());
    double pending = targetFund - baseCapital;
    if (pending < 0) pending = 0;

    double paidLoanInterest = loans.fold(0.0, (sum, l) {
      double upfrontDeduction = ((l['amount'] ?? 0.0) as num).toDouble() * 0.10;

      List history = l['paymentHistory'] ?? [];
      double pInt = history.fold(
          0.0,
          (hSum, hItem) =>
              hSum + ((hItem['interestPortion'] ?? 0.0) as num).toDouble());
      return sum + pInt + upfrontDeduction;
    });
    double unpaidLoanInterest = loans.fold(
        0.0,
        (sum, item) =>
            sum + ((item['remainingInterest'] ?? 0.0) as num).toDouble());
    double totalGeneratedInterest = paidLoanInterest + unpaidLoanInterest;

    double paidMemberPenalties = members.fold(0.0, (sum, m) {
      List history = m['history'] ?? [];
      double pPen = history
          .where((h) => h['type'].toString().contains('Penalty Paid'))
          .fold(
              0.0,
              (hSum, hItem) =>
                  hSum + ((hItem['amount'] ?? 0.0) as num).toDouble());
      return sum + pPen;
    });

    double unpaidMemberPenalties = members.fold(0.0, (sum, item) {
      double totalInt =
          (item['deficitInterest'] ?? 0.0) + (item['lateJoinInterest'] ?? 0.0);
      return sum + totalInt;
    });

    double generatedMemberPenalties =
        paidMemberPenalties + unpaidMemberPenalties;

    double totalFund = baseCapital + paidLoanInterest + paidMemberPenalties;

    double activePrincipalOut = loans.fold(0.0,
        (sum, l) => sum + ((l['remainingPrincipal'] ?? 0.0) as num).toDouble());
    double netLiquidCash = totalFund - activePrincipalOut;

    // Available Fund calculation - money actually available for new loans
    double availableFund = baseCapital - activePrincipalOut;

    // Determine fund status color and percentage
    Color fundStatusColor = availableFund > 10000
        ? Colors.green
        : availableFund > 5000
            ? Colors.orange
            : Colors.red;
    double fundPercentage =
        baseCapital > 0 ? (availableFund / baseCapital) * 100 : 0;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _summaryCard('Total Fund', '₱${totalFund.toStringAsFixed(2)}',
              Icons.account_balance, DashboardTheme.accentColor, true),
        ),
        const SizedBox(height: 12),
        // Make Available Cash the main prominent card
        SizedBox(
          width: double.infinity,
          child: _buildAvailableCashCard(
              availableFund, fundPercentage, fundStatusColor),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _summaryCard(
                    'Total Loans Out',
                    '₱${totalLoans.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.teal)),
            const SizedBox(width: 12),
            Expanded(
                child: _summaryCard('Target Returns',
                    '₱${targetFund.toStringAsFixed(2)}', Icons.trending_up)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _summaryCard(
                    'Vault Liquid Cash',
                    '₱${netLiquidCash.toStringAsFixed(2)}',
                    Icons.savings,
                    Colors.blueGrey)),
            const SizedBox(width: 12),
            Expanded(
                child: _summaryCard(
                    'Unpaid Balances',
                    '₱${pending.toStringAsFixed(2)}',
                    Icons.pending_actions,
                    Colors.blueGrey)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _summaryCard(
                    'Generated Interest',
                    '₱${totalGeneratedInterest.toStringAsFixed(2)}',
                    Icons.payments,
                    Colors.orange)),
            const SizedBox(width: 12),
            Expanded(
                child: _summaryCard(
                    'Generated Penalties',
                    '₱${generatedMemberPenalties.toStringAsFixed(2)}',
                    Icons.gavel,
                    Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _summaryCard(
                    'Paid Interest',
                    '₱${paidLoanInterest.toStringAsFixed(2)}',
                    Icons.check_circle_outline,
                    Colors.lightGreen)),
            const SizedBox(width: 12),
            Expanded(
                child: _summaryCard(
                    'Paid Penalties',
                    '₱${paidMemberPenalties.toStringAsFixed(2)}',
                    Icons.check_circle_outline,
                    Colors.lightGreen)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _summaryCard(
                    'Unpaid Interest',
                    '₱${unpaidLoanInterest.toStringAsFixed(2)}',
                    Icons.hourglass_bottom,
                    Colors.deepOrange)),
            const SizedBox(width: 12),
            Expanded(
                child: _summaryCard(
                    'Overdue Penalties',
                    '₱${unpaidMemberPenalties.toStringAsFixed(2)}',
                    Icons.warning_amber_rounded,
                    Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon,
      [Color? color, bool isLarge = false]) {
    final c = color ?? DashboardTheme.accentColor;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: isLarge ? 24.0 : 16.0, horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: isLarge ? 36 : 28),
            const SizedBox(height: 8),
            Text(
              title,
              style:
                  TextStyle(fontSize: isLarge ? 14 : 11, color: Colors.black54),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                    fontSize: isLarge ? 28 : 18,
                    fontWeight: FontWeight.bold,
                    color: c),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCashCard(
      double availableFund, double percentage, Color statusColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.account_balance_wallet,
                            color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Cash',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}% of capital',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      availableFund > 0 ? 'Available' : 'Insufficient',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₱${availableFund.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  // Status indicator
                  Container(
                    width: 60,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.shade300,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (percentage / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
