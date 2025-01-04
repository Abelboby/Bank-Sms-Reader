import 'package:flutter/material.dart';
import '../models/transaction.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == 'Credit';
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCredit
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 16,
                        color: isCredit ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transaction.type,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${transaction.amount}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.account_balance,
              label: transaction.bank,
            ),
            if (transaction.accountNumber.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: Icons.credit_card,
                label: 'A/c: ${transaction.accountNumber}',
              ),
            ],
            if (transaction.receiverName?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: Icons.person_outline,
                label:
                    '${isCredit ? 'From' : 'To'}: ${transaction.receiverName}',
              ),
            ],
            if (transaction.balance != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Balance: ₹${transaction.balance}',
              ),
            ],
            if (transaction.refNo.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: Icons.numbers,
                label: 'Ref: ${transaction.refNo}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
          ),
        ),
      ],
    );
  }
}
