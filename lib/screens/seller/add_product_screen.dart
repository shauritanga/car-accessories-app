import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/product_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../models/inventory_model.dart';
import '../../widgets/custom_button.dart';
import '../../services/supabase_storage_service.dart';
import 'pending_approval_screen.dart';
import '../../services/product_service.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  String _category = 'Seat Covers';
  final List<String> _compatibility = [];
  final List<File> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  bool _isUploadingImages = false;
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _allCarModels = [];
  bool _loadingCarModels = true;

  @override
  void initState() {
    super.initState();
    _fetchCarModels();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _fetchCarModels() async {
    final carModels = await ProductService().getCarModels();
    setState(() {
      _allCarModels = carModels;
      _loadingCarModels = false;
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploadingImages = true;
    });

    try {
      final List<String> uploadedUrls = [];

      for (final image in _selectedImages) {
        final url = await SupabaseStorageService.uploadImage(
          file: image,
          customPath:
              'products/${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      setState(() {
        _uploadedImageUrls.addAll(uploadedUrls);
        _selectedImages.clear();
        _isUploadingImages = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${uploadedUrls.length} images uploaded successfully',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading images: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user?.role == 'seller' && user?.status != 'approved') {
      return const PendingApprovalScreen();
    }
    final productNotifier = ref.read(productProvider.notifier);
    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body:
          _loadingCarModels
              ? const Center(child: CircularProgressIndicator())
              : Container(
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product Details',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 28),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Product Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.label),
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _priceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Price (TZS)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.attach_money),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: TextField(
                                    controller: _stockController,
                                    decoration: const InputDecoration(
                                      labelText: 'Initial Stock',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.inventory),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            DropdownButtonFormField<String>(
                              value: _category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Seat Covers',
                                  child: Text('Seat Covers'),
                                ),
                                DropdownMenuItem(
                                  value: 'Lighting',
                                  child: Text('Lighting'),
                                ),
                                DropdownMenuItem(
                                  value: 'Tools',
                                  child: Text('Tools'),
                                ),
                              ],
                              onChanged:
                                  (value) => setState(() => _category = value!),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Compatibility (Select car models)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _allCarModels.map((carModel) {
                                    final isSelected = _compatibility.contains(
                                      carModel,
                                    );
                                    return FilterChip(
                                      label: Text(carModel),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _compatibility.add(carModel);
                                          } else {
                                            _compatibility.remove(carModel);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Product Images',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Image picker buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImages,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Pick from Gallery'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImageFromCamera,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Take Photo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.secondary,
                                      foregroundColor: colorScheme.onSecondary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Selected images preview
                            if (_selectedImages.isNotEmpty) ...[
                              Text(
                                'Selected Images (${_selectedImages.length})',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              _selectedImages[index],
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed:
                                    _isUploadingImages ? null : _uploadImages,
                                icon:
                                    _isUploadingImages
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.cloud_upload),
                                label: Text(
                                  _isUploadingImages
                                      ? 'Uploading...'
                                      : 'Upload Images',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],

                            // Uploaded images preview
                            if (_uploadedImageUrls.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Uploaded Images (${_uploadedImageUrls.length})',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _uploadedImageUrls.map((url) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ],

                            const SizedBox(height: 36),
                            CustomButton(
                              text: 'Add Product',
                              onPressed: () async {
                                try {
                                  if (user == null) {
                                    throw Exception('User not authenticated');
                                  }

                                  // Validate required fields
                                  if (_nameController.text.isEmpty ||
                                      _priceController.text.isEmpty ||
                                      _stockController.text.isEmpty) {
                                    throw Exception(
                                      'Please fill all required fields.',
                                    );
                                  }

                                  // Validate compatibility
                                  if (_compatibility.isEmpty) {
                                    throw Exception(
                                      'Please select at least one compatible car model.',
                                    );
                                  }

                                  // Check if images are uploaded
                                  if (_uploadedImageUrls.isEmpty) {
                                    throw Exception(
                                      'Please upload at least one product image.',
                                    );
                                  }

                                  final productId = const Uuid().v4();
                                  final product = ProductModel(
                                    id: productId,
                                    name: _nameController.text,
                                    description: _descriptionController.text,
                                    price: double.parse(_priceController.text),
                                    category: _category,
                                    compatibility: _compatibility,
                                    stock: int.parse(_stockController.text),
                                    sellerId: user.id,
                                    images: _uploadedImageUrls,
                                    videos: null, // No video support for now
                                  );

                                  await productNotifier.addProduct(
                                    product,
                                    [],
                                  ); // [] for images, not used since we already have URLs

                                  // Add initial inventory entry
                                  final inventory = InventoryModel(
                                    id: const Uuid().v4(),
                                    productId: productId,
                                    sellerId: user.id,
                                    stock: int.parse(_stockController.text),
                                    lastUpdated: DateTime.now(),
                                  );
                                  await inventoryNotifier.updateInventory(
                                    inventory,
                                  );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Product and inventory added successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
