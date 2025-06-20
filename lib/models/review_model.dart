import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String title;
  final String comment;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int helpfulCount;
  final bool isVerifiedPurchase;
  final String? orderId;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userAvatar = '',
    required this.rating,
    required this.title,
    required this.comment,
    this.images = const [],
    required this.createdAt,
    this.updatedAt,
    this.helpfulCount = 0,
    this.isVerifiedPurchase = false,
    this.orderId,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> data, String id) {
    return ReviewModel(
      id: id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userAvatar: data['userAvatar'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      title: data['title'] ?? '',
      comment: data['comment'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      helpfulCount: data['helpfulCount'] ?? 0,
      isVerifiedPurchase: data['isVerifiedPurchase'] ?? false,
      orderId: data['orderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'helpfulCount': helpfulCount,
      'isVerifiedPurchase': isVerifiedPurchase,
      'orderId': orderId,
    };
  }

  ReviewModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? userAvatar,
    double? rating,
    String? title,
    String? comment,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? helpfulCount,
    bool? isVerifiedPurchase,
    String? orderId,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      orderId: orderId ?? this.orderId,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class ReviewSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // star -> count
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  factory ReviewSummary.fromReviews(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return ReviewSummary(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        fiveStarCount: 0,
        fourStarCount: 0,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
      );
    }

    final totalRating = reviews.fold(0.0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / reviews.length;

    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in reviews) {
      final starRating = review.rating.round();
      distribution[starRating] = (distribution[starRating] ?? 0) + 1;
    }

    return ReviewSummary(
      averageRating: averageRating,
      totalReviews: reviews.length,
      ratingDistribution: distribution,
      fiveStarCount: distribution[5] ?? 0,
      fourStarCount: distribution[4] ?? 0,
      threeStarCount: distribution[3] ?? 0,
      twoStarCount: distribution[2] ?? 0,
      oneStarCount: distribution[1] ?? 0,
    );
  }

  double getPercentageForRating(int rating) {
    if (totalReviews == 0) return 0.0;
    return (ratingDistribution[rating] ?? 0) / totalReviews * 100;
  }
}
