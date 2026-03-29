import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/storage_service.dart';

class MemberPenaltyBlocks {
  static List<Widget> buildGranularDeficitBlocks({
    required BuildContext context,
    required Map<String, dynamic> member,
    required Function(Map<String, dynamic>)? onUpdate,
    required StateSetter setState,
  }) {
    DateTime joined = DateFormat('MMM dd, yyyy').parse(member['joinedDate']);
    DateTime today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    List<Map<String, dynamic>> blocks = [];
    DateTime cycleDate = DateTime(joined.year, joined.month + 1, 1);

    Map<String, dynamic> customRates = member['customRates'] != null
        ? Map<String, dynamic>.from(member['customRates'])
        : {};

    while (cycleDate.isBefore(today) || cycleDate.isAtSameMomentAs(today)) {
      double target = (member['expectedReturn'] as num).toDouble();
      double contributionAsOfCycle = 0.0;

      if (member['contributions'] != null) {
        for (var contrib in member['contributions']) {
          DateTime contribDate =
              DateFormat('MMM dd, yyyy').parse(contrib['date']);
          if (contribDate.isBefore(cycleDate) ||
              contribDate.isAtSameMomentAs(cycleDate)) {
            contributionAsOfCycle += (contrib['amount'] as num).toDouble();
          }
        }
      }

      double currentDeficit = target - contributionAsOfCycle;
      bool isLate = false;
      bool isForgiven = false;
      double appliedRate = 0.10;

      if (currentDeficit > 0) {
        String cycleKey = DateFormat('MMM dd, yyyy').format(cycleDate);
        DateTime cyclePenaltyDate =
            cycleDate.add(Duration(days: member['gracePeriod'] ?? 5));

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
          appliedRate = 0.15;
          isLate = true;
        }

        double generated = currentDeficit * appliedRate;

        blocks.add({
          'month': DateFormat('MMMM yyyy').format(cycleDate),
          'generated': generated,
          'isLate': isLate,
          'isForgiven': isForgiven,
          'rawDate': cycleDate,
        });
      }

      cycleDate = DateTime(cycleDate.year, cycleDate.month + 1, 1);
    }

    if (blocks.isEmpty) {
      return [
        const Text(
          'No outstanding penalties detected.',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        )
      ];
    }

    return blocks.map((b) {
      double owed = b['generated'];
      bool isActive = blocks.indexOf(b) == 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                                : Colors.red.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${owed.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: b['isForgiven']
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (b['isForgiven'])
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Text(
                            'Manually Forgiven (10%) ',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                              child: Text(
                                '[Restore]',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else if (!b['isLate'])
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '10% Grace Active',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Text(
                            '15% Penalty Rate',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                              child: Text(
                                '[Adjust]',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isActive)
              _buildActiveButtons(context, b, member, setState, onUpdate)
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
    Map<String, dynamic> member,
    StateSetter setState,
    Function(Map<String, dynamic>)? onUpdate,
  ) {
    return Column(
      children: [
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
                onPressed: () {
                  _showPaymentDialog(
                    context: context,
                    label: '${b['month']} Deficit Penalty',
                    owed: b['generated'],
                    member: member,
                    setState: setState,
                    onUpdate: onUpdate,
                  );
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child:
                      const Text('Pay Month', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ],
        ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Forgive 10%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restore, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Restore 15%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

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
          'Confirm payment of ₱${owed.toStringAsFixed(2)}? This will clear the penalty for this month.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                List history = member['history'] ?? [];
                history.add({
                  'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  'type': 'Deficit Penalty Paid',
                  'amount': owed,
                });
                member['history'] = history;

                member['deficitInterest'] =
                    (member['deficitInterest'] ?? 0.0) - owed;
                if (member['deficitInterest'] < 0) {
                  member['deficitInterest'] = 0.0;
                }

                member['totalInterest'] = (member['deficitInterest'] ?? 0.0) +
                    (member['lateJoinInterest'] ?? 0.0);

                if (member['totalInterest'] <= 0) {
                  if ((member['contribution'] as num).toDouble() >=
                      (member['expectedReturn'] as num).toDouble()) {
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
                      '₱${owed.toStringAsFixed(2)} paid successfully towards $label!'),
                ),
              );
            },
            child:
                const Text('Pay Month', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class MemberPenaltyDialog {
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyForgiven ? Colors.red : Colors.green,
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              String cycleKey = DateFormat('MMM dd, yyyy').format(cycleDate);
              Map<String, dynamic> customRates = member['customRates'] != null
                  ? Map<String, dynamic>.from(member['customRates'])
                  : {};

              if (isCurrentlyForgiven) {
                customRates.remove(cycleKey);
              } else {
                customRates[cycleKey] = 0.10;
              }

              member['customRates'] = customRates;

              // Recalculate deficit interest
              DateTime joined =
                  DateFormat('MMM dd, yyyy').parse(member['joinedDate']);
              DateTime today = DateTime(DateTime.now().year,
                  DateTime.now().month, DateTime.now().day);
              DateTime calcCycleDate =
                  DateTime(joined.year, joined.month + 1, 1);
              double generatedDeficitInterest = 0.0;
              double target = (member['expectedReturn'] as num).toDouble();

              while (calcCycleDate.isBefore(today) ||
                  calcCycleDate.isAtSameMomentAs(today)) {
                double contributionAsOfCycle = 0.0;

                if (member['contributions'] != null) {
                  for (var contrib in member['contributions']) {
                    DateTime contribDate =
                        DateFormat('MMM dd, yyyy').parse(contrib['date']);
                    if (contribDate.isBefore(calcCycleDate) ||
                        contribDate.isAtSameMomentAs(calcCycleDate)) {
                      contributionAsOfCycle +=
                          (contrib['amount'] as num).toDouble();
                    }
                  }
                }

                double currentDeficit = target - contributionAsOfCycle;
                if (currentDeficit > 0) {
                  String calcCycleKey =
                      DateFormat('MMM dd, yyyy').format(calcCycleDate);
                  double appliedRate = 0.10;
                  DateTime cyclePenaltyDate = calcCycleDate
                      .add(Duration(days: member['gracePeriod'] ?? 5));

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

              member['deficitInterest'] = generatedDeficitInterest;
              member['totalInterest'] = generatedDeficitInterest +
                  (member['lateJoinInterest'] ?? 0.0);

              // Save to storage
              List<Map<String, dynamic>> members =
                  await StorageService.loadMembers() ?? [];
              int index = members.indexWhere((m) => m['id'] == member['id']);
              if (index != -1) {
                members[index]['customRates'] = customRates;
                members[index]['deficitInterest'] = member['deficitInterest'];
                members[index]['totalInterest'] = member['totalInterest'];
                await StorageService.saveMembers(members);
              }

              setState(() {});
              if (onUpdate != null) onUpdate(member);

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
            child: Text(
              isCurrentlyForgiven ? 'Restore 15%' : 'Forgive 10%',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
