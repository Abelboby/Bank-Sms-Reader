import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/transaction.dart';
import '../models/transaction_filter.dart';
import '../services/sms_parser_service.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/transaction_card.dart';
import '../widgets/date_header.dart';
import '../widgets/search_bar.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> get filteredTransactions {
    var filtered = _currentFilter == null
        ? transactions
        : transactions.applyFilter(_currentFilter!);

    if (_searchTerm.isEmpty) return filtered;

    return filtered.where((transaction) {
      final searchLower = _searchTerm.toLowerCase();
      return transaction.bank.toLowerCase().contains(searchLower) ||
          transaction.receiverName?.toLowerCase().contains(searchLower) ==
              true ||
          transaction.refNo.toLowerCase().contains(searchLower) ||
          transaction.amount.toString().contains(searchLower) ||
          transaction.accountNumber.toLowerCase().contains(searchLower);
    }).toList();
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
    final theme = Theme.of(context);

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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Bank Transactions',
                style: TextStyle(
                  color: theme.colorScheme.onBackground,
                ),
              ),
              centerTitle: true,
              background: Container(
                color: theme.colorScheme.surface,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatsScreen(
                        transactions: transactions,
                      ),
                    ),
                  );
                },
              ),
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
          SliverToBoxAdapter(
            child: Column(
              children: [
                TransactionSearchBar(
                  controller: _searchController,
                  hasSearchTerm: _searchTerm.isNotEmpty,
                  onChanged: (value) {
                    setState(() {
                      _searchTerm = value;
                    });
                  },
                  onClear: () {
                    setState(() {
                      _searchTerm = '';
                      _searchController.clear();
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Transactions',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            displayTransactions.length.toString(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      if (_currentFilter != null || _searchTerm.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentFilter = null;
                              _searchTerm = '';
                              _searchController.clear();
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear All'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (displayTransactions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_outlined,
                      size: 64,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: theme.textTheme.titleLarge,
                    ),
                    if (_searchTerm.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Try a different search term',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                      )
                    else if (_currentFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Try clearing the filter',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= sortedDates.length) return null;

                  final date = sortedDates[index];
                  final dateTransactions = groupedTransactions[date]!;
                  dateTransactions.sort((a, b) => b.amount.compareTo(a.amount));

                  return Column(
                    children: [
                      DateHeader(
                        date: date,
                        transactionCount: dateTransactions.length,
                      ),
                      ...dateTransactions.map((transaction) => TransactionCard(
                            transaction: transaction,
                          )),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton:
          _currentFilter == null && !isLoading && displayTransactions.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Icon(Icons.arrow_upward),
                )
              : null,
    );
  }
}
