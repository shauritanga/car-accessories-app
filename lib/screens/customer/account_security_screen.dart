import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../models/user_model.dart';

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() =>
      _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to access security settings')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account Security'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Information
            _buildSectionHeader('Account Information', Icons.account_circle),
            _buildAccountInfo(user, theme),

            const SizedBox(height: 24),

            // Security Settings
            _buildSectionHeader('Security Settings', Icons.security),
            _buildSecuritySettings(theme),

            const SizedBox(height: 24),

            // Two-Factor Authentication
            _buildSectionHeader(
              'Two-Factor Authentication',
              Icons.verified_user,
            ),
            _buildTwoFactorAuth(theme),

            const SizedBox(height: 24),

            // Privacy & Data
            _buildSectionHeader('Privacy & Data', Icons.privacy_tip),
            _buildPrivacySettings(theme),

            const SizedBox(height: 24),

            // Danger Zone
            _buildSectionHeader('Danger Zone', Icons.warning, Colors.red),
            _buildDangerZone(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, [Color? color]) {
    return Row(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfo(UserModel user, ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email Address'),
            subtitle: Text(user.email ?? 'Not provided'),
            trailing: TextButton(
              onPressed: () => _showChangeEmailDialog(),
              child: const Text('Change'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Full Name'),
            subtitle: Text(user.name ?? 'Not provided'),
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
              child: const Text('Edit'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone Number'),
            subtitle: Text(user.phone ?? 'Not provided'),
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
              child: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings(ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showChangePasswordDialog(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Login Activity'),
            subtitle: const Text('View recent login attempts'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLoginActivity(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Active Sessions'),
            subtitle: const Text('Manage logged-in devices'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showActiveSessions(),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoFactorAuth(ThemeData theme) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.verified_user),
            title: const Text('Two-Factor Authentication'),
            subtitle: const Text(
              'Add an extra layer of security to your account',
            ),
            value: true, // This would come from user preferences
            onChanged: (value) => _toggle2FA(value),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.smartphone),
            title: const Text('Authenticator App'),
            subtitle: const Text('Use an authenticator app for 2FA codes'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _setup2FA(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Codes'),
            subtitle: const Text('Generate backup codes for account recovery'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _generateBackupCodes(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings(ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download Your Data'),
            subtitle: const Text('Get a copy of your account data'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _downloadUserData(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Privacy Settings'),
            subtitle: const Text('Control who can see your information'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showPrivacySettings(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cookie),
            title: const Text('Cookie Preferences'),
            subtitle: const Text('Manage your cookie settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showCookieSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(ThemeData theme) {
    return Card(
      color: Colors.red.withValues(alpha: 0.05),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Sign Out All Devices'),
            subtitle: const Text('Sign out from all devices and browsers'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _signOutAllDevices(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account'),
            subtitle: const Text(
              'Permanently delete your account and all data',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDeleteAccountDialog(),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _showChangeEmailDialog() {
    showDialog(context: context, builder: (context) => _ChangeEmailDialog());
  }

  void _showChangePasswordDialog() {
    showDialog(context: context, builder: (context) => _ChangePasswordDialog());
  }

  void _showLoginActivity() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login activity feature coming soon!')),
    );
  }

  void _showActiveSessions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Active sessions feature coming soon!')),
    );
  }

  void _toggle2FA(bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('2FA ${enabled ? 'enabled' : 'disabled'}'),
        backgroundColor: enabled ? Colors.green : Colors.orange,
      ),
    );
  }

  void _setup2FA() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('2FA setup feature coming soon!')),
    );
  }

  void _generateBackupCodes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup codes feature coming soon!')),
    );
  }

  Future<void> _downloadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final userData = await ref
            .read(userProfileProvider.notifier)
            .exportUserData(user.id);

        // In a real app, this would trigger a download or email the data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Data export initiated. You will receive an email shortly.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
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

  void _showPrivacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings feature coming soon!')),
    );
  }

  void _showCookieSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cookie settings feature coming soon!')),
    );
  }

  void _signOutAllDevices() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out All Devices'),
            content: const Text(
              'This will sign you out from all devices and browsers. You will need to sign in again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Implement sign out all devices
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Signed out from all devices'),
                    ),
                  );
                },
                child: const Text('Sign Out All'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(context: context, builder: (context) => _DeleteAccountDialog());
  }
}

// Change Email Dialog
class _ChangeEmailDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends ConsumerState<_ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Email Address'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'New Email Address',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email address';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your current password';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changeEmail,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Change Email'),
        ),
      ],
    );
  }

  Future<void> _changeEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(userProfileProvider.notifier)
          .updateEmail(_emailController.text.trim(), _passwordController.text);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email address updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating email: $e'),
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
}

// Change Password Dialog
class _ChangePasswordDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your current password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Change Password'),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(userProfileProvider.notifier)
          .changePassword(
            _currentPasswordController.text,
            _newPasswordController.text,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e'),
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
}

// Delete Account Dialog
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _confirmDelete = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This action cannot be undone. This will permanently delete your account and all associated data.',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('I understand that this action is permanent'),
            value: _confirmDelete,
            onChanged:
                (value) => setState(() => _confirmDelete = value ?? false),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Enter your password to confirm',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              (_confirmDelete &&
                      _passwordController.text.isNotEmpty &&
                      !_isLoading)
                  ? _deleteAccount
                  : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Delete Account'),
        ),
      ],
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(userProfileProvider.notifier)
          .deleteAccount(_passwordController.text);

      if (mounted) {
        Navigator.pop(context);
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
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
}
