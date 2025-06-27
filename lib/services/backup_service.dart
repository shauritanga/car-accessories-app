import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'error_handling_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ErrorHandlingService _errorHandler = ErrorHandlingService();

  // Backup types
  static const String fullBackup = 'full_backup';
  static const String userDataBackup = 'user_data_backup';
  static const String ordersBackup = 'orders_backup';
  static const String productsBackup = 'products_backup';

  // Create comprehensive backup
  Future<Map<String, dynamic>> createBackup({
    required String backupType,
    String? userId,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final backupId = '${backupType}_${DateTime.now().millisecondsSinceEpoch}';
      final backupData = <String, dynamic>{
        'backupId': backupId,
        'backupType': backupType,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
        'version': '1.0.0',
        'data': <String, dynamic>{},
      };

      switch (backupType) {
        case fullBackup:
          backupData['data'] = await _createFullBackup();
          break;
        case userDataBackup:
          backupData['data'] = await _createUserDataBackup(userId);
          break;
        case ordersBackup:
          backupData['data'] = await _createOrdersBackup(filters);
          break;
        case productsBackup:
          backupData['data'] = await _createProductsBackup(filters);
          break;
        default:
          throw Exception('Invalid backup type: $backupType');
      }

      // Store backup metadata in Firestore
      await _firestore.collection('backups').doc(backupId).set(backupData);

      // Store backup data in Firebase Storage
      await _storeBackupData(backupId, backupData);

      // Log backup creation
      await _errorHandler.logError(
        error: 'Backup created successfully',
        type: 'backup_success',
        action: 'create_backup',
        additionalData: {
          'backupId': backupId,
          'backupType': backupType,
          'dataSize': jsonEncode(backupData).length,
        },
      );

      return {
        'success': true,
        'backupId': backupId,
        'backupType': backupType,
        'createdAt': DateTime.now().toIso8601String(),
        'dataSize': jsonEncode(backupData).length,
      };
    } catch (e) {
      await _errorHandler.logError(
        error: e.toString(),
        type: 'backup_error',
        action: 'create_backup',
        additionalData: {'backupType': backupType},
      );
      rethrow;
    }
  }

  // Create full system backup
  Future<Map<String, dynamic>> _createFullBackup() async {
    final data = <String, dynamic>{};

    // Backup users
    final usersSnapshot = await _firestore.collection('users').get();
    data['users'] =
        usersSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    // Backup products
    final productsSnapshot = await _firestore.collection('products').get();
    data['products'] =
        productsSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    // Backup orders
    final ordersSnapshot = await _firestore.collection('orders').get();
    data['orders'] =
        ordersSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    // Backup addresses
    final addressesSnapshot = await _firestore.collection('addresses').get();
    data['addresses'] =
        addressesSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    // Backup payment methods
    final paymentsSnapshot =
        await _firestore.collection('payment_methods').get();
    data['payment_methods'] =
        paymentsSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    // Backup reviews
    final reviewsSnapshot = await _firestore.collection('reviews').get();
    data['reviews'] =
        reviewsSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    return data;
  }

  // Create user-specific data backup
  Future<Map<String, dynamic>> _createUserDataBackup(String? userId) async {
    final data = <String, dynamic>{};
    final targetUserId = userId ?? _auth.currentUser?.uid;

    if (targetUserId == null) {
      throw Exception('No user ID provided for backup');
    }

    // Backup user profile
    final userDoc =
        await _firestore.collection('users').doc(targetUserId).get();
    if (userDoc.exists) {
      data['user'] = {'id': userDoc.id, 'data': userDoc.data()};
    }

    // Backup user orders
    final ordersSnapshot =
        await _firestore
            .collection('orders')
            .where('userId', isEqualTo: targetUserId)
            .get();
    data['orders'] =
        ordersSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    // Backup user addresses
    final addressesSnapshot =
        await _firestore
            .collection('addresses')
            .where('userId', isEqualTo: targetUserId)
            .get();
    data['addresses'] =
        addressesSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    // Backup user payment methods
    final paymentsSnapshot =
        await _firestore
            .collection('payment_methods')
            .where('userId', isEqualTo: targetUserId)
            .get();
    data['payment_methods'] =
        paymentsSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    // Backup user reviews
    final reviewsSnapshot =
        await _firestore
            .collection('reviews')
            .where('userId', isEqualTo: targetUserId)
            .get();
    data['reviews'] =
        reviewsSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    return data;
  }

  // Create orders backup
  Future<Map<String, dynamic>> _createOrdersBackup(
    Map<String, dynamic>? filters,
  ) async {
    final data = <String, dynamic>{};

    Query query = _firestore.collection('orders');

    // Apply filters if provided
    if (filters != null) {
      final status = filters['status'];
      if (status != null && status.toString().isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }
      final startDate = filters['startDate'];
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }
      final endDate = filters['endDate'];
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }
    }

    final ordersSnapshot = await query.get();
    data['orders'] =
        ordersSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    return data;
  }

  // Create products backup
  Future<Map<String, dynamic>> _createProductsBackup(
    Map<String, dynamic>? filters,
  ) async {
    final data = <String, dynamic>{};

    Query query = _firestore.collection('products');

    // Apply filters if provided
    if (filters != null) {
      if (filters['category'] != null) {
        query = query.where('category', isEqualTo: filters['category']);
      }
      if (filters['sellerId'] != null) {
        query = query.where('sellerId', isEqualTo: filters['sellerId']);
      }
      if (filters['isActive'] != null) {
        query = query.where('isActive', isEqualTo: filters['isActive']);
      }
    }

    final productsSnapshot = await query.get();
    data['products'] =
        productsSnapshot.docs
            .map((doc) => {'id': doc.id, 'data': doc.data()})
            .toList();

    return data;
  }

  // Store backup data in Firebase Storage
  Future<void> _storeBackupData(
    String backupId,
    Map<String, dynamic> backupData,
  ) async {
    final backupJson = jsonEncode(backupData);
    final backupBytes = utf8.encode(backupJson);

    final storageRef = _storage.ref().child('backups/$backupId.json');
    await storageRef.putData(Uint8List.fromList(backupBytes));
  }

  // Restore backup
  Future<Map<String, dynamic>> restoreBackup(String backupId) async {
    try {
      // Get backup metadata
      final backupDoc =
          await _firestore.collection('backups').doc(backupId).get();
      if (!backupDoc.exists) {
        throw Exception('Backup not found: $backupId');
      }

      final backupData = backupDoc.data()!;
      final backupType = backupData['backupType'] as String;

      // Download backup data from Storage
      final storageRef = _storage.ref().child('backups/$backupId.json');
      final backupBytes = await storageRef.getData();
      final backupJson = utf8.decode(backupBytes!);
      final fullBackupData = jsonDecode(backupJson) as Map<String, dynamic>;

      // Restore data based on backup type
      switch (backupType) {
        case fullBackup:
          await _restoreFullBackup(fullBackupData['data']);
          break;
        case userDataBackup:
          await _restoreUserDataBackup(fullBackupData['data']);
          break;
        case ordersBackup:
          await _restoreOrdersBackup(fullBackupData['data']);
          break;
        case productsBackup:
          await _restoreProductsBackup(fullBackupData['data']);
          break;
        default:
          throw Exception('Invalid backup type: $backupType');
      }

      // Log restore operation
      await _errorHandler.logError(
        error: 'Backup restored successfully',
        type: 'backup_restore_success',
        action: 'restore_backup',
        additionalData: {'backupId': backupId, 'backupType': backupType},
      );

      return {
        'success': true,
        'backupId': backupId,
        'backupType': backupType,
        'restoredAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      await _errorHandler.logError(
        error: e.toString(),
        type: 'backup_restore_error',
        action: 'restore_backup',
        additionalData: {'backupId': backupId},
      );
      rethrow;
    }
  }

  // Restore full backup
  Future<void> _restoreFullBackup(Map<String, dynamic> data) async {
    final batch = _firestore.batch();

    // Restore users
    if (data['users'] != null) {
      for (final user in data['users']) {
        final docRef = _firestore.collection('users').doc(user['id']);
        batch.set(docRef, user['data']);
      }
    }

    // Restore products
    if (data['products'] != null) {
      for (final product in data['products']) {
        final docRef = _firestore.collection('products').doc(product['id']);
        batch.set(docRef, product['data']);
      }
    }

    // Restore orders
    if (data['orders'] != null) {
      for (final order in data['orders']) {
        final docRef = _firestore.collection('orders').doc(order['id']);
        batch.set(docRef, order['data']);
      }
    }

    // Restore addresses
    if (data['addresses'] != null) {
      for (final address in data['addresses']) {
        final docRef = _firestore.collection('addresses').doc(address['id']);
        batch.set(docRef, address['data']);
      }
    }

    // Restore payment methods
    if (data['payment_methods'] != null) {
      for (final payment in data['payment_methods']) {
        final docRef = _firestore
            .collection('payment_methods')
            .doc(payment['id']);
        batch.set(docRef, payment['data']);
      }
    }

    // Restore reviews
    if (data['reviews'] != null) {
      for (final review in data['reviews']) {
        final docRef = _firestore.collection('reviews').doc(review['id']);
        batch.set(docRef, review['data']);
      }
    }

    await batch.commit();
  }

  // Restore user data backup
  Future<void> _restoreUserDataBackup(Map<String, dynamic> data) async {
    final batch = _firestore.batch();

    // Restore user profile
    if (data['user'] != null) {
      final docRef = _firestore.collection('users').doc(data['user']['id']);
      batch.set(docRef, data['user']['data']);
    }

    // Restore user orders
    if (data['orders'] != null) {
      for (final order in data['orders']) {
        final docRef = _firestore.collection('orders').doc(order['id']);
        batch.set(docRef, order['data']);
      }
    }

    // Restore user addresses
    if (data['addresses'] != null) {
      for (final address in data['addresses']) {
        final docRef = _firestore.collection('addresses').doc(address['id']);
        batch.set(docRef, address['data']);
      }
    }

    // Restore user payment methods
    if (data['payment_methods'] != null) {
      for (final payment in data['payment_methods']) {
        final docRef = _firestore
            .collection('payment_methods')
            .doc(payment['id']);
        batch.set(docRef, payment['data']);
      }
    }

    // Restore user reviews
    if (data['reviews'] != null) {
      for (final review in data['reviews']) {
        final docRef = _firestore.collection('reviews').doc(review['id']);
        batch.set(docRef, review['data']);
      }
    }

    await batch.commit();
  }

  // Restore orders backup
  Future<void> _restoreOrdersBackup(Map<String, dynamic> data) async {
    final batch = _firestore.batch();

    if (data['orders'] != null) {
      for (final order in data['orders']) {
        final docRef = _firestore.collection('orders').doc(order['id']);
        batch.set(docRef, order['data']);
      }
    }

    await batch.commit();
  }

  // Restore products backup
  Future<void> _restoreProductsBackup(Map<String, dynamic> data) async {
    final batch = _firestore.batch();

    if (data['products'] != null) {
      for (final product in data['products']) {
        final docRef = _firestore.collection('products').doc(product['id']);
        batch.set(docRef, product['data']);
      }
    }

    await batch.commit();
  }

  // Get backup list
  Future<List<Map<String, dynamic>>> getBackupList() async {
    try {
      final snapshot =
          await _firestore
              .collection('backups')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['backupType'],
          'createdAt': data['createdAt'],
          'createdBy': data['createdBy'],
          'version': data['version'],
        };
      }).toList();
    } catch (e) {
      await _errorHandler.logError(
        error: e.toString(),
        type: 'backup_list_error',
        action: 'get_backup_list',
      );
      rethrow;
    }
  }

  // Delete backup
  Future<void> deleteBackup(String backupId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('backups').doc(backupId).delete();

      // Delete from Storage
      final storageRef = _storage.ref().child('backups/$backupId.json');
      await storageRef.delete();

      await _errorHandler.logError(
        error: 'Backup deleted successfully',
        type: 'backup_delete_success',
        action: 'delete_backup',
        additionalData: {'backupId': backupId},
      );
    } catch (e) {
      await _errorHandler.logError(
        error: e.toString(),
        type: 'backup_delete_error',
        action: 'delete_backup',
        additionalData: {'backupId': backupId},
      );
      rethrow;
    }
  }

  // Export backup to local file
  Future<String> exportBackupToLocal(String backupId) async {
    try {
      // Download backup data
      final storageRef = _storage.ref().child('backups/$backupId.json');
      final backupBytes = await storageRef.getData();
      final backupJson = utf8.decode(backupBytes!);

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Save to local file
      final file = File('${backupDir.path}/$backupId.json');
      await file.writeAsString(backupJson);

      return file.path;
    } catch (e) {
      await _errorHandler.logError(
        error: e.toString(),
        type: 'backup_export_error',
        action: 'export_backup',
        additionalData: {'backupId': backupId},
      );
      rethrow;
    }
  }

  // Import backup from local file
  Future<Map<String, dynamic>> importBackupFromLocal(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found: $filePath');
      }

      final backupJson = await file.readAsString();
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

      // Validate backup data
      if (!backupData.containsKey('backupId') ||
          !backupData.containsKey('data')) {
        throw Exception('Invalid backup file format');
      }

      // Restore backup
      return await restoreBackup(backupData['backupId']);
    } catch (e) {
      await _errorHandler.logError(
        error: e.toString(),
        type: 'backup_import_error',
        action: 'import_backup',
        additionalData: {'filePath': filePath},
      );
      rethrow;
    }
  }

  // Schedule automatic backups
  Future<void> scheduleAutomaticBackup({
    required String backupType,
    required Duration interval,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final scheduleData = {
        'backupType': backupType,
        'interval': interval.inSeconds,
        'filters': filters,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
        'lastRun': null,
        'nextRun': DateTime.now().add(interval).toIso8601String(),
      };

      await _firestore.collection('backup_schedules').add(scheduleData);

      await _errorHandler.logError(
        error: 'Automatic backup scheduled',
        type: 'backup_schedule_created',
        action: 'schedule_backup',
        additionalData: {
          'backupType': backupType,
          'interval': interval.inSeconds,
        },
      );
    } catch (e) {
      await _errorHandler.logError(
        error: e.toString(),
        type: 'backup_schedule_error',
        action: 'schedule_backup',
        additionalData: {'backupType': backupType},
      );
      rethrow;
    }
  }
}
