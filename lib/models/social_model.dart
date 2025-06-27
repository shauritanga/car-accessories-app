import 'package:cloud_firestore/cloud_firestore.dart';

enum SocialPlatform {
  facebook,
  twitter,
  instagram,
  whatsapp,
  telegram,
  email,
  sms,
  copyLink,
}

enum SocialActionType {
  share,
  like,
  comment,
  follow,
  mention,
  tag,
}

enum InfluencerTier {
  nano,
  micro,
  macro,
  mega,
  celebrity,
}

class SocialShare {
  final String id;
  final String userId;
  final String? productId;
  final String? orderId;
  final SocialPlatform platform;
  final String shareUrl;
  final String? message;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final int? viewCount;
  final int? clickCount;
  final int? conversionCount;

  SocialShare({
    required this.id,
    required this.userId,
    this.productId,
    this.orderId,
    required this.platform,
    required this.shareUrl,
    this.message,
    this.metadata = const {},
    required this.timestamp,
    this.viewCount,
    this.clickCount,
    this.conversionCount,
  });

  factory SocialShare.fromMap(Map<String, dynamic> data, String id) {
    return SocialShare(
      id: id,
      userId: data['userId'] ?? '',
      productId: data['productId'],
      orderId: data['orderId'],
      platform: SocialPlatform.values.firstWhere(
        (e) => e.toString() == data['platform'],
        orElse: () => SocialPlatform.facebook,
      ),
      shareUrl: data['shareUrl'] ?? '',
      message: data['message'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      viewCount: data['viewCount'],
      clickCount: data['clickCount'],
      conversionCount: data['conversionCount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'orderId': orderId,
      'platform': platform.toString(),
      'shareUrl': shareUrl,
      'message': message,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
      'viewCount': viewCount,
      'clickCount': clickCount,
      'conversionCount': conversionCount,
    };
  }
}

class SocialLogin {
  final String id;
  final String userId;
  final SocialPlatform platform;
  final String platformUserId;
  final String? platformEmail;
  final String? platformName;
  final String? platformAvatar;
  final Map<String, dynamic> platformData;
  final DateTime createdAt;
  final DateTime? lastUsed;

  SocialLogin({
    required this.id,
    required this.userId,
    required this.platform,
    required this.platformUserId,
    this.platformEmail,
    this.platformName,
    this.platformAvatar,
    this.platformData = const {},
    required this.createdAt,
    this.lastUsed,
  });

  factory SocialLogin.fromMap(Map<String, dynamic> data, String id) {
    return SocialLogin(
      id: id,
      userId: data['userId'] ?? '',
      platform: SocialPlatform.values.firstWhere(
        (e) => e.toString() == data['platform'],
        orElse: () => SocialPlatform.facebook,
      ),
      platformUserId: data['platformUserId'] ?? '',
      platformEmail: data['platformEmail'],
      platformName: data['platformName'],
      platformAvatar: data['platformAvatar'],
      platformData: Map<String, dynamic>.from(data['platformData'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUsed: data['lastUsed'] != null
          ? (data['lastUsed'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'platform': platform.toString(),
      'platformUserId': platformUserId,
      'platformEmail': platformEmail,
      'platformName': platformName,
      'platformAvatar': platformAvatar,
      'platformData': platformData,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
    };
  }
}

class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String title;
  final String content;
  final List<String> images;
  final String? productId;
  final String? category;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final List<String> likedBy;
  final bool isVerified;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.title,
    required this.content,
    this.images = const [],
    this.productId,
    this.category,
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.likedBy = const [],
    this.isVerified = false,
    this.isPinned = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommunityPost.fromMap(Map<String, dynamic> data, String id) {
    return CommunityPost(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'],
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      productId: data['productId'],
      category: data['category'],
      tags: List<String>.from(data['tags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      shareCount: data['shareCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isVerified: data['isVerified'] ?? false,
      isPinned: data['isPinned'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'title': title,
      'content': content,
      'images': images,
      'productId': productId,
      'category': category,
      'tags': tags,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'likedBy': likedBy,
      'isVerified': isVerified,
      'isPinned': isPinned,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool get isLikedByUser => likedBy.isNotEmpty;
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class CommunityComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final List<String> images;
  final int likeCount;
  final List<String> likedBy;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommunityComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.images = const [],
    this.likeCount = 0,
    this.likedBy = const [],
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommunityComment.fromMap(Map<String, dynamic> data, String id) {
    return CommunityComment(
      id: id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'],
      content: data['content'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'images': images,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class InfluencerProfile {
  final String id;
  final String userId;
  final String name;
  final String? bio;
  final String? avatar;
  final String? coverImage;
  final InfluencerTier tier;
  final List<SocialPlatform> platforms;
  final Map<SocialPlatform, String> platformHandles;
  final Map<SocialPlatform, int> followerCounts;
  final double engagementRate;
  final List<String> categories;
  final List<String> tags;
  final bool isVerified;
  final bool isActive;
  final double commissionRate;
  final List<String> completedCampaigns;
  final double totalEarnings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  InfluencerProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.bio,
    this.avatar,
    this.coverImage,
    required this.tier,
    required this.platforms,
    required this.platformHandles,
    required this.followerCounts,
    required this.engagementRate,
    required this.categories,
    required this.tags,
    this.isVerified = false,
    this.isActive = true,
    required this.commissionRate,
    this.completedCampaigns = const [],
    this.totalEarnings = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory InfluencerProfile.fromMap(Map<String, dynamic> data, String id) {
    final platformsList = (data['platforms'] as List<dynamic>?)
            ?.map((e) => SocialPlatform.values.firstWhere(
                  (p) => p.toString() == e,
                  orElse: () => SocialPlatform.facebook,
                ))
            .toList() ??
        [];

    final platformHandlesMap = <SocialPlatform, String>{};
    final handlesData = data['platformHandles'] as Map<String, dynamic>? ?? {};
    for (final entry in handlesData.entries) {
      final platform = SocialPlatform.values.firstWhere(
        (p) => p.toString() == entry.key,
        orElse: () => SocialPlatform.facebook,
      );
      platformHandlesMap[platform] = entry.value;
    }

    final followerCountsMap = <SocialPlatform, int>{};
    final followersData = data['followerCounts'] as Map<String, dynamic>? ?? {};
    for (final entry in followersData.entries) {
      final platform = SocialPlatform.values.firstWhere(
        (p) => p.toString() == entry.key,
        orElse: () => SocialPlatform.facebook,
      );
      followerCountsMap[platform] = entry.value;
    }

    return InfluencerProfile(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      bio: data['bio'],
      avatar: data['avatar'],
      coverImage: data['coverImage'],
      tier: InfluencerTier.values.firstWhere(
        (e) => e.toString() == data['tier'],
        orElse: () => InfluencerTier.nano,
      ),
      platforms: platformsList,
      platformHandles: platformHandlesMap,
      followerCounts: followerCountsMap,
      engagementRate: (data['engagementRate'] as num?)?.toDouble() ?? 0.0,
      categories: List<String>.from(data['categories'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      commissionRate: (data['commissionRate'] as num?)?.toDouble() ?? 0.0,
      completedCampaigns: List<String>.from(data['completedCampaigns'] ?? []),
      totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final platformHandlesMap = <String, String>{};
    for (final entry in platformHandles.entries) {
      platformHandlesMap[entry.key.toString()] = entry.value;
    }

    final followerCountsMap = <String, int>{};
    for (final entry in followerCounts.entries) {
      followerCountsMap[entry.key.toString()] = entry.value;
    }

    return {
      'userId': userId,
      'name': name,
      'bio': bio,
      'avatar': avatar,
      'coverImage': coverImage,
      'tier': tier.toString(),
      'platforms': platforms.map((e) => e.toString()).toList(),
      'platformHandles': platformHandlesMap,
      'followerCounts': followerCountsMap,
      'engagementRate': engagementRate,
      'categories': categories,
      'tags': tags,
      'isVerified': isVerified,
      'isActive': isActive,
      'commissionRate': commissionRate,
      'completedCampaigns': completedCampaigns,
      'totalEarnings': totalEarnings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  int get totalFollowers {
    return followerCounts.values.fold(0, (sum, count) => sum + count);
  }

  String get tierDisplayName {
    switch (tier) {
      case InfluencerTier.nano:
        return 'Nano Influencer (1K-10K)';
      case InfluencerTier.micro:
        return 'Micro Influencer (10K-50K)';
      case InfluencerTier.macro:
        return 'Macro Influencer (50K-500K)';
      case InfluencerTier.mega:
        return 'Mega Influencer (500K-1M)';
      case InfluencerTier.celebrity:
        return 'Celebrity (1M+)';
    }
  }
}

class InfluencerCampaign {
  final String id;
  final String name;
  final String description;
  final String influencerId;
  final String productId;
  final List<String> requirements;
  final double budget;
  final double commissionRate;
  final DateTime startDate;
  final DateTime endDate;
  final CampaignStatus status;
  final List<String> deliverables;
  final Map<String, dynamic> metrics;
  final DateTime createdAt;
  final DateTime? updatedAt;

  InfluencerCampaign({
    required this.id,
    required this.name,
    required this.description,
    required this.influencerId,
    required this.productId,
    required this.requirements,
    required this.budget,
    required this.commissionRate,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.deliverables,
    this.metrics = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory InfluencerCampaign.fromMap(Map<String, dynamic> data, String id) {
    return InfluencerCampaign(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      influencerId: data['influencerId'] ?? '',
      productId: data['productId'] ?? '',
      requirements: List<String>.from(data['requirements'] ?? []),
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      commissionRate: (data['commissionRate'] as num?)?.toDouble() ?? 0.0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: CampaignStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => CampaignStatus.pending,
      ),
      deliverables: List<String>.from(data['deliverables'] ?? []),
      metrics: Map<String, dynamic>.from(data['metrics'] ?? {}),
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
      'influencerId': influencerId,
      'productId': productId,
      'requirements': requirements,
      'budget': budget,
      'commissionRate': commissionRate,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.toString(),
      'deliverables': deliverables,
      'metrics': metrics,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

enum CampaignStatus {
  pending,
  active,
  completed,
  cancelled,
  failed,
}

class WishlistItem {
  final String id;
  final String userId;
  final String productId;
  final DateTime addedAt;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.addedAt,
  });

  factory WishlistItem.fromMap(Map<String, dynamic> data, String docId) {
    return WishlistItem(
      id: docId,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}

class Follow {
  final String id;
  final String followerId;
  final String followingId;
  final String type; // 'user', 'seller', 'brand'
  final DateTime followedAt;

  Follow({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.type,
    required this.followedAt,
  });

  factory Follow.fromMap(Map<String, dynamic> data, String docId) {
    return Follow(
      id: docId,
      followerId: data['followerId'] ?? '',
      followingId: data['followingId'] ?? '',
      type: data['type'] ?? 'user',
      followedAt: (data['followedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'type': type,
      'followedAt': Timestamp.fromDate(followedAt),
    };
  }
}

class ProductShare {
  final String id;
  final String userId;
  final String productId;
  final String platform; // 'facebook', 'twitter', 'whatsapp', etc.
  final DateTime sharedAt;

  ProductShare({
    required this.id,
    required this.userId,
    required this.productId,
    required this.platform,
    required this.sharedAt,
  });

  factory ProductShare.fromMap(Map<String, dynamic> data, String docId) {
    return ProductShare(
      id: docId,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      platform: data['platform'] ?? '',
      sharedAt: (data['sharedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'platform': platform,
      'sharedAt': Timestamp.fromDate(sharedAt),
    };
  }
}

class ActivityFeedItem {
  final String id;
  final String userId;
  final String type; // 'wishlist', 'follow', 'share', 'review', 'purchase', etc.
  final String? targetId;
  final String? targetType; // 'product', 'user', 'order', etc.
  final String? description;
  final DateTime createdAt;

  ActivityFeedItem({
    required this.id,
    required this.userId,
    required this.type,
    this.targetId,
    this.targetType,
    this.description,
    required this.createdAt,
  });

  factory ActivityFeedItem.fromMap(Map<String, dynamic> data, String docId) {
    return ActivityFeedItem(
      id: docId,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      targetId: data['targetId'],
      targetType: data['targetType'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'targetId': targetId,
      'targetType': targetType,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
