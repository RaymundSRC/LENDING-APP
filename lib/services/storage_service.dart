import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _membersKey = 'members_data_prod';
  static const String _loansKey = 'loans_data_prod';

  /// Saves the current list of Members to local Shared Preferences as a JSON String
  static Future<void> saveMembers(List<Map<String, dynamic>> members) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(members);
    await prefs.setString(_membersKey, jsonString);
  }

  /// Loads the saved JSON string of members and decodes it back to a List of Maps
  static Future<List<Map<String, dynamic>>?> loadMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_membersKey);
      
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading members JSON: ₱e');
    }
    return null;
  }
  static Future<void> saveLoans(List<Map<String, dynamic>> loans) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(loans);
    await prefs.setString(_loansKey, jsonString);
  }

  static Future<List<Map<String, dynamic>>?> loadLoans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_loansKey);
      
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading loans JSON: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> loadAllTransactions() async {
    final members = await loadMembers() ?? [];
    final loans = await loadLoans() ?? [];
    List<Map<String, dynamic>> allTx = [];
    
    for (var m in members) {
       List h = m['history'] ?? [];
       for (var entry in h) {
          allTx.add({
             'id': m['id'],
             'originalDate': entry['date'],
             'date': entry['date'].toString().replaceAll(' 202', ' \'2'), 
             'name': m['name'],
             'type': entry['type'] ?? 'Contribution',
             'amount': (entry['amount'] as num).toDouble(),
             'isCredit': true,
             'notes': entry['type'] == 'Penalty' ? 'Cleared penalty fee' : 'Scheduled contribution',
          });
       }
    }

    for (var l in loans) {
       List h = l['paymentHistory'] ?? [];
       for (var entry in h) {
          double intPortion = (entry['interestPortion'] as num?)?.toDouble() ?? 0.0;
          double prinPortion = (entry['principalPortion'] as num?)?.toDouble() ?? 0.0;
          String notes = '';
          if (intPortion > 0 && prinPortion > 0) {
             notes = 'Interest: ₱${intPortion.toStringAsFixed(0)} | Principal: ₱${prinPortion.toStringAsFixed(0)}';
          } else if (intPortion > 0) {
             notes = 'Interest Payload: ₱${intPortion.toStringAsFixed(0)}';
          } else if (prinPortion > 0) {
             notes = 'Principal Reduction: ₱${prinPortion.toStringAsFixed(0)}';
          } else {
             notes = 'General Payment';
          }

          allTx.add({
             'id': l['id'],
             'originalDate': entry['date'],
             'date': entry['date'].toString().replaceAll(' 202', ' \'2'),
             'name': l['borrower'],
             'type': 'Loan Payment',
             'amount': (entry['amount'] as num).toDouble(),
             'isCredit': true,
             'notes': notes,
          });
       }
       
       if (l['borrowedDate'] != null) {
          allTx.add({
             'id': l['id'],
             'originalDate': l['borrowedDate'],
             'date': l['borrowedDate'].toString().replaceAll(' 202', ' \'2'),
             'name': l['borrower'],
             'type': 'Disbursed Loan',
             'amount': (l['amount'] as num).toDouble(),
             'isCredit': false,
             'notes': 'Initial Loan Disbursement',
          });
       }
    }

    allTx.sort((a, b) {
       try {
          DateTime dateA = DateFormat('MMM dd, yyyy').parse(a['originalDate']);
          DateTime dateB = DateFormat('MMM dd, yyyy').parse(b['originalDate']);
          return dateB.compareTo(dateA); 
       } catch(e) {
          return 0; 
       }
    });

    return allTx;
  }
}
