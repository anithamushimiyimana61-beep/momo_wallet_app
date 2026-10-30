import 'package:flutter/material.dart';

import '../logic/wallet_logic.dart';
import '../models/wallet_transaction.dart';
import '../widgets/form_screen_scaffold.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key, required this.balance});

  final int balance;

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  void _send() {
    final phoneError = validatePhoneNumber(_phoneController.text);
    if (phoneError != null) {
      setState(() => _error = phoneError);
      return;
    }

    final amountCheck = checkSendAmount(_amountController.text, widget.balance);
    if (!amountCheck.isValid) {
      setState(() => _error = amountCheck.error);
      return;
    }

    final phone = _phoneController.text.trim();
    Navigator.pop(
      context,
      WalletTransaction(
        id: DateTime.now().microsecondsSinceEpoch,
        description: 'Sent to $phone',
        amount: amountCheck.value!,
        type: TransactionType.moneyOut,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormScreenScaffold(
      title: 'Send money',
      subtitle: 'Send to an MTN Momo number starting with 078 or 079.',
      icon: Icons.arrow_upward_rounded,
      accent: const Color(0xFF176B87),
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
              Text(
                'Available to send',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Spacer(),
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
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clearError(),
          decoration: const InputDecoration(
            labelText: 'Recipient phone',
            hintText: '0788123456',
            prefixIcon: Icon(Icons.phone_iphone_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onChanged: (_) => _clearError(),
          onSubmitted: (_) => _send(),
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: '1000',
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
                '10 digits · starts with 078 or 079 · minimum 100 RWF.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _send,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Send money'),
        ),
      ],
    );
  }
}
