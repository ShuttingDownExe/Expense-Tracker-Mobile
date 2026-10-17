import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/upi_payment_data.dart';
import '../theme/app_theme.dart';

/// Neo-Brutalist "Payment Failed" screen shown when a UPI transaction fails,
/// is declined by the bank, or is cancelled by the user.
class PaymentFailedScreen extends StatelessWidget {
  final UpiPaymentData paymentData;
  final double amount;
  final String reason;

  const PaymentFailedScreen({
    super.key,
    required this.paymentData,
    required this.amount,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a, d MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    // Error Icon Box
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        border: Border.all(color: AppColors.borderBlack, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.borderBlack,
                            offset: Offset(6, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close,
                          size: 52,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'TRANSACTION FAILED',
                      style: AppText.displaySm(color: AppColors.primaryRed),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Tilted Status Badge
                    Transform.rotate(
                      angle: -0.03,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.borderBlack,
                          border: Border.all(
                              color: AppColors.borderBlack, width: 2),
                        ),
                        child: Text(
                          'UNABLE TO COMPLETE TRANSACTION',
                          style: AppText.caption(color: AppColors.cardBg),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Transaction Detail Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        border: Border.all(
                            color: AppColors.borderBlack, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.borderBlack,
                            offset: Offset(5, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow(
                            label: 'AMOUNT',
                            value: '₹${amount.toStringAsFixed(2)}',
                            isHighlight: true,
                          ),
                          const Divider(
                              color: AppColors.borderBlack,
                              thickness: 2,
                              height: 24),
                          _detailRow(
                            label: 'PAYEE',
                            value: paymentData.payeeName,
                          ),
                          const SizedBox(height: 12),
                          _detailRow(
                            label: 'UPI ID',
                            value: paymentData.vpa,
                          ),
                          const SizedBox(height: 12),
                          _detailRow(
                            label: 'TIME',
                            value: timeStr,
                          ),
                          const Divider(
                              color: AppColors.borderBlack,
                              thickness: 2,
                              height: 24),
                          _detailRow(
                            label: 'REASON',
                            value: reason.isNotEmpty
                                ? reason
                                : 'Payment cancelled or declined by bank.',
                            isError: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Helpful Hint Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F4),
                        border: Border.all(
                            color: AppColors.primaryRed, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.primaryRed, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No money was deducted from your account. You can retry paying with UPI or enter the expense manually.',
                              style: AppText.bodySm(
                                  color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                border: Border(
                  top: BorderSide(color: AppColors.borderBlack, width: 4),
                ),
              ),
              child: Column(
                children: [
                  // TRY AGAIN
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(true), // retry = true
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        border: Border.all(
                            color: AppColors.borderBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.borderBlack,
                            offset: Offset(4, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh,
                              color: AppColors.onPrimary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'TRY AGAIN',
                            style: AppText.headlineSm(
                                color: AppColors.onPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CANCEL / BACK
                  GestureDetector(
                    onTap: () {
                      // Pop back to root / previous screens
                      Navigator.of(context).pop(false);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        border: Border.all(
                            color: AppColors.borderBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.borderBlack,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'CANCEL TRANSACTION',
                          style: AppText.headlineSm(
                              color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderBlack, width: 4),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border.all(color: AppColors.borderBlack, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.borderBlack,
                    offset: Offset(3, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: AppColors.borderBlack),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'PAYMENT FAILED',
              style: AppText.headlineSm(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
    bool isHighlight = false,
    bool isError = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.bodySm(color: AppColors.textSecondary),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: isHighlight
                ? AppText.displaySm(color: AppColors.primaryRed)
                : (isError
                    ? AppText.bodyLg(color: AppColors.primaryRed)
                    : AppText.headlineSm(color: AppColors.textPrimary)),
          ),
        ),
      ],
    );
  }
}
