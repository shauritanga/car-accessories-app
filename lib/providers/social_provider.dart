import 'package:flutter/foundation.dart';
import '../models/social_model.dart';
import '../services/social_service.dart';

class SocialProvider with ChangeNotifier {
  final SocialService _socialService = SocialService();

  List<WishlistItem> _wishlist = [];
  List<Follow> _follows = [];
  List<ActivityFeedItem> _activityFeed = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<WishlistItem> get wishlist => _wishlist;
  List<Follow> get follows => _follows;
  List<ActivityFeedItem> get activityFeed => _activityFeed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Wishlist operations
  Future<void> loadWishlist(String userId) async {
    _setLoading(true);
    try {
      _wishlist = await _socialService.getWishlist(userId);
      _clearError();
    } catch (e) {
      _setError('Failed to load wishlist: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addToWishlist(String userId, String productId) async {
    try {
      final item = WishlistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        productId: productId,
        addedAt: DateTime.now(),
      );
      await _socialService.addToWishlist(item);
      _wishlist.add(item);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add to wishlist: $e');
    }
  }

  Future<void> removeFromWishlist(String wishlistItemId) async {
    try {
      await _socialService.removeFromWishlist(wishlistItemId);
      _wishlist.removeWhere((item) => item.id == wishlistItemId);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove from wishlist: $e');
    }
  }

  bool isInWishlist(String productId) {
    return _wishlist.any((item) => item.productId == productId);
  }

  // Follow operations
  Future<void> loadFollows(String userId) async {
    _setLoading(true);
    try {
      _follows = await _socialService.getFollows(userId);
      _clearError();
    } catch (e) {
      _setError('Failed to load follows: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> followUser(
    String followerId,
    String followingId,
    String type,
  ) async {
    try {
      final follow = Follow(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        followerId: followerId,
        followingId: followingId,
        type: type,
        followedAt: DateTime.now(),
      );
      await _socialService.follow(follow);
      _follows.add(follow);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to follow user: $e');
    }
  }

  Future<void> unfollowUser(String followId) async {
    try {
      await _socialService.unfollow(followId);
      _follows.removeWhere((follow) => follow.id == followId);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to unfollow user: $e');
    }
  }

  bool isFollowing(String followingId) {
    return _follows.any((follow) => follow.followingId == followingId);
  }

  // Activity feed operations
  Future<void> loadActivityFeed(String userId) async {
    _setLoading(true);
    try {
      _activityFeed = await _socialService.getUserActivityFeed(userId);
      _clearError();
    } catch (e) {
      _setError('Failed to load activity feed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addActivity(
    String userId,
    String type, {
    String? targetId,
    String? targetType,
    String? description,
  }) async {
    try {
      final activity = ActivityFeedItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: type,
        targetId: targetId,
        targetType: targetType,
        description: description,
        createdAt: DateTime.now(),
      );
      await _socialService.addActivity(activity);
      _activityFeed.insert(0, activity);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add activity: $e');
    }
  }

  // Product share operations
  Future<void> shareProduct(
    String userId,
    String productId,
    String platform,
  ) async {
    try {
      final share = ProductShare(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        productId: productId,
        platform: platform,
        sharedAt: DateTime.now(),
      );
      final platformEnum = SocialPlatform.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            platform.toLowerCase(),
        orElse: () => SocialPlatform.facebook,
      );
      await _socialService.shareProduct(
        productId: productId,
        platform: platformEnum,
      );
      _clearError();
    } catch (e) {
      _setError('Failed to share product: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
