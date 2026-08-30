import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/data/providers/checkout_provider.dart';
import 'package:dealio/data/providers/orders_provider.dart';
import 'package:dealio/data/providers/profile_provider.dart';
import 'package:dealio/features/checkout/widgets/address_card.dart';
import 'package:dealio/features/checkout/widgets/address_form_dialog.dart';
import 'package:dealio/features/checkout/widgets/order_summary_panel.dart';
import 'package:dealio/features/checkout/widgets/payment_method_selector.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:dealio/features/checkout/widgets/fawry_cash_modal.dart';
import 'package:flutter_paymob_sdk/flutter_paymob_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckoutProvider>().fetchAddresses();
    });
  }

  // ───────────────────── placeOrder / Paymob Flow ──────────────
  Future<void> _handlePlaceOrder() async {
    final checkout = context.read<CheckoutProvider>();
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();

    if (checkout.selectedAddress == null) {
      _showError('Please select a delivery address.');
      return;
    }

    // Guard against double-tap while already loading
    if (checkout.isPlacingOrder || checkout.isInitiatingPayment) return;

    try {
      // ── Step 1: Create the order (stays 'pending' until payment confirmed) ──
      final order = await checkout.placeOrder(
        userId: auth.userId,
        cartItems: cart.items,
        subtotal: cart.subtotal,
        tax: cart.tax,
        total: cart.total,
      );

      // ── Cash on Delivery: no Paymob needed ───────────────────────────
      if (checkout.paymentMethod == PaymentMethod.cod) {
        if (!mounted) return;
        context.read<OrdersProvider>().prependOrder(order);
        cart.clearLocalCart();
        Navigator.of(
          context,
        ).pushReplacementNamed('/order-success', arguments: order);
        return;
      }

      // ── Step 2: Initiate Paymob session (card / wallet / cash) ────────
      // For wallet payment, pass registered user phone or shipping address phone as fallback
      String? userWalletPhone;
      if (checkout.paymentMethod == PaymentMethod.wallet) {
        try {
          final profilePhone = context.read<ProfileProvider>().phoneNumber;
          if (profilePhone.isNotEmpty) userWalletPhone = profilePhone;
        } catch (_) {}
        if ((userWalletPhone == null || userWalletPhone.isEmpty) &&
            checkout.selectedAddress != null) {
          userWalletPhone = checkout.selectedAddress!.phone;
        }
      }

      final result = await checkout.initiatePaymobPayment(
        orderId: order.id,
        paymentMethod: checkout.paymentMethod,
        amount: cart.total,
        walletNumber: userWalletPhone,
      );

      if (!mounted) return;

      final paymentType = result['payment_type'] as String? ?? 'card';

      // ── Cash / Fawry: show bill reference modal ─────────────────────
      if (paymentType == 'cash') {
        // Provider now returns 'reference_number' and 'expire_date'
        final ref = result['reference_number'] as String? ?? '';
        final expires = result['expire_date'] as String? ?? '';

        if (ref.isEmpty) {
          _showError('No bill reference was returned. Please try again.');
          return;
        }

        await FawryCashModal.show(
          context,
          billReference: ref,
          expiresAt: expires,
          amount: cart.total,
          onDone: () {
            context.read<OrdersProvider>().prependOrder(order);
            cart.clearLocalCart();
            Navigator.of(
              context,
            ).pushReplacementNamed('/order-success', arguments: order);
          },
        );
        return;
      }

      // ── Card / Wallet: open Paymob native SDK / Unified Checkout ───────
      final clientSecret = result['client_secret'] as String? ?? '';
      final publicKey = (result['public_key'] as String?)?.isNotEmpty == true
          ? result['public_key'] as String
          : const String.fromEnvironment('PAYMOB_PUBLIC_KEY', defaultValue: '');

      if (clientSecret.isEmpty) {
        _showError('Client secret was not returned. Please try again.');
        return;
      }

      // final unifiedCheckoutUrl = (result['payment_url'] as String?)?.isNotEmpty == true
      //     ? result['payment_url'] as String
      //     : (publicKey.isNotEmpty
      //         ? 'https://accept.paymob.com/unifiedcheckout/?publicKey=${Uri.encodeComponent(publicKey)}&clientSecret=${Uri.encodeComponent(clientSecret)}'
      //         : null);

      // --- التعديل هنا: تحديد الدومين ديناميكياً ---
      final isTestKey = publicKey.toLowerCase().contains('test');
      final domain = isTestKey
          ? 'accept.paymobsolutions.com'
          : 'accept.paymob.com';

      final unifiedCheckoutUrl =
          (result['payment_url'] as String?)?.isNotEmpty == true
          ? result['payment_url'] as String
          : (publicKey.isNotEmpty
                ? 'https://$domain/unifiedcheckout/?publicKey=${Uri.encodeComponent(publicKey)}&clientSecret=${Uri.encodeComponent(clientSecret)}'
                : null);
      // ----------------------------------------------

      try {
        final paymobService = PaymobService();
        final paymentResult = await paymobService.payWithPaymob(
          publicKey: publicKey,
          clientSecret: clientSecret,
        );

        if (!mounted) return;

        if (paymentResult.status == PaymentStatus.successful) {
          context.read<OrdersProvider>().prependOrder(order);
          cart.clearLocalCart();
          Navigator.of(
            context,
          ).pushReplacementNamed('/order-success', arguments: order);
        } else if (paymentResult.status == PaymentStatus.unknown &&
            (paymentResult.errorMessage?.contains('MissingPluginException') ==
                    true ||
                paymentResult.errorMessage?.contains('NotImplemented') ==
                    true) &&
            unifiedCheckoutUrl != null) {
          // // Fallback to Unified Checkout URL ONLY for unsupported platforms (e.g. Web, Windows)
          // final uri = Uri.parse(unifiedCheckoutUrl);
          // if (await canLaunchUrl(uri)) {
          //   await launchUrl(
          //     uri,
          //     mode: LaunchMode.externalApplication,
          //     webOnlyWindowName: '_self',
          //   );
          // } else {
          //   _showError('Could not open Paymob checkout page.');
          // }
          // Fallback to Unified Checkout URL via In-App WebView
          final uri = Uri.parse(unifiedCheckoutUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView,
              webViewConfiguration: const WebViewConfiguration(
                enableJavaScript: true,
              ),
            );
          } else {
            _showError('Could not open Paymob checkout page.');
          }
        } else {
          _showError(
            paymentResult.errorMessage?.isNotEmpty == true
                ? paymentResult.errorMessage!
                : 'Payment was declined or cancelled. Please try again.',
          );
        }
      } catch (e) {
        final errorStr = e.toString();
        if ((errorStr.contains('MissingPluginException') ||
                errorStr.contains('Unsupported operation')) &&
            unifiedCheckoutUrl != null) {
          final uri = Uri.parse(unifiedCheckoutUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView,
              webViewConfiguration: const WebViewConfiguration(
                enableJavaScript: true,
              ),
            );
            return;
          }
        }
        if (mounted) _showError(errorStr.replaceAll('Exception: ', ''));
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = R.isMobile(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkAppBar : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimaryDark,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimaryDark,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.dividerGrey,
          ),
        ),
      ),
      body: isMobile
          ? _MobileLayout(onPlaceOrder: _handlePlaceOrder, isDark: isDark)
          : _DesktopLayout(onPlaceOrder: _handlePlaceOrder, isDark: isDark),
    );
  }
}

// ─────────────────────── Mobile (1-column) ───────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final VoidCallback onPlaceOrder;
  final bool isDark;
  const _MobileLayout({required this.onPlaceOrder, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Delivery Address',
                  icon: LucideIcons.mapPin,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _AddressSection(isDark: isDark),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Payment Method',
                  icon: LucideIcons.creditCard,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                const PaymentMethodSelector(),
              ],
            ),
          ),
        ),
        OrderSummaryPanel(onPlaceOrder: onPlaceOrder, compact: true),
      ],
    );
  }
}

// ──────────────────── Desktop / Tablet (2-column) ────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final VoidCallback onPlaceOrder;
  final bool isDark;
  const _DesktopLayout({required this.onPlaceOrder, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left 60%: Form ─────────────────────────────
        Flexible(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 28, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Delivery Address',
                  icon: LucideIcons.mapPin,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _AddressSection(isDark: isDark),
                const SizedBox(height: 32),
                _SectionHeader(
                  title: 'Payment Method',
                  icon: LucideIcons.creditCard,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                const PaymentMethodSelector(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // ── Right 40%: Sticky Summary ───────────────────
        Flexible(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 28, 32, 28),
            child: _StickyPanel(
              child: OrderSummaryPanel(onPlaceOrder: onPlaceOrder),
            ),
          ),
        ),
      ],
    );
  }
}

/// Simulates sticky positioning using a ConstrainedBox inside a scrollable area.
class _StickyPanel extends StatelessWidget {
  final Widget child;
  const _StickyPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - kToolbarHeight - 80,
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}

// ─────────────────── Shared Widgets ──────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }
}

class _AddressSection extends StatelessWidget {
  final bool isDark;
  const _AddressSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutProvider>(
      builder: (context, checkout, _) {
        if (checkout.isLoading) {
          return const _AddressShimmer();
        }

        return Column(
          children: [
            ...checkout.addresses.map(
              (addr) => AddressCard(
                address: addr,
                isSelected: checkout.selectedAddress?.id == addr.id,
              ),
            ),
            const SizedBox(height: 4),
            _AddNewButton(isDark: isDark),
          ],
        );
      },
    );
  }
}

class _AddNewButton extends StatelessWidget {
  final bool isDark;
  const _AddNewButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showAddressFormDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plus, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Add New Address',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressShimmer extends StatefulWidget {
  const _AddressShimmer();

  @override
  State<_AddressShimmer> createState() => _AddressShimmerState();
}

class _AddressShimmerState extends State<_AddressShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.3 + _ctrl.value * 0.4,
        child: Column(
          children: List.generate(
            2,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
