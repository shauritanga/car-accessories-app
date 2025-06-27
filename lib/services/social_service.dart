import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social_model.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Social Sharing
  Future<void> shareProduct({
    required String productId,
    required SocialPlatform platform,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final shareUrl = await _generateShareUrl(productId);

      final share = SocialShare(
        id: '',
        userId: user.uid,
        productId: productId,
        platform: platform,
        shareUrl: shareUrl,
        message: message,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('social_shares').add(share.toMap());

      // Track analytics
      await _trackShareAnalytics(productId, platform);
    } catch (e) {
      print('Error sharing product: $e');
      rethrow;
    }
  }

  Future<String> _generateShareUrl(String productId) async {
    // Generate a shareable URL for the product
    return 'https://yourapp.com/product/$productId';
  }

  Future<void> _trackShareAnalytics(
    String productId,
    SocialPlatform platform,
  ) async {
    // Track share analytics
    await _firestore.collection('analytics').add({
      'type': 'social_share',
      'productId': productId,
      'platform': platform.toString(),
      'timestamp': Timestamp.now(),
    });
  }

  // Social Login
  Future<SocialLogin?> getSocialLogin(SocialPlatform platform) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final querySnapshot =
          await _firestore
              .collection('social_logins')
              .where('userId', isEqualTo: user.uid)
              .where('platform', isEqualTo: platform.toString())
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return SocialLogin.fromMap(
          querySnapshot.docs.first.data(),
          querySnapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting social login: $e');
      return null;
    }
  }

  Future<void> saveSocialLogin({
    required SocialPlatform platform,
    required String platformUserId,
    String? platformEmail,
    String? platformName,
    String? platformAvatar,
    Map<String, dynamic>? platformData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final socialLogin = SocialLogin(
        id: '',
        userId: user.uid,
        platform: platform,
        platformUserId: platformUserId,
        platformEmail: platformEmail,
        platformName: platformName,
        platformAvatar: platformAvatar,
        platformData: platformData ?? {},
        createdAt: DateTime.now(),
        lastUsed: DateTime.now(),
      );

      await _firestore.collection('social_logins').add(socialLogin.toMap());
    } catch (e) {
      print('Error saving social login: $e');
      rethrow;
    }
  }

  // Community Features
  Future<List<CommunityPost>> getCommunityPosts({
    String? category,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('community_posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map(
            (doc) => CommunityPost.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      print('Error getting community posts: $e');
      return [];
    }
  }

  Future<CommunityPost> createCommunityPost({
    required String title,
    required String content,
    List<String> images = const [],
    String? productId,
    String? category,
    List<String> tags = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user profile
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'Anonymous';
      final userAvatar = userData?['avatar'];

      final post = CommunityPost(
        id: '',
        userId: user.uid,
        userName: userName,
        userAvatar: userAvatar,
        title: title,
        content: content,
        images: images,
        productId: productId,
        category: category,
        tags: tags,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('community_posts')
          .add(post.toMap());

      return CommunityPost.fromMap(post.toMap(), docRef.id);
    } catch (e) {
      print('Error creating community post: $e');
      rethrow;
    }
  }

  Future<void> likeCommunityPost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final postRef = _firestore.collection('community_posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) throw Exception('Post not found');

        final postData = postDoc.data()!;
        final likedBy = List<String>.from(postData['likedBy'] ?? []);

        if (likedBy.contains(user.uid)) {
          // Unlike
          likedBy.remove(user.uid);
          transaction.update(postRef, {
            'likedBy': likedBy,
            'likeCount': FieldValue.increment(-1),
          });
        } else {
          // Like
          likedBy.add(user.uid);
          transaction.update(postRef, {
            'likedBy': likedBy,
            'likeCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      print('Error liking post: $e');
      rethrow;
    }
  }

  Future<CommunityComment> addComment({
    required String postId,
    required String content,
    List<String> images = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user profile
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'Anonymous';
      final userAvatar = userData?['avatar'];

      final comment = CommunityComment(
        id: '',
        postId: postId,
        userId: user.uid,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        images: images,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('community_comments')
          .add(comment.toMap());

      // Update post comment count
      await _firestore.collection('community_posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      return CommunityComment.fromMap(comment.toMap(), docRef.id);
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  Future<List<CommunityComment>> getPostComments(String postId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('community_comments')
              .where('postId', isEqualTo: postId)
              .orderBy('createdAt', descending: false)
              .get();

      return querySnapshot.docs
          .map((doc) => CommunityComment.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  // Influencer Features
  Future<InfluencerProfile?> getInfluencerProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection('influencer_profiles').doc(userId).get();

      if (doc.exists) {
        return InfluencerProfile.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting influencer profile: $e');
      return null;
    }
  }

  Future<InfluencerProfile> createInfluencerProfile({
    required String name,
    String? bio,
    String? avatar,
    String? coverImage,
    required InfluencerTier tier,
    required List<SocialPlatform> platforms,
    required Map<SocialPlatform, String> platformHandles,
    required Map<SocialPlatform, int> followerCounts,
    required double engagementRate,
    required List<String> categories,
    required List<String> tags,
    required double commissionRate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final profile = InfluencerProfile(
        id: '',
        userId: user.uid,
        name: name,
        bio: bio,
        avatar: avatar,
        coverImage: coverImage,
        tier: tier,
        platforms: platforms,
        platformHandles: platformHandles,
        followerCounts: followerCounts,
        engagementRate: engagementRate,
        categories: categories,
        tags: tags,
        commissionRate: commissionRate,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('influencer_profiles')
          .doc(user.uid)
          .set(profile.toMap());

      return profile;
    } catch (e) {
      print('Error creating influencer profile: $e');
      rethrow;
    }
  }

  Future<List<InfluencerProfile>> searchInfluencers({
    List<String>? categories,
    InfluencerTier? tier,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('influencer_profiles')
          .where('isActive', isEqualTo: true)
          .limit(limit);

      if (categories != null && categories.isNotEmpty) {
        query = query.where('categories', arrayContainsAny: categories);
      }

      if (tier != null) {
        query = query.where('tier', isEqualTo: tier.toString().split('.').last);
      }

      final querySnapshot = await query.get();

      var profiles =
          querySnapshot.docs
              .map(
                (doc) => InfluencerProfile.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      // Filter by tags if provided
      if (tags != null && tags.isNotEmpty) {
        profiles =
            profiles.where((profile) {
              return tags.any((tag) => profile.tags.contains(tag));
            }).toList();
      }

      return profiles;
    } catch (e) {
      print('Error searching influencers: $e');
      return [];
    }
  }

  Future<InfluencerCampaign> createInfluencerCampaign({
    required String name,
    required String description,
    required String influencerId,
    required String productId,
    required List<String> requirements,
    required double budget,
    required double commissionRate,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> deliverables,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final campaign = InfluencerCampaign(
        id: '',
        name: name,
        description: description,
        influencerId: influencerId,
        productId: productId,
        requirements: requirements,
        budget: budget,
        commissionRate: commissionRate,
        startDate: startDate,
        endDate: endDate,
        status: CampaignStatus.pending,
        deliverables: deliverables,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('influencer_campaigns')
          .add(campaign.toMap());

      return InfluencerCampaign.fromMap(campaign.toMap(), docRef.id);
    } catch (e) {
      print('Error creating influencer campaign: $e');
      rethrow;
    }
  }

  Future<List<InfluencerCampaign>> getInfluencerCampaigns({
    String? influencerId,
    CampaignStatus? status,
  }) async {
    try {
      Query query = _firestore.collection('influencer_campaigns');

      if (influencerId != null) {
        query = query.where('influencerId', isEqualTo: influencerId);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString());
      }

      final querySnapshot =
          await query.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs
          .map(
            (doc) => InfluencerCampaign.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      print('Error getting influencer campaigns: $e');
      return [];
    }
  }

  Future<void> updateCampaignStatus(
    String campaignId,
    CampaignStatus status,
  ) async {
    try {
      await _firestore
          .collection('influencer_campaigns')
          .doc(campaignId)
          .update({'status': status.toString(), 'updatedAt': Timestamp.now()});
    } catch (e) {
      print('Error updating campaign status: $e');
      rethrow;
    }
  }

  // Analytics for social features
  Future<Map<String, dynamic>> getSocialAnalytics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user's social activity
      final sharesQuery =
          await _firestore
              .collection('social_shares')
              .where('userId', isEqualTo: user.uid)
              .get();

      final postsQuery =
          await _firestore
              .collection('community_posts')
              .where('userId', isEqualTo: user.uid)
              .get();

      final commentsQuery =
          await _firestore
              .collection('community_comments')
              .where('userId', isEqualTo: user.uid)
              .get();

      return {
        'totalShares': sharesQuery.docs.length,
        'totalPosts': postsQuery.docs.length,
        'totalComments': commentsQuery.docs.length,
        'totalLikes': _calculateTotalLikes(postsQuery.docs),
        'engagementRate': _calculateEngagementRate(postsQuery.docs),
      };
    } catch (e) {
      print('Error getting social analytics: $e');
      return {};
    }
  }

  int _calculateTotalLikes(List<QueryDocumentSnapshot> posts) {
    return posts.fold<int>(0, (sum, post) {
      final data = post.data();
      if (data is Map<String, dynamic> && data['likeCount'] != null) {
        final likeCount = data['likeCount'];
        if (likeCount is int) return sum + likeCount;
        if (likeCount is double) return sum + likeCount.toInt();
      }
      return sum;
    });
  }

  double _calculateEngagementRate(List<QueryDocumentSnapshot> posts) {
    if (posts.isEmpty) return 0.0;

    final totalLikes = _calculateTotalLikes(posts);
    final totalComments = posts.fold<int>(0, (sum, post) {
      final data = post.data();
      if (data is Map<String, dynamic> && data['commentCount'] != null) {
        final commentCount = data['commentCount'];
        if (commentCount is int) return sum + commentCount;
        if (commentCount is double) return sum + commentCount.toInt();
      }
      return sum;
    });

    return posts.isEmpty ? 0.0 : (totalLikes + totalComments) / posts.length;
  }

  // Wishlist
  Future<void> addToWishlist(WishlistItem item) async {
    await _firestore.collection('wishlists').doc(item.id).set(item.toMap());
  }

  Future<void> removeFromWishlist(String wishlistItemId) async {
    await _firestore.collection('wishlists').doc(wishlistItemId).delete();
  }

  Future<List<WishlistItem>> getWishlist(String userId) async {
    final snapshot =
        await _firestore
            .collection('wishlists')
            .where('userId', isEqualTo: userId)
            .get();
    return snapshot.docs
        .map((doc) => WishlistItem.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Follows
  Future<void> follow(Follow follow) async {
    await _firestore.collection('follows').doc(follow.id).set(follow.toMap());
  }

  Future<void> unfollow(String followId) async {
    await _firestore.collection('follows').doc(followId).delete();
  }

  Future<List<Follow>> getFollows(String userId) async {
    final snapshot =
        await _firestore
            .collection('follows')
            .where('followerId', isEqualTo: userId)
            .get();
    return snapshot.docs
        .map((doc) => Follow.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Product Shares
  Future<void> shareProductDirect(ProductShare share) async {
    await _firestore
        .collection('product_shares')
        .doc(share.id)
        .set(share.toMap());
  }

  Future<List<ProductShare>> getProductShares(String productId) async {
    final snapshot =
        await _firestore
            .collection('product_shares')
            .where('productId', isEqualTo: productId)
            .get();
    return snapshot.docs
        .map((doc) => ProductShare.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Activity Feed
  Future<void> addActivity(ActivityFeedItem activity) async {
    await _firestore
        .collection('activity_feed')
        .doc(activity.id)
        .set(activity.toMap());
  }

  Future<List<ActivityFeedItem>> getUserActivityFeed(String userId) async {
    final snapshot =
        await _firestore
            .collection('activity_feed')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
    return snapshot.docs
        .map((doc) => ActivityFeedItem.fromMap(doc.data(), doc.id))
        .toList();
  }
}
