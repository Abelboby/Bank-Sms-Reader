import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/transaction.dart';
import '../models/transaction_filter.dart';
import '../services/sms_parser_service.dart';
import '../widgets/filter_dialog.dart';
import 'settings_screen.dart';

class SMSReaderPage extends StatefulWidget {
  const SMSReaderPage({super.key});

  @override
  State<SMSReaderPage> createState() => _SMSReaderPageState();
}

class _SMSReaderPageState extends State<SMSReaderPage> {
  final SmsQuery _query = SmsQuery();
  List<Transaction> transactions = [];
  bool isLoading = true;
  TransactionFilter? _currentFilter;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  List<Transaction> get filteredTransactions {
    if (_currentFilter == null) return transactions;
    return transactions.applyFilter(_currentFilter!);
  }

  Future<void> initPlatformState() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      await loadTransactions();
      await readMessages();
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        transactions: transactions,
        currentFilter: _currentFilter,
        onFilterChanged: (filter) {
          setState(() {
            _currentFilter = filter;
          });
        },
      ),
    );
  }

  Future<void> readMessages() async {
    setState(() {
      isLoading = true;
    });

    try {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
      );

      setState(() {
        transactions.clear();
      });

      for (var message in messages) {
        final transaction = SMSParserService.parseMessage(
          message.body ?? '',
          message.address ?? '',
        );
        if (transaction != null) {
          setState(() {
            transactions.add(transaction);
          });
        }
      }

      // Sort transactions by parsed date
      setState(() {
        transactions.sort((a, b) => b.parsedDate.compareTo(a.parsedDate));
      });
      saveTransactions();
    } catch (e) {
      debugPrint('Error reading SMS: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsJson = prefs.getString('transactions');
    if (transactionsJson != null) {
      final List<dynamic> decoded = jsonDecode(transactionsJson);
      setState(() {
        transactions =
            decoded.map((item) => Transaction.fromJson(item)).toList();
      });
    }
  }

  Future<void> saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(transactions.map((t) => t.toJson()).toList());
    await prefs.setString('transactions', encoded);
  }

  @override
  Widget build(BuildContext context) {
    final displayTransactions = filteredTransactions;

    // Group transactions by formatted date
    final Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in displayTransactions) {
      final date = transaction.date;
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    // Sort dates using parsed DateTime
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) {
        final transA = groupedTransactions[a]!.first;
        final transB = groupedTransactions[b]!.first;
        return transB.parsedDate.compareTo(transA.parsedDate);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Transactions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _currentFilter != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: readMessages,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  'Total Transactions: ${displayTransactions.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_currentFilter != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentFilter = null;
                      });
                    },
                    child: const Text('Clear Filter'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayTransactions.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : ListView.builder(
                        itemCount: sortedDates.length,
                        itemBuilder: (context, dateIndex) {
                          final date = sortedDates[dateIndex];
                          final dateTransactions = groupedTransactions[date]!;

                          // Sort transactions within the date by amount
                          dateTransactions
                              .sort((a, b) => b.amount.compareTo(a.amount));

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.3),
                                child: Row(
                                  children: [
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${dateTransactions.length} transactions',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              ...dateTransactions.map((transaction) => Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            transaction.type == 'Credit'
                                                ? Colors.green.shade100
                                                : Colors.red.shade100,
                                        child: Icon(
                                          transaction.type == 'Credit'
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          color: transaction.type == 'Credit'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Text(
                                            '₹${transaction.amount}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            transaction.type,
                                            style: TextStyle(
                                              color:
                                                  transaction.type == 'Credit'
                                                      ? Colors.green
                                                      : Colors.red,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text('Bank: ${transaction.bank}'),
                                          if (transaction
                                              .accountNumber.isNotEmpty)
                                            Text(
                                                'A/c: ${transaction.accountNumber}'),
                                          if (transaction.balance != null)
                                            Text(
                                                'Balance: ₹${transaction.balance}'),
                                          if (transaction
                                                  .receiverName?.isNotEmpty ??
                                              false)
                                            Text(
                                                '${transaction.type == 'Credit' ? 'From' : 'To'}: ${transaction.receiverName}'),
                                          if (transaction.refNo.isNotEmpty)
                                            Text('Ref: ${transaction.refNo}'),
                                        ],
                                      ),
                                      isThreeLine: true,
                                    ),
                                  )),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
