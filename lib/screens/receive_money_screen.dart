import 'package:flutter/material.dart';

import '../logic/wallet_logic.dart';
import '../models/wallet_transaction.dart';
import '../widgets/form_screen_scaffold.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _receive() {
    final descriptionError = validateDescription(_descriptionController.text);
    if (descriptionError != null) {
      setState(() => _error = descriptionError);
      return;
    }

    final amountCheck = checkPositiveAmount(_amountController.text);
    if (!amountCheck.isValid) {
      setState(() => _error = amountCheck.error);
      return;
    }

    Navigator.pop(
      context,
      WalletTransaction(
        id: DateTime.now().microsecondsSinceEpoch,
        description: _descriptionController.text.trim(),
        amount: amountCheck.value!,
        type: TransactionType.moneyIn,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormScreenScaffold(
      title: 'Receive money',
      subtitle:
          'Add money to this wallet and keep a clear record of who sent it.',
      icon: Icons.add_card_rounded,
      accent: const Color(0xFF147A58),
      children: [
        if (_error != null) FormErrorBanner(message: _error!),
        TextField(
          controller: _descriptionController,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'From Aline',
            prefixIcon: Icon(Icons.edit_note_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _receive(),
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: '5000',
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
                'Whole amounts above 0 RWF only.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _receive,
          icon: const Icon(Icons.south_west_rounded),
          label: const Text('Receive money'),
        ),
      ],
    );
  }
}
