import 'transaction.dart';

class TransactionFilter {
  String? type; // Credit, Debit, or null for all
  String? bank; // Bank name or null for all
  DateTime? startDate;
  DateTime? endDate;

  TransactionFilter({
    this.type,
    this.bank,
    this.startDate,
    this.endDate,
  });

  bool matches(Transaction transaction) {
    if (type != null && transaction.type != type) {
      return false;
    }

    if (bank != null &&
        !transaction.bank.toLowerCase().contains(bank!.toLowerCase())) {
      return false;
    }

    if (startDate != null && transaction.parsedDate.isBefore(startDate!)) {
      return false;
    }

    if (endDate != null && transaction.parsedDate.isAfter(endDate!)) {
      return false;
    }

    return true;
  }
}

// Add this to your Transaction class
extension TransactionListExtension on List<Transaction> {
  List<Transaction> applyFilter(TransactionFilter filter) {
    return where((transaction) => filter.matches(transaction)).toList();
  }

  Set<String> get uniqueBanks {
    return map((t) => t.bank).toSet();
  }
}

// Add this extension method after the existing TransactionListExtension
extension TransactionSorting on List<Transaction> {
  List<Transaction> sortByDate({bool ascending = false}) {
    final sorted = List<Transaction>.from(this);
    sorted.sort((a, b) => ascending
        ? a.parsedDate.compareTo(b.parsedDate)
        : b.parsedDate.compareTo(a.parsedDate));
    return sorted;
  }
}
