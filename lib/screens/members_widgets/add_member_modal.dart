import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/dashboard_theme.dart';

class AddMemberModal {
  static void show(BuildContext context, {required Function(Map<String, dynamic>) onSave, Map<String, dynamic>? initialMember}) {
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
          child: _AddMemberForm(onSave: onSave, initialMember: initialMember),
        );
      },
    );
  }
}

class _AddMemberForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialMember;
  
  const _AddMemberForm({required this.onSave, this.initialMember});

  @override
  State<_AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends State<_AddMemberForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _status = 'With Balance';

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _targetAmountController.addListener(() => setState(() {}));
    
    if (widget.initialMember != null) {
      final m = widget.initialMember!;
      _nameController.text = m['name'] ?? '';
      _amountController.text = (m['contribution'] ?? '').toString();
      _targetAmountController.text = (m['expectedReturn'] ?? '').toString();
      _status = m['status'] == 'Active' ? 'With Balance' : (m['status'] ?? 'With Balance');
      try {
        _selectedDate = DateFormat('MMM dd, yyyy').parse(m['date']);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  double get _targetAmount => double.tryParse(_targetAmountController.text) ?? 0.0;
  double get _amount => double.tryParse(_amountController.text) ?? 0.0;

  int get _monthsMissed {
    if (_selectedDate.year > DateTime.now().year) return 0;
    return _selectedDate.month > 1 ? _selectedDate.month - 1 : 0;
  }

  double get _deficitInterestRate {
    // A strict 1-month grace period based precisely on calendar date exactness.
    DateTime oneMonthLater = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    if (today.isAfter(oneMonthLater)) {
      return 0.15;
    }
    return 0.10;
  }

  double get _deficitInterest {
    if (_amount < _targetAmount) {
      return (_targetAmount - _amount) * _deficitInterestRate;
    }
    return 0.0;
  }

  double get _lateJoinInterest {
    if (_monthsMissed > 0 && _targetAmount > 0) {
      return (_targetAmount * 0.15) * _monthsMissed;
    }
    return 0.0;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
          Text(widget.initialMember == null ? 'Add New Member' : 'Edit Member', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Enter the details for the member below.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          _buildTextField('Full Name', Icons.person, _nameController),
          const SizedBox(height: 16),
          _buildTextField('Amount (₱)', Icons.account_balance_wallet, _amountController, TextInputType.number),
          const SizedBox(height: 16),
          _buildTextField('Target Amount (₱)', Icons.track_changes, _targetAmountController, TextInputType.number),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(
              labelText: 'Membership Status',
              prefixIcon: const Icon(Icons.verified_user),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardTheme.accentColor)),
            ),
            items: ['With Balance', 'Pending', 'With Penalty', 'Completed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) { if (val != null) setState(() => _status = val); },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'Date: ${DateFormat('MMMM dd, yyyy').format(_selectedDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, size: 16, color: DashboardTheme.accentColor),
                ],
              ),
            ),
          ),
          if (_targetAmount > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Interest Calculations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                  const SizedBox(height: 8),
                  if (_amount < _targetAmount)
                    Text('• Deficit Penalty (₱${(_targetAmount - _amount).toStringAsFixed(2)}): +₱${_deficitInterest.toStringAsFixed(2)} (${(_deficitInterestRate * 100).toInt()}%)', style: TextStyle(color: Colors.orange.shade800)),
                  if (_monthsMissed > 0)
                    Text('• Late Join ($_monthsMissed months missed): +₱${_lateJoinInterest.toStringAsFixed(2)} (15%)', style: TextStyle(color: Colors.orange.shade800)),
                  if (_amount >= _targetAmount && _monthsMissed == 0)
                    Text('No penalty applied. Goal met on time!', style: TextStyle(color: Colors.green.shade800)),
                  if (_deficitInterest > 0 || _lateJoinInterest > 0) ...[
                    const Divider(),
                    Text('Total Interest: ₱${(_deficitInterest + _lateJoinInterest).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                  ]
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardTheme.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                String finalStatus = _status == 'Active' ? 'With Balance' : _status;
                if ((_deficitInterest > 0 || _lateJoinInterest > 0) && finalStatus == 'With Balance') {
                  finalStatus = 'With Penalty';
                } else if (_amount >= _targetAmount && _deficitInterest == 0 && _lateJoinInterest == 0 && finalStatus == 'With Balance') {
                  finalStatus = 'Completed';
                }

                final newMember = {
                  'id': widget.initialMember?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': _nameController.text.trim(),
                  'contribution': _amount,
                  'expectedReturn': _targetAmount,
                  'deficitInterest': _deficitInterest,
                  'lateJoinInterest': _lateJoinInterest,
                  'totalInterest': _deficitInterest + _lateJoinInterest,
                  'date': DateFormat('MMM dd, yyyy').format(_selectedDate),
                  'status': finalStatus,
                  'history': widget.initialMember?['history'] ?? [
                    {'date': DateFormat('MMM dd, yyyy').format(_selectedDate), 'type': 'Initial Deposit', 'amount': _amount}
                  ],
                  'loans': widget.initialMember?['loans'] ?? []
                };
                widget.onSave(newMember);
                Navigator.pop(context);
              },
              child: Text(widget.initialMember == null ? 'Save Member' : 'Update Member', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, [TextInputType keyboardType = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardTheme.accentColor)),
      ),
    );
  }
}

