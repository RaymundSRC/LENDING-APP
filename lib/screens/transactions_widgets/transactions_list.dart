import 'package:flutter/material.dart';

class TransactionsList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const TransactionsList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions match the filters.', style: TextStyle(color: Colors.black54)));
    }

    Map<String, List<Map<String, dynamic>>> groupedTx = {};
    for (var t in transactions) {
       String date = t['date'].toString().replaceAll('\'2', '202');
       if (!groupedTx.containsKey(date)) groupedTx[date] = [];
       groupedTx[date]!.add(t);
    }

    return ListView.builder(
      itemCount: groupedTx.keys.length,
      itemBuilder: (context, index) {
        String dateKey = groupedTx.keys.elementAt(index);
        List<Map<String, dynamic>> dayTx = groupedTx[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
              child: Text(dateKey, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            ...dayTx.map((t) {
              final isCredit = t['isCredit'] as bool;
              
              IconData typeIcon;
              Color typeColor;
              String tType = t['type'].toString();
              if (tType.contains('Penalty')) {
                typeIcon = Icons.warning; typeColor = Colors.red;
              } else if (tType.contains('Contribution')) {
                typeIcon = Icons.savings; typeColor = Colors.blue;
              } else if (tType.contains('Disbursed')) {
                typeIcon = Icons.account_balance_wallet; typeColor = Colors.orange;
              } else if (tType.contains('Loan Payment')) {
                typeIcon = Icons.payments; typeColor = Colors.green;
              } else {
                typeIcon = Icons.receipt; typeColor = Colors.grey;
              }

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: typeColor.withOpacity(0.1),
                        radius: 20,
                        child: Icon(typeIcon, color: typeColor, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(t['notes'], style: const TextStyle(color: Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isCredit ? '+₱${t['amount']}' : '-₱${t['amount']}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isCredit ? Colors.green : Colors.red),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(t['type'], style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
