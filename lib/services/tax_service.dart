import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tax_model.dart';
import '../models/cart_item_model.dart';

class TaxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate tax for cart items
  Future<TaxCalculation> calculateTax({
    required List<CartItemModel> cartItems,
    required double subtotal,
    required String country,
    String? state,
    String? city,
  }) async {
    try {
      // Get applicable tax rates
      final taxRates = await getApplicableTaxRates(
        country: country,
        state: state,
        city: city,
      );

      // Get product categories from cart items
      final productCategories = cartItems
          .where((item) => item.category != null)
          .map((item) => item.category!)
          .toSet()
          .toList();

      // Calculate tax using the service
      return TaxCalculationService.calculateTax(
        subtotal: subtotal,
        applicableTaxRates: taxRates,
        country: country,
        state: state,
        city: city,
        productCategories: productCategories,
      );
    } catch (e) {
      throw Exception('Failed to calculate tax: $e');
    }
  }

  // Get applicable tax rates for a location
  Future<List<TaxRate>> getApplicableTaxRates({
    required String country,
    String? state,
    String? city,
  }) async {
    try {
      Query query = _firestore
          .collection('tax_rates')
          .where('country', isEqualTo: country)
          .where('isActive', isEqualTo: true)
          .where('effectiveDate', isLessThanOrEqualTo: Timestamp.now());

      // Add expiry date filter
      query = query.where('expiryDate', isGreaterThan: Timestamp.now());

      final snapshot = await query.get();
      
      final taxRates = snapshot.docs
          .map((doc) => TaxRate.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((rate) => rate.isValid)
          .toList();

      // Filter by state and city if provided
      return taxRates.where((rate) {
        if (rate.state != null && state != null && rate.state != state) {
          return false;
        }
        if (rate.city != null && city != null && rate.city != city) {
          return false;
        }
        return true;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch tax rates: $e');
    }
  }

  // Calculate VAT specifically (common in Tanzania)
  double calculateVAT(double amount, {double rate = 18.0}) {
    return TaxCalculationService.calculateVAT(amount, rate: rate);
  }

  // Calculate total with VAT
  double calculateTotalWithVAT(double amount, {double rate = 18.0}) {
    return TaxCalculationService.calculateTotalWithVAT(amount, rate: rate);
  }

  // Extract VAT from total amount
  double extractVATFromTotal(double totalWithVAT, {double rate = 18.0}) {
    return TaxCalculationService.extractVATFromTotal(totalWithVAT, rate: rate);
  }

  // Get amount excluding VAT
  double getAmountExcludingVAT(double totalWithVAT, {double rate = 18.0}) {
    return TaxCalculationService.getAmountExcludingVAT(totalWithVAT, rate: rate);
  }

  // Calculate tax for specific product categories
  Future<double> calculateCategoryTax({
    required String category,
    required double amount,
    required String country,
    String? state,
    String? city,
  }) async {
    try {
      final taxRates = await getApplicableTaxRates(
        country: country,
        state: state,
        city: city,
      );

      double totalTax = 0.0;

      for (final rate in taxRates) {
        // Check if tax rate applies to this category
        bool isApplicable = true;
        
        if (rate.applicableCategories != null) {
          isApplicable = rate.applicableCategories!.contains(category);
        }
        
        if (rate.exemptCategories != null && rate.exemptCategories!.contains(category)) {
          isApplicable = false;
        }

        if (isApplicable) {
          totalTax += rate.calculateTax(amount);
        }
      }

      return totalTax;
    } catch (e) {
      throw Exception('Failed to calculate category tax: $e');
    }
  }

  // Check if product category is tax exempt
  Future<bool> isCategoryTaxExempt({
    required String category,
    required String country,
    String? state,
    String? city,
  }) async {
    try {
      final taxRates = await getApplicableTaxRates(
        country: country,
        state: state,
        city: city,
      );

      // Check if any tax rate explicitly exempts this category
      for (final rate in taxRates) {
        if (rate.exemptCategories != null && rate.exemptCategories!.contains(category)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false; // Default to not exempt if error occurs
    }
  }

  // Get tax breakdown for display
  Future<List<TaxBreakdown>> getTaxBreakdown({
    required List<CartItemModel> cartItems,
    required double subtotal,
    required String country,
    String? state,
    String? city,
  }) async {
    try {
      final calculation = await calculateTax(
        cartItems: cartItems,
        subtotal: subtotal,
        country: country,
        state: state,
        city: city,
      );

      return calculation.taxes;
    } catch (e) {
      throw Exception('Failed to get tax breakdown: $e');
    }
  }

  // Create tax record for order
  Future<void> createTaxRecord({
    required String orderId,
    required String customerId,
    required TaxCalculation taxCalculation,
    required String country,
    String? state,
    String? city,
  }) async {
    try {
      final taxRecordId = _firestore.collection('tax_records').doc().id;
      
      final taxRecord = {
        'id': taxRecordId,
        'orderId': orderId,
        'customerId': customerId,
        'country': country,
        'state': state,
        'city': city,
        'subtotal': taxCalculation.subtotal,
        'totalTax': taxCalculation.totalTax,
        'totalWithTax': taxCalculation.totalWithTax,
        'effectiveTaxRate': taxCalculation.effectiveTaxRate,
        'taxes': taxCalculation.taxes.map((tax) => {
          'taxId': tax.taxId,
          'taxName': tax.taxName,
          'taxType': tax.taxType.toString(),
          'rate': tax.rate,
          'taxableAmount': tax.taxableAmount,
          'taxAmount': tax.taxAmount,
        }).toList(),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore
          .collection('tax_records')
          .doc(taxRecordId)
          .set(taxRecord);
    } catch (e) {
      throw Exception('Failed to create tax record: $e');
    }
  }

  // Get tax record by order ID
  Future<Map<String, dynamic>?> getTaxRecordByOrderId(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('tax_records')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first.data();
    } catch (e) {
      throw Exception('Failed to fetch tax record: $e');
    }
  }

  // Initialize default tax rates for Tanzania
  Future<void> initializeDefaultTaxRates() async {
    try {
      final defaultRates = TanzaniaTaxRates.getDefaultTaxRates();
      
      for (final rate in defaultRates) {
        final existingRate = await _firestore
            .collection('tax_rates')
            .doc(rate.id)
            .get();
            
        if (!existingRate.exists) {
          await _firestore
              .collection('tax_rates')
              .doc(rate.id)
              .set(rate.toMap());
        }
      }
    } catch (e) {
      throw Exception('Failed to initialize default tax rates: $e');
    }
  }

  // Update tax rate
  Future<void> updateTaxRate(TaxRate taxRate) async {
    try {
      await _firestore
          .collection('tax_rates')
          .doc(taxRate.id)
          .update(taxRate.toMap());
    } catch (e) {
      throw Exception('Failed to update tax rate: $e');
    }
  }

  // Deactivate tax rate
  Future<void> deactivateTaxRate(String taxRateId) async {
    try {
      await _firestore
          .collection('tax_rates')
          .doc(taxRateId)
          .update({
            'isActive': false,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Failed to deactivate tax rate: $e');
    }
  }

  // Get tax summary for reporting
  Future<Map<String, dynamic>> getTaxSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? country,
  }) async {
    try {
      Query query = _firestore
          .collection('tax_records')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (country != null) {
        query = query.where('country', isEqualTo: country);
      }

      final snapshot = await query.get();
      
      double totalTaxCollected = 0.0;
      double totalTaxableAmount = 0.0;
      int totalOrders = snapshot.docs.length;
      
      final taxTypeBreakdown = <String, double>{};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalTaxCollected += (data['totalTax'] as num).toDouble();
        totalTaxableAmount += (data['subtotal'] as num).toDouble();

        // Process tax breakdown
        final taxes = data['taxes'] as List<dynamic>;
        for (final tax in taxes) {
          final taxType = tax['taxType'] as String;
          final taxAmount = (tax['taxAmount'] as num).toDouble();
          taxTypeBreakdown[taxType] = (taxTypeBreakdown[taxType] ?? 0.0) + taxAmount;
        }
      }

      return {
        'totalTaxCollected': totalTaxCollected,
        'totalTaxableAmount': totalTaxableAmount,
        'totalOrders': totalOrders,
        'averageTaxRate': totalTaxableAmount > 0 
            ? (totalTaxCollected / totalTaxableAmount) * 100 
            : 0.0,
        'taxTypeBreakdown': taxTypeBreakdown,
        'period': {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      };
    } catch (e) {
      throw Exception('Failed to get tax summary: $e');
    }
  }
}
