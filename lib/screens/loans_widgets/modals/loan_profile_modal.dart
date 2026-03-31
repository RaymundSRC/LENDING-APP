import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/dashboard_theme.dart';
import '../../../services/storage_service.dart';
import '../components/loan_payment_history.dart';
import '../components/loan_interest_breakdown.dart';
import 'record_loan_payment_modal.dart';

/// Modal for displaying comprehensive loan profile information
class LoanProfileModal {
  /// Shows loan profile modal with full loan details and actions
  static void show(BuildContext context, Map<String, dynamic> loan,
      {Function? onUpdate}) {
    // onUpdate callback for UI refresh
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow scrolling when keyboard appears
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(24))), // Rounded top corners
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              expand: false, // Don't expand to full screen
              initialChildSize: 0.85, // Initial height (85% of screen)
              minChildSize: 0.5, // Minimum height (50% of screen)
              maxChildSize: 0.95, // Maximum height (95% of screen)
              builder: (context, scrollController) {
                // Determine status color based on loan status
                Color statusColor;
                switch (loan['status']) {
                  case 'Active':
                    statusColor = Colors.green; // Green for active loans
                    break;
                  case 'Completed':
                    statusColor = Colors.blue; // Blue for completed loans
                    break;
                  case 'Pending':
                    statusColor = Colors.orange; // Orange for pending loans
                    break;
                  case 'Late':
                    statusColor = Colors.red; // Red for late loans
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                int missed = (loan['missedMonths'] as num?)?.toInt() ?? 0;
                String intLabel =
                    missed > 1 ? 'Interest ($missed Mos)' : 'Monthly Interest';

                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4)))),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${loan['borrower'] ?? 'Unknown'}\'s Loan',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                Text('ID: ${loan['id'] ?? '-'}',
                                    style:
                                        const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          Chip(
                              label: Text(loan['status'] ?? 'Active'),
                              backgroundColor: statusColor.withOpacity(0.1),
                              labelStyle: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold),
                              side: BorderSide.none),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: DashboardTheme.accentColor),
                            onPressed: () => _showEditPrincipalDialog(
                                context, setState, loan, onUpdate),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Summary Cards
                      ...LoanPaymentHistory.buildSummaryCards(loan),
                      const SizedBox(height: 24),

                      // Interest Breakdown Section
                      Text(intLabel,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Current Interest:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                    '₱${(loan['remainingInterest'] as num).toDouble().toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.red)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.analytics),
                                label: const Text('View Interest Breakdown'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DashboardTheme.accentColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () =>
                                    LoanInterestBreakdown.show(context, loan),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Payment Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.payment),
                              label: const Text('Record Payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                RecordLoanPaymentModal.show(context, loan,
                                    onUpdate: onUpdate);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Payment History
                      const Text('Payment History',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      ...LoanPaymentHistory.buildPaymentHistory(loan),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static void _showEditPrincipalDialog(BuildContext context,
      StateSetter setState, Map<String, dynamic> loan, Function? onUpdate) {
    TextEditingController controller =
        TextEditingController(text: loan['amount'].toString());
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Edit Base Loan Amount'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Enter the new updated total Base Capital for this loan. Any previous active payments made will be identically mathematically preserved.',
                        style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'New Amount (₱)',
                          prefixText: '₱ ',
                          border: OutlineInputBorder()),
                    )
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: DashboardTheme.accentColor),
                  onPressed: () async {
                    double? newAmount = double.tryParse(controller.text);
                    if (newAmount == null || newAmount <= 0) return;

                    Navigator.pop(ctx);

                    double oldAmount = (loan['amount'] as num).toDouble();
                    double oldRemaining =
                        (loan['remainingPrincipal'] as num).toDouble();
                    double principalDelta = newAmount - oldAmount;
                    double newRemaining = oldRemaining + principalDelta;
                    if (newRemaining < 0) newRemaining = 0.0;

                    loan['amount'] = newAmount;
                    loan['remainingPrincipal'] = newRemaining;

                    List loans = await StorageService.loadLoans() ?? [];
                    int index = loans.indexWhere((l) => l['id'] == loan['id']);
                    if (index != -1) {
                      loans[index]['amount'] = newAmount;
                      loans[index]['remainingPrincipal'] = newRemaining;

                      // Aggressive implicit recalculate
                      double totalInterestOwed = 0.0;
                      DateTime currentCycle =
                          DateFormat('MMM dd, yyyy').parse(loan['dueDate']);
                      DateTime todayMidnight = DateTime(DateTime.now().year,
                          DateTime.now().month, DateTime.now().day);
                      Map<String, dynamic> customR = loan['customRates'] != null
                          ? Map<String, dynamic>.from(loan['customRates'])
                          : {};

                      while (todayMidnight.isAfter(currentCycle) ||
                          currentCycle.isAtSameMomentAs(todayMidnight)) {
                        String key =
                            DateFormat('MMM dd, yyyy').format(currentCycle);
                        double rate = 0.10;
                        DateTime penaltyDateLimit =
                            currentCycle.add(const Duration(days: 5));
                        bool penalty = todayMidnight
                                .isAfter(penaltyDateLimit) ||
                            todayMidnight.isAtSameMomentAs(penaltyDateLimit);

                        if (customR.containsKey(key)) {
                          rate = (customR[key] as num).toDouble();
                        } else if (penalty) {
                          rate = 0.15;
                        }
                        totalInterestOwed += newRemaining * rate;
                        currentCycle = DateTime(currentCycle.year,
                            currentCycle.month + 1, currentCycle.day);
                      }

                      loans[index]['remainingInterest'] =
                          double.parse(totalInterestOwed.toStringAsFixed(2));
                      loan['remainingInterest'] =
                          loans[index]['remainingInterest'];

                      await StorageService.saveLoans(
                          loans.cast<Map<String, dynamic>>());
                      if (onUpdate != null) onUpdate();
                      setState(() {});
                    }
                  },
                  child: const Text('Update',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ));
  }
}
