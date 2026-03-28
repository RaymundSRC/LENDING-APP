import 'package:flutter/material.dart';
import '../../theme/dashboard_theme.dart';

class RecentRecords extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> loans;
  const RecentRecords({super.key, required this.members, required this.loans});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          Container(
            height: 380, // Fixed height to allow scrolling within
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                const TabBar(
                  labelColor: DashboardTheme.accentColor,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: DashboardTheme.accentColor,
                  tabs: [
                    Tab(text: 'Members'),
                    Tab(text: 'Loans'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildMembersData(),
                      _buildLoansData(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('View All Records', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersData() {
    // Show 6 most recent members
    final recent = members.reversed.take(6).toList();
    if (recent.isEmpty) {
      return const Center(child: Text('No members registered yet.', style: TextStyle(color: Colors.black54)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(0),
      itemCount: recent.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final m = recent[index];
        double totalInt = (m['deficitInterest'] ?? 0.0) + (m['lateJoinInterest'] ?? 0.0);
        double cont = (m['contribution'] as num).toDouble();
        double exp = (m['expectedReturn'] as num).toDouble();
        
        String displayStatus = m['status'] == 'Active' ? 'With Balance' : m['status'];
        if (displayStatus != 'Pending') {
          if (cont >= (exp - 0.01) && totalInt <= 0.01) {
            displayStatus = 'Completed';
          } else if (totalInt > 0.01) {
            displayStatus = 'With Penalty';
          } else {
            displayStatus = 'With Balance';
          }
        }

        Color statusColor;
        switch (displayStatus) {
          case 'With Balance': statusColor = Colors.green; break;
          case 'Pending': statusColor = Colors.orange; break;
          case 'With Penalty': statusColor = Colors.red; break;
          case 'Completed': statusColor = Colors.blue; break;
          default: statusColor = Colors.grey;
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Text(m['name'].toString().substring(0, 1).toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ),
          title: Text(m['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('Joined: ${m['date']} • TGT: ₱${exp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱${cont.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(displayStatus, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoansData() {
    final recent = loans.reversed.take(6).toList();
    if (recent.isEmpty) {
      return const Center(child: Text('No loans generated yet.', style: TextStyle(color: Colors.black54)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(0),
      itemCount: recent.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final l = recent[index];
        Color statusColor;
        switch (l['status']) {
          case 'Active': statusColor = Colors.green; break;
          case 'Completed': statusColor = Colors.blue; break;
          case 'Pending': statusColor = Colors.orange; break;
          case 'Late': statusColor = Colors.red; break;
          default: statusColor = Colors.grey;
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Icon(Icons.account_balance_wallet, color: statusColor, size: 20),
          ),
          title: Text(l['borrower'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('Due: ${l['dueDate']}', style: const TextStyle(fontSize: 12)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱${(l['amount'] as num).toDouble().toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(l['status'].toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
            ],
          ),
        );
      },
    );
  }
}
