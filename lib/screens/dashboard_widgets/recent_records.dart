import 'package:flutter/material.dart';
import '../../theme/dashboard_theme.dart';

/// Recent records widget for dashboard
/// Displays tabbed view of recent members and loans with status indicators
class RecentRecords extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> loans;
  const RecentRecords({super.key, required this.members, required this.loans});

  // === UI LAYOUT ===

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Members and Loans tabs
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Records',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 12),

          // Tab container with fixed height for scrolling
          Container(
            height: 380, // Fixed height to allow scrolling within
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                // Tab bar for switching between Members and Loans
                const TabBar(
                  labelColor: DashboardTheme.accentColor,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: DashboardTheme.accentColor,
                  tabs: [
                    Tab(text: 'Members'),
                    Tab(text: 'Loans'),
                  ],
                ),

                // Tab content views
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildMembersData(),
                      _buildLoansData(),
                    ],
                  ),
                ),

                // View all records button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextButton(
                    onPressed: () {}, // TODO: Navigate to full records view
                    child: const Text('View All Records',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === END OF UI LAYOUT ===

  // === MEMBERS DATA SECTION ===

  /// Builds the members tab content with recent member records
  Widget _buildMembersData() {
    // Show 6 most recent members (newest first)
    final recent = members.reversed.take(6).toList();
    if (recent.isEmpty) {
      return const Center(
          child: Text('No members registered yet.',
              style: TextStyle(color: Colors.black54)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(0),
      itemCount: recent.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey.shade200), // Separator line
      itemBuilder: (context, index) {
        final m = recent[index];

        // === FINANCIAL SUMMARY ===

        // Calculate member status for display
        double totalInt =
            (m['deficitInterest'] ?? 0.0) + (m['lateJoinInterest'] ?? 0.0);
        double cont = (m['contribution'] as num).toDouble();
        double exp = (m['expectedReturn'] as num).toDouble();

        // Determine display status based on contributions and penalties
        String displayStatus =
            m['status'] == 'Active' ? 'With Balance' : m['status'];
        if (displayStatus != 'Pending') {
          if (cont >= (exp - 0.01) && totalInt <= 0.01) {
            displayStatus = 'Completed';
          } else if (totalInt > 0.01) {
            displayStatus = 'With Penalty';
          } else {
            displayStatus = 'With Balance';
          }
        }

        // Assign color based on status
        Color statusColor;
        switch (displayStatus) {
          case 'With Balance':
            statusColor = Colors.green;
            break;
          case 'Pending':
            statusColor = Colors.orange;
            break;
          case 'With Penalty':
            statusColor = Colors.red;
            break;
          case 'Completed':
            statusColor = Colors.blue;
            break;
          default:
            statusColor = Colors.grey;
        }

        // === END OF FINANCIAL SUMMARY ===

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor:
                statusColor.withOpacity(0.1), // Status color background
            child: Text(m['name'].toString().substring(0, 1).toUpperCase(),
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ),
          title: Text(m['name'].toString(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
              'Joined: ${m['date']} • TGT: ₱${exp.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱${cont.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4), // Spacing between amount and status
              Text(displayStatus,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor)), // Status label with color
            ],
          ),
        );
      },
    );
  }

  // === END OF MEMBERS DATA SECTION ===

  // === LOANS DATA SECTION ===

  /// Builds the loans tab content with recent loan records
  Widget _buildLoansData() {
    // Show 6 most recent loans (newest first)
    final recent = loans.reversed.take(6).toList();
    if (recent.isEmpty) {
      return const Center(
          child: Text('No loans generated yet.',
              style: TextStyle(color: Colors.black54)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(0),
      itemCount: recent.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey.shade200), // Separator line
      itemBuilder: (context, index) {
        final l = recent[index];

        // Assign color based on loan status
        Color statusColor;
        switch (l['status']) {
          case 'Active':
            statusColor = Colors.green;
            break;
          case 'Completed':
            statusColor = Colors.blue;
            break;
          case 'Pending':
            statusColor = Colors.orange;
            break;
          case 'Late':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.grey;
        }

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor:
                statusColor.withOpacity(0.1), // Status color background
            child: Icon(Icons.account_balance_wallet,
                color: statusColor, size: 20), // Loan icon
          ),
          title: Text(l['borrower'].toString(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('Due: ${l['dueDate']}',
              style: const TextStyle(fontSize: 12)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱${(l['amount'] as num).toDouble().toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4), // Spacing between amount and status
              Text(l['status'].toString(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor)), // Status label with color
            ],
          ),
        );
      },
    );
  }

  // === END OF LOANS DATA SECTION ===
}

// === END OF CLASS ===
