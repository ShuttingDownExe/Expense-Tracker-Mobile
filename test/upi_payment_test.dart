import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expense_tracker/config/app_config.dart';
import 'package:expense_tracker/models/upi_payment_data.dart';
import 'package:expense_tracker/screens/payment_failed_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('UpiPaymentData parsing & building tests', () {
    test('Parses complete standard UPI URI correctly', () {
      const raw =
          'upi://pay?pa=starbucks@icici&pn=Starbucks%20Coffee&am=280.50&cu=INR&tn=Cold%20Brew&tr=TXN_12345';
      final data = UpiPaymentData.tryParse(raw);

      expect(data, isNotNull);
      expect(data!.vpa, 'starbucks@icici');
      expect(data.payeeName, 'Starbucks Coffee');
      expect(data.amount, 280.50);
      expect(data.note, 'Cold Brew');
      expect(data.transactionRef, 'TXN_12345');
    });

    test('Parses UPI URI without pre-filled amount', () {
      const raw = 'upi://pay?pa=merchant@bank&pn=Chai%20Stall&cu=INR';
      final data = UpiPaymentData.tryParse(raw);

      expect(data, isNotNull);
      expect(data!.vpa, 'merchant@bank');
      expect(data.payeeName, 'Chai Stall');
      expect(data.amount, isNull);
    });

    test('Returns null on non-UPI strings', () {
      expect(UpiPaymentData.tryParse('https://google.com'), isNull);
      expect(UpiPaymentData.tryParse('hello world'), isNull);
      expect(UpiPaymentData.tryParse(''), isNull);
    });

    test('buildIntentUri produces correct Google Pay compatible deep link', () {
      const raw = 'upi://pay?pa=merchant@hdfc&pn=Merchant';
      final data = UpiPaymentData.tryParse(raw)!;
      final intentUri = data.buildIntentUri(finalAmount: 150.0);

      expect(intentUri.scheme, 'upi');
      expect(intentUri.host, 'pay');
      expect(intentUri.queryParameters['pa'], 'merchant@hdfc');
      expect(intentUri.queryParameters['am'], '150.00');
      expect(intentUri.queryParameters['cu'], 'INR');
    });
  });

  group('PaymentFailedScreen widget tests', () {
    testWidgets('Renders Neo-Brutalist failure UI and returns retry result',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const upi = UpiPaymentData(
        vpa: 'vendor@axis',
        payeeName: 'Organic Store',
        amount: 320.0,
        transactionRef: 'TXN_999',
        rawUri: 'upi://pay?pa=vendor@axis&pn=Organic%20Store&am=320.00',
      );

      bool? retryResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                retryResult = await Navigator.of(ctx).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const PaymentFailedScreen(
                      paymentData: upi,
                      amount: 320.0,
                      reason: 'Bank server timeout',
                    ),
                  ),
                );
              },
              child: const Text('Open Failed'),
            ),
          ),
        ),
      );

      // Open screen
      await tester.tap(find.text('Open Failed'));
      await tester.pumpAndSettle();

      expect(find.text('TRANSACTION FAILED'), findsOneWidget);
      expect(find.text('₹320.00'), findsOneWidget);
      expect(find.text('Organic Store'), findsOneWidget);
      expect(find.text('vendor@axis'), findsOneWidget);
      expect(find.text('Bank server timeout'), findsOneWidget);
      expect(find.text('TRY AGAIN'), findsOneWidget);
      expect(find.text('CANCEL TRANSACTION'), findsOneWidget);

      // Tap TRY AGAIN
      await tester.tap(find.text('TRY AGAIN'));
      await tester.pumpAndSettle();

      expect(retryResult, isTrue);
    });
  });

  group('Environment checks for test QR', () {
    test('Test QR is enabled only in dev debug mode, disabled in prod or test/uat', () {
      final isDevDebug = kDebugMode && AppConfig.isDev;
      if (AppConfig.isTest || AppConfig.isProd) {
        expect(isDevDebug, isFalse,
            reason: 'Test QR must strictly be disabled in test/uat and prod builds');
      } else {
        expect(isDevDebug, isTrue,
            reason: 'Test QR is available only in dev debug environment');
      }
    });
  });
}
