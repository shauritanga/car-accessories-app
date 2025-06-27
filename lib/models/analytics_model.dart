import 'package:cloud_firestore/cloud_firestore.dart';

// Customer segment enum
enum CustomerSegment {
  newCustomer,
  returning,
  loyal,
  atRisk,
  churned,
  highValue,
  lowValue,
}

// Customer behavior model
class CustomerBehavior {
  final String userId;
  final CustomerSegment segment;
  final int totalSessions;
  final int totalPageViews;
  final int totalProductViews;
  final int totalAddToCart;
  final int totalPurchases;
  final double averageSessionDuration;
  final double averageOrderValue;
  final double lifetimeValue;
  final int daysSinceLastPurchase;
  final double churnProbability;
  final List<String> favoriteCategories;
  final List<String> favoriteProducts;
  final Map<String, int> categoryPreferences;
  final Map<String, int> productPreferences;

  CustomerBehavior({
    required this.userId,
    required this.segment,
    required this.totalSessions,
    required this.totalPageViews,
    required this.totalProductViews,
    required this.totalAddToCart,
    required this.totalPurchases,
    required this.averageSessionDuration,
    required this.averageOrderValue,
    required this.lifetimeValue,
    required this.daysSinceLastPurchase,
    required this.churnProbability,
    required this.favoriteCategories,
    required this.favoriteProducts,
    required this.categoryPreferences,
    required this.productPreferences,
  });

  factory CustomerBehavior.fromMap(Map<String, dynamic> data) {
    return CustomerBehavior(
      userId: data['userId'] ?? '',
      segment: CustomerSegment.values.firstWhere(
        (e) => e.toString().split('.').last == data['segment'],
        orElse: () => CustomerSegment.newCustomer,
      ),
      totalSessions: data['totalSessions'] ?? 0,
      totalPageViews: data['totalPageViews'] ?? 0,
      totalProductViews: data['totalProductViews'] ?? 0,
      totalAddToCart: data['totalAddToCart'] ?? 0,
      totalPurchases: data['totalPurchases'] ?? 0,
      averageSessionDuration: (data['averageSessionDuration'] as num?)?.toDouble() ?? 0.0,
      averageOrderValue: (data['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      lifetimeValue: (data['lifetimeValue'] as num?)?.toDouble() ?? 0.0,
      daysSinceLastPurchase: data['daysSinceLastPurchase'] ?? 0,
      churnProbability: (data['churnProbability'] as num?)?.toDouble() ?? 0.0,
      favoriteCategories: List<String>.from(data['favoriteCategories'] ?? []),
      favoriteProducts: List<String>.from(data['favoriteProducts'] ?? []),
      categoryPreferences: Map<String, int>.from(data['categoryPreferences'] ?? {}),
      productPreferences: Map<String, int>.from(data['productPreferences'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'segment': segment.toString().split('.').last,
      'totalSessions': totalSessions,
      'totalPageViews': totalPageViews,
      'totalProductViews': totalProductViews,
      'totalAddToCart': totalAddToCart,
      'totalPurchases': totalPurchases,
      'averageSessionDuration': averageSessionDuration,
      'averageOrderValue': averageOrderValue,
      'lifetimeValue': lifetimeValue,
      'daysSinceLastPurchase': daysSinceLastPurchase,
      'churnProbability': churnProbability,
      'favoriteCategories': favoriteCategories,
      'favoriteProducts': favoriteProducts,
      'categoryPreferences': categoryPreferences,
      'productPreferences': productPreferences,
    };
  }
}

// Sales forecast model
class SalesForecast {
  final String id;
  final DateTime date;
  final double predictedRevenue;
  final int predictedUnits;
  final double confidence;
  final String? productId;
  final String? category;
  final String? description;

  SalesForecast({
    required this.id,
    required this.date,
    required this.predictedRevenue,
    required this.predictedUnits,
    required this.confidence,
    this.productId,
    this.category,
    this.description,
  });

  factory SalesForecast.fromMap(Map<String, dynamic> data, String docId) {
    return SalesForecast(
      id: docId,
      date: (data['date'] as Timestamp).toDate(),
      predictedRevenue: (data['predictedRevenue'] as num?)?.toDouble() ?? 0.0,
      predictedUnits: data['predictedUnits'] ?? 0,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      productId: data['productId'],
      category: data['category'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'predictedRevenue': predictedRevenue,
      'predictedUnits': predictedUnits,
      'confidence': confidence,
      'productId': productId,
      'category': category,
      'description': description,
    };
  }
}

// Inventory optimization model
class InventoryOptimization {
  final String id;
  final String productId;
  final String productName;
  final int currentStock;
  final int optimalStock;
  final double stockoutRisk;
  final double overstockRisk;
  final List<String> recommendations;
  final DateTime createdAt;

  InventoryOptimization({
    required this.id,
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.optimalStock,
    required this.stockoutRisk,
    required this.overstockRisk,
    required this.recommendations,
    required this.createdAt,
  });

  factory InventoryOptimization.fromMap(Map<String, dynamic> data, String docId) {
    return InventoryOptimization(
      id: docId,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      currentStock: data['currentStock'] ?? 0,
      optimalStock: data['optimalStock'] ?? 0,
      stockoutRisk: (data['stockoutRisk'] as num?)?.toDouble() ?? 0.0,
      overstockRisk: (data['overstockRisk'] as num?)?.toDouble() ?? 0.0,
      recommendations: List<String>.from(data['recommendations'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'currentStock': currentStock,
      'optimalStock': optimalStock,
      'stockoutRisk': stockoutRisk,
      'overstockRisk': overstockRisk,
      'recommendations': recommendations,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// Performance metrics model (enhanced version)
class PerformanceMetrics {
  final String id;
  final DateTime date;
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final double conversionRate;
  final double cartAbandonmentRate;
  final double customerSatisfactionScore;
  final int activeUsers;
  final int newUsers;
  final double retentionRate;
  final double churnRate;
  final Map<String, double> categoryPerformance;
  final Map<String, double> productPerformance;
  final double appLoadTime;
  final double searchResponseTime;
  final int errorCount;
  final double uptimePercentage;

  PerformanceMetrics({
    required this.id,
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.conversionRate,
    required this.cartAbandonmentRate,
    required this.customerSatisfactionScore,
    required this.activeUsers,
    required this.newUsers,
    required this.retentionRate,
    required this.churnRate,
    required this.categoryPerformance,
    required this.productPerformance,
    required this.appLoadTime,
    required this.searchResponseTime,
    required this.errorCount,
    required this.uptimePercentage,
  });

  factory PerformanceMetrics.fromMap(Map<String, dynamic> data, String docId) {
    return PerformanceMetrics(
      id: docId,
      date: (data['date'] as Timestamp).toDate(),
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: data['totalOrders'] ?? 0,
      averageOrderValue: (data['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      conversionRate: (data['conversionRate'] as num?)?.toDouble() ?? 0.0,
      cartAbandonmentRate: (data['cartAbandonmentRate'] as num?)?.toDouble() ?? 0.0,
      customerSatisfactionScore: (data['customerSatisfactionScore'] as num?)?.toDouble() ?? 0.0,
      activeUsers: data['activeUsers'] ?? 0,
      newUsers: data['newUsers'] ?? 0,
      retentionRate: (data['retentionRate'] as num?)?.toDouble() ?? 0.0,
      churnRate: (data['churnRate'] as num?)?.toDouble() ?? 0.0,
      categoryPerformance: Map<String, double>.from(data['categoryPerformance'] ?? {}),
      productPerformance: Map<String, double>.from(data['productPerformance'] ?? {}),
      appLoadTime: (data['appLoadTime'] as num?)?.toDouble() ?? 0.0,
      searchResponseTime: (data['searchResponseTime'] as num?)?.toDouble() ?? 0.0,
      errorCount: data['errorCount'] ?? 0,
      uptimePercentage: (data['uptimePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'averageOrderValue': averageOrderValue,
      'conversionRate': conversionRate,
      'cartAbandonmentRate': cartAbandonmentRate,
      'customerSatisfactionScore': customerSatisfactionScore,
      'activeUsers': activeUsers,
      'newUsers': newUsers,
      'retentionRate': retentionRate,
      'churnRate': churnRate,
      'categoryPerformance': categoryPerformance,
      'productPerformance': productPerformance,
      'appLoadTime': appLoadTime,
      'searchResponseTime': searchResponseTime,
      'errorCount': errorCount,
      'uptimePercentage': uptimePercentage,
    };
  }
}

class SalesAnalytics {
  final String id;
  final DateTime date;
  final double totalRevenue;
  final int totalOrders;
  final int totalItems;
  final double averageOrderValue;
  final Map<String, double> revenueByCategory;
  final Map<String, int> ordersByCategory;
  final Map<String, double> revenueBySeller;
  final Map<String, int> ordersBySeller;
  final List<String> topProducts;
  final List<String> topCategories;
  final double refundAmount;
  final int refundCount;
  final double discountAmount;
  final int discountCount;

  SalesAnalytics({
    required this.id,
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalItems,
    required this.averageOrderValue,
    required this.revenueByCategory,
    required this.ordersByCategory,
    required this.revenueBySeller,
    required this.ordersBySeller,
    required this.topProducts,
    required this.topCategories,
    required this.refundAmount,
    required this.refundCount,
    required this.discountAmount,
    required this.discountCount,
  });

  factory SalesAnalytics.fromMap(Map<String, dynamic> data, String docId) {
    return SalesAnalytics(
      id: docId,
      date: (data['date'] as Timestamp).toDate(),
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: data['totalOrders'] ?? 0,
      totalItems: data['totalItems'] ?? 0,
      averageOrderValue: (data['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      revenueByCategory: Map<String, double>.from(data['revenueByCategory'] ?? {}),
      ordersByCategory: Map<String, int>.from(data['ordersByCategory'] ?? {}),
      revenueBySeller: Map<String, double>.from(data['revenueBySeller'] ?? {}),
      ordersBySeller: Map<String, int>.from(data['ordersBySeller'] ?? {}),
      topProducts: List<String>.from(data['topProducts'] ?? []),
      topCategories: List<String>.from(data['topCategories'] ?? []),
      refundAmount: (data['refundAmount'] as num?)?.toDouble() ?? 0.0,
      refundCount: data['refundCount'] ?? 0,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      discountCount: data['discountCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'totalItems': totalItems,
      'averageOrderValue': averageOrderValue,
      'revenueByCategory': revenueByCategory,
      'ordersByCategory': ordersByCategory,
      'revenueBySeller': revenueBySeller,
      'ordersBySeller': ordersBySeller,
      'topProducts': topProducts,
      'topCategories': topCategories,
      'refundAmount': refundAmount,
      'refundCount': refundCount,
      'discountAmount': discountAmount,
      'discountCount': discountCount,
    };
  }
}

class UserBehaviorAnalytics {
  final String id;
  final DateTime date;
  final int totalUsers;
  final int newUsers;
  final int activeUsers;
  final int returningUsers;
  final double averageSessionDuration;
  final int totalSessions;
  final Map<String, int> pageViews;
  final Map<String, int> userActions;
  final List<String> mostViewedProducts;
  final List<String> mostSearchedTerms;
  final Map<String, double> conversionRates;
  final double cartAbandonmentRate;
  final double checkoutCompletionRate;

  UserBehaviorAnalytics({
    required this.id,
    required this.date,
    required this.totalUsers,
    required this.newUsers,
    required this.activeUsers,
    required this.returningUsers,
    required this.averageSessionDuration,
    required this.totalSessions,
    required this.pageViews,
    required this.userActions,
    required this.mostViewedProducts,
    required this.mostSearchedTerms,
    required this.conversionRates,
    required this.cartAbandonmentRate,
    required this.checkoutCompletionRate,
  });

  factory UserBehaviorAnalytics.fromMap(Map<String, dynamic> data, String docId) {
    return UserBehaviorAnalytics(
      id: docId,
      date: (data['date'] as Timestamp).toDate(),
      totalUsers: data['totalUsers'] ?? 0,
      newUsers: data['newUsers'] ?? 0,
      activeUsers: data['activeUsers'] ?? 0,
      returningUsers: data['returningUsers'] ?? 0,
      averageSessionDuration: (data['averageSessionDuration'] as num?)?.toDouble() ?? 0.0,
      totalSessions: data['totalSessions'] ?? 0,
      pageViews: Map<String, int>.from(data['pageViews'] ?? {}),
      userActions: Map<String, int>.from(data['userActions'] ?? {}),
      mostViewedProducts: List<String>.from(data['mostViewedProducts'] ?? []),
      mostSearchedTerms: List<String>.from(data['mostSearchedTerms'] ?? []),
      conversionRates: Map<String, double>.from(data['conversionRates'] ?? {}),
      cartAbandonmentRate: (data['cartAbandonmentRate'] as num?)?.toDouble() ?? 0.0,
      checkoutCompletionRate: (data['checkoutCompletionRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'totalUsers': totalUsers,
      'newUsers': newUsers,
      'activeUsers': activeUsers,
      'returningUsers': returningUsers,
      'averageSessionDuration': averageSessionDuration,
      'totalSessions': totalSessions,
      'pageViews': pageViews,
      'userActions': userActions,
      'mostViewedProducts': mostViewedProducts,
      'mostSearchedTerms': mostSearchedTerms,
      'conversionRates': conversionRates,
      'cartAbandonmentRate': cartAbandonmentRate,
      'checkoutCompletionRate': checkoutCompletionRate,
    };
  }
}

class ProductAnalytics {
  final String id;
  final String productId;
  final DateTime date;
  final int views;
  final int clicks;
  final int addToCart;
  final int purchases;
  final double revenue;
  final double conversionRate;
  final double clickThroughRate;
  final int reviews;
  final double averageRating;
  final int wishlistAdds;
  final int shares;
  final Map<String, int> viewsBySource;
  final Map<String, int> salesByRegion;

  ProductAnalytics({
    required this.id,
    required this.productId,
    required this.date,
    required this.views,
    required this.clicks,
    required this.addToCart,
    required this.purchases,
    required this.revenue,
    required this.conversionRate,
    required this.clickThroughRate,
    required this.reviews,
    required this.averageRating,
    required this.wishlistAdds,
    required this.shares,
    required this.viewsBySource,
    required this.salesByRegion,
  });

  factory ProductAnalytics.fromMap(Map<String, dynamic> data, String docId) {
    return ProductAnalytics(
      id: docId,
      productId: data['productId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      views: data['views'] ?? 0,
      clicks: data['clicks'] ?? 0,
      addToCart: data['addToCart'] ?? 0,
      purchases: data['purchases'] ?? 0,
      revenue: (data['revenue'] as num?)?.toDouble() ?? 0.0,
      conversionRate: (data['conversionRate'] as num?)?.toDouble() ?? 0.0,
      clickThroughRate: (data['clickThroughRate'] as num?)?.toDouble() ?? 0.0,
      reviews: data['reviews'] ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      wishlistAdds: data['wishlistAdds'] ?? 0,
      shares: data['shares'] ?? 0,
      viewsBySource: Map<String, int>.from(data['viewsBySource'] ?? {}),
      salesByRegion: Map<String, int>.from(data['salesByRegion'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'date': Timestamp.fromDate(date),
      'views': views,
      'clicks': clicks,
      'addToCart': addToCart,
      'purchases': purchases,
      'revenue': revenue,
      'conversionRate': conversionRate,
      'clickThroughRate': clickThroughRate,
      'reviews': reviews,
      'averageRating': averageRating,
      'wishlistAdds': wishlistAdds,
      'shares': shares,
      'viewsBySource': viewsBySource,
      'salesByRegion': salesByRegion,
    };
  }
}

class InventoryAnalytics {
  final String id;
  final DateTime date;
  final int totalProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double totalInventoryValue;
  final Map<String, int> productsByCategory;
  final Map<String, double> inventoryValueByCategory;
  final List<String> topSellingProducts;
  final List<String> slowMovingProducts;
  final double inventoryTurnoverRate;
  final int daysOfInventory;

  InventoryAnalytics({
    required this.id,
    required this.date,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.totalInventoryValue,
    required this.productsByCategory,
    required this.inventoryValueByCategory,
    required this.topSellingProducts,
    required this.slowMovingProducts,
    required this.inventoryTurnoverRate,
    required this.daysOfInventory,
  });

  factory InventoryAnalytics.fromMap(Map<String, dynamic> data, String docId) {
    return InventoryAnalytics(
      id: docId,
      date: (data['date'] as Timestamp).toDate(),
      totalProducts: data['totalProducts'] ?? 0,
      lowStockProducts: data['lowStockProducts'] ?? 0,
      outOfStockProducts: data['outOfStockProducts'] ?? 0,
      totalInventoryValue: (data['totalInventoryValue'] as num?)?.toDouble() ?? 0.0,
      productsByCategory: Map<String, int>.from(data['productsByCategory'] ?? {}),
      inventoryValueByCategory: Map<String, double>.from(data['inventoryValueByCategory'] ?? {}),
      topSellingProducts: List<String>.from(data['topSellingProducts'] ?? []),
      slowMovingProducts: List<String>.from(data['slowMovingProducts'] ?? []),
      inventoryTurnoverRate: (data['inventoryTurnoverRate'] as num?)?.toDouble() ?? 0.0,
      daysOfInventory: data['daysOfInventory'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'totalProducts': totalProducts,
      'lowStockProducts': lowStockProducts,
      'outOfStockProducts': outOfStockProducts,
      'totalInventoryValue': totalInventoryValue,
      'productsByCategory': productsByCategory,
      'inventoryValueByCategory': inventoryValueByCategory,
      'topSellingProducts': topSellingProducts,
      'slowMovingProducts': slowMovingProducts,
      'inventoryTurnoverRate': inventoryTurnoverRate,
      'daysOfInventory': daysOfInventory,
    };
  }
} 