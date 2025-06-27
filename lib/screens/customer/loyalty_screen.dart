import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/loyalty_provider.dart';
import '../../models/loyalty_model.dart';

final loyaltyProvider = ChangeNotifierProvider<LoyaltyProvider>(
  (ref) => LoyaltyProvider(),
);

class LoyaltyScreen extends ConsumerStatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  ConsumerState<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends ConsumerState<LoyaltyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loyaltyProvider).initializeLoyalty();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyProviderValue = ref.watch(loyaltyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Program'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          if (loyaltyProviderValue.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (loyaltyProviderValue.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    loyaltyProviderValue.error!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => loyaltyProviderValue.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildLoyaltyHeader(loyaltyProviderValue),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRewardsTab(loyaltyProviderValue),
                    _buildTransactionsTab(loyaltyProviderValue),
                    _buildTierInfoTab(loyaltyProviderValue),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoyaltyHeader(LoyaltyProvider provider) {
    final account = provider.userAccount;
    if (account == null) return const SizedBox.shrink();

    final nextTierReq = provider.getNextTierRequirements();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Tier Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(provider.getTierColor()).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color(provider.getTierColor()),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: Color(provider.getTierColor()),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.getTierDisplayName(),
                  style: TextStyle(
                    color: Color(provider.getTierColor()),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Points Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPointsCard(
                'Current Points',
                '${account.currentPoints}',
                Icons.stars,
                Colors.amber,
              ),
              _buildPointsCard(
                'Points Value',
                provider.getFormattedPointsValue(),
                Icons.attach_money,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress to Next Tier
          if (nextTierReq != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress to ${nextTierReq['nextTier'].toString().split('.').last}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  '${nextTierReq['progress'].toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: nextTierReq['progress'] / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(provider.getTierColor()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TZS ${nextTierReq['remainingSpend'].toStringAsFixed(0)} more to next tier',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPointsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'Rewards'),
          Tab(text: 'History'),
          Tab(text: 'Tier Info'),
        ],
      ),
    );
  }

  Widget _buildRewardsTab(LoyaltyProvider provider) {
    final rewards = provider.availableRewards;

    if (rewards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No rewards available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canRedeem = provider.canRedeemReward(reward);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: canRedeem ? Theme.of(context).primaryColor : Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getRewardIcon(reward.type),
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              reward.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.stars, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.pointsCost} points',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed:
                  canRedeem
                      ? () => _redeemReward(context, provider, reward)
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canRedeem ? Theme.of(context).primaryColor : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: Text(canRedeem ? 'Redeem' : 'Not Enough'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab(LoyaltyProvider provider) {
    final transactions = provider.transactions;

    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No transactions yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isEarned = transaction.type == TransactionType.earned;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isEarned ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isEarned ? Icons.add : Icons.remove,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              transaction.description,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _formatDate(transaction.createdAt),
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Text(
              '${isEarned ? '+' : ''}${transaction.points}',
              style: TextStyle(
                color: isEarned ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTierInfoTab(LoyaltyProvider provider) {
    final currentTier = provider.userAccount?.currentTier ?? LoyaltyTier.bronze;
    final benefits = provider.getTierBenefits(currentTier);
    final nextTierReq = provider.getNextTierRequirements();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current Tier Benefits
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Color(provider.getTierColor()),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${provider.getTierDisplayName()} Benefits',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBenefitItem(
                  'Points Multiplier',
                  '${benefits['pointsMultiplier']}x',
                  Icons.trending_up,
                ),
                _buildBenefitItem(
                  'Discount',
                  '${benefits['discountPercentage']}%',
                  Icons.discount,
                ),
                _buildBenefitItem(
                  'Free Shipping',
                  benefits['freeShipping'] ? 'Yes' : 'No',
                  Icons.local_shipping,
                ),
                _buildBenefitItem(
                  'Priority Support',
                  'Level ${benefits['prioritySupport']}',
                  Icons.support_agent,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Next Tier Info
        if (nextTierReq != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Tier: ${nextTierReq['nextTier'].toString().split('.').last}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Spend TZS ${nextTierReq['minimumSpend'].toStringAsFixed(0)} to unlock',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: nextTierReq['progress'] / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(provider.getTierColor()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${nextTierReq['progress'].toStringAsFixed(1)}% complete',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // All Tiers Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Tiers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...LoyaltyTier.values.map((tier) {
                  final tierBenefits = provider.getTierBenefits(tier);
                  final isCurrentTier = tier == currentTier;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isCurrentTier
                              ? Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1)
                              : null,
                      border:
                          isCurrentTier
                              ? Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              )
                              : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color:
                              isCurrentTier
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tierBenefits['name'],
                                style: TextStyle(
                                  fontWeight:
                                      isCurrentTier
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      isCurrentTier
                                          ? Theme.of(context).primaryColor
                                          : null,
                                ),
                              ),
                              Text(
                                '${tierBenefits['pointsMultiplier']}x points • ${tierBenefits['discountPercentage']}% discount',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrentTier)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(dynamic type) {
    // Accepts either RewardType or String
    RewardType rewardType;
    if (type is RewardType) {
      rewardType = type;
    } else if (type is String) {
      switch (type) {
        case 'discount':
          rewardType = RewardType.discount;
          break;
        case 'freeShipping':
        case 'free_shipping':
          rewardType = RewardType.freeShipping;
          break;
        case 'freeProduct':
        case 'free_product':
          rewardType = RewardType.freeProduct;
          break;
        case 'cashback':
          rewardType = RewardType.cashback;
          break;
        case 'bonusPoints':
        case 'bonus_points':
          rewardType = RewardType.bonusPoints;
          break;
        case 'exclusiveAccess':
        case 'exclusive_access':
          rewardType = RewardType.exclusiveAccess;
          break;
        default:
          rewardType = RewardType.discount;
      }
    } else {
      rewardType = RewardType.discount;
    }
    switch (rewardType) {
      case RewardType.discount:
        return Icons.discount;
      case RewardType.freeShipping:
        return Icons.local_shipping;
      case RewardType.freeProduct:
        return Icons.card_giftcard;
      case RewardType.cashback:
        return Icons.attach_money;
      case RewardType.bonusPoints:
        return Icons.stars;
      case RewardType.exclusiveAccess:
        return Icons.access_time;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  Future<void> _redeemReward(
    BuildContext context,
    LoyaltyProvider provider,
    LoyaltyReward reward,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Redeem Reward'),
            content: Text(
              'Are you sure you want to redeem "${reward.name}" for ${reward.pointsCost} points?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Redeem'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await provider.redeemPoints(
        rewardId: reward.id,
        pointsCost: reward.pointsCost,
        rewardName: reward.name,
      );

      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Successfully redeemed ${reward.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to redeem reward'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
