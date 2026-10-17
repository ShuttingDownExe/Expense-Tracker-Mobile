import 'package:flutter/foundation.dart';

/// Holds structured UPI payment details parsed from a standard UPI QR code.
/// Format: upi://pay?pa=payee@bank&pn=Payee%20Name&am=150.00&cu=INR&tn=Coffee
class UpiPaymentData {
  final String vpa; // Payee VPA / UPI ID (pa)
  final String payeeName; // Payee display name (pn)
  final double? amount; // Pre-filled amount (am), if any
  final String? note; // Transaction note (tn)
  final String? merchantCode; // Merchant category code (mc)
  final String transactionRef; // Transaction reference ID (tr)
  final String rawUri;

  const UpiPaymentData({
    required this.vpa,
    required this.payeeName,
    this.amount,
    this.note,
    this.merchantCode,
    required this.transactionRef,
    required this.rawUri,
  });

  /// Parse a raw QR string into [UpiPaymentData] if it contains UPI payment params.
  static UpiPaymentData? tryParse(String raw) {
    try {
      final trimmed = raw.trim();
      Uri uri;
      if (trimmed.startsWith('upi://')) {
        uri = Uri.parse(trimmed);
      } else if (trimmed.contains('pa=')) {
        uri = Uri.parse('upi://pay?$trimmed');
      } else {
        return null;
      }

      final params = uri.queryParameters;
      final vpa = params['pa'];
      if (vpa == null || vpa.isEmpty || !vpa.contains('@')) {
        return null;
      }

      final name = params['pn'] ?? vpa.split('@').first;
      final amountStr = params['am'];
      final double? parsedAmount =
          amountStr != null ? double.tryParse(amountStr) : null;
      final note = params['tn'];
      final mc = params['mc'];
      final tr = params['tr'] ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}';

      return UpiPaymentData(
        vpa: vpa,
        payeeName: Uri.decodeComponent(name),
        amount: parsedAmount,
        note: note != null ? Uri.decodeComponent(note) : null,
        merchantCode: mc,
        transactionRef: tr,
        rawUri: trimmed,
      );
    } catch (e) {
      debugPrint('Failed to parse UPI QR: $e');
      return null;
    }
  }

  /// Builds the deep link URI targeting Google Pay / UPI apps with the given amount.
  Uri buildIntentUri({required double finalAmount}) {
    final query = <String, String>{
      'pa': vpa,
      'pn': payeeName,
      'am': finalAmount.toStringAsFixed(2),
      'cu': 'INR',
      'tr': transactionRef,
      if (note != null && note!.isNotEmpty) 'tn': note!,
      if (merchantCode != null && merchantCode!.isNotEmpty)
        'mc': merchantCode!,
    };

    return Uri(scheme: 'upi', host: 'pay', queryParameters: query);
  }
}
