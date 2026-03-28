import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/storage_service.dart';
import '../../theme/dashboard_theme.dart';

class RecordLoanPaymentModal {
  static void show(BuildContext context, Map<String, dynamic> loan, {Function? onUpdate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 24, right: 24,
          ),
          child: _RecordPaymentForm(loan: loan, onUpdate: onUpdate),
        );
      },
    );
  }
}

class _RecordPaymentForm extends StatefulWidget {
  final Map<String, dynamic> loan;
  final Function? onUpdate;

  const _RecordPaymentForm({required this.loan, this.onUpdate});

  @override
  State<_RecordPaymentForm> createState() => _RecordPaymentFormState();
}

class _RecordPaymentFormState extends State<_RecordPaymentForm> {
  DateTime _paymentDate = DateTime.now();
  int _monthsToClear = 0;
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _interestOnlyController = TextEditingController();

  double _principalPayment = 0.0;
  double _interestOnlyPayment = 0.0;
  late int _billableMonths;

  @override
  void initState() {
    super.initState();
    _billableMonths = (widget.loan['missedMonths'] == null || widget.loan['missedMonths'] == 0) 
        ? 1 : widget.loan['missedMonths'];

    _principalController.addListener(() {
      setState(() {
        _principalPayment = double.tryParse(_principalController.text) ?? 0.0;
      });
    });
    _interestOnlyController.addListener(() {
      setState(() {
        _interestOnlyPayment = double.tryParse(_interestOnlyController.text) ?? 0.0;
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

  double _calculateInterestCost(int months) {
    if (months == 0) return 0.0;
    
    double cost = 0.0;
    double principal = (widget.loan['remainingPrincipal'] as num).toDouble();
    DateTime cycleDate = DateFormat('MMM dd, yyyy').parse(widget.loan['dueDate']);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    for (int i = 0; i < months; i++) {
       DateTime penaltyDate = cycleDate.add(const Duration(days: 5));
       if (today.isAfter(penaltyDate) || today.isAtSameMomentAs(penaltyDate)) {
          cost += principal * 0.15;
       } else {
          cost += principal * 0.10;
       }
       cycleDate = _addOneMonth(cycleDate);
    }
    return cost;
  }

  Future<void> _submitPayment() async {
    double remainingPrincipalDB = (widget.loan['remainingPrincipal'] as num).toDouble();

    if (_monthsToClear == 0 && _principalPayment <= 0 && _interestOnlyPayment <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a payment amount.')));
       return;
    }

    double totalInterestPaid = remainingPrincipalDB <= 0 ? _interestOnlyPayment : _calculateInterestCost(_monthsToClear);
    double totalPayment = totalInterestPaid + _principalPayment;

    // Load full DB to find and update this loan
    final loans = await StorageService.loadLoans() ?? [];
    int index = loans.indexWhere((l) => l['id'] == widget.loan['id']);
    if (index != -1) {
       var dbLoan = loans[index];
       
       // Advance Due Date by N months cleared ONLY if using Dropdown
       if (_monthsToClear > 0 && remainingPrincipalDB > 0) {
          DateTime updatedDueDate = DateFormat('MMM dd, yyyy').parse(dbLoan['dueDate']);
          for(int i=0; i<_monthsToClear; i++){
             updatedDueDate = _addOneMonth(updatedDueDate);
          }
          dbLoan['dueDate'] = DateFormat('MMM dd, yyyy').format(updatedDueDate);
          dbLoan['penaltyDate'] = DateFormat('MMM dd, yyyy').format(updatedDueDate.add(const Duration(days: 5)));
       }

       if (totalInterestPaid > 0) {
          dbLoan['remainingInterest'] = (dbLoan['remainingInterest'] as num).toDouble() - totalInterestPaid;
          if (dbLoan['remainingInterest'] < 0) dbLoan['remainingInterest'] = 0.0;
       }

       if (_principalPayment > 0) {
          dbLoan['remainingPrincipal'] = (dbLoan['remainingPrincipal'] as num).toDouble() - _principalPayment;
          if (dbLoan['remainingPrincipal'] <= 0) {
              dbLoan['remainingPrincipal'] = 0.0;
          }
       }

       if ((dbLoan['remainingPrincipal'] as num).toDouble() <= 0 && (dbLoan['remainingInterest'] as num).toDouble() <= 0) {
          dbLoan['status'] = 'Completed';
       }

       dbLoan['totalPaid'] = (dbLoan['totalPaid'] as num).toDouble() + totalPayment;

       List history = dbLoan['paymentHistory'] ?? [];
       history.insert(0, {
          'date': DateFormat('MMM dd, yyyy').format(_paymentDate),
          'amount': totalPayment,
          'interestPortion': totalInterestPaid,
          'principalPortion': _principalPayment,
       });
       dbLoan['paymentHistory'] = history;

       await StorageService.saveLoans(loans);
    }

    if (widget.onUpdate != null) widget.onUpdate!();
    if (mounted) {
       Navigator.pop(context); // pop payment modal
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recorded ₱${totalPayment.toStringAsFixed(2)} payment successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalInterestCost = _calculateInterestCost(_monthsToClear);
    double remainingPrincipalDB = (widget.loan['remainingPrincipal'] as num).toDouble();
    double currentInterestDB = (widget.loan['remainingInterest'] as num).toDouble();
    double totalPayment = remainingPrincipalDB <= 0 ? _interestOnlyPayment : (totalInterestCost + _principalPayment);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
          const Text('Record Loan Payment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            tileColor: Colors.grey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            leading: const Icon(Icons.calendar_month, color: DashboardTheme.accentColor),
            title: const Text('Date of Payment', style: TextStyle(fontSize: 12, color: Colors.black54)),
            subtitle: Text(DateFormat('MMMM dd, yyyy').format(_paymentDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            trailing: const Text('Change', style: TextStyle(color: DashboardTheme.accentColor, fontWeight: FontWeight.bold)),
            onTap: () async {
              DateTime? picked = await showDatePicker(context: context, initialDate: _paymentDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (picked != null) setState(() => _paymentDate = picked);
            },
          ),
          const SizedBox(height: 24),

          if (remainingPrincipalDB > 0) ...[
            const Text('1. Clear Monthly Interest', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Iterative Penalty Assessment', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Select: $_monthsToClear / $_billableMonths months', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (totalInterestCost > 0) Text('Paying: ₱${totalInterestCost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<int>(
                      value: _monthsToClear,
                      underline: const SizedBox(),
                      items: List.generate(_billableMonths + 1, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text(index == 0 ? '0 Months' : '$index Month${index > 1 ? 's' : ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => _monthsToClear = val);
                      },
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('2. Pay Down Principal (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _principalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Principal Amount (₱)',
                hintText: 'Max: ₱${remainingPrincipalDB.toStringAsFixed(2)}',
                prefixIcon: const Icon(Icons.account_balance_wallet),
                filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardTheme.accentColor)),
              ),
            ),
          ] else ...[
            const Text('Clear Outstanding Interest Base', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Base Line Principal has been cleanly processed to 0. You currently owe a mathematically frozen ₱${currentInterestDB.toStringAsFixed(2)} in un-liquidated interest penalty fees.', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            TextField(
              controller: _interestOnlyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Frozen Interest Payment (₱)',
                hintText: 'Max: ₱${currentInterestDB.toStringAsFixed(2)}',
                prefixIcon: const Icon(Icons.money_off),
                filled: true, fillColor: Colors.orange.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.orange.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.orange.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardTheme.accentColor)),
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitPayment,
              child: Text('Confirm Payment of ₱${totalPayment.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
