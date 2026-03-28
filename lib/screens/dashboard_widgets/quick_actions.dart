import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onAddMember;
  final VoidCallback onAddLoan;
  final VoidCallback onPayment;
  final VoidCallback onReport;

  const QuickActions({
    super.key,
    required this.onAddMember,
    required this.onAddLoan,
    required this.onPayment,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actionButton(Icons.person_add, 'Member', Colors.blue, onAddMember),
          _actionButton(Icons.payments, 'New Loan', Colors.green, onAddLoan),
          _actionButton(Icons.payment, 'Payment', Colors.orange, onPayment),
          _actionButton(Icons.assessment, 'Report', Colors.purple, onReport),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
