import 'package:flutter/material.dart';
import '../models/transaction_stats.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatefulWidget {
  final List<Transaction> transactions;

  const StatsScreen({
    super.key,
    required this.transactions,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late DateTime _selectedMonth;
  late TransactionStats _stats;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _updateStats();
  }

  void _updateStats() {
    _stats = TransactionStats(transactions: widget.transactions)
        .filterByMonth(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      locale: 'en_IN',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stats for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (date != null) {
                setState(() {
                  _selectedMonth = date;
                  _updateStats();
                });
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(theme, currencyFormat),
          const SizedBox(height: 16),
          _buildSpendingInsightsCard(theme, currencyFormat),
          const SizedBox(height: 16),
          _buildTopReceiversCard(theme, currencyFormat),
          const SizedBox(height: 16),
          _buildBankwiseStats(theme, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, NumberFormat format) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Summary',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Income',
                    _stats.totalCredit,
                    Colors.green,
                    Icons.arrow_downward,
                    format,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Expense',
                    _stats.totalDebit,
                    Colors.red,
                    Icons.arrow_upward,
                    format,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Balance',
                    _stats.balance,
                    _stats.balance >= 0 ? Colors.green : Colors.red,
                    _stats.balance >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    format,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingInsightsCard(ThemeData theme, NumberFormat format) {
    final highestTransaction = _stats.getHighestTransaction();
    final averageDaily = _stats.getAverageDailySpend();
    final spendingChange = _stats.debitChangePercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Insights',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (spendingChange != 0) ...[
              ListTile(
                leading: Icon(
                  spendingChange > 0 ? Icons.trending_up : Icons.trending_down,
                  color: spendingChange > 0 ? Colors.red : Colors.green,
                ),
                title: Text(
                  spendingChange > 0
                      ? 'Spending increased by ${spendingChange.abs().toStringAsFixed(1)}%'
                      : 'Spending decreased by ${spendingChange.abs().toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyLarge,
                ),
                subtitle: const Text('compared to last month'),
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                'Average Daily Spend',
                style: theme.textTheme.bodyLarge,
              ),
              trailing: Text(
                format.format(averageDaily),
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (highestTransaction != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: Text(
                  'Highest Transaction',
                  style: theme.textTheme.bodyLarge,
                ),
                subtitle: Text(
                  highestTransaction.receiverName ?? 'Unknown',
                ),
                trailing: Text(
                  format.format(highestTransaction.amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopReceiversCard(ThemeData theme, NumberFormat format) {
    final topReceivers = _stats.topReceivers;
    if (topReceivers.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Recipients',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...topReceivers.map((receiver) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(receiver.key),
                    trailing: Text(
                      format.format(receiver.value),
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${_stats.receiverCount[receiver.key]} transactions',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBankwiseStats(ThemeData theme, NumberFormat format) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Distribution',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...List.generate(_stats.topBanks.length, (index) {
              final bank = _stats.topBanks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            bank.key,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            format.format(bank.value),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: bank.value / _stats.totalDebit,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    double amount,
    Color color,
    IconData icon,
    NumberFormat format,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          format.format(amount),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
