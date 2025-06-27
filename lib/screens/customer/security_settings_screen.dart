import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  bool _twoFactorEnabled = false;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _loginActivity = [];
  List<Map<String, dynamic>> _activeSessions = [];

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
    _loadLoginActivity();
    _loadActiveSessions();
  }

  Future<void> _loadSecuritySettings() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('user_security')
              .doc(user.id)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _twoFactorEnabled = data['twoFactorEnabled'] ?? false;
          _emailNotifications = data['emailNotifications'] ?? true;
          _smsNotifications = data['smsNotifications'] ?? false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading security settings: $e')),
        );
      }
    }
  }

  Future<void> _loadLoginActivity() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Mock login activity data
    setState(() {
      _loginActivity = [
        {
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          'device': 'iPhone 14 Pro',
          'location': 'Dar es Salaam, Tanzania',
          'ipAddress': '192.168.1.100',
          'status': 'Success',
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'device': 'Chrome Browser',
          'location': 'Dar es Salaam, Tanzania',
          'ipAddress': '192.168.1.101',
          'status': 'Success',
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(days: 1)),
          'device': 'Android Phone',
          'location': 'Arusha, Tanzania',
          'ipAddress': '10.0.0.50',
          'status': 'Failed',
        },
      ];
    });
  }

  Future<void> _loadActiveSessions() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Mock active sessions data
    setState(() {
      _activeSessions = [
        {
          'id': 'session_1',
          'device': 'iPhone 14 Pro',
          'location': 'Dar es Salaam, Tanzania',
          'lastActive': DateTime.now().subtract(const Duration(minutes: 5)),
          'isCurrent': true,
        },
        {
          'id': 'session_2',
          'device': 'Chrome Browser',
          'location': 'Dar es Salaam, Tanzania',
          'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
          'isCurrent': false,
        },
      ];
    });
  }

  Future<void> _updateSecuritySetting(String key, bool value) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('user_security')
          .doc(user.id)
          .set({
            key: value,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security setting updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating setting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match')),
                    );
                    return;
                  }

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPasswordController.text,
                      );

                      await user.reauthenticateWithCredential(credential);
                      await user.updatePassword(newPasswordController.text);

                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error changing password: $e')),
                      );
                    }
                  }
                },
                child: const Text('Change Password'),
              ),
            ],
          ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _setup2FA() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Two-Factor Authentication'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Two-factor authentication adds an extra layer of security to your account.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'This feature will be available in a future update.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _terminateSession(String sessionId) async {
    setState(() {
      _activeSessions.removeWhere((session) => session['id'] == sessionId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session terminated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Security',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage your account security settings',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Security Settings
            Text(
              'Security Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Two-Factor Authentication'),
                    subtitle: const Text('Add an extra layer of security'),
                    value: _twoFactorEnabled,
                    onChanged:
                        _isLoading
                            ? null
                            : (value) {
                              if (value) {
                                _setup2FA();
                              } else {
                                setState(() => _twoFactorEnabled = value);
                                _updateSecuritySetting(
                                  'twoFactorEnabled',
                                  value,
                                );
                              }
                            },
                    secondary: const Icon(Icons.security),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Receive security alerts via email'),
                    value: _emailNotifications,
                    onChanged:
                        _isLoading
                            ? null
                            : (value) {
                              setState(() => _emailNotifications = value);
                              _updateSecuritySetting(
                                'emailNotifications',
                                value,
                              );
                            },
                    secondary: const Icon(Icons.email),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('SMS Notifications'),
                    subtitle: const Text('Receive security alerts via SMS'),
                    value: _smsNotifications,
                    onChanged:
                        _isLoading
                            ? null
                            : (value) {
                              setState(() => _smsNotifications = value);
                              _updateSecuritySetting('smsNotifications', value);
                            },
                    secondary: const Icon(Icons.sms),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your account password'),
                    leading: const Icon(Icons.lock),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _changePassword,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Login Activity
            Text(
              'Recent Login Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children:
                    _loginActivity.map((activity) {
                      final isSuccess = activity['status'] == 'Success';
                      return ListTile(
                        leading: Icon(
                          isSuccess ? Icons.check_circle : Icons.error,
                          color: isSuccess ? Colors.green : Colors.red,
                        ),
                        title: Text(activity['device']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activity['location']),
                            Text(
                              '${activity['timestamp'].toString().substring(0, 16)} • ${activity['ipAddress']}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isSuccess ? Colors.green : Colors.red)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            activity['status'],
                            style: TextStyle(
                              color: isSuccess ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 32),

            // Active Sessions
            Text(
              'Active Sessions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children:
                    _activeSessions.map((session) {
                      final isCurrent = session['isCurrent'] as bool;
                      return ListTile(
                        leading: Icon(
                          Icons.devices,
                          color:
                              isCurrent
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                        ),
                        title: Row(
                          children: [
                            Text(session['device']),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Current',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(session['location']),
                            Text(
                              'Last active: ${session['lastActive'].toString().substring(0, 16)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing:
                            isCurrent
                                ? null
                                : IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _terminateSession(session['id']),
                                  tooltip: 'Terminate session',
                                ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
