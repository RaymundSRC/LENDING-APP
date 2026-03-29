import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/dashboard_theme.dart';
import '../../../services/storage_service.dart';

class MemberProfileModal {
  static void show(BuildContext context, Map<String, dynamic> member,
      {Function(Map<String, dynamic>)? onUpdate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setState) {
                double totalInt = (member['deficitInterest'] ?? 0.0) +
                    (member['lateJoinInterest'] ?? 0.0);
                double cont = (member['contribution'] as num).toDouble();
                double exp = (member['expectedReturn'] as num).toDouble();
                double remaining = exp - cont;
                if (remaining < 0) remaining = 0;

                String displayStatus = member['status'] == 'Active'
                    ? 'With Balance'
                    : member['status'];
                if (displayStatus != 'Pending') {
                  if (cont >= (exp - 0.01) && totalInt <= 0.01) {
                    displayStatus = 'Completed';
                  } else if (totalInt > 0.01) {
                    displayStatus = 'With Penalty';
                  } else {
                    displayStatus = 'With Balance';
                  }
                }

                Color statusColor = displayStatus == 'With Balance'
                    ? Colors.green
                    : (displayStatus == 'Pending'
                        ? Colors.orange
                        : (displayStatus == 'With Penalty'
                            ? Colors.red
                            : Colors.blue));

                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4)))),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: statusColor.withOpacity(0.1),
                            child: Text(
                                member['name'].toString().substring(0, 1),
                                style: TextStyle(
                                    fontSize: 28,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member['name'],
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                                Text('Joined ${member['date']}',
                                    style:
                                        const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          Chip(
                              label: Text(displayStatus),
                              backgroundColor: statusColor.withOpacity(0.1),
                              labelStyle: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold),
                              side: BorderSide.none)
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text('Outstanding Penalties',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if ((member['deficitInterest'] ?? 0) <= 0 &&
                          (member['lateJoinInterest'] ?? 0) <= 0)
                        remaining > 0
                            ? const Text('Current penalties paid natively.',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold))
                            : const Text(
                                'No outstanding penalties. Member is in completely clear standing.',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold))
                      else
                        ...[],
                      if (remaining > 0) ...[
                        const SizedBox(height: 16),
                        _buildUpcomingPenaltyWarning(member),
                      ],
                      if ((member['deficitInterest'] ?? 0) > 0)
                        ..._buildGranularDeficitBlocks(
                            context, setState, member, onUpdate),
                      if ((member['lateJoinInterest'] ?? 0) > 0)
                        _buildPenaltyRow(
                            'Late Join Penalty',
                            member['lateJoinInterest'],
                            context,
                            setState,
                            member,
                            onUpdate,
                            'lateJoinInterest'),
                      const SizedBox(height: 32),
                      const Text('Financial Summary',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildInfoCard(
                                  'Target',
                                  '₱${exp.toStringAsFixed(2)}',
                                  Icons.track_changes)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _buildInfoCard(
                                  'Paid',
                                  '₱${cont.toStringAsFixed(2)}',
                                  Icons.account_balance_wallet)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _buildInfoCard(
                                  'Remaining',
                                  '₱${remaining.toStringAsFixed(2)}',
                                  Icons.payments)),
                        ],
                      ),
                      if (member['contribution'] <
                          member['expectedReturn']) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: DashboardTheme.accentColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0),
                            icon:
                                const Icon(Icons.payment, color: Colors.white),
                            label: Text(
                                'Pay Remaining Balance (₱${member['expectedReturn'] - member['contribution']})',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            onPressed: () {
                              double deficit = (member['expectedReturn'] as num)
                                      .toDouble() -
                                  (member['contribution'] as num).toDouble();
                              _showPaymentDialog(
                                  context, 'Remaining Balance', deficit,
                                  (paidAmount) {
                                setState(() {
                                  member['contribution'] =
                                      (member['contribution'] as num)
                                              .toDouble() +
                                          paidAmount;

                                  List history = member['history'] ?? [];
                                  history.add({
                                    'date': DateFormat('MMM dd, yyyy')
                                        .format(DateTime.now()),
                                    'type': 'Contribution Payment',
                                    'amount': paidAmount
                                  });

                                  if ((member['contribution'] as num)
                                          .toDouble() >=
                                      (member['expectedReturn'] as num)
                                          .toDouble()) {
                                    if ((member['totalInterest'] ?? 0.0) <= 0) {
                                      member['status'] = 'Completed';
                                    } else {
                                      member['status'] = 'With Penalty';
                                    }
                                  }
                                });
                                if (onUpdate != null) onUpdate(member);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        '₱${paidAmount.toStringAsFixed(2)} Contribution Added!')));
                              });
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      const Text('Contribution History',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (member['history'] as List).length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final h = member['history'][index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.history,
                                color: Colors.black54),
                            title: Text(h['type']),
                            subtitle: Text(h['date']),
                            trailing: Text(
                              h['amount'] > 0
                                  ? '+₱${h['amount']}'
                                  : '-₱${h['amount'].abs()}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: h['amount'] > 0
                                      ? Colors.green
                                      : Colors.red),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      const Text('Loans Involved',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      (member['loans'] as List).isEmpty
                          ? const Text('No active loans associated.',
                              style: TextStyle(color: Colors.black54))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: (member['loans'] as List).length,
                              itemBuilder: (context, index) {
                                final l = member['loans'][index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.blue),
                                  title: Text('₱${l['amount']} Loan'),
                                  trailing: Text(l['status'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                );
                              },
                            ),
                      const SizedBox(height: 48),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static String _getDeficitExplanation(
      Map<String, dynamic> member, double amount) {
    double target = (member['expectedReturn'] as num).toDouble();
    double contribution = (member['contribution'] as num).toDouble();
    double currentDeficit = target - contribution;
    if (currentDeficit < 0) currentDeficit = 0;

    int daysPassed = 0;
    double rate = 0.10;
    try {
      DateTime joinedDate = DateFormat('MMM dd, yyyy').parse(member['date']);
      daysPassed = DateTime.now().difference(joinedDate).inDays;
      DateTime oneMonthLater =
          DateTime(joinedDate.year, joinedDate.month + 1, joinedDate.day);
      DateTime today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (today.isAfter(oneMonthLater)) rate = 0.15;
    } catch (_) {}

    return '''DEFICIT PENALTY BREAKDOWN:
• Target Goal: ₱${target.toStringAsFixed(2)}
• Current Contribution: ₱${contribution.toStringAsFixed(2)}
• Current Deficit: ₱${currentDeficit.toStringAsFixed(2)}

TIME ASSESSMENT:
• Joined Date: ${member['date']}
• Days Elapsed: $daysPassed days
• Applicable Rate: ${(rate * 100).toInt()}% (Jumps to 15% after 1mo)

MATH CALCULATION:
₱${currentDeficit.toStringAsFixed(2)} × $rate = ₱${(currentDeficit * rate).toStringAsFixed(2)} raw penalty

Remaining Penalty to Pay: ₱${amount.toStringAsFixed(2)}
(Note: If you made partial balance/penalty payments previously, this remaining fee is accurate to your ledger.)''';
  }

  static String _getLateJoinExplanation(
      Map<String, dynamic> member, double amount) {
    double target = (member['expectedReturn'] as num).toDouble();

    int monthsMissed = 0;
    try {
      DateTime joinedDate = DateFormat('MMM dd, yyyy').parse(member['date']);
      if (joinedDate.year <= DateTime.now().year && joinedDate.month > 1) {
        monthsMissed = joinedDate.month - 1;
      }
    } catch (_) {}

    double rawLatePenalty = (target * 0.15) * monthsMissed;

    return '''LATE JOIN PENALTY BREAKDOWN:
• Target Goal: ₱${target.toStringAsFixed(2)}
• Joined Date: ${member['date']}
• Months Missed Since January: $monthsMissed months
• Monthly Penalty Rate: 15% of Target Amount

MATH CALCULATION:
₱${target.toStringAsFixed(2)} × 15% × $monthsMissed months = ₱${rawLatePenalty.toStringAsFixed(2)}

Remaining Penalty to Pay: ₱${amount.toStringAsFixed(2)}
(Note: If you made partial penalty payments previously, this remaining fee is accurate to your ledger.)''';
  }

  static List<Widget> _buildGranularDeficitBlocks(
      BuildContext context,
      StateSetter setState,
      Map<String, dynamic> member,
      Function(Map<String, dynamic>)? onUpdate) {
    if ((member['deficitInterest'] ?? 0) <= 0) return [];

    try {
      DateTime joinedDate = DateFormat('MMM dd, yyyy').parse(member['date']);
      double target = (member['expectedReturn'] as num).toDouble();
      List history = member['history'] ?? [];

      double totalPaid = 0.0;
      for (var h in history) {
        if (h['type'] != null &&
            h['type'].toString().contains('Deficit Penalty Paid')) {
          totalPaid += ((h['amount'] ?? 0.0) as num).toDouble();
        }
      }

      List<Map<String, dynamic>> blocks = [];
      DateTime cycleDate = _addOneMonth(joinedDate);
      DateTime today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);

      while (today.isAfter(cycleDate) || cycleDate.isAtSameMomentAs(today)) {
        DateTime cyclePenaltyDate = cycleDate.add(const Duration(days: 5));

        double contributionAsOfCycle = 0.0;
        for (var h in history) {
          if (h['type'] != null && !h['type'].toString().contains('Penalty')) {
            try {
              DateTime hDate = DateFormat('MMM dd, yyyy').parse(h['date']);
              if (hDate.isBefore(cyclePenaltyDate) ||
                  hDate.isAtSameMomentAs(cyclePenaltyDate)) {
                contributionAsOfCycle +=
                    ((h['amount'] ?? 0.0) as num).toDouble();
              }
            } catch (_) {}
          }
        }

        double currentDeficit = target - contributionAsOfCycle;
        if (currentDeficit > 0) {
          double generated = 0.0;
          bool isLate = false;
          bool isForgiven = false;
          double appliedRate = 0.10;
          String cycleKey = DateFormat('MMM dd, yyyy').format(cycleDate);
          Map<String, dynamic> customRates = member['customRates'] != null
              ? Map<String, dynamic>.from(member['customRates'])
              : {};

          if (customRates.containsKey(cycleKey)) {
            appliedRate = (customRates[cycleKey] as num).toDouble();
            if (today.isAfter(cyclePenaltyDate) ||
                today.isAtSameMomentAs(cyclePenaltyDate)) {
              generated = currentDeficit * appliedRate;
              isLate = true;
              if (appliedRate <= 0.10) isForgiven = true;
            } else {
              generated = currentDeficit * appliedRate;
            }
          } else if (today.isAfter(cyclePenaltyDate) ||
              today.isAtSameMomentAs(cyclePenaltyDate)) {
            generated = currentDeficit * 0.15;
            appliedRate = 0.15;
            isLate = true;
          } else {
            generated = currentDeficit * 0.10;
            appliedRate = 0.10;
          }

          blocks.add({
            'month': DateFormat('MMMM yyyy').format(cycleDate),
            'generated': generated,
            'isLate': isLate,
            'isForgiven': isForgiven,
            'appliedRate': appliedRate,
            'cycleKey': cycleKey,
            'rawDate': cycleDate,
          });
        }
        cycleDate = _addOneMonth(cycleDate);
      }

      // Chronological subtraction logic
      for (var b in blocks) {
        if (totalPaid <= 0) break;
        double amt = b['generated'];
        if (totalPaid >= amt) {
          b['generated'] = 0.0; // Fully paid
          totalPaid -= amt;
        } else {
          b['generated'] = amt - totalPaid; // Partially paid balance
          totalPaid = 0.0;
        }
      }

      // UI widget builder
      List<Widget> widgets = [];
      for (var b in blocks) {
        if (b['generated'] > 0.01) {
          double owed = b['generated'];
          bool isForgiven = b['isForgiven'];
          bool isActive = !isForgiven && b['isLate'];

          widgets.add(Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: isForgiven ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isForgiven
                        ? Colors.green.shade200
                        : Colors.red.shade200)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                  b['isLate']
                                      ? (isForgiven
                                          ? Icons.check_circle
                                          : Icons.warning_rounded)
                                      : Icons.info_outline,
                                  size: 16,
                                  color: isForgiven
                                      ? Colors.green.shade900
                                      : Colors.red.shade900),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text('${b['month']} Penalty',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isForgiven
                                              ? Colors.green.shade900
                                              : Colors.red.shade900),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('₱${owed.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isForgiven
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  fontWeight: FontWeight.bold)),
                          if (isForgiven)
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
                                        onTap: () =>
                                            _showPenaltyAdjustmentDialog(
                                                context,
                                                b['rawDate'],
                                                b['month'],
                                                true,
                                                member,
                                                setState,
                                                onUpdate),
                                        child: Text('[Restore]',
                                            style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline)),
                                      ),
                                  ],
                                ))
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
                                child: Row(
                                  children: [
                                    Text('15% Penalty Rate',
                                        style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                    if (isActive)
                                      GestureDetector(
                                        onTap: () =>
                                            _showPenaltyAdjustmentDialog(
                                                context,
                                                b['rawDate'],
                                                b['month'],
                                                false,
                                                member,
                                                setState,
                                                onUpdate),
                                        child: Text('[Adjust]',
                                            style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline)),
                                      ),
                                  ],
                                )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: isForgiven
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0),
                        onPressed: () {
                          _showPaymentDialog(
                              context, '${b['month']} Deficit Penalty', owed,
                              (paidAmount) {
                            setState(() {
                              List history = member['history'] ?? [];
                              history.add({
                                'date': DateFormat('MMM dd, yyyy')
                                    .format(DateTime.now()),
                                'type': 'Deficit Penalty Paid',
                                'amount': paidAmount
                              });
                              member['deficitInterest'] =
                                  (member['deficitInterest'] ?? 0.0) -
                                      paidAmount;
                              if (member['deficitInterest'] < 0) {
                                member['deficitInterest'] = 0.0;
                              }
                              member['totalInterest'] =
                                  (member['deficitInterest'] ?? 0.0) +
                                      (member['lateJoinInterest'] ?? 0.0);

                              if (member['totalInterest'] <= 0) {
                                if ((member['contribution'] as num)
                                        .toDouble() >=
                                    (member['expectedReturn'] as num)
                                        .toDouble()) {
                                  member['status'] = 'Completed';
                                } else {
                                  member['status'] = 'With Balance';
                                }
                              }
                            });
                            if (onUpdate != null) onUpdate(member);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    '₱${paidAmount.toStringAsFixed(2)} paid seamlessly towards ${b['month']} penalties!')));
                          });
                        },
                        child: const Text('Pay Month'),
                      ),
                    ),
                    if (b['isLate'] && !isForgiven) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          onPressed: () => _showPenaltyAdjustmentDialog(
                              context,
                              b['rawDate'],
                              b['month'],
                              false,
                              member,
                              setState,
                              onUpdate),
                          child: const Text('Forgive 10%'),
                        ),
                      ),
                    ],
                    if (isForgiven) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          onPressed: () => _showPenaltyAdjustmentDialog(
                              context,
                              b['rawDate'],
                              b['month'],
                              true,
                              member,
                              setState,
                              onUpdate),
                          child: const Text('Restore 15%'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ));
        }
      }

      return widgets.isEmpty
          ? [
              _buildPenaltyRow('Deficit Penalty', member['deficitInterest'],
                  context, setState, member, onUpdate, 'deficitInterest')
            ]
          : widgets;
    } catch (_) {
      return [
        _buildPenaltyRow('Deficit Penalty', member['deficitInterest'], context,
            setState, member, onUpdate, 'deficitInterest')
      ];
    }
  }

  static Widget _buildPenaltyRow(
      String title,
      double amount,
      BuildContext context,
      StateSetter setState,
      Map<String, dynamic> member,
      Function(Map<String, dynamic>)? onUpdate,
      String penaltyKey) {
    String explanation = penaltyKey == 'deficitInterest'
        ? _getDeficitExplanation(member, amount)
        : _getLateJoinExplanation(member, amount);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900)),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                                    title: Text('About $title'),
                                    content: Text(explanation,
                                        style: const TextStyle(
                                            fontSize: 15, height: 1.5)),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Close'))
                                    ]));
                      },
                      child: Icon(Icons.info_outline,
                          size: 16, color: Colors.red.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('₱${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0),
            onPressed: () {
              _showPaymentDialog(context, title, amount, (paidAmount) {
                setState(() {
                  List history = member['history'] ?? [];
                  history.add({
                    'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
                    'type': '$title Paid',
                    'amount': paidAmount
                  });
                  member[penaltyKey] = amount - paidAmount;
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        '₱${paidAmount.toStringAsFixed(2)} Paid for $title!')));
              });
            },
            child: const Text('Pay Now'),
          )
        ],
      ),
    );
  }

  static void _showPaymentDialog(BuildContext context, String title,
      double maxAmount, Function(double) onPay) {
    TextEditingController controller =
        TextEditingController(text: maxAmount.toStringAsFixed(2));
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text('Pay $title'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outstanding Amount: ₱${maxAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Amount to Pay (₱)',
                          border: OutlineInputBorder()),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: DashboardTheme.accentColor),
                    onPressed: () {
                      double? amount = double.tryParse(controller.text);
                      // Allow partial payments and full payments, but not negative or over-payments.
                      if (amount != null && amount > 0 && amount <= maxAmount) {
                        Navigator.pop(ctx);
                        onPay(amount);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter a valid amount.')));
                      }
                    },
                    child: const Text('Confirm Payment',
                        style: TextStyle(color: Colors.white)),
                  )
                ]));
  }

  static Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
          color: DashboardTheme.accentColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: DashboardTheme.accentColor.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DashboardTheme.accentColor, size: 20),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(color: Colors.black54, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: DashboardTheme.accentColor)),
          ),
        ],
      ),
    );
  }

  static void _showPenaltyAdjustmentDialog(
    BuildContext context,
    DateTime cycleDate,
    String monthLabel,
    bool isCurrentlyForgiven,
    Map<String, dynamic> member,
    StateSetter setState,
    Function(Map<String, dynamic>)? onUpdate,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          title: Text(isCurrentlyForgiven
              ? 'Restore 15% Penalty Lock'
              : 'Grant Leniency Override'),
          content: Text(isCurrentlyForgiven
              ? 'Are you sure you want to revert $monthLabel back to the severe 15% late compounding lock?'
              : 'Permanently forgive the 15% severity lock for $monthLabel mathematically dropping it to the base 10% rate?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCurrentlyForgiven ? Colors.red : Colors.green),
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

                List<Map<String, dynamic>> members =
                    await StorageService.loadMembers() ?? [];
                int index = members.indexWhere((m) => m['id'] == member['id']);
                if (index != -1) {
                  members[index]['customRates'] = customRates;

                  // Recalculate deficit interest
                  double totalDeficitInterest = 0.0;
                  try {
                    DateTime joinedDate =
                        DateFormat('MMM dd, yyyy').parse(member['date']);
                    double target =
                        (member['expectedReturn'] as num).toDouble();
                    List history = member['history'] ?? [];
                    DateTime today = DateTime(DateTime.now().year,
                        DateTime.now().month, DateTime.now().day);
                    DateTime currentCycle = _addOneMonth(joinedDate);

                    while (today.isAfter(currentCycle) ||
                        currentCycle.isAtSameMomentAs(today)) {
                      DateTime penaltyDateLimit =
                          currentCycle.add(const Duration(days: 5));
                      String key =
                          DateFormat('MMM dd, yyyy').format(currentCycle);
                      double rate = 0.10;
                      bool penalty = today.isAfter(penaltyDateLimit) ||
                          today.isAtSameMomentAs(penaltyDateLimit);

                      if (customRates.containsKey(key)) {
                        rate = (customRates[key] as num).toDouble();
                      } else if (penalty) {
                        rate = 0.15;
                      }

                      double contributionAsOfCycle = 0.0;
                      for (var h in history) {
                        if (h['type'] != null &&
                            !h['type'].toString().contains('Penalty')) {
                          try {
                            DateTime hDate =
                                DateFormat('MMM dd, yyyy').parse(h['date']);
                            if (hDate.isBefore(penaltyDateLimit) ||
                                hDate.isAtSameMomentAs(penaltyDateLimit)) {
                              contributionAsOfCycle +=
                                  ((h['amount'] ?? 0.0) as num).toDouble();
                            }
                          } catch (_) {}
                        }
                      }

                      double currentDeficit = target - contributionAsOfCycle;
                      if (currentDeficit > 0) {
                        totalDeficitInterest += (currentDeficit * rate);
                      }
                      currentCycle = _addOneMonth(currentCycle);
                    }

                    double totalPaidDeficitInterest = 0.0;
                    for (var h in history) {
                      if (h['type'] != null &&
                          h['type']
                              .toString()
                              .contains('Deficit Penalty Paid')) {
                        totalPaidDeficitInterest +=
                            ((h['amount'] ?? 0.0) as num).toDouble();
                      }
                    }

                    double newDeficitInterest =
                        totalDeficitInterest - totalPaidDeficitInterest;
                    if (newDeficitInterest < 0) newDeficitInterest = 0.0;

                    members[index]['deficitInterest'] = newDeficitInterest;
                    members[index]['totalInterest'] = newDeficitInterest +
                        (members[index]['lateJoinInterest'] ?? 0.0);

                    // Update status
                    if (members[index]['totalInterest'] <= 0) {
                      if ((members[index]['contribution'] as num).toDouble() >=
                          (members[index]['expectedReturn'] as num)
                              .toDouble()) {
                        members[index]['status'] = 'Completed';
                      } else {
                        members[index]['status'] = 'With Balance';
                      }
                    } else {
                      members[index]['status'] = 'With Penalty';
                    }

                    await StorageService.saveMembers(members);
                    member['deficitInterest'] = newDeficitInterest;
                    member['totalInterest'] = members[index]['totalInterest'];
                    member['status'] = members[index]['status'];
                  } catch (e) {
                    debugPrint('Error recalculating deficit interest: $e');
                  }
                }

                setState(() {});
                if (onUpdate != null) onUpdate(member);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isCurrentlyForgiven
                        ? 'Restored 15% Penalty for $monthLabel'
                        : 'Successfully Forgiven $monthLabel!'),
                    backgroundColor:
                        isCurrentlyForgiven ? Colors.red : Colors.green));
              },
              child: Text(isCurrentlyForgiven ? 'Restore 15%' : 'Forgive 10%',
                  style: const TextStyle(color: Colors.white)),
            )
          ]),
    );
  }

  static DateTime _addOneMonth(DateTime date) {
    int nextYear = date.year;
    int nextMonth = date.month + 1;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    int maxDays = DateTime(nextYear, nextMonth + 1, 0).day;
    int nextDay = date.day > maxDays ? maxDays : date.day;
    return DateTime(nextYear, nextMonth, nextDay);
  }

  static Widget _buildUpcomingPenaltyWarning(Map<String, dynamic> member) {
    try {
      DateTime joinedDate = DateFormat('MMM dd, yyyy').parse(member['date']);
      DateTime today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      DateTime cycleDate = _addOneMonth(joinedDate);

      while (!cycleDate.isAfter(today)) {
        cycleDate = _addOneMonth(cycleDate);
      }

      DateTime penaltyDate = cycleDate.add(const Duration(days: 5));

      double target = (member['expectedReturn'] as num).toDouble();
      double cont = (member['contribution'] as num).toDouble();
      double remainingDeficit = target - cont;
      if (remainingDeficit < 0) remainingDeficit = 0.0;

      double est10 = remainingDeficit * 0.10;
      double est15 = remainingDeficit * 0.15;

      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.warning_amber_rounded,
                    size: 20, color: Colors.orange.shade900),
                const SizedBox(width: 8),
                Text('Upcoming Deficit Penalty Risk',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900)),
              ]),
              const SizedBox(height: 8),
              Text(
                  'Because base capital is unpaid, a 10% penalty will actively generate upon reaching your next cycle. A severe 15% penalty lock applies if not paid within the 5-day grace period threshold.',
                  style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                      height: 1.4)),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('10% Grace Active:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(DateFormat('MMM dd, yyyy').format(cycleDate),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 13)),
                              Text('+₱${est10.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800,
                                      fontSize: 15)),
                            ],
                          )
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('15% Late Lock:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  DateFormat('MMM dd, yyyy')
                                      .format(penaltyDate),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 13)),
                              Text('+₱${est15.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 15)),
                            ],
                          )
                        ],
                      ),
                    ]),
              )
            ],
          ));
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
