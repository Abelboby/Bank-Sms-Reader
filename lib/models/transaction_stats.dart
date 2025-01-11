import 'transaction.dart';

class TransactionStats {
  final List<Transaction> transactions;
  final double totalCredit;
  final double totalDebit;
  final Map<String, double> bankwiseTotal;
  final Map<String, double> receiverTotal;
  final Map<String, int> receiverCount;
  final DateTime? previousMonthStart;
  final DateTime? previousMonthEnd;
  final List<Transaction> previousMonthTransactions;

  TransactionStats({
    required this.transactions,
    this.previousMonthTransactions = const [],
    this.previousMonthStart,
    this.previousMonthEnd,
  })  : totalCredit = transactions
            .where((t) => t.type == 'Credit')
            .fold(0, (sum, t) => sum + t.amount),
        totalDebit = transactions
            .where((t) => t.type == 'Debit')
            .fold(0, (sum, t) => sum + t.amount),
        bankwiseTotal = _calculateBankwiseTotal(transactions),
        receiverTotal = _calculateReceiverTotal(transactions),
        receiverCount = _calculateReceiverCount(transactions);

  static Map<String, double> _calculateBankwiseTotal(
      List<Transaction> transactions) {
    final map = <String, double>{};
    for (var transaction in transactions) {
      map[transaction.bank] = (map[transaction.bank] ?? 0) + transaction.amount;
    }
    return map;
  }

  static Map<String, double> _calculateReceiverTotal(
      List<Transaction> transactions) {
    final map = <String, double>{};
    for (var transaction in transactions) {
      if (transaction.receiverName != null &&
          transaction.receiverName!.isNotEmpty) {
        map[transaction.receiverName!] =
            (map[transaction.receiverName] ?? 0) + transaction.amount;
      }
    }
    return map;
  }

  static Map<String, int> _calculateReceiverCount(
      List<Transaction> transactions) {
    final map = <String, int>{};
    for (var transaction in transactions) {
      if (transaction.receiverName != null &&
          transaction.receiverName!.isNotEmpty) {
        map[transaction.receiverName!] =
            (map[transaction.receiverName] ?? 0) + 1;
      }
    }
    return map;
  }

  double get balance => totalCredit - totalDebit;

  double get previousMonthDebit => previousMonthTransactions
      .where((t) => t.type == 'Debit')
      .fold(0, (sum, t) => sum + t.amount);

  double get debitChangePercentage {
    if (previousMonthDebit == 0) return 0;
    return ((totalDebit - previousMonthDebit) / previousMonthDebit) * 100;
  }

  List<MapEntry<String, double>> get topBanks {
    final entries = bankwiseTotal.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  List<MapEntry<String, double>> get topReceivers {
    final entries = receiverTotal.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  List<MapEntry<String, int>> get mostFrequentReceivers {
    final entries = receiverCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  double getAverageDailySpend() {
    if (transactions.isEmpty) return 0;
    final days = transactions.last.parsedDate
            .difference(transactions.first.parsedDate)
            .inDays
            .abs() +
        1;
    return totalDebit / days;
  }

  Transaction? getHighestTransaction() {
    if (transactions.isEmpty) return null;
    return transactions.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  Transaction? getLowestTransaction() {
    if (transactions.isEmpty) return null;
    return transactions.reduce((a, b) => a.amount < b.amount ? a : b);
  }

  TransactionStats filterByDateRange(DateTime start, DateTime end) {
    final previousMonthStart = DateTime(start.year, start.month - 1, 1);
    final previousMonthEnd = DateTime(start.year, start.month, 0);

    return TransactionStats(
      transactions: transactions
          .where((t) =>
              t.parsedDate.isAfter(start.subtract(const Duration(days: 1))) &&
              t.parsedDate.isBefore(end.add(const Duration(days: 1))))
          .toList(),
      previousMonthTransactions: transactions
          .where((t) =>
              t.parsedDate.isAfter(
                  previousMonthStart.subtract(const Duration(days: 1))) &&
              t.parsedDate
                  .isBefore(previousMonthEnd.add(const Duration(days: 1))))
          .toList(),
      previousMonthStart: previousMonthStart,
      previousMonthEnd: previousMonthEnd,
    );
  }

  TransactionStats filterByMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return filterByDateRange(start, end);
  }
}
