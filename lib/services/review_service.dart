import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Add a new review
  Future<void> addReview(ReviewModel review) async {
    try {
      await _firestore.collection('reviews').doc(review.id).set(review.toMap());
      
      // Update product rating summary
      await _updateProductRatingSummary(review.productId);
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Update an existing review
  Future<void> updateReview(ReviewModel review) async {
    try {
      await _firestore.collection('reviews').doc(review.id).update(
        review.copyWith(updatedAt: DateTime.now()).toMap(),
      );
      
      // Update product rating summary
      await _updateProductRatingSummary(review.productId);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId, String productId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      
      // Update product rating summary
      await _updateProductRatingSummary(productId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Get reviews for a product
  Stream<List<ReviewModel>> getProductReviews(String productId, {
    int? limit,
    String? orderBy = 'createdAt',
    bool descending = true,
  }) {
    Query query = _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Get reviews by a specific user
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Check if user has already reviewed a product
  Future<ReviewModel?> getUserReviewForProduct(String userId, String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return ReviewModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user review: $e');
    }
  }

  // Upload review images
  Future<List<String>> uploadReviewImages(List<File> images, String reviewId) async {
    try {
      final List<String> imageUrls = [];
      
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = '${reviewId}_$i.jpg';
        final ref = _storage.ref().child('reviews').child(fileName);
        
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        imageUrls.add(downloadUrl);
      }
      
      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload review images: $e');
    }
  }

  // Mark review as helpful
  Future<void> markReviewHelpful(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'helpfulCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to mark review as helpful: $e');
    }
  }

  // Get review summary for a product
  Future<ReviewSummary> getProductReviewSummary(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();

      return ReviewSummary.fromReviews(reviews);
    } catch (e) {
      throw Exception('Failed to get review summary: $e');
    }
  }

  // Update product rating summary in products collection
  Future<void> _updateProductRatingSummary(String productId) async {
    try {
      final summary = await getProductReviewSummary(productId);
      
      await _firestore.collection('products').doc(productId).update({
        'averageRating': summary.averageRating,
        'totalReviews': summary.totalReviews,
        'ratingDistribution': summary.ratingDistribution,
      });
    } catch (e) {
      // Don't throw error here as it's a background operation
      print('Failed to update product rating summary: $e');
    }
  }

  // Check if user can review product (has purchased it)
  Future<bool> canUserReviewProduct(String userId, String productId) async {
    try {
      // Check if user has purchased this product
      final orderQuery = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: userId)
          .where('status', whereIn: ['delivered', 'completed'])
          .get();

      for (final orderDoc in orderQuery.docs) {
        final orderData = orderDoc.data();
        final items = orderData['items'] as List<dynamic>? ?? [];
        
        for (final item in items) {
          if (item['productId'] == productId) {
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      throw Exception('Failed to check review eligibility: $e');
    }
  }

  // Get filtered reviews
  Stream<List<ReviewModel>> getFilteredReviews(
    String productId, {
    int? starFilter,
    bool? verifiedOnly,
    bool? withImagesOnly,
    String? sortBy = 'newest',
  }) {
    Query query = _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId);

    // Apply star filter
    if (starFilter != null) {
      query = query.where('rating', isEqualTo: starFilter.toDouble());
    }

    // Apply verified purchase filter
    if (verifiedOnly == true) {
      query = query.where('isVerifiedPurchase', isEqualTo: true);
    }

    // Apply images filter
    if (withImagesOnly == true) {
      query = query.where('images', isNotEqualTo: []);
    }

    // Apply sorting
    switch (sortBy) {
      case 'newest':
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'oldest':
        query = query.orderBy('createdAt', descending: false);
        break;
      case 'highest_rating':
        query = query.orderBy('rating', descending: true);
        break;
      case 'lowest_rating':
        query = query.orderBy('rating', descending: false);
        break;
      case 'most_helpful':
        query = query.orderBy('helpfulCount', descending: true);
        break;
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }
}
