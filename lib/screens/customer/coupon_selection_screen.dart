import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';

class CouponSelectionScreen extends ConsumerStatefulWidget {
  const CouponSelectionScreen({super.key});

  @override
  ConsumerState<CouponSelectionScreen> createState() =>
      _CouponSelectionScreenState();
}

class _CouponSelectionScreenState extends ConsumerState<CouponSelectionScreen> {
  final CouponService _couponService = CouponService();
  final TextEditingController _couponCodeController = TextEditingController();
  List<Coupon> _availableCoupons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableCoupons();
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCoupons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      final cart = ref.read(cartProvider);

      final coupons = await _couponService.getAvailableCoupons(
        user?.id ?? 'guest',
        isFirstTimeUser: user == null,
      );

      setState(() {
        _availableCoupons = coupons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load coupons: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _applyCouponCode() async {
    final code = _couponCodeController.text.trim();
    if (code.isEmpty) return;

    try {
      final user = ref.read(currentUserProvider);
      final cart = ref.read(cartProvider);

      final coupon = await _couponService.validateCoupon(
        code,
        user?.id ?? 'guest',
        cart.items,
        cart.subtotal,
      );

      if (coupon != null && mounted) {
        final cart = ref.read(cartProvider);
        final discount = _couponService.calculateDiscount(
          coupon,
          cart.items,
          cart.subtotal,
          cart.deliveryFee,
        );
        ref
            .read(cartProvider.notifier)
            .applyCoupon(coupon.code, discount.discountAmount);
        Navigator.pop(context, coupon);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or expired coupon code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying coupon: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectCoupon(Coupon coupon) {
    final cart = ref.read(cartProvider);
    final discount = _couponService.calculateDiscount(
      coupon,
      cart.items,
      cart.subtotal,
      cart.deliveryFee,
    );
    ref
        .read(cartProvider.notifier)
        .applyCoupon(coupon.code, discount.discountAmount);
    Navigator.pop(context, coupon);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Coupon'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with cart info
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(Icons.local_offer, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Coupons',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cart Total: TZS ${cart.subtotal.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Manual coupon code entry
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Coupon Code',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponCodeController,
                            decoration: const InputDecoration(
                              hintText: 'Enter coupon code',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.confirmation_number),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _applyCouponCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Available coupons list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error Loading Coupons',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadAvailableCoupons,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _availableCoupons.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 80,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Coupons Available',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for new offers',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _availableCoupons.length,
                      itemBuilder: (context, index) {
                        final coupon = _availableCoupons[index];
                        return _buildCouponCard(coupon, theme, colorScheme);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(
    Coupon coupon,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final cart = ref.watch(cartProvider);
    final discount = _couponService.calculateDiscount(
      coupon,
      cart.items,
      cart.subtotal,
      cart.deliveryFee,
    );
    final isApplicable = discount.hasDiscount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isApplicable ? 2 : 1,
      color:
          isApplicable
              ? null
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isApplicable ? () => _selectCoupon(coupon) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isApplicable
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.3,
                              ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      coupon.code,
                      style: TextStyle(
                        color:
                            isApplicable
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isApplicable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Save TZS ${discount.discountAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                coupon.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isApplicable ? null : colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                coupon.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isApplicable
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${coupon.endDate.day}/${coupon.endDate.month}/${coupon.endDate.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (!isApplicable)
                    Text(
                      'Not applicable',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),

              if (coupon.minimumOrderAmount != null &&
                  coupon.minimumOrderAmount! > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Minimum order: TZS ${coupon.minimumOrderAmount!.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
