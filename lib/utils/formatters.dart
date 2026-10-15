import 'package:intl/intl.dart';

final NumberFormat _peso = NumberFormat.currency(
  locale: 'en_PH',
  symbol: 'PHP ',
  decimalDigits: 2,
);

String formatPeso(num value) => _peso.format(value);

String formatPesoShort(num value) => 'PHP ${value.toStringAsFixed(2)}';
