import 'package:flutter_test/flutter_test.dart';
import 'package:momo_wallet_app/logic/wallet_logic.dart';
import 'package:momo_wallet_app/models/wallet_transaction.dart';

void main() {
  group('input checks', () {
    test('accepts a positive whole amount', () {
      final check = checkPositiveAmount('5000');

      expect(check.isValid, isTrue);
      expect(check.value, 5000);
    });

    test('refuses words, zero and negative amounts', () {
      expect(checkPositiveAmount('5k').error, isNotNull);
      expect(checkPositiveAmount('0').error, isNotNull);
      expect(checkPositiveAmount('-200').error, isNotNull);
      expect(checkPositiveAmount('').error, isNotNull);
    });

    test('checks phone digits and network prefix', () {
      expect(validatePhoneNumber('0788123456'), isNull);
      expect(validatePhoneNumber('0790000000'), isNull);
      expect(
        validatePhoneNumber('0721234567'),
        'Phone number must start with 078 or 079.',
      );
      expect(
        validatePhoneNumber('078812345'),
        'Phone number must be exactly 10 digits.',
      );
      expect(
        validatePhoneNumber('07881234567'),
        'Phone number must be exactly 10 digits.',
      );
    });

    test('send refuses amounts under 100 and over the balance', () {
      expect(checkSendAmount('50', 10000).error, contains('minimum'));
      expect(checkSendAmount('1000000', 10000).error, 'Insufficient balance.');
      expect(checkSendAmount('100', 10000).isValid, isTrue);
    });

    test('cash out refuses non-multiples and amounts over the balance', () {
      expect(checkCashOutAmount('250', 10000).error, contains('multiple'));
      expect(checkCashOutAmount('20000', 10000).error, 'Insufficient balance.');
      expect(checkCashOutAmount('3000', 10000).isValid, isTrue);
    });
  });

  test('cash out notes are biggest first and exact', () {
    final notes = cashOutBreakdown(23700);

    expect(notes, {5000: 4, 2000: 1, 1000: 1, 500: 1, 100: 2});
    expect(notes.keys.toList(), [5000, 2000, 1000, 500, 100]);
  });

  test('sample wallet statistics are calculated correctly', () {
    final transactions = buildSampleTransactions(
      now: DateTime(2026, 10, 30, 12),
    );

    expect(currentBalance(transactions), 10000);
    expect(totalIn(transactions), 15000);
    expect(totalOut(transactions), 5000);
    expect(lowestBalanceEver(transactions), 7000);
    expect(
      sortNewestFirst(transactions).first.description,
      'Sent to 0788123456',
    );
  });

  test('statistics are recalculated after a safe delete', () {
    final transactions = buildSampleTransactions(
      now: DateTime(2026, 10, 30, 12),
    );
    final received = transactions.firstWhere(
      (transaction) => transaction.description == 'Received from Aline',
    );

    expect(wouldGoNegativeWithout(transactions, received), isFalse);
    transactions.remove(received);

    expect(currentBalance(transactions), 5000);
    expect(totalIn(transactions), 10000);
    expect(totalOut(transactions), 5000);
    expect(lowestBalanceEver(transactions), 5000);
  });

  test('deleting an early IN is refused when later OUTs would go negative', () {
    final transactions = buildSampleTransactions(
      now: DateTime(2026, 10, 30, 12),
    );
    final opening = transactions.firstWhere(
      (transaction) => transaction.description == 'Opening balance',
    );
    final latestOut = transactions.firstWhere(
      (transaction) => transaction.description == 'Sent to 0788123456',
    );

    expect(wouldGoNegativeWithout(transactions, opening), isTrue);
    expect(wouldGoNegativeWithout(transactions, latestOut), isFalse);
  });

  test('amounts are grouped with commas', () {
    expect(formatRwf(10000), '10,000 RWF');
    expect(formatRwf(1000000), '1,000,000 RWF');
    expect(formatRwf(100), '100 RWF');
  });
}
