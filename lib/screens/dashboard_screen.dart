import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'dashboard_widgets/quick_actions.dart';
import 'dashboard_widgets/summary_cards.dart';
import 'dashboard_widgets/charts_section.dart';
import 'dashboard_widgets/recent_records.dart';
import 'members_widgets/modals/add_member_modal.dart';
import 'loans_widgets/modals/add_loan_modal.dart';
import 'loans_widgets/modals/record_loan_payment_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _loans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final members = await StorageService.loadMembers() ?? [];
    final loans = await StorageService.loadLoans() ?? [];
    if (mounted) {
      setState(() {
        _members = members;
        _loans = loans;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuickActions(
            onAddMember: () =>
                AddMemberModal.show(context, onSave: (newMember) async {
              final messenger = ScaffoldMessenger.of(context);
              final mems = await StorageService.loadMembers() ?? [];
              mems.add(newMember);
              await StorageService.saveMembers(mems);
              messenger.showSnackBar(SnackBar(
                  content: Text('${newMember['name']} added securely!')));
              _loadData();
            }),
            onAddLoan: () => AddLoanModal.show(context, onUpdate: _loadData),
            onPayment: () {
              List<Map<String, dynamic>> activeLoans =
                  _loans.where((l) => l['status'] != 'Completed').toList();
              if (activeLoans.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('No active loans available for payment.')));
                return;
              }
              showDialog(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                        title: const Text('Select Loan for Payment'),
                        children: activeLoans
                            .map((l) => ListTile(
                                  leading: const Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.green),
                                  title: Text(l['borrower']),
                                  subtitle: Text(
                                      'Due: ₱${l['remainingPrincipal']} | Int: ₱${l['remainingInterest']}'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    RecordLoanPaymentModal.show(context, l,
                                        onUpdate: _loadData);
                                  },
                                ))
                            .toList(),
                      ));
            },
            onReport: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Building universal PDF Report...'))),
          ),
          const SizedBox(height: 24),
          SummaryCards(members: _members, loans: _loans),
          const SizedBox(height: 32),
          ChartsSection(members: _members, loans: _loans),
          const SizedBox(height: 32),
          RecentRecords(members: _members, loans: _loans),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
