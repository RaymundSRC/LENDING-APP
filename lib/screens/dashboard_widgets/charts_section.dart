import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ChartsSection extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> loans;
  const ChartsSection({super.key, required this.members, required this.loans});

  @override
  Widget build(BuildContext context) {
    double baseCapital = members.fold(0.0, (sum, item) => sum + ((item['contribution'] ?? 0.0) as num).toDouble());
    
    double paidLoanInterest = loans.fold(0.0, (sum, l) {
      double upfrontDeduction = ((l['amount'] ?? 0.0) as num).toDouble() * 0.10;
      List history = l['paymentHistory'] ?? [];
      double pInt = history.fold(0.0, (hSum, hItem) => hSum + ((hItem['interestPortion'] ?? 0.0) as num).toDouble());
      return sum + pInt + upfrontDeduction;
    });
    
    double paidMemberPenalties = members.fold(0.0, (sum, m) {
      List history = m['history'] ?? [];
      double pPen = history.where((h) => h['type'].toString().contains('Penalty Paid')).fold(0.0, (hSum, hItem) => hSum + ((hItem['amount'] ?? 0.0) as num).toDouble());
      return sum + pPen;
    });

    double totalFund = baseCapital + paidLoanInterest + paidMemberPenalties;
    double activePrincipalOut = loans.fold(0.0, (sum, l) => sum + ((l['remainingPrincipal'] ?? 0.0) as num).toDouble());
    double liquidCash = totalFund - activePrincipalOut;
    
    double targetFund = members.fold(0.0, (sum, item) => sum + ((item['expectedReturn'] ?? 0.0) as num).toDouble());
    double pendingTarget = targetFund - baseCapital;
    if (pendingTarget < 0) pendingTarget = 0;
    
    double unpaidLoanInterest = loans.fold(0.0, (sum, item) => sum + ((item['remainingInterest'] ?? 0.0) as num).toDouble());
    double unpaidMemberPenalties = members.fold(0.0, (sum, item) {
      double totalInt = (item['deficitInterest'] ?? 0.0) + (item['lateJoinInterest'] ?? 0.0);
      return sum + totalInt;
    });
    
    double totalPendingAssets = pendingTarget + unpaidLoanInterest + unpaidMemberPenalties;

    double totalMacro = liquidCash + activePrincipalOut + totalPendingAssets;
    if (totalMacro == 0) totalMacro = 1;

    double liquidPct = (liquidCash / totalMacro) * 100;
    double activeLoansPct = (activePrincipalOut / totalMacro) * 100;
    double pendingAssetsPct = (totalPendingAssets / totalMacro) * 100;
    
    List<double> monthlyData = List.filled(12, 0.0);
    int currentYear = DateTime.now().year;
    
    for (var m in members) {
      List history = m['history'] ?? [];
      for (var h in history) {
        try {
          DateTime dt = DateFormat('MMM dd, yyyy').parse(h['date']);
          if (dt.year == currentYear) {
            monthlyData[dt.month - 1] += ((h['amount'] ?? 0.0) as num).toDouble();
          }
        } catch (_) {}
      }
    }
    
    for (var l in loans) {
      List history = l['paymentHistory'] ?? [];
      for (var h in history) {
        try {
          DateTime dt = DateFormat('MMM dd, yyyy').parse(h['date']);
          if (dt.year == currentYear) {
            double p = ((h['principalPortion'] ?? 0.0) as num).toDouble();
            double i = ((h['interestPortion'] ?? 0.0) as num).toDouble();
            monthlyData[dt.month - 1] += (p + i);
          }
        } catch (_) {}
      }
      try {
        DateTime dt = DateFormat('MMM dd, yyyy').parse(l['date']);
        if (dt.year == currentYear) {
           double updeduct = ((l['amount'] ?? 0.0) as num).toDouble() * 0.10;
           monthlyData[dt.month - 1] += updeduct;
        }
      } catch (_) {}
    }

    List<FlSpot> spots = [];
    double maxCollection = 100.0;
    for (int i = 0; i < 12; i++) {
        spots.add(FlSpot(i.toDouble(), monthlyData[i]));
        if (monthlyData[i] > maxCollection) maxCollection = monthlyData[i];
    }
    double chartMaxY = maxCollection * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fund Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: members.isEmpty && loans.isEmpty ? [
                PieChartSectionData(color: Colors.grey.shade300, value: 100, title: 'No Data', radius: 50, titleStyle: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold))
              ] : [
                if (liquidPct > 0) PieChartSectionData(color: Colors.green, value: liquidPct, title: 'Vault Cash\n${liquidPct.toStringAsFixed(0)}%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                if (activeLoansPct > 0) PieChartSectionData(color: Colors.teal, value: activeLoansPct, title: 'Loans Out\n${activeLoansPct.toStringAsFixed(0)}%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                if (pendingAssetsPct > 0) PieChartSectionData(color: Colors.orange, value: pendingAssetsPct, title: 'Pending\n${pendingAssetsPct.toStringAsFixed(0)}%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
        const Text('Monthly Collections & Growth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      if (value.toInt() >= 0 && value.toInt() < 12) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(months[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.black54)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 22,
                    interval: 1,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2), left: BorderSide(color: Colors.grey.shade300, width: 2))),
              minY: 0,
              maxY: chartMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
