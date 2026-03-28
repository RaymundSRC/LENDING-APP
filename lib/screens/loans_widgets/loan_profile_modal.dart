import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/dashboard_theme.dart';
import '../../services/storage_service.dart';
import 'record_loan_payment_modal.dart';

class LoanProfileModal {
  static DateTime _addOneMonth(DateTime date) {
    int nextYear = date.year;
    int nextMonth = date.month + 1;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    int maxDays = DateTime(nextYear, nextMonth + 1, 0).day;
    int nextDay = date.day > maxDays ? maxDays : date.day;
    return DateTime(nextYear, nextMonth, nextDay);
  }

  static void _showInterestBreakdown(BuildContext context, Map<String, dynamic> loan) {
    double principal = (loan['remainingPrincipal'] as num).toDouble();
    double displayPrincipal = principal > 0 ? principal : (loan['amount'] as num).toDouble();

    DateTime cycleDate = DateFormat('MMM dd, yyyy').parse(loan['dueDate']);
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    List<Widget> breakdownWidgets = [];

    int i = 1;
    Map<String, dynamic> customRates = loan['customRates'] != null ? Map<String, dynamic>.from(loan['customRates']) : {};

    while (today.isAfter(cycleDate) || cycleDate.isAtSameMomentAs(today)) {
      DateTime cyclePenaltyDate = cycleDate.add(const Duration(days: 5));
      String cycleKey = DateFormat('MMM dd, yyyy').format(cycleDate);
      
      bool isPenalty = today.isAfter(cyclePenaltyDate) || today.isAtSameMomentAs(cyclePenaltyDate);
      double rate = isPenalty ? 0.15 : 0.10;
      bool isForgiven = false;
      
      if (customRates.containsKey(cycleKey)) {
         rate = (customRates[cycleKey] as num).toDouble();
         if (rate <= 0.10 && isPenalty) isForgiven = true;
      }
      
      double cost = displayPrincipal * rate;

      breakdownWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cycle $i: ${DateFormat('MMM dd, yyyy').format(cycleDate)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (isForgiven)
                        Text('Manually Forgiven to 10%', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold))
                    else
                        Text(isPenalty ? 'Passed Grace Period on ${DateFormat('MMM dd').format(cyclePenaltyDate)} (15%)' : 'Active Grace Period til ${DateFormat('MMM dd').format(cyclePenaltyDate)} (10%)', style: TextStyle(fontSize: 12, color: isPenalty ? Colors.red : Colors.orange)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('₱${cost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
      
      cycleDate = _addOneMonth(cycleDate);
      i++;
    }

    // Explicit Upcoming Interest Projection Banner
    DateTime upcomingPenaltyDate = cycleDate.add(const Duration(days: 5));
    double upcomingCost = displayPrincipal * 0.10;
    double upcomingCost15 = displayPrincipal * 0.15;
    
    breakdownWidgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade900),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Upcoming Interest Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: Text('10% Start (Due Date):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87))),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(DateFormat('MMM dd, yyyy').format(cycleDate), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                              Text('+₱${upcomingCost.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 14)),
                            ],
                          )
                        ],
                     ),
                     const Divider(height: 16),
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: Text('15% Late Lock:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87))),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(DateFormat('MMM dd, yyyy').format(upcomingPenaltyDate), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                              Text('+₱${upcomingCost15.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
                            ],
                          )
                        ],
                     ),
                  ]
                )
              )
            ],
          ),
        ),
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.analytics, color: DashboardTheme.accentColor), SizedBox(width: 8), Text('Interest Breakdown', style: TextStyle(fontSize: 18))]),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Here is exactly how the un-liquidated interest fees were geometrically summed across each missed monthly cycle boundary:', style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: breakdownWidgets,
                  ),
                ),
              ),
              const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Remaining Unpaid Balance:', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Text('₱${(loan['remainingInterest'] as num).toDouble().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: DashboardTheme.accentColor)),
              ],
            )
          ],
        ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close Ledger'))
        ],
      )
    );
  }

  static void _showEditPrincipalDialog(BuildContext context, StateSetter mappedSetState, Map<String, dynamic> localLoan, Function? globalOnUpdate) {
      TextEditingController controller = TextEditingController(text: localLoan['amount'].toString());
      showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Edit Base Loan Amount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text('Enter the new updated total Base Capital for this loan. Any previous active payments made will be identically mathematically preserved.', style: TextStyle(fontSize: 13, color: Colors.black54)),
               const SizedBox(height: 16),
               TextField(
                   controller: controller,
                   keyboardType: TextInputType.number,
                   decoration: const InputDecoration(labelText: 'New Amount (₱)', prefixText: '₱ ', border: OutlineInputBorder()),
               )
            ]
          ),
          actions: [
             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
             ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: DashboardTheme.accentColor),
                onPressed: () async {
                   double? newAmount = double.tryParse(controller.text);
                   if (newAmount == null || newAmount <= 0) return;
                   
                   Navigator.pop(ctx);
                   
                   double oldAmount = (localLoan['amount'] as num).toDouble();
                   double oldRemaining = (localLoan['remainingPrincipal'] as num).toDouble();
                   double principalDelta = newAmount - oldAmount;
                   double newRemaining = oldRemaining + principalDelta;
                   if (newRemaining < 0) newRemaining = 0.0;
                   
                   localLoan['amount'] = newAmount;
                   localLoan['remainingPrincipal'] = newRemaining;
                   
                   List loans = await StorageService.loadLoans() ?? [];
                   int index = loans.indexWhere((l) => l['id'] == localLoan['id']);
                   if (index != -1) {
                       loans[index]['amount'] = newAmount;
                       loans[index]['remainingPrincipal'] = newRemaining;
                       
                       // Agressive implicit recalculate
                       double totalInterestOwed = 0.0;
                       DateTime currentCycle = DateFormat('MMM dd, yyyy').parse(localLoan['dueDate']);
                       DateTime todayMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                       Map<String, dynamic> customR = localLoan['customRates'] != null ? Map<String, dynamic>.from(localLoan['customRates']) : {};
                       
                       while (todayMidnight.isAfter(currentCycle) || currentCycle.isAtSameMomentAs(todayMidnight)) {
                         String key = DateFormat('MMM dd, yyyy').format(currentCycle);
                         double rate = 0.10;
                         DateTime penaltyDateLimit = currentCycle.add(const Duration(days: 5));
                         bool penalty = todayMidnight.isAfter(penaltyDateLimit) || todayMidnight.isAtSameMomentAs(penaltyDateLimit);
                         
                         if (customR.containsKey(key)) {
                             rate = (customR[key] as num).toDouble();
                         } else if (penalty) {
                             rate = 0.15;
                         }
                         totalInterestOwed += newRemaining * rate;
                         currentCycle = DateTime(currentCycle.year, currentCycle.month + 1, currentCycle.day);
                       }
                       
                       loans[index]['remainingInterest'] = double.parse(totalInterestOwed.toStringAsFixed(2));
                       localLoan['remainingInterest'] = loans[index]['remainingInterest'];
                       
                       await StorageService.saveLoans(loans.cast<Map<String, dynamic>>());
                       if (globalOnUpdate != null) globalOnUpdate();
                       mappedSetState(() {});
                       
                       if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Principal structurally mutated successfully!'), backgroundColor: Colors.green));
                   }
                },
                child: const Text('Update Amount', style: TextStyle(color: Colors.white)),
             )
          ]
      ));
  }

  static void show(BuildContext context, Map<String, dynamic> loan, {Function? onUpdate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                Color statusColor;
                switch (loan['status']) {
                  case 'Active': statusColor = Colors.green; break;
                  case 'Completed': statusColor = Colors.blue; break;
                  case 'Pending': statusColor = Colors.orange; break;
                  case 'Late': statusColor = Colors.red; break;
                  default: statusColor = Colors.grey;
                }

                int missed = (loan['missedMonths'] as num?)?.toInt() ?? 0;
                String intLabel = missed > 1 ? 'Interest ($missed Mos)' : 'Monthly Interest';
                
                List payments = loan['paymentHistory'] ?? [];

                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${loan['borrower'] ?? 'Unknown'}\'s Loan', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                Text('ID: ${loan['id'] ?? '-'}', style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          Chip(label: Text(loan['status'] ?? 'Active'), backgroundColor: statusColor.withOpacity(0.1), labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold), side: BorderSide.none),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showEditPrincipalDialog(context, setState, loan, onUpdate),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildModalStatCard('Principal', '₱${loan['remainingPrincipal'] ?? 0}')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildModalStatCard(intLabel, '₱${loan['remainingInterest'] ?? 0}', statusColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildModalStatCard('Base Debt', '₱${loan['amount'] ?? 0}', Colors.black54)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildModalStatCard('Total Paid', '₱${loan['totalPaid'] ?? 0}', Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: Colors.blue),
                    title: const Text('Borrowed On'),
                    trailing: Text(loan['borrowedDate'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.event_busy, color: statusColor),
                    title: const Text('Next Due Date'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          missed > 1 ? '${loan['dueDate'] ?? '-'} ($missed Mos)' : (loan['dueDate'] ?? '-'),
                          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.info_outline, size: 16, color: statusColor),
                      ],
                    ),
                    onTap: () => _showInterestBreakdown(context, loan),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.percent, color: Colors.orange),
                    title: const Text('Computed Interst Rate'),
                    trailing: Text(loan['interestRate'] ?? '10%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (payments.isEmpty)
                    const Text('No payments recorded yet.', style: TextStyle(color: Colors.black54))
                  else
                    ...payments.map((h) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(h['date'] ?? ''),
                      trailing: Text('+₱${h['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    )),
                  
                  if (loan['status'] != 'Completed') ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: DashboardTheme.accentColor, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          Navigator.pop(context);
                          RecordLoanPaymentModal.show(context, loan, onUpdate: onUpdate);
                        },
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: const Text('Record Payment', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
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

  static Widget _buildModalStatCard(String title, String value, [Color color = Colors.black87]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
