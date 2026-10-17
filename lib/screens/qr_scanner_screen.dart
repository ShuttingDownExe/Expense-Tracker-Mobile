import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../config/app_config.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/upi_payment_data.dart';
import '../services/upi_payment_service.dart';
import '../state/expense_store.dart';
import '../theme/app_theme.dart';
import 'payment_failed_screen.dart';

/// Screen 4 — UPI QR Code Scanner matching the Stitch "Raw Ledger" design:
/// 4px/6px black and red borders, hard drop shadows, animated laser viewfinder,
/// Play Services ML Kit barcode scanning, gallery import, and Google Pay integration.
class QrScannerScreen extends StatefulWidget {
  final ExpenseStore store;

  const QrScannerScreen({super.key, required this.store});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _laserController;
  late final Animation<double> _laserAnimation;

  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;
  bool _torchOn = false;

  /// Test QR presets and simulator are only available in dev debug mode,
  /// strictly disabled in production, UAT, and test builds.
  bool get _isTestQrEnabled => kDebugMode && AppConfig.isDev;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _handleScannedCode(raw);
        break;
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final BarcodeCapture? capture =
          await _scannerController.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        final code = capture.barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          _handleScannedCode(code);
          return;
        }
      }

      if (mounted) {
        _showBrutalMessage(
          'NO QR CODE FOUND',
          'Could not detect a readable QR code in this image.',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Gallery scan error: $e');
      if (mounted) {
        _showBrutalMessage(
          'SCAN ERROR',
          'Could not read image: $e',
          isError: true,
        );
      }
    }
  }

  void _handleScannedCode(String rawCode) {
    setState(() => _isProcessing = true);
    _scannerController.stop();

    final upiData = UpiPaymentData.tryParse(rawCode);
    if (upiData == null) {
      _showInvalidQrDialog(rawCode);
      return;
    }

    _showPaymentConfirmationSheet(upiData);
  }

  void _showInvalidQrDialog(String raw) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgLight,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.borderBlack, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text('NON-UPI QR CODE',
            style: AppText.headlineSm(color: AppColors.primaryRed)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The scanned QR does not contain a standard UPI payment URL.',
              style: AppText.bodyLg(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border.all(color: AppColors.borderBlack, width: 2),
              ),
              child: Text(
                raw.length > 100 ? '${raw.substring(0, 100)}...' : raw,
                style: AppText.caption(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resumeScanning();
            },
            child: Text(
              'SCAN AGAIN',
              style: AppText.headlineSm(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  void _resumeScanning() {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _scannerController.start();
  }

  /// Opens the bottom sheet allowing the user to view payee details,
  /// enter the amount if not fixed by the QR, pick a category, and trigger Google Pay.
  Future<void> _showPaymentConfirmationSheet(UpiPaymentData upiData) async {
    final amountController = TextEditingController(
      text: upiData.amount != null ? upiData.amount!.toStringAsFixed(2) : '',
    );
    final noteController = TextEditingController(text: upiData.note ?? '');
    ExpenseCategory selectedCategory = ExpenseCategory.all.first;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final mediaQuery = MediaQuery.of(context);
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                mediaQuery.viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                border: Border(
                  top: BorderSide(color: AppColors.borderBlack, width: 5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.borderBlack,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CONFIRM PAYMENT',
                          style: AppText.headlineSm(
                              color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(modalCtx).pop(false),
                        ),
                      ],
                    ),
                    const Divider(
                        color: AppColors.borderBlack, thickness: 3, height: 20),

                    // Payee Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        border: Border.all(
                            color: AppColors.borderBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.borderBlack,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified,
                                  color: AppColors.primaryRed, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  upiData.payeeName.toUpperCase(),
                                  style: AppText.headlineSm(
                                      color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            upiData.vpa,
                            style: AppText.bodySm(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Amount Input
                    Text('AMOUNT (INR)',
                        style: AppText.bodySm(color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      autofocus: upiData.amount == null,
                      style: AppText.displaySm(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: Text('₹',
                              style: AppText.displaySm(
                                  color: AppColors.primaryRed)),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 32, minHeight: 0),
                        hintText: '0.00',
                        filled: true,
                        fillColor: AppColors.bgLight,
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                              color: AppColors.borderBlack, width: 3),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                              color: AppColors.primaryRed, width: 3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Selector
                    Text('EXPENSE CATEGORY',
                        style: AppText.bodySm(color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExpenseCategory.all.map((cat) {
                        final isSel = cat == selectedCategory;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedCategory = cat);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.borderBlack
                                  : AppColors.bgLight,
                              border: Border.all(
                                  color: AppColors.borderBlack, width: 2),
                              boxShadow: isSel
                                  ? const [
                                      BoxShadow(
                                        color: AppColors.primaryRed,
                                        offset: Offset(2, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat.icon,
                                    size: 16,
                                    color: isSel
                                        ? AppColors.onPrimary
                                        : AppColors.textPrimary),
                                const SizedBox(width: 6),
                                Text(
                                  cat.label.toUpperCase(),
                                  style: AppText.caption(
                                    color: isSel
                                        ? AppColors.onPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Optional Note / Description
                    Text('NOTE / MEMO (OPTIONAL)',
                        style: AppText.bodySm(color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      style: AppText.bodyLg(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Lunch, Groceries',
                        filled: true,
                        fillColor: AppColors.bgLight,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                              color: AppColors.borderBlack, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                              color: AppColors.borderBlack, width: 3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Pay via Google Pay Button
                    GestureDetector(
                      onTap: () {
                        final amount =
                            double.tryParse(amountController.text.trim());
                        if (amount == null || amount <= 0) {
                          _showBrutalMessage(
                            'INVALID AMOUNT',
                            'Please enter a valid amount greater than ₹0.',
                            isError: true,
                          );
                          return;
                        }
                        Navigator.of(modalCtx).pop(true);
                        _executeUpiPayment(
                          upiData: upiData,
                          amount: amount,
                          category: selectedCategory,
                          customNote: noteController.text.trim(),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          border: Border.all(
                              color: AppColors.borderBlack, width: 4),
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
                            const Icon(Icons.payment,
                                color: AppColors.onPrimary, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'OPEN GOOGLE PAY & PAY',
                              style: AppText.headlineSm(
                                  color: AppColors.onPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) {
      _resumeScanning();
    }
  }

  /// Executes payment via Google Pay through native intent, with simulation fallback for emulators.
  Future<void> _executeUpiPayment({
    required UpiPaymentData upiData,
    required double amount,
    required ExpenseCategory category,
    required String customNote,
  }) async {
    // Attempt real Google Pay launch
    final result = await UpiPaymentService.pay(
      data: upiData,
      amount: amount,
      forceGooglePay: true,
    );

    if (!mounted) return;

    if (result.status == UpiPaymentStatus.noApp) {
      if (_isTestQrEnabled) {
        // Dev debug mode on emulator: allow testing via simulation dialog
        _showEmulatorSimulationDialog(
          upiData: upiData,
          amount: amount,
          category: category,
          customNote: customNote,
        );
        return;
      }

      // Production / UAT builds: report missing UPI app without developer simulation
      _showBrutalMessage(
        'NO UPI APP FOUND',
        'No supported UPI app found. Please install Google Pay to complete payment.',
        isError: true,
      );
      return;
    }

    _handlePaymentResult(
      result: result,
      upiData: upiData,
      amount: amount,
      category: category,
      customNote: customNote,
    );
  }

  /// Handles the outcome of the UPI transaction (Success vs Failure).
  Future<void> _handlePaymentResult({
    required UpiPaymentResult result,
    required UpiPaymentData upiData,
    required double amount,
    required ExpenseCategory category,
    required String customNote,
  }) async {
    if (result.isSuccess) {
      // 1. Success! Automatically record into ExpenseStore ledger.
      await _recordSuccessfulExpense(
        upiData: upiData,
        amount: amount,
        category: category,
        customNote: customNote,
      );
    } else {
      // 2. Failed or Cancelled! Navigate to Neo-Brutalist PaymentFailedScreen.
      final retry = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentFailedScreen(
            paymentData: upiData,
            amount: amount,
            reason: result.message ??
                (result.status == UpiPaymentStatus.cancelled
                    ? 'Payment was cancelled in Google Pay.'
                    : 'Transaction declined or failed.'),
          ),
        ),
      );

      if (retry == true) {
        _resumeScanning();
      } else {
        _resumeScanning();
      }
    }
  }

  /// Automatically creates and saves the expense to the store and returns to the home screen.
  Future<void> _recordSuccessfulExpense({
    required UpiPaymentData upiData,
    required double amount,
    required ExpenseCategory category,
    required String customNote,
  }) async {
    final note = customNote.isNotEmpty
        ? customNote
        : (upiData.note?.isNotEmpty == true
            ? upiData.note!
            : '${upiData.payeeName} (UPI)');

    final resolvedVendor = upiData.payeeName.trim().isNotEmpty
        ? upiData.payeeName.trim()
        : category.label;

    final expense = Expense(
      id: '',
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      description: note,
      amount: amount,
      vendor: resolvedVendor,
      category: category.value,
    );

    try {
      await widget.store.createExpense(expense);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ ₹${amount.toStringAsFixed(2)} PAID TO ${upiData.payeeName.toUpperCase()} & LOGGED',
            style: AppText.bodyLg(color: AppColors.onPrimary),
          ),
          backgroundColor: const Color(0xFF1B5E20), // Dark green brutal
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Return to Dashboard / caller with success
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showBrutalMessage(
        'SAVE WARNING',
        'Payment succeeded, but could not save to local API: $e',
        isError: true,
      );
    }
  }

  /// Simulator dialog allowing instant testing on the Android Emulator without a real bank account.
  void _showEmulatorSimulationDialog({
    required UpiPaymentData upiData,
    required double amount,
    required ExpenseCategory category,
    required String customNote,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (simCtx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            border: Border(
              top: BorderSide(color: AppColors.borderBlack, width: 5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    color: AppColors.borderBlack,
                    child: Text('EMULATOR MODE',
                        style: AppText.caption(color: AppColors.onPrimary)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(simCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('SIMULATE GOOGLE PAY OUTCOME',
                  style: AppText.headlineSm(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Google Pay is not installed or running on this emulator (UPI requires active SIM binding). Choose an outcome to test the app flow:',
                style: AppText.bodySm(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              // Simulate SUCCESS
              GestureDetector(
                onTap: () {
                  Navigator.of(simCtx).pop();
                  _handlePaymentResult(
                    result: const UpiPaymentResult(
                      status: UpiPaymentStatus.success,
                      rawResponse: 'Status=SUCCESS&responseCode=00',
                    ),
                    upiData: upiData,
                    amount: amount,
                    category: category,
                    customNote: customNote,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    border: Border.all(
                        color: AppColors.borderBlack, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.borderBlack,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '✓ SIMULATE PAYMENT SUCCESS',
                      style: AppText.headlineSm(color: AppColors.onPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Simulate FAILURE
              GestureDetector(
                onTap: () {
                  Navigator.of(simCtx).pop();
                  _handlePaymentResult(
                    result: const UpiPaymentResult(
                      status: UpiPaymentStatus.failure,
                      rawResponse: 'Status=FAILURE&responseCode=ZM',
                      message: 'Bank server timeout or insufficient balance.',
                    ),
                    upiData: upiData,
                    amount: amount,
                    category: category,
                    customNote: customNote,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                  child: Center(
                    child: Text(
                      '✕ SIMULATE PAYMENT FAILURE',
                      style: AppText.headlineSm(color: AppColors.onPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showBrutalMessage(String title, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppText.headlineSm(color: AppColors.onPrimary)),
            const SizedBox(height: 2),
            Text(message,
                style: AppText.bodySm(color: AppColors.onPrimary)),
          ],
        ),
        backgroundColor:
            isError ? AppColors.primaryRed : AppColors.borderBlack,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Preset sample UPI QRs for rapid emulator testing (dev debug mode only).
  void _triggerSampleQrDialog() {
    if (!_isTestQrEnabled) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            border: Border(
              top: BorderSide(color: AppColors.borderBlack, width: 5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'TEST UPI SAMPLES (EMULATOR)',
                style: AppText.headlineSm(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a preset to test the complete scan-and-pay flow without a physical camera:',
                style: AppText.bodySm(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _sampleButton(
                title: 'STARBUCKS COFFEE',
                vpa: 'starbucks@icici',
                amount: 280.0,
                note: 'Cold Brew & Croissant',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleScannedCode(
                      'upi://pay?pa=starbucks@icici&pn=Starbucks%20Coffee&am=280.00&cu=INR&tn=Cold%20Brew');
                },
              ),
              const SizedBox(height: 10),
              _sampleButton(
                title: 'CHAI POINT (NO PRE-FILLED AMOUNT)',
                vpa: 'chaipoint@hdfcbank',
                amount: null,
                note: 'Ginger Chai',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleScannedCode(
                      'upi://pay?pa=chaipoint@hdfcbank&pn=Chai%20Point&cu=INR&tn=Ginger%20Chai');
                },
              ),
              const SizedBox(height: 10),
              _sampleButton(
                title: 'SWIGGY FOOD ORDER',
                vpa: 'swiggy@kotak',
                amount: 450.0,
                note: 'Dinner Order',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleScannedCode(
                      'upi://pay?pa=swiggy@kotak&pn=Swiggy&am=450.00&cu=INR&tn=Dinner%20Order');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sampleButton({
    required String title,
    required String vpa,
    required double? amount,
    required String note,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          border: Border.all(color: AppColors.borderBlack, width: 3),
          boxShadow: const [
            BoxShadow(color: AppColors.borderBlack, offset: Offset(3, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.headlineSm(color: AppColors.textPrimary)),
                Text(
                  amount != null
                      ? '₹${amount.toStringAsFixed(0)} • $vpa'
                      : 'Enter amount • $vpa',
                  style: AppText.caption(color: AppColors.textSecondary),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera preview with Google Play Services barcode scanner
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),

                  // Darkened semi-transparent overlay around the scanner frame
                  _scannerOverlay(),

                  // Central Neo-Brutalist Viewfinder Frame
                  _viewfinder(),

                  // Bottom Controls Bar (Flash, Gallery, Emulator Sample)
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: _controlsBar(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderBlack, width: 4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border.all(color: AppColors.borderBlack, width: 3),
                boxShadow: const [
                  BoxShadow(color: AppColors.borderBlack, offset: Offset(3, 3)),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.borderBlack),
            ),
          ),
          Text(
            'SCAN UPI QR',
            style: AppText.headlineSm(color: AppColors.textPrimary),
          ),
          // Torch toggle button
          GestureDetector(
            onTap: () {
              _scannerController.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _torchOn ? AppColors.primaryRed : AppColors.cardBg,
                border: Border.all(color: AppColors.borderBlack, width: 3),
                boxShadow: const [
                  BoxShadow(color: AppColors.borderBlack, offset: Offset(3, 3)),
                ],
              ),
              child: Icon(
                _torchOn ? Icons.flash_on : Icons.flash_off,
                color: _torchOn ? AppColors.onPrimary : AppColors.borderBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scannerOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.55),
        BlendMode.srcOut,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewfinder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tilted Brutal Badge above viewfinder
        Transform.rotate(
          angle: -0.03,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              border: Border.all(color: AppColors.borderBlack, width: 2),
              boxShadow: const [
                BoxShadow(color: AppColors.borderBlack, offset: Offset(3, 3)),
              ],
            ),
            child: Text(
              'SCAN ANY UPI QR TO PAY',
              style: AppText.caption(color: AppColors.onPrimary),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Square frame with animated laser and corner brackets
        SizedBox(
          width: 270,
          height: 270,
          child: Stack(
            children: [
              // 4px Red/Black Border
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.primaryRed, width: 4),
                ),
              ),

              // 4 Corner Brackets (Heavy Neo-Brutalist L-brackets)
              _cornerBracket(top: 0, left: 0, isTop: true, isLeft: true),
              _cornerBracket(top: 0, right: 0, isTop: true, isLeft: false),
              _cornerBracket(bottom: 0, left: 0, isTop: false, isLeft: true),
              _cornerBracket(bottom: 0, right: 0, isTop: false, isLeft: false),

              // Animated Scanning Laser Line
              AnimatedBuilder(
                animation: _laserAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: _laserAnimation.value * 260,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Hint Text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: AppColors.borderBlack.withValues(alpha: 0.8),
          child: Text(
            'POINT AT GOOGLE PAY, PHONEPE, OR PAYTM QR',
            style: AppText.caption(color: AppColors.cardBg),
          ),
        ),
      ],
    );
  }

  Widget _cornerBracket({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppColors.borderBlack, width: 6)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppColors.borderBlack, width: 6)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppColors.borderBlack, width: 6)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppColors.borderBlack, width: 6)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _controlsBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.borderBlack, width: 4),
        boxShadow: const [
          BoxShadow(color: AppColors.borderBlack, offset: Offset(5, 5)),
        ],
      ),
      child: Row(
        children: [
          // Gallery Scan Button
          Expanded(
            child: GestureDetector(
              onTap: _pickImageFromGallery,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  border: Border.all(color: AppColors.borderBlack, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_library,
                        color: AppColors.borderBlack, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'GALLERY',
                      style: AppText.headlineSm(
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isTestQrEnabled) ...[
            const SizedBox(width: 10),
            // Emulator Sample QR Trigger (DEV ONLY)
            Expanded(
              child: GestureDetector(
                onTap: _triggerSampleQrDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    border: Border.all(color: AppColors.borderBlack, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_2,
                          color: AppColors.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'TEST QR',
                        style: AppText.headlineSm(color: AppColors.onPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
