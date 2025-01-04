import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/transaction_filter.dart';

class FilterDialog extends StatefulWidget {
  final List<Transaction> transactions;
  final TransactionFilter? currentFilter;
  final Function(TransactionFilter?) onFilterChanged;

  const FilterDialog({
    super.key,
    required this.transactions,
    this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late TransactionFilter filter;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filter = TransactionFilter(
      type: widget.currentFilter?.type,
      bank: widget.currentFilter?.bank,
      startDate: widget.currentFilter?.startDate,
      endDate: widget.currentFilter?.endDate,
    );
    _startDateController.text =
        filter.startDate?.toString().split(' ')[0] ?? '';
    _endDateController.text = filter.endDate?.toString().split(' ')[0] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final uniqueBanks = widget.transactions.uniqueBanks.toList()..sort();

    return AlertDialog(
      title: const Text('Filter Transactions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaction Type'),
            DropdownButton<String>(
              value: filter.type,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                const DropdownMenuItem(value: 'Credit', child: Text('Credit')),
                const DropdownMenuItem(value: 'Debit', child: Text('Debit')),
              ],
              onChanged: (value) {
                setState(() {
                  filter = TransactionFilter(
                    type: value,
                    bank: filter.bank,
                    startDate: filter.startDate,
                    endDate: filter.endDate,
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Bank'),
            DropdownButton<String>(
              value: filter.bank,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...uniqueBanks.map((bank) => DropdownMenuItem(
                      value: bank,
                      child: Text(bank),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  filter = TransactionFilter(
                    type: filter.type,
                    bank: value,
                    startDate: filter.startDate,
                    endDate: filter.endDate,
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Date Range'),
            TextField(
              controller: _startDateController,
              decoration: const InputDecoration(
                labelText: 'Start Date (YYYY-MM-DD)',
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: filter.startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    filter = TransactionFilter(
                      type: filter.type,
                      bank: filter.bank,
                      startDate: date,
                      endDate: filter.endDate,
                    );
                    _startDateController.text = date.toString().split(' ')[0];
                  });
                }
              },
            ),
            TextField(
              controller: _endDateController,
              decoration: const InputDecoration(
                labelText: 'End Date (YYYY-MM-DD)',
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: filter.endDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    filter = TransactionFilter(
                      type: filter.type,
                      bank: filter.bank,
                      startDate: filter.startDate,
                      endDate: date,
                    );
                    _endDateController.text = date.toString().split(' ')[0];
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onFilterChanged(null);
            Navigator.pop(context);
          },
          child: const Text('Clear Filter'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onFilterChanged(filter);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
