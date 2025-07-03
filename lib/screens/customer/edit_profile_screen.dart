import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/sample_data_service.dart';
import 'dart:io';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  String? _selectedGender;
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _hasLoadedData = false;
  XFile? _pickedImage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        setState(() => _isLoading = true);

        // Load user data directly from Firebase to get all fields
        final userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.id)
                .get();

        if (userData.exists) {
          final data = userData.data()!;

          // Load basic name data
          final fullName = data['name'] ?? '';
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';

          // If we have firstName/lastName, use them; otherwise split the full name
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            _firstNameController.text = firstName;
            _lastNameController.text = lastName;
          } else {
            final nameParts = fullName.split(' ');
            _firstNameController.text =
                nameParts.isNotEmpty ? nameParts.first : '';
            _lastNameController.text =
                nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
          }

          // Load other profile fields
          _phoneController.text = data['phone'] ?? data['phoneNumber'] ?? '';
          _dateOfBirthController.text = data['dateOfBirth'] ?? '';
          _selectedGender = data['gender'];
          _profileImageUrl = data['profileImageUrl'];
        } else {
          // User document does not exist
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile data: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasLoadedData = true;
          });
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
        body: Center(child: Text('Please log in to edit your profile')),
      );
    }

    // Load user data once when the widget is built
    if (!_hasLoadedData && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUserData();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Image Section
              _buildProfileImageSection(theme),

              const SizedBox(height: 32),

              // Personal Information
              _buildPersonalInfoSection(theme),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
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
                            'Save Changes',
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
      ),
    );
  }

  Widget _buildProfileImageSection(ThemeData theme) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.colorScheme.primary.withAlpha(30),
              backgroundImage:
                  _pickedImage != null
                      ? FileImage(File(_pickedImage!.path))
                      : (_profileImageUrl != null &&
                          _profileImageUrl!.isNotEmpty)
                      ? NetworkImage(_profileImageUrl!) as ImageProvider
                      : null,
              child:
                  (_pickedImage == null &&
                          (_profileImageUrl == null ||
                              _profileImageUrl!.isEmpty))
                      ? Icon(
                        Icons.person,
                        size: 60,
                        color: theme.colorScheme.primary,
                      )
                      : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: _isLoading ? null : _pickImage,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to change profile picture',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // First Name
        TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
            labelText: 'First Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your first name';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Last Name
        TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
            labelText: 'Last Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your last name';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Phone Number
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Date of Birth
        TextFormField(
          controller: _dateOfBirthController,
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          readOnly: true,
          onTap: _selectDateOfBirth,
        ),

        const SizedBox(height: 16),

        // Gender
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            labelText: 'Gender',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
            DropdownMenuItem(
              value: 'prefer_not_to_say',
              child: Text('Prefer not to say'),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedGender = value);
          },
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dateOfBirthController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_pickedImage == null) return _profileImageUrl;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$userId.jpg');
      await ref.putData(await _pickedImage!.readAsBytes());
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    String? imageUrl = await _uploadProfileImage(user.id);

    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final phone =
          _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null;
      final dateOfBirth =
          _dateOfBirthController.text.trim().isNotEmpty
              ? _dateOfBirthController.text.trim()
              : null;
      final fullName = '$firstName $lastName'.trim();

      // Update the main user document with all profile data
      final updateData = <String, dynamic>{
        'name': fullName,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'phoneNumber': phone, // Keep both for compatibility
        'dateOfBirth': dateOfBirth,
        'gender': _selectedGender,
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // First check if user document exists, if not create it
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.id)
              .get();

      if (!userDoc.exists) {
        // Create the user document if it doesn't exist
        await FirebaseFirestore.instance.collection('users').doc(user.id).set({
          'email': user.email,
          'role': user.role,
          'createdAt': FieldValue.serverTimestamp(),
          ...updateData,
        });
      } else {
        // Update existing document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update(updateData);
      }

      // Also update via the provider for consistency
      await ref
          .read(userProfileProvider.notifier)
          .updateProfile(
            userId: user.id,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phone,
            dateOfBirth: dateOfBirth,
            gender: _selectedGender,
            profileImageUrl: imageUrl,
          );

      // The auth provider will automatically update via Firebase listener

      if (mounted) {
        _showSuccessMessage('Profile updated successfully!');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update profile';

        // Provide more specific error messages
        if (e.toString().contains('permission-denied')) {
          errorMessage =
              'Permission denied. Check Firebase security rules or log in again.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
        } else if (e.toString().contains('not-found')) {
          errorMessage = 'User profile not found. Please contact support.';
        } else if (e.toString().contains('unauthenticated')) {
          errorMessage = 'Authentication required. Please log in again.';
        } else if (e.toString().contains('unavailable')) {
          errorMessage =
              'Firebase service unavailable. Please try again later.';
        } else {
          errorMessage = 'Failed to update profile: ${e.toString()}';
        }

        _showErrorMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _saveProfile,
        ),
      ),
    );
  }

  // Temporary method to test Firebase connection
  Future<void> _testFirebaseConnection() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        _showErrorMessage('No user logged in');
        return;
      }

      // Test writing to Firestore
      await FirebaseFirestore.instance
          .collection('test')
          .doc('connection-test')
          .set({
            'timestamp': FieldValue.serverTimestamp(),
            'userId': user.id,
            'message': 'Firebase connection test successful',
          });

      // Test reading from Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('test')
              .doc('connection-test')
              .get();

      if (doc.exists) {
        _showSuccessMessage(
          'Firebase connection successful! Check Firestore console.',
        );
      } else {
        _showErrorMessage('Firebase write succeeded but read failed');
      }
    } catch (e) {
      _showErrorMessage('Firebase connection failed: ${e.toString()}');
    }
  }

  // Method to seed sample data to Firestore
  Future<void> _seedSampleData() async {
    try {
      final sampleDataService = SampleDataService();

      // Check if products already exist
      final hasProducts = await sampleDataService.hasProducts();
      if (hasProducts) {
        _showSuccessMessage('Sample data already exists in Firestore!');
        return;
      }

      // Seed sample products and sellers
      await sampleDataService.seedSampleProducts();
      await sampleDataService.seedSampleSellers();

      _showSuccessMessage(
        'Sample data seeded successfully! Check Firestore console for products and sellers.',
      );
    } catch (e) {
      _showErrorMessage('Failed to seed sample data: ${e.toString()}');
    }
  }

  // Method to test registration process
  Future<void> _testRegistration() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'test$timestamp@example.com';

      await ref
          .read(authProvider.notifier)
          .register(
            testEmail,
            'TestPassword123!',
            'customer',
            'Test User $timestamp',
            '+255123456789',
          );

      _showSuccessMessage(
        'Test registration successful! Check Firestore console for users collection.',
      );
    } catch (e) {
      _showErrorMessage('Test registration failed: ${e.toString()}');
    }
  }

  // Method to check users in Firebase
  Future<void> _checkUsers() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').limit(10).get();

      if (usersSnapshot.docs.isEmpty) {
        _showErrorMessage('No users found in Firebase users collection');
        return;
      }

      final userCount = usersSnapshot.docs.length;
      final users = usersSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return '${data['name'] ?? 'No Name'} (${data['role'] ?? 'No Role'}) - ${doc.id.substring(0, 8)}...';
          })
          .join('\n');

      // Show detailed info in a dialog
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Found $userCount Users in Firebase'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Project ID: car-accessory-dit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Users in Firestore:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(users),
                      const SizedBox(height: 16),
                      Text(
                        'Firebase Console Link:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        'https://console.firebase.google.com/project/car-accessory-dit/firestore',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      _showErrorMessage('Failed to check users: ${e.toString()}');
    }
  }

  // Method to force collection visibility in Firebase Console
  Future<void> _forceCollectionVisibility() async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Create a visible document in users collection
      final usersRef = FirebaseFirestore.instance
          .collection('users')
          .doc('_visibility_marker');
      batch.set(usersRef, {
        'type': 'visibility_marker',
        'purpose': 'Make users collection visible in Firebase Console',
        'createdAt': FieldValue.serverTimestamp(),
        'note': 'This document can be deleted after collections are visible',
      });

      // Create a visible document in products collection
      final productsRef = FirebaseFirestore.instance
          .collection('products')
          .doc('_visibility_marker');
      batch.set(productsRef, {
        'type': 'visibility_marker',
        'purpose': 'Make products collection visible in Firebase Console',
        'createdAt': FieldValue.serverTimestamp(),
        'note': 'This document can be deleted after collections are visible',
      });

      // Create a visible document in test collection
      final testRef = FirebaseFirestore.instance
          .collection('test')
          .doc('_visibility_marker');
      batch.set(testRef, {
        'type': 'visibility_marker',
        'purpose': 'Make test collection visible in Firebase Console',
        'createdAt': FieldValue.serverTimestamp(),
        'note': 'This document can be deleted after collections are visible',
      });

      await batch.commit();

      _showSuccessMessage(
        'Visibility markers created! Refresh Firebase Console to see collections: users, products, test',
      );
    } catch (e) {
      _showErrorMessage('Failed to create visibility markers: ${e.toString()}');
    }
  }

  // Deep diagnostic method to investigate the Firebase issue
  Future<void> _runDeepDiagnostic() async {
    final diagnosticResults = <String>[];

    try {
      diagnosticResults.add('🔍 DEEP FIREBASE DIAGNOSTIC');
      diagnosticResults.add('Project ID: car-accessory-dit');
      diagnosticResults.add('');

      // Test 1: Check Firebase initialization
      diagnosticResults.add('✅ Test 1: Firebase Initialization');
      try {
        final app = Firebase.app();
        diagnosticResults.add('Firebase app name: ${app.name}');
        diagnosticResults.add('Firebase project ID: ${app.options.projectId}');
      } catch (e) {
        diagnosticResults.add('❌ Firebase not initialized: $e');
      }
      diagnosticResults.add('');

      // Test 2: Test basic Firestore write
      diagnosticResults.add('🔄 Test 2: Basic Firestore Write');
      try {
        final testDoc = FirebaseFirestore.instance
            .collection('diagnostic')
            .doc('test');
        await testDoc.set({
          'timestamp': FieldValue.serverTimestamp(),
          'test': 'basic write test',
          'random': DateTime.now().millisecondsSinceEpoch,
        });
        diagnosticResults.add('✅ Basic write successful');
      } catch (e) {
        diagnosticResults.add('❌ Basic write failed: $e');
      }

      // Test 3: Test basic Firestore read
      diagnosticResults.add('🔄 Test 3: Basic Firestore Read');
      try {
        final testDoc =
            await FirebaseFirestore.instance
                .collection('diagnostic')
                .doc('test')
                .get();
        if (testDoc.exists) {
          diagnosticResults.add('✅ Basic read successful');
          diagnosticResults.add('Document data: ${testDoc.data()}');
        } else {
          diagnosticResults.add('❌ Document does not exist after write');
        }
      } catch (e) {
        diagnosticResults.add('❌ Basic read failed: $e');
      }
      diagnosticResults.add('');

      // Test 4: Check specific collections
      diagnosticResults.add('🔄 Test 4: Check Specific Collections');
      final collectionsToCheck = ['users', 'products', 'test', 'diagnostic'];

      for (final collectionName in collectionsToCheck) {
        try {
          final snapshot =
              await FirebaseFirestore.instance
                  .collection(collectionName)
                  .limit(1)
                  .get();

          if (snapshot.docs.isNotEmpty) {
            diagnosticResults.add(
              '✅ $collectionName: ${snapshot.docs.length} documents found',
            );
          } else {
            diagnosticResults.add('⚠️ $collectionName: exists but empty');
          }
        } catch (e) {
          diagnosticResults.add('❌ $collectionName: error - $e');
        }
      }
      diagnosticResults.add('');

      // Test 5: Check users collection specifically
      diagnosticResults.add('🔄 Test 5: Users Collection Check');
      try {
        final usersQuery =
            await FirebaseFirestore.instance.collection('users').limit(5).get();
        diagnosticResults.add('✅ Users query successful');
        diagnosticResults.add('Found ${usersQuery.docs.length} user documents');

        if (usersQuery.docs.isNotEmpty) {
          diagnosticResults.add('Sample user IDs:');
          for (final doc in usersQuery.docs.take(3)) {
            final data = doc.data();
            diagnosticResults.add(
              '  - ${doc.id}: ${data['name'] ?? 'No name'} (${data['role'] ?? 'No role'})',
            );
          }
        }
      } catch (e) {
        diagnosticResults.add('❌ Users collection check failed: $e');
      }
      diagnosticResults.add('');

      // Test 6: Check current user
      diagnosticResults.add('🔄 Test 6: Current User Check');
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        diagnosticResults.add('✅ Current user logged in');
        diagnosticResults.add('User ID: ${currentUser.id}');
        diagnosticResults.add('Email: ${currentUser.email}');
        diagnosticResults.add('Role: ${currentUser.role}');
      } else {
        diagnosticResults.add('❌ No current user');
      }

      // Show results in a dialog
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Deep Diagnostic Results'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      diagnosticResults.join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      _showErrorMessage('Diagnostic failed: ${e.toString()}');
    }
  }

  Future<void> _checkDatabaseSettings() async {
    final results = <String>[];

    try {
      results.add('🔧 DATABASE SETTINGS CHECK');
      results.add('');

      // Firebase App Settings
      final app = Firebase.app();
      results.add('📱 Firebase App Settings:');
      results.add('App Name: ${app.name}');
      results.add('Project ID: ${app.options.projectId}');
      results.add('API Key: ${app.options.apiKey.substring(0, 10)}...');
      results.add('Auth Domain: ${app.options.authDomain}');
      results.add('Storage Bucket: ${app.options.storageBucket}');
      results.add('');

      // Firestore Settings
      final firestore = FirebaseFirestore.instance;
      results.add('🗄️ Firestore Settings:');
      results.add('App: ${firestore.app.name}');

      // Try to get Firestore settings (this might reveal region info)
      try {
        final settings = firestore.settings;
        results.add('Host: ${settings.host ?? "default"}');
        results.add('SSL Enabled: ${settings.sslEnabled}');
        results.add('Persistence Enabled: ${settings.persistenceEnabled}');
        results.add('Cache Size: ${settings.cacheSizeBytes}');
      } catch (e) {
        results.add('Settings access error: $e');
      }
      results.add('');

      // Test database access with different approaches
      results.add('🔍 Database Access Tests:');

      // Test 1: Check if we're using emulator
      results.add(
        'Using Firestore Emulator: ${firestore.settings.host?.contains('localhost') ?? false}',
      );

      // Test 2: Try to access with different database instances
      try {
        results.add('Testing default database instance...');
        final testDoc =
            await firestore.collection('_test_connection').doc('test').get();
        results.add(
          'Default instance accessible: ${testDoc.metadata.isFromCache ? "from cache" : "from server"}',
        );
      } catch (e) {
        results.add('Default instance error: $e');
      }

      // Test 3: Check plan migration issues
      results.add('');
      results.add('🚨 PLAN MIGRATION DIAGNOSTIC:');
      results.add('This checks for Free->Blaze->Free plan issues');

      // Try to write and immediately read to check server sync
      try {
        final testCollection = firestore.collection('_plan_migration_test');
        final testDoc = testCollection.doc('migration_test');

        // Write test data
        await testDoc.set({
          'test': 'plan migration test',
          'timestamp': Timestamp.now(),
          'source': 'app_diagnostic',
        });

        // Try to read it back immediately
        final readDoc = await testDoc.get(
          const GetOptions(source: Source.server),
        );
        if (readDoc.exists) {
          results.add('✅ Server write/read successful - no migration issues');
        } else {
          results.add('❌ Server read failed - possible migration issue');
        }

        // Clean up
        await testDoc.delete();
      } catch (e) {
        results.add('❌ Plan migration test failed: $e');
        results.add('This suggests plan migration corruption');
      }
    } catch (e) {
      results.add('❌ Settings check failed: $e');
    }

    // Show results
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Database Settings'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: SingleChildScrollView(
                  child: SelectableText(
                    results.join('\n'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    }
  }
}
