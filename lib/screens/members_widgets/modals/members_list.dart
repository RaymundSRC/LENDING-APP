import 'package:flutter/material.dart';
import 'member_profile_modal.dart';

class MembersList extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onUpdateState;
  final Function(String) onDelete;

  const MembersList(
      {super.key,
      required this.members,
      required this.onEdit,
      required this.onUpdateState,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Center(
          child: Text('No members found matching the criteria.',
              style: TextStyle(color: Colors.black54)));
    }

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final m = members[index];
        double totalInt =
            (m['deficitInterest'] ?? 0.0) + (m['lateJoinInterest'] ?? 0.0);
        double cont = (m['contribution'] as num).toDouble();
        double exp = (m['expectedReturn'] as num).toDouble();

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

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () =>
                MemberProfileModal.show(context, m, onUpdate: (updatedMember) {
              onUpdateState(updatedMember);
            }),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Text(
                      m['name'].toString().substring(0, 1),
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Joined: ${m['date']}',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₱${m['contribution']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(displayStatus,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit(m);
                      if (value == 'remove') onDelete(m['id']);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Edit Member')),
                      const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove Member',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
