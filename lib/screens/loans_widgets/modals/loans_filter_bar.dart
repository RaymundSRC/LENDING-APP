import 'package:flutter/material.dart';

/// Filter bar widget for loans list with search and status filtering
class LoansFilterBar extends StatelessWidget {
  final String filterStatus; // Current filter status
  final ValueChanged<String> onSearchChanged; // Callback for search changes
  final ValueChanged<String?> onFilterChanged; // Callback for filter changes

  const LoansFilterBar({
    super.key,
    required this.filterStatus,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search field (takes 2/3 of space)
        Expanded(
          flex: 2, // 2 parts of 3
          child: TextField(
            onChanged: onSearchChanged, // Handle search input
            decoration: InputDecoration(
              hintText: 'Search borrower...', // Search placeholder
              prefixIcon: const Icon(Icons.search), // Search icon
              filled: true, // Fill background
              fillColor: Colors.white, // White background
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none), // Rounded border
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0), // Compact padding
            ),
          ),
        ),
        const SizedBox(width: 12), // Spacing between search and filter
        // Status filter dropdown (takes 1/3 of space)
        Expanded(
          flex: 1, // 1 part of 3
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12), // Horizontal padding
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                    12)), // White background with rounded corners
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: filterStatus.isEmpty
                    ? null
                    : filterStatus, // Current filter value
                isExpanded: true,
                icon: const Icon(Icons.filter_list),
                items: ['All', 'On-time', 'Late', 'Pending'].map((String val) {
                  return DropdownMenuItem<String>(
                      value: val,
                      child: Text(val, style: const TextStyle(fontSize: 14)));
                }).toList(),
                onChanged: onFilterChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
