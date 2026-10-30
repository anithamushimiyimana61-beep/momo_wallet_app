import 'package:flutter/material.dart';

import '../logic/wallet_logic.dart';
import '../models/wallet_transaction.dart';
import '../widgets/transaction_tile.dart';
import 'cash_out_screen.dart';
import 'receive_money_screen.dart';
import 'send_money_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final List<WalletTransaction> _transactions = buildSampleTransactions();
  String _filter = 'All';

  List<WalletTransaction> get _visibleTransactions {
    if (_filter == 'IN') {
      return _transactions.where((transaction) => transaction.isIn).toList();
    }
    if (_filter == 'OUT') {
      return _transactions.where((transaction) => !transaction.isIn).toList();
    }
    return _transactions;
  }

  void _addTransaction(WalletTransaction transaction) {
    setState(() {
      _transactions.add(transaction);
      final sorted = sortNewestFirst(_transactions);
      _transactions
        ..clear()
        ..addAll(sorted);
    });
  }

  Future<void> _openReceive() async {
    final result = await Navigator.of(context).push<WalletTransaction>(
      MaterialPageRoute(builder: (context) => const ReceiveMoneyScreen()),
    );

    if (!mounted || result == null) {
      return;
    }

    _addTransaction(result);
    _showMessage('${formatRwf(result.amount)} received.');
  }

  Future<void> _openSend() async {
    final result = await Navigator.of(context).push<WalletTransaction>(
      MaterialPageRoute(
        builder: (context) =>
            SendMoneyScreen(balance: currentBalance(_transactions)),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    _addTransaction(result);
    _showMessage('${formatRwf(result.amount)} sent.');
  }

  Future<void> _openCashOut() async {
    final result = await Navigator.of(context).push<WalletTransaction>(
      MaterialPageRoute(
        builder: (context) =>
            CashOutScreen(balance: currentBalance(_transactions)),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    _addTransaction(result);
    _showMessage('Cash out complete.');
  }

  void _deleteTransaction(WalletTransaction transaction) {
    if (wouldGoNegativeWithout(_transactions, transaction)) {
      _showMessage(
        'Cannot delete this transaction: the balance would go below 0.',
      );
      return;
    }

    final index = _transactions.indexOf(transaction);
    if (index == -1) {
      return;
    }

    setState(() {
      _transactions.removeAt(index);
    });

    _showMessage(
      '${transaction.description} deleted',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          if (!mounted || _transactions.contains(transaction)) {
            return;
          }
          setState(() {
            _transactions.insert(index, transaction);
          });
        },
      ),
    );
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  void _setFilter(String filter) {
    setState(() {
      _filter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final balance = currentBalance(_transactions);
    final visible = _visibleTransactions;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const _WalletHeader(),
                const SizedBox(height: 18),
                _BalanceCard(balance: balance, count: _transactions.length),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_rounded,
                        label: 'Receive',
                        color: const Color(0xFF147A58),
                        onTap: _openReceive,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Send',
                        color: const Color(0xFF176B87),
                        onTap: _openSend,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.local_atm_rounded,
                        label: 'Cash out',
                        color: const Color(0xFFB56A12),
                        onTap: _openCashOut,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text(
                  'Money snapshot',
                  style: TextStyle(
                    color: Color(0xFF15372D),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total IN',
                        value: formatAmount(totalIn(_transactions)),
                        icon: Icons.south_west_rounded,
                        color: const Color(0xFF147A58),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Total OUT',
                        value: formatAmount(totalOut(_transactions)),
                        icon: Icons.north_east_rounded,
                        color: const Color(0xFFC53B32),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Lowest',
                        value: formatAmount(lowestBalanceEver(_transactions)),
                        icon: Icons.show_chart_rounded,
                        color: const Color(0xFF5B5B8A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Transactions',
                        style: TextStyle(
                          color: Color(0xFF15372D),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6EFE9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${visible.length}',
                        style: const TextStyle(
                          color: Color(0xFF0E5B46),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == 'All',
                      onSelected: () => _setFilter('All'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'IN',
                      selected: _filter == 'IN',
                      onSelected: () => _setFilter('IN'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'OUT',
                      selected: _filter == 'OUT',
                      onSelected: () => _setFilter('OUT'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  _EmptyTransactions(filter: _filter)
                else
                  for (final transaction in visible)
                    TransactionTile(
                      key: ValueKey(transaction.id),
                      transaction: transaction,
                      onDelete: () => _deleteTransaction(transaction),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0E5B46), Color(0xFF1B8B68)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MOMO WALLET',
                style: TextStyle(
                  color: Color(0xFF0E5B46),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.1,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Your money, clearly.',
                style: TextStyle(
                  color: Color(0xFF15372D),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: Color(0xFF2AA876),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'LIVE',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.count});

  final int balance;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B4D3B), Color(0xFF118162)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E5B46).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 48,
            bottom: -65,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Available balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.contactless_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatRwf(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    const _BalanceMeta(
                      icon: Icons.shield_outlined,
                      label: 'Protected wallet',
                    ),
                    _BalanceMeta(
                      icon: Icons.receipt_long_outlined,
                      label: '$count transactions',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceMeta extends StatelessWidget {
  const _BalanceMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.68), size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3E8E1)),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF15372D),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF15372D),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$label · RWF',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF4F665E),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF0E5B46) : const Color(0xFFD6DED7),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.filter});

  final String filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      'IN' => 'No money in yet.',
      'OUT' => 'No money out yet.',
      _ => 'Nothing here yet.',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8E1)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFE9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF0E5B46),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF15372D),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            filter == 'All'
                ? 'Receive money to start your history.'
                : 'Change the filter to see the rest.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
