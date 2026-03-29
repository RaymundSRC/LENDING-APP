import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoanInterestBreakdown {
  static void show(BuildContext context, Map<String, dynamic> loan) {
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
            children: [
              Text(
                'Cycle $i: ${DateFormat('MMM dd, yyyy').format(cycleDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (isForgiven)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Manually Forgiven to 10%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    isPenalty 
                      ? 'Passed Grace Period on ${DateFormat('MMM dd').format(cyclePenaltyDate)} (15%)'
                      : 'Active Grace Period til ${DateFormat('MMM dd').format(cyclePenaltyDate)} (10%)',
                    style: TextStyle(
                      fontSize: 12, 
                      color: isPenalty ? Colors.red : Colors.orange
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '₱${cost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isForgiven ? Colors.green.shade700 : Colors.red.shade700
                ),
              ),
            ],
          ),
        ),
      );
      
      cycleDate = _addOneMonth(cycleDate);
      i++;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Interest Breakdown'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Based on ${displayPrincipal.toStringAsFixed(2)} principal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500
                ),
              ),
              const SizedBox(height: 16),
              ...breakdownWidgets,
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
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
