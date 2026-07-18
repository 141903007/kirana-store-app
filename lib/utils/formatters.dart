import 'package:intl/intl.dart';

/// Shared currency/quantity display formatting so every screen (Dashboard,
/// Billing, Reports, ...) renders numbers the same way.
class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹', // Rupee sign
    decimalDigits: 0,
  );

  static String currency(num value) => _currencyFormat.format(value);

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  static String date(DateTime value) => _dateFormat.format(value);

  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String dateTime(DateTime value) => _dateTimeFormat.format(value);
}
