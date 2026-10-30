import 'package:flutter/material.dart';

import '../logic/wallet_logic.dart';
import '../models/wallet_transaction.dart';
import '../widgets/form_screen_scaffold.dart';

class CashOutScreen extends StatefulWidget {
  const CashOutScreen({super.key, required this.balance});

  final int balance;

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  final _amountController = TextEditingController();
  String? _error;
  int? _pendingAmount;
  Map<int, int>? _notes;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _amountChanged(String _) {
    if (_notes != null || _pendingAmount != null || _error != null) {
      setState(() {
        _notes = null;
        _pendingAmount = null;
        _error = null;
      });
    }
  }

  void _showNotes() {
    final amountCheck = checkCashOutAmount(
      _amountController.text,
      widget.balance,
    );

    if (!amountCheck.isValid) {
      setState(() {
        _error = amountCheck.error;
        _notes = null;
        _pendingAmount = null;
      });
      return;
    }

    setState(() {
      _error = null;
      _pendingAmount = amountCheck.value;
      _notes = cashOutBreakdown(amountCheck.value!);
    });
  }

  void _confirm() {
    final amount = _pendingAmount;
    if (amount == null) {
      return;
    }

    final check = checkCashOutAmount(amount.toString(), widget.balance);
    if (!check.isValid) {
      setState(() {
        _error = check.error;
        _notes = null;
        _pendingAmount = null;
      });
      return;
    }

    Navigator.pop(
      context,
      WalletTransaction(
        id: DateTime.now().microsecondsSinceEpoch,
        description: 'Cash out',
        amount: amount,
        type: TransactionType.moneyOut,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormScreenScaffold(
      title: 'Cash out',
      subtitle: 'See the exact notes before the agent hands them over.',
      icon: Icons.local_atm_rounded,
      accent: const Color(0xFFB56A12),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3E8E1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Available to cash out',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatRwf(widget.balance),
                style: const TextStyle(
                  color: Color(0xFF15372D),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_error != null) FormErrorBanner(message: _error!),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onChanged: _amountChanged,
          onSubmitted: (_) => _showNotes(),
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: '20000',
            suffixText: 'RWF',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Multiples of 100 RWF · notes: 5,000 / 2,000 / 1,000 / 500 / 100.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (_notes != null) ...[
          _NotesCard(notes: _notes!, total: _pendingAmount!),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Confirm cash out'),
          ),
        ] else
          FilledButton.icon(
            onPressed: _showNotes,
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('Show notes'),
          ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes, required this.total});

  final Map<int, int> notes;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Notes you will receive',
                  style: TextStyle(
                    color: Color(0xFF15372D),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1DA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'BIGGEST FIRST',
                  style: TextStyle(
                    color: Color(0xFF8B5710),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final entry in notes.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1DA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: Color(0xFFB56A12),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${formatAmount(entry.key)} RWF',
                    style: const TextStyle(
                      color: Color(0xFF15372D),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '× ${entry.value}',
                    style: const TextStyle(
                      color: Color(0xFFB56A12),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            children: [
              Text(
                'Total',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Spacer(),
              Text(
                formatRwf(total),
                style: const TextStyle(
                  color: Color(0xFF15372D),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
