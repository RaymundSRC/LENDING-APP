import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/dashboard_theme.dart';
import '../services/storage_service.dart';
import 'loans_widgets/loans_filter_bar.dart';
import 'loans_widgets/loans_list.dart';
import 'loans_widgets/add_loan_modal.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'All';
  List<Map<String, dynamic>> _allLoans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _loadData() async {
    final loans = await StorageService.loadLoans() ?? [];
    
    // Live Calendar Time-Travel Evaluator
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    bool requiresDBUpdate = false;

    for (var l in loans) {
      if (l['status'] == 'Completed') continue;

      try {
        DateTime dueDate = DateFormat('MMM dd, yyyy').parse(l['dueDate']);
        double principal = (l['remainingPrincipal'] as num).toDouble();

        if (principal > 0) {
          // Calculate accrued missed months mathematically
          int missedMonths = 0;
          DateTime cycleDate = dueDate;
          double totalInterestOwed = 0.0;
          bool isAnyPenalty = false;

          while (today.isAfter(cycleDate) || cycleDate.isAtSameMomentAs(today)) {
            missedMonths++;
            DateTime cyclePenaltyDate = cycleDate.add(const Duration(days: 5));
            
            if (today.isAfter(cyclePenaltyDate) || today.isAtSameMomentAs(cyclePenaltyDate)) {
               totalInterestOwed += (principal * 0.15);
               isAnyPenalty = true;
            } else {
               totalInterestOwed += (principal * 0.10);
            }
            
            cycleDate = _addOneMonth(cycleDate);
          }

          if (missedMonths == 0) totalInterestOwed = principal * 0.10;
          
          bool isLate = today.isAfter(dueDate);
          String finalStatus = isLate ? 'Late' : 'Active';
          String finalRateString = isAnyPenalty ? '15%' : '10%';

          if (l['status'] != finalStatus || l['interestRate'] != finalRateString || (l['remainingInterest'] as num).toDouble() != totalInterestOwed || (l['missedMonths'] ?? 0) != missedMonths) {
            l['status'] = finalStatus;
            l['interestRate'] = finalRateString;
            l['remainingInterest'] = double.parse(totalInterestOwed.toStringAsFixed(2));
            l['missedMonths'] = missedMonths;
            requiresDBUpdate = true;
          }
        } else {
          // Principal is mathematically 0. The loan is locked holding frozen remainingInterest.
          if ((l['remainingInterest'] as num).toDouble() <= 0) {
             if (l['status'] != 'Completed') {
                l['status'] = 'Completed';
                requiresDBUpdate = true;
             }
          }
        }
      } catch (e) {
        debugPrint('Error evaluating loan dates: $e');
      }
    }

    if (requiresDBUpdate) {
      await StorageService.saveLoans(loans);
    }

    if (mounted) {
      setState(() {
        _allLoans = loans;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredLoans {
    return _allLoans.where((l) {
      final matchesSearch = l['borrower'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _filterStatus == 'All' || l['status'] == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LoansFilterBar(
              filterStatus: _filterStatus,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              onFilterChanged: (val) { if (val != null) setState(() => _filterStatus = val); },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : LoansList(loans: _filteredLoans, onUpdate: _loadData),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddLoanModal.show(context, onUpdate: _loadData),
        icon: const Icon(Icons.add_card),
        label: const Text('Add Loan'),
        backgroundColor: DashboardTheme.accentColor,
      ),
    );
  }
}
