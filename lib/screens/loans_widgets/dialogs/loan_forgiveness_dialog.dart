import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/storage_service.dart';

/// Dialog handler for loan interest rate forgiveness and restoration
class LoanForgivenessDialog {
  /// Shows dialog to forgive or restore penalty rates for a specific loan cycle
  static void show({
    required BuildContext context,
    required DateTime cycleDate, // Specific cycle date
    required String monthLabel, // Formatted month label for display
    required bool isCurrentlyForgiven, // Current forgiveness status
    required Map<String, dynamic> loan, // Loan data
    required Function() onUpdate, // Callback to update UI
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCurrentlyForgiven
            ? 'Restore 15% Penalty Lock' // Title for restoration
            : 'Grant Leniency Override'), // Title for forgiveness
        content: Text(isCurrentlyForgiven
            ? 'Are you sure you want to revert $monthLabel back to the severe 15% late compounding lock?' // Restoration confirmation
            : 'Permanently forgive the 15% severity lock for $monthLabel mathematically dropping it to the base 10% rate?'), // Forgiveness confirmation
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')), // Cancel action
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyForgiven
                  ? Colors.red
                  : Colors.green, // Red for restore, green for forgive
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog first

              String cycleKey = DateFormat('MMM dd, yyyy')
                  .format(cycleDate); // Format date as key
              Map<String, dynamic> customRates = loan['customRates'] != null
                  ? Map<String, dynamic>.from(
                      loan['customRates']) // Copy existing custom rates
                  : {};

              if (isCurrentlyForgiven) {
                customRates
                    .remove(cycleKey); // Remove forgiveness (restore penalty)
              } else {
                customRates[cycleKey] =
                    0.10; // Add forgiveness (reduce rate to 10%)
              }
              loan['customRates'] = customRates; // Update loan data

              List<Map<String, dynamic>> loans =
                  await StorageService.loadLoans() ?? []; // Load all loans
              int index = loans
                  .indexWhere((l) => l['id'] == loan['id']); // Find loan index
              if (index != -1) {
                // If loan found
                loans[index]['customRates'] =
                    customRates; // Update loan in list

                // Recalculate interest based on new custom rates
                double totalInterestOwed = 0.0;
                DateTime currentCycle = DateFormat('MMM dd, yyyy')
                    .parse(loan['dueDate']); // Start from due date
                DateTime todayMidnight = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day); // Current date without time
                double principal = (loan['remainingPrincipal'] as num)
                    .toDouble(); // Current principal

                while (todayMidnight.isAfter(currentCycle) ||
                    currentCycle.isAtSameMomentAs(todayMidnight)) {
                  String key = DateFormat('MMM dd, yyyy')
                      .format(currentCycle); // Format cycle as key
                  double rate = 0.10; // Default rate
                  DateTime penaltyDateLimit = currentCycle.add(const Duration(
                      days: 5)); // Penalty date is 5 days after cycle
                  bool penalty = todayMidnight.isAfter(penaltyDateLimit) ||
                      todayMidnight.isAtSameMomentAs(
                          penaltyDateLimit); // Check if penalty applies

                  if (customRates.containsKey(key)) {
                    rate = (customRates[key] as num)
                        .toDouble(); // Use custom rate if available
                  } else if (penalty) {
                    rate = 0.15; // Apply penalty rate
                  }

                  totalInterestOwed +=
                      principal * rate; // Add interest for this cycle
                  currentCycle =
                      _addOneMonth(currentCycle); // Move to next cycle
                }

                loans[index]['remainingInterest'] = double.parse(
                    totalInterestOwed
                        .toStringAsFixed(2)); // Update remaining interest
                loan['remainingInterest'] =
                    loans[index]['remainingInterest']; // Update local loan data

                await StorageService.saveLoans(loans); // Save to storage
                onUpdate(); // Refresh UI

                // Show success message
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(isCurrentlyForgiven
                        ? 'Restored 15% Penalty for $monthLabel' // Restoration message
                        : 'Successfully Forgiven $monthLabel!'), // Forgiveness message
                    backgroundColor: isCurrentlyForgiven
                        ? Colors.red
                        : Colors.green)); // Color based on action
              }
            },
            child: Text(
                isCurrentlyForgiven
                    ? 'Restore 15%'
                    : 'Forgive to 10%', // Button text
                style: const TextStyle(color: Colors.white)), // White text
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
