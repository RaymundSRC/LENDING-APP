import 'package:flutter/material.dart';
import 'loan_profile_modal.dart';

class LoansList extends StatelessWidget {
  final List<Map<String, dynamic>> loans;
  final Function? onUpdate;

  const LoansList({super.key, required this.loans, this.onUpdate});

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) return const Center(child: Text('No loans found.', style: TextStyle(color: Colors.black54)));

    return ListView.builder(
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final l = loans[index];
        Color statusColor;
        switch (l['status']) {
          case 'Active': statusColor = Colors.green; break;
          case 'Completed': statusColor = Colors.blue; break;
          case 'Pending': statusColor = Colors.orange; break;
          case 'Late': statusColor = Colors.red; break;
          default: statusColor = Colors.grey;
        }

        // Safe fallback for progress bar parsing
        double totalPaid = (l['totalPaid'] as num?)?.toDouble() ?? 0.0;
        double amount = (l['amount'] as num?)?.toDouble() ?? 1.0;
        double progress = (totalPaid / amount).clamp(0.0, 1.0);

        int missed = (l['missedMonths'] as num?)?.toInt() ?? 0;
        String interestLabel = missed > 1 ? 'Int. ($missed Mos)' : 'Monthly Int.';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => LoanProfileModal.show(context, l, onUpdate: onUpdate),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: statusColor.withOpacity(0.1),
                            child: Icon(Icons.account_circle, color: statusColor, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(l['borrower'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Text(l['status'] ?? 'Unknown', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoColumn('Loan Amount', '₱${l['amount']}'),
                      _infoColumn(interestLabel, '₱${l['remainingInterest']}'),
                      _infoColumn('Principal', '₱${l['remainingPrincipal']}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoColumn('Borrowed', l['borrowedDate'] ?? '-'),
                      _infoColumn('Due', l['dueDate'] ?? '-'),
                      _infoColumn('Interest', l['interestRate'] ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paid: ₱$totalPaid', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                      Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}
