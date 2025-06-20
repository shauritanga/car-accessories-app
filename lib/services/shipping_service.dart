import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shipping_model.dart';
import '../models/cart_item_model.dart';

class ShippingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get available shipping methods
  Future<List<ShippingMethod>> getAvailableShippingMethods({
    String? city,
    String? state,
    double? totalWeight,
    double? totalValue,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('shipping_methods')
              .where('isAvailable', isEqualTo: true)
              .get();

      final methods =
          snapshot.docs
              .map((doc) => ShippingMethod.fromMap(doc.data(), doc.id))
              .where(
                (method) => _isMethodAvailable(
                  method,
                  city,
                  state,
                  totalWeight,
                  totalValue,
                ),
              )
              .toList();

      // Sort by cost (cheapest first)
      methods.sort((a, b) => a.cost.compareTo(b.cost));

      return methods;
    } catch (e) {
      throw Exception('Failed to fetch shipping methods: $e');
    }
  }

  // Calculate shipping cost based on cart items
  Future<double> calculateShippingCost(
    String shippingMethodId,
    List<CartItemModel> cartItems,
    String destinationCity,
    String destinationState,
  ) async {
    try {
      final methodDoc =
          await _firestore
              .collection('shipping_methods')
              .doc(shippingMethodId)
              .get();

      if (!methodDoc.exists) {
        throw Exception('Shipping method not found');
      }

      final method = ShippingMethod.fromMap(methodDoc.data()!, methodDoc.id);

      // Calculate total weight
      final totalWeight = cartItems.fold<double>(
        0.0,
        (total, item) => total + ((item.weight ?? 1.0) * item.quantity),
      );

      // Base cost
      double cost = method.cost;

      // Add weight-based charges if applicable
      if (totalWeight > 5.0) {
        // Over 5kg
        cost += (totalWeight - 5.0) * 1000; // TZS 1,000 per additional kg
      }

      // Add distance-based charges for certain cities
      if (_isRemoteLocation(destinationCity, destinationState)) {
        cost += 2000; // Additional TZS 2,000 for remote locations
      }

      return cost;
    } catch (e) {
      throw Exception('Failed to calculate shipping cost: $e');
    }
  }

  // Create shipping tracking
  Future<ShippingTracking> createShippingTracking({
    required String orderId,
    required String shippingMethodId,
    required String carrier,
  }) async {
    try {
      final trackingNumber = _generateTrackingNumber();
      final trackingId = _firestore.collection('shipping_tracking').doc().id;

      final tracking = ShippingTracking(
        id: trackingId,
        orderId: orderId,
        trackingNumber: trackingNumber,
        carrier: carrier,
        status: ShippingStatus.pending,
        events: [
          TrackingEvent(
            status: 'Order Placed',
            description: 'Your order has been placed and is being processed',
            timestamp: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('shipping_tracking')
          .doc(trackingId)
          .set(tracking.toMap());

      return tracking;
    } catch (e) {
      throw Exception('Failed to create shipping tracking: $e');
    }
  }

  // Update shipping status
  Future<void> updateShippingStatus(
    String trackingId,
    ShippingStatus status,
    String description, {
    String? location,
  }) async {
    try {
      final trackingRef = _firestore
          .collection('shipping_tracking')
          .doc(trackingId);
      final trackingDoc = await trackingRef.get();

      if (!trackingDoc.exists) {
        throw Exception('Tracking not found');
      }

      final tracking = ShippingTracking.fromMap(
        trackingDoc.data()!,
        trackingDoc.id,
      );

      final newEvent = TrackingEvent(
        status: status.toString().split('.').last,
        description: description,
        location: location,
        timestamp: DateTime.now(),
      );

      final updatedEvents = [...tracking.events, newEvent];

      await trackingRef.update({
        'status': status.toString(),
        'events': updatedEvents.map((e) => e.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        if (status == ShippingStatus.delivered)
          'actualDelivery': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update shipping status: $e');
    }
  }

  // Get shipping tracking by order ID
  Future<ShippingTracking?> getShippingTrackingByOrderId(String orderId) async {
    try {
      final snapshot =
          await _firestore
              .collection('shipping_tracking')
              .where('orderId', isEqualTo: orderId)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return ShippingTracking.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('Failed to fetch shipping tracking: $e');
    }
  }

  // Get shipping tracking by tracking number
  Future<ShippingTracking?> getShippingTrackingByNumber(
    String trackingNumber,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('shipping_tracking')
              .where('trackingNumber', isEqualTo: trackingNumber)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return ShippingTracking.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('Failed to fetch shipping tracking: $e');
    }
  }

  // Estimate delivery date
  DateTime estimateDeliveryDate(ShippingMethod method, String destinationCity) {
    int additionalDays = 0;

    // Add extra days for remote locations
    if (_isRemoteLocation(destinationCity, '')) {
      additionalDays += 2;
    }

    return DateTime.now().add(
      Duration(days: method.estimatedDaysMax + additionalDays),
    );
  }

  // Helper methods
  bool _isMethodAvailable(
    ShippingMethod method,
    String? city,
    String? state,
    double? totalWeight,
    double? totalValue,
  ) {
    if (!method.isAvailable) return false;

    // Check weight restrictions
    if (method.restrictions != null) {
      final maxWeight = method.restrictions!['maxWeight'] as double?;
      if (maxWeight != null && totalWeight != null && totalWeight > maxWeight) {
        return false;
      }

      final maxValue = method.restrictions!['maxValue'] as double?;
      if (maxValue != null && totalValue != null && totalValue > maxValue) {
        return false;
      }

      // Check location restrictions
      final excludedCities =
          method.restrictions!['excludedCities'] as List<String>?;
      if (excludedCities != null &&
          city != null &&
          excludedCities.contains(city)) {
        return false;
      }
    }

    return true;
  }

  bool _isRemoteLocation(String city, String state) {
    final remoteCities = [
      'Mtwara',
      'Lindi',
      'Ruvuma',
      'Njombe',
      'Songwe',
      'Katavi',
      'Rukwa',
      'Kigoma',
      'Geita',
      'Simiyu',
    ];

    return remoteCities.any(
      (remote) =>
          city.toLowerCase().contains(remote.toLowerCase()) ||
          state.toLowerCase().contains(remote.toLowerCase()),
    );
  }

  String _generateTrackingNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode % 10000).toString().padLeft(4, '0');
    return 'CAR${timestamp.substring(timestamp.length - 6)}$random';
  }

  // Initialize default shipping methods
  Future<void> initializeDefaultShippingMethods() async {
    try {
      final defaultMethods = _getDefaultShippingMethods();

      for (final method in defaultMethods) {
        final existingMethod =
            await _firestore
                .collection('shipping_methods')
                .doc(method.id)
                .get();

        if (!existingMethod.exists) {
          await _firestore
              .collection('shipping_methods')
              .doc(method.id)
              .set(method.toMap());
        }
      }
    } catch (e) {
      throw Exception('Failed to initialize default shipping methods: $e');
    }
  }

  List<ShippingMethod> _getDefaultShippingMethods() {
    return [
      ShippingMethod(
        id: 'standard',
        name: 'Standard Delivery',
        description: 'Regular delivery within 3-5 business days',
        type: ShippingType.standard,
        cost: 5000,
        estimatedDaysMin: 3,
        estimatedDaysMax: 5,
        trackingProvider: 'Tanzania Post',
        icon: 'truck',
      ),
      ShippingMethod(
        id: 'express',
        name: 'Express Delivery',
        description: 'Fast delivery within 1-2 business days',
        type: ShippingType.express,
        cost: 10000,
        estimatedDaysMin: 1,
        estimatedDaysMax: 2,
        trackingProvider: 'DHL Tanzania',
        icon: 'flash',
      ),
      ShippingMethod(
        id: 'same_day',
        name: 'Same Day Delivery',
        description: 'Delivery within the same day (Dar es Salaam only)',
        type: ShippingType.sameDay,
        cost: 15000,
        estimatedDaysMin: 0,
        estimatedDaysMax: 1,
        restrictions: {
          'includedCities': ['Dar es Salaam'],
          'maxWeight': 10.0,
        },
        trackingProvider: 'Local Courier',
        icon: 'today',
      ),
      ShippingMethod(
        id: 'pickup',
        name: 'Store Pickup',
        description: 'Pick up from our store location',
        type: ShippingType.pickup,
        cost: 0,
        estimatedDaysMin: 1,
        estimatedDaysMax: 1,
        trackingProvider: 'Store',
        icon: 'store',
      ),
    ];
  }
}
