import 'package:flutter/foundation.dart';
import '../models/loyalty_model.dart';
import '../services/loyalty_service.dart';

class LoyaltyProvider extends ChangeNotifier {
  final LoyaltyService _loyaltyService = LoyaltyService();

  UserLoyaltyAccount? _userAccount;
  LoyaltyProgram? _loyaltyProgram;
  List<LoyaltyReward> _availableRewards = [];
  List<LoyaltyTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  UserLoyaltyAccount? get userAccount => _userAccount;
  LoyaltyProgram? get loyaltyProgram => _loyaltyProgram;
  List<LoyaltyReward> get availableRewards => _availableRewards;
  List<LoyaltyTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize loyalty data
  Future<void> initializeLoyalty() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadUserAccount(),
        loadLoyaltyProgram(),
        loadAvailableRewards(),
        loadTransactionHistory(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Load user's loyalty account
  Future<void> loadUserAccount() async {
    try {
      _userAccount = await _loyaltyService.getUserLoyaltyAccount();
      _userAccount ??= await _loyaltyService.createLoyaltyAccount();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load loyalty account: $e';
      notifyListeners();
    }
  }

  // Load loyalty program configuration
  Future<void> loadLoyaltyProgram() async {
    try {
      _loyaltyProgram = await _loyaltyService.getLoyaltyProgram();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load loyalty program: $e';
      notifyListeners();
    }
  }

  // Load available rewards
  Future<void> loadAvailableRewards() async {
    try {
      _availableRewards = await _loyaltyService.getAvailableRewards();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load rewards: $e';
      notifyListeners();
    }
  }

  // Load transaction history
  Future<void> loadTransactionHistory({int limit = 20}) async {
    try {
      _transactions = await _loyaltyService.getTransactionHistory(limit: limit);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load transaction history: $e';
      notifyListeners();
    }
  }

  // Earn points from purchase
  Future<void> earnPointsFromPurchase({
    required String orderId,
    required double orderAmount,
  }) async {
    if (_loyaltyProgram == null) {
      _error = 'Loyalty program not loaded';
      notifyListeners();
      return;
    }

    try {
      await _loyaltyService.earnPointsFromPurchase(
        orderId: orderId,
        orderAmount: orderAmount,
        pointsPerCurrency: _loyaltyProgram!.pointsPerCurrency,
      );

      // Reload user account to get updated points
      await loadUserAccount();
      await loadTransactionHistory();
    } catch (e) {
      _error = 'Failed to earn points: $e';
      notifyListeners();
    }
  }

  // Redeem points for reward
  Future<bool> redeemPoints({
    required String rewardId,
    required int pointsCost,
    required String rewardName,
  }) async {
    try {
      final success = await _loyaltyService.redeemPoints(
        rewardId: rewardId,
        pointsCost: pointsCost,
        rewardName: rewardName,
      );

      if (success) {
        // Reload user account and transaction history
        await loadUserAccount();
        await loadTransactionHistory();
        return true;
      } else {
        _error = 'Failed to redeem points';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to redeem points: $e';
      notifyListeners();
      return false;
    }
  }

  // Get tier benefits
  Map<String, dynamic> getTierBenefits(LoyaltyTier tier) {
    return _loyaltyService.getTierBenefits(tier);
  }

  // Get next tier requirements
  Map<String, dynamic>? getNextTierRequirements() {
    if (_userAccount == null) return null;

    return _loyaltyService.getNextTierRequirements(
      _userAccount!.currentTier,
      _userAccount!.totalSpent,
    );
  }

  // Calculate points value in currency
  double calculatePointsValue(int points) {
    if (_loyaltyProgram == null) return 0.0;
    return _loyaltyService.calculatePointsValue(
      points,
      _loyaltyProgram!.currencyPerPoint,
    );
  }

  // Check if user can redeem a reward
  bool canRedeemReward(LoyaltyReward reward) {
    if (_userAccount == null) return false;
    return _userAccount!.currentPoints >= reward.pointsCost &&
        reward.isAvailable;
  }

  // Get user's current tier benefits
  Map<String, dynamic> getCurrentTierBenefits() {
    if (_userAccount == null) return {};
    return getTierBenefits(_userAccount!.currentTier);
  }

  // Get points to next tier
  int getPointsToNextTier() {
    if (_userAccount == null) return 0;
    return _userAccount!.pointsToNextTier;
  }

  // Get formatted points value
  String getFormattedPointsValue() {
    if (_userAccount == null) return '0 TZS';
    final value = calculatePointsValue(_userAccount!.currentPoints);
    return '${value.toStringAsFixed(0)} TZS';
  }

  // Get tier progress percentage
  double getTierProgressPercentage() {
    final nextTierReq = getNextTierRequirements();
    if (nextTierReq == null) return 100.0;
    return nextTierReq['progress'] ?? 0.0;
  }

  // Get tier display name
  String getTierDisplayName() {
    if (_userAccount == null) return 'Bronze';

    switch (_userAccount!.currentTier) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Silver';
      case LoyaltyTier.gold:
        return 'Gold';
      case LoyaltyTier.platinum:
        return 'Platinum';
      case LoyaltyTier.diamond:
        return 'Diamond';
    }
  }

  // Get tier color
  int getTierColor() {
    if (_userAccount == null) return 0xFFCD7F32; // Bronze

    switch (_userAccount!.currentTier) {
      case LoyaltyTier.bronze:
        return 0xFFCD7F32; // Bronze
      case LoyaltyTier.silver:
        return 0xFFC0C0C0; // Silver
      case LoyaltyTier.gold:
        return 0xFFFFD700; // Gold
      case LoyaltyTier.platinum:
        return 0xFFE5E4E2; // Platinum
      case LoyaltyTier.diamond:
        return 0xFFB9F2FF; // Diamond
    }
  }

  // Filter rewards by type
  List<LoyaltyReward> getRewardsByType(RewardType type) {
    return _availableRewards
        .where((reward) => reward.rewardType == type)
        .toList();
  }

  // Get recent transactions
  List<LoyaltyTransaction> getRecentTransactions({int limit = 5}) {
    return _transactions.take(limit).toList();
  }

  // Get transactions by type
  List<LoyaltyTransaction> getTransactionsByType(TransactionType type) {
    return _transactions
        .where((transaction) => transaction.type == type)
        .toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    await initializeLoyalty();
  }
}
