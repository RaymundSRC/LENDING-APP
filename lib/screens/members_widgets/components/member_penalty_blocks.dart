import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/storage_service.dart';

/// Utility class for managing member penalty blocks and calculations
class MemberPenaltyBlocks {
  // === DEFICIT PENALTY CALCULATIONS ===

  /// Builds granular deficit penalty blocks for each payment cycle
  static List<Widget> buildGranularDeficitBlocks({
    required BuildContext context,
    required Map<String, dynamic> member,
    required Function(Map<String, dynamic>)? onUpdate,
    required StateSetter setState,
  }) {
    // Initialize date calculations
    final joined = DateFormat('MMM dd, yyyy').parse(member['joinedDate']);
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final blocks = <Map<String, dynamic>>[];
    var cycleDate = DateTime(joined.year, joined.month + 1, 1);

    // Load custom penalty rates with null safety
    final customRates = member['customRates'] != null
        ? Map<String, dynamic>.from(member['customRates'])
        : <String, dynamic>{};

    // Process each payment cycle from join date to today
    while (cycleDate.isBefore(today) || cycleDate.isAtSameMomentAs(today)) {
      final target = (member['expectedReturn'] as num).toDouble();
      var contributionAsOfCycle = 0.0;

      // Calculate total contributions up to current cycle
      if (member['contributions'] != null) {
        for (var contrib in member['contributions']) {
          final contribDate = DateFormat('MMM dd, yyyy').parse(contrib['date']);
          if (contribDate.isBefore(cycleDate) ||
              contribDate.isAtSameMomentAs(cycleDate)) {
            contributionAsOfCycle += (contrib['amount'] as num).toDouble();
          }
        }
      }

      final currentDeficit = target - contributionAsOfCycle;
      var isLate = false;
      var isForgiven = false;
      var appliedRate = 0.10;

      // Calculate penalty if deficit exists
      if (currentDeficit > 0) {
        final cycleKey = DateFormat('MMM dd, yyyy').format(cycleDate);
        final cyclePenaltyDate =
            cycleDate.add(Duration(days: member['gracePeriod'] ?? 5));

        // Check for custom rates (forgiven penalties)
        if (customRates.containsKey(cycleKey)) {
          appliedRate = (customRates[cycleKey] as num).toDouble();
          if (appliedRate <= 0.10 &&
              (today.isAfter(cyclePenaltyDate) ||
                  today.isAtSameMomentAs(cyclePenaltyDate))) {
            isForgiven = true;
            isLate = true;
          }
        } else if (today.isAfter(cyclePenaltyDate) ||
            today.isAtSameMomentAs(cyclePenaltyDate)) {
          appliedRate = 0.15; // Apply higher rate after grace period
          isLate = true;
        }

        final generated = currentDeficit * appliedRate;

        blocks.add({
          'month': DateFormat('MMMM yyyy').format(cycleDate),
          'generated': generated,
          'isLate': isLate,
          'isForgiven': isForgiven,
          'rawDate': cycleDate,
        });
      }

      // Move to next month
      cycleDate = DateTime(cycleDate.year, cycleDate.month + 1, 1);
    }

    // Return empty state if no penalties
    if (blocks.isEmpty) {
      return [
        const Text('No outstanding penalties detected.',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
      ];
    }

    // Build UI blocks for each penalty
    return blocks.map((b) {
      final owed = b['generated'] as double;
      final isActive = blocks.indexOf(b) == 0; // First block is active

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        // Color coding: green for forgiven, red for active
        decoration: BoxDecoration(
          color: b['isForgiven'] ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: b['isForgiven']
                  ? Colors.green.shade200
                  : Colors.red.shade200),
        ),
        child: Row(
          children: [
            // Penalty information section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status icon and month label
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
                            : Colors.red.shade900,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${b['month']} Penalty',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: b['isForgiven']
                                  ? Colors.green.shade900
                                  : Colors.red.shade900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Penalty amount
                  Text(
                    '₱${owed.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 16,
                        color: b['isForgiven']
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.bold),
                  ),
                  // Status indicators and actions
                  if (b['isForgiven'])
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Text('Manually Forgiven (10%) ',
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                          if (isActive)
                            GestureDetector(
                              onTap: () => MemberPenaltyDialog.show(
                                context: context,
                                cycleDate: b['rawDate'],
                                monthLabel: b['month'],
                                isCurrentlyForgiven: true,
                                member: member,
                                setState: setState,
                                onUpdate: onUpdate,
                              ),
                              child: Text('[Restore]',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline)),
                            ),
                        ],
                      ),
                    )
                  else if (!b['isLate'])
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('10% Grace Active',
                          style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    )
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Text('15% Penalty Rate',
                              style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                          if (isActive)
                            GestureDetector(
                              onTap: () => MemberPenaltyDialog.show(
                                context: context,
                                cycleDate: b['rawDate'],
                                monthLabel: b['month'],
                                isCurrentlyForgiven: false,
                                member: member,
                                setState: setState,
                                onUpdate: onUpdate,
                              ),
                              child: Text('[Adjust]',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline)),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action buttons or lock icon
            if (isActive)
              _buildActiveButtons(context, b, member, setState, onUpdate)
            else
              const Icon(Icons.lock_rounded,
                  color: Colors.redAccent,
                  size: 24), // Inactive penalties are locked
          ],
        ),
      );
    }).toList();
  }

  // === END OF DEFICIT PENALTY CALCULATIONS ===

  // === ACTIVE PENALTY CONTROLS ===

  /// Builds action buttons for active penalty blocks
  static Widget _buildActiveButtons(
    BuildContext context,
    Map<String, dynamic> b,
    Map<String, dynamic> member,
    StateSetter setState,
    Function(Map<String, dynamic>)? onUpdate,
  ) {
    return Column(
      children: [
        // Primary payment button
        Row(
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _showPaymentDialog(
                  context: context,
                  label: '${b['month']} Deficit Penalty',
                  owed: b['generated'],
                  member: member,
                  setState: setState,
                  onUpdate: onUpdate,
                ),
                child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Pay Month', style: TextStyle(fontSize: 12))),
              ),
            ),
          ],
        ),
        // Forgiveness option for late penalties
        if (b['isLate'] && !b['isForgiven']) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onPressed: () => MemberPenaltyDialog.show(
                context: context,
                cycleDate: b['rawDate'],
                monthLabel: b['month'],
                isCurrentlyForgiven: false,
                member: member,
                setState: setState,
                onUpdate: onUpdate,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 16),
                  SizedBox(width: 8),
                  Text('Forgive 10%',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
        // Restore option for forgiven penalties
        if (b['isForgiven']) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onPressed: () => MemberPenaltyDialog.show(
                context: context,
                cycleDate: b['rawDate'],
                monthLabel: b['month'],
                isCurrentlyForgiven: true,
                member: member,
                setState: setState,
                onUpdate: onUpdate,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restore, size: 16),
                  SizedBox(width: 8),
                  Text('Restore 15%',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // === END OF ACTIVE PENALTY CONTROLS ===

  // === PAYMENT PROCESSING ===

  /// Shows payment confirmation dialog and processes payment
  static void _showPaymentDialog({
    required BuildContext context,
    required String label,
    required double owed,
    required Map<String, dynamic> member,
    required StateSetter setState,
    required Function(Map<String, dynamic>)? onUpdate,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay $label'),
        content: Text(
            'Confirm payment of ₱${owed.toStringAsFixed(2)}? This will clear the penalty for this month.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          // Process payment on confirmation
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              setState(() {
                // Record payment in history
                final history = member['history'] ?? [];
                history.add({
                  'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  'type': 'Deficit Penalty Paid',
                  'amount': owed,
                });
                member['history'] = history;

                // Update deficit interest
                member['deficitInterest'] =
                    (member['deficitInterest'] ?? 0.0) - owed;
                if (member['deficitInterest'] < 0) {
                  member['deficitInterest'] = 0.0; // Prevent negative values
                }

                // Recalculate total interest
                member['totalInterest'] = (member['deficitInterest'] ?? 0.0) +
                    (member['lateJoinInterest'] ?? 0.0);

                // Update member status
                if (member['totalInterest'] <= 0) {
                  if ((member['contribution'] as num).toDouble() >=
                      (member['expectedReturn'] as num).toDouble()) {
                    member['status'] = 'Completed';
                  } else {
                    member['status'] = 'With Balance';
                  }
                }
              });

              // Notify parent of changes
              if (onUpdate != null) onUpdate(member);

              // Show success feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        '₱${owed.toStringAsFixed(2)} paid successfully towards $label!')),
              );
            },
            child:
                const Text('Pay Month', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // === END OF PAYMENT PROCESSING ===
}

/// Dialog handler for penalty forgiveness and restoration
class MemberPenaltyDialog {
  // === PENALTY ADJUSTMENT DIALOG ===

  /// Shows dialog to forgive or restore penalty rates
  static void show({
    required BuildContext context,
    required DateTime cycleDate,
    required String monthLabel,
    required bool isCurrentlyForgiven,
    required Map<String, dynamic> member,
    required StateSetter setState,
    required Function(Map<String, dynamic>)? onUpdate,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCurrentlyForgiven
            ? 'Restore 15% Penalty'
            : 'Grant Leniency Override'),
        content: Text(isCurrentlyForgiven
            ? 'Are you sure you want to restore $monthLabel back to the 15% penalty rate?'
            : 'Permanently forgive the 15% penalty for $monthLabel, reducing it to 10%?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          // Process penalty adjustment
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCurrentlyForgiven ? Colors.red : Colors.green),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog

              final cycleKey = DateFormat('MMM dd, yyyy').format(cycleDate);
              final customRates = member['customRates'] != null
                  ? Map<String, dynamic>.from(member['customRates'])
                  : <String, dynamic>{};

              // Update custom rates based on action
              if (isCurrentlyForgiven) {
                customRates.remove(cycleKey); // Remove forgiveness
              } else {
                customRates[cycleKey] = 0.10; // Apply 10% rate
              }

              member['customRates'] = customRates;

              // Recalculate all deficit interest
              final joined =
                  DateFormat('MMM dd, yyyy').parse(member['joinedDate']);
              final today = DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day);
              var calcCycleDate = DateTime(joined.year, joined.month + 1, 1);
              var generatedDeficitInterest = 0.0;
              final target = (member['expectedReturn'] as num).toDouble();

              // Process each cycle to recalculate penalties
              while (calcCycleDate.isBefore(today) ||
                  calcCycleDate.isAtSameMomentAs(today)) {
                var contributionAsOfCycle = 0.0;

                if (member['contributions'] != null) {
                  for (var contrib in member['contributions']) {
                    final contribDate =
                        DateFormat('MMM dd, yyyy').parse(contrib['date']);
                    if (contribDate.isBefore(calcCycleDate) ||
                        contribDate.isAtSameMomentAs(calcCycleDate)) {
                      contributionAsOfCycle +=
                          (contrib['amount'] as num).toDouble();
                    }
                  }
                }

                final currentDeficit = target - contributionAsOfCycle;
                if (currentDeficit > 0) {
                  final calcCycleKey =
                      DateFormat('MMM dd, yyyy').format(calcCycleDate);
                  var appliedRate = 0.10;
                  final cyclePenaltyDate = calcCycleDate
                      .add(Duration(days: member['gracePeriod'] ?? 5));

                  // Apply custom or default rate
                  if (customRates.containsKey(calcCycleKey)) {
                    appliedRate = (customRates[calcCycleKey] as num).toDouble();
                  } else if (today.isAfter(cyclePenaltyDate) ||
                      today.isAtSameMomentAs(cyclePenaltyDate)) {
                    appliedRate = 0.15;
                  }

                  generatedDeficitInterest += (currentDeficit * appliedRate);
                }

                calcCycleDate =
                    DateTime(calcCycleDate.year, calcCycleDate.month + 1, 1);
              }

              // Update member data
              member['deficitInterest'] = generatedDeficitInterest;
              member['totalInterest'] = generatedDeficitInterest +
                  (member['lateJoinInterest'] ?? 0.0);

              // Persist changes to storage
              final members = await StorageService.loadMembers() ??
                  <Map<String, dynamic>>[];
              final index = members.indexWhere((m) => m['id'] == member['id']);
              if (index != -1) {
                members[index]['customRates'] = customRates;
                members[index]['deficitInterest'] = member['deficitInterest'];
                members[index]['totalInterest'] = member['totalInterest'];
                await StorageService.saveMembers(members);
              }

              setState(() {}); // Refresh UI
              if (onUpdate != null) onUpdate(member);

              // Show success feedback
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(isCurrentlyForgiven
                      ? 'Restored 15% penalty for $monthLabel'
                      : 'Successfully forgiven $monthLabel to 10%!'),
                  backgroundColor:
                      isCurrentlyForgiven ? Colors.red : Colors.green,
                ),
              );
            },
            child: Text(isCurrentlyForgiven ? 'Restore 15%' : 'Forgive 10%',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // === END OF PENALTY ADJUSTMENT DIALOG ===
}
