import 'package:flutter/material.dart';

/// Quick actions widget for dashboard
/// Provides fast access to main app functions: add member, new loan, payment, and reports
class QuickActions extends StatelessWidget {
  final VoidCallback onAddMember;
  final VoidCallback onAddLoan;
  final VoidCallback onPayment;
  final VoidCallback onReport;

  const QuickActions({
    super.key,
    required this.onAddMember, // Callback for adding a new member
    required this.onAddLoan, // Callback for creating a new loan
    required this.onPayment, // Callback for making a payment
    required this.onReport, // Callback for viewing reports
  });

  // === UI LAYOUT ===

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: 16), // Vertical padding for spacing
      decoration: BoxDecoration(
        color: Colors.white, // Background color
        borderRadius: BorderRadius.circular(12), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), // Subtle shadow for depth
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly, // Evenly spaced children
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actionButton(Icons.person_add, 'Member', Colors.blue,
              onAddMember), // Member action button
          _actionButton(Icons.payments, 'New Loan', Colors.green,
              onAddLoan), // New loan action button
          _actionButton(Icons.payment, 'Payment', Colors.orange,
              onPayment), // Payment action button
          _actionButton(Icons.assessment, 'Report', Colors.purple,
              onReport), // Report action button
        ],
      ),
    );
  }

  // === END OF UI LAYOUT ===

  // === CUSTOM WIDGETS ===

  /// Builds an individual action button with icon and label
  /// Uses consistent styling with color-coded icons for visual hierarchy
  Widget _actionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, // Handle tap event
      child: Column(
        mainAxisSize: MainAxisSize.min, // Minimum vertical space
        children: [
          CircleAvatar(
            radius: 24, // Icon size
            backgroundColor: color.withOpacity(0.15), // Subtle background
            child: Icon(icon, color: color, size: 24), // Icon with color
          ),
          const SizedBox(height: 8), // Spacing between icon and label
          Text(
            label, // Button label
            style: const TextStyle(
                fontSize: 12, // Font size
                fontWeight: FontWeight.w500, // Font weight
                color: Colors.black87), // Font color
          ),
        ],
      ),
    );
  }

  // === END OF CUSTOM WIDGETS ===
}
