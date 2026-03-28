import 'package:flutter/material.dart';
import '../../theme/dashboard_theme.dart';

class TransactionsHeader extends StatelessWidget {
  final VoidCallback onExportCSV;
  final VoidCallback onExportPDF;

  const TransactionsHeader({super.key, required this.onExportCSV, required this.onExportPDF});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Financial Ledger', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        Row(
          children: [
            TextButton.icon(
              onPressed: onExportCSV,
              icon: const Icon(Icons.file_download, size: 18),
              label: const Text('CSV'),
              style: TextButton.styleFrom(foregroundColor: DashboardTheme.accentColor),
            ),
            TextButton.icon(
              onPressed: onExportPDF,
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('PDF'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ],
        )
      ],
    );
  }
}
