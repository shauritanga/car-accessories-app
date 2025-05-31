import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  String _category = 'Seat Covers';
  List<String> _compatibility = [];
  List<XFile> _images = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productNotifier = ref.read(productProvider.notifier);
    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    final user = ref.read(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (TZS)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Initial Stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Seat Covers',
                    child: Text('Seat Covers'),
                  ),
                  DropdownMenuItem(value: 'Lighting', child: Text('Lighting')),
                  DropdownMenuItem(value: 'Tools', child: Text('Tools')),
                ],
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Compatibility (comma-separated car models)',
                  border: OutlineInputBorder(),
                ),
                onChanged:
                    (value) =>
                        _compatibility =
                            value.split(',').map((e) => e.trim()).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final picked = await ImagePicker().pickMultiImage();
                  setState(() => _images = picked);
                },
                child: Text('Pick Images (${_images.length} selected)'),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Add Product',
                onPressed: () async {
                  try {
                    if (user == null) {
                      throw Exception('User not authenticated');
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
                      images: [],
                    );
                    await productNotifier.addProduct(product, _images);

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
                        content: Text(
                          'Product and inventory added successfully',
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
