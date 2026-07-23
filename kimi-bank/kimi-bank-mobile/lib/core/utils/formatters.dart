import 'package:intl/intl.dart';

final _rupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final _dateFormat = DateFormat('d MMM, h:mm a');

String formatRupees(double amount) => _rupeeFormat.format(amount);
String formatDate(DateTime date) => _dateFormat.format(date);
