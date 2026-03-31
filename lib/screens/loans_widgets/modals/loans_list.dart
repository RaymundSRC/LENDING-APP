import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';
import './loan_profile_modal.dart';

/// List widget for displaying all loans with actions
class LoansList extends StatelessWidget {
  final List<Map<String, dynamic>> loans; // List of loans to display
  final Function? onUpdate; // Callback for UI updates

  const LoansList({super.key, required this.loans, this.onUpdate});

  /// Shows edit/delete options for a specific loan
  void _showEditDeleteDialog(BuildContext context, Map<String, dynamic> loan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Transparent for custom shape
      isScrollControlled: true, // Allow scrolling when keyboard appears
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height *
              0.85, // Max height 85% of screen
        ),
        decoration: const BoxDecoration(
          color: Colors.white, // White background
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(24)), // Rounded top corners
        ),
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
          left: 24, // Left padding
          right: 24, // Right padding
          top: 24, // Top padding
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal handle bar
              Container(
                width: 40, // Handle width
                height: 4, // Handle height
                margin: const EdgeInsets.only(bottom: 24), // Bottom margin
                decoration: BoxDecoration(
                  color: Colors.grey.shade300, // Handle color
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Loan summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Colors.blue.shade100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade500,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan['borrower'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Loan ID: ${loan['id']?.toString().substring(0, 8) ?? 'N/A'}...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem(
                            'Amount', '₱${loan['amount'] ?? '0'}', Icons.paid),
                        _buildSummaryItem('Status', loan['status'] ?? 'Unknown',
                            Icons.info_outline),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              const Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Edit button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _editLoan(context, loan);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Edit Loan Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue.shade200),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              // Delete button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteLoan(context, loan);
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Delete Loan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              // Cancel button
              Container(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.blue.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _editLoan(BuildContext context, Map<String, dynamic> loan) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit loan feature coming soon!')),
    );
  }

  void _deleteLoan(BuildContext context, Map<String, dynamic> loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this loan?'),
            const SizedBox(height: 16),
            Text('Borrower: ${loan['borrower'] ?? 'Unknown'}'),
            Text('Amount: ₱${loan['amount'] ?? '0'}'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final loans = await StorageService.loadLoans() ?? [];
              loans.removeWhere((l) => l['id'] == loan['id']);
              await StorageService.saveLoans(loans);

              onUpdate?.call();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Loan deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return const Center(
          child:
              Text('No loans found.', style: TextStyle(color: Colors.black54)));
    }

    return ListView.builder(
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final l = loans[index];
        Color statusColor;
        switch (l['status']) {
          case 'Active':
            statusColor = Colors.green;
            break;
          case 'Completed':
            statusColor = Colors.blue;
            break;
          case 'Pending':
            statusColor = Colors.orange;
            break;
          case 'Late':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.grey;
        }

        double totalPaid = (l['totalPaid'] as num?)?.toDouble() ?? 0.0;
        double amount = (l['amount'] as num?)?.toDouble() ?? 1.0;
        double progress = (totalPaid / amount).clamp(0.0, 1.0);

        int missed = (l['missedMonths'] as num?)?.toInt() ?? 0;
        String interestLabel =
            missed > 1 ? 'Int. ($missed Mos)' : 'Monthly Int.';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: statusColor.withOpacity(0.1),
                              child: Icon(Icons.account_circle,
                                  color: statusColor, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                l['borrower'] ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(l['status'] ?? 'Unknown',
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showEditDeleteDialog(context, l),
                            child: Material(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.more_vert,
                                    color: Colors.white, size: 20),
                              ),
                            ),
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
                      Text('Paid: ₱$totalPaid',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54)),
                      Text('${(progress * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.bold)),
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
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ],
    );
  }
}
