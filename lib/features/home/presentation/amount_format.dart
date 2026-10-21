import 'package:intl/intl.dart';

String formatHomeAmount(
  int amountEgp, {
  required String locale,
  required bool withCurrency,
  required String currency,
}) {
  final amount = NumberFormat.decimalPattern(locale).format(amountEgp);
  if (!withCurrency) return amount;
  return '$amount $currency';
}
