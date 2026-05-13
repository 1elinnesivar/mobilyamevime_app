import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 0,
  );

  static String format(num? value) {
    if (value == null) {
      return '-';
    }
    return _formatter.format(value);
  }
}
