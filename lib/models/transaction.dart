import 'package:flutter/material.dart';

class Transaction {
  final double amount;
  final String date;
  final String refNo;
  final String bank;
  final String type;
  final String accountNumber;
  final double? balance;
  final String? receiverName;
  late final DateTime parsedDate;

  Transaction({
    required this.amount,
    required this.date,
    required this.refNo,
    required this.bank,
    required this.type,
    this.accountNumber = '',
    this.balance,
    this.receiverName,
  }) {
    parsedDate = _parseDate(date);
  }

  static DateTime _parseDate(String date) {
    // Handle both formats: "24Mar24" and "24-12-2024"
    if (date.contains('-')) {
      final parts = date.split('-');
      return DateTime(
        int.parse(parts[2].substring(0, 4)),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } else {
      final day = int.parse(date.substring(0, 2));
      final month = _parseMonth(date.substring(2, 5));
      final year = 2000 + int.parse(date.substring(5));
      return DateTime(year, month, day);
    }
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

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      amount: json['amount'],
      date: json['date'],
      refNo: json['refNo'],
      bank: json['bank'],
      type: json['type'],
      accountNumber: json['accountNumber'] ?? '',
      balance: json['balance']?.toDouble(),
      receiverName: json['receiverName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date,
      'refNo': refNo,
      'bank': bank,
      'type': type,
      'accountNumber': accountNumber,
      'balance': balance,
      'receiverName': receiverName,
    };
  }
}
