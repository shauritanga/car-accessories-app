import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String id;
  final String productId;
  final String sellerId;
  final int stock;
  final DateTime lastUpdated;

  InventoryModel({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.stock,
    required this.lastUpdated,
  });

  factory InventoryModel.fromMap(Map<String, dynamic> data) {
    return InventoryModel(
      id: data['id'],
      productId: data['productId'],
      sellerId: data['sellerId'],
      stock: data['stock'],
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'sellerId': sellerId,
      'stock': stock,
      'lastUpdated': lastUpdated,
    };
  }
}
