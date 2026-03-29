import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/dashboard_theme.dart';
import '../../../services/storage_service.dart';

class AddLoanModal {
  static void show(BuildContext context, {Function? onUpdate}) {
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
            top: 24,
            left: 24,
            right: 24,
          ),
          child: _AddLoanForm(onUpdate: onUpdate),
        );
      },
    );
  }
}

class _AddLoanForm extends StatefulWidget {
  final Function? onUpdate;
  const _AddLoanForm({this.onUpdate});

  @override
  State<_AddLoanForm> createState() => _AddLoanFormState();
}

class _AddLoanFormState extends State<_AddLoanForm> {
  DateTime _borrowedDate = DateTime.now();

  final TextEditingController _borrowerController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  double _requestedAmount = 0.0;
  double _availableFund = 0.0;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _loans = [];

  @override
  void initState() {
    super.initState();
    _loadFundData();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _borrowerController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadFundData() async {
    print('DEBUG: Loading fund data...');
    final members = await StorageService.loadMembers() ?? [];
    final loans = await StorageService.loadLoans() ?? [];

    print('DEBUG: Loaded ${members.length} members and ${loans.length} loans');

    if (mounted) {
      setState(() {
        _members = members;
        _loans = loans;
        _availableFund = _calculateAvailableFund();
      });
    }
  }

  double _calculateAvailableFund() {
    double baseCapital = _members.fold(0.0,
        (sum, item) => sum + ((item['contribution'] ?? 0.0) as num).toDouble());
    double activePrincipalOut = _loans.fold(0.0,
        (sum, l) => sum + ((l['remainingPrincipal'] ?? 0.0) as num).toDouble());
    double available = baseCapital - activePrincipalOut;

    print('DEBUG: Fund Calculation:');
    print('  - Members count: ${_members.length}');
    print('  - Base Capital: ₱${baseCapital.toStringAsFixed(2)}');
    print('  - Loans count: ${_loans.length}');
    print(
        '  - Active Principal Out: ₱${activePrincipalOut.toStringAsFixed(2)}');
    print('  - Available Fund: ₱${available.toStringAsFixed(2)}');

    return available;
  }

  void _onAmountChanged() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _requestedAmount = amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    double advanceDeduction = _requestedAmount * 0.10;
    double disbursedAmount = _requestedAmount - advanceDeduction;
    double monthlyInterest = _requestedAmount * 0.10;

    DateTime nextDueDate = _addOneMonth(_borrowedDate);
    DateTime penaltyDate = nextDueDate.add(const Duration(days: 5));

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
          const Text('Issue New Loan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('10% advance deduction applies. 1 month standard cycle.',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          _buildTextField(
              'Borrower Full Name', Icons.person, _borrowerController),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            tileColor: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200)),
            leading: const Icon(Icons.calendar_month,
                color: DashboardTheme.accentColor),
            title: const Text('Date Borrowed',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            subtitle: Text(DateFormat('MMMM dd, yyyy').format(_borrowedDate),
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
                initialDate: _borrowedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _borrowedDate = picked);
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
              'Requested Amount (₱) - e.g. 10000',
              Icons.account_balance_wallet,
              _amountController,
              TextInputType.number),
          const SizedBox(height: 16),

          // Fund availability status
          _buildFundStatusCard(),

          const SizedBox(height: 16),
          _buildTextField('Reason (Optional)', Icons.notes, _reasonController),
          const SizedBox(height: 24),
          if (_requestedAmount > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DISBURSEMENT BREAKDOWN',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.black87)),
                  const SizedBox(height: 12),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Base Loan Debt:'),
                        Text('₱${_requestedAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('10% Upfront Deduction:'),
                        Text('- ₱${advanceDeduction.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold))
                      ]),
                  const Divider(height: 24),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cash to Disburse Now:'),
                        Text('₱${disbursedAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.green,
                                fontWeight: FontWeight.bold))
                      ]),
                  const SizedBox(height: 24),
                  const Text('TERMS & CONDITIONS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.black87)),
                  const SizedBox(height: 12),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Next Interest (10%):'),
                        Text('₱${monthlyInterest.toStringAsFixed(2)} / month',
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('First Due Date:'),
                        Text(DateFormat('MMM dd, yyyy').format(nextDueDate),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: DashboardTheme.accentColor))
                      ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.red.shade100.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'If unpaid by ${DateFormat('MMM dd').format(nextDueDate)} — ${DateFormat('MMM dd').format(penaltyDate.subtract(const Duration(days: 1)))}, the rate will automatically escalate to 15% starting ${DateFormat('MMM dd').format(penaltyDate)}.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _requestedAmount > _availableFund
                    ? Colors.grey
                    : Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _requestedAmount > _availableFund ? null : _saveLoan,
              child: Text(
                  _requestedAmount > _availableFund
                      ? 'Insufficient Funds (Available: ₱${_availableFund.toStringAsFixed(2)})'
                      : 'Confirm & Disburse ₱${disbursedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, IconData icon, TextEditingController controller,
      [TextInputType keyboardType = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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
            borderSide: const BorderSide(color: DashboardTheme.accentColor)),
      ),
    );
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

  Future<void> _saveLoan() async {
    String borrower = _borrowerController.text.trim();
    if (_requestedAmount <= 0 || borrower.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid borrower name and amount.')));
      return;
    }

    // Fund availability validation
    print('DEBUG: Available Fund: ₱${_availableFund.toStringAsFixed(2)}');
    print('DEBUG: Requested Amount: ₱${_requestedAmount.toStringAsFixed(2)}');
    print('DEBUG: Has sufficient funds: ${_requestedAmount <= _availableFund}');

    if (_requestedAmount > _availableFund) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Insufficient funds! Available: ₱${_availableFund.toStringAsFixed(2)}, Requested: ₱${_requestedAmount.toStringAsFixed(2)}'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    DateTime nextDueDate = _addOneMonth(_borrowedDate);
    DateTime penaltyDate = nextDueDate.add(const Duration(days: 5));

    final newLoan = {
      'id': 'L${DateTime.now().millisecondsSinceEpoch}',
      'borrower': borrower,
      'amount': _requestedAmount,
      'disbursedAmount': _requestedAmount * 0.90, // Net received
      'interestRate': '10%',
      'borrowedDate': DateFormat('MMM dd, yyyy').format(_borrowedDate),
      'dueDate': DateFormat('MMM dd, yyyy').format(nextDueDate),
      'penaltyDate': DateFormat('MMM dd, yyyy').format(penaltyDate),
      'totalPaid': 0.0,
      'remainingInterest': _requestedAmount * 0.10,
      'remainingPrincipal': _requestedAmount,
      'status': 'Active',
      'reason': _reasonController.text,
      'paymentHistory': [],
      'schedule': [],
    };

    final loans = await StorageService.loadLoans() ?? [];
    loans.add(newLoan);
    await StorageService.saveLoans(loans);

    if (widget.onUpdate != null) widget.onUpdate!();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '₱${(_requestedAmount * 0.90).toStringAsFixed(2)} disbursed to $borrower!')));
      Navigator.pop(context);
    }
  }

  Widget _buildFundStatusCard() {
    double remainingAfterLoan = _availableFund - _requestedAmount;
    bool hasSufficientFunds = _requestedAmount <= _availableFund;
    Color statusColor = hasSufficientFunds ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSufficientFunds ? Icons.check_circle : Icons.warning,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Fund Availability',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Fund:'),
              Text(
                '₱${_availableFund.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('After This Loan:'),
              Text(
                '₱${remainingAfterLoan.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: remainingAfterLoan >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          if (!hasSufficientFunds) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Insufficient funds! Requested amount exceeds available fund.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
