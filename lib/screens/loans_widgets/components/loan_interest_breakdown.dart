import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for loan interest breakdown display
class LoanInterestBreakdown {
  /// Shows detailed interest breakdown dialog for a specific loan
  static void show(BuildContext context, Map<String, dynamic> loan) {
    double principal = (loan['remainingPrincipal'] as num).toDouble();
    double displayPrincipal = principal > 0
        ? principal
        : (loan['amount'] as num)
            .toDouble(); // Use remaining or original principal

    DateTime cycleDate =
        DateFormat('MMM dd, yyyy').parse(loan['dueDate']); // Parse due date
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day); // Current date without time

    List<Widget> breakdownWidgets = [];
    int i = 1; // Cycle counter
    Map<String, dynamic> customRates = loan['customRates'] != null
        ? Map<String, dynamic>.from(
            loan['customRates']) // Copy custom rates if they exist
        : {};

    while (today.isAfter(cycleDate) || cycleDate.isAtSameMomentAs(today)) {
      DateTime cyclePenaltyDate = cycleDate
          .add(const Duration(days: 5)); // Penalty date is 5 days after cycle
      String cycleKey = DateFormat('MMM dd, yyyy')
          .format(cycleDate); // Format cycle date as key

      bool isPenalty = today.isAfter(cyclePenaltyDate) ||
          today.isAtSameMomentAs(
              cyclePenaltyDate); // Check if penalty period has started
      double rate = isPenalty ? 0.15 : 0.10; // Apply penalty or regular rate
      bool isForgiven = false;

      if (customRates.containsKey(cycleKey)) {
        rate = (customRates[cycleKey] as num)
            .toDouble(); // Use custom rate if available
        if (rate <= 0.10 && isPenalty)
          isForgiven =
              true; // Mark as forgiven if rate is reduced during penalty period
      }

      double cost =
          displayPrincipal * rate; // Calculate interest cost for this cycle

      breakdownWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12), // Spacing between cycles
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cycle $i: ${DateFormat('MMM dd, yyyy').format(cycleDate)}', // Cycle header
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4), // Spacing
                    if (isForgiven)
                      Text(
                        'Manually Forgiven to 10%', // Forgiveness status
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold),
                      )
                    else
                      Text(
                        isPenalty
                            ? 'Passed Grace Period on ${DateFormat('MMM dd').format(cyclePenaltyDate)} (15%)' // Penalty period message
                            : 'Active Grace Period til ${DateFormat('MMM dd').format(cyclePenaltyDate)} (10%)', // Grace period message
                        style: TextStyle(
                            fontSize: 12,
                            color: isPenalty
                                ? Colors.red
                                : Colors.orange), // Color based on status
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12), // Spacing between cycle info and cost
              Text(
                '₱${cost.toStringAsFixed(2)}', // Interest cost for this cycle
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isForgiven
                        ? Colors.green.shade700 // Green for forgiven cycles
                        : Colors.red.shade700), // Red for regular cycles
              ),
            ],
          ),
        ),
      );

      cycleDate = _addOneMonth(cycleDate); // Move to next cycle
      i++; // Increment cycle counter
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Interest Breakdown'), // Dialog title
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Based on ${displayPrincipal.toStringAsFixed(2)} principal', // Principal amount display
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16), // Spacing before breakdown
              ...breakdownWidgets, // All cycle breakdowns
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Close dialog
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Adds one month to a given date, handling month overflow
  static DateTime _addOneMonth(DateTime date) {
    int nextYear = date.year;
    int nextMonth = date.month + 1;
    if (nextMonth > 12) {
      // Handle year overflow
      nextMonth = 1;
      nextYear++;
    }
    int maxDays =
        DateTime(nextYear, nextMonth + 1, 0).day; // Get max days in next month
    int nextDay =
        date.day > maxDays ? maxDays : date.day; // Adjust day if needed
    return DateTime(nextYear, nextMonth, nextDay);
  }
}
