import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/checkout_provider.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:dealio/data/services/api_service.dart';
import 'package:dealio/features/orders/screens/order_detail_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class CheckoutStatusScreen extends StatefulWidget {
  final String? orderId;

  const CheckoutStatusScreen({super.key, this.orderId});

  @override
  State<CheckoutStatusScreen> createState() => _CheckoutStatusScreenState();
}

class _CheckoutStatusScreenState extends State<CheckoutStatusScreen>
    with SingleTickerProviderStateMixin {
  /// Verification state machine
  _VerifyState _state = _VerifyState.loading;
  String? _errorMessage;
  String? _orderId;
  bool _verificationStarted = false;

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
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    super.dispose();
  }

  // ── Step 1: Extract order_id ─────────────────────────────────────────────
  // On web: Paymob appends ?order_id=... to the URL, which Flutter web exposes
  //         via Uri.base.queryParameters.
  // On non-web / modal navigation: passed as a Map argument.
  String? _extractOrderId() {
    if (widget.orderId?.isNotEmpty == true) return widget.orderId;

    // Web: read from the live URL
    if (kIsWeb) {
      final uri = Uri.base;

      // 1. Standard query parameters (e.g. ?order_id=123)
      String? id = uri.queryParameters['order_id'] ?? uri.queryParameters['id'];
      if (id != null && id.isNotEmpty) return id;

      // 2. Hash fragment query parameters (e.g. #/checkout/status?order_id=123)
      if (uri.hasFragment) {
        final fragSplit = uri.fragment.split('?');
        if (fragSplit.length > 1) {
          final fragQuery = Uri.splitQueryString(fragSplit[1]);
          id = fragQuery['order_id'] ?? fragQuery['id'];
          if (id != null && id.isNotEmpty) return id;
        }
      }

      // 3. Fallback regex to catch it anywhere in the raw URL string
      final match = RegExp(
        r'[?&](?:order_id|id)=([^&]+)',
      ).firstMatch(uri.toString());
      if (match != null) {
        id = match.group(1);
        if (id != null && id.isNotEmpty) return id;
      }
    }

    // Fallback: route arguments (Map or plain String)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) return args;
    if (args is Map) {
      final id =
          args['order_id']?.toString() ??
          args['orderId']?.toString() ??
          args['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  // ── Step 2: Verify via backend & conditionally clear cart ───────────────
  Future<void> _resolveAndVerify() async {
    final orderId = _extractOrderId();
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    // A cold web return must not race AuthProvider's persisted-session restore.
    // build() schedules this verification again when isInitialized changes.
    if (!auth.isInitialized) {
      _verificationStarted = false;
      return;
    }

    if (orderId == null || orderId.isEmpty) {
      final isSuccessParam = kIsWeb
          ? (Uri.base.queryParameters['success'] == 'true')
          : false;
      if (isSuccessParam) {
        setState(() {
          _state = _VerifyState.pending;
          _errorMessage =
              'We are still processing your payment.\n'
              'Please check your Orders page in a few minutes.';
        });
      } else {
        setState(() {
          _state = _VerifyState.failed;
          _errorMessage =
              'No order ID found in the redirect URL.\n'
              'Please check your Orders page for payment status.';
        });
      }
      _iconCtrl.forward();
      return;
    }

    setState(() {
      _orderId = orderId;
      _state = _VerifyState.loading;
    });

    final accessToken = auth.token;
    if (!auth.isLoggedIn || accessToken == null || accessToken.isEmpty) {
      if (!mounted) return;
      setState(() {
        _state = _VerifyState.unverified;
        _errorMessage =
            'Your session is not available yet, so we could not '
            'verify this payment. Your order has not been changed.';
      });
      _iconCtrl.forward();
      return;
    }

    try {
      final checkout = context.read<CheckoutProvider>();
      final paymentStatus = await checkout.verifyPaymentStatus(
        orderId,
        accessToken: accessToken,
      );

      if (!mounted) return;

      if (paymentStatus == 'paid') {
        // ✅ Payment confirmed — clear the local cart so the badge resets
        // immediately. The server-side cart was already cleared by the
        // HMAC-verified webhook; this is just the in-memory UI update.
        context.read<CartProvider>().clearCart();
        setState(() => _state = _VerifyState.success);
      } else if (paymentStatus == 'failed') {
        // ❌ Payment failed — intentionally do NOT clear the cart.
        // Keeping items in the cart lets the user retry payment without
        // having to re-add everything.
        setState(() {
          _state = _VerifyState.failed;
          _errorMessage =
              'Your payment was not completed or was declined.\n'
              'Please try again or choose a different payment method.';
        });
      } else {
        // ⏳ 'pending' / 'initiated' — webhook hasn't fired yet.
        // Do NOT clear the cart; status is uncertain.
        setState(() {
          _state = _VerifyState.pending;
          _errorMessage =
              'Your payment is being verified. This may take a moment.\n'
              'Tap "Check Again" to refresh, or visit your Orders page.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      // On error, also do NOT clear the cart — we cannot confirm payment.
      setState(() {
        _state = _VerifyState.unverified;
        _errorMessage = ApiService.parseErrorMessage(e);
      });
    } finally {
      if (mounted) _iconCtrl.forward();
    }
  }

  // ── Navigation helpers ───────────────────────────────────────────────────
  void _goHome() {
    // Always build a clean stack anchored at /home so back-navigation works
    // whether we arrived via cold-start (Paymob redirect) or push.
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  void _goOrders() {
    // Build stack: /home → /my-orders
    // We first clear to /home (creates it if absent) then push /my-orders in the
    // next frame so back from My Orders goes to Home — even on a cold-start.
    final nav = Navigator.of(context);
    nav.pushNamedAndRemoveUntil('/home', (_) => false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nav.pushNamed('/my-orders');
    });
  }

  void _goOrderDetails() {
    if (_orderId == null) {
      _goOrders();
      return;
    }

    // Build a minimal stub Order to show the detail screen immediately.
    // The OrderDetailScreen's _tryFetchIfNeeded will call fetchOrderById
    // to populate items / address / totals within one frame.
    final stubOrder = Order(
      id: _orderId!,
      userId: '',
      status: OrderStatus.pending,
      subtotal: 0,
      tax: 0,
      total: 0,
      paymentMethod: PaymentMethod.online,
    );

    // Capture the navigator before any async gap.
    final nav = Navigator.of(context);

    // Ensure a valid /home is always at the bottom of the stack so the user
    // can press Back and reach Home — even after a Paymob cold-start redirect
    // where no /home exists in the navigator history.
    nav.pushNamedAndRemoveUntil('/home', (_) => false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const OrderDetailScreen(),
          settings: RouteSettings(name: '/order-detail', arguments: stubOrder),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (auth.isInitialized &&
        !_verificationStarted &&
        _state == _VerifyState.loading) {
      _verificationStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resolveAndVerify();
      });
    }

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

  // ── Loading spinner ──────────────────────────────────────────────────────
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
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Checking with Paymob servers. Please wait.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ── Result card (success / pending / failed) ─────────────────────────────
  Widget _buildResult(bool isDark) {
    final isSuccess = _state == _VerifyState.success;
    final isPending = _state == _VerifyState.pending;
    final isUnverified = _state == _VerifyState.unverified;

    final Color iconBg = isSuccess
        ? AppColors.successGreen.withValues(alpha: 0.12)
        : (isPending || isUnverified)
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.errorRed.withValues(alpha: 0.12);

    final Color iconColor = isSuccess
        ? AppColors.successGreen
        : (isPending || isUnverified)
        ? AppColors.primary
        : AppColors.errorRed;

    final IconData iconData = isSuccess
        ? LucideIcons.circleCheck
        : (isPending || isUnverified)
        ? LucideIcons.clock
        : LucideIcons.circleX;

    final String headline = isSuccess
        ? 'Payment Confirmed! 🎉'
        : isPending
        ? 'Verification Pending…'
        : isUnverified
        ? 'Unable to Verify Payment'
        : 'Payment Failed';

    final String subtext = isSuccess
        ? 'Your order has been placed and is being processed.'
        : _errorMessage ??
              'Something went wrong. Please check your Orders page.';

    return Column(
      children: [
        // ── Animated icon ──────────────────────────────────────────────────
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

        // ── Headline ───────────────────────────────────────────────────────
        Text(
          headline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 12),

        // ── Subtext ────────────────────────────────────────────────────────
        Text(
          subtext,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.6,
            color: AppColors.textMuted,
          ),
        ),

        if (_orderId != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.receipt, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Order #${_orderId!.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 36),

        // ── Action buttons ─────────────────────────────────────────────────
        if (isSuccess) ...[
          _PrimaryButton(
            label: 'View Order',
            icon: LucideIcons.package,
            onPressed: _goOrderDetails,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _goHome,
            child: Text(
              'Continue Shopping',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
        ] else if (isPending || isUnverified) ...[
          _PrimaryButton(
            label: isUnverified ? 'Try Again' : 'Check Again',
            icon: LucideIcons.refreshCw,
            onPressed: () {
              _iconCtrl.reset();
              _verificationStarted = true;
              setState(() => _state = _VerifyState.loading);
              _resolveAndVerify();
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _goOrders,
            icon: const Icon(LucideIcons.clipboardList, size: 16),
            label: const Text('View My Orders'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ] else ...[
          _PrimaryButton(
            label: 'Check Payment Again',
            icon: LucideIcons.refreshCw,
            onPressed: () {
              _iconCtrl.reset();
              _verificationStarted = true;
              setState(() => _state = _VerifyState.loading);
              _resolveAndVerify();
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _goHome,
            icon: const Icon(LucideIcons.house, size: 16),
            label: const Text('Back to Home'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Internal state machine ──────────────────────────────────────────────────
enum _VerifyState { loading, success, pending, failed, unverified }

// ─── Reusable primary button ─────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: AppColors.secondary),
        label: Text(
          label,
          style: const TextStyle(
            color: AppColors.secondary,
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
