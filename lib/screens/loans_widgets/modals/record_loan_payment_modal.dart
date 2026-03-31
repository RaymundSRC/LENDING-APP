import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/storage_service.dart';
import '../../../theme/dashboard_theme.dart';

/// Modal for recording loan payments with principal and interest breakdown
class RecordLoanPaymentModal {
  /// Shows the loan payment recording modal
  static void show(BuildContext context, Map<String, dynamic> loan,
      {Function? onUpdate}) {
    // onUpdate callback for UI refresh
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow scrolling when keyboard appears
      backgroundColor:
          Colors.transparent, // Transparent background for custom shape
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white, // White background for modal
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(24)), // Rounded top corners
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context)
                .viewInsets
                .bottom, // Adjust for keyboard height
            top: 24, // Top padding
            left: 24, // Left padding
            right: 24, // Right padding
          ),
          child: _RecordPaymentForm(
              loan: loan, onUpdate: onUpdate), // Payment form widget
        );
      },
    );
  }
}

/// Form widget for recording loan payments
class _RecordPaymentForm extends StatefulWidget {
  final Map<String, dynamic> loan; // Loan data
  final Function? onUpdate; // Callback for UI updates

  const _RecordPaymentForm({required this.loan, this.onUpdate});

  @override
  State<_RecordPaymentForm> createState() => _RecordPaymentFormState();
}

class _RecordPaymentFormState extends State<_RecordPaymentForm> {
  DateTime _paymentDate = DateTime.now();
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _interestOnlyController = TextEditingController();

  double _principalPayment = 0.0;
  double _interestOnlyPayment = 0.0;
  late int _billableMonths;

  @override
  void initState() {
    super.initState();
    _billableMonths = (widget.loan['missedMonths'] == null ||
            widget.loan['missedMonths'] == 0)
        ? 0
        : widget.loan['missedMonths']; // Properly default to 0 if none missed!

    _principalController.addListener(() {
      setState(() {
        _principalPayment = double.tryParse(_principalController.text) ?? 0.0;
      });
    });
    _interestOnlyController.addListener(() {
      setState(() {
        _interestOnlyPayment =
            double.tryParse(_interestOnlyController.text) ?? 0.0;
      });
    });
  }

  DateTime _addOneMonth(DateTime date) {
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

  Future<void> _processPayment(
      {required int monthsToClear,
      required double interestCost,
      required double principalToPay,
      required String label}) async {
    double totalPayment = interestCost + principalToPay;
    if (totalPayment <= 0 && monthsToClear == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid payment.')));
      return;
    }

    final loans = await StorageService.loadLoans() ?? [];
    int index = loans.indexWhere((l) => l['id'] == widget.loan['id']);
    if (index != -1) {
      var dbLoan = loans[index];
      double remainingPrincipalDB =
          (dbLoan['remainingPrincipal'] as num).toDouble();

      if (monthsToClear > 0 && remainingPrincipalDB > 0) {
        DateTime updatedDueDate =
            DateFormat('MMM dd, yyyy').parse(dbLoan['dueDate']);
        for (int i = 0; i < monthsToClear; i++) {
          updatedDueDate = _addOneMonth(updatedDueDate);
        }
        dbLoan['dueDate'] = DateFormat('MMM dd, yyyy').format(updatedDueDate);
        dbLoan['penaltyDate'] = DateFormat('MMM dd, yyyy')
            .format(updatedDueDate.add(const Duration(days: 5)));
      }

      if (interestCost > 0) {
        dbLoan['remainingInterest'] =
            (dbLoan['remainingInterest'] as num).toDouble() - interestCost;
        if (dbLoan['remainingInterest'] < 0) dbLoan['remainingInterest'] = 0.0;
      }

      if (principalToPay > 0) {
        dbLoan['remainingPrincipal'] = remainingPrincipalDB - principalToPay;
        if (dbLoan['remainingPrincipal'] <= 0) {
          dbLoan['remainingPrincipal'] = 0.0;
        }
      }

      if ((dbLoan['remainingPrincipal'] as num).toDouble() <= 0.01 &&
          (dbLoan['remainingInterest'] as num).toDouble() <= 0.01) {
        dbLoan['status'] = 'Completed';
      } else if ((dbLoan['remainingPrincipal'] as num).toDouble() <= 0.01) {
        dbLoan['status'] = 'Interest Only';
      }

      dbLoan['totalPaid'] =
          (dbLoan['totalPaid'] as num).toDouble() + totalPayment;

      List history = dbLoan['paymentHistory'] ?? [];
      history.insert(0, {
        'date': DateFormat('MMM dd, yyyy').format(_paymentDate),
        'amount': totalPayment,
        'interestPortion': interestCost,
        'principalPortion': principalToPay,
        'label': label,
      });
      dbLoan['paymentHistory'] = history;

      await StorageService.saveLoans(loans);
    }

    if (widget.onUpdate != null) widget.onUpdate!();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '₱${totalPayment.toStringAsFixed(2)} Paid Successfully for $label!')));
    }
  }

  void _showForgiveDialog(
      DateTime cycleDate, String monthLabel, bool isCurrentlyForgiven) {
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
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isCurrentlyForgiven ? Colors.red : Colors.green),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      String cycleKey =
                          DateFormat('MMM dd, yyyy').format(cycleDate);
                      Map<String, dynamic> customRates =
                          widget.loan['customRates'] != null
                              ? Map<String, dynamic>.from(
                                  widget.loan['customRates'])
                              : {};

                      if (isCurrentlyForgiven) {
                        customRates.remove(cycleKey);
                      } else {
                        customRates[cycleKey] = 0.10;
                      }
                      widget.loan['customRates'] = customRates;

                      List<Map<String, dynamic>> loans =
                          await StorageService.loadLoans() ?? [];
                      int index =
                          loans.indexWhere((l) => l['id'] == widget.loan['id']);
                      if (index != -1) {
                        loans[index]['customRates'] = customRates;

                        double totalInterestOwed = 0.0;
                        DateTime currentCycle = DateFormat('MMM dd, yyyy')
                            .parse(widget.loan['dueDate']);
                        DateTime todayMidnight = DateTime(DateTime.now().year,
                            DateTime.now().month, DateTime.now().day);
                        double principal =
                            (widget.loan['remainingPrincipal'] as num)
                                .toDouble();
                        while (todayMidnight.isAfter(currentCycle) ||
                            currentCycle.isAtSameMomentAs(todayMidnight)) {
                          String key =
                              DateFormat('MMM dd, yyyy').format(currentCycle);
                          double rate = 0.10;
                          DateTime penaltyDateLimit =
                              currentCycle.add(const Duration(days: 5));
                          bool penalty = todayMidnight
                                  .isAfter(penaltyDateLimit) ||
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
                        widget.loan['remainingInterest'] =
                            loans[index]['remainingInterest'];

                        await StorageService.saveLoans(loans);
                        if (widget.onUpdate != null) widget.onUpdate!();
                        if (mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(isCurrentlyForgiven
                                  ? 'Restored 15% Penalty for $monthLabel'
                                  : 'Successfully Forgiven $monthLabel!'),
                              backgroundColor: isCurrentlyForgiven
                                  ? Colors.red
                                  : Colors.green));
                        }
                      }
                    },
                    child: Text(
                        isCurrentlyForgiven ? 'Restore 15%' : 'Forgive to 10%',
                        style: const TextStyle(color: Colors.white)),
                  )
                ]));
  }

  @override
  Widget build(BuildContext context) {
    double remainingPrincipalDB =
        (widget.loan['remainingPrincipal'] as num).toDouble();
    double currentInterestDB =
        (widget.loan['remainingInterest'] as num).toDouble();

    // Dynamically calculate Chronological Blocks natively mapping directly to the specific exact Due Date trajectory
    List<Map<String, dynamic>> interestBlocks = [];
    if (_billableMonths > 0 && remainingPrincipalDB > 0) {
      try {
        DateTime cycleDate =
            DateFormat('MMM dd, yyyy').parse(widget.loan['dueDate']);
        DateTime today = DateTime.now();
        DateTime todayMidnight = DateTime(today.year, today.month, today.day);

        Map<String, dynamic> customRates = widget.loan['customRates'] != null
            ? Map<String, dynamic>.from(widget.loan['customRates'])
            : {};

        for (int i = 0; i < _billableMonths; i++) {
          DateTime penaltyDate = cycleDate.add(const Duration(days: 5));
          String cycleKey = DateFormat('MMM dd, yyyy').format(cycleDate);
          double generated = 0.0;
          bool isLate = false;
          bool isForgiven = false;

          if (customRates.containsKey(cycleKey)) {
            double customR = (customRates[cycleKey] as num).toDouble();
            generated = remainingPrincipalDB * customR;
            if (customR <= 0.10 &&
                (todayMidnight.isAfter(penaltyDate) ||
                    todayMidnight.isAtSameMomentAs(penaltyDate))) {
              isForgiven = true;
              isLate = true;
            }
          } else if (todayMidnight.isAfter(penaltyDate) ||
              todayMidnight.isAtSameMomentAs(penaltyDate)) {
            generated = remainingPrincipalDB * 0.15;
            isLate = true;
          } else {
            generated = remainingPrincipalDB * 0.10;
          }

          interestBlocks.add({
            'month': DateFormat('MMMM yyyy').format(cycleDate),
            'generated': generated,
            'isLate': isLate,
            'isForgiven': isForgiven,
            'rawDate': cycleDate,
          });
          cycleDate = _addOneMonth(cycleDate);
        }
      } catch (_) {}
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4)))),
          const Text('Record Loan Payment',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            tileColor: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200)),
            leading: const Icon(Icons.calendar_month,
                color: DashboardTheme.accentColor),
            title: const Text('Date of Payment',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            subtitle: Text(DateFormat('MMMM dd, yyyy').format(_paymentDate),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87)),
            trailing: const Text('Change',
                style: TextStyle(
                    color: DashboardTheme.accentColor,
                    fontWeight: FontWeight.bold)),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _paymentDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100));
              if (picked != null) setState(() => _paymentDate = picked);
            },
          ),
          const SizedBox(height: 24),
          if (remainingPrincipalDB > 0) ...[
            const Text('1. Clear Monthly Interest',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (interestBlocks.isEmpty)
              const Text('Outstanding monthly interest perfectly clear.',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold))
            else
              ...interestBlocks.asMap().entries.map((entry) {
                int index = entry.key;
                var b = entry.value;
                bool isActive = index ==
                    0; // Only the physical topmost Chronological block is securely un-locked for execution!

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: b['isForgiven']
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: b['isForgiven']
                              ? Colors.green.shade200
                              : Colors.red.shade200)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                    b['isLate']
                                        ? (b['isForgiven']
                                            ? Icons.check_circle
                                            : Icons.warning_rounded)
                                        : Icons.info_outline,
                                    size: 16,
                                    color: b['isForgiven']
                                        ? Colors.green.shade900
                                        : Colors.red.shade900),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: Text('${b['month']} Interest',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: b['isForgiven']
                                                ? Colors.green.shade900
                                                : Colors.red.shade900),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('₱${b['generated'].toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: b['isForgiven']
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                    fontWeight: FontWeight.bold)),
                            if (b['isForgiven'])
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(children: [
                                    Text('Manually Forgiven (10%) ',
                                        style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    if (isActive)
                                      GestureDetector(
                                          onTap: () => _showForgiveDialog(
                                              b['rawDate'], b['month'], true),
                                          child: Text('[ Edit ]',
                                              style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration
                                                      .underline)))
                                  ]))
                            else if (!b['isLate'])
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('10% Grace Active',
                                      style: TextStyle(
                                          color: Colors.red.shade400,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)))
                            else
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(children: [
                                    Text('15% Late Lock ',
                                        style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    if (isActive)
                                      GestureDetector(
                                          onTap: () => _showForgiveDialog(
                                              b['rawDate'], b['month'], false),
                                          child: Text('[ Edit ]',
                                              style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration
                                                      .underline)))
                                  ])),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      isActive
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 0),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                          title: Text(
                                              'Pay ${b['month']} Interest'),
                                          content: Text(
                                              'Confirm payment of ₱${b['generated'].toStringAsFixed(2)}? This mathematically secures this cycle and actively advances your Due Date tracking.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: const Text('Cancel')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red.shade600),
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _processPayment(
                                                    monthsToClear: 1,
                                                    interestCost:
                                                        b['generated'],
                                                    principalToPay: 0.0,
                                                    label:
                                                        '${b['month']} Interest');
                                              },
                                              child: const Text('Pay Month',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            )
                                          ],
                                        ));
                              },
                              child: const Text('Pay Month'),
                            )
                          : const Icon(Icons.lock_rounded,
                              color: Colors.redAccent, size: 24),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
            const Text('2. Pay Down Principal (Direct)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _principalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Principal Payload (₱)',
                      hintText:
                          'Max: ₱${remainingPrincipalDB.toStringAsFixed(2)}',
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: DashboardTheme.accentColor)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_principalPayment <= 0) return;
                    _processPayment(
                        monthsToClear: 0,
                        interestCost: 0,
                        principalToPay: _principalPayment,
                        label: 'Principal Reduction');
                  },
                  child: const Text('Pay Principal',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ] else ...[
            const Text('Clear Outstanding Base Line Interest',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                'Base capital is fully liquidated! You currently owe a mathematically frozen ₱${currentInterestDB.toStringAsFixed(2)} in un-liquidated interest fees.',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _interestOnlyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Frozen Core Interest (₱)',
                      hintText: 'Max: ₱${currentInterestDB.toStringAsFixed(2)}',
                      prefixIcon: const Icon(Icons.money_off),
                      filled: true,
                      fillColor: Colors.orange.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.orange.shade200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.orange.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: DashboardTheme.accentColor)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_interestOnlyPayment <= 0) return;
                    _processPayment(
                        monthsToClear: 0,
                        interestCost: _interestOnlyPayment,
                        principalToPay: 0,
                        label: 'Frozen Interest Dump');
                  },
                  child: const Text('Pay Frozen',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
