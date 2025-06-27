import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../providers/review_provider.dart';
import '../../providers/auth_provider.dart';
import 'write_review_screen.dart';

class ProductReviewsScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductReviewsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductReviewsScreen> createState() =>
      _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends ConsumerState<ProductReviewsScreen> {
  int? _starFilter;
  bool _verifiedOnly = false;
  bool _withImagesOnly = false;
  String _sortBy = 'newest';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    final reviewFilter = ReviewFilter(
      productId: widget.product.id,
      starFilter: _starFilter,
      verifiedOnly: _verifiedOnly ? true : null,
      withImagesOnly: _withImagesOnly ? true : null,
      sortBy: _sortBy,
    );

    final reviewsAsync = ref.watch(
      filteredProductReviewsStreamProvider(reviewFilter),
    );
    final summaryAsync = ref.watch(reviewSummaryProvider(widget.product.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        elevation: 0,
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToWriteReview(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Review summary
          summaryAsync.when(
            data: (summary) => _buildReviewSummary(summary, theme),
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => Container(),
          ),

          // Filters
          _buildFilters(theme),

          // Reviews list
          Expanded(
            child: reviewsAsync.when(
              data: (reviews) => _buildReviewsList(reviews, theme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error loading reviews: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              () => ref.refresh(
                                filteredProductReviewsStreamProvider(
                                  reviewFilter,
                                ),
                              ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSummary(ReviewSummary summary, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.averageRating.toStringAsFixed(1),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < summary.averageRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  Text(
                    '${summary.totalReviews} reviews',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final star = 5 - index;
                    final count = summary.ratingDistribution[star] ?? 0;
                    final percentage = summary.getPercentageForRating(star);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$star'),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$count', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Star filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _starFilter == null,
                  onSelected: (selected) => setState(() => _starFilter = null),
                ),
                const SizedBox(width: 8),
                ...List.generate(5, (index) {
                  final star = 5 - index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$star'),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                        ],
                      ),
                      selected: _starFilter == star,
                      onSelected:
                          (selected) => setState(
                            () => _starFilter = selected ? star : null,
                          ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Other filters
          Row(
            children: [
              FilterChip(
                label: const Text('Verified'),
                selected: _verifiedOnly,
                onSelected:
                    (selected) => setState(() => _verifiedOnly = selected),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('With Photos'),
                selected: _withImagesOnly,
                onSelected:
                    (selected) => setState(() => _withImagesOnly = selected),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                  DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                  DropdownMenuItem(
                    value: 'highest_rating',
                    child: Text('Highest Rating'),
                  ),
                  DropdownMenuItem(
                    value: 'lowest_rating',
                    child: Text('Lowest Rating'),
                  ),
                  DropdownMenuItem(
                    value: 'most_helpful',
                    child: Text('Most Helpful'),
                  ),
                ],
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(List<ReviewModel> reviews, ThemeData theme) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this product',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _navigateToWriteReview(context),
              child: const Text('Write a Review'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return ReviewCard(
          review: review,
          onHelpful: () => _markReviewHelpful(review.id),
        );
      },
    );
  }

  void _navigateToWriteReview(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final user = ref.read(currentUserProvider);
    if (user == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please log in to write a review')),
      );
      return;
    }

    // Check if user has already reviewed this product
    final existingReview = await ref
        .read(reviewProvider.notifier)
        .getUserReviewForProduct(user.id, widget.product.id);

    if (existingReview != null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('You have already reviewed this product')),
      );
      return;
    }

    if (mounted) {
      final result = await navigator.push(
        MaterialPageRoute(
          builder: (context) => WriteReviewScreen(product: widget.product),
        ),
      );

      if (result == true) {
        // Refresh the reviews
        ref.refresh(reviewSummaryProvider(widget.product.id));
      }
    }
  }

  void _markReviewHelpful(String reviewId) {
    ref.read(reviewProvider.notifier).markReviewHelpful(reviewId);
  }
}

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onHelpful;

  const ReviewCard({super.key, required this.review, required this.onHelpful});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : 'A',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (review.isVerifiedPurchase) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            review.timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            if (review.title.isNotEmpty) ...[
              Text(
                review.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Comment
            Text(review.comment, style: theme.textTheme.bodyMedium),

            // Images
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          review.images[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onHelpful,
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('Helpful (${review.helpfulCount})'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
