import 'package:flutter/material.dart';

class Transaction {
  final String type;
  final double amount;
  final String date;
  final String bank;
  final String refNo;
  final String accountNumber;
  final double? balance;
  final String? receiverName;
  final DateTime parsedDate;

  Transaction({
    required this.type,
    required this.amount,
    required this.date,
    required this.bank,
    required this.refNo,
    this.accountNumber = '',
    this.balance,
    this.receiverName,
  }) : parsedDate = _parseDate(date);

  static DateTime _parseDate(String date) {
    // Handle date format like "24Mar25"
    final RegExp dateRegex = RegExp(r'(\d{2})([A-Za-z]{3})(\d{2})');
    final match = dateRegex.firstMatch(date);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = _parseMonth(match.group(2)!);
      final year = 2000 + int.parse(match.group(3)!);
      return DateTime(year, month, day);
    }
    // Fallback to current date if parsing fails
    return DateTime.now();
  }

  static int _parseMonth(String month) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12
    };
    return months[month] ?? 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'date': date,
      'bank': bank,
      'refNo': refNo,
      'accountNumber': accountNumber,
      'balance': balance,
      'receiverName': receiverName,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      type: json['type'] as String,
      amount: json['amount'] as double,
      date: json['date'] as String,
      bank: json['bank'] as String,
      refNo: json['refNo'] as String,
      accountNumber: json['accountNumber'] as String? ?? '',
      balance: json['balance']?.toDouble(),
      receiverName: json['receiverName'] as String?,
    );
  }
}
