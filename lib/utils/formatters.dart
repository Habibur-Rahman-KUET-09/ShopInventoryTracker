import 'package:intl/intl.dart';

/// Number/currency formatting helpers.
///
/// The scope doc leaves digit choice open ("বাংলা বা ইংরেজি — যেটা সহজবোধ্য").
/// We keep digits in English (0-9) since that is what shopkeepers already use
/// on calculators, price tags and mobile banking apps, while all labels and
/// messages stay in Bangla.
class Formatters {
  // Locale is left as the intl default (en_US) on purpose: its symbol data
  // is always bundled, so no initializeDateFormatting()/number data setup is
  // required. The taka sign is prefixed manually instead of relying on a
  // custom currency locale.
  static final NumberFormat _wholeNumber = NumberFormat.decimalPattern();
  static final NumberFormat _decimalNumber = NumberFormat('#,##0.00');
  static final DateFormat _date = DateFormat('dd MMM, yyyy');
  static final DateFormat _dayLabel = DateFormat('dd MMM');
  static final DateFormat _time = DateFormat('hh:mm a');

  static String taka(num amount) {
    if (amount == amount.roundToDouble()) {
      return '৳${_wholeNumber.format(amount)}';
    }
    return '৳${_decimalNumber.format(amount)}';
  }

  static String date(DateTime date) => _date.format(date);

  static String dayLabel(DateTime date) => _dayLabel.format(date);

  static String time(DateTime date) => _time.format(date);

  static String dateTime(DateTime date) =>
      '${_date.format(date)}, ${_time.format(date)}';
}
