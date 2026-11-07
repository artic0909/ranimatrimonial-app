import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../components/rani_alert.dart';
import '../components/rani_matrimonial_loader.dart';
import 'api_service.dart';

/// Service: Native Razorpay Payment Gateway Manager for Mobile App
/// Used by:
/// 1. Connect Button when wallet balance < ₹100
/// 2. Wallet Top-Up screen
/// 3. Instant Recharge Bottom Sheet
class RaniRazorpayService {
  static final RaniRazorpayService instance = RaniRazorpayService._internal();
  RaniRazorpayService._internal() {
    _initRazorpay();
  }

  late Razorpay _razorpay;
  double _pendingAmount = 0.0;
  double _baseAmount = 0.0;
  double _platformFee = 0.0;
  BuildContext? _currentContext;
  Function(double amount)? _onSuccess;
  Function(String error)? _onError;

  /// Calculate 2% platform fee for any recharge amount
  static double calculatePlatformFee(double baseAmount) {
    return double.parse((baseAmount * 0.02).toStringAsFixed(2));
  }

  /// Calculate total payable amount (base amount + 2% platform fee)
  static double calculateTotalPayable(double baseAmount) {
    final fee = calculatePlatformFee(baseAmount);
    return double.parse((baseAmount + fee).toStringAsFixed(2));
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final ctx = _currentContext;
    if (ctx == null) return;

    RaniMatrimonialLoader.show(ctx, message: 'Verifying payment with Royal Vault...');

    try {
      final verifyRes = await ApiService.instance.verifyRazorpayPayment({
        'razorpay_payment_id': response.paymentId ?? '',
        'razorpay_order_id': response.orderId ?? '',
        'razorpay_signature': response.signature ?? '',
        'amount': _pendingAmount,
        'base_amount': _baseAmount,
        'platform_fee': _platformFee,
      });

      if (ctx.mounted) RaniMatrimonialLoader.hide(ctx);

      if (verifyRes['success'] == true) {
        if (ctx.mounted) {
          RaniAlert.success(
            ctx,
            '₹${_pendingAmount.toStringAsFixed(2)} added to your Royal Wallet successfully!',
            title: 'Payment Successful',
          );
        }
        _onSuccess?.call(_pendingAmount);
      } else {
        if (ctx.mounted) {
          RaniAlert.error(
            ctx,
            verifyRes['message'] ?? 'Payment verification failed.',
            title: 'Verification Error',
          );
        }
        _onError?.call(verifyRes['message'] ?? 'Verification failed');
      }
    } catch (e) {
      if (ctx.mounted) {
        RaniMatrimonialLoader.hide(ctx);
        RaniAlert.error(ctx, 'Verification error: $e');
      }
      _onError?.call('$e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final ctx = _currentContext;
    if (ctx != null && ctx.mounted) {
      RaniMatrimonialLoader.hide(ctx);
      final errorMsg = response.message ?? 'Payment cancelled or failed.';
      RaniAlert.error(ctx, errorMsg, title: 'Payment Incomplete');
    }
    _onError?.call(response.message ?? 'Payment failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final ctx = _currentContext;
    if (ctx != null && ctx.mounted) {
      RaniAlert.info(
        ctx,
        'Redirected to external wallet: ${response.walletName ?? 'Selected Wallet'}',
        title: 'External Wallet',
      );
    }
  }

  /// Launch Razorpay checkout directly for a given amount
  Future<void> startCheckout({
    required BuildContext context,
    required double amount,
    double? baseAmount,
    double? platformFee,
    String? description,
    Function(double amount)? onSuccess,
    Function(String error)? onError,
  }) async {
    _currentContext = context;
    _pendingAmount = amount;
    _baseAmount = baseAmount ?? double.parse((amount / 1.02).toStringAsFixed(2));
    _platformFee = platformFee ?? double.parse((amount - _baseAmount).toStringAsFixed(2));
    _onSuccess = onSuccess;
    _onError = onError;

    final desc = description ??
        'Royal Wallet Top-up (₹${_baseAmount.toStringAsFixed(0)} + 2% Platform Fee: ₹${_platformFee.toStringAsFixed(2)})';

    RaniMatrimonialLoader.show(context, message: 'Opening Secure Payment...');

    try {
      final orderRes = await ApiService.instance.createRazorpayOrder(amount);
      if (!context.mounted) return;
      RaniMatrimonialLoader.hide(context);

      if (orderRes['success'] == true && orderRes['order_id'] != null) {
        final candidate = ApiService.instance.candidate;
        final options = {
          'key': orderRes['key'],
          'amount': orderRes['amount'], // in paise
          'name': orderRes['name'] ?? 'Rani Matrimonial',
          'description': desc,
          'order_id': orderRes['order_id'],
          'prefill': orderRes['prefill'] ?? {
            'contact': candidate?['mobile'] ?? '',
            'email': candidate?['email'] ?? '',
          },
          'theme': {
            'color': '#750000',
          },
        };

        _razorpay.open(options);
      } else {
        // Fallback: direct wallet recharge if Razorpay keys not active
        final topUpRes = await ApiService.instance.addMoney(
          amount: amount,
          paymentMethod: 'UPI',
          customNote: 'Instant Recharge via UPI (incl. 2% Platform Fee)',
        );

        if (!context.mounted) return;
        if (topUpRes['success'] == true) {
          RaniAlert.success(
            context,
            '₹${amount.toStringAsFixed(2)} credited to your wallet.',
            title: 'Wallet Recharged',
          );
          onSuccess?.call(amount);
        } else {
          RaniAlert.error(
            context,
            topUpRes['message'] ?? orderRes['message'] ?? 'Could not initiate recharge.',
          );
          onError?.call('Failed');
        }
      }
    } catch (e) {
      if (context.mounted) {
        RaniMatrimonialLoader.hide(context);
        RaniAlert.error(context, 'Recharge initiation error: $e');
      }
      onError?.call('$e');
    }
  }

  /// Show Royal Recharge Bottom Sheet with Razorpay checkout
  static void showRechargeModal({
    required BuildContext context,
    double defaultAmount = 100,
    String? subtitle,
    Function(double amount)? onPaymentSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RoyalRechargeSheet(
        defaultAmount: defaultAmount,
        subtitle: subtitle,
        onSuccess: (amount) {
          Navigator.pop(ctx);
          onPaymentSuccess?.call(amount);
        },
      ),
    );
  }
}

class _RoyalRechargeSheet extends StatefulWidget {
  final double defaultAmount;
  final String? subtitle;
  final Function(double amount) onSuccess;

  const _RoyalRechargeSheet({
    required this.defaultAmount,
    this.subtitle,
    required this.onSuccess,
  });

  @override
  State<_RoyalRechargeSheet> createState() => _RoyalRechargeSheetState();
}

class _RoyalRechargeSheetState extends State<_RoyalRechargeSheet> {
  late double _selectedAmount;
  final TextEditingController _customController = TextEditingController();

  final List<Map<String, dynamic>> _packages = [
    {'amount': 100.0, 'label': '1 Connect', 'desc': 'Instant 1 Profile Connect', 'popular': false},
    {'amount': 500.0, 'label': '5 Connects', 'desc': 'Standard Starter Pack', 'popular': false},
    {'amount': 1000.0, 'label': '10 Connects', 'desc': 'Popular • 10 Connects', 'popular': true},
    {'amount': 2500.0, 'label': '25 Connects', 'desc': 'Elite • 25 Connects', 'popular': false},
  ];

  @override
  void initState() {
    super.initState();
    _selectedAmount = widget.defaultAmount;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B0000), Color(0xFF6B0000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF750000).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.creditcard, color: Color(0xFFE5B842), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recharge Royal Wallet',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2B0A0D),
                      ),
                    ),
                    Text(
                      widget.subtitle ?? 'You need at least ₹100 to send a connection request.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Container(height: 1, color: const Color(0xFFEFE8DE)),
          const SizedBox(height: 16),

          // Package Cards Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.1,
            ),
            itemCount: _packages.length,
            itemBuilder: (context, index) {
              final pkg = _packages[index];
              final amount = pkg['amount'] as double;
              final isSelected = _selectedAmount == amount;
              final isPopular = pkg['popular'] == true;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAmount = amount;
                    _customController.clear();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF8E7) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFB78103) : const Color(0xFFEFE8DE),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${amount.toInt()}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? const Color(0xFF750000) : const Color(0xFF1E1E1E),
                            ),
                          ),
                          if (isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Popular',
                                style: GoogleFonts.outfit(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pkg['label'],
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFF8D6200) : const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // Custom Amount Input
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF750000)),
              hintText: 'Or enter custom amount (e.g. 200)',
              hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFAAAAAA)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEFE8DE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEFE8DE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF750000), width: 1.5),
              ),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val.trim());
              if (parsed != null && parsed > 0) {
                setState(() => _selectedAmount = parsed);
              }
            },
          ),

          const SizedBox(height: 12),

          // 2% Platform Fee Transparency Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF4E6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5B842).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF8D6200)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recharge: ₹${_selectedAmount.toStringAsFixed(0)} + 2% Platform Fee: ₹${RaniRazorpayService.calculatePlatformFee(_selectedAmount).toStringAsFixed(2)} = Pay & Add ₹${RaniRazorpayService.calculateTotalPayable(_selectedAmount).toStringAsFixed(2)} to Wallet',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B450C),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Razorpay Pay CTA Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF750000),
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final total = RaniRazorpayService.calculateTotalPayable(_selectedAmount);
                final fee = RaniRazorpayService.calculatePlatformFee(_selectedAmount);
                RaniRazorpayService.instance.startCheckout(
                  context: context,
                  amount: total,
                  baseAmount: _selectedAmount,
                  platformFee: fee,
                  description: 'Royal Wallet Top-up (₹${_selectedAmount.toStringAsFixed(0)} + 2% Platform Fee: ₹${fee.toStringAsFixed(2)})',
                  onSuccess: (amount) {
                    widget.onSuccess(amount);
                  },
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.lock_shield_fill, color: Color(0xFFE5B842), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Pay ₹${RaniRazorpayService.calculateTotalPayable(_selectedAmount).toStringAsFixed(2)} via Razorpay',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.checkmark_seal_fill, size: 12, color: Color(0xFF2E7D32)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '100% Secure Checkout powered by Razorpay',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF8E8E93)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

