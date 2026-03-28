import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/dashboard_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  double _baseCapital = 0;
  double _liquidCash = 0;
  double _activePrincipalOut = 0;
  double _totalHarvestedRevenue = 0;
  double _unpaidRiskAssets = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final members = await StorageService.loadMembers() ?? [];
    final loans = await StorageService.loadLoans() ?? [];

    _baseCapital = members.fold(0.0, (sum, item) => sum + ((item['contribution'] ?? 0.0) as num).toDouble());
    
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

    _totalHarvestedRevenue = paidLoanInterest + paidMemberPenalties;
    double totalFund = _baseCapital + _totalHarvestedRevenue;
    
    _activePrincipalOut = loans.fold(0.0, (sum, l) => sum + ((l['remainingPrincipal'] ?? 0.0) as num).toDouble());
    _liquidCash = totalFund - _activePrincipalOut;

    double unpaidLoanInterest = loans.fold(0.0, (sum, item) => sum + ((item['remainingInterest'] ?? 0.0) as num).toDouble());
    double unpaidMemberPenalties = members.fold(0.0, (sum, item) {
      double totalInt = (item['deficitInterest'] ?? 0.0) + (item['lateJoinInterest'] ?? 0.0);
      return sum + totalInt;
    });
    
    _unpaidRiskAssets = unpaidLoanInterest + unpaidMemberPenalties;

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _exportReport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compiling internal structural ₱type Report...')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: DashboardTheme.accentColor));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Financial Integrity Report', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Comprehensive overview of macro capital utilization and total generated yields.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildLargeKPI('Total Net Revenue', '₱${_totalHarvestedRevenue.toStringAsFixed(2)}', Icons.diamond, Colors.amber.shade700)),
                const SizedBox(width: 12),
                Expanded(child: _buildLargeKPI('Unpaid Assets', '₱${_unpaidRiskAssets.toStringAsFixed(2)}', Icons.warning_amber_rounded, Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Capital Distribution Model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStatBar('Base Capital (Core Member Shares)', '₱${_baseCapital.toStringAsFixed(2)}'),
            _buildStatBar('Deployed Principal (Out on Loan)', '₱${_activePrincipalOut.toStringAsFixed(2)}'),
            _buildStatBar('Vault Liquidity (Actual Held Cash)', '₱${_liquidCash.toStringAsFixed(2)}'),
            const SizedBox(height: 24),
            const Text('Actionable Exports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: const Text('Generate Formal PDF Portfolio', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Produces a structured executive ledger.'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _exportReport('PDF'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.table_chart, color: Colors.green),
                    title: const Text('Export Raw CSV Data', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Produces raw spreadsheet matrices.'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _exportReport('CSV'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeKPI(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.withOpacity(0.8)))),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color))),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87))),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
