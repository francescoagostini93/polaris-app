import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../models/session_result.dart';

/// Service for sending exercise reports via email
class EmailService {
  /// Send session report to the configured email address
  Future<bool> sendReport({
    required SessionResult result,
    required String recipientEmail,
  }) async {
    final report = result.generateReport();
    final dateStr = _formatDate(result.startTime);

    final email = Email(
      body: report,
      subject: 'Report Esercizi Cognitivi - $dateStr',
      recipients: [recipientEmail],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
}
