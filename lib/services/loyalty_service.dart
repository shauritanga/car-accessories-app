import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/loyalty_model.dart';

class LoyaltyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's loyalty account
  Future<UserLoyaltyAccount?> getUserLoyaltyAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc =
          await _firestore.collection('loyalty_accounts').doc(user.uid).get();

      if (doc.exists) {
        return UserLoyaltyAccount.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting loyalty account: $e');
      return null;
    }
  }

  // Create or update loyalty account
  Future<UserLoyaltyAccount> createLoyaltyAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final accountData = {
        'userId': user.uid,
        'currentTier': LoyaltyTier.bronze.toString().split('.').last,
        'currentPoints': 0,
        'lifetimePoints': 0,
        'totalSpent': 0.0,
        'pointsToNextTier': 1000, // Points needed for next tier
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await _firestore
          .collection('loyalty_accounts')
          .doc(user.uid)
          .set(accountData);

      return UserLoyaltyAccount.fromMap(accountData, user.uid);
    } catch (e) {
      debugPrint('Error creating loyalty account: $e');
      rethrow;
    }
  }

  // Get loyalty program configuration
  Future<LoyaltyProgram?> getLoyaltyProgram() async {
    try {
      final doc = await _firestore.collection('loyalty_programs').doc('default').get();
      
      if (doc.exists) {
        return LoyaltyProgram.fromMap(doc.data()!, doc.id);
      }
      
      // Return default program if none exists
      return LoyaltyProgram(
        id: 'default',
        name: 'Car Accessories Loyalty Program',
        description: 'Earn points on every purchase and unlock exclusive rewards',
        pointsPerCurrency: 1.0, // 1 point per 1 TZS
        currencyPerPoint: 0.01, // 1 point = 0.01 TZS
        pointsExpiryDays: 365,
        minimumSpendForPoints: 1000.0, // Minimum 1000 TZS to earn points
        tiers: LoyaltyTier.values.toList(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error getting loyalty program: $e');
      return null;
    }
  }

  // Earn points from purchase
  Future<void> earnPointsFromPurchase({
    required String orderId,
    required double orderAmount,
    required double pointsPerCurrency,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final pointsEarned = (orderAmount * pointsPerCurrency).round();

      // Get current account
      final account = await getUserLoyaltyAccount();
      if (account == null) {
        await createLoyaltyAccount();
      }

      // Update points
      await _firestore.collection('loyalty_accounts').doc(user.uid).update({
        'currentPoints': FieldValue.increment(pointsEarned),
        'lifetimePoints': FieldValue.increment(pointsEarned),
        'totalSpent': FieldValue.increment(orderAmount),
        'updatedAt': Timestamp.now(),
      });

      // Create transaction record
      final transaction = LoyaltyTransaction(
        id: '',
        userId: user.uid,
        type: TransactionType.earned,
        points: pointsEarned,
        description: 'Points earned from purchase #$orderId',
        orderId: orderId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('loyalty_transactions')
          .add(transaction.toMap());

      // Check for tier upgrade
      await _checkAndUpdateTier(user.uid);
    } catch (e) {
      debugPrint('Error earning points: $e');
      rethrow;
    }
  }

  // Redeem points for rewards
  Future<bool> redeemPoints({
    required String rewardId,
    required int pointsCost,
    required String rewardName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final account = await getUserLoyaltyAccount();
      if (account == null) throw Exception('Loyalty account not found');

      if (account.currentPoints < pointsCost) {
        throw Exception('Insufficient points');
      }

      // Update points
      await _firestore.collection('loyalty_accounts').doc(user.uid).update({
        'currentPoints': FieldValue.increment(-pointsCost),
        'updatedAt': Timestamp.now(),
      });

      // Create transaction record
      final transaction = LoyaltyTransaction(
        id: '',
        userId: user.uid,
        type: TransactionType.redeemed,
        points: -pointsCost,
        description: 'Points redeemed for $rewardName',
        rewardId: rewardId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('loyalty_transactions')
          .add(transaction.toMap());

      return true;
    } catch (e) {
      debugPrint('Error redeeming points: $e');
      return false;
    }
  }

  // Get available rewards
  Future<List<LoyaltyReward>> getAvailableRewards() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('loyalty_rewards')
              .where('isActive', isEqualTo: true)
              .get();

      return querySnapshot.docs
          .map((doc) => LoyaltyReward.fromMap(doc.data(), doc.id))
          .where((reward) => reward.isAvailable)
          .toList();
    } catch (e) {
      debugPrint('Error getting rewards: $e');
      return [];
    }
  }

  // Get user's transaction history
  Future<List<LoyaltyTransaction>> getTransactionHistory({
    int limit = 20,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot =
          await _firestore
              .collection('loyalty_transactions')
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => LoyaltyTransaction.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting transaction history: $e');
      return [];
    }
  }

  // Get tier benefits
  Map<String, dynamic> getTierBenefits(LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.bronze:
        return {
          'name': 'Bronze',
          'discount': 0.05, // 5% discount
          'benefits': [
            '5% discount on all purchases',
            'Standard shipping',
            'Email support',
          ],
          'color': 0xFFCD7F32,
          'icon': '🥉',
        };
      case LoyaltyTier.silver:
        return {
          'name': 'Silver',
          'discount': 0.10, // 10% discount
          'benefits': [
            '10% discount on all purchases',
            'Free shipping on orders over 50,000 TZS',
            'Priority email support',
            'Exclusive monthly offers',
          ],
          'color': 0xFFC0C0C0,
          'icon': '🥈',
        };
      case LoyaltyTier.gold:
        return {
          'name': 'Gold',
          'discount': 0.15, // 15% discount
          'benefits': [
            '15% discount on all purchases',
            'Free shipping on all orders',
            'Priority phone support',
            'Exclusive monthly offers',
            'Early access to sales',
          ],
          'color': 0xFFFFD700,
          'icon': '🥇',
        };
      case LoyaltyTier.platinum:
        return {
          'name': 'Platinum',
          'discount': 0.20, // 20% discount
          'benefits': [
            '20% discount on all purchases',
            'Free express shipping',
            '24/7 dedicated support',
            'Exclusive monthly offers',
            'Early access to sales',
            'VIP events access',
          ],
          'color': 0xFFE5E4E2,
          'icon': '💎',
        };
      case LoyaltyTier.diamond:
        return {
          'name': 'Diamond',
          'discount': 0.25, // 25% discount
          'benefits': [
            '25% discount on all purchases',
            'Free express shipping',
            '24/7 dedicated support',
            'Exclusive monthly offers',
            'Early access to sales',
            'VIP events access',
            'Personal shopping assistant',
            'Custom product requests',
          ],
          'color': 0xFFB9F2FF,
          'icon': '💎',
        };
    }
  }

  // Get next tier requirements
  Map<String, dynamic>? getNextTierRequirements(LoyaltyTier currentTier, double totalSpent) {
    final tierRequirements = {
      LoyaltyTier.bronze: {'minSpent': 0.0, 'maxSpent': 50000.0},
      LoyaltyTier.silver: {'minSpent': 50000.0, 'maxSpent': 150000.0},
      LoyaltyTier.gold: {'minSpent': 150000.0, 'maxSpent': 500000.0},
      LoyaltyTier.platinum: {'minSpent': 500000.0, 'maxSpent': 1000000.0},
      LoyaltyTier.diamond: {'minSpent': 1000000.0, 'maxSpent': double.infinity},
    };

    final currentReq = tierRequirements[currentTier];
    if (currentReq == null) return null;

    final nextTier = _getNextTier(currentTier);
    if (nextTier == null) return null;

    final nextReq = tierRequirements[nextTier];
    if (nextReq == null) return null;

    final currentMinSpent = currentReq['minSpent'] as double;
    final nextMinSpent = nextReq['minSpent'] as double;
    
    final progress = (totalSpent - currentMinSpent) / (nextMinSpent - currentMinSpent);
    final pointsNeeded = nextMinSpent - totalSpent;

    return {
      'nextTier': nextTier,
      'minSpent': nextMinSpent,
      'currentSpent': totalSpent,
      'pointsNeeded': pointsNeeded,
      'progress': progress.clamp(0.0, 1.0),
    };
  }

  // Calculate points value in currency
  double calculatePointsValue(int points, double currencyPerPoint) {
    return points * currencyPerPoint;
  }

  // Helper method to get next tier
  LoyaltyTier? _getNextTier(LoyaltyTier currentTier) {
    switch (currentTier) {
      case LoyaltyTier.bronze:
        return LoyaltyTier.silver;
      case LoyaltyTier.silver:
        return LoyaltyTier.gold;
      case LoyaltyTier.gold:
        return LoyaltyTier.platinum;
      case LoyaltyTier.platinum:
        return LoyaltyTier.diamond;
      case LoyaltyTier.diamond:
        return null; // Already at highest tier
    }
  }

  // Check and update user tier
  Future<void> _checkAndUpdateTier(String userId) async {
    try {
      final account = await getUserLoyaltyAccount();
      if (account == null) return;

      final tierRequirements = {
        LoyaltyTier.bronze: 0,
        LoyaltyTier.silver: 50000,
        LoyaltyTier.gold: 150000,
        LoyaltyTier.platinum: 500000,
        LoyaltyTier.diamond: 1000000,
      };

      LoyaltyTier newTier = LoyaltyTier.bronze;
      for (final entry in tierRequirements.entries) {
        if (account.totalSpent >= entry.value) {
          newTier = entry.key;
        }
      }

      if (newTier != account.currentTier) {
        await _firestore.collection('loyalty_accounts').doc(userId).update({
          'currentTier': newTier.toString().split('.').last,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      debugPrint('Error updating tier: $e');
    }
  }
}
