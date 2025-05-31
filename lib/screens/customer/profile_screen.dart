import 'package:car_accessories/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user.name?.substring(0, 1).toUpperCase() ?? 'C',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name ?? 'Customer',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Profile sections
            ProfileSection(
              title: 'Account Information',
              items: [
                ProfileItem(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  onTap: () {
                    // Navigate to personal info screen
                  },
                ),
                ProfileItem(
                  icon: Icons.location_on_outlined,
                  title: 'Addresses',
                  onTap: () {
                    // Navigate to addresses screen
                  },
                ),
                ProfileItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {
                    // Navigate to change password screen
                  },
                ),
              ],
            ),

            ProfileSection(
              title: 'Orders & Purchases',
              items: [
                ProfileItem(
                  icon: Icons.history,
                  title: 'Order History',
                  onTap: () {
                    // Navigate to order history
                  },
                ),
                ProfileItem(
                  icon: Icons.favorite_border,
                  title: 'Wishlist',
                  onTap: () {
                    // Navigate to wishlist
                  },
                ),
              ],
            ),

            ProfileSection(
              title: 'App Settings',
              items: [
                ProfileItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    // Navigate to notifications settings
                  },
                ),
                ProfileItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    // Navigate to help & support
                  },
                ),
                ProfileItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    // Navigate to about screen
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSection extends StatelessWidget {
  final String title;
  final List<ProfileItem> items;

  const ProfileSection({required this.title, required this.items, super.key});

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
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Column(children: items),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileItem({
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
