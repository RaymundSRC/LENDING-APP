import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/storage_service.dart';

class LoanForgivenessDialog {
  static void show({
    required BuildContext context,
    required DateTime cycleDate,
    required String monthLabel,
    required bool isCurrentlyForgiven,
    required Map<String, dynamic> loan,
    required Function() onUpdate,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCurrentlyForgiven
            ? 'Restore 15% Penalty Lock'
            : 'Grant Leniency Override'),
        content: Text(isCurrentlyForgiven
            ? 'Are you sure you want to revert $monthLabel back to the severe 15% late compounding lock?'
            : 'Permanently forgive the 15% severity lock for $monthLabel mathematically dropping it to the base 10% rate?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyForgiven ? Colors.red : Colors.green,
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              String cycleKey = DateFormat('MMM dd, yyyy').format(cycleDate);
              Map<String, dynamic> customRates = loan['customRates'] != null
                  ? Map<String, dynamic>.from(loan['customRates'])
                  : {};

              if (isCurrentlyForgiven) {
                customRates.remove(cycleKey);
              } else {
                customRates[cycleKey] = 0.10;
              }
              loan['customRates'] = customRates;

              List<Map<String, dynamic>> loans =
                  await StorageService.loadLoans() ?? [];
              int index = loans.indexWhere((l) => l['id'] == loan['id']);
              if (index != -1) {
                loans[index]['customRates'] = customRates;

                // Recalculate interest
                double totalInterestOwed = 0.0;
                DateTime currentCycle =
                    DateFormat('MMM dd, yyyy').parse(loan['dueDate']);
                DateTime todayMidnight = DateTime(DateTime.now().year,
                    DateTime.now().month, DateTime.now().day);
                double principal =
                    (loan['remainingPrincipal'] as num).toDouble();

                while (todayMidnight.isAfter(currentCycle) ||
                    currentCycle.isAtSameMomentAs(todayMidnight)) {
                  String key = DateFormat('MMM dd, yyyy').format(currentCycle);
                  double rate = 0.10;
                  DateTime penaltyDateLimit =
                      currentCycle.add(const Duration(days: 5));
                  bool penalty = todayMidnight.isAfter(penaltyDateLimit) ||
                      todayMidnight.isAtSameMomentAs(penaltyDateLimit);

                  if (customRates.containsKey(key)) {
                    rate = (customRates[key] as num).toDouble();
                  } else if (penalty) {
                    rate = 0.15;
                  }

                  totalInterestOwed += principal * rate;
                  currentCycle = _addOneMonth(currentCycle);
                }

                loans[index]['remainingInterest'] =
                    double.parse(totalInterestOwed.toStringAsFixed(2));
                loan['remainingInterest'] = loans[index]['remainingInterest'];

                await StorageService.saveLoans(loans);
                onUpdate();

                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(isCurrentlyForgiven
                        ? 'Restored 15% Penalty for $monthLabel'
                        : 'Successfully Forgiven $monthLabel!'),
                    backgroundColor:
                        isCurrentlyForgiven ? Colors.red : Colors.green));
              }
            },
            child: Text(isCurrentlyForgiven ? 'Restore 15%' : 'Forgive to 10%',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

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
}
