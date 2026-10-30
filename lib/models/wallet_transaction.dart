enum TransactionType { moneyIn, moneyOut }

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.createdAt,
  }) : assert(amount > 0);

  final int id;
  final String description;
  final int amount;
  final TransactionType type;
  final DateTime createdAt;

  bool get isIn => type == TransactionType.moneyIn;

  int get signedAmount => isIn ? amount : -amount;
}

List<WalletTransaction> buildSampleTransactions({DateTime? now}) {
  final base = now ?? DateTime.now();

  return [
    WalletTransaction(
      id: 4,
      description: 'Sent to 0788123456',
      amount: 2000,
      type: TransactionType.moneyOut,
      createdAt: base.subtract(const Duration(hours: 2)),
    ),
    WalletTransaction(
      id: 3,
      description: 'Received from Aline',
      amount: 5000,
      type: TransactionType.moneyIn,
      createdAt: base.subtract(const Duration(days: 1, hours: 3)),
    ),
    WalletTransaction(
      id: 2,
      description: 'Cash out at agent',
      amount: 3000,
      type: TransactionType.moneyOut,
      createdAt: base.subtract(const Duration(days: 2, hours: 5)),
    ),
    WalletTransaction(
      id: 1,
      description: 'Opening balance',
      amount: 10000,
      type: TransactionType.moneyIn,
      createdAt: base.subtract(const Duration(days: 5)),
    ),
  ];
}
