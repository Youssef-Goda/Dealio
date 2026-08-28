import 'dart:async';
import 'dart:ui';
import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/core/constants/base_url.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:e_commerce/data/providers/settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:e_commerce/data/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:e_commerce/features/admin/widgets/uploading_images.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Default banners (shown when backend has none) ─────────────────────────────
const List<Map<String, dynamic>> _kDefaultBanners = [
  {
    'id': 'default_1',
    'imageUrl': null,
    'gradient': [Color(0xFF1a1a2e), Color(0xFF16213e)],
    'title': '🔥 Hot Deals Today',
    'subtitle': 'Up to 50% off selected items',
  },
  {
    'id': 'default_2',
    'imageUrl': null,
    'gradient': [Color(0xFF0f3460), Color(0xFF533483)],
    'title': '✨ New Arrivals',
    'subtitle': 'Fresh products every week',
  },
  {
    'id': 'default_3',
    'imageUrl': null,
    'gradient': [Color(0xFF2d6a4f), Color(0xFF1b4332)],
    'title': '🚚 Free Delivery',
    'subtitle': 'On orders above 500 EGP',
  },
];

// ═════════════════════════════════════════════════════════════════════════════
// HomeBanner Widget
// ═════════════════════════════════════════════════════════════════════════════
class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  late final PageController _pageController = PageController(initialPage: 1000);
  int _currentPage = 1000;
  Timer? _autoScrollTimer;

  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = false;
  bool _hasFetched = false;
  bool? _lastBannerEnabledState;

  @override
  void initState() {
    super.initState();
    // Listen to PageController so _currentPage stays in sync on desktop
    // (desktop carousel uses AnimatedBuilder, not PageView.onPageChanged).
    _pageController.addListener(_onPageControllerScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<StoreSettingsProvider>();
    final isEnabled = settings.isBannerEnabled;

    if (isEnabled) {
      if (_lastBannerEnabledState != true || !_hasFetched) {
        _lastBannerEnabledState = true;
        _fetchBanners();
      }
    } else {
      _lastBannerEnabledState = false;
    }
  }

  void _onPageControllerScroll() {
    if (!_pageController.hasClients) return;
    final double? p = _pageController.page;
    if (p == null) return;
    final int rounded = p.round();
    if (rounded != _currentPage && mounted) {
      setState(() => _currentPage = rounded);
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.removeListener(_onPageControllerScroll);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBanners() async {
    final settings = context.read<StoreSettingsProvider>();
    if (!settings.isBannerEnabled) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasFetched = true;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasFetched = true;
    });

    try {
      final token = context.read<AuthProvider>().token ?? '';
      // ALWAYS call the GET /banners API (public endpoint)
      final res = await ApiService.getRequest('/banners', token);

      List<Map<String, dynamic>> loaded = [];
      final result = ApiService.processResponse(res);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          loaded = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['banners'] is List) {
          loaded = (data['banners'] as List).cast<Map<String, dynamic>>();
        } else if (data is Map) {
          final inner = data['data'];
          if (inner is List) loaded = inner.cast<Map<String, dynamic>>();
        }
      }

      if (mounted) {
        final bannersToUse = loaded.isNotEmpty ? loaded : _kDefaultBanners;
        final count = bannersToUse.length;
        final initP = count > 0 ? (1000 - (1000 % count)) : 1000;
        setState(() {
          _banners = bannersToUse;
          _currentPage = initP;
          _isLoading = false;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(initP);
        }
        _startAutoScroll();
      }
    } catch (e) {
      debugPrint('⚠️ Fetch banners error: $e');
      if (mounted) {
        final count = _kDefaultBanners.length;
        final initP = count > 0 ? (1000 - (1000 % count)) : 1000;
        setState(() {
          _banners = _kDefaultBanners;
          _currentPage = initP;
          _isLoading = false;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(initP);
        }
        _startAutoScroll();
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_banners.length <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // ── Admin/Moderator long-press management ─────────────────────────────────
  void _onLongPress(BuildContext context, Map<String, dynamic> banner) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin && auth.userRole != 'moderator') return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BannerManagementSheet(
        banner: banner,
        isDefaultBanner: banner['id'].toString().startsWith('default_'),
        onAdd: _showAddBannerDialog,
        onDelete: () => _deleteBanner(banner['id'].toString()),
      ),
    );
  }

  void _showAddBannerDialog() {
    Navigator.pop(context); // close bottom sheet
    final token = context.read<AuthProvider>().token ?? '';
    showDialog(
      context: context,
      builder: (_) => _AddBannerDialog(
        token: token,
        onSaved: (imageUrl, title, subtitle, linkUrl) async {
          await _saveBanner(imageUrl, title, subtitle, linkUrl);
        },
      ),
    );
  }

  Future<void> _saveBanner(String imageUrl, String title, String subtitle, String linkUrl) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;
    try {
      final res = await ApiService.postAuthRequest('/banners', {
        'imageUrl': imageUrl,
        'title': title,
        'subtitle': subtitle,
        'linkUrl': linkUrl,
      }, token);
      final result = ApiService.processResponse(res);
      if (result['success'] == true && mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'Banner added successfully!'),
        );
        _fetchBanners();
      } else if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: result['message']?.toString() ?? 'Failed to save banner.'),
        );
      }
    } catch (_) {}
  }

  Future<void> _deleteBanner(String bannerId) async {
    if (bannerId.startsWith('default_')) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/banners/$bannerId');
      final res = await http.delete(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (res.statusCode >= 200 && res.statusCode < 300 && mounted) {
        Navigator.pop(context);
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'Banner deleted!'),
        );
        _fetchBanners();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<StoreSettingsProvider>();

    // 1. If public settings are still loading or not initialized -> DO NOT show Banner Shimmer yet!
    if (settingsProv.isLoading || !settingsProv.isInitialized) {
      return const SizedBox.shrink();
    }

    // 2. If is_banner_enabled == false -> return SizedBox.shrink() immediately
    if (!settingsProv.isBannerEnabled) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final isPrivileged = auth.isAdmin || auth.userRole == 'moderator';

    // 3. Render Banner Shimmer ONLY IF is_banner_enabled == true AND banners API call is currently in a loading state
    if (_isLoading) {
      return _BannerSkeleton(isDark: isDark);
    }

    if (_banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _buildResponsiveCarousel(context, isDark, isPrivileged),
        const SizedBox(height: 14),
      ],
    );
  }

  // ── Edge-peeking carousel (Responsive for Mobile & Web) ────────────────────
  Widget _buildResponsiveCarousel(
      BuildContext context, bool isDark, bool isPrivileged) {
    return LayoutBuilder(builder: (context, constraints) {
      final double vw = constraints.maxWidth;
      final bool isMobile = vw < 600;
      final int total = _banners.length;

      final double mainFraction = isMobile ? 0.70 : 0.60;
      final double sideFraction = isMobile ? 0.50 : 0.50;
      final double mainAspect = isMobile ? (16 / 7.5) : (16 / 5.5);

      // Main banner dimensions
      final double mainW = vw * mainFraction;
      final double mainH = mainW / mainAspect;

      // Side banner dimensions
      final double sideW = mainW * sideFraction;
      final double sideH = sideW / mainAspect;
      final double sideTopOffset = (mainH - sideH) / 2;

      // Visible portion peeking from screen edge (leaving clear gap around main banner)
      final double peekW = sideW * (isMobile ? 0.28 : 0.36);

      // Position calculations with gap between main and side banners
      final double mainLeft = (vw - mainW) / 2;
      final double prevLeft = -(sideW - peekW);
      final double nextLeft = vw - peekW;

      final double stepPrevToMain = mainLeft - prevLeft;
      final double stepMainToNext = nextLeft - mainLeft;

      final double sideRadius = isMobile ? 10 : 14;
      final double mainRadius = isMobile ? 14 : 18;

      return SizedBox(
        height: mainH + 28, // +28 for dots row below
        child: ClipRect(
          child: Stack(
            children: [
              // ── Animated Visual Layer ──────────────────────────────────────
              AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  final double page = _pageController.hasClients
                      ? (_pageController.page ?? _currentPage.toDouble())
                      : _currentPage.toDouble();

                  final int base = page.floor();
                  final double offset = page - base;

                  if (total == 0) return const SizedBox.shrink();

                  final int mainIdx = base % total;
                  final int prevIdx = (base - 1 + total * 100) % total;
                  final int nextIdx = (base + 1) % total;
                  final int nextNextIdx = (base + 2) % total;

                  final double prevX = prevLeft - offset * stepPrevToMain;
                  final double mainX = mainLeft - offset * stepPrevToMain;
                  final double nextX = nextLeft - offset * stepMainToNext;
                  final double nextNextX =
                      nextLeft + stepMainToNext - offset * stepMainToNext;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. PREV (exits left, behind main)
                      if (total > 1)
                        Positioned(
                          left: prevX,
                          top: sideTopOffset,
                          width: sideW,
                          height: sideH,
                          child: Opacity(
                            opacity: (1.0 - offset).clamp(0.0, 1.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(sideRadius),
                              child: _BannerSlide(
                                  banner: _banners[prevIdx], isDark: isDark),
                            ),
                          ),
                        ),

                      // 2. NEXT-NEXT (enters from right, behind main)
                      if (total > 1 && offset > 0.0)
                        Positioned(
                          left: nextNextX,
                          top: sideTopOffset,
                          width: sideW,
                          height: sideH,
                          child: Opacity(
                            opacity: offset.clamp(0.0, 1.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(sideRadius),
                              child: _BannerSlide(
                                  banner: _banners[nextNextIdx],
                                  isDark: isDark),
                            ),
                          ),
                        ),

                      // 3. NEXT (moves toward center, growing into main)
                      if (total > 1)
                        Positioned(
                          left: nextX,
                          top: sideTopOffset * (1.0 - offset),
                          width: sideW + (mainW - sideW) * offset,
                          height: sideH + (mainH - sideH) * offset,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                sideRadius + (mainRadius - sideRadius) * offset),
                            child: _BannerSlide(
                                banner: _banners[nextIdx], isDark: isDark),
                          ),
                        ),

                      // 4. MAIN (moves toward left, shrinking into prev)
                      Positioned(
                        left: mainX,
                        top: sideTopOffset * offset,
                        width: mainW - (mainW - sideW) * offset,
                        height: mainH - (mainH - sideH) * offset,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              mainRadius - (mainRadius - sideRadius) * offset),
                          child: _BannerSlide(
                              banner: _banners[mainIdx], isDark: isDark),
                        ),
                      ),

                      // 5. Admin badge
                      if (isPrivileged)
                        Positioned(
                          top: 8,
                          right: 16,
                          child: _adminBadge(),
                        ),

                      // 6. Dots indicator
                      if (total > 1)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _dotsRow(),
                        ),
                    ],
                  );
                },
              ),

              // ── Interactive Mouse & Touch Controller Layer ─────────────────
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: mainH,
                child: ScrollConfiguration(
                  behavior: const _BannerScrollBehavior(),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: total <= 1 ? total : 100000,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (ctx, i) {
                      final b = _banners[i % total];
                      final linkUrl = b['linkUrl']?.toString() ??
                          b['link_url']?.toString() ??
                          '';
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: linkUrl.trim().isNotEmpty
                            ? () async {
                                final uri = Uri.tryParse(linkUrl.trim());
                                if (uri != null && await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              }
                            : null,
                        onLongPress: isPrivileged
                            ? () => _onLongPress(ctx, b)
                            : null,
                        child: Container(color: Colors.transparent),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Navigate to a specific page with animation and reset the auto-scroll timer.
  void _goToPage(int index) {
    _autoScrollTimer?.cancel();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _startAutoScroll();
  }

  // ── Shared UI helpers ────────────────────────────────────────────────────────

  Widget _adminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.pencil, size: 10, color: Colors.white70),
          SizedBox(width: 4),
          Text(
            'Hold to manage',
            style: TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _dotsRow() {
    final count = _banners.length;
    if (count <= 1) return const SizedBox.shrink();
    final realCurrent = _currentPage % count;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return GestureDetector(
          onTap: () {
            final targetPage = _currentPage + (i - realCurrent);
            _goToPage(targetPage);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: realCurrent == i ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: realCurrent == i ? Colors.white : Colors.white38,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Custom Scroll Behavior enabling mouse/touch dragging on Web & Desktop
// ═════════════════════════════════════════════════════════════════════════════
class _BannerScrollBehavior extends MaterialScrollBehavior {
  const _BannerScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

// ═════════════════════════════════════════════════════════════════════════════
// Individual banner slide (Vibrant, 100% clear colors)
// ═════════════════════════════════════════════════════════════════════════════
class _BannerSlide extends StatelessWidget {
  final Map<String, dynamic> banner;
  final bool isDark;

  const _BannerSlide({required this.banner, required this.isDark});

  String? _normalizeImageUrl(String? rawUrl) {
    if (rawUrl == null) return null;
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('/')) {
      final baseWithoutApi = AppConstants.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
      return '$baseWithoutApi$trimmed';
    }

    if (trimmed.contains('localhost') || trimmed.contains('127.0.0.1')) {
      try {
        final baseUri = Uri.parse(AppConstants.baseUrl);
        final itemUri = Uri.parse(trimmed);
        final newUri = itemUri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        );
        return newUri.toString();
      } catch (_) {
        return trimmed;
      }
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    // Support both camelCase (from defaults/new inserts) and snake_case (from DB)
    final rawUrl = banner['imageUrl']?.toString().trim().isNotEmpty == true
        ? banner['imageUrl'].toString()
        : banner['image_url']?.toString().trim().isNotEmpty == true
            ? banner['image_url'].toString()
            : null;
    final imageUrl = _normalizeImageUrl(rawUrl);
    final title = banner['title']?.toString() ?? '';
    final subtitle = banner['subtitle']?.toString() ?? '';
    final gradientColors = banner['gradient'] as List<Color>? ??
        [const Color(0xFF1a1a2e), const Color(0xFF16213e)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image - rendered 100% pure & vibrant (no darkening layer)
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),

          // Subtle gradient ONLY behind text if title or subtitle exist
          if (title.isNotEmpty || subtitle.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

          // Text content
          if (title.isNotEmpty || subtitle.isNotEmpty)
            Positioned(
              left: 20,
              bottom: 16,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(blurRadius: 6, color: Colors.black87),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black87),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Management bottom sheet (admin long-press)
// ═════════════════════════════════════════════════════════════════════════════
class _BannerManagementSheet extends StatelessWidget {
  final Map<String, dynamic> banner;
  final bool isDefaultBanner;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const _BannerManagementSheet({
    required this.banner,
    required this.isDefaultBanner,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ?  AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 35),
            child: Column(
              children: [
                const Text(
                  'Manage Banners',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _SheetOption(
                  icon: LucideIcons.imagePlus,
                  label: 'Add New Banner',
                  color: AppColors.primary,
                  onTap: onAdd,
                ),
                if (!isDefaultBanner) ...[
                  const SizedBox(height: 10),
                  _SheetOption(
                    icon: LucideIcons.trash2,
                    label: 'Delete This Banner',
                    color: AppColors.errorRed,
                    onTap: onDelete,
                  ),
                ],
                const SizedBox(height: 10),
                _SheetOption(
                  icon: LucideIcons.x,
                  label: 'Cancel',
                  color: Colors.grey,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Add Banner Dialog — Drag & Drop / Pick / URL · Blurred backdrop · App design
// ═════════════════════════════════════════════════════════════════════════════
class _AddBannerDialog extends StatefulWidget {
  final String token;
  final Future<void> Function(String imageUrl, String title, String subtitle, String linkUrl) onSaved;

  const _AddBannerDialog({required this.token, required this.onSaved});

  @override
  State<_AddBannerDialog> createState() => _AddBannerDialogState();
}

class _AddBannerDialogState extends State<_AddBannerDialog>
    with SingleTickerProviderStateMixin {
  final _imageUrlController = TextEditingController();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _linkUrlController = TextEditingController();

  bool _isSaving = false;
  bool _isUploading = false;
  bool _isDraggingOver = false;
  String? _uploadedUrl;

  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _linkUrlController.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Upload a local XFile via UploadingImages (same as products) ─────────────
  Future<void> _uploadFile(XFile file) async {
    setState(() {
      _isUploading = true;
      _uploadedUrl = null;
      _imageUrlController.clear();
    });
    try {
      final bytes = await file.readAsBytes();
      final url = await _UploadingImagesHelper.upload(
        bytes, file.name, widget.token,
      );
      if (mounted) {
        setState(() {
          _uploadedUrl = url;
          if (url != null) _imageUrlController.text = url;
          _isUploading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (file != null) await _uploadFile(file);
  }

  String? get _effectiveUrl {
    if (_uploadedUrl != null && _uploadedUrl!.isNotEmpty) return _uploadedUrl;
    final typed = _imageUrlController.text.trim();
    return typed.isEmpty ? null : typed;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 600;
    final hasImage = _effectiveUrl != null;

    final surfaceColor = Theme.of(context).cardColor;
    final labelColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimaryDark;
    final subColor = isDark ? AppColors.darkTextMuted : AppColors.textSecondary;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 520,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header bar ──────────────────────────────────────────
                    _BannerDialogHeader(isDark: isDark, labelColor: labelColor),

                    // ── Scrollable body ─────────────────────────────────────
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Image source section ─────────────────────
                            Text(
                              'Banner Image',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: labelColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Drag & drop zone (or picker on mobile)
                            _BannerDropZone(
                              isDark: isDark,
                              isUploading: _isUploading,
                              isDragging: _isDraggingOver,
                              uploadedUrl: _uploadedUrl,
                              shimmerAnim: _shimmerAnim,
                              onDragEnter: () => setState(() => _isDraggingOver = true),
                              onDragLeave: () => setState(() => _isDraggingOver = false),
                              onDrop: (file) async {
                                setState(() => _isDraggingOver = false);
                                await _uploadFile(file);
                              },
                              onPickTap: _isUploading ? null : _pickFromGallery,
                            ),

                            const SizedBox(height: 14),

                            // ── OR divider ──────────────────────────────
                            Row(
                              children: [
                                Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.dividerGrey)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'or paste URL',
                                    style: TextStyle(fontSize: 12, color: subColor),
                                  ),
                                ),
                                Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.dividerGrey)),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // URL field
                            _StyledField(
                              controller: _imageUrlController,
                              hint: 'https://example.com/image.jpg',
                              icon: LucideIcons.link,
                              isDark: isDark,
                              onChanged: (_) {
                                if (_uploadedUrl != null) {
                                  setState(() => _uploadedUrl = null);
                                }
                              },
                            ),

                            // Live preview
                            if (hasImage && !_isUploading) ...[
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 16 / 6,
                                  child: Image.network(
                                    _effectiveUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _ErrorPreview(isDark: isDark),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // ── Title ──────────────────────────────────
                            Text(
                              'Title (optional)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: labelColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _StyledField(
                              controller: _titleController,
                              hint: '🔥 Hot Deals Today',
                              icon: LucideIcons.type,
                              isDark: isDark,
                            ),

                            const SizedBox(height: 14),

                            // ── Subtitle ────────────────────────────────
                            Text(
                              'Subtitle',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: labelColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _StyledField(
                              controller: _subtitleController,
                              hint: 'Up to 50% off selected items',
                              icon: LucideIcons.pencil,
                              isDark: isDark,
                            ),

                            const SizedBox(height: 14),

                            // ── Link URL ────────────────────────────────
                            Text(
                              'Redirection Link / URL (optional)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: labelColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _StyledField(
                              controller: _linkUrlController,
                              hint: 'https://example.com or external browser link',
                              icon: LucideIcons.link,
                              isDark: isDark,
                            ),

                            const SizedBox(height: 28),

                            // ── Save button ─────────────────────────────
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: (hasImage && !_isUploading) ? 1.0 : 0.45,
                              child: ElevatedButton(
                                onPressed:
                                    (_isSaving || _isUploading || !hasImage)
                                        ? null
                                        : () async {
                                            setState(() => _isSaving = true);
                                            final url = _effectiveUrl!;
                                            final title = _titleController.text.trim();
                                            final sub = _subtitleController.text.trim();
                                            final link = _linkUrlController.text.trim();
                                            final nav = Navigator.of(context);
                                            await widget.onSaved(url, title, sub, link);
                                            if (mounted) nav.pop();
                                          },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.secondary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  disabledBackgroundColor:
                                      AppColors.primary.withValues(alpha: 0.35),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.secondary,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(LucideIcons.imagePlus, size: 17),
                                          const SizedBox(width: 8),
                                          Text(
                                            hasImage ? 'Save Banner' : 'Add an image first',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: subColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
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
}

// ─── Helper: upload via products endpoint (same compression as products) ───────
class _UploadingImagesHelper {
  static Future<String?> upload(
    Uint8List bytes,
    String filename,
    String token,
  ) async {
    try {
      return await UploadingImages.uploadImageToImgBB(bytes, filename, token);
    } catch (e) {
      debugPrint('❌ BannerUpload: $e');
      return null;
    }
  }
}

// ─── Dialog header bar ─────────────────────────────────────────────────────────
class _BannerDialogHeader extends StatelessWidget {
  final bool isDark;
  final Color labelColor;
  const _BannerDialogHeader({required this.isDark, required this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.dividerGrey,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.imagePlus,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Banner',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Upload a banner image to display on the home screen',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.x,
                size: 18,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Drag & Drop Zone ─────────────────────────────────────────────────────────
class _BannerDropZone extends StatelessWidget {
  final bool isDark;
  final bool isUploading;
  final bool isDragging;
  final String? uploadedUrl;
  final Animation<double> shimmerAnim;
  final VoidCallback? onPickTap;
  final void Function(XFile file) onDrop;
  final VoidCallback onDragEnter;
  final VoidCallback onDragLeave;

  const _BannerDropZone({
    required this.isDark,
    required this.isUploading,
    required this.isDragging,
    required this.uploadedUrl,
    required this.shimmerAnim,
    required this.onPickTap,
    required this.onDrop,
    required this.onDragEnter,
    required this.onDragLeave,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 600;
    final zoneHeight = isMobile ? 240.0 : 180.0;

    final borderColor = isDragging
        ? AppColors.primary
        : (isDark ? AppColors.darkBorder : AppColors.borderLight);
    final bgColor = isDragging
        ? AppColors.primary.withValues(alpha: 0.07)
        : (isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.withValues(alpha: 0.04));

    return DragTarget<Object>(
      onWillAcceptWithDetails: (_) {
        onDragEnter();
        return true;
      },
      onLeave: (_) => onDragLeave(),
      onAcceptWithDetails: (details) async {
        final data = details.data;
        if (data is XFile) {
          onDrop(data);
        }
      },
      builder: (ctx, candidateData, rejectedData) {
        return GestureDetector(
          onTap: onPickTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: zoneHeight,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isDragging ? 2 : 1.5,
              ),
            ),
            child: isUploading
                ? _UploadingIndicator(shimmerAnim: shimmerAnim, isDark: isDark)
                : _DropZoneIdle(
                    isDark: isDark,
                    isDragging: isDragging,
                    onPickTap: onPickTap,
                  ),
          ),
        );
      },
    );
  }
}

// ── Uploading shimmer state ─────────────────────────────────────────────────
class _UploadingIndicator extends StatelessWidget {
  final Animation<double> shimmerAnim;
  final bool isDark;
  const _UploadingIndicator({required this.shimmerAnim, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0.0, 0.45, 0.55, 1.0],
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.04),
                  ]
                : [
                    Colors.grey.withValues(alpha: 0.08),
                    Colors.grey.withValues(alpha: 0.18),
                    Colors.grey.withValues(alpha: 0.08),
                    Colors.grey.withValues(alpha: 0.08),
                  ],
            transform: GradientRotation(shimmerAnim.value),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Uploading…',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Idle drop zone ─────────────────────────────────────────────────────────
class _DropZoneIdle extends StatelessWidget {
  final bool isDark;
  final bool isDragging;
  final VoidCallback? onPickTap;
  const _DropZoneIdle({
    required this.isDark,
    required this.isDragging,
    required this.onPickTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDragging
                ? AppColors.primary.withValues(alpha: 0.18)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.withValues(alpha: 0.10)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDragging ? LucideIcons.imageDown : Icons.add_photo_alternate_outlined,
            size: 26,
            color: isDragging
                ? AppColors.primary
                : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isDragging ? 'Drop to upload' : 'Drag & drop an image here',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDragging
                ? AppColors.primary
                : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimaryDark),
          ),
        ),
        const SizedBox(height: 4),
        if (!isDragging)
          Text(
            'PNG · JPG · WebP supported',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
            ),
          ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onPickTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  'Browse Files',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Styled text field ─────────────────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final void Function(String)? onChanged;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimaryDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkTextMuted : AppColors.textHint,
        ),
        prefixIcon: Icon(icon, size: 16,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        isDense: true,
      ),
    );
  }
}

// ─── Error preview placeholder ─────────────────────────────────────────────────
class _ErrorPreview extends StatelessWidget {
  final bool isDark;
  const _ErrorPreview({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.imageOff,
                size: 28,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            const SizedBox(height: 6),
            Text(
              'Could not load image preview',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Skeleton loader
// ═════════════════════════════════════════════════════════════════════════════
class _BannerSkeleton extends StatelessWidget {
  final bool isDark;
  const _BannerSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isLarge = screenW >= 900;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isLarge ? 900 : double.infinity),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AspectRatio(
            aspectRatio: isLarge ? (16 / 5.5) : (16 / 7),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.grey[200],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

