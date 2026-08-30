import 'dart:ui';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/constants/egypt_geo_data.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/data/models/shipping_address_model.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/checkout_provider.dart';
import 'package:dealio/data/providers/profile_provider.dart';
import 'package:dealio/data/services/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Blurred backdrop modal for adding / editing a shipping address.
Future<void> showAddressFormDialog(
  BuildContext context, {
  ShippingAddress? existing,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _AddressFormDialog(existing: existing),
  );
}

class _AddressFormDialog extends StatefulWidget {
  final ShippingAddress? existing;
  const _AddressFormDialog({this.existing});

  @override
  State<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<_AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line1;
  late final TextEditingController _line2;

  // ── Geo-data state ───────────────────────────────────────────
  String? _selectedGovernorate;
  String? _selectedCity;
  List<String> _availableCities = [];

  // ── GPS state ────────────────────────────────────────────────
  double? _lat;
  double? _lng;
  bool _detectingLocation = false;
  String? _locationStatus; // e.g. "Location detected ✓" or error msg

  // ── Immutability flags ───────────────────────────────────────
  bool _nameReadOnly = false;
  bool _phoneReadOnly = false;

  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    final profile = _profileProvider;
    final auth = _authProvider;

    // ── Pre-fill Name (Phase 2) ──────────────────────────────
    final profileName = _resolveName(profile, auth);
    final initialName =
        e?.fullName.isNotEmpty == true ? e!.fullName : profileName;
    _name = TextEditingController(text: initialName);
    _nameReadOnly = e == null && profileName.isNotEmpty;

    // ── Pre-fill Phone (Phase 2) ─────────────────────────────
    final profilePhone = _resolvePhone(profile, auth);
    final initialPhone =
        e?.phone.isNotEmpty == true ? e!.phone : profilePhone;
    _phone = TextEditingController(text: initialPhone);
    _phoneReadOnly = e == null && profilePhone.isNotEmpty;

    _line1 = TextEditingController(text: e?.addressLine1 ?? '');
    _line2 = TextEditingController(text: e?.addressLine2 ?? '');
    _isDefault = e?.isDefault ?? false;
    _lat = e?.latitude;
    _lng = e?.longitude;

    // ── Restore GPS-stored coords label ──────────────────────
    if (_lat != null && _lng != null) {
      _locationStatus = 'Saved coordinates restored ✓';
    }

    // ── Geo dropdowns (Phase 3) ──────────────────────────────
    if (e != null && e.governorate.isNotEmpty) {
      _selectedGovernorate =
          EgyptGeoData.governorates.contains(e.governorate)
              ? e.governorate
              : null;
      if (_selectedGovernorate != null) {
        _availableCities = EgyptGeoData.citiesFor(_selectedGovernorate!);
        _selectedCity =
            _availableCities.contains(e.city) ? e.city : null;
      }
    }
  }

  // ── Providers ─────────────────────────────────────────────
  ProfileProvider get _profileProvider =>
      Provider.of<ProfileProvider>(context, listen: false);
  AuthProvider get _authProvider =>
      Provider.of<AuthProvider>(context, listen: false);

  String _resolveName(ProfileProvider p, AuthProvider a) {
    final fn = p.firstName.trim();
    final ln = p.lastName.trim();
    if (fn.isNotEmpty || ln.isNotEmpty) return '$fn $ln'.trim();
    final user = a.user;
    final fn2 =
        (user['firstName'] ?? user['first_name'] ?? '').toString().trim();
    final ln2 =
        (user['lastName'] ?? user['last_name'] ?? '').toString().trim();
    return '$fn2 $ln2'.trim();
  }

  String _resolvePhone(ProfileProvider p, AuthProvider a) {
    final pp = p.phoneNumber.trim();
    if (pp.isNotEmpty) return pp;
    final user = a.user;
    return (user['phoneNumber'] ??
            user['phone_number'] ??
            user['phone'] ??
            '')
        .toString()
        .trim();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    super.dispose();
  }

  // ── Governorate selection ────────────────────────────────────
  void _onGovernorateChanged(String? gov) {
    setState(() {
      _selectedGovernorate = gov;
      _selectedCity = null;
      _availableCities =
          gov != null ? EgyptGeoData.citiesFor(gov) : [];
    });
  }

  // ── GPS auto-fill ────────────────────────────────────────────
  Future<void> _detectLocation() async {
    setState(() {
      _detectingLocation = true;
      _locationStatus = null;
    });

    try {
      final result = await LocationService.detectAndGeocode();
      if (!mounted) return;

      if (result == null) {
        setState(() {
          _locationStatus = 'Could not detect location. Fill manually.';
          _detectingLocation = false;
        });
        return;
      }

      // ── Store coordinates ──────────────────────────────────
      _lat = result.lat;
      _lng = result.lng;

      // ── Auto-fill governorate ──────────────────────────────
      String? newGov;
      String? newCity;
      List<String> newCities = [];

      if (result.govCandidate != null) {
        newGov = result.govCandidate;
        newCities = EgyptGeoData.citiesFor(newGov!);

        // ── Auto-fill city (fuzzy match) ────────────────────
        if (result.cityCandidate != null && newCities.isNotEmpty) {
          newCity = _fuzzyMatchCity(result.cityCandidate!, newCities);
        }
      }

      // ── Auto-fill address line 1 ──────────────────────────
      if (result.streetHint != null &&
          result.streetHint!.isNotEmpty &&
          _line1.text.trim().isEmpty) {
        _line1.text = result.streetHint!;
      }

      setState(() {
        _selectedGovernorate = newGov;
        _availableCities = newCities;
        _selectedCity = newCity;
        _locationStatus = newGov != null
            ? 'Location detected: $newGov${newCity != null ? ', $newCity' : ''} ✓'
            : 'Location found but governorate unrecognized. Select manually.';
        _detectingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationStatus = 'Error: $e';
        _detectingLocation = false;
      });
    }
  }

  /// Fuzzy-match [raw] against [candidates]. Returns the best match or null.
  String? _fuzzyMatchCity(String raw, List<String> candidates) {
    final norm = raw.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    // 1. Exact
    for (final c in candidates) {
      if (c.toLowerCase().replaceAll(RegExp(r'\s+'), '') == norm) return c;
    }
    // 2. Contains
    for (final c in candidates) {
      final cn = c.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      if (cn.contains(norm) || norm.contains(cn)) return c;
    }
    return null;
  }

  // ── Save ─────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final address = ShippingAddress(
      id: widget.existing?.id ?? '',
      userId: '',
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      addressLine1: _line1.text.trim(),
      addressLine2:
          _line2.text.trim().isEmpty ? null : _line2.text.trim(),
      city: _selectedCity ?? '',
      governorate: _selectedGovernorate ?? '',
      isDefault: _isDefault,
      latitude: _lat,
      longitude: _lng,
    );

    final provider = context.read<CheckoutProvider>();

    try {
      if (widget.existing == null) {
        await provider.addAddress(address);
      } else {
        await provider.updateAddress(address);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.toString().replaceFirst('Exception: ', ''),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : Colors.white;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: R.isMobile(context) ? 20 : 80,
          vertical: 32,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogHeader(
                title: widget.existing == null
                    ? 'New Address'
                    : 'Edit Address',
                isDark: isDark,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // ── GPS Button (Mobile only) ──────────
                        if (!kIsWeb) ...[
                          _buildGpsButton(isDark: isDark),
                          const SizedBox(height: 16),
                        ],

                        // ── Full Name ────────────────────────
                        _buildField(
                          controller: _name,
                          label: 'Full Name',
                          icon: LucideIcons.user,
                          isDark: isDark,
                          readOnly: _nameReadOnly,
                          readOnlyHint: 'From your profile',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                        ),
                        const SizedBox(height: 14),

                        // ── Phone ────────────────────────────
                        _buildField(
                          controller: _phone,
                          label: 'Phone Number',
                          icon: LucideIcons.phone,
                          keyboardType: TextInputType.phone,
                          isDark: isDark,
                          readOnly: _phoneReadOnly,
                          readOnlyHint: 'From your profile',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (!_phoneReadOnly) {
                              final digits = v
                                  .trim()
                                  .replaceAll(RegExp(r'\D'), '');
                              if (digits.length < 10 ||
                                  digits.length > 15) {
                                return 'Enter a valid phone number (10–15 digits)';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Address Line 1 ───────────────────
                        _buildField(
                          controller: _line1,
                          label: 'Address Line 1',
                          icon: LucideIcons.mapPin,
                          isDark: isDark,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                        ),
                        const SizedBox(height: 14),

                        // ── Address Line 2 ───────────────────
                        _buildField(
                          controller: _line2,
                          label: 'Address Line 2 (optional)',
                          icon: LucideIcons.mapPin,
                          isDark: isDark,
                          validator: null,
                        ),
                        const SizedBox(height: 14),

                        // ── Governorate Dropdown ─────────────
                        _buildDropdown(
                          value: _selectedGovernorate,
                          label: 'Governorate',
                          icon: LucideIcons.landmark,
                          isDark: isDark,
                          items: EgyptGeoData.governorates,
                          onChanged: _onGovernorateChanged,
                          validator: (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Please select a governorate'
                                  : null,
                        ),
                        const SizedBox(height: 14),

                        // ── City Dropdown ────────────────────
                        _buildDropdown(
                          value: _selectedCity,
                          label: 'City',
                          icon: LucideIcons.building2,
                          isDark: isDark,
                          items: _availableCities,
                          onChanged: _selectedGovernorate == null
                              ? null
                              : (v) =>
                                  setState(() => _selectedCity = v),
                          hint: _selectedGovernorate == null
                              ? 'Select governorate first'
                              : 'Select city',
                          validator: (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Please select a city'
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        // ── Default Toggle ───────────────────
                        _buildDefaultToggle(isDark: isDark),
                        const SizedBox(height: 20),

                        // ── Save Button ──────────────────────
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── GPS Button + Status ───────────────────────────────────────
  Widget _buildGpsButton({required bool isDark}) {
    final bool hasStatus = _locationStatus != null;
    final bool isSuccess =
        hasStatus && _locationStatus!.contains('✓');
    final statusColor = isSuccess
        ? AppColors.successGreen
        : AppColors.warningAmber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Button
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.6),
              width: 1.5,
            ),
            color: isDark
                ? AppColors.darkBackground
                : AppColors.backgroundLight,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _detectingLocation ? null : _detectLocation,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_detectingLocation)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    const Icon(
                      LucideIcons.locateFixed,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    _detectingLocation
                        ? 'Detecting location…'
                        : 'Detect My Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Status chip
        if (hasStatus) ...[
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: statusColor.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSuccess
                      ? LucideIcons.circleCheck
                      : LucideIcons.triangleAlert,
                  size: 15,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationStatus!,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Field Builders ────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool readOnly = false,
    String? readOnlyHint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final textColor = readOnly
        ? AppColors.textMuted
        : (isDark
            ? AppColors.darkTextPrimary
            : AppColors.textPrimaryDark);
    final fillColor = readOnly
        ? (isDark
            ? AppColors.darkBorder.withOpacity(0.3)
            : AppColors.borderLight.withOpacity(0.4))
        : (isDark
            ? AppColors.darkBackground
            : AppColors.backgroundLight);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon: Icon(icon,
            size: 18,
            color: readOnly
                ? AppColors.textMuted.withOpacity(0.6)
                : AppColors.textMuted),
        suffixIcon: readOnly && readOnlyHint != null
            ? Tooltip(
                message: readOnlyHint,
                child: Icon(LucideIcons.lock,
                    size: 15,
                    color: AppColors.textMuted.withOpacity(0.6)),
              )
            : null,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                readOnly ? AppColors.textMuted : AppColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required bool isDark,
    required List<String> items,
    required void Function(String?)? onChanged,
    required String? Function(String?)? validator,
    String? hint,
  }) {
    final isDisabled = onChanged == null;
    final fillColor = isDisabled
        ? (isDark
            ? AppColors.darkBorder.withOpacity(0.2)
            : AppColors.borderLight.withOpacity(0.3))
        : (isDark
            ? AppColors.darkBackground
            : AppColors.backgroundLight);

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: Text(
        hint ?? 'Select $label',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textMuted
              .withOpacity(isDisabled ? 0.5 : 1.0),
        ),
      ),
      style: TextStyle(
        fontSize: 14,
        color: isDisabled
            ? AppColors.textMuted
            : (isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimaryDark),
      ),
      dropdownColor:
          isDark ? AppColors.darkSurface : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon: Icon(icon,
            size: 18,
            color: isDisabled
                ? AppColors.textMuted.withOpacity(0.5)
                : AppColors.textMuted),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 4),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item,
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDefaultToggle({required bool isDark}) {
    return GestureDetector(
      onTap: () => setState(() => _isDefault = !_isDefault),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isDefault
              ? AppColors.primary.withOpacity(0.1)
              : (isDark
                  ? AppColors.darkBackground
                  : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDefault
                ? AppColors.primary
                : (isDark
                    ? AppColors.darkBorder
                    : AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isDefault
                    ? LucideIcons.circleCheck
                    : LucideIcons.circle,
                key: ValueKey(_isDefault),
                color: _isDefault
                    ? AppColors.primary
                    : AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Set as default address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFC200)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.existing == null
                      ? 'Save Address'
                      : 'Update Address',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _DialogHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _DialogHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.mapPin,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimaryDark,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(LucideIcons.x,
                color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }
}
