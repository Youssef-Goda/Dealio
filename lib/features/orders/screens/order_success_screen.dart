import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/models/order_model.dart';
import 'package:dealio/features/orders/screens/order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// التوجيه لصفحة الطلبات وفتح تفاصيل الطلب الجديد تلقائياً بـ Slide-up transition
  Future<void> _trackOrder(Order order) async {
    if (!mounted) return;

    final navigator = Navigator.of(context);

    // الخطوة 1: تنظيف الـ Stack والرجوع لصفحة الطلبات
    // بنخلي الـ Home موجودة ونفتح فوقها My Orders
    navigator.pushNamedAndRemoveUntil(
      '/my-orders',
      (route) => route.settings.name == '/home',
    );

    // الخطوة 2: انتظار بسيط عشان الـ UI يلحق يـ mount
    await Future.delayed(const Duration(milliseconds: 250));
    if (!navigator.mounted) return;

    // الخطوة 3: فتح صفحة التفاصيل بـ Animation مخصص (Premium Feel)
    navigator.push(
      PageRouteBuilder<void>(
        settings: RouteSettings(name: '/order-detail', arguments: order),
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const OrderDetailScreen(),
        transitionsBuilder: (_, animation, __, child) {
          const begin = Offset(0.0, 1.0); // يبدأ من تحت
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as Order?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: R.isMobile(context) ? 28 : 80,
                vertical: 40,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // أيقونة النجاح المتحركة
                    _AnimatedSuccessIcon(isDark: isDark),
                    const SizedBox(height: 28),

                    Text(
                      'Order Placed! 🎉',
                      style: TextStyle(
                        fontSize: R.font(context, 26),
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your order has been confirmed and\nis being processed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textMuted),
                    ),

                    if (order != null) ...[
                      const SizedBox(height: 28),
                      // كارت ملخص الأوردر
                      _buildOrderSummaryCard(order, isDark),
                    ],

                    const SizedBox(height: 36),

                    // زرار Track My Order
                    _buildTrackButton(order, context),
                    
                    const SizedBox(height: 14),
                    
                    // زرار العودة للتسوق
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
                      child: Text(
                        'Continue Shopping',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(Order order, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('Order ID', '#${order.shortId}', AppColors.primary, isBold: true),
          const SizedBox(height: 10),
          _summaryRow('Total', 'EGP ${order.total.toStringAsFixed(2)}', 
              isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark),
          const SizedBox(height: 10),
          _summaryRow('Payment', order.paymentMethod.label, 
              isDark ? AppColors.darkTextSecondary : AppColors.textDark),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
            letterSpacing: isBold ? 1 : 0,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackButton(Order? order, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFC200)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: order != null 
            ? () => _trackOrder(order) 
            : () => Navigator.of(context).pushNamedAndRemoveUntil('/my-orders', (r) => r.settings.name == '/home'),
          icon: const Icon(LucideIcons.package, color: Colors.white, size: 18),
          label: const Text(
            'Track My Order',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}

// ── المكون المتحرك للأيقونة ──
class _AnimatedSuccessIcon extends StatefulWidget {
  final bool isDark;
  const _AnimatedSuccessIcon({required this.isDark});
  @override
  State<_AnimatedSuccessIcon> createState() => _AnimatedSuccessIconState();
}

class _AnimatedSuccessIconState extends State<_AnimatedSuccessIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ring = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return ScaleTransition(
          scale: _scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1.2 + _ring.value * 0.4,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.successGreen.withOpacity(0.1 * (1 - _ring.value)),
                  ),
                ),
              ),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.successGreen, AppColors.successGreenDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.successGreen.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.circleCheck, size: 50, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}