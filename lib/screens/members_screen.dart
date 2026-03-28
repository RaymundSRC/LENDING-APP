import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/dashboard_theme.dart';
import 'members_widgets/members_filter_bar.dart';
import 'members_widgets/members_list.dart';
import 'members_widgets/add_member_modal.dart';
import '../services/storage_service.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _searchQuery = '';
  String _filterStatus = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMembers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime _addOneMonth(DateTime date) {
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

  Future<void> _loadData() async {
    try {
      final storedMembers = await StorageService.loadMembers();
      List<Map<String, dynamic>> mems = storedMembers ?? [];

      bool requiresDBUpdate = false;
      DateTime today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);

      for (var m in mems) {
        if (m['status'] == 'Completed' || m['status'] == 'Pending') continue;

        try {
          DateTime joinedDate = DateFormat('MMM dd, yyyy').parse(m['date']);
          double target = (m['expectedReturn'] as num).toDouble();
          List history = m['history'] ?? [];

          double totalPaidDeficitInterest = 0.0;
          for (var h in history) {
            if (h['type'] != null &&
                h['type'].toString().contains('Deficit Penalty Paid')) {
              totalPaidDeficitInterest +=
                  ((h['amount'] ?? 0.0) as num).toDouble();
            }
          }

          double generatedDeficitInterest = 0.0;
          DateTime cycleDate = _addOneMonth(joinedDate);

          while (
              today.isAfter(cycleDate) || cycleDate.isAtSameMomentAs(today)) {
            DateTime cyclePenaltyDate = cycleDate.add(const Duration(days: 5));

            // Re-calculate the specific deficit at this exact point in history
            double contributionAsOfCycle = 0.0;
            for (var h in history) {
              if (h['type'] != null &&
                  !h['type'].toString().contains('Penalty')) {
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
              double appliedRate = 0.10;
              String cycleKey = DateFormat('MMM dd, yyyy').format(cycleDate);
              Map<String, dynamic> customRates = m['customRates'] != null
                  ? Map<String, dynamic>.from(m['customRates'])
                  : {};

              if (customRates.containsKey(cycleKey)) {
                appliedRate = (customRates[cycleKey] as num).toDouble();
              } else if (today.isAfter(cyclePenaltyDate) ||
                  today.isAtSameMomentAs(cyclePenaltyDate)) {
                appliedRate = 0.15; // Late 15%
              } else {
                appliedRate = 0.10; // Active Grace 10%
              }
              generatedDeficitInterest += (currentDeficit * appliedRate);
            }
            cycleDate = _addOneMonth(cycleDate);
          }

          double newDeficitInterest =
              generatedDeficitInterest - totalPaidDeficitInterest;
          if (newDeficitInterest < 0) newDeficitInterest = 0.0;

          double oldDeficitInterest =
              ((m['deficitInterest'] ?? 0.0) as num).toDouble();

          if ((newDeficitInterest - oldDeficitInterest).abs() > 0.01) {
            double lateJoin =
                ((m['lateJoinInterest'] ?? 0.0) as num).toDouble();
            m['deficitInterest'] =
                double.parse(newDeficitInterest.toStringAsFixed(2));
            m['totalInterest'] = double.parse(
                (newDeficitInterest + lateJoin).toStringAsFixed(2));

            double cont = (m['contribution'] as num).toDouble();
            String displayStatus =
                m['status'] == 'Active' ? 'With Balance' : m['status'];

            if (cont >= (target - 0.01) && m['totalInterest'] <= 0.01) {
              displayStatus = 'Completed';
            } else if (m['totalInterest'] > 0.01) {
              displayStatus = 'With Penalty';
            } else if (cont < (target - 0.01)) {
              displayStatus = 'With Balance';
            }

            m['status'] = displayStatus;
            requiresDBUpdate = true;
          }
        } catch (e) {
          // Skip rows that fail to parse
        }
      }

      if (requiresDBUpdate) {
        await StorageService.saveMembers(mems);
      }

      if (mounted) {
        setState(() {
          _allMembers = mems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allMembers = [];
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    return _allMembers.where((m) {
      final matchesSearch = m['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

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
        } else if (cont < (exp - 0.01)) {
          displayStatus = 'With Balance';
        }
      }

      final matchesStatus =
          _filterStatus == 'All' || displayStatus == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: DashboardTheme.accentColor));
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MembersFilterBar(
              filterStatus: _filterStatus,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              onFilterChanged: (val) {
                if (val != null) setState(() => _filterStatus = val);
              },
            ),
            Expanded(
              child: MembersList(
                members: _filteredMembers,
                onEdit: (member) {
                  AddMemberModal.show(context, initialMember: member,
                      onSave: (updated) async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() {
                      final i = _allMembers
                          .indexWhere((m) => m['id'] == updated['id']);
                      if (i != -1) _allMembers[i] = updated;
                    });
                    await StorageService.saveMembers(_allMembers);
                    messenger.showSnackBar(SnackBar(
                        content:
                            Text('${updated['name']} updated successfully!')));
                  });
                },
                onUpdateState: (updated) async {
                  setState(() {
                    final i =
                        _allMembers.indexWhere((m) => m['id'] == updated['id']);
                    if (i != -1) _allMembers[i] = updated;
                  });
                  await StorageService.saveMembers(_allMembers);
                },
                onDelete: (id) {
                  showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                              title: const Text('Remove Member'),
                              content: const Text(
                                  'Are you sure you want to completely delete this member? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    setState(() {
                                      _allMembers
                                          .removeWhere((m) => m['id'] == id);
                                    });
                                    await StorageService.saveMembers(
                                        _allMembers);
                                    messenger.showSnackBar(const SnackBar(
                                        content: Text(
                                            'Member permanently deleted.')));
                                  },
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.white)),
                                )
                              ]));
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddMemberModal.show(
          context,
          onSave: (newMember) async {
            final messenger = ScaffoldMessenger.of(context);
            setState(() {
              _allMembers.add(newMember);
            });
            await StorageService.saveMembers(_allMembers);
            messenger.showSnackBar(
              SnackBar(
                  content: Text(
                      '${newMember['name']} added successfully! Saved permanently.')),
            );
          },
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
        backgroundColor: DashboardTheme.accentColor,
      ),
    );
  }
}
