import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/dashboard_theme.dart';
import '../../../services/storage_service.dart';
import '../components/member_penalty_blocks.dart';
import '../components/member_payment_history.dart';

class MemberProfileModal {
  static void show(BuildContext context, Map<String, dynamic> member,
      {Function(Map<String, dynamic>)? onUpdate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setState) {
                // Calculate member status and colors
                MemberStatusInfo statusInfo = _calculateMemberStatus(member);

                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with drag handle
                      Center(
                          child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4)))),

                      // Member info header
                      _buildMemberHeader(member, statusInfo),
                      const SizedBox(height: 24),

                      // Summary cards
                      ...MemberPaymentHistory.buildSummaryCards(member),
                      const SizedBox(height: 24),

                      // Payment actions
                      _buildPaymentActions(context, member, setState, onUpdate),
                      const SizedBox(height: 32),

                      // Granular deficit blocks
                      const Text('Monthly Penalties',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...MemberPenaltyBlocks.buildGranularDeficitBlocks(
                        context: context,
                        member: member,
                        onUpdate: onUpdate,
                        setState: setState,
                      ),
                      const SizedBox(height: 32),

                      // Payment history
                      const Text('Payment History',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      ...MemberPaymentHistory.buildPaymentHistory(member),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static MemberStatusInfo _calculateMemberStatus(Map<String, dynamic> member) {
    double totalInt = (member['deficitInterest'] ?? 0.0) +
        (member['lateJoinInterest'] ?? 0.0);
    double cont = (member['contribution'] as num).toDouble();
    double exp = (member['expectedReturn'] as num).toDouble();
    double remaining = exp - cont;
    if (remaining < 0) remaining = 0;

    String displayStatus =
        member['status'] == 'Active' ? 'With Balance' : member['status'];
    if (displayStatus != 'Pending') {
      if (cont >= (exp - 0.01) && totalInt <= 0.01) {
        displayStatus = 'Completed';
      } else if (totalInt > 0.01) {
        displayStatus = 'With Penalty';
      } else {
        displayStatus = 'With Balance';
      }
    }

    Color statusColor = displayStatus == 'With Balance'
        ? Colors.green
        : (displayStatus == 'Pending'
            ? Colors.orange
            : (displayStatus == 'With Penalty' ? Colors.red : Colors.blue));

    return MemberStatusInfo(
      displayStatus: displayStatus,
      statusColor: statusColor,
      totalInterest: totalInt,
      contribution: cont,
      expectedReturn: exp,
      remaining: remaining,
    );
  }

  static Widget _buildMemberHeader(
      Map<String, dynamic> member, MemberStatusInfo statusInfo) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: statusInfo.statusColor.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: statusInfo.statusColor,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member['name'] ?? 'Unknown Member',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'ID: ${member['id'] ?? '-'}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                'Joined: ${member['joinedDate'] ?? '-'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Chip(
          label: Text(statusInfo.displayStatus),
          backgroundColor: statusInfo.statusColor.withOpacity(0.1),
          labelStyle: TextStyle(
            color: statusInfo.statusColor,
            fontWeight: FontWeight.bold,
          ),
          side: BorderSide.none,
        ),
      ],
    );
  }

  static Widget _buildPaymentActions(
    BuildContext context,
    Map<String, dynamic> member,
    StateSetter setState,
    Function(Map<String, dynamic>)? onUpdate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Add Contribution'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _showContributionDialog(
                    context, member, setState, onUpdate),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DashboardTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () =>
                    _showEditMemberDialog(context, member, setState, onUpdate),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static void _showContributionDialog(
    BuildContext context,
    Map<String, dynamic> member,
    StateSetter setState,
    Function(Map<String, dynamic>)? onUpdate,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the contribution amount:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₱)',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(ctx);
                setState(() {
                  // Update contribution
                  member['contribution'] =
                      (member['contribution'] as num).toDouble() + amount;

                  // Add to history
                  List history = member['history'] ?? [];
                  history.add({
                    'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
                    'type': 'Contribution Paid',
                    'amount': amount,
                  });
                  member['history'] = history;

                  // Update status
                  double contribution =
                      (member['contribution'] as num).toDouble();
                  double expectedReturn =
                      (member['expectedReturn'] as num).toDouble();
                  double totalInterest = (member['deficitInterest'] ?? 0.0) +
                      (member['lateJoinInterest'] ?? 0.0);

                  if (totalInterest <= 0.01) {
                    if (contribution >= (expectedReturn - 0.01)) {
                      member['status'] = 'Completed';
                    } else {
                      member['status'] = 'With Balance';
                    }
                  }
                });

                if (onUpdate != null) onUpdate(member);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '₱${amount.toStringAsFixed(2)} contribution added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void _showEditMemberDialog(
    BuildContext context,
    Map<String, dynamic> member,
    StateSetter setState,
    Function(Map<String, dynamic>)? onUpdate,
  ) {
    final nameController = TextEditingController(text: member['name'] ?? '');
    final expectedController =
        TextEditingController(text: member['expectedReturn']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Member Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Member Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: expectedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Expected Return (₱)',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: DashboardTheme.accentColor),
            onPressed: () async {
              final name = nameController.text.trim();
              final expectedReturn = double.tryParse(expectedController.text);

              if (name.isNotEmpty &&
                  expectedReturn != null &&
                  expectedReturn > 0) {
                Navigator.pop(ctx);

                // Update member
                member['name'] = name;
                member['expectedReturn'] = expectedReturn;

                // Save to storage
                List<Map<String, dynamic>> members =
                    await StorageService.loadMembers() ?? [];
                int index = members.indexWhere((m) => m['id'] == member['id']);
                if (index != -1) {
                  members[index]['name'] = name;
                  members[index]['expectedReturn'] = expectedReturn;
                  await StorageService.saveMembers(members);
                }

                setState(() {});
                if (onUpdate != null) onUpdate(member);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Member information updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class MemberStatusInfo {
  final String displayStatus;
  final Color statusColor;
  final double totalInterest;
  final double contribution;
  final double expectedReturn;
  final double remaining;

  MemberStatusInfo({
    required this.displayStatus,
    required this.statusColor,
    required this.totalInterest,
    required this.contribution,
    required this.expectedReturn,
    required this.remaining,
  });
}
