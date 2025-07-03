import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/review_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/review_provider.dart';
import '../../services/user_profile_service.dart';
import '../../models/user_model.dart';
import '../../services/product_service.dart';

class SellerReviewsScreen extends ConsumerWidget {
  const SellerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final reviewsAsync = ref.watch(
      reviewsBySellerProvider(currentUser?.id ?? ''),
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return const Center(
              child: Text('No reviews found for your products.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Card(
                child: FutureBuilder<UserModel?>(
                  future: UserProfileService().getUserProfile(review.userId),
                  builder: (context, userSnapshot) {
                    final userData = userSnapshot.data;
                    return FutureBuilder<ProductModel?>(
                      future: ProductService().getProductById(review.productId),
                      builder: (context, productSnapshot) {
                        final product = productSnapshot.data;
                        return ListTile(
                          leading:
                              (userData?.profileImageUrl != null &&
                                      userData!.profileImageUrl!.isNotEmpty)
                                  ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      userData.profileImageUrl!,
                                    ),
                                  )
                                  : CircleAvatar(
                                    backgroundColor: colorScheme.primary,
                                    child: Text(
                                      review.rating.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          title: Text(review.comment ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Product: ${product?.name ?? "-"}'),
                              Text('By: ${review.userName ?? ''}'),
                              Text(
                                'Date: ${review.createdAt.toLocal().toString().split(' ')[0] ?? ''}',
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.flag, color: Colors.red),
                            tooltip: 'Flag as inappropriate',
                            onPressed: () async {
                              await ref
                                  .read(reviewProvider.notifier)
                                  .flagReview(review.id, review.productId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Review flagged for admin review.',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading reviews: $e')),
      ),
    );
  }
}
