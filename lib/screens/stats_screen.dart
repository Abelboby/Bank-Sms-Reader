import 'package:flutter/material.dart';
import '../models/transaction_stats.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class StatsScreen extends StatefulWidget {
  final List<Transaction> transactions;

  const StatsScreen({
    super.key,
    required this.transactions,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedMonth;
  late TransactionStats _stats;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _updateStats();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                background: _GlassmorphicCard(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GradientOverlayPainter(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Monthly Overview',
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMMM yyyy')
                                          .format(_selectedMonth),
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton.filled(
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedMonth,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                      initialDatePickerMode:
                                          DatePickerMode.year,
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _selectedMonth = date;
                                        _updateStats();
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.calendar_month),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildOverviewCard(
                                    theme,
                                    'Income',
                                    _stats.totalCredit,
                                    Colors.green,
                                    Icons.arrow_downward,
                                    currencyFormat,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildOverviewCard(
                                    theme,
                                    'Expense',
                                    _stats.totalDebit,
                                    Colors.red,
                                    Icons.arrow_upward,
                                    currencyFormat,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Insights'),
                  Tab(text: 'Distribution'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildInsightsTab(theme, currencyFormat),
              _buildDistributionTab(theme, currencyFormat),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        },
        icon: const Icon(Icons.arrow_upward),
        label: const Text('Top'),
      ),
    );
  }

  Widget _buildOverviewCard(
    ThemeData theme,
    String label,
    double amount,
    Color color,
    IconData icon,
    NumberFormat format,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              format.format(amount),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(ThemeData theme, NumberFormat format) {
    final highestTransaction = _stats.getHighestTransaction();
    final averageDaily = _stats.getAverageDailySpend();
    final spendingChange = _stats.debitChangePercentage;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _GlassmorphicCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Insights',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (spendingChange != 0) ...[
                _InsightTile(
                  icon: Icon(
                    spendingChange > 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: spendingChange > 0 ? Colors.red : Colors.green,
                  ),
                  title: spendingChange > 0
                      ? 'Spending increased by ${spendingChange.abs().toStringAsFixed(1)}%'
                      : 'Spending decreased by ${spendingChange.abs().toStringAsFixed(1)}%',
                  subtitle: 'compared to last month',
                  theme: theme,
                ),
                const _GradientDivider(),
              ],
              _InsightTile(
                icon: Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
                title: 'Average Daily Spend',
                subtitle: format.format(averageDaily),
                theme: theme,
              ),
              if (highestTransaction != null) ...[
                const _GradientDivider(),
                _InsightTile(
                  icon: Icon(
                    Icons.arrow_upward,
                    color: theme.colorScheme.error,
                  ),
                  title: 'Highest Transaction',
                  subtitle:
                      '${highestTransaction.receiverName ?? 'Unknown'} • ${format.format(highestTransaction.amount)}',
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTopReceiversCard(theme, format),
      ],
    );
  }

  Widget _buildDistributionTab(ThemeData theme, NumberFormat format) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _GlassmorphicCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Distribution',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(_stats.topBanks.length, (index) {
                final bank = _stats.topBanks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              bank.key,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            format.format(bank.value),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _GradientProgressBar(
                        value: bank.value / _stats.totalDebit,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopReceiversCard(ThemeData theme, NumberFormat format) {
    final topReceivers = _stats.topReceivers;
    if (topReceivers.isEmpty) return const SizedBox.shrink();

    return _GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Recipients',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...topReceivers.asMap().entries.map((entry) {
            final index = entry.key;
            final receiver = entry.value;
            return Column(
              children: [
                if (index > 0) const _GradientDivider(),
                _ReceiverTile(
                  name: receiver.key,
                  amount: format.format(receiver.value),
                  transactions: _stats.receiverCount[receiver.key] ?? 0,
                  rank: index + 1,
                  theme: theme,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _GlassmorphicCard extends StatelessWidget {
  final Widget child;

  const _GlassmorphicCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GradientDivider extends StatelessWidget {
  const _GradientDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).dividerColor.withOpacity(0),
            Theme.of(context).dividerColor,
            Theme.of(context).dividerColor.withOpacity(0),
          ],
        ),
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  final double value;
  final Color backgroundColor;
  final Gradient gradient;

  const _GradientProgressBar({
    required this.value,
    required this.backgroundColor,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final ThemeData theme;

  const _InsightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: icon,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiverTile extends StatelessWidget {
  final String name;
  final String amount;
  final int transactions;
  final int rank;
  final ThemeData theme;

  const _ReceiverTile({
    required this.name,
    required this.amount,
    required this.transactions,
    required this.rank,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$transactions transactions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const radius = 100.0;
    final circles = [
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.5, -radius),
      Offset(size.width * 0.8, size.height * 0.2),
    ];

    for (final center in circles) {
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0xFF424242).withOpacity(0.3),
          const Color(0xFF424242).withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_GradientOverlayPainter oldDelegate) => false;
}
