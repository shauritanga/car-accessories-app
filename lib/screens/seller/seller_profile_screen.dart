import 'package:car_accessories/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'store_details_screen.dart';
import 'sales_analytics_screen.dart';
import '../customer/customer_support_screen.dart';
import '../customer/notifications_screen.dart';
import 'pending_approval_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/supabase_storage_service.dart';

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  Future<void> _uploadKycDoc(BuildContext context, String sellerId, void Function(void Function()) setState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final file = File(pickedFile.path);
    final url = await SupabaseStorageService.uploadImage(file: file, customPath: 'kyc/${sellerId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    if (url != null) {
      await FirebaseFirestore.instance.collection('users').doc(sellerId).update({
        'kycDocs': FieldValue.arrayUnion([url])
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully.')));
        setState(() {});
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload document.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user?.role == 'seller' && user?.status != 'approved') {
      return const PendingApprovalScreen();
    }
    final authNotifier = ref.read(authProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Profile'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await authNotifier.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to sign out: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.05),
              colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 32,
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: colorScheme.primary,
                            child: Text(
                              user.name?.substring(0, 1).toUpperCase() ?? 'S',
                              style: const TextStyle(
                                fontSize: 44,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            user.name ?? 'Seller',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            user.email ?? '',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              'Seller Account',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Verification Documents (KYC)', style: theme.textTheme.titleMedium),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload'),
                              onPressed: () => _uploadKycDoc(context, user.id, setState),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          future: FirebaseFirestore.instance.collection('users').doc(user.id).get(),
                          builder: (context, snapshot) {
                            final kycDocs = (snapshot.data?.data()?['kycDocs'] as List?) ?? [];
                            if (kycDocs.isEmpty) {
                              return const Text('No documents uploaded.');
                            }
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: kycDocs.map<Widget>((url) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                              )).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                _ProfileSection(
                  title: 'Business Information',
                  items: [
                    _ProfileItem(
                      icon: Icons.store_outlined,
                      title: 'Store Details',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StoreDetailsScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.payment_outlined,
                      title: 'Payment Methods',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Payment methods management coming soon',
                            ),
                          ),
                        );
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () {},
                    ),
                  ],
                ),
                _ProfileSection(
                  title: 'Sales & Inventory',
                  items: [
                    _ProfileItem(
                      icon: Icons.analytics_outlined,
                      title: 'Sales Analytics',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SalesAnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.inventory_2_outlined,
                      title: 'Inventory Management',
                      onTap: () {
                        context.push('/seller/inventory');
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.reviews_outlined,
                      title: 'Customer Reviews',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Customer reviews feature coming soon'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                _ProfileSection(
                  title: 'App Settings',
                  items: [
                    _ProfileItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileItem> items;
  const _ProfileSection({required this.title, required this.items, super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Column(children: items),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
