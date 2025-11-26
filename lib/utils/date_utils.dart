import 'package:intl/intl.dart';

String formatDateForInput(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

String formatDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (e) {
    return dateString;
  }
}

String formatDateTime(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  } catch (e) {
    return dateString;
  }
}

