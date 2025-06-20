import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/product_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../models/inventory_model.dart';
import '../../widgets/custom_button.dart';

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
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  String _category = 'Seat Covers';
  List<String> _compatibility = [];
  List<String> _imageUrls = [];
  List<String> _videoUrls = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  void _addImageUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isNotEmpty && !_imageUrls.contains(url)) {
      setState(() {
        _imageUrls.add(url);
        _imageUrlController.clear();
      });
    }
  }

  void _addVideoUrl() {
    final url = _videoUrlController.text.trim();
    if (url.isNotEmpty && !_videoUrls.contains(url)) {
      setState(() {
        _videoUrls.add(url);
        _videoUrlController.clear();
      });
    }
  }

  void _removeImageUrl(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  void _removeVideoUrl(int index) {
    setState(() {
      _videoUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productNotifier = ref.read(productProvider.notifier);
    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    final user = ref.read(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary.withOpacity(0.05), colorScheme.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product Details', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
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
                        DropdownMenuItem(value: 'Seat Covers', child: Text('Seat Covers')),
                        DropdownMenuItem(value: 'Lighting', child: Text('Lighting')),
                        DropdownMenuItem(value: 'Tools', child: Text('Tools')),
                      ],
                      onChanged: (value) => setState(() => _category = value!),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Compatibility (comma-separated car models)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      onChanged: (value) => _compatibility = value.split(',').map((e) => e.trim()).toList(),
                    ),
                    const SizedBox(height: 28),
                    Text('Product Images (Paste URLs)', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _imageUrlController,
                            decoration: const InputDecoration(
                              hintText: 'Paste image URL',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _addImageUrl,
                          icon: const Icon(Icons.add_link),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_imageUrls.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_imageUrls.length, (index) {
                          final url = _imageUrls[index];
                          return Chip(
                            label: Text(url, overflow: TextOverflow.ellipsis),
                            avatar: CircleAvatar(
                              backgroundImage: NetworkImage(url),
                              backgroundColor: Colors.grey[200],
                            ),
                            onDeleted: () => _removeImageUrl(index),
                          );
                        }),
                      ),
                    const SizedBox(height: 28),
                    Text('Product Videos (Paste URLs, optional)', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _videoUrlController,
                            decoration: const InputDecoration(
                              hintText: 'Paste video URL',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _addVideoUrl,
                          icon: const Icon(Icons.add_link),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_videoUrls.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_videoUrls.length, (index) {
                          final url = _videoUrls[index];
                          return Chip(
                            label: Text(url, overflow: TextOverflow.ellipsis),
                            avatar: const CircleAvatar(
                              child: Icon(Icons.videocam, color: Colors.white, size: 16),
                              backgroundColor: Colors.blue,
                            ),
                            onDeleted: () => _removeVideoUrl(index),
                          );
                        }),
                      ),
                    const SizedBox(height: 36),
                    CustomButton(
                      text: 'Add Product',
                      onPressed: () async {
                        try {
                          if (user == null) {
                            throw Exception('User not authenticated');
                          }
                          if (_nameController.text.isEmpty || _priceController.text.isEmpty || _stockController.text.isEmpty || _imageUrls.isEmpty) {
                            throw Exception('Please fill all required fields and add at least one image URL.');
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
                            images: _imageUrls,
                            videos: _videoUrls.isNotEmpty ? _videoUrls : null,
                          );
                          await productNotifier.addProduct(product, []); // [] for images, not used
                          // Add initial inventory entry
                          final inventory = InventoryModel(
                            id: const Uuid().v4(),
                            productId: productId,
                            sellerId: user.id,
                            stock: int.parse(_stockController.text),
                            lastUpdated: DateTime.now(),
                          );
                          await inventoryNotifier.updateInventory(inventory);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product and inventory added successfully'),
                            ),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
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
