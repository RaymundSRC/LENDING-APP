import 'package:flutter/material.dart';

class LoanInterestBlocks {
  static List<Widget> buildInterestBlocks({
    required BuildContext context,
    required List<Map<String, dynamic>> interestBlocks,
    required double remainingPrincipalDB,
    required Function(DateTime, String, bool) onShowForgiveDialog,
    required Function(
            {int monthsToClear,
            double interestCost,
            double principalToPay,
            String label})
        onProcessPayment,
  }) {
    if (interestBlocks.isEmpty) {
      return [
        const Text('Outstanding monthly interest perfectly clear.',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
      ];
    }

    return interestBlocks.asMap().entries.map((entry) {
      int index = entry.key;
      var b = entry.value;
      bool isActive =
          index == 0; // Only the topmost chronological block is active

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: b['isForgiven'] ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: b['isForgiven']
                    ? Colors.green.shade200
                    : Colors.red.shade200)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                          b['isLate']
                              ? (b['isForgiven']
                                  ? Icons.check_circle
                                  : Icons.warning_rounded)
                              : Icons.info_outline,
                          size: 16,
                          color: b['isForgiven']
                              ? Colors.green.shade900
                              : Colors.red.shade900),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text('${b['month']} Interest',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: b['isForgiven']
                                      ? Colors.green.shade900
                                      : Colors.red.shade900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('₱${b['generated'].toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 16,
                          color: b['isForgiven']
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight: FontWeight.bold)),
                  if (b['isForgiven'])
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(children: [
                          Text('Manually Forgiven (10%) ',
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                          if (isActive)
                            GestureDetector(
                                onTap: () => onShowForgiveDialog(
                                    b['rawDate'], b['month'], true),
                                child: const Text('[Restore]',
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline)))
                        ]))
                  else if (!b['isLate'])
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('10% Grace Active',
                            style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)))
                  else
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(children: [
                          Text('15% Late Lock ',
                              style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                          if (isActive)
                            GestureDetector(
                                onTap: () => onShowForgiveDialog(
                                    b['rawDate'], b['month'], false),
                                child: const Text('[Forgive]',
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline)))
                        ])),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isActive)
              _buildActiveButtons(
                  context, b, onProcessPayment, onShowForgiveDialog)
            else
              const Icon(Icons.lock_rounded, color: Colors.redAccent, size: 24),
          ],
        ),
      );
    }).toList();
  }

  static Widget _buildActiveButtons(
    BuildContext context,
    Map<String, dynamic> b,
    Function(
            {int monthsToClear,
            double interestCost,
            double principalToPay,
            String label})
        onProcessPayment,
    Function(DateTime, String, bool) onShowForgiveDialog,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: b['isForgiven']
                    ? Colors.green.shade600
                    : Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                        title: Text('Pay ${b['month']} Interest'),
                        content: Text(
                            'Confirm payment of ₱${b['generated'].toStringAsFixed(2)}? This mathematically secures this cycle and actively advances your Due Date tracking.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel')),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600),
                              onPressed: () {
                                Navigator.pop(ctx);
                                onProcessPayment(
                                    monthsToClear: 1,
                                    interestCost: b['generated'],
                                    principalToPay: 0.0,
                                    label: '${b['month']} Interest');
                              },
                              child: const Text('Pay Month',
                                  style: TextStyle(color: Colors.white)))
                        ],
                      ));
            },
            child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Pay Month', style: TextStyle(fontSize: 12))),
          ),
        ),
        if (!b['isForgiven'] && b['isLate']) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              onPressed: () =>
                  onShowForgiveDialog(b['rawDate'], b['month'], false),
              child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Forgive\nto 10%',
                      style: TextStyle(fontSize: 10),
                      textAlign: TextAlign.center)),
            ),
          ),
        ],
        if (b['isForgiven']) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              onPressed: () =>
                  onShowForgiveDialog(b['rawDate'], b['month'], true),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Restore\n15%',
                    style: TextStyle(fontSize: 10),
                    textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
