import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/data/models/order_model.dart';
import 'package:e_commerce/data/providers/cart_provider.dart';
import 'package:e_commerce/data/providers/checkout_provider.dart';
import 'package:e_commerce/data/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Payment Launch Function ──────────────────────────────────────────────────
Future<void> launchPaymobPayment({
  required BuildContext context,
  required String paymentUrl,
}) async {
  final uri = Uri.parse(paymentUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_self',
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not launch payment URL.'),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }
}

// ── View Order Button Component ──────────────────────────────────────────────
class ViewOrderButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ViewOrderButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(LucideIcons.package, size: 18, color: Colors.white),
        label: const Text(
          'View Order',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ── Callback Handler Screen ──────────────────────────────────────────────────
class CheckoutCallbackScreen extends StatefulWidget {
  const CheckoutCallbackScreen({super.key});

  @override
  State<CheckoutCallbackScreen> createState() => _CheckoutCallbackScreenState();
}

enum _VerifyState { loading, success, pending, failed }

class _CheckoutCallbackScreenState extends State<CheckoutCallbackScreen>
    with SingleTickerProviderStateMixin {
  _VerifyState _state = _VerifyState.loading;
  String? _errorMessage;
  String? _orderId;

  late AnimationController _iconCtrl;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconScale = CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut);

    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveAndVerify());
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    super.dispose();
  }


String? _extractOrderId() {
  if (kIsWeb) {
    final uri = Uri.base;

    // 1. Extract order_id or merchant_order_id or id
    String? id = uri.queryParameters['order_id'] ??
        uri.queryParameters['merchant_order_id'] ??
        uri.queryParameters['id'];

    if (id != null && id.isNotEmpty) return id;

    // 2. Hash Fragment check
    if (uri.hasFragment) {
      final fragSplit = uri.fragment.split('?');
      if (fragSplit.length > 1) {
        final fragQuery = Uri.splitQueryString(fragSplit[1]);
        id = fragQuery['order_id'] ??
            fragQuery['merchant_order_id'] ??
            fragQuery['id'];
        if (id != null && id.isNotEmpty) return id;
      }
    }
  }

  // Mobile/Arguments fallback
  final args = ModalRoute.of(context)?.settings.arguments;
  if (args is String && args.isNotEmpty) return args;
  if (args is Map) {
    final id = args['order_id']?.toString() ??
        args['orderId']?.toString() ??
        args['id']?.toString();
    if (id != null && id.isNotEmpty) return id;
  }
  return null;
}


  // String? _extractOrderId() {
  //   if (kIsWeb) {
  //     final uri = Uri.base;
  //     String? id = uri.queryParameters['order_id'] ?? uri.queryParameters['id'];
  //     if (id != null && id.isNotEmpty) return id;

  //     if (uri.hasFragment) {
  //       final fragSplit = uri.fragment.split('?');
  //       if (fragSplit.length > 1) {
  //         final fragQuery = Uri.splitQueryString(fragSplit[1]);
  //         id = fragQuery['order_id'] ?? fragQuery['id'];
  //         if (id != null && id.isNotEmpty) return id;
  //       }
  //     }

  //     final match = RegExp(r'[?&](?:order_id|id)=([^&]+)').firstMatch(uri.toString());
  //     if (match != null) {
  //       id = match.group(1);
  //       if (id != null && id.isNotEmpty) return id;
  //     }
  //   }

  //   final args = ModalRoute.of(context)?.settings.arguments;
  //   if (args is String && args.isNotEmpty) return args;
  //   if (args is Map) {
  //     final id = args['order_id']?.toString() ?? args['orderId']?.toString() ?? args['id']?.toString();
  //     if (id != null && id.isNotEmpty) return id;
  //   }
  //   return null;
  // }

  Future<void> _resolveAndVerify() async {
    final orderId = _extractOrderId();
    if (!mounted) return;

    if (orderId == null || orderId.isEmpty) {
      final isSuccessParam = kIsWeb ? (Uri.base.queryParameters['success'] == 'true') : false;
      if (isSuccessParam) {
        setState(() {
          _state = _VerifyState.pending;
          _errorMessage = 'We are still processing your payment.\n'
              'Please check your Orders page in a few minutes.';
        });
      } else {
        setState(() {
          _state = _VerifyState.failed;
          _errorMessage = 'No order ID found in the redirect URL.';
        });
      }
      _iconCtrl.forward();
      return;
    }

    setState(() {
      _orderId = orderId;
      _state = _VerifyState.loading;
    });

    try {
      final checkout = context.read<CheckoutProvider>();
      final paymentStatus = await checkout.verifyPaymentStatus(orderId);

      if (!mounted) return;

      if (paymentStatus == 'paid') {
        // Clear cart on successful verification
        context.read<CartProvider>().clearCart();
        setState(() => _state = _VerifyState.success);
      } else if (paymentStatus == 'failed') {
        setState(() {
          _state = _VerifyState.failed;
          _errorMessage = 'Payment was declined or cancelled. Please try again.';
        });
      } else {
        setState(() {
          _state = _VerifyState.pending;
          _errorMessage = 'Payment verification is pending. Please refresh.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _VerifyState.failed;
        _errorMessage = ApiService.parseErrorMessage(e);
      });
    } finally {
      if (mounted) _iconCtrl.forward();
    }
  }

  void _navigateToOrderDetails() {
    if (_orderId != null) {
      final dummyOrder = Order(
        id: _orderId!,
        userId: '',
        status: OrderStatus.pending,
        subtotal: 0,
        tax: 0,
        total: 0,
        paymentMethod: PaymentMethod.online,
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/order-detail',
        (r) => r.settings.name == '/home',
        arguments: dummyOrder,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/my-orders', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _state == _VerifyState.loading
                  ? _buildLoading(isDark)
                  : _buildResult(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Verifying Payment…',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildResult(bool isDark) {
    final isSuccess = _state == _VerifyState.success;
    final isPending = _state == _VerifyState.pending;

    final Color iconBg = isSuccess
        ? AppColors.successGreen.withValues(alpha: 0.12)
        : isPending
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.errorRed.withValues(alpha: 0.12);

    final Color iconColor = isSuccess
        ? AppColors.successGreen
        : isPending
            ? AppColors.primary
            : AppColors.errorRed;

    final IconData iconData = isSuccess
        ? LucideIcons.circleCheck
        : isPending
            ? LucideIcons.clock
            : LucideIcons.circleX;

    return Column(
      children: [
        ScaleTransition(
          scale: _iconScale,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Icon(iconData, size: 54, color: iconColor),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          isSuccess ? 'Payment Confirmed! 🎉' : isPending ? 'Verification Pending' : 'Payment Failed',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isSuccess
              ? 'Your order has been placed successfully.'
              : _errorMessage ?? 'Something went wrong.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.6),
        ),
        const SizedBox(height: 36),
        if (isSuccess)
          ViewOrderButton(onPressed: _navigateToOrderDetails)
        else
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/checkout'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ),
      ],
    );
  }
}
