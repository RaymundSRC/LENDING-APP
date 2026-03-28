import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/storage_service.dart';
import 'transactions_widgets/transactions_header.dart';
import 'transactions_widgets/transactions_filter_bar.dart';
import 'transactions_widgets/transactions_list.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  String _filterType = 'All Types';
  String _filterDate = 'All Time';

  List<Map<String, dynamic>> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final tx = await StorageService.loadAllTransactions();
    if (mounted) {
       setState(() {
          _allTransactions = tx;
       });
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    return _allTransactions.where((t) {
      final matchesSearch = t['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            t['notes'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                            
      bool matchesType = false;
      String tType = t['type'].toString();
      String tNotes = t['notes'].toString();

      if (_filterType == 'All Types') {
        matchesType = true;
      } else if (_filterType == 'Contributions') {
        matchesType = tType.contains('Initial Deposit') || tType.contains('Contribution');
      } else if (_filterType == 'Disbursements') {
        matchesType = tType.contains('Loan Disbursed');
      } else if (_filterType == 'Payments') {
        matchesType = tType.contains('Loan Payment');
      } else if (_filterType == 'Interest') {
        matchesType = tNotes.contains('Interest') || tType.contains('Interest');
      } else if (_filterType == 'Penalties') {
        matchesType = tType.contains('Penalty');
      }

      bool matchesDate = false;
      if (_filterDate == 'All Time') {
        matchesDate = true;
      } else {
         try {
           DateTime tDate = DateFormat('MMM dd, yyyy').parse(t['date'].toString().replaceAll("'2", "202"));
           DateTime today = DateTime.now();
           if (_filterDate == 'Last 7 Days') {
              matchesDate = today.difference(tDate).inDays <= 7 && today.difference(tDate).inDays >= 0;
           } else if (_filterDate == 'This Month') {
              matchesDate = tDate.year == today.year && tDate.month == today.month;
           } else if (_filterDate == 'Last Month') {
              int lastMonth = today.month == 1 ? 12 : today.month - 1;
              int lastMonthYear = today.month == 1 ? today.year - 1 : today.year;
              matchesDate = tDate.year == lastMonthYear && tDate.month == lastMonth;
           } else {
              matchesDate = true;
           }
         } catch (_) {
           matchesDate = true; // Fallback unconditionally
         }
      }

      return matchesSearch && matchesType && matchesDate;
    }).toList();
  }

  void _exportRoutine(String format) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exporting Ledger as ₱format...')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TransactionsHeader(
              onExportCSV: () => _exportRoutine('CSV'),
              onExportPDF: () => _exportRoutine('PDF'),
            ),
            const SizedBox(height: 16),
            TransactionsFilterBar(
              filterType: _filterType,
              filterDate: _filterDate,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              onTypeChanged: (val) { if (val != null) setState(() => _filterType = val); },
              onDateChanged: (val) { if (val != null) setState(() => _filterDate = val); },
            ),
            const SizedBox(height: 16),
            Expanded(child: TransactionsList(transactions: _filteredTransactions)),
          ],
        ),
      ),
    );
  }
}
