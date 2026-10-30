import '../models/wallet_transaction.dart';

const List<int> cashOutNotes = [5000, 2000, 1000, 500, 100];

class AmountCheck {
  const AmountCheck._({this.value, this.error});

  const AmountCheck.valid(int value) : this._(value: value);

  const AmountCheck.invalid(String error) : this._(error: error);

  final int? value;
  final String? error;

  bool get isValid => error == null;
}

AmountCheck checkPositiveAmount(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return const AmountCheck.invalid('Enter an amount.');
  }

  final value = int.tryParse(text);
  if (value == null) {
    return const AmountCheck.invalid(
      'Amount must be a whole number, like 5,000.',
    );
  }
  if (value <= 0) {
    return const AmountCheck.invalid('Amount must be above 0 RWF.');
  }

  return AmountCheck.valid(value);
}

AmountCheck checkSendAmount(String raw, int balance) {
  final check = checkPositiveAmount(raw);
  if (!check.isValid) {
    return check;
  }

  final amount = check.value!;
  if (amount < 100) {
    return const AmountCheck.invalid('The minimum send is 100 RWF.');
  }
  if (amount > balance) {
    return const AmountCheck.invalid('Insufficient balance.');
  }

  return check;
}

AmountCheck checkCashOutAmount(String raw, int balance) {
  final check = checkPositiveAmount(raw);
  if (!check.isValid) {
    return check;
  }

  final amount = check.value!;
  if (amount % 100 != 0) {
    return const AmountCheck.invalid('Cash out must be a multiple of 100 RWF.');
  }
  if (amount > balance) {
    return const AmountCheck.invalid('Insufficient balance.');
  }

  return check;
}

String? validatePhoneNumber(String raw) {
  final phone = raw.trim();
  if (phone.isEmpty) {
    return 'Enter the recipient phone number.';
  }
  if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
    return 'Phone number must be exactly 10 digits.';
  }
  if (!phone.startsWith('078') && !phone.startsWith('079')) {
    return 'Phone number must start with 078 or 079.';
  }

  return null;
}

String? validateDescription(String raw) {
  if (raw.trim().isEmpty) {
    return 'Description cannot be empty.';
  }
  return null;
}

Map<int, int> cashOutBreakdown(int amount) {
  final notes = <int, int>{};
  var remaining = amount;

  for (final note in cashOutNotes) {
    final count = remaining ~/ note;
    if (count > 0) {
      notes[note] = count;
      remaining -= count * note;
    }
  }

  assert(remaining == 0, 'Cash out amounts must be multiples of 100.');
  return notes;
}

List<WalletTransaction> sortNewestFirst(
  Iterable<WalletTransaction> transactions,
) {
  final sorted = transactions.toList();
  sorted.sort((a, b) {
    final byDate = b.createdAt.compareTo(a.createdAt);
    return byDate != 0 ? byDate : b.id.compareTo(a.id);
  });
  return sorted;
}

List<WalletTransaction> sortChronologically(
  Iterable<WalletTransaction> transactions,
) {
  final sorted = transactions.toList();
  sorted.sort((a, b) {
    final byDate = a.createdAt.compareTo(b.createdAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
  return sorted;
}

int currentBalance(Iterable<WalletTransaction> transactions) {
  return transactions.fold(0, (balance, transaction) {
    return balance + transaction.signedAmount;
  });
}

int totalIn(Iterable<WalletTransaction> transactions) {
  return transactions
      .where((transaction) => transaction.isIn)
      .fold(0, (total, transaction) => total + transaction.amount);
}

int totalOut(Iterable<WalletTransaction> transactions) {
  return transactions
      .where((transaction) => !transaction.isIn)
      .fold(0, (total, transaction) => total + transaction.amount);
}

int lowestBalanceEver(Iterable<WalletTransaction> transactions) {
  final chronological = sortChronologically(transactions);
  var running = 0;
  int? lowest;

  for (final transaction in chronological) {
    running += transaction.signedAmount;
    if (lowest == null || running < lowest) {
      lowest = running;
    }
  }

  return lowest ?? 0;
}

bool wouldGoNegativeWithout(
  Iterable<WalletTransaction> transactions,
  WalletTransaction removed,
) {
  var running = 0;

  for (final transaction in sortChronologically(transactions)) {
    if (transaction.id == removed.id) {
      continue;
    }
    running += transaction.signedAmount;
    if (running < 0) {
      return true;
    }
  }

  return false;
}

String formatAmount(int amount) {
  final digits = amount.abs().toString();
  final result = StringBuffer();
  final sign = amount < 0 ? '-' : '';

  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    if (index > 0 && remaining % 3 == 0) {
      result.write(',');
    }
    result.write(digits[index]);
  }

  return '$sign$result';
}

String formatRwf(int amount) => '${formatAmount(amount)} RWF';

String formatSignedAmount(WalletTransaction transaction) {
  final sign = transaction.isIn ? '+' : '-';
  return '$sign${formatRwf(transaction.amount)}';
}

String formatTransactionDate(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final dateOnly = DateTime(date.year, date.month, date.day);
  final todayOnly = DateTime(today.year, today.month, today.day);
  final difference = todayOnly.difference(dateOnly).inDays;

  final time =
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  if (difference == 0) {
    return 'Today · $time';
  }
  if (difference == 1) {
    return 'Yesterday · $time';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} ${months[date.month - 1]} · $time';
}
