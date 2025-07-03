import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';
import '../models/cart_item_model.dart';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get available coupons for a user
  Future<List<Coupon>> getAvailableCoupons(
    String userId, {
    bool isFirstTimeUser = false,
  }) async {
    try {
      Query query = _firestore
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: Timestamp.now());

      if (isFirstTimeUser) {
        query = query.where('isFirstTimeUser', isEqualTo: true);
      }

      final snapshot = await query.get();
      final coupons =
          snapshot.docs
              .map(
                (doc) =>
                    Coupon.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .where((coupon) => coupon.isValid)
              .toList();

      return coupons;
    } catch (e) {
      throw Exception('Failed to fetch coupons: $e');
    }
  }

  // Validate coupon code
  Future<Coupon?> validateCoupon(
    String couponCode,
    String userId,
    List<CartItemModel> cartItems,
    double cartSubtotal,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('coupons')
              .where('code', isEqualTo: couponCode.toUpperCase())
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Invalid coupon code');
      }

      final coupon = Coupon.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );

      // Check if coupon is valid
      if (!coupon.isValid) {
        if (coupon.isExpired) {
          throw Exception('Coupon has expired');
        }
        if (coupon.isUsageLimitReached) {
          throw Exception('Coupon usage limit reached');
        }
        if (!coupon.isActive) {
          throw Exception('Coupon is not active');
        }
        throw Exception('Coupon is not valid');
      }

      // Check minimum order amount
      if (coupon.minimumOrderAmount != null &&
          cartSubtotal < coupon.minimumOrderAmount!) {
        throw Exception(
          'Minimum order amount of ${coupon.formattedMinimumOrder} required',
        );
      }

      // Check user usage limit
      if (coupon.userUsageLimit != null) {
        final userUsageCount = await getUserCouponUsageCount(coupon.id, userId);
        if (userUsageCount >= coupon.userUsageLimit!) {
          throw Exception('You have already used this coupon');
        }
      }

      // Check first-time user restriction
      if (coupon.isFirstTimeUser) {
        final isFirstTime = await isFirstTimeUser(userId);
        if (!isFirstTime) {
          throw Exception('This coupon is only for first-time users');
        }
      }

      // Check category/product applicability
      if (!isCouponApplicableToCart(coupon, cartItems)) {
        throw Exception('Coupon is not applicable to items in your cart');
      }

      return coupon;
    } catch (e) {
      rethrow;
    }
  }

  // Calculate discount amount
  DiscountCalculation calculateDiscount(
    Coupon coupon,
    List<CartItemModel> cartItems,
    double cartSubtotal,
    double shippingFee,
  ) {
    double discountAmount = 0.0;
    String description = '';

    switch (coupon.type) {
      case CouponType.percentage:
        discountAmount = cartSubtotal * (coupon.value / 100);
        if (coupon.maximumDiscountAmount != null &&
            discountAmount > coupon.maximumDiscountAmount!) {
          discountAmount = coupon.maximumDiscountAmount!;
        }
        description = '${coupon.value.toInt()}% discount applied';
        break;

      case CouponType.fixedAmount:
        discountAmount = coupon.value;
        if (discountAmount > cartSubtotal) {
          discountAmount = cartSubtotal;
        }
        description = 'TZS ${coupon.value.toStringAsFixed(0)} discount applied';
        break;

      case CouponType.freeShipping:
        discountAmount = shippingFee;
        description = 'Free shipping applied';
        break;

      case CouponType.buyOneGetOne:
        // Simplified BOGO logic - get discount on cheapest applicable item
        final applicableItems = getApplicableItems(coupon, cartItems);
        if (applicableItems.isNotEmpty) {
          applicableItems.sort((a, b) => a.price.compareTo(b.price));
          discountAmount = applicableItems.first.price;
          description = 'Buy one get one free applied';
        }
        break;
    }

    final finalAmount = cartSubtotal - discountAmount;

    return DiscountCalculation(
      originalAmount: cartSubtotal,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      couponCode: coupon.code,
      discountType: coupon.type,
      description: description,
    );
  }

  // Apply coupon and record usage
  Future<void> applyCoupon(
    String couponId,
    String userId,
    String orderId,
    double discountAmount,
  ) async {
    try {
      final batch = _firestore.batch();

      // Record coupon usage
      final usageRef = _firestore.collection('coupon_usage').doc();
      final usage = CouponUsage(
        id: usageRef.id,
        couponId: couponId,
        userId: userId,
        orderId: orderId,
        discountAmount: discountAmount,
        usedAt: DateTime.now(),
      );
      batch.set(usageRef, usage.toMap());

      // Update coupon usage count
      final couponRef = _firestore.collection('coupons').doc(couponId);
      batch.update(couponRef, {'usageCount': FieldValue.increment(1)});

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to apply coupon: $e');
    }
  }

  // Helper methods
  Future<int> getUserCouponUsageCount(String couponId, String userId) async {
    final snapshot =
        await _firestore
            .collection('coupon_usage')
            .where('couponId', isEqualTo: couponId)
            .where('userId', isEqualTo: userId)
            .get();

    return snapshot.docs.length;
  }

  Future<bool> isFirstTimeUser(String userId) async {
    final snapshot =
        await _firestore
            .collection('orders')
            .where('customerId', isEqualTo: userId)
            .limit(1)
            .get();

    return snapshot.docs.isEmpty;
  }

  bool isCouponApplicableToCart(Coupon coupon, List<CartItemModel> cartItems) {
    // If no category/product restrictions, coupon applies to all items
    if (coupon.applicableCategories == null &&
        coupon.applicableProducts == null &&
        coupon.excludedCategories == null &&
        coupon.excludedProducts == null) {
      return true;
    }

    final applicableItems = getApplicableItems(coupon, cartItems);
    return applicableItems.isNotEmpty;
  }

  List<CartItemModel> getApplicableItems(
    Coupon coupon,
    List<CartItemModel> cartItems,
  ) {
    return cartItems.where((item) {
      // Check if item is excluded
      if (coupon.excludedProducts != null &&
          coupon.excludedProducts!.contains(item.id)) {
        return false;
      }
      if (coupon.excludedCategories != null &&
          item.category != null &&
          coupon.excludedCategories!.contains(item.category)) {
        return false;
      }

      // Check if item is included
      if (coupon.applicableProducts != null) {
        return coupon.applicableProducts!.contains(item.id);
      }
      if (coupon.applicableCategories != null && item.category != null) {
        return coupon.applicableCategories!.contains(item.category);
      }

      // If no specific inclusion rules, item is applicable
      return true;
    }).toList();
  }

  // Get popular/featured coupons
  Future<List<Coupon>> getFeaturedCoupons() async {
    try {
      final snapshot =
          await _firestore
              .collection('coupons')
              .where('isActive', isEqualTo: true)
              .where('endDate', isGreaterThan: Timestamp.now())
              .orderBy('usageCount', descending: true)
              .limit(5)
              .get();

      return snapshot.docs
          .map((doc) => Coupon.fromMap(doc.data(), doc.id))
          .where((coupon) => coupon.isValid)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured coupons: $e');
    }
  }

  // Initialize default coupons (for demo purposes)
  Future<void> initializeDefaultCoupons() async {
    try {
      final defaultCoupons = PredefinedCoupons.getDefaultCoupons();

      for (final coupon in defaultCoupons) {
        final existingCoupon =
            await _firestore.collection('coupons').doc(coupon.id).get();

        if (!existingCoupon.exists) {
          await _firestore
              .collection('coupons')
              .doc(coupon.id)
              .set(coupon.toMap());
        }
      }
    } catch (e) {
      throw Exception('Failed to initialize default coupons: $e');
    }
  }

  // Get coupons for a seller
  Future<List<Coupon>> getCouponsBySeller(String sellerId) async {
    try {
      final snapshot =
          await _firestore
              .collection('coupons')
              .where('sellerId', isEqualTo: sellerId)
              .orderBy('createdAt', descending: true)
              .get();
      return snapshot.docs
          .map((doc) => Coupon.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch seller coupons: $e');
    }
  }

  // Add a new coupon (with sellerId)
  Future<void> addCoupon(Coupon coupon) async {
    try {
      await _firestore.collection('coupons').doc(coupon.id).set(coupon.toMap());
    } catch (e) {
      throw Exception('Failed to add coupon: $e');
    }
  }
}
