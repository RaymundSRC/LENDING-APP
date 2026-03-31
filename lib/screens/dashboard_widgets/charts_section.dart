import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Charts section widget for dashboard
/// Displays fund distribution pie chart and monthly collections line chart
class ChartsSection extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> loans;
  const ChartsSection({super.key, required this.members, required this.loans});

  // === FINANCIAL CALCULATIONS ===

  @override
  Widget build(BuildContext context) {
    // Calculate base capital from member contributions
    double baseCapital = members.fold(0.0,
        (sum, item) => sum + ((item['contribution'] ?? 0.0) as num).toDouble());

    // Calculate paid loan interest including upfront deductions
    double paidLoanInterest = loans.fold(0.0, (sum, l) {
      double upfrontDeduction =
          ((l['amount'] ?? 0.0) as num).toDouble() * 0.10; // 10% upfront
      List history = l['paymentHistory'] ?? [];
      double pInt = history.fold(
          0.0,
          (hSum, hItem) =>
              hSum + ((hItem['interestPortion'] ?? 0.0) as num).toDouble());
      return sum + pInt + upfrontDeduction;
    });

    // Calculate paid member penalties from payment history
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

    // Total fund includes capital + paid interest + paid penalties
    double totalFund = baseCapital + paidLoanInterest + paidMemberPenalties;

    // Active principal still outstanding in loans
    double activePrincipalOut = loans.fold(0.0,
        (sum, l) => sum + ((l['remainingPrincipal'] ?? 0.0) as num).toDouble());

    // Liquid cash available after accounting for active loans
    double liquidCash = totalFund - activePrincipalOut;

    // Calculate target fund and pending contributions
    double targetFund = members.fold(
        0.0,
        (sum, item) =>
            sum + ((item['expectedReturn'] ?? 0.0) as num).toDouble());
    double pendingTarget = targetFund - baseCapital;
    if (pendingTarget < 0) pendingTarget = 0; // Prevent negative values

    // Calculate unpaid revenue (interest + penalties)
    double unpaidLoanInterest = loans.fold(
        0.0,
        (sum, item) =>
            sum + ((item['remainingInterest'] ?? 0.0) as num).toDouble());
    double unpaidMemberPenalties = members.fold(0.0, (sum, item) {
      double totalInt =
          (item['deficitInterest'] ?? 0.0) + (item['lateJoinInterest'] ?? 0.0);
      return sum + totalInt;
    });

    // Total pending assets include unpaid contributions, interest, and penalties
    double totalPendingAssets =
        pendingTarget + unpaidLoanInterest + unpaidMemberPenalties;

    // Calculate total assets for percentage distribution
    double totalMacro = liquidCash + activePrincipalOut + totalPendingAssets;
    if (totalMacro == 0) totalMacro = 1; // Prevent division by zero

    // Calculate percentage distribution for pie chart
    double liquidPct = (liquidCash / totalMacro) * 100;
    double activeLoansPct = (activePrincipalOut / totalMacro) * 100;
    double pendingAssetsPct = (totalPendingAssets / totalMacro) * 100;

    // === MONTHLY DATA CALCULATION ===

    // Initialize monthly data array for current year
    List<double> monthlyData = List.filled(12, 0.0);
    int currentYear = DateTime.now().year;

    // Process member payment history for monthly collections
    for (var m in members) {
      List history = m['history'] ?? [];
      for (var h in history) {
        try {
          // Parse date from history entry
          DateTime dt = DateFormat('MMM dd, yyyy').parse(h['date']);
          // Check if date is within current year
          if (dt.year == currentYear) {
            // Add amount to corresponding month in monthly data
            monthlyData[dt.month - 1] +=
                ((h['amount'] ?? 0.0) as num).toDouble();
          }
        } catch (_) {} // Skip invalid dates
      }
    }

    // Process loan payment history for monthly collections
    for (var l in loans) {
      List history = l['paymentHistory'] ?? [];
      for (var h in history) {
        try {
          // Parse date from history entry
          DateTime dt = DateFormat('MMM dd, yyyy').parse(h['date']);
          // Check if date is within current year
          if (dt.year == currentYear) {
            // Extract principal and interest portions
            double p = ((h['principalPortion'] ?? 0.0) as num).toDouble();
            double i = ((h['interestPortion'] ?? 0.0) as num).toDouble();
            // Add both principal and interest to corresponding month in monthly data
            monthlyData[dt.month - 1] += (p + i);
          }
        } catch (_) {} // Skip invalid dates
      }

      // Add upfront deductions from new loans
      try {
        // Parse date from loan entry
        DateTime dt = DateFormat('MMM dd, yyyy').parse(l['date']);
        // Check if date is within current year
        if (dt.year == currentYear) {
          // Calculate upfront deduction (10% of loan amount)
          double updeduct = ((l['amount'] ?? 0.0) as num).toDouble() * 0.10;
          // Add upfront deduction to corresponding month in monthly data
          monthlyData[dt.month - 1] += updeduct;
        }
      } catch (_) {} // Skip invalid dates
    }

    // === CHART DATA PREPARATION ===

    // Prepare line chart data points
    List<FlSpot> spots = [];
    double maxCollection = 100.0; // Minimum baseline
    for (int i = 0; i < 12; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyData[i]));
      if (monthlyData[i] > maxCollection) maxCollection = monthlyData[i];
    }
    double chartMaxY = maxCollection * 1.2; // Add 20% padding to top

    // === CHARTS UI LAYOUT ===

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fund Distribution Pie Chart
        const Text('Fund Distribution',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2, // Space between pie sections
              centerSpaceRadius: 40, // Donut hole size
              sections: members.isEmpty && loans.isEmpty
                  ? [
                      // Empty state when no data available
                      PieChartSectionData(
                          color: Colors.grey.shade300,
                          value: 100,
                          title: 'No Data',
                          radius: 50,
                          titleStyle: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))
                    ]
                  : [
                      // Liquid cash section
                      if (liquidPct > 0)
                        PieChartSectionData(
                            color: Colors.green,
                            value: liquidPct,
                            title:
                                'Vault Cash\n${liquidPct.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      // Active loans section
                      if (activeLoansPct > 0)
                        PieChartSectionData(
                            color: Colors.teal,
                            value: activeLoansPct,
                            title:
                                'Loans Out\n${activeLoansPct.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      // Pending assets section
                      if (pendingAssetsPct > 0)
                        PieChartSectionData(
                            color: Colors.orange,
                            value: pendingAssetsPct,
                            title:
                                'Pending\n${pendingAssetsPct.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                    ],
            ),
          ),
        ),
        const SizedBox(height: 48),

        // Monthly Collections Line Chart
        const Text('Monthly Collections & Growth',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              // Grid configuration
              gridData: const FlGridData(show: true, drawVerticalLine: false),

              // Chart titles and labels
              titlesData: FlTitlesData(
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),

                // Bottom axis (month labels)
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = [
                        'Jan',
                        'Feb',
                        'Mar',
                        'Apr',
                        'May',
                        'Jun',
                        'Jul',
                        'Aug',
                        'Sep',
                        'Oct',
                        'Nov',
                        'Dec'
                      ];
                      if (value.toInt() >= 0 && value.toInt() < 12) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(months[value.toInt()],
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black54)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 22, // Space for month labels
                    interval: 1,
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),

              // Chart border styling
              borderData: FlBorderData(
                  show: true,
                  border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 2),
                      left: BorderSide(color: Colors.grey.shade300, width: 2))),

              // Y-axis range
              minY: 0,
              maxY: chartMaxY,

              // Line chart data
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true, // Smooth curve line
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false), // Hide data points
                  belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green
                          .withOpacity(0.1) // Subtle fill under line
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // === END OF CHARTS UI LAYOUT ===
}
