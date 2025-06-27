import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/backup_service.dart';
import '../../services/error_handling_service.dart';

class AdminBackupScreen extends ConsumerStatefulWidget {
  const AdminBackupScreen({super.key});

  @override
  ConsumerState<AdminBackupScreen> createState() => _AdminBackupScreenState();
}

class _AdminBackupScreenState extends ConsumerState<AdminBackupScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _backups = [];
  final BackupService _backupService = BackupService();
  final ErrorHandlingService _errorHandler = ErrorHandlingService();

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);

    try {
      final backups = await _backupService.getBackupList();
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _errorHandler.showErrorSnackBar(context, 'Error loading backups: $e');
    }
  }

  Future<void> _createBackup(String backupType) async {
    setState(() => _isLoading = true);

    try {
      final result = await _backupService.createBackup(backupType: backupType);

      if (result['success'] == true) {
        _errorHandler.showErrorSnackBar(
          context,
          'Backup created successfully: ${result['backupId']}',
        );
        await _loadBackups();
      }
    } catch (e) {
      _errorHandler.showErrorSnackBar(context, 'Error creating backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restore Backup'),
            content: const Text(
              'Are you sure you want to restore this backup? This will overwrite current data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Restore'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await _backupService.restoreBackup(backupId);

      if (result['success'] == true) {
        _errorHandler.showErrorSnackBar(
          context,
          'Backup restored successfully',
        );
      }
    } catch (e) {
      _errorHandler.showErrorSnackBar(context, 'Error restoring backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Backup'),
            content: const Text(
              'Are you sure you want to delete this backup? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _backupService.deleteBackup(backupId);
      _errorHandler.showErrorSnackBar(context, 'Backup deleted successfully');
      await _loadBackups();
    } catch (e) {
      _errorHandler.showErrorSnackBar(context, 'Error deleting backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportBackup(String backupId) async {
    setState(() => _isLoading = true);

    try {
      final filePath = await _backupService.exportBackupToLocal(backupId);
      _errorHandler.showErrorSnackBar(context, 'Backup exported to: $filePath');
    } catch (e) {
      _errorHandler.showErrorSnackBar(context, 'Error exporting backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);

    if (user?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to access this area.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Management'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBackups),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Backup Actions
                  _buildBackupActions(theme),

                  // Backups List
                  Expanded(
                    child:
                        _backups.isEmpty
                            ? _buildEmptyState(theme)
                            : _buildBackupsList(theme),
                  ),
                ],
              ),
    );
  }

  Widget _buildBackupActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Backup',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                'Full Backup',
                Icons.backup,
                Colors.blue,
                () => _createBackup(BackupService.fullBackup),
                theme,
              ),
              _buildActionButton(
                'User Data',
                Icons.people,
                Colors.green,
                () => _createBackup(BackupService.userDataBackup),
                theme,
              ),
              _buildActionButton(
                'Orders',
                Icons.shopping_cart,
                Colors.orange,
                () => _createBackup(BackupService.ordersBackup),
                theme,
              ),
              _buildActionButton(
                'Products',
                Icons.inventory_2,
                Colors.purple,
                () => _createBackup(BackupService.productsBackup),
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    ThemeData theme,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.backup_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No backups found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first backup to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _backups.length,
      itemBuilder: (context, index) {
        final backup = _backups[index];
        return _buildBackupCard(backup, theme);
      },
    );
  }

  Widget _buildBackupCard(Map<String, dynamic> backup, ThemeData theme) {
    final id = backup['id'] as String?;
    final type = backup['type'] as String?;
    final createdAt = backup['createdAt'] as Timestamp?;
    final createdBy = backup['createdBy'] as String?;
    final version = backup['version'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getBackupIcon(type),
                  color: _getBackupColor(type),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getBackupTypeLabel(type),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${id?.substring(0, 8)}...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'restore':
                        _restoreBackup(id!);
                        break;
                      case 'export':
                        _exportBackup(id!);
                        break;
                      case 'delete':
                        _deleteBackup(id!);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              Icon(Icons.restore, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Restore'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Export'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created: ${createdAt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt.toDate()) : 'Unknown'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (createdBy != null)
                        Text(
                          'By: ${createdBy.substring(0, 8)}...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (version != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'v$version',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBackupIcon(String? type) {
    switch (type) {
      case BackupService.fullBackup:
        return Icons.backup;
      case BackupService.userDataBackup:
        return Icons.people;
      case BackupService.ordersBackup:
        return Icons.shopping_cart;
      case BackupService.productsBackup:
        return Icons.inventory_2;
      default:
        return Icons.backup_outlined;
    }
  }

  Color _getBackupColor(String? type) {
    switch (type) {
      case BackupService.fullBackup:
        return Colors.blue;
      case BackupService.userDataBackup:
        return Colors.green;
      case BackupService.ordersBackup:
        return Colors.orange;
      case BackupService.productsBackup:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getBackupTypeLabel(String? type) {
    switch (type) {
      case BackupService.fullBackup:
        return 'Full System Backup';
      case BackupService.userDataBackup:
        return 'User Data Backup';
      case BackupService.ordersBackup:
        return 'Orders Backup';
      case BackupService.productsBackup:
        return 'Products Backup';
      default:
        return 'Unknown Backup';
    }
  }
}
