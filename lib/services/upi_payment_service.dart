import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/upi_payment_data.dart';

enum UpiPaymentStatus {
  success,
  failure,
  cancelled,
  submitted,
  noApp,
  unknown;

  bool get isSuccess =>
      this == UpiPaymentStatus.success || this == UpiPaymentStatus.submitted;
}

class UpiPaymentResult {
  final UpiPaymentStatus status;
  final String rawResponse;
  final String? message;

  const UpiPaymentResult({
    required this.status,
    this.rawResponse = '',
    this.message,
  });

  bool get isSuccess => status.isSuccess;

  factory UpiPaymentResult.fromMap(Map<dynamic, dynamic> map) {
    final statusStr = (map['status'] as String? ?? 'UNKNOWN').toUpperCase();
    final raw = map['rawResponse'] as String? ?? '';
    final msg = map['message'] as String?;

    UpiPaymentStatus status;
    switch (statusStr) {
      case 'SUCCESS':
        status = UpiPaymentStatus.success;
        break;
      case 'FAILURE':
        status = UpiPaymentStatus.failure;
        break;
      case 'CANCELLED':
        status = UpiPaymentStatus.cancelled;
        break;
      case 'SUBMITTED':
        status = UpiPaymentStatus.submitted;
        break;
      case 'NO_UPI_APP':
        status = UpiPaymentStatus.noApp;
        break;
      default:
        status = UpiPaymentStatus.unknown;
    }

    return UpiPaymentResult(status: status, rawResponse: raw, message: msg);
  }
}

class UpiPaymentService {
  static const MethodChannel _channel =
      MethodChannel('com.expensetracker.expense_tracker/upi');

  /// Check whether Google Pay is installed on the Android device.
  static Future<bool> isGooglePayInstalled() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isGooglePayInstalled');
      return res ?? false;
    } catch (e) {
      debugPrint('Error checking Google Pay: $e');
      return false;
    }
  }

  /// Check whether any UPI app is installed.
  static Future<bool> isAnyUpiAppInstalled() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isAnyUpiAppInstalled');
      return res ?? false;
    } catch (e) {
      debugPrint('Error checking UPI apps: $e');
      return false;
    }
  }

  /// Initiates payment through Google Pay or the default UPI app.
  /// Returns [UpiPaymentResult] with status and details.
  static Future<UpiPaymentResult> pay({
    required UpiPaymentData data,
    required double amount,
    bool forceGooglePay = true,
  }) async {
    final uri = data.buildIntentUri(finalAmount: amount);

    if (kIsWeb || !Platform.isAndroid) {
      return const UpiPaymentResult(
        status: UpiPaymentStatus.noApp,
        message: 'UPI payments are only supported on Android devices.',
      );
    }

    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'initiateUpiPayment',
        {
          'upiUri': uri.toString(),
          'forceGooglePay': forceGooglePay,
        },
      );

      if (result != null) {
        return UpiPaymentResult.fromMap(result);
      }
      return const UpiPaymentResult(
        status: UpiPaymentStatus.failure,
        message: 'No response from payment app',
      );
    } on PlatformException catch (e) {
      return UpiPaymentResult(
        status: UpiPaymentStatus.failure,
        message: e.message ?? 'Platform error initiating UPI payment',
      );
    } catch (e) {
      return UpiPaymentResult(
        status: UpiPaymentStatus.failure,
        message: e.toString(),
      );
    }
  }
}
