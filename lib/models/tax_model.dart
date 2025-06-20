import 'package:cloud_firestore/cloud_firestore.dart';

enum TaxType {
  vat, // Value Added Tax
  gst, // Goods and Services Tax
  salesTax,
  importDuty,
  exciseTax,
}

class TaxRate {
  final String id;
  final String name;
  final String description;
  final TaxType type;
  final double rate; // Percentage
  final String country;
  final String? state;
  final String? city;
  final List<String>? applicableCategories;
  final List<String>? exemptCategories;
  final double? minimumAmount;
  final double? maximumAmount;
  final bool isActive;
  final DateTime effectiveDate;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TaxRate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rate,
    required this.country,
    this.state,
    this.city,
    this.applicableCategories,
    this.exemptCategories,
    this.minimumAmount,
    this.maximumAmount,
    this.isActive = true,
    required this.effectiveDate,
    this.expiryDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory TaxRate.fromMap(Map<String, dynamic> data, String id) {
    return TaxRate(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: TaxType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => TaxType.vat,
      ),
      rate: (data['rate'] as num?)?.toDouble() ?? 0.0,
      country: data['country'] ?? '',
      state: data['state'],
      city: data['city'],
      applicableCategories: data['applicableCategories']?.cast<String>(),
      exemptCategories: data['exemptCategories']?.cast<String>(),
      minimumAmount: (data['minimumAmount'] as num?)?.toDouble(),
      maximumAmount: (data['maximumAmount'] as num?)?.toDouble(),
      isActive: data['isActive'] ?? true,
      effectiveDate: (data['effectiveDate'] as Timestamp).toDate(),
      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.toString(),
      'rate': rate,
      'country': country,
      'state': state,
      'city': city,
      'applicableCategories': applicableCategories,
      'exemptCategories': exemptCategories,
      'minimumAmount': minimumAmount,
      'maximumAmount': maximumAmount,
      'isActive': isActive,
      'effectiveDate': Timestamp.fromDate(effectiveDate),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isEffective => DateTime.now().isAfter(effectiveDate);
  bool get isValid => isActive && isEffective && !isExpired;

  String get formattedRate => '${rate.toStringAsFixed(1)}%';

  double calculateTax(double amount) {
    if (!isValid) return 0.0;
    if (minimumAmount != null && amount < minimumAmount!) return 0.0;
    
    double taxAmount = amount * (rate / 100);
    
    if (maximumAmount != null && taxAmount > maximumAmount!) {
      taxAmount = maximumAmount!;
    }
    
    return taxAmount;
  }
}

class TaxCalculation {
  final double subtotal;
  final List<TaxBreakdown> taxes;
  final double totalTax;
  final double totalWithTax;

  TaxCalculation({
    required this.subtotal,
    required this.taxes,
    required this.totalTax,
    required this.totalWithTax,
  });

  bool get hasTax => totalTax > 0;

  double get effectiveTaxRate {
    if (subtotal == 0) return 0;
    return (totalTax / subtotal) * 100;
  }

  String get formattedTotalTax => 'TZS ${totalTax.toStringAsFixed(0)}';
  String get formattedTotal => 'TZS ${totalWithTax.toStringAsFixed(0)}';
}

class TaxBreakdown {
  final String taxId;
  final String taxName;
  final TaxType taxType;
  final double rate;
  final double taxableAmount;
  final double taxAmount;

  TaxBreakdown({
    required this.taxId,
    required this.taxName,
    required this.taxType,
    required this.rate,
    required this.taxableAmount,
    required this.taxAmount,
  });

  String get formattedRate => '${rate.toStringAsFixed(1)}%';
  String get formattedAmount => 'TZS ${taxAmount.toStringAsFixed(0)}';
}

// Tanzania-specific tax rates
class TanzaniaTaxRates {
  static List<TaxRate> getDefaultTaxRates() {
    final now = DateTime.now();

    return [
      // VAT for Tanzania
      TaxRate(
        id: 'tz_vat_18',
        name: 'Tanzania VAT',
        description: 'Value Added Tax for Tanzania',
        type: TaxType.vat,
        rate: 18.0,
        country: 'Tanzania',
        effectiveDate: DateTime(2020, 1, 1),
        createdAt: now,
      ),
      
      // Service Tax
      TaxRate(
        id: 'tz_service_tax',
        name: 'Service Tax',
        description: 'Tax on services in Tanzania',
        type: TaxType.salesTax,
        rate: 5.0,
        country: 'Tanzania',
        applicableCategories: ['services', 'installation', 'maintenance'],
        effectiveDate: DateTime(2020, 1, 1),
        createdAt: now,
      ),
      
      // Import Duty (for imported car parts)
      TaxRate(
        id: 'tz_import_duty',
        name: 'Import Duty',
        description: 'Import duty on car accessories',
        type: TaxType.importDuty,
        rate: 25.0,
        country: 'Tanzania',
        applicableCategories: ['imported_parts'],
        effectiveDate: DateTime(2020, 1, 1),
        createdAt: now,
      ),
    ];
  }
}

// Tax calculation service
class TaxCalculationService {
  static TaxCalculation calculateTax({
    required double subtotal,
    required List<TaxRate> applicableTaxRates,
    required String country,
    String? state,
    String? city,
    List<String>? productCategories,
  }) {
    final List<TaxBreakdown> taxes = [];
    double totalTax = 0.0;

    for (final taxRate in applicableTaxRates) {
      // Check if tax rate is applicable
      if (!taxRate.isValid) continue;
      if (taxRate.country != country) continue;
      if (taxRate.state != null && taxRate.state != state) continue;
      if (taxRate.city != null && taxRate.city != city) continue;

      // Check category applicability
      bool isApplicable = true;
      if (taxRate.applicableCategories != null && productCategories != null) {
        isApplicable = taxRate.applicableCategories!
            .any((category) => productCategories.contains(category));
      }
      if (taxRate.exemptCategories != null && productCategories != null) {
        final isExempt = taxRate.exemptCategories!
            .any((category) => productCategories.contains(category));
        if (isExempt) isApplicable = false;
      }

      if (!isApplicable) continue;

      // Calculate tax
      final taxAmount = taxRate.calculateTax(subtotal);
      if (taxAmount > 0) {
        taxes.add(TaxBreakdown(
          taxId: taxRate.id,
          taxName: taxRate.name,
          taxType: taxRate.type,
          rate: taxRate.rate,
          taxableAmount: subtotal,
          taxAmount: taxAmount,
        ));
        totalTax += taxAmount;
      }
    }

    return TaxCalculation(
      subtotal: subtotal,
      taxes: taxes,
      totalTax: totalTax,
      totalWithTax: subtotal + totalTax,
    );
  }

  static double calculateVAT(double amount, {double rate = 18.0}) {
    return amount * (rate / 100);
  }

  static double calculateTotalWithVAT(double amount, {double rate = 18.0}) {
    return amount + calculateVAT(amount, rate: rate);
  }

  static double extractVATFromTotal(double totalWithVAT, {double rate = 18.0}) {
    return totalWithVAT * (rate / (100 + rate));
  }

  static double getAmountExcludingVAT(double totalWithVAT, {double rate = 18.0}) {
    return totalWithVAT - extractVATFromTotal(totalWithVAT, rate: rate);
  }
}
