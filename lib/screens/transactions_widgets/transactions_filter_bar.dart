import 'package:flutter/material.dart';

class TransactionsFilterBar extends StatelessWidget {
  final String filterType;
  final String filterDate;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onDateChanged;

  const TransactionsFilterBar({
    super.key,
    required this.filterType,
    required this.filterDate,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search by Member or Notes...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filterType,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: ['All Types', 'Contributions', 'Disbursements', 'Payments', 'Interest', 'Penalties'].map((String val) {
                      return DropdownMenuItem<String>(value: val, child: Text(val, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: onTypeChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filterDate,
                    isExpanded: true,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    items: ['All Time', 'Last 7 Days', 'This Month', 'Last Month'].map((String val) {
                      return DropdownMenuItem<String>(value: val, child: Text(val, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: onDateChanged,
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
