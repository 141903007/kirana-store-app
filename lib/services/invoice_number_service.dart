/// Pure formatting for auto-generated invoice numbers. Holds no state and
/// does no I/O — [SettingsRepository.takeNextInvoiceNumber] is what
/// atomically reads/increments the counter this formats.
class InvoiceNumberService {
  InvoiceNumberService._();

  static String format(String prefix, int number) {
    return '$prefix${number.toString().padLeft(6, '0')}';
  }
}
