import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../models/user_profile_model.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  UserPreferences? _preferences;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        final profileService = ref.read(userProfileProvider.notifier);
        await profileService.loadUserProfile(user.id);

        final profileState = ref.read(userProfileProvider);
        setState(() {
          _preferences = profileState.preferences;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading preferences: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to access settings')),
      );
    }

    if (_preferences == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Account Settings')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings
            _buildSectionHeader('General Settings', Icons.settings),
            _buildGeneralSettings(theme),

            const SizedBox(height: 24),

            // Notification Settings
            _buildSectionHeader('Notifications', Icons.notifications),
            _buildNotificationSettings(theme),

            const SizedBox(height: 24),

            // Default Preferences
            _buildSectionHeader('Default Preferences', Icons.tune),
            _buildDefaultPreferences(theme),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Save Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGeneralSettings(ThemeData theme) {
    return Card(
      child: Column(
        children: [
          _buildDropdownSetting(
            'Language',
            _preferences!.language,
            {'en': 'English', 'sw': 'Kiswahili', 'fr': 'Français'},
            (value) =>
                _updatePreference((prefs) => prefs.copyWith(language: value)),
            Icons.language,
          ),
          const Divider(height: 1),
          _buildDropdownSetting(
            'Currency',
            _preferences!.currency,
            {
              'TZS': 'Tanzanian Shilling (TZS)',
              'USD': 'US Dollar (USD)',
              'EUR': 'Euro (EUR)',
            },
            (value) =>
                _updatePreference((prefs) => prefs.copyWith(currency: value)),
            Icons.attach_money,
          ),
          const Divider(height: 1),
          _buildDropdownSetting(
            'Timezone',
            _preferences!.timezone,
            {
              'Africa/Dar_es_Salaam': 'East Africa Time (EAT)',
              'UTC': 'Coordinated Universal Time (UTC)',
              'America/New_York': 'Eastern Time (ET)',
            },
            (value) =>
                _updatePreference((prefs) => prefs.copyWith(timezone: value)),
            Icons.access_time,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(ThemeData theme) {
    return Card(
      child: Column(
        children: [
          _buildSwitchSetting(
            'Email Notifications',
            'Receive notifications via email',
            _preferences!.emailNotifications,
            (value) => _updatePreference(
              (prefs) => prefs.copyWith(emailNotifications: value),
            ),
            Icons.email,
          ),
          const Divider(height: 1),
          _buildSwitchSetting(
            'Push Notifications',
            'Receive push notifications on your device',
            _preferences!.pushNotifications,
            (value) => _updatePreference(
              (prefs) => prefs.copyWith(pushNotifications: value),
            ),
            Icons.notifications,
          ),
          const Divider(height: 1),
          _buildSwitchSetting(
            'SMS Notifications',
            'Receive notifications via SMS',
            _preferences!.smsNotifications,
            (value) => _updatePreference(
              (prefs) => prefs.copyWith(smsNotifications: value),
            ),
            Icons.sms,
          ),
          const Divider(height: 1),
          _buildSwitchSetting(
            'Order Updates',
            'Get notified about order status changes',
            _preferences!.orderUpdates,
            (value) => _updatePreference(
              (prefs) => prefs.copyWith(orderUpdates: value),
            ),
            Icons.shopping_bag,
          ),
          const Divider(height: 1),
          _buildSwitchSetting(
            'Price Alerts',
            'Get notified when prices drop on wishlist items',
            _preferences!.priceAlerts,
            (value) => _updatePreference(
              (prefs) => prefs.copyWith(priceAlerts: value),
            ),
            Icons.trending_down,
          ),
          const Divider(height: 1),
          _buildSwitchSetting(
            'Product Recommendations',
            'Receive personalized product suggestions',
            _preferences!.productRecommendations,
            (value) => _updatePreference(
              (prefs) => prefs.copyWith(productRecommendations: value),
            ),
            Icons.recommend,
          ),
          const Divider(height: 1),
          _buildSwitchSetting(
            'Marketing Emails',
            'Receive promotional offers and newsletters',
            _preferences!.marketingEmails,
            (value) => _updatePreference(
              (prefs) => prefs.copyWith(marketingEmails: value),
            ),
            Icons.campaign,
          ),
          const Divider(height: 1),
          _buildSwitchSetting(
            'Promotional Offers',
            'Get notified about special deals and discounts',
            _preferences!.promotionalOffers,
            (value) => _updatePreference(
              (prefs) => prefs.copyWith(promotionalOffers: value),
            ),
            Icons.local_offer,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPreferences(ThemeData theme) {
    final profileState = ref.watch(userProfileProvider);

    return Card(
      child: Column(
        children: [
          _buildInfoTile(
            'Default Shipping Address',
            profileState.defaultAddress?.label ?? 'Not set',
            Icons.local_shipping,
            () => _showAddressSelector(true),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            'Default Billing Address',
            profileState.defaultAddress?.label ?? 'Not set',
            Icons.receipt_long,
            () => _showAddressSelector(false),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            'Default Payment Method',
            profileState.defaultPaymentMethod?.label ?? 'Not set',
            Icons.payment,
            () => _showPaymentMethodSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    Map<String, String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items:
            options.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _updatePreference(UserPreferences Function(UserPreferences) updater) {
    setState(() {
      _preferences = updater(_preferences!);
    });
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(userProfileProvider.notifier)
          .updatePreferences(_preferences!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddressSelector(bool isShipping) {
    // This would show a dialog to select default address
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${isShipping ? 'Shipping' : 'Billing'} address selector coming soon!',
        ),
      ),
    );
  }

  void _showPaymentMethodSelector() {
    // This would show a dialog to select default payment method
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment method selector coming soon!')),
    );
  }
}
