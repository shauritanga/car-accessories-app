import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import 'dart:io';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addProduct(ProductModel product, List<XFile> images) async {
    try {
      List<String> imageUrls = [];
      for (var image in images) {
        String fileName =
            'product_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child(fileName);
        await ref.putFile(File(image.path));
        String url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Create a new product with the image URLs
      product = ProductModel(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        category: product.category,
        compatibility: product.compatibility,
        sellerId: product.sellerId,
        stock: product.stock,
        images: imageUrls,
        rating: product.rating,
      );

      // Add the product to Firestore
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(product.toMap());
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Stream<List<ProductModel>> getProducts({
    String? query,
    String? category,
    String? model,
  }) {
    Query queryRef = _firestore.collection('products');
    if (category != null) {
      queryRef = queryRef.where('category', isEqualTo: category);
    }
    if (model != null) {
      queryRef = queryRef.where('compatibility', arrayContains: model);
    }
    return queryRef.snapshots().map((snapshot) {
      List<ProductModel> products = [];
      for (var doc in snapshot.docs) {
        try {
          final product = ProductModel.fromMap({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          });

          if (query == null ||
              product.name.toLowerCase().contains(query.toLowerCase())) {
            products.add(product);
          }
        } catch (e) {
          // Continue processing other documents
        }
      }
      return products;
    });
  }

  Future<ProductModel> getProduct(String id) async {
    DocumentSnapshot doc =
        await _firestore.collection('products').doc(id).get();
    return ProductModel.fromMap({
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    });
  }
}
