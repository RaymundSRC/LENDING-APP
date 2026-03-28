import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/dashboard_theme.dart';

class MemberProfileModal {
  static void show(BuildContext context, Map<String, dynamic> member, {Function(Map<String, dynamic>)? onUpdate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setState) {
                double totalInt = (member['deficitInterest'] ?? 0.0) + (member['lateJoinInterest'] ?? 0.0);
                double cont = (member['contribution'] as num).toDouble();
                double exp = (member['expectedReturn'] as num).toDouble();
                double remaining = exp - cont;
                if (remaining < 0) remaining = 0;
                
                String displayStatus = member['status'] == 'Active' ? 'With Balance' : member['status'];
                if (displayStatus != 'Pending') {
                  if (cont >= (exp - 0.01) && totalInt <= 0.01) {
                    displayStatus = 'Completed';
                  } else if (totalInt > 0.01) {
                    displayStatus = 'With Penalty';
                  } else {
                    displayStatus = 'With Balance';
                  }
                }
                
                Color statusColor = displayStatus == 'With Balance' ? Colors.green : (displayStatus == 'Pending' ? Colors.orange : (displayStatus == 'With Penalty' ? Colors.red : Colors.blue));
                
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Text(member['name'].toString().substring(0, 1), style: TextStyle(fontSize: 28, color: statusColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('Joined ${member['date']}', style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                      Chip(label: Text(displayStatus), backgroundColor: statusColor.withOpacity(0.1), labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold), side: BorderSide.none)
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Outstanding Penalties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if ((member['deficitInterest'] ?? 0) <= 0 && (member['lateJoinInterest'] ?? 0) <= 0)
                    const Text('No outstanding penalties.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                  else ...[
                    if ((member['deficitInterest'] ?? 0) > 0)
                      _buildPenaltyRow('Deficit Penalty', member['deficitInterest'], context, setState, member, onUpdate, 'deficitInterest'),
                    if ((member['lateJoinInterest'] ?? 0) > 0)
                      _buildPenaltyRow('Late Join Penalty', member['lateJoinInterest'], context, setState, member, onUpdate, 'lateJoinInterest'),
                  ],
                  const SizedBox(height: 32),
                  const Text('Financial Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard('Target', '₱${exp.toStringAsFixed(2)}', Icons.track_changes)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildInfoCard('Paid', '₱${cont.toStringAsFixed(2)}', Icons.account_balance_wallet)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildInfoCard('Remaining', '₱${remaining.toStringAsFixed(2)}', Icons.payments)),
                    ],
                  ),
                  if (member['contribution'] < member['expectedReturn']) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: DashboardTheme.accentColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: Text('Pay Remaining Balance (₱${member['expectedReturn'] - member['contribution']})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () {
                          double deficit = (member['expectedReturn'] as num).toDouble() - (member['contribution'] as num).toDouble();
                          _showPaymentDialog(context, 'Remaining Balance', deficit, (paidAmount) {
                            setState(() {
                              member['contribution'] = (member['contribution'] as num).toDouble() + paidAmount;
                              
                              List history = member['history'] ?? [];
                              history.add({
                                'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
                                'type': 'Contribution Payment',
                                'amount': paidAmount
                              });
                              
                              if ((member['contribution'] as num).toDouble() >= (member['expectedReturn'] as num).toDouble()) {
                                if ((member['totalInterest'] ?? 0.0) <= 0) {
                                  member['status'] = 'Completed';
                                } else {
                                  member['status'] = 'With Penalty';
                                }
                              }
                            });
                            if (onUpdate != null) onUpdate(member);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('₱${paidAmount.toStringAsFixed(2)} Contribution Added!')));
                          });
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Text('Contribution History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (member['history'] as List).length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final h = member['history'][index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history, color: Colors.black54),
                        title: Text(h['type']),
                        subtitle: Text(h['date']),
                        trailing: Text(
                          h['amount'] > 0 ? '+₱${h['amount']}' : '-₱${h['amount'].abs()}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: h['amount'] > 0 ? Colors.green : Colors.red),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text('Loans Involved', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  (member['loans'] as List).isEmpty 
                    ? const Text('No active loans associated.', style: TextStyle(color: Colors.black54))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (member['loans'] as List).length,
                        itemBuilder: (context, index) {
                          final l = member['loans'][index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                            title: Text('₱${l['amount']} Loan'),
                            trailing: Text(l['status'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                  const SizedBox(height: 48),
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

  static String _getDeficitExplanation(Map<String, dynamic> member, double amount) {
    double target = (member['expectedReturn'] as num).toDouble();
    double contribution = (member['contribution'] as num).toDouble();
    double currentDeficit = target - contribution;
    if (currentDeficit < 0) currentDeficit = 0;
    
    int daysPassed = 0;
    double rate = 0.10;
    try {
      DateTime joinedDate = DateFormat('MMM dd, yyyy').parse(member['date']);
      daysPassed = DateTime.now().difference(joinedDate).inDays;
      DateTime oneMonthLater = DateTime(joinedDate.year, joinedDate.month + 1, joinedDate.day);
      DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (today.isAfter(oneMonthLater)) rate = 0.15;
    } catch (_) {}

    return '''DEFICIT PENALTY BREAKDOWN:
• Target Goal: ₱${target.toStringAsFixed(2)}
• Current Contribution: ₱${contribution.toStringAsFixed(2)}
• Current Deficit: ₱${currentDeficit.toStringAsFixed(2)}

TIME ASSESSMENT:
• Joined Date: ${member['date']}
• Days Elapsed: $daysPassed days
• Applicable Rate: ${(rate * 100).toInt()}% (Jumps to 15% after 1mo)

MATH CALCULATION:
₱${currentDeficit.toStringAsFixed(2)} × $rate = ₱${(currentDeficit * rate).toStringAsFixed(2)} raw penalty

Remaining Penalty to Pay: ₱${amount.toStringAsFixed(2)}
(Note: If you made partial balance/penalty payments previously, this remaining fee is accurate to your ledger.)''';
  }

  static String _getLateJoinExplanation(Map<String, dynamic> member, double amount) {
    double target = (member['expectedReturn'] as num).toDouble();
    
    int monthsMissed = 0;
    try {
      DateTime joinedDate = DateFormat('MMM dd, yyyy').parse(member['date']);
      if (joinedDate.year <= DateTime.now().year && joinedDate.month > 1) {
        monthsMissed = joinedDate.month - 1;
      }
    } catch (_) {}

    double rawLatePenalty = (target * 0.15) * monthsMissed;

    return '''LATE JOIN PENALTY BREAKDOWN:
• Target Goal: ₱${target.toStringAsFixed(2)}
• Joined Date: ${member['date']}
• Months Missed Since January: $monthsMissed months
• Monthly Penalty Rate: 15% of Target Amount

MATH CALCULATION:
₱${target.toStringAsFixed(2)} × 15% × $monthsMissed months = ₱${rawLatePenalty.toStringAsFixed(2)}

Remaining Penalty to Pay: ₱${amount.toStringAsFixed(2)}
(Note: If you made partial penalty payments previously, this remaining fee is accurate to your ledger.)''';
  }

  static Widget _buildPenaltyRow(String title, double amount, BuildContext context, StateSetter setState, Map<String, dynamic> member, Function(Map<String, dynamic>)? onUpdate, String penaltyKey) {
    String explanation = penaltyKey == 'deficitInterest' ? _getDeficitExplanation(member, amount) : _getLateJoinExplanation(member, amount);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('About $title'),
                            content: Text(explanation, style: const TextStyle(fontSize: 15, height: 1.5)),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))]
                          )
                        );
                      },
                      child: Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('₱${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: Colors.red.shade800, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, elevation: 0),
            onPressed: () {
              _showPaymentDialog(context, title, amount, (paidAmount) {
                setState(() {
                  List history = member['history'] ?? [];
                  history.add({
                    'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
                    'type': '$title Paid',
                    'amount': paidAmount
                  });
                  member[penaltyKey] = amount - paidAmount;
                  member['totalInterest'] = (member['deficitInterest'] ?? 0.0) + (member['lateJoinInterest'] ?? 0.0);
                  
                  if (member['totalInterest'] <= 0) {
                    if ((member['contribution'] as num).toDouble() >= (member['expectedReturn'] as num).toDouble()) {
                      member['status'] = 'Completed';
                    } else {
                      member['status'] = 'With Balance';
                    }
                  }
                });
                if (onUpdate != null) onUpdate(member);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('₱${paidAmount.toStringAsFixed(2)} Paid for $title!')));
              });
            },
            child: const Text('Pay Now'),
          )
        ],
      ),
    );
  }

  static void _showPaymentDialog(BuildContext context, String title, double maxAmount, Function(double) onPay) {
    TextEditingController controller = TextEditingController(text: maxAmount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Outstanding Amount: ₱${maxAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount to Pay (₱)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DashboardTheme.accentColor),
            onPressed: () {
              double? amount = double.tryParse(controller.text);
              // Allow partial payments and full payments, but not negative or over-payments.
              if (amount != null && amount > 0 && amount <= maxAmount) {
                Navigator.pop(ctx);
                onPay(amount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount.')));
              }
            },
            child: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
          )
        ]
      )
    );
  }

  static Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: DashboardTheme.accentColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: DashboardTheme.accentColor.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DashboardTheme.accentColor, size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: DashboardTheme.accentColor)),
          ),
        ],
      ),
    );
  }
}
