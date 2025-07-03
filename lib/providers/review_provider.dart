import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewState {
  final List<ReviewModel> reviews;
  final ReviewSummary? summary;
  final bool isLoading;
  final String? error;
  final Map<String, bool> helpfulMarked;

  ReviewState({
    this.reviews = const [],
    this.summary,
    this.isLoading = false,
    this.error,
    this.helpfulMarked = const {},
  });

  ReviewState copyWith({
    List<ReviewModel>? reviews,
    ReviewSummary? summary,
    bool? isLoading,
    String? error,
    Map<String, bool>? helpfulMarked,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      helpfulMarked: helpfulMarked ?? this.helpfulMarked,
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  final ReviewService _reviewService = ReviewService();

  ReviewNotifier() : super(ReviewState());

  Future<void> addReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String title,
    required String comment,
    List<File>? images,
    String? orderId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final reviewId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload images if provided
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        imageUrls = await _reviewService.uploadReviewImages(images, reviewId);
      }

      final review = ReviewModel(
        id: reviewId,
        productId: productId,
        userId: userId,
        userName: userName,
        rating: rating,
        title: title,
        comment: comment,
        images: imageUrls,
        createdAt: DateTime.now(),
        isVerifiedPurchase: orderId != null,
        orderId: orderId,
      );

      await _reviewService.addReview(review);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateReview(ReviewModel review) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _reviewService.updateReview(review);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteReview(String reviewId, String productId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _reviewService.deleteReview(reviewId, productId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> markReviewHelpful(String reviewId) async {
    try {
      await _reviewService.markReviewHelpful(reviewId);

      // Update local state to show the review was marked as helpful
      final updatedHelpfulMarked = Map<String, bool>.from(state.helpfulMarked);
      updatedHelpfulMarked[reviewId] = true;
      state = state.copyWith(helpfulMarked: updatedHelpfulMarked);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> canUserReviewProduct(String userId, String productId) async {
    try {
      return await _reviewService.canUserReviewProduct(userId, productId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<ReviewModel?> getUserReviewForProduct(
    String userId,
    String productId,
  ) async {
    try {
      return await _reviewService.getUserReviewForProduct(userId, productId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> flagReview(String reviewId, String productId) async {
    try {
      await _reviewService.flagReview(reviewId, productId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final reviewProvider = StateNotifierProvider<ReviewNotifier, ReviewState>((
  ref,
) {
  return ReviewNotifier();
});

// Stream provider for product reviews
final productReviewsStreamProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, productId) {
      final reviewService = ReviewService();
      return reviewService.getProductReviews(productId);
    });

// Stream provider for filtered product reviews
final filteredProductReviewsStreamProvider =
    StreamProvider.family<List<ReviewModel>, ReviewFilter>((ref, filter) {
      final reviewService = ReviewService();
      return reviewService.getFilteredReviews(
        filter.productId,
        starFilter: filter.starFilter,
        verifiedOnly: filter.verifiedOnly,
        withImagesOnly: filter.withImagesOnly,
        sortBy: filter.sortBy,
      );
    });

// Stream provider for user reviews
final userReviewsStreamProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, userId) {
      final reviewService = ReviewService();
      return reviewService.getUserReviews(userId);
    });

// Future provider for review summary
final reviewSummaryProvider = FutureProvider.family<ReviewSummary, String>((
  ref,
  productId,
) {
  final reviewService = ReviewService();
  return reviewService.getProductReviewSummary(productId);
});

// Provider to get all reviews for a seller's products
final reviewsBySellerProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, sellerId) async {
      // TODO: Implement getReviewsBySeller in ReviewService
      final reviewService = ReviewService();
      return await reviewService.getReviewsBySeller(sellerId);
    });

// Review filter class
class ReviewFilter {
  final String productId;
  final int? starFilter;
  final bool? verifiedOnly;
  final bool? withImagesOnly;
  final String? sortBy;

  ReviewFilter({
    required this.productId,
    this.starFilter,
    this.verifiedOnly,
    this.withImagesOnly,
    this.sortBy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewFilter &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          starFilter == other.starFilter &&
          verifiedOnly == other.verifiedOnly &&
          withImagesOnly == other.withImagesOnly &&
          sortBy == other.sortBy;

  @override
  int get hashCode =>
      productId.hashCode ^
      starFilter.hashCode ^
      verifiedOnly.hashCode ^
      withImagesOnly.hashCode ^
      sortBy.hashCode;
}
